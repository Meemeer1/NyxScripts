-- language: Lua, file: trench_decay_v5.lua, target: Roblox Trench Decay, universal executor
-- *no key. RightShift opens/closes menu. all toggles off by default. body/head + team check + team colors.*

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local HAS_DRAWING = pcall(function() return Drawing.new("Line") end)

-- ═══════════════════════════════════════════
-- CONFIG — ALL OFF BY DEFAULT
-- ═══════════════════════════════════════════
local Config = {
    ESP = {
        Enabled = false,
        Highlight = false,
        Chams = false,
        Tracers = false,
        Box = false,
        Names = false,
        Distance = false,
        MaxDistance = 250,
        MinDistance = 250,
        TeamColor = true,          -- green for team, red for enemy
        TeamColorSelf = Color3.fromRGB(80, 220, 120),   -- green
        TeamColorEnemy = Color3.fromRGB(230, 70, 70),   -- red
        TeamColorNeutral = Color3.fromRGB(200, 200, 210),
    },
    WeaponESP = {
        Enabled = false,
        Distance = 250,
        MinDistance = 250,
    },
    Aimbot = {
        Enabled = false,
        AimLock = false,
        WallCheck = false,
        TeamCheck = false,
        Strength = 1,
        Smoothness = 1,
        FOV = 30,
        FOVCircle = false,
        AimKey = Enum.UserInputType.MouseButton2,
        TargetPart = "Head",
    },
}

local WEAPON_NAMES = {
    "Rifle", "SMG", "Shotgun", "Pistol", "LMG",
    "Grenade", "Melee", "Bayonet", "Flare Gun",
    "M1911", "MP40", "Thompson", "BAR", "Springfield",
    "Lee-Enfield", "Mosin", "Luger", "Kar98k", "M1 Garand",
    "Trench Gun", "Flamethrower", "Mortar", "Artillery"
}

-- ═══════════════════════════════════════════
-- TEAM RESOLVER
-- ═══════════════════════════════════════════
-- Roblox-standard Team object first. Trench Decay is PvE so most targets
-- read as Neutral/no team — team check then treats them as enemies unless
-- they share an explicit Team. If the game uses a custom team attribute,
-- this reads it too.
local function getTeam(player)
    if not player then return nil end
    local team = player.Team
    if team then return team end
    -- custom attribute fallback: "Team" / "team" attribute or leaderstats
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

local function teamColor(player)
    if isTeammate(player) then return Config.ESP.TeamColorSelf end
    local t = getTeam(player)
    if t == nil then return Config.ESP.TeamColorNeutral end
    return Config.ESP.TeamColorEnemy
end

-- ═══════════════════════════════════════════
-- GLASS UI HELPERS
-- ═══════════════════════════════════════════
local function glass(parent, size, pos, radius)
    local f = Instance.new("Frame")
    f.Size = size
    f.Position = pos
    f.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    f.BackgroundTransparency = 0.45
    f.BorderSizePixel = 0
    f.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 14)
    c.Parent = f

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(140, 190, 255)
    stroke.Transparency = 0.7
    stroke.Thickness = 1
    stroke.Parent = f

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 180, 220))
    }
    grad.Rotation = 50
    grad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.55),
        NumberSequenceKeypoint.new(1, 0.85)
    }
    grad.Parent = f

    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(1, -4, 1, -4)
    glow.Position = UDim2.fromOffset(2, 2)
    glow.BackgroundColor3 = Color3.fromRGB(120, 180, 255)
    glow.BackgroundTransparency = 0.92
    glow.BorderSizePixel = 0
    glow.ZIndex = 0
    glow.Parent = f
    local gc = Instance.new("UICorner")
    gc.CornerRadius = UDim.new(0, radius or 14)
    gc.Parent = glow

    return f
end

