-- language: Lua, file: trench_decay_v7.lua, target: Roblox Trench Decay, universal executor
-- *no key. RightShift opens/closes menu. players + NPCs. real weapon list.*

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local HAS_DRAWING = pcall(function() return Drawing.new("Line") end)

-- ═══════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════
local Config = {
    ESP = {
        Enabled = false,
        Players = true,
        NPCs = true,
        Highlight = false,
        WallHack = false,
        Name = false,
        Health = false,
        Distance = false,
        Box = false,
        Tracer = false,
        Chams = false,
        TeamColors = true,
        MaxDist = 250,
        MinDist = 250,
        ColorSelf = Color3.fromRGB(80, 220, 120),
        ColorEnemy = Color3.fromRGB(230, 70, 70),
        ColorNeutral = Color3.fromRGB(200, 200, 210),
    },
    WeaponESP = {
        Enabled = false,
        MinDist = 250,
        MaxDist = 250,
    },
    Aim = {
        Enabled = false,
        AimLock = false,
        Triggerbot = false,
        TriggerDelay = 0.01,
        RequireGun = false,
        WallCheck = false,
        TeamCheck = false,
        FOV = 150,
        Smooth = 0.02,
        Part = "Head",
        Key = Enum.UserInputType.MouseButton2,
        FOVRing = false,
        FOVRingColor = Color3.fromRGB(120, 190, 255),
        IncludeNPCs = true,
    },
    Misc = {
        Fullbright = false,
        NoRecoil = false,
        NoSpread = false,
    },
}

-- ═══════════════════════════════════════════
-- REAL TRENCH DECAY WEAPON LIST
-- scanned from WeaponModels folder hierarchy
-- ═══════════════════════════════════════════
local WEAPON_NAMES = {
    -- rifles / SMGs / LMGs
    "AK-74", "AKM", "Aegis", "Bergmann MP18", "Carnage Carbine",
    "Chauchat", "Double-0", "Farquhar Hill 1909", "Hellriegel 1915",
    "Huot Huntermarch", "Lee Enfield", "Lewis Gun", "Lil Timothy",
    "M1891", "M1911", "M1918 BAR", "M27 IAR", "M4A1", "M4A1 MODDED",
    "MG-08", "Mannlicher M95", "Mauser C96", "Mauser Tankgewehr M1918",
    "Mosin Nagant", "Musket", "Nagant 1883 \"Ordem\"", "PKM",
    "RPG-7", "Revolver", "Rotinv's Minigun", "Taurus 82",
    "The \"Tommy\" M1918", "Type 38 Arisaka",
    -- special / named
    "The Demolisher", "The Eternal Chime", "The Hand Cannon",
    "The Revolutionary",
    -- melee / tools
    "Bandage", "Colonels Sabre", "Commandants Cuirassier",
    "Flare Gun", "Guts and Glory", "Medkit",
    "Trench Hammer", "Trench Hatchet", "Trench Knife", "Trench Mace",
    "Trench Machete", "Trench Pickaxe", "Trench Shotgun", "Trench Shovel",
    "Trench Sickle",
}

-- case-insensitive match against the model name; handles parent folder too
local function isWeaponModel(obj)
    if not obj or not obj:IsA("Model") then return false end
    local nm = obj.Name:lower()
    for _, wn in ipairs(WEAPON_NAMES) do
        if nm == wn:lower() or nm:find(wn:lower(), 1, true) then
            return true
        end
    end
    return false
end

-- ═══════════════════════════════════════════
-- TEAM RESOLVER
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

local function teamColor(player)
    if isTeammate(player) then return Config.ESP.ColorSelf end
    local t = getTeam(player)
    if t == nil then return Config.ESP.ColorNeutral end
    return Config.ESP.ColorEnemy
end

-- ═══════════════════════════════════════════
-- NPC DETECTION
-- ═══════════════════════════════════════════
local function isHostileNPC(model)
    if not model or not model:IsA("Model") then return false end
    if model == LocalPlayer.Character then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local plr = Players:GetPlayerFromCharacter(model)
    if plr then return false end
    return true
