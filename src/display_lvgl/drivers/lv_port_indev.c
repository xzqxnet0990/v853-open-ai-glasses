/**
 * @file lv_port_indev.c
 * Input Device Driver Implementation for V853 GPIO Buttons
 */

#include "lv_port_indev.h"
#include "ai_gpio.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

/* ============================================================================
 * Private Variables
 * ============================================================================ */

static lv_indev_drv_t indev_drv;            /* LVGL input device driver */
static gpio_event_client_t *gpio_client = NULL;
static lv_indev_data_t last_data;           /* Last input state */
static bool button_pressed = false;
static uint32_t last_key = 0;

/* GPIO button numbers (configure based on hardware) */
#define GPIO_BUTTON_LEFT  1    /* Left temple button */
#define GPIO_BUTTON_RIGHT 2    /* Right temple button */

/* LVGL key codes */
#define LV_KEY_LEFT  LV_KEY_PREV
#define LV_KEY_RIGHT LV_KEY_NEXT

/* ============================================================================
 * Private Function Prototypes
 * ============================================================================ */

static void indev_read(lv_indev_drv_t *indev_drv, lv_indev_data_t *data);
static void gpio_button_callback(gpio_event_t event_type, int gpio_number, void *user_data);

/* ============================================================================
 * Public Function Implementations
 * ============================================================================ */

/**
 * Initialize input device driver
 */
int lv_port_indev_init(void)
{
    /* Initialize AI GPIO client */
    gpio_client = ai_gpio_event_client_subscribe(GPIO_BUTTON_LEFT, gpio_button_callback, NULL);
    if (!gpio_client) {
        fprintf(stderr, "[Input] Error: Failed to subscribe to GPIO %d\n", GPIO_BUTTON_LEFT);
        return -1;
    }

    printf("[Input] Subscribed to GPIO %d (left button)\n", GPIO_BUTTON_LEFT);

    /* Subscribe to right button if available */
    /* Note: gpio_event_subscribe may only support one GPIO at a time */
    /* For multiple buttons, may need to spawn separate thread or modify SDK */

    /* Initialize LVGL input device driver */
    lv_indev_drv_init(&indev_drv);
    indev_drv.type = LV_INDEV_TYPE_KEYPAD;
    indev_drv.read_cb = indev_read;

    /* Register input device */
    lv_indev_t *indev = lv_indev_drv_register(&indev_drv);
    if (!indev) {
        fprintf(stderr, "[Input] Error: Failed to register input device\n");
        ai_gpio_event_client_unsubscribe(gpio_client);
        return -1;
    }

    /* Initialize last data */
    last_data.key = 0;
    last_data.state = LV_INDEV_STATE_RELEASED;

    printf("[Input] LVGL input device registered successfully\n");
    return 0;
}

/**
 * Deinitialize input device driver
 */
void lv_port_indev_deinit(void)
{
    /* Unsubscribe from GPIO events */
    if (gpio_client) {
        ai_gpio_event_client_unsubscribe(gpio_client);
        gpio_client = NULL;
    }

    printf("[Input] Input device driver deinitialized\n");
}

/* ============================================================================
 * Private Function Implementations
 * ============================================================================ */

/**
 * LVGL input read callback
 */
static void indev_read(lv_indev_drv_t *indev_drv, lv_indev_data_t *data)
{
    (void)indev_drv; /* Unused */

    /* Copy last input state */
    data->key = last_data.key;
    data->state = last_data.state;

    /* If button was pressed and reported, mark as released */
    if (button_pressed && last_data.state == LV_INDEV_STATE_PRESSED) {
        last_data.state = LV_INDEV_STATE_RELEASED;
        button_pressed = false;
    }
}

/**
 * GPIO button event callback (from AI Glass SDK)
 */
static void gpio_button_callback(gpio_event_t event_type, int gpio_number, void *user_data)
{
    (void)user_data; /* Unused */

    if (event_type == GPIO_EVENT_PRESS) {
        /* Map GPIO number to LVGL key code */
        if (gpio_number == GPIO_BUTTON_LEFT) {
            last_key = LV_KEY_LEFT;
        } else if (gpio_number == GPIO_BUTTON_RIGHT) {
            last_key = LV_KEY_RIGHT;
        } else {
            return; /* Unknown button */
        }

        /* Update input state */
        last_data.key = last_key;
        last_data.state = LV_INDEV_STATE_PRESSED;
        button_pressed = true;

        printf("[Input] Button %d pressed (key=%u)\n", gpio_number, last_key);
    }
    else if (event_type == GPIO_EVENT_RELEASE) {
        /* Button released */
        last_data.state = LV_INDEV_STATE_RELEASED;
        printf("[Input] Button %d released\n", gpio_number);
    }
}
