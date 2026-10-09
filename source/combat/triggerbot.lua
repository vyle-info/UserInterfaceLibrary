local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local TriggerbotGroupBox = CombatTab:AddGroupbox({
    Side = "Right",
    Name = "Triggerbot (v3)",
})

TriggerbotGroupBox:AddToggle("TriggerbotToggle1", {
    Text = "Triggerbot",
    Default = false,
})

TriggerbotGroupBox:AddToggle("TriggerbotTeamCheck", {
    Text = "Team Check",
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

local isAlive = true
local lastClickTime = 0
local holding = false
local lastTarget = nil
local lastTargetTime = 0
local TARGET_CACHE_TIME = 0.01
local camera = workspace.CurrentCamera

local function getToggle(name)
    local t = Toggles and Toggles[name]
    return t and t.Value or false
end

local function getOption(name)
    return Options and Options[name]
end

local function getDelaySeconds()
    local o = getOption("TriggerBotDelay")
    return (o and o.Value or 10) / 1000
end

local function getMode()
    local o = getOption("ModeSelection")
    local v = o and o.Value
    if type(v) == "table" then
        for k, val in pairs(v) do
            if type(k) == "string" and val == true then return k end
            if type(val) == "string" then return val end
        end
        return "Default"
    end
    return v or "Default"
end

local uiToGroup = {
    ["Head"] = "Head",
    ["Torso"] = "Chest",
    ["Left Arm"] = "LeftArm",
    ["Right Arm"] = "RightArm",
    ["Left Leg"] = "LeftLeg",
    ["Right Leg"] = "RightLeg",
}

local function isGroupSelected(group)
    local o = getOption("BodyPartSelection")
    if not o or type(o.Value) ~= "table" then return false end
    for uiName, selected in pairs(o.Value) do
        local name = type(uiName) == "number" and selected or uiName
        local on = type(uiName) == "number" and true or selected
        if on and uiToGroup[name] == group then
            return true
        end
    end
    return false
end

local mousePress, mouseRelease

local function setupMouseFunctions()
    if mouse1press and mouse1release then
        mousePress = mouse1press
        mouseRelease = mouse1release
        return "mouse1press/release"
    end

    if mouse1click then
        mousePress = function() mouse1click() end
        mouseRelease = function() end
        return "mouse1click"
    end

    if VirtualInputManager then
        mousePress = function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        end
        mouseRelease = function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end
        return "VirtualInputManager"
    end

    mousePress = function() warn("No compatible mouse input found on this executor") end
    mouseRelease = function() end
    return "none (incompatible)"
end

local function safeMousePress()
    local ok, err = pcall(mousePress)
    if not ok then warn("Mouse press failed:", err) end
end

local function safeMouseRelease()
    local ok, err = pcall(mouseRelease)
    if not ok then warn("Mouse release failed:", err) end
end

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local bodyPartMapping = {
    ["Head"] = "Head",

    ["UpperTorso"] = "Chest",
    ["LowerTorso"] = "Chest",
    ["Torso"] = "Chest",
    ["HumanoidRootPart"] = "Chest",

    ["LeftUpperArm"] = "LeftArm",
    ["LeftLowerArm"] = "LeftArm",
    ["LeftHand"] = "LeftArm",
    ["Left Arm"] = "LeftArm",
    ["LeftArm"] = "LeftArm",

    ["RightUpperArm"] = "RightArm",
    ["RightLowerArm"] = "RightArm",
    ["RightHand"] = "RightArm",
    ["Right Arm"] = "RightArm",
    ["RightArm"] = "RightArm",

    ["LeftUpperLeg"] = "LeftLeg",
    ["LeftLowerLeg"] = "LeftLeg",
    ["LeftFoot"] = "LeftLeg",
    ["Left Leg"] = "LeftLeg",
    ["LeftLeg"] = "LeftLeg",

    ["RightUpperLeg"] = "RightLeg",
    ["RightLowerLeg"] = "RightLeg",
    ["RightFoot"] = "RightLeg",
    ["Right Leg"] = "RightLeg",
    ["RightLeg"] = "RightLeg",
}

local function IsBodyPartSelected(part)
    if not part then return false end
    local group = bodyPartMapping[part.Name]
    if not group then return false end
    return isGroupSelected(group)
end

local function IsPlayerPart(part)
    if not part then return false end
    if not IsBodyPartSelected(part) then return false end

    local character = part:FindFirstAncestorWhichIsA("Model")
    if not character then return false end

    local player = Players:GetPlayerFromCharacter(character)
    if not player or player == LocalPlayer then return false end

    if getToggle("TriggerbotTeamCheck") then
        if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            return false
        end
    end

    return true
end

local function releaseHold()
    if holding then
        holding = false
        safeMouseRelease()
    end
end

local function HandleClicking(hasTarget)
    local mode = getMode()
    local now = tick()

    if mode == "Hold" then
        if hasTarget and not holding then
            holding = true
            safeMousePress()
        elseif not hasTarget then
            releaseHold()
        end
        return
    end

    releaseHold()

    if not hasTarget then return end

    local delay = (mode == "Rapid") and 0 or getDelaySeconds()

    if now - lastClickTime >= delay then
        lastClickTime = now
        safeMousePress()
        task.wait()
        safeMouseRelease()
    end
end

local function OnCharacterAdded(character)
    isAlive = true
    lastTarget = nil
    lastClickTime = 0
    releaseHold()

    raycastParams.FilterDescendantsInstances = { character }

    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.Died:Connect(function()
            isAlive = false
            lastTarget = nil
            releaseHold()
        end)
    end
end

if LocalPlayer.Character then
    OnCharacterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

if Toggles and Toggles.TriggerbotToggle1 and Toggles.TriggerbotToggle1.OnChanged then
    Toggles.TriggerbotToggle1:OnChanged(function()
        if not Toggles.TriggerbotToggle1.Value then
            releaseHold()
            lastTarget = nil
        end
    end)
end

RunService.RenderStepped:Connect(function()
    if not getToggle("TriggerbotToggle1") or not isAlive then
        return
    end

    local currentTime = tick()
    local hasTarget = false

    local mouseTarget = Mouse.Target
    if mouseTarget and IsPlayerPart(mouseTarget) then
        hasTarget = true
        lastTarget = mouseTarget
        lastTargetTime = currentTime

    elseif lastTarget and currentTime - lastTargetTime < TARGET_CACHE_TIME then
        if lastTarget.Parent and IsPlayerPart(lastTarget) then
            hasTarget = true
        else
            lastTarget = nil
        end

    else
        camera = workspace.CurrentCamera or camera

        local origin = camera.CFrame.Position
        local direction = camera.CFrame.LookVector * 500
        local result = workspace:Raycast(origin, direction, raycastParams)

        if result and IsPlayerPart(result.Instance) then
            hasTarget = true
            lastTarget = result.Instance
            lastTargetTime = currentTime
        else
            lastTarget = nil
        end
    end

    HandleClicking(hasTarget)
end)
