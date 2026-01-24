/**
 * @file lv_conf.h
 * LVGL Configuration for V853 AI Glasses
 *
 * Optimized for:
 * - V853 SoC (ARM Cortex-A7, 1 TOPS NPU)
 * - Framebuffer display (/dev/fb0)
 * - 32-bit color depth
 * - Limited memory footprint
 */

#ifndef LV_CONF_H
#define LV_CONF_H

#include <stdint.h>

/* ============================================================================
 * COLOR SETTINGS
 * ============================================================================ */

/* Color depth: 32-bit ARGB8888 (match framebuffer) */
#define LV_COLOR_DEPTH 32

/* Swap RGB565 bytes (not used with 32-bit) */
#define LV_COLOR_16_SWAP 0

/* Screen transparency (disable for performance) */
#define LV_COLOR_SCREEN_TRANSP 0

/* Color mix rounding */
#define LV_COLOR_MIX_ROUND_OFS 0

/* Chroma key color */
#define LV_COLOR_CHROMA_KEY lv_color_hex(0x00ff00)

/* ============================================================================
 * MEMORY SETTINGS
 * ============================================================================ */

/* Use built-in memory allocator */
#define LV_MEM_CUSTOM 0

/* Memory pool size (256KB for embedded system) */
#define LV_MEM_SIZE (256U * 1024U)

/* Memory address (0 = use heap) */
#define LV_MEM_ADR 0

/* Number of intermediate buffers */
#define LV_MEM_BUF_MAX_NUM 16

/* Use standard memcpy/memset */
#define LV_MEMCPY_MEMSET_STD 1

/* ============================================================================
 * HAL SETTINGS
 * ============================================================================ */

/* Display refresh period (33ms = 30 FPS) */
#define LV_DISP_DEF_REFR_PERIOD 33

/* Input device read period (33ms) */
#define LV_INDEV_DEF_READ_PERIOD 33

/* Custom tick source */
#define LV_TICK_CUSTOM 1
#if LV_TICK_CUSTOM
    uint32_t custom_tick_get(void);
    #define LV_TICK_CUSTOM_INCLUDE <stdint.h>
    #define LV_TICK_CUSTOM_SYS_TIME_EXPR (custom_tick_get())
#endif

/* DPI (dots per inch) */
#define LV_DPI_DEF 130

/* ============================================================================
 * FEATURE CONFIGURATION
 * ============================================================================ */

/* Complex drawing (shadows, gradients, etc.) */
#define LV_DRAW_COMPLEX 1

/* Shadow cache size (disable for memory) */
#define LV_SHADOW_CACHE_SIZE 0

/* Circle cache size */
#define LV_CIRCLE_CACHE_SIZE 4

/* Image cache (disable for memory) */
#define LV_IMG_CACHE_DEF_SIZE 0

/* Rotation buffer */
#define LV_DISP_ROT_MAX_BUF (10*1024)

/* ============================================================================
 * GPU ACCELERATION (Disabled for V853)
 * ============================================================================ */

#define LV_USE_GPU_STM32_DMA2D 0
#define LV_USE_GPU_NXP_PXP 0
#define LV_USE_GPU_NXP_VG_LITE 0
#define LV_USE_GPU_SDL 0

/* ============================================================================
 * LOGGING
 * ============================================================================ */

#define LV_USE_LOG 1
#if LV_USE_LOG
    #define LV_LOG_LEVEL LV_LOG_LEVEL_INFO
    #define LV_LOG_PRINTF 1
#endif

/* ============================================================================
 * COMPILER SETTINGS
 * ============================================================================ */

#define LV_ATTRIBUTE_TICK_INC
#define LV_ATTRIBUTE_TIMER_HANDLER
#define LV_ATTRIBUTE_FLUSH_READY
#define LV_ATTRIBUTE_MEM_ALIGN
#define LV_ATTRIBUTE_IMG_DECODER
#define LV_ATTRIBUTE_LARGE_CONST
#define LV_ATTRIBUTE_FAST_MEM

/* ============================================================================
 * FONT SETTINGS
 * ============================================================================ */

