--[[
    Bootayware (Mobile Support)
    Load with:
    loadstring(game:HttpGet("https://YOUR-URL-HERE"))()
]]

local LocalPlayer = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================================
-- Load UI Library
-- ============================================================
local uiLoader = loadstring(game:HttpGet('https://raw.githubusercontent.com/topitbopit/dollarware/main/library.lua'))
local ui = uiLoader({
    rounding = true,
    theme = 'cherry',
    smoothDragging = true
})

ui.autoDisableToggles = true

-- ============================================================
-- Main Window
-- ============================================================
local mainWindow = ui.newWindow({
    text = 'Bootayware',
    resize = true,
    size = isMobile and Vector2.new(340, 260) or Vector2.new(550, 400)
})

-- Helper: hotkey on PC, tap button on mobile
local function bindHotkey(section, toggle, key, tooltip, mobileButtonText)
    if not isMobile then
        local hk = section:addHotkey({ text = (mobileButtonText or 'Hotkey') .. ' Hotkey' })
        hk:setHotkey(key)
        hk:setTooltip(tooltip or 'Press this key to toggle!')
        hk:linkToControl(toggle)
    else
        section:addButton({ text = (mobileButtonText or 'Toggle') .. ' (Tap)' }, function()
            local newState = not toggle:get()
            toggle:set(newState)
            pcall(function() toggle:Fire('onToggle', newState) end)
        end):setTooltip('Mobile tap toggles ' .. (mobileButtonText or ''))
    end
end

-- ============================================================
-- Player Menu
-- ============================================================
local playerMenu = mainWindow:addMenu({ text = 'Player' })

-- Silent Aim
local silentAimSection = playerMenu:addSection({ text = 'Silent Aim' })
local silentAimEnabled = false

local silentAimToggle = silentAimSection:addToggle({ text = 'Silent Aim', state = false })
silentAimToggle:bindToEvent('onToggle', function(state)
    silentAimEnabled = state
    ui.notify({ title = 'Silent Aim', message = state and 'Enabled' or 'Disabled', duration = 3 })
end)

local aimStrength = 50
silentAimSection:addSlider({ text = 'Aim Strength', min = 1, max = 100, step = 1, val = aimStrength }, function(v)
    aimStrength = v
end)

silentAimSection:addToggle({ text = 'Auto Curve' }, function(state)
    ui.notify({ title = 'Auto Curve', message = state and 'Enabled' or 'Disabled' })
end)

-- Silent Aim FOV
local fovSection = playerMenu:addSection({ text = 'Silent Aim FOV' })
local fovEnabled = false
local fovRadius = 50

local fovToggle = fovSection:addToggle({ text = 'Enable FOV', state = false })
fovToggle:bindToEvent('onToggle', function(state) fovEnabled = state end)

fovSection:addSlider({ text = 'FOV Size', min = 1, max = 100, step = 1, val = fovRadius }, function(v)
    fovRadius = v
end)

local fovCircle = Drawing.new('Circle')
fovCircle.Thickness = 2
fovCircle.NumSides = 50
fovCircle.Radius = fovRadius
fovCircle.Visible = false

local function getAimPoint()
    local pos = UserInputService:GetMouseLocation()
    if pos and pos.Magnitude > 0 then return pos end
    local cam = workspace.CurrentCamera
    return Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
end

local function isFOVNearDefensiveHitbox()
    local aimPoint = getAimPoint()
    for _, player in pairs(game:GetService('Players'):GetPlayers()) do
        if player.Character then
            local hitbox = player.Character:FindFirstChild("DefensiveHitbox")
            if hitbox then
                local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hitbox.Position)
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - aimPoint).Magnitude
                if distance < fovRadius and onScreen then return true end
            end
        end
    end
    return false
end

RunService.RenderStepped:Connect(function()
    if fovEnabled then
        fovCircle.Position = getAimPoint()
        fovCircle.Radius = fovRadius
        fovCircle.Visible = true
        fovCircle.Color = isFOVNearDefensiveHitbox() and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
    else
        fovCircle.Visible = false
    end
end)

-- Ball Teleport
local ballTeleportSection = playerMenu:addSection({ text = 'Ball Teleport' })
local ballTeleportEnabled = false
local ballTeleportRange = 5
local ballTeleportConnection

