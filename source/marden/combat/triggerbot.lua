local CombatTBLeft = CombatTab:AddRightGroupbox("Combat Triggerbot")

local CombatJanitor = getgenv().CombatJanitor

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local MAX_DISTANCE = 1e6
local MAX_PASSES = 32
local SEE_THROUGH_TRANSPARENCY = 0.9
local HIDDEN_PART_TRANSPARENCY = 0.5
local HIDDEN_DECAL_TRANSPARENCY = 0.95
local HIDDEN_CACHE_TTL = 0.5
local LOS_OVERSHOOT = 1
local SYNTHETIC_WINDOW = 0.08

local enabled = false
local teamCheck = false
local losCheck = true
local clickMode = "Default"
local reactionDelay = 0.001
local clickInterval = 0.10
local rapidCPS = 15
local releaseGrace = 0.04

local isAlive = true
local isHoldingClick = false
local isClicking = false
local userMouseDown = false
local syntheticUntil = 0

local targetSince = nil
local lastSeen = 0
local lastClickTime = -math.huge
local firedThisAcquisition = false

local localCharacter = LocalPlayer.Character

local excludeParams = RaycastParams.new()
excludeParams.FilterType = Enum.RaycastFilterType.Exclude
excludeParams.IgnoreWater = true

local filter = {}

local connections = {}

local PART_GROUPS = {
    ["Head"] = "Head",

    ["Torso"] = "Torso",
    ["UpperTorso"] = "Torso",
    ["LowerTorso"] = "Torso",
    ["HumanoidRootPart"] = "Torso",

    ["Left Arm"] = "LeftArm",
    ["LeftUpperArm"] = "LeftArm",
    ["LeftLowerArm"] = "LeftArm",
    ["LeftHand"] = "LeftArm",

    ["Right Arm"] = "RightArm",
    ["RightUpperArm"] = "RightArm",
    ["RightLowerArm"] = "RightArm",
    ["RightHand"] = "RightArm",

    ["Left Leg"] = "LeftLeg",
    ["LeftUpperLeg"] = "LeftLeg",
    ["LeftLowerLeg"] = "LeftLeg",
    ["LeftFoot"] = "LeftLeg",

    ["Right Leg"] = "RightLeg",
    ["RightUpperLeg"] = "RightLeg",
    ["RightLowerLeg"] = "RightLeg",
    ["RightFoot"] = "RightLeg",
}

local allowAll = true      -- nothing selected = every part allowed
local allowedGroups = {}

CombatTBLeft:AddToggle("TriggerBotToggle", { Text = "Activate Triggerbot", Default = false })
CombatTBLeft:AddToggle("TeamCheckToggle", { Text = "Activate Team Check", Default = false })

CombatTBLeft:AddToggle("LineOfSightToggle", {
    Text = "Activate Third Person Check",
    Tooltip = "Requires a clear line of sight from the target (stops clicks around corners in third person)",
    Default = true,
})

CombatTBLeft:AddDropdown("ClickMode", {
    Text = "Triggerbot Mode",
    Values = { "Default", "Single Click", "Hold Click", "Rapid Click" },
    Default = 1,
})

CombatTBLeft:AddDropdown("TargetParts", {
    Text = "Targeted Body Parts",
    Values = { "Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg" },
    AllowNull = true,
    Default = nil,
    Multi = true,
})

CombatTBLeft:AddSlider("ClickDelay", {
    Text = "Reaction Delay",
    Default = 10, Min = 0, Max = 500, Rounding = 1, Suffix = "ms",
})

CombatTBLeft:AddSlider("ClickInterval", {
    Text = "Click Interval",
    Default = 100, Min = 0, Max = 1000, Rounding = 1, Suffix = "ms",
})

CombatTBLeft:AddSlider("RapidCPS", {
    Text = "Rapid Click CPS",
    Default = 15, Min = 1, Max = 50, Rounding = 0, Suffix = " cps",
})

CombatTBLeft:AddSlider("ReleaseGrace", {
    Text = "Target Lost Grace",
    Tooltip = "How long the triggerbot thinks the cursor is on the target",
    Default = 40, Min = 0, Max = 300, Rounding = 0, Suffix = "ms",
})

local function ReleaseMouseIfHolding()
    if isHoldingClick then
        isHoldingClick = false
        syntheticUntil = os.clock() + SYNTHETIC_WINDOW
        mouse1release()
    end
end

local function ResetTargetState()
    targetSince = nil
    firedThisAcquisition = false
end

local function RefreshAllowedGroups()
    local selected = Options.TargetParts.Value
    local groups = {}
    local anySelected = false

    if type(selected) == "table" then
        for name, on in pairs(selected) do
            if on then
                groups[name] = true
                anySelected = true
            end
        end
    end

    allowAll = not anySelected
    allowedGroups = groups
