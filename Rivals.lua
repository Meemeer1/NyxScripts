-- language: Lua, file: rivals_glass.lua, target: Roblox Rivals, universal executor
-- *Insert toggles menu. players only. keyless. glassmorphic.*

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local HAS_DRAWING = pcall(function() return Drawing.new("Line") end)

local Config = {
    ESP = {
        Enabled = false,
        Box = false,
        Name = false,
        Health = false,
        Distance = false,
        Tracer = false,
        Highlight = false,
        WallHack = false,
        TeamColors = true,
        MaxDist = 250,
        MinDist = 250,
        ColorSelf = Color3.fromRGB(80, 220, 120),
        ColorEnemy = Color3.fromRGB(230, 70, 70),
        ColorNeutral = Color3.fromRGB(200, 200, 210),
    },
    Aim = {
        Enabled = false,
        AimLock = false,
        Triggerbot = false,
        TriggerDelay = 0.01,
        RequireGun = false,
        WallCheck = false,
        TeamCheck = true,
        FOV = 150,
        Smooth = 0.02,
        Part = "Head",
        Key = Enum.UserInputType.MouseButton2,
        FOVRing = false,
        FOVRingColor = Color3.fromRGB(120, 190, 255),
    },
    Misc = {
        Fullbright = false,
        NoRecoil = false,
        NoSpread = false,
    },
}

local WEAPON_NAMES = {
    "AK-47", "M4A1", "MP5", "Shotgun", "Pistol", "Sniper",
    "Rifle", "SMG", "LMG", "Revolver", "Deagle", "AWP",
}

local function isWeaponModel(obj)
    if not obj or not obj:IsA("Model") then return false end
    local nm = obj.Name:lower()
    for _, wn in ipairs(WEAPON_NAMES) do
        if nm == wn:lower() or nm:find(wn:lower(), 1, true) then return true end
    end
    return false
end

-- Rivals team detection: reads Player.Team and custom attributes
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

-- Glass UI (same as Trench Decay, trimmed for Rivals)
local function glass(parent, size, pos, radius)
    local f = Instance.new("Frame")
    f.Size = size f.Position = pos
    f.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    f.BackgroundTransparency = 0.45
    f.BorderSizePixel = 0
    f.Parent = parent
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, radius or 14) c.Parent = f
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(140, 190, 255)
    stroke.Transparency = 0.7 stroke.Thickness = 1 stroke.Parent = f
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
    return f
end

-- Toggle, Slider, Header, Dropdown, ColorPicker builders (same pattern)
local function makeToggle(parent, text, default, cb, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundTransparency = 1 row.LayoutOrder = order row.Parent = parent
    local pill = Instance.new("Frame")
    pill.Size = UDim2.fromOffset(34, 18) pill.Position = UDim2.fromOffset(0, 8)
    pill.BackgroundColor3 = default and Color3.fromRGB(90, 170, 255) or Color3.fromRGB(45, 45, 58)
    pill.BorderSizePixel = 0 pill.Parent = row
    local pc = Instance.new("UICorner") pc.CornerRadius = UDim.new(1,0) pc.Parent = pill
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(14, 14)
    knob.Position = default and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255) knob.BorderSizePixel = 0 knob.Parent = pill
    local kc = Instance.new("UICorner") kc.CornerRadius = UDim.new(1,0) kc.Parent = knob
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -44, 1, 0) lbl.Position = UDim2.fromOffset(44, 0)
    lbl.BackgroundTransparency = 1 lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(225, 228, 240) lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamMedium lbl.TextXAlignment = Enum.TextXAlignment.Left lbl.Parent = row
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0) btn.BackgroundTransparency = 1 btn.Text = "" btn.Parent = row
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
    row.Size = UDim2.new(1, 0, 0, 46) row.BackgroundTransparency = 1
    row.LayoutOrder = order row.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 16) lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. default lbl.TextColor3 = Color3.fromRGB(200, 205, 220)
    lbl.TextSize = 12 lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left lbl.Parent = row
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 5) bar.Position = UDim2.fromOffset(0, 28)
    bar.BackgroundColor3 = Color3.fromRGB(40, 42, 55) bar.BorderSizePixel = 0 bar.Parent = row
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(1,0) bc.Parent = bar
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100, 180, 255) fill.BorderSizePixel = 0 fill.Parent = bar
    local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(1,0) fc.Parent = fill
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(12, 12)
    knob.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255) knob.BorderSizePixel = 0 knob.Parent = bar
    local kc = Instance.new("UICorner") kc.CornerRadius = UDim.new(1,0) kc.Parent = knob
    local drag = false
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
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
    h.Size = UDim2.new(1, 0, 0, 26) h.BackgroundTransparency = 1
    h.Text = text h.TextColor3 = Color3.fromRGB(120, 190, 255)
    h.TextSize = 11 h.Font = Enum.Font.GothamBold
    h.TextXAlignment = Enum.TextXAlignment.Left h.LayoutOrder = order h.Parent = parent
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1) line.Position = UDim2.new(0, 0, 1, 0)
    line.BackgroundColor3 = Color3.fromRGB(100, 170, 255)
    line.BackgroundTransparency = 0.6 line.BorderSizePixel = 0 line.Parent = h
    return h