local function handleBallTeleport()
    local lp = game.Players.LocalPlayer
    local ball = game.Workspace:FindFirstChild("ball")
    if not ball then
        ui.notify({ title = 'Ball Teleport', message = 'Ball not found in Workspace!', duration = 3 })
        ballTeleportEnabled = false
        return
    end
    while ballTeleportEnabled do
        local character = lp.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        ball = game.Workspace:FindFirstChild("Ball")
        if ball and character and rootPart then
            rootPart.CFrame = CFrame.new(ball.Position + Vector3.new(ballTeleportRange, 0, 0))
        else
            ui.notify({ title = 'Ball Teleport', message = 'Ball or character not found! Disabling.', duration = 3 })
            ballTeleportEnabled = false
            ballTeleportToggle:set(false)
            break
        end
        RunService.Heartbeat:Wait()
    end
end

local ballTeleportToggle = ballTeleportSection:addToggle({ text = 'Enable Ball Teleport', state = false })
ballTeleportToggle:bindToEvent('onToggle', function(state)
    ballTeleportEnabled = state
    if state then
        if not ballTeleportConnection then ballTeleportConnection = task.spawn(handleBallTeleport) end
        ui.notify({ title = 'Ball Teleport', message = 'Enabled', duration = 3 })
    else
        if ballTeleportConnection then task.cancel(ballTeleportConnection); ballTeleportConnection = nil end
        ui.notify({ title = 'Ball Teleport', message = 'Disabled', duration = 3 })
    end
end):setTooltip('Loop teleport to the ball with a set range')

ballTeleportSection:addSlider({ text = 'Teleport Range', min = 1, max = 20, step = 0.5, val = ballTeleportRange }, function(v)
    ballTeleportRange = v
end)

bindHotkey(ballTeleportSection, ballTeleportToggle, Enum.KeyCode.B, 'Toggle Ball Teleport!', 'Ball Teleport')

game.Players.LocalPlayer.CharacterAdded:Connect(function()
    if ballTeleportEnabled then
        task.wait(1)
        if ballTeleportConnection then task.cancel(ballTeleportConnection); ballTeleportConnection = nil end
        ballTeleportConnection = task.spawn(handleBallTeleport)
    end
end)

-- Team Change
local teamChangeSection = playerMenu:addSection({ text = 'Team Change' })
local function changeTeam(teamColor, role)
    local success, err = pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TeamChange"):FireServer(BrickColor.new(teamColor), role)
    end)
    if success then
        ui.notify({ title = 'Team Change', message = 'Changed to ' .. role, duration = 3 })
    else
        ui.notify({ title = 'Team Change', message = 'Failed: ' .. tostring(err), duration = 5 })
    end
end
teamChangeSection:addButton({ text = 'Right Player' }, function() changeTeam(141, "Player") end)
teamChangeSection:addButton({ text = 'Right Goalie' }, function() changeTeam(141, "Goalie") end)
teamChangeSection:addButton({ text = 'Left Player' }, function() changeTeam(23, "Player") end)
teamChangeSection:addButton({ text = 'Left Goalie' }, function() changeTeam(23, "Goalie") end)

-- Speed (TP Walk)
local speedSection = playerMenu:addSection({ text = 'Speed' })
do
    local tpWalkEnabled = false
    local tpWalkSpeed = 0.1
    local tpWalkConnection

    local function handleTPWalk()
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not (character and humanoid and rootPart) then return end
        while tpWalkEnabled do
            local delta = RunService.Heartbeat:Wait()
            if humanoid.MoveDirection.Magnitude > 0 then
                rootPart.CFrame = rootPart.CFrame + humanoid.MoveDirection * tpWalkSpeed * 10 * delta
            end
            task.wait()
        end
    end

    local tpWalkToggle = speedSection:addToggle({ text = 'TP Walk', state = false })
    tpWalkToggle:bindToEvent('onToggle', function(state)
        tpWalkEnabled = state
        if state then
            if not tpWalkConnection then tpWalkConnection = task.spawn(handleTPWalk) end
            ui.notify({ title = 'TP Walk', message = 'Enabled', duration = 3 })
        else
            if tpWalkConnection then task.cancel(tpWalkConnection); tpWalkConnection = nil end
            ui.notify({ title = 'TP Walk', message = 'Disabled', duration = 3 })
        end
    end)

    speedSection:addSlider({ text = 'TP Walk Speed', min = 0.1, max = 2, step = 0.1, val = tpWalkSpeed }, function(v)
        tpWalkSpeed = v
    end)

    bindHotkey(speedSection, tpWalkToggle, Enum.KeyCode.F, 'Toggle TP Walk!', 'TP Walk')
end