end

local function getNPCPart(model)
    if not model then return nil end
    if Config.Aim.Part == "Head" then
        local h = model:FindFirstChild("Head")
        if h and h:IsA("BasePart") then return h end
        local h2 = model:FindFirstChild("head")
        if h2 and h2:IsA("BasePart") then return h2 end
    end
    local p = model:FindFirstChild(Config.Aim.Part)
    if p and p:IsA("BasePart") then return p end
    return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
end

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
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, radius or 14) c.Parent = f
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
    local gc = Instance.new("UICorner") gc.CornerRadius = UDim.new(0, radius or 14) gc.Parent = glow
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

local function makeSlider(parent, text, min, max, default, cb, order, isFloat)
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
        or i.UserInputType == Enum.UserInputType.Touch then drag = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local raw = min + (max - min) * rel
            local val = isFloat and math.floor(raw * 100) / 100 or math.floor(raw)
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

local function makeDropdown(parent, text, options, default, cb, order)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 56)
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
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.Position = UDim2.fromOffset(0, 20)
    btn.BackgroundColor3 = Color3.fromRGB(35, 37, 48)
    btn.BackgroundTransparency = 0.25
    btn.Text = "  " .. default .. "  ▾"
    btn.TextColor3 = Color3.fromRGB(240, 242, 250)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamMedium
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.Parent = holder
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 8) bc.Parent = btn
    local open = false
    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, #options * 28)
    list.Position = UDim2.fromOffset(0, 52)
    list.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    list.BackgroundTransparency = 0.1
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 10
    list.Parent = holder
    local lc = Instance.new("UICorner") lc.CornerRadius = UDim.new(0, 8) lc.Parent = list
    local state = default
    for i, opt in ipairs(options) do
        local o = Instance.new("TextButton")
        o.Size = UDim2.new(1, 0, 0, 28)
        o.Position = UDim2.fromOffset(0, (i - 1) * 28)
        o.BackgroundTransparency = 1
        o.Text = "  " .. opt
        o.TextColor3 = Color3.fromRGB(220, 225, 235)
        o.TextSize = 13
        o.Font = Enum.Font.Gotham
        o.TextXAlignment = Enum.TextXAlignment.Left
        o.ZIndex = 11
        o.Parent = list
        o.MouseButton1Click:Connect(function()
            state = opt
            btn.Text = "  " .. opt .. "  ▾"
            list.Visible = false
            open = false
            pcall(cb, state)
        end)
    end
    btn.MouseButton1Click:Connect(function()
        open = not open
        list.Visible = open
    end)
    return holder
end

