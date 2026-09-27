-- Valley Prison | NyxScript
-- Toggle: Right Shift

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp               = Players.LocalPlayer
local cam              = workspace.CurrentCamera

---------------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------------
local S = {
    Aimbot=false, AimbotFOV=150, AimbotSmooth=0.12, AimbotPart="Head",
    AimbotTeamCheck=false, AimbotRequireGun=false, AimbotWallCheck=false, AimbotFOVRing=false,
    Aimlock=false, SilentAim=false,
    Triggerbot=false, TriggerbotDelay=0.05,
    NoRecoil=false, NoSpread=false,
    HitboxExpand=false, HitboxSize=6,

    PlayerESP=false, WallHack=false, SkeletonESP=false,
    NameESP=false, HealthESP=false, DistanceESP=false,
    ESPMaxDist=500, ItemESP=false, WeaponESP=false,

    SpeedEnabled=false, Speed=24,
    InfStamina=false, InfJump=false, JumpPower=60,
    Fly=false, FlySpeed=30,
    Noclip=false,

    AntiKick=true, AntiDisconnect=false,
    BlockArrest=false, BlockBan=false, LogRemotes=false,

    SavedPositions={},
    Open=true, Page="Home",
}

---------------------------------------------------------------------------
-- UTIL
---------------------------------------------------------------------------
local function chr(p)  return p and p.Character end
local function root(p) local c=chr(p); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum(p)  local c=chr(p); return c and c:FindFirstChildOfClass("Humanoid") end
local function head(p) local c=chr(p); return c and c:FindFirstChild("Head") end
local function dist(p) local a=root(lp); local b=root(p); if not a or not b then return 9e9 end return (a.Position-b.Position).Magnitude end
local function enemy(p)
    if not S.AimbotTeamCheck then return p~=lp end
    return p~=lp and (not p.Team or p.Team~=lp.Team)
end
local function hasGun()
    local c=chr(lp); if not c then return false end
    local t=c:FindFirstChildOfClass("Tool"); if not t then return false end
    local n=t.Name:lower()
    return n:find("gun") or n:find("pistol") or n:find("rifle") or n:find("shot") or n:find("snip") or n:find("taser")
        or t:FindFirstChild("Shoot") or t:FindFirstChild("Fire")
end
local function los(from, to)
    local p=RaycastParams.new()
    p.FilterDescendantsInstances={chr(lp), to.Parent}
    p.FilterType=Enum.RaycastFilterType.Exclude
    return workspace:Raycast(from.Position,(to.Position-from.Position),p)==nil
end
local function tw(i,t,p) TweenService:Create(i,TweenInfo.new(t,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),p):Play() end

---------------------------------------------------------------------------
-- NOTIFICATIONS
---------------------------------------------------------------------------
local nGui=Instance.new("ScreenGui")
nGui.Name="VP_N"; nGui.ResetOnSpawn=false; nGui.IgnoreGuiInset=true; nGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
nGui.Parent=(gethui and gethui()) or lp.PlayerGui

local nHolder=Instance.new("Frame")
nHolder.Size=UDim2.new(0,260,1,0); nHolder.Position=UDim2.new(1,-272,0,0)
nHolder.BackgroundTransparency=1; nHolder.Parent=nGui
local nLayout=Instance.new("UIListLayout")
nLayout.VerticalAlignment=Enum.VerticalAlignment.Bottom
nLayout.Padding=UDim.new(0,5); nLayout.Parent=nHolder
Instance.new("UIPadding",nHolder).PaddingBottom=UDim.new(0,16)

local NCOLORS={ok=Color3.fromRGB(52,211,153),warn=Color3.fromRGB(251,191,36),err=Color3.fromRGB(248,113,113),info=Color3.fromRGB(99,179,237)}

local function notify(msg, kind, dur)
    local col=NCOLORS[kind or "info"]; dur=dur or 3
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,44); f.BackgroundColor3=Color3.fromRGB(18,19,26)
    f.BackgroundTransparency=0; f.BorderSizePixel=0; f.Parent=nHolder
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
    local accent=Instance.new("Frame")
    accent.Size=UDim2.new(0,3,1,0); accent.BackgroundColor3=col; accent.BorderSizePixel=0; accent.Parent=f
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-16,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=msg; lbl.TextColor3=Color3.fromRGB(220,225,235)
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.TextWrapped=true; lbl.Parent=f
    local bar=Instance.new("Frame")
    bar.Size=UDim2.new(1,0,0,2); bar.Position=UDim2.new(0,0,1,-2)
    bar.BackgroundColor3=col; bar.BorderSizePixel=0; bar.Parent=f
    f.Position=UDim2.new(1,8,0,0); tw(f,0.2,{Position=UDim2.new(0,0,0,0)})
    tw(bar,dur,{Size=UDim2.new(0,0,0,2)})
    task.delay(dur,function() tw(f,0.15,{Position=UDim2.new(1,8,0,0)}); task.wait(0.16); f:Destroy() end)
end

---------------------------------------------------------------------------
-- MAIN GUI
---------------------------------------------------------------------------
local gui=Instance.new("ScreenGui")
gui.Name="VP_Main"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=(gethui and gethui()) or lp.PlayerGui

local W,H=700,460

local win=Instance.new("Frame")
win.Size=UDim2.new(0,W,0,H); win.Position=UDim2.new(0.5,-W/2,0.5,-H/2)
win.BackgroundColor3=Color3.fromRGB(11,12,18); win.BorderSizePixel=0; win.ZIndex=2; win.Parent=gui
Instance.new("UICorner",win).CornerRadius=UDim.new(0,10)
local winStroke=Instance.new("UIStroke")
winStroke.Color=Color3.fromRGB(255,255,255); winStroke.Transparency=0.93; winStroke.Thickness=1; winStroke.Parent=win

-- title bar
local bar=Instance.new("Frame")
bar.Size=UDim2.new(1,0,0,38); bar.BackgroundColor3=Color3.fromRGB(15,16,24)
bar.BorderSizePixel=0; bar.ZIndex=3; bar.Parent=win
Instance.new("UICorner",bar).CornerRadius=UDim.new(0,10)
-- cover bottom corners of bar
local barFill=Instance.new("Frame")
barFill.Size=UDim2.new(1,0,0,10); barFill.Position=UDim2.new(0,0,1,-10)
barFill.BackgroundColor3=Color3.fromRGB(15,16,24); barFill.BorderSizePixel=0; barFill.ZIndex=3; barFill.Parent=bar

-- accent strip on title bar
local strip=Instance.new("Frame")
strip.Size=UDim2.new(0,3,0,20); strip.Position=UDim2.new(0,12,0.5,-10)
strip.BackgroundColor3=Color3.fromRGB(0,201,185); strip.BorderSizePixel=0; strip.ZIndex=4; strip.Parent=bar
Instance.new("UICorner",strip).CornerRadius=UDim.new(1,0)

local titleLbl=Instance.new("TextLabel")
titleLbl.Size=UDim2.new(0,200,1,0); titleLbl.Position=UDim2.new(0,24,0,0)
titleLbl.BackgroundTransparency=1; titleLbl.Text="VALLEY PRISON"
titleLbl.TextColor3=Color3.fromRGB(230,235,245); titleLbl.Font=Enum.Font.GothamBold
titleLbl.TextSize=13; titleLbl.TextXAlignment=Enum.TextXAlignment.Left; titleLbl.ZIndex=4; titleLbl.Parent=bar

