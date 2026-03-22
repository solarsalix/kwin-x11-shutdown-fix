#!/bin/bash

#======================================================================
#
#   System shutdown script to fix the kwin_x11 bug
#   occurring with proprietary Nvidia drivers
#   (prevents random 90-second shutdown delay).
#
#======================================================================

# 1. Define variables: User ID and Logger Tag
USER_ID=$(id -u)
TAG="KWIN_SHUTDOWN_FIX"
# Set the DBUS_SESSION_BUS_ADDRESS to ensure qdbus commands work correctly.
# This prevents "Could not connect to D-Bus server" error by explicitly
# defining the bus path.
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus"

# 2. Locate the qdbus executable (could also be qdbus-qt5 or qdbus6).
QDBUS_BIN=$(command -v qdbus6 || command -v qdbus-qt5 || command -v qdbus)

# 3. Call qdbus to prepare kwin_x11 for graceful shutdown
if [ -z "$QDBUS_BIN" ]; then
    # 3.1. Log an error to the system journal (journalctl) if qdbus is not found.
    logger -t $TAG -p user.err "qdbus not found. Skipping reconfigure. Settings may not be saved properly."
else
    # 3.2. If qdbus is found, request KWin to sync its configuration.
    # (KWin normally syncs on shutdown, but not during a forced service termination.
    # This ensures settings are saved regardless of how the process ends)
    timeout 3s "$QDBUS_BIN" org.kde.KWin /KWin reconfigure
    logger -t $TAG -p user.info "kwin_x11 reconfigure performed successfully. Settings saved."
fi

# 4. Send SIGTERM to KWin for a clean exit.
# Wait 3 seconds for KWin to exit before proceeding
logger -t $TAG -p user.info "Closing kwin_x11."
pkill -15 kwin_x11
sleep 3

# 5. Kill kwin_x11 if it's still running or unresponsive
if pgrep -u "$USER_ID" -x kwin_x11 > /dev/null; then
    logger -t $TAG -p user.warning "kwin_x11 is stubborn. Perform SIGKILL (pkill -9) kwin_x11"
    pkill -u "$USER_ID" -9 kwin_x11
fi

# 6. Sync filesystem and pause for 2 seconds to ensure heads are parked
# (if the system runs on an HDD).
logger -t $TAG -p user.info "Sync file systems before shutdown"
sync
sleep 2
logger -t $TAG -p user.info "Sync performed successfully. Saving system log before shutdown."
journalctl --flush
logger -t $TAG -p user.info "System log saved successfully. Performing shutdown."
