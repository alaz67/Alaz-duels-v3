-- ╔══════════════════════════════════════════════════════════════╗
-- ║              ⚔  ALAZ DUEL  ⚔                                ║
-- ║              Steal a Brainrot Edition                        ║
-- ║              discord.gg/U4XXCxKUm                            ║
-- ╚══════════════════════════════════════════════════════════════╝

repeat task.wait() until game:IsLoaded()

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local Player           = Players.LocalPlayer

-- ──────────────────────────────────────────────────────────────
-- CONFIG
-- ──────────────────────────────────────────────────────────────
local Config = {
    SpeedBoost  = 60.0,
    CarrySpeed  = 29.5,
    HopPower    = 50.0,
    Gravity     = 70.0,
    SpinSpeed   = 19.0,
}

local Toggles = {
    VoidMode   = false,
    SpinBot    = false,
    Unwalk     = false,
    Float      = false,
    BatAimbot  = false,
    AutoLeft   = false,
    AutoRight  = false,
    CarryMode  = false,
    FloatMode  = false,
}

local guiVisible   = true
local Connections  = {}
local spinBAV      = nil
local floatPlat    = nil
local floatConn    = nil
local savedAnims   = {}
local defaultGrav  = workspace.Gravity
local galaxyVF, galaxyAtt = nil, nil

-- ──────────────────────────────────────────────────────────────
-- HELPERS
-- ──────────────────────────────────────────────────────────────
local function getHRP()
    local c = Player.Character; return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = Player.Character; return c and c:FindFirstChildOfClass("Humanoid")
end
local function getMoveDir()
    local h = getHum(); return h and h.MoveDirection or Vector3.zero
end

-- ──────────────────────────────────────────────────────────────
-- SPEED BOOST
-- ──────────────────────────────────────────────────────────────
local function startSpeed()
    if Connections.speed then return end
    Connections.speed = RunService.Heartbeat:Connect(function()
        local hrp = getHRP(); if not hrp then return end
        local md = getMoveDir()
        if md.Magnitude > 0.1 then
            local stealing = Player:GetAttribute("Stealing")
            local spd = stealing and Config.CarrySpeed or Config.SpeedBoost
            hrp.AssemblyLinearVelocity = Vector3.new(md.X*spd, hrp.AssemblyLinearVelocity.Y, md.Z*spd)
        end
    end)
end
local function stopSpeed()
    if Connections.speed then Connections.speed:Disconnect(); Connections.speed = nil end
end

-- ──────────────────────────────────────────────────────────────
-- VOID MODE
-- ──────────────────────────────────────────────────────────────
local function enableVoid()
    local char = Player.Character; if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
    end
end
local function disableVoid()
    local char = Player.Character; if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
    end
end

-- ──────────────────────────────────────────────────────────────
-- GRAVITY
-- ──────────────────────────────────────────────────────────────
local function setupGravity()
    local hrp = getHRP(); if not hrp then return end
    if galaxyVF  then galaxyVF:Destroy()  end
    if galaxyAtt then galaxyAtt:Destroy() end
    galaxyAtt = Instance.new("Attachment"); galaxyAtt.Parent = hrp
    galaxyVF  = Instance.new("VectorForce"); galaxyVF.Attachment0 = galaxyAtt
    galaxyVF.ApplyAtCenterOfMass = true
    galaxyVF.RelativeTo = Enum.ActuatorRelativeTo.World
    galaxyVF.Force = Vector3.zero; galaxyVF.Parent = hrp
end
local function updateGravity()
    if not galaxyVF then return end
    local char = Player.Character; if not char then return end
    local mass = 0
    for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then mass += p:GetMass() end end
    local tg = defaultGrav * (Config.Gravity/100)
    galaxyVF.Force = Vector3.new(0, mass*(defaultGrav-tg)*0.95, 0)
end

