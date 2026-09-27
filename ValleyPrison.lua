-- language: Lua (Luau), file: nyxscript_vp.lua
-- target: Roblox executor (Synapse X / KRNL / Fluxus / Velocity / Solara)
-- load: loadstring(game:HttpGet("URL"))()
-- Valley Prison cheat menu. Anti-kick active from load.

-- ============================================================================
-- SECTION 1 — SERVICES + HELPERS
-- ============================================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local Lighting          = game:GetService("Lighting")
local Teams             = game:GetService("Teams")
local lp                = Players.LocalPlayer
local cam               = workspace.CurrentCamera

local function chr(p)  return p and p.Character end
local function root(p) local c = chr(p); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum(p)  local c = chr(p); return c and c:FindFirstChildOfClass("Humanoid") end
local function isAlive(p)
    local h = hum(p)
    return h and h.Health > 0 and h:GetState() ~= Enum.HumanoidStateType.Dead
end
local function dist(p)
    local a, b = root(lp), root(p)
    if not a or not b then return math.huge end
    return (a.Position - b.Position).Magnitude
end
local function hasGun()
    local ch = chr(lp)
    if not ch then return false end
    local tool = ch:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local n = tool.Name:lower()
    local words = {"gun","pistol","rifle","shot","snip","smg","revolver","taser",
                   "mp5","ak","m4","g18","glock","ump","p90","ksg","m1911","uzi"}
    for _, w in ipairs(words) do if n:find(w) then return true end end
    return tool:FindFirstChild("Shoot") or tool:FindFirstChild("Fire")
        or tool:FindFirstChild("ShootEvent") or tool:FindFirstChild("FireEvent") ~= nil
end

-- ============================================================================
-- SECTION 2 — CFG
-- ============================================================================

local CFG = {
    Aimbot=false, AimbotFOV=150, AimbotSmooth=0.12, AimbotPart="Head",
    AimbotTeamCheck=false, AimbotRequireGun=false, AimbotWallCheck=false,
    AimbotFOVRing=false, AimbotFOVRingColor=Color3.fromRGB(0,201,185),
    Aimlock=false, SilentAim=false, Triggerbot=false, TriggerbotDelay=0.05,
    NoRecoil=false, NoSpread=false, RapidFire=false, InfiniteAmmo=false,
    AutoReload=false, InstantEquip=false,
    HitboxExpand=false, HitboxSize=6,
    PlayerESP=false, ESPFillColor=Color3.fromRGB(99,179,237),
    ESPOutlineColor=Color3.fromRGB(99,179,237),
    ESPFillTransparency=0.75, ESPOutlineTransparency=0,
    WallHack=false, SkeletonESP=false, SkeletonColor=Color3.fromRGB(0,201,185),
    NameESP=false, HealthESP=false, DistanceESP=false,
    BoxESP=false, BoxESPColor=Color3.fromRGB(255,255,255),
    TracerESP=false, TracerColor=Color3.fromRGB(248,113,113),
    TracerOrigin="Bottom", TracerThickness=1.5,
    TeamColors=true, ESPMaxDist=500, ChamsESP=false, ChamsColor=Color3.fromRGB(255,165,0),
    ItemESP=false, WeaponESP=false, KeycardESP=false, ItemESPMaxDist=150,
    SpeedEnabled=false, Speed=24, Fly=false, FlySpeed=30, Noclip=false,
    InfJump=false, JumpPower=60, InfStamina=false, AntiGravity=false,
    GravityValue=50, BunnyHop=false, SlowFall=false, SlowFallSpeed=5,
    SuperJump=false, SuperJumpPower=200, TpToCursor=false,
    GodMode=false, AntiStun=false, InfHealth=false,
    Fullbright=false, NoFog=false, TimeOfDay=false, TimeValue=14,
    ThirdPerson=false, ThirdPersonDist=10, ZoomHack=false, ZoomFOV=70,
    Rainbow=false, InvisibleChar=false, CustomCharColor=false,
    CustomCharColor3=Color3.fromRGB(255,255,255),
    NoBloom=false, NoBlur=false,
    BlockArrest=false, BlockBan=false, AutoEscape=false, RemoveCuffs=false,
    AntiKick=true, AntiDisconnect=false, LogRemotes=false,
    Open=true, Page="Home", MenuKey=Enum.KeyCode.RightShift,
    ShowNotify=true,
}

local C = {
    bg=Color3.fromRGB(8,9,16), surface=Color3.fromRGB(13,14,24),
    card=Color3.fromRGB(18,19,30), cardHov=Color3.fromRGB(22,24,38),
    accent=Color3.fromRGB(0,201,185), accentDk=Color3.fromRGB(0,140,128),
    accent2=Color3.fromRGB(123,97,255), danger=Color3.fromRGB(248,113,113),
    warn=Color3.fromRGB(251,191,36), ok=Color3.fromRGB(52,211,153),
    text=Color3.fromRGB(225,230,245), textMid=Color3.fromRGB(150,155,175),
    textDim=Color3.fromRGB(75,80,105), border=Color3.fromRGB(255,255,255),
}

-- ============================================================================
-- SECTION 3 — NOTIFICATIONS
-- ============================================================================

local notifyGui = Instance.new("ScreenGui")
notifyGui.Name = "VP_Notify"
notifyGui.ResetOnSpawn = false
notifyGui.IgnoreGuiInset = true
notifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
do
    local host = gethui and gethui() or lp:WaitForChild("PlayerGui")
    notifyGui.Parent = host
end

local notifyHolder = Instance.new("Frame")
notifyHolder.BackgroundTransparency = 1
notifyHolder.AnchorPoint = Vector2.new(1, 1)
notifyHolder.Position = UDim2.new(1, -14, 1, -14)
notifyHolder.Size = UDim2.new(0, 260, 0, 400)
notifyHolder.Parent = notifyGui
local nLayout = Instance.new("UIListLayout")
nLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
nLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
nLayout.Padding = UDim.new(0, 5)
nLayout.SortOrder = Enum.SortOrder.LayoutOrder
nLayout.Parent = notifyHolder

local NOTIFY_COLORS = { ok=C.ok, warn=C.warn, err=C.danger, info=C.accent }

local function notify(msg, kind, dur)
    if not CFG.ShowNotify then return end
    kind = kind or "info"; dur = dur or 3

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 260, 0, 44)
    card.BackgroundColor3 = C.bg
    card.BackgroundTransparency = 0
    card.Position = UDim2.new(1, 280, 0, 0)
    card.Parent = notifyHolder
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 6); cr.Parent = card
    local st = Instance.new("UIStroke")
    st.Color = C.border; st.Transparency = 0.9; st.Thickness = 1; st.Parent = card

    local strip = Instance.new("Frame")
    strip.Size = UDim2.new(0, 3, 1, -12)
    strip.Position = UDim2.new(0, 6, 0, 6)
    strip.BackgroundColor3 = NOTIFY_COLORS[kind] or C.accent
    strip.BorderSizePixel = 0
    strip.Parent = card
    local scr = Instance.new("UICorner"); scr.CornerRadius = UDim.new(1, 0); scr.Parent = strip

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 18, 0, 0)
    lbl.Size = UDim2.new(1, -24, 1, -6)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = C.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Top
    lbl.TextWrapped = true
    lbl.Text = msg
    lbl.Parent = card

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -12, 0, 2)
    bar.Position = UDim2.new(0, 6, 1, -4)
    bar.BackgroundColor3 = NOTIFY_COLORS[kind] or C.accent
    bar.BorderSizePixel = 0
    bar.Parent = card
    local bcr = Instance.new("UICorner"); bcr.CornerRadius = UDim.new(1, 0); bcr.Parent = bar

    TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Position = UDim2.new(0, 0, 0, 0) }):Play()
    TweenService:Create(bar, TweenInfo.new(dur, Enum.EasingStyle.Linear),
        { Size = UDim2.new(0, 0, 0, 2) }):Play()

    task.delay(dur, function()
        if not card.Parent then return end
        TweenService:Create(card, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            { Position = UDim2.new(1, 280, 0, 0), BackgroundTransparency = 1 }):Play()
        task.delay(0.16, function() if card.Parent then card:Destroy() end end)
    end)
end

-- ============================================================================
-- SECTION 4 — MAIN GUI
-- ============================================================================

local W, H = 720, 480
local SIDEBAR_W = 150
local TITLE_H = 40

local gui = Instance.new("ScreenGui")
gui.Name = "VP_Main"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
do
    local host = gethui and gethui() or lp:WaitForChild("PlayerGui")
    gui.Parent = host
end

local function tw(inst, t, props)
    TweenService:Create(inst, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

local win = Instance.new("Frame")
win.Name = "win"
win.Size = UDim2.new(0, W, 0, 0)
win.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
win.BackgroundColor3 = C.bg
win.BorderSizePixel = 0
win.ClipsDescendants = true
win.Parent = gui
local wcr = Instance.new("UICorner"); wcr.CornerRadius = UDim.new(0, 10); wcr.Parent = win
local wst = Instance.new("UIStroke"); wst.Color = C.border; wst.Transparency = 0.88; wst.Thickness = 1; wst.Parent = win

local titleBar = Instance.new("Frame")
titleBar.Name = "titleBar"
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.BackgroundColor3 = C.surface
titleBar.BorderSizePixel = 0
titleBar.Parent = win

local accentStrip = Instance.new("Frame")
accentStrip.Size = UDim2.new(0, 3, 0, 22)
accentStrip.Position = UDim2.new(0, 14, 0.5, -11)
accentStrip.BackgroundColor3 = C.accent
accentStrip.BorderSizePixel = 0
accentStrip.Parent = titleBar
local ascr = Instance.new("UICorner"); ascr.CornerRadius = UDim.new(0, 2); ascr.Parent = accentStrip

local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Position = UDim2.new(0, 26, 0, 6)
titleLbl.Size = UDim2.new(0, 200, 0, 16)
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 14
titleLbl.TextColor3 = C.text
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Text = "VALLEY PRISON"
titleLbl.Parent = titleBar

local subLbl = Instance.new("TextLabel")
subLbl.BackgroundTransparency = 1
subLbl.Position = UDim2.new(0, 26, 0, 22)
subLbl.Size = UDim2.new(0, 200, 0, 12)
subLbl.Font = Enum.Font.Gotham
subLbl.TextSize = 10
subLbl.TextColor3 = C.textDim
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.Text = "NyxScript v2.0"
subLbl.Parent = titleBar

local function mkTitleBtn(txt, color, xOff)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 20, 0, 20)
    b.Position = UDim2.new(1, xOff, 0, 10)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = txt
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.TextColor3 = C.bg
    b.AutoButtonColor = false
    b.Parent = titleBar
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = b
    return b
end
local btnClose = mkTitleBtn("×", C.danger, -28)
local btnMin   = mkTitleBtn("–", C.ok, -52)

