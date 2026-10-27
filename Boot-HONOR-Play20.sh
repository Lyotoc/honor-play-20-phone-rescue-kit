#!/usr/bin/env bash
# Boot-HONOR-Play20.sh
#
# 荣耀畅玩 20（KOZ-AL00）软解锁设备的一键辅助开机脚本（Linux / macOS）。
# 对应 Windows 下的 Boot-HONOR-Play20.cmd 与 Boot-SoftUnlocked.cmd：
# 只把仓库中的 spl-unlock.bin 发送到手机内存并从 0x3ee8 执行，不写入任何分区。
#
# 用法：./Boot-HONOR-Play20.sh [选项]

set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
FLASH_DIR="$SCRIPT_DIR/rescue-dependencies/honor-play-20-bootrom-flash"
SRC_DIR="$SCRIPT_DIR/rescue-dependencies/spreadtrum_flash-source"
BUILD_DIR="$SCRIPT_DIR/.build"

PAYLOAD="spl-unlock.bin"
EXEC_ADDR="0x3ee8"
LOAD_ADDR="0x5500"

WAIT_SECONDS=300
REBUILD=0
NO_BUILD=0
DRY_RUN=0

say() { printf '%s\n' "$*"; }
die() { printf '错误：%s\n' "$*" >&2; exit 1; }

usage() {
    cat <<'EOF'
用法：./Boot-HONOR-Play20.sh [选项]

把 spl-unlock.bin 发送到手机内存并从 0x3ee8 执行，用于软解锁（橙色状态）的
荣耀畅玩 20 冷启动。不写入任何分区，与 Windows 的 Boot-HONOR-Play20.cmd 等价。

选项：
  -w, --wait 秒    等待手机进入下载模式的秒数（默认 300）
  -b, --rebuild    强制重新从源码编译 spd_dump
      --no-build   缺少 spd_dump 时直接报错，不自动编译
  -n, --dry-run    只解析并打印将要执行的命令，不真正发送载荷
  -h, --help       显示本帮助

环境变量：
  SPD_DUMP         指定已有的 spd_dump 可执行文件路径

运行前的准备：
  1. 用 USB 数据线连接手机；两份 SPL 已清空，手机通常会自行进入下载模式，
     不需要再次短接。
  2. Linux 上如果报 libusb_open_device failed，需要放行展锐下载模式的 USB 设备
     （VID 1782 / PID 4d00），例如加一条 udev 规则后重新插拔：
       SUBSYSTEM=="usb", ATTR{idVendor}=="1782", ATTR{idProduct}=="4d00", MODE="0666"
  3. macOS 无需额外驱动。

首次运行会在 .build/ 目录从 rescue-dependencies/spreadtrum_flash-source 编译
spd_dump，需要编译器和 libusb-1.0、libxml2 开发包：
  macOS          brew install pkg-config libusb libxml2
  Debian/Ubuntu  sudo apt install build-essential pkg-config libusb-1.0-0-dev libxml2-dev
  Fedora         sudo dnf install gcc make pkgconf-pkg-config libusb1-devel libxml2-devel
  Arch           sudo pacman -S base-devel pkgconf libusb libxml2

退出码沿用 spd_dump 的返回值：0 表示命令链执行完毕；非 0 时请结合手机画面
与 adb 判断，不要只看退出码。
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -w|--wait)
            [ $# -ge 2 ] || die "选项 $1 需要一个秒数"
            WAIT_SECONDS=$2
            shift 2
            ;;
        -b|--rebuild) REBUILD=1; shift ;;
        --no-build) NO_BUILD=1; shift ;;
        -n|--dry-run) DRY_RUN=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; die "未知参数：$1" ;;
    esac
done

case "$WAIT_SECONDS" in
    ''|*[!0-9]*) die "--wait 需要正整数秒数" ;;
esac
[ "$WAIT_SECONDS" -gt 0 ] || die "--wait 需要大于 0 的秒数"

[ -d "$FLASH_DIR" ] || die "找不到刷机工具目录：$FLASH_DIR"
[ -f "$FLASH_DIR/$PAYLOAD" ] || die "找不到载荷文件：$FLASH_DIR/$PAYLOAD"

build_hint() {
    cat >&2 <<'EOF'
请按平台安装编译依赖后重试（或把现成的 spd_dump 放进
rescue-dependencies/honor-play-20-bootrom-flash/，或设置 SPD_DUMP 指向它）：
  macOS          brew install pkg-config libusb libxml2
  Debian/Ubuntu  sudo apt install build-essential pkg-config libusb-1.0-0-dev libxml2-dev
  Fedora         sudo dnf install gcc make pkgconf-pkg-config libusb1-devel libxml2-devel
  Arch           sudo pacman -S base-devel pkgconf libusb libxml2
EOF
}

note() { printf '%s\n' "$*" >&2; }

