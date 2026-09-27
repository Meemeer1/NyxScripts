-- language: Lua (Luau), file: nyxscript_vp_js2.lua
-- target: JJSploit / low-tier executors. No metatable hooks, no Drawing, no gethui.
-- load: paste into JJSploit, run.

-- ============================================================================
-- SERVICES + HELPERS
-- ============================================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
    return tool:FindFirstChild("Shoot") ~= nil or tool:FindFirstChild("Fire") ~= nil
end

-- ============================================================================
-- CFG + COLORS
-- ============================================================================

local CFG = {
    Aimbot=false, AimbotFOV=150, AimbotSmooth=0.15, AimbotPart="Head",
    AimbotTeamCheck=false, AimbotRequireGun=false, AimbotWallCheck=false,
    AimbotFOVRing=true, AimbotFOVRingColor=Color3.fromRGB(0,255,170),
    Aimlock=false, Triggerbot=false, TriggerbotDelay=0.05,
    HitboxExpand=false, HitboxSize=6,
    PlayerESP=false, ESPFillColor=Color3.fromRGB(99,179,237),
    ESPOutlineColor=Color3.fromRGB(99,179,237),
    ESPFillTransparency=0.75, ESPOutlineTransparency=0,
    WallHack=false, TeamColors=true, ESPMaxDist=500,
    ChamsESP=false, ChamsColor=Color3.fromRGB(255,165,0),
    NameESP=false, HealthESP=false, DistanceESP=false,
    SpeedEnabled=false, Speed=24,
    Fly=false, FlySpeed=30,
    Noclip=false, InfJump=false, JumpPower=60,
    InfStamina=false, AntiGravity=false, GravityValue=50,
    BunnyHop=false, SlowFall=false, SlowFallSpeed=5,
    GodMode=false, TpToCursor=false,
    Fullbright=false, TimeOfDay=false, TimeValue=14,
    ThirdPerson=false, ThirdPersonDist=10,
    ZoomHack=false, ZoomFOV=70,
    Rainbow=false, InvisibleChar=false,
    AntiKick=true,
    Open=true, MenuKey=Enum.KeyCode.RightShift, ShowNotify=true,
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
-- NOTIFICATIONS
-- ============================================================================

local notifyGui = Instance.new("ScreenGui")
notifyGui.Name = "VP_Notify"
notifyGui.ResetOnSpawn = false
notifyGui.IgnoreGuiInset = true
notifyGui.DisplayOrder = 999
notifyGui.Parent = lp:WaitForChild("PlayerGui")

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
nLayout.Parent = notifyHolder

local NOTIFY_COLORS = { ok=C.ok, warn=C.warn, err=C.danger, info=C.accent }

local function notify(msg, kind, dur)
    if not CFG.ShowNotify then return end
    kind = kind or "info"; dur = dur or 3

    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 260, 0, 44)
    card.BackgroundColor3 = C.bg
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

    TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = UDim2.new(0, 0, 0, 0) }):Play()

    task.delay(dur, function()
        if not card.Parent then return end
        TweenService:Create(card, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Position = UDim2.new(1, 280, 0, 0), BackgroundTransparency = 1 }):Play()
        task.delay(0.16, function() if card.Parent then card:Destroy() end end)
    end)
end

-- ============================================================================
-- MAIN GUI
-- ============================================================================

local W, H = 720, 480
local SIDEBAR_W = 150
local TITLE_H = 40

local gui = Instance.new("ScreenGui")
gui.Name = "VP_Main"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000
gui.Parent = lp:WaitForChild("PlayerGui")

