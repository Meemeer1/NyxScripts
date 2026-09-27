-- ============================================================================
-- NyxScript v2.3 — Valley Prison (JJSploit-compatible)
-- Single-file. Right Shift to toggle.
-- No getrawmetatable, no Drawing, no fireclickdetector. BillboardGui ESP.
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
local lp                  = Players.LocalPlayer
local cam                 = workspace.CurrentCamera

-- ============================================================================
-- SECTION 1 — CONFIG
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
    PlayerESP           = false,   -- BillboardGui box (primary, JJSploit-safe)
    ESPUseHighlight     = false,   -- Highlight-based (secondary, may not work on JJSploit)
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

    -- ANTI-CHEAT
    AntiKick            = true,   -- UI toggle only on JJSploit (no hook available)

    -- GUI
    Open                = true,
    Page                = "Home",
    MenuKey             = Enum.KeyCode.RightShift,
    ShowNotifications   = true,
    DebugHUD            = true,
}

-- ============================================================================
-- SECTION 2 — PALETTE, TWEEN, NOTIFY, DEBUG
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

local function safeGetHui()
    if type(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    return nil
end

-- Notification ScreenGui
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

-- Debug HUD
local dbgGui = Instance.new("ScreenGui")
dbgGui.Name = "VP_Debug"
dbgGui.ResetOnSpawn = false
dbgGui.IgnoreGuiInset = true
dbgGui.DisplayOrder = 5000
do
    local hui = safeGetHui()
    if hui then dbgGui.Parent = hui else dbgGui.Parent = lp:WaitForChild("PlayerGui") end
end

local dbgFrame = Instance.new("Frame")
dbgFrame.Name = "DebugFrame"
dbgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dbgFrame.BackgroundTransparency = 0.4
dbgFrame.BorderSizePixel = 0
dbgFrame.Position = UDim2.fromOffset(8, 8)
dbgFrame.Size = UDim2.fromOffset(240, 130)
dbgFrame.Parent = dbgGui
Instance.new("UICorner", dbgFrame).CornerRadius = UDim.new(0, 6)

local dbgLabel = Instance.new("TextLabel")
dbgLabel.Name = "DebugText"
dbgLabel.BackgroundTransparency = 1
dbgLabel.Position = UDim2.fromOffset(8, 6)
dbgLabel.Size = UDim2.new(1, -16, 1, -12)
dbgLabel.Font = Enum.Font.Code
dbgLabel.TextSize = 11
dbgLabel.TextColor3 = Color3.fromRGB(0, 255, 180)
dbgLabel.TextXAlignment = Enum.TextXAlignment.Left
dbgLabel.TextYAlignment = Enum.TextYAlignment.Top
dbgLabel.Text = "VP_DEBUG"
dbgLabel.Parent = dbgFrame

-- ============================================================================
-- SECTION 3 — HELPERS
-- ============================================================================
local function chr(p) return p and p.Character end
local function root(p) local c = chr(p); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum(p) local c = chr(p); return c and c:FindFirstChildOfClass("Humanoid") end
local function isAlive(p)
    local h = hum(p)
    -- JJSploit-safe: no GetState() call
    return h ~= nil and h.Health > 0
end
local function dist(p)
    local a, b = root(lp), root(p)
    if not a or not b then return math.huge end
    return (a.Position - b.Position).Magnitude
end

-- ============================================================================
-- SECTION 4 — TEAM SIGNATURE
-- ============================================================================
local _teamCache = {}
local _teamCacheTime = {}
local TEAM_CACHE_DURATION = 0.2

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
    player.CharacterAdded:Connect(function() clearTeamCache(player) end)
end)
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= lp then
        player:GetPropertyChangedSignal("Team"):Connect(function() clearTeamCache(player) end)
        player.CharacterAdded:Connect(function() clearTeamCache(player) end)
    end
end
Players.PlayerRemoving:Connect(function(player) clearTeamCache(player) end)

-- ============================================================================
-- SECTION 5 — RAYCAST (shared, LOS check)
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
-- SECTION 6 — 8-CORNER HITBOX BOUNDS
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
-- SECTION 7 — DEX-INFORMED DATA
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
-- SECTION 8 — GUI SHELL
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
subtitle.Text = "NyxScript  v2.3  ·  JJSploit"
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
local btnMin = mkCircleBtn(C.ok, "-", -12)
local btnClose = mkCircleBtn(C.danger, "x", -38)

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
-- SECTION 9 — COMPONENTS
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
        if onToggle then
            local ok, err = pcall(onToggle, CFG[cfgKey])
            if not ok then notify("toggle " .. cfgKey .. " err: " .. tostring(err), "err", 4) end
        end
    end)
    return function(state)
        CFG[cfgKey] = state
        applyVisual(state)
        if onToggle then pcall(onToggle, state) end
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
        if onChanged then pcall(onChanged, snapped) end
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
    b.MouseButton1Click:Connect(function()
        if fn then
            local ok, err = pcall(fn)
            if not ok then notify("btn err: " .. tostring(err), "err", 4) end
        end
    end)
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
    btn.TextSize = 12
    btn.TextColor3 = C.accent
    btn.Text = "v  " .. tostring(CFG[cfgKey])
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
                btn.Text = "v  " .. tostring(opt)
                close()
                if onChanged then pcall(onChanged, opt) end
            end)
        end
    end)
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
                if onChanged then pcall(onChanged, CFG[cfgKey]) end
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
        btn.MouseButton1Click:Connect(function()
            if onItemClick then pcall(onItemClick, item) end
        end)
    end
    return sf
