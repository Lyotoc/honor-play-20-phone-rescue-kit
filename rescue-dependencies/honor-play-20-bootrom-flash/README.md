# 荣耀畅玩20 BROM 刷机工具

#### 介绍
荣耀畅玩20 (KOZ-AL00) BROM 刷机工具：FDL1/FDL2 引导链、spd_dump 刷机、部分启动分区恢复。

#### 使用说明

1.  手机进下载模式 ：
   spd_dump --wait 300 fdl fdl1-dl-patched.bin 0x5500 fdl fdl2-sign.bin 0x9efffe00 exec e splloader e splloader_bak w uboot uboot_patched.bin e metadata e misc e userdata reset
2.  10 秒内自动进下载模式 → spd_dump --wait 300 exec_addr 0x3ee8 fdl spl-unlock.bin 0x5500
   → 解锁警告 → 自动恢复出厂 → 重启 → 下载模式
3.  再 spd_dump --wait 300 exec_addr 0x3ee8 fdl spl-unlock.bin 0x5500 → 进系统（orange 软解锁）
4.  关机 → 自动进下载模式 → 使用spd_dump --wait 300 exec_addr 0x3ee8 fdl spl-unlock.bin 0x5500 开机（之后每次开机重复第 3 步）

需要用到的分区在 utilizes 文件夹里，刷入改版可用orig（原版文件）恢复
