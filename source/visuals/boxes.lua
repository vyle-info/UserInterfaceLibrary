local Tabs = {(function(w) return w:AddTab("Box Visuals", "box"), w:AddTab("Box Colors", "palette") end)(
    loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))():CreateWindow({
        Title    = "Box ESP Export",
        Footer   = "Box ESP",
        Size     = UDim2.fromOffset(500, 600),
        Center   = true,
        AutoShow = true,
    })
)}

local Players = game:GetService("Players")
local Camera  = workspace.CurrentCamera

local Config = {
    Enabled           = false,
    FillEnabled       = false,
    ShowTeammates     = false,
    ShowSelf          = false,
    UseTeamColors     = false,
    VisibleDetection  = false,

    BoxThickness      = 1.5,
    BoxTransparency   = 1,
    EnemyColor        = Color3.fromRGB(255, 0, 0),
    TeamColor         = Color3.fromRGB(0, 200, 255),

    FillColor         = Color3.fromRGB(255, 0, 0),
    FillTransparency  = 0.5,

    VisibleColor      = Color3.fromRGB(0, 255, 0),
    VisibleFillColor  = Color3.fromRGB(0, 255, 0),
}

local VisibilityCache, ESPStorage = {}, {}

-- MM2 role check: tool in Backpack or Character
local function Has(p, n)
    return (p:FindFirstChild("Backpack") and p.Backpack:FindFirstChild(n))
        or (p.Character and p.Character:FindFirstChild(n))
end

local function IsVisible(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local now, cached = tick(), VisibilityCache[character]
    if cached and now - cached.time < 0.02 then return cached.result end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {character, Camera, Players.LocalPlayer.Character}

    for _, offset in ipairs({
        Vector3.new(0, 2.5, 0), Vector3.new(0, 0, 0), Vector3.new(0, -2, 0),
        Vector3.new(0.8, 1, 0), Vector3.new(-0.8, 1, 0),
    }) do
        if not workspace:Raycast(Camera.CFrame.Position, root.Position + offset - Camera.CFrame.Position, rayParams) then
            VisibilityCache[character] = {result = true, time = now}
            return true
        end
    end

    VisibilityCache[character] = {result = false, time = now}
    return false
end

local function RemoveESP(player)
    for _, d in pairs(ESPStorage[player] or {}) do d:Remove() end
    ESPStorage[player] = nil
end

local function AddESP(player)
    if (player == Players.LocalPlayer and not Config.ShowSelf) or ESPStorage[player] then return end
    ESPStorage[player] = {}
    for i = 1, 5 do -- 1-4 = outline lines, 5 = fill
        local d = Drawing.new(i < 5 and "Line" or "Square")
        d.Visible      = false
        d.Color        = i < 5 and Config.EnemyColor or Config.FillColor
        d.Thickness    = i < 5 and Config.BoxThickness or 0
        d.Transparency = i < 5 and Config.BoxTransparency or Config.FillTransparency
        d.ZIndex       = i < 5 and 5 or 4
        if i == 5 then d.Filled = true end
        ESPStorage[player][i < 5 and i or "fill"] = d
    end
end

local function Hide(lines, fillOnly)
    for i = 1, fillOnly and 0 or 4 do lines[i].Visible = false end
    lines.fill.Visible = false
end

-- Bounding box + drawing in one step
local function Draw(lines, character)
    local root, b = character:FindFirstChild("HumanoidRootPart"), {math.huge, math.huge, -math.huge, -math.huge}
    if not root or not character:FindFirstChildOfClass("Humanoid") then return Hide(lines) end

    for _, y in ipairs({root.Position.Y - 5.5 * 0.52, root.Position.Y + 5.5 * 0.48}) do
        for _, dx in ipairs({-1.4, 1.4}) do
            for _, dz in ipairs({-1.4, 1.4}) do
                local s, visible = Camera:WorldToViewportPoint(Vector3.new(root.Position.X + dx, y, root.Position.Z + dz))
                if not visible then return Hide(lines) end
                b = {math.min(b[1], s.X), math.min(b[2], s.Y), math.max(b[3], s.X), math.max(b[4], s.Y)}
            end
        end
    end

    lines[1].From, lines[1].To = Vector2.new(b[1], b[2]), Vector2.new(b[3], b[2])
    lines[2].From, lines[2].To = Vector2.new(b[1], b[4]), Vector2.new(b[3], b[4])
    lines[3].From, lines[3].To = Vector2.new(b[1], b[2]), Vector2.new(b[1], b[4])
    lines[4].From, lines[4].To = Vector2.new(b[3], b[2]), Vector2.new(b[3], b[4])
    for i = 1, 4 do lines[i].Visible = true end

    if Config.FillEnabled then
        lines.fill.Position = Vector2.new(b[1], b[2])
        lines.fill.Size     = Vector2.new(b[3] - b[1], b[4] - b[2])
    end
    lines.fill.Visible = Config.FillEnabled
end

game:GetService("RunService").RenderStepped:Connect(function()
    for player, lines in pairs(ESPStorage) do
        if not Config.Enabled then
            Hide(lines)
        elseif not player or not player.Parent then
            RemoveESP(player)
        elseif (player == Players.LocalPlayer and not Config.ShowSelf)
            or (player ~= Players.LocalPlayer and Players.LocalPlayer.Team ~= nil
                and Players.LocalPlayer.Team == player.Team and not Config.ShowTeammates)
            or ((player.Character and player.Character:FindFirstChildOfClass("Humanoid")) or {Health = 0}).Health <= 0 then
            Hide(lines)
        else
            local vis, c = Config.VisibleDetection and IsVisible(player.Character)
            if not vis and Config.UseTeamColors then
                if game.PlaceId == 142823291 then
                    c = Has(player, "Gun") and Color3.fromRGB(0, 120, 255)
                        or Has(player, "Knife") and Color3.fromRGB(255, 0, 0)
                elseif player.Team then
                    c = player.TeamColor.Color
                end
            end

            for i = 1, 4 do
                lines[i].Color        = vis and Config.VisibleColor or c or Config.EnemyColor
                lines[i].Transparency = Config.BoxTransparency
                lines[i].Thickness    = Config.BoxThickness
            end
            lines.fill.Color        = vis and Config.VisibleFillColor or c or Config.FillColor
            lines.fill.Transparency = Config.FillTransparency

            Draw(lines, player.Character)
        end
    end
end)

for _, player in ipairs(Players:GetPlayers()) do AddESP(player) end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function() AddESP(player) end)
    AddESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    if player.Character then VisibilityCache[player.Character] = nil end
    RemoveESP(player)
