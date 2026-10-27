# HONOR Play 20 BootROM preparation

Device: KOZ-AL00, Magic UI 4.0.0.136(C00E3R2P5).

Selected repository: https://github.com/Mambo-Senpai/honor-play-20-bootrom-flash
Reviewed commit: d594f1a7a2ce70ab6230391669c02b4c853ab999.

The repository describes a tethered orange soft-unlock. It erases both SPL
copies, writes the patched U-Boot, and erases metadata, misc, and userdata.
Every subsequent cold start requires a computer to send spl-unlock.bin.
The user explicitly accepted these effects before device changes.

## Verified backup

Seven raw backups were read through the existing root Recovery. File sizes
were checked against sysfs partition sector counts. SHA-256 hashes and device
paths are recorded in manifest.json. Tool and payload hashes are recorded in
tool-manifest.json.

Both complete eMMC boot regions are 4 MiB. Their first 262144 bytes match the
repository's utilizes/splloader_original.bin. Both live U-Boot copies match
utilizes/uboot_original.bin. The rescue kit's boot, dtbo, and vbmeta also match
the repository original images.

These are boot and metadata backups, not a backup of personal userdata.
Erased userdata cannot be recovered from these files.

## Startup helper

Boot-SoftUnlocked.cmd in the cloned repository implements the README's RAM
startup command. It is intended for this prepared device after applying the
soft-unlock, not for unrelated phones.

## Stock boot recovery plan

If the modified boot chain fails, establish the same verified FDL connection
and restore both SPL copies from utilizes/splloader_original.bin, and restore
uboot from the verified uboot.bin backup. Check reads after writing before
requesting reset. Restoring a normal boot chain does not restore erased user
data. Do not restore an old metadata backup over newly initialized userdata.

Do not substitute raw mmc partition numbers for FDL's special splloader names:
Linux exposes those SPL copies in mmcblk0boot0 and mmcblk0boot1, not in the GPT
by-name directory.

## Connection attempt status (2026-10-26)

No erase or partition-write command has been issued for this method. Initial
COM4 detection ended with `usb_send failed (0 / 8)` before FDL1 was sent.
The old idle ResearchDownload process was terminated to avoid port conflicts.
Android was verified booted via ADB, then shut down normally with
`adb shell reboot -p`. Subsequent manual test-point attempts did not establish
a stable download connection. The final USB device was VID_339B/PID_107F
(ordinary USB storage), with no present SPRD download port. The waiting
spd_dump process was stopped. Do not treat the startup helper as an applied
unlock: the device's boot partitions still retain their original contents.

Next step: verify the user's physical test-point procedure and establish FDL2
successfully before issuing the already-authorized destructive operations.

ResearchDownload subsequently completed a FDL-only test with green Passed
(COM4, six seconds). Both Recovery image selections, repartition, reset,
poweroff, active write, active erase and erase-all were disabled. COM4 remained
present afterward. spd_dump could not take over that session: it failed to
send its initial eight-byte packet. ResearchDownload was stopped and its idle
process exited. Trying ResearchDownload's Channel9.dll did not resolve this;
the repository Channel9.dll was restored (SHA256
79EDBD9E4AE5D1D8B572D8663EB921069736EF0B7EE661920D3CDE9855BC3D4F).

After a new unplug/reconnect and forced-restart attempt, Windows instead
reported Unknown USB Device (Device Descriptor Request Failed), instance
USB\\VID_0000&PID_0002\\5&21523F81&0&1, on the same physical port previously
used by COM4. pnputil restart-device and scan-devices were denied by Windows
permissions. No SPL erases, U-Boot writes, userdata erases, or startup payloads
have been sent. The direct FDL listener was stopped while the USB connection
is checked. No stage1-verified.ready flag has been created.

## Soft-unlock applied (2026-10-26)

USB communication recovered as ordinary Android ADB. The model/build were
rechecked (KOZ-AL00, 4.0.0.136), battery was 65%, and all seven original
backups were rehashed successfully. With the direct FDL listener ready,
`adb reboot autodloader` was sent under the user's existing authorization for
SPL erasure and computer-assisted startup. This produced a working BROM
SPRD3 connection and the repository's FDL1/FDL2 chain loaded successfully.

FDL reads confirmed both SPL copies were already zero and live U-Boot still
matched the original backup. The README's SPL erase commands were issued.
`w uboot utilizes\uboot_patched.bin` wrote both U-Boot copies (the tool handles
the backup automatically). Both complete 3 MiB copies were read back and
matched SHA256 CF98408F2AD57E3E5CC06B6535DED4088CB79E977B7A66FB99044EBC4588E036.
The first U-Boot read after writing returned an unexpected ACK with zero bytes;
a subsequent complete read succeeded and passed the hash check.

`e metadata`, `e misc`, and `e userdata` were issued as documented. In this
spd_dump version, `e userdata` writes a 2048-byte boot-recovery/--wipe_data
request to misc and erases persist; it delegates userdata formatting to
Recovery. This behavior was confirmed in the tool source. The staged misc
request was read back and verified. Both SPL reads were reconfirmed zero.

Only after these checks was stage1-verified.ready created. `reset` then
automatically launched two README RAM startup passes through
Continue-Approved-Unlock.ps1. Both sent spl-unlock.bin and the 0x3ee8 exec
payload, reached EXEC FDL1, and disconnected as the phone booted. A piped key
handled the tool's Windows pause so the next pass was ready promptly.

Recovery first appeared with flash.locked=0, vbmeta.device_state=unlocked and
verifiedbootstate=orange, then automatically rebooted. After the second pass,
Android ADB returned with the same three unlock values. First initialization
was still in progress when first checked (boot animation running).

User startup entry point: D:\honor-play-20-phone-rescue-kit\Boot-HONOR-Play20.cmd
Instructions: D:\honor-play-20-phone-rescue-kit\软解锁后开机说明.md
The original backup files and manifest have not been overwritten.

Final Android verification completed after approximately seven minutes of
first-boot application optimization: flash.locked=0,
vbmeta.device_state=unlocked, verifiedbootstate=orange, sys.boot_completed=1,
init.svc.bootanim=stopped. No dex2oat process remained in the last process
sample. The exact queried values and UTC check time are saved in
final-device-status.json. No further reboot was performed after verification.
