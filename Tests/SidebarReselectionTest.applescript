tell application "System Events"
    tell process "MarkD"
        set appWindow to front window
        set modePicker to radio group 1 of group 1 of toolbar 1 of appWindow
        click radio button 1 of modePicker
        delay 0.3

        if exists splitter group 1 of group 1 of appWindow then
            set splitView to splitter group 1 of group 1 of appWindow
        else
            set splitView to splitter group 1 of group 2 of appWindow
        end if
        set sidebarOutline to outline 1 of scroll area 1 of group 1 of splitView
        set editorScroller to scroll bar 1 of scroll area 1 of group 2 of splitView
        set lastRow to last row of sidebarOutline

        set selected of row 1 of sidebarOutline to true
        delay 0.2
        set selected of lastRow to true
        delay 0.3

        set value of editorScroller to 0
        delay 0.2
        click button 1 of UI element 1 of lastRow
        delay 0.3

        set finalPosition to value of editorScroller
        if finalPosition < 0.5 then
            error "Reselecting the active heading did not scroll again; position=" & finalPosition
        end if

        -- The same active outline row must work in rendered Preview as well.
        click radio button 2 of modePicker
        delay 0.5

        if exists splitter group 1 of group 1 of appWindow then
            set splitView to splitter group 1 of group 1 of appWindow
        else
            set splitView to splitter group 1 of group 2 of appWindow
        end if
        set sidebarOutline to outline 1 of scroll area 1 of group 1 of splitView
        set lastRow to last row of sidebarOutline
        set previewScroller to scroll area 1 of group 2 of splitView
        set previewBar to scroll bar 1 of previewScroller

        set value of previewBar to 0
        delay 0.2
        click button 1 of UI element 1 of lastRow
        delay 0.8

        set previewPosition to value of previewBar
        if previewPosition < 0.5 then
            error "Reselecting the active heading did not scroll Preview; position=" & previewPosition
        end if

        click radio button 1 of modePicker
    end tell
end tell

return "SidebarReselectionTest: passed"