local function makeToggle(parent, text, default, cb, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order
    row.Parent = parent

    local pill = Instance.new("Frame")
    pill.Size = UDim2.fromOffset(34, 18)
    pill.Position = UDim2.fromOffset(0, 8)
    pill.BackgroundColor3 = default and Color3.fromRGB(90, 170, 255) or Color3.fromRGB(45, 45, 58)
    pill.BackgroundTransparency = 0.2
    pill.BorderSizePixel = 0
    pill.Parent = row
    local pc = Instance.new("UICorner") pc.CornerRadius = UDim.new(1,0) pc.Parent = pill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(14, 14)
    knob.Position = default and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = pill
    local kc = Instance.new("UICorner") kc.CornerRadius = UDim.new(1,0) kc.Parent = knob

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -44, 1, 0)
    lbl.Position = UDim2.fromOffset(44, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(225, 228, 240)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        pill.BackgroundColor3 = state and Color3.fromRGB(90, 170, 255) or Color3.fromRGB(45, 45, 58)
        knob.Position = state and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2)
        pcall(cb, state)
    end)
    return row
end

local function makeSlider(parent, text, min, max, default, cb, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 46)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. default
    lbl.TextColor3 = Color3.fromRGB(200, 205, 220)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 5)
    bar.Position = UDim2.fromOffset(0, 28)
    bar.BackgroundColor3 = Color3.fromRGB(40, 42, 55)
    bar.BackgroundTransparency = 0.2
    bar.BorderSizePixel = 0
    bar.Parent = row
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(1,0) bc.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(1,0) fc.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(12, 12)
    knob.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = bar
    local kc = Instance.new("UICorner") kc.CornerRadius = UDim.new(1,0) kc.Parent = knob

    local drag = false
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, -6, 0.5, -6)
            lbl.Text = text .. ": " .. val
            pcall(cb, val)
        end
    end)
    return row
end

local function makeHeader(parent, text, order)
    local h = Instance.new("TextLabel")
    h.Size = UDim2.new(1, 0, 0, 26)
    h.BackgroundTransparency = 1
    h.Text = text
    h.TextColor3 = Color3.fromRGB(120, 190, 255)
    h.TextSize = 11
    h.Font = Enum.Font.GothamBold
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.LayoutOrder = order
    h.Parent = parent

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 1, 0)
    line.BackgroundColor3 = Color3.fromRGB(100, 170, 255)
    line.BackgroundTransparency = 0.6
    line.BorderSizePixel = 0
    line.Parent = h
    return h
end

local function makeSegmented(parent, text, options, default, cb, order)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 52)
    holder.BackgroundTransparency = 1
    holder.LayoutOrder = order
    holder.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(200, 205, 220)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = holder

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 28)
    track.Position = UDim2.fromOffset(0, 20)
    track.BackgroundColor3 = Color3.fromRGB(35, 37, 48)
    track.BackgroundTransparency = 0.25
    track.BorderSizePixel = 0
    track.Parent = holder
    local tc = Instance.new("UICorner") tc.CornerRadius = UDim.new(0, 8) tc.Parent = track

    local state = default
    local buttons = {}
    local n = #options
    for i, opt in ipairs(options) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1 / n, -4, 1, -4)
        b.Position = UDim2.new((i - 1) / n, 2, 0, 2)
        b.BackgroundColor3 = (state == opt) and Color3.fromRGB(90, 170, 255) or Color3.fromRGB(50, 52, 66)
        b.BackgroundTransparency = (state == opt) and 0.15 or 0.35
        b.Text = opt
        b.TextColor3 = Color3.fromRGB(240, 242, 250)
        b.TextSize = 12
        b.Font = Enum.Font.GothamMedium
        b.BorderSizePixel = 0
        b.Parent = track
        local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 6) bc.Parent = b
        table.insert(buttons, { btn = b, name = opt })

        b.MouseButton1Click:Connect(function()
            state = opt
            for _, entry in ipairs(buttons) do
                local active = (entry.name == state)
                entry.btn.BackgroundColor3 = active and Color3.fromRGB(90, 170, 255) or Color3.fromRGB(50, 52, 66)
                entry.btn.BackgroundTransparency = active and 0.15 or 0.35
            end
            pcall(cb, state)
        end)
    end
    return holder
end

-- ═══════════════════════════════════════════
-- BUILD MENU
-- ═══════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name = "TD_GlassMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999999
do
    local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not ok or not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local main = glass(gui, UDim2.fromOffset(400, 600), UDim2.new(0.5, -200, 0.5, -300), 16)
