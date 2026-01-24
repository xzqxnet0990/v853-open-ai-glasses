/**
 * @file ui_settings.c
 * Settings Screen Implementation
 */

#include "ui_settings.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/sysinfo.h>

/* ============================================================================
 * Private Variables
 * ============================================================================ */

static lv_obj_t *screen = NULL;
static lv_obj_t *label_title = NULL;
static lv_obj_t *label_wifi = NULL;
static lv_obj_t *label_time = NULL;
static lv_obj_t *label_uptime = NULL;
static lv_obj_t *label_memory = NULL;

/* ============================================================================
 * Public Function Implementations
 * ============================================================================ */

/**
 * Create settings screen
 */
lv_obj_t *ui_settings_create(void)
{
    /* Create screen */
    screen = lv_obj_create(NULL);
    if (!screen) {
        fprintf(stderr, "[UI Settings] Error: Failed to create screen\n");
        return NULL;
    }

    /* Set screen background color */
    lv_obj_set_style_bg_color(screen, lv_color_hex(0x000000), 0);

    /* Create title label */
    label_title = lv_label_create(screen);
    lv_label_set_text(label_title, "System Settings");
    lv_obj_set_style_text_font(label_title, &lv_font_montserrat_24, 0);
    lv_obj_set_style_text_color(label_title, lv_color_hex(0xFFFFFF), 0);
    lv_obj_align(label_title, LV_ALIGN_TOP_MID, 0, 20);

    /* Create WiFi status label */
    label_wifi = lv_label_create(screen);
    lv_label_set_text(label_wifi, "WiFi: Checking...");
    lv_obj_set_style_text_font(label_wifi, &lv_font_montserrat_16, 0);
    lv_obj_set_style_text_color(label_wifi, lv_color_hex(0xCCCCCC), 0);
    lv_obj_align(label_wifi, LV_ALIGN_CENTER, 0, -60);

    /* Create time label */
    label_time = lv_label_create(screen);
    lv_label_set_text(label_time, "Time: --:--:--");
    lv_obj_set_style_text_font(label_time, &lv_font_montserrat_16, 0);
    lv_obj_set_style_text_color(label_time, lv_color_hex(0xCCCCCC), 0);
    lv_obj_align(label_time, LV_ALIGN_CENTER, 0, -20);

    /* Create uptime label */
    label_uptime = lv_label_create(screen);
    lv_label_set_text(label_uptime, "Uptime: --");
    lv_obj_set_style_text_font(label_uptime, &lv_font_montserrat_16, 0);
    lv_obj_set_style_text_color(label_uptime, lv_color_hex(0xCCCCCC), 0);
    lv_obj_align(label_uptime, LV_ALIGN_CENTER, 0, 20);

    /* Create memory usage label */
    label_memory = lv_label_create(screen);
    lv_label_set_text(label_memory, "Memory: -- MB / -- MB");
    lv_obj_set_style_text_font(label_memory, &lv_font_montserrat_16, 0);
    lv_obj_set_style_text_color(label_memory, lv_color_hex(0xCCCCCC), 0);
    lv_obj_align(label_memory, LV_ALIGN_CENTER, 0, 60);

    /* Initial update */
    ui_settings_update();

    printf("[UI Settings] Settings screen created\n");
    return screen;
}

/**
 * Update settings information
 */
void ui_settings_update(void)
{
    if (!screen) return;

    /* Update current time */
    time_t now = time(NULL);
    struct tm *tm_info = localtime(&now);
    char time_buf[32];
    strftime(time_buf, sizeof(time_buf), "Time: %H:%M:%S", tm_info);
    lv_label_set_text(label_time, time_buf);

    /* Update system uptime */
    struct sysinfo si;
    if (sysinfo(&si) == 0) {
        int hours = si.uptime / 3600;
        int minutes = (si.uptime % 3600) / 60;
        char uptime_buf[64];
        snprintf(uptime_buf, sizeof(uptime_buf), "Uptime: %dh %dm", hours, minutes);
        lv_label_set_text(label_uptime, uptime_buf);

        /* Update memory usage */
        unsigned long total_mb = si.totalram / (1024 * 1024);
        unsigned long used_mb = (si.totalram - si.freeram) / (1024 * 1024);
        char mem_buf[64];
        snprintf(mem_buf, sizeof(mem_buf), "Memory: %lu MB / %lu MB", used_mb, total_mb);
        lv_label_set_text(label_memory, mem_buf);
    }

    /* TODO: Check WiFi status */
    lv_label_set_text(label_wifi, "WiFi: Not configured");
}
