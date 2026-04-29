# Hypr-Arch: Arch Linux + Hyprland 自动化部署脚本

一个用于在 Arch Linux 最小化安装后，自动化部署 Hyprland 桌面环境及其配套软件的 bash 脚本集合。

## 🎯 功能特点

- **自动化安装**: 一键部署完整的 Hyprland 桌面环境
- **智能检测**: 自动检测 Nvidia 显卡并安装对应驱动
- **错误处理**: 每个步骤都有错误重试、跳过或退出选项
- **模块化设计**: 每个组件独立脚本，便于维护和定制
- **配置部署**: 自动部署预配置的 dotfiles
- **中文支持**: 包含中文 locale 和输入法配置

## 📋 安装的组件

### 核心组件
- **Hyprland** - Wayland 合成器
- **SDDM** - 显示管理器（登录界面）
- **polkit-kde-agent** - 权限管理

### 配套软件
- **终端**: Kitty
- **文件管理器**: Dolphin
- **启动器**: Wofi
- **状态栏**: Waybar
- **锁屏**: Hyprlock
- **壁纸**: Hyprpaper
- **通知**: SwayNC
- **截图**: Hyprshot
- **亮度控制**: Brightnessctl

### 开发工具
- **Shell**: Fish (含 Fisher 插件管理器)
- **编辑器**: Neovim
- **Node.js**: 通过 nvm 安装 (v25)
- **Python**: uv 包管理器
- **Docker**: 含 Nvidia 容器支持

### 系统工具
- **中文支持**: fcitx5 输入法 + 中文字体
- **剪贴板**: wl-clipboard, cliphist
- **文件搜索**: fd, ripgrep, fzf
- **系统监控**: fastfetch, htop, nvtop
- **备份**: Timeshift

## 🔧 前置要求

1. **Arch Linux 基础系统**
   - 已完成最小化安装
   - 已配置网络连接
   - 已创建普通用户并配置 sudo 权限

2. **用户权限**
   - 使用普通用户运行（**不要**用 root 运行）
   - 用户需有 sudo 权限

## 🚀 使用方法

### 快速开始

```bash
# 克隆或下载此项目
cd hypr-arch

# 赋予安装脚本执行权限
chmod +x install.sh
chmod +x scripts/*.sh

# 运行安装脚本
./install.sh
```

### 安装流程

脚本将按以下顺序执行：

1. ✅ 更新系统软件包
2. ✅ 安装 yay AUR 助手
3. ✅ 安装系统依赖
4. ✅ 安装 Hyprland 及组件
5. ✅ 安装 yazi 文件管理器
6. ✅ 配置中文 locale
7. ✅ 安装 Docker
8. ✅ 安装 uv (Python)
9. ✅ 安装 Node.js (nvm)
10. ✅ 安装字体
11. ✅ 配置 Flathub
12. ✅ 安装 fcitx5 输入法
13. ✅ 添加用户到 video/render 组
14. ✅ 安装 Fish shell
15. ✅ 部署配置文件

### 错误处理

每个步骤失败时，可以选择：
- **[r] Retry** - 重试当前步骤
- **[s] Skip** - 跳过此步骤
- **[e] Exit** - 退出安装

## ⚠️ 注意事项

1. **重启生效**
   - 安装完成后需要重启系统
   - 用户组变更 (docker, video, render) 需要重新登录生效

2. **Nvidia 用户**
   - 脚本会自动检测 Nvidia 显卡
   - 安装 `nvidia-open-dkms` 驱动
   - 配置 NVIDIA container toolkit (用于 Docker GPU 支持)

3. **配置备份**
   - 部署 dotfiles 时会自动备份现有配置
   - 备份位置: `~/.config-backup-YYYYMMDD-HHMMSS`

4. **Fish Shell**
   - 安装完成后默认 shell 会切换为 Fish
   - 如需返回 bash: `chsh -s /bin/bash`

## 📁 项目结构

```
hypr-arch/
├── install.sh              # 主安装脚本
├── README.md              # 本文件
├── scripts/               # 安装脚本目录
│   ├── utils.sh          # 工具函数 (日志、颜色)
│   ├── upgrade-deps.sh   # 更新系统
│   ├── install-yay.sh    # 安装 yay
│   ├── install-deps.sh   # 系统依赖
│   ├── install-hyperland.sh  # Hyprland 及组件
│   ├── install-yazi.sh   # yazi 文件管理器
│   ├── install-locale.sh # 中文 locale
│   ├── install-docker.sh # Docker
│   ├── install-uv.sh     # Python uv
│   ├── install-nodejs.sh # Node.js (nvm)
│   ├── install-fonts.sh  # 字体
│   ├── install-flathub.sh # Flathub
│   ├── install-fcitx5.sh # fcitx5 输入法
│   ├── add-video-group.sh # 用户组
│   ├── install-fish.sh   # Fish shell
│   └── deploy-dotfiles.sh # 部署配置
└── dotfiles/             # 配置文件目录
    ├── fish/             # Fish 配置
    ├── hypr/             # Hyprland 配置
    ├── kitty/            # Kitty 终端配置
    ├── nvim/             # Neovim 配置
    └── ...               # 其他应用配置
```

## 🛠️ 自定义

### 跳过特定步骤

编辑 `install.sh`，注释掉不需要的步骤：

```bash
# run_step "Install Docker" "./scripts/install-docker.sh"
```

### 修改安装的软件包

编辑对应的脚本文件，修改软件包列表。例如：

- `scripts/install-deps.sh` - 系统依赖
- `scripts/install-hyperland.sh` - Hyprland 组件

### 添加自定义 dotfiles

将配置文件放入 `dotfiles/` 对应目录，运行 `deploy-dotfiles.sh` 即可部署。

## 🐛 问题排查

### 安装失败

1. 检查网络连接
2. 确认 Arch 软件源配置正确
3. 查看错误信息，单独运行失败的脚本调试

### Nvidia 驱动问题

```bash
# 查看是否检测到 Nvidia
lspci | grep -i nvidia

# 查看驱动状态
nvidia-smi
```

### 登录问题

```bash
# 检查 SDDM 服务状态
sudo systemctl status sddm

# 查看日志
journalctl -u sddm -b
```

## 📄 许可证

本项目遵循 MIT 许可证。

## 🙏 致谢

- [Hyprland](https://hyprland.org/) - Wayland 合成器
- [Arch Linux](https://archlinux.org/) - 简洁、现代的 Linux 发行版
- 所有开源软件的维护者

---

**注意**: 本脚本仅供学习和个人使用，使用前请备份重要数据。