-- ──────────────────────────────────────────────────────────────
-- SPIN BOT
-- ──────────────────────────────────────────────────────────────
local function startSpin()
    local hrp = getHRP(); if not hrp then return end
    if spinBAV then spinBAV:Destroy() end
    spinBAV = Instance.new("BodyAngularVelocity")
    spinBAV.Name = "SpinBAV"; spinBAV.MaxTorque = Vector3.new(0,math.huge,0)
    spinBAV.AngularVelocity = Vector3.new(0,Config.SpinSpeed,0); spinBAV.Parent = hrp
end
local function stopSpin()
    if spinBAV then spinBAV:Destroy(); spinBAV = nil end
end

-- ──────────────────────────────────────────────────────────────
-- UNWALK
-- ──────────────────────────────────────────────────────────────
local function startUnwalk()
    local char = Player.Character; if not char then return end
    local hum = getHum(); if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
    local anim = char:FindFirstChild("Animate")
    if anim then savedAnims.Animate = anim:Clone(); anim:Destroy() end
end
local function stopUnwalk()
    local char = Player.Character
    if char and savedAnims.Animate then savedAnims.Animate:Clone().Parent = char; savedAnims.Animate = nil end
end

-- ──────────────────────────────────────────────────────────────
-- FLOAT (F key)
-- ──────────────────────────────────────────────────────────────
local function startFloat()
    if floatPlat then floatPlat:Destroy() end
    floatPlat = Instance.new("Part")
    floatPlat.Size = Vector3.new(6,1,6); floatPlat.Anchored = true
    floatPlat.CanCollide = true; floatPlat.Transparency = 1; floatPlat.Parent = workspace
    task.spawn(function()
        while floatPlat and Toggles.Float do
            local hrp = getHRP()
            if hrp then floatPlat.Position = hrp.Position - Vector3.new(0,3,0) end
            task.wait(0.05)
        end
    end)
end
local function stopFloat()
    if floatPlat then floatPlat:Destroy(); floatPlat = nil end
end

-- ──────────────────────────────────────────────────────────────
-- BAT AIMBOT
-- ──────────────────────────────────────────────────────────────
local function findEnemy()
    local hrp = getHRP(); if not hrp then return nil end
    local best, bestD = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local eh = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 then
                local d = (eh.Position - hrp.Position).Magnitude
                if d < bestD then bestD = d; best = eh end
            end
        end
    end
    return best
