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
    SpeedBoost   = 60.0,
    CarrySpeed   = 29.5,
    HopPower     = 50.0,
    Gravity      = 70.0,
    SpinSpeed    = 19.0,
}

local Toggles = {
    VoidMode    = false,
    SpinBot     = false,
    Unwalk      = false,
    Float       = false,
    BatAimbot   = false,
    AutoLeft    = false,
    AutoRight   = false,
    CarryMode   = false,
    FloatMode   = false,
    DropAnimal  = false,
}

local guiVisible = true
local Connections = {}
local spinBAV = nil
local floatPlatform = nil
local savedAnims = {}

-- KEYBINDS
local KEYBINDS = {
    Float = Enum.KeyCode.F,
}

-- ──────────────────────────────────────────────────────────────
-- HELPERS
-- ──────────────────────────────────────────────────────────────
local function getHRP()
    local c = Player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = Player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getMoveDir()
    local h = getHum()
    return h and h.MoveDirection or Vector3.zero
end

-- ──────────────────────────────────────────────────────────────
-- SPEED BOOST
-- ──────────────────────────────────────────────────────────────
local function startSpeedBoost()
    if Connections.speed then return end
    Connections.speed = RunService.Heartbeat:Connect(function()
        local hrp = getHRP(); if not hrp then return end
        local md = getMoveDir()
        if md.Magnitude > 0.1 then
            hrp.AssemblyLinearVelocity = Vector3.new(
                md.X * Config.SpeedBoost,
                hrp.AssemblyLinearVelocity.Y,
                md.Z * Config.SpeedBoost
            )
        end
    end)
end
local function stopSpeedBoost()
    if Connections.speed then Connections.speed:Disconnect(); Connections.speed = nil end
end

-- ──────────────────────────────────────────────────────────────
-- VOID MODE (no clip through floor)
-- ──────────────────────────────────────────────────────────────
local function enableVoidMode()
    local char = Player.Character; if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = false
        end
    end
end
local function disableVoidMode()
    local char = Player.Character; if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = true
        end
    end
end

-- ──────────────────────────────────────────────────────────────
-- GRAVITY
-- ──────────────────────────────────────────────────────────────
local defaultGravity = workspace.Gravity
local galaxyVF = nil
local galaxyAtt = nil

local function setupGravity()
    local char = Player.Character; if not char then return end
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
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then mass = mass + p:GetMass() end
    end
    local gravPct = Config.Gravity / 100
    local tg = defaultGravity * gravPct
    galaxyVF.Force = Vector3.new(0, mass * (defaultGravity - tg) * 0.95, 0)
end

-- ──────────────────────────────────────────────────────────────
-- HOP POWER
-- ──────────────────────────────────────────────────────────────
local lastHop = 0
RunService.Heartbeat:Connect(function()
    if not Toggles.VoidMode then return end
    local hrp = getHRP(); local hum = getHum(); if not hrp or not hum then return end
    if tick() - lastHop < 0.08 then return end
    lastHop = tick()
    if hum.FloorMaterial == Enum.Material.Air then
        hrp.AssemblyLinearVelocity = Vector3.new(
            hrp.AssemblyLinearVelocity.X,
            Config.HopPower,
            hrp.AssemblyLinearVelocity.Z
        )
    end
end)

-- ──────────────────────────────────────────────────────────────
-- SPIN BOT
-- ──────────────────────────────────────────────────────────────
local function startSpinBot()
    local hrp = getHRP(); if not hrp then return end
    if spinBAV then spinBAV:Destroy(); spinBAV = nil end
    spinBAV = Instance.new("BodyAngularVelocity")
    spinBAV.Name = "SpinBAV"; spinBAV.MaxTorque = Vector3.new(0, math.huge, 0)
    spinBAV.AngularVelocity = Vector3.new(0, Config.SpinSpeed, 0); spinBAV.Parent = hrp
end
local function stopSpinBot()
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
    if char and savedAnims.Animate then
        savedAnims.Animate:Clone().Parent = char; savedAnims.Animate = nil
    end
end

