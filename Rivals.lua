-- language: Lua (Luau), file: rivals_aim_fixed.lua
-- target: JJSploit / low-tier executors. No Drawing.
-- only aimbot + aimlock + esp + distance + sliders + wallcheck.

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
    return ch:FindFirstChildOfClass("Tool") ~= nil
end

local CFG = {
    Aimbot = false,
    Aimlock = false,
    AimbotFOV = 200,
    AimbotSmooth = 0.25,
    AimbotPart = "Head",
    AimbotTeamCheck = false,
    AimbotRequireGun = false,
    AimbotWallCheck = false,
    AimbotMaxDist = 800,
    AimbotFOVRing = true,
    AimbotFOVRingColor = Color3.fromRGB(0, 255, 170),
    PlayerESP = false,
    TeamColors = true,
    ESPFillColor = Color3.fromRGB(99, 179, 237),
    ESPOutlineColor = Color3.fromRGB(99, 179, 237),
    ESPFillTransparency = 0.35,
    ESPOutlineTransparency = 0,
    ESPMaxDist = 800,
    DistanceESP = false,
    Open = true,
    MenuKey = Enum.KeyCode.Insert,
}

local C = {
    bg = Color3.fromRGB(8, 9, 16),
    surface = Color3.fromRGB(13, 14, 24),
    card = Color3.fromRGB(18, 19, 30),
    cardHov = Color3.fromRGB(22, 24, 38),
    accent = Color3.fromRGB(0, 201, 185),
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
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)
local wst = Instance.new("UIStroke", win)
wst.Color = C.border; wst.Transparency = 0.88; wst.Thickness = 1

local titleBar = Instance.new("Frame", win)
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = C.surface
titleBar.BorderSizePixel = 0

local accentStrip = Instance.new("Frame", titleBar)
accentStrip.Size = UDim2.new(0, 3, 0, 22)
accentStrip.Position = UDim2.new(0, 14, 0.5, -11)
accentStrip.BackgroundColor3 = C.accent
accentStrip.BorderSizePixel = 0
Instance.new("UICorner", accentStrip).CornerRadius = UDim.new(0, 2)

local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.BackgroundTransparency = 1
titleLbl.Position = UDim2.new(0, 26, 0, 6)
titleLbl.Size = UDim2.new(0, 300, 0, 16)
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 14
titleLbl.TextColor3 = C.text
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Text = "RIVALS"

local subLbl = Instance.new("TextLabel", titleBar)
subLbl.BackgroundTransparency = 1
subLbl.Position = UDim2.new(0, 26, 0, 22)
subLbl.Size = UDim2.new(0, 300, 0, 12)
subLbl.Font = Enum.Font.Gotham
subLbl.TextSize = 10
subLbl.TextColor3 = C.textDim
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.Text = "aim + esp  ·  Insert"

local btnClose = Instance.new("TextButton", titleBar)
btnClose.Size = UDim2.new(0, 20, 0, 20)
btnClose.Position = UDim2.new(1, -28, 0, 10)
btnClose.BackgroundColor3 = C.danger
btnClose.BorderSizePixel = 0
btnClose.Text = "x"
btnClose.Font = Enum.Font.GothamBold
btnClose.TextSize = 14
btnClose.TextColor3 = C.bg
btnClose.AutoButtonColor = false
btnClose.ZIndex = 5
Instance.new("UICorner", btnClose).CornerRadius = UDim.new(1, 0)

local content = Instance.new("ScrollingFrame", win)
content.Size = UDim2.new(1, -20, 1, -60)
content.Position = UDim2.new(0, 10, 0, 50)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = C.accent
local cl = Instance.new("UIListLayout", content)
cl.Padding = UDim.new(0, 6)
local cpad = Instance.new("UIPadding", content)
cpad.PaddingTop = UDim.new(0, 8)
cpad.PaddingBottom = UDim.new(0, 8)

local function secLabel(parent, text)
    local f = Instance.new("Frame", parent)
    f.BackgroundTransparency = 1
    f.Size = UDim2.new(1, 0, 0, 22)
    local l = Instance.new("TextLabel", f)
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1, 0, 1, 0)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 10
    l.TextColor3 = C.accent
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = string.upper(text)
end

local function mkCard(parent)
    local c = Instance.new("Frame", parent)
    c.BackgroundColor3 = C.card
    c.BorderSizePixel = 0
    c.AutomaticSize = Enum.AutomaticSize.Y
    c.Size = UDim2.new(1, 0, 0, 0)
    Instance.new("UICorner", c).CornerRadius = UDim.new(0, 7)
    local st = Instance.new("UIStroke", c)
    st.Color = C.border; st.Transparency = 0.92; st.Thickness = 1
    local lay = Instance.new("UIListLayout", c)
    lay.Padding = UDim.new(0, 4)
    local pd = Instance.new("UIPadding", c)
    pd.PaddingLeft = UDim.new(0, 10); pd.PaddingRight = UDim.new(0, 10)
    pd.PaddingTop = UDim.new(0, 8); pd.PaddingBottom = UDim.new(0, 8)
    return c
