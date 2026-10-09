-- MAIN SCRIPT FOR DONKEY'S MAIN SCRIPT --
-- By Earl Donkey


-- Prevent running outside Roblox
if not game or not workspace or not game.Players then
    while true do end
end

-- Optional: stop decompilers
local debugInfo = debug.getinfo
if not debugInfo then
    while true do end
end

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
	Players.PlayerAdded:Wait()
	LocalPlayer = Players.LocalPlayer
end

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Settings
local ESPEnabled = false
local AimlockEnabled = false
local AimlockDistance = 200
local AimlockFOV = 90
local NoclipEnabled = false
local NoclipSpeed = 50
local FlyEnabled = false
local FlySpeed = 50
-- Aim Enhancements
local AimSmoothness = 0.18      -- lower = stronger / faster
local PredictionStrength = 0.13
local StrongLockBoost = 1.25
local VisibilityCheck = true

-- ESP Storage
local ESPs = {}

-- Theme Colors (dark mode)
local Theme = {
	Main = Color3.fromRGB(20,20,20),       -- Main panel
	Secondary = Color3.fromRGB(35,35,35),  -- Title / secondary backgrounds
	Accent = Color3.fromRGB(255,255,255),  -- Buttons
	Text = Color3.fromRGB(255,255,255),    -- White text
	Outline = Color3.fromRGB(0,0,0)        -- Black outline for strokes
}

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminMenu"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Main frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 230, 0, 270)
frame.Position = UDim2.new(0, -260, 0, 10)
frame.BackgroundColor3 = Theme.Main
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Curved frame
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = frame

-- Slide-in animation
frame.Visible = true
task.spawn(function()
	for x = -260, 10, 16 do
		frame.Position = UDim2.new(0, x, 0, 10)
		task.wait(0.01)
	end
end)

-- Draggable frame
local dragging, dragStart, startPos = false, nil, nil
frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)
frame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 0
title.BackgroundColor3 = Theme.Secondary
title.BorderSizePixel = 0
title.Text = "Donkey's Main Script"
title.TextColor3 = Theme.Text
title.TextStrokeColor3 = Theme.Outline
title.TextStrokeTransparency = 0.2
title.Font = Enum.Font.SourceSansBold
title.TextScaled = true
title.Parent = frame

-- FPS label
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 120, 0, 24)
fpsLabel.Position = UDim2.new(1, -130, 0, 10)
fpsLabel.BackgroundColor3 = Theme.Secondary
fpsLabel.BackgroundTransparency = 0.2
fpsLabel.BorderSizePixel = 0
fpsLabel.TextColor3 = Theme.Text
fpsLabel.TextStrokeColor3 = Theme.Outline
fpsLabel.TextStrokeTransparency = 0.3
fpsLabel.Font = Enum.Font.SourceSansBold
fpsLabel.TextSize = 16
fpsLabel.Text = "FPS: ..."
fpsLabel.Parent = screenGui

local lastTime = tick()
local frameCount = 0
RunService.RenderStepped:Connect(function()
	frameCount += 1
	local now = tick()
	if now - lastTime >= 1 then
		local fps = math.floor(frameCount / (now - lastTime))
		fpsLabel.Text = "FPS: " .. fps
		frameCount = 0
		lastTime = now
	end
end)

-- FOV Circle
local fovCircle = Instance.new("Frame")
fovCircle.Size = UDim2.new(0, AimlockDistance, 0, AimlockDistance)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0.5, 0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.Parent = screenGui

local fovUICorner = Instance.new("UICorner")
fovUICorner.CornerRadius = UDim.new(1, 0)
fovUICorner.Parent = fovCircle

local fovUIStroke = Instance.new("UIStroke")
fovUIStroke.Thickness = 2
fovUIStroke.Color = Theme.Accent
fovUIStroke.Transparency = 0
fovUIStroke.Parent = fovCircle

-- Button helper
local buttons = {}
local function createButton(text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 180, 0, 28)
	btn.BackgroundColor3 = Theme.Secondary
	btn.TextColor3 = Theme.Text
	btn.Font = Enum.Font.SourceSansBold
	btn.TextScaled = true
	btn.Text = text
	btn.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	table.insert(buttons, btn)
	return btn
end

