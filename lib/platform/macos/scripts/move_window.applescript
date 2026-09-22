-- Moves and resizes a window
-- Usage: move_window.applescript <window_id> <x> <y> <width> <height>
on run argv
    if (length of argv) < 4 then
        error "Usage: move_window.applescript <window_id> <x> <y> <width> <height>"
    end if

    set windowId to item 1 of argv
    set x to (item 2 of argv as integer)
    set y to (item 3 of argv as integer)
    set width to (item 4 of argv as integer)
    set height to (item 5 of argv as integer)

    tell application "System Events"
        set found to false
        repeat with aProcess in (every process whose background only is false)
            try
                repeat with aWindow in (every window of aProcess)
                    if (value of attribute "AXIdentifier" of aWindow) is equal to windowId then
                        set position of aWindow to {x, y}
                        set size of aWindow to {width, height}
                        set found to true
                        exit repeat
                    end if
                end repeat
            end try
            if found then exit repeat
        end repeat
    end tell

    if not found then
        error "Window with ID " & windowId & " not found"
    end if
end run