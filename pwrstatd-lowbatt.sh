#!/bin/bash
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
logfile="/var/log/UPS/ups_low-power_shutdown-${timestamp}.log"
logstamp() {
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$logfile"
}
logstamp "UPS low battery protective shutdown sequence initiated..."
echo "WARNING: THE UPS BATTERY THRESHOLD HAS BEEN MET (<35%). THE SYSTEM PROTECTIVE SHUTDOWN SEQUENCE HAS BEEN INITIATED. DO NOT TOUCH THE COMPUTER AT THIS STAGE." | wall
systemd-run --machine=asha@.host --user notify-send --expire-time=0 --urgency=critical "WARNING: UPS battery threshold met (<35%). Protective shutdown sequence initiated." --icon=battery-caution --category=system.power &
logstamp "Playing alarm..." && machinectl shell --uid=asha .host /usr/bin/pw-play /home/asha/Music/Samples/st._louis_mo_tornado_warning.wav &
logstamp "Syncing filesystems..."
if sync; then
	logstamp "Sync complete."
else
	exitcode=$?
	logstamp "WARNING: Sync command failed with exit code $exitcode. Data not secured."
fi
sleep 2
logstamp "Dismounting VeraCrypt volumes if present..."
if veracrypt -df; then
	logstamp "VeraCrypt dismount completed."
else
	exitcode=$?
	logstamp "WARNING: VeraCrypt dismount failed with exit code $exitcode. Potentially unclean dismount."
fi
logstamp "Checking active process for /mnt/JARNSAXA..."
if lsof +D /mnt/JARNSAXA > /dev/null 2>&1; then
    logstamp "Process identified on /mnt/JARNSAXA, attempting to terminate..."
    pids=$(lsof -t +D /mnt/JARNSAXA 2>/dev/null | grep -v '^$')
    if [ -n "$pids" ]; then
        logstamp "Sending SIGTERM (gentle) to process: $pids."
        kill $pids 2>/dev/null
        sleep 2
        pidremain=$(lsof -t +D /mnt/JARNSAXA 2>/dev/null | grep -v '^$')
        if [ -n "$pidremain" ]; then
            logstamp "Pesky process pestering persistent, sending SIGKILL (rough!) to: $pidremain."
            kill -9 $pidremain 2>/dev/null
            sleep 2
        fi
    fi
    logstamp "Process termination completed."
else
	logstamp "No process found using /mnt/JARNSAXA."
fi
logstamp "Dismounting JARNSAXA..."
if mountpoint -q /mnt/JARNSAXA; then
	if umount -vf /mnt/JARNSAXA; then
		logstamp "JARNSAXA dismounted."
	else
		exitcode=$?
		logstamp "WARNING: JARNSAXA failed to dismount with exit code $exitcode. If the drive was disconnected ignore this error, otherwise consider filesystem analysis and repair with xfs_repair."
	fi
else
	logstamp "JARNSAXA is not mounted, skipping dismount."
fi
sleep 2
if [ -e /dev/mapper/JARNSAXA ]; then
	logstamp "Closing LUKS container..."
	if dmsetup remove --force /dev/mapper/JARNSAXA; then
		logstamp "LUKS container /dev/mapper/JARNSAXA closed."
	else
		exitcode=$?
		logstamp "WARNING: LUKS closure failed with exit code $exitcode."
	fi
else
	logstamp "LUKS container /dev/mapper/JARNSAXA is not open, skipping closure."
fi
if systemctl is-active --quiet systemd-cryptsetup@JARNSAXA.service; then
	logstamp "Stopping systemd-cryptsetup service for JARNSAXA..."
	if systemctl stop systemd-cryptsetup@JARNSAXA.service; then
		logstamp "Service successfully stopped."
	else
		exitcode=$?
		logstamp "WARNING: Service stop failure with exit code $exitcode."
	fi
else
	logstamp "systemd-cryptsetup@JARNSAXA.service is not active, skipping stoppage."
fi
logstamp "Spinning down drive..."
if hdparm -Y /dev/disk/by-id/ata-WUH721816ALE6L4_3WK0P99P; then
	logstamp "Drive /dev/disk/by-id/ata-WUH721816ALE6L4_3WK0P99P successfully spun down."
else
	exitcode=$?
	logstamp "WARNING: Drive spin-down failed and/or returned an exit code of $exitcode. If the drive was disconnected ignore this error, otherwise analyse SMART data for reallocation."
fi
logstamp "UPS low battery protective shutdown sequence completed. Proceeding to shutdown..."
machinectl shell --uid=asha .host /usr/bin/pw-play /home/asha/Music/Samples/windows_xp_shutdown.wav &
echo "Shleep now..."
exit 0
