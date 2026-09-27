--[[
    Aim Assist + ESP with Menu GUI - Private Testing Only
    Features: Aimbot, FOV, Smoothness, Target Lock, Wallcheck,
              Distance sliders, ESP (Box/Name/Distance/Health/Tracer),
              Highlight ESP (through walls)
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
    -- Aim
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
    AimMaxDistance = 500,          -- distance slider for aimbot

    SwitchKey = Enum.KeyCode.Q,
    HitParts = { "Head", "UpperTorso", "HumanoidRootPart", "Torso", "LowerTorso" },

    -- ESP (2D draw)
    ESPEnabled = true,
    ESPBox = true,
    ESPName = true,
    ESPDistance = true,
    ESPHealth = true,
    ESPTracer = false,
    ESPTeamCheck = false,
    ESPMaxDistance = 500,          -- distance slider for ESP
    ESPColor = Color3.fromRGB(0, 255, 170),
    ESPTextColor = Color3.fromRGB(255, 255, 255),
    ESPFilled = false,
    ESPFillTransparency = 0.85,

    -- Highlight ESP
    HighlightEnabled = false,
    HighlightFillColor = Color3.fromRGB(255, 60, 60),
    HighlightOutlineColor = Color3.fromRGB(255, 255, 255),
    HighlightFillTransparency = 0.6,
    HighlightOutlineTransparency = 0,
    HighlightTeamCheck = false,
    HighlightMaxDistance = 500,    -- distance slider for highlights
    HighlightDepthMode = Enum.HighlightDepthMode.AlwaysOnTop, -- AlwaysOnTop | Occluded
}

------------------------------------------------------------
-- STATE
------------------------------------------------------------
local CurrentTarget = nil
local TargetList = {}
local TargetIndex = 0
local IsAiming = false
local ESPObjects = {}       -- [player] = { box=..., ... }
local Highlights = {}       -- [player] = Highlight instance

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

local function isSameTeam(plr, enabled)
    if not enabled then return false end
    if not plr.Team or not LocalPlayer.Team then return false end
    return plr.Team == LocalPlayer.Team
end

local function screenDistance(worldPos)
    local sp, onScreen = Camera:WorldToViewportPoint(worldPos)
    if not onScreen then return math.huge end
    local mousePos = UserInputService:GetMouseLocation()
    return (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
end

local function worldDistance(worldPos)
    return (Camera.CFrame.Position - worldPos).Magnitude
end

------------------------------------------------------------
-- TARGETING (AIMBOT)
------------------------------------------------------------
local function buildTargetList()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isAlive(plr) and not isSameTeam(plr, Config.TeamCheck) then
            local part = getHitPart(plr.Character)
            if part then
                local sdist = screenDistance(part.Position)
                local wdist = worldDistance(part.Position)
                if sdist <= Config.FOV
                   and wdist <= Config.AimMaxDistance
                   and isVisible(part) then
                    table.insert(list, { player = plr, part = part, dist = sdist, wdist = wdist })
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
    if worldDistance(part.Position) > Config.AimMaxDistance then return false end
    if not isVisible(part) then return false end
    entry.part = part
    return true
end

local function switchTarget()
    TargetList = buildTargetList()
    if #TargetList == 0 then CurrentTarget = nil; return end
    TargetIndex = TargetIndex % #TargetList + 1
    CurrentTarget = TargetList[TargetIndex]
end

local function aimAt(targetPart)
    local camPos = Camera.CFrame.Position
    local desired = CFrame.new(camPos, targetPart.Position)
    if Config.Smoothness <= 0 then
        Camera.CFrame = desired
    else
        local alpha = math.clamp(1 - Config.Smoothness, 0.01, 1)
        Camera.CFrame = Camera.CFrame:Lerp(desired, alpha)
    end
end

------------------------------------------------------------
-- FOV CIRCLE
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
Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)

------------------------------------------------------------
-- ESP 2D DRAW GUI
------------------------------------------------------------
local ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "ESPDraw"
ESPGui.IgnoreGuiInset = true
ESPGui.ResetOnSpawn = false
ESPGui.DisplayOrder = 998
ESPGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local function makeESP(player)
    local data = {}

    data.box = Instance.new("Frame")
    data.box.BackgroundTransparency = 1
    data.box.BorderSizePixel = 0
    data.box.Visible = false
    data.box.Parent = ESPGui

    data.boxFill = Instance.new("Frame")
    data.boxFill.Size = UDim2.fromScale(1, 1)
    data.boxFill.BackgroundColor3 = Config.ESPColor
    data.boxFill.BackgroundTransparency = Config.ESPFillTransparency
    data.boxFill.BorderSizePixel = 0
    data.boxFill.Visible = Config.ESPFilled
    data.boxFill.Parent = data.box

    data.boxStroke = Instance.new("UIStroke")
    data.boxStroke.Color = Config.ESPColor
    data.boxStroke.Thickness = 1.4
    data.boxStroke.Parent = data.box

    data.name = Instance.new("TextLabel")
    data.name.BackgroundTransparency = 1
    data.name.Size = UDim2.new(1, 0, 0, 14)
    data.name.Position = UDim2.new(0, 0, 0, -16)
    data.name.TextColor3 = Config.ESPTextColor
    data.name.Font = Enum.Font.GothamBold
    data.name.TextSize = 12
    data.name.TextStrokeTransparency = 0.3
    data.name.Text = player.Name
    data.name.Parent = data.box

    data.dist = Instance.new("TextLabel")
    data.dist.BackgroundTransparency = 1
    data.dist.Size = UDim2.new(1, 0, 0, 12)
    data.dist.Position = UDim2.new(0, 0, 1, 2)
    data.dist.TextColor3 = Config.ESPTextColor
    data.dist.Font = Enum.Font.Gotham
    data.dist.TextSize = 11
    data.dist.TextStrokeTransparency = 0.3
    data.dist.Text = "0m"
    data.dist.Parent = data.box

    data.healthBg = Instance.new("Frame")
    data.healthBg.Size = UDim2.new(0, 3, 1, 0)
    data.healthBg.Position = UDim2.new(0, -6, 0, 0)
    data.healthBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    data.healthBg.BorderSizePixel = 0
    data.healthBg.Parent = data.box

    data.health = Instance.new("Frame")
    data.health.Size = UDim2.fromScale(1, 1)
    data.health.Position = UDim2.new(0, 0, 1, 0)
    data.health.AnchorPoint = Vector2.new(0, 1)
    data.health.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    data.health.BorderSizePixel = 0
    data.health.Parent = data.healthBg

    data.tracer = Instance.new("Frame")
    data.tracer.AnchorPoint = Vector2.new(0.5, 0)
    data.tracer.BackgroundColor3 = Config.ESPColor
    data.tracer.BorderSizePixel = 0
    data.tracer.Size = UDim2.new(0, 1, 0, 0)
    data.tracer.Visible = false
    data.tracer.ZIndex = 0
    data.tracer.Parent = ESPGui

    data.player = player
    return data
end

local function removeESP(player)
    local d = ESPObjects[player]
    if not d then return end
    for _, obj in pairs(d) do
        if typeof(obj) == "Instance" then obj:Destroy() end
    end
    ESPObjects[player] = nil
end

------------------------------------------------------------
-- HIGHLIGHT ESP
------------------------------------------------------------
local function makeHighlight(player)
    local hl = Instance.new("Highlight")
    hl.Name = "AimESP_Highlight"
    hl.FillColor = Config.HighlightFillColor
    hl.OutlineColor = Config.HighlightOutlineColor
    hl.FillTransparency = Config.HighlightFillTransparency
    hl.OutlineTransparency = Config.HighlightOutlineTransparency
    hl.DepthMode = Config.HighlightDepthMode
    hl.Adornee = player.Character
    hl.Parent = player.Character
    return hl
end

local function removeHighlight(player)
    local hl = Highlights[player]
    if hl then
        hl:Destroy()
        Highlights[player] = nil
    end
end

------------------------------------------------------------
-- PLAYER EVENTS
------------------------------------------------------------
local function onCharacterAdded(plr)
    if plr == LocalPlayer then return end

    if not ESPObjects[plr] then
        ESPObjects[plr] = makeESP(plr)
    end

    removeHighlight(plr)
    if Config.HighlightEnabled and not isSameTeam(plr, Config.HighlightTeamCheck) then
        Highlights[plr] = makeHighlight(plr)
    end
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then
        ESPObjects[plr] = makeESP(plr)
        plr.CharacterAdded:Connect(function() onCharacterAdded(plr) end)
        if plr.Character then onCharacterAdded(plr) end
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    removeESP(plr)
    removeHighlight(plr)
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        ESPObjects[plr] = makeESP(plr)
        plr.CharacterAdded:Connect(function() onCharacterAdded(plr) end)
        if plr.Character then onCharacterAdded(plr) end
    end
end

------------------------------------------------------------
-- ESP UPDATE
------------------------------------------------------------
local function getBoundingBox(char)
    local parts = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            table.insert(parts, part)
        end
    end
    if #parts == 0 then return nil end

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local anyOnScreen = false

    for _, part in ipairs(parts) do
        local cf, size = part.CFrame, part.Size
        for _, corner in ipairs({
            cf * Vector3.new( size.X/2,  size.Y/2,  size.Z/2),
            cf * Vector3.new( size.X/2,  size.Y/2, -size.Z/2),
            cf * Vector3.new( size.X/2, -size.Y/2,  size.Z/2),
            cf * Vector3.new( size.X/2, -size.Y/2, -size.Z/2),
            cf * Vector3.new(-size.X/2,  size.Y/2,  size.Z/2),
            cf * Vector3.new(-size.X/2,  size.Y/2, -size.Z/2),
            cf * Vector3.new(-size.X/2, -size.Y/2,  size.Z/2),
            cf * Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
        }) do
            local sp, onScreen = Camera:WorldToViewportPoint(corner)
            if onScreen then
                anyOnScreen = true
                minX = math.min(minX, sp.X); minY = math.min(minY, sp.Y)
                maxX = math.max(maxX, sp.X); maxY = math.max(maxY, sp.Y)
            end
        end
    end

    if not anyOnScreen then return nil end
    return { x = minX, y = minY, w = maxX - minX, h = maxY - minY }
end

local function updateESP()
    for plr, data in pairs(ESPObjects) do
        local skip = (not Config.ESPEnabled)
            or plr == LocalPlayer
            or not plr.Character
            or not isAlive(plr)
            or isSameTeam(plr, Config.ESPTeamCheck)

        if skip then
            data.box.Visible = false
            data.tracer.Visible = false
        else
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then
                data.box.Visible = false
                data.tracer.Visible = false
            else
                local dist = worldDistance(hrp.Position)
                if dist > Config.ESPMaxDistance then
                    data.box.Visible = false
                    data.tracer.Visible = false
                else
                    local bb = getBoundingBox(plr.Character)
                    if bb then
                        -- Live colors
                        data.boxStroke.Color = Config.ESPColor
                        data.boxStroke.Enabled = Config.ESPBox
                        data.boxFill.BackgroundColor3 = Config.ESPColor
                        data.boxFill.Visible = Config.ESPFilled and Config.ESPBox
                        data.boxFill.BackgroundTransparency = Config.ESPFillTransparency
                        data.name.TextColor3 = Config.ESPTextColor
                        data.dist.TextColor3 = Config.ESPTextColor
                        data.tracer.BackgroundColor3 = Config.ESPColor

                        data.box.Visible = true
                        data.box.Position = UDim2.fromOffset(bb.x, bb.y)
                        data.box.Size = UDim2.fromOffset(bb.w, bb.h)

                        data.name.Visible = Config.ESPName
                        data.dist.Visible = Config.ESPDistance
                        data.healthBg.Visible = Config.ESPHealth
                        data.dist.Text = string.format("%d studs", math.floor(dist))

                        if Config.ESPHealth then
                            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                            if hum then
                                local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                                data.health.Size = UDim2.fromScale(1, pct)
                                local r, g
                                if pct > 0.5 then r = (1 - pct) * 2; g = 1
                                else r = 1; g = pct * 2 end
                                data.health.BackgroundColor3 = Color3.new(r, g, 0)
                            end
                        end

                        if Config.ESPTracer then
                            local sp = Camera:WorldToViewportPoint(hrp.Position)
                            local origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            local delta = Vector2.new(sp.X, sp.Y) - origin
                            data.tracer.Visible = true
                            data.tracer.Position = UDim2.fromOffset(origin.X, origin.Y)
                            data.tracer.Size = UDim2.new(0, 1, 0, delta.Magnitude)
                            data.tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X)) - 90
                        else
                            data.tracer.Visible = false
                        end
                    else
                        data.box.Visible = false
                        data.tracer.Visible = false
                    end
                end
            end
        end
    end
