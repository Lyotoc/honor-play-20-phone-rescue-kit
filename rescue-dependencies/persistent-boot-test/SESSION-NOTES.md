# Persistent SPL evaluation

User explicitly requested trying TomKing062/CVE-2022-38691_38692 and then authorized continuation.
No extra data wipe is authorized or needed for this test.
Original primary and backup eMMC boot regions were already all zero under the working tethered soft-unlock.
Working Magisk core/manager: 28.1; final merged boot image preserved.

Upstream commit ea1cd3159061cca7211a326ae8abecf784d50c9b cloned to ../persistent-boot-upstream.
Official gen_spl-unlock-legacy.exe asset digest E77AB36FBC799B130FAA3ABFC9236D35C8199A976F7F238D5BDBC513125478B0.
Running generator on exact matching original SPL reproduced existing known-good RAM SPL SHA256 5703bb1378894e698dc17286343f8f11f1d474070b6c16f6d7d6d6dde0ab2785.
Built unmodified upstream main.c and sha256.c with Zig 0.16.0 C compiler inside this workspace.
Candidate spl-persistent-ums512.bin generated using upstream cfg/ums512.cfg.
63124 bytes, SHA256 02192340297ed5862be346d95917d57dbdda8ceb01b58c8f618ef59dfbe36187.
Independent structure checks verified payload equality, header/footer sizes, payload hash, all configured overflow address words, and original rollback version 0 retained.
Current boot0/boot1 actual full-region backups in before-boot0.bin and before-boot1.bin; both 4MiB of zero, SHA256 bb9f8df61474d25e71fa00722318cd387396ca1736605e1248821cc0de3d3af8.
Rollback-To-Tethered.ps1 prepared to clear only both SPLs over known FDL chain then send existing RAM helper; physical test point may be needed if a persisted candidate hangs.

## First test: RAM only, not flashed

Prestarted existing spd_dump with --wait 300 fdl candidate 0x5500, WITHOUT exec_addr or custom_exec_no_verify payload. Then adb reboot.
The candidate was sent, tool reached EXEC FDL1 and three CHECK_BAUD FAIL then USB disconnect.
Awaiting Android status to determine whether the candidate's own certificate bypass worked.
No boot-region writes have occurred.

RAM-only test did NOT bring Android online after the observation window. COM4 remained enumerated but a retry with the known-good loader failed at the initial one-byte handshake (USB no response). Asked user to disconnect USB, hold power 15-20 seconds, reconnect; awaiting physical reset. Both SPLs remain all zero; candidate has NOT been flashed. Do not write this unproven generic candidate.

User performed physical reset. Known-good RAM helper then restored Android successfully: boot_completed=1, uid=0 magisk, orange.
A subsequent READ-ONLY BootROM read attempt was made through known-good FDL1 (read_mem 0x100000 0x10000). FDL1 connected normally, but the read timed out, leaving a zero-byte file. Attempt to reconnect FDL1 and load FDL2 failed at USB initial 8-byte handshake. No flash writes occurred. This ROM-read path is stopped. Another physical reset is needed to restore the known-good RAM startup.
Kernel has CONFIG_DEVMEM unset, so Android root cannot provide /dev/mem BootROM access either. Generic persistent cfg remains unproven and must not be written to startup partitions.

## Final recovery verified

After the second physical reset, the known-good SPL RAM helper restored Android.
Final boot_completed=1, bootanim=stopped, flash.locked=0, unlocked/orange,
Magisk 28.1 and uid=0 magisk verified. Both full eMMC boot regions, both U-Boot
copies, final Magisk boot, and both original vbmeta copies match their
pre-test hashes. Saved final-restoration-verification.txt. No persistent
SPL was flashed and no data erase was performed. Persistent boot was NOT
achieved by this attempt. Generic candidate is marked do-not-flash.
User report: ../../持久引导测试结果.md.
