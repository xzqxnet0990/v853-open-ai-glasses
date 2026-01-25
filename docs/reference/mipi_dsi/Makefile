# Makefile for MIPI DSI panel driver
# Target: RV1109 (ARM Cortex-A7)

obj-m := panel_mipi_dsi.o

# Kernel source directory
KERNEL_SRC ?= /opt/new/rv1106b_rv1103b_linux_ipc_v1.0.0_20241016/kernel

# Cross-compiler prefix
CROSS_COMPILE ?= arm-rockchip831-linux-uclibcgnueabihf-

# Architecture
ARCH := arm

# Build directory
PWD := $(shell pwd)

all:
	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules

clean:
	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) clean

install:
	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules_install

help:
	@echo "MIPI DSI Panel Driver Build"
	@echo "============================"
	@echo "Targets:"
	@echo "  all       - Build kernel module (default)"
	@echo "  clean     - Clean build artifacts"
	@echo "  install   - Install module to target system"
	@echo ""
	@echo "Variables:"
	@echo "  KERNEL_SRC     = $(KERNEL_SRC)"
	@echo "  CROSS_COMPILE  = $(CROSS_COMPILE)"
	@echo "  ARCH           = $(ARCH)"

.PHONY: all clean install help