end

local function makeDropdown(parent, text, options, default, cb, order)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 56) holder.BackgroundTransparency = 1
    holder.LayoutOrder = order holder.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 16) lbl.BackgroundTransparency = 1
    lbl.Text = text lbl.TextColor3 = Color3.fromRGB(200, 205, 220)
    lbl.TextSize = 12 lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left lbl.Parent = holder
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30) btn.Position = UDim2.fromOffset(0, 20)
    btn.BackgroundColor3 = Color3.fromRGB(35, 37, 48)
    btn.Text = "  " .. default .. "  v" btn.TextColor3 = Color3.fromRGB(240, 242, 250)
    btn.TextSize = 13 btn.Font = Enum.Font.GothamMedium
    btn.TextXAlignment = Enum.TextXAlignment.Left btn.BorderSizePixel = 0 btn.Parent = holder
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 8) bc.Parent = btn
    local open = false
    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, #options * 28) list.Position = UDim2.fromOffset(0, 52)
    list.BackgroundColor3 = Color3.fromRGB(20, 22, 30) list.BorderSizePixel = 0
    list.Visible = false list.ZIndex = 10 list.Parent = holder
    local lc = Instance.new("UICorner") lc.CornerRadius = UDim.new(0, 8) lc.Parent = list
    local state = default
    for i, opt in ipairs(options) do
        local o = Instance.new("TextButton")
        o.Size = UDim2.new(1, 0, 0, 28) o.Position = UDim2.fromOffset(0, (i - 1) * 28)
        o.BackgroundTransparency = 1 o.Text = "  " .. opt
        o.TextColor3 = Color3.fromRGB(220, 225, 235) o.TextSize = 13
        o.Font = Enum.Font.Gotham o.TextXAlignment = Enum.TextXAlignment.Left
        o.ZIndex = 11 o.Parent = list
        o.MouseButton1Click:Connect(function()
            state = opt
            btn.Text = "  " .. opt .. "  v"
            list.Visible = false open = false
            pcall(cb, state)
        end)
    end
    btn.MouseButton1Click:Connect(function() open = not open list.Visible = open end)
    return holder
end

-- Build menu
local gui = Instance.new("ScreenGui")
gui.Name = "Rivals_GlassMenu_" .. tostring(math.random(1000, 9999))
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999999
do
    local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not ok or not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end

