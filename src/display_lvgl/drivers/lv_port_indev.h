/**
 * @file lv_port_indev.h
 * Input Device Port for LVGL on V853 (GPIO Buttons)
 *
 * This module provides input device driver for LVGL using
 * GPIO buttons via AI Glass SDK.
 */

#ifndef LV_PORT_INDEV_H
#define LV_PORT_INDEV_H

#ifdef __cplusplus
extern "C" {
#endif

#include "lvgl.h"

/**
 * Initialize the input device driver
 * - Subscribes to GPIO button events via AI Glass SDK
 * - Registers LVGL input device driver
 *
 * @return 0 on success, -1 on failure
 */
int lv_port_indev_init(void);

/**
 * Deinitialize the input device driver
 * - Unsubscribes from GPIO events
 * - Cleans up resources
 */
void lv_port_indev_deinit(void);

#ifdef __cplusplus
}
#endif

#endif /* LV_PORT_INDEV_H */
