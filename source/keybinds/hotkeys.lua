-- Hotkey 1: Outline Boxes
KeybindsTab:AddLeftGroupbox("Visualize Outline Boxes")
    :AddLabel("Selected Hotkey:")
    :AddKeyPicker("OutlineBoxesKeybind", {
        Default = nil,
        Text = "Hotkey",
    })
task.defer(function()
    Options.OutlineBoxesKeybind:OnClick(function()
        Library:Notify({
            Title = "Marden Interface Notification",
            Description = "Toggled / Enabled Outline Box Visualization",
            SoundId = SelectedNotificationSound,
            Time = 8
        })
    end)
end)

-- Hotkey 2: Fill Boxes
KeybindsTab:AddRightGroupbox("Visualize Fill Boxes")
    :AddLabel("Selected Hotkey:")
    :AddKeyPicker("FillBoxesKeybind", {
        Default = nil,
        Text = "Hotkey",
    })
task.defer(function()
    Options.FillBoxesKeybind:OnClick(function()
        Library:Notify({
            Title = "Marden Interface Notification",
            Description = "Toggled / Enabled Fill Box Visualization",
            SoundId = SelectedNotificationSound,
            Time = 8
        })
    end)
end)

-- Hotkey 3: Teammates
KeybindsTab:AddLeftGroupbox("Visualize Teammates")
    :AddLabel("Selected Hotkey:")
    :AddKeyPicker("TeammatesBoxesKeybind", {
        Default = nil,
        Text = "Hotkey",
    })
task.defer(function()
    Options.TeammatesBoxesKeybind:OnClick(function()
        Library:Notify({
            Title = "Marden Interface Notification",
            Description = "Toggled / Enabled Teammate Box Visualization",
            SoundId = SelectedNotificationSound,
            Time = 8
        })
    end)
end)

-- Hotkey 4: Box Visibility
KeybindsTab:AddRightGroupbox("Visualize Box Visibility")
    :AddLabel("Selected Hotkey:")
    :AddKeyPicker("VisibilityBoxesKeybind", {
        Default = nil,
        Text = "Hotkey",
    })
task.defer(function()
    Options.VisibilityBoxesKeybind:OnClick(function()
        Library:Notify({
            Title = "Marden Interface Notification",
            Description = "Toggled / Enabled Box Visibility",
            SoundId = SelectedNotificationSound,
            Time = 8
        })
    end)
end)



-- Hotkey 5: Outline Highlights
KeybindsTab:AddLeftGroupbox("Visualize Outline Highlights")
    :AddLabel("Selected Hotkey:")
    :AddKeyPicker("OutlineHighlightsKeybind", {
        Default = nil,
        Text = "Hotkey",
    })
task.defer(function()
    Options.OutlineHighlightsKeybind:OnClick(function()
        Library:Notify({
            Title = "Marden Interface Notification",
            Description = "Toggled / Enabled Outline Highlight Visualization",
            SoundId = SelectedNotificationSound,
            Time = 8
        })
    end)
end)

-- Hotkey 6: Fill Highlights
KeybindsTab:AddRightGroupbox("Visualize Fill Highlights")
    :AddLabel("Selected Hotkey:")
    :AddKeyPicker("FillHighlightsKeybind", {
        Default = nil,
        Text = "Hotkey",
    })
task.defer(function()
    Options.FillHighlightsKeybind:OnClick(function()
        Library:Notify({
            Title = "Marden Interface Notification",
            Description = "Toggled / Enabled Fill Highlight Visualization",
            SoundId = SelectedNotificationSound,
            Time = 8
        })
    end)
end)

-- Hotkey 7: Highlight Teammates
KeybindsTab:AddLeftGroupbox("Visualize Highlight Teammates")
    :AddLabel("Selected Hotkey:")
    :AddKeyPicker("TeammatesHighlightsKeybind", {
        Default = nil,
        Text = "Hotkey",
    })
task.defer(function()
    Options.TeammatesHighlightsKeybind:OnClick(function()
        Library:Notify({
            Title = "Marden Interface Notification",
            Description = "Toggled / Enabled Teammate Highlight Visualization",
            SoundId = SelectedNotificationSound,
            Time = 8
        })
    end)
end)

-- Hotkey 8: Highlight Visibility
KeybindsTab:AddRightGroupbox("Visualize Highlight Visibility")
    :AddLabel("Selected Hotkey:")
    :AddKeyPicker("VisibilityHighlightsKeybind", {
        Default = nil,
        Text = "Hotkey",
    })
task.defer(function()
    Options.VisibilityHighlightsKeybind:OnClick(function()
        Library:Notify({
            Title = "Marden Interface Notification",
            Description = "Toggled / Enabled Highlight Visibility",
            SoundId = SelectedNotificationSound,
            Time = 8
        })
    end)
end)
