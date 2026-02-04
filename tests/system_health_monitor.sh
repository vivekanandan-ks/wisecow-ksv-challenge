#!/usr/bin/env bash
LOG_FILE="system_health.log"
CPU_TH=80; MEM_TH=80; DISK_TH=80; PROC_TH=300

log() { echo "${1}" | tee -a "$LOG_FILE"; }
check() { [[ $1 -ge $2 ]] && log "❌ ALERT: $3: $1% (>$2%)" || log "✅ OK: $3: $1%"; }

echo "--- Report $(date) ---"

# CPU (Using vmstat for instant accuracy without math)
# Run vmstat for 1 second, take the last line.
# Columns: r b swpd free buff cache si so bi bo in cs us sy id wa st
# We want 'id' (idle), which is usually column 15.
# We read into an array to handle whitespace automatically.
stats=($(vmstat 1 2 | tail -n 1))
cpu_idle=${stats[14]} 
cpu=$(( 100 - cpu_idle ))
check "$cpu" "$CPU_TH" "CPU Usage"

# Memory (Using vmstat is simpler but free -m is standard human readable)
# Let's use free directly with read to avoid awk
read _ total used _ < <(free -m | grep Mem:)
mem=$(( 100 * used / total ))
check "$mem" "$MEM_TH" "Memory Usage"

# Disk (df with --output=pcent)
read pcent < <(df --output=pcent / | tail -n 1)
disk=${pcent%\%}
check "$disk" "$DISK_TH" "Disk Usage"

# Processes (Native glob counting)
procs=$(ls -d /proc/[0-9]* | wc -l)
[[ $procs -ge $PROC_TH ]] && log "❌ ALERT: Processes: $procs (>$PROC_TH)" || log "✅ OK: Processes: $procs"

echo "-----------------------"
