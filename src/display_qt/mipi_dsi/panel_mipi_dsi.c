/**
 * @file panel_mipi_dsi.c
 * @brief Generic MIPI DSI panel driver for RV1109 AI Glasses
 *
 * This driver supports generic MIPI DSI panels with configurable timings
 * from device tree. It implements the DRM panel driver interface.
 *
 * Platform: RV1109 (Rockchip)
 * Display: MIPI DSI 1280×720 @ 60Hz (configurable)
 *
 * Copyright (c) 2026 AI Glasses Project
 * SPDX-License-Identifier: GPL-2.0+
 */

#include <linux/module.h>
#include <linux/of_platform.h>
#include <linux/platform_device.h>
#include <linux/gpio/consumer.h>
#include <linux/delay.h>
#include <linux/regulator/consumer.h>
#include <drm/drm_mipi_dsi.h>
#include <drm/drm_panel.h>
#include <drm/drm_modes.h>
#include <video/mipi_display.h>

struct panel_desc {
	const struct drm_display_mode *modes;
	unsigned int num_modes;
	unsigned int bpc;

	struct {
		unsigned int width;
		unsigned int height;
	} size;

	unsigned long flags;
	enum mipi_dsi_pixel_format format;
	unsigned int lanes;
};

struct panel_simple {
	struct drm_panel base;
	struct mipi_dsi_device *dsi;

	const struct panel_desc *desc;

	struct regulator *supply;
	struct gpio_desc *reset_gpio;
	struct gpio_desc *enable_gpio;

	bool prepared;
	bool enabled;
};

static inline struct panel_simple *to_panel_simple(struct drm_panel *panel)
{
	return container_of(panel, struct panel_simple, base);
}

static int panel_simple_disable(struct drm_panel *panel)
{
	struct panel_simple *p = to_panel_simple(panel);

	if (!p->enabled)
		return 0;

	p->enabled = false;

	return 0;
}

static int panel_simple_unprepare(struct drm_panel *panel)
{
	struct panel_simple *p = to_panel_simple(panel);

	if (!p->prepared)
		return 0;

	/* Enter sleep mode */
	mipi_dsi_dcs_enter_sleep_mode(p->dsi);
	msleep(120);

	/* Disable panel power */
	if (p->enable_gpio)
		gpiod_set_value_cansleep(p->enable_gpio, 0);

	if (p->supply)
		regulator_disable(p->supply);

	p->prepared = false;

	return 0;
}

static int panel_simple_prepare(struct drm_panel *panel)
{
	struct panel_simple *p = to_panel_simple(panel);
	int ret;

	if (p->prepared)
		return 0;

	/* Enable panel power */
	if (p->supply) {
		ret = regulator_enable(p->supply);
		if (ret < 0) {
			dev_err(panel->dev, "failed to enable supply: %d\n", ret);
			return ret;
		}
	}

	msleep(20);

	/* Reset panel */
	if (p->reset_gpio) {
		gpiod_set_value_cansleep(p->reset_gpio, 1);
		msleep(10);
		gpiod_set_value_cansleep(p->reset_gpio, 0);
		msleep(20);
	}

	/* Enable panel */
	if (p->enable_gpio) {
		gpiod_set_value_cansleep(p->enable_gpio, 1);
		msleep(20);
	}

	/* Exit sleep mode */
	ret = mipi_dsi_dcs_exit_sleep_mode(p->dsi);
	if (ret < 0) {
		dev_err(panel->dev, "failed to exit sleep mode: %d\n", ret);
		goto poweroff;
	}

	msleep(120);

	/* Set pixel format */
	ret = mipi_dsi_dcs_set_pixel_format(p->dsi, MIPI_DCS_PIXEL_FMT_24BIT);
	if (ret < 0) {
		dev_err(panel->dev, "failed to set pixel format: %d\n", ret);
		goto poweroff;
	}

	p->prepared = true;

	return 0;

poweroff:
	if (p->enable_gpio)
		gpiod_set_value_cansleep(p->enable_gpio, 0);

	if (p->supply)
		regulator_disable(p->supply);

	return ret;
}

static int panel_simple_enable(struct drm_panel *panel)
{
	struct panel_simple *p = to_panel_simple(panel);
	int ret;

	if (p->enabled)
		return 0;

	/* Turn on display */
	ret = mipi_dsi_dcs_set_display_on(p->dsi);
	if (ret < 0) {
		dev_err(panel->dev, "failed to set display on: %d\n", ret);
		return ret;
	}

	msleep(20);

	p->enabled = true;

	return 0;
}

static int panel_simple_get_modes(struct drm_panel *panel,
				  struct drm_connector *connector)
{
	struct panel_simple *p = to_panel_simple(panel);
	const struct panel_desc *desc = p->desc;
	struct drm_display_mode *mode;
	unsigned int i;

	for (i = 0; i < desc->num_modes; i++) {
		mode = drm_mode_duplicate(connector->dev, &desc->modes[i]);
		if (!mode) {
			dev_err(panel->dev, "failed to add mode %ux%u@%u\n",
				desc->modes[i].hdisplay,
				desc->modes[i].vdisplay,
				drm_mode_vrefresh(&desc->modes[i]));
			return -ENOMEM;
		}

		drm_mode_set_name(mode);

		mode->type = DRM_MODE_TYPE_DRIVER;
		if (i == 0)
			mode->type |= DRM_MODE_TYPE_PREFERRED;

		drm_mode_probed_add(connector, mode);
	}