local main = glass(gui, UDim2.fromOffset(420, 520), UDim2.new(0.5, -210, 0.5, -260), 16)
main.Active = true main.Draggable = true main.Name = "Main" main.Visible = false

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 44) titleBar.BackgroundTransparency = 1 titleBar.Parent = main
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 24) title.Position = UDim2.fromOffset(16, 8)
title.BackgroundTransparency = 1 title.Text = "RIVALS"
title.TextColor3 = Color3.fromRGB(255, 255, 255) title.TextSize = 17
title.Font = Enum.Font.GothamBold title.TextXAlignment = Enum.TextXAlignment.Left title.Parent = titleBar
local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1, -60, 0, 14) sub.Position = UDim2.fromOffset(16, 28)
sub.BackgroundTransparency = 1 sub.Text = "glass suite · keyless"
sub.TextColor3 = Color3.fromRGB(120, 185, 255) sub.TextSize = 10
sub.Font = Enum.Font.Gotham sub.TextXAlignment = Enum.TextXAlignment.Left sub.Parent = titleBar
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(26, 26) closeBtn.Position = UDim2.new(1, -38, 0, 9)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 70) closeBtn.Text = "x"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255) closeBtn.TextSize = 15
closeBtn.Font = Enum.Font.GothamBold closeBtn.BorderSizePixel = 0 closeBtn.Parent = titleBar
local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(1,0) cc.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -24, 1, -60) scroll.Position = UDim2.fromOffset(12, 50)
scroll.BackgroundTransparency = 1 scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3 scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 180, 255)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0) scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = main
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8) layout.SortOrder = Enum.SortOrder.LayoutOrder layout.Parent = scroll
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 4) pad.PaddingBottom = UDim.new(0, 8) pad.Parent = scroll

makeHeader(scroll, "AIMBOT", 1)
makeToggle(scroll, "Aimbot (hold RMB)", false, function(v) Config.Aim.Enabled = v end, 2)
makeToggle(scroll, "AimLock (continuous)", false, function(v) Config.Aim.AimLock = v end, 3)
makeDropdown(scroll, "Aim Part", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, "Head", function(v) Config.Aim.Part = v end, 4)
makeSlider(scroll, "FOV (px)", 30, 600, 150, function(v) Config.Aim.FOV = v end, 5)
makeSlider(scroll, "Smooth", 0.02, 1.00, 0.02, function(v) Config.Aim.Smooth = v end, 6, true)
makeToggle(scroll, "Wall Check", false, function(v) Config.Aim.WallCheck = v end, 7)
makeToggle(scroll, "Team Check", true, function(v) Config.Aim.TeamCheck = v end, 8)
makeToggle(scroll, "Require Gun", false, function(v) Config.Aim.RequireGun = v end, 9)
makeToggle(scroll, "FOV Ring", false, function(v) Config.Aim.FOVRing = v end, 10)

makeHeader(scroll, "ESP", 11)
makeToggle(scroll, "ESP Enabled", false, function(v) Config.ESP.Enabled = v end, 12)
makeToggle(scroll, "Box", false, function(v) Config.ESP.Box = v end, 13)
makeToggle(scroll, "Name", false, function(v) Config.ESP.Name = v end, 14)
makeToggle(scroll, "Health", false, function(v) Config.ESP.Health = v end, 15)
makeToggle(scroll, "Distance", false, function(v) Config.ESP.Distance = v end, 16)
makeToggle(scroll, "Tracer", false, function(v) Config.ESP.Tracer = v end, 17)
makeToggle(scroll, "Highlight", false, function(v) Config.ESP.Highlight = v end, 18)
makeToggle(scroll, "WallHack", false, function(v) Config.ESP.WallHack = v end, 19)
makeToggle(scroll, "Team Colors (green/red)", true, function(v) Config.ESP.TeamColors = v end, 20)
makeSlider(scroll, "ESP Min Dist", 250, 1000, 250, function(v) Config.ESP.MinDist = v end, 21)
makeSlider(scroll, "ESP Max Dist", 250, 1000, 250, function(v) Config.ESP.MaxDist = v end, 22)