local function makeColorPicker(parent, text, default, cb, order)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 34)
    holder.BackgroundTransparency = 1
    holder.LayoutOrder = order
    holder.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -40, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(225, 228, 240)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = holder
    local swatch = Instance.new("TextButton")
    swatch.Size = UDim2.fromOffset(28, 20)
    swatch.Position = UDim2.new(1, -28, 0.5, -10)
    swatch.BackgroundColor3 = default
    swatch.Text = ""
    swatch.BorderSizePixel = 0
    swatch.Parent = holder
    local sc = Instance.new("UICorner") sc.CornerRadius = UDim.new(0, 6) sc.Parent = swatch
    local r, g, b = default.R * 255, default.G * 255, default.B * 255
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(1, 0, 0, 72)
    panel.Position = UDim2.fromOffset(0, 34)
    panel.BackgroundColor3 = Color3.fromRGB(25, 27, 36)
    panel.BackgroundTransparency = 0.2
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = holder
    local pc = Instance.new("UICorner") pc.CornerRadius = UDim.new(0, 8) pc.Parent = panel
    local function mkChan(name, y, init, setter)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0, 16, 0, 16)
        l.Position = UDim2.fromOffset(8, y)
        l.BackgroundTransparency = 1
        l.Text = name
        l.TextColor3 = Color3.fromRGB(200, 205, 220)
        l.TextSize = 11
        l.Font = Enum.Font.GothamBold
        l.Parent = panel
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -40, 0, 6)
        bar.Position = UDim2.fromOffset(28, y + 5)
        bar.BackgroundColor3 = Color3.fromRGB(40, 42, 55)
        bar.BorderSizePixel = 0
        bar.Parent = panel
        local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(1,0) bc.Parent = bar
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(init / 255, 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
        fill.BorderSizePixel = 0
        fill.Parent = bar
        local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(1,0) fc.Parent = fill
        local kn = Instance.new("Frame")
        kn.Size = UDim2.fromOffset(10, 10)
        kn.Position = UDim2.new(init / 255, -5, 0.5, -5)
        kn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        kn.BorderSizePixel = 0
        kn.Parent = bar
        local kc = Instance.new("UICorner") kc.CornerRadius = UDim.new(1,0) kc.Parent = kn
        local drag = false
        kn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local v = math.floor(rel * 255)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                kn.Position = UDim2.new(rel, -5, 0.5, -5)
                setter(v)
            end
        end)
    end
    mkChan("R", 8, r, function(v) r = v local c = Color3.fromRGB(r, g, b) swatch.BackgroundColor3 = c pcall(cb, c) end)
    mkChan("G", 30, g, function(v) g = v local c = Color3.fromRGB(r, g, b) swatch.BackgroundColor3 = c pcall(cb, c) end)
    mkChan("B", 52, b, function(v) b = v local c = Color3.fromRGB(r, g, b) swatch.BackgroundColor3 = c pcall(cb, c) end)
    swatch.MouseButton1Click:Connect(function()
        panel.Visible = not panel.Visible
        holder.Size = panel.Visible and UDim2.new(1, 0, 0, 106) or UDim2.new(1, 0, 0, 34)
    end)
    return holder
end

-- ═══════════════════════════════════════════
-- BUILD MENU — TABS
-- ═══════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name = "TD_GlassMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999999
do
    local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not ok or not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end

local main = glass(gui, UDim2.fromOffset(440, 560), UDim2.new(0.5, -220, 0.5, -280), 16)
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
sub.Text = "full suite · v7"
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
closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -24, 0, 30)
tabBar.Position = UDim2.fromOffset(12, 48)
tabBar.BackgroundTransparency = 1
tabBar.Parent = main

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = tabBar

local pages, tabButtons = {}, {}

local function switchTab(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, b in pairs(tabButtons) do
        b.BackgroundColor3 = (n == name) and Color3.fromRGB(90, 170, 255) or Color3.fromRGB(35, 37, 48)
        b.BackgroundTransparency = (n == name) and 0.15 or 0.4
    end
end

local function makeTabButton(name)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(90, 30)
    b.BackgroundColor3 = Color3.fromRGB(35, 37, 48)
    b.BackgroundTransparency = 0.4
    b.Text = name
    b.TextColor3 = Color3.fromRGB(240, 242, 250)
    b.TextSize = 12
    b.Font = Enum.Font.GothamMedium
    b.BorderSizePixel = 0
    b.Parent = tabBar
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 8) bc.Parent = b
    b.MouseButton1Click:Connect(function() switchTab(name) end)
    tabButtons[name] = b
    return b
end

local function makePage(name)
    local s = Instance.new("ScrollingFrame")
    s.Size = UDim2.new(1, -24, 1, -90)
    s.Position = UDim2.fromOffset(12, 84)
    s.BackgroundTransparency = 1
    s.BorderSizePixel = 0
    s.ScrollBarThickness = 3
    s.ScrollBarImageColor3 = Color3.fromRGB(100, 180, 255)
    s.ScrollBarImageTransparency = 0.4
    s.CanvasSize = UDim2.new(0, 0, 0, 0)
    s.AutomaticCanvasSize = Enum.AutomaticSize.Y
    s.Visible = false
    s.Parent = main
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 8)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = s
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, 4)
    p.PaddingBottom = UDim.new(0, 8)
    p.Parent = s
    pages[name] = s
    return s