end

Toggles.TriggerBotToggle:OnChanged(function(state)
    enabled = state
    if not state then
        ReleaseMouseIfHolding()
        ResetTargetState()
    end
end)

Toggles.TeamCheckToggle:OnChanged(function(state) teamCheck = state end)
Toggles.LineOfSightToggle:OnChanged(function(state) losCheck = state end)

Options.ClickMode:OnChanged(function()
    clickMode = Options.ClickMode.Value
    ReleaseMouseIfHolding()
    ResetTargetState()
end)

Options.TargetParts:OnChanged(function()
    RefreshAllowedGroups()
    ReleaseMouseIfHolding()
    ResetTargetState()
end)

Options.ClickDelay:OnChanged(function(v) reactionDelay = v / 1000 end)
Options.ClickInterval:OnChanged(function(v) clickInterval = v / 1000 end)
Options.RapidCPS:OnChanged(function(v) rapidCPS = math.max(v, 1) end)
Options.ReleaseGrace:OnChanged(function(v) releaseGrace = v / 1000 end)

clickMode = Options.ClickMode.Value or clickMode
reactionDelay = (Options.ClickDelay.Value or 10) / 1000
clickInterval = (Options.ClickInterval.Value or 100) / 1000
rapidCPS = math.max(Options.RapidCPS.Value or 15, 1)
releaseGrace = (Options.ReleaseGrace.Value or 40) / 1000
losCheck = Toggles.LineOfSightToggle.Value

RefreshAllowedGroups()

table.insert(connections, UIS.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if gameProcessed or isHoldingClick or isClicking or os.clock() < syntheticUntil then return end
    userMouseDown = true
end))

table.insert(connections, UIS.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if isHoldingClick or isClicking or os.clock() < syntheticUntil then return end
    userMouseDown = false
end))

local function GetPlayerFromPart(part)
    local current = part
    while current and current ~= workspace do
        if current:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(current)
            if player then
                return player, current
            end
        end
        current = current.Parent
    end
    return nil, nil
end

local function GetHumanoidModel(part)
    local current = part.Parent
    while current and current ~= workspace do
        if current:IsA("Model") then
            local hum = current:FindFirstChildOfClass("Humanoid")
            if hum then
                return current, hum
            end
        end
        current = current.Parent
    end
    return nil, nil
end

local function GetBodyGroup(part)
    local name = part.Name

    local accessory = part:FindFirstAncestorOfClass("Accessory")
    if accessory then
        local handle = accessory:FindFirstChild("Handle")
        local weld = handle and handle:FindFirstChildWhichIsA("Weld")
        if not weld then return nil end
        local attached = (weld.Part0 == handle) and weld.Part1 or weld.Part0
        if not attached then return nil end
        name = attached.Name
    end

    return PART_GROUPS[name]
end

local function IsValidTarget(part)
    if not part then return false end

    local player, character = GetPlayerFromPart(part)
    if not player or player == LocalPlayer then return false end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end

    if teamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end

    if not allowAll then
        local group = GetBodyGroup(part)
        if not group or not allowedGroups[group] then
            return false
        end
    end

    return true
end

local hiddenValue = setmetatable({}, { __mode = "k" })
local hiddenTime = setmetatable({}, { __mode = "k" })

local function HasHiddenContent(part)
    if part.Transparency < HIDDEN_PART_TRANSPARENCY then return false end

    for _, d in ipairs(part:GetDescendants()) do
        if d:IsA("Decal") or d:IsA("Texture") then
            if d.Transparency >= HIDDEN_DECAL_TRANSPARENCY then return true end
        elseif d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
            if not d.Enabled then return true end
        end
    end

    return false
end

local function IsSeeThrough(part)
    local _, hum = GetHumanoidModel(part)
    if hum then
        return hum.Health <= 0
    end

    if part.Transparency >= SEE_THROUGH_TRANSPARENCY then return true end
    if not part.CanCollide then return true end

    local now = os.clock()
    local checkedAt = hiddenTime[part]
    if checkedAt and now - checkedAt < HIDDEN_CACHE_TTL then
        return hiddenValue[part]
    end

    local hidden = HasHiddenContent(part)
    hiddenValue[part] = hidden
    hiddenTime[part] = now
    return hidden
end

