# 荣耀畅玩 20（KOZ-AL00）救砖包

用于 **荣耀畅玩 20 / KOZ-AL00** 的救砖分区镜像、SPD 刷机工具，以及本机已完成的
软解锁（橙色状态）与 Magisk 安装过程记录。

> ⚠️ **风险提示**
> 本仓库内容基于一台特定设备（同一机型、同一启动链版本）的实际操作记录整理，
> 并非官方固件包。刷写分区、清空 SPL、改动机型引导链均可能导致设备无法开机或
> 永久丢失数据。请先读完本文件，确认已保存好备份，再决定是否操作。

## 设备与状态摘要

| 项目 | 值 |
| --- | --- |
| 机型 | 荣耀畅玩 20，KOZ-AL00 |
| 原系统 | Magic UI 4.0.0.136(C00E3R2P5) |
| 引导状态 | `flash.locked=0`、`unlocked`、`orange`（软解锁） |
| Root | Magisk 28.1，`su -c id` → `uid=0(root)`，SELinux `u:r:magisk:s0` |
| 开机方式 | **每次冷启动都需要电脑辅助**（发送 `spl-unlock.bin` 到内存） |
| 持久引导 | 尝试过，**未成功**，见 [`持久引导测试结果.md`](持久引导测试结果.md) |
| 个人数据 | 软解锁流程已清空 userdata；备份中**不含**个人数据 |

## 目录结构

```
honor-play-20-phone-rescue-kit/
├── README.md                       本文件
├── Boot-HONOR-Play20.cmd           软解锁设备的一键辅助开机脚本（Windows）
├── Boot-HONOR-Play20.sh            软解锁设备的一键辅助开机脚本（Linux / macOS）
├── [WriteFlash].txt                ResearchDownload 的 [WriteFlash] 分区路径模板
├── pac文件（含REC分区）/t610.pac    救砖用 PAC 固件（含 REC 分区）
├── SPD Research Tool/              SPD ResearchDownload 刷机工具（含驱动说明）
│   ├── SPD_Research_Tool_R24.0.0003/
│   └── SPD_Research_Tool_R24.0.0003.zip
├── 软解锁后开机说明.md              软解锁后每次开机的操作流程
├── Magisk安装结果.md               Magisk 安装、验证与回滚说明
├── 持久引导测试结果.md              持久引导尝试的结论（失败，勿刷）
└── rescue-dependencies/            备份、工具链源码与测试记录
    ├── SOURCE.txt                   VC++ 运行库来源与校验说明
    ├── t610.pac                     同上，PAC 副本
    ├── bootrom-before-change/       改机前的 7 份原始分区备份 + 清单/哈希
    ├── honor-play-20-bootrom-flash/ BROM 工具链（spd_dump、FDL1/FDL2、SPL 载荷）
    ├── magisk/                      Magisk 相关镜像、脚本、截图与验证输出
    ├── persistent-boot-test/        持久引导测试的候选、工具与结论
    ├── persistent-boot-upstream/    上游 CVE-2022-38691_38692 源码快照
    ├── spreadtrum_flash-source/     spreadtrum_flash 源码快照
    ├── rec-diagnostics/             Recovery / factory_reset 二进制与字符串
    ├── unlock-guide-review/         解锁流程相关的页面与字符串分析
    ├── vc2010-crt/ vc2010-package/  ResearchDownload 需要的 VC++ 2010 运行库
    └── vcredist_2010_sp1_x86.exe    官方运行库安装包
```

