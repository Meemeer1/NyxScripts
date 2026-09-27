-- language: Lua (Luau), file: rivals_aim_esp.lua
-- target: JJSploit / low-tier executors. No Drawing. No metatable hooks. No gethui.
-- load: paste into JJSploit, run.

-- ============================================================================
-- SERVICES
-- ============================================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp               = Players.LocalPlayer
local cam              = workspace.CurrentCamera

local function chr(p) return p and p.Character end
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
    local words = {"gun","pistol","rifle","shot","snip","smg","revolver",
                   "mp5","ak","m4","g18","glock","ump","p90","ksg","m1911","uzi","awp","deagle"}
    for _, w in ipairs(words) do if n:find(w) then return true end end
    return tool:FindFirstChild("Shoot") ~= nil or tool:FindFirstChild("Fire") ~= nil
end

-- ============================================================================
-- CONFIG
-- ============================================================================
local CFG = {
    -- aimbot
    Aimbot = false,
    Aimlock = false,
    AimbotFOV = 150,
    AimbotSmooth = 0.15,
    AimbotPart = "Head",
    AimbotTeamCheck = true,
    AimbotRequireGun = false,
    AimbotWallCheck = false,
    AimbotMaxDist = 500,
    AimbotFOVRing = true,
    AimbotFOVRingColor = Color3.fromRGB(0, 255, 170),
    -- esp
    PlayerESP = false,
    TeamColors = true,
    ESPFillColor = Color3.fromRGB(99, 179, 237),
    ESPOutlineColor = Color3.fromRGB(99, 179, 237),
    ESPFillTransparency = 0.35,
    ESPOutlineTransparency = 0,
    ESPMaxDist = 500,
    DistanceESP = false,
    -- menu
    Open = true,
    MenuKey = Enum.KeyCode.Insert,
}

local C = {
    bg = Color3.fromRGB(8, 9, 16),
    surface = Color3.fromRGB(13, 14, 24),
    card = Color3.fromRGB(18, 19, 30),
    cardHov = Color3.fromRGB(22, 24, 38),
    accent = Color3.fromRGB(0, 201, 185),
    accentDk = Color3.fromRGB(0, 140, 128),
    danger = Color3.fromRGB(248, 113, 113),
    text = Color3.fromRGB(225, 230, 245),
    textMid = Color3.fromRGB(150, 155, 175),
    textDim = Color3.fromRGB(75, 80, 105),
    border = Color3.fromRGB(255, 255, 255),
}

local function teamColor(pl)
    if lp.Team and pl.Team == lp.Team then
        return Color3.fromRGB(80, 220, 120)
    end
    return Color3.fromRGB(230, 70, 70)
end

local function isTeammate(pl)
    if not lp.Team or not pl.Team then return false end
    return pl.Team == lp.Team
end

-- ============================================================================
-- GUI
-- ============================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "RIV_Main"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000
gui.Parent = lp:WaitForChild("PlayerGui")

local W, H = 520, 460
local win = Instance.new("Frame")
win.Size = UDim2.new(0, W, 0, H)
win.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
win.BackgroundColor3 = C.bg
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true
win.Parent = gui
local wcr = Instance.new("UICorner"); wcr.CornerRadius = UDim.new(0, 10); wcr.Parent = win
local wst = Instance.new("UIStroke")
wst.Color = C.border; wst.Transparency = 0.88; wst.Thickness = 1; wst.Parent = win

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
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
titleLbl.Size = UDim2.new(0, 300, 0, 16)
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 14
titleLbl.TextColor3 = C.text
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Text = "RIVALS"
titleLbl.Parent = titleBar

local subLbl = Instance.new("TextLabel")
subLbl.BackgroundTransparency = 1
subLbl.Position = UDim2.new(0, 26, 0, 22)
subLbl.Size = UDim2.new(0, 300, 0, 12)
subLbl.Font = Enum.Font.Gotham
subLbl.TextSize = 10
subLbl.TextColor3 = C.textDim
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.Text = "aim + esp  ·  Insert"
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
    b.ZIndex = 5
    b.Parent = titleBar
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = b
    return b
end
local btnClose = mkTitleBtn("x", C.danger, -28)

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -20, 1, -60)
content.Position = UDim2.new(0, 10, 0, 50)
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
cpad.PaddingTop = UDim.new(0, 8)
cpad.PaddingBottom = UDim.new(0, 8)
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
    local st = Instance.new("UIStroke")
    st.Color = C.border; st.Transparency = 0.92; st.Thickness = 1; st.Parent = c
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 4)
    lay.Parent = c
    local pd = Instance.new("UIPadding")
    pd.PaddingLeft = UDim.new(0, 10); pd.PaddingRight = UDim.new(0, 10)
    pd.PaddingTop = UDim.new(0, 8); pd.PaddingBottom = UDim.new(0, 8)
    pd.Parent = c
    return c
end

