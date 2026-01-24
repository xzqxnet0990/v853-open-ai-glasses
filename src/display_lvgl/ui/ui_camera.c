/**
 * @file ui_camera.c
 * Camera Preview Screen Implementation
 */

#include "ui_camera.h"
#include "ai_camera.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ============================================================================
 * Private Variables
 * ============================================================================ */

static lv_obj_t *screen = NULL;
static lv_obj_t *label_title = NULL;
static lv_obj_t *img_camera = NULL;
static lv_obj_t *label_info = NULL;
static ai_core_client_t *camera_client = NULL;

/* ============================================================================
 * Public Function Implementations
 * ============================================================================ */

/**
 * Create camera preview screen
 */
lv_obj_t *ui_camera_create(void)
{
    /* Create screen */
    screen = lv_obj_create(NULL);
    if (!screen) {
        fprintf(stderr, "[UI Camera] Error: Failed to create screen\n");
        return NULL;
    }

    /* Set screen background color */
    lv_obj_set_style_bg_color(screen, lv_color_hex(0x000000), 0);

    /* Create title label */
    label_title = lv_label_create(screen);
    lv_label_set_text(label_title, "Camera Preview");
    lv_obj_set_style_text_font(label_title, &lv_font_montserrat_24, 0);
    lv_obj_set_style_text_color(label_title, lv_color_hex(0xFFFFFF), 0);
    lv_obj_align(label_title, LV_ALIGN_TOP_MID, 0, 20);

    /* Create camera image placeholder */
    img_camera = lv_img_create(screen);
    lv_obj_align(img_camera, LV_ALIGN_CENTER, 0, 0);

    /* Create camera info label */
    label_info = lv_label_create(screen);
    lv_label_set_text(label_info, "Initializing camera...");
    lv_obj_set_style_text_font(label_info, &lv_font_montserrat_14, 0);
    lv_obj_set_style_text_color(label_info, lv_color_hex(0xCCCCCC), 0);
    lv_obj_align(label_info, LV_ALIGN_BOTTOM_MID, 0, -20);

    /* Initialize AI Camera SDK */
    camera_client = ai_core_init();
    if (!camera_client) {
        fprintf(stderr, "[UI Camera] Warning: Failed to initialize camera SDK\n");
        lv_label_set_text(label_info, "Camera unavailable");
    } else {
        lv_label_set_text(label_info, "Camera ready - Capturing...");
    }

    printf("[UI Camera] Camera screen created\n");
    return screen;
}

/**
 * Update camera preview
 */
void ui_camera_update(void)
{
    if (!screen || !camera_client) return;

    /* Capture frame from camera */
    ai_core_data_t camera_data;
    int ret = ai_core_capture(camera_client, &camera_data, 100);

    if (ret == AI_MEDIA_SUCCESS) {
        /* Update info */
        char buf[128];
        snprintf(buf, sizeof(buf), "Resolution: %dx%d | Format: %s | Size: %zu bytes",
                 camera_data.width, camera_data.height,
                 camera_data.format == AI_MEDIA_FORMAT_JPEG ? "JPEG" : "NV12",
                 camera_data.size);
        lv_label_set_text(label_info, buf);

        /* TODO: Convert camera_data to LVGL image and display */
        /* This requires implementing image decoder for JPEG/NV12 */
        /* For now, just update the info */

        /* Free camera data */
        ai_core_free_data(&camera_data);
    } else {
        lv_label_set_text(label_info, "Camera capture failed");
    }
}