local function tw(inst, t, props)
    TweenService:Create(inst, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local win = Instance.new("Frame")
win.Name = "win"
win.Size = UDim2.new(0, W, 0, H)
win.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
win.BackgroundColor3 = C.bg
win.BorderSizePixel = 0
win.ClipsDescendants = true
win.Active = true
win.Draggable = true
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
subLbl.Text = "NyxScript v2.0-JS"
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
local btnClose = mkTitleBtn("x", C.danger, -28)
local btnMin   = mkTitleBtn("-", C.ok, -52)

local sidebar = Instance.new("Frame")
sidebar.Name = "sidebar"
sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -TITLE_H)
sidebar.Position = UDim2.new(0, 0, 0, TITLE_H)
sidebar.BackgroundColor3 = C.surface
sidebar.BorderSizePixel = 0
sidebar.Parent = win
local sl = Instance.new("UIListLayout")
sl.Padding = UDim.new(0, 4)
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
cl.Parent = content
local cpad = Instance.new("UIPadding")
cpad.PaddingTop = UDim.new(0, 12)
cpad.PaddingBottom = UDim.new(0, 12)
cpad.PaddingLeft = UDim.new(0, 12)
cpad.PaddingRight = UDim.new(0, 12)
cpad.Parent = content

-- ============================================================================
-- COMPONENTS
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
    lay.Parent = c
    local pd = Instance.new("UIPadding")
    pd.PaddingLeft = UDim.new(0, 10); pd.PaddingRight = UDim.new(0, 10)
    pd.PaddingTop = UDim.new(0, 8); pd.PaddingBottom = UDim.new(0, 8)
    pd.Parent = c
    return c
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
    pill.BackgroundColor3 = CFG[cfgKey] and C.accent or C.card
    pill.BorderSizePixel = 0
    pill.Text = ""
    pill.AutoButtonColor = false
    pill.Parent = row
    local pcr = Instance.new("UICorner"); pcr.CornerRadius = UDim.new(1, 0); pcr.Parent = pill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = CFG[cfgKey] and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
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
        local snapped = math.floor(raw / step + 0.5) * step
        snapped = math.clamp(snapped, min, max)
        CFG[cfgKey] = snapped
        render(snapped)
        if onChanged then pcall(onChanged, snapped) end
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = outer

    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            applyInput(inp.Position.X)
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
    b.MouseButton1Click:Connect(function() if fn then pcall(fn) end end)
end

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
            val.Text = ok and tostring(v) or "?"
            task.wait(0.5)
        end
    end)
end

-- ============================================================================
-- PAGES
-- ============================================================================

local PAGE_NAMES = {"Home","Combat","ESP","Movement","Visuals","Teleport","Spawning","Prison","Players","Settings"}
local PAGES, NAVBTNS = {}, {}

for i, name in ipairs(PAGE_NAMES) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = C.bg
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
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

    local lbl = Instance.new("TextLabel")
    lbl.Name = "navLabel"
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -16, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
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
    pg.Parent = content
    local pgl = Instance.new("UIListLayout"); pgl.Padding = UDim.new(0, 6); pgl.Parent = pg
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
        local lbl = btn:FindFirstChild("navLabel")
        if lbl then lbl.TextColor3 = active and C.text or C.textDim end
    end
end

-- ============================================================================
-- HOME
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
    sub.Text = "Valley Prison  ·  NyxScript v2.0-JS"
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
        local h = hum(lp); return h and (math.floor(h.Health).."/"..math.floor(h.MaxHealth)) or "-"
    end)
    mkInfoRow(c2, "Ping", function() return math.floor(lp:GetNetworkPing() * 1000) .. "ms" end)

    local c3 = mkCard(pg)
    secLabel(c3, "Quick Toggles")
    mkToggle(c3, "Player ESP", "PlayerESP")
    mkToggle(c3, "Aimbot", "Aimbot")
    mkToggle(c3, "Fly", "Fly", function(v)
        if v then _G._startFly() else _G._stopFly() end
    end)
    mkToggle(c3, "Speed Hack", "SpeedEnabled")
    mkToggle(c3, "Infinite Stamina", "InfStamina")
end

-- ============================================================================
-- COMBAT
-- ============================================================================