-- FOV Camera
local camFovSection = playerMenu:addSection({ text = 'FOV' })
local fovValue = 90
local camera = workspace.CurrentCamera
camFovSection:addSlider({ text = 'Field of View', min = 90, max = 200, step = 1, val = fovValue }, function(v) fovValue = v end)
RunService.Heartbeat:Connect(function() camera.FieldOfView = fovValue end)

-- Lag Switch
local lagSwitchSection = playerMenu:addSection({ text = 'Lag Switch' })
local lagEnabled = false
local seatHolder, vehicleSeat, weld, lagConnection, animate

local function createSeat()
    local character = game.Players.LocalPlayer.Character
    if not character then return end
    local hrp = character:WaitForChild("HumanoidRootPart")
    seatHolder = Instance.new("Part")
    seatHolder.Name = "SeatHolder"
    seatHolder.Size = Vector3.new(1.5, 1.5, 1.5)
    seatHolder.Position = hrp.Position + Vector3.new(0, 5, 0)
    seatHolder.Anchored = true
    seatHolder.CanCollide = false
    seatHolder.Transparency = 1
    seatHolder.Parent = workspace
    vehicleSeat = Instance.new("VehicleSeat")
    vehicleSeat.Name = "SeatObject"
    vehicleSeat.Parent = seatHolder
    vehicleSeat.Position = seatHolder.Position + Vector3.new(0, 1, 0)
    vehicleSeat.CanCollide = false
    vehicleSeat.Transparency = 1
    weld = Instance.new("Weld")
    weld.Part0 = hrp
    weld.Part1 = vehicleSeat
    weld.Parent = vehicleSeat
end

local function removeSeat()
    if weld then weld:Destroy() end
    if vehicleSeat then vehicleSeat:Destroy() end
    if seatHolder then seatHolder:Destroy() end
    weld, vehicleSeat, seatHolder = nil, nil, nil
end

local function toggleLag(state)
    lagEnabled = state
    local character = game.Players.LocalPlayer.Character
    if lagEnabled then
        if character then
            createSeat()
            lagConnection = RunService.Heartbeat:Connect(function()
                for _ = 1, 500 do workspace:FindFirstChild("NonExistentObject") end
            end)
            animate = character:FindFirstChild("Animate")
            if animate then animate.Parent = nil end
        end
        ui.notify({ title = 'Lag Switch', message = 'Activated', duration = 3 })
    else
        if lagConnection then lagConnection:Disconnect(); lagConnection = nil end
        removeSeat()
        if character and animate then animate.Parent = character end
        ui.notify({ title = 'Lag Switch', message = 'Deactivated', duration = 3 })
    end
end

local lagSwitchToggle = lagSwitchSection:addToggle({ text = 'Enable Lag Switch', state = false })
lagSwitchToggle:bindToEvent('onToggle', function(state) toggleLag(state) end)
bindHotkey(lagSwitchSection, lagSwitchToggle, Enum.KeyCode.T, 'Toggle Lag Switch!', 'Lag Switch')

game.Players.LocalPlayer.CharacterAdded:Connect(function()
    if lagEnabled then toggleLag(false); task.wait(1); toggleLag(true) end
end)

-- Ball (Fling)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local hiddenfling = false
local flingThread
local flingPower = 1

if not ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok") then
    local detection = Instance.new("Decal")
    detection.Name = "juisdfj0i32i0eidsuf0iok"
    detection.Parent = ReplicatedStorage
end

local function fling()
    local lp = Players.LocalPlayer
    local c, hrp, vel, movel = nil, nil, nil, 0.1
    while hiddenfling do
        RunService.Heartbeat:Wait()
        c = lp.Character
        hrp = c and c:FindFirstChild("HumanoidRootPart")
        if hrp then
            vel = hrp.Velocity
            hrp.Velocity = vel * flingPower + hrp.CFrame.LookVector * (flingPower * 1000)
            RunService.RenderStepped:Wait()
            hrp.Velocity = vel
            RunService.Stepped:Wait()
            hrp.Velocity = vel + Vector3.new(0, movel, 0)
            movel = -movel
        end
    end
end

local flingSection = playerMenu:addSection({ text = 'Ball' })
local flingToggle = flingSection:addToggle({ text = 'Ball Timeskip', state = false })
flingToggle:bindToEvent('onToggle', function(state)
    hiddenfling = state
    if hiddenfling then
        flingThread = coroutine.create(fling)
        coroutine.resume(flingThread)
    end
    ui.notify({ title = 'Ball Timeskip', message = state and 'Enabled' or 'Disabled', duration = 3 })
end)
flingSection:addSlider({ text = 'Timeskip Power', min = 1, max = 9.5, step = 0.1, val = flingPower }, function(v) flingPower = v end)
bindHotkey(flingSection, flingToggle, Enum.KeyCode.G, 'Toggle Ball Timeskip!', 'Ball Timeskip')