end
local function findBat()
    local char = Player.Character; if not char then return nil end
    local bp = Player:FindFirstChildOfClass("Backpack")
    for _, ch in ipairs(char:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end
    if bp then for _, ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end
end
local function startAimbot()
    if Connections.aim then return end
    Connections.aim = RunService.Heartbeat:Connect(function()
        if not Toggles.BatAimbot then return end
        local hrp = getHRP(); local hum = getHum(); if not hrp or not hum then return end
        local bat = findBat(); if bat and bat.Parent ~= Player.Character then hum:EquipTool(bat) end
        local t = findEnemy(); if not t then return end
        local flat = Vector3.new(t.Position.X-hrp.Position.X, 0, t.Position.Z-hrp.Position.Z)
        if flat.Magnitude > 1.5 then
            local md = flat.Unit
            hrp.AssemblyLinearVelocity = Vector3.new(md.X*55, hrp.AssemblyLinearVelocity.Y, md.Z*55)
        end
    end)
end
local function stopAimbot()
    if Connections.aim then Connections.aim:Disconnect(); Connections.aim = nil end
end

-- ──────────────────────────────────────────────────────────────
-- AUTO LEFT / RIGHT
-- ──────────────────────────────────────────────────────────────
local PL1=Vector3.new(-476.48,-6.28,92.73); local PL2=Vector3.new(-483.12,-4.95,94.80)
local PR1=Vector3.new(-476.16,-6.52,25.62); local PR2=Vector3.new(-483.04,-5.09,23.14)
local leftPhase=1; local rightPhase=1

local function startAutoLeft()
    if Connections.autoL then Connections.autoL:Disconnect() end; leftPhase=1
    Connections.autoL = RunService.Heartbeat:Connect(function()
        if not Toggles.AutoLeft then return end
        local hrp=getHRP(); local hum=getHum(); if not hrp or not hum then return end
        local tgt = leftPhase==1 and PL1 or PL2
        local dist = (Vector3.new(tgt.X,hrp.Position.Y,tgt.Z)-hrp.Position).Magnitude
        if dist < 1.5 then
            if leftPhase==1 then leftPhase=2
            else
                hum:Move(Vector3.zero,false); hrp.AssemblyLinearVelocity=Vector3.zero
                Toggles.AutoLeft=false; Connections.autoL:Disconnect(); Connections.autoL=nil; return
            end
        end
        local d=(tgt-hrp.Position); local md=Vector3.new(d.X,0,d.Z).Unit
        hum:Move(md,false); hrp.AssemblyLinearVelocity=Vector3.new(md.X*Config.SpeedBoost,hrp.AssemblyLinearVelocity.Y,md.Z*Config.SpeedBoost)
    end)
end
local function stopAutoLeft()
    if Connections.autoL then Connections.autoL:Disconnect(); Connections.autoL=nil end
    local hum=getHum(); if hum then hum:Move(Vector3.zero,false) end
end

local function startAutoRight()
    if Connections.autoR then Connections.autoR:Disconnect() end; rightPhase=1
    Connections.autoR = RunService.Heartbeat:Connect(function()
        if not Toggles.AutoRight then return end
        local hrp=getHRP(); local hum=getHum(); if not hrp or not hum then return end
        local tgt = rightPhase==1 and PR1 or PR2
        local dist = (Vector3.new(tgt.X,hrp.Position.Y,tgt.Z)-hrp.Position).Magnitude
        if dist < 1.5 then
            if rightPhase==1 then rightPhase=2
            else
                hum:Move(Vector3.zero,false); hrp.AssemblyLinearVelocity=Vector3.zero
                Toggles.AutoRight=false; Connections.autoR:Disconnect(); Connections.autoR=nil; return
            end
        end
        local d=(tgt-hrp.Position); local md=Vector3.new(d.X,0,d.Z).Unit
        hum:Move(md,false); hrp.AssemblyLinearVelocity=Vector3.new(md.X*Config.SpeedBoost,hrp.AssemblyLinearVelocity.Y,md.Z*Config.SpeedBoost)
    end)
end
local function stopAutoRight()
    if Connections.autoR then Connections.autoR:Disconnect(); Connections.autoR=nil end
    local hum=getHum(); if hum then hum:Move(Vector3.zero,false) end
end

-- ──────────────────────────────────────────────────────────────
-- CARRY MODE
-- ──────────────────────────────────────────────────────────────
local function startCarry()
    if Connections.carry then return end
    Connections.carry = RunService.Heartbeat:Connect(function()
        if not Toggles.CarryMode then return end
        if not Player:GetAttribute("Stealing") then return end
        local hrp=getHRP(); if not hrp then return end
        local md=getMoveDir()
        if md.Magnitude>0.1 then hrp.AssemblyLinearVelocity=Vector3.new(md.X*Config.CarrySpeed,hrp.AssemblyLinearVelocity.Y,md.Z*Config.CarrySpeed) end
    end)
end
local function stopCarry()
    if Connections.carry then Connections.carry:Disconnect(); Connections.carry=nil end
end

-- ──────────────────────────────────────────────────────────────
-- FLOAT MODE
-- ──────────────────────────────────────────────────────────────
local floatAnchorY = nil
local function startFloatMode()
    if floatConn then return end
    local hrp=getHRP(); if not hrp then return end
    floatAnchorY = hrp.Position.Y
    floatConn = RunService.Heartbeat:Connect(function()
        if not Toggles.FloatMode then return end
        local h=getHRP(); if not h then return end
        h.AssemblyLinearVelocity=Vector3.new(h.AssemblyLinearVelocity.X,0,h.AssemblyLinearVelocity.Z)
        if floatAnchorY and math.abs(h.Position.Y-floatAnchorY)>1 then
            h.CFrame=CFrame.new(h.Position.X,floatAnchorY,h.Position.Z)
        end
    end)
end
local function stopFloatMode()
    if floatConn then floatConn:Disconnect(); floatConn=nil end
end

-- ──────────────────────────────────────────────────────────────
-- DROP ANIMAL
-- ──────────────────────────────────────────────────────────────
local function dropAnimal()
    local hum=getHum(); if hum then hum:UnequipTools() end
end

-- ──────────────────────────────────────────────────────────────
-- GUI
-- ──────────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name="AlazDuel"; sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.Parent=Player:FindFirstChildOfClass("PlayerGui") or Player.PlayerGui

local PINK   = Color3.fromRGB(220,0,120)
local DARKBG = Color3.fromRGB(20,5,15)
local CARDBG = Color3.fromRGB(35,8,25)
local WHITE  = Color3.fromRGB(255,255,255)
local DIMTXT = Color3.fromRGB(150,50,100)

-- ══════════════════════════════
-- LEFT PANEL (Sliders)
-- ══════════════════════════════
local leftPanel = Instance.new("Frame",sg)
leftPanel.Name="LeftPanel"
leftPanel.Size=UDim2.new(0,170,0,440)
leftPanel.Position=UDim2.new(0.5,-85,0.5,-220)
leftPanel.BackgroundColor3=DARKBG
leftPanel.BackgroundTransparency=0.05
leftPanel.BorderSizePixel=0
leftPanel.Active=true; leftPanel.Draggable=true
leftPanel.ClipsDescendants=true; leftPanel.ZIndex=10
Instance.new("UICorner",leftPanel).CornerRadius=UDim.new(0,14)
local lps=Instance.new("UIStroke",leftPanel); lps.Color=PINK; lps.Thickness=1.5

-- Title
local titleLbl=Instance.new("TextLabel",leftPanel)
titleLbl.Size=UDim2.new(1,0,0,35); titleLbl.BackgroundTransparency=1
titleLbl.Text="ALAZ DUEL"; titleLbl.TextColor3=PINK
titleLbl.Font=Enum.Font.GothamBlack; titleLbl.TextSize=14
titleLbl.TextXAlignment=Enum.TextXAlignment.Center; titleLbl.ZIndex=11

-- Scroll inside left panel
local lScroll=Instance.new("ScrollingFrame",leftPanel)
lScroll.Size=UDim2.new(1,0,1,-38); lScroll.Position=UDim2.new(0,0,0,36)
lScroll.BackgroundTransparency=1; lScroll.BorderSizePixel=0
lScroll.ScrollBarThickness=3; lScroll.ScrollBarImageColor3=PINK
lScroll.CanvasSize=UDim2.new(0,0,0,0); lScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
lScroll.ZIndex=11

local lList=Instance.new("UIListLayout",lScroll)
lList.Padding=UDim.new(0,4); lList.SortOrder=Enum.SortOrder.LayoutOrder
lList.HorizontalAlignment=Enum.HorizontalAlignment.Center
local lPad=Instance.new("UIPadding",lScroll)
lPad.PaddingTop=UDim.new(0,8); lPad.PaddingBottom=UDim.new(0,8)
lPad.PaddingLeft=UDim.new(0,8); lPad.PaddingRight=UDim.new(0,8)

local lo=0
local function nextLO() lo=lo+1; return lo end

local function mkSectionLbl(text)
    local l=Instance.new("TextLabel",lScroll)
    l.Size=UDim2.new(1,0,0,18); l.BackgroundTransparency=1
    l.Text=text; l.TextColor3=DIMTXT
    l.Font=Enum.Font.GothamBold; l.TextSize=10
    l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=12; l.LayoutOrder=nextLO()
end

local function mkSlider(title, configKey, mn, mx)
    local cont=Instance.new("Frame",lScroll)
    cont.Size=UDim2.new(1,0,0,36); cont.BackgroundColor3=CARDBG
    cont.BackgroundTransparency=0.2; cont.BorderSizePixel=0; cont.ZIndex=12; cont.LayoutOrder=nextLO()
    Instance.new("UICorner",cont).CornerRadius=UDim.new(0,8)

    local tl=Instance.new("TextLabel",cont)
    tl.Size=UDim2.new(0.7,0,0,20); tl.Position=UDim2.new(0,10,0,4)
    tl.BackgroundTransparency=1; tl.Text=title; tl.TextColor3=PINK
    tl.Font=Enum.Font.GothamBold; tl.TextSize=12; tl.TextXAlignment=Enum.TextXAlignment.Left; tl.ZIndex=13

    local vl=Instance.new("TextLabel",cont)
    vl.Size=UDim2.new(0.28,0,0,20); vl.Position=UDim2.new(0.72,0,0,4)
    vl.BackgroundTransparency=1; vl.Text=tostring(Config[configKey])
    vl.TextColor3=WHITE; vl.Font=Enum.Font.GothamBold; vl.TextSize=12
    vl.TextXAlignment=Enum.TextXAlignment.Right; vl.ZIndex=13

    local track=Instance.new("Frame",cont)
    track.Size=UDim2.new(1,-20,0,5); track.Position=UDim2.new(0,10,0,32)
    track.BackgroundColor3=Color3.fromRGB(60,15,40); track.BorderSizePixel=0; track.ZIndex=12
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)

    local pct=(Config[configKey]-mn)/(mx-mn)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new(pct,0,1,0); fill.BackgroundColor3=PINK; fill.BorderSizePixel=0; fill.ZIndex=13
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)

    local thumb=Instance.new("Frame",track)
    thumb.Size=UDim2.new(0,13,0,13); thumb.Position=UDim2.new(pct,-6.5,0.5,-6.5)
    thumb.BackgroundColor3=WHITE; thumb.BorderSizePixel=0; thumb.ZIndex=14
    Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)

    local sBtn=Instance.new("TextButton",track)
    sBtn.Size=UDim2.new(1,0,4,0); sBtn.Position=UDim2.new(0,0,-1.5,0)
    sBtn.BackgroundTransparency=1; sBtn.Text=""; sBtn.ZIndex=15

    local dragging=false
    local function upd(rel)
        rel=math.clamp(rel,0,1); fill.Size=UDim2.new(rel,0,1,0); thumb.Position=UDim2.new(rel,-6.5,0.5,-6.5)
        local val=math.floor((mn+(mx-mn)*rel)*10)/10
        vl.Text=tostring(val); Config[configKey]=val
        if configKey=="Gravity" then updateGravity() end
        if configKey=="SpinSpeed" and spinBAV then spinBAV.AngularVelocity=Vector3.new(0,val,0) end
    end
    sBtn.MouseButton1Down:Connect(function() dragging=true end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            upd((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X)
        end
    end)
end

local function mkToggleLeft(title, key, keybindTxt, onCb, offCb)
    local cont=Instance.new("Frame",lScroll)
    cont.Size=UDim2.new(1,0,0,36); cont.BackgroundColor3=CARDBG
    cont.BackgroundTransparency=0.2; cont.BorderSizePixel=0; cont.ZIndex=12; cont.LayoutOrder=nextLO()
    Instance.new("UICorner",cont).CornerRadius=UDim.new(0,8)

    if keybindTxt then
        local kl=Instance.new("TextLabel",cont)
        kl.Size=UDim2.new(0,26,0,26); kl.Position=UDim2.new(0,8,0.5,-13)
        kl.BackgroundColor3=Color3.fromRGB(60,15,40); kl.BackgroundTransparency=0
        kl.Text=keybindTxt; kl.TextColor3=PINK; kl.Font=Enum.Font.GothamBold; kl.TextSize=11
        kl.BorderSizePixel=0; kl.ZIndex=13
        Instance.new("UICorner",kl).CornerRadius=UDim.new(0,5)
    end

    local xOff = keybindTxt and 42 or 10
    local tl=Instance.new("TextLabel",cont)
    tl.Size=UDim2.new(1,-85,1,0); tl.Position=UDim2.new(0,xOff,0,0)
    tl.BackgroundTransparency=1; tl.Text=title; tl.TextColor3=PINK
    tl.Font=Enum.Font.GothamBold; tl.TextSize=12
    tl.TextXAlignment=Enum.TextXAlignment.Left; tl.ZIndex=13

    local defOn=Toggles[key] or false
    local tb=Instance.new("Frame",cont)
    tb.Size=UDim2.new(0,44,0,22); tb.Position=UDim2.new(1,-52,0.5,-11)
    tb.BackgroundColor3=defOn and PINK or Color3.fromRGB(80,30,60); tb.BorderSizePixel=0; tb.ZIndex=13
    Instance.new("UICorner",tb).CornerRadius=UDim.new(1,0)

    local knob=Instance.new("Frame",tb)
    knob.Size=UDim2.new(0,16,0,16)
    knob.Position=defOn and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
    knob.BackgroundColor3=WHITE; knob.BorderSizePixel=0; knob.ZIndex=14
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local clk=Instance.new("TextButton",cont)
    clk.Size=UDim2.new(1,0,1,0); clk.BackgroundTransparency=1; clk.Text=""; clk.ZIndex=15

    local isOn=defOn
    clk.MouseButton1Click:Connect(function()
        isOn=not isOn; Toggles[key]=isOn
        TweenService:Create(tb,TweenInfo.new(0.2),{BackgroundColor3=isOn and PINK or Color3.fromRGB(80,30,60)}):Play()
        TweenService:Create(knob,TweenInfo.new(0.2,Enum.EasingStyle.Back),{Position=isOn and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
        if isOn and onCb  then onCb()  end
        if not isOn and offCb then offCb() end
    end)
end

-- Populate left panel
mkSectionLbl("SPEED")
mkSlider("Speed Boost", "SpeedBoost", 0, 120)
mkSlider("Carry Speed", "CarrySpeed", 0, 60)
mkSectionLbl("MOVEMENT")
mkToggleLeft("Void Mode",  "VoidMode",  nil, enableVoid,  disableVoid)
mkSlider("Hop Power",  "HopPower",  0,  150)
mkSlider("Gravity",    "Gravity",   10, 150)
mkToggleLeft("Spin Bot",   "SpinBot",   nil, startSpin,   stopSpin)
mkSlider("Spin Speed", "SpinSpeed", 0,  80)
mkToggleLeft("Unwalk",     "Unwalk",    nil, startUnwalk, stopUnwalk)
mkToggleLeft("Float",      "Float",     "F", startFloat,  stopFloat)

-- ══════════════════════════════
-- RIGHT PANEL (Cards)
-- ══════════════════════════════
local rightPanel=Instance.new("Frame",sg)
rightPanel.Name="RightPanel"
rightPanel.Size=UDim2.new(0,75,0,310)
rightPanel.Position=UDim2.new(1,-81,0,55)
rightPanel.BackgroundTransparency=1
rightPanel.ZIndex=10

local rList=Instance.new("UIListLayout",rightPanel)
rList.Padding=UDim.new(0,4); rList.SortOrder=Enum.SortOrder.LayoutOrder
rList.HorizontalAlignment=Enum.HorizontalAlignment.Center

local ro=0
local function nextRO() ro=ro+1; return ro end

local function mkCard(line1, line2, key, onCb, offCb)
    local card=Instance.new("Frame",rightPanel)
    card.Size=UDim2.new(1,0,0,62); card.BackgroundColor3=CARDBG
    card.BackgroundTransparency=0.1; card.BorderSizePixel=0; card.ZIndex=12; card.LayoutOrder=nextRO()
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,10)
    local cs=Instance.new("UIStroke",card); cs.Color=PINK; cs.Thickness=0; cs.Transparency=1

    local tl1=Instance.new("TextLabel",card)
    tl1.Size=UDim2.new(1,0,0.48,0); tl1.Position=UDim2.new(0,0,0.04,0)
    tl1.BackgroundTransparency=1; tl1.Text=line1; tl1.TextColor3=PINK
    tl1.Font=Enum.Font.GothamBlack; tl1.TextSize=11
    tl1.TextXAlignment=Enum.TextXAlignment.Center; tl1.ZIndex=13

    local tl2=Instance.new("TextLabel",card)
    tl2.Size=UDim2.new(1,0,0.38,0); tl2.Position=UDim2.new(0,0,0.46,0)
    tl2.BackgroundTransparency=1; tl2.Text=line2; tl2.TextColor3=PINK
    tl2.Font=Enum.Font.GothamBold; tl2.TextSize=10
    tl2.TextXAlignment=Enum.TextXAlignment.Center; tl2.ZIndex=13

    -- Small toggle dot at bottom
    local dot=Instance.new("Frame",card)
    dot.Size=UDim2.new(0,10,0,10); dot.Position=UDim2.new(0.5,-5,1,-14)
    dot.BackgroundColor3=Color3.fromRGB(80,30,60); dot.BorderSizePixel=0; dot.ZIndex=13
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)

    local clk=Instance.new("TextButton",card)
    clk.Size=UDim2.new(1,0,1,0); clk.BackgroundTransparency=1; clk.Text=""; clk.ZIndex=15

    local isOn=false
    clk.MouseButton1Click:Connect(function()
        isOn=not isOn
        if key then Toggles[key]=isOn end
        TweenService:Create(dot,TweenInfo.new(0.2),{BackgroundColor3=isOn and PINK or Color3.fromRGB(80,30,60)}):Play()
        TweenService:Create(card,TweenInfo.new(0.15),{BackgroundTransparency=isOn and 0 or 0.1}):Play()
        if isOn and onCb  then onCb()  end
        if not isOn and offCb then offCb() end
    end)
    return card
end

local function mkActionCard(line1, line2, cb)
    local card=Instance.new("TextButton",rightPanel)
    card.Size=UDim2.new(1,0,0,62); card.BackgroundColor3=CARDBG
    card.BackgroundTransparency=0.1; card.BorderSizePixel=0; card.Text=""; card.ZIndex=12; card.LayoutOrder=nextRO()
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,10)

    local tl1=Instance.new("TextLabel",card)
    tl1.Size=UDim2.new(1,0,0.5,0); tl1.Position=UDim2.new(0,0,0.08,0)
    tl1.BackgroundTransparency=1; tl1.Text=line1; tl1.TextColor3=PINK
    tl1.Font=Enum.Font.GothamBlack; tl1.TextSize=11
    tl1.TextXAlignment=Enum.TextXAlignment.Center; tl1.ZIndex=13

    local tl2=Instance.new("TextLabel",card)
    tl2.Size=UDim2.new(1,0,0.38,0); tl2.Position=UDim2.new(0,0,0.52,0)
    tl2.BackgroundTransparency=1; tl2.Text=line2; tl2.TextColor3=PINK
    tl2.Font=Enum.Font.GothamBold; tl2.TextSize=10
    tl2.TextXAlignment=Enum.TextXAlignment.Center; tl2.ZIndex=13

    card.MouseButton1Click:Connect(cb)
    card.MouseEnter:Connect(function() TweenService:Create(card,TweenInfo.new(0.15),{BackgroundTransparency=0}):Play() end)
    card.MouseLeave:Connect(function() TweenService:Create(card,TweenInfo.new(0.15),{BackgroundTransparency=0.1}):Play() end)
