/**
 * @file ui_settings.h
 * Settings Screen
 */

#ifndef UI_SETTINGS_H
#define UI_SETTINGS_H

#ifdef __cplusplus
extern "C" {
#endif

#include "lvgl.h"

/**
 * Create settings screen
 * @return Screen object, or NULL on failure
 */
lv_obj_t *ui_settings_create(void);

/**
 * Update settings information
 * Called periodically to refresh system info
 */
void ui_settings_update(void);

#ifdef __cplusplus
}
#endif

#endif /* UI_SETTINGS_H */
