#!/bin/bash

# Enhanced Red Team Cleanup Script for Debian Bookworm
# Run with sudo for full effectiveness

echo "Starting comprehensive cleanup procedure..."

# Clear system logs more thoroughly
echo "Clearing system logs..."
sudo journalctl --vacuum-time=0s
sudo find /var/log -type f -name "*.log" -exec sh -c 'echo "" > {}' \;
sudo find /var/log -type f -name "*.gz" -delete
sudo find /var/log -type f -name "*.1" -delete
sudo rm -f /var/log/auth.log* /var/log/syslog* /var/log/kern.log* /var/log/messages*
sudo rm -f /var/log/apt/history.log* /var/log/apt/term.log*
sudo rm -f /var/log/dpkg.log*

# Clear temporary files and caches
echo "Clearing temporary files and caches..."
sudo rm -rf /tmp/* /var/tmp/*
rm -rf ~/.cache/*
sudo rm -rf /root/.cache/*
rm -rf ~/.local/share/Trash/*
sudo rm -rf /root/.local/share/Trash/*

# Clear browser data comprehensively
echo "Clearing browser data..."

# Firefox
FIREFOX_PROFILE_DIR="$HOME/.mozilla/firefox"
if [ -d "$FIREFOX_PROFILE_DIR" ]; then
    find "$FIREFOX_PROFILE_DIR" -name "*.sqlite" -delete
    find "$FIREFOX_PROFILE_DIR" -name "cookies.sqlite" -delete
    find "$FIREFOX_PROFILE_DIR" -name "places.sqlite" -delete
    find "$FIREFOX_PROFILE_DIR" -name "formhistory.sqlite" -delete
    find "$FIREFOX_PROFILE_DIR" -name "webappsstore.sqlite" -delete
    rm -rf "$FIREFOX_PROFILE_DIR"/*/cache2/*
    rm -rf "$FIREFOX_PROFILE_DIR"/*/thumbnails/*
    rm -f "$FIREFOX_PROFILE_DIR"/*/sessionstore.*
    rm -f "$FIREFOX_PROFILE_DIR"/*/recovery.*
fi

# Chromium/Chrome
CHROMIUM_DIR="$HOME/.config/chromium"
if [ -d "$CHROMIUM_DIR" ]; then
    rm -rf "$CHROMIUM_DIR/Default/"{"Cache","Cookies","History","Visited Links","Web Data"}
    rm -rf "$CHROMIUM_DIR"/*/{"Cache","Cookies","History","Visited Links","Web Data"}
fi

# Google Chrome
CHROME_DIR="$HOME/.config/google-chrome"
if [ -d "$CHROME_DIR" ]; then
    rm -rf "$CHROME_DIR/Default/"{"Cache","Cookies","History","Visited Links","Web Data"}
    rm -rf "$CHROME_DIR"/*/{"Cache","Cookies","History","Visited Links","Web Data"}
fi

# Clear systemd user journals
echo "Clearing user journals..."
journalctl --user --vacuum-time=0s 2>/dev/null || true

# Clear bash history and shell logs
echo "Clearing shell history..."
rm -f ~/.bash_history
rm -f ~/.zsh_history
rm -f ~/.node_repl_history
rm -f ~/.python_history
rm -f ~/.sqlite_history
rm -f ~/.wget-hsts
rm -f ~/.lesshst
rm -f ~/.mysql_history

# Clear root history
sudo rm -f /root/.bash_history
sudo rm -f /root/.zsh_history

# Clear current session history
history -c
if [ -n "$ZSH_VERSION" ]; then
    history -p
fi

# Clear SSH and keys
echo "Clearing SSH data..."
rm -f ~/.ssh/known_hosts
rm -f ~/.ssh/known_hosts.old

# Clear system caches
echo "Clearing system caches..."
sudo apt-get clean
sudo apt-get autoclean

# Clear memory caches (requires root)
echo "Clearing memory caches..."
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

# Clear swap (warning: this will remove all data from swap)
echo "Clearing swap space..."
sudo swapoff -a && sudo swapon -a

# Clear recent documents
echo "Clearing recent documents..."
rm -f ~/.local/share/recently-used.xbel
rm -rf ~/.local/share/Recent/*

# Clear thumbnails
echo "Clearing thumbnails..."
rm -rf ~/.cache/thumbnails/*
rm -rf ~/.thumbnails/*

# Clear trash
echo "Clearing trash..."
rm -rf ~/.local/share/Trash/*

# Clear package manager logs
echo "Clearing package manager logs..."
sudo rm -f /var/log/apt/history.log*
sudo rm -f /var/log/apt/term.log*
sudo rm -f /var/log/dpkg.log*

# Clear kernel logs
echo "Clearing kernel logs..."
sudo dmesg -c > /dev/null

# Clear systemd logs more aggressively
echo "Clearing systemd logs..."
sudo systemctl stop systemd-journald
sudo rm -rf /var/log/journal/*
sudo systemctl start systemd-journald

# Clear user activity logs
echo "Clearing user activity logs..."
rm -rf ~/.local/share/gvfs-metadata/*
rm -f ~/.local/share/recently-used.xbel

# Clear DNS cache
echo "Clearing DNS cache..."
sudo systemd-resolve --flush-caches 2>/dev/null || true
sudo /etc/init.d/nscd restart 2>/dev/null || true

# Clear clipboard
echo "Clearing clipboard..."
echo "" | xclip -selection clipboard
echo "" | xclip -selection primary

# Secure delete with multiple passes (if shred is available)
echo "Performing secure deletion..."
if command -v shred >/dev/null 2>&1; then
    # Securely delete sensitive files that were "deleted"
    find /tmp -type f -exec shred -zuf {} \; 2>/dev/null || true
    find ~/.cache -type f -exec shred -zuf {} \; 2>/dev/null || true
fi

# Fill free space with zeros (optional - very thorough but slow)
# echo "Wiping free space (this may take a while)..."
# if command -v shred >/dev/null 2>&1; then
#     shred -n 1 -z -v /tmp/fillfile 2>/dev/null || true
#     rm -f /tmp/fillfile
# fi

# Clear audit logs
echo "Clearing audit logs..."
sudo systemctl stop auditd 2>/dev/null || true
sudo rm -f /var/log/audit/audit.log*
sudo systemctl start auditd 2>/dev/null || true

echo "Cleanup completed. Consider shutting down now."

# Optional: Shutdown after cleanup
# echo "Shutting down in 10 seconds..."
# sleep 10
# sudo shutdown -h now
