/**
 * @file ui_camera.h
 * Camera Preview Screen
 */

#ifndef UI_CAMERA_H
#define UI_CAMERA_H

#ifdef __cplusplus
extern "C" {
#endif

#include "lvgl.h"

/**
 * Create camera preview screen
 * @return Screen object, or NULL on failure
 */
lv_obj_t *ui_camera_create(void);

/**
 * Update camera preview
 * Called periodically to refresh camera feed
 */
void ui_camera_update(void);

#ifdef __cplusplus
}
#endif

#endif /* UI_CAMERA_H */