do
    local pg = PAGES.Combat
    secLabel(pg, "Aimbot")
    local c = mkCard(pg)
    mkToggle(c, "Aimbot", "Aimbot")
    mkToggle(c, "Aimlock (hard snap)", "Aimlock")
    mkToggle(c, "FOV Ring", "AimbotFOVRing")
    mkToggle(c, "Require Gun", "AimbotRequireGun")
    mkToggle(c, "Wall Check", "AimbotWallCheck")
    mkToggle(c, "Team Check", "AimbotTeamCheck")
    mkSlider(c, "FOV Radius", "AimbotFOV", 30, 400, 5)
    mkSlider(c, "Smoothness", "AimbotSmooth", 0, 1, 0.01)

    secLabel(pg, "Weapon Mods")
    local c4 = mkCard(pg)
    mkToggle(c4, "No Recoil", "NoRecoil")
    mkToggle(c4, "No Spread / Bloom", "NoSpread")
    mkToggle(c4, "Rapid Fire", "RapidFire")
    mkToggle(c4, "Infinite Ammo", "InfiniteAmmo")
    mkToggle(c4, "Auto Reload", "AutoReload")

    secLabel(pg, "Hitbox")
    local c5 = mkCard(pg)
    mkToggle(c5, "Hitbox Expand", "HitboxExpand")
    mkSlider(c5, "Hitbox Size (studs)", "HitboxSize", 1, 20, 0.5)
end

-- ============================================================================
-- ESP
-- ============================================================================

do
    local pg = PAGES.ESP
    secLabel(pg, "Player ESP")
    local c1 = mkCard(pg)
    mkToggle(c1, "Player Highlight", "PlayerESP")
    mkToggle(c1, "Wallhack (AlwaysOnTop)", "WallHack")
    mkToggle(c1, "Chams", "ChamsESP")
    mkToggle(c1, "Team Colors", "TeamColors")
    mkSlider(c1, "Max Distance", "ESPMaxDist", 250, 1000, 25)

    secLabel(pg, "Tags")
    local c2 = mkCard(pg)
    mkToggle(c2, "Name Tags", "NameESP")
    mkToggle(c2, "Health Bar", "HealthESP")
    mkToggle(c2, "Distance Tag", "DistanceESP")
end

-- ============================================================================
-- MOVEMENT
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
        if v then _G._startFly() else _G._stopFly() end
    end)
    mkSlider(c2, "Fly Speed", "FlySpeed", 5, 64, 1)

    secLabel(pg, "Jump")
    local c3 = mkCard(pg)
    mkToggle(c3, "Infinite Jump", "InfJump")
    mkSlider(c3, "Jump Power", "JumpPower", 50, 500, 10)
    mkToggle(c3, "Slow Fall", "SlowFall")
    mkSlider(c3, "Slow Fall Speed", "SlowFallSpeed", 1, 30, 1)

    secLabel(pg, "Other")
    local c5 = mkCard(pg)
    mkToggle(c5, "Noclip", "Noclip")
    mkToggle(c5, "Infinite Stamina", "InfStamina")
    mkToggle(c5, "God Mode", "GodMode")
    mkToggle(c5, "Anti-Gravity", "AntiGravity", function(v)
        workspace.Gravity = v and CFG.GravityValue or 196.2
    end)
    mkToggle(c5, "Teleport to Cursor (hold T)", "TpToCursor")
end

-- ============================================================================
-- VISUALS
-- ============================================================================

