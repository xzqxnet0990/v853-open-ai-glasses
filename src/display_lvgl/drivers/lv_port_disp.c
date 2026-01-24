/**
 * @file lv_port_disp.c
 * Display Driver Implementation for V853 Framebuffer
 */

#include "lv_port_disp.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <linux/fb.h>
#include <errno.h>

/* ============================================================================
 * Private Variables
 * ============================================================================ */

static int fb_fd = -1;                      /* Framebuffer file descriptor */
static struct fb_var_screeninfo vinfo;      /* Variable screen info */
static struct fb_fix_screeninfo finfo;      /* Fixed screen info */
static uint8_t *fb_mem = NULL;              /* Mapped framebuffer memory */
static size_t fb_size = 0;                  /* Framebuffer size in bytes */

static lv_disp_drv_t disp_drv;              /* LVGL display driver */
static lv_disp_draw_buf_t disp_buf;         /* LVGL display buffer */
static lv_color_t *buf1 = NULL;             /* Display buffer 1 */
static lv_color_t *buf2 = NULL;             /* Display buffer 2 (for double buffering) */

/* Framebuffer device path */
#define FB_DEVICE "/dev/fb0"

/* Buffer size (1/10 of screen for memory efficiency) */
#define BUFFER_DIVISOR 10

/* ============================================================================
 * Private Function Prototypes
 * ============================================================================ */

static void disp_flush(lv_disp_drv_t *disp_drv, const lv_area_t *area, lv_color_t *color_p);

/* ============================================================================
 * Public Function Implementations
 * ============================================================================ */

/**
 * Initialize framebuffer display driver
 */
int lv_port_disp_init(void)
{
    /* Open framebuffer device */
    fb_fd = open(FB_DEVICE, O_RDWR);
    if (fb_fd < 0) {
        perror("Error opening framebuffer device");
        return -1;
    }

    /* Get fixed screen information */
    if (ioctl(fb_fd, FBIOGET_FSCREENINFO, &finfo) < 0) {
        perror("Error reading fixed screen information");
        close(fb_fd);
        return -1;
    }

    /* Get variable screen information */
    if (ioctl(fb_fd, FBIOGET_VSCREENINFO, &vinfo) < 0) {
        perror("Error reading variable screen information");
        close(fb_fd);
        return -1;
    }

    /* Calculate framebuffer size */
    fb_size = vinfo.xres * vinfo.yres * vinfo.bits_per_pixel / 8;

    /* Map framebuffer to memory */
    fb_mem = (uint8_t *)mmap(NULL, fb_size, PROT_READ | PROT_WRITE, MAP_SHARED, fb_fd, 0);
    if (fb_mem == MAP_FAILED) {
        perror("Error mapping framebuffer memory");
        close(fb_fd);
        return -1;
    }

    printf("[Display] Framebuffer initialized:\n");
    printf("  Resolution: %dx%d\n", vinfo.xres, vinfo.yres);
    printf("  BPP: %d\n", vinfo.bits_per_pixel);
    printf("  Size: %zu bytes\n", fb_size);

    /* Verify color depth matches LVGL configuration */
    if (vinfo.bits_per_pixel != (LV_COLOR_DEPTH == 1 ? 8 : LV_COLOR_DEPTH)) {
        printf("[Display] Warning: Framebuffer BPP (%d) doesn't match LV_COLOR_DEPTH (%d)\n",
               vinfo.bits_per_pixel, LV_COLOR_DEPTH);
    }

    /* Allocate LVGL display buffers */
    uint32_t buf_size = vinfo.xres * vinfo.yres / BUFFER_DIVISOR;
    buf1 = (lv_color_t *)malloc(buf_size * sizeof(lv_color_t));
    buf2 = (lv_color_t *)malloc(buf_size * sizeof(lv_color_t));

    if (!buf1 || !buf2) {
        fprintf(stderr, "[Display] Error: Failed to allocate display buffers\n");
        if (buf1) free(buf1);
        if (buf2) free(buf2);
        munmap(fb_mem, fb_size);
        close(fb_fd);
        return -1;
    }

    printf("[Display] Allocated buffers: %u pixels each\n", buf_size);

    /* Initialize LVGL display buffer */
    lv_disp_draw_buf_init(&disp_buf, buf1, buf2, buf_size);

    /* Initialize LVGL display driver */
    lv_disp_drv_init(&disp_drv);
    disp_drv.draw_buf = &disp_buf;
    disp_drv.flush_cb = disp_flush;
    disp_drv.hor_res = vinfo.xres;
    disp_drv.ver_res = vinfo.yres;

    /* Register display driver */
    lv_disp_t *disp = lv_disp_drv_register(&disp_drv);
    if (!disp) {
        fprintf(stderr, "[Display] Error: Failed to register display driver\n");
        free(buf1);
        free(buf2);
        munmap(fb_mem, fb_size);
        close(fb_fd);
        return -1;
    }

    printf("[Display] LVGL display driver registered successfully\n");
    return 0;
}

/**
 * Deinitialize display driver
 */
void lv_port_disp_deinit(void)
{
    /* Free display buffers */
    if (buf1) {
        free(buf1);
        buf1 = NULL;
    }
    if (buf2) {
        free(buf2);
        buf2 = NULL;
    }

    /* Unmap framebuffer */
    if (fb_mem && fb_mem != MAP_FAILED) {
        munmap(fb_mem, fb_size);
        fb_mem = NULL;
    }

    /* Close framebuffer device */
    if (fb_fd >= 0) {
        close(fb_fd);
        fb_fd = -1;
    }

    printf("[Display] Display driver deinitialized\n");
}

/**
 * Get display resolution
 */
void lv_port_disp_get_resolution(uint32_t *width, uint32_t *height)
{
    if (width) *width = vinfo.xres;
    if (height) *height = vinfo.yres;
}

/* ============================================================================
 * Private Function Implementations
 * ============================================================================ */

/**
 * LVGL flush callback - copy buffer to framebuffer
 */
static void disp_flush(lv_disp_drv_t *disp_drv, const lv_area_t *area, lv_color_t *color_p)
{
    if (!fb_mem) {
        lv_disp_flush_ready(disp_drv);
        return;
    }

    /* Copy pixel data to framebuffer */
    int32_t x, y;
    for (y = area->y1; y <= area->y2; y++) {
        for (x = area->x1; x <= area->x2; x++) {
            /* Calculate framebuffer offset */
            uint32_t fb_offset = (y * vinfo.xres + x) * (vinfo.bits_per_pixel / 8);

            /* Get source color */
            lv_color_t c = *color_p++;

            /* Write pixel to framebuffer based on bit depth */
            if (vinfo.bits_per_pixel == 32) {
                /* 32-bit ARGB8888 */
                uint32_t *pixel = (uint32_t *)(fb_mem + fb_offset);
                *pixel = (0xFF << 24) |           /* Alpha */
                         (c.ch.red << 16) |       /* Red */
                         (c.ch.green << 8) |      /* Green */
                         (c.ch.blue);             /* Blue */
            }
            else if (vinfo.bits_per_pixel == 16) {
                /* 16-bit RGB565 */
                uint16_t *pixel = (uint16_t *)(fb_mem + fb_offset);
                *pixel = ((c.ch.red >> 3) << 11) |
                         ((c.ch.green >> 2) << 5) |
                         (c.ch.blue >> 3);
            }
            /* Add other formats if needed */
        }
    }

    /* Inform LVGL that flushing is done */
    lv_disp_flush_ready(disp_drv);
}
