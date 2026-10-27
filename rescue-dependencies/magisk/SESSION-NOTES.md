# Magisk installation session

Device: KOZ-AL00, firmware 4.0.0.136(C00E3R2P5), Android 10.
Before this task, tethered BROM soft-unlock was complete, Android booted, and
properties were flash.locked=0, vbmeta.device_state=unlocked, verifiedbootstate=orange.
The user explicitly requested installation of Magisk.

Official instructions: https://topjohnwu.github.io/Magisk/install.html
APKs were downloaded directly from topjohnwu/Magisk GitHub releases.
All patching took place on this exact phone using scripts and binaries from
the corresponding official APK. KEEPVERITY and KEEPFORCEENCRYPT were true;
PATCHVBMETAFLAG and RECOVERYMODE were false. Pre-init storage was detected as cache.

## Original partitions

Actual partition backups in before-magisk/ were read in root Recovery via
bounded dd into /tmp files, then adb pull. Direct adb pull of the block device
stalled and its read-only client was terminated; the completed regular-file
backups were verified instead.

- boot: 36700160 bytes, SHA256 21d939b1c58648d9f84994486bf36c700150785d768a4df91c73d153d6883be9
- ramdisk: 2097152 bytes, SHA256 0e4175783d2e1dc4bc2b2189118da65bbb1fd28e1730981630df2c6ce0bfb642
- vbmeta: 1048576 bytes, SHA256 d96c5f9fc7604dfa25d674c9e2f38e91e3f34602b79718c1fc78a3be6e4a5503

These all matched the rescue-kit images. Original boot contains only a
369-byte compressed ramdisk (fstab); the separate ramdisk contains init.

## Attempts so far

1. Official Magisk 30.7 app installed. A 30.7 patched separate ramdisk was
   written and read back correctly, but Android started with no magisk/su
   or magiskd. This separate ramdisk was subsequently restored to its original
   content and its hash checked.
2. A Magisk 30.7 patched boot was produced, preserving kernel and DTB exactly.
   Written hash: 214ade6effd0a2ad1e0b13521b0077aefbbd31ff8292b3a90c960e6da6962c43.
   It did not bring Android online and the device returned to BROM.
   FDL connection was reestablished without physical shorting. uboot_log and
   bootfail_info were saved in fdl-readback/. The U-Boot log includes orange
   normal-boot flow; no definite AVB rejection has been established. bootfail_info
   was all zero. At that stage vbmeta had not been modified.
3. Original boot was restored over FDL, read back, and matched the original
   SHA256. A normal RAM-assisted boot returned Android with boot_completed=1
   and orange. The Magisk 30.7 manager app is still installed, but no root is active.
