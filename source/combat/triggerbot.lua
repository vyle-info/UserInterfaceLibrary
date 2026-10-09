

--// Services
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local Workspace           = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

--// UI Library + addons
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title      = "Venice",
    Footer     = "universal triggerbot",
    Center     = true,
    AutoShow   = true,
    NotifySide = "Right",
})

local Tabs = {
    Combat   = Window:AddTab("Combat", "crosshair"),
    Settings = Window:AddTab("Settings", "settings"),
}

local CombatTab = Tabs.Combat

--=============================================================
--  UI  (your layout, wired up)
--=============================================================
local TriggerbotGroupBox = CombatTab:AddGroupbox({
    Side = "Right",
    Name = "Triggerbot (v3)",
})

local TriggerbotToggle = TriggerbotGroupBox:AddToggle("TriggerbotToggle1", {
    Text = "Triggerbot",
    Default = false,
})

local TriggerBotDelay = TriggerbotGroupBox:AddSlider("TriggerBotDelay", {
    Text = "Triggerbot Delay",
    Default = 10,
    Min = 0,
    Max = 200,
    Rounding = 1,
    Suffix = "ms",
})

local ModeSelection = TriggerbotGroupBox:AddDropdown("ModeSelection", {
    Text = "Triggerbot Mode",
    Values = { "Default", "Rapid", "Hold" },
    Multi = false,
    Searchable = true,
    Default = { "Default" },
})

local BodyPartSelection = TriggerbotGroupBox:AddDropdown("BodyPartSelection", {
    Text = "Targeted Body Parts",
    Values = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" },
    Multi = true,
    Searchable = true,
    Visible = true,
    Default = { "Head" },
})

-- extras that make it genuinely universal
local TeamCheck = TriggerbotGroupBox:AddToggle("TeamCheck", {
    Text = "Team Check",
    Default = false,
    Tooltip = "Skip players on your own team",
})

local WallCheck = TriggerbotGroupBox:AddToggle("WallCheck", {
    Text = "Wall Check",
    Default = false,
    Tooltip = "Only fire when the target is not behind a wall",
})

--=============================================================
--  CONFIG
--=============================================================
local Config = {
    Enabled   = false,
    Delay     = 10,          -- ms
    Mode      = "Default",
    BodyParts = { Head = true },
    TeamCheck = false,
    WallCheck = false,
}

local function toSet(value)
    local set = {}
    if type(value) == "table" then
        for k, v in pairs(value) do
            if type(k) == "number" then set[v] = true
            elseif v then set[k] = true end
        end
    elseif type(value) == "string" then
        set[value] = true
    end
    return set
end

local function firstOf(value)
    if type(value) == "table" then
        for k, v in pairs(value) do
            if type(k) == "number" then return v end
            if v then return k end
        end
        return nil
    end
    return value
end

--=============================================================
--  TARGET DETECTION
--=============================================================
-- Map any part name (R6, R15, custom) to a selectable body category
local function getCategory(name)
    local n = name:lower():gsub("%s+", "")
    if n:find("head") then return "Head" end
    if n:find("torso") or n:find("chest") then return "Torso" end
    if n:find("arm") then
        if n:find("left")  then return "Left Arm"  end
        if n:find("right") then return "Right Arm" end
    end
    if n:find("leg") then
        if n:find("left")  then return "Left Leg"  end
        if n:find("right") then return "Right Leg" end
    end
    return nil
end

local includeParams = RaycastParams.new()
includeParams.FilterType = Enum.RaycastFilterType.Include
includeParams.IgnoreWater = true

local wallParams = RaycastParams.new()
wallParams.FilterType = Enum.RaycastFilterType.Exclude
wallParams.IgnoreWater = true

-- Returns the part under the crosshair + its character (or nil)
local function getTarget()
    local parts, partToChar = {}, {}
    local selected = Config.BodyParts

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local isEnemy = true
                if Config.TeamCheck and LocalPlayer.Team and plr.Team == LocalPlayer.Team then
                    isEnemy = false
                end
                if hum and hum.Health > 0 and isEnemy then
                    for _, d in ipairs(char:GetDescendants()) do
                        if d:IsA("BasePart") then
                            local cat = getCategory(d.Name)
                            if cat and selected[cat] then
                                parts[#parts + 1] = d
                                partToChar[d] = char
                            end
                        end
                    end
                end
            end
        end
    end

    if #parts == 0 then return nil end

    local ray = Mouse.UnitRay
    if not ray then return nil end

    includeParams.FilterDescendantsInstances = parts
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, includeParams)
    if result then
        return result.Instance, partToChar[result.Instance]
    end
    return nil
end

local function isVisible(part, char)
    local ray = Mouse.UnitRay
    if not ray then return false end
    wallParams.FilterDescendantsInstances = { LocalPlayer.Character }
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, wallParams)
    if result then
        return result.Instance == part or result.Instance:IsDescendantOf(char)
    end
    return false
end

--=============================================================
--  FIRING
--=============================================================
local function press()
    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, game, 1)
end
local function release()
    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, game, 1)
end
local function click()
    press()
    release()
end

--=============================================================
--  MAIN LOOP
--=============================================================
local currentTarget = nil
local confirmTime   = 0
local firedForTarget = false
local holding       = false
local lastFire      = 0

RunService.RenderStepped:Connect(function()
    if not Config.Enabled then
        if holding then release(); holding = false end
        currentTarget = nil
        return
    end

    local part, char = getTarget()

    if part and Config.WallCheck and not isVisible(part, char) then
        part, char = nil, nil
    end

    if part and char then
        -- new target -> reset confirmation timer
        if currentTarget ~= char then
            currentTarget   = char
            confirmTime     = tick()
            firedForTarget  = false
            if holding then release(); holding = false end
        end

        local elapsedMs = (tick() - confirmTime) * 1000
        if elapsedMs >= Config.Delay then
            if Config.Mode == "Default" then
                if not firedForTarget then
                    click()
                    firedForTarget = true
                end
            elseif Config.Mode == "Rapid" then
                local interval = math.max(Config.Delay, 5) / 1000
                if (tick() - lastFire) >= interval then
                    click()
                    lastFire = tick()
                end
            elseif Config.Mode == "Hold" then
                if not holding then
                    press()
                    holding = true
                end
            end
        end
    else
        currentTarget  = nil
        firedForTarget = false
        if holding then release(); holding = false end
    end
end)

--=============================================================
--  WIRING
--=============================================================
TriggerbotToggle:OnChanged(function(v) Config.Enabled = v end)
TriggerBotDelay:OnChanged(function(v) Config.Delay = v end)
ModeSelection:OnChanged(function(v) Config.Mode = firstOf(v) or "Default" end)
BodyPartSelection:OnChanged(function(v) Config.BodyParts = toSet(v) end)
TeamCheck:OnChanged(function(v) Config.TeamCheck = v end)
WallCheck:OnChanged(function(v) Config.WallCheck = v end)

--=============================================================
--  ADDONS
--=============================================================
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
ThemeManager:SetFolder("Venice")
SaveManager:SetFolder("Venice/UniversalTriggerbot")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

Library:OnUnload(function()
    if holding then release() end
end)

Library:Notify({ Title = "Venice", Description = "Universal Triggerbot loaded", Time = 4 })