main.Active = true
main.Draggable = true
main.Name = "Main"
main.Visible = false

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundTransparency = 1
titleBar.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 24)
title.Position = UDim2.fromOffset(16, 8)
title.BackgroundTransparency = 1
title.Text = "TRENCH DECAY"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 17
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1, -60, 0, 14)
sub.Position = UDim2.fromOffset(16, 28)
sub.BackgroundTransparency = 1
sub.Text = "glassmorphic suite · v5"
sub.TextColor3 = Color3.fromRGB(120, 185, 255)
sub.TextSize = 10
sub.Font = Enum.Font.Gotham
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(26, 26)
closeBtn.Position = UDim2.new(1, -38, 0, 9)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 70)
closeBtn.BackgroundTransparency = 0.15
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 17
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(1,0) cc.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function()
    main.Visible = false
end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -24, 1, -60)
scroll.Position = UDim2.fromOffset(12, 50)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 180, 255)
scroll.ScrollBarImageTransparency = 0.4
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 4)
pad.PaddingBottom = UDim.new(0, 8)
pad.Parent = scroll

makeHeader(scroll, "PLAYER ESP", 1)
makeToggle(scroll, "Enable ESP", false, function(v) Config.ESP.Enabled = v end, 2)
makeToggle(scroll, "Highlight (glass fill)", false, function(v) Config.ESP.Highlight = v end, 3)
makeToggle(scroll, "Chams (always-on-top)", false, function(v) Config.ESP.Chams = v end, 4)
makeToggle(scroll, "Tracers", false, function(v) Config.ESP.Tracers = v end, 5)
makeToggle(scroll, "Box", false, function(v) Config.ESP.Box = v end, 6)
makeToggle(scroll, "Names", false, function(v) Config.ESP.Names = v end, 7)
makeToggle(scroll, "Distance", false, function(v) Config.ESP.Distance = v end, 8)
makeToggle(scroll, "Team Colors (green/red)", true, function(v) Config.ESP.TeamColor = v end, 9)
makeSlider(scroll, "ESP Min Dist", 250, 1000, 250, function(v) Config.ESP.MinDistance = v end, 10)
makeSlider(scroll, "ESP Max Dist", 250, 1000, 250, function(v) Config.ESP.MaxDistance = v end, 11)

makeHeader(scroll, "WEAPON ESP", 12)
makeToggle(scroll, "Enable Weapon ESP", false, function(v) Config.WeaponESP.Enabled = v end, 13)
makeSlider(scroll, "Weapon Min Dist", 250, 1000, 250, function(v) Config.WeaponESP.MinDistance = v end, 14)
makeSlider(scroll, "Weapon Max Dist", 250, 1000, 250, function(v) Config.WeaponESP.Distance = v end, 15)

makeHeader(scroll, "AIMBOT / AIMLOCK", 16)
makeToggle(scroll, "Aimbot (hold RMB)", false, function(v) Config.Aimbot.Enabled = v end, 17)
makeToggle(scroll, "AimLock (continuous)", false, function(v) Config.Aimbot.AimLock = v end, 18)
makeSegmented(scroll, "Target Part", {"Head", "Body"}, "Head", function(v) Config.Aimbot.TargetPart = v end, 19)
makeToggle(scroll, "Wall Check", false, function(v) Config.Aimbot.WallCheck = v end, 20)
makeToggle(scroll, "Team Check (skip teammates)", false, function(v) Config.Aimbot.TeamCheck = v end, 21)
makeToggle(scroll, "FOV Circle", false, function(v) Config.Aimbot.FOVCircle = v end, 22)
makeSlider(scroll, "FOV", 30, 360, 30, function(v) Config.Aimbot.FOV = v end, 23)
makeSlider(scroll, "Strength", 1, 100, 1, function(v) Config.Aimbot.Strength = v end, 24)
makeSlider(scroll, "Smoothness", 1, 100, 1, function(v) Config.Aimbot.Smoothness = v end, 25)

-- ═══════════════════════════════════════════
-- RIGHT SHIFT TOGGLE
-- ═══════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        main.Visible = not main.Visible
    end
end)

-- ═══════════════════════════════════════════
-- TARGET RESOLVER
-- ═══════════════════════════════════════════
local function getAimPart(character)
    if not character then return nil end
    if Config.Aimbot.TargetPart == "Head" then
        local head = character:FindFirstChild("Head")
        if head and head:IsA("BasePart") then return head end
        return character:FindFirstChild("HumanoidRootPart")
    else
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp:IsA("BasePart") then return hrp end
        return character:FindFirstChild("Head")
    end