-- Buttons
local espToggle = createButton("ESP: OFF")
local aimToggle = createButton("Aimlock: OFF")
local noclipToggle = createButton("Noclip: OFF")
local flyToggle = createButton("Fly: OFF")
-- SETTINGS BUTTON
local settingsToggle = createButton("Settings")
--local settingsFrameVisible = false

-- Settings frame
local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(0, 200, 0, 180)
settingsFrame.Position = UDim2.new(0.5, -100, 0.5, -90)
settingsFrame.BackgroundColor3 = Theme.Secondary
settingsFrame.BorderSizePixel = 0
settingsFrame.Visible = false
settingsFrame.Parent = screenGui

local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = UDim.new(0, 12)
settingsCorner.Parent = settingsFrame

-- Draggable settings frame
local draggingSettings, dragStartSettings, startPosSettings = false, nil, nil
settingsFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSettings = true
		dragStartSettings = input.Position
		startPosSettings = settingsFrame.Position
	end
end)
settingsFrame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSettings = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if draggingSettings and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStartSettings
		settingsFrame.Position = UDim2.new(
			startPosSettings.X.Scale,
			startPosSettings.X.Offset + delta.X,
			startPosSettings.Y.Scale,
			startPosSettings.Y.Offset + delta.Y
		)
	end
end)

-- Toggle Settings frame visibility
settingsToggle.MouseButton1Click:Connect(function()
	settingsFrameVisible = not settingsFrameVisible
	settingsFrame.Visible = settingsFrameVisible
end)

-- ======= Character Settings =======
local characterButton = Instance.new("TextButton")
characterButton.Size = UDim2.new(0, 180, 0, 28)
-- Position it under the Settings button (we’ll update all button positions later)
characterButton.BackgroundColor3 = Theme.Secondary
characterButton.TextColor3 = Theme.Text
characterButton.Font = Enum.Font.SourceSansBold
characterButton.TextScaled = true
characterButton.Text = "Character"
characterButton.Parent = frame -- MAIN frame, not settingsFrame

local charCorner = Instance.new("UICorner")
charCorner.CornerRadius = UDim.new(0, 8)
charCorner.Parent = characterButton

-- Character Frame
local charFrame = Instance.new("Frame")
charFrame.Size = UDim2.new(0, 200, 0, 180)
charFrame.Position = UDim2.new(0.5, -100, 0.5, -90)
charFrame.BackgroundColor3 = Theme.Secondary
charFrame.BorderSizePixel = 0
charFrame.Visible = false
charFrame.Parent = screenGui

local charCornerFrame = Instance.new("UICorner")
charCornerFrame.CornerRadius = UDim.new(0, 12)
charCornerFrame.Parent = charFrame

-- Draggable character frame
local draggingChar, dragStartChar, startPosChar = false, nil, nil
charFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingChar = true
		dragStartChar = input.Position
		startPosChar = charFrame.Position
	end
end)
charFrame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingChar = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if draggingChar and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStartChar
		charFrame.Position = UDim2.new(
			startPosChar.X.Scale,
			startPosChar.X.Offset + delta.X,
			startPosChar.Y.Scale,
			startPosChar.Y.Offset + delta.Y
		)
	end
end)

-- Toggle character frame visibility
characterButton.MouseButton1Click:Connect(function()
	charFrame.Visible = not charFrame.Visible
end)

-- ======= Character Functions =======
--local lpChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
--local humanoid = lpChar:FindFirstChildWhichIsA("Humanoid")

-- Invisibility toggle
local invisButton = Instance.new("TextButton")
invisButton.Size = UDim2.new(0, 160, 0, 28)
invisButton.Position = UDim2.new(0, 20, 0, 10)
invisButton.BackgroundColor3 = Theme.Main
invisButton.TextColor3 = Theme.Text
invisButton.Font = Enum.Font.SourceSansBold
invisButton.TextScaled = true
invisButton.Text = "Invisible: OFF"
invisButton.Parent = charFrame

local isInvisible = false
invisButton.MouseButton1Click:Connect(function()
	isInvisible = not isInvisible
	invisButton.Text = isInvisible and "Invisible: ON" or "Invisible: OFF"


    
    local char = localPlayer.Character
    if not char then return end

	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("MeshPart") then
			part.Transparency = isInvisible and 1 or 0
			if part:IsA("Decal") then
				part.Transparency = isInvisible and 1 or 0
			end
		end
	end
end)