do
    local pg = PAGES.Visuals
    secLabel(pg, "Lighting")
    local c1 = mkCard(pg)
    mkToggle(c1, "Fullbright", "Fullbright", function(v) _G._applyFullbright(v) end)
    mkToggle(c1, "Custom Time", "TimeOfDay", function(v)
        if v then Lighting.ClockTime = CFG.TimeValue end
    end)
    mkSlider(c1, "Time of Day", "TimeValue", 0, 24, 0.25, function(v)
        if CFG.TimeOfDay then Lighting.ClockTime = v end
    end)

    secLabel(pg, "Camera")
    local c3 = mkCard(pg)
    mkToggle(c3, "Third Person Camera", "ThirdPerson", function(v)
        if v then _G._startThirdPerson() else _G._stopThirdPerson() end
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
end

-- ============================================================================
-- TELEPORT
-- ============================================================================

do
    local pg = PAGES.Teleport
    secLabel(pg, "Locations")
    local c1 = mkCard(pg)
    local LOCATIONS = {
        "Main Gate","Guard Room","Armory","Cafeteria","Visitor Lobby","Control Room",
        "Cell Block A","Cell Block B","Warden's Office","Medical Bay","Courtyard",
        "Parking Lot","Evidence Room","Prison Roof"
    }
    for _, locName in ipairs(LOCATIONS) do
        mkBtn(c1, locName, function()
            local target
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("BasePart") and d.Name == locName then target = d; break end
            end
            local r = root(lp)
            if target and r then
                r.CFrame = target.CFrame + Vector3.new(0, 4, 0)
                notify("TP -> " .. locName, "ok")
            else
                notify(locName .. " not found", "warn")
            end
        end)
    end

    secLabel(pg, "Saved Positions")
    local c3 = mkCard(pg)
    local saved = {}
    local savedList = Instance.new("Frame")
    savedList.BackgroundTransparency = 1
    savedList.Size = UDim2.new(1, 0, 0, 0)
    savedList.AutomaticSize = Enum.AutomaticSize.Y
    savedList.Parent = c3
    local sll = Instance.new("UIListLayout"); sll.Padding = UDim.new(0, 4); sll.Parent = savedList

    local function rebuildSaved()
        for _, ch in ipairs(savedList:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        for i, sp in ipairs(saved) do
            local r = Instance.new("Frame")
            r.Size = UDim2.new(1, 0, 0, 28)
            r.BackgroundColor3 = C.bg
            r.BorderSizePixel = 0
            r.Parent = savedList
            local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 4); rc.Parent = r
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Size = UDim2.new(0.6, 0, 1, 0)
            l.Position = UDim2.new(0, 6, 0, 0)
            l.Font = Enum.Font.Gotham
            l.TextSize = 11
            l.TextColor3 = C.textMid
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.Text = sp.name
            l.Parent = r
            local goBtn = Instance.new("TextButton")
            goBtn.Size = UDim2.new(0, 40, 0, 20)
            goBtn.Position = UDim2.new(1, -86, 0.5, -10)
            goBtn.BackgroundColor3 = C.accentDk
            goBtn.BorderSizePixel = 0
            goBtn.Font = Enum.Font.GothamBold
            goBtn.TextSize = 10
            goBtn.TextColor3 = C.text
            goBtn.Text = "Go"
            goBtn.Parent = r
            local gbc = Instance.new("UICorner"); gbc.CornerRadius = UDim.new(0, 3); gbc.Parent = goBtn
            goBtn.MouseButton1Click:Connect(function()
                local rp = root(lp)
                if rp then rp.CFrame = sp.cf; notify("TP -> "..sp.name, "ok") end
            end)
            local delBtn = Instance.new("TextButton")
            delBtn.Size = UDim2.new(0, 30, 0, 20)
            delBtn.Position = UDim2.new(1, -42, 0.5, -10)
            delBtn.BackgroundColor3 = C.danger
            delBtn.BorderSizePixel = 0
            delBtn.Font = Enum.Font.GothamBold
            delBtn.TextSize = 10
            delBtn.TextColor3 = C.bg
            delBtn.Text = "Del"
            delBtn.Parent = r
            local dbc = Instance.new("UICorner"); dbc.CornerRadius = UDim.new(0, 3); dbc.Parent = delBtn
            delBtn.MouseButton1Click:Connect(function()
                table.remove(saved, i)
                rebuildSaved()
            end)
        end
    end
    mkBtn(c3, "Save Current Position", function()
        local r = root(lp)
        if not r then return end
        if #saved >= 20 then notify("Max 20 saved", "warn"); return end
        table.insert(saved, {name = "Pos "..(#saved + 1), cf = r.CFrame})
        rebuildSaved()
        notify("Position saved", "ok")
    end)

    secLabel(pg, "Teleport to Cursor")
    local c4 = mkCard(pg)
    mkToggle(c4, "Enable TP-to-cursor (hold T)", "TpToCursor")
end

-- ============================================================================
-- SPAWNING
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
            if ok then notify(name.." -> backpack", "ok") else notify(name.." failed", "err") end
        else
            notify(name.." not found", "warn")
        end
    end

    local CATS = {
        {name="Keycards", items={"Corrections Keycard","Supervisors Keycard","Directors Keycard",
                                 "Employee Keycard","Master Keycard","Developer Keycard"}},
        {name="Materials", items={"Metal","Plastic","Rope","Shiv"}},
        {name="Shotguns", items={"KSG-12","M1014","Model 590","Saiga 12K","Terminator"}},
        {name="SMGs", items={"M1928","M1A1","MP40","MP5","MP7","UMP45","P90"}},
        {name="Assault Rifles", items={"AK-47","AK-74","M4A1","HK416","G36","G36C","M16A4",
                                       "SCAR-L","SKS","Honey Badger"}},
        {name="Pistols", items={"92FS","Makarov","1911 Emperor","SW500","G18","G17"}},
        {name="Heavy", items={"M82A1","M249 SAW","MGL MK1S"}},
    }
    for _, cat in ipairs(CATS) do
        secLabel(pg, cat.name)
        local c = mkCard(pg)
        local sf = Instance.new("ScrollingFrame")
        sf.Size = UDim2.new(1, 0, 0, 130)
        sf.BackgroundColor3 = C.bg
        sf.BackgroundTransparency = 0.4
        sf.BorderSizePixel = 0
        sf.CanvasSize = UDim2.new(0, 0, 0, 0)
        sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sf.ScrollBarThickness = 3
        sf.ScrollBarImageColor3 = C.accent
        sf.Parent = c
        local scr = Instance.new("UICorner"); scr.CornerRadius = UDim.new(0, 5); scr.Parent = sf
        local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 2); lay.Parent = sf
        local pd = Instance.new("UIPadding")
        pd.PaddingLeft = UDim.new(0, 6); pd.PaddingRight = UDim.new(0, 6)
        pd.PaddingTop = UDim.new(0, 6); pd.PaddingBottom = UDim.new(0, 6)
        pd.Parent = sf
        for _, itemName in ipairs(cat.items) do
            local r = Instance.new("Frame")
            r.Size = UDim2.new(1, -2, 0, 26)
            r.BackgroundColor3 = C.card
            r.BorderSizePixel = 0
            r.Parent = sf
            local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 4); rc.Parent = r
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Size = UDim2.new(0.7, -34, 1, 0)
            l.Position = UDim2.new(0, 6, 0, 0)
            l.Font = Enum.Font.Gotham
            l.TextSize = 11
            l.TextColor3 = C.textMid
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.Text = itemName
            l.Parent = r
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 50, 0, 18)
            b.Position = UDim2.new(1, -56, 0.5, -9)
            b.BackgroundColor3 = C.accentDk
            b.BorderSizePixel = 0
            b.Font = Enum.Font.GothamBold
            b.TextSize = 10
            b.TextColor3 = C.text
            b.Text = "Get"
            b.Parent = r
            local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 3); bc.Parent = b
            b.MouseButton1Click:Connect(function() pcall(function() tryGetItem(itemName) end) end)
        end
    end

    secLabel(pg, "Backpack")
    local c = mkCard(pg)
    mkBtn(c, "Collect All Dropped Items", function()
        local n = 0
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Tool") then
                local ok = pcall(function() v.Parent = lp.Backpack end)
                if ok then n = n + 1 end
            end
        end
        notify("Collected "..n, "ok")
    end)
    mkBtn(c, "Drop All Items", function()
        local r = root(lp)
        if not r then return end
        for _, v in ipairs(lp.Backpack:GetChildren()) do
            if v:IsA("Tool") then
                pcall(function() v.Parent = workspace; v:SetPrimaryPartCFrame(r.CFrame + Vector3.new(0,2,0)) end)
            end
        end
        notify("Dropped", "info")
    end)