end

-- ═══════════════════════════════════════════
-- ESP
-- ═══════════════════════════════════════════
local espCache, tracerCache, weaponCache = {}, {}, {}
local fovCircle = nil

local function newBox(color)
    local outer = Drawing.new("Square")
    outer.Filled = false
    outer.Color = color
    outer.Thickness = 1.5
    outer.Transparency = 0.9
    outer.Visible = false

    local inner = Drawing.new("Square")
    inner.Filled = true
    inner.Color = color
    inner.Thickness = 0
    inner.Transparency = 0.08
    inner.Visible = false
    return { outer = outer, inner = inner }
end

local function newTracer(color)
    local l = Drawing.new("Line")
    l.Color = color
    l.Thickness = 1.5
    l.Transparency = 0.7
    l.Visible = false
    return l
end

local function newText(color, size)
    local t = Drawing.new("Text")
    t.Color = color
    t.Size = size
    t.Center = true
    t.Outline = true
    t.OutlineColor = Color3.fromRGB(0, 0, 0)
    t.Visible = false
    return t
end

local function isVisible(part)
    if not Config.Aimbot.WallCheck then return true end
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

local function closest()
    local best, bestDist = nil, Config.Aimbot.FOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            -- team check: skip teammates when enabled
            if Config.Aimbot.TeamCheck and isTeammate(p) then
                continue
            end
            local aimPart = getAimPart(p.Character)
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if aimPart and hum and hum.Health > 0 then
                local sp, on = Camera:WorldToViewportPoint(aimPart.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < bestDist and isVisible(aimPart) then
                        bestDist = d
                        best = aimPart
                    end
                end
            end
        end
    end
    return best
end

if HAS_DRAWING then
    RunService.RenderStepped:Connect(function()
        if Config.Aimbot.FOVCircle then
            if not fovCircle then
                fovCircle = Drawing.new("Circle")
                fovCircle.Filled = false
                fovCircle.Color = Color3.fromRGB(120, 190, 255)
                fovCircle.Thickness = 1
                fovCircle.Transparency = 0.6
            end
            fovCircle.Visible = true
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            fovCircle.Radius = Config.Aimbot.FOV / 2
        elseif fovCircle then
            fovCircle.Visible = false
        end

        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local char = p.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local alive = hrp and hum and hum.Health > 0

            local dist = alive and (Camera.CFrame.Position - hrp.Position).Magnitude or 0
            local show = Config.ESP.Enabled and alive
                and dist >= Config.ESP.MinDistance
                and dist <= Config.ESP.MaxDistance

            -- color per team when TeamColor is on, else default blue
            local col = Config.ESP.TeamColor and teamColor(p) or Color3.fromRGB(120, 190, 255)

            local hl = char and char:FindFirstChild("TD_HL")
            if Config.ESP.Highlight and show and char then
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "TD_HL"
                    hl.Adornee = char
                    hl.FillColor = col
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.OutlineTransparency = 0.4
                    hl.Parent = char
                end
                hl.FillColor = col
                hl.FillTransparency = Config.ESP.Chams and 0.45 or 0.8
                hl.DepthMode = Config.ESP.Chams
                    and Enum.HighlightDepthMode.AlwaysOnTop
                    or Enum.HighlightDepthMode.Occluded
            elseif hl then
                hl:Destroy()
            end

            if not show then
                local c = espCache[p]
                if c then
                    c.box.outer.Visible = false
                    c.box.inner.Visible = false
                    c.name.Visible = false
                    c.dist.Visible = false
                end
                if tracerCache[p] then tracerCache[p].Visible = false end
                continue
            end

            local top = hrp.Position + Vector3.new(0, 3, 0)
            local bot = hrp.Position - Vector3.new(0, 3, 0)
            local ts, ton = Camera:WorldToViewportPoint(top)
            local bs, bon = Camera:WorldToViewportPoint(bot)
            if not (ton and bon) then continue end

            if not espCache[p] then
                espCache[p] = {
                    box = newBox(col),
                    name = newText(col, 13),
                    dist = newText(col, 12),
                }
            end
            local c = espCache[p]

            -- recolor everything each frame so team toggles update live
            c.box.outer.Color = col
            c.box.inner.Color = col
            c.name.Color = col
            c.dist.Color = col

            local h = math.abs(ts.Y - bs.Y)
            local w = h * 0.6
            local x = ts.X - w / 2
            local y = ts.Y

            if Config.ESP.Box then
                c.box.inner.Size = Vector2.new(w, h)
                c.box.inner.Position = Vector2.new(x, y)
                c.box.inner.Visible = true
                c.box.outer.Size = Vector2.new(w, h)
                c.box.outer.Position = Vector2.new(x, y)
                c.box.outer.Visible = true
            else
                c.box.inner.Visible = false
                c.box.outer.Visible = false
            end

            if Config.ESP.Names then
                c.name.Text = p.Name
                c.name.Position = Vector2.new(ts.X, y - 16)
                c.name.Visible = true
            else
                c.name.Visible = false
            end

            if Config.ESP.Distance then
                c.dist.Text = math.floor(dist) .. "m"
                c.dist.Position = Vector2.new(ts.X, y + h + 6)
                c.dist.Visible = true
            else
                c.dist.Visible = false
            end

            if Config.ESP.Tracers then
                if not tracerCache[p] then tracerCache[p] = newTracer(col) end
                tracerCache[p].Color = col
                tracerCache[p].From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                tracerCache[p].To = Vector2.new(ts.X, ts.Y)
                tracerCache[p].Visible = true
            elseif tracerCache[p] then
                tracerCache[p].Visible = false
            end
        end

        if Config.WeaponESP.Enabled then
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("Model") and obj:FindFirstChild("Handle") then
                    local nm = obj.Name:lower()
                    local isW = false
                    for _, wn in ipairs(WEAPON_NAMES) do
                        if nm:find(wn:lower(), 1, true) then isW = true break end
                    end
                    if isW then
                        local d = (Camera.CFrame.Position - obj.Handle.Position).Magnitude
                        if d >= Config.WeaponESP.MinDistance and d <= Config.WeaponESP.Distance then
                            local sp, on = Camera:WorldToViewportPoint(obj.Handle.Position)
                            if on then
                                local whl = obj:FindFirstChild("TD_WHL")
                                if not whl then
                                    whl = Instance.new("Highlight")
                                    whl.Name = "TD_WHL"
                                    whl.Adornee = obj
                                    whl.FillColor = Color3.fromRGB(255, 190, 90)
                                    whl.FillTransparency = 0.6
                                    whl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                    whl.OutlineTransparency = 0.3
                                    whl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                    whl.Parent = obj
                                end
                                if not weaponCache[obj] then
                                    weaponCache[obj] = newText(Color3.fromRGB(255, 210, 130), 12)
                                end
                                weaponCache[obj].Text = obj.Name
                                weaponCache[obj].Position = Vector2.new(sp.X, sp.Y - 20)
                                weaponCache[obj].Visible = true
                            end
                        end
                    end
                end
            end
        else
            for obj, txt in pairs(weaponCache) do
                txt.Visible = false
                local hh = obj:FindFirstChild("TD_WHL")
                if hh then hh:Destroy() end
            end
        end
    end)
end

-- ═══════════════════════════════════════════
-- AIMBOT / AIMLOCK
-- ═══════════════════════════════════════════
UserInputService.InputBegan:Connect(function(i, proc)
    if proc then return end
    if i.UserInputType == Config.Aimbot.AimKey and Config.Aimbot.Enabled then
        local t = closest()
        if t then
            local s = Config.Aimbot.Strength / 100
            local sm = Config.Aimbot.Smoothness / 100
            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(Camera.CFrame.Position, t.Position),
                s * (1 - sm) * 0.3
            )
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if Config.Aimbot.AimLock and Config.Aimbot.Enabled then
        local t = closest()
        if t then
            local s = Config.Aimbot.Strength / 100
            local sm = Config.Aimbot.Smoothness / 100
            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(Camera.CFrame.Position, t.Position),
                s * (1 - sm) * 0.5
            )
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    for _, c in pairs(espCache) do
        c.box.outer:Remove()
        c.box.inner:Remove()
        c.name:Remove()
        c.dist:Remove()
    end
    espCache = {}
    for _, t in pairs(tracerCache) do t:Remove() end
    tracerCache = {}
end)

print("[TD] v5 loaded. RightShift toggles menu. team check + team colors live.")
