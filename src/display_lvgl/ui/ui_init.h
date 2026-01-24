/**
 * @file ui_init.h
 * UI Initialization and Screen Management
 */

#ifndef UI_INIT_H
#define UI_INIT_H

#ifdef __cplusplus
extern "C" {
#endif

#include "lvgl.h"

/* Screen IDs */
typedef enum {
    SCREEN_BATTERY = 0,
    SCREEN_CAMERA,
    SCREEN_SETTINGS,
    SCREEN_COUNT
} screen_id_t;

/**
 * Initialize all UI screens
 * @return 0 on success, -1 on failure
 */
int ui_init(void);

/**
 * Deinitialize UI
 */
void ui_deinit(void);

/**
 * Switch to a specific screen
 * @param screen Screen ID to switch to
 */
void ui_switch_screen(screen_id_t screen);

/**
 * Get current screen ID
 * @return Current screen ID
 */
screen_id_t ui_get_current_screen(void);

/**
 * Switch to next screen (circular)
 */
void ui_next_screen(void);

/**
 * Switch to previous screen (circular)
 */
void ui_prev_screen(void);

#ifdef __cplusplus
}
#endif

#endif /* UI_INIT_H */