-- Snitch Detector
local snitchSection = playerMenu:addSection({ text = 'Snitch Detector' })
local snitchEnabled = false
local detectedSnitches = {}
local snitchList = { 'love', 'gerdmulla', 'IsXboxMan', 'DragonMaaz360' }

local function createBillboard(player)
    local character = player.Character
    if character and not character:FindFirstChild('SnitchBillboard') then
        local billboard = Instance.new('BillboardGui')
        billboard.Name = 'SnitchBillboard'
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.AlwaysOnTop = true
        local textLabel = Instance.new('TextLabel', billboard)
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.Text = 'Snitch'
        textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextScaled = true
        billboard.Parent = character:FindFirstChild('Head') or character.PrimaryPart
    end
end

local function checkForSnitches()
    if not snitchEnabled then return end
    for _, player in ipairs(game.Players:GetPlayers()) do
        if table.find(snitchList, player.Name) and not detectedSnitches[player] then
            detectedSnitches[player] = true
            ui.notify({ title = 'Snitch Detector', message = 'Warning: suspected snitch in server.', duration = 5 })
            createBillboard(player)
        end
    end
end

game.Players.PlayerAdded:Connect(checkForSnitches)
game.Players.PlayerRemoving:Connect(function(player) detectedSnitches[player] = nil end)

snitchSection:addToggle({ text = 'Enable Snitch Detector', state = false }, function(state)
    snitchEnabled = state
    if not state then
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player.Character then
                local b = player.Character:FindFirstChild('SnitchBillboard')
                if b then b:Destroy() end
            end
        end
        detectedSnitches = {}
    else
        checkForSnitches()
    end
end)

-- ============================================================
-- Miscellaneous Menu
-- ============================================================
local miscMenu = mainWindow:addMenu({ text = 'Miscellaneous' })

-- ============================================================
-- Fun Menu
-- ============================================================
local funMenu = mainWindow:addMenu({ text = 'Fun' })
local animationsSection = funMenu:addSection({ text = 'Animations' })

local movesSection = funMenu:addSection({ text = 'Movesets' })
movesSection:addButton({ text = 'Karate' }, function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/obamajoepoop/rssware/refs/heads/main/karate'))()
end)
movesSection:addButton({ text = 'Reach (R)' }, function()
    loadstring(game:HttpGet('https://pastefy.app/oUJmtM8K/raw'))()
end)

local animationList = { "Antony Spin", "Ball Hop", "Cruyff Turn", "Elastico", "Jump Deke", "Rainbow Flick", "Ronaldo Chop", "Sombrero Flick", "Spin", "StepOver" }
for _, animName in pairs(animationList) do
    animationsSection:addButton({ text = animName }, function()
        local character = LocalPlayer.Character
        if character then
            local animTrack = game:GetService("ReplicatedStorage").Animations.Dribble:FindFirstChild(animName)
            if animTrack then
                local humanoid = character:FindFirstChild("Humanoid")
                local animator = humanoid and humanoid:FindFirstChild("Animator")
                if animator then animator:LoadAnimation(animTrack):Play() end
            end
        end
    end)
end

local unreleasedSection = funMenu:addSection({ text = 'Unreleased Animations' })
unreleasedSection:addButton({ text = 'Content Creator Dribble' }, function()
    loadstring(game:HttpGet("https://pastebin.com/raw/bnQdzYaf"))()
end)
unreleasedSection:addButton({ text = 'Twist Flip' }, function()
    local character = LocalPlayer.Character
    if character then
        local animTrack = game:GetService("ReplicatedStorage").Animations.Dribble:FindFirstChild("Twist Flip")
        if animTrack then
            local humanoid = character:FindFirstChild("Humanoid")
            local animator = humanoid and humanoid:FindFirstChild("Animator")
            if animator then animator:LoadAnimation(animTrack):Play() end
        end
    end
end)

local othersSection = funMenu:addSection({ text = 'Others' })
othersSection:addButton({ text = 'Infinite Yield' }, function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end)
othersSection:addButton({ text = 'Cursing Script (SERVER FOR TUT)' }, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/AnnaRoblox/AnnaBypasser/refs/heads/main/AnnaBypasser.lua",true))()
end)

