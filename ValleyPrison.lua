-- ============================================================================
-- NyxScript v2.2 — Valley Prison
-- Single-file, no fetch, no license. Right Shift to toggle.
-- v2.2: FOV ring (Drawing), cursor-based silent aim, shift-lock-safe aimbot,
-- real toggle off-states, Skeleton/Box/Tracer/Chams ESP, cheap item ESP,
-- teleport-to-rack spawning, cuff auto-escape. DEX-informed remote targets.
-- ============================================================================

-- ============================================================================
-- SECTION 1 — SERVICES & HELPERS
-- ============================================================================
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local TweenService        = game:GetService("TweenService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local HttpService         = game:GetService("HttpService")
local Lighting            = game:GetService("Lighting")
local TeamsService        = game:GetService("Teams")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ProximityPromptService = game:GetService("ProximityPromptService")
local lp                  = Players.LocalPlayer
local cam                 = workspace.CurrentCamera

local function safeGetRawMetatable(o)
    local ok, mt = pcall(function() return getrawmetatable(o) end)
    if ok then return mt end
    return nil
end
local function safeNewCclosure(fn)
    if type(newcclosure) == "function" then
        local ok, c = pcall(newcclosure, fn)
        if ok then return c end
    end
    return fn
end
local function safeGetNamecallMethod()
    if type(getnamecallmethod) == "function" then
        local ok, m = pcall(getnamecallmethod)
        if ok then return m end
    end
    return nil
end
local function safeGetHui()
    if type(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    return nil
end
local function safeFireClickDetector(cd)
    if type(fireclickdetector) == "function" then
        local ok = pcall(fireclickdetector, cd)
        if ok then return true end
    end
    return false
end
local function safeFireProximityPrompt(prompt, holdTime)
    if type(fireproximityprompt) == "function" then
        local ok = pcall(fireproximityprompt, prompt, holdTime or 0)
        if ok then return true end
    end
    return false
end

local function chr(p) return p and p.Character end
local function root(p) local c = chr(p); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum(p) local c = chr(p); return c and c:FindFirstChildOfClass("Humanoid") end
local function head(p) local c = chr(p); return c and c:FindFirstChild("Head") end
local function isAlive(p)
    local h = hum(p)
    return h and h.Health > 0 and h:GetState() ~= Enum.HumanoidStateType.Dead
end
local function dist(p)
    local a, b = root(lp), root(p)
    if not a or not b then return math.huge end
    return (a.Position - b.Position).Magnitude
end

-- ============================================================================
-- SECTION 2 — CONFIG
-- ============================================================================
local CFG = {
    -- AIMBOT
    Aimbot              = false,
    AimbotFOV           = 150,
    AimbotSmooth        = 0.12,
    AimbotPart          = "Head",
    AimbotTeamCheck     = false,
    AimbotRequireGun    = false,
    AimbotWallCheck     = true,
    AimbotFOVRing       = false,
    AimbotFOVRingColor  = Color3.fromRGB(0, 201, 185),
    Aimlock             = false,
    AimbotForceAiming   = false,
    SilentAim           = false,
    SilentAimFOV        = 150,
    SilentAimWallCheck  = true,
    Triggerbot          = false,
    TriggerbotDelay     = 0.05,

    -- WEAPON
    NoRecoil            = false,
    NoSpread            = false,
    RapidFire           = false,
    InfiniteAmmo        = false,
    AutoReload          = false,
    InstantEquip        = false,

    -- HITBOX
    HitboxExpand        = false,
    HitboxSize          = 6,

    -- ESP
    PlayerESP           = false,
    ESPFillColor        = Color3.fromRGB(99, 179, 237),
    ESPOutlineColor     = Color3.fromRGB(99, 179, 237),
    ESPFillTransparency = 0.75,
    ESPOutlineTransparency = 0,
    WallHack            = false,
    ChamsESP            = false,
    ChamsColor          = Color3.fromRGB(255, 165, 0),
    SkeletonESP         = false,
    SkeletonColor       = Color3.fromRGB(0, 201, 185),
    BoxESP              = false,
    BoxESPColor         = Color3.fromRGB(255, 255, 255),
    TracerESP           = false,
    TracerColor         = Color3.fromRGB(248, 113, 113),
    TracerOrigin        = "Bottom",
    TracerThickness     = 1.5,
    NameESP             = false,
    HealthESP           = false,
    DistanceESP         = false,
    TeamColors          = true,
    ESPMaxDist          = 500,

    -- ITEM ESP
    ItemESP             = false,
    WeaponESP           = false,
    KeycardESP          = false,
    ItemESPMaxDist      = 150,
    ItemESPInterval     = 1.0,

    -- MOVEMENT
    SpeedEnabled        = false,
    Speed               = 24,
    Fly                 = false,
    FlySpeed            = 30,
    FlyMode             = "Head",
    Noclip              = false,
    InfJump             = false,
    JumpPower           = 60,
    InfStamina          = false,
    AntiGravity         = false,
    GravityValue        = 50,
    BunnyHop            = false,
    SlowFall            = false,
    SlowFallSpeed       = 5,
    SuperJump           = false,
    SuperJumpPower      = 200,
    TpToCursor          = false,
    TpToCursorKey       = Enum.KeyCode.T,

    -- PLAYER BUFFS
    GodMode             = false,
    AntiStun            = false,
    InfHealth           = false,

    -- VISUALS
    Fullbright          = false,
    NoFog               = false,
    TimeOfDay           = false,
    TimeValue           = 14,
    ThirdPerson         = false,
    ThirdPersonDist     = 10,
    ZoomHack            = false,
    ZoomFOV             = 70,
    RainbowCharacter    = false,
    InvisibleCharacter  = false,
    CharColor           = Color3.fromRGB(255, 255, 255),
    CustomCharColor     = false,

    -- PRISON
    AutoEscapeCuffs     = false,
    BlockArrest         = false,
    BlockBan            = false,
    LogRemotes          = false,
    LogACTraffic        = false,

    -- ANTI-CHEAT (spec floor: on from first frame)
    AntiKick            = true,
    AntiDisconnect      = false,

    -- GUI
    Open                = true,
    Page                = "Home",
    MenuKey             = Enum.KeyCode.RightShift,
    ShowNotifications   = true,
}

-- ============================================================================
-- SECTION 3 — PALETTE, TWEEN, NOTIFY
-- ============================================================================
local C = {
    bg       = Color3.fromRGB(8, 9, 16),
    surface  = Color3.fromRGB(13, 14, 24),
    card     = Color3.fromRGB(18, 19, 30),
    cardHov  = Color3.fromRGB(22, 24, 38),
    accent   = Color3.fromRGB(0, 201, 185),
    accentDk = Color3.fromRGB(0, 140, 128),
    accent2  = Color3.fromRGB(123, 97, 255),
    danger   = Color3.fromRGB(248, 113, 113),
    warn     = Color3.fromRGB(251, 191, 36),
    ok       = Color3.fromRGB(52, 211, 153),
    text     = Color3.fromRGB(225, 230, 245),
    textMid  = Color3.fromRGB(150, 155, 175),
    textDim  = Color3.fromRGB(75, 80, 105),
    border   = Color3.fromRGB(255, 255, 255),
    borderAc = Color3.fromRGB(0, 201, 185),
}

local FONT      = Enum.Font.Gotham
local FONT_MED  = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local function tw(inst, t, props)
    if not inst or not inst.Parent then return end
    TweenService:Create(inst, TweenInfo.new(t or 0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

local notifyGui = Instance.new("ScreenGui")
notifyGui.Name = "VP_Notify"
notifyGui.ResetOnSpawn = false
notifyGui.IgnoreGuiInset = true
notifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
do
    local hui = safeGetHui()
    if hui then notifyGui.Parent = hui else notifyGui.Parent = lp:WaitForChild("PlayerGui") end
end

local notifyHolder = Instance.new("Frame")
notifyHolder.Name = "Holder"
notifyHolder.BackgroundTransparency = 1
notifyHolder.AnchorPoint = Vector2.new(1, 1)
notifyHolder.Position = UDim2.new(1, -12, 1, -12)
notifyHolder.Size = UDim2.new(0, 280, 1, -24)
notifyHolder.Parent = notifyGui

local notifyList = Instance.new("UIListLayout")
notifyList.FillDirection = Enum.FillDirection.Vertical
notifyList.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifyList.HorizontalAlignment = Enum.HorizontalAlignment.Right
notifyList.SortOrder = Enum.SortOrder.LayoutOrder
notifyList.Padding = UDim.new(0, 6)
notifyList.Parent = notifyHolder

local notifySerial = 0
local function notify(msg, kind, dur)
    if not CFG.ShowNotifications then return end
    notifySerial = notifySerial + 1
    local kcolor = ({ ok = C.ok, warn = C.warn, err = C.danger, info = C.accent })[kind] or C.accent
    local card = Instance.new("Frame")
    card.Name = "Toast_" .. notifySerial
    card.BackgroundColor3 = C.bg
    card.BorderSizePixel = 0
    card.Size = UDim2.fromOffset(260, 44)
    card.Position = UDim2.new(1, 300, 0, 0)
    card.LayoutOrder = notifySerial
    card.Parent = notifyHolder
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
    local strip = Instance.new("Frame")
    strip.BackgroundColor3 = kcolor
    strip.BorderSizePixel = 0
    strip.Size = UDim2.new(0, 3, 1, 0)
    strip.Parent = card
    Instance.new("UICorner", strip).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke")
    stroke.Color = C.border; stroke.Transparency = 0.92; stroke.Thickness = 1
    stroke.Parent = card
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(12, 0)
    label.Size = UDim2.new(1, -20, 1, -6)
    label.Font = FONT
    label.TextSize = 12
    label.TextColor3 = C.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = true
    label.Text = tostring(msg)
    label.Parent = card
    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = kcolor
    bar.BorderSizePixel = 0
    bar.Position = UDim2.new(0, 0, 1, -2)
    bar.Size = UDim2.new(1, 0, 0, 2)
    bar.Parent = card
    TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
    TweenService:Create(bar, TweenInfo.new(dur or 3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Size = UDim2.new(0, 0, 0, 2)}):Play()
    task.delay(dur or 3, function()
        if not card.Parent then return end
        local t = TweenService:Create(card, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(1, 300, 0, 0)})
        t:Play()
        t.Completed:Connect(function() card:Destroy() end)
    end)
end

-- ============================================================================
-- SECTION 4 — GUI SHELL
-- ============================================================================
local W, H = 720, 480
local TITLE_H = 40
local SIDEBAR_W = 150

local mainGui = Instance.new("ScreenGui")
mainGui.Name = "VP_Main"
mainGui.ResetOnSpawn = false
mainGui.IgnoreGuiInset = true
mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
do
    local hui = safeGetHui()
    if hui then mainGui.Parent = hui else mainGui.Parent = lp:WaitForChild("PlayerGui") end
end

local win = Instance.new("Frame")
win.Name = "win"
win.BackgroundColor3 = C.bg
win.BorderSizePixel = 0
win.AnchorPoint = Vector2.new(0.5, 0.5)
win.Position = UDim2.new(0.5, 0, 0.5, 0)
win.Size = UDim2.fromOffset(W, H)
win.ClipsDescendants = true
win.Parent = mainGui
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)
do
    local s = Instance.new("UIStroke")
    s.Color = C.border; s.Transparency = 0.85; s.Thickness = 1
    s.Parent = win
end

local titleBar = Instance.new("Frame")
titleBar.Name = "titleBar"
titleBar.BackgroundColor3 = C.surface
titleBar.BorderSizePixel = 0
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.Parent = win
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)
do
    local fix = Instance.new("Frame")
    fix.BackgroundColor3 = C.surface
    fix.BorderSizePixel = 0
    fix.Position = UDim2.new(0, 0, 1, -8)
    fix.Size = UDim2.new(1, 0, 0, 8)
    fix.Parent = titleBar
end

local accentStrip = Instance.new("Frame")
accentStrip.BackgroundColor3 = C.accent
accentStrip.BorderSizePixel = 0
accentStrip.Position = UDim2.fromOffset(12, 9)
accentStrip.Size = UDim2.fromOffset(3, 22)
accentStrip.Parent = titleBar
Instance.new("UICorner", accentStrip).CornerRadius = UDim.new(1, 0)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(24, 4)
title.Size = UDim2.new(0, 200, 0, 20)
title.Font = FONT_BOLD
title.TextSize = 14
title.TextColor3 = C.text
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "VALLEY PRISON"
title.Parent = titleBar

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(24, 22)
subtitle.Size = UDim2.new(0, 200, 0, 12)
subtitle.Font = FONT
subtitle.TextSize = 10
subtitle.TextColor3 = C.textDim
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Text = "NyxScript  v2.2"
subtitle.Parent = titleBar

local function mkCircleBtn(color, glyph, x)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.AnchorPoint = Vector2.new(1, 0.5)
    b.Position = UDim2.new(1, x, 0, TITLE_H / 2)
    b.Size = UDim2.fromOffset(20, 20)
    b.Text = glyph
    b.Font = FONT_BOLD
    b.TextSize = 12
    b.TextColor3 = Color3.fromRGB(0, 0, 0)
    b.AutoButtonColor = false
    b.Parent = titleBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
    return b
end
local btnMin = mkCircleBtn(C.ok, "–", -12)
local btnClose = mkCircleBtn(C.danger, "×", -38)

local sidebar = Instance.new("Frame")
sidebar.Name = "sidebar"
sidebar.BackgroundColor3 = C.surface
sidebar.BorderSizePixel = 0
sidebar.Position = UDim2.fromOffset(0, TITLE_H)
sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -TITLE_H)
sidebar.Parent = win

local sep = Instance.new("Frame")
sep.BackgroundColor3 = C.border
sep.BackgroundTransparency = 0.92
sep.BorderSizePixel = 0
sep.Position = UDim2.fromOffset(SIDEBAR_W, TITLE_H)
sep.Size = UDim2.new(0, 1, 1, -TITLE_H)
sep.Parent = win

local content = Instance.new("ScrollingFrame")
content.Name = "content"
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.Position = UDim2.fromOffset(SIDEBAR_W + 1, TITLE_H)
content.Size = UDim2.new(1, -(SIDEBAR_W + 1), 1, -TITLE_H)
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = C.accent
content.Parent = win

local contentPad = Instance.new("UIPadding")
contentPad.PaddingLeft = UDim.new(0, 12)
contentPad.PaddingRight = UDim.new(0, 12)
contentPad.PaddingTop = UDim.new(0, 12)
contentPad.PaddingBottom = UDim.new(0, 12)
contentPad.Parent = content

local contentList = Instance.new("UIListLayout")
contentList.FillDirection = Enum.FillDirection.Vertical
contentList.SortOrder = Enum.SortOrder.LayoutOrder
contentList.Padding = UDim.new(0, 6)
contentList.Parent = content

local navList = Instance.new("UIListLayout")
navList.FillDirection = Enum.FillDirection.Vertical
navList.SortOrder = Enum.SortOrder.LayoutOrder
navList.Padding = UDim.new(0, 2)
navList.Parent = sidebar
local navPad = Instance.new("UIPadding")
navPad.PaddingTop = UDim.new(0, 8)
navPad.PaddingLeft = UDim.new(0, 6)
navPad.PaddingRight = UDim.new(0, 6)
navPad.Parent = sidebar

-- Drag
do
    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - dragStart
        win.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local _tabHeld = false
local function holdTab()
    if _tabHeld then return end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Tab, false, game)
    end)
    _tabHeld = true
end
local function releaseTab()
    if not _tabHeld then return end
    pcall(function()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Tab, false, game)
    end)
    _tabHeld = false
end

local minimized = false
btnMin.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        tw(win, 0.15, {Size = UDim2.fromOffset(W, TITLE_H)})
    else
        tw(win, 0.15, {Size = UDim2.fromOffset(W, H)})
    end
end)

