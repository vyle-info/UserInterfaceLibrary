local CombatAB         = CombatTab:AddLeftGroupbox("M A R D E N Soft-Aim")
local CombatABSettings = CombatTab:AddRightGroupbox("M A R D E N Soft-Aim Settings")

local Svc = {
    Players = game:GetService("Players"),
    Input   = game:GetService("UserInputService"),
    Run     = game:GetService("RunService"),
    Gui     = game:GetService("GuiService"),
}

local LocalPlayer = Svc.Players.LocalPlayer
local function GetCamera() return workspace.CurrentCamera end

local TRANSPARENCY_THRESHOLD = 0.95
local MAX_WALL_IGNORES       = 12

local S = {
    Target  = nil,
    Locked  = false,
    KeyHeld = false,
    ResX    = 0,
    ResY    = 0,
}

local FOV = {
    Circle = Drawing.new("Circle"),
    Square = Drawing.new("Square"),
}

FOV.Circle.Thickness    = 2
FOV.Circle.Radius       = 200
FOV.Circle.Color        = Color3.fromRGB(255, 255, 255)
FOV.Circle.Transparency = 1
FOV.Circle.Visible      = false
FOV.Circle.Filled       = false

FOV.Square.Thickness    = 2
FOV.Square.Size         = Vector2.new(400, 400)
FOV.Square.Color        = Color3.fromRGB(255, 255, 255)
FOV.Square.Transparency = 1
FOV.Square.Visible      = false
FOV.Square.Filled       = false

CombatAB:AddToggle("LockOnToggle",            { Text = "Toggle Soft-Aim",                 Default = false })
CombatAB:AddToggle("ShowFOVToggle",           { Text = "Toggle FOV Circle",               Default = false })
CombatAB:AddToggle("AutoLockToggle",          { Text = "Autolock while in FOV radius",    Default = false })
CombatAB:AddToggle("LockDetectionToggle",     { Text = "Toggle Detection",                Default = false })
CombatAB:AddToggle("WallCheckToggle",         { Text = "Wall Check",                      Default = false })
CombatAB:AddToggle("AdvancedWallCheckToggle", { Text = "Advanced Wall Check",             Default = false })
CombatAB:AddToggle("IgnoreTeammatesToggle",   { Text = "Team Check",                      Default = false })
CombatAB:AddToggle("DeathCheckToggle",        { Text = "Death Check",                     Default = false })

CombatAB:AddDropdown("BodyPartDropdown", {
    Text    = "Targeted Body Part",
    Values  = { "Head", "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart" },
    Default = 3,
})

CombatAB:AddDropdown("KeybindModeDropdown", {
    Text    = "Soft-Aim Hotkey Mode",
    Values  = { "Toggle", "Hold" },
    Default = 1,
})

CombatAB:AddDropdown("FOVModeDropdown", {
    Text    = "FOV Circle Position",
    Values  = { "Center", "Mouse" },
    Default = 2,
})

CombatAB:AddDropdown("LockMethodDropdown", {
    Text    = "Tracking Method",
    Values  = { "Camera", "Cursor" },
    Default = 1,
})

CombatAB:AddSlider("Smoothness",      { Text = "Smoothness",      Default = 20,   Min = 1,   Max = 50, Rounding = 1, Suffix = "" })
CombatAB:AddSlider("SmoothnessSpeed", { Text = "Smoothness Speed", Default = 1.75, Min = 0.1, Max = 5,  Rounding = 2, Suffix = "" })
CombatAB:AddSlider("MaxDistance",     { Text = "Max Distance",     Default = 100,  Min = 0,   Max = 745, Rounding = 0, Suffix = "" })

CombatAB:AddLabel("Soft-Aim Hotkey"):AddKeyPicker("LockOnKey", {
    Text    = "Soft-Aim Hotkey",
    Default = "F3",
    Mode    = "Toggle",
})

CombatABSettings:AddLabel("FOV Circle Color"):AddColorPicker("FOVColor", {
    Default      = Color3.fromRGB(255, 255, 255),
    Title        = "FOV Circle Color",
    Transparency = 0,
})

CombatABSettings:AddLabel("Lock Detection Color"):AddColorPicker("LockDetectionColor", {
    Default      = Color3.fromRGB(168, 0, 0),
    Title        = "Detection Color",
    Transparency = 0,
})

CombatABSettings:AddSlider("FOVTransparency", {
    Text     = "FOV Circle Transparency",
    Default  = 0.45,
    Min      = 0,
    Max      = 1,
    Rounding = 2,
    Suffix   = "",
})

CombatABSettings:AddSlider("FOV", { Text = "FOV Radius/Range", Default = 200, Min = 10, Max = 800, Rounding = 0, Suffix = "" })

