# Magisk 已安装

设备：荣耀畅玩 20 KOZ-AL00，系统 4.0.0.136(C00E3R2P5)。

已安装官方 Magisk 28.1，管理应用与核心版本一致。已完成必要运行环境修复，
并在自动重启后验证：

- `su -c id`：`uid=0(root)`，SELinux 上下文 `u:r:magisk:s0`。
- `magisk -v`：`28.1:MAGISK:R`。
- `sys.boot_completed=1`，开机动画已停止。
- 引导状态仍为 `flash.locked=0`、`unlocked`、`orange`。

最终 boot 镜像为 `rescue-dependencies/magisk/magisk-patched-merged-boot-28.1.img`。
原始 boot 的 ramdisk 只有 fstab，独立 ramdisk 分区包含 init；本次把这台手机的
原始 init、目录和 fstab 合入 boot 的 ramdisk，再在这台手机上使用官方工具修补。
内核和 DTB 与原始备份逐字节一致，原始 init 已保存在 Magisk 镜像内部的备份中。

测试过的 AVB 关闭方案未解决启动问题，最终两份 vbmeta 均已恢复原始内容；
独立 ramdisk 分区也保持原始内容。本次安装 Magisk 没有执行清除数据命令。

## 每次重启后

继续用 USB 连接电脑，运行本目录的 `Boot-HONOR-Play20.cmd` 辅助启动。
安装 Magisk 没有改变先前软解锁所需的电脑辅助开机方式。

保留当前适配镜像。以后更新 Magisk 时，需要保留这个完整 ramdisk 布局，
不能直接修补原始的 369 字节 ramdisk 并替换当前 boot。

## 备份与验证

原始 boot、ramdisk、vbmeta、vbmeta_bak 在 `rescue-dependencies/magisk/before-magisk/`。
最终验证输出在 `rescue-dependencies/magisk/final-verification.txt`。
Magisk 界面截图在 `rescue-dependencies/magisk/magisk-installed.png`。

最终 boot SHA-256：
`51ca5c7b35c57a3f67acda7b97c680ff39edc369bd1ed34de4ccf497181abfc9`。

如果只需撤销本次 Magisk 安装，可在已验证的 root Recovery 或 FDL 连接下恢复
本次备份的原始 boot，并读回核对哈希；两份 vbmeta 和独立 ramdisk 已是原始内容。
不要因此重刷 SPL 或 U-Boot，那会改变先前完成的软解锁。
