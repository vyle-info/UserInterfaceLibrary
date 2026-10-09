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