end

makeTabButton("Home")
makeTabButton("Combat")
makeTabButton("ESP")
makeTabButton("Settings")

local homePage = makePage("Home")
local combatPage = makePage("Combat")
local espPage = makePage("ESP")
local settingsPage = makePage("Settings")

makeHeader(homePage, "STATUS", 1)
makeToggle(homePage, "ESP Master", false, function(v) Config.ESP.Enabled = v end, 2)
makeToggle(homePage, "Aimbot", false, function(v) Config.Aim.Enabled = v end, 3)
makeToggle(homePage, "AimLock", false, function(v) Config.Aim.AimLock = v end, 4)
makeToggle(homePage, "Triggerbot", false, function(v) Config.Aim.Triggerbot = v end, 5)
makeHeader(homePage, "MISC", 6)
makeToggle(homePage, "Fullbright", false, function(v)
    Config.Misc.Fullbright = v
    if v then
        Lighting.Brightness = 3
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        pcall(function()
            Lighting.Ambient = Color3.fromRGB(180, 180, 180)
            Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
        end)
    else
        Lighting.Brightness = 2
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
    end
end, 7)
makeToggle(homePage, "NoRecoil", false, function(v) Config.Misc.NoRecoil = v end, 8)
makeToggle(homePage, "NoSpread", false, function(v) Config.Misc.NoSpread = v end, 9)

makeHeader(combatPage, "AIMBOT", 1)
makeToggle(combatPage, "Aimbot (hold RMB)", false, function(v) Config.Aim.Enabled = v end, 2)
makeToggle(combatPage, "AimLock (continuous snap)", false, function(v) Config.Aim.AimLock = v end, 3)
makeDropdown(combatPage, "Aim Part", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, "Head", function(v) Config.Aim.Part = v end, 4)
makeSlider(combatPage, "FOV (px)", 30, 600, 150, function(v) Config.Aim.FOV = v end, 5)
makeSlider(combatPage, "Smooth", 0.02, 1.00, 0.02, function(v) Config.Aim.Smooth = v end, 6, true)
makeToggle(combatPage, "Require Gun Equipped", false, function(v) Config.Aim.RequireGun = v end, 7)
makeToggle(combatPage, "Wall Check", false, function(v) Config.Aim.WallCheck = v end, 8)
makeToggle(combatPage, "Team Check", false, function(v) Config.Aim.TeamCheck = v end, 9)
makeToggle(combatPage, "Include NPCs", true, function(v) Config.Aim.IncludeNPCs = v end, 10)
makeToggle(combatPage, "FOV Ring", false, function(v) Config.Aim.FOVRing = v end, 11)
makeColorPicker(combatPage, "FOV Ring Color", Color3.fromRGB(120, 190, 255), function(c) Config.Aim.FOVRingColor = c end, 12)

makeHeader(combatPage, "TRIGGERBOT", 13)
makeToggle(combatPage, "Triggerbot", false, function(v) Config.Aim.Triggerbot = v end, 14)
makeSlider(combatPage, "Trigger Delay (s)", 0.01, 0.50, 0.01, function(v) Config.Aim.TriggerDelay = v end, 15, true)

makeHeader(espPage, "TARGETS", 1)
makeToggle(espPage, "ESP Enabled", false, function(v) Config.ESP.Enabled = v end, 2)
makeToggle(espPage, "Players", true, function(v) Config.ESP.Players = v end, 3)
makeToggle(espPage, "NPCs", true, function(v) Config.ESP.NPCs = v end, 4)
makeToggle(espPage, "Team Colors (green/red)", true, function(v) Config.ESP.TeamColors = v end, 5)

