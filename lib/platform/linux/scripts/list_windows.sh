#!/bin/bash
# Lists visible windows with ID, name, and geometry
for id in $(xdotool search --onlyvisible --name ""); do
    name=$(xdotool getwindowname $id 2>/dev/null)
    geom=$(xdotool getwindowgeometry --shell $id 2>/dev/null)
    echo "---"
    echo "ID=$id"
    echo "NAME=$name"
    echo "$geom"
done