-- Shots
local Shots = playerMenu:addSection({ text = 'Shots' })
local backupAnimation = nil
Shots:addButton({ text = 'Instant Shot' }, function()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    if LocalPlayer.Character then
        local animations = replicatedStorage:FindFirstChild("Animations")
        local animToDelete = animations and animations:FindFirstChild("ChargeShot")
        if animToDelete then
            if not backupAnimation then backupAnimation = animToDelete:Clone() end
            animToDelete:Destroy()
            ui.notify({ title = 'Instant Shot', message = 'Enabled! Execute in-game, not lobby.', duration = 3 })
            LocalPlayer.CharacterAdded:Connect(function()
                if backupAnimation and animations and not animations:FindFirstChild("ChargeShot") then
                    backupAnimation:Clone().Parent = animations
                end
            end)
        else
            ui.notify({ title = 'Instant Shot', message = 'Already Enabled', duration = 7 })
        end
    end
end)

othersSection:addButton({ text = 'Power Shooting Icon' }, function()
    local boolPath = workspace:FindFirstChild(LocalPlayer.Name) and workspace[LocalPlayer.Name]:FindFirstChild("Bools")
    if boolPath and boolPath:FindFirstChild("PowerShooting") then
        boolPath.PowerShooting.Value = true
        ui.notify({ title = 'Power Shot Icon', message = 'Enabled', duration = 3 })
    end
end)
othersSection:addButton({ text = 'VIP Icon' }, function()
    local boolPath = workspace:FindFirstChild(LocalPlayer.Name) and workspace[LocalPlayer.Name]:FindFirstChild("Bools")
    if boolPath and boolPath:FindFirstChild("VIP") then
        boolPath.VIP.Value = true
        ui.notify({ title = 'VIP', message = 'Enabled', duration = 3 })
    end
end)

-- ============================================================
-- Dances Menu
-- ============================================================
local danceMenu = mainWindow:addMenu({ text = 'Dances' })
local celebrationsSection = danceMenu:addSection({ text = 'Celebrations' })

local celebrationList = { "Arm Spread", "Backflip", "Brazil Dance", "Electro Shuffle", "Floss", "Griddy", "Hype Dance", "Knee Slide", "Orange Justice", "Silly Dance", "Sui", "Take The L" }
local currentAnimationTrack
local animationSpeed = 1

for _, animName in pairs(celebrationList) do
    celebrationsSection:addButton({ text = animName }, function()
        local character = LocalPlayer.Character
        if character then
            local animTrack = game:GetService("ReplicatedStorage").Animations.Celebration:FindFirstChild(animName)
            if animTrack then
                local humanoid = character:FindFirstChild("Humanoid")
                local animator = humanoid and humanoid:FindFirstChild("Animator")
                if animator then
                    if currentAnimationTrack then currentAnimationTrack:Stop() end
                    currentAnimationTrack = animator:LoadAnimation(animTrack)
                    currentAnimationTrack:Play()
                    currentAnimationTrack:AdjustSpeed(animationSpeed)
                end
            end
        end
    end)
end

celebrationsSection:addButton({ text = "Stop Animation" }, function()
    if currentAnimationTrack then currentAnimationTrack:Stop(); currentAnimationTrack = nil end
end)

celebrationsSection:addSlider({ text = "Animation Speed", min = 0.1, max = 2, initial = 1 }, function(v)
    animationSpeed = v
    if currentAnimationTrack then currentAnimationTrack:AdjustSpeed(animationSpeed) end
end)

-- ============================================================
-- Teleports Menu
-- ============================================================
local TeleportService = game:GetService("TeleportService")
local currentPlaceId = game.PlaceId
local teleportsMenu = mainWindow:addMenu({ text = 'Teleports' })
local teleportsSection = teleportsMenu:addSection({ text = 'Teleport Options' })

if currentPlaceId ~= 16071359275 then teleportsSection:addButton({ text = '7V7 Servers' }, function() TeleportService:Teleport(16071359275) end) end
if currentPlaceId ~= 16213033715 then teleportsSection:addButton({ text = '7V7 Pro Servers' }, function() TeleportService:Teleport(16213033715) end) end
if currentPlaceId ~= 14315258385 then teleportsSection:addButton({ text = '4V4 Servers' }, function() TeleportService:Teleport(14315258385) end) end
if currentPlaceId ~= 15266870117 then teleportsSection:addButton({ text = '4V4 Pro Servers' }, function() TeleportService:Teleport(15266870117) end) end

ui.notify({
    title = 'Bootayware Loaded!' .. (isMobile and ' (Mobile)' or ''),
    message = '',
    duration = 3
})