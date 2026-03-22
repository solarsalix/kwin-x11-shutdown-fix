# KWin X11 Shutdown Fix
System shutdown script to fix the kwin_x11 bug occurring with proprietary Nvidia drivers (KWin occasionally hangs on shutdown). 
This script may also address other scenarios where KWin hangs during the reboot or shutdown process.

## Issue
During system shutdown, the KWin service may hang (stuck at "plasma-kwin_x11.service/stop running...") because KWin attempts to access the Nvidia driver context after it has already been cleared.

## Solution
This script ensures KWin terminates gracefully before the global system shutdown sequence begins, thereby preventing the service from attempting to access a non-existent context:
   1. **Saves State:** Sends a `qdbus` command to KWin to save parameters (widgets, menu history, etc.).
   2. **Graceful Stop:** Sends a soft termination signal `SIGTERM` (`pkill -15`).
   3. **Force Close:** If the process hangs, it sends a `SIGKILL` to KWin for the current user (`pkill -u "$USER_ID" -9 kwin_x11`). This is safe at this stage since data has already been synchronized.
   4. **Final Cleanup:** Performs a filesystem sync (`sync`) and flushes logs (`journalctl --flush`).

## Installation
   1. **Script:** Place the executable file in the following directory: 
    `~/.local/bin/kwin-x11-shutdown-hang-fix.sh` 
    *(Make sure to grant execution permissions: `chmod +x ~/.local/bin/kwin-x11-shutdown-hang-fix.sh`)*
   2. **Service:** Place the unit file in the following directory: 
    `~/.config/systemd/user/kwin-x11-shutdown-hang-fix.service`

## Activation
Run the following command as the current user (**do not use sudo**):
```bash
systemctl --user enable --now kwin-x11-shutdown-hang-fix.service
```

## Monitoring & Debugging
To verify the script's operation or review logs from previous sessions, use the following commands:
  * **System Log:**
    ```bash
    journalctl --user -u kwin-x11-shutdown-hang-fix.service
    ```
  * **Script internal Log**
      ```bash
    journalctl -t KWIN_SHUTDOWN_FIX
    ```

## Why is it safe?
The script first forces the session state to save. Even if a `SIGKILL` occurs at the end, your desktop settings, widgets, and application history remain intact, and the system shuts down instantly without hanging.