local function ResetFilter()
    table.clear(filter)
    if localCharacter then
        filter[1] = localCharacter
    end
    local camera = workspace.CurrentCamera
    if camera then
        filter[#filter + 1] = camera
    end
end

local function CastSolid(origin, direction)
    ResetFilter()
    excludeParams.FilterDescendantsInstances = filter

    for _ = 1, MAX_PASSES do
        local result = workspace:Raycast(origin, direction, excludeParams)
        if not result then
            return nil
        end

        if IsSeeThrough(result.Instance) then
            filter[#filter + 1] = result.Instance
            excludeParams.FilterDescendantsInstances = filter
        else
            return result
        end
    end

    return nil
end

local function HasLineOfSight(hitPosition, targetCharacter)
    local char = localCharacter
    local head = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
    if not head then return true end

    local origin = head.Position
    local delta = hitPosition - origin
    if delta.Magnitude < 0.5 then return true end

    local result = CastSolid(origin, delta + delta.Unit * LOS_OVERSHOOT)
    return result ~= nil and result.Instance:IsDescendantOf(targetCharacter)
end

local function GetTargetPart(origin, direction)
    local result = CastSolid(origin, direction)
    if not result then return nil end

    local part = result.Instance
    if not IsValidTarget(part) then return nil end

    if losCheck then
        local _, character = GetPlayerFromPart(part)
        if not character or not HasLineOfSight(result.Position, character) then
            return nil
        end
    end

    return part
end

local function SimulateClick()
    if isClicking or isHoldingClick then return end
    isClicking = true
    task.spawn(function()
        syntheticUntil = os.clock() + SYNTHETIC_WINDOW
        mouse1press()
        task.wait()
        mouse1release()
        syntheticUntil = os.clock() + SYNTHETIC_WINDOW
        isClicking = false
    end)
end

local function GetRequiredGap()
    if clickMode == "Rapid Click" then
        return math.max(clickInterval, 1 / rapidCPS)
    end
    return clickInterval
end

local function HandleClicking(now, hasTarget, ready, tracking)
    local intervalPassed = now - lastClickTime >= GetRequiredGap()

    if clickMode == "Hold Click" then
        if hasTarget and ready then
            if not isHoldingClick and not isClicking and not userMouseDown and intervalPassed then
                lastClickTime = now
                isHoldingClick = true
                syntheticUntil = now + SYNTHETIC_WINDOW
                mouse1press()
            end
        elseif not tracking then
            ReleaseMouseIfHolding()
        end

    elseif clickMode == "Single Click" then
        if hasTarget and ready and not firedThisAcquisition and not userMouseDown and intervalPassed then
            firedThisAcquisition = true
            lastClickTime = now
            SimulateClick()
        end

    else
        if hasTarget and ready and not userMouseDown and intervalPassed then
            lastClickTime = now
            SimulateClick()
        end
    end
end

local humanoidDiedConn

local function OnCharacterAdded(character)
    isAlive = true
    localCharacter = character
    ReleaseMouseIfHolding()
    ResetTargetState()

    if humanoidDiedConn then
        humanoidDiedConn:Disconnect()
        humanoidDiedConn = nil
    end

    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        isAlive = humanoid.Health > 0
        humanoidDiedConn = humanoid.Died:Connect(function()
            isAlive = false
            ReleaseMouseIfHolding()
            ResetTargetState()
        end)
    end
end

if LocalPlayer.Character then
    task.spawn(OnCharacterAdded, LocalPlayer.Character)
end
table.insert(connections, LocalPlayer.CharacterAdded:Connect(OnCharacterAdded))

table.insert(connections, RunService.RenderStepped:Connect(function()
    if not enabled or not isAlive then
        ReleaseMouseIfHolding()
        ResetTargetState()
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then return end

    local now = os.clock()
    local mousePos = UIS:GetMouseLocation()
    local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)

    local hitPart = GetTargetPart(ray.Origin, ray.Direction * MAX_DISTANCE)
    local hasTarget = hitPart ~= nil and IsValidTarget(hitPart)

    if hasTarget then
        if not targetSince then
            targetSince = now
        end
        lastSeen = now
    elseif targetSince and now - lastSeen > releaseGrace then
        targetSince = nil
        firedThisAcquisition = false
    end

    local tracking = targetSince ~= nil
    local ready = tracking and (now - targetSince) >= reactionDelay

    HandleClicking(now, hasTarget, ready, tracking)
end))

if CombatJanitor then
    for _, conn in ipairs(connections) do
        CombatJanitor:Add(conn)
    end
    CombatJanitor:Add(function()
        if humanoidDiedConn then
            humanoidDiedConn:Disconnect()
            humanoidDiedConn = nil
        end
    end)
    CombatJanitor:AddRestore(function()
        enabled = false
        isAlive = false
        isClicking = false
        userMouseDown = false
        ResetTargetState()
        ReleaseMouseIfHolding()
    end)
end