end

local function mkToggle(parent, label, cfgKey)
    local row = Instance.new("Frame", parent)
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 30)
    local lbl = Instance.new("TextLabel", row)
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = C.textMid
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    local pill = Instance.new("TextButton", row)
    pill.Size = UDim2.new(0, 42, 0, 22)
    pill.Position = UDim2.new(1, -42, 0.5, -11)
    pill.BackgroundColor3 = CFG[cfgKey] and C.accent or C.card
    pill.BorderSizePixel = 0
    pill.Text = ""
    pill.AutoButtonColor = false
    pill.ZIndex = 2
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame", pill)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = CFG[cfgKey] and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 3
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
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
    local outer = Instance.new("Frame", parent)
    outer.BackgroundTransparency = 1
    outer.Size = UDim2.new(1, 0, 0, 44)
    local lbl = Instance.new("TextLabel", outer)
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -60, 0, 18)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = C.textMid
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    local val = Instance.new("TextLabel", outer)
    val.BackgroundTransparency = 1
    val.Position = UDim2.new(1, -60, 0, 0)
    val.Size = UDim2.new(0, 60, 0, 18)
    val.Font = Enum.Font.GothamBold
    val.TextSize = 12
    val.TextColor3 = C.accent
    val.TextXAlignment = Enum.TextXAlignment.Right
    local track = Instance.new("Frame", outer)
    track.Size = UDim2.new(1, 0, 0, 5)
    track.Position = UDim2.new(0, 0, 0, 26)
    track.BackgroundColor3 = C.card
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local function fmt(v)
        if step < 0.1 then return string.format("%.2f", v) end
        if step < 1 then return string.format("%.1f", v) end
        return tostring(math.floor(v + 0.5))
    end
    local dragging = false
    local function render(v)
        local rel = math.clamp((v - min) / math.max(max - min, 0.0001), 0, 1)
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
    local hit = Instance.new("TextButton", outer)
    hit.Size = UDim2.new(1, 0, 0, 22)
    hit.Position = UDim2.new(0, 0, 0, 22)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.ZIndex = 5
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
    local row = Instance.new("Frame", parent)
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 30)
    local lbl = Instance.new("TextLabel", row)
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = C.textMid
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label
    local current = CFG[cfgKey] or options[1]
    CFG[cfgKey] = current
    local btn = Instance.new("TextButton", row)
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
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    local bst = Instance.new("UIStroke", btn)
    bst.Color = C.border; bst.Transparency = 0.92; bst.Thickness = 1
    local list = Instance.new("Frame", row)
    list.Size = UDim2.new(0, 150, 0, 0)
    list.Position = UDim2.new(1, -150, 0, 30)
    list.BackgroundColor3 = C.surface
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 50
    list.ClipsDescendants = true
    Instance.new("UICorner", list).CornerRadius = UDim.new(0, 5)
    local lst = Instance.new("UIStroke", list)
    lst.Color = C.accent; lst.Transparency = 0.5; lst.Thickness = 1
    Instance.new("UIListLayout", list)
    local open = false
    for _, opt in ipairs(options) do
        local o = Instance.new("TextButton", list)
        o.Size = UDim2.new(1, 0, 0, 24)
        o.BackgroundColor3 = C.surface
        o.BorderSizePixel = 0
        o.Font = Enum.Font.Gotham
        o.TextSize = 11
        o.TextColor3 = C.textMid
        o.Text = tostring(opt)
        o.AutoButtonColor = false
        o.ZIndex = 51
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

secLabel(content, "Aimbot")
local c1 = mkCard(content)
mkToggle(c1, "Aimbot (always-on while enabled)", "Aimbot")
mkToggle(c1, "Aimlock (hold RMB, snap)", "Aimlock")
mkToggle(c1, "Team Check", "AimbotTeamCheck")
mkToggle(c1, "Require Gun", "AimbotRequireGun")
mkToggle(c1, "Wall Check", "AimbotWallCheck")
mkToggle(c1, "FOV Ring", "AimbotFOVRing")
mkSlider(c1, "FOV Radius", "AimbotFOV", 50, 800, 10)
mkSlider(c1, "Smoothness", "AimbotSmooth", 0.02, 1.0, 0.01)
mkSlider(c1, "Max Distance", "AimbotMaxDist", 50, 3000, 25)
mkDrop(c1, "Aim Part", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, "AimbotPart")

secLabel(content, "ESP")
local c2 = mkCard(content)
mkToggle(c2, "Player Highlight (through walls)", "PlayerESP")
mkToggle(c2, "Distance Tag", "DistanceESP")
mkToggle(c2, "Team Colors", "TeamColors")
mkSlider(c2, "ESP Max Distance", "ESPMaxDist", 100, 3000, 25)
mkSlider(c2, "Fill Transparency", "ESPFillTransparency", 0, 1, 0.05)

