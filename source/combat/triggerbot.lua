local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local Workspace          = game:GetService("Workspace")
local Camera             = Workspace.CurrentCamera

local LocalPlayer        = Players.LocalPlayer
local Mouse              = LocalPlayer:GetMouse()

local State = {
    Enabled   = false,
    Delay     = 10,
    Mode      = "Default",   -- "Default" | "Rapid" | "Hold"
    BodyParts = { ["Head"] = true },
    LastShot  = 0,
    Holding   = false,
}

local BodyPartMap = {
    ["Head"]       = { "head" },
    ["Torso"]      = { "torso", "uppertorso", "lowertorso", "chest", "upperchest" },
    ["Left Arm"]   = { "leftarm", "left arm", "leftupperarm", "leftlowerarm" },
    ["Right Arm"]  = { "rightarm", "right arm", "rightupperarm", "rightlowerarm" },
    ["Left Leg"]   = { "leftleg", "left leg", "leftupperleg", "leftlowerleg" },
    ["Right Leg"]  = { "rightleg", "right leg", "rightupperleg", "rightlowerleg" },
}

local function isBodyPartEnabled(name)
    local lower = string.lower(name)
    for label, keywords in pairs(BodyPartMap) do
        if State.BodyParts[label] then
            for _, kw in ipairs(keywords) do
                if string.find(lower, kw, 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

local function getTargetPart()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end

    local mousePos = UserInputService:GetMouseLocation()
    local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character, cam }
    params.IgnoreWater = true

    local result = Workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
    if not result or not result.Instance then return nil end

    local part = result.Instance
    local model = part:FindFirstAncestorOfClass("Model")

    if not model then return nil end
    local owner = Players:GetPlayerFromCharacter(model)
    if not owner or owner == LocalPlayer then return nil end

    if not isBodyPartEnabled(part.Name) then return nil end

    return part, owner
end

local function fireOnce()
    pcall(function() mouse1click() end)
end

RunService.RenderStepped:Connect(function()
    if not State.Enabled then
        if State.Holding then
            State.Holding = false
            pcall(function() mouse1up() end)
        end
        return
    end

    local part = getTargetPart()
    local now = tick() * 1000

    if State.Mode == "Hold" then
        if part then
            if not State.Holding then
                pcall(function() mouse1down() end)
                State.Holding = true
            end
        else
            if State.Holding then
                pcall(function() mouse1up() end)
                State.Holding = false
            end
        end
        return
    end

    if not part then return end
    if (now - State.LastShot) < State.Delay then return end

    if State.Mode == "Rapid" then
        fireOnce()
        State.LastShot = now
    else
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            fireOnce()
            State.LastShot = now
        end
    end
end)

TriggerbotGroupBox:AddToggle("TriggerbotToggle1", {
    Text = "Triggerbot",
    Default = false,
})
TriggerbotGroupBox:AddToggle("TriggerbotToggle1").OnChanged:Connect(function(v)
    State.Enabled = v
    if not v and State.Holding then
        State.Holding = false
        pcall(function() mouse1up() end)
    end
end)

TriggerbotGroupBox:AddSlider("TriggerBotDelay", {
    Text = "Triggerbot Delay",
    Default = 10,
    Min = 0,
    Max = 200,
    Rounding = 1,
    Suffix = "ms",
})
TriggerbotGroupBox:AddSlider("TriggerBotDelay").OnChanged:Connect(function(v)
    State.Delay = v
end)

TriggerbotGroupBox:AddDropdown("ModeSelection", {
    Text = "Triggerbot Mode",
    Values = { "Default", "Rapid", "Hold" },
    Multi = false,
    Searchable = true,
    Default = { "Default" },
})
TriggerbotGroupBox:AddDropdown("ModeSelection").OnChanged:Connect(function(v)
    State.Mode = v or "Default"
    if State.Holding and State.Mode ~= "Hold" then
        State.Holding = false
        pcall(function() mouse1up() end)
    end
end)

TriggerbotGroupBox:AddDropdown("BodyPartSelection", {
    Text = "Targeted Body Parts",
    Values = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" },
    Multi = true,
    Searchable = true,
    Visible = true,
    Default = { "Head" },
})
TriggerbotGroupBox:AddDropdown("BodyPartSelection").OnChanged:Connect(function(v)
    State.BodyParts = {}
    for _, name in ipairs(v) do
        State.BodyParts[name] = true
    end
end)
