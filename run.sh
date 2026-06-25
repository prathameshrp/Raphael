#!/usr/bin/env bash

# Stoic Habit Tracker: Raphael Widget Setup & Orchestration Script
set -e

WORKSPACE_DIR="/home/nyanyra/.local/share/plasma/plasmoids/raphael"
DAEMON_SCRIPT="${WORKSPACE_DIR}/contents/ui/daemon/raphael_core_daemon.py"
DAEMON_LOG="${WORKSPACE_DIR}/daemon.log"
PORT=5757

echo "============================================="
echo "Initializing Raphael Cognitive Advisor Setup"
echo "============================================="

# 1. Check Python Daemon Executability
if [ ! -f "$DAEMON_SCRIPT" ]; then
    echo "Error: Daemon script not found at ${DAEMON_SCRIPT}"
    exit 1
fi
chmod +x "$DAEMON_SCRIPT"

# 2. Stop existing daemon instances running on port 5757
echo "Stopping any existing Raphael daemon instances..."
pkill -f raphael_core_daemon.py || true
python3 -c "
import os, signal
def kill_port(port):
    port_hex = f'{port:04X}'
    inodes = []
    try:
        with open('/proc/net/tcp', 'r') as f:
            for line in f.readlines()[1:]:
                parts = line.strip().split()
                if parts[1].split(':')[1] == port_hex:
                    inodes.append(parts[9])
    except: pass
    if not inodes: return
    for pid in os.listdir('/proc'):
        if pid.isdigit():
            try:
                for fd in os.listdir(f'/proc/{pid}/fd'):
                    link = os.readlink(f'/proc/{pid}/fd/{fd}')
                    if any(inode in link for inode in inodes):
                        os.kill(int(pid), signal.SIGKILL)
                        print(f'Terminated process {pid} on port {port}')
                        return
            except: pass
kill_port(5757)
" || true
sleep 1

# 3. Start Python Daemon in Background
echo "Launching Raphael core daemon in the background..."
nohup python3 "$DAEMON_SCRIPT" > "$DAEMON_LOG" 2>&1 &
NEW_PID=$!
sleep 2

# Check if daemon is still running
if kill -0 "$NEW_PID" 2>/dev/null; then
    echo "Raphael core daemon started successfully (PID: ${NEW_PID})."
    echo "Logs are available at ${DAEMON_LOG}"
else
    echo "Error: Raphael daemon failed to start. Last log lines:"
    tail -n 15 "$DAEMON_LOG"
    exit 1
fi

# 4. Desktop Widget Notice
echo "Info: Daemon is running. Add the 'Raphael' widget manually from your Plasma widgets panel if it is not already present."

# 5. Inform user on how to force reload QML files if they are not updating live
echo "---------------------------------------------"
echo "Raphael is fully initialized!"
echo "If you made visual QML changes, you can force-reload plasmashell by running:"
echo "  killall plasmashell && kstart plasmashell"
echo "============================================="