end

-- Populate right panel
mkCard("AUTO",  "GRAB",       "AutoSteal",  startAutoSteal,  stopAutoSteal)
mkCard("BAT",   "AIMBOT",     "BatAimbot",  startAimbot,    stopAimbot)
mkCard("AUTO",  "LEFT",       "AutoLeft",   startAutoLeft,  stopAutoLeft)
mkCard("AUTO",  "RIGHT",      "AutoRight",  startAutoRight, stopAutoRight)

-- ══════════════════════════════
-- TOGGLE ICON (top right, like screenshot)
-- ══════════════════════════════
local iconBtn=Instance.new("TextButton",sg)
iconBtn.Size=UDim2.new(0,50,0,50)
iconBtn.Position=UDim2.new(0,5,0,5)
iconBtn.BackgroundColor3=Color3.fromRGB(25,8,20)
iconBtn.BackgroundTransparency=0.1
iconBtn.Text="A"; iconBtn.TextColor3=PINK
iconBtn.Font=Enum.Font.GothamBlack; iconBtn.TextSize=22
iconBtn.ZIndex=999; iconBtn.BorderSizePixel=0
Instance.new("UICorner",iconBtn).CornerRadius=UDim.new(0,12)
local iS=Instance.new("UIStroke",iconBtn); iS.Color=PINK; iS.Thickness=2

