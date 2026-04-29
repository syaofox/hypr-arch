#!/bin/bash
# Btrfs Subvolume Optimization Script (Arch Linux / Generic)
# Version: 3.0
# Description:
#   - Creates separate subvolumes for /opt, /var/log, /var/cache, /var/lib/docker, etc.
#   - Applies recommended mount options (noatime, compress=zstd, etc.)
#   - Sets NoCoW on directories that benefit from it (e.g., Docker, VM images)
#   - Updates /etc/fstab and kernel parameters
#   - Timeshift compatibility: ensures @ and @home are snapshots-compatible
# 验证脚本执行结果的方法
# 1. 检查 btrfs 子卷
# btrfs subvolume list /
# 应看到新增: @pkg, @log, @docker, @images
# 2. 检查挂载情况
# mount | grep btrfs
# 应显示每个目标目录对应独立子卷挂载
# 3. 检查 fstab 条目
# grep btrfs /etc/fstab
# 确认新增条目包含正确的挂载选项和 pass=0
# 4. 检查 NoCoW 属性
# lsattr /var/lib/docker
# 应有 C 标志 (NoCoW)
# 5. 检查目录权限
# ls -la /var/log /var/cache/pacman/pkg
# 确认权限正确
# 6. 验证数据完整性
# ls /var/log /var/cache/pacman/pkg /var/lib/docker /var/lib/libvirt/images
# 确认数据完整

[[ "$(id -u)" -ne 0 ]] && exec sudo "$0" "$@"

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

normalize_subvol() {
    echo "${1#/}"
}

check_subvol_exists() {
    local subvol="$1"
    grep -qE "subvol=(/@|@${subvol#@})([[:space:],]|$)" /etc/fstab
}

