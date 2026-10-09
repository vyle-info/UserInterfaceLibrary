CombatAB = CombatTab:AddLeftGroupbox("M A R D E N Soft-Aim")
CombatABSettings = CombatTab:AddRightGroupbox("M A R D E N Soft-Aim Settings")

local Svc = {
    Players = game:GetService("Players"),
    Input = game:GetService("UserInputService"),
    Run = game:GetService("RunService"),
}

local Camera = workspace.CurrentCamera

local S = {
    Target = nil,
    Locked = false,
    KeyHeld = false,
    Offset = Vector3.new(0, 0, 0),
    Conn = nil,
    WasLockedLastFrame = false,
    ResX = 0,
    ResY = 0,
}

local FOV = {
    Circle = Drawing.new("Circle"),
    Square = Drawing.new("Square"),
}

FOV.Circle.Thickness = 2
FOV.Circle.Radius = 200
FOV.Circle.Color = Color3.fromRGB(255, 255, 255)
FOV.Circle.Transparency = 1
FOV.Circle.Visible = false
FOV.Circle.Filled = false

FOV.Square.Thickness = 2
FOV.Square.Size = Vector2.new(400, 400)
FOV.Square.Color = Color3.fromRGB(255, 255, 255)
FOV.Square.Transparency = 1
FOV.Square.Visible = false
FOV.Square.Filled = false

CombatAB:AddToggle("LockOnToggle", { Text = "Toggle Soft-Aim", Default = false })
CombatAB:AddToggle("ShowFOVToggle", { Text = "Toggle FOV Circle", Default = false })
CombatAB:AddToggle("AutoLockToggle", { Text = "Autolock while in FOV radius", Default = false })
CombatAB:AddToggle("LockDetectionToggle", { Text = "Toggle Detection", Default = false })
CombatAB:AddToggle("WallCheckToggle", { Text = "Wall Check", Default = false })
CombatAB:AddToggle("AdvancedWallCheckToggle", { Text = "Advanced Wall Check", Default = false })
CombatAB:AddToggle("IgnoreTeammatesToggle", { Text = "Team Check", Default = false })
CombatAB:AddToggle("DeathCheckToggle", { Text = "Death Check", Default = false })

CombatAB:AddDropdown("BodyPartDropdown", {
    Text = "Targeted Body Part",
    Values = { "Head", "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart" },
    Default = 3,
})

CombatAB:AddDropdown("KeybindModeDropdown", {
    Text = "Soft-Aim Hotkey Mode",
    Values = { "Toggle", "Hold" },
    Default = 1,
})

CombatAB:AddDropdown("FOVModeDropdown", {
    Text = "FOV Circle Position",
    Values = { "Center", "Mouse" },
    Default = 2,
})

CombatAB:AddDropdown("LockMethodDropdown", {
    Text = "Tracking Method",
    Values = { "Camera", "Cursor" },
    Default = 1,
})

CombatAB:AddSlider("Smoothness", { Text = "Smoothness", Default = 20, Min = 1, Max = 50, Rounding = 1, Suffix = "" })
CombatAB:AddSlider("SmoothnessSpeed", { Text = "Smoothness Speed", Default = 1.75, Min = 0.1, Max = 5, Rounding = 2, Suffix = "" })
CombatAB:AddSlider("MaxDistance", { Text = "Max Distance", Default = 100, Min = 0, Max = 745, Rounding = 0, Suffix = "" })

CombatAB:AddLabel("Soft-Aim Hotkey"):AddKeyPicker("LockOnKey", {
    Text = "Soft-Aim Hotkey",
    Default = "F3",
    Mode = "Toggle",
})

CombatABSettings:AddLabel("FOV Circle Color"):AddColorPicker("FOVColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Title = "FOV Circle Color",
    Transparency = 0,
})

CombatABSettings:AddLabel("Lock Detection Color"):AddColorPicker("LockDetectionColor", {
    Default = Color3.fromRGB(168, 0, 0),
    Title = "Detection Color",
    Transparency = 0,
})

CombatABSettings:AddSlider("FOVTransparency", {
    Text = "FOV Circle Transparency",
    Default = 0.45,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Suffix = "",
})

CombatABSettings:AddSlider("FOV", { Text = "FOV Radius/Range", Default = 200, Min = 10, Max = 800, Rounding = 0, Suffix = "" })

CombatABSettings:AddDropdown("FOVShape", {
    Text = "FOV Shape",
    Values = { "Circle", "Square" },
    Default = 1,
})

Options.FOVShape:OnChanged(function() end)

Toggles.LockOnToggle:OnChanged(function(state)
    if not state then
        S.Locked = false
        S.Target = nil
        if S.Conn then
            S.Conn:Disconnect()
            S.Conn = nil
        end
    end
end)

Toggles.ShowFOVToggle:OnChanged(function(state)
    FOV.Circle.Visible = state
end)

