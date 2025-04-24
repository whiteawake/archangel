#!/bin/bash
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
logdir="/var/log/UPS"
if [ ! -d "$logdir" ]; then
    mkdir -p "$logdir"
fi
logfile="/var/log/UPS/ups_powerfail-${timestamp}.log"
logstamp() {
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$logfile"
}
logstamp "Mains power supply disconnected. Initiating power failure log and alert..."
logstamp "Notifying user..." 
systemd-run --machine=asha@.host --user notify-send --expire-time=0 --urgency=critical "WARNING: Mains power supply has disconnected." --icon=battery-caution --category=system.power &
if [ $? -eq 0 ]; then
	warnpid=$!
	logstamp "User notified (PID: $warnpid)."
else
	logstamp "Unable to visually notify user."
fi
logstamp "Playing alarm..."
machinectl shell --uid=asha .host /usr/bin/pw-play /home/asha/Music/Samples/a300_fire_alarm.wav &
if [ $? -eq 0 ]; then
	alarmpid=$!
	logstamp "Alarm ringing (PID: $alarmpid)."
else
	logstamp "Unable to sound alarm."
fi
logstamp "Preemptive filesystem sync..."
if sync; then
	logstamp "Preemptive sync complete."
else
	exitcode=$?
	logstamp "WARNING: Sync command failed with exit code $exitcode. Data not secured."
fi
logstamp "Power failure log sequence completed. Protective shutdown sequence will initiate at <35% UPS battery power or 540 seconds remaining runtime capacity."
exit 0