end

------------------------------------------------------------
-- HIGHLIGHT UPDATE
------------------------------------------------------------
local function updateHighlights()
    for plr, hl in pairs(Highlights) do
        local valid = Config.HighlightEnabled
            and plr.Character
            and isAlive(plr)
            and not isSameTeam(plr, Config.HighlightTeamCheck)

        if valid then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp and worldDistance(hrp.Position) <= Config.HighlightMaxDistance then
                hl.Adornee = plr.Character
                hl.FillColor = Config.HighlightFillColor
                hl.OutlineColor = Config.HighlightOutlineColor
                hl.FillTransparency = Config.HighlightFillTransparency
                hl.OutlineTransparency = Config.HighlightOutlineTransparency
                hl.DepthMode = Config.HighlightDepthMode
                hl.Enabled = true
            else
                hl.Enabled = false
            end
        else
            hl.Enabled = false
        end
    end
end

------------------------------------------------------------
-- MENU GUI
------------------------------------------------------------
local MenuGui = Instance.new("ScreenGui")
MenuGui.Name = "AimMenu"
MenuGui.ResetOnSpawn = false
MenuGui.DisplayOrder = 1000
MenuGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Theme = {
    BG      = Color3.fromRGB(25, 25, 30),
    PANEL   = Color3.fromRGB(35, 35, 42),
    ACCENT  = Color3.fromRGB(0, 180, 130),
    ACCENT2 = Color3.fromRGB(60, 60, 72),
    TEXT    = Color3.fromRGB(235, 235, 240),
    SUBTEXT = Color3.fromRGB(160, 160, 175),
    DANGER  = Color3.fromRGB(220, 70, 70),
    FONT    = Enum.Font.Gotham,
    FONTBOLD= Enum.Font.GothamBold,
}

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(360, 580)
Main.Position = UDim2.new(0.5, -180, 0.5, -290)
Main.BackgroundColor3 = Theme.BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = MenuGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.ACCENT
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.4
MainStroke.Parent = Main

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Theme.PANEL
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

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
Title.Text = "AIM ASSIST + ESP"
Title.TextColor3 = Theme.TEXT
Title.Font = Theme.FONTBOLD
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.fromOffset(28, 28)
MinBtn.Position = UDim2.new(1, -66, 0, 4)
MinBtn.BackgroundColor3 = Theme.ACCENT2
MinBtn.Text = "—"
MinBtn.TextColor3 = Theme.TEXT
MinBtn.Font = Theme.FONTBOLD
MinBtn.TextSize = 14
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

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

------------------------------------------------------------
-- UI COMPONENTS
------------------------------------------------------------
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
end

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

    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(44, 22)
    track.Position = UDim2.new(1, -54, 0.5, -11)
    track.BackgroundColor3 = initial and Theme.ACCENT or Theme.ACCENT2
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

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
        state = not state; update(); callback(state)
    end)
    return { Set = function(v) state = v; update() end, Get = function() return state end }
end

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
    valLbl.Text = string.format("%." .. decimals .. "f", initial)
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
            dragging = true; setFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    return { Set = function(v)
        value = math.clamp(v, min, max)
        local pct = (value - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valLbl.Text = string.format("%." .. decimals .. "f", value)
        callback(value)
    end }
end

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
    keyBtn.MouseButton1Click:Connect(function()
        listening = true
        keyBtn.Text = "..."
        keyBtn.BackgroundColor3 = Theme.ACCENT
    end)

    UserInputService.InputBegan:Connect(function(input)
        if not listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            keyBtn.Text = input.KeyCode.Name
            keyBtn.BackgroundColor3 = Theme.ACCENT2
            listening = false
            callback(input.KeyCode)
        end