run_btrfs_optimization() {

    if [[ -n "${SUDO_USER:-}" ]]; then
        REAL_USER="$SUDO_USER"
    else
        REAL_USER=$(logname 2>/dev/null || echo "")
        [[ -z "$REAL_USER" ]] && log_error "Cannot determine regular username, please use sudo"
    fi
    USER_HOME=$(eval echo "~$REAL_USER")
    [[ ! -d "$USER_HOME" ]] && log_error "User $REAL_USER home directory $USER_HOME does not exist"

    ROOT_FSTYPE=$(findmnt -n -o FSTYPE /)
    if [[ "$ROOT_FSTYPE" != "btrfs" ]]; then
        log_error "Root filesystem is not btrfs, cannot execute this script"
    fi
    UUID=$(findmnt -n -o UUID /)
    [[ -z "$UUID" ]] && log_error "Cannot get root partition UUID"

    log_info "Checking subvolume prerequisites..."

    if grep -qE "^[^#]*${UUID}.*subvol=(/@|@)([[:space:]]|$)" /etc/fstab; then
        log_info "Detected @ subvolume (compatible with both /@ and @ formats)"
    fi

    if grep -q "^[^#]*${UUID}.*subvol=/0" /etc/fstab; then
        log_info "Detected legacy /0 style subvolumes, checking structure..."

        local mnt=$(mktemp -d /tmp/btrfs_check_XXXXX)
        if mount -U "$UUID" "$mnt" -o subvolid=5 2>/dev/null; then
            local subvols=$(btrfs subvolume list "$mnt" 2>/dev/null | sed -n 's/.*path //p' || true)

            if echo "$subvols" | grep -q "^0$"; then
                log_info "Subvolume 0 detected (Arch Linux default)"
                if echo "$subvols" | grep -q "^0/home$"; then
                    log_info "Subvolume 0/home detected - normalizing to @ and @home"
                    sed -i 's|subvol=0/subvol=|g' /etc/fstab
                    sed -i 's|subvol=0/home|subvol=@home|g' /etc/fstab
                fi
            fi

            umount "$mnt" 2>/dev/null || true
            rmdir "$mnt" 2>/dev/null || true
        fi
    fi

    grep -qE "subvol=(/@|@)([[:space:]]|$)" /etc/fstab || log_error "Root subvolume @ not found in fstab"
    grep -qE "subvol=(/@home|@home)([[:space:]]|$)" /etc/fstab || log_error "Home subvolume @home not found in fstab"
    log_info "Subvolume prerequisites verified"

    log_info "Timeshift compatibility check..."
    if command -v timeshift &>/dev/null || [[ -f /usr/bin/timeshift ]]; then
        log_info "Timeshift detected - independent subvolumes will be created to EXCLUDE these directories from snapshots:"
        log_info "  - /var/cache/pacman/pkg (package cache)"
        log_info "  - /var/log (system logs)"
        log_info "  - /var/lib/docker (Docker data)"
        log_info "  - /var/lib/libvirt/images (VM images)"
        echo "This allows timeshift to exclude these large/frequently-changing directories from snapshots."
        echo "Continue? (Y/n)"
        read -r ans
        if [[ "$ans" =~ ^[Nn]$ ]]; then
            log_info "Cancelled by user"
            return 0
        fi
    else
        log_warn "Timeshift not detected. For timeshift compatibility, you should install timeshift after running this script."
        log_info "Creating independent subvolumes for better snapshot management..."
    fi

    detect_and_fix_subvolume_structure() {
        log_info "Detecting subvolume structure..."

        local mnt=$(mktemp -d /tmp/btrfs_detect_XXXXX)
        mount -U "$UUID" "$mnt" -o subvolid=5 2>/dev/null || {
            rmdir "$mnt"
            return 1
        }

        local existing_subvols=$(btrfs subvolume list "$mnt" 2>/dev/null | sed -n 's/.*path //p' | sort || true)
        log_info "Existing subvolumes: $existing_subvols"

        echo "$existing_subvols" | grep -q "^@$" || log_warn "Subvolume @ not found in root"
        echo "$existing_subvols" | grep -q "^@home$" || log_warn "Subvolume @home not found in root"

        if echo "$existing_subvols" | grep -q "^0$"; then
            log_warn "Found subvolume 0 (Arch Linux default), checking structure..."
            if [[ -d "$mnt/0" ]]; then
                if [[ -d "$mnt/0/@" ]] || [[ -d "$mnt/@" ]]; then
                    log_info "Subvolume structure verified"
                fi
            fi
        fi

        umount "$mnt" 2>/dev/null || true
        rmdir "$mnt" 2>/dev/null || true
    }

    detect_and_fix_subvolume_structure

    MOUNT_OPTS="noatime,compress=zstd:3,discard=async,space_cache=v2,commit=120,x-gvfs-hide,ssd"

    TARGETS=(
        "/var/cache/pacman/pkg:/@pkg:false"
        "/var/log:/@log:false"
        "/var/lib/docker:/@docker:true"
        "/var/lib/libvirt/images:/@images:true"
    )

    BACKUP_DIR="/root/btrfs_optimize_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    log_info "Backing up original configuration files to $BACKUP_DIR"
    cp -a /etc/fstab "$BACKUP_DIR/fstab"
    cp -a /etc/sysctl.d/* "$BACKUP_DIR/sysctl.d" 2>/dev/null || true
    [ -f /etc/docker/daemon.json ] && cp -a /etc/docker/daemon.json "$BACKUP_DIR/daemon.json" 2>/dev/null || true

    MNT=$(mktemp -d /tmp/btrfs_mnt_XXXXXX)
    trap 'umount -l "$MNT" 2>/dev/null; rmdir "$MNT" 2>/dev/null; exit' INT TERM EXIT
    mount -U "$UUID" "$MNT" -o subvolid=5 || log_error "Cannot mount btrfs root volume"

    log_info "Initializing user directory structure..."
    for t in "${TARGETS[@]}"; do
        IFS=':' read -r DIR SUBVOL_NAME NOCOW <<< "$t"
        [[ -z "$DIR" || -z "$SUBVOL_NAME" ]] && continue
        if [[ "$DIR" == "$USER_HOME"* ]]; then
            for parent in "$DIR" "$(dirname "$DIR")"; do
                if [[ "$parent" != "$USER_HOME" && ! -d "$parent" ]]; then
                    mkdir -p "$parent"
                    chown "$REAL_USER":"$REAL_USER" "$parent"
                fi
            done
        fi
    done

    log_info "Updating all btrfs subvolume mount options in /etc/fstab..."

    update_subvol_mount_opts() {
        local subvol=$1
        local fstab="/etc/fstab"
        local mnt_point
        local normalized
        case "$subvol" in
            "@"|"/@") mnt_point="/" ;;
            "@home"|"/@home") mnt_point="/home" ;;
            "@"*|"@"*) normalized="${subvol#/}"; mnt_point="/${normalized#@}" ;;
            *) mnt_point="/${subvol#/}" ;;
        esac
        
        if ! grep -q "^[^#]*${UUID}[[:space:]]*${mnt_point}[[:space:]]" "$fstab"; then
            return 1
        fi
        
        log_info "Updating subvolume $subvol mount options..."
        local opts_field="rw,${MOUNT_OPTS},subvol=${subvol}"
        awk -F'\t' -v uuid="$UUID" -v mp="$mnt_point" -v opts="$opts_field" '
        $1 ~ uuid && $2 == mp {
            $4 = opts
            $5 = 0
            $6 = 0
        }
        {OFS="\t"; print}
        ' "$fstab" > "${fstab}.tmp" && mv "${fstab}.tmp" "$fstab"
        return 0
    }

    update_subvol_mount_opts "@"   || log_error "Root subvolume @ not found in fstab, please check your fstab"
    update_subvol_mount_opts "@home" || log_error "Home subvolume @home not found in fstab, please check your fstab"

    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ ! "$line" =~ "$UUID" ]] && continue
        if [[ "$line" =~ subvol=(/@|@)([^[:space:],*) ]]; then
            SUBVOL=$(echo "$line" | sed -n 's/.*subvol=\([^[:space:],]*\).*/\1/p')
            SUBVOL=$(normalize_subvol "$SUBVOL")
            [[ "$SUBVOL" == "@" || "$SUBVOL" == "@home" ]] && continue
            update_subvol_mount_opts "$SUBVOL" && log_info "Updated subvolume $SUBVOL mount options"
        fi
    done < /etc/fstab

    for t in "${TARGETS[@]}"; do
        IFS=':' read -r DIR SUBVOL_NAME NOCOW <<< "$t"
        [[ -z "$DIR" || -z "$SUBVOL_NAME" ]] && continue

        mkdir -p "$(dirname "$DIR")" 2>/dev/null || true
        mkdir -p "$DIR" 2>/dev/null || true

        if [[ "$DIR" == "$USER_HOME"* ]]; then
            chown -h "$REAL_USER":"$REAL_USER" "$DIR" 2>/dev/null || true
            chown -h "$REAL_USER":"$REAL_USER" "$(dirname "$DIR")" 2>/dev/null || true
        fi

        if btrfs subvolume show "$DIR" &>/dev/null; then
            log_info "$DIR is already a subvolume, skipping"
            continue
        fi

        log_info "Processing $DIR"

        case "$DIR" in
            "/var/lib/docker") systemctl stop docker.socket docker 2>/dev/null || true ;;
            "/var/lib/libvirt/images") systemctl stop libvirtd 2>/dev/null || true ;;
        esac

        if lsof +D "$DIR" &>/dev/null; then
            log_warn "Directory $DIR is being used by the following processes:"
            lsof +D "$DIR" | head -5
            if [[ "$DIR" == "/usr/local" || "$DIR" == "/opt" || "$DIR" == "/srv" ]]; then
                log_warn "Critical system directory $DIR is in use, skipping migration"
                continue
            else
                echo -n "Forcefully terminate these processes? (y/N) "
                read -r ans
                if [[ "$ans" =~ ^[Yy]$ ]]; then
                    fuser -k "$DIR" 2>/dev/null || true
                    sleep 2
                else
                    log_error "Please manually close related processes and retry"
                fi
            fi
        fi

        SV_PATH="$MNT${SUBVOL_NAME}"
        if [[ ! -d "$SV_PATH" ]]; then
            btrfs subvolume create "$SV_PATH" || log_error "Failed to create subvolume $SV_PATH"
            log_info "Subvolume $SV_PATH created"
        else
            log_info "Subvolume $SV_PATH already exists, reusing"
        fi

        if [[ "$NOCOW" == "true" ]]; then
            chattr +C "$SV_PATH" || log_warn "Failed to set NoCoW"
            log_info "NoCoW enabled for $SV_PATH"
        fi

        OLD_DIR="${DIR}_bak_$$"
        mv "$DIR" "$OLD_DIR" || log_error "Cannot move $DIR"
        mkdir -p "$DIR"
        chmod --reference="$OLD_DIR" "$DIR" 2>/dev/null || true
        chown --reference="$OLD_DIR" "$DIR" 2>/dev/null || true

        mount -U "$UUID" "$DIR" -o "subvol=${SUBVOL_NAME},${MOUNT_OPTS}" || {
            rmdir "$DIR"
            mv "$OLD_DIR" "$DIR"
            log_error "Failed to mount subvolume, rolled back"
        }

        if command -v rsync &>/dev/null; then
            rsync -aAX "$OLD_DIR"/ "$DIR"/ || {
                umount "$DIR"
                rmdir "$DIR"
                mv "$OLD_DIR" "$DIR"
                log_error "Data copy failed, rolled back"
            }
        else
            cp -a --reflink=auto "$OLD_DIR"/. "$DIR"/ || {
                umount "$DIR"
                rmdir "$DIR"
                mv "$OLD_DIR" "$DIR"
                log_error "Data copy failed, rolled back"
            }
        fi

        rm -rf "$OLD_DIR" || log_warn "Cannot remove backup directory $OLD_DIR"

        if ! grep -qE "subvol=${SUBVOL_NAME}([[:space:],]|$)" /etc/fstab; then
            echo "UUID=${UUID}  ${DIR}  btrfs  ${MOUNT_OPTS},subvol=${SUBVOL_NAME}  0  0" >> /etc/fstab
            log_info "Added $DIR mount entry to fstab"
        fi

        log_info "$DIR processing complete"
    done

    umount "$MNT" && rmdir "$MNT"
    trap - INT TERM EXIT

    log_info "Fixing user directory permissions..."
    if [[ -d "$USER_HOME" ]]; then
        chown -R "$REAL_USER":"$REAL_USER" "$USER_HOME" || log_warn "Cannot fix ownership of $USER_HOME"
        [[ -d "$USER_HOME/.local" ]] && chown "$REAL_USER":"$REAL_USER" "$USER_HOME/.local" && log_info "Fixed .local"
        [[ -d "$USER_HOME/.config" ]] && chown "$REAL_USER":"$REAL_USER" "$USER_HOME/.config" && log_info "Fixed .config"
    fi

    log_info "Adding manual mount reference to /etc/fstab..."
    cat >> /etc/fstab << 'EOF'

