--[[
    Aim Assist with Menu GUI - Private Testing Only
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------
local Config = {
    Enabled = false,
    AimKey = Enum.KeyCode.E,
    ToggleMode = true,

    FOV = 120,
    ShowFOV = true,
    FOVColor = Color3.fromRGB(0, 255, 170),

    Smoothness = 0.15,
    TargetLock = false,
    WallCheck = true,
    TeamCheck = false,

    SwitchKey = Enum.KeyCode.Q,

    HitParts = { "Head", "UpperTorso", "HumanoidRootPart", "Torso", "LowerTorso" },
}

------------------------------------------------------------
-- STATE
------------------------------------------------------------
local CurrentTarget = nil
local TargetList = {}
local TargetIndex = 0
local IsAiming = false

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------
local function isAlive(plr)
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function getHitPart(char)
    for _, name in ipairs(Config.HitParts) do
        local part = char:FindFirstChild(name)
        if part then return part end
    end
    return nil
end

local function isVisible(targetPart)
    if not Config.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character, Camera }
    local result = Workspace:Raycast(origin, direction, params)
    if not result then return true end
    return result.Instance:IsDescendantOf(targetPart.Parent)
end

local function isSameTeam(plr)
    if not Config.TeamCheck then return false end
    if not plr.Team or not LocalPlayer.Team then return false end
    return plr.Team == LocalPlayer.Team
end

local function screenDistance(worldPos)
    local screenPoint, onScreen = Camera:WorldToViewportPoint(worldPos)
    if not onScreen then return math.huge end
    local mousePos = UserInputService:GetMouseLocation()
    return (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
end

------------------------------------------------------------
-- TARGETING
------------------------------------------------------------
local function buildTargetList()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isAlive(plr) and not isSameTeam(plr) then
            local char = plr.Character
            local part = getHitPart(char)
            if part then
                local dist = screenDistance(part.Position)
                if dist <= Config.FOV and isVisible(part) then
                    table.insert(list, { player = plr, part = part, dist = dist })
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end

local function validateTarget(entry)
    if not entry or not entry.player or not entry.player.Character then return false end
    local hum = entry.player.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local part = getHitPart(entry.player.Character)
    if not part then return false end
    if screenDistance(part.Position) > Config.FOV then return false end
    if not isVisible(part) then return false end
    entry.part = part
    return true
end

local function switchTarget()
    TargetList = buildTargetList()
    if #TargetList == 0 then
        CurrentTarget = nil
        return
    end
    TargetIndex = TargetIndex % #TargetList + 1
    CurrentTarget = TargetList[TargetIndex]
end

------------------------------------------------------------
-- AIM LOOP
------------------------------------------------------------
local function aimAt(targetPart)
    local targetPos = targetPart.Position
    local camPos = Camera.CFrame.Position
    local desiredCFrame = CFrame.new(camPos, targetPos)
    if Config.Smoothness <= 0 then
        Camera.CFrame = desiredCFrame
    else
        local alpha = math.clamp(1 - Config.Smoothness, 0.01, 1)
        Camera.CFrame = Camera.CFrame:Lerp(desiredCFrame, alpha)
    end
end

------------------------------------------------------------
-- FOV CIRCLE (drawn in world space via ScreenGui)
------------------------------------------------------------
local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "AimFOV"
FOVGui.IgnoreGuiInset = true
FOVGui.ResetOnSpawn = false
FOVGui.DisplayOrder = 999
FOVGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local FOVCircle = Instance.new("Frame")
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Visible = false
FOVCircle.Parent = FOVGui

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 1.5
FOVStroke.Color = Config.FOVColor
FOVStroke.Transparency = 0.25
FOVStroke.Parent = FOVCircle

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

------------------------------------------------------------
-- MENU GUI
------------------------------------------------------------
local MenuGui = Instance.new("ScreenGui")
MenuGui.Name = "AimMenu"
MenuGui.ResetOnSpawn = false
MenuGui.DisplayOrder = 1000
MenuGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Theme
local Theme = {
    BG        = Color3.fromRGB(25, 25, 30),
    PANEL     = Color3.fromRGB(35, 35, 42),
    ACCENT    = Color3.fromRGB(0, 180, 130),
    ACCENT2   = Color3.fromRGB(60, 60, 72),
    TEXT      = Color3.fromRGB(235, 235, 240),
    SUBTEXT   = Color3.fromRGB(160, 160, 175),
    DANGER    = Color3.fromRGB(220, 70, 70),
    FONT      = Enum.Font.Gotham,
    FONTBOLD  = Enum.Font.GothamBold,
}

-- Main frame
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(340, 460)
Main.Position = UDim2.new(0.5, -170, 0.5, -230)
Main.BackgroundColor3 = Theme.BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = MenuGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.ACCENT
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.4
MainStroke.Parent = Main

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Theme.PANEL
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

-- Cover bottom rounded corners of title
local TitleCover = Instance.new("Frame")
TitleCover.Size = UDim2.new(1, 0, 0, 12)
TitleCover.Position = UDim2.new(0, 0, 1, -12)
TitleCover.BackgroundColor3 = Theme.PANEL
TitleCover.BorderSizePixel = 0
TitleCover.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.fromOffset(14, 0)
Title.BackgroundTransparency = 1
Title.Text = "AIM ASSIST"
Title.TextColor3 = Theme.TEXT
Title.Font = Theme.FONTBOLD
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.fromOffset(28, 28)
MinBtn.Position = UDim2.new(1, -66, 0, 4)
MinBtn.BackgroundColor3 = Theme.ACCENT2
MinBtn.Text = "—"
MinBtn.TextColor3 = Theme.TEXT
MinBtn.Font = Theme.FONTBOLD
MinBtn.TextSize = 14
MinBtn.AutoButtonColor = true
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(28, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 4)
CloseBtn.BackgroundColor3 = Theme.DANGER
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Theme.TEXT
CloseBtn.Font = Theme.FONTBOLD
CloseBtn.TextSize = 18
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- Content area (scrollable)
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -20, 1, -50)
Content.Position = UDim2.fromOffset(10, 44)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = Theme.ACCENT
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 8)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Content