end

-- ============================================================================
-- PRISON
-- ============================================================================

do
    local pg = PAGES.Prison
    secLabel(pg, "Bypasses")
    local c1 = mkCard(pg)
    mkBtn(c1, "Unlock Doors", function()
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
        notify("Cuffs cleared", "ok")
    end)
    mkBtn(c1, "Cancel Arrest", function()
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
    for _, teamName in ipairs({"Prisoner","Guard","Warden","Visitor","Criminal","Police","Staff"}) do
        mkBtn(c2, teamName, function()
            local team = Teams:FindFirstChild(teamName)
            if team then pcall(function() lp.Team = team end) end
            for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") then
                    local nl = v.Name:lower()
                    if nl:find("team") or nl:find("role") then
                        pcall(function() v:FireServer(teamName) end)
                    end
                end
            end
            notify("Team -> "..teamName, "info")
        end)
    end

    secLabel(pg, "Remotes")
    local c3 = mkCard(pg)
    mkBtn(c3, "List All Remotes (F9 console)", function()
        local n = 0
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                print("[VP Remote] " .. v:GetFullName()); n = n + 1
            end
        end
        notify("Found "..n.." remotes (F9)", "info", 4)
    end)
end

-- ============================================================================
-- PLAYERS
-- ============================================================================

do
    local pg = PAGES.Players
    secLabel(pg, "Player List")
    local c1 = mkCard(pg)
    local plist
    local function rebuild()
        if plist then plist:Destroy() end
        local sf = Instance.new("ScrollingFrame")
        sf.Size = UDim2.new(1, 0, 0, 200)
        sf.BackgroundColor3 = C.bg
        sf.BackgroundTransparency = 0.4
        sf.BorderSizePixel = 0
        sf.CanvasSize = UDim2.new(0, 0, 0, 0)
        sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sf.ScrollBarThickness = 3
        sf.ScrollBarImageColor3 = C.accent
        sf.Parent = c1
        local scr = Instance.new("UICorner"); scr.CornerRadius = UDim.new(0, 5); scr.Parent = sf
        local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 2); lay.Parent = sf
        local pd = Instance.new("UIPadding")
        pd.PaddingLeft = UDim.new(0, 6); pd.PaddingRight = UDim.new(0, 6)
        pd.PaddingTop = UDim.new(0, 6); pd.PaddingBottom = UDim.new(0, 6)
        pd.Parent = sf
        plist = sf
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= lp then
                local ping = math.floor(pl:GetNetworkPing() * 1000)
                local r = Instance.new("Frame")
                r.Size = UDim2.new(1, -2, 0, 26)
                r.BackgroundColor3 = C.card
                r.BorderSizePixel = 0
                r.Parent = sf
                local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 4); rc.Parent = r
                local l = Instance.new("TextLabel")
                l.BackgroundTransparency = 1
                l.Size = UDim2.new(0.6, -34, 1, 0)
                l.Position = UDim2.new(0, 6, 0, 0)
                l.Font = Enum.Font.Gotham
                l.TextSize = 11
                l.TextColor3 = C.textMid
                l.TextXAlignment = Enum.TextXAlignment.Left
                l.Text = pl.Name.." - "..ping.."ms"
                l.Parent = r
                local tpBtn = Instance.new("TextButton")
                tpBtn.Size = UDim2.new(0, 60, 0, 18)
                tpBtn.Position = UDim2.new(1, -66, 0.5, -9)
                tpBtn.BackgroundColor3 = C.accentDk
                tpBtn.BorderSizePixel = 0
                tpBtn.Font = Enum.Font.GothamBold
                tpBtn.TextSize = 10
                tpBtn.TextColor3 = C.text
                tpBtn.Text = "TP"
                tpBtn.Parent = r
                local tbc = Instance.new("UICorner"); tbc.CornerRadius = UDim.new(0, 3); tbc.Parent = tpBtn
                tpBtn.MouseButton1Click:Connect(function()
                    local t, m = root(pl), root(lp)
                    if t and m then m.CFrame = t.CFrame + Vector3.new(2,0,0); notify("TP -> "..pl.Name, "ok") end
                end)
            end
        end
    end
    rebuild()
    mkBtn(c1, "Refresh", rebuild)
    Players.PlayerAdded:Connect(rebuild)
    Players.PlayerRemoving:Connect(rebuild)

    secLabel(pg, "Your Info")
    local c2 = mkCard(pg)
    mkInfoRow(c2, "Username", function() return lp.Name end)
    mkInfoRow(c2, "UserID", function() return lp.UserId end)
    mkInfoRow(c2, "Team", function() return lp.Team and lp.Team.Name or "None" end)
    mkInfoRow(c2, "Health", function()
        local h = hum(lp); return h and (math.floor(h.Health).."/"..math.floor(h.MaxHealth)) or "-"
    end)
    mkInfoRow(c2, "Walk Speed", function() local h = hum(lp); return h and h.WalkSpeed or "-" end)
    mkInfoRow(c2, "Ping", function() return math.floor(lp:GetNetworkPing() * 1000).."ms" end)