makeHeader(scroll, "TRIGGERBOT", 23)
makeToggle(scroll, "Triggerbot", false, function(v) Config.Aim.Triggerbot = v end, 24)
makeSlider(scroll, "Trigger Delay (s)", 0.01, 0.50, 0.01, function(v) Config.Aim.TriggerDelay = v end, 25, true)

makeHeader(scroll, "MISC", 26)
makeToggle(scroll, "Fullbright", false, function(v)
    Config.Misc.Fullbright = v
    if v then
        Lighting.Brightness = 3 Lighting.ClockTime = 12 Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        pcall(function()
            Lighting.Ambient = Color3.fromRGB(180, 180, 180)
            Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
        end)
    else
        Lighting.Brightness = 2 Lighting.FogEnd = 100000 Lighting.GlobalShadows = true
    end
end, 27)
makeToggle(scroll, "NoRecoil", false, function(v) Config.Misc.NoRecoil = v end, 28)
makeToggle(scroll, "NoSpread", false, function(v) Config.Misc.NoSpread = v end, 29)

-- Insert toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        main.Visible = not main.Visible
    end
end)

-- ESP engine (players only — no NPCs in Rivals)
local espCache = {}
local fovRing = nil

local function newBox(color)
    local outer = Drawing.new("Square")
    outer.Filled = false outer.Color = color outer.Thickness = 1.5
    outer.Transparency = 0.9 outer.Visible = false
    local inner = Drawing.new("Square")
    inner.Filled = true inner.Color = color inner.Thickness = 0
    inner.Transparency = 0.08 inner.Visible = false
    return { outer = outer, inner = inner }
end

local function newTracer(color)
    local l = Drawing.new("Line")
    l.Color = color l.Thickness = 1.5 l.Transparency = 0.7 l.Visible = false
    return l
end

