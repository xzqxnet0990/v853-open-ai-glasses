# V853 AI Glasses - Makefile
#
# 快速编译和部署

.PHONY: all sdk app clean deploy help

# 默认目标
all: sdk app

# 编译SDK适配层
sdk:
	@echo "编译SDK适配层..."
	@./build_all.sh sdk

# 编译应用层
app:
	@echo "编译应用层..."
	@./build_all.sh app

# 清理
clean:
	@echo "清理编译输出..."
	@./build_all.sh clean

# 部署 (需要指定目标)
deploy:
	@echo "请使用以下命令部署:"
	@echo "  make deploy-ssh IP=192.168.1.100"
	@echo "  make deploy-adb"

deploy-ssh:
	@if [ -z "$(IP)" ]; then \
		echo "错误: 请指定设备IP"; \
		echo "用法: make deploy-ssh IP=192.168.1.100"; \
		exit 1; \
	fi
	@./deploy.sh $(IP)

deploy-adb:
	@./deploy.sh adb

# 帮助信息
help:
	@echo "V853 AI Glasses Makefile"
	@echo ""
	@echo "可用目标:"
	@echo "  make all          - 编译所有组件 (默认)"
	@echo "  make sdk          - 只编译SDK适配层"
	@echo "  make app          - 只编译应用层"
	@echo "  make clean        - 清理编译输出"
	@echo "  make deploy-ssh IP=<ip> - 通过SSH部署"
	@echo "  make deploy-adb   - 通过ADB部署"
	@echo "  make help         - 显示此帮助"
	@echo ""
	@echo "示例:"
	@echo "  make              # 编译所有"
	@echo "  make sdk app      # 编译SDK和应用"
	@echo "  make deploy-ssh IP=192.168.1.100"