-- WalkSpeed slider
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 160, 0, 20)
speedLabel.Position = UDim2.new(0, 20, 0, 50)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Theme.Text
speedLabel.Font = Enum.Font.SourceSansBold
speedLabel.TextSize = 14
speedLabel.Text = "WalkSpeed: 16"
speedLabel.Parent = charFrame

local speedSlider = Instance.new("TextButton")
speedSlider.Size = UDim2.new(0, 160, 0, 20)
speedSlider.Position = UDim2.new(0, 20, 0, 70)
speedSlider.BackgroundColor3 = Theme.Main
speedSlider.Text = ""
speedSlider.Parent = charFrame

local speedBar = Instance.new("Frame")
speedBar.Size = UDim2.new(0, 0, 1, 0)
speedBar.BackgroundColor3 = Theme.Accent
speedBar.BorderSizePixel = 0
speedBar.Parent = speedSlider

local draggingSpeed = false
speedSlider.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSpeed = true
	end
end)
speedSlider.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSpeed = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if draggingSpeed and input.UserInputType == Enum.UserInputType.MouseMovement then
		local mouseX = input.Position.X - speedSlider.AbsolutePosition.X
		mouseX = math.clamp(mouseX, 0, speedSlider.AbsoluteSize.X)
		speedBar.Size = UDim2.new(0, mouseX, 1, 0)
		local speedValue = math.floor((mouseX / speedSlider.AbsoluteSize.X) * 100) -- 0-100
		humanoid.WalkSpeed = speedValue
		speedLabel.Text = "WalkSpeed: "..speedValue
	end
end)

-- JumpPower multiplier slider
local jumpLabel = Instance.new("TextLabel")
jumpLabel.Size = UDim2.new(0, 160, 0, 20)
jumpLabel.Position = UDim2.new(0, 20, 0, 100)
jumpLabel.BackgroundTransparency = 1
jumpLabel.TextColor3 = Theme.Text
jumpLabel.Font = Enum.Font.SourceSansBold
jumpLabel.TextSize = 14
jumpLabel.Text = "JumpPower: 50"
jumpLabel.Parent = charFrame

local jumpSlider = Instance.new("TextButton")
jumpSlider.Size = UDim2.new(0, 160, 0, 20)
jumpSlider.Position = UDim2.new(0, 20, 0, 120)
jumpSlider.BackgroundColor3 = Theme.Main
jumpSlider.Text = ""
jumpSlider.Parent = charFrame

local jumpBar = Instance.new("Frame")
jumpBar.Size = UDim2.new(0, 0, 1, 0)
jumpBar.BackgroundColor3 = Theme.Accent
jumpBar.BorderSizePixel = 0
jumpBar.Parent = jumpSlider

local draggingJump = false
jumpSlider.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingJump = true
	end
end)
jumpSlider.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingJump = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if draggingJump and input.UserInputType == Enum.UserInputType.MouseMovement then
		local mouseX = input.Position.X - jumpSlider.AbsolutePosition.X
		mouseX = math.clamp(mouseX, 0, jumpSlider.AbsoluteSize.X)
		jumpBar.Size = UDim2.new(0, mouseX, 1, 0)
		local jumpValue = math.floor((mouseX / jumpSlider.AbsoluteSize.X) * 200) -- 0-200 jump power
		humanoid.JumpPower = jumpValue
		jumpLabel.Text = "JumpPower: "..jumpValue
	end
end)

-----
local function applyCharacterSettings(char)
	local humanoid = char:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return end

	-- Reapply WalkSpeed
	humanoid.WalkSpeed = speedBar.Size.X.Offset / speedSlider.AbsoluteSize.X * 100

	-- Reapply JumpPower
	humanoid.JumpPower = jumpBar.Size.X.Offset / jumpSlider.AbsoluteSize.X * 200

	-- Reapply invisibility
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("MeshPart") then
			part.Transparency = isInvisible and 1 or 0
		end
	end
end

localPlayer.CharacterAdded:Connect(applyCharacterSettings)

-- Also apply immediately for current character
if localPlayer.Character then
	applyCharacterSettings(localPlayer.Character)
end

-------------------------------------------------------
-- HOTKEY SETTER FEATURE