/* Built-in fonts */
#define LV_FONT_MONTSERRAT_8  0
#define LV_FONT_MONTSERRAT_10 0
#define LV_FONT_MONTSERRAT_12 1
#define LV_FONT_MONTSERRAT_14 1
#define LV_FONT_MONTSERRAT_16 1
#define LV_FONT_MONTSERRAT_18 0
#define LV_FONT_MONTSERRAT_20 1
#define LV_FONT_MONTSERRAT_22 0
#define LV_FONT_MONTSERRAT_24 1
#define LV_FONT_MONTSERRAT_26 0
#define LV_FONT_MONTSERRAT_28 0
#define LV_FONT_MONTSERRAT_30 0
#define LV_FONT_MONTSERRAT_32 0
#define LV_FONT_MONTSERRAT_34 0
#define LV_FONT_MONTSERRAT_36 0
#define LV_FONT_MONTSERRAT_38 0
#define LV_FONT_MONTSERRAT_40 0
#define LV_FONT_MONTSERRAT_42 0
#define LV_FONT_MONTSERRAT_44 0
#define LV_FONT_MONTSERRAT_46 0
#define LV_FONT_MONTSERRAT_48 1  /* Enable 48pt font for battery percentage */

/* Unscii fonts (pixel perfect) */
#define LV_FONT_UNSCII_8  0
#define LV_FONT_UNSCII_16 0

/* Default font */
#define LV_FONT_DEFAULT &lv_font_montserrat_16

/* ============================================================================
 * TEXT SETTINGS
 * ============================================================================ */

/* Text encoding */
#define LV_TXT_ENC LV_TXT_ENC_UTF8

/* Line break algorithm */
#define LV_TXT_BREAK_CHARS " ,.;:-_"

/* Text selection (disable for performance) */
#define LV_TXT_SEL_DISABLED 0

/* ============================================================================
 * WIDGET USAGE
 * ============================================================================ */

#define LV_USE_ARC        1
#define LV_USE_BAR        1
#define LV_USE_BTN        1
#define LV_USE_BTNMATRIX  1
#define LV_USE_CANVAS     0  // Disable for memory
#define LV_USE_CHECKBOX   1
#define LV_USE_DROPDOWN   1
#define LV_USE_IMG        1
#define LV_USE_LABEL      1
#define LV_USE_LINE       1
#define LV_USE_ROLLER     1
#define LV_USE_SLIDER     1
#define LV_USE_SWITCH     1
#define LV_USE_TEXTAREA   1
#define LV_USE_TABLE      0  // Disable for memory

/* ============================================================================
 * EXTRA WIDGETS
 * ============================================================================ */

#define LV_USE_ANIMIMG    0
#define LV_USE_CALENDAR   0
#define LV_USE_CHART      1
#define LV_USE_COLORWHEEL 0
#define LV_USE_IMGBTN     1
#define LV_USE_KEYBOARD   0
#define LV_USE_LED        1
#define LV_USE_LIST       1
#define LV_USE_MENU       1
#define LV_USE_METER      1
#define LV_USE_MSGBOX     1
#define LV_USE_SPAN       0
#define LV_USE_SPINBOX    0
#define LV_USE_SPINNER    1
#define LV_USE_TABVIEW    1
#define LV_USE_TILEVIEW   1
#define LV_USE_WIN        1

/* ============================================================================
 * THEMES
 * ============================================================================ */

#define LV_USE_THEME_DEFAULT 1
#define LV_USE_THEME_BASIC   1
#define LV_USE_THEME_MONO    0

/* ============================================================================
 * LAYOUTS
 * ============================================================================ */

#define LV_USE_FLEX     1
#define LV_USE_GRID     1

/* ============================================================================
 * THIRD PARTY LIBRARIES (Disabled)
 * ============================================================================ */

#define LV_USE_FS_STDIO  0
#define LV_USE_FS_POSIX  0
#define LV_USE_FS_WIN32  0
#define LV_USE_FS_FATFS  0

#define LV_USE_PNG       0
#define LV_USE_BMP       0
#define LV_USE_SJPG      0
#define LV_USE_GIF       0
#define LV_USE_QRCODE    0

#define LV_USE_FREETYPE  0
#define LV_USE_RLOTTIE   0
#define LV_USE_FFMPEG    0

/* ============================================================================
 * OTHERS
 * ============================================================================ */

#define LV_USE_SNAPSHOT   0
#define LV_USE_MONKEY     0
#define LV_USE_GRIDNAV    0
#define LV_USE_FRAGMENT   0

/* ============================================================================
 * EXAMPLES AND DEMOS (Disabled)
 * ============================================================================ */

#define LV_BUILD_EXAMPLES 0

/* ============================================================================
 * DOCUMENTATION
 * ============================================================================ */

/* Disable doxygen comments */
#define LV_USE_DOXYGEN    0

#endif /* LV_CONF_H */
