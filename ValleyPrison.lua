-- ================================================================
--  VALLEY PRISON  ·  NyxScript  ·  Premium Edition
--  Toggle: Right Shift
-- ================================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp               = Players.LocalPlayer
local cam              = workspace.CurrentCamera

-- ================================================================
--  CONFIG  — nothing is on by default except AntiKick
-- ================================================================
local CFG = {
    -- Combat
    Aimbot           = false,
    AimbotFOV        = 150,
    AimbotSmooth     = 0.15,
    AimbotPart       = "Head",
    AimbotTeamCheck  = false,
    AimbotRequireGun = false,   -- only aim when holding a weapon tool
    AimbotWallCheck  = false,   -- if true, only targets with line of sight (blocks through walls)
    AimbotFOVRing    = false,   -- draw the FOV circle on screen
    Aimlock          = false,
    SilentAim        = false,
    Triggerbot       = false,
    TriggerbotDelay  = 0.05,
    NoRecoil         = false,
    NoSpread         = false,
    HitboxExpand     = false,
    HitboxSize       = 6,

    -- ESP
    PlayerESP        = false,
    WallHack         = false,
    SkeletonESP      = false,
    NameESP          = false,
    HealthESP        = false,
    DistanceESP      = false,
    ESPMaxDist       = 500,     -- 250–1000 studs
    ItemESP          = false,
    WeaponESP        = false,

    -- Movement
    SpeedEnabled     = false,
    Speed            = 16,      -- max 64
    InfStamina       = false,
    InfJump          = false,
    JumpPower        = 50,
    Fly              = false,
    FlySpeed         = 30,      -- max 64
    Noclip           = false,

    -- Teleport
    SavedPositions   = {},

    -- Anti-Kick  ← ON by default
    AntiKick         = true,
    AntiDisconnect   = false,

    -- Internal
    GuiOpen          = true,
    ActivePage       = "Home",
    EnabledCount     = 0,
    _SpawnedItems    = {},
    _logRemotes      = false,
    _blockArrest     = false,
    _blockBan        = false,
    _spoofAgent      = false,
}

-- ================================================================
--  UTILITY
-- ================================================================
local function getChar(p)  return p and p.Character end
local function getRoot(p)  local c=getChar(p); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum(p)   local c=getChar(p); return c and c:FindFirstChildOfClass("Humanoid") end
local function getHead(p)  local c=getChar(p); return c and c:FindFirstChild("Head") end
local function distTo(p)
    local r1=getRoot(lp); local r2=getRoot(p)
    if not r1 or not r2 then return math.huge end
    return (r1.Position-r2.Position).Magnitude
end
local function isEnemy(p)
    if not CFG.AimbotTeamCheck then return p ~= lp end
    return p ~= lp and (p.Team ~= lp.Team or p.Team == nil)
end
local function tweenProp(inst,t,props)
    TweenService:Create(inst,TweenInfo.new(t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props):Play()
end
local function hasLineOfSight(fromPart, toPart)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {getChar(lp), toPart.Parent}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local dir = (toPart.Position - fromPart.Position)
    local result = workspace:Raycast(fromPart.Position, dir, params)
    return result == nil  -- nil = nothing blocking = clear line of sight
end
local function isHoldingGun()
    local char = getChar(lp)
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local n = tool.Name:lower()
    return n:find("gun") or n:find("pistol") or n:find("rifle") or n:find("shot")
        or n:find("snip") or n:find("weapon") or n:find("fire") or n:find("taser")
        -- fallback: any tool with a ranged script
        or tool:FindFirstChild("Shoot") ~= nil
        or tool:FindFirstChild("Fire")  ~= nil
end

local function countEnabled()
    local n = 0
    for _, k in ipairs({
        "Aimbot","Aimlock","SilentAim","Triggerbot","NoRecoil","NoSpread","HitboxExpand",
        "PlayerESP","SkeletonESP","NameESP","HealthESP","DistanceESP","ItemESP","WeaponESP",
        "InfStamina","InfJump","Fly","Noclip","AntiKick","AntiDisconnect","SpeedEnabled",
    }) do if CFG[k] then n+=1 end end
    CFG.EnabledCount = n
    return n
end

-- ================================================================
--  NOTIFICATION SYSTEM
-- ================================================================
local notifGui = Instance.new("ScreenGui")
notifGui.Name="VP_Notif"; notifGui.ResetOnSpawn=false
notifGui.IgnoreGuiInset=true; notifGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
notifGui.Parent=(gethui and gethui()) or lp.PlayerGui

local notifStack=Instance.new("Frame")
notifStack.Size=UDim2.new(0,280,1,0)
notifStack.Position=UDim2.new(1,-295,0,0)
notifStack.BackgroundTransparency=1; notifStack.Parent=notifGui

local nsl=Instance.new("UIListLayout")
nsl.VerticalAlignment=Enum.VerticalAlignment.Bottom
nsl.SortOrder=Enum.SortOrder.LayoutOrder
nsl.Padding=UDim.new(0,6); nsl.Parent=notifStack
Instance.new("UIPadding",notifStack).PaddingBottom=UDim.new(0,12)

local nColors={info=Color3.fromRGB(80,120,255),success=Color3.fromRGB(60,200,100),
    warn=Color3.fromRGB(255,180,40),error=Color3.fromRGB(220,60,60)}

local function notify(title,msg,kind,duration)
    kind=kind or "info"; duration=duration or 3.5
    local col=nColors[kind] or nColors.info
    local card=Instance.new("Frame")
    card.Size=UDim2.new(1,0,0,64); card.BackgroundColor3=Color3.fromRGB(14,14,22)
    card.BackgroundTransparency=0.05; card.BorderSizePixel=0; card.ClipsDescendants=true
    card.Parent=notifStack
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,8)
    local bar=Instance.new("Frame")
    bar.Size=UDim2.new(0,3,1,0); bar.BackgroundColor3=col; bar.BorderSizePixel=0; bar.Parent=card
    local tl=Instance.new("TextLabel")
    tl.Size=UDim2.new(1,-20,0,20); tl.Position=UDim2.new(0,14,0,8)
    tl.BackgroundTransparency=1; tl.Text=title; tl.TextColor3=col
    tl.Font=Enum.Font.GothamBold; tl.TextSize=13; tl.TextXAlignment=Enum.TextXAlignment.Left; tl.Parent=card
    local ml=Instance.new("TextLabel")
    ml.Size=UDim2.new(1,-20,0,28); ml.Position=UDim2.new(0,14,0,28)
    ml.BackgroundTransparency=1; ml.Text=msg; ml.TextColor3=Color3.fromRGB(180,180,195)
    ml.Font=Enum.Font.Gotham; ml.TextSize=12; ml.TextXAlignment=Enum.TextXAlignment.Left
    ml.TextWrapped=true; ml.Parent=card
    local prog=Instance.new("Frame")
    prog.Size=UDim2.new(1,0,0,2); prog.Position=UDim2.new(0,0,1,-2)
    prog.BackgroundColor3=col; prog.BorderSizePixel=0; prog.Parent=card
    card.Position=UDim2.new(1,10,0,0)
    tweenProp(card,0.25,{Position=UDim2.new(0,0,0,0)})
    tweenProp(prog,duration,{Size=UDim2.new(0,0,0,2)})
    task.delay(duration,function()
        tweenProp(card,0.2,{Position=UDim2.new(1,10,0,0)})
        task.wait(0.22); card:Destroy()
    end)
end

-- ================================================================
--  GUI — MAIN WINDOW
-- ================================================================
local screenGui=Instance.new("ScreenGui")
screenGui.Name="VP_Main"; screenGui.ResetOnSpawn=false
screenGui.IgnoreGuiInset=true; screenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
screenGui.Parent=(gethui and gethui()) or lp.PlayerGui

local overlay=Instance.new("Frame")
overlay.Size=UDim2.new(1,0,1,0); overlay.BackgroundColor3=Color3.new(0,0,0)
overlay.BackgroundTransparency=0.55; overlay.BorderSizePixel=0; overlay.ZIndex=1; overlay.Parent=screenGui

local WIN_W,WIN_H=740,500
local window=Instance.new("Frame")
window.Name="Window"; window.Size=UDim2.new(0,WIN_W,0,WIN_H)
window.Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)
window.BackgroundColor3=Color3.fromRGB(10,10,18); window.BackgroundTransparency=0.08
window.BorderSizePixel=0; window.ClipsDescendants=true; window.ZIndex=2; window.Parent=screenGui
Instance.new("UICorner",window).CornerRadius=UDim.new(0,12)
local bdr=Instance.new("UIStroke")
bdr.Color=Color3.fromRGB(255,255,255); bdr.Transparency=0.88; bdr.Thickness=1; bdr.Parent=window
local wg=Instance.new("UIGradient")
wg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(22,16,40)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(8,8,18))})
wg.Rotation=135; wg.Parent=window