local sidebar = Instance.new("Frame")
sidebar.Name = "sidebar"
sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -TITLE_H)
sidebar.Position = UDim2.new(0, 0, 0, TITLE_H)
sidebar.BackgroundColor3 = C.surface
sidebar.BorderSizePixel = 0
sidebar.Parent = win
local sl = Instance.new("UIListLayout")
sl.Padding = UDim.new(0, 4)
sl.SortOrder = Enum.SortOrder.LayoutOrder
sl.Parent = sidebar
local spad = Instance.new("UIPadding")
spad.PaddingTop = UDim.new(0, 8)
spad.PaddingLeft = UDim.new(0, 6)
spad.PaddingRight = UDim.new(0, 6)
spad.Parent = sidebar

local sep = Instance.new("Frame")
sep.Size = UDim2.new(0, 1, 1, -TITLE_H)
sep.Position = UDim2.new(0, SIDEBAR_W, 0, TITLE_H)
sep.BackgroundColor3 = C.border
sep.BackgroundTransparency = 0.92
sep.BorderSizePixel = 0
sep.Parent = win

local content = Instance.new("ScrollingFrame")
content.Name = "content"
content.Size = UDim2.new(1, -(SIDEBAR_W + 1), 1, -TITLE_H)
content.Position = UDim2.new(0, SIDEBAR_W + 1, 0, TITLE_H)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = C.accent
content.Parent = win
local cl = Instance.new("UIListLayout")
cl.Padding = UDim.new(0, 6)
cl.SortOrder = Enum.SortOrder.LayoutOrder
cl.Parent = content
local cpad = Instance.new("UIPadding")
cpad.PaddingTop = UDim.new(0, 12)
cpad.PaddingBottom = UDim.new(0, 12)
cpad.PaddingLeft = UDim.new(0, 12)
cpad.PaddingRight = UDim.new(0, 12)
cpad.Parent = content

-- ============================================================================
-- SECTION 5 — COMPONENTS
-- ============================================================================

local function secLabel(parent, text)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.Size = UDim2.new(1, 0, 0, 22)
    f.Parent = parent
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1, 0, 1, 0)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 10
    l.TextColor3 = C.accent
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = string.upper(text)
    l.Parent = f
    return f
end

local function mkCard(parent)
    local c = Instance.new("Frame")
    c.BackgroundColor3 = C.card
    c.BorderSizePixel = 0
    c.AutomaticSize = Enum.AutomaticSize.Y
    c.Size = UDim2.new(1, 0, 0, 0)
    c.Parent = parent
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 7); cr.Parent = c
    local st = Instance.new("UIStroke"); st.Color = C.border; st.Transparency = 0.92; st.Thickness = 1; st.Parent = c
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 4)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = c
    local pd = Instance.new("UIPadding")
    pd.PaddingLeft = UDim.new(0, 10); pd.PaddingRight = UDim.new(0, 10)
    pd.PaddingTop = UDim.new(0, 8); pd.PaddingBottom = UDim.new(0, 8)
    pd.Parent = c
    return c
end

local function mkDivider(parent)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, 0, 0, 1)
    d.BackgroundColor3 = C.border
    d.BackgroundTransparency = 0.9
    d.BorderSizePixel = 0
    d.Parent = parent
end

local function mkToggle(parent, label, cfgKey, onToggle)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 30)
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = C.textMid
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = row

    local pill = Instance.new("TextButton")
    pill.Size = UDim2.new(0, 42, 0, 22)
    pill.Position = UDim2.new(1, -42, 0.5, -11)
    pill.BackgroundColor3 = C.card
    pill.BorderSizePixel = 0
    pill.Text = ""
    pill.AutoButtonColor = false
    pill.Parent = row
    local pcr = Instance.new("UICorner"); pcr.CornerRadius = UDim.new(1, 0); pcr.Parent = pill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0
    knob.Parent = pill
    local kcr = Instance.new("UICorner"); kcr.CornerRadius = UDim.new(1, 0); kcr.Parent = knob

    local state = CFG[cfgKey] and true or false
    local function render()
        tw(pill, 0.12, { BackgroundColor3 = state and C.accent or C.card })
        tw(knob, 0.12, { Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) })
    end
    render()

    local function set(v)
        state = v and true or false
        CFG[cfgKey] = state
        render()
        if onToggle then pcall(onToggle, state) end
    end
    pill.MouseButton1Click:Connect(function() set(not state) end)
    return set
end

local function mkSlider(parent, label, cfgKey, min, max, step, onChanged)
    local outer = Instance.new("Frame")
    outer.BackgroundTransparency = 1
    outer.Size = UDim2.new(1, 0, 0, 44)
    outer.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -60, 0, 18)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = C.textMid
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = outer

    local val = Instance.new("TextLabel")
    val.BackgroundTransparency = 1
    val.Position = UDim2.new(1, -60, 0, 0)
    val.Size = UDim2.new(0, 60, 0, 18)
    val.Font = Enum.Font.GothamBold
    val.TextSize = 12
    val.TextColor3 = C.accent
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Parent = outer

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 5)
    track.Position = UDim2.new(0, 0, 0, 26)
    track.BackgroundColor3 = C.card
    track.BorderSizePixel = 0
    track.Parent = outer
    local tcr = Instance.new("UICorner"); tcr.CornerRadius = UDim.new(1, 0); tcr.Parent = track

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    local fcr = Instance.new("UICorner"); fcr.CornerRadius = UDim.new(1, 0); fcr.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Parent = track
    local kcr = Instance.new("UICorner"); kcr.CornerRadius = UDim.new(1, 0); kcr.Parent = knob

    local function fmt(v)
        if step < 0.1 then return string.format("%.2f", v) end
        if step < 1 then return string.format("%.1f", v) end
        return tostring(math.floor(v + 0.5))
    end

    local dragging = false
    local function render(v)
        local rel = (max > min) and ((v - min) / (max - min)) or 0
        rel = math.clamp(rel, 0, 1)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        val.Text = fmt(v)
    end
    render(CFG[cfgKey] or min)

    local function applyInput(posX)
        local rel = math.clamp((posX - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local raw = min + (max - min) * rel
        local snapped = math.round(raw / step) * step
        snapped = math.clamp(snapped, min, max)
        CFG[cfgKey] = snapped
        render(snapped)
        if onChanged then pcall(onChanged, snapped) end
    end

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            applyInput(inp.Position.X)
        end
    end)
    knob.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            applyInput(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    local function set(v)
        v = math.clamp(math.round(v / step) * step, min, max)
        CFG[cfgKey] = v
        render(v)
        if onChanged then pcall(onChanged, v) end
    end
    return set
end

local function mkBtn(parent, label, fn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 30)
    b.BackgroundColor3 = C.card
    b.BorderSizePixel = 0
    b.Text = label
    b.Font = Enum.Font.Gotham
    b.TextSize = 12
    b.TextColor3 = C.textMid
    b.AutoButtonColor = false
    b.Parent = parent
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 6); cr.Parent = b
    local st = Instance.new("UIStroke"); st.Color = C.border; st.Transparency = 0.92; st.Thickness = 1; st.Parent = b

    b.MouseEnter:Connect(function() tw(b, 0.08, { BackgroundColor3 = C.cardHov }) end)
    b.MouseLeave:Connect(function() tw(b, 0.08, { BackgroundColor3 = C.card }) end)
    b.MouseButton1Down:Connect(function() tw(b, 0.05, { BackgroundColor3 = C.accentDk }) end)
    b.MouseButton1Up:Connect(function() tw(b, 0.05, { BackgroundColor3 = C.card }) end)
    b.MouseButton1Click:Connect(function() if fn then pcall(fn) end end)
    return b
end

local function mkDrop(parent, label, options, cfgKey, onChanged)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 30)
    row.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = C.textMid
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = row

    local current = CFG[cfgKey] or options[1]
    CFG[cfgKey] = current

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.48, 0, 0, 24)
    btn.Position = UDim2.new(0.52, 0, 0.5, -12)
    btn.BackgroundColor3 = C.card
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.TextColor3 = C.accent
    btn.Text = "▾  " .. tostring(current)
    btn.AutoButtonColor = false
    btn.Parent = row
    local bcr = Instance.new("UICorner"); bcr.CornerRadius = UDim.new(0, 5); bcr.Parent = btn
    local bst = Instance.new("UIStroke"); bst.Color = C.border; bst.Transparency = 0.92; bst.Thickness = 1; bst.Parent = btn

    local list = Instance.new("Frame")
    list.Size = UDim2.new(0, 150, 0, 0)
    list.Position = UDim2.new(1, -150, 0, 30)
    list.BackgroundColor3 = C.surface
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 10
    list.ClipsDescendants = true
    list.Parent = row
    local lcr = Instance.new("UICorner"); lcr.CornerRadius = UDim.new(0, 5); lcr.Parent = list
    local lst = Instance.new("UIStroke"); lst.Color = C.accent; lst.Transparency = 0.5; lst.Thickness = 1; lst.Parent = list
    local ll = Instance.new("UIListLayout"); ll.Padding = UDim.new(0, 0); ll.Parent = list

    local open = false
    for i, opt in ipairs(options) do
        local o = Instance.new("TextButton")
        o.Size = UDim2.new(1, 0, 0, 24)
        o.BackgroundColor3 = C.surface
        o.BorderSizePixel = 0
        o.Font = Enum.Font.Gotham
        o.TextSize = 11
        o.TextColor3 = C.textMid
        o.Text = tostring(opt)
        o.AutoButtonColor = false
        o.LayoutOrder = i
        o.Parent = list
        o.MouseEnter:Connect(function() o.BackgroundColor3 = C.cardHov end)
        o.MouseLeave:Connect(function() o.BackgroundColor3 = C.surface end)
        o.MouseButton1Click:Connect(function()
            current = opt
            CFG[cfgKey] = opt
            btn.Text = "▾  " .. tostring(opt)
            open = false
            tw(list, 0.12, { Size = UDim2.new(0, 150, 0, 0) })
            task.delay(0.13, function() list.Visible = false end)
            if onChanged then pcall(onChanged, opt) end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            list.Visible = true
            tw(list, 0.12, { Size = UDim2.new(0, 150, 0, 24 * #options) })
        else
            tw(list, 0.12, { Size = UDim2.new(0, 150, 0, 0) })
            task.delay(0.13, function() list.Visible = false end)
        end
    end)
    return function(v) current = v; CFG[cfgKey] = v; btn.Text = "▾  " .. tostring(v) end
end

-- FIX 1: color picker panel now lives inside the row as a floating frame with ZIndex,
-- so it doesn't push sibling rows in the card's UIListLayout.
local function mkColorPicker(parent, label, cfgKey, onChanged)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 30)
    row.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = C.textMid
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = row

    local sw = Instance.new("TextButton")
    sw.Size = UDim2.new(0, 28, 0, 20)
    sw.Position = UDim2.new(1, -28, 0.5, -10)
    sw.BackgroundColor3 = CFG[cfgKey] or Color3.fromRGB(255,255,255)
    sw.BorderSizePixel = 0
    sw.Text = ""
    sw.AutoButtonColor = false
    sw.Parent = row
    local scr = Instance.new("UICorner"); scr.CornerRadius = UDim.new(0, 4); scr.Parent = sw
    local sst = Instance.new("UIStroke"); sst.Color = C.border; sst.Transparency = 0.7; sst.Thickness = 1; sst.Parent = sw

    local holder = Instance.new("Frame")
    holder.BackgroundColor3 = C.cardHov
    holder.BorderSizePixel = 0
    holder.Size = UDim2.new(1, -8, 0, 0)
    holder.Position = UDim2.new(0, 4, 1, 4)
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.Visible = false
    holder.ZIndex = 20
    holder.ClipsDescendants = true
    holder.Parent = row
    local hcr = Instance.new("UICorner"); hcr.CornerRadius = UDim.new(0, 5); hcr.Parent = holder
    local hst = Instance.new("UIStroke"); hst.Color = C.border; hst.Transparency = 0.85; hst.Thickness = 1; hst.Parent = holder
    local hl = Instance.new("UIListLayout"); hl.Padding = UDim.new(0, 2); hl.Parent = holder
    local hpad = Instance.new("UIPadding")
    hpad.PaddingLeft = UDim.new(0, 8); hpad.PaddingRight = UDim.new(0, 8)
    hpad.PaddingTop = UDim.new(0, 4); hpad.PaddingBottom = UDim.new(0, 4)
    hpad.Parent = holder

    local vals = {
        R = math.floor((CFG[cfgKey] or Color3.fromRGB(255,255,255)).R * 255 + 0.5),
        G = math.floor((CFG[cfgKey] or Color3.fromRGB(255,255,255)).G * 255 + 0.5),
        B = math.floor((CFG[cfgKey] or Color3.fromRGB(255,255,255)).B * 255 + 0.5),
    }

    local function rebuild()
        sw.BackgroundColor3 = Color3.fromRGB(vals.R, vals.G, vals.B)
        CFG[cfgKey] = sw.BackgroundColor3
        if onChanged then pcall(onChanged, sw.BackgroundColor3) end
    end

    for _, ch in ipairs({"R","G","B"}) do
        local chanRow = Instance.new("Frame")
        chanRow.BackgroundTransparency = 1
        chanRow.Size = UDim2.new(1, 0, 0, 22)
        chanRow.Parent = holder
        local clbl = Instance.new("TextLabel")
        clbl.BackgroundTransparency = 1
        clbl.Size = UDim2.new(0, 20, 1, 0)
        clbl.Font = Enum.Font.GothamBold
        clbl.TextSize = 11
        clbl.TextColor3 = C.textMid
        clbl.Text = ch
        clbl.TextXAlignment = Enum.TextXAlignment.Left
        clbl.Parent = chanRow
        local valLbl = Instance.new("TextLabel")
        valLbl.BackgroundTransparency = 1
        valLbl.Position = UDim2.new(1, -30, 0, 0)
        valLbl.Size = UDim2.new(0, 30, 1, 0)
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextSize = 10
        valLbl.TextColor3 = C.accent
        valLbl.Text = tostring(vals[ch])
        valLbl.Parent = chanRow
        local trk = Instance.new("Frame")
        trk.Position = UDim2.new(0, 26, 0.5, -2)
        trk.Size = UDim2.new(1, -62, 0, 4)
        trk.BackgroundColor3 = C.bg
        trk.BorderSizePixel = 0
        trk.Parent = chanRow
        local tcr2 = Instance.new("UICorner"); tcr2.CornerRadius = UDim.new(1, 0); tcr2.Parent = trk
        local fl = Instance.new("Frame")
        fl.Size = UDim2.new(vals[ch] / 255, 0, 1, 0)
        fl.BackgroundColor3 = C.accent
        fl.BorderSizePixel = 0
        fl.Parent = trk
        local fcr2 = Instance.new("UICorner"); fcr2.CornerRadius = UDim.new(1, 0); fcr2.Parent = fl
        local dragging2 = false
        local function apply(px)
            local rel = math.clamp((px - trk.AbsolutePosition.X) / math.max(trk.AbsoluteSize.X, 1), 0, 1)
            local v = math.floor(rel * 255 + 0.5)
            vals[ch] = v
            fl.Size = UDim2.new(rel, 0, 1, 0)
            valLbl.Text = tostring(v)
            rebuild()
        end
        trk.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging2 = true; apply(inp.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging2 and inp.UserInputType == Enum.UserInputType.MouseMovement then apply(inp.Position.X) end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging2 = false end
        end)
    end

    local open = false
    sw.MouseButton1Click:Connect(function()
        open = not open
        holder.Visible = open
    end)
end

-- FIX 2: st.Parent = st.Parent or btn  →  st.Parent = btn
local function mkKeybind(parent, label, cfgKey)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 30)
    row.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = C.textMid
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 90, 0, 24)
    btn.Position = UDim2.new(1, -90, 0.5, -12)
    btn.BackgroundColor3 = C.card
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = C.accent
    btn.Text = tostring(CFG[cfgKey].Name or CFG[cfgKey])
    btn.AutoButtonColor = false
    btn.Parent = row
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 5); cr.Parent = btn
    local st = Instance.new("UIStroke"); st.Color = C.border; st.Transparency = 0.92; st.Thickness = 1; st.Parent = btn

    local listening = false
    btn.MouseButton1Click:Connect(function()
        listening = true
        btn.Text = "[ ... ]"
        btn.TextColor3 = C.warn
    end)
    UserInputService.InputBegan:Connect(function(inp)
        if not listening then return end
        if inp.UserInputType == Enum.UserInputType.Keyboard then
            CFG[cfgKey] = inp.KeyCode
            btn.Text = inp.KeyCode.Name
            btn.TextColor3 = C.accent
            listening = false
        elseif inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.MouseButton2 then
            listening = false
            btn.Text = tostring(CFG[cfgKey].Name or CFG[cfgKey])
            btn.TextColor3 = C.accent
        end
    end)
