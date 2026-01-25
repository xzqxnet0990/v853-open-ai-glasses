╔════════════════════════════════════════════════════════════╗
║           V853 AI Glasses - 脚本快速参考                  ║
╚════════════════════════════════════════════════════════════╝

📜 核心脚本（4个）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. start-docker.sh  ⭐ Docker 容器管理
   └─ ./start-docker.sh start         启动容器
   └─ ./start-docker.sh shell         进入容器
   └─ ./start-docker.sh build-all     编译应用
   └─ ./start-docker.sh deploy-ssh    部署到设备
   └─ ./start-docker.sh help          查看帮助

2. build_all.sh     ⭐⭐⭐ 应用层编译（最常用）
   └─ 在容器内运行
   └─ 5-10分钟完成
   └─ 编译 SDK + LVGL + FFmpeg + GPIO

3. deploy.sh        ⭐⭐ 部署工具
   └─ ./deploy.sh 192.168.1.100       SSH 部署
   └─ ./deploy.sh adb                 ADB 部署

4. firmware.sh      ⭐ 固件编译（高级，不推荐）
   └─ ./firmware.sh                   交互菜单
   └─ ./firmware.sh kernel            编译内核
   └─ ./firmware.sh status            检查状态

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 推荐工作流（3步）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# 在 macOS
./start-docker.sh shell

# 在容器内
./build_all.sh
exit

# 在 macOS
./start-docker.sh deploy-ssh 192.168.1.100

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

详细说明: 查看 SCRIPTS.md