-- ──────────────────────────────────────────────────────────────
-- FLOAT (F key)
-- ──────────────────────────────────────────────────────────────
local function startFloat()
    if floatPlatform then floatPlatform:Destroy() end
    floatPlatform = Instance.new("Part")
    floatPlatform.Size = Vector3.new(6,1,6)
    floatPlatform.Anchored = true; floatPlatform.CanCollide = true
    floatPlatform.Transparency = 1; floatPlatform.Parent = workspace
    task.spawn(function()
        while floatPlatform and Toggles.Float do
            local hrp = getHRP()
            if hrp then floatPlatform.Position = hrp.Position - Vector3.new(0,3,0) end
            task.wait(0.05)
        end
    end)
end
local function stopFloat()
    if floatPlatform then floatPlatform:Destroy(); floatPlatform = nil end
end

-- ──────────────────────────────────────────────────────────────
-- BAT AIMBOT
-- ──────────────────────────────────────────────────────────────
local function findNearestEnemy()
    local hrp = getHRP(); if not hrp then return nil end
    local nearest, nearDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local eh = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 then
                local d = (eh.Position - hrp.Position).Magnitude
                if d < nearDist then nearDist = d; nearest = eh end
            end
        end
    end
    return nearest
end

local function findBat()
    local char = Player.Character; if not char then return nil end
    local bp = Player:FindFirstChildOfClass("Backpack")
    for _, ch in ipairs(char:GetChildren()) do
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
        end
    end
    return nil
end

local function startBatAimbot()
    if Connections.aimbot then return end
    Connections.aimbot = RunService.Heartbeat:Connect(function()
        if not Toggles.BatAimbot then return end
        local hrp = getHRP(); local hum = getHum(); if not hrp or not hum then return end
        local bat = findBat()
        if bat and bat.Parent ~= Player.Character then hum:EquipTool(bat) end
        local target = findNearestEnemy()
        if target then
            local dir = (target.Position - hrp.Position)
            local flat = Vector3.new(dir.X, 0, dir.Z)
            if flat.Magnitude > 1.5 then
                local md = flat.Unit
                hrp.AssemblyLinearVelocity = Vector3.new(md.X*55, hrp.AssemblyLinearVelocity.Y, md.Z*55)
            end
        end
    end)
end
local function stopBatAimbot()
    if Connections.aimbot then Connections.aimbot:Disconnect(); Connections.aimbot = nil end
end

-- ──────────────────────────────────────────────────────────────
-- AUTO LEFT / RIGHT
-- ──────────────────────────────────────────────────────────────
local POSITION_L1 = Vector3.new(-476.48, -6.28, 92.73)
local POSITION_L2 = Vector3.new(-483.12, -4.95, 94.80)
local POSITION_R1 = Vector3.new(-476.16, -6.52, 25.62)
local POSITION_R2 = Vector3.new(-483.04, -5.09, 23.14)

local autoLeftPhase = 1
local autoRightPhase = 1

local function startAutoLeft()
    if Connections.autoLeft then Connections.autoLeft:Disconnect() end
    autoLeftPhase = 1
    Connections.autoLeft = RunService.Heartbeat:Connect(function()
        if not Toggles.AutoLeft then return end
        local hrp = getHRP(); local hum = getHum(); if not hrp or not hum then return end
        local target = autoLeftPhase == 1 and POSITION_L1 or POSITION_L2
        local dist = (Vector3.new(target.X, hrp.Position.Y, target.Z) - hrp.Position).Magnitude
        if dist < 1.5 then
            if autoLeftPhase == 1 then autoLeftPhase = 2
            else
                hum:Move(Vector3.zero, false)
                hrp.AssemblyLinearVelocity = Vector3.zero
                Toggles.AutoLeft = false
                if Connections.autoLeft then Connections.autoLeft:Disconnect(); Connections.autoLeft = nil end
                return
            end
        end
        local d = (target - hrp.Position); local md = Vector3.new(d.X,0,d.Z).Unit
        hum:Move(md, false)
        hrp.AssemblyLinearVelocity = Vector3.new(md.X*Config.SpeedBoost, hrp.AssemblyLinearVelocity.Y, md.Z*Config.SpeedBoost)
    end)
