/**
 * @file ui_battery.h
 * Battery Status Screen
 */

#ifndef UI_BATTERY_H
#define UI_BATTERY_H

#ifdef __cplusplus
extern "C" {
#endif

#include "lvgl.h"

/**
 * Create battery status screen
 * @return Screen object, or NULL on failure
 */
lv_obj_t *ui_battery_create(void);

/**
 * Update battery information
 * Called periodically to refresh battery status
 */
void ui_battery_update(void);

#ifdef __cplusplus
}
#endif

#endif /* UI_BATTERY_H */
