#!/bin/bash
# ZRAM Swap Optimization Script (Arch Linux / Generic)
# Version: 3.0
# Description:
#   - ZRAM swap configuration via systemd-zram-generator
# 验证脚本执行结果的方法
# 1. 检查 ZRAM 设备
# swapon --show
# 应看到 zram0 设备
# 2. 检查 ZRAM 配置
# cat /etc/systemd/zram-generator.conf
# 确认配置正确
# 3. 检查服务状态
# systemctl status zram-swap
# 确认服务已启用并运行

[[ "$(id -u)" -ne 0 ]] && exec sudo "$0" "$@"

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

run_zram_optimization() {

    BACKUP_DIR="/root/btrfs_optimize_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    echo "========================================"
    echo "  ZRAM Configuration"
    echo "========================================"
    echo ""
    read -p "Enter ZRAM size as percentage of physical RAM (default 75): " ZRAM_PERCENT
    ZRAM_PERCENT=${ZRAM_PERCENT:-75}
    
    if ! [[ "$ZRAM_PERCENT" =~ ^[0-9]+$ ]] || [ "$ZRAM_PERCENT" -lt 1 ] || [ "$ZRAM_PERCENT" -gt 100 ]; then
        log_error "Invalid percentage. Must be between 1 and 100"
    fi
    
    echo "ZRAM will use ${ZRAM_PERCENT}% of physical RAM"
    echo ""

    log_info "Applying ZRAM optimization..."

    if swapon --show | grep -q zram; then
        log_info "ZRAM swap already active"
        echo -n "Reconfigure anyway? (y/N): "
        read -r ans
        [[ ! "$ans" =~ ^[Yy]$ ]] && return 0
    fi

    if systemctl is-enabled zram-swap &>/dev/null; then
        systemctl stop zram-swap 2>/dev/null || true
        systemctl disable zram-swap 2>/dev/null || true
    fi

    if [[ -f /etc/systemd/zram-generator.conf ]]; then
        log_info "ZRAM generator config already exists, backing up and updating"
        cp -a /etc/systemd/zram-generator.conf "${BACKUP_DIR}/zram-generator.conf.bak"
    fi

    cat << EOF > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 100 * ${ZRAM_PERCENT}
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

    systemctl daemon-reload 2>/dev/null || true
    systemctl enable zram-swap 2>/dev/null || true
    systemctl start zram-swap 2>/dev/null || true
    
    log_info "=========================================="
    log_info "ZRAM configured via systemd-zram-generator:"
    log_info "  - Size: ${ZRAM_PERCENT}% of RAM"
    log_info "  - Compression: zstd"
    log_info "  - Priority: 100"
    log_info "=========================================="
    log_info "Verify with: swapon --show"
    log_warn "Reboot or restart zram-swap service to apply changes"
}

run_zram_optimization
