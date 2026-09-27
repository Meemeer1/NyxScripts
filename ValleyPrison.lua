-- ================================================================
--  VALLEY PRISON  ·  NyxScript  ·  Premium Edition
--  Toggle: Right Shift
-- ================================================================

-- ================================================================
--  SERVICES
-- ================================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace        = workspace
local lp               = Players.LocalPlayer
local cam              = Workspace.CurrentCamera

-- ================================================================
--  CONFIG  (all feature state lives here)
-- ================================================================
local CFG = {
    -- Combat
    Aimbot          = false,
    AimbotFOV       = 150,
    AimbotSmooth    = 0.15,
    AimbotPart      = "Head",
    AimbotTeamCheck = true,
    Aimlock         = false,
    SilentAim       = false,
    Triggerbot      = false,
    TriggerbotDelay = 0.05,
    NoRecoil        = false,
    NoSpread        = false,
    HitboxExpand    = false,
    HitboxSize      = 6,

    -- ESP
    PlayerESP       = true,
    WallHack        = true,
    SkeletonESP     = false,
    NameESP         = true,
    HealthESP       = true,
    DistanceESP     = true,
    ItemESP         = false,
    WeaponESP       = false,

    -- Movement
    Speed           = 16,
    InfStamina      = false,
    InfJump         = false,
    JumpPower       = 50,
    Fly             = false,
    FlySpeed        = 60,
    Noclip          = false,

    -- Teleport
    SavedPositions  = {},   -- {name=string, cf=CFrame}

    -- Anti-Kick
    AntiKick        = false,
    AntiDisconnect  = false,

    -- GUI
    GuiOpen         = true,
    ActivePage      = "Home",
    EnabledCount    = 0,
    Notifications   = {},

    -- Spawning / Prison
    _SpawnedItems   = {},
}

-- ================================================================
--  UTILITY
-- ================================================================
local function getChar(p)   return p and p.Character end
local function getRoot(p)   local c=getChar(p); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum(p)    local c=getChar(p); return c and c:FindFirstChildOfClass("Humanoid") end
local function getHead(p)   local c=getChar(p); return c and c:FindFirstChild("Head") end

local function dist3(a, b)
    return (a - b).Magnitude
end
local function distTo(p)
    local r1 = getRoot(lp); local r2 = getRoot(p)
    if not r1 or not r2 then return math.huge end
    return dist3(r1.Position, r2.Position)
end

local function isEnemy(p)
    if not CFG.AimbotTeamCheck then return p ~= lp end
    return p ~= lp and (p.Team ~= lp.Team or p.Team == nil)
end

local function tweenProp(inst, time, props)
    TweenService:Create(inst, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function countEnabled()
    local n = 0
    local bools = {"Aimbot","Aimlock","SilentAim","Triggerbot","NoRecoil","NoSpread","HitboxExpand",
        "PlayerESP","SkeletonESP","NameESP","HealthESP","DistanceESP","ItemESP","WeaponESP",
        "InfStamina","InfJump","Fly","Noclip","AntiKick","AntiDisconnect"}
    for _, k in ipairs(bools) do if CFG[k] then n += 1 end end
    if CFG.Speed ~= 16 then n += 1 end
    CFG.EnabledCount = n
    return n
end

-- ================================================================
--  NOTIFICATION SYSTEM
-- ================================================================
local notifGui = Instance.new("ScreenGui")
notifGui.Name            = "VP_Notif"
notifGui.ResetOnSpawn    = false
notifGui.IgnoreGuiInset  = true
notifGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
notifGui.Parent          = (syn and syn.protect_gui and syn.protect_gui(notifGui)) or
    (gethui and gethui()) or lp.PlayerGui

local notifStack = Instance.new("Frame")
notifStack.Size                = UDim2.new(0, 280, 1, 0)
notifStack.Position            = UDim2.new(1, -295, 0, 0)
notifStack.BackgroundTransparency = 1
notifStack.Parent              = notifGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.VerticalAlignment  = Enum.VerticalAlignment.Bottom
notifLayout.SortOrder          = Enum.SortOrder.LayoutOrder
notifLayout.Padding            = UDim.new(0, 6)
notifLayout.Parent             = notifStack

Instance.new("UIPadding", notifStack).PaddingBottom = UDim.new(0, 12)

local notifColors = {
    info    = Color3.fromRGB(80,  120, 255),
    success = Color3.fromRGB(60,  200, 100),
    warn    = Color3.fromRGB(255, 180, 40),
    error   = Color3.fromRGB(220, 60,  60),
}

local function notify(title, msg, kind, duration)
    kind     = kind     or "info"
    duration = duration or 3.5
    local col = notifColors[kind] or notifColors.info

    local card = Instance.new("Frame")
    card.Size             = UDim2.new(1, 0, 0, 64)
    card.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
    card.BackgroundTransparency = 0.05
    card.BorderSizePixel  = 0
    card.ClipsDescendants = true
    card.Parent           = notifStack
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    -- accent bar
    local bar = Instance.new("Frame")
    bar.Size              = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3  = col
    bar.BorderSizePixel   = 0
    bar.Parent            = card

    local titleL = Instance.new("TextLabel")
    titleL.Size              = UDim2.new(1, -20, 0, 20)
    titleL.Position          = UDim2.new(0, 14, 0, 8)
    titleL.BackgroundTransparency = 1
    titleL.Text              = title
    titleL.TextColor3        = col
    titleL.Font              = Enum.Font.GothamBold
    titleL.TextSize          = 13
    titleL.TextXAlignment    = Enum.TextXAlignment.Left
    titleL.Parent            = card

    local msgL = Instance.new("TextLabel")
    msgL.Size                = UDim2.new(1, -20, 0, 28)
    msgL.Position            = UDim2.new(0, 14, 0, 28)
    msgL.BackgroundTransparency = 1
    msgL.Text                = msg
    msgL.TextColor3          = Color3.fromRGB(180, 180, 195)
    msgL.Font                = Enum.Font.Gotham
    msgL.TextSize            = 12
    msgL.TextXAlignment      = Enum.TextXAlignment.Left
    msgL.TextWrapped         = true
    msgL.Parent              = card

    -- progress bar
    local prog = Instance.new("Frame")
    prog.Size             = UDim2.new(1, 0, 0, 2)
    prog.Position         = UDim2.new(0, 0, 1, -2)
    prog.BackgroundColor3 = col
    prog.BorderSizePixel  = 0
    prog.Parent           = card

    -- slide in
    card.Position = UDim2.new(1, 10, 0, 0)
    tweenProp(card, 0.25, {Position = UDim2.new(0, 0, 0, 0)})
    tweenProp(prog, duration, {Size = UDim2.new(0, 0, 0, 2)})

    task.delay(duration, function()
        tweenProp(card, 0.2, {Position = UDim2.new(1, 10, 0, 0)})
        task.wait(0.22)
        card:Destroy()
    end)
end

-- ================================================================
--  GUI  – MAIN WINDOW
-- ================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "VP_Main"
screenGui.ResetOnSpawn    = false
screenGui.IgnoreGuiInset  = true
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Parent          = (syn and syn.protect_gui and syn.protect_gui(screenGui)) or
    (gethui and gethui()) or lp.PlayerGui

-- Dim overlay (behind window)
local overlay = Instance.new("Frame")
overlay.Size                  = UDim2.new(1,0,1,0)
overlay.BackgroundColor3      = Color3.new(0,0,0)
overlay.BackgroundTransparency = 0.55
overlay.BorderSizePixel        = 0
overlay.ZIndex                 = 1
overlay.Parent                 = screenGui

-- Main window
local WIN_W, WIN_H = 740, 500
local window = Instance.new("Frame")
window.Name                = "Window"
window.Size                = UDim2.new(0, WIN_W, 0, WIN_H)
window.Position            = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
window.BackgroundColor3    = Color3.fromRGB(10, 10, 18)
window.BackgroundTransparency = 0.08
window.BorderSizePixel     = 0
window.ClipsDescendants    = true
window.ZIndex              = 2
window.Parent              = screenGui
Instance.new("UICorner", window).CornerRadius = UDim.new(0, 12)

-- Glass border
local border = Instance.new("UIStroke")
border.Color        = Color3.fromRGB(255, 255, 255)
border.Transparency = 0.88
border.Thickness    = 1
border.Parent       = window

-- Glass gradient
local winGrad = Instance.new("UIGradient")
winGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 16, 40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 18)),
})
winGrad.Rotation = 135
winGrad.Parent   = window

-- ── Title bar ──────────────────────────────────────────────────
local titleBar = Instance.new("Frame")
titleBar.Name             = "TitleBar"
titleBar.Size             = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3 = Color3.fromRGB(18, 12, 36)
titleBar.BackgroundTransparency = 0.1
titleBar.BorderSizePixel  = 0
titleBar.ZIndex           = 3
titleBar.Parent           = window

