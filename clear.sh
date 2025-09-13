#!/bin/bash

# Clear system logs
echo "Clearing system logs..."
sudo journalctl --vacuum-time=1d

# Clear temporary files
echo "Clearing temporary files..."
sudo rm -rf /tmp/*

# Clear Firefox cache and sessions
echo "Clearing Firefox cache and sessions..."
FIREFOX_PROFILE_DIR="$HOME/.mozilla/firefox"
if [ -d "$FIREFOX_PROFILE_DIR" ]; then
    # Remove cache
    rm -rf "$FIREFOX_PROFILE_DIR/*/cache2/*"
    # Remove session files
    rm -f "$FIREFOX_PROFILE_DIR/*/recovery.jsonlz4"
    rm -f "$FIREFOX_PROFILE_DIR/*/recovery.baklz4"
    rm -f "$FIREFOX_PROFILE_DIR/*/previous.jsonlz4"
    echo "Firefox cache and sessions cleared."
else
    echo "Firefox profile directory not found."
fi

# Delete Firefox history file
echo "Deleting Firefox history file..."
rm -f "$FIREFOX_PROFILE_DIR/*/places.sqlite"

# Delete .bash_history file
echo "Deleting .bash_history file..."
rm -f "$HOME/.bash_history"

# Optionally, clear the current shell's history
history -c

echo "Cleanup completed."
