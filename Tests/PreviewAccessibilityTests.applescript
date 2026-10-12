tell application "System Events"
    tell process "MarkD"
        set frontmost to true
        set appWindow to front window
        set modePicker to radio group 1 of group 1 of toolbar 1 of appWindow
        click radio button 2 of modePicker
        delay 0.5

        set mainHeadingFound to false
        set secondaryHeadingFound to false

        set allElements to entire contents of appWindow
        repeat with candidate in allElements
            try
                if role of candidate is "AXHeading" then
                    set candidateDescription to description of candidate
                    if candidateDescription is "Theme Test" then
                        set mainHeadingFound to true
                    else if candidateDescription is "Secondary heading" then
                        set secondaryHeadingFound to true
                    end if
                end if
            end try
        end repeat

        if mainHeadingFound is not true then
            error "Preview H1 is not exposed with AXHeading role"
        end if
        if secondaryHeadingFound is not true then
            error "Preview H2 is not exposed with AXHeading role"
        end if

        click radio button 1 of modePicker
    end tell
end tell

return "PreviewAccessibilityTests: passed"