local tbGrad = Instance.new("UIGradient")
tbGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 30, 100)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 12, 36)),
})
tbGrad.Rotation = 90
tbGrad.Parent   = titleBar

-- Logo dot
local logoDot = Instance.new("Frame")
logoDot.Size             = UDim2.new(0, 10, 0, 10)
logoDot.Position         = UDim2.new(0, 14, 0.5, -5)
logoDot.BackgroundColor3 = Color3.fromRGB(130, 80, 255)
logoDot.BorderSizePixel  = 0
logoDot.ZIndex           = 4
logoDot.Parent           = titleBar
Instance.new("UICorner", logoDot).CornerRadius = UDim.new(1, 0)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size               = UDim2.new(0, 200, 1, 0)
titleLabel.Position           = UDim2.new(0, 32, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text               = "NyxScript  ·  Valley Prison"
titleLabel.TextColor3         = Color3.fromRGB(210, 190, 255)
titleLabel.Font               = Enum.Font.GothamBold
titleLabel.TextSize           = 14
titleLabel.TextXAlignment     = Enum.TextXAlignment.Left
titleLabel.ZIndex             = 4
titleLabel.Parent             = titleBar

-- Window controls
local function winBtn(x, col, label)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0, 22, 0, 22)
    b.Position         = UDim2.new(1, x, 0.5, -11)
    b.BackgroundColor3 = col
    b.Text             = label
    b.TextColor3       = Color3.new(1,1,1)
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 11
    b.BorderSizePixel  = 0
    b.ZIndex           = 4
    b.Parent           = titleBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(1,0)
    b.MouseEnter:Connect(function() tweenProp(b, 0.08, {BackgroundTransparency = 0.3}) end)
    b.MouseLeave:Connect(function() tweenProp(b, 0.08, {BackgroundTransparency = 0}) end)
    return b
end

local minimizeBtn = winBtn(-78, Color3.fromRGB(200, 160, 30), "–")
local closeBtn    = winBtn(-46, Color3.fromRGB(200, 50, 50),  "✕")

closeBtn.MouseButton1Click:Connect(function()
    tweenProp(window, 0.18, {Size = UDim2.new(0, WIN_W, 0, 0)})
    task.wait(0.2)
    window.Visible = false
    overlay.Visible = false
    CFG.GuiOpen = false
end)
minimizeBtn.MouseButton1Click:Connect(function()
    local minimized = window.Size.Y.Offset < 50
    if minimized then
        tweenProp(window, 0.2, {Size = UDim2.new(0, WIN_W, 0, WIN_H)})
    else
        tweenProp(window, 0.2, {Size = UDim2.new(0, WIN_W, 0, 44)})
    end
end)

-- Draggable
local _drag, _dragStart, _dragWinPos
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        _drag = true; _dragStart = i.Position; _dragWinPos = window.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if _drag and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - _dragStart
        window.Position = UDim2.new(
            _dragWinPos.X.Scale, _dragWinPos.X.Offset + d.X,
            _dragWinPos.Y.Scale, _dragWinPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then _drag = false end
end)

-- ── Sidebar ────────────────────────────────────────────────────
local SIDEBAR_W = 160
local sidebar = Instance.new("Frame")
sidebar.Size             = UDim2.new(0, SIDEBAR_W, 1, -44)
sidebar.Position         = UDim2.new(0, 0, 0, 44)
sidebar.BackgroundColor3 = Color3.fromRGB(12, 8, 24)
sidebar.BackgroundTransparency = 0.05
sidebar.BorderSizePixel  = 0
sidebar.ZIndex           = 3
sidebar.Parent           = window

local sbGrad = Instance.new("UIGradient")
sbGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 12, 40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 8, 20)),
})
sbGrad.Rotation = 180
sbGrad.Parent   = sidebar

local sbStroke = Instance.new("UIStroke")
sbStroke.Color = Color3.fromRGB(255,255,255); sbStroke.Transparency = 0.92
sbStroke.Thickness = 1; sbStroke.Parent = sidebar

local sbLayout = Instance.new("UIListLayout")
sbLayout.SortOrder = Enum.SortOrder.LayoutOrder
sbLayout.Padding   = UDim.new(0, 3)
sbLayout.Parent    = sidebar
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0, 10)

-- Sidebar separator
local sbSep = Instance.new("Frame")
sbSep.Size             = UDim2.new(0, 1, 1, -44)
sbSep.Position         = UDim2.new(0, SIDEBAR_W, 0, 44)
sbSep.BackgroundColor3 = Color3.fromRGB(255,255,255)
sbSep.BackgroundTransparency = 0.88
sbSep.BorderSizePixel  = 0
sbSep.ZIndex           = 3
sbSep.Parent           = window

-- ── Content area ───────────────────────────────────────────────
local content = Instance.new("ScrollingFrame")
content.Size              = UDim2.new(1, -SIDEBAR_W-1, 1, -44)
content.Position          = UDim2.new(0, SIDEBAR_W+1, 0, 44)
content.BackgroundTransparency = 1
content.ScrollBarThickness = 4
content.ScrollBarImageColor3 = Color3.fromRGB(100, 60, 200)
content.CanvasSize        = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.BorderSizePixel   = 0
content.ZIndex            = 3
content.Parent            = window

local contentPad = Instance.new("UIPadding")
contentPad.PaddingLeft   = UDim.new(0, 14)
contentPad.PaddingRight  = UDim.new(0, 14)
contentPad.PaddingTop    = UDim.new(0, 10)
contentPad.PaddingBottom = UDim.new(0, 14)
contentPad.Parent        = content

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding   = UDim.new(0, 8)
contentLayout.Parent    = content

-- ================================================================
--  GUI COMPONENT BUILDERS
-- ================================================================
local PAGES = {}       -- page frames
local SB_BTNS = {}     -- sidebar button refs

-- Clear content area and show a page
local function showPage(name)
    for n, f in pairs(PAGES) do
        f.Visible = (n == name)
    end
    CFG.ActivePage = name
    -- Update sidebar highlight
    for n, btn in pairs(SB_BTNS) do
        local active = (n == name)
        tweenProp(btn, 0.12, {
            BackgroundColor3 = active
                and Color3.fromRGB(45, 28, 80)
                or  Color3.fromRGB(0,0,0),
            BackgroundTransparency = active and 0.2 or 1,
        })
        local lbl = btn:FindFirstChildOfClass("TextLabel")
        if lbl then
            lbl.TextColor3 = active
                and Color3.fromRGB(200, 160, 255)
                or  Color3.fromRGB(140, 130, 160)
        end
    end
end

-- Sidebar nav button
local SB_ICONS = {
    Home               = "⌂",
    Combat             = "⚔",
    ESP                = "👁",
    Movement           = "🏃",
    Teleportation      = "📍",
    Spawning           = "📦",
    ["Prison System"]  = "🔐",
    ["Anti-Kick"]      = "🛡",
}