makeHeader(espPage, "VISUALS", 6)
makeToggle(espPage, "Highlight", false, function(v) Config.ESP.Highlight = v end, 7)
makeToggle(espPage, "WallHack (AlwaysOnTop)", false, function(v) Config.ESP.WallHack = v end, 8)
makeToggle(espPage, "Chams", false, function(v) Config.ESP.Chams = v end, 9)
makeToggle(espPage, "Box", false, function(v) Config.ESP.Box = v end, 10)
makeToggle(espPage, "Tracer", false, function(v) Config.ESP.Tracer = v end, 11)
makeToggle(espPage, "Name", false, function(v) Config.ESP.Name = v end, 12)
makeToggle(espPage, "Health", false, function(v) Config.ESP.Health = v end, 13)
makeToggle(espPage, "Distance", false, function(v) Config.ESP.Distance = v end, 14)

makeHeader(espPage, "RANGE", 15)
makeSlider(espPage, "ESP Min Dist", 250, 1000, 250, function(v) Config.ESP.MinDist = v end, 16)
makeSlider(espPage, "ESP Max Dist", 250, 1000, 250, function(v) Config.ESP.MaxDist = v end, 17)

makeHeader(espPage, "WEAPON ESP", 18)
makeToggle(espPage, "Enable Weapon ESP", false, function(v) Config.WeaponESP.Enabled = v end, 19)
makeSlider(espPage, "Weapon Min Dist", 250, 1000, 250, function(v) Config.WeaponESP.MinDist = v end, 20)
makeSlider(espPage, "Weapon Max Dist", 250, 1000, 250, function(v) Config.WeaponESP.MaxDist = v end, 21)

makeHeader(settingsPage, "MENU", 1)
makeHeader(settingsPage, "Open/Close: RightShift", 2)
makeHeader(settingsPage, "Drag: title bar", 3)
makeHeader(settingsPage, "TEAM COLORS", 4)
makeColorPicker(settingsPage, "Self (team)", Color3.fromRGB(80, 220, 120), function(c) Config.ESP.ColorSelf = c end, 5)
makeColorPicker(settingsPage, "Enemy", Color3.fromRGB(230, 70, 70), function(c) Config.ESP.ColorEnemy = c end, 6)
makeColorPicker(settingsPage, "Neutral", Color3.fromRGB(200, 200, 210), function(c) Config.ESP.ColorNeutral = c end, 7)

switchTab("Home")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        main.Visible = not main.Visible
    end
end)

-- ═══════════════════════════════════════════
-- ESP ENGINE
-- ═══════════════════════════════════════════
local espCache = {}
local weaponCache = {}
local fovRing = nil

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

local function getEntityColor(model)
    local plr = Players:GetPlayerFromCharacter(model)
    if plr and Config.ESP.TeamColors then
        return teamColor(plr)
    elseif plr then
        return Color3.fromRGB(120, 190, 255)
    end
    return Config.ESP.ColorEnemy
end

local function collectTargets()
    local list = {}
    if Config.ESP.Players then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    table.insert(list, { model = p.Character, player = p, hum = hum, hrp = hrp })
                end
            end
        end
    end
    if Config.ESP.NPCs then
        -- scan workspace recursively for humanoid models
        local function scan(container, depth)
            if depth > 3 then return end
            for _, m in ipairs(container:GetChildren()) do
                if m:IsA("Model") and isHostileNPC(m) then
                    local hrp = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Head")
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    if hrp and hum then
                        table.insert(list, { model = m, player = nil, hum = hum, hrp = hrp })
                    end
                elseif m:IsA("Folder") or (m:IsA("Model") and not m:FindFirstChildOfClass("Humanoid")) then
                    scan(m, depth + 1)
                end
            end
        end
        scan(Workspace, 0)
    end
    return list
end

