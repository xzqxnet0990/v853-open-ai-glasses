/**
 * @file ui_battery.c
 * Battery Status Screen Implementation
 */

#include "ui_battery.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* ============================================================================
 * Private Variables
 * ============================================================================ */

static lv_obj_t *screen = NULL;
static lv_obj_t *label_title = NULL;
static lv_obj_t *label_percentage = NULL;
static lv_obj_t *label_voltage = NULL;
static lv_obj_t *label_status = NULL;
static lv_obj_t *bar_battery = NULL;

/* Battery status paths */
#define BATTERY_CAPACITY_PATH "/sys/class/power_supply/rk817-battery/capacity"
#define BATTERY_VOLTAGE_PATH  "/sys/class/power_supply/rk817-battery/voltage_now"
#define BATTERY_STATUS_PATH   "/sys/class/power_supply/rk817-battery/status"

/* ============================================================================
 * Private Function Prototypes
 * ============================================================================ */

static int read_battery_capacity(void);
static int read_battery_voltage(void);
static const char *read_battery_status(void);

/* ============================================================================
 * Public Function Implementations
 * ============================================================================ */

/**
 * Create battery status screen
 */
lv_obj_t *ui_battery_create(void)
{
    /* Create screen */
    screen = lv_obj_create(NULL);
    if (!screen) {
        fprintf(stderr, "[UI Battery] Error: Failed to create screen\n");
        return NULL;
    }

    /* Set screen background color */
    lv_obj_set_style_bg_color(screen, lv_color_hex(0x000000), 0);

    /* Create title label */
    label_title = lv_label_create(screen);
    lv_label_set_text(label_title, "Battery Status");
    lv_obj_set_style_text_font(label_title, &lv_font_montserrat_24, 0);
    lv_obj_set_style_text_color(label_title, lv_color_hex(0xFFFFFF), 0);
    lv_obj_align(label_title, LV_ALIGN_TOP_MID, 0, 20);

    /* Create battery percentage label */
    label_percentage = lv_label_create(screen);
    lv_label_set_text(label_percentage, "---%");
    lv_obj_set_style_text_font(label_percentage, &lv_font_montserrat_48, 0);
    lv_obj_set_style_text_color(label_percentage, lv_color_hex(0x00FF00), 0);
    lv_obj_align(label_percentage, LV_ALIGN_CENTER, 0, -40);

    /* Create battery progress bar */
    bar_battery = lv_bar_create(screen);
    lv_obj_set_size(bar_battery, 300, 30);
    lv_obj_align(bar_battery, LV_ALIGN_CENTER, 0, 20);
    lv_bar_set_value(bar_battery, 0, LV_ANIM_OFF);
    lv_obj_set_style_bg_color(bar_battery, lv_color_hex(0x333333), LV_PART_MAIN);
    lv_obj_set_style_bg_color(bar_battery, lv_color_hex(0x00FF00), LV_PART_INDICATOR);

    /* Create voltage label */
    label_voltage = lv_label_create(screen);
    lv_label_set_text(label_voltage, "Voltage: -.-- V");
    lv_obj_set_style_text_font(label_voltage, &lv_font_montserrat_16, 0);
    lv_obj_set_style_text_color(label_voltage, lv_color_hex(0xCCCCCC), 0);
    lv_obj_align(label_voltage, LV_ALIGN_CENTER, 0, 70);

    /* Create status label */
    label_status = lv_label_create(screen);
    lv_label_set_text(label_status, "Status: Unknown");
    lv_obj_set_style_text_font(label_status, &lv_font_montserrat_16, 0);
    lv_obj_set_style_text_color(label_status, lv_color_hex(0xCCCCCC), 0);
    lv_obj_align(label_status, LV_ALIGN_CENTER, 0, 100);

    /* Create instruction label */
    lv_obj_t *label_help = lv_label_create(screen);
    lv_label_set_text(label_help, "Press LEFT/RIGHT to switch screens");
    lv_obj_set_style_text_font(label_help, &lv_font_montserrat_12, 0);
    lv_obj_set_style_text_color(label_help, lv_color_hex(0x888888), 0);
    lv_obj_align(label_help, LV_ALIGN_BOTTOM_MID, 0, -20);

    /* Initial update */
    ui_battery_update();

    printf("[UI Battery] Battery screen created\n");
    return screen;
}

/**
 * Update battery information
 */
void ui_battery_update(void)
{
    if (!screen) return;

    /* Read battery capacity */
    int capacity = read_battery_capacity();
    if (capacity >= 0) {
        char buf[32];
        snprintf(buf, sizeof(buf), "%d%%", capacity);
        lv_label_set_text(label_percentage, buf);
        lv_bar_set_value(bar_battery, capacity, LV_ANIM_ON);

        /* Change color based on capacity */
        if (capacity > 50) {
            lv_obj_set_style_text_color(label_percentage, lv_color_hex(0x00FF00), 0);
            lv_obj_set_style_bg_color(bar_battery, lv_color_hex(0x00FF00), LV_PART_INDICATOR);
        } else if (capacity > 20) {
            lv_obj_set_style_text_color(label_percentage, lv_color_hex(0xFFFF00), 0);
            lv_obj_set_style_bg_color(bar_battery, lv_color_hex(0xFFFF00), LV_PART_INDICATOR);
        } else {
            lv_obj_set_style_text_color(label_percentage, lv_color_hex(0xFF0000), 0);
            lv_obj_set_style_bg_color(bar_battery, lv_color_hex(0xFF0000), LV_PART_INDICATOR);
        }
    }

    /* Read battery voltage */
    int voltage_uv = read_battery_voltage();
    if (voltage_uv > 0) {
        char buf[32];
        float voltage_v = voltage_uv / 1000000.0f;
        snprintf(buf, sizeof(buf), "Voltage: %.2f V", voltage_v);
        lv_label_set_text(label_voltage, buf);
    }

    /* Read battery status */
    const char *status = read_battery_status();
    if (status) {
        char buf[64];
        snprintf(buf, sizeof(buf), "Status: %s", status);
        lv_label_set_text(label_status, buf);
    }
}

/* ============================================================================
 * Private Function Implementations
 * ============================================================================ */

/**
 * Read battery capacity from sysfs
 */
static int read_battery_capacity(void)
{
    FILE *fp = fopen(BATTERY_CAPACITY_PATH, "r");
    if (!fp) {
        return -1;
    }

    int capacity = -1;
    fscanf(fp, "%d", &capacity);
    fclose(fp);

    return capacity;
}

/**
 * Read battery voltage from sysfs (in microvolts)
 */
static int read_battery_voltage(void)
{
    FILE *fp = fopen(BATTERY_VOLTAGE_PATH, "r");
    if (!fp) {
        return -1;
    }

    int voltage = -1;
    fscanf(fp, "%d", &voltage);
    fclose(fp);

    return voltage;
}

/**
 * Read battery status from sysfs
 */
static const char *read_battery_status(void)
{
    static char status[32] = {0};
    FILE *fp = fopen(BATTERY_STATUS_PATH, "r");
    if (!fp) {
        return "Unknown";
    }

    if (fgets(status, sizeof(status), fp)) {
        /* Remove trailing newline */
        size_t len = strlen(status);
        if (len > 0 && status[len-1] == '\n') {
            status[len-1] = '\0';
        }
    }

    fclose(fp);
    return status;
}