-- Green leaf dot (like screenshot)
local leafDot=Instance.new("Frame",iconBtn)
leafDot.Size=UDim2.new(0,14,0,14); leafDot.Position=UDim2.new(1,-16,0,2)
leafDot.BackgroundColor3=Color3.fromRGB(0,200,80); leafDot.BorderSizePixel=0; leafDot.ZIndex=1000
Instance.new("UICorner",leafDot).CornerRadius=UDim.new(1,0)

local leafTxt=Instance.new("TextLabel",leafDot)
leafTxt.Size=UDim2.new(1,0,1,0); leafTxt.BackgroundTransparency=1
leafTxt.Text="🌿"; leafTxt.TextSize=9; leafTxt.ZIndex=1001

iconBtn.MouseButton1Click:Connect(function()
    guiVisible=not guiVisible
    leftPanel.Visible=guiVisible
end)

-- ──────────────────────────────────────────────────────────────
-- KEYBINDS
-- ──────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.U then guiVisible=not guiVisible; leftPanel.Visible=guiVisible end
    if inp.KeyCode==Enum.KeyCode.F then
        Toggles.Float=not Toggles.Float
        if Toggles.Float then startFloat() else stopFloat() end
    end
end)

-- ──────────────────────────────────────────────────────────────
-- GRAVITY LOOP + SPEED LOOP
-- ──────────────────────────────────────────────────────────────
task.spawn(function()
    task.wait(1); setupGravity()
    startSpeed()
    RunService.Heartbeat:Connect(updateGravity)
end)

-- ──────────────────────────────────────────────────────────────
-- RESPAWN
-- ──────────────────────────────────────────────────────────────
Player.CharacterAdded:Connect(function()
    task.wait(1); setupGravity(); startSpeed()
    if Toggles.SpinBot    then stopSpin();     task.wait(0.1); startSpin()     end
    if Toggles.BatAimbot  then stopAimbot();   task.wait(0.1); startAimbot()   end
    if Toggles.Float      then startFloat()                                     end
    if Toggles.VoidMode   then enableVoid()                                     end
    if Toggles.Unwalk     then startUnwalk()                                    end
end)

print("⚔ ALAZ DUEL Loaded!  U=Toggle  discord.gg/U4XXCxKUm")
