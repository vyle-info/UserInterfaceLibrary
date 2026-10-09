-- Toggle Aimbot Keybind
KeybindsTab:AddLeftGroupbox("Hotkey 1")
    :AddLabel("Selected Hotkey:")
    :AddKeyPicker("GetSkinKeybind", {
        Default = nil,
        Text = "Hotkey"
    })
task.defer(function()
    Options.GetSkinKeybind:OnClick(function()
        Library:Notify({
            Title = "Marden Interface Notification",
            Description = "You toggled / enabled",
            SoundId = SelectedNotificationSound,
            Time = 8
        })
    end)
end)

-- Toggle FOV Circle Keybind
KeybindsTab:AddRightGroupbox("Hotkey 2")
    :AddLabel("Selected Hotkey:")
    :AddKeyPicker("RevertSkinKeybind", {
        Default = nil,
        Text = "Hotkey"
    })
task.defer(function()
    Options.RevertSkinKeybind:OnClick(function()
        Library:Notify({
            Title = "Marden Interface Notification",
            Description = "You toggled / enabled",
            SoundId = SelectedNotificationSound,
            Time = 8
        })
    end)
end)