-- Title bar
local titleBar=Instance.new("Frame")
titleBar.Name="TitleBar"; titleBar.Size=UDim2.new(1,0,0,44)
titleBar.BackgroundColor3=Color3.fromRGB(18,12,36); titleBar.BackgroundTransparency=0.1
titleBar.BorderSizePixel=0; titleBar.ZIndex=3; titleBar.Parent=window
local tbg=Instance.new("UIGradient")
tbg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(50,30,100)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(18,12,36))})
tbg.Rotation=90; tbg.Parent=titleBar

local dot=Instance.new("Frame")
dot.Size=UDim2.new(0,10,0,10); dot.Position=UDim2.new(0,14,0.5,-5)
dot.BackgroundColor3=Color3.fromRGB(130,80,255); dot.BorderSizePixel=0; dot.ZIndex=4; dot.Parent=titleBar
Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)

local titleLabel=Instance.new("TextLabel")
titleLabel.Size=UDim2.new(0,240,1,0); titleLabel.Position=UDim2.new(0,32,0,0)
titleLabel.BackgroundTransparency=1; titleLabel.Text="NyxScript  ·  Valley Prison"
titleLabel.TextColor3=Color3.fromRGB(210,190,255); titleLabel.Font=Enum.Font.GothamBold
titleLabel.TextSize=14; titleLabel.TextXAlignment=Enum.TextXAlignment.Left; titleLabel.ZIndex=4; titleLabel.Parent=titleBar

local function winBtn(xOff,col,lbl)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,22,0,22); b.Position=UDim2.new(1,xOff,0.5,-11)
    b.BackgroundColor3=col; b.Text=lbl; b.TextColor3=Color3.new(1,1,1)
    b.Font=Enum.Font.GothamBold; b.TextSize=11; b.BorderSizePixel=0; b.ZIndex=4; b.Parent=titleBar
    Instance.new("UICorner",b).CornerRadius=UDim.new(1,0)
    b.MouseEnter:Connect(function() tweenProp(b,0.08,{BackgroundTransparency=0.3}) end)
    b.MouseLeave:Connect(function() tweenProp(b,0.08,{BackgroundTransparency=0}) end)
    return b
end
local minBtn=winBtn(-78,Color3.fromRGB(200,160,30),"–")
local clsBtn=winBtn(-46,Color3.fromRGB(200,50,50),"✕")
clsBtn.MouseButton1Click:Connect(function()
    tweenProp(window,0.18,{Size=UDim2.new(0,WIN_W,0,0)}); task.wait(0.2)
    window.Visible=false; overlay.Visible=false; CFG.GuiOpen=false
end)
minBtn.MouseButton1Click:Connect(function()
    local mini=window.Size.Y.Offset<50
    tweenProp(window,0.2,{Size=mini and UDim2.new(0,WIN_W,0,WIN_H) or UDim2.new(0,WIN_W,0,44)})
end)

-- Drag
local _drag,_dStart,_dWin
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        _drag=true; _dStart=i.Position; _dWin=window.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if _drag and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-_dStart
        window.Position=UDim2.new(_dWin.X.Scale,_dWin.X.Offset+d.X,_dWin.Y.Scale,_dWin.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then _drag=false end
end)

-- Sidebar
local SIDEBAR_W=160
local sidebar=Instance.new("Frame")
sidebar.Size=UDim2.new(0,SIDEBAR_W,1,-44); sidebar.Position=UDim2.new(0,0,0,44)
sidebar.BackgroundColor3=Color3.fromRGB(12,8,24); sidebar.BackgroundTransparency=0.05
sidebar.BorderSizePixel=0; sidebar.ZIndex=3; sidebar.Parent=window
local sbg=Instance.new("UIGradient")
sbg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(20,12,40)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(10,8,20))})
sbg.Rotation=180; sbg.Parent=sidebar
local sbs=Instance.new("UIStroke")
sbs.Color=Color3.fromRGB(255,255,255); sbs.Transparency=0.92; sbs.Thickness=1; sbs.Parent=sidebar
local sbLayout=Instance.new("UIListLayout")
sbLayout.SortOrder=Enum.SortOrder.LayoutOrder; sbLayout.Padding=UDim.new(0,3); sbLayout.Parent=sidebar
Instance.new("UIPadding",sidebar).PaddingTop=UDim.new(0,10)

local sbSep=Instance.new("Frame")
sbSep.Size=UDim2.new(0,1,1,-44); sbSep.Position=UDim2.new(0,SIDEBAR_W,0,44)
sbSep.BackgroundColor3=Color3.fromRGB(255,255,255); sbSep.BackgroundTransparency=0.88
sbSep.BorderSizePixel=0; sbSep.ZIndex=3; sbSep.Parent=window

-- Content
local content=Instance.new("ScrollingFrame")
content.Size=UDim2.new(1,-SIDEBAR_W-1,1,-44); content.Position=UDim2.new(0,SIDEBAR_W+1,0,44)
content.BackgroundTransparency=1; content.ScrollBarThickness=4
content.ScrollBarImageColor3=Color3.fromRGB(100,60,200)
content.CanvasSize=UDim2.new(0,0,0,0); content.AutomaticCanvasSize=Enum.AutomaticSize.Y
content.BorderSizePixel=0; content.ZIndex=3; content.Parent=window
local cp=Instance.new("UIPadding")
cp.PaddingLeft=UDim.new(0,14); cp.PaddingRight=UDim.new(0,14)
cp.PaddingTop=UDim.new(0,10); cp.PaddingBottom=UDim.new(0,14); cp.Parent=content
local cl=Instance.new("UIListLayout")
cl.SortOrder=Enum.SortOrder.LayoutOrder; cl.Padding=UDim.new(0,8); cl.Parent=content

-- ================================================================
--  GUI COMPONENTS
-- ================================================================
local PAGES={}; local SB_BTNS={}

local function showPage(name)
    for n,f in pairs(PAGES) do f.Visible=(n==name) end
    CFG.ActivePage=name
    for n,btn in pairs(SB_BTNS) do
        local act=(n==name)
        tweenProp(btn,0.12,{BackgroundColor3=act and Color3.fromRGB(45,28,80) or Color3.fromRGB(0,0,0),
            BackgroundTransparency=act and 0.2 or 1})
        local l=btn:FindFirstChildOfClass("TextLabel")
        if l then l.TextColor3=act and Color3.fromRGB(200,160,255) or Color3.fromRGB(140,130,160) end
    end
end

local SB_ICONS={Home="⌂",Combat="⚔",ESP="👁",Movement="🏃",Teleportation="📍",
    Spawning="📦",["Prison System"]="🔐",["Anti-Kick"]="🛡"}

local function makeSidebarBtn(name,order)
    local btn=Instance.new("TextButton")
    btn.Name=name; btn.Size=UDim2.new(1,-16,0,36); btn.Position=UDim2.new(0,8,0,0)
    btn.BackgroundTransparency=1; btn.Text=""; btn.LayoutOrder=order; btn.BorderSizePixel=0
    btn.ZIndex=4; btn.Parent=sidebar
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,7)
    local icon=Instance.new("TextLabel")
    icon.Size=UDim2.new(0,24,1,0); icon.BackgroundTransparency=1
    icon.Text=SB_ICONS[name] or "·"; icon.TextColor3=Color3.fromRGB(140,130,160)
    icon.Font=Enum.Font.GothamBold; icon.TextSize=15; icon.ZIndex=5; icon.Parent=btn
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-30,1,0); lbl.Position=UDim2.new(0,28,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=name; lbl.TextColor3=Color3.fromRGB(140,130,160)
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.ZIndex=5; lbl.Parent=btn
    btn.MouseEnter:Connect(function()
        if CFG.ActivePage~=name then tweenProp(btn,0.1,{BackgroundTransparency=0.7,BackgroundColor3=Color3.fromRGB(40,25,70)}) end
    end)
    btn.MouseLeave:Connect(function()
        if CFG.ActivePage~=name then tweenProp(btn,0.1,{BackgroundTransparency=1}) end
    end)
    btn.MouseButton1Click:Connect(function() showPage(name) end)
    SB_BTNS[name]=btn
end

local function makePage(name,order)
    local f=Instance.new("Frame")
    f.Name=name; f.Size=UDim2.new(1,0,0,0); f.AutomaticSize=Enum.AutomaticSize.Y
    f.BackgroundTransparency=1; f.LayoutOrder=order; f.Visible=false; f.Parent=content
    local lay=Instance.new("UIListLayout")
    lay.SortOrder=Enum.SortOrder.LayoutOrder; lay.Padding=UDim.new(0,8); lay.Parent=f
    PAGES[name]=f; return f
end

local function sectionHdr(page,text)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,26); f.BackgroundTransparency=1; f.BorderSizePixel=0; f.Parent=page
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1; l.Text=text:upper()
    l.TextColor3=Color3.fromRGB(110,80,180); l.Font=Enum.Font.GothamBold; l.TextSize=11
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=f
    local line=Instance.new("Frame")
    line.Size=UDim2.new(1,0,0,1); line.Position=UDim2.new(0,0,1,-1)
    line.BackgroundColor3=Color3.fromRGB(80,50,140); line.BackgroundTransparency=0.6
    line.BorderSizePixel=0; line.Parent=f