end

-- ============================================================================
-- SECTION 10 — PAGES
-- ============================================================================
local PAGES = {}
local NAVBTNS = {}
local PAGE_NAMES = {
    {"Home", "H"}, {"Combat", "C"}, {"ESP", "E"}, {"Movement", "M"},
    {"Visuals", "V"}, {"Teleport", "T"}, {"Spawn", "S"},
    {"Prison", "P"}, {"Players", "U"}, {"Settings", "X"},
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
    lbl.Text = "[" .. icon .. "]  " .. pageName
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
-- 10.1 HOME
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
    sub.Text = "Valley Prison  -  NyxScript v2.3  -  JJSploit"
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
    mkInfoRow(c2, "Ping", function() return math.floor(lp:GetNetworkPing() * 1000) .. " ms" end)
    mkInfoRow(c2, "Your Team", function() return lp.Team and lp.Team.Name or "None" end)
    mkInfoRow(c2, "Active Cheats", function()
        local n = 0
        for k, v in pairs(CFG) do
            if v == true and k ~= "Open" and k ~= "AntiKick" and k ~= "ShowNotifications" and k ~= "DebugHUD" then n = n + 1 end
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
    mkToggle(c3, "Debug HUD", "DebugHUD")
end

-- ============================================================================
-- 10.2 COMBAT
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
    mkSlider(c1, "FOV Radius (px)", "AimbotFOV", 30, 400, 5)
    mkSlider(c1, "Smooth (0.02 = snap, 1.0 = slow)", "AimbotSmooth", 0.02, 1.0, 0.01)
    mkDrop(c1, "Aim Part", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, "AimbotPart")

    secLabel(pg, "Silent Aim (JJSploit: unavailable)")
    local c2 = mkCard(pg)
    mkBtn(c2, "Silent Aim - requires getrawmetatable (not on JJSploit)", function()
        notify("Silent Aim needs a higher executor (Solara, Wave, Delta)", "warn", 5)
    end)

    secLabel(pg, "Triggerbot")
    local c3 = mkCard(pg)
    mkToggle(c3, "Triggerbot", "Triggerbot")
    mkSlider(c3, "Trigger Delay (s)", "TriggerbotDelay", 0.01, 0.5, 0.01)
    mkInfoRow(c3, "Last fired", function() return _G._VP_lastTrig and string.format("%.2fs", tick() - _G._VP_lastTrig) or "never" end)

    secLabel(pg, "Weapon Mods")
    local c4 = mkCard(pg)
    mkToggle(c4, "No Spread (ServerVariables.Cursor.Inaccuracy)", "NoSpread")
    mkToggle(c4, "Infinite Ammo (ServerVariables.Cursor.BulletCount)", "InfiniteAmmo")

    secLabel(pg, "Hitbox")
    local c5 = mkCard(pg)
    mkToggle(c5, "Hitbox Expand", "HitboxExpand")
    mkSlider(c5, "Hitbox Size (studs)", "HitboxSize", 1, 20, 0.5)
end

-- ============================================================================
-- 10.3 ESP
-- ============================================================================
do
    local pg = PAGES.ESP
    secLabel(pg, "Player ESP (BillboardGui - JJSploit safe)")
    local c1 = mkCard(pg)
    mkToggle(c1, "Player ESP Master", "PlayerESP", function(s)
        if s then
            local pls = #Players:GetPlayers()
            local chars = 0
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= lp and p.Character then chars = chars + 1 end
            end
            notify(string.format("ESP on: players=%d, chars=%d, maxdist=%d", pls, chars, CFG.ESPMaxDist), "info", 5)
        end
    end)
    mkToggle(c1, "Wallhack (always on top)", "WallHack")
    mkToggle(c1, "Team Colors", "TeamColors")
    mkSlider(c1, "Max Distance (studs)", "ESPMaxDist", 250, 1000, 25)

    secLabel(pg, "Tags")
    local c2 = mkCard(pg)
    mkToggle(c2, "Name Tags", "NameESP")
    mkToggle(c2, "Health Bar", "HealthESP")
    mkToggle(c2, "Distance Tag", "DistanceESP")

    secLabel(pg, "Box + Tracer")
    local c3 = mkCard(pg)
    mkToggle(c3, "Box ESP", "BoxESP")
    mkColorPicker(c3, "Box Color", "BoxESPColor")
    mkToggle(c3, "Tracer Lines", "TracerESP")
    mkColorPicker(c3, "Tracer Color", "TracerColor")
    mkSlider(c3, "Tracer Thickness", "TracerThickness", 1, 4, 0.5)
    mkDrop(c3, "Tracer Origin", {"Bottom", "Center", "Top", "Mouse"}, "TracerOrigin")

    secLabel(pg, "Highlight (may not work on JJSploit)")
    local c4 = mkCard(pg)
    mkToggle(c4, "Use Highlight (secondary)", "ESPUseHighlight")
    mkColorPicker(c4, "Fill Color", "ESPFillColor")
    mkSlider(c4, "Fill Transparency", "ESPFillTransparency", 0, 1, 0.05)

    secLabel(pg, "World ESP")
    local c5 = mkCard(pg)
    mkToggle(c5, "Item ESP", "ItemESP")
    mkToggle(c5, "Weapon ESP", "WeaponESP")
    mkToggle(c5, "Keycard ESP", "KeycardESP")
    mkSlider(c5, "Item Max Distance", "ItemESPMaxDist", 50, 500, 25)
end

-- ============================================================================
-- 10.4 MOVEMENT
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
    mkToggle(c2, "Fly", "Fly")
    mkSlider(c2, "Fly Speed", "FlySpeed", 5, 64, 1)
    mkDrop(c2, "Fly Mode", {"Head", "HRP", "CFrame"}, "FlyMode", function(v)
        if CFG.Fly then _G._VP_restartFly() end
    end)

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
    mkToggle(c5, "Teleport to Cursor", "TpToCursor")
    mkKeybind(c5, "TP Key", "TpToCursorKey")
end

-- ============================================================================
-- 10.5 VISUALS
-- ============================================================================
do
    local pg = PAGES.Visuals
    secLabel(pg, "Lighting")
    local c1 = mkCard(pg)
    mkToggle(c1, "Fullbright", "Fullbright")
    mkToggle(c1, "No Fog", "NoFog")

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
    mkToggle(c4, "Invisible Character", "InvisibleCharacter")
    mkToggle(c4, "Custom Character Color", "CustomCharColor")
    mkColorPicker(c4, "Character Color", "CharColor")
end

-- ============================================================================
-- 10.6 TELEPORT
-- ============================================================================
do
    local pg = PAGES.Teleport
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
                notify("TP -> " .. name, "ok")
            end
        else
            notify(name .. " not found", "warn")
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
            b1.Text = "> TP"
            b1.AutoButtonColor = false
            b1.Parent = row
            Instance.new("UICorner", b1).CornerRadius = UDim.new(0, 4)
            b1.MouseButton1Click:Connect(function()
                local a, b = root(lp), root(p)
                if a and b then a.CFrame = b.CFrame + Vector3.new(2, 0, 0) end
            end)
        end
    end
    mkBtn(c2, "Refresh Player List", rebuildTpList)
    rebuildTpList()
    Players.PlayerAdded:Connect(function() task.wait(0.5); rebuildTpList() end)
    Players.PlayerRemoving:Connect(function() task.wait(0.1); rebuildTpList() end)
end

-- ============================================================================
-- 10.7 SPAWN (teleport + proximity prompt)
-- ============================================================================
do
    local pg = PAGES.Spawn
    local function findRack(name)
        local lower = name:lower()
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                local at = (d.ActionText or ""):lower()
                local ot = (d.ObjectText or ""):lower()
                if at:find(lower, 1, true) or ot:find(lower, 1, true) then
                    return d, d.Parent
                end
            end
        end
        return nil, nil
    end
    local function tryRack(name)
        local obj, rackPart = findRack(name)
        if not obj then notify(name .. " not in world", "warn"); return end
        local r = root(lp)
        if rackPart and rackPart:IsA("BasePart") and r then
            r.CFrame = rackPart.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.35)
        end
        if obj:IsA("ProximityPrompt") then
            local ok = pcall(function()
                obj:InputHoldBegin()
                task.wait(obj.HoldDuration or 0)
                obj:InputHoldEnd()
            end)
            if not ok then notify("prompt fire failed", "err") end
        end
        task.wait(0.4)
        local got = false
        for _, t in ipairs(lp.Backpack:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find(name:lower(), 1, true) then got = true; break end
        end
        notify(got and (name .. " -> backpack") or (name .. " pickup failed"), got and "ok" or "warn")
    end

    secLabel(pg, "Weapon Pickup")
    local c1 = mkCard(pg)
    local info = Instance.new("TextLabel")
    info.BackgroundTransparency = 1
    info.Size = UDim2.new(1, 0, 0, 30)
    info.Font = FONT
    info.TextSize = 11
    info.TextColor3 = C.textDim
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextWrapped = true
    info.Text = "Finds a weapon rack (ProximityPrompt) for the weapon, teleports to it, and fires the prompt. Server permission still applies."
    info.Parent = c1
    mkScrollList(c1, WEAPON_NAMES, tryRack, 240)

    secLabel(pg, "Backpack")
    local c2 = mkCard(pg)
    mkBtn(c2, "Drop Held Tool", function()
        local ch = chr(lp)
        if not ch then return end
        local tool = ch:FindFirstChildOfClass("Tool")
        if not tool then notify("No tool", "warn"); return end
        local r = root(lp)
        local handle = tool:FindFirstChild("Handle")
        tool.Parent = workspace
        if handle and r then
            handle.CFrame = r.CFrame + r.CFrame.LookVector * 4 + Vector3.new(0, 1, 0)
        end
    end)
    mkBtn(c2, "Clear Backpack", function()
        local n = 0
        for _, d in ipairs(lp.Backpack:GetChildren()) do
            if d:IsA("Tool") then d:Destroy(); n = n + 1 end
        end
        notify("Cleared " .. n, "ok")
    end)
    mkInfoRow(c2, "Backpack Count", function()
        local n = 0
        for _, d in ipairs(lp.Backpack:GetChildren()) do
            if d:IsA("Tool") then n = n + 1 end
        end
        return n
    end)
end

-- ============================================================================
-- 10.8 PRISON
-- ============================================================================
do
    local pg = PAGES.Prison
    local function getRemote(folderName, childName)
        local folder = ReplicatedStorage:FindFirstChild("Remotes")
        if not folder then return nil end
        if folderName == "" then return folder:FindFirstChild(childName) end
        local sub = folder:FindFirstChild(folderName)
        if not sub then return nil end
        return sub:FindFirstChild(childName)
    end

    secLabel(pg, "Cuffs")
    local c1 = mkCard(pg)
    mkToggle(c1, "Auto-Escape Cuffs", "AutoEscapeCuffs")
    mkBtn(c1, "Fire ReleaseTarget", function()
        local r = getRemote("CuffsSystem", "ReleaseTarget")
        if not r then notify("ReleaseTarget missing", "err"); return end
        pcall(function() r:FireServer(lp) end)
        pcall(function() r:FireServer(lp.Character) end)
        notify("ReleaseTarget fired", "info")
    end)
    mkBtn(c1, "Break Cuff Welds", function()
        local ch = chr(lp)
        if not ch then return end
        local n = 0
        for _, d in ipairs(ch:GetDescendants()) do
            if d:IsA("WeldConstraint") or d:IsA("Weld") then
                local nm = (d.Name or ""):lower()
                local pnm = (d.Parent and d.Parent.Name or ""):lower()
                if nm:find("cuff") or pnm:find("cuff") then d:Destroy(); n = n + 1 end
            end
        end
        notify("Broke " .. n .. " welds", "ok")
    end)

    secLabel(pg, "Team Switcher")
    local c3 = mkCard(pg)
    for _, tn in ipairs(VALLEY_TEAMS) do
        mkBtn(c3, tn, function()
            local t = TeamsService:FindFirstChild(tn)
            if t then
                local ok = pcall(function() lp.Team = t end)
                notify(ok and ("Team -> " .. tn) or "Team change blocked", ok and "ok" or "warn")
            else
                notify("Team " .. tn .. " missing", "warn")
            end
            local r = getRemote("", "ChangeTeam")
            if r then pcall(function() r:FireServer(tn) end) end
        end)
    end
end

-- ============================================================================
-- 10.9 PLAYERS
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
    local function rebuild()
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
            local tpBtn = Instance.new("TextButton")
            tpBtn.AnchorPoint = Vector2.new(1, 0.5)
            tpBtn.Position = UDim2.new(1, -8, 0.5, 0)
            tpBtn.Size = UDim2.fromOffset(40, 20)
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
                    if a and b then a.CFrame = b.CFrame + Vector3.new(2, 0, 0) end
                end
            end)
        end
    end
    mkBtn(c1, "Refresh", rebuild)
    rebuild()
    Players.PlayerAdded:Connect(function() task.wait(0.5); rebuild() end)
    Players.PlayerRemoving:Connect(function() task.wait(0.1); rebuild() end)

    secLabel(pg, "Local Info")
    local c2 = mkCard(pg)
    mkInfoRow(c2, "UserID", function() return lp.UserId end)
    mkInfoRow(c2, "Team", function() return lp.Team and lp.Team.Name or "None" end)
    mkInfoRow(c2, "Health", function()
        local h = hum(lp)
        return h and (math.floor(h.Health) .. "/" .. math.floor(h.MaxHealth)) or "-"
    end)
    mkInfoRow(c2, "WalkSpeed", function()
        local h = hum(lp)
        return h and math.floor(h.WalkSpeed) or "-"
    end)
    mkInfoRow(c2, "Position", function()
        local r = root(lp)
        return r and string.format("%.0f, %.0f, %.0f", r.Position.X, r.Position.Y, r.Position.Z) or "-"
    end)
end

-- ============================================================================
-- 10.10 SETTINGS
-- ============================================================================
do
    local pg = PAGES.Settings
    secLabel(pg, "Menu")
    local c1 = mkCard(pg)
    mkKeybind(c1, "Menu Toggle Key", "MenuKey")
    mkToggle(c1, "Show Notifications", "ShowNotifications")
    mkToggle(c1, "Debug HUD", "DebugHUD")

    secLabel(pg, "About")
    local c2 = mkCard(pg)
    mkInfoRow(c2, "Executor", function() return "JJSploit (limited)" end)
    mkInfoRow(c2, "Limitations", function() return "No silent aim / anti-kick hook" end)
    mkInfoRow(c2, "Script", function() return "NyxScript v2.3" end)
end

-- ============================================================================
-- SECTION 11 — ESP LOGIC (BillboardGui-based)
-- ============================================================================
local tagFolder = Instance.new("Folder")
tagFolder.Name = "VP_ESP"
tagFolder.Parent = workspace

local boxFolder = Instance.new("Folder")
boxFolder.Name = "VP_Box"
boxFolder.Parent = workspace

local espHighlights = {}

local function buildESP(pl)
    if pl == lp then return end
    -- Billboard
    local existing = tagFolder:FindFirstChild(pl.Name)
    if existing then existing:Destroy() end
    local ch = chr(pl)
    if not ch then
        pl.CharacterAdded:Connect(function() task.wait(0.3); buildESP(pl) end)
        return
    end
    local r = root(pl)
    if not r then
        pl.CharacterAdded:Connect(function() task.wait(0.3); buildESP(pl) end)
        return
    end
    local bb = Instance.new("BillboardGui")
    bb.Name = pl.Name
    bb.Adornee = r
    bb.Size = UDim2.fromOffset(140, 56)
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

    -- Optional Highlight
    if CFG.ESPUseHighlight then
        if espHighlights[pl] and espHighlights[pl].Parent then espHighlights[pl]:Destroy() end
        local hl = Instance.new("Highlight")
        hl.FillColor = CFG.TeamColors and teamColor(pl) or CFG.ESPFillColor
        hl.OutlineColor = CFG.TeamColors and teamColor(pl) or CFG.ESPOutlineColor
        hl.FillTransparency = CFG.ESPFillTransparency
        hl.OutlineTransparency = CFG.ESPOutlineTransparency
        hl.DepthMode = CFG.WallHack and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        hl.Adornee = ch
        hl.Enabled = CFG.PlayerESP
        hl.Parent = ch
        espHighlights[pl] = hl
    end
end

local function updateTags()
    for _, bb in ipairs(tagFolder:GetChildren()) do
        local pl = Players:FindFirstChild(bb.Name)
        if not pl or pl == lp then bb:Destroy(); continue end
        local r = root(pl)
        if not r then bb.Enabled = false; continue end
        local h = hum(pl)
        local d = dist(pl)
        local within = d <= CFG.ESPMaxDist
        local show = CFG.PlayerESP and within and h and h.Health > 0
        bb.Enabled = show
        if show then
            bb.Adornee = r
            local nameLbl = bb:FindFirstChild("NameLbl")
            if nameLbl then
                nameLbl.TextColor3 = CFG.TeamColors and teamColor(pl) or C.text
            end
            local infoLbl = bb:FindFirstChild("InfoLbl")
            if infoLbl then
                local parts = {}
                if CFG.DistanceESP then table.insert(parts, string.format("%.0fm", d)) end
                infoLbl.Text = table.concat(parts, "  -  ")
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
    for pl, hl in pairs(espHighlights) do
        if not pl.Parent or not CFG.ESPUseHighlight then
            if hl.Parent then hl:Destroy() end
            espHighlights[pl] = nil
        elseif hl.Parent then
            hl.Enabled = CFG.PlayerESP and dist(pl) <= CFG.ESPMaxDist
        end
    end
end

-- Box ESP via BillboardGui
local boxCache = {}
local function updateBoxes()
    for _, bb in ipairs(boxFolder:GetChildren()) do
        local pl = Players:FindFirstChild(bb.Name)
        if not pl or pl == lp or not CFG.BoxESP or dist(pl) > CFG.ESPMaxDist or not isAlive(pl) then
            bb.Enabled = false
            continue
        end
        local ch = chr(pl)
        if not ch then bb.Enabled = false; continue end
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
        bb.Size = UDim2.fromOffset(math.max(4, maxX - minX), math.max(4, maxY - minY))
        bb.Enabled = true
    end
end

local function getBox(pl)
    local existing = boxFolder:FindFirstChild(pl.Name)
    if existing then return existing end
    local r = root(pl)
    if not r then return nil end
    local bb = Instance.new("BillboardGui")
    bb.Name = pl.Name
    bb.Adornee = r
    bb.Size = UDim2.fromOffset(100, 100)
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
    stroke.Parent = f
    return bb
end

-- Tracer via ScreenGui
local tracerGui = Instance.new("ScreenGui")
tracerGui.Name = "VP_Tracer"
tracerGui.ResetOnSpawn = false
tracerGui.IgnoreGuiInset = true
do
    local hui = safeGetHui()
    if hui then tracerGui.Parent = hui else tracerGui.Parent = lp:WaitForChild("PlayerGui") end
end
local tracers = {}
local function updateTracers()
    if not CFG.TracerESP then
        for _, f in pairs(tracers) do if f.Parent then f.Visible = false end end
        return
    end
    local vp = cam.ViewportSize
    local ox, oy = vp.X / 2, vp.Y
    if CFG.TracerOrigin == "Center" then ox, oy = vp.X / 2, vp.Y / 2
    elseif CFG.TracerOrigin == "Top" then ox, oy = vp.X / 2, 0
    elseif CFG.TracerOrigin == "Mouse" then
        local mp = UserInputService:GetMouseLocation()
        ox, oy = mp.X, mp.Y
    end
    local seen = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == lp or isTeammate(pl) or not isAlive(pl) or dist(pl) > CFG.ESPMaxDist then continue end
        local r = root(pl)
        if not r then continue end
        local sp, vis = cam:WorldToViewportPoint(r.Position)
        if not vis or sp.Z < 0 then continue end
        local f = tracers[pl]
        if not f or not f.Parent then
            f = Instance.new("Frame")
            f.BackgroundColor3 = CFG.TracerColor
            f.BorderSizePixel = 0
            f.AnchorPoint = Vector2.new(0.5, 0)
            f.ZIndex = 999
            f.Parent = tracerGui
            tracers[pl] = f
        end
        local dx, dy = sp.X - ox, sp.Y - oy
        local len = math.sqrt(dx * dx + dy * dy)
        local angle = math.deg(math.atan2(dy, dx)) + 90
        f.Position = UDim2.fromOffset(ox, oy)
        f.Size = UDim2.fromOffset(CFG.TracerThickness, len)
        f.Rotation = angle
        f.BackgroundColor3 = CFG.TracerColor
        f.Visible = true
        seen[pl] = true
    end
    for pl, f in pairs(tracers) do
        if not seen[pl] and f.Parent then f.Visible = false end
    end
end

-- FOV ring via Frame (JJSploit-safe approximation: a hollow square with UICorner)
local fovRingGui = Instance.new("ScreenGui")
fovRingGui.Name = "VP_FOV"
fovRingGui.ResetOnSpawn = false
fovRingGui.IgnoreGuiInset = true
do
    local hui = safeGetHui()
    if hui then fovRingGui.Parent = hui else fovRingGui.Parent = lp:WaitForChild("PlayerGui") end
end
local fovRing = Instance.new("Frame")
fovRing.Name = "FOVRing"
fovRing.AnchorPoint = Vector2.new(0.5, 0.5)
fovRing.BackgroundTransparency = 1
fovRing.BorderSizePixel = 0
fovRing.Visible = false
fovRing.Parent = fovRingGui
Instance.new("UICorner", fovRing).CornerRadius = UDim.new(0.5, 0)
local fovStroke = Instance.new("UIStroke")
fovStroke.Name = "FOVStroke"
fovStroke.Thickness = 1.5
fovStroke.Color = CFG.AimbotFOVRingColor
fovStroke.Parent = fovRing

local function updateFOVRing()
    local show = CFG.AimbotFOVRing and (CFG.Aimbot or CFG.Aimlock)
    if not show then fovRing.Visible = false; return end
    local vp = cam.ViewportSize
    fovRing.Position = UDim2.fromOffset(vp.X / 2, vp.Y / 2)
    fovRing.Size = UDim2.fromOffset(CFG.AimbotFOV * 2, CFG.AimbotFOV * 2)
    fovStroke.Color = CFG.AimbotFOVRingColor
    fovRing.Visible = true
end

-- ============================================================================
-- SECTION 12 — COMBAT LOGIC
-- ============================================================================
local function hasWeapon()
    local ch = chr(lp)
    if not ch then return false end
    local tool = ch:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local n = tool.Name:lower()
    for _, w in ipairs(WEAPON_KEYWORDS) do
        if n:find(w, 1, true) then return true end
    end
    return false
end

local function getBestTargetCamera()
    local vp = cam.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2
    local best, bestSD = nil, CFG.AimbotFOV
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == lp or not isAlive(pl) then continue end
        if CFG.AimbotTeamCheck and isTeammate(pl) then continue end
        if dist(pl) > CFG.ESPMaxDist then continue end
        local ch = chr(pl)
        local pt = ch and (ch:FindFirstChild(CFG.AimbotPart) or root(pl))
        if not pt then continue end
        if CFG.AimbotWallCheck and not hasLineOfSight(pt) then continue end
        local sp, vis = cam:WorldToViewportPoint(pt.Position)
        if not vis or sp.Z < 0 then continue end
        local sd = math.sqrt((sp.X - cx) ^ 2 + (sp.Y - cy) ^ 2)
        if sd < bestSD then bestSD = sd; best = pt end
    end
    return best
end

RunService:BindToRenderStep("VP_Aim", Enum.RenderPriority.Camera.Value + 1, function()
    if not (CFG.Aimbot or CFG.Aimlock) then return end
    if CFG.AimbotRequireGun and not hasWeapon() then return end
    local t = getBestTargetCamera()
    if not t then return end
    local goalCF = CFrame.new(cam.CFrame.Position, t.Position)
    if CFG.Aimlock then
        cam.CFrame = goalCF
    else
        cam.CFrame = cam.CFrame:Lerp(goalCF, CFG.AimbotSmooth)
    end
end)

-- ============================================================================
-- SECTION 13 — TRIGGERBOT
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
-- SECTION 14 — MOVEMENT
-- ============================================================================
RunService.Stepped:Connect(function()
    if not CFG.Noclip then return end
    local ch = chr(lp)
    if not ch then return end
    for _, p in ipairs(ch:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

RunService.Stepped:Connect(function()
    local h = hum(lp)
    if not h then return end
    if CFG.SpeedEnabled then
        if h.WalkSpeed ~= CFG.Speed then h.WalkSpeed = CFG.Speed end
    else
        if h.WalkSpeed ~= 16 and h.WalkSpeed ~= 0 then h.WalkSpeed = 16 end
    end
    if CFG.InfJump and h.JumpPower ~= CFG.JumpPower then h.JumpPower = CFG.JumpPower end
end)

UserInputService.JumpRequest:Connect(function()
    if not CFG.InfJump then return end
    local h = hum(lp)
    if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

RunService.Heartbeat:Connect(function()
    if not CFG.SlowFall then return end
    local h = hum(lp)
    if not h or not root(lp) then return end
    if h:GetState() == Enum.HumanoidStateType.Freefall and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        local r = root(lp)
        r.Velocity = Vector3.new(r.Velocity.X, -CFG.SlowFallSpeed, r.Velocity.Z)
    end
end)

RunService.Heartbeat:Connect(function()
    if not CFG.BunnyHop then return end
    local h = hum(lp)
    if not h then return end
    if h:GetState() == Enum.HumanoidStateType.Landed then
        h:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Fly
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
    notify("Fly ON - " .. mode, "ok")
end
_G._VP_restartFly = function() if CFG.Fly then startFly() else stopFly() end end

-- ============================================================================
-- SECTION 15 — MISC LOOPS
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

RunService.Heartbeat:Connect(function()
    if not CFG.NoSpread then return end
    local sv = lp:FindFirstChild("ServerVariables")
    local cur = sv and sv:FindFirstChild("Cursor")
    local inacc = cur and cur:FindFirstChild("Inaccuracy")
    if inacc and inacc:IsA("NumberValue") and inacc.Value > 0 then
        inacc.Value = 0
    end
end)

RunService.Heartbeat:Connect(function()
    if not CFG.InfiniteAmmo then return end
    local sv = lp:FindFirstChild("ServerVariables")
    local cur = sv and sv:FindFirstChild("Cursor")
    local bc = cur and cur:FindFirstChild("BulletCount")
    if bc and bc:IsA("NumberValue") and bc.Value < 30 then
        bc.Value = 999
    end
end)

RunService.Heartbeat:Connect(function()
    if not CFG.GodMode and not CFG.InfHealth then return end
    local h = hum(lp)
    if h and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
end)

local _fbApplied = false
local _origLighting = {}
RunService.Heartbeat:Connect(function()
    if CFG.Fullbright and not _fbApplied then
        _origLighting = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
        }
        Lighting.Brightness = 10
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e5
        Lighting.FogStart = 1e5 - 1
        _fbApplied = true
    elseif not CFG.Fullbright and _fbApplied then
        for k, v in pairs(_origLighting) do Lighting[k] = v end
        _fbApplied = false
    end
    if CFG.NoFog then
        Lighting.FogEnd = 1e5
        Lighting.FogStart = 1e5 - 1
    end
    if CFG.TimeOfDay then Lighting.ClockTime = CFG.TimeValue end
end)

-- Third person
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

RunService.RenderStepped:Connect(function()
    if CFG.ZoomHack then cam.FieldOfView = CFG.ZoomFOV end
end)

-- Character visuals
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
    elseif not CFG.RainbowCharacter then
        -- restore when invis off
    end
    if CFG.CustomCharColor and not CFG.RainbowCharacter then
        for _, p in ipairs(ch:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Color = CFG.CharColor end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if CFG.AntiGravity and workspace.Gravity ~= CFG.GravityValue then
        workspace.Gravity = CFG.GravityValue
    end
end)

-- TP to cursor
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

-- Cuff auto-escape
task.spawn(function()
    while true do
        task.wait(1.5)
        if CFG.AutoEscapeCuffs then
            local sv = lp:FindFirstChild("ServerVariables")
            local hc = sv and sv:FindFirstChild("Handcuffs")
            local cuffed = hc and hc:FindFirstChild("Cuffed")
            if cuffed and cuffed:IsA("BoolValue") and cuffed.Value then
                local ch = chr(lp)
                if ch then
                    for _, d in ipairs(ch:GetDescendants()) do
                        if d:IsA("WeldConstraint") or d:IsA("Weld") then
                            local nm = (d.Name or ""):lower()
                            local pnm = (d.Parent and d.Parent.Name or ""):lower()
                            if nm:find("cuff") or pnm:find("cuff") then
                                pcall(function() d:Destroy() end)
                            end
                        end
                    end
                end
                local r = ReplicatedStorage:FindFirstChild("Remotes")
                local cs = r and r:FindFirstChild("CuffsSystem")
                local release = cs and cs:FindFirstChild("ReleaseTarget")
                if release then pcall(function() release:FireServer(lp) end) end
            end
        end
    end
end)

-- ============================================================================
-- SECTION 16 — LIFECYCLE
-- ============================================================================
local function ensureESPFor(pl)
    if pl == lp then return end
    buildESP(pl)
    getBox(pl)
end

lp.CharacterAdded:Connect(function()
    task.wait(0.5)
    if CFG.Fly then _G._VP_restartFly() end
    local h = hum(lp)
    if h and CFG.SpeedEnabled then h.WalkSpeed = CFG.Speed end
    for _, pl in ipairs(Players:GetPlayers()) do ensureESPFor(pl) end
end)

Players.PlayerAdded:Connect(function(pl)
    pl.CharacterAdded:Connect(function()
        task.wait(0.3)
        ensureESPFor(pl)
    end)
    ensureESPFor(pl)
end)

Players.PlayerRemoving:Connect(function(pl)
    local bb = tagFolder:FindFirstChild(pl.Name)
    if bb then bb:Destroy() end
    local bx = boxFolder:FindFirstChild(pl.Name)
    if bx then bx:Destroy() end
    if tracers[pl] then tracers[pl]:Destroy(); tracers[pl] = nil end
    if espHighlights[pl] then
        if espHighlights[pl].Parent then espHighlights[pl]:Destroy() end
        espHighlights[pl] = nil
    end
end)

for _, pl in ipairs(Players:GetPlayers()) do ensureESPFor(pl) end

-- ============================================================================
-- SECTION 17 — MAIN LOOPS
-- ============================================================================
local timers = {esp = 0, box = 0, tracer = 0, fov = 0, items = 0}
RunService.RenderStepped:Connect(function(dt)
    timers.esp = timers.esp + dt
    timers.box = timers.box + dt
    timers.tracer = timers.tracer + dt
    timers.fov = timers.fov + dt
    if timers.esp >= 0.1 then
        timers.esp = 0
        updateTags()
    end
    if timers.box >= 0.05 then
        timers.box = 0
        updateBoxes()
    end
    if timers.tracer >= 0.02 then
        timers.tracer = 0
        updateTracers()
    end
    timers.fov = timers.fov + dt
    if timers.fov >= 0.05 then
        timers.fov = 0
        updateFOVRing()
    end
end)

-- ============================================================================
-- SECTION 18 — DEBUG HUD
-- ============================================================================
local function updateDebug()
    if not CFG.DebugHUD then
        dbgFrame.Visible = false
        return
    end
    dbgFrame.Visible = true
    local players = #Players:GetPlayers()
    local chars = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then chars = chars + 1 end
    end
    local bbCount = #tagFolder:GetChildren()
    local enabledBB = 0
    for _, bb in ipairs(tagFolder:GetChildren()) do
        if bb.Enabled then enabledBB = enabledBB + 1 end
    end
    local hlCount = 0
    for _, hl in pairs(espHighlights) do
        if hl and hl.Parent then hlCount = hlCount + 1 end
    end
    local boxCount = #boxFolder:GetChildren()
    local tracerCount = #tracerGui:GetChildren()

    dbgLabel.Text = string.format(
        "VP_DEBUG\nplayers=%d  chars=%d\nESPMaster=%s  maxdist=%d\nbillboards=%d  enabled=%d\nhighlights=%d  boxes=%d  tracers=%d\nfovRing=%s  boxESP=%s  tracerESP=%s",
        players, chars,
        tostring(CFG.PlayerESP), CFG.ESPMaxDist,
        bbCount, enabledBB,
        hlCount, boxCount, tracerCount,
        tostring(CFG.AimbotFOVRing and (CFG.Aimbot or CFG.Aimlock)),
        tostring(CFG.BoxESP),
        tostring(CFG.TracerESP)
    )
end
task.spawn(function()
    while true do
        task.wait(0.25)
        pcall(updateDebug)
    end
end)

-- ============================================================================
-- SECTION 19 — MENU TOGGLE
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
-- SECTION 20 — INIT
-- ============================================================================
setPage("Home")
notify("NyxScript v2.3 (JJSploit) loaded", "ok", 5)