btnClose.MouseButton1Click:Connect(function()
    CFG.Open = false
    releaseTab()
    tw(win, 0.15, {Size = UDim2.fromOffset(W, 0)})
    task.delay(0.16, function()
        win.Visible = false
        win.Size = UDim2.fromOffset(W, H)
        minimized = false
    end)
end)

-- ============================================================================
-- SECTION 3C — COMPONENT BUILDERS
-- ============================================================================
local function secLabel(parent, text)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.Size = UDim2.new(1, 0, 0, 22)
    f.Parent = parent
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Size = UDim2.new(1, 0, 1, 0)
    t.Font = FONT_BOLD
    t.TextSize = 10
    t.TextColor3 = C.accent
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = string.upper(text)
    t.Parent = f
    return f
end

local function mkCard(parent)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = C.card
    f.BorderSizePixel = 0
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.Size = UDim2.new(1, 0, 0, 0)
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 7)
    local s = Instance.new("UIStroke")
    s.Color = C.border; s.Transparency = 0.92; s.Thickness = 1
    s.Parent = f
    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, 0)
    l.Parent = f
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 10)
    p.PaddingRight = UDim.new(0, 10)
    p.PaddingTop = UDim.new(0, 6)
    p.PaddingBottom = UDim.new(0, 6)
    p.Parent = f
    return f
end

local function mkToggle(parent, label, cfgKey, onToggle)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 34)
    row.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Font = FONT
    lbl.TextSize = 13
    lbl.TextColor3 = C.textMid
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = row
    local pill = Instance.new("TextButton")
    pill.AnchorPoint = Vector2.new(1, 0.5)
    pill.Position = UDim2.new(1, 0, 0.5, 0)
    pill.Size = UDim2.fromOffset(42, 22)
    pill.BackgroundColor3 = CFG[cfgKey] and C.accent or C.card
    pill.BorderSizePixel = 0
    pill.Text = ""
    pill.AutoButtonColor = false
    pill.Parent = row
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = CFG[cfgKey] and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    knob.Size = UDim2.fromOffset(16, 16)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local function applyVisual(state)
        pill.BackgroundColor3 = state and C.accent or C.card
        tw(knob, 0.12, {Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)})
    end
    pill.MouseButton1Click:Connect(function()
        CFG[cfgKey] = not CFG[cfgKey]
        applyVisual(CFG[cfgKey])
        if onToggle then onToggle(CFG[cfgKey]) end
    end)
    return function(state)
        CFG[cfgKey] = state
        applyVisual(state)
        if onToggle then onToggle(state) end
    end
end

local function mkSlider(parent, label, cfgKey, min, max, step, onChanged)
    local outer = Instance.new("Frame")
    outer.BackgroundTransparency = 1
    outer.Size = UDim2.new(1, 0, 0, 46)
    outer.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.7, 0, 0, 20)
    lbl.Font = FONT
    lbl.TextSize = 13
    lbl.TextColor3 = C.textMid
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = outer
    local val = Instance.new("TextLabel")
    val.BackgroundTransparency = 1
    val.AnchorPoint = Vector2.new(1, 0)
    val.Position = UDim2.new(1, 0, 0, 0)
    val.Size = UDim2.new(0.3, 0, 0, 20)
    val.Font = FONT_BOLD
    val.TextSize = 13
    val.TextColor3 = C.accent
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Text = tostring(CFG[cfgKey])
    val.Parent = outer
    local track = Instance.new("Frame")
    track.BackgroundColor3 = C.card
    track.BorderSizePixel = 0
    track.Position = UDim2.fromOffset(0, 30)
    track.Size = UDim2.new(1, 0, 0, 5)
    track.Parent = outer
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new((CFG[cfgKey] - min) / (max - min), 0, 1, 0)
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((CFG[cfgKey] - min) / (max - min), 0, 0.5, 0)
    knob.Size = UDim2.fromOffset(14, 14)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local raw = min + (max - min) * rel
        local snapped = math.round(raw / step) * step
        snapped = math.clamp(snapped, min, max)
        CFG[cfgKey] = snapped
        local pct = (snapped - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        val.Text = tostring(snapped)
        if onChanged then onChanged(snapped) end
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    return function(v)
        local snapped = math.clamp(math.round(v / step) * step, min, max)
        CFG[cfgKey] = snapped
        local pct = (snapped - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        val.Text = tostring(snapped)
        if onChanged then onChanged(snapped) end
    end
end

local function mkBtn(parent, label, fn)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = C.card
    b.BorderSizePixel = 0
    b.Size = UDim2.new(1, 0, 0, 30)
    b.Font = FONT
    b.TextSize = 12
    b.TextColor3 = C.textMid
    b.Text = label
    b.AutoButtonColor = false
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke")
    s.Color = C.border; s.Transparency = 0.92; s.Thickness = 1
    s.Parent = b
    b.MouseEnter:Connect(function() tw(b, 0.08, {BackgroundColor3 = C.cardHov}) end)
    b.MouseLeave:Connect(function() tw(b, 0.08, {BackgroundColor3 = C.card}) end)
    b.MouseButton1Down:Connect(function() tw(b, 0.05, {BackgroundColor3 = C.accentDk}) end)
    b.MouseButton1Up:Connect(function() tw(b, 0.05, {BackgroundColor3 = C.card}) end)
    b.MouseButton1Click:Connect(function() if fn then fn() end end)
    return b
end

local function mkDrop(parent, label, options, cfgKey, onChanged)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 34)
    row.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Font = FONT
    lbl.TextSize = 13
    lbl.TextColor3 = C.textMid
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = row
    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, 0, 0.5, 0)
    btn.Size = UDim2.new(0.48, 0, 0, 26)
    btn.BackgroundColor3 = C.bg
    btn.BorderSizePixel = 0
    btn.Font = FONT_MED
    btn.TextSize = 12    btn.TextColor3 = C.accent
    btn.Text = "▾  " .. tostring(CFG[cfgKey])
    btn.AutoButtonColor = false
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    local s = Instance.new("UIStroke")
    s.Color = C.border; s.Transparency = 0.9; s.Thickness = 1
    s.Parent = btn
    local list
    local function close()
        if list then list:Destroy(); list = nil end
    end
    btn.MouseButton1Click:Connect(function()
        if list then close(); return end
        list = Instance.new("Frame")
        list.BackgroundColor3 = C.bg
        list.BorderSizePixel = 0
        list.Position = UDim2.new(0, 0, 1, 2)
        list.Size = UDim2.new(1, 0, 0, #options * 24 + 6)
        list.ZIndex = 10
        list.Parent = row
        Instance.new("UICorner", list).CornerRadius = UDim.new(0, 5)
        local ls = Instance.new("UIStroke")
        ls.Color = C.border; ls.Transparency = 0.88; ls.Thickness = 1
        ls.Parent = list
        local l = Instance.new("UIListLayout")
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Parent = list
        for i, opt in ipairs(options) do
            local o = Instance.new("TextButton")
            o.BackgroundTransparency = 1
            o.Size = UDim2.new(1, 0, 0, 24)
            o.Font = FONT
            o.TextSize = 12
            o.TextColor3 = C.text
            o.TextXAlignment = Enum.TextXAlignment.Left
            o.Text = "  " .. tostring(opt)
            o.LayoutOrder = i
            o.ZIndex = 11
            o.Parent = list
            o.MouseEnter:Connect(function() tw(o, 0.06, {BackgroundTransparency = 0.85, BackgroundColor3 = C.cardHov}) end)
            o.MouseLeave:Connect(function() tw(o, 0.06, {BackgroundTransparency = 1}) end)
            o.MouseButton1Click:Connect(function()
                CFG[cfgKey] = opt
                btn.Text = "▾  " .. tostring(opt)
                close()
                if onChanged then onChanged(opt) end
            end)
        end
    end)
    return function(v)
        CFG[cfgKey] = v
        btn.Text = "▾  " .. tostring(v)
        if onChanged then onChanged(v) end
    end
end

local function mkColorPicker(parent, label, cfgKey, onChanged)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 34)
    row.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.Font = FONT
    lbl.TextSize = 13
    lbl.TextColor3 = C.textMid
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = row
    local swatch = Instance.new("TextButton")
    swatch.AnchorPoint = Vector2.new(1, 0.5)
    swatch.Position = UDim2.new(1, 0, 0.5, 0)
    swatch.Size = UDim2.fromOffset(28, 20)
    swatch.BackgroundColor3 = CFG[cfgKey]
    swatch.BorderSizePixel = 0
    swatch.Text = ""
    swatch.AutoButtonColor = false
    swatch.Parent = row
    Instance.new("UICorner", swatch).CornerRadius = UDim.new(0, 4)
    local ss = Instance.new("UIStroke")
    ss.Color = C.border; ss.Transparency = 0.85; ss.Thickness = 1
    ss.Parent = swatch
    local panel
    swatch.MouseButton1Click:Connect(function()
        if panel then panel:Destroy(); panel = nil; return end
        panel = Instance.new("Frame")
        panel.BackgroundColor3 = C.bg
        panel.BorderSizePixel = 0
        panel.Position = UDim2.new(0, 0, 1, 2)
        panel.Size = UDim2.new(1, 0, 0, 108)
        panel.ZIndex = 10
        panel.Parent = row
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 5)
        local ps = Instance.new("UIStroke")
        ps.Color = C.border; ps.Transparency = 0.88; ps.Thickness = 1
        ps.Parent = panel
        local channels = {"R", "G", "B"}
        local vals = {
            math.floor(CFG[cfgKey].R * 255),
            math.floor(CFG[cfgKey].G * 255),
            math.floor(CFG[cfgKey].B * 255),
        }
        for i = 1, 3 do
            local ch = channels[i]
            local chLbl = Instance.new("TextLabel")
            chLbl.BackgroundTransparency = 1
            chLbl.Position = UDim2.new(0, 8, 0, (i - 1) * 34 + 4)
            chLbl.Size = UDim2.new(0, 14, 0, 26)
            chLbl.Font = FONT_BOLD
            chLbl.TextSize = 12
            chLbl.TextColor3 = C.text
            chLbl.Text = ch
            chLbl.ZIndex = 11
            chLbl.Parent = panel
            local chVal = Instance.new("TextLabel")
            chVal.BackgroundTransparency = 1
            chVal.AnchorPoint = Vector2.new(1, 0)
            chVal.Position = UDim2.new(1, -8, 0, (i - 1) * 34 + 4)
            chVal.Size = UDim2.new(0, 30, 0, 26)
            chVal.Font = FONT_BOLD
            chVal.TextSize = 12
            chVal.TextColor3 = C.accent
            chVal.TextXAlignment = Enum.TextXAlignment.Right
            chVal.Text = tostring(vals[i])
            chVal.ZIndex = 11
            chVal.Parent = panel
            local track = Instance.new("Frame")
            track.BackgroundColor3 = C.card
            track.BorderSizePixel = 0
            track.Position = UDim2.new(0, 26, 0, (i - 1) * 34 + 15)
            track.Size = UDim2.new(1, -66, 0, 5)
            track.ZIndex = 11
            track.Parent = panel
            Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
            local fill = Instance.new("Frame")
            fill.BackgroundColor3 = C.accent
            fill.BorderSizePixel = 0
            fill.Size = UDim2.new(vals[i] / 255, 0, 1, 0)
            fill.ZIndex = 11
            fill.Parent = track
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
            local knob = Instance.new("Frame")
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.Position = UDim2.new(vals[i] / 255, 0, 0.5, 0)
            knob.Size = UDim2.fromOffset(12, 12)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.ZIndex = 12
            knob.Parent = track
            Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
            local function set(x)
                local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local v = math.floor(rel * 255 + 0.5)
                vals[i] = v
                fill.Size = UDim2.new(rel, 0, 1, 0)
                knob.Position = UDim2.new(rel, 0, 0.5, 0)
                chVal.Text = tostring(v)
                CFG[cfgKey] = Color3.fromRGB(vals[1], vals[2], vals[3])
                swatch.BackgroundColor3 = CFG[cfgKey]
                if onChanged then onChanged(CFG[cfgKey]) end
            end
            local drag = false
            track.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; set(inp.Position.X) end
            end)
            knob.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = true end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then set(inp.Position.X) end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
            end)
        end
    end)
    return function(color)
        CFG[cfgKey] = color
        swatch.BackgroundColor3 = color
        if onChanged then onChanged(color) end
    end
end

local function mkKeybind(parent, label, cfgKey)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 34)
    row.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Font = FONT
    lbl.TextSize = 13
    lbl.TextColor3 = C.textMid
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = row
    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, 0, 0.5, 0)
    btn.Size = UDim2.new(0.36, 0, 0, 26)
    btn.BackgroundColor3 = C.bg
    btn.BorderSizePixel = 0
    btn.Font = FONT_MED
    btn.TextSize = 12
    btn.TextColor3 = C.accent
    btn.Text = tostring(CFG[cfgKey]):gsub("Enum.KeyCode.", "")
    btn.AutoButtonColor = false
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    local s = Instance.new("UIStroke")
    s.Color = C.border; s.Transparency = 0.9; s.Thickness = 1
    s.Parent = btn
    local listening = false
    btn.MouseButton1Click:Connect(function()
        listening = true
        btn.Text = "[ ... ]"
        btn.TextColor3 = C.warn
    end)
    UserInputService.InputBegan:Connect(function(input)
        if not listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            CFG[cfgKey] = input.KeyCode
            btn.Text = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
            btn.TextColor3 = C.accent
            listening = false
        elseif input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.MouseButton2
            or input.UserInputType == Enum.UserInputType.MouseButton3 then
            CFG[cfgKey] = input.UserInputType
            btn.Text = tostring(input.UserInputType):gsub("Enum.UserInputType.", "")
            btn.TextColor3 = C.accent
            listening = false
        end
    end)
end

local function mkInfoRow(parent, label, valueGetter)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 28)
    row.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Font = FONT
    lbl.TextSize = 13
    lbl.TextColor3 = C.textMid
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = row
    local val = Instance.new("TextLabel")
    val.BackgroundTransparency = 1
    val.AnchorPoint = Vector2.new(1, 0)
    val.Position = UDim2.new(1, 0, 0, 0)
    val.Size = UDim2.new(0.5, 0, 1, 0)
    val.Font = FONT_MED
    val.TextSize = 13
    val.TextColor3 = C.accent
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Text = "..."
    val.Parent = row
    task.spawn(function()
        while row.Parent do
            local ok, v = pcall(valueGetter)
            val.Text = ok and tostring(v) or "?"
            task.wait(0.5)
        end
    end)
    return row
end

local function mkScrollList(parent, items, onItemClick, height)
    local sf = Instance.new("ScrollingFrame")
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.Size = UDim2.new(1, 0, 0, height or 120)
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = C.accent
    sf.Parent = parent
    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, 2)
    l.Parent = sf
    for i, item in ipairs(items) do
        local row = Instance.new("Frame")
        row.BackgroundColor3 = C.card
        row.BorderSizePixel = 0
        row.Size = UDim2.new(1, -4, 0, 26)
        row.LayoutOrder = i
        row.Parent = sf
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
        local name = Instance.new("TextLabel")
        name.BackgroundTransparency = 1
        name.Position = UDim2.fromOffset(8, 0)
        name.Size = UDim2.new(1, -70, 1, 0)
        name.Font = FONT
        name.TextSize = 12
        name.TextColor3 = C.text
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Text = tostring(item)
        name.Parent = row
        local btn = Instance.new("TextButton")
        btn.AnchorPoint = Vector2.new(1, 0.5)
        btn.Position = UDim2.new(1, -4, 0.5, 0)
        btn.Size = UDim2.fromOffset(56, 20)
        btn.BackgroundColor3 = C.accent
        btn.BorderSizePixel = 0
        btn.Font = FONT_BOLD
        btn.TextSize = 11
        btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        btn.Text = "Go"
        btn.AutoButtonColor = false
        btn.Parent = row
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        row.MouseEnter:Connect(function() tw(row, 0.06, {BackgroundColor3 = C.cardHov}) end)
        row.MouseLeave:Connect(function() tw(row, 0.06, {BackgroundColor3 = C.card}) end)
        btn.MouseButton1Click:Connect(function() if onItemClick then onItemClick(item) end end)
    end
    return sf