# ============================================
# Manual Mount Reference (uncomment as needed)
# ============================================

# ssd
#UUID=cb6285a3-5e94-4376-a9fc-38b10c28d40e /mnt/github btrfs rw,noatime,ssd,compress=zstd:3,discard=async,space_cache=v2,subvol=/@github 0 0
#UUID=cb6285a3-5e94-4376-a9fc-38b10c28d40e /mnt/data btrfs rw,noatime,ssd,compress=zstd:3,discard=async,space_cache=v2,subvol=/@data 0 0

# dnas
#10.10.10.2:/fs/1000/nfs /mnt/dnas nfs noauto,x-systemd.automount,_netdev,addr=10.10.10.2 0 0

# xiaoxin
#10.10.10.6:/fs/1000/nfs /mnt/xiaoxin nfs noauto,x-systemd.automount,_netdev,addr=10.10.10.6 0 0
EOF

    log_info "Applying kernel parameter optimization..."
    cat << 'EOF' > /etc/sysctl.d/99-swappiness.conf
vm.swappiness=10
EOF
    cat << 'EOF' > /etc/sysctl.d/99-developer-optimizations.conf
fs.inotify.max_user_watches=524288
vm.max_map_count=262144
EOF
    sysctl -p /etc/sysctl.d/99-swappiness.conf >/dev/null 2>&1 || true
    sysctl -p /etc/sysctl.d/99-developer-optimizations.conf >/dev/null 2>&1 || true

    log_info "=========================================="
    log_info "Btrfs optimization completed!"
    log_info "Backup files saved in: $BACKUP_DIR"
    log_info "=========================================="
    log_warn "Please reboot the system for all mounts to take effect"
    log_info "Verify mounts with: mount | grep btrfs"
}

run_btrfs_optimization