CombatABSettings:AddDropdown("FOVShape", {
    Text    = "FOV Shape",
    Values  = { "Circle", "Square" },
    Default = 1,
})

local function GetFOVCenter()
    if Options.FOVModeDropdown.Value == "Mouse" then
        return Svc.Input:GetMouseLocation()
    end
    local vp    = GetCamera().ViewportSize
    local inset = Svc.Gui:GetGuiInset()
    return Vector2.new(vp.X / 2, inset.Y + vp.Y / 2)
end

local function GetBodyPart(character, partName)
    if not character then return nil end
    local part = character:FindFirstChild(partName)
    if part then return part end
    if partName == "Torso" then
        return character:FindFirstChild("UpperTorso")
    elseif partName == "UpperTorso" then
        return character:FindFirstChild("Torso")
    end
    return nil
end

local function GetTargetPart(character)
    return GetBodyPart(character, Options.BodyPartDropdown.Value)
end

local function IsTeammate(player)
    if not Toggles.IgnoreTeammatesToggle.Value then return false end
    if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then return true end
    if LocalPlayer.TeamColor and player.TeamColor and LocalPlayer.TeamColor == player.TeamColor then return true end
    return false
end

local function IsWithinDistance(targetCharacter)
    if Options.MaxDistance.Value <= 1 then return true end
    local character = LocalPlayer.Character
    if not character then return false end
    local localRoot = character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return false end
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return false end
    return (localRoot.Position - targetRoot.Position).Magnitude <= Options.MaxDistance.Value
end

local function IsTargetValid(target)
    if not target or not target.Parent or not target.Character then return false end
    if IsTeammate(target) then return false end

    local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    if not IsWithinDistance(target.Character) then return false end

    if Toggles.DeathCheckToggle.Value then
        if humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead then
            return false
        end
    end
    return true
end

local function IsPartTransparent(part)
    return part:IsA("BasePart") and part.Transparency >= TRANSPARENCY_THRESHOLD
end

local function IsPartValidObstacle(part)
    if not part:IsA("BasePart") then return true end
    if IsPartTransparent(part) then return false end
    if not part.CanCollide then return false end
    return true
end

local function IsTargetVisible(targetCharacter)
    if not Toggles.WallCheckToggle.Value then return true end

    local character = LocalPlayer.Character
    if not character then return false end
    local localRoot = character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return false end

    local targetPart = GetTargetPart(targetCharacter)
    if not targetPart then return false end

    local rayOrigin    = localRoot.Position
    local rayDirection = targetPart.Position - rayOrigin

    local baseFilter = { character, targetCharacter }

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = baseFilter
    params.FilterType                 = Enum.RaycastFilterType.Exclude
    params.IgnoreWater                = true

    local result = workspace:Raycast(rayOrigin, rayDirection, params)
    if result == nil then return true end

    if not Toggles.AdvancedWallCheckToggle.Value then
        return false
    end

    local ignored = table.clone(baseFilter)
    for _ = 1, MAX_WALL_IGNORES do
        local testParams = RaycastParams.new()
        testParams.FilterDescendantsInstances = ignored
        testParams.FilterType                 = Enum.RaycastFilterType.Exclude
        testParams.IgnoreWater                = true

        local test = workspace:Raycast(rayOrigin, rayDirection, testParams)
        if test == nil then return true end
        if IsPartValidObstacle(test.Instance) then return false end
        table.insert(ignored, test.Instance)
    end
    return false
end

