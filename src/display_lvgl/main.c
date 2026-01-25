/**
 * @file main.c
 * AI Glasses LVGL Display Application - Main Entry Point
 *
 * Platform: V853 (Allwinner ARM Cortex-A7)
 * Display: Framebuffer (/dev/fb0)
 * UI Framework: LVGL 8.x
 *
 * Copyright (c) 2026 AI Glasses Project
 */

#include "lvgl.h"
#include "drivers/lv_port_disp.h"
#include "drivers/lv_port_indev.h"
#include "ui/ui_init.h"
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>
#include <sys/time.h>

/* ============================================================================
 * Configuration
 * ============================================================================ */

#define APP_NAME "AI Glasses LVGL Display"
#define APP_VERSION "1.0.0"
#define UI_UPDATE_PERIOD_MS 1000  /* Update UI every 1 second */

/* ============================================================================
 * Global Variables
 * ============================================================================ */

static volatile int running = 1;

/* ============================================================================
 * Signal Handler
 * ============================================================================ */

void signal_handler(int signum)
{
    printf("\n[Main] Received signal %d, shutting down gracefully...\n", signum);
    running = 0;
}

/* ============================================================================
 * Custom Tick Function for LVGL
 * ============================================================================ */

uint32_t custom_tick_get(void)
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (tv.tv_sec * 1000) + (tv.tv_usec / 1000);
}

/* ============================================================================
 * Main Function
 * ============================================================================ */

int main(int argc, char *argv[])
{
    (void)argc;
    (void)argv;

    printf("===========================================\n");
    printf("  %s v%s\n", APP_NAME, APP_VERSION);
    printf("  Platform: V853 (ARM Cortex-A7)\n");
    printf("  UI Framework: LVGL %d.%d.%d\n",
           LVGL_VERSION_MAJOR, LVGL_VERSION_MINOR, LVGL_VERSION_PATCH);
    printf("===========================================\n\n");

    /* Install signal handlers */
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    /* Initialize LVGL */
    printf("[Main] Initializing LVGL...\n");
    lv_init();

    /* Initialize display driver */
    printf("[Main] Initializing display driver...\n");
    if (lv_port_disp_init() != 0) {
        fprintf(stderr, "[Main] Error: Failed to initialize display driver\n");
        return -1;
    }

    uint32_t disp_width, disp_height;
    lv_port_disp_get_resolution(&disp_width, &disp_height);
    printf("[Main] Display resolution: %ux%u\n", disp_width, disp_height);

    /* Initialize input device driver */
    printf("[Main] Initializing input device driver...\n");
    printf("[Main] Warning: Input device initialization temporarily disabled\n");
    printf("[Main] Reason: GPIO event system not yet available on this hardware\n");
    /* TODO: Enable when GPIO event system is ready
    if (lv_port_indev_init() != 0) {
        fprintf(stderr, "[Main] Warning: Failed to initialize input device\n");
        // Continue without input - can still display UI
    }
    */

    /* Initialize UI */
    printf("[Main] Initializing user interface...\n");
    if (ui_init() != 0) {
        fprintf(stderr, "[Main] Error: Failed to initialize UI\n");
        lv_port_indev_deinit();
        lv_port_disp_deinit();
        return -1;
    }

    printf("\n[Main] Application started successfully!\n");
    printf("[Main] Press Ctrl+C to exit\n\n");

    /* Main event loop */
    uint32_t last_ui_update = 0;

    while (running) {
        /* Handle LVGL tasks */
        lv_timer_handler();

        /* Periodic UI update */
        uint32_t now = custom_tick_get();
        if (now - last_ui_update >= UI_UPDATE_PERIOD_MS) {
            /* Update current screen */
            screen_id_t current = ui_get_current_screen();
            switch (current) {
                case SCREEN_BATTERY:
                    ui_battery_update();
                    break;
                case SCREEN_CAMERA:
                    ui_camera_update();
                    break;
                case SCREEN_SETTINGS:
                    ui_settings_update();
                    break;
                default:
                    break;
            }
            last_ui_update = now;
        }

        /* Small delay to prevent busy loop */
        usleep(5000); /* 5ms = 200 FPS max */
    }

    /* Cleanup */
    printf("\n[Main] Cleaning up...\n");
    ui_deinit();
    lv_port_indev_deinit();
    lv_port_disp_deinit();

    printf("[Main] Application exited successfully\n");
    return 0;
}