end

-- ============================================================================
-- SETTINGS
-- ============================================================================

do
    local pg = PAGES.Settings
    secLabel(pg, "Menu")
    local c1 = mkCard(pg)
    mkToggle(c1, "Show Notifications", "ShowNotify")
    mkBtn(c1, "Reset All Settings", function()
        for k, v in pairs(CFG) do
            if type(v) == "boolean" then CFG[k] = (k == "Open" or k == "ShowNotify") end
        end
        notify("Settings reset", "warn", 4)
    end)

    secLabel(pg, "About")
    local c3 = mkCard(pg)
    mkInfoRow(c3, "Game", function() return "Valley Prison" end)
    mkInfoRow(c3, "Script", function() return "NyxScript v2.0-JS" end)
    mkInfoRow(c3, "Build", function() return os.date("%Y-%m-%d") end)
end

setPage("Home")

-- ============================================================================
-- AIMBOT
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

local function getBestTarget()
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
                                table.insert(candidates, {part = pt, sd = sd})
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

-- FOV circle drawn with a Frame + UIStroke, exactly like the working aim-assist script.
local fovCircle = Instance.new("Frame")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 0
fovCircle.Visible = false
fovCircle.Parent = gui
local fovStroke = Instance.new("UIStroke")
fovStroke.Thickness = 1.5
fovStroke.Color = CFG.AimbotFOVRingColor
fovStroke.Transparency = 0.25
fovStroke.Parent = fovCircle
local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