Toggles.AutoLockToggle:OnChanged(function(state)
    if not state then
        S.Locked = false
        S.Target = nil
    end
end)

local function GetFOVCenter()
    if Options.FOVModeDropdown.Value == "Mouse" then
        return Svc.Input:GetMouseLocation()
    else
        return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
end

local function GetBodyPart(character, partName)
    if not character then return nil end
    local part = character:FindFirstChild(partName)
    if not part and partName == "Torso" then
        part = character:FindFirstChild("UpperTorso")
    elseif not part and partName == "UpperTorso" then
        part = character:FindFirstChild("Torso")
    end
    return part
end

local function GetTargetPart(character)
    return GetBodyPart(character, Options.BodyPartDropdown.Value)
end

local function IsTeammate(player)
    if not Toggles.IgnoreTeammatesToggle.Value then return false end
    local lp = Svc.Players.LocalPlayer
    if lp.Team and player.Team and lp.Team == player.Team then return true end
    if lp.TeamColor and player.TeamColor and lp.TeamColor == player.TeamColor then return true end
    return false
end

local function IsWithinDistance(targetCharacter)
    if Options.MaxDistance.Value <= 1 then return true end
    local lp = Svc.Players.LocalPlayer
    if not lp.Character then return false end
    local localRoot = lp.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return false end
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return false end
    return (localRoot.Position - targetRoot.Position).Magnitude <= Options.MaxDistance.Value
end

local function IsTargetValid(target)
    if not target or not target.Parent then return false end
    if not target.Character then return false end
    if IsTeammate(target) then return false end
    local humanoid = target.Character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    if not IsWithinDistance(target.Character) then return false end
    if Toggles.DeathCheckToggle.Value then
        if humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead then return false end
    end
    return true
end

local function IsPartTransparent(part)
    if part:IsA("BasePart") then
        if part.Transparency >= 0.95 then return true end
    end
    if part:IsA("MeshPart") then
        if part.Transparency >= 0.95 then return true end
    end
    for _, child in pairs(part:GetChildren()) do
        if child:IsA("Decal") then
            if child.Transparency >= 0.95 then return true end
        end
    end
    for _, child in pairs(part:GetDescendants()) do
        if child:IsA("SurfaceGui") or child:IsA("BillboardGui") then
            if child.Enabled == false then return true end
        end
    end
    return false
end

local function CanPartCollide(part)
    if part:IsA("BasePart") then
        if not part.CanCollide then return false end
    end
    return true
end

local function IsPartValidObstacle(part)
    if IsPartTransparent(part) then return false end
    if not CanPartCollide(part) then return false end
    return true
end

local function IsTargetVisible(targetCharacter)
    if not Toggles.WallCheckToggle.Value then return true end
    local lp = Svc.Players.LocalPlayer
    if not lp.Character then return false end
    local localRoot = lp.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return false end
    local targetPart = GetTargetPart(targetCharacter)
    if not targetPart then return false end

    local rayOrigin = localRoot.Position
    local rayDirection = targetPart.Position - rayOrigin

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {lp.Character, targetCharacter}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true

    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if raycastResult == nil then return true end

    if Toggles.AdvancedWallCheckToggle.Value then
        local hitPart = raycastResult.Instance
        if not IsPartValidObstacle(hitPart) then
            local ignoredParts = {lp.Character, targetCharacter}
            for _ = 1, 10 do
                local testParams = RaycastParams.new()
                testParams.FilterDescendantsInstances = ignoredParts
                testParams.FilterType = Enum.RaycastFilterType.Exclude
                testParams.IgnoreWater = true
                local testResult = workspace:Raycast(rayOrigin, rayDirection, testParams)
                if testResult == nil then return true end
                local testPart = testResult.Instance
                if IsPartValidObstacle(testPart) then return false end
                table.insert(ignoredParts, testPart)
            end
            return false
        else
            return false
        end
    end

    return false
end

local function GetNearestPlayer()
    local lp = Svc.Players.LocalPlayer
    if not lp.Character then return nil end
    if not lp.Character:FindFirstChild("HumanoidRootPart") then return nil end

    local fovCenter = GetFOVCenter()
    local fovRadius = Options.FOV.Value
    local nearestPlayer = nil
    local nearestDistance = math.huge

    for _, player in pairs(Svc.Players:GetPlayers()) do
        if player == lp then continue end
        if not player.Character then continue end
        if IsTeammate(player) then continue end
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then continue end
        if not IsWithinDistance(player.Character) then continue end
        local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - fovCenter).Magnitude
        if dist <= fovRadius and dist < nearestDistance and IsTargetVisible(player.Character) then
            nearestDistance = dist
            nearestPlayer = player
        end
    end

    return nearestPlayer
end