local function makeSidebarBtn(name, order)
    local btn = Instance.new("TextButton")
    btn.Name             = name
    btn.Size             = UDim2.new(1, -16, 0, 36)
    btn.Position         = UDim2.new(0, 8, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text             = ""
    btn.LayoutOrder      = order
    btn.BorderSizePixel  = 0
    btn.ZIndex           = 4
    btn.Parent           = sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    local icon = Instance.new("TextLabel")
    icon.Size               = UDim2.new(0, 24, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text               = SB_ICONS[name] or "·"
    icon.TextColor3         = Color3.fromRGB(140, 130, 160)
    icon.Font               = Enum.Font.GothamBold
    icon.TextSize           = 15
    icon.ZIndex             = 5
    icon.Parent             = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size                = UDim2.new(1, -30, 1, 0)
    lbl.Position            = UDim2.new(0, 28, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                = name
    lbl.TextColor3          = Color3.fromRGB(140, 130, 160)
    lbl.Font                = Enum.Font.Gotham
    lbl.TextSize            = 13
    lbl.TextXAlignment      = Enum.TextXAlignment.Left
    lbl.ZIndex              = 5
    lbl.Parent              = btn

    btn.MouseEnter:Connect(function()
        if CFG.ActivePage ~= name then
            tweenProp(btn, 0.1, {BackgroundTransparency = 0.7, BackgroundColor3 = Color3.fromRGB(40,25,70)})
        end
    end)
    btn.MouseLeave:Connect(function()
        if CFG.ActivePage ~= name then
            tweenProp(btn, 0.1, {BackgroundTransparency = 1})
        end
    end)
    btn.MouseButton1Click:Connect(function()
        showPage(name)
    end)
    SB_BTNS[name] = btn
end

-- Page container
local function makePage(name, order)
    local f = Instance.new("Frame")
    f.Name                 = name
    f.Size                 = UDim2.new(1, 0, 0, 0)
    f.AutomaticSize        = Enum.AutomaticSize.Y
    f.BackgroundTransparency = 1
    f.LayoutOrder          = order
    f.Visible              = false
    f.Parent               = content

    local lay = Instance.new("UIListLayout")
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Padding   = UDim.new(0, 8)
    lay.Parent    = f

    PAGES[name] = f
    return f
end

-- Section header inside a page
local function sectionHdr(page, text)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, 26)
    f.BackgroundTransparency = 1
    f.BorderSizePixel  = 0
    f.Parent           = page

    local l = Instance.new("TextLabel")
    l.Size              = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text              = text:upper()
    l.TextColor3        = Color3.fromRGB(110, 80, 180)
    l.Font              = Enum.Font.GothamBold
    l.TextSize          = 11
    l.TextXAlignment    = Enum.TextXAlignment.Left
    l.Parent            = f

    local line = Instance.new("Frame")
    line.Size             = UDim2.new(1, 0, 0, 1)
    line.Position         = UDim2.new(0, 0, 1, -1)
    line.BackgroundColor3 = Color3.fromRGB(80, 50, 140)
    line.BackgroundTransparency = 0.6
    line.BorderSizePixel  = 0
    line.Parent           = f
end

-- Card wrapper
local function card(page)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, 0)
    f.AutomaticSize    = Enum.AutomaticSize.Y
    f.BackgroundColor3 = Color3.fromRGB(16, 12, 28)
    f.BackgroundTransparency = 0.1
    f.BorderSizePixel  = 0
    f.Parent           = page
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color        = Color3.fromRGB(255,255,255)
    stroke.Transparency = 0.91
    stroke.Thickness    = 1
    stroke.Parent       = f

    local lay = Instance.new("UIListLayout")
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Padding   = UDim.new(0, 0)
    lay.Parent    = f

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft   = UDim.new(0, 12)
    pad.PaddingRight  = UDim.new(0, 12)
    pad.PaddingTop    = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent        = f

    return f
end

-- Toggle row
local function toggleRow(parent, label, desc, key, onChange)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, desc and 48 or 36)
    row.BackgroundTransparency = 1
    row.BorderSizePixel  = 0
    row.Parent           = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size              = UDim2.new(1, -56, 0, 18)
    lbl.Position          = UDim2.new(0, 0, 0, desc and 6 or 9)
    lbl.BackgroundTransparency = 1
    lbl.Text              = label
    lbl.TextColor3        = Color3.fromRGB(210, 205, 225)
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextSize          = 13
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Parent            = row

    if desc then
        local sub = Instance.new("TextLabel")
        sub.Size              = UDim2.new(1, -56, 0, 14)
        sub.Position          = UDim2.new(0, 0, 0, 26)
        sub.BackgroundTransparency = 1
        sub.Text              = desc
        sub.TextColor3        = Color3.fromRGB(110, 105, 130)
        sub.Font              = Enum.Font.Gotham
        sub.TextSize          = 11
        sub.TextXAlignment    = Enum.TextXAlignment.Left
        sub.Parent            = row
    end

    -- Toggle pill
    local pill = Instance.new("TextButton")
    pill.Size             = UDim2.new(0, 44, 0, 24)
    pill.Position         = UDim2.new(1, -44, 0.5, -12)
    pill.Text             = ""
    pill.BorderSizePixel  = 0
    pill.Parent           = row
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 18, 0, 18)
    knob.AnchorPoint      = Vector2.new(0, 0.5)
    knob.Position         = UDim2.new(0, 3, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel  = 0
    knob.Parent           = pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function setState(on)
        CFG[key] = on
        tweenProp(pill, 0.14, {
            BackgroundColor3 = on
                and Color3.fromRGB(100, 55, 220)
                or  Color3.fromRGB(40, 35, 55),
        })
        tweenProp(knob, 0.14, {
            Position = on
                and UDim2.new(1, -21, 0.5, 0)
                or  UDim2.new(0,   3, 0.5, 0),
        })
        countEnabled()
        if onChange then onChange(on) end
    end
    setState(CFG[key] or false)

    pill.MouseButton1Click:Connect(function()
        setState(not CFG[key])
    end)

    return setState
end

-- Slider row
local function sliderRow(parent, label, key, min, max, step, onChange)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 52)
    row.BackgroundTransparency = 1
    row.BorderSizePixel  = 0
    row.Parent           = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size              = UDim2.new(1, -60, 0, 18)
    lbl.Position          = UDim2.new(0, 0, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text              = label
    lbl.TextColor3        = Color3.fromRGB(200, 195, 215)
    lbl.Font              = Enum.Font.Gotham
    lbl.TextSize          = 13
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Parent            = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Size              = UDim2.new(0, 55, 0, 18)
    valLbl.Position          = UDim2.new(1, -55, 0, 4)
    valLbl.BackgroundTransparency = 1
    valLbl.Text              = tostring(CFG[key])
    valLbl.TextColor3        = Color3.fromRGB(140, 100, 240)
    valLbl.Font              = Enum.Font.GothamBold
    valLbl.TextSize          = 13
    valLbl.TextXAlignment    = Enum.TextXAlignment.Right
    valLbl.Parent            = row

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(1, 0, 0, 6)
    track.Position         = UDim2.new(0, 0, 0, 34)
    track.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
    track.BorderSizePixel  = 0
    track.Parent           = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local ratio = (CFG[key]-min) / math.max(max-min, 0.001)
    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new(ratio, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100, 55, 220)
    fill.BorderSizePixel  = 0
    fill.Parent           = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local thumb = Instance.new("Frame")
    thumb.Size             = UDim2.new(0, 14, 0, 14)
    thumb.AnchorPoint      = Vector2.new(0.5, 0.5)
    thumb.Position         = UDim2.new(ratio, 0, 0.5, 0)
    thumb.BackgroundColor3 = Color3.new(1,1,1)
    thumb.BorderSizePixel  = 0
    thumb.Parent           = track
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1,0)

    local draggingSlider = false
    local function updateSlider(x)
        local ap = track.AbsolutePosition
        local as = track.AbsoluteSize
        local t  = math.clamp((x - ap.X) / as.X, 0, 1)
        local raw = min + (max - min) * t
        local snapped = math.round(raw / step) * step
        CFG[key] = snapped
        fill.Size  = UDim2.new(t, 0, 1, 0)
        thumb.Position = UDim2.new(t, 0, 0.5, 0)
        valLbl.Text = tostring(snapped)
        if onChange then onChange(snapped) end
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
            updateSlider(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if draggingSlider and i.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end
    end)
end

-- Button
local function btnRow(parent, label, sub, fn)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, 0, 0, sub and 44 or 34)
    btn.BackgroundColor3 = Color3.fromRGB(28, 18, 54)
    btn.BackgroundTransparency = 0.1
    btn.Text             = ""
    btn.BorderSizePixel  = 0
    btn.Parent           = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local stroke2 = Instance.new("UIStroke")
    stroke2.Color = Color3.fromRGB(130,80,255); stroke2.Transparency = 0.7
    stroke2.Thickness = 1; stroke2.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size              = UDim2.new(1, -20, 0, 18)
    lbl.Position          = UDim2.new(0, 12, 0, sub and 6 or 8)
    lbl.BackgroundTransparency = 1
    lbl.Text              = label
    lbl.TextColor3        = Color3.fromRGB(190, 165, 255)
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextSize          = 13
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Parent            = btn

    if sub then
        local sl = Instance.new("TextLabel")
        sl.Size              = UDim2.new(1, -20, 0, 13)
        sl.Position          = UDim2.new(0, 12, 0, 26)
        sl.BackgroundTransparency = 1
        sl.Text              = sub
        sl.TextColor3        = Color3.fromRGB(100, 90, 120)
        sl.Font              = Enum.Font.Gotham
        sl.TextSize          = 11
        sl.TextXAlignment    = Enum.TextXAlignment.Left
        sl.Parent            = btn
    end

    btn.MouseEnter:Connect(function() tweenProp(btn, 0.1, {BackgroundColor3 = Color3.fromRGB(50,32,90), BackgroundTransparency = 0}) end)
    btn.MouseLeave:Connect(function() tweenProp(btn, 0.1, {BackgroundColor3 = Color3.fromRGB(28,18,54), BackgroundTransparency = 0.1}) end)
    btn.MouseButton1Down:Connect(function() tweenProp(btn, 0.06, {BackgroundColor3 = Color3.fromRGB(70,45,120)}) end)
    btn.MouseButton1Click:Connect(fn)
end

