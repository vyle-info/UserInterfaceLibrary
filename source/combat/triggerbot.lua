local TriggerbotGroupBox = CombatTab:AddGroupbox({
    Side = "Right",
    Name = "Triggerbot (v3)",
})

TriggerbotGroupBox:AddToggle("TriggerbotToggle1", {
    Text = "Triggerbot",
    Default = false,
})

TriggerbotGroupBox:AddSlider("TriggerBotDelay", {
    Text = "Triggerbot Delay",
    Default = 10,
    Min = 0,
    Max = 200,
    Rounding = 1,
    Suffix = "ms",
})

TriggerbotGroupBox:AddDropdown("ModeSelection", {
    Text = "Triggerbot Mode",
    Values = { "Default", "Rapid", "Hold" },
    Multi = false,
    Searchable = true,
    Default = { "Default" },
})

TriggerbotGroupBox:AddDropdown("BodyPartSelection", {
    Text = "Targeted Body Parts",
    Values = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" },
    Multi = true,
    Searchable = true,
    Visible = true,
    Default = { "Head" },
})