-- ============================================================================
-- ESP
-- ============================================================================

local espHighlights = {}
local tagFolder = workspace:FindFirstChild("VP_Tags") or Instance.new("Folder")
tagFolder.Name = "VP_Tags"
tagFolder.Parent = workspace

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
    nameLbl.Name = "nameLbl"
    nameLbl.BackgroundTransparency = 1
    nameLbl.Size = UDim2.new(1, 0, 0, 16)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 13
    nameLbl.TextColor3 = Color3.fromRGB(255,255,255)
    nameLbl.TextStrokeTransparency = 0.5
    nameLbl.Text = pl.Name
    nameLbl.Parent = bb

    local infoLbl = Instance.new("TextLabel")
    infoLbl.Name = "infoLbl"
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
    hbarBg.Name = "hbarBg"
    hbarBg.Size = UDim2.new(0, 100, 0, 5)
    hbarBg.Position = UDim2.new(0.5, -50, 1, -8)
    hbarBg.BackgroundColor3 = Color3.fromRGB(30,30,40)
    hbarBg.BorderSizePixel = 0
    hbarBg.Parent = bb
    local hbcr = Instance.new("UICorner"); hbcr.CornerRadius = UDim.new(1, 0); hbcr.Parent = hbarBg

    local hbarFill = Instance.new("Frame")
    hbarFill.Name = "hbarFill"
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
    local nameLbl = bb:FindFirstChild("nameLbl")
    local infoLbl = bb:FindFirstChild("infoLbl")
    local h = hum(pl)
    if nameLbl then nameLbl.Visible = CFG.NameESP end
    if infoLbl then
        local parts = {}
        if CFG.HealthESP and h then table.insert(parts, math.floor(h.Health).."hp") end
        if CFG.DistanceESP then table.insert(parts, math.floor(dist(pl)).."m") end
        infoLbl.Text = table.concat(parts, "  ")
    end
    local hbarBg = bb:FindFirstChild("hbarBg")
    if hbarBg then
        hbarBg.Visible = CFG.HealthESP
        if h and CFG.HealthESP then
            local pct = math.clamp(h.Health / math.max(h.MaxHealth, 1), 0, 1)
            local fill = hbarBg:FindFirstChild("hbarFill")
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

