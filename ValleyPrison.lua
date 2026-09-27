--[[
    Aim Assist Script - Private Testing Only
    Features: Toggle, FOV circle, Smoothness, Target Lock, Keybind, Wallcheck, Target Switching
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

------------------------------------------------------------
-- CONFIGURATION
------------------------------------------------------------
local Config = {
    -- Core
    Enabled = false,               -- master toggle
    AimKey = Enum.KeyCode.E,       -- hold or toggle this to aim
    ToggleMode = true,             -- true = toggle, false = hold

    -- FOV
    FOV = 120,                     -- radius in pixels
    ShowFOV = true,                -- draw FOV circle
    FOVColor = Color3.fromRGB(0, 255, 170),

    -- Aim behavior
    Smoothness = 0.15,             -- 0 = instant, 1 = slowest
    TargetLock = false,            -- if true, stays on one target until lost/dead
    WallCheck = true,              -- raycast visibility check
    TeamCheck = false,             -- ignore teammates (works only if game uses Teams)

    -- Target switching
    SwitchKey = Enum.KeyCode.Q,    -- cycle to next target while aiming
    
    -- Body part priority (first found in order)
    HitParts = { "Head", "UpperTorso", "HumanoidRootPart", "Torso", "LowerTorso" },
}

------------------------------------------------------------
-- STATE
------------------------------------------------------------
local CurrentTarget = nil
local TargetList = {}
local TargetIndex = 0
local IsAiming = false
local FOVCircle = nil

------------------------------------------------------------
-- GUI (FOV Circle + Status)
------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimAssistUI"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- FOV circle using a frame + UICorner trick (draws a ring)
FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2)
FOVCircle.Visible = false
FOVCircle.Parent = ScreenGui

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 1.5
FOVStroke.Color = Config.FOVColor
FOVStroke.Transparency = 0.3
FOVStroke.Parent = FOVCircle

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------
local function isAlive(plr)
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function getHitPart(char)
    for _, name in ipairs(Config.HitParts) do
        local part = char:FindFirstChild(name)
        if part then return part end
    end
    return nil
end

local function isVisible(targetPart)
    if not Config.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character, Camera }

    local result = Workspace:Raycast(origin, direction, params)
    if not result then return true end
    -- If the first thing hit is part of the target character, it's visible
    return result.Instance:IsDescendantOf(targetPart.Parent)
end

local function isSameTeam(plr)
    if not Config.TeamCheck then return false end
    if not plr.Team or not LocalPlayer.Team then return false end
    return plr.Team == LocalPlayer.Team
end

local function screenDistance(worldPos)
    local screenPoint, onScreen = Camera:WorldToViewportPoint(worldPos)
    if not onScreen then return math.huge end
    local mousePos = UserInputService:GetMouseLocation()
    return (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
end

------------------------------------------------------------
-- TARGETING
------------------------------------------------------------
local function buildTargetList()
    local list = {}
    local mousePos = UserInputService:GetMouseLocation()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isAlive(plr) and not isSameTeam(plr) then
            local char = plr.Character
            local part = getHitPart(char)
            if part then
                local dist = screenDistance(part.Position)
                if dist <= Config.FOV and isVisible(part) then
                    table.insert(list, { player = plr, part = part, dist = dist })
                end
            end
        end
    end

    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end

local function validateTarget(entry)
    if not entry or not entry.player or not entry.player.Character then return false end
    local hum = entry.player.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local part = getHitPart(entry.player.Character)
    if not part then return false end
    if screenDistance(part.Position) > Config.FOV then return false end
    if not isVisible(part) then return false end
    entry.part = part
    return true
end

local function switchTarget()
    TargetList = buildTargetList()
    if #TargetList == 0 then
        CurrentTarget = nil
        return
    end
    TargetIndex = TargetIndex % #TargetList + 1
    CurrentTarget = TargetList[TargetIndex]
end

------------------------------------------------------------
-- AIM LOGIC
------------------------------------------------------------
local function aimAt(targetPart)
    local targetPos = targetPart.Position
    local camPos = Camera.CFrame.Position
    local desiredCFrame = CFrame.new(camPos, targetPos)

    if Config.Smoothness <= 0 then
        Camera.CFrame = desiredCFrame
    else
        -- exponential smoothing (frame-rate independent-ish)
        local alpha = math.clamp(1 - Config.Smoothness, 0.01, 1)
        Camera.CFrame = Camera.CFrame:Lerp(desiredCFrame, alpha)
    end
end

RunService:BindToRenderStep("AimAssist", Enum.RenderPriority.Camera.Value + 1, function()
    -- Update FOV circle
    FOVCircle.Visible = Config.ShowFOV and Config.Enabled
    if Config.ShowFOV then
        local mousePos = UserInputService:GetMouseLocation()
        FOVCircle.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
        FOVCircle.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2)
        FOVStroke.Color = Config.FOVColor
    end

    if not Config.Enabled or not IsAiming then return end
    if not LocalPlayer.Character or not isAlive(LocalPlayer) then return end

    -- Target lock handling
    if Config.TargetLock then
        if not validateTarget(CurrentTarget) then
            CurrentTarget = nil
        end
    else
        -- Non-lock: always pick closest
        local list = buildTargetList()
        if #list > 0 then
            CurrentTarget = list[1]
        else
            CurrentTarget = nil
        end
    end

    if not CurrentTarget then
        -- Auto acquire once
        switchTarget()
    end

    if CurrentTarget and CurrentTarget.part then
        aimAt(CurrentTarget.part)
    end
end)

------------------------------------------------------------
-- INPUT
------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == Config.AimKey then
        if Config.ToggleMode then
            IsAiming = not IsAiming
        else
            IsAiming = true
        end
        if IsAiming then
            TargetIndex = 0
            switchTarget()
        end
    elseif input.KeyCode == Config.SwitchKey and IsAiming then
        switchTarget()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Config.AimKey and not Config.ToggleMode then
        IsAiming = false
        CurrentTarget = nil
    end
end)

------------------------------------------------------------
-- CLEANUP ON RESPAWN
------------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function()
    CurrentTarget = nil
    TargetList = {}
    TargetIndex = 0
end)

------------------------------------------------------------
-- PUBLIC API (for quick in-game tweaks via executor console)
------------------------------------------------------------
_G.AimAssist = {
    Config = Config,
    Enable = function() Config.Enabled = true end,
    Disable = function() Config.Enabled = false end,
    Toggle = function() Config.Enabled = not Config.Enabled end,
    SetFOV = function(v) Config.FOV = v end,
    SetSmoothness = function(v) Config.Smoothness = v end,
    SetTargetLock = function(v) Config.TargetLock = v end,
    SetWallCheck = function(v) Config.WallCheck = v end,
}
