/**
 * @file ui_init.c
 * UI Initialization and Screen Management Implementation
 */

#include "ui_init.h"
#include "ui_battery.h"
#include "ui_camera.h"
#include "ui_settings.h"
#include <stdio.h>

/* ============================================================================
 * Private Variables
 * ============================================================================ */

static lv_obj_t *screens[SCREEN_COUNT] = {NULL};
static screen_id_t current_screen = SCREEN_BATTERY;

/* ============================================================================
 * Public Function Implementations
 * ============================================================================ */

/**
 * Initialize all UI screens
 */
int ui_init(void)
{
    printf("[UI] Initializing user interface...\n");

    /* Create and initialize battery screen */
    screens[SCREEN_BATTERY] = ui_battery_create();
    if (!screens[SCREEN_BATTERY]) {
        fprintf(stderr, "[UI] Error: Failed to create battery screen\n");
        return -1;
    }

    /* Create and initialize camera screen */
    screens[SCREEN_CAMERA] = ui_camera_create();
    if (!screens[SCREEN_CAMERA]) {
        fprintf(stderr, "[UI] Error: Failed to create camera screen\n");
        return -1;
    }

    /* Create and initialize settings screen */
    screens[SCREEN_SETTINGS] = ui_settings_create();
    if (!screens[SCREEN_SETTINGS]) {
        fprintf(stderr, "[UI] Error: Failed to create settings screen\n");
        return -1;
    }

    /* Load initial screen */
    ui_switch_screen(SCREEN_BATTERY);

    printf("[UI] UI initialized successfully\n");
    return 0;
}

/**
 * Deinitialize UI
 */
void ui_deinit(void)
{
    /* Delete all screens */
    for (int i = 0; i < SCREEN_COUNT; i++) {
        if (screens[i]) {
            lv_obj_del(screens[i]);
            screens[i] = NULL;
        }
    }

    printf("[UI] UI deinitialized\n");
}

/**
 * Switch to a specific screen
 */
void ui_switch_screen(screen_id_t screen)
{
    if (screen >= SCREEN_COUNT) {
        fprintf(stderr, "[UI] Error: Invalid screen ID %d\n", screen);
        return;
    }

    if (!screens[screen]) {
        fprintf(stderr, "[UI] Error: Screen %d not initialized\n", screen);
        return;
    }

    /* Load the new screen */
    lv_scr_load(screens[screen]);
    current_screen = screen;

    /* Update screen title */
    const char *titles[] = {"Battery Status", "Camera Preview", "Settings"};
    printf("[UI] Switched to screen: %s\n", titles[screen]);
}

/**
 * Get current screen ID
 */
screen_id_t ui_get_current_screen(void)
{
    return current_screen;
}

/**
 * Switch to next screen
 */
void ui_next_screen(void)
{
    screen_id_t next = (current_screen + 1) % SCREEN_COUNT;
    ui_switch_screen(next);
}

/**
 * Switch to previous screen
 */
void ui_prev_screen(void)
{
    screen_id_t prev = (current_screen - 1 + SCREEN_COUNT) % SCREEN_COUNT;
    ui_switch_screen(prev);
}