local Hotkeys = {
    Aimlock = Enum.KeyCode.E,
    Noclip = Enum.KeyCode.H,
    Fly = Enum.KeyCode.J,
    ESP = Enum.KeyCode.K
}

local hotkeyButtons = {}

local function createHotkeyButton(actionName, defaultKey, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 28)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Theme.Main
    btn.TextColor3 = Theme.Text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextScaled = true
    btn.Text = actionName..": "..defaultKey.Name
    btn.Parent = settingsFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        btn.Text = actionName..": ..."
        local connection
        connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                Hotkeys[actionName] = input.KeyCode
                btn.Text = actionName..": "..input.KeyCode.Name
                connection:Disconnect()
            end
        end)
    end)

    table.insert(hotkeyButtons, btn)
end

-- Create buttons for each action
createHotkeyButton("Aimlock", Hotkeys.Aimlock, 10)
createHotkeyButton("Noclip", Hotkeys.Noclip, 50)
createHotkeyButton("Fly", Hotkeys.Fly, 90)
createHotkeyButton("ESP", Hotkeys.ESP, 130)

-------------------------------------------------------
-- Arrange buttons
local function updateButtonPositions()
	local spacing = 10
	local yStart = 40
	for i, btn in ipairs(buttons) do
		btn.Position = UDim2.new(0, 10, 0, yStart + (i-1)*(btn.Size.Y.Offset + spacing))
	end
end
table.insert(buttons, characterButton) -- include character button
updateButtonPositions()

-- Team color helper
local function getTeamColor(player)
	if player.Team then return player.TeamColor.Color end
	return Theme.Accent
end

-- Health color helper (green → red)
local function getHealthColor(humanoid)
	if not humanoid then return Color3.fromRGB(0,255,0) end
	local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
	return Color3.fromRGB(255*(1-ratio), 255*ratio, 0)
end

