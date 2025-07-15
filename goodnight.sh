#!/bin/bash
set -x
pw-play ~/Music/Samples/windows_xp_shutdown.wav &

sudo pacman -Syuv --noconfirm
yay -Yc --noconfirm
paccache -rk1 && paccache -ruk0

echo "Syncing filesystems…"
if sync; then
	echo "Sync complete."
else
	exitcode=$?
	echo "WARNING: Sync command failed with exit code $exitcode. Data not secured."
fi
sleep 2
echo "Dismounting VeraCrypt volumes if present…"
if veracrypt -df; then
	echo "VeraCrypt dismount completed."
else
	exitcode=$?
	echo "WARNING: VeraCrypt dismount failed with exit code $exitcode. Potentially unclean dismount."
fi
echo "Checking active process for /mnt/JARNSAXA…"
if lsof /mnt/JARNSAXA > /dev/null 2>&1; then
    echo "Process identified on /mnt/JARNSAXA, attempting to terminate…"
    pids=$(lsof -t /mnt/JARNSAXA 2>/dev/null | grep -v '^$')
    if [ -n "$pids" ]; then
        echo "Sending SIGTERM (gentle) to process: $pids."
        kill $pids 2>/dev/null
        sleep 2
        pidremain=$(lsof -t /mnt/JARNSAXA 2>/dev/null | grep -v '^$')
        if [ -n "$pidremain" ]; then
            echo "Pesky process pestering persistent, sending SIGKILL (rough!) to: $pidremain."
            kill -9 $pidremain 2>/dev/null
            sleep 2
        fi
    fi
    echo "Process termination completed."
else
	echo "No process found using /mnt/JARNSAXA."
fi
echo "Dismounting JARNSAXA…"
if mountpoint -q /mnt/JARNSAXA; then
	if umount -vf /mnt/JARNSAXA; then
		echo "JARNSAXA dismounted."
	else
		exitcode=$?
		echo "WARNING: JARNSAXA failed to dismount with exit code $exitcode. If the drive was disconnected ignore this error, otherwise consider filesystem analysis and repair with xfs_repair (whilst dismounted)."
	fi
else
	echo "JARNSAXA is not mounted, skipping dismount."
fi
sleep 2
if [ -e /dev/mapper/JARNSAXA ]; then
	echo "Closing LUKS container…"
	if dmsetup remove --force /dev/mapper/JARNSAXA; then
		echo "LUKS container /dev/mapper/JARNSAXA closed."
	else
		exitcode=$?
		echo "WARNING: LUKS closure failed with exit code $exitcode."
	fi
else
	echo "LUKS container /dev/mapper/JARNSAXA is not open, skipping closure."
fi
if systemctl is-active --quiet systemd-cryptsetup@JARNSAXA.service; then
	echo "Stopping systemd-cryptsetup service for JARNSAXA…"
	if systemctl stop systemd-cryptsetup@JARNSAXA.service; then
		echo "Service successfully stopped."
	else
		exitcode=$?
		echo "WARNING: Service stop failure with exit code $exitcode."
	fi
else
	echo "systemd-cryptsetup@JARNSAXA.service is not active, skipping stoppage."
fi
echo "Spinning down drive…"
if hdparm -Y /dev/disk/by-id/ata-WUH721816ALE6L4_3WK0P99P; then
	echo "Drive /dev/disk/by-id/ata-WUH721816ALE6L4_3WK0P99P successfully spun down."
else
	exitcode=$?
	echo "WARNING: Drive spin-down failed and/or returned an exit code of $exitcode. If the drive was disconnected ignore this error, otherwise analyse SMART data for reallocation."
fi
shutdown now &
exit 0