-- ============================================================================
-- TARGET SELECTION
-- ============================================================================
local function getBestTarget()
    local vp = cam.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2
    local bestPart, bestScore = nil, math.huge
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
                        local sp, onScreen = cam:WorldToViewportPoint(pt.Position)
                        if onScreen and sp.Z > 0 then
                            local sd = math.sqrt((sp.X - cx)^2 + (sp.Y - cy)^2)
                            if sd <= CFG.AimbotFOV and sd < bestScore then
                                bestScore = sd
                                bestPart = pt
                            end
                        end
                    end
                end
            end
        end
    end
    return bestPart
end

-- FOV ring — Frame + UIStroke
local fovCircle = Instance.new("Frame", gui)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 0
fovCircle.Visible = false
fovCircle.ZIndex = 500
local fovStroke = Instance.new("UIStroke", fovCircle)
fovStroke.Thickness = 1.5
fovStroke.Color = CFG.AimbotFOVRingColor
fovStroke.Transparency = 0.25
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)

-- ============================================================================
-- AIM LOOPS
-- ============================================================================
-- KEY DESIGN:
--   Aimbot   = always-on while enabled, mouse stays free, smooth lerp each frame
--   Aimlock  = hold RMB, mouse stays free, hard snap each frame
--
-- Both write camera CFrame ONLY when a target is in FOV. When no target,
-- the loop does nothing — camera stays in Custom mode, mouse works normally.

local BIND_NAME = "RIV_AimCamera"
local CAS = game:GetService("ContextActionService")

-- Keep a Scriptable camera ONLY while aiming + target present.
-- Binding a low-priority action prevents the default camera from taking over
-- while we hold CFrame writes, but does NOT stop mouse-look — Roblox's mouse
-- delta is applied by the default camera script only when CameraType == Custom,
-- so as long as we restore Custom the moment we stop aiming, mouse is free.

local camLock = false
local function lockCamera()
    if camLock then return end
    cam.CameraType = Enum.CameraType.Scriptable
    camLock = true
end
local function unlockCamera()
    if not camLock then return end
    cam.CameraType = Enum.CameraType.Custom
    camLock = false
end

-- Aimbot: always-on, no key, smooth
RunService.RenderStepped:Connect(function(dt)
    local ringOn = CFG.AimbotFOVRing and (CFG.Aimbot or CFG.Aimlock)
    fovCircle.Visible = ringOn
    if ringOn then
        local vp = cam.ViewportSize
        fovCircle.Position = UDim2.fromOffset(vp.X / 2, vp.Y / 2)
        fovCircle.Size = UDim2.fromOffset(CFG.AimbotFOV * 2, CFG.AimbotFOV * 2)
        fovStroke.Color = CFG.AimbotFOVRingColor
    end

    -- AIMBOT: always-on when enabled
    if CFG.Aimbot then
        local t = getBestTarget()
        if t then
            lockCamera()
            -- read camera position EVERY frame so lerp stays continuous
            local camPos = cam.CFrame.Position
            local goal = CFrame.lookAt(camPos, t.Position)
            if CFG.AimbotSmooth <= 0.02 then
                cam.CFrame = goal
            else
                local s = math.clamp(CFG.AimbotSmooth, 0.02, 1.0)
                local alpha = 1 - math.pow(1 - s, dt * 60)
                cam.CFrame = cam.CFrame:Lerp(goal, alpha)
            end
        else
            -- no target: if Aimlock isn't also active, release camera so mouse works
            if not (CFG.Aimlock and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) then
                unlockCamera()
            end
        end
    end
end)

-- Aimlock: hold RMB, hard snap
RunService.RenderStepped:Connect(function()
    local holdingRMB = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if CFG.Aimlock and holdingRMB and (not CFG.AimbotRequireGun or hasGun()) then
        local t = getBestTarget()
        if t then
            lockCamera()
            cam.CFrame = CFrame.lookAt(cam.CFrame.Position, t.Position)
        else
            -- holding RMB but no target: keep camera unlocked so mouse still works
            if not CFG.Aimbot then
                unlockCamera()
            end
        end
    else
        -- not holding / aimlock off
        if not CFG.Aimbot then
            unlockCamera()
        elseif not getBestTarget() then
            unlockCamera()
        end
    end
end)

-- ============================================================================
-- ESP
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
    local distLbl = Instance.new("TextLabel", bb)
    distLbl.Name = "distLbl"
    distLbl.BackgroundTransparency = 1
    distLbl.Size = UDim2.new(1, 0, 1, 0)
    distLbl.Font = Enum.Font.GothamBold
    distLbl.TextSize = 13
    distLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    distLbl.TextStrokeTransparency = 0.5
    distLbl.Text = ""
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
    local show = CFG.PlayerESP and dist(pl) <= CFG.ESPMaxDist
    hl.Enabled = show
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
