#!/bin/bash
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
logfile="/var/log/UPS/ups_powerfail-${timestamp}.log"
logstamp() {
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$logfile"
}
logstamp "Mains power supply disconnected. Initiating power failure log and alert..."
logstamp "Notifying user..." && systemd-run --machine=asha@.host --user notify-send --expire-time=0 --urgency=critical "WARNING: Mains power supply has disconnected." --icon=battery-caution --category=system.power &
logstamp "Playing alarm..." && machinectl shell --uid=asha .host /usr/bin/pw-play /home/asha/Music/Samples/a300_fire_alarm.wav &
logstamp "Preemptive filesystem sync..."
if sync; then
	logstamp "Preemtive sync complete."
else
	exit_code=$?
	logstamp "WARNING: Sync command failed with exit code $exit_code. Data not secured."
fi
logstamp "Power failure log sequence completed. Protective shutdown sequence will initiate at <35% UPS battery power."
exit 0