`images/`（分区镜像解压结果）与 `images.zip.001/002`（镜像压缩包本体）**不在本仓库中**，
只以 Release 附件形式提供，详见下文[Release 资产](#release-资产)。

## 快速开始

### 1. 准备分区镜像

1. 在本仓库的 **Releases** 页面下载 `images.zip.001` 与 `images.zip.002` 两个分卷。
2. 合并分卷（Apple 自带的“归档实用工具”不能直接打开分卷，需要先合并）：

   ```bash
   # macOS / Linux
   cat images.zip.001 images.zip.002 > images.zip
   ```

   ```bat
   rem Windows CMD
   copy /b images.zip.001+images.zip.002 images.zip
   ```

3. 校验合并结果（可选但强烈建议）：

   | 文件 | 大小（字节） | SHA-256 |
   | --- | --- | --- |
   | `images.zip.001` | 1677721600 | `ebddab1d302a69d9459be722bc43558ceb748a7f515c4faac0a85fc655f38b7c` |
   | `images.zip.002` | 1397935904 | `2abb8d81e105895edfc6e54206865070c435dfc1846256361cbccba842697fba` |
   | `images.zip`（合并后） | 3075657504 | `90644846e2d0786e5321d72bb6bdd5a00f8ec403a2767d3e568432d4d87de112` |

   ```bash
   shasum -a 256 images.zip        # macOS
   sha256sum images.zip            # Linux
   ```

4. 解压得到 `images/`（35 个文件，解压后约 6.3 GB，其中 `super` 约 5.9 GB），
   放到本救砖包根目录，与 `[WriteFlash].txt` 中的相对结构保持一致。
5. 同时下载本仓库源码（Code → Download ZIP），或直接 clone，获得 PAC、刷机工具和脚本。

> 只需要救砖、不做软解锁的话，源码包里除 `images/` 外的内容已经够用。

### 2. 刷写救砖镜像

1. 用文本编辑器打开根目录的 [`[WriteFlash].txt`]([WriteFlash].txt)，把每一行的
   `D:\honor-play-20-phone-rescue-kit\images\...` 改成你**实际解压镜像的绝对路径**。
2. 打开 `SPD Research Tool/SPD_Research_Tool_R24.0.0003/SPD_Research_Tool_R24.0.0003/`
   下的 `ResearchDownload.ini`，找到 `[WriteFlash]` 段，把上一步 `[WriteFlash].txt`
   的内容粘贴到该段内 `;` 注释行的位置，确认路径无误。
3. 运行同目录的 `ResearchDownload.exe`，加载 `pac文件（含REC分区）/t610.pac`。
4. 进入 **Download Setting**：
   - `Options` 中勾选 `Repartition` 与 `UART Download`；
   - `Flash Operation` 中勾选 `Active Write Flash`；
   - 核对分区路径与镜像一一对应。
5. 手机短接进入虎贲（SPD）下载模式，点 `OK`，再点右箭头开始刷写，等待提示 `Pass`。
6. 刷完后长按电源开机；在 logo 出现时按住 **电源 + 音量上** 进入 REC，
   执行恢复出厂设置并清除 data，重启即可完成救砖。

### 3. 救砖之后的开机

如果设备已经做过度软解锁（本仓库记录的状态），**不能**像普通手机那样直接开机，
需要按 [`软解锁后开机说明.md`](软解锁后开机说明.md) 操作：

1. 用 USB 数据线连接电脑（两份 SPL 已清空，通常会自动进入下载模式，无需再次短接）。
2. 双击根目录的 `Boot-HONOR-Play20.cmd`，等待 Android 启动完成。
3. 出现解锁警告属于预期现象；首次初始化会明显更久。

Linux / macOS 下用等价脚本：

```bash
chmod +x Boot-HONOR-Play20.sh      # 仅首次需要
./Boot-HONOR-Play20.sh             # 等待 300 秒；可用 -w 30 调整
./Boot-HONOR-Play20.sh --dry-run   # 只打印将要执行的命令
```

脚本首次运行会从 `rescue-dependencies/spreadtrum_flash-source` 自动编译
`spd_dump` 到 `.build/`（需要 `libusb-1.0`、`libxml2` 与 `pkg-config`，
缺少时脚本会打印对应平台的安装命令）。Linux 上如果提示设备打不开，
需为展锐下载模式（VID `1782` / PID `4d00`）配置 udev 权限，详见脚本 `--help`。

脚本只把 `spl-unlock.bin` 发送到内存，**不写入任何分区**。
若工具在 `EXEC FDL1` 之后报 `usb_send failed`，多为手机启动瞬间 USB 断开所致，
应以手机画面与 ADB 状态判断，不要只看退出码。

## 软解锁说明

本机的软解锁流程来自上游项目
[Mambo-Senpai/honor-play-20-bootrom-flash](https://github.com/Mambo-Senpai/honor-play-20-bootrom-flash)
（审阅版本 `d594f1a7a2ce70ab6230391669c02b4c853ab999`）。该流程会：

- 清空两份 SPL（`splloader` / `splloader_bak`）；
- 写入改版 U-Boot（`uboot` / `uboot_bak`）；
- 擦除 `metadata`、`misc`、`userdata`。

因此**每次冷启动都必须由电脑发送 `spl-unlock.bin`**，这属于该流程的预期代价。
详细命令见 [`rescue-dependencies/honor-play-20-bootrom-flash/README.md`](rescue-dependencies/honor-play-20-bootrom-flash/README.md)。

## Magisk

本机已安装官方 Magisk 28.1，最终可用镜像为
`rescue-dependencies/magisk/magisk-patched-merged-boot-28.1.img`
（SHA-256 `51ca5c7b35c57a3f67acda7b97c680ff39edc369bd1ed34de4ccf497181abfc9`）。

关键点：

- 该机原始 ramdisk 分区只含 `fstab`，`init` 在独立 ramdisk 分区里；安装时把原始
  `init`、目录与 `fstab` 合入 boot 的 ramdisk 后再用官方工具修补，**不要**直接修补
  原始 369 字节 ramdisk。
- 内核与 DTB 与原始备份逐字节一致；未清除数据。
- 安装 Magisk **没有改变**电脑辅助开机的需求。
- 回滚方法见 [`Magisk安装结果.md`](Magisk安装结果.md)。

## 备份与恢复

改机前的原始备份位于 `rescue-dependencies/bootrom-before-change/`，包含：

| 名称 | 分区 | 大小 | SHA-256 |
| --- | --- | --- | --- |
| emmc-boot0 | `/dev/block/mmcblk0boot0` | 4 MiB | `C79E284F…97FD25` |
| emmc-boot1 | `/dev/block/mmcblk0boot1` | 4 MiB | `C79E284F…97FD25` |
| uboot | `/dev/block/mmcblk0p31` | 3 MiB | `8583D263…7E1C42` |
| uboot_bak | `/dev/block/mmcblk0p32` | 3 MiB | `8583D263…7E1C42` |
| misc | `/dev/block/mmcblk0p4` | 2 MiB | `5647F05E…B31EEE` |
| metadata | `/dev/block/mmcblk0p44` | 16 MiB | `7A15EF4B…47C52D` |
| miscdata | `/dev/block/mmcblk0p2` | 1 MiB | `81809C8D…630F8E` |

完整哈希见 `manifest.json` 与 `tool-manifest.json`。

> 这些是**引导与元数据备份**，不是个人数据备份。已擦除的 userdata 无法由这些文件恢复；
> 也不要把旧的 `metadata` 备份覆盖到已重新初始化的 userdata 上。

恢复原厂启动链需要刷回两份原始 SPL 与原始 U-Boot，并读回校验；
这与“电脑辅助开机”是两种不同操作，不能互相替代。

## Release 资产

| 资产 | 说明 |
| --- | --- |
| `images.zip.001` | 分区镜像压缩包第 1 卷（1.6 GB） |
| `images.zip.002` | 分区镜像压缩包第 2 卷（1.3 GB） |

合并后共 35 个分区镜像：`boot`、`dtbo`、`uboot`、`splloader`、`super`、`vbmeta*`、
`l_modem`、`l_gdsp`、`l_ldsp`、`l_agdsp`、`l_cdsp`、`wcnmodem`、`gnssmodem`、
`patch`、`socko`、`odmko`、`kpatch`、`pm_sys`、`ramdisk`、`sml`、`trustos`、
`teecfg`、`version`、`ddr_para` 及对应的 `_bak` 副本。

### 仓库中未包含的内容

为控制体积并遵守 GitHub 限制，以下内容不进入 git 历史：

- `/images/`：分区镜像解压结果（约 6.3 GB），从 Release 获取；
- `/images.zip.001`、`/images.zip.002`：镜像压缩包本体，仅作为 Release 附件；
- `/rescue-dependencies/persistent-boot-test/compiler/` 与 `zig-cache/`：持久引导测试用的
  Zig 0.16.0 工具链与构建缓存，`zig.exe` 单文件 169 MB，超过 GitHub 单文件 100 MB 限制，
  且可自行重新下载。

## 参考项目

- [Mambo-Senpai/honor-play-20-bootrom-flash](https://github.com/Mambo-Senpai/honor-play-20-bootrom-flash) — 软解锁与 SPL 载荷
- [TomKing062/spreadtrum_flash](https://github.com/TomKing062/spreadtrum_flash) — `spd_dump` / FDL 工具链
- [TomKing062/CVE-2022-38691_38692](https://github.com/TomKing062/CVE-2022-38691_38692) — 持久引导尝试所用上游
- [topjohnwu/Magisk](https://github.com/topjohnwu/Magisk) — Magisk

## 免责声明

本项目仅记录一台已授权设备上的救砖与折腾过程，供同机型、同启动链版本参考。
使用本仓库内容造成的任何设备损坏、数据丢失或保修失效，由使用者自行承担。
刷机前请确认你拥有设备的所有权并已备份重要数据。
