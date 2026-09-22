#!/bin/bash
# Moves and resizes a window
# Usage: move_window.sh <window_id> <x> <y> <width> <height>
WINDOW_ID=$1
X=$2
Y=$3
WIDTH=$4
HEIGHT=$5

xdotool windowmove $WINDOW_ID $X $Y
xdotool windowsize $WINDOW_ID $WIDTH $HEIGHT