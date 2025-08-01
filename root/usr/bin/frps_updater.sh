#!/bin/sh

# frps_updater.sh - 自动下载并更新 frps

# 日志文件
LOG_FILE="/tmp/frps_update.log"

# 自定义 frps 安装目录和文件名
INSTALL_DIR="/usr/share/frps_custom"
INSTALL_PATH="$INSTALL_DIR/frps"

# UCI 路径，用于保存版本号
UCI_PATH="frps.main.custom_version"

# 清理旧日志
echo "Starting frps update..." > $LOG_FILE

log() {
    echo "$(date): $@" >> $LOG_FILE
}

# 1. 检测系统架构
ARCH=$(uname -m)
FRP_ARCH=""

log "Detected system architecture: $ARCH"

case "$ARCH" in
    x86_64) FRP_ARCH="amd64" ;;
    aarch64) FRP_ARCH="arm64" ;;
    armv7l) FRP_ARCH="arm" ;;
    mips) FRP_ARCH="mips" ;;
    mipsle) FRP_ARCH="mipsle" ;;
    *) 
        log "Error: Unsupported architecture: $ARCH"
        uci set $UCI_PATH="Error: Unsupported architecture: $ARCH"
        uci commit frps
        exit 1
        ;;
esac

log "Mapped to frp architecture: $FRP_ARCH"

# 2. 获取最新的 release 信息
API_URL="https://api.github.com/repos/fatedier/frp/releases/latest"
log "Fetching latest release info from $API_URL"

RELEASE_INFO=$(curl -s $API_URL)

if [ -z "$RELEASE_INFO" ]; then
    log "Error: Failed to fetch release info from GitHub API."
    uci set $UCI_PATH="Error: Failed to fetch release info."
    uci commit frps
    exit 1
fi

# 3. 解析下载链接
# 我们需要包含 linux 和我们的架构的包
DOWNLOAD_URL=$(echo "$RELEASE_INFO" | jsonfilter -e "@.assets[*]" | \
    jsonfilter -e "@.browser_download_url" | \
    grep "linux_${FRP_ARCH}" | \
    grep -v "full" | head -n 1)

if [ -z "$DOWNLOAD_URL" ]; then
    log "Error: Could not find a download URL for linux_${FRP_ARCH}."
    uci set $UCI_PATH="Error: No download URL found."
    uci commit frps
    exit 1
fi

log "Found download URL: $DOWNLOAD_URL"

# 4. 下载并解压
TMP_FILE="/tmp/frp.tar.gz"

log "Downloading to $TMP_FILE..."
uci set $UCI_PATH="Downloading..."
uci commit frps

wget -O "$TMP_FILE" "$DOWNLOAD_URL"

if [ $? -ne 0 ]; then
    log "Error: Download failed."
    uci set $UCI_PATH="Error: Download failed."
    uci commit frps
    exit 1
fi

log "Download complete. Extracting frps..."
uci set $UCI_PATH="Extracting..."
uci commit frps

# 从压缩包中提取 frps，并找到它的路径
# tar 的 --strip-components=1 可以移除顶层目录
EXTRACT_DIR=$(tar -tzf $TMP_FILE | head -n 1 | cut -f1 -d"/")
tar -xzf "$TMP_FILE" -C /tmp "${EXTRACT_DIR}/frps"

TMP_FRPS_PATH="/tmp/${EXTRACT_DIR}/frps"

if [ ! -f "$TMP_FRPS_PATH" ]; then
    log "Error: Failed to extract frps from the archive."
    uci set $UCI_PATH="Error: Extraction failed."
    uci commit frps
    rm "$TMP_FILE"
    exit 1
fi

# 5. 安装
log "Installing frps to $INSTALL_PATH"
uci set $UCI_PATH="Installing..."
uci commit frps

mkdir -p "$INSTALL_DIR"
mv "$TMP_FRPS_PATH" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

# 6. 获取新版本并保存
NEW_VERSION=$($INSTALL_PATH -v)

if [ -z "$NEW_VERSION" ]; then
    log "Error: Failed to get version from the new frps binary."
    uci set $UCI_PATH="Error: Version check failed."
    uci commit frps
else
    log "Update successful. New version: $NEW_VERSION"
    uci set $UCI_PATH="$NEW_VERSION (Updated: $(date '+\%Y-%m-%d %H:%M'))"
    uci commit frps
fi

# 7. 清理
log "Cleaning up temporary files..."
rm "$TMP_FILE"
rm -r "/tmp/${EXTRACT_DIR}"

log "Update script finished."

# 重启服务以应用新版本
/etc/init.d/frps restart

exit 0