-- Dropdown
local function dropdownRow(parent, label, options, key, onChange)
    local container = Instance.new("Frame")
    container.Size             = UDim2.new(1, 0, 0, 36)
    container.BackgroundTransparency = 1
    container.ClipsDescendants = false
    container.BorderSizePixel  = 0
    container.Parent           = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size              = UDim2.new(0.45, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text              = label
    lbl.TextColor3        = Color3.fromRGB(200, 195, 215)
    lbl.Font              = Enum.Font.Gotham
    lbl.TextSize          = 13
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Parent            = container

    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0.52, 0, 0, 28)
    btn.Position         = UDim2.new(0.48, 0, 0.5, -14)
    btn.BackgroundColor3 = Color3.fromRGB(25, 18, 45)
    btn.BorderSizePixel  = 0
    btn.Text             = tostring(CFG[key])
    btn.TextColor3       = Color3.fromRGB(160, 120, 255)
    btn.Font             = Enum.Font.Gotham
    btn.TextSize         = 12
    btn.Parent           = container
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local stroke3 = Instance.new("UIStroke")
    stroke3.Color = Color3.fromRGB(255,255,255); stroke3.Transparency = 0.88
    stroke3.Thickness = 1; stroke3.Parent = btn

    local dropFrame = Instance.new("Frame")
    dropFrame.Size             = UDim2.new(0.52, 0, 0, 0)
    dropFrame.Position         = UDim2.new(0.48, 0, 1, 4)
    dropFrame.BackgroundColor3 = Color3.fromRGB(20, 14, 38)
    dropFrame.BorderSizePixel  = 0
    dropFrame.ClipsDescendants = true
    dropFrame.ZIndex           = 10
    dropFrame.Visible          = false
    dropFrame.Parent           = container
    Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0,6)
    local stroke4 = Instance.new("UIStroke")
    stroke4.Color = Color3.fromRGB(255,255,255); stroke4.Transparency = 0.88
    stroke4.Thickness = 1; stroke4.Parent = dropFrame

    local dLayout = Instance.new("UIListLayout")
    dLayout.SortOrder = Enum.SortOrder.LayoutOrder
    dLayout.Parent    = dropFrame

    for i, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size             = UDim2.new(1, 0, 0, 26)
        ob.BackgroundTransparency = 1
        ob.Text             = opt
        ob.TextColor3       = Color3.fromRGB(170, 155, 200)
        ob.Font             = Enum.Font.Gotham
        ob.TextSize         = 12
        ob.ZIndex           = 11
        ob.Parent           = dropFrame
        ob.MouseButton1Click:Connect(function()
            CFG[key] = opt
            btn.Text = opt
            tweenProp(dropFrame, 0.1, {Size = UDim2.new(0.52, 0, 0, 0)})
            task.wait(0.12)
            dropFrame.Visible = false
            if onChange then onChange(opt) end
        end)
        ob.MouseEnter:Connect(function() tweenProp(ob, 0.08, {BackgroundTransparency = 0.7, BackgroundColor3 = Color3.fromRGB(40,28,70)}) end)
        ob.MouseLeave:Connect(function() tweenProp(ob, 0.08, {BackgroundTransparency = 1}) end)
    end

    local totalH = #options * 26
    btn.MouseButton1Click:Connect(function()
        if dropFrame.Visible then
            tweenProp(dropFrame, 0.1, {Size = UDim2.new(0.52, 0, 0, 0)})
            task.wait(0.12); dropFrame.Visible = false
        else
            dropFrame.Visible = true
            tweenProp(dropFrame, 0.12, {Size = UDim2.new(0.52, 0, 0, totalH)})
        end
    end)
end

-- ================================================================
--  BUILD SIDEBAR + PAGES
-- ================================================================
local PAGE_NAMES = {
    "Home","Combat","ESP","Movement","Teleportation",
    "Spawning","Prison System","Anti-Kick"
}
for i, n in ipairs(PAGE_NAMES) do
    makeSidebarBtn(n, i)
    makePage(n, i)
end

-- Spacer at sidebar bottom
local sbSpacer = Instance.new("Frame")
sbSpacer.Size             = UDim2.new(1, 0, 0, 1)
sbSpacer.BackgroundTransparency = 1
sbSpacer.LayoutOrder      = 99
sbSpacer.Parent           = sidebar