end
local function stopAutoLeft()
    if Connections.autoLeft then Connections.autoLeft:Disconnect(); Connections.autoLeft = nil end
    local hum = getHum(); if hum then hum:Move(Vector3.zero, false) end
end

local function startAutoRight()
    if Connections.autoRight then Connections.autoRight:Disconnect() end
    autoRightPhase = 1
    Connections.autoRight = RunService.Heartbeat:Connect(function()
        if not Toggles.AutoRight then return end
        local hrp = getHRP(); local hum = getHum(); if not hrp or not hum then return end
        local target = autoRightPhase == 1 and POSITION_R1 or POSITION_R2
        local dist = (Vector3.new(target.X, hrp.Position.Y, target.Z) - hrp.Position).Magnitude
        if dist < 1.5 then
            if autoRightPhase == 1 then autoRightPhase = 2
            else
                hum:Move(Vector3.zero, false)
                hrp.AssemblyLinearVelocity = Vector3.zero
                Toggles.AutoRight = false
                if Connections.autoRight then Connections.autoRight:Disconnect(); Connections.autoRight = nil end
                return
            end
        end
        local d = (target - hrp.Position); local md = Vector3.new(d.X,0,d.Z).Unit
        hum:Move(md, false)
        hrp.AssemblyLinearVelocity = Vector3.new(md.X*Config.SpeedBoost, hrp.AssemblyLinearVelocity.Y, md.Z*Config.SpeedBoost)
    end)
end
local function stopAutoRight()
    if Connections.autoRight then Connections.autoRight:Disconnect(); Connections.autoRight = nil end
    local hum = getHum(); if hum then hum:Move(Vector3.zero, false) end
end

-- ──────────────────────────────────────────────────────────────
-- CARRY MODE
-- ──────────────────────────────────────────────────────────────
local function enableCarryMode()
    if Connections.carry then return end
    Connections.carry = RunService.Heartbeat:Connect(function()
        if not Toggles.CarryMode then return end
        if not Player:GetAttribute("Stealing") then return end
        local hrp = getHRP(); if not hrp then return end
        local md = getMoveDir()
        if md.Magnitude > 0.1 then
            hrp.AssemblyLinearVelocity = Vector3.new(md.X*Config.CarrySpeed, hrp.AssemblyLinearVelocity.Y, md.Z*Config.CarrySpeed)
        end
    end)
end
local function disableCarryMode()
    if Connections.carry then Connections.carry:Disconnect(); Connections.carry = nil end
end

-- ──────────────────────────────────────────────────────────────
-- FLOAT MODE (hover in air)
-- ──────────────────────────────────────────────────────────────
local floatConn = nil
local function enableFloatMode()
    if floatConn then return end
    local hrp = getHRP(); if not hrp then return end
    local anchor = hrp.Position
    floatConn = RunService.Heartbeat:Connect(function()
        if not Toggles.FloatMode then return end
        local h = getHRP(); if not h then return end
        h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X, 0, h.AssemblyLinearVelocity.Z)
        if math.abs(h.Position.Y - anchor.Y) > 1 then
            h.CFrame = CFrame.new(h.Position.X, anchor.Y, h.Position.Z)
        end
    end)
end
local function disableFloatMode()
    if floatConn then floatConn:Disconnect(); floatConn = nil end
end

-- ──────────────────────────────────────────────────────────────
-- DROP ANIMAL
-- ──────────────────────────────────────────────────────────────
local function dropAnimal()
    local char = Player.Character; if not char then return end
    local hum = getHum(); if not hum then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            hum:UnequipTools()
            break
        end
    end
end

-- ──────────────────────────────────────────────────────────────
-- GUI
-- ──────────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "AlazDuel"; sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = Player:FindFirstChildOfClass("PlayerGui") or Player.PlayerGui

