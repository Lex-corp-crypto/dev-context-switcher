#!/bin/bash
# Launches a terminal in the specified working directory and optionally runs a command
# Usage: launch_terminal.sh <working_directory> [command]
WORKING_DIR=$1
COMMAND=${2:-""}

# Use x-terminal-emulator if available, otherwise fall back to common terminals
if command -v x-terminal-emulator &> /dev/null; then
    TERMINAL="x-terminal-emulator"
elif command -v gnome-terminal &> /dev/null; then
    TERMINAL="gnome-terminal"
elif command -v konsole &> /dev/null; then
    TERMINAL="konsole"
elif command -v xfce4-terminal &> /dev/null; then
    TERMINAL="xfce4-terminal"
elif command -v alacritty &> /dev/null; then
    TERMINAL="alacritty"
else
    TERMINAL="xterm" # Fallback
fi

if [ -n "$COMMAND" ]; then
    $TERMINAL --working-directory="$WORKING_DIR" -e "$COMMAND" &
else
    $TERMINAL --working-directory="$WORKING_DIR" &
fi