-- ================================================================
--  HOME PAGE
-- ================================================================
do
    local p = PAGES["Home"]

    -- Welcome card
    local wc = card(p)
    local welc = Instance.new("TextLabel")
    welc.Size              = UDim2.new(1, 0, 0, 22)
    welc.BackgroundTransparency = 1
    welc.Text              = "Welcome back, " .. lp.Name
    welc.TextColor3        = Color3.fromRGB(200, 175, 255)
    welc.Font              = Enum.Font.GothamBold
    welc.TextSize          = 16
    welc.TextXAlignment    = Enum.TextXAlignment.Left
    welc.Parent            = wc

    local sub = Instance.new("TextLabel")
    sub.Size               = UDim2.new(1, 0, 0, 16)
    sub.BackgroundTransparency = 1
    sub.Text               = "NyxScript  ·  Valley Prison Edition  ·  All features loaded"
    sub.TextColor3         = Color3.fromRGB(100, 90, 130)
    sub.Font               = Enum.Font.Gotham
    sub.TextSize           = 12
    sub.TextXAlignment     = Enum.TextXAlignment.Left
    sub.Parent             = wc

    -- Stats row
    local statsCard = card(p)
    local statsRow = Instance.new("Frame")
    statsRow.Size             = UDim2.new(1, 0, 0, 60)
    statsRow.BackgroundTransparency = 1
    statsRow.Parent           = statsCard

    local statLayout = Instance.new("UIListLayout")
    statLayout.FillDirection = Enum.FillDirection.Horizontal
    statLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    statLayout.Padding        = UDim.new(0, 8)
    statLayout.Parent         = statsRow

    local function statBox(label, val, col)
        local f = Instance.new("Frame")
        f.Size             = UDim2.new(0.3, -4, 1, 0)
        f.BackgroundColor3 = Color3.fromRGB(22, 16, 40)
        f.BorderSizePixel  = 0
        f.Parent           = statsRow
        Instance.new("UICorner", f).CornerRadius = UDim.new(0,7)

        local v = Instance.new("TextLabel")
        v.Size              = UDim2.new(1, 0, 0, 28)
        v.Position          = UDim2.new(0, 0, 0, 8)
        v.BackgroundTransparency = 1
        v.Text              = val
        v.TextColor3        = col
        v.Font              = Enum.Font.GothamBold
        v.TextSize          = 20
        v.Parent            = f

        local l = Instance.new("TextLabel")
        l.Size              = UDim2.new(1, 0, 0, 14)
        l.Position          = UDim2.new(0, 0, 0, 38)
        l.BackgroundTransparency = 1
        l.Text              = label
        l.TextColor3        = Color3.fromRGB(100, 90, 120)
        l.Font              = Enum.Font.Gotham
        l.TextSize          = 11
        l.Parent            = f
        return v
    end

    local enabledStat = statBox("Active Features", "0",  Color3.fromRGB(120,80,255))
    local playerStat  = statBox("Players",         tostring(#Players:GetPlayers()), Color3.fromRGB(60,200,120))
    local statusStat  = statBox("Status",          "LIVE", Color3.fromRGB(60,200,100))

    -- Quick toggles
    sectionHdr(p, "Quick Toggles")
    local qc = card(p)
    toggleRow(qc, "Player ESP",      "See players through walls",  "PlayerESP")
    toggleRow(qc, "Aimbot",          "Auto-aim to nearest enemy",  "Aimbot")
    toggleRow(qc, "Speed Boost",     "Move faster than normal",    "Speed",
        function(on) CFG.Speed = on and 50 or 16 end)
    toggleRow(qc, "Infinite Stamina","Never run out of stamina",   "InfStamina")
    toggleRow(qc, "Anti-Kick",       "Prevent server kick attempts","AntiKick")

    -- Update enabled count on each render
    RunService.RenderStepped:Connect(function()
        enabledStat.Text = tostring(countEnabled())
        playerStat.Text  = tostring(#Players:GetPlayers())
    end)
end

-- ================================================================
--  COMBAT PAGE
-- ================================================================
do
    local p = PAGES["Combat"]
    sectionHdr(p, "Aimbot")
    local ac = card(p)
    toggleRow(ac, "Aimbot",        "Smooth aim towards nearest enemy",  "Aimbot")
    toggleRow(ac, "Aimlock",       "Hard-lock camera to target",        "Aimlock")
    toggleRow(ac, "Silent Aim",    "Hit without visually aiming",       "SilentAim")
    toggleRow(ac, "Triggerbot",    "Auto-fire when crosshair on enemy", "Triggerbot")
    sliderRow(ac, "FOV Radius",    "AimbotFOV",     20,  500, 10)
    sliderRow(ac, "Smoothness",    "AimbotSmooth",  0.02, 1,  0.02)
    sliderRow(ac, "Trigger Delay", "TriggerbotDelay", 0.01, 0.5, 0.01)
    dropdownRow(ac, "Aim Part", {"Head","HumanoidRootPart","UpperTorso"}, "AimbotPart")
    toggleRow(ac, "Team Check",    "Skip teammates",                    "AimbotTeamCheck")

    sectionHdr(p, "Weapon Mechanics")
    local wc = card(p)
    toggleRow(wc, "No Recoil",     "Counteract camera recoil",          "NoRecoil")
    toggleRow(wc, "No Spread",     "Remove bullet spread",              "NoSpread")
    toggleRow(wc, "Hitbox Expand", "Enlarge enemy hitboxes client-side","HitboxExpand")
    sliderRow(wc, "Hitbox Size",   "HitboxSize", 1, 20, 0.5)
end

-- ================================================================
--  ESP PAGE
-- ================================================================
do
    local p = PAGES["ESP"]
    sectionHdr(p, "Player Information")
    local ec = card(p)
    toggleRow(ec, "Player ESP",    "Highlight player silhouettes",      "PlayerESP",
        function(v)
            for _, ep in ipairs(Players:GetPlayers()) do
                if ep ~= lp then
                    local h = ep.Character and ep.Character:FindFirstChildOfClass("Highlight")
                    if h then h.Enabled = v end
                end
            end
        end)
    toggleRow(ec, "Wallhack",      "See players through any surface",   "WallHack")
    toggleRow(ec, "Skeleton ESP",  "Draw bone lines on players",        "SkeletonESP")
    toggleRow(ec, "Name Tags",     "Show player names overhead",        "NameESP")
    toggleRow(ec, "Health Bars",   "Show HP above players",             "HealthESP")
    toggleRow(ec, "Distance",      "Show distance to each player",      "DistanceESP")

    sectionHdr(p, "World Objects")
    local oc = card(p)
    toggleRow(oc, "Item ESP",      "Highlight collectible items",       "ItemESP")
    toggleRow(oc, "Weapon ESP",    "Highlight weapons and tools",       "WeaponESP")

    sectionHdr(p, "Colors")
    local cc = card(p)
    -- color pickers as dropdowns for simplicity
    dropdownRow(cc, "Guard Color",    {"Red","Orange","Yellow","Pink"},      "_guardColorName")
    dropdownRow(cc, "Prisoner Color", {"Blue","Cyan","Purple","White"},      "_prisonerColorName")
    dropdownRow(cc, "Fill Opacity",   {"25%","50%","75%","90%"},              "_espFillOpacity")
end

-- ================================================================
--  MOVEMENT PAGE
-- ================================================================
do
    local p = PAGES["Movement"]
    sectionHdr(p, "Speed & Jump")
    local mc = card(p)
    toggleRow(mc, "Speed Hack",     "Override WalkSpeed",                "SpeedEnabled",
        function(v)
            local h = getHum(lp)
            if h then h.WalkSpeed = v and CFG.Speed or 16 end
        end)
    sliderRow(mc, "Walk Speed",    "Speed",       16, 200,  2,
        function(v) local h=getHum(lp); if h then h.WalkSpeed=v end end)
    toggleRow(mc, "Infinite Jump",  "Jump as many times as you want",   "InfJump")
    sliderRow(mc, "Jump Power",    "JumpPower",   50, 500, 10,
        function(v) local h=getHum(lp); if h then h.JumpPower=v end end)

    sectionHdr(p, "Stamina & Air")
    local sc = card(p)
    toggleRow(sc, "Infinite Stamina","Never get tired",                  "InfStamina")

    sectionHdr(p, "Fly")
    local fc = card(p)
    toggleRow(fc, "Fly",            "Float and fly freely (WASD+Space)",  "Fly",
        function(v) if v then _startFly() else _stopFly() end end)
    sliderRow(fc, "Fly Speed",     "FlySpeed",    10, 300,  5)

    sectionHdr(p, "Noclip")
    local nc = card(p)
    toggleRow(nc, "Noclip",         "Phase through all walls",           "Noclip")
end

-- ================================================================
--  TELEPORTATION PAGE
-- ================================================================
do
    local p = PAGES["Teleportation"]

    sectionHdr(p, "Locations")
    local lc = card(p)
    local LOCATIONS = {
        {"Prison Spawn",   function() return workspace:FindFirstChild("Spawn") or workspace:FindFirstChild("SpawnLocation") end},
        {"Exit / Gate",    function()
            for _, v in ipairs(workspace:GetDescendants()) do
                local n=v.Name:lower()
                if v:IsA("BasePart") and (n:find("exit") or n:find("gate") or n:find("escape")) then return v end
            end
        end},
        {"Guard Room",     function()
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and v.Name:lower():find("guard") then return v end
            end
        end},
        {"Armory",         function()
            for _, v in ipairs(workspace:GetDescendants()) do
                local n=v.Name:lower()
                if v:IsA("BasePart") and (n:find("armory") or n:find("weapon") or n:find("gun")) then return v end
            end
        end},
        {"Visitor Lobby",  function()
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and v.Name:lower():find("visit") then return v end
            end
        end},
        {"Cafeteria",      function()
            for _, v in ipairs(workspace:GetDescendants()) do
                local n=v.Name:lower()
                if v:IsA("BasePart") and (n:find("cafe") or n:find("food")) then return v end
            end
        end},
    }

    for _, loc in ipairs(LOCATIONS) do
        local name, fn = loc[1], loc[2]
        btnRow(lc, "→  " .. name, nil, function()
            local root = getRoot(lp)
            if not root then return end
            local target = fn()
            if target and target:IsA("BasePart") then
                root.CFrame = target.CFrame + Vector3.new(0, 4, 0)
                notify("Teleport", "Teleported to " .. name, "success")
            else
                notify("Teleport", name .. " not found in workspace", "warn")
            end
        end)
    end

    sectionHdr(p, "Teleport to Player")
    local pc2 = card(p)

    local playerListFrame = Instance.new("Frame")
    playerListFrame.Size             = UDim2.new(1, 0, 0, 0)
    playerListFrame.AutomaticSize    = Enum.AutomaticSize.Y
    playerListFrame.BackgroundTransparency = 1
    playerListFrame.Parent           = pc2

    local plLayout = Instance.new("UIListLayout")
    plLayout.SortOrder = Enum.SortOrder.LayoutOrder
    plLayout.Padding   = UDim.new(0, 4)
    plLayout.Parent    = playerListFrame

    local function rebuildPlayerList()
        for _, c in ipairs(playerListFrame:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
        end
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= lp then
                btnRow(playerListFrame, "→  " .. pl.Name,
                    tostring(pl.Team and pl.Team.Name or "No Team"),
                    function()
                        local r1 = getRoot(lp); local r2 = getRoot(pl)
                        if r1 and r2 then
                            r1.CFrame = r2.CFrame + Vector3.new(2,0,2)
                            notify("Teleport","Teleported to " .. pl.Name, "success")
                        end
                    end)
            end
        end
    end
    rebuildPlayerList()
    Players.PlayerAdded:Connect(rebuildPlayerList)
    Players.PlayerRemoving:Connect(rebuildPlayerList)

    btnRow(pc2, "↺  Refresh Player List", nil, rebuildPlayerList)

    sectionHdr(p, "Saved Positions")
    local spc = card(p)
    local savedListFrame = Instance.new("Frame")
    savedListFrame.Size             = UDim2.new(1,0,0,0)
    savedListFrame.AutomaticSize    = Enum.AutomaticSize.Y
    savedListFrame.BackgroundTransparency = 1
    savedListFrame.Parent           = spc

    local savedLayout2 = Instance.new("UIListLayout")
    savedLayout2.SortOrder = Enum.SortOrder.LayoutOrder
    savedLayout2.Padding   = UDim.new(0,4)
    savedLayout2.Parent    = savedListFrame

    local function rebuildSavedList()
        for _, c in ipairs(savedListFrame:GetChildren()) do c:Destroy() end
        for i, sp in ipairs(CFG.SavedPositions) do
            local row = Instance.new("Frame")
            row.Size             = UDim2.new(1,0,0,32)
            row.BackgroundTransparency = 1
            row.Parent           = savedListFrame

            local rlay = Instance.new("UIListLayout")
            rlay.FillDirection = Enum.FillDirection.Horizontal
            rlay.Padding       = UDim.new(0,4)
            rlay.Parent        = row

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(0.5,-4,1,0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = sp.name
            nameLbl.TextColor3 = Color3.fromRGB(180,170,210)
            nameLbl.Font = Enum.Font.Gotham; nameLbl.TextSize = 12
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Parent = row

            local tpBtn = Instance.new("TextButton")
            tpBtn.Size = UDim2.new(0.25,-4,0,26)
            tpBtn.BackgroundColor3 = Color3.fromRGB(28,18,54)
            tpBtn.Text = "Go"; tpBtn.TextColor3 = Color3.fromRGB(160,120,255)
            tpBtn.Font = Enum.Font.GothamBold; tpBtn.TextSize = 12
            tpBtn.BorderSizePixel = 0; tpBtn.Parent = row
            Instance.new("UICorner",tpBtn).CornerRadius = UDim.new(0,5)
            tpBtn.MouseButton1Click:Connect(function()
                local root = getRoot(lp)
                if root then root.CFrame = sp.cf end
            end)

            local delBtn = Instance.new("TextButton")
            delBtn.Size = UDim2.new(0.25,-4,0,26)
            delBtn.BackgroundColor3 = Color3.fromRGB(50,18,18)
            delBtn.Text = "Del"; delBtn.TextColor3 = Color3.fromRGB(255,100,100)
            delBtn.Font = Enum.Font.GothamBold; delBtn.TextSize = 12
            delBtn.BorderSizePixel = 0; delBtn.Parent = row
            Instance.new("UICorner",delBtn).CornerRadius = UDim.new(0,5)
            delBtn.MouseButton1Click:Connect(function()
                table.remove(CFG.SavedPositions, i)
                rebuildSavedList()
            end)
        end
    end
    rebuildSavedList()

    btnRow(spc, "📌  Save Current Position", "Saves where you are standing", function()
        local root = getRoot(lp)
        if root then
            local n = "Pos " .. (#CFG.SavedPositions + 1)
            table.insert(CFG.SavedPositions, {name=n, cf=root.CFrame})
            rebuildSavedList()
            notify("Saved", "Position saved as " .. n, "success")
        end
    end)
end

-- ================================================================
--  SPAWNING PAGE
-- ================================================================
do
    local p = PAGES["Spawning"]

    sectionHdr(p, "Weapons & Tools")
    local wc = card(p)
    local WEAPONS = {"Pistol","Rifle","Shotgun","Knife","Taser","Baton","Handcuffs","Keycard"}
    for _, wname in ipairs(WEAPONS) do
        btnRow(wc, "Spawn  " .. wname, nil, function()
            -- Search backpack/tools in game for matching tool
            local spawned = false
            for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("Tool") and v.Name:lower():find(wname:lower()) then
                    local clone = v:Clone()
                    clone.Parent = lp.Backpack
                    spawned = true
                    notify("Spawned", wname .. " added to backpack", "success")
                    break
                end
            end
            -- Also check workspace
            if not spawned then
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("Tool") and v.Name:lower():find(wname:lower()) then
                        local clone = v:Clone()
                        clone.Parent = lp.Backpack
                        spawned = true
                        notify("Spawned", wname .. " cloned from world", "info")
                        break
                    end
                end
            end
            if not spawned then
                notify("Spawn Failed", wname .. " not found in game assets", "warn")
            end
        end)
    end

    sectionHdr(p, "Item Manipulation")
    local ic = card(p)
    btnRow(ic, "Collect All Dropped Items", "Pull all dropped tools to inventory", function()
        local root = getRoot(lp)
        if not root then return end
        local count = 0
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Tool") then
                v.Parent = lp.Backpack
                count += 1
            end
        end
        notify("Collected", count .. " items picked up", "success")
    end)

    btnRow(ic, "Drop All Items", "Drop everything from backpack", function()
        local root = getRoot(lp)
        if not root then return end
        for _, v in ipairs(lp.Backpack:GetChildren()) do
            if v:IsA("Tool") then
                v.Parent = workspace
                if v:FindFirstChild("Handle") then
                    v.Handle.CFrame = root.CFrame + Vector3.new(math.random(-3,3),1,math.random(-3,3))
                end
            end
        end
        notify("Dropped", "Backpack cleared", "info")
    end)

    btnRow(ic, "Max Tool Speed", "Set all held tool fire rates to max", function()
        local char = getChar(lp)
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                for _, v in ipairs(tool:GetDescendants()) do
                    if v:IsA("NumberValue") and (v.Name:lower():find("fire") or v.Name:lower():find("rate") or v.Name:lower():find("speed")) then
                        v.Value = 0.01
                    end
                end
                notify("Modified", "Tool properties updated", "success")
            end
        end
    end)
end

-- ================================================================
--  PRISON SYSTEM PAGE
-- ================================================================
do
    local p = PAGES["Prison System"]

    sectionHdr(p, "Restriction Bypasses")
    local rc = card(p)
    btnRow(rc, "Bypass Door Locks", "Trigger door open remotes", nil, function()
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") and (v.Name:lower():find("door") or v.Name:lower():find("open")) then
                pcall(function() v:FireServer() end)
            end
        end
        notify("Bypass", "Fired all door remotes", "info")
    end)

    btnRow(rc, "Remove Handcuffs", "Free yourself from arrest", nil, function()
        -- Find and destroy handcuff constraint / weld
        local char = getChar(lp)
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("WeldConstraint") or v:IsA("Motor6D") then
                    if v.Name:lower():find("cuff") or v.Name:lower():find("arrest") then
                        v:Destroy()
                    end
                end
            end
        end
        -- Fire escape remote if it exists
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name:lower():find("escape") then
                pcall(function() v:FireServer() end)
            end
        end
        notify("Freed", "Attempted handcuff removal", "success")
    end)

    sectionHdr(p, "Team & Role")
    local tc = card(p)
    local teamBtns = {"Prisoner","Guard","Warden","Visitor","Criminal","Police"}
    for _, tname in ipairs(teamBtns) do
        btnRow(tc, "Set Team: " .. tname, nil, function()
            -- Fire team-change remote
            for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") and (v.Name:lower():find("team") or v.Name:lower():find("role")) then
                    pcall(function() v:FireServer(tname) end)
                end
            end
            -- Direct team assignment attempt
            for _, team in ipairs(game:GetService("Teams"):GetTeams()) do
                if team.Name:lower():find(tname:lower()) then
                    pcall(function() lp.Team = team end)
                end
            end
            notify("Team", "Attempted team change to " .. tname, "info")
        end)
    end

    sectionHdr(p, "Remote Event Monitor")
    local rmc = card(p)
    toggleRow(rmc, "Log All Remotes",  "Print fired remotes to console", "_logRemotes")
    toggleRow(rmc, "Block Arrest Remote","Intercept and block arrest calls","_blockArrest")

    btnRow(rmc, "List All RemoteEvents", "Print all remotes to output", function()
        local found = 0
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                print("[VP Remote] " .. v:GetFullName())
                found += 1
            end
        end
        notify("Remotes", found .. " remotes found (see output)", "info")
    end)
end

-- ================================================================
--  ANTI-KICK PAGE
-- ================================================================
do
    local p = PAGES["Anti-Kick"]

    sectionHdr(p, "Protection")
    local ac = card(p)
    toggleRow(ac, "Anti-Kick",       "Block server kick attempts",        "AntiKick",
        function(v)
            if v then
                -- Hook LocalPlayer.Kick via metamethods if available
                if getrawmetatable then
                    pcall(function()
                        local mt = getrawmetatable(lp)
                        local old = mt.__namecall
                        if not old then return end
                        mt.__namecall = newcclosure(function(self, ...)
                            local method = getnamecallmethod()
                            if method == "Kick" then
                                notify("Anti-Kick","Kick blocked","success")
                                return
                            end
                            return old(self, ...)
                        end)
                    end)
                else
                    notify("Anti-Kick","Partial — metamethod hook unavailable in this executor","warn")
                end
            end
        end)

    toggleRow(ac, "Anti-Disconnect",  "Reconnect on unexpected disconnects","AntiDisconnect")

    sectionHdr(p, "Remote Filtering")
    local rfc = card(p)
    toggleRow(rfc, "Block Ban Remotes","Intercept known ban/kick remotes",  "_blockBan")
    toggleRow(rfc, "Spoof UserAgent",  "Spoof game detection signals",      "_spoofAgent")

    btnRow(rfc, "Scan Kick Remotes", "Find potential kick/ban remotes", function()
        local found = {}
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            local n = v.Name:lower()
            if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and
               (n:find("kick") or n:find("ban") or n:find("mute") or n:find("punish")) then
                table.insert(found, v:GetFullName())
            end
        end
        if #found == 0 then
            notify("Scan","No kick remotes found","info")
        else
            notify("Scan", #found .. " suspicious remotes found (output)","warn")
            for _, path in ipairs(found) do print("[VP KickScan] " .. path) end
        end
    end)

    sectionHdr(p, "Info")
    local ic = card(p)
    local infoL = Instance.new("TextLabel")
    infoL.Size              = UDim2.new(1,0,0,80)
    infoL.BackgroundTransparency = 1
    infoL.Text              = "Anti-kick uses metamethod hooks to intercept :Kick() calls.\n" ..
        "Effectiveness varies by executor.\n" ..
        "Remote blocking identifies and silently drops suspicious server calls.\n" ..
        "These methods do NOT guarantee ban prevention — use at own risk."
    infoL.TextColor3        = Color3.fromRGB(100,90,120)
    infoL.Font              = Enum.Font.Gotham
    infoL.TextSize          = 11
    infoL.TextXAlignment    = Enum.TextXAlignment.Left
    infoL.TextWrapped       = true
    infoL.Parent            = ic
end

-- ================================================================
--  CHEAT LOGIC
-- ================================================================

-- ── ESP Highlights ──────────────────────────────────────────────
local _espHighlights = {}
local ESPColors = {
    Guard    = Color3.fromRGB(255, 60,  60),
    Prisoner = Color3.fromRGB(80,  150, 255),
    Default  = Color3.fromRGB(120, 80,  255),
}

local function getTeamColor(p)
    local t = tostring(p.Team and p.Team.Name or ""):lower()
    if t:find("guard") or t:find("police") or t:find("warden") then return ESPColors.Guard end
    return ESPColors.Prisoner
end

local function removeESP(p)
    local h = _espHighlights[p]
    if h and h.Parent then h:Destroy() end
    _espHighlights[p] = nil
end

local function buildESP(p)
    if p == lp then return end
    removeESP(p)
    local function setup()
        local char = getChar(p)
        if not char then return end
        local h = Instance.new("Highlight")
        h.FillColor           = getTeamColor(p)
        h.OutlineColor        = getTeamColor(p)
        h.FillTransparency    = 0.72
        h.OutlineTransparency = 0
        h.DepthMode           = CFG.WallHack
            and Enum.HighlightDepthMode.AlwaysOnTop
            or  Enum.HighlightDepthMode.Occluded
        h.Adornee             = char
        h.Enabled             = CFG.PlayerESP
        h.Parent              = char
        _espHighlights[p]     = h
    end
    setup()
    p.CharacterAdded:Connect(function() task.wait(0.15); setup() end)
end

local function refreshAllESP()
    if not CFG.PlayerESP then
        for _, h in pairs(_espHighlights) do if h.Parent then h:Destroy() end end
        _espHighlights = {}
        return
    end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= lp and not _espHighlights[pl] then buildESP(pl) end
    end
    -- sync wallhack depth mode
    for _, h in pairs(_espHighlights) do
        if h.Parent then
            h.DepthMode = CFG.WallHack
                and Enum.HighlightDepthMode.AlwaysOnTop
                or  Enum.HighlightDepthMode.Occluded
            h.Enabled   = CFG.PlayerESP
        end
    end
end

Players.PlayerAdded:Connect(function(p) if CFG.PlayerESP then buildESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)

-- ── Name/Health/Distance Tag BillboardGuis ──────────────────────
local _tagFolder = Instance.new("Folder")
_tagFolder.Name   = "_VPTags"
_tagFolder.Parent = Workspace

local function updateTags()
    -- Remove stale
    for _, bb in ipairs(_tagFolder:GetChildren()) do
        local pname = bb.Name
        if not Players:FindFirstChild(pname) then bb:Destroy() end
    end
    if not CFG.NameESP and not CFG.HealthESP and not CFG.DistanceESP then return end

    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == lp then continue end
        local root = getRoot(pl)
        local hum  = getHum(pl)
        if not root or not hum then continue end

        local bb = _tagFolder:FindFirstChild(pl.Name)
        if not bb then
            bb = Instance.new("BillboardGui")
            bb.Name         = pl.Name
            bb.Size         = UDim2.new(0, 130, 0, 44)
            bb.StudsOffset  = Vector3.new(0, 3.4, 0)
            bb.AlwaysOnTop  = true
            bb.ResetOnSpawn = false
            bb.Parent       = _tagFolder

            local nl = Instance.new("TextLabel")
            nl.Name                 = "Name"
            nl.Size                 = UDim2.new(1,0,0,18)
            nl.BackgroundTransparency = 1
            nl.Font                 = Enum.Font.GothamBold
            nl.TextSize             = 13
            nl.TextStrokeTransparency = 0
            nl.TextColor3           = getTeamColor(pl)
            nl.Parent               = bb

            local hl = Instance.new("TextLabel")
            hl.Name                 = "Info"
            hl.Size                 = UDim2.new(1,0,0,14)
            hl.Position             = UDim2.new(0,0,0,20)
            hl.BackgroundTransparency = 1
            hl.Font                 = Enum.Font.Gotham
            hl.TextSize             = 11
            hl.TextStrokeTransparency = 0.2
            hl.TextColor3           = Color3.fromRGB(200,200,220)
            hl.Parent               = bb
        end

        bb.Adornee = root
        local nl = bb:FindFirstChild("Name")
        local il = bb:FindFirstChild("Info")
        if nl then nl.Text = CFG.NameESP and pl.Name or "" end
        if il then
            local parts = {}
            if CFG.HealthESP   then table.insert(parts, math.floor(hum.Health) .. "HP") end
            if CFG.DistanceESP then table.insert(parts, math.floor(distTo(pl)) .. "m") end
            il.Text = table.concat(parts, "  ")
        end
    end
end

-- ── Skeleton ESP (Drawing API) ────────────────────────────────
local _skelLines = {}
local SKELETON_PAIRS = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
}
local hasDrawing = pcall(function() return Drawing.new("Line") end)

local function clearSkelLines()
    for _, l in ipairs(_skelLines) do pcall(function() l:Remove() end) end
    _skelLines = {}
end

local function drawSkeleton()
    clearSkelLines()
    if not CFG.SkeletonESP or not hasDrawing then return end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == lp then continue end
        local char = getChar(pl)
        if not char then continue end
        local hum = getHum(pl)
        if not hum or hum.Health <= 0 then continue end
        for _, pair in ipairs(SKELETON_PAIRS) do
            local a = char:FindFirstChild(pair[1])
            local b = char:FindFirstChild(pair[2])
            if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                local sa, va = cam:WorldToViewportPoint(a.Position)
                local sb, vb = cam:WorldToViewportPoint(b.Position)
                if va and vb then
                    local line = Drawing.new("Line")
                    line.From      = Vector2.new(sa.X, sa.Y)
                    line.To        = Vector2.new(sb.X, sb.Y)
                    line.Color     = getTeamColor(pl)
                    line.Thickness = 1.5
                    line.Visible   = true
                    table.insert(_skelLines, line)
                end
            end
        end
    end
end

-- ── Aimbot / Aimlock ─────────────────────────────────────────
local _aimbotTarget = nil

local function getBestAimbotTarget()
    local vpSize = cam.ViewportSize
    local cx, cy = vpSize.X/2, vpSize.Y/2
    local bestFov, bestPart = CFG.AimbotFOV, nil

    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == lp then continue end
        if not isEnemy(pl) then continue end
        local char = getChar(pl)
        if not char then continue end
        local hum = getHum(pl)
        if not hum or hum.Health <= 0 then continue end
        local part = char:FindFirstChild(CFG.AimbotPart) or getRoot(pl)
        if not part then continue end

        local sp, onScreen = cam:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local fovDist = ((sp.X-cx)^2 + (sp.Y-cy)^2)^0.5
        if fovDist < bestFov then
            bestFov = fovDist; bestPart = part
        end
    end
    return bestPart
end

-- ── Triggerbot ───────────────────────────────────────────────
local _lastTrigger = 0
local function checkTriggerbot()
    if not CFG.Triggerbot then return end
    local now = tick()
    if now - _lastTrigger < CFG.TriggerbotDelay then return end

    local vp = cam.ViewportSize
    local ray = cam:ScreenPointToRay(vp.X/2, vp.Y/2)
    local result = workspace:Raycast(ray.Origin, ray.Direction * 500,
        RaycastParams.new())
    if result and result.Instance then
        local hit = result.Instance
        local char = hit:FindFirstAncestorOfClass("Model")
        if char then
            local pl = Players:GetPlayerFromCharacter(char)
            if pl and pl ~= lp and isEnemy(pl) then
                _lastTrigger = now
                -- simulate click / use tool
                local tool = getChar(lp) and getChar(lp):FindFirstChildOfClass("Tool")
                if tool then
                    local fa = tool:FindFirstChildOfClass("RemoteEvent")
                        or tool:FindFirstChildOfClass("RemoteFunction")
                    if fa and fa:IsA("RemoteEvent") then
                        pcall(function() fa:FireServer(result.Instance, result.Position,
                            result.Normal, result.Distance, tool:FindFirstChild("Handle") and
                            tool.Handle or tool) end)
                    end
                end
            end
        end
    end
end

-- ── Silent Aim (metamethod hook) ─────────────────────────────
local _silentAimHooked = false
local function applySilentAim()
    if _silentAimHooked then return end
    _silentAimHooked = true
    if not getrawmetatable then
        notify("Silent Aim","Executor does not support metamethod hooks","warn")
        return
    end
    pcall(function()
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if CFG.SilentAim and (method == "FireServer" or method == "InvokeServer") then
                local args = {...}
                -- Redirect hit position to aimbot target
                local target = getBestAimbotTarget()
                if target then
                    for i, v in ipairs(args) do
                        if typeof(v) == "Vector3" then
                            args[i] = target.Position
                        elseif typeof(v) == "Instance" and v:IsA("BasePart") then
                            args[i] = target
                        end
                    end
                end
                return old(self, table.unpack(args))
            end
            return old(self, ...)
        end)
    end)
end

-- ── No Recoil ────────────────────────────────────────────────
local _prevCamCF
RunService.RenderStepped:Connect(function()
    if CFG.NoRecoil then
        if _prevCamCF then
            local cur = cam.CFrame
            cam.CFrame = CFrame.new(cur.Position)
                * CFrame.Angles(math.rad(math.deg(select(1,_prevCamCF:ToEulerAnglesYXZ()))),
                                 math.rad(math.deg(select(2,cur:ToEulerAnglesYXZ()))),
                                 0)
        end
        _prevCamCF = cam.CFrame
    else
        _prevCamCF = nil
    end
end)

-- ── Hitbox Expander ──────────────────────────────────────────
local _origSizes = {}
RunService.Heartbeat:Connect(function()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == lp then continue end
        local char = getChar(pl)
        if not char then continue end
        local head = getHead(pl)
        local root = getRoot(pl)
        for _, part in ipairs({head, root}) do
            if not part then continue end
            if CFG.HitboxExpand then
                if not _origSizes[part] then _origSizes[part] = part.Size end
                part.Size = Vector3.new(CFG.HitboxSize, CFG.HitboxSize, CFG.HitboxSize)
            elseif _origSizes[part] then
                part.Size = _origSizes[part]
                _origSizes[part] = nil
            end
        end
    end
end)

-- ── Fly ──────────────────────────────────────────────────────
local _flyConn
function _startFly()
    _stopFly()
    local char = getChar(lp); local root = getRoot(lp); local hum = getHum(lp)
    if not char or not root or not hum then return end
    hum.PlatformStand = true

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e9,1e9,1e9); bv.Velocity = Vector3.zero
    bv.Parent = root

    _flyConn = RunService.RenderStepped:Connect(function()
        if not CFG.Fly then _stopFly(); return end
        local dir = Vector3.zero
        local cf  = cam.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
        bv.Velocity = dir.Magnitude > 0 and dir.Unit * CFG.FlySpeed or Vector3.zero
    end)
end

function _stopFly()
    if _flyConn then _flyConn:Disconnect(); _flyConn = nil end
    local root = getRoot(lp); local hum = getHum(lp)
    if root then local bv=root:FindFirstChildOfClass("BodyVelocity"); if bv then bv:Destroy() end end
    if hum then hum.PlatformStand = false end
end

-- ── Noclip ───────────────────────────────────────────────────
RunService.Stepped:Connect(function()
    if not CFG.Noclip then return end
    local char = getChar(lp); if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

-- ── Infinite Jump ────────────────────────────────────────────
UserInputService.JumpRequest:Connect(function()
    if CFG.InfJump then
        local hum = getHum(lp)
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ── Infinite Stamina ─────────────────────────────────────────
local function findStaminaValue()
    for _, v in ipairs({lp, lp.Character}) do
        if not v then continue end
        for _, c in ipairs(v:GetDescendants()) do
            if (c:IsA("NumberValue") or c:IsA("IntValue"))
               and c.Name:lower():find("stam") then
                return c
            end
        end
    end
    -- PlayerGui stamina bar
    for _, v in ipairs(lp.PlayerGui:GetDescendants()) do
        if v:IsA("NumberValue") and v.Name:lower():find("stam") then return v end
    end
end

-- ── Main heartbeat loop ──────────────────────────────────────
RunService.Heartbeat:Connect(function()
    -- Speed
    local hum = getHum(lp)
    if hum and CFG.SpeedEnabled then
        if hum.WalkSpeed ~= CFG.Speed then hum.WalkSpeed = CFG.Speed end
    end

    -- Jump power
    if hum and CFG.InfJump then
        if hum.JumpPower ~= CFG.JumpPower then hum.JumpPower = CFG.JumpPower end
    end

    -- Infinite stamina
    if CFG.InfStamina then
        local sv = findStaminaValue()
        if sv then
            local max = rawget(sv,"MaxValue") or 100
            if sv.Value < max then sv.Value = max end
        end
    end

    -- God mode
    if CFG.GodMode then
        if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
    end

    -- Triggerbot
    checkTriggerbot()
end)

-- ── Main render loop ─────────────────────────────────────────
local _espTimer = 0
local _skelTimer = 0

RunService.RenderStepped:Connect(function(dt)
    _espTimer += dt
    _skelTimer += dt

    if _espTimer >= 0.2 then
        _espTimer = 0
        refreshAllESP()
        updateTags()
    end

    if _skelTimer >= 0.05 then
        _skelTimer = 0
        drawSkeleton()
    end

    -- Aimbot
    if CFG.Aimbot or CFG.Aimlock then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = getBestAimbotTarget()
            if target then
                local goalCF = CFrame.new(cam.CFrame.Position, target.Position)
                if CFG.Aimlock then
                    cam.CFrame = goalCF
                else
                    cam.CFrame = cam.CFrame:Lerp(goalCF, CFG.AimbotSmooth)
                end
            end
        end
    end

    -- Silent aim activation
    if CFG.SilentAim and not _silentAimHooked then
        applySilentAim()
    end
end)

-- ── Item / Weapon ESP ─────────────────────────────────────────
local _itemHighlights = {}

RunService.Heartbeat:Connect(function()
    for _, h in pairs(_itemHighlights) do
        if h.Parent and not CFG.ItemESP and not CFG.WeaponESP then
            h:Destroy()
        end
    end
    if not CFG.ItemESP and not CFG.WeaponESP then _itemHighlights = {}; return end

    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Tool") and not _itemHighlights[v] then
            local isWeapon = v:FindFirstChildOfClass("Script") and
                tostring(v.Name):lower():find("gun") or
                tostring(v.Name):lower():find("pistol") or
                tostring(v.Name):lower():find("rifle") or
                tostring(v.Name):lower():find("knife")

            if (CFG.ItemESP and not isWeapon) or (CFG.WeaponESP and isWeapon) or CFG.ItemESP then
                local h = Instance.new("Highlight")
                h.FillColor        = isWeapon
                    and Color3.fromRGB(255, 200, 50)
                    or  Color3.fromRGB(50, 220, 150)
                h.OutlineColor     = h.FillColor
                h.FillTransparency = 0.5
                h.DepthMode        = Enum.HighlightDepthMode.AlwaysOnTop
                h.Adornee          = v
                h.Parent           = v
                _itemHighlights[v] = h
            end
        end
    end
end)

-- ── Remote Monitor / Arrest Block ────────────────────────────
if getrawmetatable then
    pcall(function()
        local mt  = getrawmetatable(game)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                local n = tostring(self.Name):lower()
                -- Block arrest
                if CFG._blockArrest and (n:find("arrest") or n:find("cuff") or n:find("detain")) then
                    notify("Blocked","Arrest remote intercepted","success")
                    return
                end
                -- Block ban
                if CFG._blockBan and (n:find("ban") or n:find("kick") or n:find("punish")) then
                    notify("Blocked","Ban remote intercepted","success")
                    return
                end
                -- Log
                if CFG._logRemotes then
                    print("[VP Remote] " .. method .. " → " .. self:GetFullName())
                end
            end
            return old(self, ...)
        end)
    end)
end

-- ================================================================
--  TOGGLE GUI  (Right Shift)
-- ================================================================
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        CFG.GuiOpen = not CFG.GuiOpen
        window.Visible  = CFG.GuiOpen
        overlay.Visible = CFG.GuiOpen
        if CFG.GuiOpen then
            window.Size = UDim2.new(0, WIN_W, 0, 0)
            tweenProp(window, 0.22, {Size = UDim2.new(0, WIN_W, 0, WIN_H)})
        end
    end
end)

-- ================================================================
--  INIT
-- ================================================================
refreshAllESP()
showPage("Home")
lp.CharacterAdded:Connect(function()
    task.wait(0.6)
    refreshAllESP()
    if CFG.Fly then _startFly() end
    local hum = getHum(lp)
    if hum then
        if CFG.SpeedEnabled then hum.WalkSpeed = CFG.Speed end
        if CFG.InfJump then hum.JumpPower = CFG.JumpPower end
    end
end)

-- Opening animation
window.Size = UDim2.new(0, WIN_W, 0, 0)
tweenProp(window, 0.25, {Size = UDim2.new(0, WIN_W, 0, WIN_H)})

notify("NyxScript","Valley Prison loaded  ·  Right Shift to toggle","success", 4)
print("[NyxScript] Valley Prison — loaded. Right Shift = toggle GUI.")
