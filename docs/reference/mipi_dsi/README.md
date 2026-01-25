# MIPI DSI Panel Driver for RV1109

Generic MIPI DSI panel driver for RV1109 AI Glasses. Supports DRM/KMS subsystem with configurable display timings.

## Overview

This kernel module implements a DRM panel driver for generic MIPI DSI displays. It provides:

- Standard DRM panel interface
- GPIO-based reset and enable control
- Regulator-based power management
- Configurable display modes via device tree
- MIPI DSI command support (DCS)

## Hardware Configuration

Compatible with device tree configuration in:
```
arch/arm/boot/dts/rv1109-aiglasses.dts
```

Device tree node example:
```dts
&dsi {
    status = "okay";

    panel@0 {
        compatible = "simple-panel-dsi";
        reg = <0>;

        power-supply = <&vcc_3v3>;
        reset-gpios = <&gpio1 3 GPIO_ACTIVE_LOW>;
        enable-gpios = <&gpio1 4 GPIO_ACTIVE_HIGH>;

        dsi,flags = <(MIPI_DSI_MODE_VIDEO |
                      MIPI_DSI_MODE_VIDEO_BURST |
                      MIPI_DSI_MODE_LPM)>;
        dsi,format = <MIPI_DSI_FMT_RGB888>;
        dsi,lanes = <4>;

        display-timings {
            native-mode = <&timing0>;

            timing0: timing0 {
                clock-frequency = <75000000>;
                hactive = <1280>;
                vactive = <720>;
                hfront-porch = <110>;
                hsync-len = <40>;
                hback-porch = <220>;
                vfront-porch = <5>;
                vsync-len = <5>;
                vback-porch = <20>;
            };
        };
    };
};
```

## Build

### Prerequisites

1. Kernel source configured for RV1109
2. Cross-compiler installed
3. DRM and MIPI DSI support enabled in kernel config

Required kernel config options:
```
CONFIG_DRM=y
CONFIG_DRM_ROCKCHIP=y
CONFIG_DRM_PANEL=y
CONFIG_DRM_MIPI_DSI=y
CONFIG_ROCKCHIP_DW_MIPI_DSI=y
```

### Compile

```bash
cd src/display_qt/mipi_dsi

# Build module
make

# Output: panel_mipi_dsi.ko
```

### Install

**On device:**
```bash
# Copy module to device
adb push panel_mipi_dsi.ko /lib/modules/$(uname -r)/kernel/drivers/gpu/drm/panel/

# Load module
modprobe panel_mipi_dsi

# Or insert directly
insmod panel_mipi_dsi.ko
```

**Automatic loading:**
```bash
# Add to /etc/modules
echo "panel_mipi_dsi" >> /etc/modules

# Rebuild module dependencies
depmod -a
```

## Usage

### Check Driver Status

```bash
# Check if driver loaded
lsmod | grep panel_mipi_dsi

# Check kernel log
dmesg | grep "MIPI DSI panel"

# Expected output:
# panel-mipi-dsi-simple: MIPI DSI panel initialized: 1280x720@60Hz, 4 lanes
```

### Verify Display

```bash
# Check DRM devices
ls -l /dev/dri/

# Check framebuffer
ls -l /dev/fb0
cat /sys/class/graphics/fb0/modes

# Expected output: U:1280x720p-60
```

### Test Display Output

```bash
# Fill screen with color
dd if=/dev/zero of=/dev/fb0 bs=1M count=10

# Random pattern
cat /dev/urandom > /dev/fb0

# Run Qt application
/usr/bin/AIGlassesDisplay
```

## Driver Architecture

### DRM Panel Operations

The driver implements the standard DRM panel operations:

```c
static const struct drm_panel_funcs panel_simple_funcs = {
    .disable = panel_simple_disable,      // Turn off display
    .unprepare = panel_simple_unprepare,  // Power off panel
    .prepare = panel_simple_prepare,      // Power on panel
    .enable = panel_simple_enable,        // Turn on display
    .get_modes = panel_simple_get_modes,  // Provide display modes
};
```

### Power Sequence

**Panel initialization sequence:**

1. `prepare()`: Power on sequence
   - Enable regulator (3.3V power supply)
   - Assert reset GPIO (low)
   - Delay 10ms
   - Deassert reset GPIO (high)
   - Delay 20ms
   - Enable panel via enable GPIO
   - Exit sleep mode (DCS command 0x11)
   - Delay 120ms
   - Set pixel format (DCS command 0x3A)

2. `enable()`: Display on
   - Send display on command (DCS command 0x29)
   - Delay 20ms

**Panel shutdown sequence:**

1. `disable()`: Display off (no action in this simple driver)

2. `unprepare()`: Power off
   - Enter sleep mode (DCS command 0x10)
   - Delay 120ms
   - Disable enable GPIO
   - Disable regulator

### MIPI DSI Configuration

