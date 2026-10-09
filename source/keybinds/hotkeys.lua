local function FlipToggle(toggleName, label)
    local toggle = Toggles[toggleName]
    if not toggle then return end

    local newState = not toggle.Value
    toggle:SetValue(newState)

    Library:Notify({
        Title = "Marden Interface Notification",
        Description = label .. (newState and " enabled" or " disabled"),
        SoundId = SelectedNotificationSound,
        Time = 8
    })
end

-- Hotkey 1: Outline Boxes (GlobalBoxVisuals)
KeybindsTab:AddLeftGroupbox("Visualize Outline Boxes")
    :AddLabel("Selected Hotkey:")
    :AddKeyPicker("OutlineBoxesKeybind", {
        Default = nil,
        Text = "Hotkey",
        Mode = "Toggle",
    })

task.defer(function()
    Options.OutlineBoxesKeybind:OnClick(function()
        FlipToggle("GlobalBoxVisuals", "Outline Boxes")
    end)
end)

-- Hotkey 2: Fill Boxes (VisualizeFillBoxes)
KeybindsTab:AddRightGroupbox("Visualize Fill Boxes")
    :AddLabel("Selected Hotkey:")
    :AddKeyPicker("FillBoxesKeybind", {
        Default = nil,
        Text = "Hotkey",
        Mode = "Toggle",
    })

task.defer(function()
    Options.FillBoxesKeybind:OnClick(function()
        FlipToggle("VisualizeFillBoxes", "Fill Boxes")
    end)
end)

-- Hotkey 3: Teammates (VisualizeTeammates)
KeybindsTab:AddLeftGroupbox("Visualize Teammates")
    :AddLabel("Selected Hotkey:")
    :AddKeyPicker("TeammatesBoxesKeybind", {
        Default = nil,
        Text = "Hotkey",
        Mode = "Toggle",
    })

task.defer(function()
    Options.TeammatesBoxesKeybind:OnClick(function()
        FlipToggle("VisualizeTeammates", "Teammates")
    end)
end)

-- Hotkey 4: Box Visibility (DetectBoxVisibility)
KeybindsTab:AddRightGroupbox("Visualize Box Visibility")
    :AddLabel("Selected Hotkey:")
    :AddKeyPicker("VisibilityBoxesKeybind", {
        Default = nil,
        Text = "Hotkey",
        Mode = "Toggle",
    })

task.defer(function()
    Options.VisibilityBoxesKeybind:OnClick(function()
        FlipToggle("DetectBoxVisibility", "Box Visibility")
    end)
end)