local C = {
    bg      = Color3.fromRGB(255,255,255),
    card    = Color3.fromRGB(248,248,248),
    border  = Color3.fromRGB(220,220,220),
    text    = Color3.fromRGB(20,20,20),
    textDim = Color3.fromRGB(120,120,120),
    accent  = Color3.fromRGB(220,0,120),
    accentDk= Color3.fromRGB(170,0,90),
    toggleOn= Color3.fromRGB(220,0,120),
    toggleOf= Color3.fromRGB(200,200,200),
    white   = Color3.fromRGB(255,255,255),
    dark    = Color3.fromRGB(30,10,20),
}

-- MAIN FRAME (side panel like screenshot)
local main = Instance.new("Frame", sg)
main.Name = "Main"
main.Size = UDim2.new(0,200,0,700)
main.Position = UDim2.new(1,-210,0.5,-350)
main.BackgroundColor3 = Color3.fromRGB(20,5,15)
main.BackgroundTransparency = 0.1
main.BorderSizePixel = 0
main.Active = true; main.Draggable = true
main.ClipsDescendants = true; main.ZIndex = 10
Instance.new("UICorner",main).CornerRadius = UDim.new(0,14)
local ms = Instance.new("UIStroke",main); ms.Color=Color3.fromRGB(180,0,100); ms.Thickness=1.5

-- TITLE
local titleBar = Instance.new("Frame",main)
titleBar.Size = UDim2.new(1,0,0,55); titleBar.BackgroundTransparency=1; titleBar.ZIndex=11

local titleLbl = Instance.new("TextLabel",titleBar)
titleLbl.Size = UDim2.new(1,0,1,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "ALAZ DUEL"
titleLbl.TextColor3 = C.accent
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 20
titleLbl.TextXAlignment = Enum.TextXAlignment.Center
titleLbl.ZIndex = 12

-- CLOSE BUTTON
local closeBtn = Instance.new("TextButton",titleBar)
closeBtn.Size = UDim2.new(0,28,0,28); closeBtn.Position = UDim2.new(1,-34,0.5,-14)
closeBtn.BackgroundColor3 = C.accentDk; closeBtn.Text = "✕"
closeBtn.TextColor3 = C.white; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 13
closeBtn.BorderSizePixel = 0; closeBtn.ZIndex = 13
Instance.new("UICorner",closeBtn).CornerRadius = UDim.new(1,0)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

-- SCROLL
local scroll = Instance.new("ScrollingFrame",main)
scroll.Size = UDim2.new(1,0,1,-60); scroll.Position = UDim2.new(0,0,0,58)
scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3; scroll.ScrollBarImageColor3 = C.accent
scroll.CanvasSize = UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 11

local listLayout = Instance.new("UIListLayout",scroll)
listLayout.Padding = UDim.new(0,8); listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local uiPad = Instance.new("UIPadding",scroll)
uiPad.PaddingTop = UDim.new(0,8); uiPad.PaddingBottom = UDim.new(0,8)
uiPad.PaddingLeft = UDim.new(0,8); uiPad.PaddingRight = UDim.new(0,8)

local itemOrder = 0
local function nextOrder() itemOrder=itemOrder+1; return itemOrder end

-- SECTION HEADER
local function mkSection(text)
    local lbl = Instance.new("TextLabel",scroll)
    lbl.Size = UDim2.new(1,0,0,22); lbl.BackgroundTransparency=1
    lbl.Text = text; lbl.TextColor3 = C.textDim
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 12; lbl.LayoutOrder = nextOrder()
end

-- SLIDER FACTORY (like screenshot style)
local function mkSlider(title, configKey, mn, mx, cb)
    local cont = Instance.new("Frame",scroll)
    cont.Size = UDim2.new(1,0,0,58); cont.BackgroundTransparency=1
    cont.BorderSizePixel=0; cont.ZIndex=12; cont.LayoutOrder=nextOrder()

    local tl = Instance.new("TextLabel",cont)
    tl.Size=UDim2.new(1,-60,0,20); tl.Position=UDim2.new(0,0,0,0)
    tl.BackgroundTransparency=1; tl.Text=title
    tl.TextColor3=C.white; tl.Font=Enum.Font.GothamBold; tl.TextSize=13
    tl.TextXAlignment=Enum.TextXAlignment.Left; tl.ZIndex=13

    local valLbl = Instance.new("TextLabel",cont)
    valLbl.Size=UDim2.new(0,55,0,20); valLbl.Position=UDim2.new(1,-55,0,0)
    valLbl.BackgroundTransparency=1; valLbl.Text=tostring(Config[configKey])
    valLbl.TextColor3=C.accent; valLbl.Font=Enum.Font.GothamBold; valLbl.TextSize=13
    valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.ZIndex=13

    local track = Instance.new("Frame",cont)
    track.Size=UDim2.new(1,0,0,6); track.Position=UDim2.new(0,0,0,32)
    track.BackgroundColor3=Color3.fromRGB(60,20,40); track.BorderSizePixel=0; track.ZIndex=12
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)

    local defPct=(Config[configKey]-mn)/(mx-mn)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new(defPct,0,1,0); fill.BackgroundColor3=C.accent
    fill.BorderSizePixel=0; fill.ZIndex=13
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)

    local thumb=Instance.new("Frame",track)
    thumb.Size=UDim2.new(0,14,0,14); thumb.Position=UDim2.new(defPct,-7,0.5,-7)
    thumb.BackgroundColor3=C.white; thumb.BorderSizePixel=0; thumb.ZIndex=14
    Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)

    local sBtn=Instance.new("TextButton",track)
    sBtn.Size=UDim2.new(1,0,4,0); sBtn.Position=UDim2.new(0,0,-1.5,0)
    sBtn.BackgroundTransparency=1; sBtn.Text=""; sBtn.ZIndex=15

    local dragging=false
    local function upd(rel)
        rel=math.clamp(rel,0,1)
        fill.Size=UDim2.new(rel,0,1,0); thumb.Position=UDim2.new(rel,-7,0.5,-7)
        local val=math.floor((mn+(mx-mn)*rel)*10)/10
        valLbl.Text=tostring(val); Config[configKey]=val
        if cb then cb(val) end
    end
    sBtn.MouseButton1Down:Connect(function() dragging=true end)
    UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            upd((inp.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X)
        end
    end)
    return cont