end

-- FIX 3: FPS read from a cached variable updated by the main RenderStepped loop
-- instead of yielding the info-row thread every 0.5s.
local _cachedFPS = 60
local function mkInfoRow(parent, label, getter)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 22)
    row.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.55, 0, 1, 0)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextColor3 = C.textDim
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    lbl.Parent = row
    local val = Instance.new("TextLabel")
    val.BackgroundTransparency = 1
    val.Position = UDim2.new(0.55, 0, 0, 0)
    val.Size = UDim2.new(0.45, 0, 1, 0)
    val.Font = Enum.Font.GothamBold
    val.TextSize = 11
    val.TextColor3 = C.accent
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Text = "..."
    val.Parent = row
    task.spawn(function()
        while row.Parent do
            local ok, v = pcall(getter)
            val.Text = ok and tostring(v) or "—"
            task.wait(0.5)
        end
    end)
    return row
end

local function mkScrollList(parent, height)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 0, height or 120)
    sf.BackgroundColor3 = C.bg
    sf.BackgroundTransparency = 0.4
    sf.BorderSizePixel = 0
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = C.accent
    sf.Parent = parent
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 5); cr.Parent = sf
    local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 2); lay.Parent = sf
    local pd = Instance.new("UIPadding")
    pd.PaddingLeft = UDim.new(0, 6); pd.PaddingRight = UDim.new(0, 6)
    pd.PaddingTop = UDim.new(0, 6); pd.PaddingBottom = UDim.new(0, 6)
    pd.Parent = sf

    local function addRow(text, onClick, btnText)
        local r = Instance.new("Frame")
        r.Size = UDim2.new(1, -2, 0, 26)
        r.BackgroundColor3 = C.card
        r.BorderSizePixel = 0
        r.Parent = sf
        local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 4); rc.Parent = r
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Size = UDim2.new(0.7, -34, 1, 0)
        l.Font = Enum.Font.Gotham
        l.TextSize = 11
        l.TextColor3 = C.textMid
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTruncate = Enum.TextTruncate.AtEnd
        l.Position = UDim2.new(0, 6, 0, 0)
        l.Text = text
        l.Parent = r
        if onClick then
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 50, 0, 18)
            b.Position = UDim2.new(1, -56, 0.5, -9)
            b.BackgroundColor3 = C.accentDk
            b.BorderSizePixel = 0
            b.Font = Enum.Font.GothamBold
            b.TextSize = 10
            b.TextColor3 = C.text
            b.Text = btnText or "Get"
            b.AutoButtonColor = false
            b.Parent = r
            local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 3); bc.Parent = b
            b.MouseButton1Click:Connect(function() pcall(onClick) end)
        end
        return r
    end
    return sf, addRow
end

-- ============================================================================
-- SECTION 6 — PAGES
-- ============================================================================

local PAGE_NAMES = {"Home","Combat","ESP","Movement","Visuals","Teleportation",
                    "Spawning","Prison","Players","Settings"}
local PAGE_ICONS = {Home="⊞",Combat="⊕",ESP="◈",Movement="⊿",Visuals="◉",
                    Teleportation="⊙",Spawning="⊛",Prison="⊠",Players="◎",Settings="⊡"}

local PAGES, NAVBTNS = {}, {}

for i, name in ipairs(PAGE_NAMES) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = C.bg
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = i
    btn.Parent = sidebar
    local bcr = Instance.new("UICorner"); bcr.CornerRadius = UDim.new(0, 5); bcr.Parent = btn

    local ind = Instance.new("Frame")
    ind.Name = "_ind"
    ind.Size = UDim2.new(0, 2, 0, 18)
    ind.Position = UDim2.new(0, 2, 0.5, -9)
    ind.BackgroundColor3 = C.accent
    ind.BorderSizePixel = 0
    ind.BackgroundTransparency = 1
    ind.Parent = btn
    local icr = Instance.new("UICorner"); icr.CornerRadius = UDim.new(1, 0); icr.Parent = ind

    local icon = Instance.new("TextLabel")
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.new(0, 22, 1, 0)
    icon.Position = UDim2.new(0, 10, 0, 0)
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 12
    icon.TextColor3 = C.textDim
    icon.Text = PAGE_ICONS[name]
    icon.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -36, 1, 0)
    lbl.Position = UDim2.new(0, 34, 0, 0)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = C.textDim
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = name
    lbl.Parent = btn

    NAVBTNS[name] = btn

    local pg = Instance.new("Frame")
    pg.Size = UDim2.new(1, 0, 0, 0)
    pg.AutomaticSize = Enum.AutomaticSize.Y
    pg.BackgroundTransparency = 1
    pg.Visible = false
    pg.LayoutOrder = i
    pg.Parent = content
    local pgl = Instance.new("UIListLayout"); pgl.Padding = UDim.new(0, 6); pgl.SortOrder = Enum.SortOrder.LayoutOrder; pgl.Parent = pg
    PAGES[name] = pg
end