4. Official Magisk 28.1 was downloaded for compatibility testing (primary
   issue https://github.com/topjohnwu/Magisk/issues/9950 describes Huawei
   regressions after 28102, but it is not proof of this phone's precise failure).
   The 28.1 boot was patched on this phone, with kernel/DTB verified unchanged.
   File: magisk-patched-boot-28.1.img, 36700160 bytes,
   SHA256 8fe8e513379d2cc2fe840f0ca7a3fc7eb723517041344eb67ed588642e137be8.
   Currently rebooting into root Recovery to test that image.

No userdata, cache or metadata erase was performed during this Magisk task.
The original bootloader/SPL soft-unlock arrangement has been preserved.

## Reboot and rollback

Every reboot requires the existing SPL RAM payload. Start a waiting spd_dump
first, then adb reboot; the RAM command is the one in Boot-HONOR-Play20.cmd.
EXEC FDL1 followed by USB send failure is expected when the payload boots the phone.

Recovery has root ADB. Use bounded reads/writes, ensure ro.bootmode=recovery,
and check SHA256 before rebooting. In BROM the repository FDL chain has also
worked. Restore before-magisk/boot.img to boot and before-magisk/ramdisk.img
to ramdisk if an attempt fails; retain the already working patched U-Boot and
erased SPLs unless specifically restoring the original boot chain.

## AVB test authorized explicitly by user

User approved writing a modified vbmeta and accepted disabled boot verification,
possible boot failure and data-loss risk. Initial automatic-review rejection
was respected; the identical write was retried only after explicit approval.
Actual original vbmeta_bak was additionally read and matched original vbmeta.
Canonical vbmeta-disable-verification.img changes only byte 0x7B to 3
(standard big-endian AVB flags at offset 120). SHA256:
b151af0675201fc5f21b53126cbf521812d3dbec4d77247b4020b435fc6d94a5.
FDL wrote primary flags=3, backup flags=0 (tool deliberately clears byte 0x7B
in its source file before auto-writing backup). Both readbacks matched.
Patched boot 28.1 still returned to BROM. Readback confirmed primary vbmeta
remained modified, not automatically overwritten. U-Boot still logged a full
AVB chain and verity enforcing; the effect of this flag on this Huawei loader
has not been established.
Original boot has now been restored and read back to its original SHA256.
Separate ramdisk remains original. Currently observing normal startup.
No erase commands were used.

Layout investigation: original boot CPIO contains only fstab.ums512_1h10;
separate ramdisk CPIO contains init and directories but no fstab. Kernel's
built-in CPIO is empty except dev/console/root. A merged-original-ramdisk.cpio
has been PREPARED LOCALLY ONLY, combining exact original separate ramdisk
entries with exact boot fstab, for a possible boot-entry compatibility test.
This file has not yet been patched or flashed.

## Successful boot with complete original init

Restored original vbmeta + vbmeta_bak, both read back to original d96c5f...
Phone then entered root eRecovery (auto recovery after failed boots).
On this same phone in eRecovery, official Magisk 28.1 magiskboot unpacked
original boot, replaced only ramdisk.cpio with merged-original-ramdisk.cpio,
repacked to combined-original-boot.img, and boot_patch.sh patched that image.
Explicit flags remained KEEPVERITY=true, KEEPFORCEENCRYPT=true,
PATCHVBMETAFLAG=false, RECOVERYMODE=false, LEGACYSAR=false,
PREINITDEVICE=cache. Original init was backed up as .backup/init.xz.
Final: magisk-patched-merged-boot-28.1.img, 36700160 bytes, SHA256
51ca5c7b35c57a3f67acda7b97c680ff39edc369bd1ed34de4ccf497181abfc9.
Kernel and DTB match actual original bit for bit. Written in root eRecovery,
full partition readback matched. Android boot completed with magiskd,
/sbin/magisk, /sbin/su. magisk -V returned 28100. Boot properties remain
flash.locked=0, device_state=unlocked, orange.
Official Magisk manager was aligned to 28.1 using adb install -r -d; phone
installation confirmations were handled through observed UI XML.
App showed current Magisk 28.1 and App 28.1, Ramdisk yes.
The mandatory additional environment setup was accepted; its automatic
reboot was caught by the prestarted RAM SPL loader. Awaiting final root test.
No data wipe or other erase commands used in this Magisk task.

## Final result: installation complete

After mandatory environment repair and automatic reboot, Android completed
boot with boot_completed=1, bootanim=stopped. The first ADB su request timed
out while the setup welcome screen was foreground and created a denied Shell
policy. Opened Magisk, observed Superuser > [SharedUID] Shell policy disabled,
and enabled it for the explicit root verification. su -c id then returned
uid=0(root) gid=0(root) groups=0(root) context=u:r:magisk:s0.
Core and manager are both 28.1; no environment repair dialog remains.
Final live block hashes were saved in final-verification.txt and match:
boot=51ca5c7b35c57a3f67acda7b97c680ff39edc369bd1ed34de4ccf497181abfc9;
ramdisk=original 0e4175...; vbmeta and vbmeta_bak=original d96c5f....
Thus AVB weakening is NOT left applied; the user's authorized AVB test was
rolled back. Existing tethered SPL/UBoot soft-unlock remains in effect.
User guide: ../../Magisk安装结果.md. App left on Magisk home page.