local function aimTargetPart(entry)
    if entry.player then
        return getPlayerAimPart(entry.model)
    else
        return getNPCPart(entry.model)
    end
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
    local entries = collectTargets()
    for _, entry in ipairs(entries) do
        if entry.player and Config.Aim.TeamCheck and isTeammate(entry.player) then
            -- skip teammates
        elseif (not entry.player) and (not Config.Aim.IncludeNPCs) then
            -- skip NPCs
        else
            local part = aimTargetPart(entry)
            if part then
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
    return best
end

-- ═══════════════════════════════════════════
-- MAIN LOOP
-- ═══════════════════════════════════════════
if HAS_DRAWING then
    RunService.RenderStepped:Connect(function()
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

        if Config.ESP.Enabled then
            local entries = collectTargets()
            local seen = {}
            for _, entry in ipairs(entries) do
                local model = entry.model
                seen[model] = true
                local hrp = entry.hrp
                local hum = entry.hum
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                local show = dist >= Config.ESP.MinDist and dist <= Config.ESP.MaxDist
                local col = getEntityColor(model)

                local hl = model:FindFirstChild("TD_HL")
                local wantHl = show and (Config.ESP.Highlight or Config.ESP.WallHack or Config.ESP.Chams)
                if wantHl then
                    if not hl then
                        hl = Instance.new("Highlight")
                        hl.Name = "TD_HL"
                        hl.Adornee = model
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.OutlineTransparency = 0.4
                        hl.Parent = model
                    end
                    hl.FillColor = col
                    if Config.ESP.Chams then
                        hl.FillTransparency = 0.45
                    elseif Config.ESP.WallHack then
                        hl.FillTransparency = 0.2
                    else
                        hl.FillTransparency = 0.75
                    end
                    hl.DepthMode = (Config.ESP.WallHack or Config.ESP.Chams)
                        and Enum.HighlightDepthMode.AlwaysOnTop
                        or Enum.HighlightDepthMode.Occluded
                elseif hl then
                    hl:Destroy()
                end

                if not show then
                    local c = espCache[model]
                    if c then
                        c.box.outer.Visible = false
                        c.box.inner.Visible = false
                        c.name.Visible = false
                        c.health.Visible = false
                        c.dist.Visible = false
                        c.tracer.Visible = false
                    end
                    continue
                end

                local top = hrp.Position + Vector3.new(0, 3, 0)
                local bot = hrp.Position - Vector3.new(0, 3, 0)
                local ts, ton = Camera:WorldToViewportPoint(top)
                local bs, bon = Camera:WorldToViewportPoint(bot)
                if not (ton and bon) then continue end

                if not espCache[model] then
                    espCache[model] = {
                        box = newBox(col),
                        name = newText(col, 13),
                        health = newText(Color3.fromRGB(120, 255, 120), 11),
                        dist = newText(col, 12),
                        tracer = newTracer(col),
                    }
                end
                local c = espCache[model]
                c.box.outer.Color = col
                c.box.inner.Color = col
                c.name.Color = col
                c.dist.Color = col
                c.tracer.Color = col

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

                local label = entry.player and entry.player.Name or model.Name
                if Config.ESP.Name then
                    c.name.Text = label
                    c.name.Position = Vector2.new(ts.X, y - 16)
                    c.name.Visible = true
                else
                    c.name.Visible = false
                end

                if Config.ESP.Health then
                    local hp = math.floor(hum.Health)
                    local maxhp = math.floor(hum.MaxHealth)
                    c.health.Text = hp .. "/" .. maxhp
                    c.health.Position = Vector2.new(ts.X, y - 30)
                    c.health.Visible = true
                else
                    c.health.Visible = false
                end

                if Config.ESP.Distance then
                    c.dist.Text = math.floor(dist) .. "m"
                    c.dist.Position = Vector2.new(ts.X, y + h + 6)
                    c.dist.Visible = true
                else
                    c.dist.Visible = false
                end

                if Config.ESP.Tracer then
                    c.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    c.tracer.To = Vector2.new(ts.X, ts.Y)
                    c.tracer.Visible = true
                else
                    c.tracer.Visible = false
                end
            end

            for model, c in pairs(espCache) do
                if not seen[model] then
                    c.box.outer.Visible = false
                    c.box.inner.Visible = false
                    c.name.Visible = false
                    c.health.Visible = false
                    c.dist.Visible = false
                    c.tracer.Visible = false
                    local hl = model:FindFirstChild("TD_HL")
                    if hl then hl:Destroy() end
                end
            end
        else
            for model, c in pairs(espCache) do
                c.box.outer.Visible = false
                c.box.inner.Visible = false
                c.name.Visible = false
                c.health.Visible = false
                c.dist.Visible = false
                c.tracer.Visible = false
                local hl = model:FindFirstChild("TD_HL")
                if hl then hl:Destroy() end
            end
        end

        -- ── WEAPON ESP (real folder structure) ──
        if Config.WeaponESP.Enabled then
            -- find WeaponModels folder anywhere in Workspace
            local function scanWeapons(container, depth)
                if depth > 4 then return end
                for _, obj in ipairs(container:GetChildren()) do
                    if obj:IsA("Model") and isWeaponModel(obj) then
                        local handle = obj:FindFirstChild("Handle")
                            or obj:FindFirstChildOfClass("BasePart")
                        local pos = handle and handle.Position or obj:GetPivot().Position
                        local d = (Camera.CFrame.Position - pos).Magnitude
                        if d >= Config.WeaponESP.MinDist and d <= Config.WeaponESP.MaxDist then
                            local sp, on = Camera:WorldToViewportPoint(pos)
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
                    elseif obj:IsA("Folder") or (obj:IsA("Model") and not obj:FindFirstChildOfClass("Humanoid")) then
                        scanWeapons(obj, depth + 1)
                    end
                end
            end
            scanWeapons(Workspace, 0)
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
-- AIMBOT / AIMLOCK / TRIGGERBOT
-- ═══════════════════════════════════════════
local triggerLast = 0

UserInputService.InputBegan:Connect(function(i, proc)
    if proc then return end
    if i.UserInputType == Config.Aim.Key and Config.Aim.Enabled and not Config.Aim.AimLock then
        local t = closestAim()
        if t then
            local smooth = math.clamp(Config.Aim.Smooth, 0.02, 1.0)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, t.Position), smooth)
        end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if Config.Aim.AimLock and Config.Aim.Enabled then
        local t = closestAim()
        if t then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position)
        end
    end

    if Config.Aim.Triggerbot then
        local now = tick()
        if now - triggerLast >= Config.Aim.TriggerDelay then
            local t = closestAim()
            if t then
                local char = LocalPlayer.Character
                local tool = char and char:FindFirstChildOfClass("Tool")
                if tool then
                    local remote = tool:FindFirstChildOfClass("RemoteEvent")
                        or tool:FindFirstChildOfClass("RemoteFunction")
                    if remote then
                        pcall(function()
                            if remote:IsA("RemoteEvent") then
                                remote:FireServer()
                            end
                        end)
                    end
                end
                triggerLast = now
            end
        end
    end

    if Config.Misc.NoRecoil then
        local char = LocalPlayer.Character
        if char then
            local look = Camera.CFrame.LookVector
            local pos = Camera.CFrame.Position
            Camera.CFrame = CFrame.new(pos, pos + look)
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if Config.Misc.NoSpread then
            local char = LocalPlayer.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    for _, name in ipairs({"Spread", "spread", "SpreadValue", "Recoil", "recoil"}) do
                        local v = tool:FindFirstChild(name) or char:FindFirstChild(name)
                        if v and v:IsA("NumberValue") then
                            v.Value = 0
                        end
                    end
                end
            end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    for _, c in pairs(espCache) do
        c.box.outer:Remove()
        c.box.inner:Remove()
        c.name:Remove()
        c.health:Remove()
        c.dist:Remove()
        c.tracer:Remove()
    end
    espCache = {}
end)

print("[TD] v7 loaded. RightShift toggles menu. real weapon list wired.")