local function newText(color, size)
    local t = Drawing.new("Text")
    t.Color = color t.Size = size t.Center = true t.Outline = true
    t.OutlineColor = Color3.fromRGB(0, 0, 0) t.Visible = false
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
                -- skip
            else
                local part = getPlayerAimPart(p.Character)
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if part and hum and hum.Health > 0 then
                    local sp, on = Camera:WorldToViewportPoint(part.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < bestDist and isVisible(part) then
                            bestDist = d best = part
                        end
                    end
                end
            end
        end
    end
    return best
end

if HAS_DRAWING then
    RunService.RenderStepped:Connect(function()
        if Config.Aim.FOVRing then
            if not fovRing then
                fovRing = Drawing.new("Circle")
                fovRing.Filled = false fovRing.Thickness = 1.5 fovRing.Transparency = 0.75
            end
            fovRing.Visible = true
            fovRing.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            fovRing.Radius = Config.Aim.FOV fovRing.Color = Config.Aim.FOVRingColor
        elseif fovRing then fovRing.Visible = false end

        if Config.ESP.Enabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p == LocalPlayer then continue end
                local char = p.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local alive = hrp and hum and hum.Health > 0
                local dist = alive and (Camera.CFrame.Position - hrp.Position).Magnitude or 0
                local show = alive and dist >= Config.ESP.MinDist and dist <= Config.ESP.MaxDist
                local col = Config.ESP.TeamColors and teamColor(p) or Color3.fromRGB(120, 190, 255)

                local hl = char and char:FindFirstChild("RIV_HL")
                if Config.ESP.Highlight and show and char then
                    if not hl then
                        hl = Instance.new("Highlight") hl.Name = "RIV_HL"
                        hl.Adornee = char hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.OutlineTransparency = 0.4 hl.Parent = char
                    end
                    hl.FillColor = col
                    hl.FillTransparency = Config.ESP.WallHack and 0.2 or 0.75
                    hl.DepthMode = Config.ESP.WallHack and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                elseif hl then hl:Destroy() end

                if not show then
                    local c = espCache[p]
                    if c then
                        c.box.outer.Visible = false c.box.inner.Visible = false
                        c.name.Visible = false c.health.Visible = false
                        c.dist.Visible = false c.tracer.Visible = false
                    end
                    continue
                end

                local top = hrp.Position + Vector3.new(0, 3, 0)
                local bot = hrp.Position - Vector3.new(0, 3, 0)
                local ts, ton = Camera:WorldToViewportPoint(top)
                local bs, bon = Camera:WorldToViewportPoint(bot)
                if not (ton and bon) then continue end

                if not espCache[p] then
                    espCache[p] = {
                        box = newBox(col), name = newText(col, 13),
                        health = newText(Color3.fromRGB(120, 255, 120), 11),
                        dist = newText(col, 12), tracer = newTracer(col),
                    }
                end
                local c = espCache[p]
                c.box.outer.Color = col c.box.inner.Color = col
                c.name.Color = col c.dist.Color = col c.tracer.Color = col

                local h = math.abs(ts.Y - bs.Y)
                local w = h * 0.6
                local x = ts.X - w / 2
                local y = ts.Y

                if Config.ESP.Box then
                    c.box.inner.Size = Vector2.new(w, h) c.box.inner.Position = Vector2.new(x, y) c.box.inner.Visible = true
                    c.box.outer.Size = Vector2.new(w, h) c.box.outer.Position = Vector2.new(x, y) c.box.outer.Visible = true
                else
                    c.box.inner.Visible = false c.box.outer.Visible = false
                end

                if Config.ESP.Name then
                    c.name.Text = p.Name c.name.Position = Vector2.new(ts.X, y - 16) c.name.Visible = true
                else c.name.Visible = false end

                if Config.ESP.Health then
                    c.health.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                    c.health.Position = Vector2.new(ts.X, y - 30) c.health.Visible = true
                else c.health.Visible = false end

                if Config.ESP.Distance then
                    c.dist.Text = math.floor(dist) .. "m"
                    c.dist.Position = Vector2.new(ts.X, y + h + 6) c.dist.Visible = true
                else c.dist.Visible = false end

                if Config.ESP.Tracer then
                    c.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    c.tracer.To = Vector2.new(ts.X, ts.Y) c.tracer.Visible = true
                else c.tracer.Visible = false end
            end
        else
            for _, c in pairs(espCache) do
                c.box.outer.Visible = false c.box.inner.Visible = false
                c.name.Visible = false c.health.Visible = false
                c.dist.Visible = false c.tracer.Visible = false
                local hl = c.box.outer -- placeholder
            end
        end
    end)
end

-- Aimbot / AimLock / Triggerbot
local triggerLast = 0

UserInputService.InputBegan:Connect(function(i, proc)
    if proc then return end
    if i.UserInputType == Config.Aim.Key and Config.Aim.Enabled and not Config.Aim.AimLock then
        local t = closestAim()
        if t then
            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(Camera.CFrame.Position, t.Position),
                math.clamp(Config.Aim.Smooth, 0.02, 1.0))
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if Config.Aim.AimLock and Config.Aim.Enabled then
        local t = closestAim()
        if t then Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position) end
    end

    if Config.Aim.Triggerbot then
        local now = tick()
        if now - triggerLast >= Config.Aim.TriggerDelay then
            local t = closestAim()
            if t then
                local char = LocalPlayer.Character
                local tool = char and char:FindFirstChildOfClass("Tool")
                if tool then
                    local remote = tool:FindFirstChildOfClass("RemoteEvent") or tool:FindFirstChildOfClass("RemoteFunction")
                    if remote then
                        pcall(function()
                            if remote:IsA("RemoteEvent") then remote:FireServer() end
                        end)
                    end
                end
                triggerLast = now
            end
        end
    end

    if Config.Misc.NoRecoil then
        local look = Camera.CFrame.LookVector
        local pos = Camera.CFrame.Position
        Camera.CFrame = CFrame.new(pos, pos + look)
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
                        if v and v:IsA("NumberValue") then v.Value = 0 end
                    end
                end
            end
        end
    end
end)

print("[RIVALS] glass menu loaded. Insert toggles. keyless.")