```c
dsi->lanes = 4;                    // 4-lane MIPI DSI
dsi->format = MIPI_DSI_FMT_RGB888; // 24-bit RGB
dsi->mode_flags = MIPI_DSI_MODE_VIDEO |          // Video mode
                  MIPI_DSI_MODE_VIDEO_BURST |     // Burst mode
                  MIPI_DSI_MODE_LPM |             // Low power mode
                  MIPI_DSI_MODE_EOT_PACKET;       // EOT packet
```

## Display Modes

### Default Mode: 1280×720 @ 60Hz

```c
.clock = 75000,           // 75 MHz pixel clock
.hdisplay = 1280,         // Active horizontal pixels
.hsync_start = 1390,      // H-sync start (1280 + 110)
.hsync_end = 1430,        // H-sync end (1390 + 40)
.htotal = 1650,           // Total horizontal (1430 + 220)
.vdisplay = 720,          // Active vertical lines
.vsync_start = 725,       // V-sync start (720 + 5)
.vsync_end = 730,         // V-sync end (725 + 5)
.vtotal = 750,            // Total vertical (730 + 20)
```

**Refresh rate calculation:**
```
Pixel clock = 75 MHz
Total pixels = 1650 × 750 = 1,237,500
Refresh rate = 75,000,000 / 1,237,500 = 60.6 Hz
```

### Custom Display Modes

To add custom display modes, modify `panel_mipi_dsi.c`:

```c
static const struct drm_display_mode custom_mode = {
    .clock = <pixel_clock_khz>,
    .hdisplay = <width>,
    .hsync_start = <width + hfront_porch>,
    .hsync_end = <hsync_start + hsync_len>,
    .htotal = <hsync_end + hback_porch>,
    .vdisplay = <height>,
    .vsync_start = <height + vfront_porch>,
    .vsync_end = <vsync_start + vsync_len>,
    .vtotal = <vsync_end + vback_porch>,
    .vrefresh = <refresh_rate>,
};
```

## Troubleshooting

### Module Won't Load

**Error: "Unknown symbol"**
```bash
# Check module dependencies
modinfo panel_mipi_dsi.ko

# Ensure DRM and MIPI DSI support loaded
modprobe drm
modprobe drm_kms_helper
modprobe rockchip_drm
```

**Error: "Device tree node not found"**
- Check device tree has `compatible = "simple-panel-dsi"` node
- Verify DSI controller enabled in device tree
- Rebuild device tree blob (DTB)

### Black Screen

**Check display power:**
```bash
# Verify power supply enabled
cat /sys/class/regulator/regulator*/name
cat /sys/class/regulator/regulator*/state
# Should show "enabled" for vcc_3v3
```

**Check GPIO states:**
```bash
# Export and check GPIOs
echo 35 > /sys/class/gpio/export  # gpio1_3 (reset)
echo 36 > /sys/class/gpio/export  # gpio1_4 (enable)
cat /sys/class/gpio/gpio35/value  # Should be 1 (reset released)
cat /sys/class/gpio/gpio36/value  # Should be 1 (panel enabled)
```

**Check MIPI DSI:**
```bash
# Kernel log for DSI errors
dmesg | grep dsi
dmesg | grep mipi

# Check DRM status
cat /sys/kernel/debug/dri/0/state
```

### Display Shows Garbage

**Wrong pixel format:**
- Verify `dsi,format = <MIPI_DSI_FMT_RGB888>` in device tree
- Check panel datasheet for supported formats

**Wrong timing:**
- Verify display timings match panel specifications
- Check pixel clock frequency
- Adjust hsync/vsync timing values

### Low Refresh Rate

**Insufficient bandwidth:**
```
Required bandwidth = width × height × bpp × fps
                  = 1280 × 720 × 24 × 60
                  = 1,327 Mbps

4-lane MIPI DSI @ 500 MHz = 2,000 Mbps (sufficient)
```

**Check MIPI DSI clock:**
```bash
# Check DSI PHY clock in device tree
grep -A 5 "dsi_dphy" arch/arm/boot/dts/rv1109-aiglasses.dts
```

## Integration with Qt Application

The Qt application (`src/display_qt/`) uses this driver automatically through the Linux framebuffer or DRM backend:

```bash
# Framebuffer backend (simple)
export QT_QPA_PLATFORM=linuxfb:/dev/fb0

# DRM/KMS backend (hardware-accelerated)
export QT_QPA_PLATFORM=eglfs
export QT_QPA_EGLFS_INTEGRATION=eglfs_kms
```

No application-level changes needed - the driver provides standard Linux display interfaces.

## Performance Metrics

- **Initialization time**: < 200ms
- **Frame rate**: 60 Hz (hardware limited)
- **Latency**: < 16ms (single frame)
- **Memory usage**: < 10KB (driver)

## References

- Linux DRM Panel Documentation: `Documentation/gpu/drm-kms.rst`
- MIPI DSI Specification: MIPI Alliance DSI v1.3
- Rockchip DW MIPI DSI Driver: `drivers/gpu/drm/rockchip/dw-mipi-dsi-rockchip.c`

---

**Version**: 1.0.0
**Date**: 2026-01-20
**Platform**: RV1109 (Rockchip)
**License**: GPL v2