end

-- ============================================================================
-- SECTION 4B — TEAM SIGNATURE SYSTEM
-- ============================================================================
local _teamCache = {}
local _teamCacheTime = {}
local TEAM_CACHE_DURATION = 0.15

local function normalizeTeamValue(value)
    if value == nil then return nil end
    local t = typeof(value)
    if t == "Instance" then return value end
    if t == "Color3" then return string.format("color:%.4f:%.4f:%.4f", value.R, value.G, value.B) end
    if t == "BrickColor" then return "brick:" .. value.Name end
    if t == "string" then return value == "" and nil or "string:" .. value end
    if t == "number" then return "number:" .. tostring(value) end
    if t == "boolean" then return "boolean:" .. tostring(value) end
    return nil
end

local function isTeamName(name)
    if typeof(name) ~= "string" then return false end
    local lowered = string.gsub(string.lower(name), "[%s_%-]", "")
    return lowered == "team" or lowered == "teamid" or lowered == "teamidentifier"
        or lowered == "teamindex" or lowered == "teamcolor" or lowered == "teamcolour"
        or string.find(lowered, "teamid", 1, true) ~= nil
end

local function getTeamFromAttributes(container)
    if not container then return nil end
    local ok, attrs = pcall(function() return container:GetAttributes() end)
    if not ok or not attrs then return nil end
    for name, value in pairs(attrs) do
        if isTeamName(name) then
            local n = normalizeTeamValue(value)
            if n ~= nil then return n end
        end
    end
    return nil
end

local function getTeamFromValues(container)
    if not container then return nil end
    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return nil end
    for _, object in ipairs(children) do
        if isTeamName(object.Name) then
            local n = normalizeTeamValue(object.Value)
            if n then return n end
        end
    end
    return nil
end

local function getTeamSignature(player)
    if not player then return nil end
    local now = os.clock()
    if _teamCache[player] ~= nil and _teamCacheTime[player]
    and now - _teamCacheTime[player] < TEAM_CACHE_DURATION then
        return _teamCache[player]
    end
    local signature = player.Team
        or getTeamFromAttributes(player)
        or getTeamFromValues(player)
        or (player.Character and getTeamFromAttributes(player.Character))
        or (player.Character and getTeamFromValues(player.Character))
    if not signature then
        local ok, tc = pcall(function() return player.TeamColor end)
        if ok and tc then
            local colorName = tc.Name
            if colorName and colorName ~= "Medium stone grey" then
                signature = "brick:" .. colorName
            end
        end
    end
    _teamCache[player] = signature
    _teamCacheTime[player] = now
    return signature
end

local function clearTeamCache(player)
    if player then
        _teamCache[player] = nil
        _teamCacheTime[player] = nil
    else
        _teamCache = {}
        _teamCacheTime = {}
    end
end

local function isTeammate(player)
    if not player or player == lp then return true end
    local ok1, lTeam = pcall(function() return lp.Team end)
    local ok2, pTeam = pcall(function() return player.Team end)
    if ok1 and ok2 and lTeam and pTeam then return lTeam == pTeam end
    local ls = getTeamSignature(lp)
    local ts = getTeamSignature(player)
    if ls ~= nil and ts ~= nil then
        if typeof(ls) == "Instance" and typeof(ts) == "Instance" then return ls == ts end
        return tostring(ls) == tostring(ts)
    end
    return false
end

local function teamColor(p)
    local t = tostring(p.Team and p.Team.Name or ""):lower()
    if t:find("guard") or t:find("police") or t:find("warden") or t:find("staff")
    or t:find("officer") or t:find("swat") or t:find("sheriff")
    or t:find("department") or t:find("director") then
        return Color3.fromRGB(248, 113, 113)
    elseif t:find("prisoner") or t:find("inmate") or t:find("criminal")
    or t:find("escapee") or t:find("security") or t:find("civilian")
    or t:find("patient") then
        return Color3.fromRGB(99, 179, 237)
    end
    return Color3.fromRGB(220, 220, 220)
end

Players.PlayerAdded:Connect(function(player)
    clearTeamCache(player)
    player:GetPropertyChangedSignal("Team"):Connect(function() clearTeamCache(player) end)
    player:GetPropertyChangedSignal("TeamColor"):Connect(function() clearTeamCache(player) end)
    player.CharacterAdded:Connect(function() clearTeamCache(player) end)
end)
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= lp then
        player:GetPropertyChangedSignal("Team"):Connect(function() clearTeamCache(player) end)
        player:GetPropertyChangedSignal("TeamColor"):Connect(function() clearTeamCache(player) end)
        player.CharacterAdded:Connect(function() clearTeamCache(player) end)
    end
end
Players.PlayerRemoving:Connect(function(player) clearTeamCache(player) end)

-- ============================================================================
-- SECTION 4C — SHARED RAYCAST PARAMS
-- ============================================================================
local _sharedRayParams = RaycastParams.new()
_sharedRayParams.FilterType = Enum.RaycastFilterType.Exclude
local _raycastBlacklistDirty = true
local _raycastBlacklistTime = 0

local function markRaycastDirty() _raycastBlacklistDirty = true end
Players.PlayerAdded:Connect(markRaycastDirty)
Players.PlayerRemoving:Connect(markRaycastDirty)

local function getSharedRayParams(excludeChar)
    local now = os.clock()
    if _raycastBlacklistDirty or (now - _raycastBlacklistTime) > 0.5 then
        local blacklist = {}
        if lp.Character then table.insert(blacklist, lp.Character) end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= lp and player.Character and player.Character ~= excludeChar then
                table.insert(blacklist, player.Character)
            end
        end
        _sharedRayParams.FilterDescendantsInstances = blacklist
        _raycastBlacklistDirty = false
        _raycastBlacklistTime = now
    end
    return _sharedRayParams
end

local function hasLineOfSight(targetPart)
    if not targetPart or not cam then return false end
    local parent = targetPart.Parent
    if not parent then return false end
    local camPos = cam.CFrame.Position
    local ok_pos, targetPos = pcall(function() return targetPart.Position end)
    if not ok_pos then return false end
    local offset = targetPos - camPos
    local distance = offset.Magnitude
    if distance <= 0 then return false end
    local params = getSharedRayParams(parent)
    local ok, rayResult = pcall(function()
        return workspace:Raycast(camPos, offset.Unit * distance, params)
    end)
    if not ok then return true end
    if not rayResult or not rayResult.Instance then return true end
    return rayResult.Instance:IsDescendantOf(parent)
end

-- ============================================================================
-- SECTION 4D — 8-CORNER HITBOX SCREEN BOUNDS
-- ============================================================================
local function getHitboxScreenBounds(part)
    if not cam or not part or not part.Parent then return nil end
    local ok, cf, halfSize = pcall(function() return part.CFrame, part.Size * 0.5 end)
    if not ok or not cf or not halfSize then return nil end
    local sx, sy, sz = halfSize.X, halfSize.Y, halfSize.Z
    local corners = {
        cf * Vector3.new( sx,  sy,  sz),
        cf * Vector3.new(-sx,  sy,  sz),
        cf * Vector3.new( sx, -sy,  sz),
        cf * Vector3.new(-sx, -sy,  sz),
        cf * Vector3.new( sx,  sy, -sz),
        cf * Vector3.new(-sx,  sy, -sz),
        cf * Vector3.new( sx, -sy, -sz),
        cf * Vector3.new(-sx, -sy, -sz),
    }
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local anyOnScreen = false
    for _, corner in ipairs(corners) do
        local ok2, result = pcall(function() return cam:WorldToScreenPoint(corner) end)
        if ok2 and result and result.Z > 0 then
            anyOnScreen = true
            if result.X < minX then minX = result.X end
            if result.Y < minY then minY = result.Y end
            if result.X > maxX then maxX = result.X end
            if result.Y > maxY then maxY = result.Y end
        end
    end
    if not anyOnScreen then return nil end
    return minX, minY, maxX, maxY
end

-- ============================================================================
-- SECTION 4 — PAGES
-- ============================================================================
local PAGES = {}
local NAVBTNS = {}
local PAGE_NAMES = {
    {"Home", "⊞"}, {"Combat", "⊕"}, {"ESP", "◈"}, {"Movement", "⊿"},
    {"Visuals", "◉"}, {"Teleportation", "⊙"}, {"Spawning", "⊛"},
    {"Prison", "⊠"}, {"Players", "◎"}, {"Settings", "⊡"},
}
local PAGE_LOOKUP = {}
for _, p in ipairs(PAGE_NAMES) do PAGE_LOOKUP[p[1]] = true end

local function setPage(name)
    if not PAGE_LOOKUP[name] then return end
    CFG.Page = name
    for n, frame in pairs(PAGES) do frame.Visible = (n == name) end
    for n, btn in pairs(NAVBTNS) do
        local active = (n == name)
        tw(btn, 0.1, {
            BackgroundColor3 = active and C.card or C.bg,
            BackgroundTransparency = active and 0 or 1,
        })
        local ind = btn:FindFirstChild("_ind")
        if ind then tw(ind, 0.1, {BackgroundTransparency = active and 0 or 1}) end
        local lbl = btn:FindFirstChildOfClass("TextLabel")
        if lbl then lbl.TextColor3 = active and C.text or C.textDim end
    end
end

for i, data in ipairs(PAGE_NAMES) do
    local pageName, icon = data[1], data[2]
    local btn = Instance.new("TextButton")
    btn.Name = "nav_" .. pageName
    btn.BackgroundColor3 = C.bg
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.LayoutOrder = i
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local ind = Instance.new("Frame")
    ind.Name = "_ind"
    ind.BackgroundColor3 = C.accent
    ind.BackgroundTransparency = 1
    ind.BorderSizePixel = 0
    ind.Position = UDim2.fromOffset(0, 5)
    ind.Size = UDim2.fromOffset(2, 20)
    ind.Parent = btn
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.fromOffset(12, 0)
    lbl.Size = UDim2.new(1, -12, 1, 0)
    lbl.Font = FONT_MED
    lbl.TextSize = 12
    lbl.TextColor3 = C.textDim
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = icon .. "   " .. pageName
    lbl.Parent = btn
    btn.MouseButton1Click:Connect(function() setPage(pageName) end)
    NAVBTNS[pageName] = btn
    local pg = Instance.new("Frame")
    pg.Name = "page_" .. pageName
    pg.BackgroundTransparency = 1
    pg.Size = UDim2.new(1, 0, 0, 0)
    pg.AutomaticSize = Enum.AutomaticSize.Y
    pg.Visible = false
    pg.Parent = content
    local pl = Instance.new("UIListLayout")
    pl.SortOrder = Enum.SortOrder.LayoutOrder
    pl.Padding = UDim.new(0, 6)
    pl.Parent = pg
    PAGES[pageName] = pg
end

-- ============================================================================
-- DEX-INFORMED DATA
-- ============================================================================
local WEAPON_NAMES = {
    "1911 Emperor", "92FS", "93R", "AA.50 Beowulf", "AK Bayonet", "AK-12", "AK-47", "AK-74",
    "AMD-65", "AR-57", "AR2", "ARP", "Baton", "Beanbag Shotgun", "C8IUR (EXPS3-0)", "Cat gun",
    "FNX45", "Five Seven", "G17", "G18", "G18C", "G22", "G36", "G36C", "G40", "GEN-12",
    "Galil", "Giant17", "Godgun", "HK416", "HK416D", "Honey Badger", "KSG-12", "L1A1 SLR",
    "M1014", "M134", "M16A1", "M16A4", "M1911A1", "M1928", "M1A1", "M249 SAW", "M3 Grease Gun",
    "M4A1", "M82A1", "MCX Spear", "MGL MK1S", "MP40", "MP5", "MP7", "Makarov", "Model 590",
    "P90", "PKSG-12", "PM82A1", "PUMP45", "Paintball Gun", "Paterson 1836", "Patriot",
    "PepperBall Pistol", "PepperBall Rifle", "S550", "SA58 OSW", "SCAR-L", "SKS", "SR9",
    "SW500", "Saiga 12K", "Scorpion E3", "Screwdriver", "Shiv", "TOZ-106", "TT-33 Tokarev",
    "Terminator", "UMP45", "Ultimax100", "VSS Vintorez", "X26", "X5000",
}

local WEAPON_KEYWORDS = {
    "gun", "pistol", "rifle", "shot", "snip", "smg", "revolver", "taser",
    "mp5", "mp7", "ak", "m4", "g18", "g17", "glock", "ump", "p90", "scar",
    "hk", "g36", "m16", "m1911", "saiga", "ksg", "m1014", "terminator",
    "toz", "beowulf", "mcx", "harrow", "galil", "slr", "sa58", "sks", "vss",
    "vintorez", "patriot", "ar2", "c8", "dmr", "sg550", "honey badger",
    "ump45", "pump45", "scorpion", "se3", "m1928", "m1a1", "grease", "mp40",
    "m249", "ultimax", "m82", "mgl", "tempest", "giant17", "godgun", "sw500",
    "makarov", "92fs", "1911", "paterson", "pm82", "fnx", "five seven",
    "pepperball", "paintball", "m134", "sr9", "tokarev", "x26", "x5000",
    "baton", "bayonet",
    "shiv", "screwdriver", "screw driver", "knife", "blade", "bat", "crowbar",
    "wrench", "pipe", "hammer", "machete", "axe", "club", "stick",
    "weapon", "melee", "tool",
}

local VALLEY_SPAWNS = {
    "AssistantDirector", "Booking", "Civilian", "Cook",
    "Correctional Emergency Response", "CorrectionalOfficer", "Director",
    "Employee", "Escapee", "Janitor", "Maintenance", "Medical Staff",
    "Riot Officer", "Sheriff's Office", "State Police",
    "VCSO-SWAT", "VSP-SWAT", "WeaponsTester",
}

local VALLEY_TEAMS = {
    "Booking", "Civilian", "DepartmentOfCorrections", "Escapee",
    "MaximumSecurity", "MediumSecurity", "MentalPatient",
    "MinimumSecurity", "Sheriff'sOffice", "StatePolice",
    "VCSO-SWAT", "WeaponsTester",
}