local subLbl=Instance.new("TextLabel")
subLbl.Size=UDim2.new(0,120,1,0); subLbl.Position=UDim2.new(0,175,0,0)
subLbl.BackgroundTransparency=1; subLbl.Text="NyxScript"
subLbl.TextColor3=Color3.fromRGB(0,201,185); subLbl.Font=Enum.Font.Gotham
subLbl.TextSize=12; subLbl.TextXAlignment=Enum.TextXAlignment.Left; subLbl.ZIndex=4; subLbl.Parent=bar

-- window buttons
local function mkWinBtn(xOff, col, txt)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,20,0,20); b.Position=UDim2.new(1,xOff,0.5,-10)
    b.BackgroundColor3=col; b.Text=txt; b.TextColor3=Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold; b.TextSize=10; b.BorderSizePixel=0; b.ZIndex=5; b.Parent=bar
    Instance.new("UICorner",b).CornerRadius=UDim.new(1,0)
    b.MouseEnter:Connect(function() tw(b,0.06,{BackgroundTransparency=0.3}) end)
    b.MouseLeave:Connect(function() tw(b,0.06,{BackgroundTransparency=0}) end)
    return b
end

local btnClose=mkWinBtn(-32, Color3.fromRGB(232,65,65), "×")
local btnMin=mkWinBtn(-58, Color3.fromRGB(52,211,153), "–")

local minimized=false
btnMin.MouseButton1Click:Connect(function()
    minimized=not minimized
    tw(win,0.18,{Size=minimized and UDim2.new(0,W,0,38) or UDim2.new(0,W,0,H)})
end)
btnClose.MouseButton1Click:Connect(function()
    S.Open=false
    tw(win,0.15,{Size=UDim2.new(0,W,0,0)})
    task.wait(0.16); win.Visible=false
    win.Size=UDim2.new(0,W,0,H) -- reset size for when it reopens
end)

-- drag
local _drag,_ds,_dw
bar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then _drag=true; _ds=i.Position; _dw=win.Position end
end)
UserInputService.InputChanged:Connect(function(i)
    if _drag and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-_ds
        win.Position=UDim2.new(_dw.X.Scale,_dw.X.Offset+d.X,_dw.Y.Scale,_dw.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then _drag=false end
end)

---------------------------------------------------------------------------
-- SIDEBAR
---------------------------------------------------------------------------
local SB_W=140
local sb=Instance.new("Frame")
sb.Size=UDim2.new(0,SB_W,1,-38); sb.Position=UDim2.new(0,0,0,38)
sb.BackgroundColor3=Color3.fromRGB(9,10,16); sb.BorderSizePixel=0; sb.ZIndex=3; sb.Parent=win
local sbSep=Instance.new("Frame")
sbSep.Size=UDim2.new(0,1,1,-38); sbSep.Position=UDim2.new(0,SB_W,0,38)
sbSep.BackgroundColor3=Color3.fromRGB(255,255,255); sbSep.BackgroundTransparency=0.93
sbSep.BorderSizePixel=0; sbSep.ZIndex=3; sbSep.Parent=win

local sbList=Instance.new("UIListLayout"); sbList.SortOrder=Enum.SortOrder.LayoutOrder
sbList.Padding=UDim.new(0,2); sbList.Parent=sb
local sbPad=Instance.new("UIPadding"); sbPad.PaddingTop=UDim.new(0,8)
sbPad.PaddingLeft=UDim.new(0,6); sbPad.PaddingRight=UDim.new(0,6); sbPad.Parent=sb

---------------------------------------------------------------------------
-- CONTENT
---------------------------------------------------------------------------
local content=Instance.new("ScrollingFrame")
content.Size=UDim2.new(1,-SB_W-1,1,-38); content.Position=UDim2.new(0,SB_W+1,0,38)
content.BackgroundTransparency=1; content.ScrollBarThickness=3
content.ScrollBarImageColor3=Color3.fromRGB(0,201,185)
content.CanvasSize=UDim2.new(0,0,0,0); content.AutomaticCanvasSize=Enum.AutomaticSize.Y
content.BorderSizePixel=0; content.ZIndex=3; content.Parent=win
local cPad=Instance.new("UIPadding")
cPad.PaddingLeft=UDim.new(0,12); cPad.PaddingRight=UDim.new(0,12)
cPad.PaddingTop=UDim.new(0,10); cPad.PaddingBottom=UDim.new(0,12); cPad.Parent=content
local cList=Instance.new("UIListLayout"); cList.SortOrder=Enum.SortOrder.LayoutOrder
cList.Padding=UDim.new(0,6); cList.Parent=content

---------------------------------------------------------------------------
-- PAGE / NAV SYSTEM
---------------------------------------------------------------------------
local PAGES={}; local NAVBTNS={}

local function setPage(name)
    S.Page=name
    for n,f in pairs(PAGES) do f.Visible=(n==name) end
    for n,b in pairs(NAVBTNS) do
        local on=(n==name)
        tw(b,0.1,{BackgroundColor3=on and Color3.fromRGB(20,22,32) or Color3.fromRGB(0,0,0),
            BackgroundTransparency=on and 0 or 1})
        local ind=b:FindFirstChild("_ind")
        if ind then tw(ind,0.1,{BackgroundTransparency=on and 0 or 1}) end
        local lbl=b:FindFirstChildOfClass("TextLabel")
        if lbl then lbl.TextColor3=on and Color3.fromRGB(230,235,245) or Color3.fromRGB(90,95,115) end
    end
end

local ICONS={Home="⊞",Combat="⊕",ESP="◈",Movement="⊿",Teleportation="⊙",Spawning="⊛",["Prison"]="⊠",["Anti-Kick"]="⊡"}
local PNAMES={"Home","Combat","ESP","Movement","Teleportation","Spawning","Prison","Anti-Kick"}

for i,name in ipairs(PNAMES) do
    -- nav button
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,0,30); btn.BackgroundColor3=Color3.fromRGB(0,0,0)
    btn.BackgroundTransparency=1; btn.Text=""; btn.BorderSizePixel=0
    btn.LayoutOrder=i; btn.ZIndex=4; btn.Parent=sb
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)

    -- left indicator
    local ind=Instance.new("Frame"); ind.Name="_ind"
    ind.Size=UDim2.new(0,2,0,16); ind.Position=UDim2.new(0,-2,0.5,-8)
    ind.BackgroundColor3=Color3.fromRGB(0,201,185); ind.BackgroundTransparency=1
    ind.BorderSizePixel=0; ind.ZIndex=5; ind.Parent=btn
    Instance.new("UICorner",ind).CornerRadius=UDim.new(1,0)

    local icon=Instance.new("TextLabel")
    icon.Size=UDim2.new(0,20,1,0); icon.Position=UDim2.new(0,8,0,0)
    icon.BackgroundTransparency=1; icon.Text=ICONS[name] or "·"
    icon.TextColor3=Color3.fromRGB(90,95,115); icon.Font=Enum.Font.GothamBold
    icon.TextSize=14; icon.ZIndex=5; icon.Parent=btn

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-32,1,0); lbl.Position=UDim2.new(0,30,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=name; lbl.TextColor3=Color3.fromRGB(90,95,115)
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.ZIndex=5; lbl.Parent=btn

    btn.MouseEnter:Connect(function()
        if S.Page~=name then tw(btn,0.08,{BackgroundTransparency=0.7,BackgroundColor3=Color3.fromRGB(18,20,30)}) end
    end)
    btn.MouseLeave:Connect(function()
        if S.Page~=name then tw(btn,0.08,{BackgroundTransparency=1}) end
    end)
    btn.MouseButton1Click:Connect(function() setPage(name) end)
    NAVBTNS[name]=btn

    -- page frame
    local pg=Instance.new("Frame"); pg.Name=name
    pg.Size=UDim2.new(1,0,0,0); pg.AutomaticSize=Enum.AutomaticSize.Y
    pg.BackgroundTransparency=1; pg.LayoutOrder=i; pg.Visible=false; pg.Parent=content
    local pl=Instance.new("UIListLayout"); pl.SortOrder=Enum.SortOrder.LayoutOrder
    pl.Padding=UDim.new(0,6); pl.Parent=pg
    PAGES[name]=pg
end

---------------------------------------------------------------------------
-- COMPONENT HELPERS
---------------------------------------------------------------------------
local function secLabel(pg, txt)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,22); f.BackgroundTransparency=1
    f.BorderSizePixel=0; f.Parent=pg
    local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,0,1,0)
    l.BackgroundTransparency=1; l.Text=txt:upper()
    l.TextColor3=Color3.fromRGB(0,201,185); l.Font=Enum.Font.GothamBold
    l.TextSize=10; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=f
