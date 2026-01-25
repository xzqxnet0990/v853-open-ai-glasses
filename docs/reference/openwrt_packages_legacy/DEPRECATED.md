# OpenWrt 包定义 - 已弃用

## ⚠️ 状态：已弃用

此目录包含用于 Tina SDK 固件集成的 OpenWrt 包定义。

**弃用原因**：
- 固件编译过于复杂且不稳定
- 开发采用**独立编译 + SSH 部署**方式，更快速高效
- display-qt 和 system-services 已从项目中移除

---

## 📦 原包列表

1. **ai-glass-sdk** - SDK 适配层包定义
   - 源代码：`src/sdk_adapter/`
   - 仍可用，如需固件集成可参考

2. **display-qt** - Qt 显示应用包定义 ❌ 已删除
   - 源代码已移除

3. **system-services** - 系统服务包定义 ❌ 未实现
   - 源代码已移除

---

## 🔄 当前开发流程

**不使用** OpenWrt 包系统，采用独立编译：

```bash
# 编译应用层
./start-docker.sh shell
./build_all.sh
exit

# 部署到设备
./deploy.sh 192.168.1.100
```

**优势**：
- ✅ 编译速度快（5-10分钟 vs 30-60分钟）
- ✅ 成功率高（95%+ vs 30-50%）
- ✅ 迭代速度快
- ✅ 调试方便

---

## 📚 保留原因

作为参考资料保留，如果未来需要：
- 固件级集成
- 生产环境打包
- OpenWrt 包制作参考

---

**弃用时间**: 2026-01-25
**替代方案**: `build_all.sh` + `deploy.sh`