end

-- TOGGLE FACTORY (like screenshot - full width card with toggle on right)
local function mkToggle(title, toggleKey, keybind, cb)
    local cont = Instance.new("Frame",scroll)
    cont.Size=UDim2.new(1,0,0,52); cont.BackgroundColor3=Color3.fromRGB(40,10,30)
    cont.BackgroundTransparency=0.3; cont.BorderSizePixel=0; cont.ZIndex=12
    cont.LayoutOrder=nextOrder()
    Instance.new("UICorner",cont).CornerRadius=UDim.new(0,10)

    -- Keybind label
    if keybind then
        local kbl=Instance.new("TextLabel",cont)
        kbl.Size=UDim2.new(0,28,0,28); kbl.Position=UDim2.new(0,8,0.5,-14)
        kbl.BackgroundColor3=Color3.fromRGB(60,20,50); kbl.BackgroundTransparency=0
        kbl.Text=keybind; kbl.TextColor3=C.accent; kbl.Font=Enum.Font.GothamBold
        kbl.TextSize=12; kbl.BorderSizePixel=0; kbl.ZIndex=13
        Instance.new("UICorner",kbl).CornerRadius=UDim.new(0,6)
    end

    local tl=Instance.new("TextLabel",cont)
    local xOff = keybind and 44 or 12
    tl.Size=UDim2.new(1,-90,1,0); tl.Position=UDim2.new(0,xOff,0,0)
    tl.BackgroundTransparency=1; tl.Text=title
    tl.TextColor3=C.accent; tl.Font=Enum.Font.GothamBlack; tl.TextSize=13
    tl.TextXAlignment=Enum.TextXAlignment.Left; tl.ZIndex=13

    local defOn=Toggles[toggleKey] or false
    local tb=Instance.new("Frame",cont)
    tb.Size=UDim2.new(0,46,0,22); tb.Position=UDim2.new(1,-54,0.5,-11)
    tb.BackgroundColor3=defOn and C.toggleOn or C.toggleOf; tb.BorderSizePixel=0; tb.ZIndex=13
    Instance.new("UICorner",tb).CornerRadius=UDim.new(1,0)

    local knob=Instance.new("Frame",tb)
    knob.Size=UDim2.new(0,17,0,17)
    knob.Position=defOn and UDim2.new(1,-20,0.5,-8.5) or UDim2.new(0,3,0.5,-8.5)
    knob.BackgroundColor3=C.white; knob.BorderSizePixel=0; knob.ZIndex=14
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local clk=Instance.new("TextButton",cont)
    clk.Size=UDim2.new(1,0,1,0); clk.BackgroundTransparency=1; clk.Text=""; clk.ZIndex=15

    local isOn=defOn
    clk.MouseButton1Click:Connect(function()
        isOn=not isOn; Toggles[toggleKey]=isOn
        TweenService:Create(tb,TweenInfo.new(0.2),{BackgroundColor3=isOn and C.toggleOn or C.toggleOf}):Play()
        TweenService:Create(knob,TweenInfo.new(0.2,Enum.EasingStyle.Back),{Position=isOn and UDim2.new(1,-20,0.5,-8.5) or UDim2.new(0,3,0.5,-8.5)}):Play()
        if cb then cb(isOn) end
    end)
    return cont
