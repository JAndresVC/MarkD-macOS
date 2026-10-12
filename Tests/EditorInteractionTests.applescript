tell application "System Events"
    tell process "MarkD"
        set frontmost to true
        set appWindow to front window
        set modePicker to radio group 1 of group 1 of toolbar 1 of appWindow

        if exists splitter group 1 of group 1 of appWindow then
            set splitView to splitter group 1 of group 1 of appWindow
        else
            set splitView to splitter group 1 of group 2 of appWindow
        end if

        set editorScroller to scroll area 1 of group 2 of splitView
        set editorTextArea to text area 1 of editorScroller

        -- Returning from Preview should put the caret back where the user left it.
        click radio button 1 of modePicker
        set focused of editorTextArea to true
        delay 0.2
        if not (value of attribute "AXFocused" of editorTextArea) then
            error "Could not focus the editor before the mode switch"
        end if

        keystroke "2" using command down
        delay 0.3
        keystroke "1" using command down
        delay 0.5
        if not (value of attribute "AXFocused" of editorTextArea) then
            error "Editor focus was not restored after Preview"
        end if

        -- The native Find bar must work in both editable and read-only source modes.
        keystroke "f" using command down
        delay 0.4
        if not (exists text field 1 of editorScroller) then
            error "Cmd+F did not open Find in Edit mode"
        end if
        click button "Done" of editorScroller

        click radio button 3 of modePicker
        set focused of editorTextArea to true
        keystroke "f" using command down
        delay 0.4
        if not (exists text field 1 of editorScroller) then
            error "Cmd+F did not open Find in RAW mode"
        end if
        click button "Done" of editorScroller
        click radio button 1 of modePicker
    end tell
end tell

return "EditorInteractionTests: passed"
