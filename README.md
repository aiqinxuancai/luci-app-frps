# LuCI App for Frps (luci-app-frps)

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/lwz322/luci-app-frps/blob/master/LICENSE)

这是一个为 [frp](https://github.com/fatedier/frp) 服务端 (frps) 设计的 LuCI 应用，让您可以在 OpenWrt 的网页界面中轻松配置和管理 frps。

本项目的设计灵感来源于 [kuoruan/luci-app-frpc](https://github.com/kuoruan/luci-app-frpc)，并已被 [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede) 项目收录。

## ✨ 功能特性

- **统一配置**: 使用单一的 TOML 配置文件，告别繁琐的表单，配置更清晰、更灵活。
- **自动更新**: 内置更新器，可一键从 GitHub 获取最新版本的 frps，并自动安装。
- **服务管理**: 与 OpenWrt 的 `procd` 进程管理器深度集成，提供可靠的守护进程管理和优雅的服务重载。
- **状态监控**: 在 LuCI 界面实时显示 frps 的运行状态。
- **依赖管理**: 自动依赖 `frps` 软件包，确保开箱即用。

## 🔧 安装

1.  从 [Release 页面](https://github.com/lwz322/luci-app-frps/releases)下载最新的 `.ipk` 安装包。
2.  将安装包上传到您的 OpenWrt 路由器。
3.  通过 `opkg` 命令安装软件包：

    ```shell
    opkg install luci-app-frps_*.ipk
    ```

## 🚀 使用说明

1.  安装完成后，在 LuCI 界面的 “服务” 菜单下找到 “Frps”。
2.  **启用服务**: 勾选 “Enable Frps” 复选框。
3.  **配置 Frps**: 在 “TOML Configuration” 文本框中，粘贴您的 `frps.toml` 文件的完整内容。
4.  **保存并应用**: 点击 “保存并应用” 按钮，frps 服务将会根据您的配置启动。

## ⬆️ 版本更新

-   在 “Frps Version Management” (Frps 版本管理) 部分，您可以查看当前由本插件管理的 frps 版本。
-   点击 “Check and Update Frps” (检查并更新 Frps) 按钮，插件会自动从 GitHub 下载与您路由器架构匹配的最新版本 frps。
-   更新过程在后台进行，您可以在状态区域看到实时日志。更新完成后，服务会自动重启以应用新版本。

## 🤝 贡献

欢迎提交 Pull Request 或 Issue 来改进本项目。

## 📄 开源许可

本项目基于 [MIT License](https://github.com/lwz322/luci-app-frps/blob/master/LICENSE) 开源。