-- ESP Functions (Updated Dynamic Version)
local function createESP(player)
	if ESPs[player] or not player.Character then return end

	local char = player.Character
	local highlight = Instance.new("Highlight")
	highlight.Name = "ESPHighlight"
	highlight.Adornee = char
	highlight.FillColor = getTeamColor(player)
	highlight.OutlineColor = Theme.Accent
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = char

	local rootPart = char:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = rootPart
	billboard.Size = UDim2.new(0, 80, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = char

	local frameGui = Instance.new("Frame")
	frameGui.Size = UDim2.new(1, 0, 1, 0)
	frameGui.BackgroundTransparency = 0.6
	frameGui.BorderSizePixel = 0
	frameGui.BackgroundColor3 = Theme.Secondary
	frameGui.Parent = billboard

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.Name
	nameLabel.TextColor3 = getTeamColor(player)
	nameLabel.TextStrokeColor3 = Theme.Outline
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextScaled = true
	nameLabel.Parent = frameGui

	local healthBack = Instance.new("Frame")
	healthBack.Size = UDim2.new(1, 0, 0.15, 0)
	healthBack.Position = UDim2.new(0, 0, 0.85, 0)
	healthBack.BackgroundColor3 = Color3.fromRGB(200,200,200)
	healthBack.BorderSizePixel = 0
	healthBack.Parent = frameGui

	local healthFront = Instance.new("Frame")
	healthFront.Size = UDim2.new(1, 0, 1, 0)
	healthFront.BackgroundColor3 = Color3.fromRGB(255,255,255)
	healthFront.BorderSizePixel = 0
	healthFront.Parent = healthBack

	local humanoid = char:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		-- Update health bar dynamically with green → red
		humanoid.HealthChanged:Connect(function()
			local percent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
			healthFront.Size = UDim2.new(percent, 0, 1, 0)
			healthFront.BackgroundColor3 = getHealthColor(humanoid)
		end)
		-- Set initial color
		healthFront.BackgroundColor3 = getHealthColor(humanoid)
	end

	-- Update team color if it changes
	player:GetPropertyChangedSignal("TeamColor"):Connect(function()
		if highlight and highlight.Parent then
			highlight.FillColor = getTeamColor(player)
		end
		if nameLabel and nameLabel.Parent then
			nameLabel.TextColor3 = getTeamColor(player)
		end
	end)

	ESPs[player] = {highlight = highlight, gui = billboard, healthFront = healthFront, nameLabel = nameLabel}
end

local function removeESP(player)
	if ESPs[player] then
		if ESPs[player].highlight then ESPs[player].highlight:Destroy() end
		if ESPs[player].gui then ESPs[player].gui:Destroy() end
		ESPs[player] = nil
	end
end

-- Improved Player Tracking for ESP
local function trackPlayer(player)
	player.CharacterRemoving:Connect(function()
		removeESP(player)
	end)

	player.CharacterAdded:Connect(function()
		if ESPEnabled then
			createESP(player)
		end
	end)

	if player.Character and ESPEnabled then
		createESP(player)
	end
end

for _, player in pairs(Players:GetPlayers()) do
	trackPlayer(player)
end

Players.PlayerAdded:Connect(trackPlayer)
Players.PlayerRemoving:Connect(removeESP)

-- Toggle functions
local function toggleESP()
    ESPEnabled = not ESPEnabled
    espToggle.Text = ESPEnabled and "ESP: ON" or "ESP: OFF"
    if not ESPEnabled then
        for player,_ in pairs(ESPs) do removeESP(player) end
    else
        for _,player in pairs(Players:GetPlayers()) do createESP(player) end
    end
end
espToggle.MouseButton1Click:Connect(toggleESP)

-- Aimlock toggle
aimToggle.MouseButton1Click:Connect(function()
	AimlockEnabled = not AimlockEnabled
	aimToggle.Text = AimlockEnabled and "Aimlock: ON" or "Aimlock: OFF"
	fovCircle.Visible = AimlockEnabled
end)

-- Noclip toggle
local noclipConnection
local function enableNoclip()
	local lpChar = localPlayer.Character
	if not lpChar then return end
	local hrp = lpChar:FindFirstChild("HumanoidRootPart")
	local humanoid = lpChar:FindFirstChildWhichIsA("Humanoid")
	if not hrp or not humanoid then return end

	for _, part in pairs(lpChar:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end

	humanoid.PlatformStand = true

	noclipConnection = RunService.RenderStepped:Connect(function(deltaTime)
		if not NoclipEnabled then return end
		local moveVector = Vector3.new(0,0,0)

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			moveVector += camera.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			moveVector -= camera.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			moveVector -= camera.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			moveVector += camera.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			moveVector += Vector3.new(0,1,0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			moveVector -= Vector3.new(0,1,0)
		end

		if moveVector.Magnitude > 0 then
			moveVector = moveVector.Unit * NoclipSpeed * deltaTime
			hrp.CFrame += moveVector
		end
	end)
end

local function disableNoclip()
	local lpChar = localPlayer.Character
	if not lpChar then return end
	local humanoid = lpChar:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
	end

	for _, part in pairs(lpChar:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
		end
	end

	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end
end

local function toggleNoclip()
	NoclipEnabled = not NoclipEnabled
	if NoclipEnabled then
		enableNoclip()
	else
		disableNoclip()
	end
	noclipToggle.Text = NoclipEnabled and "Noclip: ON" or "Noclip: OFF"
end
noclipToggle.MouseButton1Click:Connect(toggleNoclip)

-- Improved Fly
local flyVelocity
local flyConnection
local function enableFly()
    local lpChar = localPlayer.Character
    if not lpChar then return end
    local hrp = lpChar:FindFirstChild("HumanoidRootPart")
    local humanoid = lpChar:FindFirstChildWhichIsA("Humanoid")
    if not hrp or not humanoid then return end

    humanoid.PlatformStand = true -- disable default physics

    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5) -- strong enough to counter gravity
    flyVelocity.Velocity = Vector3.new(0,0,0)
    flyVelocity.Parent = hrp

    flyConnection = RunService.RenderStepped:Connect(function(deltaTime)
        if not FlyEnabled then return end

        local moveVector = Vector3.new(0,0,0)
        local camCFrame = workspace.CurrentCamera.CFrame

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVector += camCFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVector -= camCFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVector -= camCFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVector += camCFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVector += Vector3.new(0,1,0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveVector -= Vector3.new(0,1,0)
        end

        if moveVector.Magnitude > 0 then
            moveVector = moveVector.Unit * FlySpeed
        end

        flyVelocity.Velocity = moveVector
    end)
end

local function disableFly()
    local lpChar = localPlayer.Character
    if not lpChar then return end
    local humanoid = lpChar:FindFirstChildWhichIsA("Humanoid")
    local hrp = lpChar:FindFirstChild("HumanoidRootPart")
    if humanoid then
        humanoid.PlatformStand = false
    end
    if flyVelocity then
        flyVelocity:Destroy()
        flyVelocity = nil
    end
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
end

local function toggleFly()
    FlyEnabled = not FlyEnabled
    if FlyEnabled then
        enableFly()
    else
        disableFly()
    end
    flyToggle.Text = FlyEnabled and "Fly: ON" or "Fly: OFF"
end
flyToggle.MouseButton1Click:Connect(toggleFly)

-- Keybinds
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.CapsLock then
        frame.Visible = not frame.Visible
        settingsFrame.Visible = false
        settingsFrameVisible = false
        charFrame.Visible = false
        charFrameVisible = false
        return
    end

    -- Dynamic hotkey execution
    if input.KeyCode == Hotkeys.Aimlock then
        AimlockEnabled = not AimlockEnabled
        aimToggle.Text = AimlockEnabled and "Aimlock: ON" or "Aimlock: OFF"
        fovCircle.Visible = AimlockEnabled
    elseif input.KeyCode == Hotkeys.Noclip then
        toggleNoclip()
    elseif input.KeyCode == Hotkeys.Fly then
        toggleFly()
    elseif input.KeyCode == Hotkeys.ESP then
        toggleESP()
    end
end)

-- RenderStepped
local function getTargetPart(character)
    -- Priority: Head -> head -> HumanoidRootPart -> highest part
    if character:FindFirstChild("Head") then return character.Head end
    if character:FindFirstChild("head") then return character.head end
    if character:FindFirstChild("HumanoidRootPart") then return character.HumanoidRootPart end

    -- fallback: find highest BasePart
    local highestPart
    local highestY = -math.huge
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Position.Y > highestY then
            highestY = part.Position.Y
            highestPart = part
        end
    end
    return highestPart
end

local function isVisible(part)
	if not VisibilityCheck then return true end
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {localPlayer.Character}
	params.FilterType = Enum.RaycastFilterType.Blacklist

	local origin = camera.CFrame.Position
	local direction = (part.Position - origin)

	local result = workspace:Raycast(origin, direction, params)
	return result and result.Instance:IsDescendantOf(part.Parent)
end

local function getPredictedPosition(part)
	local velocity = part.AssemblyLinearVelocity or Vector3.zero
	return part.Position + (velocity * PredictionStrength)
end


RunService.RenderStepped:Connect(function()
    -- FOV circle
    if fovCircle.Visible then
        fovCircle.Size = UDim2.new(0, AimlockDistance, 0, AimlockDistance)
        fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
    end

    -- ESP
    if ESPEnabled then
        for _,player in pairs(Players:GetPlayers()) do
            if player.Character and (not ESPs[player] or not ESPs[player].highlight or not ESPs[player].highlight.Parent) then
                createESP(player)
            end
        end
    end

    -- Aimlock
    if AimlockEnabled then
        local bestTarget = nil
        local bestScore = math.huge

        for _,player in pairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Team ~= localPlayer.Team and player.Character then
                local part = getTargetPart(player.Character)
                if part and isVisible(part) then
                    local predicted = getPredictedPosition(part)
                    local dir = predicted - camera.CFrame.Position
                    local distance = dir.Magnitude
                    local angle = math.deg(math.acos(camera.CFrame.LookVector:Dot(dir.Unit)))

                    if angle <= AimlockFOV and distance <= AimlockDistance then
                        local score =
                            distance
                            + (angle * 3)
                            - (part.AssemblyLinearVelocity.Magnitude * 0.4)

                        if score < bestScore then
                            bestScore = score
                            bestTarget = part
                        end
                    end
                end
            end
        end

        if bestTarget then
            local predicted = getPredictedPosition(bestTarget)
            local camPos = camera.CFrame.Position

            local strongFactor = math.clamp(1 / (bestScore / AimlockDistance), 1, StrongLockBoost)
            local smooth = math.clamp(AimSmoothness / strongFactor, 0.05, AimSmoothness)

            local targetCF = CFrame.lookAt(camPos, predicted)
            camera.CFrame = camera.CFrame:Lerp(targetCF, smooth)
        end
    end
end)