end

local function card(page)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,0); f.AutomaticSize=Enum.AutomaticSize.Y
    f.BackgroundColor3=Color3.fromRGB(16,12,28); f.BackgroundTransparency=0.1
    f.BorderSizePixel=0; f.Parent=page
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
    local s=Instance.new("UIStroke")
    s.Color=Color3.fromRGB(255,255,255); s.Transparency=0.91; s.Thickness=1; s.Parent=f
    local lay=Instance.new("UIListLayout")
    lay.SortOrder=Enum.SortOrder.LayoutOrder; lay.Padding=UDim.new(0,0); lay.Parent=f
    local pad=Instance.new("UIPadding")
    pad.PaddingLeft=UDim.new(0,12); pad.PaddingRight=UDim.new(0,12)
    pad.PaddingTop=UDim.new(0,8); pad.PaddingBottom=UDim.new(0,8); pad.Parent=f
    return f
end

local function toggleRow(parent,label,desc,key,onChange)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,desc and 48 or 36); row.BackgroundTransparency=1
    row.BorderSizePixel=0; row.Parent=parent
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-56,0,18); lbl.Position=UDim2.new(0,0,0,desc and 6 or 9)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=Color3.fromRGB(210,205,225)
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
    if desc then
        local sub=Instance.new("TextLabel")
        sub.Size=UDim2.new(1,-56,0,14); sub.Position=UDim2.new(0,0,0,26)
        sub.BackgroundTransparency=1; sub.Text=desc; sub.TextColor3=Color3.fromRGB(110,105,130)
        sub.Font=Enum.Font.Gotham; sub.TextSize=11; sub.TextXAlignment=Enum.TextXAlignment.Left; sub.Parent=row
    end
    local pill=Instance.new("TextButton")
    pill.Size=UDim2.new(0,44,0,24); pill.Position=UDim2.new(1,-44,0.5,-12)
    pill.Text=""; pill.BorderSizePixel=0; pill.Parent=row
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,18,0,18); knob.AnchorPoint=Vector2.new(0,0.5)
    knob.Position=UDim2.new(0,3,0.5,0); knob.BackgroundColor3=Color3.new(1,1,1)
    knob.BorderSizePixel=0; knob.Parent=pill
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local function setState(on)
        CFG[key]=on
        tweenProp(pill,0.14,{BackgroundColor3=on and Color3.fromRGB(100,55,220) or Color3.fromRGB(40,35,55)})
        tweenProp(knob,0.14,{Position=on and UDim2.new(1,-21,0.5,0) or UDim2.new(0,3,0.5,0)})
        countEnabled()
        if onChange then onChange(on) end
    end
    setState(CFG[key] or false)
    pill.MouseButton1Click:Connect(function() setState(not CFG[key]) end)
    return setState
end

local function sliderRow(parent,label,key,min,max,step,onChange)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,52); row.BackgroundTransparency=1; row.BorderSizePixel=0; row.Parent=parent
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-60,0,18); lbl.Position=UDim2.new(0,0,0,4)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=Color3.fromRGB(200,195,215)
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
    local valLbl=Instance.new("TextLabel")
    valLbl.Size=UDim2.new(0,55,0,18); valLbl.Position=UDim2.new(1,-55,0,4)
    valLbl.BackgroundTransparency=1; valLbl.Text=tostring(CFG[key])
    valLbl.TextColor3=Color3.fromRGB(140,100,240); valLbl.Font=Enum.Font.GothamBold
    valLbl.TextSize=13; valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.Parent=row
    local track=Instance.new("Frame")
    track.Size=UDim2.new(1,0,0,6); track.Position=UDim2.new(0,0,0,34)
    track.BackgroundColor3=Color3.fromRGB(35,30,50); track.BorderSizePixel=0; track.Parent=row
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local ratio=(CFG[key]-min)/math.max(max-min,0.001)
    local fill=Instance.new("Frame")
    fill.Size=UDim2.new(ratio,0,1,0); fill.BackgroundColor3=Color3.fromRGB(100,55,220)
    fill.BorderSizePixel=0; fill.Parent=track
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local thumb=Instance.new("Frame")
    thumb.Size=UDim2.new(0,14,0,14); thumb.AnchorPoint=Vector2.new(0.5,0.5)
    thumb.Position=UDim2.new(ratio,0,0.5,0); thumb.BackgroundColor3=Color3.new(1,1,1)
    thumb.BorderSizePixel=0; thumb.Parent=track
    Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)
    local dragging=false
    local function update(x)
        local t=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v=math.round((min+(max-min)*t)/step)*step
        CFG[key]=v; fill.Size=UDim2.new(t,0,1,0); thumb.Position=UDim2.new(t,0,0.5,0)
        valLbl.Text=tostring(v)
        if onChange then onChange(v) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; update(i.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then update(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
end

local function btnRow(parent,label,sub,fn)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,0,sub and 44 or 34); btn.BackgroundColor3=Color3.fromRGB(28,18,54)
    btn.BackgroundTransparency=0.1; btn.Text=""; btn.BorderSizePixel=0; btn.Parent=parent
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,7)
    local s=Instance.new("UIStroke")
    s.Color=Color3.fromRGB(130,80,255); s.Transparency=0.7; s.Thickness=1; s.Parent=btn
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-20,0,18); l.Position=UDim2.new(0,12,0,sub and 6 or 8)
    l.BackgroundTransparency=1; l.Text=label; l.TextColor3=Color3.fromRGB(190,165,255)
    l.Font=Enum.Font.GothamBold; l.TextSize=13; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=btn
    if sub then
        local sl=Instance.new("TextLabel")
        sl.Size=UDim2.new(1,-20,0,13); sl.Position=UDim2.new(0,12,0,26)
        sl.BackgroundTransparency=1; sl.Text=sub; sl.TextColor3=Color3.fromRGB(100,90,120)
        sl.Font=Enum.Font.Gotham; sl.TextSize=11; sl.TextXAlignment=Enum.TextXAlignment.Left; sl.Parent=btn
    end
    btn.MouseEnter:Connect(function() tweenProp(btn,0.1,{BackgroundColor3=Color3.fromRGB(50,32,90),BackgroundTransparency=0}) end)
    btn.MouseLeave:Connect(function() tweenProp(btn,0.1,{BackgroundColor3=Color3.fromRGB(28,18,54),BackgroundTransparency=0.1}) end)
    btn.MouseButton1Down:Connect(function() tweenProp(btn,0.06,{BackgroundColor3=Color3.fromRGB(70,45,120)}) end)
    btn.MouseButton1Click:Connect(fn)
end

