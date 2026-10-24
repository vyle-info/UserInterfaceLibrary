local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserGameSettings = UserSettings():GetService("UserGameSettings")

local BlurController = {
    Enabled = false,
    Unloaded = false,
    Amount = 100,
    FallbackSize = 24,
    GraphicsThreshold = 8,
    Connection = nil,
    RobloxBlur = nil,
    CreatedBlur = false,
}

BlurController.RobloxBlur = Lighting:FindFirstChild("UserInterfaceFallbackBlur")

if not BlurController.RobloxBlur then
    BlurController.CreatedBlur = true

    local Blur = Instance.new("BlurEffect")
    Blur.Name = "UserInterfaceFallbackBlur"
    Blur.Size = BlurController.FallbackSize
    Blur.Enabled = false
    Blur.Parent = Lighting

    BlurController.RobloxBlur = Blur
end

BlurController.RobloxBlur.Enabled = false
BlurController.RobloxBlur.Size = BlurController.FallbackSize

local function GetGraphicsLevel()
    local Quality = UserGameSettings.SavedQualityLevel

    if Quality == Enum.SavedQualitySetting.Automatic then
        local Success, Level = pcall(function()
            return settings().Rendering.QualityLevel.Value
        end)
        return if Success and Level > 0 then Level else nil
    end

    return tonumber(string.match(Quality.Name, "%d+"))
end

local function UpdateBlur()
    if BlurController.Unloaded or Library.Unloaded then
        return
    end

    local Level = GetGraphicsLevel()
    local UseRobloxBlur = Level == nil or Level < BlurController.GraphicsThreshold

    local ShouldBlur = BlurController.Enabled and Library.Toggled == true
    local WantRoblox = ShouldBlur and UseRobloxBlur
    local WantAcrylic = ShouldBlur and not UseRobloxBlur

    if BlurController.RobloxBlur.Enabled ~= WantRoblox then
        BlurController.RobloxBlur.Enabled = WantRoblox
    end

    if Library.Acrylic.Amount ~= BlurController.Amount then
        Library:SetBlurAmount(BlurController.Amount)
    end

    if Library.Acrylic.Enabled ~= WantAcrylic then
        Library:SetBlurEnabled(WantAcrylic)
    end
end

UIManagementGroup:AddToggle("BlurToggle", {
    Text = "UserInterface Blur",
    Default = true,
    Tooltip = "uses standard roblox blur instead of acrylic when graphics is below level 8",

    Callback = function(Value)
        BlurController.Enabled = Value
        UpdateBlur()
    end
})

BlurController.Enabled = Library.Toggles.BlurToggle.Value

BlurController.Connection = RunService.RenderStepped:Connect(function()
    UpdateBlur()
end)

Library:GiveSignal(BlurController.Connection)

UpdateBlur()

Library:OnUnload(function()
    BlurController.Unloaded = true
    BlurController.Enabled = false

    if BlurController.RobloxBlur then
        BlurController.RobloxBlur.Enabled = false

        if BlurController.CreatedBlur then
            BlurController.RobloxBlur:Destroy()
        end
    end

    Library:SetBlurEnabled(false)
end)