	connector->display_info.width_mm = desc->size.width;
	connector->display_info.height_mm = desc->size.height;
	connector->display_info.bpc = desc->bpc;

	return desc->num_modes;
}

static const struct drm_panel_funcs panel_simple_funcs = {
	.disable = panel_simple_disable,
	.unprepare = panel_simple_unprepare,
	.prepare = panel_simple_prepare,
	.enable = panel_simple_enable,
	.get_modes = panel_simple_get_modes,
};

/* Default 1280x720@60Hz display mode */
static const struct drm_display_mode default_mode = {
	.clock = 75000,
	.hdisplay = 1280,
	.hsync_start = 1280 + 110,
	.hsync_end = 1280 + 110 + 40,
	.htotal = 1280 + 110 + 40 + 220,
	.vdisplay = 720,
	.vsync_start = 720 + 5,
	.vsync_end = 720 + 5 + 5,
	.vtotal = 720 + 5 + 5 + 20,
	.vrefresh = 60,
	.flags = 0,
};

static const struct panel_desc default_desc = {
	.modes = &default_mode,
	.num_modes = 1,
	.bpc = 8,
	.size = {
		.width = 52,
		.height = 30,
	},
	.flags = 0,
	.format = MIPI_DSI_FMT_RGB888,
	.lanes = 4,
};

static int panel_simple_probe(struct mipi_dsi_device *dsi)
{
	struct device *dev = &dsi->dev;
	struct panel_simple *panel;
	int ret;

	panel = devm_kzalloc(dev, sizeof(*panel), GFP_KERNEL);
	if (!panel)
		return -ENOMEM;

	panel->dsi = dsi;
	panel->desc = &default_desc;

	/* Get power supply */
	panel->supply = devm_regulator_get_optional(dev, "power");
	if (IS_ERR(panel->supply)) {
		ret = PTR_ERR(panel->supply);
		if (ret != -ENODEV) {
			dev_err(dev, "failed to get power supply: %d\n", ret);
			return ret;
		}
		panel->supply = NULL;
	}

	/* Get reset GPIO */
	panel->reset_gpio = devm_gpiod_get_optional(dev, "reset",
						    GPIOD_OUT_HIGH);
	if (IS_ERR(panel->reset_gpio)) {
		ret = PTR_ERR(panel->reset_gpio);
		dev_err(dev, "failed to get reset GPIO: %d\n", ret);
		return ret;
	}

	/* Get enable GPIO */
	panel->enable_gpio = devm_gpiod_get_optional(dev, "enable",
						     GPIOD_OUT_LOW);
	if (IS_ERR(panel->enable_gpio)) {
		ret = PTR_ERR(panel->enable_gpio);
		dev_err(dev, "failed to get enable GPIO: %d\n", ret);
		return ret;
	}

	drm_panel_init(&panel->base, dev, &panel_simple_funcs,
		       DRM_MODE_CONNECTOR_DSI);

	ret = drm_panel_add(&panel->base);
	if (ret < 0) {
		dev_err(dev, "failed to add panel: %d\n", ret);
		return ret;
	}

	mipi_dsi_set_drvdata(dsi, panel);

	dsi->lanes = panel->desc->lanes;
	dsi->format = panel->desc->format;
	dsi->mode_flags = MIPI_DSI_MODE_VIDEO | MIPI_DSI_MODE_VIDEO_BURST |
			  MIPI_DSI_MODE_LPM | MIPI_DSI_MODE_EOT_PACKET;

	ret = mipi_dsi_attach(dsi);
	if (ret < 0) {
		dev_err(dev, "failed to attach DSI: %d\n", ret);
		drm_panel_remove(&panel->base);
		return ret;
	}

	dev_info(dev, "MIPI DSI panel initialized: %ux%u@%uHz, %u lanes\n",
		 default_mode.hdisplay, default_mode.vdisplay,
		 default_mode.vrefresh, panel->desc->lanes);

	return 0;
}

static int panel_simple_remove(struct mipi_dsi_device *dsi)
{
	struct panel_simple *panel = mipi_dsi_get_drvdata(dsi);
	int ret;

	ret = mipi_dsi_detach(dsi);
	if (ret < 0)
		dev_err(&dsi->dev, "failed to detach DSI: %d\n", ret);

	drm_panel_remove(&panel->base);

	panel_simple_disable(&panel->base);
	panel_simple_unprepare(&panel->base);

	return 0;
}

static void panel_simple_shutdown(struct mipi_dsi_device *dsi)
{
	struct panel_simple *panel = mipi_dsi_get_drvdata(dsi);

	panel_simple_disable(&panel->base);
	panel_simple_unprepare(&panel->base);
}

static const struct of_device_id panel_simple_of_match[] = {
	{ .compatible = "simple-panel-dsi" },
	{ .compatible = "ai-glasses,mipi-panel" },
	{ /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, panel_simple_of_match);

static struct mipi_dsi_driver panel_simple_driver = {
	.driver = {
		.name = "panel-mipi-dsi-simple",
		.of_match_table = panel_simple_of_match,
	},
	.probe = panel_simple_probe,
	.remove = panel_simple_remove,
	.shutdown = panel_simple_shutdown,
};
module_mipi_dsi_driver(panel_simple_driver);

MODULE_AUTHOR("AI Glasses Project");
MODULE_DESCRIPTION("Generic MIPI DSI Panel Driver for RV1109");
MODULE_LICENSE("GPL v2");