end

-- ACTION BUTTON FACTORY
local function mkActionBtn(title, subtitle, cb)
    local cont=Instance.new("TextButton",scroll)
    cont.Size=UDim2.new(1,0,0,62); cont.BackgroundColor3=Color3.fromRGB(40,10,30)
    cont.BackgroundTransparency=0.3; cont.BorderSizePixel=0; cont.Text=""; cont.ZIndex=12
    cont.LayoutOrder=nextOrder()
    Instance.new("UICorner",cont).CornerRadius=UDim.new(0,10)

    local tl=Instance.new("TextLabel",cont)
    tl.Size=UDim2.new(1,0,0.5,0); tl.Position=UDim2.new(0,0,0.1,0)
    tl.BackgroundTransparency=1; tl.Text=title
    tl.TextColor3=C.accent; tl.Font=Enum.Font.GothamBlack; tl.TextSize=14
    tl.TextXAlignment=Enum.TextXAlignment.Center; tl.ZIndex=13

    if subtitle then
        local sl=Instance.new("TextLabel",cont)
        sl.Size=UDim2.new(1,0,0.4,0); sl.Position=UDim2.new(0,0,0.55,0)
        sl.BackgroundTransparency=1; sl.Text=subtitle
        sl.TextColor3=C.accent; sl.Font=Enum.Font.GothamBold; sl.TextSize=12
        sl.TextXAlignment=Enum.TextXAlignment.Center; sl.ZIndex=13
    end

    cont.MouseButton1Click:Connect(cb)
    cont.MouseEnter:Connect(function() TweenService:Create(cont,TweenInfo.new(0.15),{BackgroundTransparency=0.1}):Play() end)
    cont.MouseLeave:Connect(function() TweenService:Create(cont,TweenInfo.new(0.15),{BackgroundTransparency=0.3}):Play() end)
    return cont
end

-- ──────────────────────────────────────────────────────────────
-- POPULATE GUI
-- ──────────────────────────────────────────────────────────────

-- SPEED SECTION
mkSection("SPEED")
mkSlider("Speed Boost", "SpeedBoost", 0, 120, function(v)
    Config.SpeedBoost = v
end)
mkSlider("Carry Speed", "CarrySpeed", 0, 60, function(v)
    Config.CarrySpeed = v
end)