end)

-- ── Box Visuals tab ──
local g = Tabs[1]:AddGroupbox({ Side = "Left", Name = "Global Box Visuals" })

g:AddCheckbox("BoxEnabled", {
    Text     = "Global Visual Boxes",
    Default  = Config.Enabled,
    Callback = function(value)
        Config.Enabled = value
        if not value then for _, lines in pairs(ESPStorage) do Hide(lines) end end
    end,
})

g:AddCheckbox("BoxFillEnabled", {
    Text     = "Fill Visual Boxes",
    Default  = Config.FillEnabled,
    Callback = function(value)
        Config.FillEnabled = value
        if not value then for _, lines in pairs(ESPStorage) do Hide(lines, true) end end
    end,
})

g:AddCheckbox("BoxVisibleDetection", {
    Text     = "Visible Detection",
    Default  = Config.VisibleDetection,
    Callback = function(value) Config.VisibleDetection = value end,
})

g:AddCheckbox("BoxShowTeammates", {
    Text     = "Show Teammates",
    Default  = Config.ShowTeammates,
    Callback = function(value) Config.ShowTeammates = value end,
})

g:AddCheckbox("BoxTeamColors", {
    Text     = "Team Colors",
    Default  = Config.UseTeamColors,
    Callback = function(value) Config.UseTeamColors = value end,
})

g:AddCheckbox("BoxShowSelf", {
    Text     = "Show Self",
    Default  = Config.ShowSelf,
    Callback = function(value)
        Config.ShowSelf = value
        if value then AddESP(Players.LocalPlayer) else RemoveESP(Players.LocalPlayer) end
    end,
})

-- ── Box Colors tab ──
g = Tabs[2]:AddGroupbox({ Side = "Left", Name = "Global Box Colors" })

g:AddLabel("Box Outline Color"):AddColorPicker("BoxOutlineColor", {
    Default  = Config.EnemyColor,
    Title    = "Box Outline Color",
    Callback = function(color) Config.EnemyColor = color end,
})

g:AddSlider("BoxThickness", {
    Text     = "Thickness",
    Default  = Config.BoxThickness,
    Min      = 0.5,
    Max      = 5,
    Rounding = 1,
    Callback = function(v)
        Config.BoxThickness = math.round(v * 2) / 2
        for _, lines in pairs(ESPStorage) do
            for i = 1, 4 do lines[i].Thickness = Config.BoxThickness end
        end
    end,
})

g:AddSlider("BoxTransparency", {
    Text     = "Transparency",
    Default  = Config.BoxTransparency * 100,
    Min      = 0,
    Max      = 100,
    Rounding = 0,
    Suffix   = "/100",
    Callback = function(v)
        Config.BoxTransparency = v / 100
        for _, lines in pairs(ESPStorage) do
            for i = 1, 4 do lines[i].Transparency = Config.BoxTransparency end
        end
    end,
})

g = Tabs[2]:AddGroupbox({ Side = "Right", Name = "Global Filled Box Colors" })

g:AddLabel("Box Fill Color"):AddColorPicker("BoxFillColor", {
    Default  = Config.FillColor,
    Title    = "Box Fill Color",
    Callback = function(color) Config.FillColor = color end,
})

g:AddSlider("BoxFillTransparency", {
    Text     = "Fill Transparency",
    Default  = Config.FillTransparency * 100,
    Min      = 0,
    Max      = 100,
    Rounding = 0,
    Suffix   = "/100",
    Callback = function(v)
        Config.FillTransparency = v / 100
        for _, lines in pairs(ESPStorage) do lines.fill.Transparency = Config.FillTransparency end
    end,
})

g = Tabs[2]:AddGroupbox({ Side = "Right", Name = "Visible Detection Colors" })

g:AddLabel("Visible Box Outline Color"):AddColorPicker("VisibleOutlineColor", {
    Default  = Config.VisibleColor,
    Title    = "Visible Box Outline Color",
    Callback = function(color) Config.VisibleColor = color end,
})

g:AddLabel("Visible Fill Color"):AddColorPicker("VisibleFillColor", {
    Default  = Config.VisibleFillColor,
    Title    = "Visible Fill Color",
    Callback = function(color) Config.VisibleFillColor = color end,
})