local function LockCamera()
    if not Options.LockMethodDropdown.Value then return end
    if not S.Target or not S.Target.Character then return end
    local tp = GetTargetPart(S.Target.Character)
    if not tp then return end
    local pos = tp.Position + S.Offset
    local sf  = math.clamp((1 / Options.Smoothness.Value) * Options.SmoothnessSpeed.Value, 0.001, 1)
    if Options.LockMethodDropdown.Value == "Camera" then
        local cf = Camera.CFrame
        Camera.CFrame = cf:Lerp(CFrame.new(cf.Position, pos), sf)
    elseif Options.LockMethodDropdown.Value == "Cursor" then
        local sp, onScreen = Camera:WorldToViewportPoint(pos)
        if not onScreen then return end
        local d = (Vector2.new(sp.X, sp.Y) - Svc.Input:GetMouseLocation()) * sf
        if d.Magnitude < 1 then return end
        local sx = d.X + S.ResX
        local sy = d.Y + S.ResY
        local ix, iy = math.round(sx), math.round(sy)
        S.ResX = sx - ix
        S.ResY = sy - iy
        if ix ~= 0 or iy ~= 0 then mousemoverel(ix, iy) end
    end
end

Options.LockOnKey:OnClick(function()
    if not Toggles.LockOnToggle.Value then
        return
    end

    if Options.KeybindModeDropdown.Value == "Hold" then
        S.KeyHeld = true
        local nearestPlayer = GetNearestPlayer()
        if nearestPlayer then
            S.Target = nearestPlayer
            S.Locked = true
        else
            S.Locked = false
        end
    else
        S.Locked = not S.Locked
        if S.Locked then
            local nearestPlayer = GetNearestPlayer()
            if nearestPlayer then
                S.Target = nearestPlayer
            else
                S.Locked = false
            end
        else
            S.Target = nil
        end
    end
end)

Svc.Input.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if Options.KeybindModeDropdown.Value == "Hold" and S.KeyHeld then
        local boundKey = Options.LockOnKey.Value
        if input.KeyCode.Name == boundKey or input.UserInputType.Name == boundKey then
            S.KeyHeld = false
            S.Locked = false
            S.Target = nil
        end
    end
end)

Svc.Run.RenderStepped:Connect(function()
    local fovCenter = GetFOVCenter()
    local isSquare = Options.FOVShape.Value == "Square"
    local showFOV = Toggles.ShowFOVToggle.Value
    local activeColor = Options.FOVColor.Value

    if Toggles.LockDetectionToggle.Value then
        if S.Locked and S.Target and IsTargetValid(S.Target) then
            activeColor = Options.LockDetectionColor.Value
        end
    end

    if isSquare then
        local size = Options.FOV.Value * 2
        FOV.Square.Size = Vector2.new(size, size)
        FOV.Square.Position = fovCenter - Vector2.new(size / 2, size / 2)
        FOV.Square.Transparency = Options.FOVTransparency.Value
        FOV.Square.Color = activeColor
        FOV.Square.Visible = showFOV
        FOV.Circle.Visible = false
    else
        FOV.Circle.Position = fovCenter
        FOV.Circle.Radius = Options.FOV.Value
        FOV.Circle.Transparency = Options.FOVTransparency.Value
        FOV.Circle.Color = activeColor
        FOV.Circle.Visible = showFOV
        FOV.Square.Visible = false
    end

    if not Toggles.LockOnToggle.Value then return end

    if Toggles.AutoLockToggle.Value then
        local nearestPlayer = GetNearestPlayer()
        if nearestPlayer then
            if S.Target ~= nearestPlayer then
                S.Target = nearestPlayer
            end
            S.Locked = true
        else
            S.Locked = false
            S.Target = nil
        end
    end

    if not S.Locked or not S.Target then return end

    if not IsTargetValid(S.Target) then
        if Toggles.AutoLockToggle.Value then
            local nearestPlayer = GetNearestPlayer()
            if nearestPlayer and IsTargetValid(nearestPlayer) then
                S.Target = nearestPlayer
            else
                S.Target = nil
                S.Locked = false
                return
            end
        else
            S.Target = nil
            S.Locked = false
            return
        end
    end

    if not IsTargetVisible(S.Target.Character) then
        if not Toggles.AutoLockToggle.Value then
            return
        else
            local nearestPlayer = GetNearestPlayer()
            if nearestPlayer and IsTargetValid(nearestPlayer) then
                S.Target = nearestPlayer
            else
                S.Target = nil
                S.Locked = false
                return
            end
        end
    end

    LockCamera()
    S.WasLockedLastFrame = S.Locked
end)

Svc.Players.LocalPlayer.CharacterAdded:Connect(function()
    S.Locked = false
    S.Target = nil
end)

Svc.Players.PlayerRemoving:Connect(function(player)
    if player == S.Target then
        S.Target = nil
        S.Locked = false
    end
end)
