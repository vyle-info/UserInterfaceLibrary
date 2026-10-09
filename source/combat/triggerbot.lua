--// Services
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local Workspace           = game:GetService("Workspace")
local GuiService          = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

--// CombatTab must already exist
local CombatTab = CombatTab or (getgenv and getgenv().CombatTab)

--=============================================================
--  UI  (exactly your elements)
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

--=============================================================
--  CONFIG
--=============================================================
local Config = {
    Enabled   = false,
    Delay     = 10,
    Mode      = "Default",
    BodyParts = { Head = true },
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
--  BODY-PART MATCHING  (R6 / R15 / custom)
--=============================================================
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

--=============================================================
--  GEOMETRY HELPERS
--=============================================================
local function cross(a, b, p)
    return (b.X - a.X) * (p.Y - a.Y) - (b.Y - a.Y) * (p.X - a.X)
end

-- Andrew's monotone chain -> convex hull
local function convexHull(points)
    local n = #points
    if n < 3 then return points end
    table.sort(points, function(a, b)
        if a.X == b.X then return a.Y < b.Y end
        return a.X < b.X
    end)

    local hull = {}
    for i = 1, n do
        while #hull >= 2 and cross(hull[#hull - 1], hull[#hull], points[i]) <= 0 do
            table.remove(hull)
        end
        hull[#hull + 1] = points[i]
    end
    local lower = #hull + 1
    for i = n - 1, 1, -1 do
        while #hull >= lower and cross(hull[#hull - 1], hull[#hull], points[i]) <= 0 do
            table.remove(hull)
        end
        hull[#hull + 1] = points[i]
    end
    table.remove(hull)
    return hull
end

-- Push hull outward by a few px so edge pixels still register
local function expandHull(hull, px)
    local n = #hull
    if n < 3 then return hull end
    local cx, cy = 0, 0
    for _, p in ipairs(hull) do cx = cx + p.X; cy = cy + p.Y end
    cx, cy = cx / n, cy / n
    local out = table.create(n)
    for i, p in ipairs(hull) do
        local d = Vector2.new(p.X - cx, p.Y - cy)
        local m = d.Magnitude
        out[i] = (m > 0) and (p + d / m * px) or p
    end
    return out
end

-- Convex point-in-polygon (orientation-agnostic)
local function pointInHull(pt, hull)
    local n = #hull
    if n < 3 then return false end
    local pos, neg = false, false
    for i = 1, n do
        local c = cross(hull[i], hull[i % n + 1], pt)
        if c > 0 then pos = true end
        if c < 0 then neg = true end
        if pos and neg then return false end
    end
    return true
end

local function projectHull(part, cam)
    local cf, size = part.CFrame, part.Size
    local hx, hy, hz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
    local pts = {}
    for sx = -1, 1, 2 do
        for sy = -1, 1, 2 do
            for sz = -1, 1, 2 do
                local world = cf * Vector3.new(hx * sx, hy * sy, hz * sz)
                local sp, onScreen = cam:WorldToViewportPoint(world)
                if onScreen and sp.Z > 0 then
                    pts[#pts + 1] = Vector2.new(sp.X, sp.Y)
                end
            end
        end
    end
    if #pts < 3 then return nil end
    return expandHull(convexHull(pts), 1.5)
end

--=============================================================
--  TARGET ACQUISITION
--=============================================================
local includeParams = RaycastParams.new()
includeParams.FilterType  = Enum.RaycastFilterType.Include
includeParams.IgnoreWater = true

local function getMouseViewport()
    local inset = GuiService:GetGuiInset()
    return Vector2.new(Mouse.X, Mouse.Y) - inset
end

local function getTarget()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end

    local selected = Config.BodyParts
    local candidates, partToChar = {}, {}

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    for _, d in ipairs(char:GetDescendants()) do
                        if d:IsA("BasePart") then
                            local cat = getCategory(d.Name)
                            if cat and selected[cat] then
                                candidates[#candidates + 1] = d
                                partToChar[d] = char
                            end
                        end
                    end
                end
            end
        end
    end
    if #candidates == 0 then return nil end

    local mouseVP = getMouseViewport()
    local camPos   = cam.CFrame.Position
    local best, bestDepth = nil, math.huge

    -- (2) screen-space silhouette test
    for _, part in ipairs(candidates) do
        local hull = projectHull(part, cam)
        if hull and pointInHull(mouseVP, hull) then
            local depth = (part.Position - camPos).Magnitude
            if depth < bestDepth then
                best, bestDepth = part, depth
            end
        end
    end

    -- (1) exact 3D crosshair ray (union with the above)
    local ray = cam:ViewportPointToRay(mouseVP.X, mouseVP.Y)
    includeParams.FilterDescendantsInstances = candidates
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, includeParams)
    if result and partToChar[result.Instance] then
        local depth = (result.Instance.Position - camPos).Magnitude
        if depth < bestDepth then
            best, bestDepth = result.Instance, depth
        end
    end

    if best then return best, partToChar[best] end
    return nil
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
local currentTarget, confirmTime, firedForTarget, holding, lastFire = nil, 0, false, false, 0

RunService.RenderStepped:Connect(function()
    if not Config.Enabled then
        if holding then release(); holding = false end
        currentTarget = nil
        return
    end

    local part, char = getTarget()

    if part and char then
        if currentTarget ~= char then
            currentTarget  = char
            confirmTime    = tick()
            firedForTarget = false
            if holding then release(); holding = false end
        end

        local elapsedMs = (tick() - confirmTime) * 1000
        if elapsedMs >= Config.Delay then
            if Config.Mode == "Default" then
                if not firedForTarget then
                    click(); firedForTarget = true
                end
            elseif Config.Mode == "Rapid" then
                local interval = math.max(Config.Delay, 5) / 1000
                if (tick() - lastFire) >= interval then
                    click(); lastFire = tick()
                end
            elseif Config.Mode == "Hold" then
                if not holding then press(); holding = true end
            end
        end
    else
        currentTarget, firedForTarget = nil, false
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