-- Hide scroll bar background
local function addPadding()
    local pad = Instance.new("Frame")
    pad.BackgroundTransparency = 1
    pad.Size = UDim2.new(1, 0, 0, 4)
    pad.Parent = Content
end

------------------------------------------------------------
-- UI COMPONENT BUILDERS
------------------------------------------------------------

-- Section header
local function makeSection(text)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 24)
    frame.BackgroundTransparency = 1
    frame.Parent = Content

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.upper(text)
    lbl.TextColor3 = Theme.ACCENT
    lbl.Font = Theme.FONTBOLD
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 1, -3)
    line.BackgroundColor3 = Theme.ACCENT2
    line.BorderSizePixel = 0
    line.Parent = frame
    return frame
end

-- Toggle switch row
local function makeToggle(label, initial, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = Theme.PANEL
    row.BorderSizePixel = 0
    row.Parent = Content
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.fromOffset(12, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Theme.TEXT
    lbl.Font = Theme.FONT
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    -- Track
    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(44, 22)
    track.Position = UDim2.new(1, -54, 0.5, -11)
    track.BackgroundColor3 = initial and Theme.ACCENT or Theme.ACCENT2
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    -- Knob
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(18, 18)
    knob.Position = initial and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row

    local state = initial
    local function update()
        track.BackgroundColor3 = state and Theme.ACCENT or Theme.ACCENT2
        knob:TweenPosition(
            state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
            Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true
        )
    end

    btn.MouseButton1Click:Connect(function()
        state = not state
        update()
        callback(state)
    end)

    return {
        Set = function(v) state = v; update() end,
        Get = function() return state end,
    }
end

-- Slider row
local function makeSlider(label, min, max, initial, decimals, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 46)
    row.BackgroundColor3 = Theme.PANEL
    row.BorderSizePixel = 0
    row.Parent = Content
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 0, 20)
    lbl.Position = UDim2.fromOffset(12, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Theme.TEXT
    lbl.Font = Theme.FONT
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.fromOffset(70, 20)
    valLbl.Position = UDim2.new(1, -80, 0, 6)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(initial)
    valLbl.TextColor3 = Theme.ACCENT
    valLbl.Font = Theme.FONTBOLD
    valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = row

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -24, 0, 6)
    barBg.Position = UDim2.new(0, 12, 1, -14)
    barBg.BackgroundColor3 = Theme.ACCENT2
    barBg.BorderSizePixel = 0
    barBg.Parent = row
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((initial - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.ACCENT
    fill.BorderSizePixel = 0
    fill.Parent = barBg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(14, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = barBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row

    local dragging = false
    local value = initial

    local function setFromX(x)
        local rel = math.clamp((x - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
        value = min + (max - min) * rel
        local step = 10 ^ (-decimals)
        value = math.floor(value / step + 0.5) * step
        local pct = (value - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valLbl.Text = string.format("%." .. decimals .. "f", value)
        callback(value)
    end

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return {
        Set = function(v)
            value = math.clamp(v, min, max)
            local pct = (value - min) / (max - min)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, 0, 0.5, 0)
            valLbl.Text = string.format("%." .. decimals .. "f", value)
            callback(value)
        end,
    }
end

-- Keybind row
local function makeKeybind(label, initial, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = Theme.PANEL
    row.BorderSizePixel = 0
    row.Parent = Content
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -120, 1, 0)
    lbl.Position = UDim2.fromOffset(12, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Theme.TEXT
    lbl.Font = Theme.FONT
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.fromOffset(88, 24)
    keyBtn.Position = UDim2.new(1, -100, 0.5, -12)
    keyBtn.BackgroundColor3 = Theme.ACCENT2
    keyBtn.Text = initial.Name
    keyBtn.TextColor3 = Theme.TEXT
    keyBtn.Font = Theme.FONTBOLD
    keyBtn.TextSize = 12
    keyBtn.Parent = row
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 6)

    local listening = false
    local currentKey = initial

    keyBtn.MouseButton1Click:Connect(function()
        listening = true
        keyBtn.Text = "..."
        keyBtn.BackgroundColor3 = Theme.ACCENT
    end)

    local conn
    conn = UserInputService.InputBegan:Connect(function(input, gpe)
        if not listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            currentKey = input.KeyCode
            keyBtn.Text = currentKey.Name
            keyBtn.BackgroundColor3 = Theme.ACCENT2
            listening = false
            callback(currentKey)
        elseif input.UserInputType == Enum.UserInputType.MouseButton then
            currentKey = input.KeyCode
            keyBtn.Text = input.UserInputType.Name
            keyBtn.BackgroundColor3 = Theme.ACCENT2
            listening = false
            callback(input.UserInputType)
        end
    end)

    return {
        Set = function(k)
            currentKey = k
            keyBtn.Text = k.Name
            callback(k)
        end,
    }
end

------------------------------------------------------------
-- BUILD MENU CONTENT
------------------------------------------------------------
makeSection("General")

local masterToggle
masterToggle = makeToggle("Enable Aim Assist", Config.Enabled, function(v)
    Config.Enabled = v
end)

makeToggle("Toggle Mode (off = hold)", Config.ToggleMode, function(v)
    Config.ToggleMode = v
end)

makeKeybind("Aim Keybind", Config.AimKey, function(k)
    Config.AimKey = k
end)

makeKeybind("Switch Target Key", Config.SwitchKey, function(k)
    Config.SwitchKey = k
end)

makeSection("FOV")

makeSlider("FOV Radius", 10, 500, Config.FOV, 0, function(v)
    Config.FOV = v
end)

makeToggle("Show FOV Circle", Config.ShowFOV, function(v)
    Config.ShowFOV = v
end)

makeSection("Aiming")

makeSlider("Smoothness", 0, 1, Config.Smoothness, 2, function(v)
    Config.Smoothness = v
end)

makeToggle("Target Lock", Config.TargetLock, function(v)
    Config.TargetLock = v
end)

makeToggle("Wall Check", Config.WallCheck, function(v)
    Config.WallCheck = v
end)

makeToggle("Team Check", Config.TeamCheck, function(v)
    Config.TeamCheck = v
end)

makeSection("Status")

local statusRow = Instance.new("Frame")
statusRow.Size = UDim2.new(1, 0, 0, 34)
statusRow.BackgroundColor3 = Theme.PANEL
statusRow.BorderSizePixel = 0
statusRow.Parent = Content
Instance.new("UICorner", statusRow).CornerRadius = UDim.new(0, 8)

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -12, 1, 0)
statusLbl.Position = UDim2.fromOffset(12, 0)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Target: none"
statusLbl.TextColor3 = Theme.SUBTEXT
statusLbl.Font = Theme.FONT
statusLbl.TextSize = 12
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = statusRow

-- Update status each frame
RunService.RenderStepped:Connect(function()
    if CurrentTarget and CurrentTarget.player then
        local name = CurrentTarget.player.Name
        local dist = math.floor((Camera.CFrame.Position - CurrentTarget.part.Position).Magnitude)
        statusLbl.Text = string.format("Target: %s  (%d studs)", name, dist)
        statusLbl.TextColor3 = Theme.ACCENT
    else
        statusLbl.Text = "Target: none"
        statusLbl.TextColor3 = Theme.SUBTEXT
    end
end)

------------------------------------------------------------
-- MINIMIZE / CLOSE
------------------------------------------------------------
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    Main.Size = minimized and UDim2.fromOffset(340, 36) or UDim2.fromOffset(340, 460)
    MinBtn.Text = minimized and "+" or "—"
end)

CloseBtn.MouseButton1Click:Connect(function()
    MenuGui.Enabled = false
    FOVGui.Enabled = false
    Config.Enabled = false
end)

-- Reopen with RightShift if closed
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        MenuGui.Enabled = not MenuGui.Enabled
        FOVGui.Enabled = MenuGui.Enabled
    end
end)

------------------------------------------------------------
-- AIM LOOP
------------------------------------------------------------
RunService:BindToRenderStep("AimAssist", Enum.RenderPriority.Camera.Value + 1, function()
    -- FOV circle
    FOVCircle.Visible = Config.ShowFOV and Config.Enabled
    if FOVCircle.Visible then
        local mousePos = UserInputService:GetMouseLocation()
        FOVCircle.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
        FOVCircle.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2)
        FOVStroke.Color = Config.FOVColor
    end

    if not Config.Enabled or not IsAiming then return end
    if not LocalPlayer.Character or not isAlive(LocalPlayer) then return end

    if Config.TargetLock then
        if not validateTarget(CurrentTarget) then CurrentTarget = nil end
    else
        local list = buildTargetList()
        CurrentTarget = #list > 0 and list[1] or nil
    end

    if not CurrentTarget then switchTarget() end
    if CurrentTarget and CurrentTarget.part then aimAt(CurrentTarget.part) end
end)

------------------------------------------------------------
-- INPUT
------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Config.AimKey then
        if Config.ToggleMode then
            IsAiming = not IsAiming
        else
            IsAiming = true
        end
        if IsAiming then TargetIndex = 0; switchTarget() end
    elseif input.KeyCode == Config.SwitchKey and IsAiming then
        switchTarget()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Config.AimKey and not Config.ToggleMode then
        IsAiming = false
        CurrentTarget = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    CurrentTarget = nil
    TargetList = {}
    TargetIndex = 0
end)