end

local function mkCard(pg)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,0); f.AutomaticSize=Enum.AutomaticSize.Y
    f.BackgroundColor3=Color3.fromRGB(16,17,26); f.BackgroundTransparency=0; f.BorderSizePixel=0; f.Parent=pg
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,7)
    local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(255,255,255); s.Transparency=0.94; s.Thickness=1; s.Parent=f
    local l=Instance.new("UIListLayout"); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,0); l.Parent=f
    local p=Instance.new("UIPadding")
    p.PaddingLeft=UDim.new(0,10); p.PaddingRight=UDim.new(0,10)
    p.PaddingTop=UDim.new(0,6); p.PaddingBottom=UDim.new(0,6); p.Parent=f
    return f
end

local function mkToggle(pg, label, key, cb)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,34); row.BackgroundTransparency=1
    row.BorderSizePixel=0; row.Parent=pg
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-52,1,0)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=Color3.fromRGB(190,195,210)
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row

    local pill=Instance.new("TextButton")
    pill.Size=UDim2.new(0,42,0,22); pill.Position=UDim2.new(1,-42,0.5,-11)
    pill.Text=""; pill.BorderSizePixel=0; pill.Parent=row
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)

    local knob=Instance.new("Frame"); knob.Size=UDim2.new(0,16,0,16)
    knob.AnchorPoint=Vector2.new(0,0.5); knob.Position=UDim2.new(0,3,0.5,0)
    knob.BackgroundColor3=Color3.new(1,1,1); knob.BorderSizePixel=0; knob.Parent=pill
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local function set(v)
        S[key]=v
        tw(pill,0.12,{BackgroundColor3=v and Color3.fromRGB(0,175,160) or Color3.fromRGB(35,37,52)})
        tw(knob,0.12,{Position=v and UDim2.new(1,-19,0.5,0) or UDim2.new(0,3,0.5,0)})
        if cb then cb(v) end
    end
    set(S[key] or false)
    pill.MouseButton1Click:Connect(function() set(not S[key]) end)
    return set
end

local function mkSlider(pg, label, key, mn, mx, step, cb)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,46); row.BackgroundTransparency=1
    row.BorderSizePixel=0; row.Parent=pg
    local top=Instance.new("Frame"); top.Size=UDim2.new(1,0,0,20); top.BackgroundTransparency=1; top.Parent=row
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-50,1,0)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=Color3.fromRGB(170,175,195)
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=top
    local val=Instance.new("TextLabel"); val.Size=UDim2.new(0,46,1,0); val.Position=UDim2.new(1,-46,0,0)
    val.BackgroundTransparency=1; val.Text=tostring(S[key]); val.TextColor3=Color3.fromRGB(0,201,185)
    val.Font=Enum.Font.GothamBold; val.TextSize=12; val.TextXAlignment=Enum.TextXAlignment.Right; val.Parent=top

    local track=Instance.new("Frame"); track.Size=UDim2.new(1,0,0,5); track.Position=UDim2.new(0,0,0,30)
    track.BackgroundColor3=Color3.fromRGB(28,30,44); track.BorderSizePixel=0; track.Parent=row
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)

    local r=(S[key]-mn)/math.max(mx-mn,1e-4)
    local fill=Instance.new("Frame"); fill.Size=UDim2.new(r,0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(0,175,160); fill.BorderSizePixel=0; fill.Parent=track
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)

    local thumb=Instance.new("Frame"); thumb.Size=UDim2.new(0,13,0,13)
    thumb.AnchorPoint=Vector2.new(0.5,0.5); thumb.Position=UDim2.new(r,0,0.5,0)
    thumb.BackgroundColor3=Color3.new(1,1,1); thumb.BorderSizePixel=0; thumb.Parent=track
    Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)

    local drag=false
    local function upd(x)
        local t=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v=math.round((mn+(mx-mn)*t)/step)*step
        S[key]=v; fill.Size=UDim2.new(t,0,1,0); thumb.Position=UDim2.new(t,0,0.5,0)
        val.Text=tostring(v); if cb then cb(v) end
    end
    track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; upd(i.Position.X) end end)
    UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
end

local function mkBtn(pg, label, fn)
    local btn=Instance.new("TextButton"); btn.Size=UDim2.new(1,0,0,30)
    btn.BackgroundColor3=Color3.fromRGB(20,22,33); btn.BackgroundTransparency=0
    btn.Text=label; btn.TextColor3=Color3.fromRGB(170,175,200)
    btn.Font=Enum.Font.Gotham; btn.TextSize=12; btn.BorderSizePixel=0; btn.Parent=pg
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
    local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(255,255,255); s.Transparency=0.92; s.Thickness=1; s.Parent=btn
    btn.MouseEnter:Connect(function() tw(btn,0.08,{BackgroundColor3=Color3.fromRGB(28,30,46)}) end)
    btn.MouseLeave:Connect(function() tw(btn,0.08,{BackgroundColor3=Color3.fromRGB(20,22,33)}) end)
    btn.MouseButton1Down:Connect(function() tw(btn,0.05,{BackgroundColor3=Color3.fromRGB(0,140,128)}) end)
    btn.MouseButton1Up:Connect(function() tw(btn,0.05,{BackgroundColor3=Color3.fromRGB(20,22,33)}) end)
    btn.MouseButton1Click:Connect(fn)
    return btn
end

