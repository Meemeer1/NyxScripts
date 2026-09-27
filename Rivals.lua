-- language: Lua, file: rivals_aimbot_fix.lua, target: Roblox Rivals, universal executor
-- *hold RMB to aim. continuous per-frame rotation while held.*

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local HAS_DRAWING = pcall(function() return Drawing.new("Line") end)

-- ═══════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════
local Config = {
    Aim = {
        Enabled = false,
        AimLock = false,
        WallCheck = false,
        TeamCheck = true,
        FOV = 150,
        Smooth = 0.15,           -- higher = snappier. 0.02 is too slow for one frame.
        Part = "Head",
        Key = Enum.UserInputType.MouseButton2,
        FOVRing = false,
        FOVRingColor = Color3.fromRGB(120, 190, 255),
        RequireGun = false,
    },
}

-- ═══════════════════════════════════════════
-- TEAM CHECK
-- ═══════════════════════════════════════════
local function getTeam(player)
    if not player then return nil end
    if player.Team then return player.Team end
    local attr = player:GetAttribute("Team") or player:GetAttribute("team")
    if attr then return tostring(attr) end
    local ls = player:FindFirstChild("leaderstats")
    if ls then
        local t = ls:FindFirstChild("Team")
        if t then return tostring(t.Value) end
    end
    return nil
end

local function isTeammate(player)
    if player == LocalPlayer then return true end
    local myTeam = getTeam(LocalPlayer)
    local theirTeam = getTeam(player)
    if myTeam == nil or theirTeam == nil then return false end
    return tostring(myTeam) == tostring(theirTeam)
end

-- ═══════════════════════════════════════════
-- TARGET RESOLUTION
-- ═══════════════════════════════════════════
local function getPlayerAimPart(character)
    if not character then return nil end
    if Config.Aim.Part == "Head" then
        local head = character:FindFirstChild("Head")
        if head and head:IsA("BasePart") then return head end
    end
    local p = character:FindFirstChild(Config.Aim.Part)
    if p and p:IsA("BasePart") then return p end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
end

local function isVisible(part)
    if not Config.Aim.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { LocalPlayer.Character }
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ok, r = pcall(function() return Workspace:Raycast(origin, dir, params) end)
    if not ok then return true end
    if r and r.Instance then return r.Instance:IsDescendantOf(part.Parent) end
    return true
end

local function hasGunEquipped()
    local char = LocalPlayer.Character
    if not char then return false end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then return true end
    end
    return false
end

local function closestAim()
    if Config.Aim.RequireGun and not hasGunEquipped() then return nil end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local best, bestDist = nil, Config.Aim.FOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if Config.Aim.TeamCheck and isTeammate(p) then
                -- skip teammate
            else
                local part = getPlayerAimPart(p.Character)
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if part and hum and hum.Health > 0 then
                    local sp, on = Camera:WorldToViewportPoint(part.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < bestDist and isVisible(part) then
                            bestDist = d
                            best = part
                        end
                    end
                end
            end
        end
    end
    return best
end

-- ═══════════════════════════════════════════
-- HOLD STATE — this is the fix
-- ═══════════════════════════════════════════
local aimHeld = false

UserInputService.InputBegan:Connect(function(i, proc)
    if proc then return end
    if i.UserInputType == Config.Aim.Key then
        aimHeld = true
    end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Config.Aim.Key then
        aimHeld = false
    end
end)

-- ═══════════════════════════════════════════
-- AIM LOOP — runs every frame while held
-- ═══════════════════════════════════════════
local fovRing = nil

RunService.RenderStepped:Connect(function(dt)
    -- FOV ring
    if Config.Aim.FOVRing then
        if not fovRing then
            fovRing = Drawing.new("Circle")
            fovRing.Filled = false
            fovRing.Thickness = 1.5
            fovRing.Transparency = 0.75
        end
        fovRing.Visible = true
        fovRing.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovRing.Radius = Config.Aim.FOV
        fovRing.Color = Config.Aim.FOVRingColor
    elseif fovRing then
        fovRing.Visible = false
    end

    -- Aimbot: only when enabled AND key held AND not in aimlock mode
    if Config.Aim.Enabled and aimHeld and not Config.Aim.AimLock then
        local target = closestAim()
        if target then
            local smooth = math.clamp(Config.Aim.Smooth, 0.02, 1.0)
            -- frame-rate independent: 1 - (1-smooth)^(dt*60)
            local alpha = 1 - math.pow(1 - smooth, dt * 60)
            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(Camera.CFrame.Position, target.Position),
                alpha
            )
        end
    end

    -- AimLock: continuous hard snap, independent of key
    if Config.Aim.AimLock and Config.Aim.Enabled then
        local target = closestAim()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
end)

print("[RIVALS] aimbot fix loaded. Hold RMB to aim. AimLock ignores key.")