local function dropdownRow(parent,label,options,key,onChange)
    local container=Instance.new("Frame")
    container.Size=UDim2.new(1,0,0,36); container.BackgroundTransparency=1
    container.ClipsDescendants=false; container.BorderSizePixel=0; container.Parent=parent
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(0.45,0,1,0); lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(200,195,215); lbl.Font=Enum.Font.Gotham; lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=container
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0.52,0,0,28); btn.Position=UDim2.new(0.48,0,0.5,-14)
    btn.BackgroundColor3=Color3.fromRGB(25,18,45); btn.BorderSizePixel=0
    btn.Text=tostring(CFG[key]); btn.TextColor3=Color3.fromRGB(160,120,255)
    btn.Font=Enum.Font.Gotham; btn.TextSize=12; btn.Parent=container
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
    local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(255,255,255); s.Transparency=0.88; s.Thickness=1; s.Parent=btn
    local df=Instance.new("Frame")
    df.Size=UDim2.new(0.52,0,0,0); df.Position=UDim2.new(0.48,0,1,4)
    df.BackgroundColor3=Color3.fromRGB(20,14,38); df.BorderSizePixel=0
    df.ClipsDescendants=true; df.ZIndex=10; df.Visible=false; df.Parent=container
    Instance.new("UICorner",df).CornerRadius=UDim.new(0,6)
    local s2=Instance.new("UIStroke"); s2.Color=Color3.fromRGB(255,255,255); s2.Transparency=0.88; s2.Thickness=1; s2.Parent=df
    local dl=Instance.new("UIListLayout"); dl.SortOrder=Enum.SortOrder.LayoutOrder; dl.Parent=df
    for _,opt in ipairs(options) do
        local ob=Instance.new("TextButton")
        ob.Size=UDim2.new(1,0,0,26); ob.BackgroundTransparency=1; ob.Text=opt
        ob.TextColor3=Color3.fromRGB(170,155,200); ob.Font=Enum.Font.Gotham; ob.TextSize=12; ob.ZIndex=11; ob.Parent=df
        ob.MouseButton1Click:Connect(function()
            CFG[key]=opt; btn.Text=opt
            tweenProp(df,0.1,{Size=UDim2.new(0.52,0,0,0)}); task.wait(0.12); df.Visible=false
            if onChange then onChange(opt) end
        end)
        ob.MouseEnter:Connect(function() tweenProp(ob,0.08,{BackgroundTransparency=0.7,BackgroundColor3=Color3.fromRGB(40,28,70)}) end)
        ob.MouseLeave:Connect(function() tweenProp(ob,0.08,{BackgroundTransparency=1}) end)
    end
    btn.MouseButton1Click:Connect(function()
        if df.Visible then tweenProp(df,0.1,{Size=UDim2.new(0.52,0,0,0)}); task.wait(0.12); df.Visible=false
        else df.Visible=true; tweenProp(df,0.12,{Size=UDim2.new(0.52,0,0,#options*26)}) end
    end)
end

-- ================================================================
--  BUILD SIDEBAR + PAGES
-- ================================================================
local PAGE_NAMES={"Home","Combat","ESP","Movement","Teleportation","Spawning","Prison System","Anti-Kick"}
for i,n in ipairs(PAGE_NAMES) do makeSidebarBtn(n,i); makePage(n,i) end

-- ================================================================
--  HOME PAGE
-- ================================================================
do
    local p=PAGES["Home"]
    local wc=card(p)
    local w=Instance.new("TextLabel")
    w.Size=UDim2.new(1,0,0,22); w.BackgroundTransparency=1
    w.Text="Welcome back, "..lp.Name; w.TextColor3=Color3.fromRGB(200,175,255)
    w.Font=Enum.Font.GothamBold; w.TextSize=16; w.TextXAlignment=Enum.TextXAlignment.Left; w.Parent=wc
    local s=Instance.new("TextLabel")
    s.Size=UDim2.new(1,0,0,16); s.BackgroundTransparency=1
    s.Text="NyxScript  ·  Valley Prison  ·  Right Shift to toggle"
    s.TextColor3=Color3.fromRGB(100,90,130); s.Font=Enum.Font.Gotham; s.TextSize=12
    s.TextXAlignment=Enum.TextXAlignment.Left; s.Parent=wc

    local sc=card(p)
    local sr=Instance.new("Frame")
    sr.Size=UDim2.new(1,0,0,60); sr.BackgroundTransparency=1; sr.Parent=sc
    local srl=Instance.new("UIListLayout")
    srl.FillDirection=Enum.FillDirection.Horizontal; srl.SortOrder=Enum.SortOrder.LayoutOrder
    srl.Padding=UDim.new(0,8); srl.Parent=sr
    local function statBox(label,val,col)
        local f=Instance.new("Frame")
        f.Size=UDim2.new(0.3,-4,1,0); f.BackgroundColor3=Color3.fromRGB(22,16,40)
        f.BorderSizePixel=0; f.Parent=sr
        Instance.new("UICorner",f).CornerRadius=UDim.new(0,7)
        local v=Instance.new("TextLabel")
        v.Size=UDim2.new(1,0,0,28); v.Position=UDim2.new(0,0,0,8)
        v.BackgroundTransparency=1; v.Text=val; v.TextColor3=col
        v.Font=Enum.Font.GothamBold; v.TextSize=20; v.Parent=f
        local l=Instance.new("TextLabel")
        l.Size=UDim2.new(1,0,0,14); l.Position=UDim2.new(0,0,0,38)
        l.BackgroundTransparency=1; l.Text=label; l.TextColor3=Color3.fromRGB(100,90,120)
        l.Font=Enum.Font.Gotham; l.TextSize=11; l.Parent=f
        return v
    end
    local enStat=statBox("Active",  "0",    Color3.fromRGB(120,80,255))
    local plStat=statBox("Players", tostring(#Players:GetPlayers()), Color3.fromRGB(60,200,120))
    statBox("Status","LIVE",Color3.fromRGB(60,200,100))

    sectionHdr(p,"Quick Toggles")
    local qc=card(p)
    toggleRow(qc,"Player ESP",    "See players through walls",   "PlayerESP")
    toggleRow(qc,"Aimbot",        "Auto-aim to nearest enemy",   "Aimbot")
    toggleRow(qc,"Speed Hack",    "Move faster than normal",     "SpeedEnabled",
        function(v) local h=getHum(lp); if h then h.WalkSpeed=v and CFG.Speed or 16 end end)
    toggleRow(qc,"Infinite Stamina","Never run out of stamina",  "InfStamina")
    toggleRow(qc,"Anti-Kick",     "Block kick attempts (ON)",    "AntiKick")

    RunService.RenderStepped:Connect(function()
        enStat.Text=tostring(countEnabled())
        plStat.Text=tostring(#Players:GetPlayers())
    end)
end

-- ================================================================
--  COMBAT PAGE
-- ================================================================
do
    local p=PAGES["Combat"]
    sectionHdr(p,"Aimbot")
    local ac=card(p)
    toggleRow(ac,"Aimbot",          "Smooth aim to nearest enemy",         "Aimbot")
    toggleRow(ac,"Aimlock",         "Hard-lock camera to target",          "Aimlock")
    toggleRow(ac,"FOV Ring",        "Show aim circle on screen",           "AimbotFOVRing")
    toggleRow(ac,"Require Gun",     "Only aim when holding a weapon",      "AimbotRequireGun")
    toggleRow(ac,"Wall Check",      "Block targeting through walls",       "AimbotWallCheck")
    toggleRow(ac,"Team Check",      "Skip teammates",                      "AimbotTeamCheck")
    sliderRow(ac,"FOV Radius",      "AimbotFOV",       30,  400,  10)
    sliderRow(ac,"Smoothness",      "AimbotSmooth",    0.02, 1,   0.02)
    dropdownRow(ac,"Aim Part",      {"Head","HumanoidRootPart","UpperTorso"},"AimbotPart")
    toggleRow(ac,"Aimlock",         "Hard lock (no smoothing)",            "Aimlock")
    toggleRow(ac,"Silent Aim",      "Hit without visually aiming",         "SilentAim")
    toggleRow(ac,"Triggerbot",      "Auto-fire when on enemy",             "Triggerbot")
    sliderRow(ac,"Trigger Delay",   "TriggerbotDelay", 0.01, 0.5,  0.01)

    sectionHdr(p,"Weapon Mechanics")
    local wc=card(p)
    toggleRow(wc,"No Recoil",       "Counteract camera recoil",            "NoRecoil")
    toggleRow(wc,"No Spread",       "Remove bullet spread",                "NoSpread")
    toggleRow(wc,"Hitbox Expand",   "Enlarge enemy hitboxes client-side",  "HitboxExpand")
    sliderRow(wc,"Hitbox Size",     "HitboxSize",      1,   20,   0.5)
end

-- ================================================================
--  ESP PAGE
-- ================================================================
do
    local p=PAGES["ESP"]
    sectionHdr(p,"Player ESP")
    local ec=card(p)
    toggleRow(ec,"Player Highlight","Color silhouette around players",     "PlayerESP")
    toggleRow(ec,"Wallhack",        "See highlights through walls",        "WallHack")
    toggleRow(ec,"Skeleton ESP",    "Draw bone lines on players",          "SkeletonESP")
    toggleRow(ec,"Name Tags",       "Show player names overhead",          "NameESP")
    toggleRow(ec,"Health Bars",     "Show HP above players",               "HealthESP")
    toggleRow(ec,"Distance",        "Show distance to each player",        "DistanceESP")
    sliderRow(ec,"Max Distance",    "ESPMaxDist",      250, 1000, 25)

    sectionHdr(p,"World Objects")
    local oc=card(p)
    toggleRow(oc,"Item ESP",        "Highlight collectible items",         "ItemESP")
    toggleRow(oc,"Weapon ESP",      "Highlight weapons and tools",         "WeaponESP")

    sectionHdr(p,"Colors")
    local cc=card(p)
    dropdownRow(cc,"Guard Color",   {"Red","Orange","Yellow","Pink"},       "_guardColor")
    dropdownRow(cc,"Prisoner Color",{"Blue","Cyan","Purple","White"},       "_prisonerColor")
end

-- ================================================================
--  MOVEMENT PAGE
-- ================================================================
do
    local p=PAGES["Movement"]
    sectionHdr(p,"Speed & Jump")
    local mc=card(p)
    toggleRow(mc,"Speed Hack",      "Override walk speed",                 "SpeedEnabled",
        function(v) local h=getHum(lp); if h then h.WalkSpeed=v and CFG.Speed or 16 end end)
    sliderRow(mc,"Walk Speed",      "Speed",           16,  64,   1,
        function(v) if CFG.SpeedEnabled then local h=getHum(lp); if h then h.WalkSpeed=v end end end)
    toggleRow(mc,"Infinite Jump",   "Jump unlimited times",                "InfJump")
    sliderRow(mc,"Jump Power",      "JumpPower",       50,  500,  10,
        function(v) local h=getHum(lp); if h then h.JumpPower=v end end)

    sectionHdr(p,"Stamina")
    local sc=card(p)
    toggleRow(sc,"Infinite Stamina","Never get tired",                     "InfStamina")

    sectionHdr(p,"Fly")
    local fc=card(p)
    toggleRow(fc,"Fly",             "Float freely  (WASD + Space/Ctrl)",   "Fly",
        function(v) if v then _startFly() else _stopFly() end end)
    sliderRow(fc,"Fly Speed",       "FlySpeed",        5,   64,   1)

    sectionHdr(p,"Noclip")
    local nc=card(p)
    toggleRow(nc,"Noclip",          "Phase through all walls",             "Noclip")
end

-- ================================================================
--  TELEPORTATION PAGE
-- ================================================================
do
    local p=PAGES["Teleportation"]
    sectionHdr(p,"Locations")
    local lc=card(p)
    local LOCS={
        {"Exit / Gate",   function() for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and (v.Name:lower():find("exit") or v.Name:lower():find("gate")) then return v end end end},
        {"Guard Room",    function() for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and v.Name:lower():find("guard") then return v end end end},
        {"Armory",        function() for _,v in ipairs(workspace:GetDescendants()) do
            local n=v.Name:lower()
            if v:IsA("BasePart") and (n:find("armory") or n:find("weapon")) then return v end end end},
        {"Cafeteria",     function() for _,v in ipairs(workspace:GetDescendants()) do
            local n=v.Name:lower()
            if v:IsA("BasePart") and (n:find("cafe") or n:find("food")) then return v end end end},
        {"Prison Spawn",  function() return workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChild("Spawn") end},
        {"Visitor Lobby", function() for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and v.Name:lower():find("visit") then return v end end end},
    }
    for _,loc in ipairs(LOCS) do
        local name,fn=loc[1],loc[2]
        btnRow(lc,"→  "..name,nil,function()
            local root=getRoot(lp); if not root then return end
            local t=fn()
            if t and t:IsA("BasePart") then
                root.CFrame=t.CFrame+Vector3.new(0,4,0)
                notify("Teleport","Teleported to "..name,"success")
            else notify("Teleport",name.." not found","warn") end
        end)
    end

    sectionHdr(p,"Teleport to Player")
    local pc=card(p)
    local plFrame=Instance.new("Frame")
    plFrame.Size=UDim2.new(1,0,0,0); plFrame.AutomaticSize=Enum.AutomaticSize.Y
    plFrame.BackgroundTransparency=1; plFrame.Parent=pc
    local pll=Instance.new("UIListLayout"); pll.SortOrder=Enum.SortOrder.LayoutOrder
    pll.Padding=UDim.new(0,4); pll.Parent=plFrame
    local function rebuildPL()
        for _,c in ipairs(plFrame:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
        end
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl~=lp then
                btnRow(plFrame,"→  "..pl.Name,pl.Team and pl.Team.Name or "No Team",function()
                    local r1=getRoot(lp); local r2=getRoot(pl)
                    if r1 and r2 then r1.CFrame=r2.CFrame+Vector3.new(2,0,2)
                        notify("Teleport","Teleported to "..pl.Name,"success") end
                end)
            end
        end
    end
    rebuildPL()
    Players.PlayerAdded:Connect(rebuildPL); Players.PlayerRemoving:Connect(rebuildPL)
    btnRow(pc,"↺  Refresh List",nil,rebuildPL)

    sectionHdr(p,"Saved Positions")
    local spc=card(p)
    local spFrame=Instance.new("Frame")
    spFrame.Size=UDim2.new(1,0,0,0); spFrame.AutomaticSize=Enum.AutomaticSize.Y
    spFrame.BackgroundTransparency=1; spFrame.Parent=spc
    local spl=Instance.new("UIListLayout"); spl.SortOrder=Enum.SortOrder.LayoutOrder
    spl.Padding=UDim.new(0,4); spl.Parent=spFrame
    local function rebuildSP()
        for _,c in ipairs(spFrame:GetChildren()) do c:Destroy() end
        for i,sp in ipairs(CFG.SavedPositions) do
            local row=Instance.new("Frame")
            row.Size=UDim2.new(1,0,0,32); row.BackgroundTransparency=1; row.Parent=spFrame
            local rl=Instance.new("UIListLayout"); rl.FillDirection=Enum.FillDirection.Horizontal
            rl.Padding=UDim.new(0,4); rl.Parent=row
            local nl=Instance.new("TextLabel")
            nl.Size=UDim2.new(0.5,-4,1,0); nl.BackgroundTransparency=1; nl.Text=sp.name
            nl.TextColor3=Color3.fromRGB(180,170,210); nl.Font=Enum.Font.Gotham; nl.TextSize=12
            nl.TextXAlignment=Enum.TextXAlignment.Left; nl.Parent=row
            local tb=Instance.new("TextButton"); tb.Size=UDim2.new(0.25,-4,0,26)
            tb.BackgroundColor3=Color3.fromRGB(28,18,54); tb.Text="Go"
            tb.TextColor3=Color3.fromRGB(160,120,255); tb.Font=Enum.Font.GothamBold; tb.TextSize=12
            tb.BorderSizePixel=0; tb.Parent=row
            Instance.new("UICorner",tb).CornerRadius=UDim.new(0,5)
            tb.MouseButton1Click:Connect(function() local r=getRoot(lp); if r then r.CFrame=sp.cf end end)
            local db=Instance.new("TextButton"); db.Size=UDim2.new(0.25,-4,0,26)
            db.BackgroundColor3=Color3.fromRGB(50,18,18); db.Text="Del"
            db.TextColor3=Color3.fromRGB(255,100,100); db.Font=Enum.Font.GothamBold; db.TextSize=12
            db.BorderSizePixel=0; db.Parent=row
            Instance.new("UICorner",db).CornerRadius=UDim.new(0,5)
            db.MouseButton1Click:Connect(function() table.remove(CFG.SavedPositions,i); rebuildSP() end)
        end
    end
    rebuildSP()
    btnRow(spc,"📌  Save Current Position","Saves where you are standing",function()
        local root=getRoot(lp)
        if root then
            local n="Pos "..(#CFG.SavedPositions+1)
            table.insert(CFG.SavedPositions,{name=n,cf=root.CFrame})
            rebuildSP(); notify("Saved","Position saved as "..n,"success")
        end
    end)
end

-- ================================================================
--  SPAWNING PAGE
-- ================================================================
do
    local p=PAGES["Spawning"]

    -- Generic spawn function: searches RS then workspace by exact name
    local function spawnItem(name)
        for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("Tool") and v.Name==name then
                v:Clone().Parent=lp.Backpack
                notify("Spawned",name.." added to backpack","success"); return
            end
        end
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Tool") and v.Name==name then
                v:Clone().Parent=lp.Backpack
                notify("Spawned",name.." cloned from world","info"); return
            end
        end
        notify("Not Found",name.." is not in the game world yet","warn")
    end

    -- Scrollable sub-list builder
    local function makeList(page, items)
        local c=card(page)
        local sf=Instance.new("ScrollingFrame")
        sf.Size=UDim2.new(1,0,0,180); sf.CanvasSize=UDim2.new(0,0,0,0)
        sf.AutomaticCanvasSize=Enum.AutomaticSize.Y
        sf.ScrollBarThickness=3; sf.ScrollBarImageColor3=Color3.fromRGB(100,60,200)
        sf.BackgroundTransparency=1; sf.BorderSizePixel=0; sf.Parent=c
        local lay=Instance.new("UIListLayout")
        lay.SortOrder=Enum.SortOrder.LayoutOrder; lay.Padding=UDim.new(0,3); lay.Parent=sf
        for _,name in ipairs(items) do
            local btn=Instance.new("TextButton")
            btn.Size=UDim2.new(1,0,0,28); btn.BackgroundColor3=Color3.fromRGB(20,14,36)
            btn.BackgroundTransparency=0.3; btn.BorderSizePixel=0; btn.Text=""
            btn.Parent=sf
            Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
            local lbl=Instance.new("TextLabel")
            lbl.Size=UDim2.new(1,-50,1,0); lbl.Position=UDim2.new(0,10,0,0)
            lbl.BackgroundTransparency=1; lbl.Text=name
            lbl.TextColor3=Color3.fromRGB(200,190,220); lbl.Font=Enum.Font.Gotham
            lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=btn
            local sp=Instance.new("TextButton")
            sp.Size=UDim2.new(0,40,0,22); sp.Position=UDim2.new(1,-44,0.5,-11)
            sp.BackgroundColor3=Color3.fromRGB(60,35,110); sp.BorderSizePixel=0
            sp.Text="Get"; sp.TextColor3=Color3.fromRGB(180,140,255)
            sp.Font=Enum.Font.GothamBold; sp.TextSize=11; sp.Parent=btn
            Instance.new("UICorner",sp).CornerRadius=UDim.new(0,5)
            sp.MouseButton1Click:Connect(function() spawnItem(name) end)
            btn.MouseEnter:Connect(function() tweenProp(btn,0.08,{BackgroundColor3=Color3.fromRGB(35,25,60),BackgroundTransparency=0}) end)
            btn.MouseLeave:Connect(function() tweenProp(btn,0.08,{BackgroundColor3=Color3.fromRGB(20,14,36),BackgroundTransparency=0.3}) end)
        end
    end

    sectionHdr(p,"Keycards")
    makeList(p,{
        "Corrections Keycard","Supervisors Keycard","Directors Keycard",
        "Employee Keycard","Master Keycard","Developer Keycard",
    })

    sectionHdr(p,"Materials")
    makeList(p,{"Metal","Plastic","Rope","Shiv"})

    sectionHdr(p,"Shotguns")
    makeList(p,{"KSG-12","M1014","Model 590","Saiga 12K","Terminator","Toz 106",
        "John's KSG","PKSG-12","GEN-12"})

    sectionHdr(p,"SMGs")
    makeList(p,{"M1928","M1A1","M3 Grease Gun","MP40","MP5","MP5 Mod","MP7","MP7 Mod",
        "Scorpion E3","SE3 Express","UMP45","UMP45-X","P90","PUMP45"})

    sectionHdr(p,"Assault Rifles")
    makeList(p,{"AMD-65","AK-12","AK-47","AK-74","AR-57","ARP","M4A1","HK416",
        "HK416 Patrol","HK416D","G36","G36C","AA .50 Beowulf","M16A4","M16A1",
        "SCAR-L","LEO MCX Spear","MCX Spear","The Harrow","IMI Galil",
        "L1A1 SLR","SA58 OSW-E","SA58 OSW-L","SA58 OSW","SKS","VSS Vintorez",
        "Patriot","AR2","C8IUR","Cat Gun","M4A1 DMR","SG 550","Honey Badger"})

    sectionHdr(p,"Pistols")
    makeList(p,{"92FS","Makarov","1911 Emperor","SW500","93R","G18","G18C",
        "G17","Arrow Fed G17","Giant17","Godgun","Paterson 1836","PM82A1"})

    sectionHdr(p,"Heavy / Special")
    makeList(p,{"M82A1","Ultimax 100","M249 SAW","Tempest","MGL MK1S"})

    sectionHdr(p,"Item Manipulation")
    local ic=card(p)
    btnRow(ic,"Collect All Dropped Items","Pull all dropped tools to backpack",function()
        local n=0
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Tool") then v.Parent=lp.Backpack; n+=1 end
        end
        notify("Collected",n.." items picked up","success")
    end)
    btnRow(ic,"Drop All Items","Empty backpack to ground",function()
        local root=getRoot(lp)
        for _,v in ipairs(lp.Backpack:GetChildren()) do
            if v:IsA("Tool") then
                v.Parent=workspace
                if v:FindFirstChild("Handle") and root then
                    v.Handle.CFrame=root.CFrame+Vector3.new(math.random(-3,3),1,math.random(-3,3))
                end
            end
        end
        notify("Dropped","Backpack cleared","info")
    end)
end

-- ================================================================
--  PRISON SYSTEM PAGE
-- ================================================================
do
    local p=PAGES["Prison System"]
    sectionHdr(p,"Restriction Bypasses")
    local rc=card(p)
    btnRow(rc,"Bypass Door Locks","Fire all door open remotes",function()
        for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name:lower():find("door") then pcall(function() v:FireServer() end) end
        end
        notify("Bypass","Fired door remotes","info")
    end)
    btnRow(rc,"Remove Handcuffs","Attempt to free yourself",function()
        local char=getChar(lp)
        if char then
            for _,v in ipairs(char:GetDescendants()) do
                if v:IsA("WeldConstraint") and v.Name:lower():find("cuff") then v:Destroy() end
            end
        end
        for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name:lower():find("escape") then pcall(function() v:FireServer() end) end
        end
        notify("Freed","Attempted handcuff removal","success")
    end)
    sectionHdr(p,"Team & Role")
    local tc=card(p)
    for _,tname in ipairs({"Prisoner","Guard","Warden","Visitor","Criminal","Police"}) do
        btnRow(tc,"Set Team: "..tname,nil,function()
            for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") and (v.Name:lower():find("team") or v.Name:lower():find("role")) then
                    pcall(function() v:FireServer(tname) end)
                end
            end
            for _,team in ipairs(game:GetService("Teams"):GetTeams()) do
                if team.Name:lower():find(tname:lower()) then pcall(function() lp.Team=team end) end
            end
            notify("Team","Attempted team change to "..tname,"info")
        end)
    end
    sectionHdr(p,"Remote Monitor")
    local rmc=card(p)
    toggleRow(rmc,"Log All Remotes","Print fired remotes to console","_logRemotes")
    toggleRow(rmc,"Block Arrest Remote","Intercept arrest calls","_blockArrest")
    btnRow(rmc,"List All Remotes","Print to output",function()
        local n=0
        for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                print("[VP] "..v:GetFullName()); n+=1
            end
        end
        notify("Remotes",n.." found (see output)","info")
    end)
end

-- ================================================================
--  ANTI-KICK PAGE
-- ================================================================
do
    local p=PAGES["Anti-Kick"]
    sectionHdr(p,"Protection")
    local ac=card(p)
    toggleRow(ac,"Anti-Kick","Block server kick attempts (on by default)","AntiKick",function(v)
        if v then
            pcall(function()
                if not getrawmetatable then return end
                local mt=getrawmetatable(lp)
                local old=mt.__namecall
                mt.__namecall=newcclosure(function(self,...)
                    if getnamecallmethod()=="Kick" then
                        notify("Anti-Kick","Kick blocked","success"); return
                    end
                    return old(self,...)
                end)
            end)
        end
    end)
    toggleRow(ac,"Anti-Disconnect","Reconnect on unexpected drops","AntiDisconnect")
    sectionHdr(p,"Remote Filtering")
    local rfc=card(p)
    toggleRow(rfc,"Block Ban Remotes","Intercept known ban remotes","_blockBan")
    btnRow(rfc,"Scan Kick Remotes","Find suspicious remotes",function()
        local found={}
        for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
            local n=v.Name:lower()
            if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and
               (n:find("kick") or n:find("ban") or n:find("punish")) then
                table.insert(found,v:GetFullName())
            end
        end
        if #found==0 then notify("Scan","No suspicious remotes found","info")
        else
            notify("Scan",#found.." found (see output)","warn")
            for _,path in ipairs(found) do print("[VP KickScan] "..path) end
        end
    end)
end

-- ================================================================
--  CHEAT LOGIC
-- ================================================================

-- ── Anti-kick hook (runs at startup since it's on by default) ──
pcall(function()
    if not getrawmetatable then return end
    local mt=getrawmetatable(lp)
    local old=mt.__namecall
    mt.__namecall=newcclosure(function(self,...)
        local method=getnamecallmethod()
        if method=="Kick" and CFG.AntiKick then
            notify("Anti-Kick","Kick blocked","success"); return
        end
        if (method=="FireServer" or method=="InvokeServer") then
            local n=tostring(self.Name):lower()
            if CFG._blockArrest and (n:find("arrest") or n:find("cuff") or n:find("detain")) then
                notify("Blocked","Arrest remote blocked","success"); return
            end
            if CFG._blockBan and (n:find("ban") or n:find("kick") or n:find("punish")) then
                notify("Blocked","Ban remote blocked","success"); return
            end
            if CFG._logRemotes then print("[VP Remote] "..method.." → "..self:GetFullName()) end
        end
        return old(self,...)
    end)
end)

-- ── FOV Ring (Drawing API) ────────────────────────────────────
local fovRing
local hasDrawing=pcall(function()
    fovRing=Drawing.new("Circle")
    fovRing.Color=Color3.fromRGB(200,150,255)
    fovRing.Thickness=1.5
    fovRing.Filled=false
    fovRing.Visible=false
end)

-- ── Skeleton ESP (Drawing lines) ─────────────────────────────
local _skelLines={}
local SKEL_PAIRS={
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
}
local function clearSkel()
    for _,l in ipairs(_skelLines) do pcall(function() l:Remove() end) end
    _skelLines={}
end
local function drawSkeleton()
    clearSkel()
    if not CFG.SkeletonESP or not hasDrawing then return end
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==lp then continue end
        if distTo(pl)>CFG.ESPMaxDist then continue end
        local char=getChar(pl); if not char then continue end
        local hum=getHum(pl); if not hum or hum.Health<=0 then continue end
        for _,pair in ipairs(SKEL_PAIRS) do
            local a=char:FindFirstChild(pair[1]); local b=char:FindFirstChild(pair[2])
            if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                local sa,va=cam:WorldToViewportPoint(a.Position)
                local sb,vb=cam:WorldToViewportPoint(b.Position)
                if va and vb then
                    local line=Drawing.new("Line")
                    line.From=Vector2.new(sa.X,sa.Y); line.To=Vector2.new(sb.X,sb.Y)
                    line.Color=Color3.fromRGB(255,255,255); line.Thickness=1.2; line.Visible=true
                    table.insert(_skelLines,line)
                end
            end
        end
    end
end

-- ── ESP Highlights ────────────────────────────────────────────
local _espH={}
local function getTeamCol(p)
    local t=tostring(p.Team and p.Team.Name or ""):lower()
    if t:find("guard") or t:find("police") or t:find("warden") then return Color3.fromRGB(255,60,60) end
    return Color3.fromRGB(80,150,255)
end
local function removeESP(p)
    local h=_espH[p]; if h and h.Parent then h:Destroy() end; _espH[p]=nil
end
local function buildESP(p)
    if p==lp then return end
    removeESP(p)
    local function setup()
        local char=getChar(p); if not char then return end
        local h=Instance.new("Highlight")
        h.FillColor=getTeamCol(p); h.OutlineColor=getTeamCol(p)
        h.FillTransparency=0.72; h.OutlineTransparency=0
        h.DepthMode=CFG.WallHack and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        h.Adornee=char; h.Enabled=CFG.PlayerESP; h.Parent=char; _espH[p]=h
    end
    setup(); p.CharacterAdded:Connect(function() task.wait(0.15); setup() end)
end
local function refreshESP()
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl~=lp then
            if CFG.PlayerESP then
                if not _espH[pl] then buildESP(pl) end
                local h=_espH[pl]
                if h and h.Parent then
                    h.Enabled=CFG.PlayerESP and distTo(pl)<=CFG.ESPMaxDist
                    h.DepthMode=CFG.WallHack and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                end
            else
                removeESP(pl)
            end
        end
    end
end
Players.PlayerAdded:Connect(function(p) if CFG.PlayerESP then buildESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)

-- ── Name/Health/Distance Tags ─────────────────────────────────
local tagFolder=Instance.new("Folder"); tagFolder.Name="_VPTags"; tagFolder.Parent=workspace
local function updateTags()
    for _,bb in ipairs(tagFolder:GetChildren()) do
        if not Players:FindFirstChild(bb.Name) then bb:Destroy() end
    end
    local anyTag=CFG.NameESP or CFG.HealthESP or CFG.DistanceESP
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==lp then continue end
        local root=getRoot(pl); local hum=getHum(pl)
        if not root or not hum then continue end
        if distTo(pl)>CFG.ESPMaxDist then
            local bb=tagFolder:FindFirstChild(pl.Name); if bb then bb.Enabled=false end
            continue
        end
        local bb=tagFolder:FindFirstChild(pl.Name)
        if not bb then
            bb=Instance.new("BillboardGui"); bb.Name=pl.Name
            bb.Size=UDim2.new(0,130,0,44); bb.StudsOffset=Vector3.new(0,3.4,0)
            bb.AlwaysOnTop=true; bb.ResetOnSpawn=false; bb.Parent=tagFolder
            local nl=Instance.new("TextLabel"); nl.Name="Name"
            nl.Size=UDim2.new(1,0,0,18); nl.BackgroundTransparency=1
            nl.Font=Enum.Font.GothamBold; nl.TextSize=13
            nl.TextStrokeTransparency=0; nl.TextXAlignment=Enum.TextXAlignment.Center; nl.Parent=bb
            local il=Instance.new("TextLabel"); il.Name="Info"
            il.Size=UDim2.new(1,0,0,14); il.Position=UDim2.new(0,0,0,20)
            il.BackgroundTransparency=1; il.Font=Enum.Font.Gotham; il.TextSize=11
            il.TextStrokeTransparency=0.2; il.TextXAlignment=Enum.TextXAlignment.Center; il.Parent=bb
        end
        bb.Adornee=root; bb.Enabled=anyTag
        local nl=bb:FindFirstChild("Name"); local il=bb:FindFirstChild("Info")
        if nl then nl.Text=CFG.NameESP and pl.Name or ""; nl.TextColor3=getTeamCol(pl) end
        if il then
            local parts={}
            if CFG.HealthESP then table.insert(parts,math.floor(hum.Health).."HP") end
            if CFG.DistanceESP then table.insert(parts,math.floor(distTo(pl)).."m") end
            il.Text=table.concat(parts,"  "); il.TextColor3=Color3.fromRGB(200,200,220)
        end
    end
end

-- ── Item / Weapon ESP ─────────────────────────────────────────
local _itemH={}
local function refreshItemESP()
    for v,h in pairs(_itemH) do
        if not v.Parent or (not CFG.ItemESP and not CFG.WeaponESP) then
            if h.Parent then h:Destroy() end; _itemH[v]=nil
        end
    end
    if not CFG.ItemESP and not CFG.WeaponESP then return end
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Tool") and not _itemH[v] then
            local n=v.Name:lower()
            local isWep=n:find("gun") or n:find("pistol") or n:find("rifle") or n:find("knife") or n:find("shot")
            if (CFG.WeaponESP and isWep) or (CFG.ItemESP and not isWep) or CFG.ItemESP then
                local h=Instance.new("Highlight")
                h.FillColor=isWep and Color3.fromRGB(255,200,50) or Color3.fromRGB(50,220,150)
                h.OutlineColor=h.FillColor; h.FillTransparency=0.5
                h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                h.Adornee=v; h.Parent=v; _itemH[v]=h
            end
        end
    end
end

-- ── Aimbot ────────────────────────────────────────────────────
local function getBestTarget()
    local vp=cam.ViewportSize; local cx,cy=vp.X/2,vp.Y/2
    local bestFov,bestPart=CFG.AimbotFOV,nil
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==lp then continue end
        if not isEnemy(pl) then continue end
        local char=getChar(pl); if not char then continue end
        local hum=getHum(pl); if not hum or hum.Health<=0 then continue end
        if distTo(pl)>CFG.ESPMaxDist then continue end
        local part=char:FindFirstChild(CFG.AimbotPart) or getRoot(pl); if not part then continue end
        local sp,onScreen=cam:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        -- Wall check: if enabled, skip targets behind walls
        if CFG.AimbotWallCheck then
            local myRoot=getRoot(lp)
            if myRoot and not hasLineOfSight(myRoot,part) then continue end
        end
        local fovD=((sp.X-cx)^2+(sp.Y-cy)^2)^0.5
        if fovD<bestFov then bestFov=fovD; bestPart=part end
    end
    return bestPart
end

-- ── Silent Aim hook ───────────────────────────────────────────
local _silentHooked=false
local function applySilentAim()
    if _silentHooked or not getrawmetatable then return end
    _silentHooked=true
    pcall(function()
        local mt=getrawmetatable(game); local old=mt.__namecall
        mt.__namecall=newcclosure(function(self,...)
            local method=getnamecallmethod()
            if CFG.SilentAim and (method=="FireServer" or method=="InvokeServer") then
                local args={...}; local target=getBestTarget()
                if target then
                    for i,v in ipairs(args) do
                        if typeof(v)=="Vector3" then args[i]=target.Position
                        elseif typeof(v)=="Instance" and v:IsA("BasePart") then args[i]=target end
                    end
                end
                return old(self,table.unpack(args))
            end
            return old(self,...)
        end)
    end)
end

-- ── Triggerbot ────────────────────────────────────────────────
local _lastTrig=0
local function checkTrigger()
    if not CFG.Triggerbot then return end
    local now=tick(); if now-_lastTrig<CFG.TriggerbotDelay then return end
    local vp=cam.ViewportSize
    local ray=cam:ScreenPointToRay(vp.X/2,vp.Y/2)
    local params=RaycastParams.new()
    params.FilterDescendantsInstances={getChar(lp)}; params.FilterType=Enum.RaycastFilterType.Exclude
    local result=workspace:Raycast(ray.Origin,ray.Direction*500,params)
    if result then
        local char=result.Instance:FindFirstAncestorOfClass("Model")
        if char then
            local pl=Players:GetPlayerFromCharacter(char)
            if pl and pl~=lp and isEnemy(pl) then
                _lastTrig=now
                local tool=getChar(lp) and getChar(lp):FindFirstChildOfClass("Tool")
                if tool then
                    for _,re in ipairs(tool:GetDescendants()) do
                        if re:IsA("RemoteEvent") then
                            pcall(function() re:FireServer(result.Instance,result.Position,result.Normal) end)
                            break
                        end
                    end
                end
            end
        end
    end
end

-- ── Fly ───────────────────────────────────────────────────────
local _flyConn
function _startFly()
    _stopFly()
    local char=getChar(lp); local root=getRoot(lp); local hum=getHum(lp)
    if not char or not root or not hum then return end
    hum.PlatformStand=true
    local bv=Instance.new("BodyVelocity")
    bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Velocity=Vector3.zero; bv.Parent=root
    _flyConn=RunService.RenderStepped:Connect(function()
        if not CFG.Fly then _stopFly(); return end
        local dir=Vector3.zero; local cf=cam.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir+=cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir-=cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir-=cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir+=cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir+=Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir-=Vector3.new(0,1,0) end
        bv.Velocity=dir.Magnitude>0 and dir.Unit*CFG.FlySpeed or Vector3.zero
    end)
end
function _stopFly()
    if _flyConn then _flyConn:Disconnect(); _flyConn=nil end
    local root=getRoot(lp); local hum=getHum(lp)
    if root then local bv=root:FindFirstChildOfClass("BodyVelocity"); if bv then bv:Destroy() end end
    if hum then hum.PlatformStand=false end
end

-- ── Noclip ────────────────────────────────────────────────────
RunService.Stepped:Connect(function()
    if not CFG.Noclip then return end
    local char=getChar(lp); if not char then return end
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide=false end
    end
end)

-- ── Infinite Jump ─────────────────────────────────────────────
UserInputService.JumpRequest:Connect(function()
    if CFG.InfJump then
        local hum=getHum(lp)
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ── Stamina finder ────────────────────────────────────────────
local function findStamina()
    for _,v in ipairs(lp:GetDescendants()) do
        if (v:IsA("NumberValue") or v:IsA("IntValue")) and v.Name:lower():find("stam") then return v end
    end
    local char=getChar(lp)
    if char then
        for _,v in ipairs(char:GetDescendants()) do
            if (v:IsA("NumberValue") or v:IsA("IntValue")) and v.Name:lower():find("stam") then return v end
        end
    end
end

-- ── Hitbox expand ─────────────────────────────────────────────
local _origSizes={}

-- ── Main loops ────────────────────────────────────────────────
local _espT,_skelT=0,0

RunService.Heartbeat:Connect(function()
    -- Speed
    local hum=getHum(lp)
    if hum and CFG.SpeedEnabled then
        if hum.WalkSpeed~=CFG.Speed then hum.WalkSpeed=CFG.Speed end
    end
    if hum and CFG.InfJump and hum.JumpPower~=CFG.JumpPower then hum.JumpPower=CFG.JumpPower end
    if CFG.InfStamina then
        local sv=findStamina()
        if sv then sv.Value=math.max(sv.Value,100) end
    end
    checkTrigger()
    -- Hitbox
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==lp then continue end
        local char=getChar(pl); if not char then continue end
        for _,part in ipairs({getHead(pl),getRoot(pl)}) do
            if not part then continue end
            if CFG.HitboxExpand then
                if not _origSizes[part] then _origSizes[part]=part.Size end
                part.Size=Vector3.new(CFG.HitboxSize,CFG.HitboxSize,CFG.HitboxSize)
            elseif _origSizes[part] then
                part.Size=_origSizes[part]; _origSizes[part]=nil
            end
        end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    _espT+=dt; _skelT+=dt

    -- FOV ring
    if hasDrawing and fovRing then
        fovRing.Visible=CFG.AimbotFOVRing and (CFG.Aimbot or CFG.Aimlock)
        if fovRing.Visible then
            local vp=cam.ViewportSize
            fovRing.Position=Vector2.new(vp.X/2,vp.Y/2)
            fovRing.Radius=CFG.AimbotFOV
            fovRing.Color=CFG.Aimlock and Color3.fromRGB(255,80,80) or Color3.fromRGB(180,120,255)
        end
    end

    -- Aimbot
    if (CFG.Aimbot or CFG.Aimlock) and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if CFG.AimbotRequireGun and not isHoldingGun() then
            -- skip
        else
            local target=getBestTarget()
            if target then
                local goalCF=CFrame.new(cam.CFrame.Position,target.Position)
                if CFG.Aimlock then cam.CFrame=goalCF
                else cam.CFrame=cam.CFrame:Lerp(goalCF,CFG.AimbotSmooth) end
            end
        end
    end

    if CFG.SilentAim and not _silentHooked then applySilentAim() end

    if _espT>=0.2 then _espT=0; refreshESP(); updateTags(); refreshItemESP() end
    if _skelT>=0.05 then _skelT=0; drawSkeleton() end
end)

-- ================================================================
--  TOGGLE GUI  (Right Shift)
-- ================================================================
UserInputService.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Enum.KeyCode.RightShift then
        CFG.GuiOpen=not CFG.GuiOpen
        window.Visible=CFG.GuiOpen; overlay.Visible=CFG.GuiOpen
        if CFG.GuiOpen then
            window.Size=UDim2.new(0,WIN_W,0,0)
            tweenProp(window,0.22,{Size=UDim2.new(0,WIN_W,0,WIN_H)})
        end
    end
end)

-- ================================================================
--  INIT
-- ================================================================
for _,pl in ipairs(Players:GetPlayers()) do if pl~=lp then buildESP(pl) end end

showPage("Home")

lp.CharacterAdded:Connect(function()
    task.wait(0.6)
    for _,pl in ipairs(Players:GetPlayers()) do if pl~=lp then buildESP(pl) end end
    if CFG.Fly then _startFly() end
    local hum=getHum(lp)
    if hum then
        if CFG.SpeedEnabled then hum.WalkSpeed=CFG.Speed end
        if CFG.InfJump then hum.JumpPower=CFG.JumpPower end
    end
end)

window.Size=UDim2.new(0,WIN_W,0,0)
tweenProp(window,0.25,{Size=UDim2.new(0,WIN_W,0,WIN_H)})

notify("NyxScript","Valley Prison loaded  ·  Anti-Kick is ON  ·  Right Shift = toggle","success",5)
print("[NyxScript] Valley Prison loaded. Right Shift = toggle GUI.")