local function setPage(name)
    CFG.Page = name
    for n, frame in pairs(PAGES) do frame.Visible = (n == name) end
    for n, btn in pairs(NAVBTNS) do
        local active = (n == name)
        tw(btn, 0.1, {
            BackgroundColor3 = active and Color3.fromRGB(20,22,32) or C.bg,
            BackgroundTransparency = active and 0 or 1,
        })
        local ind = btn:FindFirstChild("_ind")
        if ind then tw(ind, 0.1, { BackgroundTransparency = active and 0 or 1 }) end
        for _, ch in ipairs(btn:GetChildren()) do
            if ch:IsA("TextLabel") and ch.Text ~= PAGE_ICONS[n] then
                ch.TextColor3 = active and C.text or C.textDim
            end
        end
    end
end

-- ============================================================================
-- SECTION 7 — HOME PAGE
-- ============================================================================

do
    local pg = PAGES.Home
    local c1 = mkCard(pg)
    local wn = Instance.new("TextLabel")
    wn.BackgroundTransparency = 1
    wn.Size = UDim2.new(1, 0, 0, 24)
    wn.Font = Enum.Font.GothamBold
    wn.TextSize = 18
    wn.TextColor3 = C.text
    wn.TextXAlignment = Enum.TextXAlignment.Left
    wn.Text = lp.DisplayName or lp.Name
    wn.Parent = c1
    local sub = Instance.new("TextLabel")
    sub.BackgroundTransparency = 1
    sub.Size = UDim2.new(1, 0, 0, 16)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 12
    sub.TextColor3 = C.textDim
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Text = "Valley Prison  ·  NyxScript  ·  v2.0"
    sub.Parent = c1
    local hint = Instance.new("TextLabel")
    hint.BackgroundTransparency = 1
    hint.Size = UDim2.new(1, 0, 0, 14)
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 11
    hint.TextColor3 = C.accent
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.Text = "Right Shift to toggle menu"
    hint.Parent = c1

    local c2 = mkCard(pg)
    secLabel(c2, "Quick Status")
    mkInfoRow(c2, "Players", function() return #Players:GetPlayers() end)
    mkInfoRow(c2, "Your Team", function() return lp.Team and lp.Team.Name or "None" end)
    mkInfoRow(c2, "Health", function()
        local h = hum(lp); return h and (math.floor(h.Health).."/"..math.floor(h.MaxHealth)) or "—"
    end)
    mkInfoRow(c2, "Ping", function() return math.floor(lp:GetNetworkPing() * 1000) .. "ms" end)
    mkInfoRow(c2, "FPS", function() return _cachedFPS end)
    mkInfoRow(c2, "Active Cheats", function()
        local n = 0
        for k, v in pairs(CFG) do
            if type(v) == "boolean" and v and k ~= "Open" and k ~= "TeamColors"
               and k ~= "AntiKick" and k ~= "ShowNotify" then
                n = n + 1
            end
        end
        return n
    end)

    local c3 = mkCard(pg)
    secLabel(c3, "Quick Toggles")
    mkToggle(c3, "Player ESP", "PlayerESP")
    mkToggle(c3, "Aimbot", "Aimbot")
    mkToggle(c3, "Fly", "Fly", function(v)
        if v then _G._startFly and _G._startFly() else _G._stopFly and _G._stopFly() end
    end)
    mkToggle(c3, "Speed Hack", "SpeedEnabled")
    mkToggle(c3, "Infinite Stamina", "InfStamina")
    mkToggle(c3, "Anti-Kick", "AntiKick")
end

-- ============================================================================
-- SECTION 8 — COMBAT PAGE
-- ============================================================================

do
    local pg = PAGES.Combat
    secLabel(pg, "Aimbot")
    local c = mkCard(pg)
    mkToggle(c, "Aimbot", "Aimbot")
    mkToggle(c, "Aimlock (hard snap)", "Aimlock")
    mkToggle(c, "FOV Ring", "AimbotFOVRing")
    mkColorPicker(c, "FOV Ring Color", "AimbotFOVRingColor")
    mkToggle(c, "Require Gun", "AimbotRequireGun")
    mkToggle(c, "Wall Check", "AimbotWallCheck")
    mkToggle(c, "Team Check", "AimbotTeamCheck")
    mkSlider(c, "FOV Radius", "AimbotFOV", 30, 400, 5)
    mkSlider(c, "Smooth (0.02=snap, 1.0=slow)", "AimbotSmooth", 0.02, 1.0, 0.01)
    mkDrop(c, "Aim Part", {"Head","HumanoidRootPart","UpperTorso","Torso","RightUpperArm"}, "AimbotPart")

    secLabel(pg, "Silent Aim")
    local c2 = mkCard(pg)
    mkToggle(c2, "Silent Aim (hold RMB)", "SilentAim", function(v)
        if v then _G._hookSilentAim and _G._hookSilentAim() end
    end)

    secLabel(pg, "Triggerbot")
    local c3 = mkCard(pg)
    mkToggle(c3, "Triggerbot", "Triggerbot")
    mkSlider(c3, "Trigger Delay", "TriggerbotDelay", 0.01, 0.5, 0.01)

    secLabel(pg, "Weapon Mods")
    local c4 = mkCard(pg)
    mkToggle(c4, "No Recoil", "NoRecoil")
    mkToggle(c4, "No Spread / Bloom", "NoSpread")
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
-- SECTION 9 — ESP PAGE
-- ============================================================================

do
    local pg = PAGES.ESP
    secLabel(pg, "Player ESP")
    local c1 = mkCard(pg)
    mkToggle(c1, "Player Highlight", "PlayerESP")
    mkToggle(c1, "Wallhack (AlwaysOnTop)", "WallHack")
    mkToggle(c1, "Box ESP", "BoxESP")
    mkToggle(c1, "Tracer Lines", "TracerESP")
    mkToggle(c1, "Skeleton ESP", "SkeletonESP")
    mkToggle(c1, "Chams", "ChamsESP")
    mkToggle(c1, "Team Colors", "TeamColors")
    mkSlider(c1, "Max Distance", "ESPMaxDist", 250, 1000, 25)

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
    mkColorPicker(c3, "Skeleton Color", "SkeletonColor")
    mkColorPicker(c3, "Tracer Color", "TracerColor")
    mkColorPicker(c3, "Box Color", "BoxESPColor")
    mkSlider(c3, "Tracer Thickness", "TracerThickness", 1, 4, 0.5)
    mkDrop(c3, "Tracer Origin", {"Bottom","Center","Top","Mouse"}, "TracerOrigin")
    mkColorPicker(c3, "Chams Color", "ChamsColor")

    secLabel(pg, "World ESP")
    local c4 = mkCard(pg)
    mkToggle(c4, "Item ESP", "ItemESP")
    mkToggle(c4, "Weapon ESP", "WeaponESP")
    mkToggle(c4, "Keycard ESP", "KeycardESP")
    mkSlider(c4, "Item Max Distance", "ItemESPMaxDist", 50, 500, 25)
end

-- ============================================================================
-- SECTION 10 — MOVEMENT PAGE
-- ============================================================================

do
    local pg = PAGES.Movement
    secLabel(pg, "Speed")
    local c1 = mkCard(pg)
    mkToggle(c1, "Speed Hack", "SpeedEnabled")
    mkSlider(c1, "Walk Speed", "Speed", 16, 64, 1)
    mkToggle(c1, "Bunny Hop", "BunnyHop")

    secLabel(pg, "Flight")
    local c2 = mkCard(pg)
    mkToggle(c2, "Fly", "Fly", function(v)
        if v then _G._startFly and _G._startFly() else _G._stopFly and _G._stopFly() end
    end)
    mkSlider(c2, "Fly Speed", "FlySpeed", 5, 64, 1)
    local fi = Instance.new("TextLabel")
    fi.BackgroundTransparency = 1
    fi.Size = UDim2.new(1, 0, 0, 16)
    fi.Font = Enum.Font.Gotham
    fi.TextSize = 10
    fi.TextColor3 = C.textDim
    fi.TextXAlignment = Enum.TextXAlignment.Left
    fi.Text = "WASD = direction  ·  Space = up  ·  Ctrl = down"
    fi.Parent = c2

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
    mkToggle(c4, "Anti-Gravity", "AntiGravity", function(v)
        workspace.Gravity = v and CFG.GravityValue or 196.2
    end)
    mkSlider(c4, "Gravity Value", "GravityValue", 0, 196, 5, function(v)
        if CFG.AntiGravity then workspace.Gravity = v end
    end)

    secLabel(pg, "Other")
    local c5 = mkCard(pg)
    mkToggle(c5, "Noclip", "Noclip")
    mkToggle(c5, "Infinite Stamina", "InfStamina")
    mkToggle(c5, "Teleport to Cursor (hold T)", "TpToCursor")
end

-- ============================================================================
-- SECTION 11 — VISUALS PAGE
-- ============================================================================

do
    local pg = PAGES.Visuals
    secLabel(pg, "Lighting")
    local c1 = mkCard(pg)
    mkToggle(c1, "Fullbright", "Fullbright", function(v) _G._applyFullbright and _G._applyFullbright(v) end)
    mkToggle(c1, "No Fog", "NoFog")
    mkToggle(c1, "No Bloom", "NoBloom")
    mkToggle(c1, "No Blur / DOF", "NoBlur")

    secLabel(pg, "Clock")
    local c2 = mkCard(pg)
    mkToggle(c2, "Custom Time", "TimeOfDay", function(v)
        if v then Lighting.ClockTime = CFG.TimeValue end
    end)
    mkSlider(c2, "Time of Day", "TimeValue", 0, 24, 0.25, function(v)
        if CFG.TimeOfDay then Lighting.ClockTime = v end
    end)
    mkInfoRow(c2, "Current ClockTime", function() return string.format("%.2f", Lighting.ClockTime) end)

    secLabel(pg, "Camera")
    local c3 = mkCard(pg)
    mkToggle(c3, "Third Person Camera", "ThirdPerson", function(v)
        if v then _G._startThirdPerson and _G._startThirdPerson()
        else _G._stopThirdPerson and _G._stopThirdPerson() end
    end)
    mkSlider(c3, "Third Person Distance", "ThirdPersonDist", 5, 30, 1)
    mkToggle(c3, "FOV Zoom Hack", "ZoomHack", function(v)
        cam.FieldOfView = v and CFG.ZoomFOV or 70
    end)
    mkSlider(c3, "Custom FOV", "ZoomFOV", 30, 120, 1, function(v)
        if CFG.ZoomHack then cam.FieldOfView = v end
    end)

    secLabel(pg, "Character")
    local c4 = mkCard(pg)
    mkToggle(c4, "Rainbow Character", "Rainbow")
    mkToggle(c4, "Invisible Character", "InvisibleChar", function(v)
        local ch = chr(lp); if not ch then return end
        for _, p in ipairs(ch:GetDescendants()) do
            if p:IsA("BasePart") then p.LocalTransparencyModifier = v and 1 or 0 end
        end
    end)
    mkToggle(c4, "Custom Character Color", "CustomCharColor")
    mkColorPicker(c4, "Character Color", "CustomCharColor3", function(col)
        local ch = chr(lp); if not ch then return end
        for _, p in ipairs(ch:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.Color = col
            end
        end
    end)
end

-- ============================================================================
-- SECTION 12 — TELEPORTATION PAGE
-- ============================================================================

do
    local pg = PAGES.Teleportation
    secLabel(pg, "Locations")
    local c1 = mkCard(pg)
    local LOCATIONS = {
        "Main Gate","Guard Room","Armory","Cafeteria","Visitor Lobby","Control Room",
        "Cell Block A","Cell Block B","Warden's Office","Medical Bay","Courtyard",
        "Parking Lot","Evidence Room","Prison Roof"
    }
    for _, locName in ipairs(LOCATIONS) do
        mkBtn(c1, locName, function()
            -- FIX 5: exact-name match first, then substring fallback with longest-name priority.
            local target
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("BasePart") and d.Name == locName then target = d; break end
            end
            if not target then
                local bestLen = 0
                for _, d in ipairs(workspace:GetDescendants()) do
                    if d:IsA("BasePart") then
                        local nl = d.Name:lower()
                        local ql = locName:lower()
                        if nl:find(ql, 1, true) and #nl > bestLen then
                            target = d; bestLen = #nl
                        end
                    end
                end
            end
            local r = root(lp)
            if target and r then
                r.CFrame = target.CFrame + Vector3.new(0, 4, 0)
                notify("TP → " .. locName, "ok")
            else
                notify(locName .. " — not found in world", "warn")
            end
        end)
    end

    secLabel(pg, "Player Teleport")
    local c2 = mkCard(pg)
    local tpList
    local function rebuildTp()
        if tpList then tpList:Destroy() end
        local sf, addRow = mkScrollList(c2, 140)
        tpList = sf
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= lp then
                local r = addRow(pl.Name, function()
                    local t, m = root(pl), root(lp)
                    if t and m then m.CFrame = t.CFrame + Vector3.new(2, 0, 0); notify("TP → "..pl.Name, "ok") end
                end, "→ TP")
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(0, 50, 0, 18)
                b.Position = UDim2.new(1, -110, 0.5, -9)
                b.BackgroundColor3 = C.accent2
                b.BorderSizePixel = 0
                b.Font = Enum.Font.GothamBold
                b.TextSize = 10
                b.TextColor3 = C.text
                b.Text = "← Me"
                b.AutoButtonColor = false
                b.Parent = r
                local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 3); bc.Parent = b
                b.MouseButton1Click:Connect(function()
                    local t, m = root(pl), root(lp)
                    if t and m then
                        pcall(function() t.CFrame = m.CFrame + Vector3.new(2, 0, 0) end)
                        notify("Bring → "..pl.Name, "info")
                    end
                end)
            end
        end
        mkBtn(c2, "Refresh Player List", rebuildTp)
    end
    rebuildTp()
    Players.PlayerAdded:Connect(rebuildTp)
    Players.PlayerRemoving:Connect(rebuildTp)

    secLabel(pg, "Saved Positions")
    local c3 = mkCard(pg)
    local saved = {}
    local savedList
    local function rebuildSaved()
        if savedList then savedList:Destroy() end
        local sf, addRow = mkScrollList(c3, 140)
        savedList = sf
        for i, sp in ipairs(saved) do
            addRow(sp.name, function()
                local r = root(lp)
                if r then r.CFrame = sp.cf; notify("TP → "..sp.name, "ok") end
            end, "Go")
            local rows = sf:GetChildren()
            local lastRow = rows[#rows]
            if lastRow and lastRow:IsA("Frame") then
                local d = Instance.new("TextButton")
                d.Size = UDim2.new(0, 30, 0, 18)
                d.Position = UDim2.new(1, -90, 0.5, -9)
                d.BackgroundColor3 = C.danger
                d.BorderSizePixel = 0
                d.Font = Enum.Font.GothamBold
                d.TextSize = 10
                d.TextColor3 = C.bg
                d.Text = "Del"
                d.AutoButtonColor = false
                d.Parent = lastRow
                local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(0, 3); dc.Parent = d
                d.MouseButton1Click:Connect(function()
                    table.remove(saved, i)
                    rebuildSaved()
                end)
            end
        end
    end
    mkBtn(c3, "Save Current Position", function()
        local r = root(lp)
        if not r then return end
        if #saved >= 20 then notify("Max 20 saved positions", "warn"); return end
        table.insert(saved, {name = "Pos "..(#saved + 1), cf = r.CFrame})
        rebuildSaved()
        notify("Position saved", "ok")
    end)
    rebuildSaved()

    secLabel(pg, "Teleport to Cursor")
    local c4 = mkCard(pg)
    mkToggle(c4, "Enable TP-to-cursor (hold T)", "TpToCursor")
    local info = Instance.new("TextLabel")
    info.BackgroundTransparency = 1
    info.Size = UDim2.new(1, 0, 0, 16)
    info.Font = Enum.Font.Gotham
    info.TextSize = 10
    info.TextColor3 = C.textDim
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.Text = "Hold T, aim at ground, release to TP there."
    info.Parent = c4
end

-- ============================================================================
-- SECTION 13 — SPAWNING PAGE
-- ============================================================================

do
    local pg = PAGES.Spawning
    local function tryGetItem(name)
        local function search(container)
            for _, v in ipairs(container:GetDescendants()) do
                if v:IsA("Tool") and v.Name == name then return v end
            end
            return nil
        end
        local src = search(ReplicatedStorage) or search(workspace)
        if src then
            local ok = pcall(function()
                local clone = src:Clone()
                clone.Parent = lp.Backpack
            end)
            if ok then notify(name.." → backpack", "ok") else notify(name.." clone failed", "err") end
        else
            notify(name.." not in world yet", "warn")
        end
    end

    local CATS = {
        {name="Keycards", items={"Corrections Keycard","Supervisors Keycard","Directors Keycard",
                                 "Employee Keycard","Master Keycard","Developer Keycard"}},
        {name="Materials", items={"Metal","Plastic","Rope","Shiv"}},
        {name="Shotguns", items={"KSG-12","M1014","Model 590","Saiga 12K","Terminator",
                                 "Toz 106","John's KSG","PKSG-12","GEN-12"}},
        {name="SMGs", items={"M1928","M1A1","M3 Grease Gun","MP40","MP5","MP5 Mod","MP7",
                             "MP7 Mod","Scorpion E3","SE3 Express","UMP45","UMP45-X","P90","PUMP45"}},
        {name="Assault Rifles", items={"AMD-65","AK-12","AK-47","AK-74","AR-57","ARP","M4A1",
                                       "HK416","HK416 Patrol","HK416D","G36","G36C","AA .50 Beowulf",
                                       "M16A4","M16A1","SCAR-L","LEO MCX Spear","MCX Spear","The Harrow",
                                       "IMI Galil","L1A1 SLR","SA58 OSW-E","SA58 OSW-L","SA58 OSW","SKS",
                                       "VSS Vintorez","Patriot","AR2","C8IUR","Cat Gun","M4A1 DMR",
                                       "SG 550","Honey Badger"}},
        {name="Pistols", items={"92FS","Makarov","1911 Emperor","SW500","93R","G18","G18C","G17",
                                "Arrow Fed G17","Giant17","Godgun","Paterson 1836","PM82A1"}},
        {name="Heavy / Special", items={"M82A1","Ultimax 100","M249 SAW","Tempest","MGL MK1S"}},
    }
    for _, cat in ipairs(CATS) do
        secLabel(pg, cat.name)
        local c = mkCard(pg)
        local sf, addRow = mkScrollList(c, 130)
        for _, itemName in ipairs(cat.items) do
            addRow(itemName, function() tryGetItem(itemName) end, "Get")
        end
    end

    secLabel(pg, "Backpack Actions")
    local c = mkCard(pg)
    mkBtn(c, "Collect All Dropped Items", function()
        local n = 0
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Tool") then
                local ok = pcall(function() v.Parent = lp.Backpack end)
                if ok then n = n + 1 end
            end
        end
        notify("Collected "..n.." items", "ok")
    end)
    mkBtn(c, "Drop All Items", function()
        local r = root(lp)
        if not r then return end
        for _, v in ipairs(lp.Backpack:GetChildren()) do
            if v:IsA("Tool") then
                pcall(function() v.Parent = workspace; v:SetPrimaryPartCFrame(r.CFrame + Vector3.new(0,2,0)) end)
            end
        end
        notify("Dropped backpack", "info")
    end)
    mkInfoRow(c, "Items in backpack", function()
        local n = 0
        for _, v in ipairs(lp.Backpack:GetChildren()) do if v:IsA("Tool") then n = n + 1 end end
        return n
    end)
end

-- ============================================================================
-- SECTION 14 — PRISON PAGE
-- ============================================================================

do
    local pg = PAGES.Prison
    secLabel(pg, "Bypasses")
    local c1 = mkCard(pg)
    mkBtn(c1, "Unlock Doors (fire door/unlock remotes)", function()
        local n = 0
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                local nl = v.Name:lower()
                if nl:find("door") or nl:find("unlock") or nl:find("open") then
                    pcall(function() v:FireServer() end); n = n + 1
                end
            end
        end
        notify("Fired "..n.." door remotes", "ok")
    end)
    mkBtn(c1, "Remove Handcuffs", function()
        local ch = chr(lp)
        if ch then
            for _, v in ipairs(ch:GetDescendants()) do
                if v:IsA("WeldConstraint") or v:IsA("Weld") then
                    if v.Name:lower():find("cuff") then v:Destroy() end
                end
            end
        end
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                local nl = v.Name:lower()
                if nl:find("escape") or nl:find("uncuff") or nl:find("free") then
                    pcall(function() v:FireServer() end)
                end
            end
        end
        notify("Cuffs removed", "ok")
    end)
    mkBtn(c1, "Force Escape", function()
        local ch = chr(lp)
        if ch then
            for _, v in ipairs(ch:GetDescendants()) do
                if v:IsA("WeldConstraint") or v:IsA("Weld") then v:Destroy() end
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name:lower():find("escape") then
                pcall(function() v:FireServer() end)
            end
        end
        notify("Force escape fired", "warn")
    end)
    mkBtn(c1, "Cancel Arrest (fire arrest remotes)", function()
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                local nl = v.Name:lower()
                if nl:find("arrest") or nl:find("detain") then
                    pcall(function() v:FireServer() end)
                end
            end
        end
        notify("Arrest remotes fired", "info")
    end)

    secLabel(pg, "Team Switcher")
    local c2 = mkCard(pg)
    for _, teamName in ipairs({"Prisoner","Guard","Warden","Visitor","Criminal","Police","Staff","Inmate"}) do
        mkBtn(c2, teamName, function()
            local team = Teams:FindFirstChild(teamName)
            if team then
                pcall(function() lp.Team = team end)
            end
            for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") then
                    local nl = v.Name:lower()
                    if nl:find("team") or nl:find("role") then
                        pcall(function() v:FireServer(teamName) end)
                    end
                end
            end
            notify("Team switch → "..teamName, "info")
        end)
    end

    secLabel(pg, "Remote Monitor")
    local c3 = mkCard(pg)
    mkToggle(c3, "Log All Remotes", "LogRemotes")
    mkToggle(c3, "Block Arrest Remotes", "BlockArrest")
    mkToggle(c3, "Block Ban/Kick Remotes", "BlockBan")
    mkBtn(c3, "List All Remotes", function()
        local n = 0
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                print("[VP Remote] " .. v:GetFullName()); n = n + 1
            end
        end
        notify("Found "..n.." remotes (see output)", "info", 4)
    end)
end

-- ============================================================================
-- SECTION 15 — PLAYERS PAGE
-- ============================================================================

do
    local pg = PAGES.Players
    secLabel(pg, "Player List")
    local c1 = mkCard(pg)
    local plist
    local function rebuild()
        if plist then plist:Destroy() end
        local sf, addRow = mkScrollList(c1, 200)
        plist = sf
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= lp then
                local ping = math.floor(pl:GetNetworkPing() * 1000)
                addRow(pl.Name .. "  ·  " .. ping .. "ms  ·  " .. (pl.Team and pl.Team.Name or "—"),
                    function()
                        local ch = chr(pl)
                        if ch then
                            local hl = Instance.new("Highlight")
                            hl.Adornee = ch
                            hl.FillColor = C.accent2
                            hl.OutlineColor = C.accent2
                            hl.Parent = ch
                            task.delay(3, function() hl:Destroy() end)
                        end
                    end, "Flash")
            end
        end
    end
    rebuild()
    mkBtn(c1, "Refresh", rebuild)
    Players.PlayerAdded:Connect(rebuild)
    Players.PlayerRemoving:Connect(rebuild)

    secLabel(pg, "Local Player Info")
    local c2 = mkCard(pg)
    mkInfoRow(c2, "UserID", function() return lp.UserId end)
    mkInfoRow(c2, "Username", function() return lp.Name end)
    mkInfoRow(c2, "Display Name", function() return lp.DisplayName end)
    mkInfoRow(c2, "Team", function() return lp.Team and lp.Team.Name or "None" end)
    mkInfoRow(c2, "Health", function()
        local h = hum(lp); return h and (math.floor(h.Health).."/"..math.floor(h.MaxHealth)) or "—"
    end)
    mkInfoRow(c2, "Walk Speed", function() local h = hum(lp); return h and h.WalkSpeed or "—" end)
    mkInfoRow(c2, "Position", function()
        local r = root(lp); if not r then return "—" end
        return string.format("%d, %d, %d", r.Position.X, r.Position.Y, r.Position.Z)
    end)
    mkInfoRow(c2, "Ping", function() return math.floor(lp:GetNetworkPing() * 1000).."ms" end)
    mkInfoRow(c2, "Account Age", function() return lp.AccountAge.." days" end)
end

-- ============================================================================
-- SECTION 16 — SETTINGS PAGE
-- ============================================================================

do
    local pg = PAGES.Settings
    secLabel(pg, "Menu")
    local c1 = mkCard(pg)
    mkKeybind(c1, "Menu Toggle Key", "MenuKey")
    mkToggle(c1, "Show Notifications", "ShowNotify")
    mkBtn(c1, "Reset All Settings", function()
        for k, v in pairs(CFG) do
            if type(v) == "boolean" then CFG[k] = (k == "AntiKick" or k == "Open" or k == "ShowNotify") end
        end
        notify("Settings reset — reload script to rebuild UI", "warn", 4)
    end)

    secLabel(pg, "Aimbot Key")
    local c2 = mkCard(pg)
    local aimBtnLbl = Instance.new("TextLabel")
    aimBtnLbl.BackgroundTransparency = 1
    aimBtnLbl.Size = UDim2.new(1, 0, 0, 16)
    aimBtnLbl.Font = Enum.Font.Gotham
    aimBtnLbl.TextSize = 10
    aimBtnLbl.TextColor3 = C.textDim
    aimBtnLbl.TextXAlignment = Enum.TextXAlignment.Left
    aimBtnLbl.Text = "Hold RMB to activate aimbot"
    aimBtnLbl.Parent = c2

    secLabel(pg, "About")
    local c3 = mkCard(pg)
    mkInfoRow(c3, "Game", function() return "Valley Prison" end)
    mkInfoRow(c3, "Script", function() return "NyxScript v2.0" end)
    mkInfoRow(c3, "Build", function() return os.date("%Y-%m-%d") end)
    mkInfoRow(c3, "Toggle Key", function() return CFG.MenuKey.Name or tostring(CFG.MenuKey) end)
end

setPage("Home")

-- ============================================================================
-- SECTION 17 — ANTI-KICK / REMOTE HOOKS
-- ============================================================================

pcall(function()
    if not getrawmetatable then return end
    local mt = getrawmetatable(lp)
    if not mt or not mt.__namecall then return end
    local old = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local m = getnamecallmethod()
        if m == "Kick" and CFG.AntiKick then
            notify("Kick blocked", "warn", 4); return
        end
        if m == "Disconnect" and CFG.AntiDisconnect then
            notify("Disconnect blocked", "warn", 4); return
        end
        return old(self, ...)
    end)
end)

pcall(function()
    if not getrawmetatable then return end
    local mt = getrawmetatable(game)
    if not mt or not mt.__namecall then return end
    local old = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local m = getnamecallmethod()
        if m == "FireServer" or m == "InvokeServer" then
            local n = tostring(self.Name):lower()
            if CFG.BlockArrest and (n:find("arrest") or n:find("cuff") or n:find("detain")) then
                notify("Arrest remote blocked", "ok"); return
            end
            if CFG.BlockBan and (n:find("ban") or n:find("kick") or n:find("punish")) then
                notify("Ban remote blocked", "ok"); return
            end
            if CFG.LogRemotes then
                print(string.format("[VP Remote] %s → %s", m, self:GetFullName()))
            end
        end
        return old(self, ...)
    end)
end)

-- ============================================================================
-- SECTION 18 — SILENT AIM
-- ============================================================================

local _saHooked = false
_G._hookSilentAim = function()
    if _saHooked or not getrawmetatable then return end
    _saHooked = true
    pcall(function()
        local mt = getrawmetatable(game)
        if not mt or not mt.__namecall then return end
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local m = getnamecallmethod()
            if CFG.SilentAim and (m == "FireServer" or m == "InvokeServer") then
                local args = {...}
                local t = _G._getBestTarget and _G._getBestTarget()
                if t then
                    for i, v in ipairs(args) do
                        if typeof(v) == "Vector3" then args[i] = t.Position
                        elseif typeof(v) == "Instance" and v:IsA("BasePart") then args[i] = t end
                    end
                end
                return old(self, table.unpack(args))
            end
            return old(self, ...)
        end)
    end)
end

-- ============================================================================
-- SECTION 19 — AIMBOT
-- ============================================================================

local function teamColor(pl)
    local t = tostring(pl.Team and pl.Team.Name or ""):lower()
    if t:find("guard") or t:find("police") or t:find("warden") or t:find("staff") then
        return Color3.fromRGB(248, 113, 113)
    elseif t:find("prisoner") or t:find("inmate") or t:find("criminal") then
        return Color3.fromRGB(99, 179, 237)
    end
    return Color3.fromRGB(220, 220, 220)
end

_G._getBestTarget = function()
    local vp = cam.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2
    local candidates = {}

    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= lp and isAlive(pl) then
            local skip = false
            if CFG.AimbotTeamCheck and lp.Team and pl.Team == lp.Team then skip = true end
            if dist(pl) > CFG.ESPMaxDist then skip = true end
            if CFG.AimbotRequireGun and not hasGun() then skip = true end
            if not skip then
                local ch = chr(pl)
                local pt = ch and (ch:FindFirstChild(CFG.AimbotPart) or root(pl))
                if pt then
                    local blocked = false
                    if CFG.AimbotWallCheck then
                        local me = root(lp)
                        if me then
                            local params = RaycastParams.new()
                            params.FilterType = Enum.RaycastFilterType.Exclude
                            params.FilterDescendantsInstances = {ch, chr(lp)}
                            local res = workspace:Raycast(me.Position, pt.Position - me.Position, params)
                            if res then blocked = true end
                        end
                    end
                    if not blocked then
                        local sp, vis = cam:WorldToViewportPoint(pt.Position)
                        if vis and sp.Z > 0 then
                            local sd = math.sqrt((sp.X - cx)^2 + (sp.Y - cy)^2)
                            if sd <= CFG.AimbotFOV then
                                table.insert(candidates, {part = pt, sd = sd, player = pl})
                            end
                        end
                    end
                end
            end
        end
    end

    if #candidates == 0 then return nil end
    table.sort(candidates, function(a, b) return a.sd < b.sd end)
    return candidates[1].part
end

local aimBtn = Enum.UserInputType.MouseButton2
RunService:BindToRenderStep("VP_Aim", Enum.RenderPriority.Camera.Value + 1, function()
    if not (CFG.Aimbot or CFG.Aimlock) then return end
    if not UserInputService:IsMouseButtonPressed(aimBtn) then return end
    if CFG.AimbotRequireGun and not hasGun() then return end
    local t = _G._getBestTarget()
    if not t then return end
    local goalCF = CFrame.new(cam.CFrame.Position, t.Position)
    if CFG.Aimlock then
        cam.CFrame = goalCF
    else
        cam.CFrame = cam.CFrame:Lerp(goalCF, math.clamp(CFG.AimbotSmooth, 0.01, 1))
    end
end)

local fovRing
if Drawing then
    pcall(function()
        fovRing = Drawing.new("Circle")
        fovRing.Thickness = 1.2
        fovRing.Filled = false
        fovRing.Visible = false
    end)
end
RunService.RenderStepped:Connect(function()
    if not fovRing then return end
    fovRing.Visible = CFG.AimbotFOVRing and (CFG.Aimbot or CFG.Aimlock)
    if fovRing.Visible then
        local vp = cam.ViewportSize
        fovRing.Position = Vector2.new(vp.X / 2, vp.Y / 2)
        fovRing.Radius = CFG.AimbotFOV
        fovRing.Color = CFG.AimbotFOVRingColor
    end
end)

-- ============================================================================
-- SECTION 20 — ESP SYSTEMS
-- ============================================================================

local espHighlights = {}
local drawPool = {}
local tagFolder = workspace:FindFirstChild("VP_Tags") or Instance.new("Folder")
tagFolder.Name = "VP_Tags"
tagFolder.Parent = workspace

local BONES = {
    {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
}

local function buildESP(pl)
    if pl == lp then return end
    if espHighlights[pl] and espHighlights[pl].Parent then espHighlights[pl]:Destroy() end
    espHighlights[pl] = nil
    local ch = chr(pl)
    if not ch then return end
    local hl = Instance.new("Highlight")
    hl.FillColor = CFG.TeamColors and teamColor(pl) or CFG.ESPFillColor
    hl.OutlineColor = CFG.TeamColors and teamColor(pl) or CFG.ESPOutlineColor
    hl.FillTransparency = CFG.ESPFillTransparency
    hl.OutlineTransparency = CFG.ESPOutlineTransparency
    hl.DepthMode = CFG.WallHack and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    hl.Adornee = ch
    hl.Enabled = CFG.PlayerESP or CFG.ChamsESP
    hl.Parent = ch
    espHighlights[pl] = hl
end

local function buildTag(pl)
    if pl == lp then return end
    local old = tagFolder:FindFirstChild(pl.Name)
    if old then old:Destroy() end
    local ch = chr(pl)
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = pl.Name
    bb.Size = UDim2.new(0, 140, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = hrp
    bb.Parent = tagFolder

    local nameLbl = Instance.new("TextLabel")
    nameLbl.BackgroundTransparency = 1
    nameLbl.Size = UDim2.new(1, 0, 0, 16)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 13
    nameLbl.TextColor3 = Color3.fromRGB(255,255,255)
    nameLbl.TextStrokeTransparency = 0.5
    nameLbl.Text = pl.Name
    nameLbl.Parent = bb

    local infoLbl = Instance.new("TextLabel")
    infoLbl.BackgroundTransparency = 1
    infoLbl.Position = UDim2.new(0, 0, 0, 16)
    infoLbl.Size = UDim2.new(1, 0, 0, 14)
    infoLbl.Font = Enum.Font.Gotham
    infoLbl.TextSize = 11
    infoLbl.TextColor3 = Color3.fromRGB(220,220,220)
    infoLbl.TextStrokeTransparency = 0.5
    infoLbl.Text = ""
    infoLbl.Parent = bb

    local hbarBg = Instance.new("Frame")
    hbarBg.Size = UDim2.new(0, 100, 0, 5)
    hbarBg.Position = UDim2.new(0.5, -50, 1, -8)
    hbarBg.BackgroundColor3 = Color3.fromRGB(30,30,40)
    hbarBg.BorderSizePixel = 0
    hbarBg.Parent = bb
    local hbcr = Instance.new("UICorner"); hbcr.CornerRadius = UDim.new(1, 0); hbcr.Parent = hbarBg

    local hbarFill = Instance.new("Frame")
    hbarFill.AnchorPoint = Vector2.new(0, 0.5)
    hbarFill.Position = UDim2.new(0, 0, 0.5, 0)
    hbarFill.Size = UDim2.new(1, 0, 1, 0)
    hbarFill.BackgroundColor3 = Color3.fromRGB(52,211,153)
    hbarFill.BorderSizePixel = 0
    hbarFill.Parent = hbarBg
    local hfcr = Instance.new("UICorner"); hfcr.CornerRadius = UDim.new(1, 0); hfcr.Parent = hbarFill
end

local function updateTag(pl)
    local bb = tagFolder:FindFirstChild(pl.Name)
    if not bb then return end
    local show = CFG.NameESP or CFG.HealthESP or CFG.DistanceESP
    bb.Enabled = show and dist(pl) <= CFG.ESPMaxDist
    if not bb.Enabled then return end
    local nameLbl = bb:FindFirstChildOfClass("TextLabel")
    local infoLbl = bb:GetChildren()[3]
    local h = hum(pl)
    if nameLbl then nameLbl.Visible = CFG.NameESP end
    if infoLbl and infoLbl:IsA("TextLabel") then
        local parts = {}
        if CFG.HealthESP and h then table.insert(parts, math.floor(h.Health).."hp") end
        if CFG.DistanceESP then table.insert(parts, math.floor(dist(pl)).."m") end
        infoLbl.Text = table.concat(parts, " · ")
    end
    local hbarBg = bb:FindFirstChild("Frame")
    if hbarBg then
        hbarBg.Visible = CFG.HealthESP
        if h and CFG.HealthESP then
            local pct = math.clamp(h.Health / math.max(h.MaxHealth, 1), 0, 1)
            local fill = hbarBg:FindFirstChild("Frame")
            if fill then
                fill.Size = UDim2.new(pct, 0, 1, 0)
                local r, g
                if pct > 0.5 then r = (1 - pct) * 2; g = 1 else r = 1; g = pct * 2 end
                fill.BackgroundColor3 = Color3.new(r, g, 0.2)
            end
        end
    end
end

local function updateHighlight(pl)
    local hl = espHighlights[pl]
    if not hl then return end
    local ch = chr(pl)
    if not ch or hl.Adornee ~= ch then
        if hl.Parent then hl:Destroy() end
        espHighlights[pl] = nil
        return
    end
    local show = CFG.PlayerESP or CFG.ChamsESP
    hl.Enabled = show and dist(pl) <= CFG.ESPMaxDist
    if not show then return end
    if CFG.ChamsESP and not CFG.PlayerESP then
        hl.FillColor = CFG.ChamsColor
        hl.OutlineColor = CFG.ChamsColor
        hl.FillTransparency = 0.4
        hl.OutlineTransparency = 0.2
    else
        local col = CFG.TeamColors and teamColor(pl) or CFG.ESPFillColor
        hl.FillColor = col
        hl.OutlineColor = CFG.TeamColors and col or CFG.ESPOutlineColor
        hl.FillTransparency = CFG.ESPFillTransparency
        hl.OutlineTransparency = CFG.ESPOutlineTransparency
    end
    hl.DepthMode = CFG.WallHack and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
end

local function ensureDrawPool(pl)
    if drawPool[pl] then return drawPool[pl] end
    if not Drawing then return nil end
    local pool = { bones = {}, box = {}, tracer = nil, name = pl.Name }
    local ok = pcall(function()
        for i = 1, #BONES do
            local l = Drawing.new("Line")
            l.Visible = false
            l.Thickness = 1.4
            l.Color = CFG.SkeletonColor
            table.insert(pool.bones, l)
        end
        for i = 1, 4 do
            local l = Drawing.new("Line")
            l.Visible = false
            l.Thickness = 1.2
            l.Color = CFG.BoxESPColor
            table.insert(pool.box, l)
        end
        pool.tracer = Drawing.new("Line")
        pool.tracer.Visible = false
        pool.tracer.Thickness = CFG.TracerThickness
        pool.tracer.Color = CFG.TracerColor
    end)
    if not ok then return nil end
    drawPool[pl] = pool
    return pool
end

local function updateDrawingESP()
    if not Drawing then return end
    local vp = cam.ViewportSize
    local tracerOrigin
    if CFG.TracerOrigin == "Bottom" then tracerOrigin = Vector2.new(vp.X / 2, vp.Y)
    elseif CFG.TracerOrigin == "Center" then tracerOrigin = Vector2.new(vp.X / 2, vp.Y / 2)
    elseif CFG.TracerOrigin == "Top" then tracerOrigin = Vector2.new(vp.X / 2, 0)
    else
        local mp = UserInputService:GetMouseLocation()
        tracerOrigin = Vector2.new(mp.X, mp.Y)
    end

    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= lp and isAlive(pl) then
            local pool = ensureDrawPool(pl)
            if pool then
                local ch = chr(pl)
                local inRange = dist(pl) <= CFG.ESPMaxDist
                for i, pair in ipairs(BONES) do
                    local l = pool.bones[i]
                    if l then
                        local a = ch and ch:FindFirstChild(pair[1])
                        local b = ch and ch:FindFirstChild(pair[2])
                        if CFG.SkeletonESP and inRange and a and b then
                            local sa, va = cam:WorldToViewportPoint(a.Position)
                            local sb, vb = cam:WorldToViewportPoint(b.Position)
                            if va and vb and sa.Z > 0 and sb.Z > 0 then
                                l.From = Vector2.new(sa.X, sa.Y)
                                l.To = Vector2.new(sb.X, sb.Y)
                                l.Color = CFG.SkeletonColor
                                l.Visible = true
                            else l.Visible = false end
                        else l.Visible = false end
                    end
                end
                if CFG.BoxESP and inRange and ch then
                    local minX, minY = math.huge, math.huge
                    local maxX, maxY = -math.huge, -math.huge
                    for _, part in ipairs(ch:GetChildren()) do
                        if part:IsA("BasePart") then
                            local cf = part.CFrame; local s = part.Size
                            for _, sx in ipairs({-1, 1}) do
                                for _, sy in ipairs({-1, 1}) do
                                    for _, sz in ipairs({-1, 1}) do
                                        local corner = cf * Vector3.new(s.X/2*sx, s.Y/2*sy, s.Z/2*sz)
                                        local sp, vis = cam:WorldToViewportPoint(corner)
                                        if vis and sp.Z > 0 then
                                            minX = math.min(minX, sp.X); maxX = math.max(maxX, sp.X)
                                            minY = math.min(minY, sp.Y); maxY = math.max(maxY, sp.Y)
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if minX < math.huge then
                        local p1 = Vector2.new(minX, minY); local p2 = Vector2.new(maxX, minY)
                        local p3 = Vector2.new(maxX, maxY); local p4 = Vector2.new(minX, maxY)
                        local segs = {{p1,p2},{p2,p3},{p3,p4},{p4,p1}}
                        for i = 1, 4 do
                            local l = pool.box[i]
                            if l then
                                l.From = segs[i][1]; l.To = segs[i][2]
                                l.Color = CFG.BoxESPColor; l.Visible = true
                            end
                        end
                    else
                        for _, l in ipairs(pool.box) do l.Visible = false end
                    end
                else
                    for _, l in ipairs(pool.box) do l.Visible = false end
                end
                if CFG.TracerESP and inRange then
                    local hrp = root(pl)
                    if hrp then
                        local sp, vis = cam:WorldToViewportPoint(hrp.Position)
                        if vis and sp.Z > 0 then
                            pool.tracer.From = tracerOrigin
                            pool.tracer.To = Vector2.new(sp.X, sp.Y)
                            pool.tracer.Color = CFG.TracerColor
                            pool.tracer.Thickness = CFG.TracerThickness
                            pool.tracer.Visible = true
                        else pool.tracer.Visible = false end
                    end
                else pool.tracer.Visible = false end
            end
        end
    end
end

local function clearDrawPool(pl)
    local pool = drawPool[pl]
    if not pool then return end
    for _, l in ipairs(pool.bones) do pcall(function() l:Remove() end) end
    for _, l in ipairs(pool.box) do pcall(function() l:Remove() end) end
    if pool.tracer then pcall(function() pool.tracer:Remove() end) end
    drawPool[pl] = nil
end

Players.PlayerAdded:Connect(function(pl)
    pl.CharacterAdded:Connect(function()
        task.wait(0.3)
        buildESP(pl); buildTag(pl)
    end)
    buildESP(pl); buildTag(pl)
end)
Players.PlayerRemoving:Connect(function(pl)
    if espHighlights[pl] then
        if espHighlights[pl].Parent then espHighlights[pl]:Destroy() end
        espHighlights[pl] = nil
    end
    local bb = tagFolder:FindFirstChild(pl.Name)
    if bb then bb:Destroy() end
    clearDrawPool(pl)
end)

for _, pl in ipairs(Players:GetPlayers()) do
    if pl ~= lp then
        buildESP(pl); buildTag(pl)
        pl.CharacterAdded:Connect(function() task.wait(0.3); buildESP(pl); buildTag(pl) end)
    end
end

-- ============================================================================
-- SECTION 21 — FLY / NOCLIP / THIRD PERSON / FULLBRIGHT
-- ============================================================================

local _flyBV, _flyBG, _flyConn
_G._startFly = function()
    _G._stopFly()
    local ch, r, h = chr(lp), root(lp), hum(lp)
    if not ch or not r or not h then notify("Fly: no character", "err"); return end
    h.PlatformStand = true
    _flyBV = Instance.new("BodyVelocity")
    _flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    _flyBV.Velocity = Vector3.zero
    _flyBV.Parent = r
    _flyBG = Instance.new("BodyGyro")
    _flyBG.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
    _flyBG.D = 100
    _flyBG.CFrame = r.CFrame
    _flyBG.Parent = r
    _flyConn = RunService.RenderStepped:Connect(function()
        if not CFG.Fly then _G._stopFly(); return end
        local ch2 = chr(lp); if not ch2 then return end
        local r2 = ch2:FindFirstChild("HumanoidRootPart"); if not r2 then return end
        local dir = Vector3.zero
        local cf = cam.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
        if dir.Magnitude > 0 then
            _flyBV.Velocity = dir.Unit * CFG.FlySpeed
            _flyBG.CFrame = CFrame.new(r2.Position, r2.Position + dir)
        else
            _flyBV.Velocity = Vector3.zero
        end
    end)
    notify("Fly ON  ·  WASD + Space/Ctrl", "ok")
end
_G._stopFly = function()
    if _flyConn then _flyConn:Disconnect(); _flyConn = nil end
    if _flyBV and _flyBV.Parent then _flyBV:Destroy(); _flyBV = nil end
    if _flyBG and _flyBG.Parent then _flyBG:Destroy(); _flyBG = nil end
    local h = hum(lp); if h then h.PlatformStand = false end
end

local _tpConn
_G._startThirdPerson = function()
    if _tpConn then _tpConn:Disconnect() end
    cam.CameraType = Enum.CameraType.Scriptable
    _tpConn = RunService.RenderStepped:Connect(function()
        if not CFG.ThirdPerson then _G._stopThirdPerson(); return end
        local r = root(lp); if not r then return end
        local d = CFG.ThirdPersonDist
        local camPos = r.Position - r.CFrame.LookVector * d + Vector3.new(0, d * 0.4, 0)
        cam.CFrame = CFrame.new(camPos, r.Position + Vector3.new(0, 1.5, 0))
    end)
end
_G._stopThirdPerson = function()
    if _tpConn then _tpConn:Disconnect(); _tpConn = nil end
    cam.CameraType = Enum.CameraType.Custom
end

local _origLighting = {}
_G._applyFullbright = function(on)
    if on then
        _origLighting = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
        }
        Lighting.Brightness = 5
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.FogStart = 99999
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") or v:IsA("BlurEffect") then v.Enabled = false end
        end
    else
        for k, v in pairs(_origLighting) do Lighting[k] = v end
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") or v:IsA("BlurEffect") then v.Enabled = true end
        end
    end
end

-- ============================================================================
-- SECTION 22 — MAIN LOOPS
-- ============================================================================

RunService.Stepped:Connect(function()
    if not CFG.Noclip then return end
    local ch = chr(lp); if not ch then return end
    for _, p in ipairs(ch:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

local origSizes = {}
RunService.Heartbeat:Connect(function()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= lp then
            local ch = chr(pl)
            if ch then
                for _, pname in ipairs({"Head","HumanoidRootPart","UpperTorso"}) do
                    local pt = ch:FindFirstChild(pname)
                    if pt then
                        if CFG.HitboxExpand then
                            if not origSizes[pt] then origSizes[pt] = pt.Size end
                            pt.Size = Vector3.new(CFG.HitboxSize, CFG.HitboxSize, CFG.HitboxSize)
                        elseif origSizes[pt] then
                            pt.Size = origSizes[pt]; origSizes[pt] = nil
                        end
                    end
                end
            end
        end
    end
end)

local _lastStamScan = 0
local _stamCache
RunService.Heartbeat:Connect(function()
    local h = hum(lp)
    if h then
        if CFG.SpeedEnabled and h.WalkSpeed ~= CFG.Speed then h.WalkSpeed = CFG.Speed end
        if CFG.InfJump and h.JumpPower ~= CFG.JumpPower then h.JumpPower = CFG.JumpPower end
        if CFG.GodMode or CFG.InfHealth then h.Health = h.MaxHealth end
        if CFG.BunnyHop and h:GetState() == Enum.HumanoidStateType.Landed then
            h:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        if CFG.SlowFall and h:GetState() == Enum.HumanoidStateType.Freefall
           and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            local r = root(lp)
            if r then
                local v = r.AssemblyLinearVelocity
                r.AssemblyLinearVelocity = Vector3.new(v.X, -CFG.SlowFallSpeed, v.Z)
            end
        end
    end
    if CFG.InfStamina then
        local now = tick()
        if now - _lastStamScan > 1 or not _stamCache or not _stamCache.Parent then
            _lastStamScan = now
            _stamCache = nil
            for _, v in ipairs(lp:GetDescendants()) do
                if (v:IsA("NumberValue") or v:IsA("IntValue")) and v.Name:lower():find("stam") then
                    _stamCache = v; break
                end
            end
            if not _stamCache then
                local ch = chr(lp)
                if ch then
                    for _, v in ipairs(ch:GetDescendants()) do
                        if (v:IsA("NumberValue") or v:IsA("IntValue")) and v.Name:lower():find("stam") then
                            _stamCache = v; break
                        end
                    end
                end
            end
        end
        if _stamCache then
            _stamCache.Value = math.max(_stamCache.Value, _stamCache.Value > 1 and 100 or 1)
        end
    end
    if CFG.Rainbow then
        local ch = chr(lp)
        if ch then
            local hue = (tick() * 0.2) % 1
            local col = Color3.fromHSV(hue, 1, 1)
            for _, p in ipairs(ch:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Color = col end
            end
        end
    end
    if CFG.AntiGravity and workspace.Gravity ~= CFG.GravityValue then
        workspace.Gravity = CFG.GravityValue
    end
end)

UserInputService.JumpRequest:Connect(function()
    if not CFG.InfJump then return end
    local h = hum(lp)
    if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

local _tpHeld = false
UserInputService.InputBegan:Connect(function(inp, gpe)
    if not CFG.TpToCursor then return end
    if inp.KeyCode == Enum.KeyCode.T then _tpHeld = true end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.T and _tpHeld then
        _tpHeld = false
        local r = root(lp)
        if r then
            local mouse = UserInputService:GetMouseLocation()
            local ray = cam:ScreenPointToRay(mouse.X, mouse.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {chr(lp)}
            local res = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
            if res then
                r.CFrame = CFrame.new(res.Position + Vector3.new(0, 3, 0))
                notify("TP → cursor", "ok")
            end
        end
    end
end)

local _lastTrig = 0
RunService.Heartbeat:Connect(function()
    if not CFG.Triggerbot then return end
    local now = tick()
    if now - _lastTrig < CFG.TriggerbotDelay then return end
    local vp = cam.ViewportSize
    local ray = cam:ScreenPointToRay(vp.X / 2, vp.Y / 2)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {chr(lp)}
    local res = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
    if res then
        local model = res.Instance:FindFirstAncestorOfClass("Model")
        if model then
            local pl = Players:GetPlayerFromCharacter(model)
            if pl and pl ~= lp and isAlive(pl) then
                if not CFG.AimbotTeamCheck or (lp.Team and pl.Team ~= lp.Team) then
                    _lastTrig = now
                    local tool = chr(lp) and chr(lp):FindFirstChildOfClass("Tool")
                    if tool then
                        for _, re in ipairs(tool:GetDescendants()) do
                            if re:IsA("RemoteEvent") then
                                pcall(function() re:FireServer(res.Instance, res.Position, res.Normal) end)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- throttled visual update loop, also drives the cached FPS
local timers = { esp = 0, tags = 0, draw = 0, fps = 0, frames = 0 }
RunService.RenderStepped:Connect(function(dt)
    timers.esp += dt; timers.tags += dt; timers.draw += dt
    timers.fps += dt; timers.frames += 1

    if timers.fps >= 1 then
        _cachedFPS = math.floor(timers.frames / timers.fps + 0.5)
        timers.fps = 0; timers.frames = 0
    end
    if timers.esp >= 0.18 then
        timers.esp = 0
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= lp then updateHighlight(pl) end
        end
    end
    if timers.tags >= 0.1 then
        timers.tags = 0
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= lp then updateTag(pl) end
        end
    end
    if timers.draw >= 0.05 then
        timers.draw = 0
        updateDrawingESP()
    end
end)

lp.CharacterAdded:Connect(function()
    task.wait(0.5)
    if CFG.Fly then _G._startFly() end
    local h = hum(lp)
    if h and CFG.SpeedEnabled then h.WalkSpeed = CFG.Speed end
    notify("Respawned — cheats reapplied", "info")
end)

-- ============================================================================
-- SECTION 23 — MENU TOGGLE + WINDOW CONTROLS
-- ============================================================================

local minimized = false
UserInputService.InputBegan:Connect(function(inp, gpe)
    if inp.KeyCode ~= CFG.MenuKey then return end
    CFG.Open = not CFG.Open
    if CFG.Open then
        win.Visible = true
        win.Size = UDim2.new(0, W, 0, 0)
        tw(win, 0.2, { Size = UDim2.new(0, W, 0, H) })
        minimized = false
    else
        tw(win, 0.15, { Size = UDim2.new(0, W, 0, 0) })
        task.delay(0.16, function()
            win.Visible = false
            win.Size = UDim2.new(0, W, 0, H)
        end)
    end
end)

btnClose.MouseButton1Click:Connect(function()
    CFG.Open = false
    tw(win, 0.15, { Size = UDim2.new(0, W, 0, 0) })
    task.delay(0.16, function()
        win.Visible = false
        win.Size = UDim2.new(0, W, 0, H)
    end)
end)

btnMin.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        tw(win, 0.2, { Size = UDim2.new(0, W, 0, TITLE_H) })
    else
        tw(win, 0.2, { Size = UDim2.new(0, W, 0, H) })
    end
end)

do
    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = inp.Position
            startPos = win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            win.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- ============================================================================
-- SECTION 24 — INIT
-- ============================================================================

task.wait(0.05)
win.Visible = true
tw(win, 0.2, { Size = UDim2.new(0, W, 0, H) })
notify("NyxScript loaded  ·  Anti-Kick active", "ok", 5)
print("[NyxScript] Valley Prison loaded. Right Shift = toggle menu.")