local function mkDrop(pg, label, options, key)
    local c=Instance.new("Frame"); c.Size=UDim2.new(1,0,0,34); c.BackgroundTransparency=1
    c.ClipsDescendants=false; c.BorderSizePixel=0; c.Parent=pg
    local l=Instance.new("TextLabel"); l.Size=UDim2.new(0.5,0,1,0)
    l.BackgroundTransparency=1; l.Text=label; l.TextColor3=Color3.fromRGB(170,175,195)
    l.Font=Enum.Font.Gotham; l.TextSize=12; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=c
    local btn=Instance.new("TextButton"); btn.Size=UDim2.new(0.48,0,0,26); btn.Position=UDim2.new(0.52,0,0.5,-13)
    btn.BackgroundColor3=Color3.fromRGB(20,22,33); btn.BorderSizePixel=0
    btn.Text="▾  "..tostring(S[key]); btn.TextColor3=Color3.fromRGB(0,201,185)
    btn.Font=Enum.Font.Gotham; btn.TextSize=11; btn.Parent=c
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
    local df=Instance.new("Frame"); df.Size=UDim2.new(0.48,0,0,0); df.Position=UDim2.new(0.52,0,1,3)
    df.BackgroundColor3=Color3.fromRGB(18,20,30); df.BorderSizePixel=0; df.ClipsDescendants=true
    df.ZIndex=10; df.Visible=false; df.Parent=c
    Instance.new("UICorner",df).CornerRadius=UDim.new(0,5)
    local dl=Instance.new("UIListLayout"); dl.Parent=df
    for _,opt in ipairs(options) do
        local ob=Instance.new("TextButton"); ob.Size=UDim2.new(1,0,0,24); ob.BackgroundTransparency=1
        ob.Text=opt; ob.TextColor3=Color3.fromRGB(170,175,200); ob.Font=Enum.Font.Gotham; ob.TextSize=11; ob.ZIndex=11; ob.Parent=df
        ob.MouseButton1Click:Connect(function()
            S[key]=opt; btn.Text="▾  "..opt
            tw(df,0.08,{Size=UDim2.new(0.48,0,0,0)}); task.wait(0.09); df.Visible=false
        end)
        ob.MouseEnter:Connect(function() tw(ob,0.07,{BackgroundTransparency=0.8,BackgroundColor3=Color3.fromRGB(0,140,128)}) end)
        ob.MouseLeave:Connect(function() tw(ob,0.07,{BackgroundTransparency=1}) end)
    end
    btn.MouseButton1Click:Connect(function()
        if df.Visible then tw(df,0.08,{Size=UDim2.new(0.48,0,0,0)}); task.wait(0.09); df.Visible=false
        else df.Visible=true; tw(df,0.1,{Size=UDim2.new(0.48,0,0,#options*24)}) end
    end)
end

---------------------------------------------------------------------------
-- HOME
---------------------------------------------------------------------------
do
    local pg=PAGES["Home"]
    local c=mkCard(pg)
    local welcome=Instance.new("TextLabel"); welcome.Size=UDim2.new(1,0,0,24)
    welcome.BackgroundTransparency=1; welcome.Text=lp.Name
    welcome.TextColor3=Color3.fromRGB(230,235,245); welcome.Font=Enum.Font.GothamBold
    welcome.TextSize=16; welcome.TextXAlignment=Enum.TextXAlignment.Left; welcome.Parent=c
    local sub=Instance.new("TextLabel"); sub.Size=UDim2.new(1,0,0,18)
    sub.BackgroundTransparency=1; sub.Text="Valley Prison  ·  Right Shift toggles menu"
    sub.TextColor3=Color3.fromRGB(70,75,100); sub.Font=Enum.Font.Gotham; sub.TextSize=11
    sub.TextXAlignment=Enum.TextXAlignment.Left; sub.Parent=c

    secLabel(pg,"Quick Access")
    local qc=mkCard(pg)
    mkToggle(qc,"Player ESP","PlayerESP")
    mkToggle(qc,"Aimbot","Aimbot")
    mkToggle(qc,"Fly","Fly",function(v) if v then _startFly() else _stopFly() end end)
    mkToggle(qc,"Speed Hack","SpeedEnabled",function(v) local h=hum(lp); if h then h.WalkSpeed=v and S.Speed or 16 end end)
    mkToggle(qc,"Infinite Stamina","InfStamina")
    mkToggle(qc,"Anti-Kick","AntiKick")
end

---------------------------------------------------------------------------
-- COMBAT
---------------------------------------------------------------------------
do
    local pg=PAGES["Combat"]
    secLabel(pg,"Aimbot")
    local c=mkCard(pg)
    mkToggle(c,"Aimbot","Aimbot")
    mkToggle(c,"Aimlock","Aimlock")
    mkToggle(c,"FOV Ring","AimbotFOVRing")
    mkToggle(c,"Require Gun","AimbotRequireGun")
    mkToggle(c,"Wall Check (block walls)","AimbotWallCheck")
    mkToggle(c,"Team Check","AimbotTeamCheck")
    mkSlider(c,"FOV Radius","AimbotFOV",30,400,10)
    mkSlider(c,"Smooth","AimbotSmooth",0.02,1,0.01)
    mkDrop(c,"Aim Part",{"Head","HumanoidRootPart","UpperTorso"},"AimbotPart")
    secLabel(pg,"Other")
    local c2=mkCard(pg)
    mkToggle(c2,"Silent Aim","SilentAim")
    mkToggle(c2,"Triggerbot","Triggerbot")
    mkSlider(c2,"Trigger Delay","TriggerbotDelay",0.01,0.5,0.01)
    secLabel(pg,"Weapon")
    local c3=mkCard(pg)
    mkToggle(c3,"No Recoil","NoRecoil")
    mkToggle(c3,"Hitbox Expand","HitboxExpand")
    mkSlider(c3,"Hitbox Size","HitboxSize",1,20,0.5)
end

---------------------------------------------------------------------------
-- ESP
---------------------------------------------------------------------------
do
    local pg=PAGES["ESP"]
    secLabel(pg,"Players")
    local c=mkCard(pg)
    mkToggle(c,"Highlight","PlayerESP")
    mkToggle(c,"Wallhack","WallHack")
    mkToggle(c,"Skeleton","SkeletonESP")
    mkToggle(c,"Names","NameESP")
    mkToggle(c,"Health","HealthESP")
    mkToggle(c,"Distance","DistanceESP")
    mkSlider(c,"Max Distance","ESPMaxDist",250,1000,25)
    secLabel(pg,"World")
    local c2=mkCard(pg)
    mkToggle(c2,"Items","ItemESP")
    mkToggle(c2,"Weapons","WeaponESP")
end

---------------------------------------------------------------------------
-- MOVEMENT
---------------------------------------------------------------------------
do
    local pg=PAGES["Movement"]
    secLabel(pg,"Speed")
    local c=mkCard(pg)
    mkToggle(c,"Speed Hack","SpeedEnabled",function(v) local h=hum(lp); if h then h.WalkSpeed=v and S.Speed or 16 end end)
    mkSlider(c,"Walk Speed","Speed",16,64,1,function(v) if S.SpeedEnabled then local h=hum(lp); if h then h.WalkSpeed=v end end end)
    secLabel(pg,"Jump")
    local c2=mkCard(pg)
    mkToggle(c2,"Infinite Jump","InfJump")
    mkSlider(c2,"Jump Power","JumpPower",50,500,10,function(v) local h=hum(lp); if h then h.JumpPower=v end end)
    secLabel(pg,"Flight")
    local c3=mkCard(pg)
    mkToggle(c3,"Fly  (WASD + Space / Ctrl)","Fly",function(v) if v then _startFly() else _stopFly() end end)
    mkSlider(c3,"Fly Speed","FlySpeed",5,64,1)
    secLabel(pg,"Other")
    local c4=mkCard(pg)
    mkToggle(c4,"Noclip","Noclip")
    mkToggle(c4,"Infinite Stamina","InfStamina")
end

---------------------------------------------------------------------------
-- TELEPORTATION
---------------------------------------------------------------------------
do
    local pg=PAGES["Teleportation"]
    secLabel(pg,"Locations")
    local c=mkCard(pg)
    local function tpTo(fn, name)
        local r=root(lp); if not r then return end
        local t=fn(); if t and t:IsA("BasePart") then
            r.CFrame=t.CFrame+Vector3.new(0,4,0); notify("→ "..name,"ok")
        else notify(name.." not found","warn") end
    end
    mkBtn(c,"Exit / Gate",      function() tpTo(function() for _,v in ipairs(workspace:GetDescendants()) do if v:IsA("BasePart") and (v.Name:lower():find("exit") or v.Name:lower():find("gate")) then return v end end end,"Exit") end)
    mkBtn(c,"Guard Room",       function() tpTo(function() for _,v in ipairs(workspace:GetDescendants()) do if v:IsA("BasePart") and v.Name:lower():find("guard") then return v end end end,"Guard Room") end)
    mkBtn(c,"Armory",           function() tpTo(function() for _,v in ipairs(workspace:GetDescendants()) do if v:IsA("BasePart") and (v.Name:lower():find("armory") or v.Name:lower():find("weapon")) then return v end end end,"Armory") end)
    mkBtn(c,"Cafeteria",        function() tpTo(function() for _,v in ipairs(workspace:GetDescendants()) do if v:IsA("BasePart") and (v.Name:lower():find("cafe") or v.Name:lower():find("food")) then return v end end end,"Cafeteria") end)
    mkBtn(c,"Visitor Lobby",    function() tpTo(function() for _,v in ipairs(workspace:GetDescendants()) do if v:IsA("BasePart") and v.Name:lower():find("visit") then return v end end end,"Visitor Lobby") end)

    secLabel(pg,"Players")
    local pc=mkCard(pg)
    local plFrame=Instance.new("Frame"); plFrame.Size=UDim2.new(1,0,0,0)
    plFrame.AutomaticSize=Enum.AutomaticSize.Y; plFrame.BackgroundTransparency=1; plFrame.Parent=pc
    local pll=Instance.new("UIListLayout"); pll.Padding=UDim.new(0,3); pll.Parent=plFrame
    local function rebuildPL()
        for _,c2 in ipairs(plFrame:GetChildren()) do if not c2:IsA("UIListLayout") then c2:Destroy() end end
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl~=lp then
                mkBtn(plFrame,"→ "..pl.Name,function()
                    local r1=root(lp); local r2=root(pl)
                    if r1 and r2 then r1.CFrame=r2.CFrame+Vector3.new(2,0,2); notify("→ "..pl.Name,"ok") end
                end)
            end
        end
    end
    rebuildPL(); Players.PlayerAdded:Connect(rebuildPL); Players.PlayerRemoving:Connect(rebuildPL)
    mkBtn(pc,"Refresh",rebuildPL)

    secLabel(pg,"Saved")
    local sc=mkCard(pg)
    local spFrame=Instance.new("Frame"); spFrame.Size=UDim2.new(1,0,0,0)
    spFrame.AutomaticSize=Enum.AutomaticSize.Y; spFrame.BackgroundTransparency=1; spFrame.Parent=sc
    local spl=Instance.new("UIListLayout"); spl.Padding=UDim.new(0,3); spl.Parent=spFrame
    local function rebuildSP()
        for _,c2 in ipairs(spFrame:GetChildren()) do if not c2:IsA("UIListLayout") then c2:Destroy() end end
        for i,sp in ipairs(S.SavedPositions) do
            local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,30); row.BackgroundTransparency=1; row.Parent=spFrame
            local rl=Instance.new("UIListLayout"); rl.FillDirection=Enum.FillDirection.Horizontal; rl.Padding=UDim.new(0,4); rl.Parent=row
            local nl=Instance.new("TextLabel"); nl.Size=UDim2.new(0.55,0,1,0); nl.BackgroundTransparency=1
            nl.Text=sp.name; nl.TextColor3=Color3.fromRGB(170,175,200); nl.Font=Enum.Font.Gotham; nl.TextSize=12
            nl.TextXAlignment=Enum.TextXAlignment.Left; nl.Parent=row
            local gb=Instance.new("TextButton"); gb.Size=UDim2.new(0.22,-4,0,26); gb.BackgroundColor3=Color3.fromRGB(0,140,128)
            gb.Text="Go"; gb.TextColor3=Color3.new(1,1,1); gb.Font=Enum.Font.GothamBold; gb.TextSize=11; gb.BorderSizePixel=0; gb.Parent=row
            Instance.new("UICorner",gb).CornerRadius=UDim.new(0,5)
            gb.MouseButton1Click:Connect(function() local r=root(lp); if r then r.CFrame=sp.cf end end)
            local db=Instance.new("TextButton"); db.Size=UDim2.new(0.22,-4,0,26); db.BackgroundColor3=Color3.fromRGB(55,20,20)
            db.Text="Del"; db.TextColor3=Color3.fromRGB(248,113,113); db.Font=Enum.Font.GothamBold; db.TextSize=11; db.BorderSizePixel=0; db.Parent=row
            Instance.new("UICorner",db).CornerRadius=UDim.new(0,5)
            db.MouseButton1Click:Connect(function() table.remove(S.SavedPositions,i); rebuildSP() end)
        end
    end
    rebuildSP()
    mkBtn(sc,"Save Position",function()
        local r=root(lp); if r then
            local n="Pos "..(#S.SavedPositions+1)
            table.insert(S.SavedPositions,{name=n,cf=r.CFrame}); rebuildSP(); notify("Saved: "..n,"ok")
        end
    end)
end

---------------------------------------------------------------------------
-- SPAWNING
---------------------------------------------------------------------------
do
    local pg=PAGES["Spawning"]
    local function spawnTool(name)
        for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("Tool") and v.Name==name then v:Clone().Parent=lp.Backpack; notify(name.." → backpack","ok"); return end
        end
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Tool") and v.Name==name then v:Clone().Parent=lp.Backpack; notify(name.." cloned","info"); return end
        end
        notify(name.." not in world yet","warn")
    end
    local function mkList(pg2, items)
        local sf=Instance.new("ScrollingFrame"); sf.Size=UDim2.new(1,0,0,160)
        sf.CanvasSize=UDim2.new(0,0,0,0); sf.AutomaticCanvasSize=Enum.AutomaticSize.Y
        sf.ScrollBarThickness=3; sf.ScrollBarImageColor3=Color3.fromRGB(0,201,185)
        sf.BackgroundTransparency=1; sf.BorderSizePixel=0; sf.Parent=pg2
        local l=Instance.new("UIListLayout"); l.Padding=UDim.new(0,2); l.Parent=sf
        for _,name in ipairs(items) do
            local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,26); row.BackgroundColor3=Color3.fromRGB(18,19,28)
            row.BackgroundTransparency=0; row.BorderSizePixel=0; row.Parent=sf
            Instance.new("UICorner",row).CornerRadius=UDim.new(0,5)
            local nl=Instance.new("TextLabel"); nl.Size=UDim2.new(1,-44,1,0); nl.Position=UDim2.new(0,8,0,0)
            nl.BackgroundTransparency=1; nl.Text=name; nl.TextColor3=Color3.fromRGB(180,185,210)
            nl.Font=Enum.Font.Gotham; nl.TextSize=11; nl.TextXAlignment=Enum.TextXAlignment.Left; nl.Parent=row
            local gb=Instance.new("TextButton"); gb.Size=UDim2.new(0,36,0,20); gb.Position=UDim2.new(1,-38,0.5,-10)
            gb.BackgroundColor3=Color3.fromRGB(0,140,128); gb.Text="Get"; gb.TextColor3=Color3.new(1,1,1)
            gb.Font=Enum.Font.GothamBold; gb.TextSize=10; gb.BorderSizePixel=0; gb.Parent=row
            Instance.new("UICorner",gb).CornerRadius=UDim.new(0,4)
            gb.MouseButton1Click:Connect(function() spawnTool(name) end)
        end
    end

    secLabel(pg,"Keycards")
    local kc=mkCard(pg)
    mkList(kc,{"Corrections Keycard","Supervisors Keycard","Directors Keycard","Employee Keycard","Master Keycard","Developer Keycard"})

    secLabel(pg,"Materials")
    local mc=mkCard(pg)
    mkList(mc,{"Metal","Plastic","Rope","Shiv"})

    secLabel(pg,"Shotguns")
    local sc=mkCard(pg)
    mkList(sc,{"KSG-12","M1014","Model 590","Saiga 12K","Terminator","Toz 106","John's KSG","PKSG-12","GEN-12"})

    secLabel(pg,"SMGs")
    local smgc=mkCard(pg)
    mkList(smgc,{"M1928","M1A1","M3 Grease Gun","MP40","MP5","MP5 Mod","MP7","MP7 Mod","Scorpion E3","SE3 Express","UMP45","UMP45-X","P90","PUMP45"})

    secLabel(pg,"Assault Rifles")
    local arc=mkCard(pg)
    mkList(arc,{"AMD-65","AK-12","AK-47","AK-74","AR-57","ARP","M4A1","HK416","HK416 Patrol","HK416D","G36","G36C","AA .50 Beowulf","M16A4","M16A1","SCAR-L","LEO MCX Spear","MCX Spear","The Harrow","IMI Galil","L1A1 SLR","SA58 OSW-E","SA58 OSW-L","SA58 OSW","SKS","VSS Vintorez","Patriot","AR2","C8IUR","Cat Gun","M4A1 DMR","SG 550","Honey Badger"})

    secLabel(pg,"Pistols")
    local pic=mkCard(pg)
    mkList(pic,{"92FS","Makarov","1911 Emperor","SW500","93R","G18","G18C","G17","Arrow Fed G17","Giant17","Godgun","Paterson 1836","PM82A1"})

    secLabel(pg,"Heavy")
    local hvc=mkCard(pg)
    mkList(hvc,{"M82A1","Ultimax 100","M249 SAW","Tempest","MGL MK1S"})

    secLabel(pg,"Actions")
    local ac=mkCard(pg)
    mkBtn(ac,"Collect All Dropped Items",function()
        local n=0; for _,v in ipairs(workspace:GetDescendants()) do if v:IsA("Tool") then v.Parent=lp.Backpack; n+=1 end end
        notify(n.." items collected","ok")
    end)
    mkBtn(ac,"Drop All Items",function()
        local r=root(lp)
        for _,v in ipairs(lp.Backpack:GetChildren()) do
            if v:IsA("Tool") then v.Parent=workspace
                if v:FindFirstChild("Handle") and r then v.Handle.CFrame=r.CFrame+Vector3.new(math.random(-3,3),1,math.random(-3,3)) end
            end
        end; notify("Backpack cleared","info")
    end)
end

---------------------------------------------------------------------------
-- PRISON
---------------------------------------------------------------------------
do
    local pg=PAGES["Prison"]
    secLabel(pg,"Bypasses")
    local c=mkCard(pg)
    mkBtn(c,"Unlock Doors",function()
        for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name:lower():find("door") then pcall(function() v:FireServer() end) end
        end; notify("Door remotes fired","info")
    end)
    mkBtn(c,"Remove Handcuffs",function()
        local ch=chr(lp); if ch then
            for _,v in ipairs(ch:GetDescendants()) do if v:IsA("WeldConstraint") and v.Name:lower():find("cuff") then v:Destroy() end end
        end
        for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name:lower():find("escape") then pcall(function() v:FireServer() end) end
        end; notify("Handcuff removal attempted","ok")
    end)
    secLabel(pg,"Team")
    local tc=mkCard(pg)
    for _,t in ipairs({"Prisoner","Guard","Warden","Visitor","Criminal","Police"}) do
        mkBtn(tc,"→ "..t,function()
            for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") and (v.Name:lower():find("team") or v.Name:lower():find("role")) then pcall(function() v:FireServer(t) end) end
            end
            for _,team in ipairs(game:GetService("Teams"):GetTeams()) do
                if team.Name:lower():find(t:lower()) then pcall(function() lp.Team=team end) end
            end; notify("Team → "..t,"info")
        end)
    end
    secLabel(pg,"Remote Monitor")
    local rc=mkCard(pg)
    mkToggle(rc,"Log Remotes","LogRemotes")
    mkToggle(rc,"Block Arrest","BlockArrest")
    mkToggle(rc,"Block Ban","BlockBan")
    mkBtn(rc,"List All Remotes",function()
        local n=0; for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then print("[VP] "..v:GetFullName()); n+=1 end
        end; notify(n.." remotes (see output)","info")
    end)
end

---------------------------------------------------------------------------
-- ANTI-KICK
---------------------------------------------------------------------------
do
    local pg=PAGES["Anti-Kick"]
    secLabel(pg,"Protection")
    local c=mkCard(pg)
    mkToggle(c,"Anti-Kick  (on by default)","AntiKick")
    mkToggle(c,"Anti-Disconnect","AntiDisconnect")
    secLabel(pg,"Remote Block")
    local c2=mkCard(pg)
    mkToggle(c2,"Block Ban Remotes","BlockBan")
    mkBtn(c2,"Scan for Kick Remotes",function()
        local found={}
        for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
            local n=v.Name:lower()
            if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and (n:find("kick") or n:find("ban") or n:find("punish")) then
                table.insert(found,v:GetFullName())
            end
        end
        if #found==0 then notify("No kick remotes found","ok") else
            notify(#found.." suspicious remotes (output)","warn")
            for _,p in ipairs(found) do print("[VP Kick] "..p) end
        end
    end)
end

---------------------------------------------------------------------------
-- CHEAT LOGIC
---------------------------------------------------------------------------

-- Anti-kick hook (runs immediately since AntiKick is on by default)
pcall(function()
    if not getrawmetatable then return end
    local mt=getrawmetatable(lp)
    local old=mt.__namecall
    mt.__namecall=newcclosure(function(self,...)
        local m=getnamecallmethod()
        if m=="Kick" and S.AntiKick then notify("Kick blocked","ok"); return end
        if (m=="FireServer" or m=="InvokeServer") then
            local n=tostring(self.Name):lower()
            if S.BlockArrest and (n:find("arrest") or n:find("cuff") or n:find("detain")) then notify("Arrest blocked","ok"); return end
            if S.BlockBan and (n:find("ban") or n:find("kick") or n:find("punish")) then notify("Ban remote blocked","ok"); return end
            if S.LogRemotes then print("[VP Remote] "..m.." → "..self:GetFullName()) end
        end
        return old(self,...)
    end)
end)

-- FOV ring
local ring; local hasDrawing=pcall(function()
    ring=Drawing.new("Circle"); ring.Color=Color3.fromRGB(0,201,185)
    ring.Thickness=1.2; ring.Filled=false; ring.Visible=false
end)

-- Skeleton lines
local skelLines={}
local BONES={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"}}
local function clearSkel()
    for _,l in ipairs(skelLines) do pcall(function() l:Remove() end) end; skelLines={}
end
local function drawSkel()
    clearSkel(); if not S.SkeletonESP or not hasDrawing then return end
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==lp or dist(pl)>S.ESPMaxDist then continue end
        local ch=chr(pl); if not ch then continue end
        local h=hum(pl); if not h or h.Health<=0 then continue end
        for _,pair in ipairs(BONES) do
            local a=ch:FindFirstChild(pair[1]); local b=ch:FindFirstChild(pair[2])
            if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                local sa,va=cam:WorldToViewportPoint(a.Position)
                local sb,vb=cam:WorldToViewportPoint(b.Position)
                if va and vb then
                    local line=Drawing.new("Line"); line.From=Vector2.new(sa.X,sa.Y)
                    line.To=Vector2.new(sb.X,sb.Y); line.Color=Color3.fromRGB(0,201,185)
                    line.Thickness=1; line.Visible=true; table.insert(skelLines,line)
                end
            end
        end
    end
end

-- ESP highlights
local espH={}
local function teamCol(p)
    local t=tostring(p.Team and p.Team.Name or ""):lower()
    return (t:find("guard") or t:find("police") or t:find("warden"))
        and Color3.fromRGB(248,113,113) or Color3.fromRGB(99,179,237)
end
local function removeESP(p) local h=espH[p]; if h and h.Parent then h:Destroy() end; espH[p]=nil end
local function buildESP(p)
    if p==lp then return end; removeESP(p)
    local function mk()
        local c=chr(p); if not c then return end
        local h=Instance.new("Highlight")
        h.FillColor=teamCol(p); h.OutlineColor=teamCol(p); h.FillTransparency=0.75; h.OutlineTransparency=0
        h.DepthMode=S.WallHack and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        h.Adornee=c; h.Enabled=S.PlayerESP and dist(p)<=S.ESPMaxDist; h.Parent=c; espH[p]=h
    end
    mk(); p.CharacterAdded:Connect(function() task.wait(0.2); mk() end)
end
local function refreshESP()
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==lp then continue end
        if S.PlayerESP then
            if not espH[pl] then buildESP(pl) end
            local h=espH[pl]; if h and h.Parent then
                h.Enabled=dist(pl)<=S.ESPMaxDist
                h.DepthMode=S.WallHack and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            end
        else removeESP(pl) end
    end
end
Players.PlayerAdded:Connect(function(p) if S.PlayerESP then buildESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)

-- Name/health/distance tags
local tagFolder=Instance.new("Folder"); tagFolder.Name="_VPT"; tagFolder.Parent=workspace
local function updateTags()
    for _,bb in ipairs(tagFolder:GetChildren()) do if not Players:FindFirstChild(bb.Name) then bb:Destroy() end end
    local any=S.NameESP or S.HealthESP or S.DistanceESP
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==lp then continue end
        local r=root(pl); local h=hum(pl); if not r or not h then continue end
        local far=dist(pl)>S.ESPMaxDist
        local bb=tagFolder:FindFirstChild(pl.Name)
        if not bb then
            bb=Instance.new("BillboardGui"); bb.Name=pl.Name
            bb.Size=UDim2.new(0,120,0,40); bb.StudsOffset=Vector3.new(0,3.5,0)
            bb.AlwaysOnTop=true; bb.ResetOnSpawn=false; bb.Parent=tagFolder
            local nl=Instance.new("TextLabel"); nl.Name="N"; nl.Size=UDim2.new(1,0,0,18)
            nl.BackgroundTransparency=1; nl.Font=Enum.Font.GothamBold; nl.TextSize=13
            nl.TextStrokeTransparency=0; nl.TextXAlignment=Enum.TextXAlignment.Center; nl.Parent=bb
            local il=Instance.new("TextLabel"); il.Name="I"; il.Size=UDim2.new(1,0,0,14); il.Position=UDim2.new(0,0,0,20)
            il.BackgroundTransparency=1; il.Font=Enum.Font.Gotham; il.TextSize=11
            il.TextStrokeTransparency=0; il.TextXAlignment=Enum.TextXAlignment.Center; il.Parent=bb
        end
        bb.Adornee=r; bb.Enabled=any and not far
        local nl=bb:FindFirstChild("N"); local il=bb:FindFirstChild("I")
        if nl then nl.Text=S.NameESP and pl.Name or ""; nl.TextColor3=teamCol(pl) end
        if il then
            local pts={}
            if S.HealthESP then table.insert(pts,math.floor(h.Health).."hp") end
            if S.DistanceESP then table.insert(pts,math.floor(dist(pl)).."m") end
            il.Text=table.concat(pts,"  "); il.TextColor3=Color3.fromRGB(180,185,210)
        end
    end
end

-- Item ESP
local itemH={}
local function refreshItemESP()
    for v,h in pairs(itemH) do
        if not v.Parent or (not S.ItemESP and not S.WeaponESP) then if h.Parent then h:Destroy() end; itemH[v]=nil end
    end
    if not S.ItemESP and not S.WeaponESP then return end
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Tool") and not itemH[v] then
            local n=v.Name:lower(); local wep=n:find("gun") or n:find("pistol") or n:find("rifle") or n:find("knife") or n:find("shot")
            if (S.WeaponESP and wep) or (S.ItemESP and not wep) or S.ItemESP then
                local h=Instance.new("Highlight")
                h.FillColor=wep and Color3.fromRGB(251,191,36) or Color3.fromRGB(52,211,153)
                h.OutlineColor=h.FillColor; h.FillTransparency=0.5; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                h.Adornee=v; h.Parent=v; itemH[v]=h
            end
        end
    end
end

-- Aimbot target finder — sorts by screen distance to crosshair (closest to center wins)
local function getBestTarget()
    local vp=cam.ViewportSize; local cx,cy=vp.X/2,vp.Y/2
    local candidates={}
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==lp or not enemy(pl) then continue end
        local ch=chr(pl); if not ch then continue end
        local h=hum(pl); if not h or h.Health<=0 then continue end
        if h:GetState()==Enum.HumanoidStateType.Dead then continue end
        if dist(pl)>S.ESPMaxDist then continue end
        local pt=ch:FindFirstChild(S.AimbotPart) or root(pl); if not pt then continue end
        if S.AimbotWallCheck then local r=root(lp); if r and not los(r,pt) then continue end end
        local sp,vis=cam:WorldToViewportPoint(pt.Position)
        if not vis or sp.Z<0 then continue end  -- behind camera
        local screenDist=((sp.X-cx)^2+(sp.Y-cy)^2)^0.5
        if screenDist<=S.AimbotFOV then
            table.insert(candidates,{part=pt, sd=screenDist})
        end
    end
    if #candidates==0 then return nil end
    table.sort(candidates,function(a,b) return a.sd<b.sd end)
    return candidates[1].part
end

-- Silent aim
local _saHooked=false
local function hookSilentAim()
    if _saHooked or not getrawmetatable then return end; _saHooked=true
    pcall(function()
        local mt=getrawmetatable(game); local old=mt.__namecall
        mt.__namecall=newcclosure(function(self,...)
            local m=getnamecallmethod()
            if S.SilentAim and (m=="FireServer" or m=="InvokeServer") then
                local args={...}; local t=getBestTarget()
                if t then
                    for i,v in ipairs(args) do
                        if typeof(v)=="Vector3" then args[i]=t.Position
                        elseif typeof(v)=="Instance" and v:IsA("BasePart") then args[i]=t end
                    end
                end
                return old(self,table.unpack(args))
            end
            return old(self,...)
        end)
    end)
end

-- Triggerbot
local _lastTrig=0
local function checkTrig()
    if not S.Triggerbot then return end
    local now=tick(); if now-_lastTrig<S.TriggerbotDelay then return end
    local vp=cam.ViewportSize
    local r=cam:ScreenPointToRay(vp.X/2,vp.Y/2)
    local p=RaycastParams.new(); p.FilterDescendantsInstances={chr(lp)}; p.FilterType=Enum.RaycastFilterType.Exclude
    local res=workspace:Raycast(r.Origin,r.Direction*500,p)
    if res then
        local ch=res.Instance:FindFirstAncestorOfClass("Model")
        if ch then
            local pl=Players:GetPlayerFromCharacter(ch)
            if pl and pl~=lp and enemy(pl) then
                _lastTrig=now
                local tool=chr(lp) and chr(lp):FindFirstChildOfClass("Tool")
                if tool then for _,re in ipairs(tool:GetDescendants()) do
                    if re:IsA("RemoteEvent") then pcall(function() re:FireServer(res.Instance,res.Position,res.Normal) end); break end
                end end
            end
        end
    end
end

-- Fly (BodyGyro + BodyVelocity for stability)
local _flyConn,_flyBV,_flyBG
function _startFly()
    _stopFly()
    local ch=chr(lp); local r=root(lp); local h=hum(lp)
    if not ch or not r or not h then return end
    h.PlatformStand=true

    _flyBV=Instance.new("BodyVelocity"); _flyBV.MaxForce=Vector3.new(1e9,1e9,1e9); _flyBV.Velocity=Vector3.zero; _flyBV.Parent=r
    _flyBG=Instance.new("BodyGyro"); _flyBG.MaxTorque=Vector3.new(4e5,4e5,4e5); _flyBG.D=100; _flyBG.CFrame=r.CFrame; _flyBG.Parent=r

    _flyConn=RunService.RenderStepped:Connect(function()
        if not S.Fly then _stopFly(); return end
        local dir=Vector3.zero; local cf=cam.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir+=cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir-=cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir-=cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir+=cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir+=Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir-=Vector3.new(0,1,0) end
        _flyBV.Velocity=dir.Magnitude>0 and dir.Unit*S.FlySpeed or Vector3.zero
        if dir.Magnitude>0 then _flyBG.CFrame=CFrame.new(r.Position,r.Position+dir) end
    end)
end
function _stopFly()
    if _flyConn then _flyConn:Disconnect(); _flyConn=nil end
    if _flyBV and _flyBV.Parent then _flyBV:Destroy(); _flyBV=nil end
    if _flyBG and _flyBG.Parent then _flyBG:Destroy(); _flyBG=nil end
    local h=hum(lp); if h then h.PlatformStand=false end
end

-- Noclip
RunService.Stepped:Connect(function()
    if not S.Noclip then return end
    local ch=chr(lp); if not ch then return end
    for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
end)

-- Inf jump
UserInputService.JumpRequest:Connect(function()
    if S.InfJump then local h=hum(lp); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

-- Stamina finder
local function findStamina()
    for _,v in ipairs(lp:GetDescendants()) do
        if (v:IsA("NumberValue") or v:IsA("IntValue")) and v.Name:lower():find("stam") then return v end
    end
    local ch=chr(lp); if ch then
        for _,v in ipairs(ch:GetDescendants()) do
            if (v:IsA("NumberValue") or v:IsA("IntValue")) and v.Name:lower():find("stam") then return v end
        end
    end
end

-- Hitbox
local origSizes={}

-- Heartbeat
RunService.Heartbeat:Connect(function()
    local h=hum(lp)
    if h then
        if S.SpeedEnabled and h.WalkSpeed~=S.Speed then h.WalkSpeed=S.Speed end
        if S.InfJump and h.JumpPower~=S.JumpPower then h.JumpPower=S.JumpPower end
    end
    if S.InfStamina then local sv=findStamina(); if sv then sv.Value=math.max(sv.Value,100) end end
    checkTrig()
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==lp then continue end
        for _,pt in ipairs({head(pl),root(pl)}) do
            if not pt then continue end
            if S.HitboxExpand then
                if not origSizes[pt] then origSizes[pt]=pt.Size end
                pt.Size=Vector3.new(S.HitboxSize,S.HitboxSize,S.HitboxSize)
            elseif origSizes[pt] then pt.Size=origSizes[pt]; origSizes[pt]=nil end
        end
    end
end)

-- Render (ESP/drawing — runs before camera update, fine for UI)
local _et,_st=0,0
RunService.RenderStepped:Connect(function(dt)
    _et+=dt; _st+=dt

    -- FOV ring
    if hasDrawing and ring then
        ring.Visible=S.AimbotFOVRing and (S.Aimbot or S.Aimlock)
        if ring.Visible then
            local vp=cam.ViewportSize; ring.Position=Vector2.new(vp.X/2,vp.Y/2)
            ring.Radius=S.AimbotFOV; ring.Color=S.Aimlock and Color3.fromRGB(248,113,113) or Color3.fromRGB(0,201,185)
        end
    end

    if S.SilentAim and not _saHooked then hookSilentAim() end

    if _et>=0.18 then _et=0; refreshESP(); updateTags(); refreshItemESP() end
    if _st>=0.05 then _st=0; drawSkel() end
end)

-- Aimbot — must run at Camera.Value+1 so our write is last and Roblox doesn't overwrite it
RunService:BindToRenderStep("VP_Aim", Enum.RenderPriority.Camera.Value + 1, function()
    if not (S.Aimbot or S.Aimlock) then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    if S.AimbotRequireGun and not hasGun() then return end
    local t=getBestTarget(); if not t then return end
    local g=CFrame.new(cam.CFrame.Position, t.Position)
    if S.Aimlock then cam.CFrame=g else cam.CFrame=cam.CFrame:Lerp(g, S.AimbotSmooth) end
end)

---------------------------------------------------------------------------
-- TOGGLE  (Right Shift — no gameProcessed guard so it always works)
---------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(i)
    if i.KeyCode~=Enum.KeyCode.RightShift then return end
    S.Open=not S.Open
    if S.Open then
        win.Visible=true; win.Size=UDim2.new(0,W,0,0)
        tw(win,0.2,{Size=UDim2.new(0,W,0,H)})
        minimized=false
    else
        tw(win,0.15,{Size=UDim2.new(0,W,0,0)})
        task.wait(0.16); win.Visible=false; win.Size=UDim2.new(0,W,0,H)
    end
end)

---------------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------------
for _,pl in ipairs(Players:GetPlayers()) do if pl~=lp then buildESP(pl) end end
setPage("Home")
lp.CharacterAdded:Connect(function()
    task.wait(0.6)
    for _,pl in ipairs(Players:GetPlayers()) do if pl~=lp then buildESP(pl) end end
    if S.Fly then _startFly() end
    local h=hum(lp)
    if h then
        if S.SpeedEnabled then h.WalkSpeed=S.Speed end
        if S.InfJump then h.JumpPower=S.JumpPower end
    end
end)

tw(win,0.22,{Size=UDim2.new(0,W,0,H)})
notify("Loaded  ·  Anti-Kick active","ok",4)
print("[NyxScript] Valley Prison ready. Right Shift = toggle.")