Players.PlayerAdded:Connect(function(pl)
    pl.CharacterAdded:Connect(function() task.wait(0.3); buildESP(pl); buildTag(pl) end)
    buildESP(pl); buildTag(pl)
end)
Players.PlayerRemoving:Connect(function(pl)
    if espHighlights[pl] then
        if espHighlights[pl].Parent then espHighlights[pl]:Destroy() end
        espHighlights[pl] = nil
    end
    local bb = tagFolder:FindFirstChild(pl.Name)
    if bb then bb:Destroy() end
end)

for _, pl in ipairs(Players:GetPlayers()) do
    if pl ~= lp then
        buildESP(pl); buildTag(pl)
        pl.CharacterAdded:Connect(function() task.wait(0.3); buildESP(pl); buildTag(pl) end)
    end
end

-- ============================================================================
-- FLY / THIRD PERSON / FULLBRIGHT
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
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        if dir.Magnitude > 0 then
            _flyBV.Velocity = dir.Unit * CFG.FlySpeed
            _flyBG.CFrame = CFrame.new(r2.Position, r2.Position + dir)
        else
            _flyBV.Velocity = Vector3.zero
        end
    end)
    notify("Fly ON  -  WASD + Space/Ctrl", "ok")
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
    else
        for k, v in pairs(_origLighting) do Lighting[k] = v end
    end
end

-- ============================================================================
-- MAIN LOOPS
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
        if CFG.GodMode then h.Health = h.MaxHealth end
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
UserInputService.InputBegan:Connect(function(inp)
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
                notify("TP -> cursor", "ok")
            end
        end
    end
end)

local timers = { esp = 0, tags = 0 }
RunService.RenderStepped:Connect(function(dt)
    timers.esp = timers.esp + dt
    timers.tags = timers.tags + dt
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
end)

lp.CharacterAdded:Connect(function()
    task.wait(0.5)
    if CFG.Fly then _G._startFly() end
    local h = hum(lp)
    if h and CFG.SpeedEnabled then h.WalkSpeed = CFG.Speed end
    notify("Respawned - cheats reapplied", "info")
end)

-- ============================================================================
-- AIM LOOP (RenderStepped, not BindToRenderStep)
-- ============================================================================

RunService.RenderStepped:Connect(function()
    -- FOV ring
    fovCircle.Visible = CFG.AimbotFOVRing and (CFG.Aimbot or CFG.Aimlock)
    if fovCircle.Visible then
        local vp = cam.ViewportSize
        fovCircle.Position = UDim2.fromOffset(vp.X / 2, vp.Y / 2)
        fovCircle.Size = UDim2.fromOffset(CFG.AimbotFOV * 2, CFG.AimbotFOV * 2)
        fovStroke.Color = CFG.AimbotFOVRingColor
    end

    if not (CFG.Aimbot or CFG.Aimlock) then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    if CFG.AimbotRequireGun and not hasGun() then return end
    local t = getBestTarget()
    if not t then return end
    local goalCF = CFrame.new(cam.CFrame.Position, t.Position)
    if CFG.Aimlock then
        cam.CFrame = goalCF
    else
        local alpha = math.clamp(1 - CFG.AimbotSmooth, 0.01, 1)
        cam.CFrame = cam.CFrame:Lerp(goalCF, alpha)
    end
end)

-- ============================================================================
-- MENU TOGGLE + WINDOW CONTROLS
-- ============================================================================

local minimized = false

UserInputService.InputBegan:Connect(function(inp, gpe)
    if inp.KeyCode ~= CFG.MenuKey then return end
    CFG.Open = not CFG.Open
    win.Visible = CFG.Open
    btnMin.Text = "-"
    minimized = false
    win.Size = UDim2.new(0, W, 0, H)
end)

btnClose.MouseButton1Click:Connect(function()
    CFG.Open = false
    win.Visible = false
end)

btnMin.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        win.Size = UDim2.new(0, W, 0, TITLE_H)
        btnMin.Text = "+"
    else
        win.Size = UDim2.new(0, W, 0, H)
        btnMin.Text = "-"
    end
end)

-- ============================================================================
-- INIT
-- ============================================================================

win.Visible = true
CFG.Open = true
notify("NyxScript v2.0-JS loaded", "ok", 4)
