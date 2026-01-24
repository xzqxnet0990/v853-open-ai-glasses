/**
 * @file lv_port_disp.h
 * Display Port for LVGL on V853 Framebuffer
 *
 * This module provides the display driver interface for LVGL
 * using Linux framebuffer (/dev/fb0).
 */

#ifndef LV_PORT_DISP_H
#define LV_PORT_DISP_H

#ifdef __cplusplus
extern "C" {
#endif

#include "lvgl.h"

/**
 * Initialize the display driver
 * - Opens /dev/fb0
 * - Detects resolution and color format
 * - Allocates display buffers
 * - Registers LVGL display driver
 *
 * @return 0 on success, -1 on failure
 */
int lv_port_disp_init(void);

/**
 * Deinitialize the display driver
 * - Closes framebuffer
 * - Frees allocated buffers
 */
void lv_port_disp_deinit(void);

/**
 * Get current display resolution
 * @param width Output: display width in pixels
 * @param height Output: display height in pixels
 */
void lv_port_disp_get_resolution(uint32_t *width, uint32_t *height);

#ifdef __cplusplus
}
#endif

#endif /* LV_PORT_DISP_H */