-- ============================================================================
-- 4.1 HOME
-- ============================================================================
do
    local pg = PAGES.Home
    secLabel(pg, "Welcome")
    local c1 = mkCard(pg)
    local welcome = Instance.new("TextLabel")
    welcome.BackgroundTransparency = 1
    welcome.Size = UDim2.new(1, 0, 0, 24)
    welcome.Font = FONT_BOLD
    welcome.TextSize = 18
    welcome.TextColor3 = C.text
    welcome.TextXAlignment = Enum.TextXAlignment.Left
    welcome.Text = "Hello, " .. lp.Name
    welcome.Parent = c1
    local sub = Instance.new("TextLabel")
    sub.BackgroundTransparency = 1
    sub.Size = UDim2.new(1, 0, 0, 16)
    sub.Font = FONT
    sub.TextSize = 12
    sub.TextColor3 = C.textDim
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Text = "Valley Prison  ·  NyxScript  ·  v2.2"
    sub.Parent = c1
    local hint = Instance.new("TextLabel")
    hint.BackgroundTransparency = 1
    hint.Size = UDim2.new(1, 0, 0, 16)
    hint.Font = FONT_MED
    hint.TextSize = 12
    hint.TextColor3 = C.accent
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.Text = "Right Shift  =  toggle menu"
    hint.Parent = c1

    secLabel(pg, "Quick Status")
    local c2 = mkCard(pg)
    mkInfoRow(c2, "Players", function() return #Players:GetPlayers() end)
    mkInfoRow(c2, "FPS", function() return math.floor(1 / RunService.RenderStepped:Wait()) end)
    mkInfoRow(c2, "Ping", function() return math.floor(lp:GetNetworkPing() * 1000) .. " ms" end)
    mkInfoRow(c2, "Your Team", function() return lp.Team and lp.Team.Name or "None" end)
    mkInfoRow(c2, "Active Cheats", function()
        local n = 0
        for k, v in pairs(CFG) do
            if v == true and k ~= "Open" and k ~= "AntiKick" and k ~= "ShowNotifications" then n = n + 1 end
        end
        return n
    end)

    secLabel(pg, "Quick Toggles")
    local c3 = mkCard(pg)
    mkToggle(c3, "Player ESP", "PlayerESP")
    mkToggle(c3, "Aimbot", "Aimbot")
    mkToggle(c3, "Fly", "Fly")
    mkToggle(c3, "Speed Hack", "SpeedEnabled")
    mkToggle(c3, "Infinite Stamina", "InfStamina")
    mkToggle(c3, "Anti-Kick", "AntiKick")
end

-- ============================================================================
-- 4.2 COMBAT
-- ============================================================================
do
    local pg = PAGES.Combat
    secLabel(pg, "Aimbot")
    local c1 = mkCard(pg)
    mkToggle(c1, "Aimbot ON/OFF", "Aimbot")
    mkToggle(c1, "Aimlock (hard snap)", "Aimlock")
    mkToggle(c1, "FOV Ring", "AimbotFOVRing")
    mkColorPicker(c1, "FOV Ring Color", "AimbotFOVRingColor")
    mkToggle(c1, "Require Weapon", "AimbotRequireGun")
    mkToggle(c1, "Wall Check", "AimbotWallCheck")
    mkToggle(c1, "Team Check", "AimbotTeamCheck")
    mkToggle(c1, "Force Aiming flag (server-visible)", "AimbotForceAiming")
    mkSlider(c1, "FOV Radius (px)", "AimbotFOV", 30, 400, 5)
    mkSlider(c1, "Smooth (0.02 = snap, 1.0 = slow)", "AimbotSmooth", 0.02, 1.0, 0.01)
    mkDrop(c1, "Aim Part", {"Head", "HumanoidRootPart", "UpperTorso", "Torso", "RightUpperArm"}, "AimbotPart")
    local aimInfo = Instance.new("TextLabel")
    aimInfo.BackgroundTransparency = 1
    aimInfo.Size = UDim2.new(1, 0, 0, 30)
    aimInfo.Font = FONT
    aimInfo.TextSize = 11
    aimInfo.TextColor3 = C.textDim
    aimInfo.TextXAlignment = Enum.TextXAlignment.Left
    aimInfo.TextWrapped = true
    aimInfo.Text = "Aimbot only fires when ON, a target is inside the FOV ring, and (if Require Weapon) you are holding a weapon. Camera writes are skipped when no target exists, so shift-lock stays intact."
    aimInfo.Parent = c1

    secLabel(pg, "Silent Aim")
    local c2 = mkCard(pg)
    mkToggle(c2, "Silent Aim", "SilentAim")
    mkToggle(c2, "Silent Aim Wall Check", "SilentAimWallCheck")
    mkSlider(c2, "Silent Aim FOV (px, from cursor)", "SilentAimFOV", 30, 400, 5)
    local saInfo = Instance.new("TextLabel")
    saInfo.BackgroundTransparency = 1
    saInfo.Size = UDim2.new(1, 0, 0, 30)
    saInfo.Font = FONT
    saInfo.TextSize = 11
    saInfo.TextColor3 = C.textDim
    saInfo.TextXAlignment = Enum.TextXAlignment.Left
    saInfo.TextWrapped = true
    saInfo.Text = "Redirects projectiles to the target nearest your cursor (or screen center if shift-locked). Independent of aimbot FOV. Enable only after confirming the fire remote accepts Vector3/BasePart args — otherwise leave off."
    saInfo.Parent = c2

    secLabel(pg, "Triggerbot")
    local c3 = mkCard(pg)
    mkToggle(c3, "Triggerbot", "Triggerbot")
    mkSlider(c3, "Trigger Delay (s)", "TriggerbotDelay", 0.01, 0.5, 0.01)
    mkInfoRow(c3, "Last fired", function() return _G._VP_lastTrig and string.format("%.2fs ago", tick() - _G._VP_lastTrig) or "never" end)

    secLabel(pg, "Weapon Mods")
    local c4 = mkCard(pg)
    mkToggle(c4, "No Recoil", "NoRecoil")
    mkToggle(c4, "No Spread (ServerVariables.Cursor.Inaccuracy = 0)", "NoSpread")
    mkToggle(c4, "Rapid Fire", "RapidFire")
    mkToggle(c4, "Infinite Ammo", "InfiniteAmmo")
    mkToggle(c4, "Auto Reload", "AutoReload")
    mkToggle(c4, "Instant Equip", "InstantEquip")

    secLabel(pg, "Hitbox")
    local c5 = mkCard(pg)
    mkToggle(c5, "Hitbox Expand", "HitboxExpand")
    mkSlider(c5, "Hitbox Size (studs)", "HitboxSize", 1, 20, 0.5)
end

-- ============================================================================
-- 4.3 ESP
-- ============================================================================
do
    local pg = PAGES.ESP
    secLabel(pg, "Player ESP")
    local c1 = mkCard(pg)
    mkToggle(c1, "Player Highlight", "PlayerESP")
    mkToggle(c1, "Wallhack (always on top)", "WallHack")
    mkToggle(c1, "Chams (second highlight, own color)", "ChamsESP")
    mkColorPicker(c1, "Chams Color", "ChamsColor")
    mkToggle(c1, "Skeleton (billboard lines)", "SkeletonESP")
    mkColorPicker(c1, "Skeleton Color", "SkeletonColor")
    mkToggle(c1, "Box ESP", "BoxESP")
    mkColorPicker(c1, "Box Color", "BoxESPColor")
    mkToggle(c1, "Tracer Lines", "TracerESP")
    mkColorPicker(c1, "Tracer Color", "TracerColor")
    mkDrop(c1, "Tracer Origin", {"Bottom", "Center", "Top", "Mouse"}, "TracerOrigin")
    mkSlider(c1, "Tracer Thickness", "TracerThickness", 1, 4, 0.5)
    mkToggle(c1, "Team Colors", "TeamColors")
    mkSlider(c1, "Max Distance (studs)", "ESPMaxDist", 250, 1000, 25)

    secLabel(pg, "Tags")
    local c2 = mkCard(pg)
    mkToggle(c2, "Name Tags", "NameESP")
    mkToggle(c2, "Health Bar", "HealthESP")
    mkToggle(c2, "Distance Tag", "DistanceESP")

    secLabel(pg, "Colors")
    local c3 = mkCard(pg)
    mkColorPicker(c3, "Fill Color", "ESPFillColor")
    mkSlider(c3, "Fill Transparency", "ESPFillTransparency", 0, 1, 0.05)
    mkColorPicker(c3, "Outline Color", "ESPOutlineColor")
    mkSlider(c3, "Outline Transparency", "ESPOutlineTransparency", 0, 1, 0.05)

    secLabel(pg, "World ESP")
    local c5 = mkCard(pg)
    mkToggle(c5, "Item ESP", "ItemESP")
    mkToggle(c5, "Weapon ESP", "WeaponESP")
    mkToggle(c5, "Keycard ESP", "KeycardESP")
    mkSlider(c5, "Item Max Distance", "ItemESPMaxDist", 50, 500, 25)
    mkSlider(c5, "Item Scan Interval (s)", "ItemESPInterval", 0.5, 3.0, 0.25)
end

-- ============================================================================
-- 4.4 MOVEMENT
-- ============================================================================
do
    local pg = PAGES.Movement
    secLabel(pg, "Speed")
    local c1 = mkCard(pg)
    mkToggle(c1, "Speed Hack", "SpeedEnabled")
    mkSlider(c1, "Walk Speed", "Speed", 16, 64, 1)
    mkToggle(c1, "Bunny Hop", "BunnyHop")
    local sInfo = Instance.new("TextLabel")
    sInfo.BackgroundTransparency = 1
    sInfo.Size = UDim2.new(1, 0, 0, 16)
    sInfo.Font = FONT
    sInfo.TextSize = 11
    sInfo.TextColor3 = C.textDim
    sInfo.TextXAlignment = Enum.TextXAlignment.Left
    sInfo.Text = "Resets to 16 on toggle off. Server validates against ServerVariables.Sprint."
    sInfo.Parent = c1

    secLabel(pg, "Flight")
    local c2 = mkCard(pg)
    mkToggle(c2, "Fly", "Fly")
    mkSlider(c2, "Fly Speed", "FlySpeed", 5, 64, 1)
    mkDrop(c2, "Fly Mode", {"Head", "HRP", "CFrame"}, "FlyMode", function(v)
        if CFG.Fly then _G._VP_restartFly() end
        notify("Fly mode: " .. v, "info")
    end)
    local fInfo = Instance.new("TextLabel")
    fInfo.BackgroundTransparency = 1
    fInfo.Size = UDim2.new(1, 0, 0, 16)
    fInfo.Font = FONT
    fInfo.TextSize = 11
    fInfo.TextColor3 = C.textDim
    fInfo.TextXAlignment = Enum.TextXAlignment.Left
    fInfo.Text = "WASD = move   Space = up   Ctrl = down"
    fInfo.Parent = c2

    secLabel(pg, "Jump")
    local c3 = mkCard(pg)
    mkToggle(c3, "Infinite Jump", "InfJump")
    mkSlider(c3, "Jump Power", "JumpPower", 50, 500, 10)
    mkToggle(c3, "Super Jump", "SuperJump")
    mkSlider(c3, "Super Jump Power", "SuperJumpPower", 100, 1000, 25)
    mkToggle(c3, "Slow Fall", "SlowFall")
    mkSlider(c3, "Slow Fall Speed", "SlowFallSpeed", 1, 30, 1)

    secLabel(pg, "Gravity")
    local c4 = mkCard(pg)
    mkToggle(c4, "Anti-Gravity", "AntiGravity")
    mkSlider(c4, "Gravity Value (196 = default)", "GravityValue", 0, 196, 5)

    secLabel(pg, "Other")
    local c5 = mkCard(pg)
    mkToggle(c5, "Noclip", "Noclip")
    mkToggle(c5, "Infinite Stamina", "InfStamina")
    mkToggle(c5, "Anti-Gravity Light", "AntiStun")
    mkToggle(c5, "Teleport to Cursor", "TpToCursor")
    mkKeybind(c5, "TP Key", "TpToCursorKey")
end

-- ============================================================================
-- 4.5 VISUALS
-- ============================================================================
do
    local pg = PAGES.Visuals
    secLabel(pg, "Lighting")
    local c1 = mkCard(pg)
    mkToggle(c1, "Fullbright", "Fullbright", function(s)
        if not s and _G._VP_restoreLighting then _G._VP_restoreLighting() end
    end)
    mkToggle(c1, "No Fog", "NoFog")
    mkBtn(c1, "Disable Bloom", function()
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("BloomEffect") then v.Enabled = false end
        end
        notify("Bloom disabled", "ok")
    end)
    mkBtn(c1, "Disable Blur", function()
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") then v.Enabled = false end
        end
        notify("Blur disabled", "ok")
    end)

    secLabel(pg, "Clock")
    local c2 = mkCard(pg)
    mkToggle(c2, "Custom Time", "TimeOfDay")
    mkSlider(c2, "Time (hours)", "TimeValue", 0, 24, 0.25)

    secLabel(pg, "Camera")
    local c3 = mkCard(pg)
    mkToggle(c3, "Third Person Camera", "ThirdPerson")
    mkSlider(c3, "Third Person Distance", "ThirdPersonDist", 5, 30, 1)
    mkToggle(c3, "FOV Zoom Hack", "ZoomHack")
    mkSlider(c3, "Custom FOV", "ZoomFOV", 30, 120, 1)

    secLabel(pg, "Character")
    local c4 = mkCard(pg)
    mkToggle(c4, "Rainbow Character", "RainbowCharacter")
    mkToggle(c4, "Invisible Character", "InvisibleCharacter", function(s)
        if not s and _G._VP_restoreCharTransparency then _G._VP_restoreCharTransparency() end
    end)
    mkToggle(c4, "Custom Character Color", "CustomCharColor")
    mkColorPicker(c4, "Character Color", "CharColor")
end

-- ============================================================================
-- 4.6 TELEPORTATION
-- ============================================================================
do
    local pg = PAGES.Teleportation
    secLabel(pg, "Spawn Points")
    local c1 = mkCard(pg)
    local function tpToSpawn(name)
        local target = nil
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") and d.Name:lower():find(name:lower(), 1, true) then
                target = d
                break
            end
        end
        if target then
            local r = root(lp)
            if r then
                r.CFrame = target.CFrame + Vector3.new(0, 4, 0)
                notify("TP → " .. name, "ok")
            end
        else
            notify(name .. " — not found", "warn")
        end
    end
    for _, spawnName in ipairs(VALLEY_SPAWNS) do
        mkBtn(c1, spawnName, function() tpToSpawn(spawnName) end)
    end

    secLabel(pg, "Player Teleport")
    local c2 = mkCard(pg)
    local tpFrame = Instance.new("Frame")
    tpFrame.BackgroundTransparency = 1
    tpFrame.Size = UDim2.new(1, 0, 0, 140)
    tpFrame.Parent = c2
    local tpScroll = Instance.new("ScrollingFrame")
    tpScroll.BackgroundTransparency = 1
    tpScroll.BorderSizePixel = 0
    tpScroll.Size = UDim2.new(1, 0, 1, 0)
    tpScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tpScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tpScroll.ScrollBarThickness = 3
    tpScroll.ScrollBarImageColor3 = C.accent
    tpScroll.Parent = tpFrame
    local tpL = Instance.new("UIListLayout")
    tpL.SortOrder = Enum.SortOrder.LayoutOrder
    tpL.Padding = UDim.new(0, 2)
    tpL.Parent = tpScroll
    local function rebuildTpList()
        for _, c in ipairs(tpScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        for i, p in ipairs(Players:GetPlayers()) do
            if p == lp then continue end
            local row = Instance.new("Frame")
            row.BackgroundColor3 = C.card
            row.BorderSizePixel = 0
            row.Size = UDim2.new(1, -4, 0, 26)
            row.LayoutOrder = i
            row.Parent = tpScroll
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
            local n = Instance.new("TextLabel")
            n.BackgroundTransparency = 1
            n.Position = UDim2.fromOffset(8, 0)
            n.Size = UDim2.new(0.5, 0, 1, 0)
            n.Font = FONT
            n.TextSize = 12
            n.TextColor3 = C.text
            n.TextXAlignment = Enum.TextXAlignment.Left
            n.Text = p.Name
            n.Parent = row
            local b1 = Instance.new("TextButton")
            b1.AnchorPoint = Vector2.new(1, 0.5)
            b1.Position = UDim2.new(1, -4, 0.5, 0)
            b1.Size = UDim2.fromOffset(56, 20)
            b1.BackgroundColor3 = C.accent
            b1.BorderSizePixel = 0
            b1.Font = FONT_BOLD
            b1.TextSize = 11
            b1.TextColor3 = Color3.fromRGB(0, 0, 0)
            b1.Text = "→ TP"
            b1.AutoButtonColor = false
            b1.Parent = row
            Instance.new("UICorner", b1).CornerRadius = UDim.new(0, 4)
            b1.MouseButton1Click:Connect(function()
                local a, b = root(lp), root(p)
                if a and b then a.CFrame = b.CFrame + Vector3.new(2, 0, 0); notify("TP → " .. p.Name, "ok") end
            end)
        end
    end
    mkBtn(c2, "Refresh Player List", rebuildTpList)
    rebuildTpList()
    Players.PlayerAdded:Connect(function() task.wait(0.5); rebuildTpList() end)
    Players.PlayerRemoving:Connect(function() task.wait(0.1); rebuildTpList() end)

    secLabel(pg, "Saved Positions")
    local c3 = mkCard(pg)
    local savedPositions = {}
    local savedFrame = Instance.new("Frame")
    savedFrame.BackgroundTransparency = 1
    savedFrame.Size = UDim2.new(1, 0, 0, 120)
    savedFrame.Parent = c3
    local savedScroll = Instance.new("ScrollingFrame")
    savedScroll.BackgroundTransparency = 1
    savedScroll.BorderSizePixel = 0
    savedScroll.Size = UDim2.new(1, 0, 1, 0)
    savedScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    savedScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    savedScroll.ScrollBarThickness = 3
    savedScroll.ScrollBarImageColor3 = C.accent
    savedScroll.Parent = savedFrame
    local sL = Instance.new("UIListLayout")
    sL.SortOrder = Enum.SortOrder.LayoutOrder
    sL.Padding = UDim.new(0, 2)
    sL.Parent = savedScroll
    local function rebuildSaved()
        for _, c in ipairs(savedScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        for i, entry in ipairs(savedPositions) do
            local row = Instance.new("Frame")
            row.BackgroundColor3 = C.card
            row.BorderSizePixel = 0
            row.Size = UDim2.new(1, -4, 0, 26)
            row.LayoutOrder = i
            row.Parent = savedScroll
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
            local n = Instance.new("TextLabel")
            n.BackgroundTransparency = 1
            n.Position = UDim2.fromOffset(8, 0)
            n.Size = UDim2.new(0.5, 0, 1, 0)
            n.Font = FONT
            n.TextSize = 12
            n.TextColor3 = C.text
            n.TextXAlignment = Enum.TextXAlignment.Left
            n.Text = entry.name
            n.Parent = row
            local goB = Instance.new("TextButton")
            goB.AnchorPoint = Vector2.new(1, 0.5)
            goB.Position = UDim2.new(1, -32, 0.5, 0)
            goB.Size = UDim2.fromOffset(28, 20)
            goB.BackgroundColor3 = C.accent
            goB.BorderSizePixel = 0
            goB.Font = FONT_BOLD
            goB.TextSize = 10
            goB.TextColor3 = Color3.fromRGB(0, 0, 0)
            goB.Text = "Go"
            goB.AutoButtonColor = false
            goB.Parent = row
            Instance.new("UICorner", goB).CornerRadius = UDim.new(0, 4)
            goB.MouseButton1Click:Connect(function()
                local r = root(lp)
                if r then r.CFrame = entry.cf; notify("TP → " .. entry.name, "ok") end
            end)
            local delB = Instance.new("TextButton")
            delB.AnchorPoint = Vector2.new(1, 0.5)
            delB.Position = UDim2.new(1, -4, 0.5, 0)
            delB.Size = UDim2.fromOffset(24, 20)
            delB.BackgroundColor3 = C.danger
            delB.BorderSizePixel = 0
            delB.Font = FONT_BOLD
            delB.TextSize = 10
            delB.TextColor3 = Color3.fromRGB(0, 0, 0)
            delB.Text = "×"
            delB.AutoButtonColor = false
            delB.Parent = row
            Instance.new("UICorner", delB).CornerRadius = UDim.new(0, 4)
            delB.MouseButton1Click:Connect(function()
                table.remove(savedPositions, i)
                rebuildSaved()
            end)
        end
    end
    mkBtn(c3, "Save Current Position", function()
        if #savedPositions >= 20 then notify("Max 20 saved positions", "warn"); return end
        local r = root(lp)
        if r then
            table.insert(savedPositions, {name = "Pos " .. (#savedPositions + 1), cf = r.CFrame})
            rebuildSaved()
            notify("Position saved", "ok")
        end
    end)
    rebuildSaved()
end

-- ============================================================================
-- 4.7 SPAWNING  — teleport-to-rack & interact
-- ============================================================================
do
    local pg = PAGES.Spawning

    -- Utility: find a rack for the given weapon name and interact with it
    local function findWeaponRack(name)
        local lower = name:lower()
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                local at = (d.ActionText or ""):lower()
                local ot = (d.ObjectText or ""):lower()
                if at:find(lower, 1, true) or ot:find(lower, 1, true) then
                    return d, d.Parent
                end
            elseif d:IsA("ClickDetector") then
                local parentName = d.Parent and d.Parent.Name or ""
                if parentName:lower():find(lower, 1, true) then
                    return d, d.Parent
                end
            elseif d:IsA("BasePart") and d.Name:lower() == lower then
                -- bare weapon part on ground — check for prompt/click children
                local prompt = d:FindFirstChildOfClass("ProximityPrompt")
                local cd = d:FindFirstChildOfClass("ClickDetector")
                if prompt or cd then return prompt or cd, d end
            end
        end
        return nil, nil
    end

    local function interactWithRack(name)
        local obj, rackPart = findWeaponRack(name)
        if not obj then
            notify(name .. " rack not found in world", "warn")
            return false
        end
        local r = root(lp)
        if not r then notify("No character", "err"); return false end
        if rackPart and rackPart:IsA("BasePart") then
            r.CFrame = rackPart.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.35)
        end
        if obj:IsA("ProximityPrompt") then
            if not safeFireProximityPrompt(obj, 0) then
                -- fallback: manual hold
                pcall(function()
                    obj:InputHoldBegin()
                    task.wait(obj.HoldDuration or 0)
                    obj:InputHoldEnd()
                end)
            end
        elseif obj:IsA("ClickDetector") then
            if not safeFireClickDetector(obj) then
                pcall(function() fireclickdetector(obj, 0) end)
            end
        end
        task.wait(0.4)
        local got = false
        for _, t in ipairs(lp.Backpack:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find(name:lower(), 1, true) then got = true; break end
        end
        if got then
            notify(name .. " → backpack", "ok")
            return true
        else
            notify(name .. " pickup failed (may need permission)", "warn")
            return false
        end
    end

    secLabel(pg, "Weapon Pickup — Teleport & Grab")
    local c1 = mkCard(pg)
    local info = Instance.new("TextLabel")
    info.BackgroundTransparency = 1
    info.Size = UDim2.new(1, 0, 0, 30)
    info.Font = FONT
    info.TextSize = 11
    info.TextColor3 = C.textDim
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextWrapped = true
    info.Text = "Searches the world for a weapon rack (ProximityPrompt, ClickDetector, or a matching part), teleports you to it, and fires the prompt. If the server permits the weapon for your role, it lands in your backpack. Server-side permission still applies — you can't pick up an armory gun as a prisoner."
    info.Parent = c1

    mkScrollList(c1, WEAPON_NAMES, interactWithRack, 240)

    secLabel(pg, "Backpack Actions")
    local c2 = mkCard(pg)
    mkBtn(c2, "Drop Held Tool on Ground", function()
        local ch = chr(lp)
        if not ch then return end
        local tool = ch:FindFirstChildOfClass("Tool")
        if not tool then notify("No tool equipped", "warn"); return end
        local r = root(lp)
        local handle = tool:FindFirstChild("Handle")
        tool.Parent = workspace
        if handle and r then
            handle.CFrame = r.CFrame + r.CFrame.LookVector * 4 + Vector3.new(0, 1, 0)
        end
        notify("Dropped " .. tool.Name, "info")
    end)
    mkBtn(c2, "Collect All Dropped Items", function()
        local n = 0
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("Tool") then d.Parent = lp.Backpack; n = n + 1 end
        end
        notify("Collected " .. n .. " items", "ok")
    end)
    mkBtn(c2, "Clear Backpack", function()
        local n = 0
        for _, d in ipairs(lp.Backpack:GetChildren()) do
            if d:IsA("Tool") then d:Destroy(); n = n + 1 end
        end
        notify("Cleared " .. n .. " items", "ok")
    end)
    mkInfoRow(c2, "Items in backpack", function()
        local n = 0
        for _, d in ipairs(lp.Backpack:GetChildren()) do
            if d:IsA("Tool") then n = n + 1 end
        end
        return n
    end)
end

-- ============================================================================
-- 4.8 PRISON
-- ============================================================================
do
    local pg = PAGES.Prison

    local function getRemote(folderName, childName)
        local folder = ReplicatedStorage:FindFirstChild("Remotes")
        if not folder then return nil end
        local sub = folder:FindFirstChild(folderName)
        if not sub then return nil end
        return sub:FindFirstChild(childName)
    end

    secLabel(pg, "Cuffs")
    local c1 = mkCard(pg)
    mkToggle(c1, "Auto-Escape Cuffs", "AutoEscapeCuffs")
    mkBtn(c1, "Fire ReleaseTarget (one-shot)", function()
        local r = getRemote("CuffsSystem", "ReleaseTarget")
        if not r then notify("ReleaseTarget remote missing", "err"); return end
        pcall(function()
            r:FireServer(lp)
        end)
        pcall(function()
            r:FireServer(lp.Character)
        end)
        pcall(function()
            r:FireServer(lp.Name)
        end)
        notify("ReleaseTarget fired (3 arg shapes)", "info")
    end)
    mkBtn(c1, "Fire UnDetainTarget (one-shot)", function()
        local r = getRemote("CuffsSystem", "UnDetainTarget")
        if not r then notify("UnDetainTarget remote missing", "err"); return end
        pcall(function() r:FireServer(lp) end)
        pcall(function() r:FireServer(lp.Character) end)
        notify("UnDetainTarget fired", "info")
    end)
    mkBtn(c1, "Break Cuff Welds", function()
        local ch = chr(lp)
        if not ch then return end
        local n = 0
        for _, d in ipairs(ch:GetDescendants()) do
            if (d:IsA("WeldConstraint") or d:IsA("Weld")) then
                local nm = (d.Name or ""):lower()
                local parentNm = (d.Parent and d.Parent.Name or ""):lower()
                if nm:find("cuff") or parentNm:find("cuff") then
                    d:Destroy(); n = n + 1
                end
            end
        end
        notify("Broke " .. n .. " cuff welds", "ok")
    end)

    secLabel(pg, "Doors")
    local c2 = mkCard(pg)
    mkBtn(c2, "Open Nearby Doors", function()
        local r = getRemote("Gate", "GateStatus")
        if r then
            pcall(function() r:FireServer() end)
        end
        -- Physical: disable CanCollide on any door part within 25 studs
        local myRoot = root(lp)
        if not myRoot then return end
        local n = 0
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                local nm = (d.Name or ""):lower()
                if (nm:find("door") or nm:find("gate")) then
                    if (d.Position - myRoot.Position).Magnitude < 25 then
                        d.CanCollide = false
                        n = n + 1
                    end
                end
            end
        end
        notify("Removed collision on " .. n .. " nearby doors (client)", "info")
    end)

    secLabel(pg, "Team Switcher")
    local c3 = mkCard(pg)
    for _, tn in ipairs(VALLEY_TEAMS) do
        mkBtn(c3, tn, function()
            local t = TeamsService:FindFirstChild(tn)
            if t then
                local ok = pcall(function() lp.Team = t end)
                if ok then notify("Team → " .. tn, "ok") else notify("Team change blocked", "warn") end
            else
                notify("Team " .. tn .. " not found", "warn")
            end
            local r = getRemote("", "ChangeTeam")
            if r then pcall(function() r:FireServer(tn) end) end
        end)
    end

    secLabel(pg, "Remote Monitor")
    local c4 = mkCard(pg)
    mkToggle(c4, "Log All Remotes", "LogRemotes")
    mkToggle(c4, "Log AC Traffic (1984 / when_will_you_learn / GetAC)", "LogACTraffic")
    mkToggle(c4, "Block Arrest Remotes", "BlockArrest")
    mkToggle(c4, "Block Ban/Kick Remotes", "BlockBan")
    mkBtn(c4, "List All Remotes", function()
        local n = 0
        for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
            if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                print("[VP Remote] " .. d:GetFullName())
                n = n + 1
            end
        end
        notify("Listed " .. n .. " remotes", "info", 4)
    end)
    mkBtn(c4, "Scan for Kick Remotes", function()
        local n = 0
        for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
            if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                local nm = d.Name:lower()
                if nm:find("kick") or nm:find("ban") or nm:find("punish") then
                    print("[VP Suspect] " .. d:GetFullName())
                    n = n + 1
                end
            end
        end
        notify("Found " .. n .. " suspects", "info", 4)
    end)
end

-- ============================================================================
-- 4.9 PLAYERS
-- ============================================================================
do
    local pg = PAGES.Players
    secLabel(pg, "Player List")
    local c1 = mkCard(pg)
    local listFrame = Instance.new("Frame")
    listFrame.BackgroundTransparency = 1
    listFrame.Size = UDim2.new(1, 0, 0, 200)
    listFrame.Parent = c1
    local listScroll = Instance.new("ScrollingFrame")
    listScroll.BackgroundTransparency = 1
    listScroll.BorderSizePixel = 0
    listScroll.Size = UDim2.new(1, 0, 1, 0)
    listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    listScroll.ScrollBarThickness = 3
    listScroll.ScrollBarImageColor3 = C.accent
    listScroll.Parent = listFrame
    local lL = Instance.new("UIListLayout")
    lL.SortOrder = Enum.SortOrder.LayoutOrder
    lL.Padding = UDim.new(0, 2)
    lL.Parent = listScroll
    local function rebuildPlayerList()
        for _, c in ipairs(listScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        for i, p in ipairs(Players:GetPlayers()) do
            local row = Instance.new("Frame")
            row.BackgroundColor3 = C.card
            row.BorderSizePixel = 0
            row.Size = UDim2.new(1, -4, 0, 34)
            row.LayoutOrder = i
            row.Parent = listScroll
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
            local dot = Instance.new("Frame")
            dot.AnchorPoint = Vector2.new(0, 0.5)
            dot.Position = UDim2.new(0, 8, 0.5, 0)
            dot.Size = UDim2.fromOffset(8, 8)
            dot.BackgroundColor3 = teamColor(p)
            dot.BorderSizePixel = 0
            dot.Parent = row
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            local nm = Instance.new("TextLabel")
            nm.BackgroundTransparency = 1
            nm.Position = UDim2.fromOffset(24, 0)
            nm.Size = UDim2.new(0.5, 0, 0.5, 0)
            nm.Font = FONT_BOLD
            nm.TextSize = 12
            nm.TextColor3 = C.text
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.Text = p.Name
            nm.Parent = row
            local role = Instance.new("TextLabel")
            role.BackgroundTransparency = 1
            role.Position = UDim2.fromOffset(24, 17)
            role.Size = UDim2.new(0.5, 0, 0.5, 0)
            role.Font = FONT
            role.TextSize = 10
            role.TextColor3 = C.textDim
            role.TextXAlignment = Enum.TextXAlignment.Left
            role.Text = p.Team and p.Team.Name or "None"
            role.Parent = row
            local ping = Instance.new("TextLabel")
            ping.AnchorPoint = Vector2.new(1, 0)
            ping.Position = UDim2.new(1, -8, 0, 4)
            ping.Size = UDim2.new(0.3, 0, 0.5, 0)
            ping.BackgroundTransparency = 1
            ping.Font = FONT_MED
            ping.TextSize = 11
            ping.TextColor3 = C.accent
            ping.TextXAlignment = Enum.TextXAlignment.Right
            ping.Text = math.floor(p:GetNetworkPing() * 1000) .. " ms"
            ping.Parent = row
            local tpBtn = Instance.new("TextButton")
            tpBtn.AnchorPoint = Vector2.new(1, 0.5)
            tpBtn.Position = UDim2.new(1, -8, 0.5, 8)
            tpBtn.Size = UDim2.fromOffset(50, 16)
            tpBtn.BackgroundColor3 = C.accent
            tpBtn.BorderSizePixel = 0
            tpBtn.Font = FONT_BOLD
            tpBtn.TextSize = 10
            tpBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            tpBtn.Text = "TP"
            tpBtn.AutoButtonColor = false
            tpBtn.Parent = row
            Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 3)
            tpBtn.MouseButton1Click:Connect(function()
                if p ~= lp then
                    local a, b = root(lp), root(p)
                    if a and b then a.CFrame = b.CFrame + Vector3.new(2, 0, 0); notify("TP → " .. p.Name, "ok") end
                end
            end)
        end
    end
    mkBtn(c1, "Refresh", rebuildPlayerList)
    rebuildPlayerList()
    Players.PlayerAdded:Connect(function() task.wait(0.5); rebuildPlayerList() end)
    Players.PlayerRemoving:Connect(function() task.wait(0.1); rebuildPlayerList() end)

    secLabel(pg, "Local Player Info")
    local c2 = mkCard(pg)
    mkInfoRow(c2, "UserID", function() return lp.UserId end)
    mkInfoRow(c2, "Username", function() return lp.Name end)
    mkInfoRow(c2, "Display Name", function() return lp.DisplayName end)
    mkInfoRow(c2, "Team", function() return lp.Team and lp.Team.Name or "None" end)
    mkInfoRow(c2, "Health", function()
        local h = hum(lp)
        return h and (math.floor(h.Health) .. "/" .. math.floor(h.MaxHealth)) or "—"
    end)
    mkInfoRow(c2, "Walk Speed", function()
        local h = hum(lp)
        return h and math.floor(h.WalkSpeed) or "—"
    end)
    mkInfoRow(c2, "Position", function()
        local r = root(lp)
        return r and string.format("%.0f, %.0f, %.0f", r.Position.X, r.Position.Y, r.Position.Z) or "—"
    end)
    mkInfoRow(c2, "Server HP", function()
        local sv = lp:FindFirstChild("ServerVariables")
        local sp = sv and sv:FindFirstChild("SpawnStats")
        local hm = sp and sp:FindFirstChild("Humanoid")
        local hp = hm and hm:FindFirstChild("Health")
        return hp and tostring(hp.Value) or "—"
    end)
    mkInfoRow(c2, "Stamina", function()
        local sv = lp:FindFirstChild("ServerVariables")
        local sp = sv and sv:FindFirstChild("Sprint")
        local st = sp and sp:FindFirstChild("Stamina")
        return st and string.format("%.0f", st.Value) or "—"
    end)
    mkInfoRow(c2, "Ping", function() return math.floor(lp:GetNetworkPing() * 1000) .. " ms" end)
    mkInfoRow(c2, "Account Age", function() return lp.AccountAge .. " days" end)
end

-- ============================================================================
-- 4.10 SETTINGS
-- ============================================================================
do
    local pg = PAGES.Settings
    secLabel(pg, "Menu")
    local c1 = mkCard(pg)
    mkKeybind(c1, "Menu Toggle Key", "MenuKey")
    mkToggle(c1, "Show Notifications", "ShowNotifications")
    mkBtn(c1, "Reset All Settings", function()
        for k, v in pairs(CFG) do
            if type(v) == "boolean" then CFG[k] = (k == "AntiKick") end
        end
        notify("Settings reset", "warn")
    end)

    secLabel(pg, "Config")
    local c2 = mkCard(pg)
    mkBtn(c2, "Save Config to Clipboard", function()
        local SERIALIZABLE = {boolean = true, number = true, string = true}
        local clean = {}
        for k, v in pairs(CFG) do
            if SERIALIZABLE[typeof(v)] then clean[k] = v end
        end
        local ok, json = pcall(function() return HttpService:JSONEncode(clean) end)
        if not ok then notify("Encode failed", "err"); return end
        local copied = false
        if type(setclipboard) == "function" then copied = pcall(setclipboard, json) end
        if not copied and type(toclipboard) == "function" then copied = pcall(toclipboard, json) end
        if copied then notify("Config copied", "ok") else print(json); notify("Copied to output", "info") end
    end)

    secLabel(pg, "About")
    local c3 = mkCard(pg)
    mkInfoRow(c3, "Game", function() return "Valley Prison" end)
    mkInfoRow(c3, "Script", function() return "NyxScript v2.2" end)
    mkInfoRow(c3, "Build", function() return os.date("%Y-%m-%d") end)
end

-- ============================================================================
-- SECTION 5 — CHEAT LOGIC
-- ============================================================================

-- 5.1 ANTI-KICK (installed at load, gated by CFG)
do
    local lp_mt = safeGetRawMetatable(lp)
    if lp_mt and lp_mt.__namecall then
        local old = lp_mt.__namecall
        lp_mt.__namecall = safeNewCclosure(function(self, ...)
            local m = safeGetNamecallMethod()
            if m == "Kick" and CFG.AntiKick then
                notify("Kick blocked", "warn", 4)
                return
            end
            if m == "Disconnect" and CFG.AntiDisconnect then
                notify("Disconnect blocked", "warn", 4)
                return
            end
            return old(self, ...)
        end)
    end

    local game_mt = safeGetRawMetatable(game)
    if game_mt and game_mt.__namecall then
        local old = game_mt.__namecall
        game_mt.__namecall = safeNewCclosure(function(self, ...)
            local m = safeGetNamecallMethod()
            if m == "FireServer" or m == "InvokeServer" then
                local n = ""
                pcall(function() n = tostring(self.Name):lower() end)
                if CFG.BlockArrest and (n:find("arrest") or n:find("cuff") or n:find("detain")) then
                    notify("Arrest remote blocked", "ok", 2)
                    return
                end
                if CFG.BlockBan and (n:find("ban") or n:find("kick") or n:find("punish")) then
                    notify("Ban remote blocked", "ok", 2)
                    return
                end
                if CFG.LogACTraffic and (self.Name == "1984"
                or tostring(self.Name):find("when_will_you_learn", 1, true)
                or self.Name == "GetAC") then
                    local parts = {}
                    for i, v in ipairs({...}) do
                        parts[#parts + 1] = string.format("arg%d=%s", i, typeof(v))
                    end
                    print("[AC-TRAFFIC]", m, self:GetFullName(), table.concat(parts, ", "))
                end
                if CFG.LogRemotes and not (self.Name == "1984" or self.Name == "GetAC") then
                    pcall(function() print(string.format("[VP Remote] %s → %s", m, self:GetFullName())) end)
                end
            end
            return old(self, ...)
        end)
    end
end

-- 5.2 WEAPON DETECTION
local function hasWeapon()
    local ch = chr(lp)
    if not ch then return false end
    local tool = ch:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local n = tool.Name:lower()
    for _, w in ipairs(WEAPON_KEYWORDS) do
        if n:find(w, 1, true) then return true end
    end
    for _, d in ipairs(tool:GetDescendants()) do
        if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
            local dn = d.Name:lower()
            if dn:find("shoot") or dn:find("fire") or dn:find("attack") or dn:find("hit") then
                return true
            end
        end
    end
    return false
end

-- 5.3 AIMBOT TARGET FINDER (camera center FOV)
local function getBestTargetCamera()
    local vp = cam.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2
    local candidates = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == lp then continue end
        if not isAlive(pl) then continue end
        if CFG.AimbotTeamCheck and isTeammate(pl) then continue end
        if dist(pl) > CFG.ESPMaxDist then continue end
        local ch = chr(pl)
        local pt = ch and (ch:FindFirstChild(CFG.AimbotPart) or root(pl))
        if not pt then continue end
        if CFG.AimbotWallCheck and not hasLineOfSight(pt) then continue end
        local sp, vis = cam:WorldToViewportPoint(pt.Position)
        if not vis or sp.Z < 0 then continue end
        local sd = math.sqrt((sp.X - cx) ^ 2 + (sp.Y - cy) ^ 2)
        if sd <= CFG.AimbotFOV then
            table.insert(candidates, {part = pt, sd = sd, player = pl})
        end
    end
    if #candidates == 0 then return nil end
    table.sort(candidates, function(a, b) return a.sd < b.sd end)
    return candidates[1].part
end

-- 5.4 AIMBOT TARGET FINDER (cursor FOV, for silent aim)
local function getBestTargetCursor()
    local mousePos = UserInputService:GetMouseLocation()
    local mx, my = mousePos.X, mousePos.Y
    if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        local vp = cam.ViewportSize
        mx, my = vp.X / 2, vp.Y / 2
    end
    local candidates = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == lp then continue end
        if not isAlive(pl) then continue end
        if isTeammate(pl) then continue end
        local ch = chr(pl)
        local pt = ch and (ch:FindFirstChild("Head") or root(pl))
        if not pt then continue end
        if CFG.SilentAimWallCheck and not hasLineOfSight(pt) then continue end
        local sp, vis = cam:WorldToViewportPoint(pt.Position)
        if not vis or sp.Z < 0 then continue end
        local sd = math.sqrt((sp.X - mx) ^ 2 + (sp.Y - my) ^ 2)
        if sd <= CFG.SilentAimFOV then
            table.insert(candidates, {part = pt, sd = sd})
        end
    end
    if #candidates == 0 then return nil end
    table.sort(candidates, function(a, b) return a.sd < b.sd end)
    return candidates[1].part
end

-- 5.5 AIMBOT CAMERA LOOP — shift-lock safe
RunService:BindToRenderStep("VP_Aim", Enum.RenderPriority.Camera.Value + 1, function()
    if not (CFG.Aimbot or CFG.Aimlock) then return end
    if CFG.AimbotRequireGun and not hasWeapon() then return end
    local t = getBestTargetCamera()
    if not t then return end  -- no target -> don't touch camera -> shift-lock intact
    if CFG.AimbotForceAiming then
        local sv = lp:FindFirstChild("ServerVariables")
        if sv then
            local aiming = sv:FindFirstChild("Aiming")
            if aiming and aiming:IsA("BoolValue") then
                pcall(function() aiming.Value = true end)
            end
        end
    end
    local goalCF = CFrame.new(cam.CFrame.Position, t.Position)
    if CFG.Aimlock then
        cam.CFrame = goalCF
    else
        cam.CFrame = cam.CFrame:Lerp(goalCF, CFG.AimbotSmooth)
    end
end)

-- 5.6 SILENT AIM HOOK
local _saHooked = false
local function hookSilentAim()
    if _saHooked then return end
    local mt = safeGetRawMetatable(game)
    if not mt or not mt.__namecall then return end
    _saHooked = true
    local old = mt.__namecall
    mt.__namecall = safeNewCclosure(function(self, ...)
        local m = safeGetNamecallMethod()
        if CFG.SilentAim and (m == "FireServer" or m == "InvokeServer") then
            local isWeaponFire = false
            pcall(function()
                isWeaponFire = self and self.Parent and self.Parent:IsA("Tool")
            end)
            if isWeaponFire then
                local args = {...}
                local t = getBestTargetCursor()
                if t then
                    for i, v in ipairs(args) do
                        if typeof(v) == "Vector3" then
                            args[i] = t.Position
                        elseif typeof(v) == "Instance" and v:IsA("BasePart") then
                            args[i] = t
                        end
                    end
                end
                return old(self, table.unpack(args))
            end
        end
        return old(self, ...)
    end)
end
task.spawn(function()
    while not _saHooked do
        task.wait(0.5)
        if CFG.SilentAim then hookSilentAim() end
    end
end)

-- 5.7 FOV RING (Drawing) — always centered, shows when Aimbot or Aimlock on
local _fovRing = nil
pcall(function()
    if Drawing then
        _fovRing = Drawing.new("Circle")
        _fovRing.Thickness = 1.5
        _fovRing.Filled = false
        _fovRing.NumSides = 64
        _fovRing.Transparency = 1
        _fovRing.Color = CFG.AimbotFOVRingColor
        _fovRing.Visible = false
    end
end)
RunService.RenderStepped:Connect(function()
    if not _fovRing then return end
    local show = CFG.AimbotFOVRing and (CFG.Aimbot or CFG.Aimlock)
    if show then
        local vp = cam.ViewportSize
        _fovRing.Position = Vector2.new(vp.X / 2, vp.Y / 2)
        _fovRing.Radius = CFG.AimbotFOV
        _fovRing.Color = CFG.AimbotFOVRingColor
        _fovRing.Visible = true
    else
        _fovRing.Visible = false
    end
end)

-- 5.8 ESP — HIGHLIGHTS
local espHighlights = {}
local chamsHighlights = {}
local function buildESP(pl)
    if pl == lp then return end
    if espHighlights[pl] and espHighlights[pl].Parent then espHighlights[pl]:Destroy() end
    espHighlights[pl] = nil
    if chamsHighlights[pl] and chamsHighlights[pl].Parent then chamsHighlights[pl]:Destroy() end
    chamsHighlights[pl] = nil
    local ch = chr(pl)
    if not ch then
        pl.CharacterAdded:Connect(function() task.wait(0.2); buildESP(pl) end)
        return
    end
    local hl = Instance.new("Highlight")
    hl.Name = "VP_HL"
    hl.FillColor = CFG.TeamColors and teamColor(pl) or CFG.ESPFillColor
    hl.OutlineColor = CFG.TeamColors and teamColor(pl) or CFG.ESPOutlineColor
    hl.FillTransparency = CFG.ESPFillTransparency
    hl.OutlineTransparency = CFG.ESPOutlineTransparency
    hl.DepthMode = CFG.WallHack and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    hl.Adornee = ch
    hl.Enabled = CFG.PlayerESP
    hl.Parent = ch
    espHighlights[pl] = hl

    local ch2 = Instance.new("Highlight")
    ch2.Name = "VP_Chams"
    ch2.FillColor = CFG.ChamsColor
    ch2.OutlineColor = CFG.ChamsColor
    ch2.FillTransparency = 0.5
    ch2.OutlineTransparency = 1
    ch2.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    ch2.Adornee = ch
    ch2.Enabled = CFG.ChamsESP
    ch2.Parent = ch
    chamsHighlights[pl] = ch2
end

local function refreshHighlights()
    for pl, hl in pairs(espHighlights) do
        if not pl.Parent then
            if hl.Parent then hl:Destroy() end
            espHighlights[pl] = nil
            if chamsHighlights[pl] then
                if chamsHighlights[pl].Parent then chamsHighlights[pl]:Destroy() end
                chamsHighlights[pl] = nil
            end
        else
            local d = dist(pl)
            local within = d <= CFG.ESPMaxDist and isAlive(pl)
            hl.Enabled = CFG.PlayerESP and within
            if hl.Enabled then
                hl.FillColor = CFG.TeamColors and teamColor(pl) or CFG.ESPFillColor
                hl.OutlineColor = CFG.TeamColors and teamColor(pl) or CFG.ESPOutlineColor
                hl.FillTransparency = CFG.ESPFillTransparency
                hl.OutlineTransparency = CFG.ESPOutlineTransparency
                hl.DepthMode = CFG.WallHack and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            end
            local chl = chamsHighlights[pl]
            if chl and chl.Parent then
                chl.FillColor = CFG.ChamsColor
                chl.OutlineColor = CFG.ChamsColor
                chl.Enabled = CFG.ChamsESP and within
            end
        end
    end
end

-- 5.9 BILLBOARD TAGS
local tagFolder = Instance.new("Folder")
tagFolder.Name = "VP_Tags"
tagFolder.Parent = workspace

local function buildTag(pl)
    if pl == lp then return end
    local existing = tagFolder:FindFirstChild(pl.Name)
    if existing then existing:Destroy() end
    local ch = chr(pl)
    if not ch then return end
    local r = root(pl)
    if not r then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = pl.Name
    bb.Adornee = r
    bb.Size = UDim2.new(0, 140, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.Enabled = false
    bb.Parent = tagFolder
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Name = "NameLbl"
    nameLbl.BackgroundTransparency = 1
    nameLbl.Size = UDim2.new(1, 0, 0, 16)
    nameLbl.Font = FONT_BOLD
    nameLbl.TextSize = 13
    nameLbl.TextColor3 = C.text
    nameLbl.TextStrokeTransparency = 0.4
    nameLbl.Text = pl.Name
    nameLbl.Parent = bb
    local infoLbl = Instance.new("TextLabel")
    infoLbl.Name = "InfoLbl"
    infoLbl.BackgroundTransparency = 1
    infoLbl.Size = UDim2.new(1, 0, 0, 14)
    infoLbl.Position = UDim2.new(0, 0, 0, 16)
    infoLbl.Font = FONT
    infoLbl.TextSize = 11
    infoLbl.TextColor3 = C.text
    infoLbl.TextStrokeTransparency = 0.4
    infoLbl.Text = ""
    infoLbl.Parent = bb
    local barBg = Instance.new("Frame")
    barBg.Name = "BarBg"
    barBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    barBg.BackgroundTransparency = 0.35
    barBg.BorderSizePixel = 0
    barBg.Size = UDim2.fromOffset(100, 6)
    barBg.Position = UDim2.new(0.5, -50, 1, -8)
    barBg.Parent = bb
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)
    local barFill = Instance.new("Frame")
    barFill.Name = "BarFill"
    barFill.AnchorPoint = Vector2.new(0, 0.5)
    barFill.Position = UDim2.new(0, 0, 0.5, 0)
    barFill.Size = UDim2.new(1, 0, 1, 0)
    barFill.BackgroundColor3 = C.ok
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)
end

local function updateBillboardTags()
    for _, bb in ipairs(tagFolder:GetChildren()) do
        local pl = Players:FindFirstChild(bb.Name)
        if not pl or pl == lp then bb:Destroy(); continue end
        local r = root(pl)
        if not r then bb.Enabled = false; continue end
        local h = hum(pl)
        local d = dist(pl)
        local inRange = d <= CFG.ESPMaxDist
        local show = inRange and (CFG.NameESP or CFG.HealthESP or CFG.DistanceESP) and isAlive(pl)
        bb.Enabled = show
        if show then
            bb.Adornee = r
            local nameLbl = bb:FindFirstChild("NameLbl")
            if nameLbl then
                nameLbl.Visible = CFG.NameESP
                nameLbl.TextColor3 = CFG.TeamColors and teamColor(pl) or C.text
            end
            local infoLbl = bb:FindFirstChild("InfoLbl")
            if infoLbl then
                local parts = {}
                if CFG.DistanceESP then table.insert(parts, string.format("%.0fm", d)) end
                infoLbl.Text = table.concat(parts, "  ·  ")
                infoLbl.Visible = #parts > 0
            end
            local barBg = bb:FindFirstChild("BarBg")
            if barBg then
                barBg.Visible = CFG.HealthESP
                if CFG.HealthESP and h then
                    local pct = math.clamp(h.Health / h.MaxHealth, 0, 1)
                    local r2, g2
                    if pct > 0.5 then r2 = (1 - pct) * 2; g2 = 1
                    else r2 = 1; g2 = pct * 2 end
                    local fill = barBg:FindFirstChild("BarFill")
                    if fill then
                        fill.Size = UDim2.new(pct, 0, 1, 0)
                        fill.BackgroundColor3 = Color3.new(r2, g2, 0)
                    end
                end
            end
        end
    end
end

-- 5.10 BOX ESP via BillboardGui (one frame per player)
local boxFolder = Instance.new("Folder")
boxFolder.Name = "VP_Boxes"
boxFolder.Parent = workspace

local function getBox(pl)
    local existing = boxFolder:FindFirstChild(pl.Name)
    if existing then return existing end
    local r = root(pl)
    if not r then return nil end
    local bb = Instance.new("BillboardGui")
    bb.Name = pl.Name
    bb.Adornee = r
    bb.Size = UDim2.new(0, 100, 0, 100)
    bb.StudsOffset = Vector3.new(0, 0, 0)
    bb.AlwaysOnTop = true
    bb.Enabled = false
    bb.Parent = boxFolder
    local f = Instance.new("Frame")
    f.Name = "BoxFrame"
    f.BackgroundTransparency = 1
    f.Size = UDim2.fromScale(1, 1)
    f.Parent = bb
    local stroke = Instance.new("UIStroke")
    stroke.Name = "BoxStroke"
    stroke.Color = CFG.BoxESPColor
    stroke.Thickness = 1.5
    stroke.Transparency = 0
    stroke.Parent = f
    return bb
end

local function updateBoxes()
    for _, bb in ipairs(boxFolder:GetChildren()) do
        local pl = Players:FindFirstChild(bb.Name)
        if not pl or pl == lp or not CFG.BoxESP or not isAlive(pl) or dist(pl) > CFG.ESPMaxDist then
            bb.Enabled = false
            continue
        end
        local ch = chr(pl)
        if not ch then bb.Enabled = false; continue end
        -- Compute 8-corner bounding box across all BaseParts
        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        local any = false
        for _, part in ipairs(ch:GetChildren()) do
            if part:IsA("BasePart") then
                local a, b, c, d = getHitboxScreenBounds(part)
                if a then
                    any = true
                    if a < minX then minX = a end
                    if b < minY then minY = b end
                    if c > maxX then maxX = c end
                    if d > maxY then maxY = d end
                end
            end
        end
        if not any then bb.Enabled = false; continue end
        local vp = cam.ViewportSize
        local w = maxX - minX
        local h = maxY - minY
        local cx = (minX + maxX) / 2
        local cy = (minY + maxY) / 2
        bb.Size = UDim2.fromOffset(w, h)
        bb.StudsOffsetWorldSpace = Vector3.new(0, 0, 0)
        bb.Enabled = true
        -- Position is handled by adornee + offset; billboard centers on adornee, so
        -- a Frame sized to the projected box approximates well enough for on-screen
        local f = bb:FindFirstChild("BoxFrame")
        if f then
            local stroke = f:FindFirstChild("BoxStroke")
            if stroke then
                stroke.Color = CFG.BoxESPColor
                stroke.Thickness = 1.5
            end
        end
    end
end

-- 5.11 TRACER ESP via ScreenGui frame
local tracerGui = Instance.new("ScreenGui")
tracerGui.Name = "VP_Tracers"
tracerGui.ResetOnSpawn = false
tracerGui.IgnoreGuiInset = true
tracerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
do
    local hui = safeGetHui()
    if hui then tracerGui.Parent = hui else tracerGui.Parent = lp:WaitForChild("PlayerGui") end
end

local tracers = {}
local function getTracer(pl)
    if tracers[pl] and tracers[pl].Parent then return tracers[pl] end
    local f = Instance.new("Frame")
    f.Name = "T_" .. pl.Name
    f.AnchorPoint = Vector2.new(0.5, 0)
    f.BackgroundColor3 = CFG.TracerColor
    f.BorderSizePixel = 0
    f.Size = UDim2.new(0, 1, 0, 1)
    f.ZIndex = 999
    f.Parent = tracerGui
    tracers[pl] = f
    return f
end

local function tracerOriginScreen()
    local vp = cam.ViewportSize
    if CFG.TracerOrigin == "Bottom" then return Vector2.new(vp.X / 2, vp.Y) end
    if CFG.TracerOrigin == "Center" then return Vector2.new(vp.X / 2, vp.Y / 2) end
    if CFG.TracerOrigin == "Top" then return Vector2.new(vp.X / 2, 0) end
    if CFG.TracerOrigin == "Mouse" then
        local mp = UserInputService:GetMouseLocation()
        return Vector2.new(mp.X, mp.Y)
    end
    return Vector2.new(vp.X / 2, vp.Y)
end

local function updateTracers()
    local seen = {}
    if not CFG.TracerESP then
        for _, f in pairs(tracers) do
            if f.Parent then f.Visible = false end
        end
        return
    end
    local origin = tracerOriginScreen()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == lp then continue end
        if isTeammate(pl) then continue end
        if not isAlive(pl) then continue end
        if dist(pl) > CFG.ESPMaxDist then continue end
        local r = root(pl)
        if not r then continue end
        local sp, vis = cam:WorldToViewportPoint(r.Position)
        if not vis or sp.Z < 0 then
            local f = tracers[pl]
            if f then f.Visible = false end
            continue
        end
        local to = Vector2.new(sp.X, sp.Y)
        local delta = to - origin
        local length = delta.Magnitude
        local angle = math.deg(math.atan2(delta.Y, delta.X)) + 90
        local f = getTracer(pl)
        f.Position = UDim2.fromOffset(origin.X, origin.Y)
        f.Size = UDim2.fromOffset(CFG.TracerThickness, length)
        f.Rotation = angle
        f.BackgroundColor3 = CFG.TracerColor
        f.Visible = true
        seen[pl] = true
    end
    for pl, f in pairs(tracers) do
        if not seen[pl] and f.Parent then f.Visible = false end
        if not pl.Parent then f:Destroy(); tracers[pl] = nil end
    end
end

-- 5.12 SKELETON ESP via BillboardGui lines
local skeletonFolder = Instance.new("Folder")
skeletonFolder.Name = "VP_Skeletons"
skeletonFolder.Parent = workspace

local BONES_R15 = {
    {"Head","UpperTorso"},
    {"UpperTorso","LowerTorso"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"UpperTorso","LeftUpperArm"},  {"LeftUpperArm","LeftLowerArm"},   {"LeftLowerArm","LeftHand"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
    {"LowerTorso","LeftUpperLeg"},  {"LeftUpperLeg","LeftLowerLeg"},   {"LeftLowerLeg","LeftFoot"},
}
local BONES_R6 = {
    {"Head","Torso"},
    {"Torso","Right Arm"}, {"Right Arm","Right Leg"},
    {"Torso","Left Arm"},  {"Left Arm","Left Leg"},
    {"Torso","Right Leg"}, {"Torso","Left Leg"},
}

local function getSkeleton(pl)
    local existing = skeletonFolder:FindFirstChild(pl.Name)
    if existing then return existing end
    local ch = chr(pl)
    if not ch then return nil end
    local isR15 = ch:FindFirstChild("UpperTorso") ~= nil
    local bones = isR15 and BONES_R15 or BONES_R6
    local bb = Instance.new("BillboardGui")
    bb.Name = pl.Name
    bb.Adornee = root(pl) or ch:FindFirstChild("Torso") or ch:FindFirstChild("Head")
    bb.Size = UDim2.new(0, 500, 0, 500)
    bb.StudsOffset = Vector3.new(0, 0, 0)
    bb.AlwaysOnTop = true
    bb.Enabled = false
    bb.Parent = skeletonFolder
    for i, pair in ipairs(bones) do
        local line = Instance.new("Frame")
        line.Name = "bone_" .. i
        line.AnchorPoint = Vector2.new(0.5, 0)
        line.BackgroundColor3 = CFG.SkeletonColor
        line.BorderSizePixel = 0
        line.ZIndex = 2
        line.Visible = false
        line.Parent = bb
    end
    return bb
end

local function updateSkeletons()
    for _, bb in ipairs(skeletonFolder:GetChildren()) do
        local pl = Players:FindFirstChild(bb.Name)
        if not pl or pl == lp or not CFG.SkeletonESP or isTeammate(pl) or not isAlive(pl) or dist(pl) > CFG.ESPMaxDist then
            bb.Enabled = false
            continue
        end
        local ch = chr(pl)
        if not ch then bb.Enabled = false; continue end
        local r = root(pl)
        if r then bb.Adornee = r end
        local isR15 = ch:FindFirstChild("UpperTorso") ~= nil
        local bones = isR15 and BONES_R15 or BONES_R6
        bb.Enabled = true
        for i, pair in ipairs(bones) do
            local line = bb:FindFirstChild("bone_" .. i)
            if not line then break end
            local a = ch:FindFirstChild(pair[1])
            local b = ch:FindFirstChild(pair[2])
            if a and b then
                local sp1, v1 = cam:WorldToViewportPoint(a.Position)
                local sp2, v2 = cam:WorldToViewportPoint(b.Position)
                if v1 and v2 and sp1.Z > 0 and sp2.Z > 0 then
                    local bbAbs = bb.AbsolutePosition
                    local p1 = Vector2.new(sp1.X - bbAbs.X, sp1.Y - bbAbs.Y)
                    local p2 = Vector2.new(sp2.X - bbAbs.X, sp2.Y - bbAbs.Y)
                    local delta = p2 - p1
                    local length = delta.Magnitude
                    local angle = math.deg(math.atan2(delta.Y, delta.X)) + 90
                    line.Position = UDim2.fromOffset(p1.X, p1.Y)
                    line.Size = UDim2.fromOffset(1.5, length)
                    line.Rotation = angle
                    line.BackgroundColor3 = CFG.SkeletonColor
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
    end
end

-- 5.13 ITEM ESP (perf-safe)
local itemFolder = Instance.new("Folder")
itemFolder.Name = "VP_Items"
itemFolder.Parent = workspace
local itemHighlights = {}

local function refreshItemESP()
    if not (CFG.ItemESP or CFG.WeaponESP or CFG.KeycardESP) then
        for inst, hl in pairs(itemHighlights) do
            if hl.Parent then hl:Destroy() end
            itemHighlights[inst] = nil
        end
        return
    end
    local r = root(lp)
    if not r then return end
    local tracked = {}
    for _, d in ipairs(workspace:GetChildren()) do
        if d:IsA("Tool") and d:FindFirstChild("Handle") then
            tracked[d] = true
            local nm = d.Name:lower()
            local isKey = nm:find("keycard") ~= nil
            local isWeapon = false
            for _, w in ipairs(WEAPON_KEYWORDS) do
                if nm:find(w, 1, true) then isWeapon = true; break end
            end
            local want = CFG.ItemESP or (CFG.WeaponESP and isWeapon) or (CFG.KeycardESP and isKey)
            local within = (d.Handle.Position - r.Position).Magnitude <= CFG.ItemESPMaxDist
            if want and within then
                if not itemHighlights[d] or not itemHighlights[d].Parent then
                    local hl = Instance.new("Highlight")
                    hl.FillColor = isKey and Color3.fromRGB(251, 191, 36) or C.accent
                    hl.OutlineColor = isKey and Color3.fromRGB(251, 191, 36) or C.accent
                    hl.FillTransparency = 0.6
                    hl.Adornee = d
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = d
                    itemHighlights[d] = hl
                end
            else
                if itemHighlights[d] then
                    itemHighlights[d]:Destroy()
                    itemHighlights[d] = nil
                end
            end
        end
    end
    for inst, hl in pairs(itemHighlights) do
        if not tracked[inst] or not inst.Parent then
            if hl.Parent then hl:Destroy() end
            itemHighlights[inst] = nil
        end
    end
end

-- ============================================================================
-- 5.14 FLY
-- ============================================================================
local _flyBV, _flyBG, _flyConn
local function stopFly()
    if _flyConn then _flyConn:Disconnect(); _flyConn = nil end
    if _flyBV and _flyBV.Parent then _flyBV:Destroy(); _flyBV = nil end
    if _flyBG and _flyBG.Parent then _flyBG:Destroy(); _flyBG = nil end
    local h = hum(lp)
    if h then h.PlatformStand = false end
end

local function startFly()
    stopFly()
    local ch = chr(lp)
    local r = root(lp)
    local h = hum(lp)
    if not ch or not r or not h then notify("Fly: no character", "err"); return end
    local mode = CFG.FlyMode or "Head"
    if mode == "CFrame" then
        h.PlatformStand = true
        _flyConn = RunService.Heartbeat:Connect(function()
            if not CFG.Fly then stopFly(); return end
            local ch2 = chr(lp)
            if not ch2 then return end
            local hd = ch2:FindFirstChild("Head")
            if not hd then return end
            local dir = Vector3.zero
            local cf = cam.CFrame
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end
            local move = dir.Magnitude > 0 and dir.Unit * (CFG.FlySpeed / 60) or Vector3.zero
            hd.CFrame = hd.CFrame + move
        end)
    else
        local parentPart = (mode == "HRP") and r or ch:FindFirstChild("Head")
        if not parentPart then parentPart = r end
        h.PlatformStand = true
        _flyBV = Instance.new("BodyVelocity")
        _flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        _flyBV.Velocity = Vector3.zero
        _flyBV.Parent = parentPart
        _flyBG = Instance.new("BodyGyro")
        _flyBG.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
        _flyBG.D = 100
        _flyBG.CFrame = parentPart.CFrame
        _flyBG.Parent = parentPart
        _flyConn = RunService.RenderStepped:Connect(function()
            if not CFG.Fly then stopFly(); return end
            local ch2 = chr(lp)
            if not ch2 then return end
            local r2 = ch2:FindFirstChild("HumanoidRootPart")
            if not r2 then return end
            local dir = Vector3.zero
            local cf = cam.CFrame
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end
            if dir.Magnitude > 0 then
                _flyBV.Velocity = dir.Unit * CFG.FlySpeed
                _flyBG.CFrame = CFrame.new(r2.Position, r2.Position + dir)
            else
                _flyBV.Velocity = Vector3.zero
            end
        end)
    end
    notify("Fly ON  ·  " .. mode, "ok")
end

_G._VP_restartFly = function()
    if CFG.Fly then startFly() else stopFly() end
end

-- React to ResetCharacterMass: reattach body movers if fly is on
do
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    local massReset = r and r:FindFirstChild("ResetCharacterMass")
    if massReset then
        massReset.OnClientEvent:Connect(function()
            if CFG.Fly then
                task.wait(0.1)
                _G._VP_restartFly()
            end
        end)
    end
end

-- ============================================================================
-- 5.15 NOCLIP
-- ============================================================================
RunService.Stepped:Connect(function()
    if not CFG.Noclip then return end
    local ch = chr(lp)
    if not ch then return end
    for _, p in ipairs(ch:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

-- ============================================================================
-- 5.16 SPEED + INF JUMP (with proper off-state)
-- ============================================================================
RunService.Stepped:Connect(function()
    local h = hum(lp)
    if not h then return end
    if CFG.SpeedEnabled then
        if h.WalkSpeed ~= CFG.Speed then h.WalkSpeed = CFG.Speed end
    else
        if h.WalkSpeed ~= 16 and h.WalkSpeed ~= 0 then h.WalkSpeed = 16 end
    end
    if CFG.InfJump then
        if h.JumpPower ~= CFG.JumpPower then h.JumpPower = CFG.JumpPower end
    end
end)

-- ============================================================================
-- 5.17 INFINITE JUMP
-- ============================================================================
UserInputService.JumpRequest:Connect(function()
    if not CFG.InfJump then return end
    local h = hum(lp)
    if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- ============================================================================
-- 5.18 SUPER JUMP
-- ============================================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Space and CFG.SuperJump then
        local h = hum(lp)
        if h then
            h.JumpPower = CFG.SuperJumpPower
            task.delay(0.15, function()
                if h and h.Parent then h.JumpPower = 50 end
            end)
        end
    end
end)

-- ============================================================================
-- 5.19 SLOW FALL
-- ============================================================================
RunService.Heartbeat:Connect(function()
    if not CFG.SlowFall then return end
    local h = hum(lp)
    if not h or not root(lp) then return end
    if h:GetState() == Enum.HumanoidStateType.Freefall and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        local r = root(lp)
        r.Velocity = Vector3.new(r.Velocity.X, -CFG.SlowFallSpeed, r.Velocity.Z)
    end
end)

-- ============================================================================
-- 5.20 BUNNY HOP
-- ============================================================================
RunService.Heartbeat:Connect(function()
    if not CFG.BunnyHop then return end
    local h = hum(lp)
    if not h then return end
    if h:GetState() == Enum.HumanoidStateType.Landed then
        h:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ============================================================================
-- 5.21 INFINITE STAMINA (fast path via ServerVariables.Sprint.Stamina)
-- ============================================================================
RunService.Heartbeat:Connect(function()
    if not CFG.InfStamina then return end
    local sv = lp:FindFirstChild("ServerVariables")
    local sprint = sv and sv:FindFirstChild("Sprint")
    local stam = sprint and sprint:FindFirstChild("Stamina")
    local maxS = sprint and sprint:FindFirstChild("MaxStamina")
    if stam and stam:IsA("NumberValue") then
        stam.Value = maxS and maxS.Value or math.max(stam.Value, 100)
    end
end)

-- ============================================================================
-- 5.22 HITBOX EXPANSION (virtualized)
-- ============================================================================
local origSizes = {}
RunService.Heartbeat:Connect(function()
    if not CFG.HitboxExpand then
        for pt, sz in pairs(origSizes) do
            if pt.Parent then pt.Size = sz end
            origSizes[pt] = nil
        end
        return
    end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == lp then continue end
        local ch = chr(pl)
        if not ch then continue end
        for _, pt in ipairs(ch:GetChildren()) do
            if pt:IsA("BasePart") and pt.Name ~= "HumanoidRootPart" then
                if not origSizes[pt] then origSizes[pt] = pt.Size end
                pt.Size = Vector3.new(CFG.HitboxSize, CFG.HitboxSize, CFG.HitboxSize)
            end
        end
    end
end)

-- ============================================================================
-- 5.23 GOD MODE (client-side only — server authoritative)
-- ============================================================================
local _godConn
local function hookGodMode(on)
    if _godConn then _godConn:Disconnect(); _godConn = nil end
    if on then
        local h = hum(lp)
        if h then
            _godConn = h.HealthChanged:Connect(function()
                if CFG.GodMode or CFG.InfHealth then h.Health = h.MaxHealth end
            end)
        end
    end
end
RunService.Heartbeat:Connect(function()
    if not (CFG.GodMode or CFG.InfHealth) then return end
    local h = hum(lp)
    if h and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
end)

-- ============================================================================
-- 5.24 TRIGGERBOT (8-corner bounds)
-- ============================================================================
_G._VP_lastTrig = 0
RunService.Heartbeat:Connect(function()
    if not CFG.Triggerbot then return end
    local now = tick()
    if now - _G._VP_lastTrig < CFG.TriggerbotDelay then return end
    local vp = cam.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == lp then continue end
        if CFG.AimbotTeamCheck and isTeammate(pl) then continue end
        if not isAlive(pl) then continue end
        if dist(pl) > CFG.ESPMaxDist then continue end
        local ch = chr(pl)
        if not ch then continue end
        for _, part in ipairs(ch:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                if not hasLineOfSight(part) then continue end
                local minX, minY, maxX, maxY = getHitboxScreenBounds(part)
                if minX and cx >= minX and cx <= maxX and cy >= minY and cy <= maxY then
                    _G._VP_lastTrig = now
                    local tool = chr(lp) and chr(lp):FindFirstChildOfClass("Tool")
                    if tool then
                        for _, re in ipairs(tool:GetDescendants()) do
                            if re:IsA("RemoteEvent") then
                                pcall(function() re:FireServer(part, part.Position, Vector3.zero) end)
                                break
                            end
                        end
                    end
                    return
                end
            end
        end
    end
end)

-- ============================================================================
-- 5.25 NO SPREAD (ServerVariables.Cursor.Inaccuracy)
-- ============================================================================
RunService.Heartbeat:Connect(function()
    if not CFG.NoSpread then return end
    local sv = lp:FindFirstChild("ServerVariables")
    local cur = sv and sv:FindFirstChild("Cursor")
    local inacc = cur and cur:FindFirstChild("Inaccuracy")
    if inacc and inacc:IsA("NumberValue") and inacc.Value > 0 then
        inacc.Value = 0
    end
end)

-- ============================================================================
-- 5.26 FULLBRIGHT (with explicit restore callback)
-- ============================================================================
local _origLighting = {}
local _fbApplied = false
_G._VP_restoreLighting = function()
    if not _fbApplied then return end
    for k, v in pairs(_origLighting) do Lighting[k] = v end
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere") or v:IsA("BlurEffect") then v.Enabled = true end
    end
    _fbApplied = false
end
RunService.Heartbeat:Connect(function()
    if CFG.Fullbright and not _fbApplied then
        _origLighting.Brightness = Lighting.Brightness
        _origLighting.ClockTime = Lighting.ClockTime
        _origLighting.FogEnd = Lighting.FogEnd
        _origLighting.FogStart = Lighting.FogStart
        Lighting.Brightness = 10
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.FogStart = 99999
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") or v:IsA("BlurEffect") then v.Enabled = false end
        end
        _fbApplied = true
    end
    if CFG.NoFog then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 99999
    end
    if CFG.TimeOfDay then Lighting.ClockTime = CFG.TimeValue end
end)

-- ============================================================================
-- 5.27 THIRD PERSON
-- ============================================================================
local _tpConn
RunService.RenderStepped:Connect(function()
    if not CFG.ThirdPerson then return end
    if _tpConn then return end
    cam.CameraType = Enum.CameraType.Scriptable
    _tpConn = RunService.RenderStepped:Connect(function()
        if not CFG.ThirdPerson then
            cam.CameraType = Enum.CameraType.Custom
            if _tpConn then _tpConn:Disconnect(); _tpConn = nil end
            return
        end
        local r = root(lp)
        if not r then return end
        local d = CFG.ThirdPersonDist
        local camPos = r.Position - r.CFrame.LookVector * d + Vector3.new(0, d * 0.4, 0)
        cam.CFrame = CFrame.new(camPos, r.Position + Vector3.new(0, 1.5, 0))
    end)
end)

-- ============================================================================
-- 5.28 ZOOM
-- ============================================================================
RunService.RenderStepped:Connect(function()
    if CFG.ZoomHack then cam.FieldOfView = CFG.ZoomFOV end
end)

-- ============================================================================
-- 5.29 RAINBOW / INVIS / CUSTOM CHAR COLOR (with restore)
-- ============================================================================
_G._VP_restoreCharTransparency = function()
    local ch = chr(lp)
    if not ch then return end
    for _, p in ipairs(ch:GetDescendants()) do
        if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end
    end
end
RunService.RenderStepped:Connect(function()
    local ch = chr(lp)
    if not ch then return end
    if CFG.RainbowCharacter then
        local hue = (tick() * 0.5) % 1
        local col = Color3.fromHSV(hue, 1, 1)
        for _, p in ipairs(ch:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Color = col end
        end
    end
    if CFG.InvisibleCharacter then
        for _, p in ipairs(ch:GetDescendants()) do
            if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 end
        end
    end
    if CFG.CustomCharColor and not CFG.RainbowCharacter then
        for _, p in ipairs(ch:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Color = CFG.CharColor end
        end
    end
end)

-- ============================================================================
-- 5.30 TP TO CURSOR
-- ============================================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not CFG.TpToCursor then return end
    if input.KeyCode == CFG.TpToCursorKey then
        local m = UserInputService:GetMouseLocation()
        local ray = cam:ViewportPointToRay(m.X, m.Y)
        local params = getSharedRayParams(nil)
        local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
        if hit then
            local r = root(lp)
            if r then r.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0)) end
        end
    end
end)

-- ============================================================================
-- 5.31 ANTI-GRAVITY
-- ============================================================================
RunService.Heartbeat:Connect(function()
    if CFG.AntiGravity and workspace.Gravity ~= CFG.GravityValue then
        workspace.Gravity = CFG.GravityValue
    end
end)

-- ============================================================================
-- 5.32 CUFF AUTO-ESCAPE
-- ============================================================================
local _cuffConn
task.spawn(function()
    while true do
        task.wait(1.0)
        if _cuffConn then _cuffConn:Disconnect(); _cuffConn = nil end
        if not CFG.AutoEscapeCuffs then
            -- idle
        else
            _cuffConn = RunService.Heartbeat:Connect(function()
                local sv = lp:FindFirstChild("ServerVariables")
                local hc = sv and sv:FindFirstChild("Handcuffs")
                local cuffed = hc and hc:FindFirstChild("Cuffed")
                if cuffed and cuffed:IsA("BoolValue") and cuffed.Value then
                    -- break welds on character
                    local ch = chr(lp)
                    if ch then
                        for _, d in ipairs(ch:GetDescendants()) do
                            if d:IsA("WeldConstraint") or d:IsA("Weld") then
                                local nm = (d.Name or ""):lower()
                                local parentNm = (d.Parent and d.Parent.Name or ""):lower()
                                if nm:find("cuff") or parentNm:find("cuff") then
                                    pcall(function() d:Destroy() end)
                                end
                            end
                        end
                    end
                    -- fire release remote
                    local r = ReplicatedStorage:FindFirstChild("Remotes")
                    local cs = r and r:FindFirstChild("CuffsSystem")
                    local release = cs and cs:FindFirstChild("ReleaseTarget")
                    if release then
                        pcall(function() release:FireServer(lp) end)
                    end
                end
            end)
            task.wait(2.0)
        end
    end
end)

-- ============================================================================
-- SECTION 7 — LIFECYCLE
-- ============================================================================
lp.CharacterAdded:Connect(function()
    task.wait(0.5)
    hookGodMode(CFG.GodMode or CFG.InfHealth)
    if CFG.Fly then _G._VP_restartFly() end
    local h = hum(lp)
    if h and CFG.SpeedEnabled then h.WalkSpeed = CFG.Speed end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= lp then
            buildESP(pl)
            buildTag(pl)
            getSkeleton(pl)
            getBox(pl)
        end
    end
    notify("Respawned", "info")
end)

Players.PlayerAdded:Connect(function(pl)
    pl.CharacterAdded:Connect(function()
        task.wait(0.3)
        buildESP(pl)
        buildTag(pl)
        getSkeleton(pl)
        getBox(pl)
    end)
    buildESP(pl)
    buildTag(pl)
    getSkeleton(pl)
    getBox(pl)
end)

Players.PlayerRemoving:Connect(function(pl)
    if espHighlights[pl] then
        if espHighlights[pl].Parent then espHighlights[pl]:Destroy() end
        espHighlights[pl] = nil
    end
    if chamsHighlights[pl] then
        if chamsHighlights[pl].Parent then chamsHighlights[pl]:Destroy() end
        chamsHighlights[pl] = nil
    end
    local bb = tagFolder:FindFirstChild(pl.Name)
    if bb then bb:Destroy() end
    local sk = skeletonFolder:FindFirstChild(pl.Name)
    if sk then sk:Destroy() end
    local bx = boxFolder:FindFirstChild(pl.Name)
    if bx then bx:Destroy() end
    if tracers[pl] then tracers[pl]:Destroy(); tracers[pl] = nil end
    for pt, _ in pairs(origSizes) do
        if not pt.Parent then origSizes[pt] = nil end
    end
end)

for _, pl in ipairs(Players:GetPlayers()) do
    if pl ~= lp then
        buildESP(pl)
        buildTag(pl)
        getSkeleton(pl)
        getBox(pl)
    end
end

-- ============================================================================
-- SECTION 6 — MAIN RENDER LOOP
-- ============================================================================
local timers = {esp = 0, tags = 0, items = 0, box = 0, skel = 0, tracer = 0}
RunService.RenderStepped:Connect(function(dt)
    timers.esp = timers.esp + dt
    timers.tags = timers.tags + dt
    timers.items = timers.items + dt
    timers.box = timers.box + dt
    timers.skel = timers.skel + dt
    timers.tracer = timers.tracer + dt
    if timers.esp >= 0.18 then
        timers.esp = 0
        refreshHighlights()
    end
    if timers.tags >= 0.1 then
        timers.tags = 0
        updateBillboardTags()
    end
    if timers.items >= CFG.ItemESPInterval then
        timers.items = 0
        refreshItemESP()
    end
    if timers.box >= 0.05 then
        timers.box = 0
        updateBoxes()
    end
    if timers.skel >= 0.05 then
        timers.skel = 0
        updateSkeletons()
    end
    if timers.tracer >= 0.02 then
        timers.tracer = 0
        updateTracers()
    end
end)

-- ============================================================================
-- MENU TOGGLE
-- ============================================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode ~= CFG.MenuKey then return end
    CFG.Open = not CFG.Open
    if CFG.Open then
        win.Visible = true
        win.Size = UDim2.fromOffset(W, 0)
        tw(win, 0.2, {Size = UDim2.fromOffset(W, H)})
        minimized = false
        holdTab()
    else
        releaseTab()
        tw(win, 0.15, {Size = UDim2.fromOffset(W, 0)})
        task.delay(0.16, function()
            win.Visible = false
            win.Size = UDim2.fromOffset(W, H)
        end)
    end
end)

-- ============================================================================
-- SECTION 9 — INIT
-- ============================================================================
setPage("Home")
notify("NyxScript v2.2 loaded  ·  Anti-Kick active", "ok", 5)
print("[NyxScript v2.2] Valley Prison loaded. Right Shift = toggle menu.")