local function mkToggle(parent, label, cfgKey)
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
    pill.ZIndex = 2
    pill.Parent = row
    local pcr = Instance.new("UICorner"); pcr.CornerRadius = UDim.new(1, 0); pcr.Parent = pill
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = CFG[cfgKey] and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 3
    knob.Parent = pill
    local kcr = Instance.new("UICorner"); kcr.CornerRadius = UDim.new(1, 0); kcr.Parent = knob
    local state = CFG[cfgKey] and true or false
    local function render()
        pill.BackgroundColor3 = state and C.accent or C.card
        knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    end
    render()
    pill.MouseButton1Click:Connect(function()
        state = not state
        CFG[cfgKey] = state
        render()
    end)
end

local function mkSlider(parent, label, cfgKey, min, max, step)
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
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
    end
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 0, 22)
    hit.Position = UDim2.new(0, 0, 0, 22)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.ZIndex = 5
    hit.Parent = outer
    hit.InputBegan:Connect(function(inp)
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

local function mkDrop(parent, label, options, cfgKey)
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
    btn.Text = "v  " .. tostring(current)
    btn.AutoButtonColor = false
    btn.ZIndex = 3
    btn.Parent = row
    local bcr = Instance.new("UICorner"); bcr.CornerRadius = UDim.new(0, 5); bcr.Parent = btn
    local bst = Instance.new("UIStroke")
    bst.Color = C.border; bst.Transparency = 0.92; bst.Thickness = 1; bst.Parent = btn
    local list = Instance.new("Frame")
    list.Size = UDim2.new(0, 150, 0, 0)
    list.Position = UDim2.new(1, -150, 0, 30)
    list.BackgroundColor3 = C.surface
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 50
    list.ClipsDescendants = true
    list.Parent = row
    local lcr = Instance.new("UICorner"); lcr.CornerRadius = UDim.new(0, 5); lcr.Parent = list
    local lst = Instance.new("UIStroke")
    lst.Color = C.accent; lst.Transparency = 0.5; lst.Thickness = 1; lst.Parent = list
    local ll = Instance.new("UIListLayout"); ll.Parent = list
    local open = false
    for _, opt in ipairs(options) do
        local o = Instance.new("TextButton")
        o.Size = UDim2.new(1, 0, 0, 24)
        o.BackgroundColor3 = C.surface
        o.BorderSizePixel = 0
        o.Font = Enum.Font.Gotham
        o.TextSize = 11
        o.TextColor3 = C.textMid
        o.Text = tostring(opt)
        o.AutoButtonColor = false
        o.ZIndex = 51
        o.Parent = list
        o.MouseEnter:Connect(function() o.BackgroundColor3 = C.cardHov end)
        o.MouseLeave:Connect(function() o.BackgroundColor3 = C.surface end)
        o.MouseButton1Click:Connect(function()
            current = opt
            CFG[cfgKey] = opt
            btn.Text = "v  " .. tostring(opt)
            open = false
            list.Visible = false
        end)
    end
    btn.MouseButton1Click:Connect(function()
        open = not open
        list.Visible = open
        list.Size = open and UDim2.new(0, 150, 0, 24 * #options) or UDim2.new(0, 150, 0, 0)
    end)
end

-- ============================================================================
-- BUILD MENU
-- ============================================================================
secLabel(content, "Aimbot")
local c1 = mkCard(content)
mkToggle(c1, "Aimbot (hold RMB)", "Aimbot")
mkToggle(c1, "Aimlock (instant snap)", "Aimlock")
mkToggle(c1, "Team Check", "AimbotTeamCheck")
mkToggle(c1, "Require Gun", "AimbotRequireGun")
mkToggle(c1, "Wall Check", "AimbotWallCheck")
mkToggle(c1, "FOV Ring", "AimbotFOVRing")
mkSlider(c1, "FOV Radius", "AimbotFOV", 30, 500, 5)
mkSlider(c1, "Smoothness", "AimbotSmooth", 0, 0.5, 0.01)
mkSlider(c1, "Max Distance", "AimbotMaxDist", 50, 2000, 25)
mkDrop(c1, "Aim Part", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, "AimbotPart")

secLabel(content, "ESP")
local c2 = mkCard(content)
mkToggle(c2, "Player Highlight (through walls)", "PlayerESP")
mkToggle(c2, "Distance Tag", "DistanceESP")
mkToggle(c2, "Team Colors", "TeamColors")
mkSlider(c2, "ESP Max Distance", "ESPMaxDist", 100, 2000, 25)
mkSlider(c2, "Fill Transparency", "ESPFillTransparency", 0, 1, 0.05)

-- ============================================================================
-- AIMBOT
-- ============================================================================
local function getBestTarget()
    local vp = cam.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2
    local candidates = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= lp and isAlive(pl) then
            local skip = false
            if CFG.AimbotTeamCheck and isTeammate(pl) then skip = true end
            if dist(pl) > CFG.AimbotMaxDist then skip = true end
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

-- FOV ring via Frame + UIStroke (no Drawing needed)
local fovCircle = Instance.new("Frame")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 0
fovCircle.Visible = false
fovCircle.ZIndex = 500
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
-- ESP — Highlight + BillboardGui
-- ============================================================================
local espHighlights = {}
local tagFolder = workspace:FindFirstChild("RIV_Tags") or Instance.new("Folder")
tagFolder.Name = "RIV_Tags"
tagFolder.Parent = workspace

local function buildESP(pl)
    if pl == lp then return end
    if espHighlights[pl] and espHighlights[pl].Parent then espHighlights[pl]:Destroy() end
    espHighlights[pl] = nil
    local ch = chr(pl)
    if not ch then return end
    local hl = Instance.new("Highlight")
    local col = CFG.TeamColors and teamColor(pl) or CFG.ESPFillColor
    hl.FillColor = col
    hl.OutlineColor = CFG.TeamColors and col or CFG.ESPOutlineColor
    hl.FillTransparency = CFG.ESPFillTransparency
    hl.OutlineTransparency = CFG.ESPOutlineTransparency
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = ch
    hl.Enabled = CFG.PlayerESP
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
    bb.Size = UDim2.new(0, 120, 0, 20)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = hrp
    bb.Parent = tagFolder
    local distLbl = Instance.new("TextLabel")
    distLbl.Name = "distLbl"
    distLbl.BackgroundTransparency = 1
    distLbl.Size = UDim2.new(1, 0, 1, 0)
    distLbl.Font = Enum.Font.GothamBold
    distLbl.TextSize = 13
    distLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    distLbl.TextStrokeTransparency = 0.5
    distLbl.Text = ""
    distLbl.Parent = bb
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
    local show = CFG.PlayerESP
    hl.Enabled = show and dist(pl) <= CFG.ESPMaxDist
    if not show then return end
    local col = CFG.TeamColors and teamColor(pl) or CFG.ESPFillColor
    hl.FillColor = col
    hl.OutlineColor = CFG.TeamColors and col or CFG.ESPOutlineColor
    hl.FillTransparency = CFG.ESPFillTransparency
    hl.OutlineTransparency = CFG.ESPOutlineTransparency
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

local function updateTag(pl)
    local bb = tagFolder:FindFirstChild(pl.Name)
    if not bb then return end
    local show = CFG.DistanceESP and dist(pl) <= CFG.ESPMaxDist
    bb.Enabled = show
    if not show then return end
    local distLbl = bb:FindFirstChild("distLbl")
    if distLbl then
        distLbl.Text = math.floor(dist(pl)) .. "m"
        distLbl.TextColor3 = CFG.TeamColors and teamColor(pl) or Color3.fromRGB(255, 255, 255)
    end
end

Players.PlayerAdded:Connect(function(pl)
    pl.CharacterAdded:Connect(function()
        task.wait(0.3)
        buildESP(pl)
        buildTag(pl)
    end)
    buildESP(pl)
    buildTag(pl)
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
        buildESP(pl)
        buildTag(pl)
        pl.CharacterAdded:Connect(function()
            task.wait(0.3)
            buildESP(pl)
            buildTag(pl)
        end)
    end
end

lp.CharacterAdded:Connect(function()
    task.wait(0.3)
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= lp then
            buildESP(pl)
            buildTag(pl)
        end
    end
end)

-- ============================================================================
-- UPDATE LOOPS
-- ============================================================================
local timers = {esp = 0, tags = 0}
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

-- ============================================================================
-- AIM LOOP — camera Scriptable while aiming
-- ============================================================================
local _cameraSaved = false
RunService.RenderStepped:Connect(function()
    fovCircle.Visible = CFG.AimbotFOVRing and (CFG.Aimbot or CFG.Aimlock)
    if fovCircle.Visible then
        local vp = cam.ViewportSize
        fovCircle.Position = UDim2.fromOffset(vp.X / 2, vp.Y / 2)
        fovCircle.Size = UDim2.fromOffset(CFG.AimbotFOV * 2, CFG.AimbotFOV * 2)
        fovStroke.Color = CFG.AimbotFOVRingColor
    end

    local holding = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    local active = (CFG.Aimbot or CFG.Aimlock) and holding
        and (not CFG.AimbotRequireGun or hasGun())

    if active then
        if not _cameraSaved then
            cam.CameraType = Enum.CameraType.Scriptable
            _cameraSaved = true
        end
        local t = getBestTarget()
        if t then
            local goalCF = CFrame.new(cam.CFrame.Position, t.Position)
            if CFG.Aimlock or CFG.AimbotSmooth <= 0 then
                cam.CFrame = goalCF
            else
                local alpha = math.clamp(1 - CFG.AimbotSmooth * 2, 0.05, 1)
                cam.CFrame = cam.CFrame:Lerp(goalCF, alpha)
            end
        end
    elseif _cameraSaved then
        cam.CameraType = Enum.CameraType.Custom
        _cameraSaved = false
    end
end)

-- ============================================================================
-- MENU TOGGLE
-- ============================================================================
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == CFG.MenuKey then
        CFG.Open = not CFG.Open
        win.Visible = CFG.Open
    end
end)

btnClose.MouseButton1Click:Connect(function()
    CFG.Open = false
    win.Visible = false
end)

win.Visible = true