build_spd_dump() {
    if [ "$NO_BUILD" -eq 1 ]; then
        note "已指定 --no-build，跳过编译"
        return 1
    fi
    command -v "${CC:-cc}" >/dev/null 2>&1 || { note "未找到 C 编译器"; return 1; }
    command -v pkg-config >/dev/null 2>&1 || { note "未找到 pkg-config"; return 1; }
    pkg-config --exists libusb-1.0 || { note "缺少 libusb-1.0 开发包"; return 1; }
    pkg-config --exists libxml-2.0 || { note "缺少 libxml2 开发包"; return 1; }
    [ -f "$SRC_DIR/spd_dump.c" ] && [ -f "$SRC_DIR/common.c" ] || {
        note "缺少 spd_dump 源码：$SRC_DIR"; return 1;
    }

    mkdir -p "$BUILD_DIR" || return 1
    printf '#define GIT_VER "%s"\n#define GIT_SHA1 "%s"\n' \
        "local-build" "rescue-kit" > "$BUILD_DIR/GITVER.h" || return 1

    # 源码里是 #include <libusb-1.0/libusb.h>，因此除 pkg-config 的
    # include/libusb-1.0 之外还要加上它的父目录（Homebrew 上必需）。
    libusb_inc=$(pkg-config --variable=includedir libusb-1.0)

    note "正在编译 spd_dump（首次运行需要十几秒）..."
    # shellcheck disable=SC2046
    if ! "${CC:-cc}" -O2 -std=c99 -Wno-unused -DUSE_LIBUSB=1 \
        -I"$BUILD_DIR" -I"$libusb_inc" \
        $(pkg-config --cflags libxml-2.0) \
        "$SRC_DIR/spd_dump.c" "$SRC_DIR/common.c" \
        $(pkg-config --libs libusb-1.0 libxml-2.0) -lm -lpthread \
        -o "$BUILD_DIR/spd_dump"; then
        note "编译失败"
        return 1
    fi
    return 0
}

resolve_runner() {
    # 输出两行：第一行是启动器（可能为空行），第二行是 spd_dump 路径。
    if [ -n "${SPD_DUMP:-}" ]; then
        [ -x "$SPD_DUMP" ] || die "SPD_DUMP 指向的文件不可执行：$SPD_DUMP"
        printf '\n%s\n' "$SPD_DUMP"
        return
    fi

    if [ "$REBUILD" -eq 1 ]; then
        build_spd_dump || { build_hint; die "无法编译 spd_dump"; }
        printf '\n%s\n' "$BUILD_DIR/spd_dump"
        return
    fi

    for candidate in "$FLASH_DIR/spd_dump" "$BUILD_DIR/spd_dump" "$SRC_DIR/spd_dump"; do
        if [ -x "$candidate" ]; then
            printf '\n%s\n' "$candidate"
            return
        fi
    done

    if build_spd_dump; then
        printf '\n%s\n' "$BUILD_DIR/spd_dump"
        return
    fi

    # 退路：用 Wine 跑仓库自带的 Windows 版。
    if [ -f "$FLASH_DIR/spd_dump.exe" ] && command -v wine >/dev/null 2>&1; then
        note "未能本地编译，改用 Wine 运行 spd_dump.exe"
        printf 'wine\n%s\n' "$FLASH_DIR/spd_dump.exe"
        return
    fi

    build_hint
    die "没有可用的 spd_dump"
}

RUNNER_INFO=$(resolve_runner) || exit 1
RUNNER_LINE=$(printf '%s\n' "$RUNNER_INFO" | sed -n '1p')
SPD_BIN=$(printf '%s\n' "$RUNNER_INFO" | sed -n '2p')
[ -n "$SPD_BIN" ] || die "没有可用的 spd_dump"
[ -x "$SPD_BIN" ] || die "spd_dump 不可执行：$SPD_BIN"

RUNNER=()
[ -n "$RUNNER_LINE" ] && RUNNER=("$RUNNER_LINE")

# 有些平台没有 coreutils 的 timeout（macOS 默认没有），有则加一层保护。
TIMEOUT_BIN=""
if command -v timeout >/dev/null 2>&1; then
    TIMEOUT_BIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
    TIMEOUT_BIN="gtimeout"
fi

say "等待已准备好的荣耀畅玩 20 进入下载模式。"
say "本脚本只把仓库中的 SPL 载荷发送到内存，不写入任何分区。"

RUN_CMD=()
if [ -n "$TIMEOUT_BIN" ]; then
    RUN_CMD=("$TIMEOUT_BIN" "$((WAIT_SECONDS + 180))")
fi
# bash 3.2（macOS 自带）在 set -u 下展开空数组会报错，先判断长度。
if [ ${#RUNNER[@]} -gt 0 ]; then
    RUN_CMD+=("${RUNNER[@]}")
fi
RUN_CMD+=("$SPD_BIN" --wait "$WAIT_SECONDS" \
    exec_addr "$EXEC_ADDR" fdl "$PAYLOAD" "$LOAD_ADDR")

if [ "$DRY_RUN" -eq 1 ]; then
    say ""
    say "（dry-run）将在 $FLASH_DIR 执行："
    printf '  '
    printf '%q ' "${RUN_CMD[@]}"
    printf '\n'
    exit 0
fi

say ""
# 与 .cmd 里的 pushd 一致：必须在该目录运行，spd_dump 会从当前目录
# 查找 custom_exec_no_verify_<addr>.bin 等辅助载荷。
cd "$FLASH_DIR" || die "无法进入目录：$FLASH_DIR"

"${RUN_CMD[@]}"
status=$?

say ""
say "EXEC FDL1 之后，手机启动过程中 USB 断开可能表现为 usb_send failed /"
say "CHECK_BAUD FAIL。请以手机画面和 adb 判断结果，不要只看退出码。"
say "退出码：$status"

if [ -t 0 ]; then
    printf '\n按回车键退出...'
    read -r _ || true
fi

exit "$status"