-- MOVEMENT SECTION
mkSection("MOVEMENT")
mkToggle("Void Mode", "VoidMode", nil, function(s)
    if s then enableVoidMode() else disableVoidMode() end
end)
mkSlider("Hop Power", "HopPower", 0, 150, function(v) Config.HopPower = v end)
mkSlider("Gravity", "Gravity", 10, 150, function(v)
    Config.Gravity = v
    updateGravity()
end)
mkToggle("Spin Bot", "SpinBot", nil, function(s)
    if s then startSpinBot() else stopSpinBot() end
end)
mkSlider("Spin Speed", "SpinSpeed", 0, 80, function(v)
    Config.SpinSpeed = v
    if spinBAV then spinBAV.AngularVelocity = Vector3.new(0, v, 0) end
end)
mkToggle("Unwalk", "Unwalk", nil, function(s)
    if s then startUnwalk() else stopUnwalk() end
end)
mkToggle("Float", "Float", "F", function(s)
    if s then startFloat() else stopFloat() end
end)

-- COMBAT SECTION
mkSection("COMBAT")
mkToggle("BAT AIMBOT", "BatAimbot", nil, function(s)
    if s then startBatAimbot() else stopBatAimbot() end
end)
mkToggle("AUTO LEFT", "AutoLeft", nil, function(s)
    if s then startAutoLeft() else stopAutoLeft() end
end)
mkToggle("AUTO RIGHT", "AutoRight", nil, function(s)
    if s then startAutoRight() else stopAutoRight() end
end)
mkToggle("CARRY MODE", "CarryMode", nil, function(s)
    if s then enableCarryMode() else disableCarryMode() end
end)
mkToggle("FLOAT MODE", "FloatMode", nil, function(s)
    if s then
        local hrp = getHRP()
        if hrp then
            -- save anchor Y
            enableFloatMode()
        end
    else
        disableFloatMode()
    end
end)
mkActionBtn("DROP", "ANIMAL", function()
    dropAnimal()
end)

-- ──────────────────────────────────────────────────────────────
-- MINI TOGGLE BUTTON
-- ──────────────────────────────────────────────────────────────
local miniBtn = Instance.new("TextButton",sg)
miniBtn.Size = UDim2.new(0,50,0,50); miniBtn.Position = UDim2.new(1,-215,0.5,-25)
miniBtn.BackgroundColor3 = Color3.fromRGB(30,10,20); miniBtn.BackgroundTransparency=0.2
miniBtn.Text = "S"; miniBtn.TextColor3 = C.accent
miniBtn.Font = Enum.Font.GothamBlack; miniBtn.TextSize = 24
miniBtn.ZIndex = 999; miniBtn.BorderSizePixel = 0
Instance.new("UICorner",miniBtn).CornerRadius = UDim.new(0,12)
local mbS = Instance.new("UIStroke",miniBtn); mbS.Color=C.accent; mbS.Thickness=2

miniBtn.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible; main.Visible = guiVisible
end)

-- ──────────────────────────────────────────────────────────────
-- INPUT HANDLER
-- ──────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.U then
        guiVisible = not guiVisible; main.Visible = guiVisible
    end
    if inp.KeyCode == KEYBINDS.Float then
        Toggles.Float = not Toggles.Float
        if Toggles.Float then startFloat() else stopFloat() end
    end
end)

-- ──────────────────────────────────────────────────────────────
-- GRAVITY LOOP
-- ──────────────────────────────────────────────────────────────
task.spawn(function()
    task.wait(1)
    setupGravity()
    RunService.Heartbeat:Connect(function()
        updateGravity()
    end)
end)

-- ──────────────────────────────────────────────────────────────
-- RESPAWN
-- ──────────────────────────────────────────────────────────────
Player.CharacterAdded:Connect(function()
    task.wait(1)
    setupGravity()
    if Toggles.SpinBot     then stopSpinBot();     task.wait(0.1); startSpinBot()     end
    if Toggles.BatAimbot   then stopBatAimbot();   task.wait(0.1); startBatAimbot()   end
    if Toggles.Float       then startFloat()                                           end
    if Toggles.VoidMode    then enableVoidMode()                                       end
    if Toggles.Unwalk      then startUnwalk()                                          end
end)

print("⚔ ALAZ DUEL Loaded! discord.gg/U4XXCxKUm  |  U = Toggle")
