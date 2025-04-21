#!/bin/bash
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
logfile="/var/log/UPS/ups_low-power_shutdown-${timestamp}.log"
logstamp() {
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$logfile"
}
logstamp "UPS low battery protective shutdown sequence initiated..."
echo "WARNING: The UPS battery threshold has been met (<35%). The system protective shutdown sequence has been initiated. Do not touch the computer at this stage." | wall
systemd-run --machine=asha@.host --user notify-send --expire-time=0 --urgency=critical "WARNING: UPS battery threshold met (<35%). Protective shutdown sequence initiated." --icon=battery-caution --category=system.power &
logstamp "Playing alarm..." && machinectl shell --uid=asha .host /usr/bin/pw-play /home/asha/Music/Samples/st._louis_mo_tornado_warning.wav &
logstamp "Syncing filesystems..."
if sync; then
	logstamp "Sync complete."
else
	exitcode=$?
	logstamp "WARNING: Sync command failed with exit code $exitcode. Data not secured."
fi
sleep 10
logstamp "Dismounting VeraCrypt volumes if present..."
if veracrypt -d; then
	logstamp "VeraCrypt dismount completed."
else
	exitcode=$?
	logstamp "WARNING: VeraCrypt dismount failed with exit code $exitcode. Potentially unclean dismount."
fi
logstamp "Dismounting <?> if present..."
if umount -v /mnt/<?>; then
	logstamp "<?> dismount completed."
else
	exitcode=$?
	logstamp "WARNING: <?> failed to dismount with exit code $exitcode. If the drive was disconnected ignore this error, otherwise consider filesystem analysis and repair with xfs_repair."
fi
sleep 5
logstamp "Closing LUKS container..."
if cryptsetup luksClose /dev/mapper/<?>; then
	logstamp "LUKS container /dev/mapper/<?> closed."
else
	exitcode=$?
	logstamp "WARNING: LUKS closure failed with exit code $exitcode. If the drive was disconnected ignore this error."
fi
sleep 3
logstamp "Stopping systemd-cryptsetup service..."
if systemctl stop systemd-cryptsetup@<?>.service; then
	logstamp "Service successfully/confirmed stopped."
else
	exitcode=$?
	logstamp "WARNING: Service stop failure with exit code $exitcode."
fi
logstamp "Spinning down drive..."
if hdparm -y /dev/disk/by-id/<?>; then
	logstamp "Drive /dev/disk/by-id/<?> successfully spun down."
else
	exitcode=$?
	logstamp "WARNING: Drive spin-down failed and/or returned and exit code of $exitcode. If the drive was disconnected ignore this error, otherwise analyse SMART data for reallocation."
fi
logstamp "UPS low battery protective shutdown sequence completed. Proceeding to shutdown..."
machinectl shell --uid=asha .host /usr/bin/pw-play /home/asha/Music/Samples/windows_xp_shutdown.wav &
exit 0