local function GetNearestPlayer()
    local character = LocalPlayer.Character
    if not character then return nil end
    local localRoot = character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil end

    local camera    = GetCamera()
    local fovCenter = GetFOVCenter()
    local fovRadius = Options.FOV.Value
    local maxDist   = Options.MaxDistance.Value
    local useDist   = maxDist > 1

    local best, bestDist = nil, math.huge

    for _, player in ipairs(Svc.Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and not IsTeammate(player) then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local distOK = true
                    if useDist then
                        distOK = (localRoot.Position - root.Position).Magnitude <= maxDist
                    end
                    if distOK then
                        local screenPos, onScreen = camera:WorldToScreenPoint(root.Position)
                        if onScreen then
                            local d = (Vector2.new(screenPos.X, screenPos.Y) - fovCenter).Magnitude
                            if d <= fovRadius and d < bestDist and IsTargetVisible(player.Character) then
                                bestDist = d
                                best     = player
                            end
                        end
                    end
                end
            end
        end
    end

    return best
end

local function SetTarget(player)
    if S.Target ~= player then
        S.ResX, S.ResY = 0, 0
    end
    S.Target = player
    S.Locked = player ~= nil
end

local function LockCamera()
    if not S.Target or not S.Target.Character then return end
    local targetPart = GetTargetPart(S.Target.Character)
    if not targetPart then return end

    local camera = GetCamera()
    local smooth = math.max(Options.Smoothness.Value, 1)
    local sf     = math.clamp((1 / smooth) * Options.SmoothnessSpeed.Value, 0.001, 1)
    local pos    = targetPart.Position

    if Options.LockMethodDropdown.Value == "Camera" then
        local cf = camera.CFrame
        camera.CFrame = cf:Lerp(CFrame.new(cf.Position, pos), sf)
    else
        local screenPos, onScreen = camera:WorldToScreenPoint(pos)
        if not onScreen then return end

        local delta = (Vector2.new(screenPos.X, screenPos.Y) - Svc.Input:GetMouseLocation()) * sf
        if delta.Magnitude < 0.5 then return end

        local sx = delta.X + S.ResX
        local sy = delta.Y + S.ResY
        local ix, iy = math.round(sx), math.round(sy)
        S.ResX, S.ResY = sx - ix, sy - iy

        if (ix ~= 0 or iy ~= 0) and mousemoverel then
            mousemoverel(ix, iy)
        end
    end
end

local function UpdateFOV()
    local fovCenter = GetFOVCenter()
    local show      = Toggles.ShowFOVToggle.Value
    local color     = Options.FOVColor.Value

    if Toggles.LockDetectionToggle.Value and S.Locked and S.Target and IsTargetValid(S.Target) then
        color = Options.LockDetectionColor.Value
    end

    if Options.FOVShape.Value == "Square" then
        local size = Options.FOV.Value * 2
        FOV.Square.Size         = Vector2.new(size, size)
        FOV.Square.Position     = fovCenter - Vector2.new(size / 2, size / 2)
        FOV.Square.Transparency = Options.FOVTransparency.Value
        FOV.Square.Color        = color
        FOV.Square.Visible      = show
        FOV.Circle.Visible      = false
    else
        FOV.Circle.Position     = fovCenter
        FOV.Circle.Radius       = Options.FOV.Value
        FOV.Circle.Transparency = Options.FOVTransparency.Value
        FOV.Circle.Color        = color
        FOV.Circle.Visible      = show
        FOV.Square.Visible      = false
    end
end

local function InputMatches(input)
    local bound = Options.LockOnKey.Value
    if not bound then return false end
    if input.KeyCode and input.KeyCode.Name == bound then return true end
    if input.UserInputType and input.UserInputType.Name == bound then return true end
    return false
end

Toggles.LockOnToggle:OnChanged(function(state)
    if not state then
        S.Locked  = false
        S.Target  = nil
        S.KeyHeld = false
    end
end)

Toggles.AutoLockToggle:OnChanged(function(state)
    if not state then
        S.Locked = false
        S.Target = nil
    end
end)

Options.FOVShape:OnChanged(function()
    UpdateFOV()
end)

Options.KeybindModeDropdown:OnChanged(function()
    S.KeyHeld = false
    S.Locked  = false
    S.Target  = nil
end)

Options.LockOnKey:OnClick(function()
    if not Toggles.LockOnToggle.Value then return end

    if Options.KeybindModeDropdown.Value == "Hold" then
        if S.KeyHeld then return end
        S.KeyHeld = true
        local nearest = GetNearestPlayer()
        if nearest then
            SetTarget(nearest)
        else
            S.Locked = false
            S.Target = nil
        end
    else
        if S.Locked then
            S.Locked = false
            S.Target = nil
        else
            local nearest = GetNearestPlayer()
            if nearest then
                SetTarget(nearest)
            else
                S.Locked = false
                S.Target = nil
            end
        end
    end
end)

Svc.Input.InputEnded:Connect(function(input)
    if Options.KeybindModeDropdown.Value ~= "Hold" or not S.KeyHeld then return end
    if InputMatches(input) then
        S.KeyHeld = false
        S.Locked  = false
        S.Target  = nil
    end
end)

Svc.Run.RenderStepped:Connect(function()
    UpdateFOV()

    if not Toggles.LockOnToggle.Value then return end

    local valid = S.Target ~= nil
        and IsTargetValid(S.Target)
        and IsTargetVisible(S.Target.Character)

    if not valid then
        if Toggles.AutoLockToggle.Value then
            local nearest = GetNearestPlayer()
            if nearest then
                SetTarget(nearest)
                valid = true
            else
                S.Target = nil
                S.Locked = false
            end
        else
            S.Target = nil
            S.Locked = false
        end
    end

    if not S.Locked or not S.Target or not valid then return end

    LockCamera()
end)

LocalPlayer.CharacterAdded:Connect(function()
    S.Locked  = false
    S.Target  = nil
    S.KeyHeld = false
    S.ResX, S.ResY = 0, 0
end)

Svc.Players.PlayerRemoving:Connect(function(player)
    if player == S.Target then
        S.Target = nil
        S.Locked = false
    end
end)

UpdateFOV()
