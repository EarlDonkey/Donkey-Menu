-- ============================================================
-- Donkey's Main Script (v9.0)

-- By Earl Donkey
-- ============================================================
-- Combat · Visual · Movement · Character · Utility · UX
-- ============================================================

-- ============================================================
-- 1. GUARDS + SERVICES
-- ============================================================
if not game or not workspace or not game.Players then return end
if not game:IsLoaded() then game.Loaded:Wait() end

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local HttpService       = game:GetService("HttpService")
local Lighting          = game:GetService("Lighting")
local Stats             = game:GetService("Stats")
local SoundService      = game:GetService("SoundService")

local localPlayer = Players.LocalPlayer
while not localPlayer do
    Players.PlayerAdded:Wait()
    localPlayer = Players.LocalPlayer
end

local camera = workspace.CurrentCamera

-- ============================================================
-- 2. SETTINGS
-- ============================================================
local Settings = {
    -- ESP
    ESPEnabled            = false,
    ESPShowName           = true,
    ESPShowHealth         = true,
    ESPShowDistance       = true,
    ESPOnlyEnemies        = true,
    ESPOnlyVisible        = false,
    ESPTeamColorHighlight = true,
    ESPDistanceFade       = true,
    ESPFadeDistance       = 500,

    -- Aimlock
    AimlockEnabled        = false,
    AimlockDistance       = 200,
    AimlockFOV            = 90,
    AimSmoothness         = 0.18,
    PredictionStrength    = 0.13,
    StrongLockBoost       = 1.25,
    VisibilityCheck       = true,
    TeamCheck             = true,

    -- Silent Aim
    SilentAimEnabled      = false,
    SilentAimFOV          = 120,
    SilentAimDebug        = false,
    SilentAimDebugRate    = 1.0,

    -- Trigger Bot
    TriggerBotEnabled     = false,
    TriggerBotDelay       = 0.05,
    TriggerBotFOVPixels   = 15,
    TriggerBotRequireLMB  = false,

    -- Movement
    NoclipEnabled         = false,
    NoclipSpeed           = 50,
    FlyEnabled            = false,
    FlySpeed              = 50,
    InfiniteJumpEnabled   = false,
    AntiFlingEnabled      = false,
    AntiVoidEnabled       = false,

    -- Character
    Invisible             = false,
    WalkSpeed             = 16,
    JumpPower             = 50,
    Gravity               = 196,
    GodModeEnabled        = false,

    -- Environment
    FullbrightEnabled     = false,
    NoFogEnabled          = false,

    -- Info overlays
    ShowPing              = false,
    ShowPosition          = false,
    ShowVelocity          = false,

    -- v9.0 Combat
    AimTargetMode         = "Head",        -- "Head" | "Torso" | "Nearest" | "NearestVisible"
    AimCurve              = "Linear",      -- "Linear" | "EaseOut" | "EaseInOut" | "Snap"
    TriggerBurst          = 1,
    TriggerBurstDelay     = 0.03,
    NoRecoilEnabled       = false,
    NoSpreadEnabled       = false,
    RapidFireEnabled      = false,
    RapidFireMultiplier   = 2.0,
    HitMarkerEnabled      = false,
    KillNotifierEnabled   = false,
    KillSoundEnabled      = false,

    -- UI
    ActiveTab             = "Combat",
    ToastEnabled          = true,
    ShowStatusBar         = true,
    MenuScale             = 1.0,
    MenuOpacity           = 1.0,
}

local Hotkeys = {
    Aimlock    = Enum.KeyCode.E,
    SilentAim  = Enum.KeyCode.Q,
    TriggerBot = Enum.KeyCode.T,
    Noclip     = Enum.KeyCode.H,
    Fly        = Enum.KeyCode.J,
    ESP        = Enum.KeyCode.K,
    ToggleMenu = Enum.KeyCode.CapsLock,
}

-- ============================================================
-- 3. THEME
-- ============================================================
local Theme = {
    Background   = Color3.fromRGB(16, 16, 20),
    Panel        = Color3.fromRGB(24, 24, 30),
    PanelLight   = Color3.fromRGB(34, 34, 42),
    PanelAccent  = Color3.fromRGB(44, 44, 54),
    Hover        = Color3.fromRGB(58, 58, 72),

    Accent       = Color3.fromRGB(80, 220, 180),
    AccentDim    = Color3.fromRGB(50, 140, 115),
    AccentGlow   = Color3.fromRGB(120, 255, 210),

    Text         = Color3.fromRGB(240, 240, 245),
    TextDim      = Color3.fromRGB(160, 160, 175),
    TextMuted    = Color3.fromRGB(110, 110, 125),

    Danger       = Color3.fromRGB(235, 90, 100),
    Success      = Color3.fromRGB(80, 200, 130),
    Warning      = Color3.fromRGB(240, 195, 75),
    Trigger      = Color3.fromRGB(255, 200, 60),

    Outline      = Color3.fromRGB(0, 0, 0),
    Border       = Color3.fromRGB(45, 45, 55),
}

-- ============================================================
-- 4. PERSISTENCE
-- ============================================================
local PERSIST_KEY = "DonkeyCheat_v9"
local PROFILES_KEY = "DonkeyCheat_profiles_v9"
local PersistBackend, PersistStore = "memory", nil

do
    if writefile and readfile and isfile then
        PersistBackend = "file"
    else
        local ok, ds = pcall(function()
            return game:GetService("DataStoreService"):GetDataStore(PERSIST_KEY)
        end)
        if ok and ds then
            PersistBackend = "datastore"
            PersistStore = ds
        end
    end
end

local memoryCache = {}

local function serializeHotkeys()
    local out = {}
    for k, v in pairs(Hotkeys) do out[k] = v.Name end
    return out
end

local function deserializeHotkeys(data)
    for k, v in pairs(data or {}) do
        local ok, keyCode = pcall(function() return Enum.KeyCode[v] end)
        if ok and keyCode then Hotkeys[k] = keyCode end
    end
end

local function buildPayload()
    local payload = { Settings = {}, Hotkeys = serializeHotkeys() }
    for k, v in pairs(Settings) do
        if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
            payload.Settings[k] = v
        end
    end
    -- Never auto-enable dangerous features
    payload.Settings.TriggerBotEnabled    = false
    payload.Settings.NoclipEnabled        = false
    payload.Settings.FlyEnabled           = false
    payload.Settings.ESPEnabled           = false
    payload.Settings.AimlockEnabled       = false
    payload.Settings.SilentAimEnabled     = false
    payload.Settings.GodModeEnabled       = false
    payload.Settings.AntiFlingEnabled     = false
    payload.Settings.AntiVoidEnabled      = false
    payload.Settings.InfiniteJumpEnabled  = false
    payload.Settings.NoRecoilEnabled      = false
    payload.Settings.NoSpreadEnabled      = false
    payload.Settings.RapidFireEnabled     = false
    payload.Settings.HitMarkerEnabled     = false
    payload.Settings.KillNotifierEnabled  = false
    payload.Settings.KillSoundEnabled     = false
    return payload
end

local saveDebounceToken = 0
local function saveSettings()
    saveDebounceToken += 1
    local myToken = saveDebounceToken
    task.delay(0.5, function()
        if saveDebounceToken ~= myToken then return end
        local payload = buildPayload()
        local ok, encoded = pcall(function() return HttpService:JSONEncode(payload) end)
        if not ok then warn("[Donkey] saveSettings encode failed") return end
        if PersistBackend == "file" then
            pcall(writefile, PERSIST_KEY .. ".json", encoded)
        elseif PersistBackend == "datastore" then
            pcall(function()
                PersistStore:SetAsync(localPlayer.UserId .. "_" .. PERSIST_KEY, encoded)
            end)
        else
            memoryCache[PERSIST_KEY] = encoded
        end
    end)
end

local function saveSettingsNow()
    saveDebounceToken += 1
    local payload = buildPayload()
    local ok, encoded = pcall(function() return HttpService:JSONEncode(payload) end)
    if not ok then return end
    if PersistBackend == "file" then
        pcall(writefile, PERSIST_KEY .. ".json", encoded)
    elseif PersistBackend == "datastore" then
        pcall(function()
            PersistStore:SetAsync(localPlayer.UserId .. "_" .. PERSIST_KEY, encoded)
        end)
    else
        memoryCache[PERSIST_KEY] = encoded
    end
end

local function applyPayload(payload)
    if not payload then return end
    for k, v in pairs(payload.Settings or {}) do
        if Settings[k] ~= nil and type(Settings[k]) == type(v) then
            Settings[k] = v
        end
    end
    deserializeHotkeys(payload.Hotkeys)
end

local function loadSettings()
    local encoded
    if PersistBackend == "file" then
        if isfile and isfile(PERSIST_KEY .. ".json") then
            local ok, data = pcall(readfile, PERSIST_KEY .. ".json")
            if ok then encoded = data end
        end
    elseif PersistBackend == "datastore" then
        pcall(function()
            encoded = PersistStore:GetAsync(localPlayer.UserId .. "_" .. PERSIST_KEY)
        end)
    else
        encoded = memoryCache[PERSIST_KEY]
    end
    if not encoded then return end
    local ok, payload = pcall(function() return HttpService:JSONDecode(encoded) end)
    if not ok or not payload then
        warn("[Donkey] loadSettings decode failed")
        return
    end
    applyPayload(payload)
end

pcall(loadSettings)

-- Profiles
local Profiles = {}
local function loadProfiles()
    local encoded
    if PersistBackend == "file" then
        if isfile and isfile(PROFILES_KEY .. ".json") then
            local ok, data = pcall(readfile, PROFILES_KEY .. ".json")
            if ok then encoded = data end
        end
    else
        encoded = memoryCache[PROFILES_KEY]
    end
    if not encoded then return end
    local ok, decoded = pcall(function() return HttpService:JSONDecode(encoded) end)
    if ok and decoded then Profiles = decoded end
end

local function saveProfiles()
    local ok, encoded = pcall(function() return HttpService:JSONEncode(Profiles) end)
    if not ok then return end
    if PersistBackend == "file" then
        pcall(writefile, PROFILES_KEY .. ".json", encoded)
    else
        memoryCache[PROFILES_KEY] = encoded
    end
end

pcall(loadProfiles)

-- ============================================================
-- 5. STATE REGISTRIES
-- ============================================================
local DyingPlayers = {}
local RecentlyDead = {}
local silentAimTarget = nil
local sharedFrameId = 0
local cachedTarget, cachedScore = nil, nil
local cacheFrameId, cacheFov, cacheDist = -1, nil, nil
local lastDebugPrint = 0
local listeningAction = nil

local espToggleAPI, aimToggleAPI, silentToggleAPI, triggerToggleAPI
local noclipToggleAPI, flyToggleAPI
local hotkeyBadges = {}

local capsState = 0

local espWanted = {}
local espRetryQueue = {}

local savedLighting = nil
local savedFog = nil

-- v9.0 Combat state
local WeaponWhitelist = {}
local rapidFireConn = nil
local noRecoilConn = nil
local hitMarkerConn = nil
local killNotifierUI = nil
local hitMarkerUI = nil
local lastHealthSnapshot = {}
local lastEnemyHealth = {}

-- ============================================================
-- 6. LOGIC LAYER
-- ============================================================

-- ---------- 6.1 Utility ----------
local function getTeamColor(player)
    if player.Team then return player.TeamColor.Color end
    return Theme.Accent
end

local function getHealthColor(hum)
    if not hum then return Color3.fromRGB(0, 255, 0) end
    local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
    return Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 0)
end

local function formatDistance(studs)
    return string.format("%dm", math.floor(studs))
end

-- ---------- 6.2 Death tracking ----------
local function markPlayerDying(player, char)
    if not player then return end
    if DyingPlayers[player] then return end
    DyingPlayers[player] = true
    RecentlyDead[player] = os.clock()

    if silentAimTarget and silentAimTarget.Parent and char then
        if silentAimTarget:IsDescendantOf(char) then
            silentAimTarget = nil
        end
    end

    task.delay(3, function() DyingPlayers[player] = nil end)
end

-- ---------- 6.3 Targeting ----------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = localPlayer.Character and { localPlayer.Character } or {}
localPlayer.CharacterAdded:Connect(function(char)
    rayParams.FilterDescendantsInstances = { char }
end)

local function isAliveCharacter(character)
    if not character or not character.Parent then return false end
    local owner = Players:GetPlayerFromCharacter(character)
    if owner and DyingPlayers[owner] then return false end
    local hum = character:FindFirstChildWhichIsA("Humanoid")
    if not hum then return false end
    if hum.Health <= 0 then return false end
    if hum:GetState() == Enum.HumanoidStateType.Dead then return false end
    if character:FindFirstChildOfClass("ForceField") then return false end
    return true
end

local function isESPReady(character)
    if not character or not character.Parent then return false end
    local hum = character:FindFirstChildWhichIsA("Humanoid")
    if not hum then return false end
    if hum.Health <= 0 then return false end
    if not character:FindFirstChild("HumanoidRootPart") then return false end
    return true
end

local function isEnemyTeam(player)
    if not player then return false end
    if not Settings.TeamCheck then return true end
    local myTeam = localPlayer.Team
    local theirTeam = player.Team
    if myTeam == nil and theirTeam == nil then return true end
    if myTeam == nil or theirTeam == nil then return false end
    return theirTeam ~= myTeam
end

local function isTargetStillValid(part)
    if not part or not part.Parent then return false end
    local char = part:FindFirstAncestorOfClass("Model")
    if not char then return false end
    local owner = Players:GetPlayerFromCharacter(char)
    if not owner then return false end
    if DyingPlayers[owner] then return false end
    if not isEnemyTeam(owner) then return false end
    return isAliveCharacter(char)
end

local function isVisible(part)
    if not Settings.VisibilityCheck then return true end
    local origin = camera.CFrame.Position
    local result = workspace:Raycast(origin, part.Position - origin, rayParams)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

-- Target part respecting AimTargetMode
local function getTargetPart(character)
    if not isAliveCharacter(character) then return nil end

    local mode = Settings.AimTargetMode

    if mode == "Head" then
        local head = character:FindFirstChild("Head")
        if head and head:IsA("BasePart") then return head end
    elseif mode == "Torso" then
        local tor = character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("LowerTorso")
        if tor and tor:IsA("BasePart") then return tor end
    elseif mode == "Nearest" or mode == "NearestVisible" then
        local camPos = camera.CFrame.Position
        local best, bestDist = nil, math.huge
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                local skip = false
                if mode == "NearestVisible" and not isVisible(part) then skip = true end
                if not skip then
                    local d = (part.Position - camPos).Magnitude
                    if d < bestDist then
                        bestDist, best = d, part
                    end
                end
            end
        end
        if best then return best end
    end

    -- Fallback chain
    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then return head end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then return hrp end

    local best, bestY = nil, -math.huge
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Position.Y > bestY then
            bestY, best = part.Position.Y, part
        end
    end
    return best
end

local function isEnemy(player)
    if not player or not player.Parent then return false end
    if DyingPlayers[player] then return false end
    local deadAt = RecentlyDead[player]
    if deadAt and os.clock() - deadAt < 2 then return false end
    if not isAliveCharacter(player.Character) then return false end
    return isEnemyTeam(player)
end

local function getPredictedPosition(part)
    local char = part:FindFirstAncestorOfClass("Model")
    local hum  = char and char:FindFirstChildWhichIsA("Humanoid")
    if hum then
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0 then
            return part.Position + moveDir * hum.WalkSpeed * Settings.PredictionStrength
        end
    end
    local v = part.AssemblyLinearVelocity or Vector3.zero
    return part.Position + v * Settings.PredictionStrength
end

local function findBestTarget(fovDegrees, maxDistance)
    maxDistance = maxDistance or Settings.AimlockDistance
    local camPos  = camera.CFrame.Position
    local lookVec = camera.CFrame.LookVector
    local bestPart, bestScore = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and isEnemy(player) then
            local target = getTargetPart(player.Character)
            if target and isVisible(target) then
                local predicted = getPredictedPosition(target)
                local dir = predicted - camPos
                local distance = dir.Magnitude
                if distance > 0 and distance <= maxDistance then
                    local angle = math.deg(math.acos(math.clamp(lookVec:Dot(dir.Unit), -1, 1)))
                    if angle <= fovDegrees then
                        local velocity = target.AssemblyLinearVelocity.Magnitude
                        local score = distance + angle * 3 - velocity * 0.4
                        if score < bestScore then
                            bestScore, bestPart = score, target
                        end
                    end
                end
            end
        end
    end
    if not bestPart then return nil, nil end
    return bestPart, bestScore
end

local function getSharedTarget(fov, dist)
    if cacheFrameId == sharedFrameId and cacheFov == fov and cacheDist == dist then
        if cachedTarget and not cachedTarget.Parent then
            cachedTarget, cachedScore = nil, nil
        else
            return cachedTarget, cachedScore
        end
    end
    cachedTarget, cachedScore = findBestTarget(fov, dist)
    cacheFrameId, cacheFov, cacheDist = sharedFrameId, fov, dist
    return cachedTarget, cachedScore
end

-- Apply aim curve to lerp amount
local function applyAimCurve(t)
    local curve = Settings.AimCurve
    if curve == "Snap" then return 1 end
    if curve == "EaseOut" then return 1 - (1 - t) ^ 2 end
    if curve == "EaseInOut" then
        return t < 0.5 and (2 * t * t) or (1 - (-2 * t + 2) ^ 2 / 2)
    end
    return t
end

-- ---------- 6.4 ESP ----------
local ESPs = {}

local function shouldShowESP(player)
    if player == localPlayer then return false end
    if not player.Parent then return false end
    if Settings.ESPOnlyEnemies and not isEnemyTeam(player) then return false end
    return true
end

local function computeESPAlpha(distance)
    if not Settings.ESPDistanceFade then return 1 end
    local fadeDist = math.max(1, Settings.ESPFadeDistance)
    local ratio = math.clamp(1 - (distance / fadeDist), 0, 1)
    return 0.25 + 0.75 * ratio
end

local function createESP(player)
    if ESPs[player] then return true end
    if not shouldShowESP(player) then return false end
    local char = player.Character
    if not isESPReady(char) then return false end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.Adornee = char
    highlight.FillColor = getTeamColor(player)
    highlight.OutlineColor = Theme.Accent
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char

    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        highlight:Destroy()
        return false
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = rootPart
    billboard.Size = UDim2.new(0, 100, 0, 70)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = char

    local frameGui = Instance.new("Frame")
    frameGui.Size = UDim2.new(1, 0, 1, 0)
    frameGui.BackgroundTransparency = 0.6
    frameGui.BorderSizePixel = 0
    frameGui.BackgroundColor3 = Theme.Panel
    frameGui.Parent = billboard
    Instance.new("UICorner", frameGui).CornerRadius = UDim.new(0, 4)

    local teamStrip = Instance.new("Frame")
    teamStrip.Size = UDim2.new(1, 0, 0, 2)
    teamStrip.Position = UDim2.new(0, 0, 0, 0)
    teamStrip.BackgroundColor3 = getTeamColor(player)
    teamStrip.BorderSizePixel = 0
    teamStrip.Parent = frameGui
    Instance.new("UICorner", teamStrip).CornerRadius = UDim.new(0, 4)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.32, 0)
    nameLabel.Position = UDim2.new(0, 0, 0.03, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = getTeamColor(player)
    nameLabel.TextStrokeColor3 = Theme.Outline
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.Visible = Settings.ESPShowName
    nameLabel.Parent = frameGui

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0.22, 0)
    distLabel.Position = UDim2.new(0, 0, 0.35, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0m"
    distLabel.TextColor3 = Theme.Accent
    distLabel.TextStrokeColor3 = Theme.Outline
    distLabel.TextStrokeTransparency = 0.2
    distLabel.Font = Enum.Font.GothamSemibold
    distLabel.TextScaled = true
    distLabel.Visible = Settings.ESPShowDistance
    distLabel.Parent = frameGui

    local healthBack = Instance.new("Frame")
    healthBack.Size = UDim2.new(1, 0, 0.13, 0)
    healthBack.Position = UDim2.new(0, 0, 0.86, 0)
    healthBack.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    healthBack.BorderSizePixel = 0
    healthBack.Visible = Settings.ESPShowHealth
    healthBack.Parent = frameGui
    Instance.new("UICorner", healthBack).CornerRadius = UDim.new(0, 2)

    local healthFront = Instance.new("Frame")
    healthFront.Size = UDim2.new(1, 0, 1, 0)
    healthFront.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthFront.BorderSizePixel = 0
    healthFront.Parent = healthBack
    Instance.new("UICorner", healthFront).CornerRadius = UDim.new(0, 2)

    local connections = {}
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        local function updateHealth()
            local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            healthFront.Size = UDim2.new(ratio, 0, 1, 0)
            healthFront.BackgroundColor3 = getHealthColor(humanoid)
        end
        updateHealth()
        task.defer(updateHealth)
        table.insert(connections, humanoid.HealthChanged:Connect(updateHealth))
    end

    local function refreshTeamVisuals()
        local c = getTeamColor(player)
        if highlight.Parent then highlight.FillColor = c end
        if nameLabel.Parent then nameLabel.TextColor3 = c end
        if teamStrip.Parent then teamStrip.BackgroundColor3 = c end
    end
    table.insert(connections, player:GetPropertyChangedSignal("TeamColor"):Connect(refreshTeamVisuals))
    table.insert(connections, player:GetPropertyChangedSignal("Team"):Connect(refreshTeamVisuals))

    table.insert(connections, player:GetPropertyChangedSignal("Team"):Connect(function()
        if silentAimTarget then
            local tChar = silentAimTarget:FindFirstAncestorOfClass("Model")
            if tChar == char and not isEnemyTeam(player) then
                silentAimTarget = nil
            end
        end
    end))

    table.insert(connections, player:GetPropertyChangedSignal("Team"):Connect(function()
        if Settings.ESPOnlyEnemies and not isEnemyTeam(player) then
            removeESP(player)
        end
    end))

    ESPs[player] = {
        highlight = highlight,
        gui = billboard,
        frameGui = frameGui,
        teamStrip = teamStrip,
        nameLabel = nameLabel,
        distLabel = distLabel,
        healthBack = healthBack,
        healthFront = healthFront,
        connections = connections,
        lastAlpha = -1,
    }
    return true
end

local function removeESP(player)
    local data = ESPs[player]
    if not data then return end
    for _, c in ipairs(data.connections) do c:Disconnect() end
    if data.highlight then data.highlight:Destroy() end
    if data.gui then data.gui:Destroy() end
    ESPs[player] = nil
end

local function queueESPRetry(player, char)
    espRetryQueue[player] = {
        char = char,
        attempts = 0,
        firstTry = os.clock(),
    }
end

local function toggleESP(forceState, silent)
    local newState = forceState
    if newState == nil then newState = not Settings.ESPEnabled end
    Settings.ESPEnabled = newState

    if not newState then
        local toRemove = {}
        for p in pairs(ESPs) do table.insert(toRemove, p) end
        for _, p in ipairs(toRemove) do removeESP(p) end
        for p in pairs(espRetryQueue) do espRetryQueue[p] = nil end
        for p in pairs(espWanted) do espWanted[p] = nil end
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= localPlayer then
                espWanted[p] = true
                local ok = createESP(p)
                if not ok and p.Character and p.Character.Parent then
                    queueESPRetry(p, p.Character)
                end
            end
        end
    end

    if espToggleAPI then espToggleAPI.SetState(newState, true) end

    if not silent then
        toast("ESP " .. (newState and "ON" or "OFF"),
            newState and Theme.Accent or Theme.TextDim)
        task.spawn(saveSettings)
    end
end

-- ---------- 6.5 Silent aim hook ----------
local cameraHooked = false
local function enableSilentAimHook()
    if cameraHooked then return end
    cameraHooked = true
    RunService:BindToRenderStep("SilentAimHook", 200, function()
        if not Settings.SilentAimEnabled then return end
        if silentAimTarget and silentAimTarget.Parent then
            local predicted = getPredictedPosition(silentAimTarget)
            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, predicted)
        end
    end)
end

-- ---------- 6.6 Character helpers ----------
local function applyInvisibility(char, state)
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("MeshPart") then
            part.Transparency = state and 1 or 0
        end
    end
end

local function applyCharacterSettings(char)
    if Settings.FlyEnabled or Settings.NoclipEnabled then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    hum.WalkSpeed = Settings.WalkSpeed
    hum.JumpPower = Settings.JumpPower
    workspace.Gravity = Settings.Gravity
    if Settings.Invisible then applyInvisibility(char, true) end
    if Settings.GodModeEnabled then
        hum.MaxHealth = math.huge
        hum.Health = math.huge
    end
end

-- ---------- 6.7 Movement ----------
local Movement = { connection = nil, velocity = nil, bodyVelocity = nil }
local infiniteJumpConn = nil
local antiFlingConn = nil
local antiVoidConn = nil
local godModeConn = nil

local function clearMovement()
    local char = localPlayer.Character
    if char then
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.PlatformStand = false end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
    if Movement.connection then Movement.connection:Disconnect() end
    if Movement.bodyVelocity then Movement.bodyVelocity:Destroy() end
    Movement.connection = nil
    Movement.bodyVelocity = nil
    Movement.velocity = nil

    local c = localPlayer.Character
    if c then pcall(applyCharacterSettings, c) end
end

local function startNoclip()
    clearMovement()
    local char = localPlayer.Character
    if not char then return end
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not hrp or not hum then return end

    hum.PlatformStand = true
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end

    Movement.velocity = Vector3.zero
    Movement.connection = RunService.RenderStepped:Connect(function(dt)
        if not Settings.NoclipEnabled then return end
        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.yAxis end        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.yAxis end
        if moveDir.Magnitude > 0 then
            Movement.velocity = Movement.velocity:Lerp(moveDir.Unit * Settings.NoclipSpeed, 9 * dt)
        else
            Movement.velocity = Movement.velocity:Lerp(Vector3.zero, 7 * dt)
        end
        hrp.CFrame += Movement.velocity * dt
    end)
end

local function startFly()
    clearMovement()
    local char = localPlayer.Character
    if not char then return end
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not hrp or not hum then return end

    hum.PlatformStand = true
    Movement.bodyVelocity = Instance.new("BodyVelocity")
    Movement.bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    Movement.bodyVelocity.Velocity = Vector3.zero
    Movement.bodyVelocity:SetAttribute("_DonkeyOwned", true)
    Movement.bodyVelocity.Parent = hrp

    Movement.connection = RunService.RenderStepped:Connect(function()
        if not Settings.FlyEnabled then return end
        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.yAxis end
        Movement.bodyVelocity.Velocity =
            moveDir.Magnitude > 0 and moveDir.Unit * Settings.FlySpeed or Vector3.zero
    end)
end

local function startInfiniteJump()
    if infiniteJumpConn then return end
    infiniteJumpConn = UserInputService.JumpRequest:Connect(function()
        if not Settings.InfiniteJumpEnabled then return end
        local char = localPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if not hum then return end
        if hum:GetState() == Enum.HumanoidStateType.Jumping
            or hum:GetState() == Enum.HumanoidStateType.Freefall then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

local function stopInfiniteJump()
    if infiniteJumpConn then
        infiniteJumpConn:Disconnect()
        infiniteJumpConn = nil
    end
end

local function startAntiFling()
    if antiFlingConn then return end
    antiFlingConn = RunService.Heartbeat:Connect(function()
        if not Settings.AntiFlingEnabled then return end
        -- Don't fight our own movement features
        if Settings.FlyEnabled or Settings.NoclipEnabled then return end
        local char = localPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        for _, v in ipairs(hrp:GetChildren()) do
            if not v:GetAttribute("_DonkeyOwned") then
                if v:IsA("BodyVelocity") or v:IsA("BodyAngularVelocity")
                    or v:IsA("BodyGyro") or v:IsA("BodyPosition")
                    or v:IsA("LinearVelocity") or v:IsA("AngularVelocity") then
                    v:Destroy()
                end
            end
        end
    end)
end

local function stopAntiFling()
    if antiFlingConn then
        antiFlingConn:Disconnect()
        antiFlingConn = nil
    end
end

local function startAntiVoid()
    if antiVoidConn then return end
    antiVoidConn = RunService.Heartbeat:Connect(function()
        if not Settings.AntiVoidEnabled then return end
        local char = localPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if hrp.Position.Y < -100 then
            local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
            if spawn then
                hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
            else
                hrp.CFrame = CFrame.new(0, 50, 0)
            end
        end
    end)
end

local function stopAntiVoid()
    if antiVoidConn then
        antiVoidConn:Disconnect()
        antiVoidConn = nil
    end
end

local function enableFullbright()
    if savedLighting then return end
    savedLighting = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness,
        GlobalShadows = Lighting.GlobalShadows,
    }
    Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
    Lighting.Brightness = 2
    Lighting.GlobalShadows = false
end

local function disableFullbright()
    if not savedLighting then return end
    Lighting.Ambient = savedLighting.Ambient
    Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
    Lighting.Brightness = savedLighting.Brightness
    Lighting.GlobalShadows = savedLighting.GlobalShadows
    savedLighting = nil
end

local function enableNoFog()
    if savedFog then return end
    savedFog = {
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
    }
    Lighting.FogEnd = 1e6
    Lighting.FogStart = 0
end

local function disableNoFog()
    if not savedFog then return end
    Lighting.FogEnd = savedFog.FogEnd
    Lighting.FogStart = savedFog.FogStart
    savedFog = nil
end

local function enableGodMode()
    local char = localPlayer.Character
    if char then
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if hum then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
        end
    end
    if godModeConn then return end
    godModeConn = RunService.Heartbeat:Connect(function()
        if not Settings.GodModeEnabled then return end
        local c = localPlayer.Character
        if c then
            local hum = c:FindFirstChildWhichIsA("Humanoid")
            if hum then
                if hum.MaxHealth ~= math.huge then hum.MaxHealth = math.huge end
                if hum.Health ~= math.huge then hum.Health = math.huge end
            end
        end
    end)
end

local function disableGodMode()
    if godModeConn then
        godModeConn:Disconnect()
        godModeConn = nil
    end
    local char = localPlayer.Character
    if char then
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if hum then
            hum.MaxHealth = 100
            if hum.Health > 100 then hum.Health = 100 end
        end
    end
end

local function toggleNoclip(forceState, silent)
    local newState = forceState
    if newState == nil then newState = not Settings.NoclipEnabled end
    Settings.NoclipEnabled = newState
    if newState then
        if Settings.FlyEnabled then
            Settings.FlyEnabled = false
            if flyToggleAPI then flyToggleAPI.SetState(false, true) end
        end
        startNoclip()
    else
        clearMovement()
    end
    if noclipToggleAPI then noclipToggleAPI.SetState(newState, true) end

    if not silent then
        toast("Noclip " .. (newState and "ON" or "OFF"),
            newState and Theme.Accent or Theme.TextDim)
        task.spawn(saveSettings)
    end
end

local function toggleFly(forceState, silent)
    local newState = forceState
    if newState == nil then newState = not Settings.FlyEnabled end
    Settings.FlyEnabled = newState
    if newState then
        if Settings.NoclipEnabled then
            Settings.NoclipEnabled = false
            if noclipToggleAPI then noclipToggleAPI.SetState(false, true) end
        end
        startFly()
    else
        clearMovement()
    end
    if flyToggleAPI then flyToggleAPI.SetState(newState, true) end

    if not silent then
        toast("Fly " .. (newState and "ON" or "OFF"),
            newState and Theme.Accent or Theme.TextDim)
        task.spawn(saveSettings)
    end
end

-- ---------- 6.7.5 Combat Enhancements (v9.0) ----------

local function isWeaponAllowed(tool)
    if not tool then return false end
    local empty = true
    for _ in pairs(WeaponWhitelist) do empty = false break end
    if empty then return true end
    return WeaponWhitelist[tool.Name] == true
end

local function startRapidFire()
    if rapidFireConn then return end
    rapidFireConn = RunService.Heartbeat:Connect(function()
        if not Settings.RapidFireEnabled then return end
        local char = localPlayer.Character
        if not char then return end
        local tool = char:FindFirstChildWhichIsA("Tool")
        if not tool or not tool.Enabled then return end
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            pcall(function() tool:Activate() end)
        end
    end)
end

local function stopRapidFire()
    if rapidFireConn then
        rapidFireConn:Disconnect()
        rapidFireConn = nil
    end
end

local function startNoRecoil()
    if noRecoilConn then return end
    noRecoilConn = RunService.RenderStepped:Connect(function()
        if not Settings.NoRecoilEnabled then return end
        -- Nudge camera pitch to 0 (horizontal)
        local cam = camera.CFrame
        local _, yaw, _ = cam:ToOrientation()
        local target = CFrame.new(cam.Position) * CFrame.Angles(0, yaw, 0)
        camera.CFrame = cam:Lerp(target, 0.15)
    end)
end

local function stopNoRecoil()
    if noRecoilConn then
        noRecoilConn:Disconnect()
        noRecoilConn = nil
    end
end

-- Hit marker UI
local function createHitMarker()
    local marker = Instance.new("Frame")
    marker.Name = "HitMarker"
    marker.Size = UDim2.new(0, 22, 0, 22)
    marker.AnchorPoint = Vector2.new(0.5, 0.5)
    marker.Position = UDim2.new(0.5, 0, 0.5, 0)
    marker.BackgroundTransparency = 1
    marker.ZIndex = 200
    marker.Visible = false
    marker.Parent = screenGui

    for _, rot in ipairs({45, 135, 225, 315}) do
        local stroke = Instance.new("Frame")
        stroke.Size = UDim2.new(0, 2, 0, 8)
        stroke.AnchorPoint = Vector2.new(0.5, 1)
        stroke.Position = UDim2.new(0.5, 0, 0.5, 0)
        stroke.Rotation = rot
        stroke.BackgroundColor3 = Theme.Danger
        stroke.BorderSizePixel = 0
        stroke.Parent = marker
    end
    return marker
end

local function showHitMarker()
    if not Settings.HitMarkerEnabled then return end
    if not hitMarkerUI then
        hitMarkerUI = createHitMarker()
    end
    hitMarkerUI.Visible = true
    for _, c in ipairs(hitMarkerUI:GetChildren()) do
        if c:IsA("Frame") then
            c.BackgroundTransparency = 0
        end
    end
    task.delay(0.15, function()
        if hitMarkerUI then
            for _, c in ipairs(hitMarkerUI:GetChildren()) do
                if c:IsA("Frame") then
                    TweenService:Create(c, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
                end
            end
            task.delay(0.16, function()
                if hitMarkerUI then hitMarkerUI.Visible = false end
            end)
        end
    end)
end

local function startHitMarker()
    if hitMarkerConn then return end
    hitMarkerConn = RunService.Heartbeat:Connect(function()
        if not Settings.HitMarkerEnabled then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Character then
                local hum = player.Character:FindFirstChildWhichIsA("Humanoid")
                if hum then
                    local prev = lastHealthSnapshot[player] or hum.MaxHealth
                    if hum.Health < prev and hum.Health > 0 then
                        local target = silentAimTarget
                        if target then
                            local char = target:FindFirstAncestorOfClass("Model")
                            if char == player.Character then
                                showHitMarker()
                            end
                        end
                    end
                    lastHealthSnapshot[player] = hum.Health
                end
            end
        end
    end)
end

local function stopHitMarker()
    if hitMarkerConn then
        hitMarkerConn:Disconnect()
        hitMarkerConn = nil
    end
end

-- Kill notifier
local function createKillNotifier()
    local notif = Instance.new("Frame")
    notif.Name = "KillNotifier"
    notif.Size = UDim2.new(0, 240, 0, 40)
    notif.Position = UDim2.new(0.5, -120, 0.3, 0)
    notif.BackgroundColor3 = Theme.Panel
    notif.BackgroundTransparency = 0.2
    notif.BorderSizePixel = 0
    notif.ZIndex = 150
    notif.Visible = false
    notif.Parent = screenGui
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Accent
    stroke.Thickness = 2
    stroke.Parent = notif

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.Size = UDim2.new(1, -20, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = ""
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.Parent = notif

    return notif
end

local function showKillNotifier(victimName)
    if not Settings.KillNotifierEnabled then return end
    if not killNotifierUI then
        killNotifierUI = createKillNotifier()
    end
    local lbl = killNotifierUI:FindFirstChild("Label")
    if lbl then lbl.Text = "KILL · " .. victimName end
    killNotifierUI.Visible = true
    killNotifierUI.Position = UDim2.new(0.5, -120, 0.3, 0)
    TweenService:Create(killNotifierUI, TweenInfo.new(0.2), {
        Position = UDim2.new(0.5, -120, 0.3, -10)
    }):Play()
    task.delay(1.8, function()
        if killNotifierUI then
            TweenService:Create(killNotifierUI, TweenInfo.new(0.3), {
                Position = UDim2.new(0.5, -120, 0.3, -20)
            }):Play()
            task.delay(0.31, function()
                if killNotifierUI then killNotifierUI.Visible = false end
            end)
        end
    end)

    if Settings.KillSoundEnabled then
        pcall(function()
            local snd = Instance.new("Sound")
            snd.SoundId = "rbxasset://sounds/electronicpingshort.wav"
            snd.Volume = 0.5
            snd.Parent = SoundService
            snd:Play()
            task.delay(1, function() snd:Destroy() end)
        end)
    end
end

-- ---------- 6.8 Trigger bot ----------
local TriggerBot = { lastFire = 0, debugDot = nil }

local TRIGGER_PART_NAMES = {
    Head = true, HumanoidRootPart = true,
    UpperTorso = true, LowerTorso = true, Torso = true,
}

local triggerParts = {}
local function cacheTriggerParts(player, char)
    local list = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and TRIGGER_PART_NAMES[part.Name] then
            table.insert(list, part)
        end
    end
    triggerParts[player] = list
end

local function worldToScreen(worldPos)
    local sp, onScreen = camera:WorldToViewportPoint(worldPos)
    if not onScreen then return nil end
    return Vector2.new(sp.X, sp.Y)
end

local function findTriggerTarget()
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local bestPlayer, bestPart, bestDist = nil, nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and isEnemy(player) then
            local parts = triggerParts[player]
            if parts then
                for _, part in ipairs(parts) do
                    if part.Parent then
                        local sp = worldToScreen(part.Position)
                        if sp then
                            local d = (sp - center).Magnitude
                            if d < bestDist and d <= Settings.TriggerBotFOVPixels then
                                if isVisible(part) then
                                    bestDist, bestPlayer, bestPart = d, player, part
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return bestPlayer, bestPart, bestDist
end

local function fireWeapon()
    local char = localPlayer.Character
    if not char then return false end
    local tool = char:FindFirstChildWhichIsA("Tool")
    if tool then
        if tool.Enabled == false then return false end
        if not isWeaponAllowed(tool) then return false end
        local ok = pcall(function() tool:Activate() end)
        if ok then return true end
        for _, child in ipairs(tool:GetDescendants()) do
            if child:IsA("RemoteEvent") then
                local fired = pcall(function() child:FireServer("Fire") end)
                if fired then return true end
            end
        end
    end
    for _, name in ipairs({ "Fire", "Shoot", "FireWeapon", "Attack" }) do
        local remote = localPlayer:FindFirstChild(name)
            or (char and char:FindFirstChild(name))
            or ReplicatedStorage:FindFirstChild(name, true)
        if remote and remote:IsA("RemoteEvent") then
            local ok = pcall(function() remote:FireServer() end)
            if ok then return true end
        end
    end
    return false
end

local function createTriggerDot()
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = UDim2.new(0.5, 0, 0.5, 0)
    dot.BackgroundColor3 = Theme.Danger
    dot.BorderSizePixel = 0
    dot.BackgroundTransparency = 0.3
    dot.ZIndex = 100
    dot.Parent = screenGui
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    return dot
end

local function toggleTriggerBot(forceState, silent)
    local newState = forceState
    if newState == nil then newState = not Settings.TriggerBotEnabled end
    Settings.TriggerBotEnabled = newState

    if newState then
        if not TriggerBot.debugDot then
            TriggerBot.debugDot = createTriggerDot()
        end
        TriggerBot.debugDot.Visible = true
    else
        if TriggerBot.debugDot then TriggerBot.debugDot:Destroy() TriggerBot.debugDot = nil end
    end

    if triggerToggleAPI then triggerToggleAPI.SetState(newState, true) end

    if not silent then
        toast("Trigger Bot " .. (newState and "ON" or "OFF"),
            newState and Theme.Accent or Theme.TextDim)
        task.spawn(saveSettings)
    end
end

-- ---------- 6.9 Phase view ----------
local PhaseView = { active = false, parts = {} }

local function enablePhaseView()
    if PhaseView.active then return end
    PhaseView.active = true
    PhaseView.parts = {}
    local myChar = localPlayer.Character
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency < 1
            and not (myChar and part:IsDescendantOf(myChar)) then
            PhaseView.parts[part] = {
                Transparency = part.Transparency,
                CanCollide = part.CanCollide,
            }
            part.Transparency = math.clamp(part.Transparency + 0.6, 0, 1)
            part.CanCollide = false
        end
    end
end

local function disablePhaseView()
    if not PhaseView.active then return end
    PhaseView.active = false
    for part, data in pairs(PhaseView.parts) do
        if part and part.Parent then
            part.Transparency = data.Transparency
            part.CanCollide = data.CanCollide
        end
    end
    PhaseView.parts = {}
end

-- ============================================================
-- 7. UI LAYER
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DonkeyMenu"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local toastContainer = Instance.new("Frame")
toastContainer.Size = UDim2.new(0, 260, 1, -80)
toastContainer.Position = UDim2.new(1, -270, 0, 60)
toastContainer.BackgroundTransparency = 1
toastContainer.Parent = screenGui

local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 6)
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.Parent = toastContainer

local toastHistory = {}

local function toast(message, color)
    if not Settings.ToastEnabled then return end
    table.insert(toastHistory, { text = message, color = color or Theme.Accent, time = os.clock() })
    if #toastHistory > 20 then table.remove(toastHistory, 1) end

    local toastFrame = Instance.new("Frame")
    toastFrame.Size = UDim2.new(0, 240, 0, 34)
    toastFrame.BackgroundColor3 = Theme.Panel
    toastFrame.BackgroundTransparency = 1
    toastFrame.BorderSizePixel = 0
    toastFrame.Parent = toastContainer
    Instance.new("UICorner", toastFrame).CornerRadius = UDim.new(0, 8)

    local toastStroke = Instance.new("UIStroke")
    toastStroke.Color = color or Theme.Accent
    toastStroke.Thickness = 1
    toastStroke.Transparency = 1
    toastStroke.Parent = toastFrame

    local accentStripe = Instance.new("Frame")
    accentStripe.Size = UDim2.new(0, 3, 1, -12)
    accentStripe.Position = UDim2.new(0, 6, 0, 6)
    accentStripe.BackgroundColor3 = color or Theme.Accent
    accentStripe.BorderSizePixel = 0
    accentStripe.BackgroundTransparency = 1
    accentStripe.Parent = toastFrame
    Instance.new("UICorner", accentStripe).CornerRadius = UDim.new(1, 0)

    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -24, 1, 0)
    msg.Position = UDim2.new(0, 16, 0, 0)
    msg.BackgroundTransparency = 1
    msg.Text = message
    msg.TextColor3 = Theme.Text
    msg.Font = Enum.Font.GothamMedium
    msg.TextSize = 12
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.TextTransparency = 1
    msg.Parent = toastFrame

    toastFrame.Position = UDim2.new(0, 20, 0, 0)
    TweenService:Create(toastFrame, TweenInfo.new(0.2), { BackgroundTransparency = 0.15, Position = UDim2.new(0, 0, 0, 0) }):Play()
    TweenService:Create(toastStroke, TweenInfo.new(0.2), { Transparency = 0.4 }):Play()
    TweenService:Create(accentStripe, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
    TweenService:Create(msg, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()

    task.delay(2.2, function()
        if not toastFrame.Parent then return end
        TweenService:Create(toastFrame, TweenInfo.new(0.25), { BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 0) }):Play()
        TweenService:Create(toastStroke, TweenInfo.new(0.25), { Transparency = 1 }):Play()
        TweenService:Create(accentStripe, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(msg, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
        task.wait(0.3)
        toastFrame:Destroy()
    end)
end

local PANEL_W, PANEL_H = 520, 440

local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
root.Position = UDim2.new(0, -PANEL_W - 20, 0, 60)
root.BackgroundColor3 = Theme.Background
root.BorderSizePixel = 0
root.Parent = screenGui
Instance.new("UICorner", root).CornerRadius = UDim.new(0, 14)

local rootStroke = Instance.new("UIStroke")
rootStroke.Color = Theme.Border
rootStroke.Thickness = 1
rootStroke.Transparency = 0.3
rootStroke.Parent = root

local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(0, 3, 1, -24)
accentBar.Position = UDim2.new(0, 6, 0, 12)
accentBar.BackgroundColor3 = Theme.Accent
accentBar.BorderSizePixel = 0
accentBar.Parent = root
Instance.new("UICorner", accentBar).CornerRadius = UDim.new(1, 0)

task.spawn(function()
    TweenService:Create(
        root,
        TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Position = UDim2.new(0, 60, 0, 60) }
    ):Play()
end)

local function makeDraggable(gui)
    local dragging, dragStart, startPos = false, nil, nil
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, dragStart, startPos = true, input.Position, gui.Position
        end
    end)
    gui.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end
makeDraggable(root)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = Theme.Panel
header.BorderSizePixel = 0
header.Parent = root
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

local headerFlatten = Instance.new("Frame")
headerFlatten.Size = UDim2.new(1, 0, 0, 14)
headerFlatten.Position = UDim2.new(0, 0, 1, -14)
headerFlatten.BackgroundColor3 = Theme.Panel
headerFlatten.BorderSizePixel = 0
headerFlatten.Parent = header

local logo = Instance.new("TextLabel")
logo.Size = UDim2.new(0, 40, 0, 40)
logo.Position = UDim2.new(0, 12, 0, 4)
logo.BackgroundTransparency = 1
logo.Text = "◉"
logo.TextColor3 = Theme.Accent
logo.Font = Enum.Font.GothamBlack
logo.TextSize = 26
logo.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 220, 0, 22)
title.Position = UDim2.new(0, 52, 0, 8)
title.BackgroundTransparency = 1
title.Text = "DONKEY"
title.TextColor3 = Theme.Text
title.Font = Enum.Font.GothamBlack
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(0, 220, 0, 14)
subtitle.Position = UDim2.new(0, 52, 0, 26)
subtitle.BackgroundTransparency = 1
subtitle.Text = "v9.0 · " .. PersistBackend
subtitle.TextColor3 = Theme.TextMuted
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local historyBtn = Instance.new("TextButton")
historyBtn.Size = UDim2.new(0, 30, 0, 30)
historyBtn.Position = UDim2.new(1, -108, 0, 9)
historyBtn.BackgroundColor3 = Theme.PanelLight
historyBtn.TextColor3 = Theme.TextDim
historyBtn.Font = Enum.Font.GothamBold
historyBtn.TextSize = 14
historyBtn.Text = "≡"
historyBtn.AutoButtonColor = false
historyBtn.Parent = header
Instance.new("UICorner", historyBtn).CornerRadius = UDim.new(0, 8)

historyBtn.MouseEnter:Connect(function()
    TweenService:Create(historyBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.AccentDim }):Play()
end)
historyBtn.MouseLeave:Connect(function()
    TweenService:Create(historyBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.PanelLight }):Play()
end)

local historyPanel = Instance.new("Frame")
historyPanel.Size = UDim2.new(0, 300, 0, 200)
historyPanel.Position = UDim2.new(1, -310, 0, 48)
historyPanel.BackgroundColor3 = Theme.Panel
historyPanel.BorderSizePixel = 0
historyPanel.Visible = false
historyPanel.ZIndex = 50
historyPanel.Parent = root
Instance.new("UICorner", historyPanel).CornerRadius = UDim.new(0, 10)

local historyStroke = Instance.new("UIStroke")
historyStroke.Color = Theme.Border
historyStroke.Thickness = 1
historyStroke.Transparency = 0.3
historyStroke.Parent = historyPanel

local historyTitle = Instance.new("TextLabel")
historyTitle.Size = UDim2.new(1, -20, 0, 24)
historyTitle.Position = UDim2.new(0, 10, 0, 4)
historyTitle.BackgroundTransparency = 1
historyTitle.Text = "Recent Notifications"
historyTitle.TextColor3 = Theme.TextDim
historyTitle.Font = Enum.Font.GothamBold
historyTitle.TextSize = 11
historyTitle.TextXAlignment = Enum.TextXAlignment.Left
historyTitle.Parent = historyPanel

local historyScroll = Instance.new("ScrollingFrame")
historyScroll.Size = UDim2.new(1, -16, 1, -34)
historyScroll.Position = UDim2.new(0, 8, 0, 28)
historyScroll.BackgroundTransparency = 1
historyScroll.BorderSizePixel = 0
historyScroll.ScrollBarThickness = 3
historyScroll.ScrollBarImageColor3 = Theme.AccentDim
historyScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
historyScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
historyScroll.Parent = historyPanel

local historyLayout = Instance.new("UIListLayout")
historyLayout.Padding = UDim.new(0, 4)
historyLayout.SortOrder = Enum.SortOrder.LayoutOrder
historyLayout.Parent = historyScroll

local function refreshHistoryPanel()
    for _, child in ipairs(historyScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for i = #toastHistory, 1, -1 do
        local entry = toastHistory[i]
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 22)
        row.BackgroundColor3 = Theme.PanelLight
        row.BorderSizePixel = 0
        row.LayoutOrder = #toastHistory - i
        row.Parent = historyScroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

        local stripe = Instance.new("Frame")
        stripe.Size = UDim2.new(0, 3, 1, -6)
        stripe.Position = UDim2.new(0, 3, 0, 3)
        stripe.BackgroundColor3 = entry.color
        stripe.BorderSizePixel = 0
        stripe.Parent = row
        Instance.new("UICorner", stripe).CornerRadius = UDim.new(1, 0)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -14, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = entry.text
        lbl.TextColor3 = Theme.Text
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row
    end
end

historyBtn.MouseButton1Click:Connect(function()
    historyPanel.Visible = not historyPanel.Visible
    if historyPanel.Visible then refreshHistoryPanel() end
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 9)
closeBtn.BackgroundColor3 = Theme.PanelLight
closeBtn.TextColor3 = Theme.TextDim
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Text = "×"
closeBtn.AutoButtonColor = false
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Danger }):Play()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(255,255,255) }):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.PanelLight }):Play()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), { TextColor3 = Theme.TextDim }):Play()
end)
closeBtn.MouseButton1Click:Connect(function()
    root.Visible = false
    capsState = 2
end)

local TAB_HEIGHT = 34
local TABS = { "Combat", "Visuals", "Movement", "Character", "Players", "Info", "Settings" }
local tabButtons = {}
local tabFrames = {}
local activeTab = Settings.ActiveTab or "Combat"

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -24, 0, TAB_HEIGHT)
tabBar.Position = UDim2.new(0, 12, 0, 56)
tabBar.BackgroundTransparency = 1
tabBar.Parent = root

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabBar

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -24, 1, -TAB_HEIGHT - 92)
contentFrame.Position = UDim2.new(0, 12, 0, 96)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = root

for _, name in ipairs(TABS) do
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Theme.AccentDim
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Visible = false
    scroll.Parent = contentFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 4)
    pad.Parent = scroll

    tabFrames[name] = scroll
end

for i, name in ipairs(TABS) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 68, 1, 0)
    btn.BackgroundColor3 = Theme.Panel
    btn.TextColor3 = Theme.TextDim
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 11
    btn.Text = name
    btn.AutoButtonColor = false
    btn.LayoutOrder = i
    btn.Parent = tabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseEnter:Connect(function()
        if activeTab ~= name then
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.PanelAccent }):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTab ~= name then
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Panel }):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function()
        activeTab = name
        Settings.ActiveTab = name
        for tname, tbtn in pairs(tabButtons) do
            if tname == activeTab then
                TweenService:Create(tbtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.PanelAccent, TextColor3 = Theme.Accent }):Play()
            else
                TweenService:Create(tbtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Panel, TextColor3 = Theme.TextDim }):Play()
            end
        end
        for tname, sf in pairs(tabFrames) do
            sf.Visible = (tname == activeTab)
        end
        task.spawn(saveSettings)
    end)

    tabButtons[name] = btn
end

for tname, tbtn in pairs(tabButtons) do
    if tname == activeTab then
        tbtn.BackgroundColor3 = Theme.PanelAccent
        tbtn.TextColor3 = Theme.Accent
    end
end
for tname, sf in pairs(tabFrames) do
    sf.Visible = (tname == activeTab)
end

local ROW_H = 34

local function sectionHeader(parent, text, layoutOrder)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, -8, 0, 20)
    h.BackgroundTransparency = 1
    h.LayoutOrder = layoutOrder
    h.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "▎ " .. text:upper()
    lbl.TextColor3 = Theme.TextMuted
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = h
    return h
end

local function toggleRow(parent, label, initial, layoutOrder, onChange, hotkeyName)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, ROW_H)
    row.BackgroundColor3 = Theme.Panel
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    row.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.12), { BackgroundColor3 = Theme.PanelLight }):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Panel }):Play()
    end)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -100, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    if hotkeyName and Hotkeys[hotkeyName] then
        local badge = Instance.new("TextLabel")
        badge.Size = UDim2.new(0, 26, 0, 18)
        badge.Position = UDim2.new(1, -134, 0, 8)
        badge.BackgroundColor3 = Theme.PanelAccent
        badge.TextColor3 = Theme.TextDim
        badge.Font = Enum.Font.GothamBold
        badge.TextSize = 10
        badge.Text = Hotkeys[hotkeyName].Name
        badge.Parent = row
        Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)
        hotkeyBadges[hotkeyName] = badge
    end

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 42, 0, 22)
    switch.Position = UDim2.new(1, -56, 0, 6)
    switch.BackgroundColor3 = initial and Theme.Accent or Theme.PanelAccent
    switch.Text = ""
    switch.AutoButtonColor = false
    switch.Parent = row
    Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = initial and UDim2.new(1, -20, 0, 3) or UDim2.new(0, 3, 0, 3)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = switch
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = initial
    local function setState(newState, silent)
        state = newState
        local targetPos = state and UDim2.new(1, -20, 0, 3) or UDim2.new(0, 3, 0, 3)
        TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quint), { Position = targetPos }):Play()
        TweenService:Create(switch, TweenInfo.new(0.18), { BackgroundColor3 = state and Theme.Accent or Theme.PanelAccent }):Play()
        if not silent and onChange then onChange(state) end
    end

    switch.MouseButton1Click:Connect(function()
        setState(not state, false)
        task.spawn(saveSettings)
    end)

    return {
        SetState = setState,
        GetState = function() return state end,
        Row = row,
    }
end

local function sliderRow(parent, label, minV, maxV, initial, layoutOrder, format, onChange)
    format = format or function(v) return tostring(math.floor(v)) end

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, ROW_H + 18)
    row.BackgroundColor3 = Theme.Panel
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, 0, 0, 20)
    lbl.Position = UDim2.new(0, 14, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local valueLbl = Instance.new("TextLabel")
    valueLbl.Size = UDim2.new(0.4, -14, 0, 20)
    valueLbl.Position = UDim2.new(0.6, 0, 0, 6)
    valueLbl.BackgroundTransparency = 1
    valueLbl.Text = format(initial)
    valueLbl.TextColor3 = Theme.Accent
    valueLbl.Font = Enum.Font.GothamBold
    valueLbl.TextSize = 12
    valueLbl.TextXAlignment = Enum.TextXAlignment.Right
    valueLbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 6)
    track.Position = UDim2.new(0, 14, 0, 30)
    track.BackgroundColor3 = Theme.PanelAccent
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = Theme.Text
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false

    local function applyFromX(x)
        local ratio = math.clamp(x / track.AbsoluteSize.X, 0, 1)
        local value = minV + (maxV - minV) * ratio
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, 0)
        valueLbl.Text = format(value)
        if onChange then onChange(value) end
    end

    local function setValue(v, silent)
        local ratio = math.clamp((v - minV) / (maxV - minV), 0, 1)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, 0)
        valueLbl.Text = format(v)
        if not silent and onChange then onChange(v) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            applyFromX(input.Position.X - track.AbsolutePosition.X)
        end
    end)
    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            task.spawn(saveSettings)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            applyFromX(input.Position.X - track.AbsolutePosition.X)
        end
    end)

    setValue(initial, true)
    return { SetValue = setValue, Row = row }
end

local function actionRow(parent, label, layoutOrder, onClick, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, ROW_H)
    btn.BackgroundColor3 = Theme.Panel
    btn.TextColor3 = color or Theme.Text
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.Text = label
    btn.AutoButtonColor = false
    btn.LayoutOrder = layoutOrder
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.PanelLight }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.Panel }):Play()
    end)
    btn.MouseButton1Click:Connect(onClick)
    return btn
end

local function textInputRow(parent, placeholder, layoutOrder, onChange)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, ROW_H)
    row.BackgroundColor3 = Theme.Panel
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -20, 1, -8)
    box.Position = UDim2.new(0, 10, 0, 4)
    box.BackgroundTransparency = 1
    box.Text = ""
    box.PlaceholderText = placeholder
    box.TextColor3 = Theme.Text
    box.PlaceholderColor3 = Theme.TextMuted
    box.Font = Enum.Font.GothamMedium
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Parent = row

    box:GetPropertyChangedSignal("Text"):Connect(function()
        if onChange then onChange(box.Text) end
    end)

    return box
end

local function hotkeyRow(parent, actionName, layoutOrder)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, ROW_H)
    row.BackgroundColor3 = Theme.Panel
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = actionName
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.new(0, 90, 0, 22)
    keyBtn.Position = UDim2.new(1, -104, 0, 6)
    keyBtn.BackgroundColor3 = Theme.PanelAccent
    keyBtn.TextColor3 = Theme.Accent
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 11
    keyBtn.Text = Hotkeys[actionName] and Hotkeys[actionName].Name or "?"
    keyBtn.AutoButtonColor = false
    keyBtn.Parent = row
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 5)

    keyBtn.MouseButton1Click:Connect(function()
        listeningAction = actionName
        keyBtn.Text = "..."
        keyBtn.TextColor3 = Theme.Warning
    end)

    return { row = row, keyBtn = keyBtn }
end

-- ============================================================
-- 8. TAB CONTENT
-- ============================================================

-- ---------- Combat ----------
do
    local tab = tabFrames.Combat
    local order = 0
    local function o() order += 1 return order end

    sectionHeader(tab, "Aimlock", o())
    aimToggleAPI = toggleRow(tab, "Aimlock", Settings.AimlockEnabled, o(), function(state)
        Settings.AimlockEnabled = state
        fovCircle.Visible = state
        toast("Aimlock " .. (state and "ON" or "OFF"), state and Theme.Accent or Theme.TextDim)
    end, "Aimlock")

    sliderRow(tab, "Aim Smoothness", 0.02, 1.0, Settings.AimSmoothness, o(),
        function(v) return string.format("%.2f", v) end,
        function(v) Settings.AimSmoothness = v end)

    sliderRow(tab, "Aim FOV", 10, 360, Settings.AimlockFOV, o(),
        function(v) return math.floor(v) .. "°" end,
        function(v) Settings.AimlockFOV = v end)

    sliderRow(tab, "Aim Distance", 10, 1000, Settings.AimlockDistance, o(),
        function(v) return math.floor(v) .. "m" end,
        function(v)
            Settings.AimlockDistance = v
            fovCircle.Size = UDim2.new(0, v, 0, v)
        end)

    sliderRow(tab, "Prediction", 0.0, 0.5, Settings.PredictionStrength, o(),
        function(v) return string.format("%.2f", v) end,
        function(v) Settings.PredictionStrength = v end)

    -- Aim Target Selector
    sectionHeader(tab, "Aim Target", o())
    local modeRow = Instance.new("Frame")
    modeRow.Size = UDim2.new(1, -8, 0, ROW_H)
    modeRow.BackgroundColor3 = Theme.Panel
    modeRow.BorderSizePixel = 0
    modeRow.LayoutOrder = o()
    modeRow.Parent = tab
    Instance.new("UICorner", modeRow).CornerRadius = UDim.new(0, 8)

    local modeHolder = Instance.new("Frame")
    modeHolder.Size = UDim2.new(1, -20, 0, 24)
    modeHolder.Position = UDim2.new(0, 10, 0, 5)
    modeHolder.BackgroundTransparency = 1
    modeHolder.Parent = modeRow

    local modeLayout = Instance.new("UIListLayout")
    modeLayout.FillDirection = Enum.FillDirection.Horizontal
    modeLayout.Padding = UDim.new(0, 4)
    modeLayout.Parent = modeHolder

    local modeButtons = {}
    local MODES = { "Head", "Torso", "Nearest", "NearestVisible" }
    local MODE_LABELS = { Head = "Head", Torso = "Torso", Nearest = "Near", NearestVisible = "Vis" }

    local function refreshModeButtons()
        for m, btn in pairs(modeButtons) do
            if m == Settings.AimTargetMode then
                TweenService:Create(btn, TweenInfo.new(0.15), {
                    BackgroundColor3 = Theme.Accent,
                    TextColor3 = Theme.Background,
                }):Play()
            else
                TweenService:Create(btn, TweenInfo.new(0.15), {
                    BackgroundColor3 = Theme.PanelAccent,
                    TextColor3 = Theme.TextDim,
                }):Play()
            end
        end
    end

    for _, mode in ipairs(MODES) do
        local mb = Instance.new("TextButton")
        mb.Size = UDim2.new(0, 60, 1, 0)
        mb.BackgroundColor3 = Theme.PanelAccent
        mb.TextColor3 = Theme.TextDim
        mb.Font = Enum.Font.GothamBold
        mb.TextSize = 11
        mb.Text = MODE_LABELS[mode] or mode
        mb.AutoButtonColor = false
        mb.Parent = modeHolder
        Instance.new("UICorner", mb).CornerRadius = UDim.new(0, 5)
        modeButtons[mode] = mb
        mb.MouseButton1Click:Connect(function()
            Settings.AimTargetMode = mode
            refreshModeButtons()
            task.spawn(saveSettings)
        end)
    end
    refreshModeButtons()

    -- Aim Curve
    sectionHeader(tab, "Aim Curve", o())
    local curveRow = Instance.new("Frame")
    curveRow.Size = UDim2.new(1, -8, 0, ROW_H)
    curveRow.BackgroundColor3 = Theme.Panel
    curveRow.BorderSizePixel = 0
    curveRow.LayoutOrder = o()
    curveRow.Parent = tab
    Instance.new("UICorner", curveRow).CornerRadius = UDim.new(0, 8)

    local curveHolder = Instance.new("Frame")
    curveHolder.Size = UDim2.new(1, -20, 0, 24)
    curveHolder.Position = UDim2.new(0, 10, 0, 5)
    curveHolder.BackgroundTransparency = 1
    curveHolder.Parent = curveRow

    local curveLayout = Instance.new("UIListLayout")
    curveLayout.FillDirection = Enum.FillDirection.Horizontal
    curveLayout.Padding = UDim.new(0, 4)
    curveLayout.Parent = curveHolder

    local curveButtons = {}
    local CURVES = { "Linear", "EaseOut", "EaseInOut", "Snap" }
    local CURVE_LABELS = { Linear = "Linear", EaseOut = "Out", EaseInOut = "In/Out", Snap = "Snap" }

    local function refreshCurveButtons()
        for c, btn in pairs(curveButtons) do
            if c == Settings.AimCurve then
                TweenService:Create(btn, TweenInfo.new(0.15), {
                    BackgroundColor3 = Theme.Accent,
                    TextColor3 = Theme.Background,
                }):Play()
            else
                TweenService:Create(btn, TweenInfo.new(0.15), {
                    BackgroundColor3 = Theme.PanelAccent,
                    TextColor3 = Theme.TextDim,
                }):Play()
            end
        end
    end

    for _, curve in ipairs(CURVES) do
        local cb = Instance.new("TextButton")
        cb.Size = UDim2.new(0, 60, 1, 0)
        cb.BackgroundColor3 = Theme.PanelAccent
        cb.TextColor3 = Theme.TextDim
        cb.Font = Enum.Font.GothamBold
        cb.TextSize = 11
        cb.Text = CURVE_LABELS[curve] or curve
        cb.AutoButtonColor = false
        cb.Parent = curveHolder
        Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 5)
        curveButtons[curve] = cb
        cb.MouseButton1Click:Connect(function()
            Settings.AimCurve = curve
            refreshCurveButtons()
            task.spawn(saveSettings)
        end)
    end
    refreshCurveButtons()

    -- Silent Aim
    sectionHeader(tab, "Silent Aim", o())
    silentToggleAPI = toggleRow(tab, "Silent Aim", Settings.SilentAimEnabled, o(), function(state)
        Settings.SilentAimEnabled = state
        silentFovCircle.Visible = state
        if state then enableSilentAimHook() else silentAimTarget = nil end
        toast("Silent Aim " .. (state and "ON" or "OFF"), state and Theme.Accent or Theme.TextDim)
    end, "SilentAim")

    sliderRow(tab, "Silent Aim FOV", 10, 360, Settings.SilentAimFOV, o(),
        function(v) return math.floor(v) .. "°" end,
        function(v)
            Settings.SilentAimFOV = v
            silentFovCircle.Size = UDim2.new(0, v * 2, 0, v * 2)
        end)

    -- Trigger Bot
    sectionHeader(tab, "Trigger Bot", o())
    triggerToggleAPI = toggleRow(tab, "Trigger Bot", Settings.TriggerBotEnabled, o(), function(state)
        toggleTriggerBot(state, true)
        triggerFovCircle.Visible = state
        toast("Trigger Bot " .. (state and "ON" or "OFF"), state and Theme.Accent or Theme.TextDim)
    end, "TriggerBot")

    sliderRow(tab, "Trigger FOV (px)", 1, 60, Settings.TriggerBotFOVPixels, o(),
        function(v) return math.floor(v) .. "px" end,
        function(v)
            Settings.TriggerBotFOVPixels = v
            triggerFovCircle.Size = UDim2.new(0, v * 2, 0, v * 2)
        end)

    sliderRow(tab, "Trigger Delay", 0.01, 0.5, Settings.TriggerBotDelay, o(),
        function(v) return string.format("%.2fs", v) end,
        function(v) Settings.TriggerBotDelay = v end)

    toggleRow(tab, "Require Left Mouse", Settings.TriggerBotRequireLMB, o(), function(state)
        Settings.TriggerBotRequireLMB = state
    end)

    -- Burst
    sectionHeader(tab, "Burst Mode", o())
    sliderRow(tab, "Burst Shots", 1, 10, Settings.TriggerBurst, o(),
        function(v) return tostring(math.floor(v)) end,
        function(v) Settings.TriggerBurst = v end)

    sliderRow(tab, "Burst Delay", 0.01, 0.2, Settings.TriggerBurstDelay, o(),
        function(v) return string.format("%.2fs", v) end,
        function(v) Settings.TriggerBurstDelay = v end)

    -- Enhancements
    sectionHeader(tab, "Enhancements", o())

    toggleRow(tab, "No Recoil", Settings.NoRecoilEnabled, o(), function(state)
        Settings.NoRecoilEnabled = state
        if state then startNoRecoil() else stopNoRecoil() end
        toast("No Recoil " .. (state and "ON" or "OFF"),
            state and Theme.Accent or Theme.TextDim)
    end)

    toggleRow(tab, "No Spread", Settings.NoSpreadEnabled, o(), function(state)
        Settings.NoSpreadEnabled = state
        toast("No Spread " .. (state and "ON" or "OFF"),
            state and Theme.Accent or Theme.TextDim)
    end)

    toggleRow(tab, "Rapid Fire", Settings.RapidFireEnabled, o(), function(state)
        Settings.RapidFireEnabled = state
        if state then startRapidFire() else stopRapidFire() end
        toast("Rapid Fire " .. (state and "ON" or "OFF"),
            state and Theme.Accent or Theme.TextDim)
    end)

    toggleRow(tab, "Hit Marker", Settings.HitMarkerEnabled, o(), function(state)
        Settings.HitMarkerEnabled = state
        if state then startHitMarker() else stopHitMarker() end
        toast("Hit Marker " .. (state and "ON" or "OFF"),
            state and Theme.Accent or Theme.TextDim)
    end)

    toggleRow(tab, "Kill Notifier", Settings.KillNotifierEnabled, o(), function(state)
        Settings.KillNotifierEnabled = state
        toast("Kill Notifier " .. (state and "ON" or "OFF"),
            state and Theme.Accent or Theme.TextDim)
    end)

    toggleRow(tab, "Kill Sound", Settings.KillSoundEnabled, o(), function(state)
        Settings.KillSoundEnabled = state
        toast("Kill Sound " .. (state and "ON" or "OFF"),
            state and Theme.Accent or Theme.TextDim)
    end)

    -- Weapon Whitelist
    sectionHeader(tab, "Weapon Whitelist", o())
    local whitelistInfo = Instance.new("TextLabel")
    whitelistInfo.Size = UDim2.new(1, -8, 0, 24)
    whitelistInfo.BackgroundColor3 = Theme.Panel
    whitelistInfo.TextColor3 = Theme.TextDim
    whitelistInfo.Font = Enum.Font.GothamMedium
    whitelistInfo.TextSize = 11
    whitelistInfo.Text = "  Empty = all weapons allowed"
    whitelistInfo.TextXAlignment = Enum.TextXAlignment.Left
    whitelistInfo.LayoutOrder = o()
    whitelistInfo.Parent = tab
    Instance.new("UICorner", whitelistInfo).CornerRadius = UDim.new(0, 8)

    local weaponScroll = Instance.new("ScrollingFrame")
    weaponScroll.Size = UDim2.new(1, -8, 0, 120)
    weaponScroll.BackgroundColor3 = Theme.Panel
    weaponScroll.BorderSizePixel = 0
    weaponScroll.ScrollBarThickness = 3
    weaponScroll.ScrollBarImageColor3 = Theme.AccentDim
    weaponScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    weaponScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    weaponScroll.LayoutOrder = o()
    weaponScroll.Parent = tab
    Instance.new("UICorner", weaponScroll).CornerRadius = UDim.new(0, 8)

    local wLayout = Instance.new("UIListLayout")
    wLayout.Padding = UDim.new(0, 4)
    wLayout.Parent = weaponScroll

    local function refreshWhitelist()
        for _, child in ipairs(weaponScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        local seen = {}
        local unique = {}
        for _, item in ipairs(ReplicatedStorage:GetDescendants()) do
            if item:IsA("Tool") and not seen[item.Name] then
                seen[item.Name] = true
                table.insert(unique, item.Name)
            end
        end
        local backpack = localPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") and not seen[item.Name] then
                    seen[item.Name] = true
                    table.insert(unique, item.Name)
                end
            end
        end
        local char = localPlayer.Character
        if char then
            for _, item in ipairs(char:GetChildren()) do
                if item:IsA("Tool") and not seen[item.Name] then
                    seen[item.Name] = true
                    table.insert(unique, item.Name)
                end
            end
        end
        table.sort(unique)
        if #unique == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, -8, 0, 24)
            empty.BackgroundTransparency = 1
            empty.Text = "  No tools found"
            empty.TextColor3 = Theme.TextMuted
            empty.Font = Enum.Font.GothamMedium
            empty.TextSize = 11
            empty.TextXAlignment = Enum.TextXAlignment.Left
            empty.Parent = weaponScroll
            return
        end
        for i, name in ipairs(unique) do
            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1, -8, 0, 24)
            row.Position = UDim2.new(0, 4, 0, 0)
            row.BackgroundColor3 = WeaponWhitelist[name] and Theme.Accent or Theme.PanelAccent
            row.TextColor3 = WeaponWhitelist[name] and Theme.Background or Theme.Text
            row.Font = Enum.Font.GothamMedium
            row.TextSize = 12
            row.Text = "  " .. name
            row.TextXAlignment = Enum.TextXAlignment.Left
            row.AutoButtonColor = false
            row.LayoutOrder = i
            row.Parent = weaponScroll
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
            row.MouseButton1Click:Connect(function()
                if WeaponWhitelist[name] then
                    WeaponWhitelist[name] = nil
                else
                    WeaponWhitelist[name] = true
                end
                row.BackgroundColor3 = WeaponWhitelist[name] and Theme.Accent or Theme.PanelAccent
                row.TextColor3 = WeaponWhitelist[name] and Theme.Background or Theme.Text
            end)
        end
    end
    refreshWhitelist()

    actionRow(tab, "  Rescan Weapons", o(), function()
        refreshWhitelist()
        toast("Weapons rescanned", Theme.Success)
    end)
end

-- ---------- Visuals ----------
do
    local tab = tabFrames.Visuals
    local order = 0
    local function o() order += 1 return order end

    sectionHeader(tab, "ESP", o())
    espToggleAPI = toggleRow(tab, "ESP Enabled", Settings.ESPEnabled, o(), function(state)
        toggleESP(state, true)
        toast("ESP " .. (state and "ON" or "OFF"), state and Theme.Accent or Theme.TextDim)
    end, "ESP")

    toggleRow(tab, "Only Enemies", Settings.ESPOnlyEnemies, o(), function(state)
        Settings.ESPOnlyEnemies = state
        if Settings.ESPEnabled then
            local toRemove = {}
            for p in pairs(ESPs) do table.insert(toRemove, p) end
            for _, p in ipairs(toRemove) do removeESP(p) end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= localPlayer then
                    local ok = createESP(p)
                    if not ok and p.Character and p.Character.Parent then
                        queueESPRetry(p, p.Character)
                    end
                end
            end
        end
    end)

    toggleRow(tab, "Only Visible", Settings.ESPOnlyVisible, o(), function(state)
        Settings.ESPOnlyVisible = state
    end)

    toggleRow(tab, "Team Color Highlight", Settings.ESPTeamColorHighlight, o(), function(state)
        Settings.ESPTeamColorHighlight = state
        for p, data in pairs(ESPs) do
            if data.highlight then
                data.highlight.FillColor = state and getTeamColor(p) or Theme.Accent
            end
        end
    end)

    toggleRow(tab, "Distance Fade", Settings.ESPDistanceFade, o(), function(state)
        Settings.ESPDistanceFade = state
    end)

    sliderRow(tab, "Fade Distance", 100, 2000, Settings.ESPFadeDistance, o(),
        function(v) return math.floor(v) .. "m" end,
        function(v) Settings.ESPFadeDistance = v end)

    sectionHeader(tab, "ESP Elements", o())
    toggleRow(tab, "Show Name", Settings.ESPShowName, o(), function(state)
        Settings.ESPShowName = state
        for _, data in pairs(ESPs) do
            if data.nameLabel then data.nameLabel.Visible = state end
        end
    end)

    toggleRow(tab, "Show Health", Settings.ESPShowHealth, o(), function(state)
        Settings.ESPShowHealth = state
        for _, data in pairs(ESPs) do
            if data.healthBack then data.healthBack.Visible = state end
        end
    end)

    toggleRow(tab, "Show Distance", Settings.ESPShowDistance, o(), function(state)
        Settings.ESPShowDistance = state
        for _, data in pairs(ESPs) do
            if data.distLabel then data.distLabel.Visible = state end
        end
    end)

    sectionHeader(tab, "Environment", o())
    toggleRow(tab, "Fullbright", Settings.FullbrightEnabled, o(), function(state)
        Settings.FullbrightEnabled = state
        if state then enableFullbright() else disableFullbright() end
        toast("Fullbright " .. (state and "ON" or "OFF"), state and Theme.Accent or Theme.TextDim)
    end)

    toggleRow(tab, "No Fog", Settings.NoFogEnabled, o(), function(state)
        Settings.NoFogEnabled = state
        if state then enableNoFog() else disableNoFog() end
        toast("No Fog " .. (state and "ON" or "OFF"), state and Theme.Accent or Theme.TextDim)
    end)

    sectionHeader(tab, "Filters", o())
    toggleRow(tab, "Team Check", Settings.TeamCheck, o(), function(state)
        Settings.TeamCheck = state
    end)
    toggleRow(tab, "Visibility Check", Settings.VisibilityCheck, o(), function(state)
        Settings.VisibilityCheck = state
    end)

    sectionHeader(tab, "Phase View", o())
    local phaseInfo = Instance.new("TextLabel")
    phaseInfo.Size = UDim2.new(1, -8, 0, 34)
    phaseInfo.BackgroundColor3 = Theme.Panel
    phaseInfo.TextColor3 = Theme.TextDim
    phaseInfo.Font = Enum.Font.GothamMedium
    phaseInfo.TextSize = 11
    phaseInfo.Text = "  Hold [L] to see through walls"
    phaseInfo.TextXAlignment = Enum.TextXAlignment.Left
    phaseInfo.LayoutOrder = o()
    phaseInfo.Parent = tab
    Instance.new("UICorner", phaseInfo).CornerRadius = UDim.new(0, 8)
end

-- ---------- Movement ----------
do
    local tab = tabFrames.Movement
    local order = 0
    local function o() order += 1 return order end

    sectionHeader(tab, "Noclip", o())
    noclipToggleAPI = toggleRow(tab, "Noclip", Settings.NoclipEnabled, o(), function(state)
        toggleNoclip(state, true)
        toast("Noclip " .. (state and "ON" or "OFF"), state and Theme.Accent or Theme.TextDim)
    end, "Noclip")

    sliderRow(tab, "Noclip Speed", 10, 300, Settings.NoclipSpeed, o(),
        function(v) return math.floor(v) end,
        function(v) Settings.NoclipSpeed = v end)

    sectionHeader(tab, "Fly", o())
    flyToggleAPI = toggleRow(tab, "Fly", Settings.FlyEnabled, o(), function(state)
        toggleFly(state, true)
        toast("Fly " .. (state and "ON" or "OFF"), state and Theme.Accent or Theme.TextDim)
    end, "Fly")

    sliderRow(tab, "Fly Speed", 10, 300, Settings.FlySpeed, o(),
        function(v) return math.floor(v) end,
        function(v) Settings.FlySpeed = v end)

    sectionHeader(tab, "Enhancements", o())
    toggleRow(tab, "Infinite Jump", Settings.InfiniteJumpEnabled, o(), function(state)
        Settings.InfiniteJumpEnabled = state
        if state then startInfiniteJump() else stopInfiniteJump() end
        toast("Infinite Jump " .. (state and "ON" or "OFF"), state and Theme.Accent or Theme.TextDim)
    end)

    toggleRow(tab, "Anti-Fling", Settings.AntiFlingEnabled, o(), function(state)
        Settings.AntiFlingEnabled = state
        if state then startAntiFling() else stopAntiFling() end
        toast("Anti-Fling " .. (state and "ON" or "OFF"), state and Theme.Accent or Theme.TextDim)
    end)

    toggleRow(tab, "Anti-Void", Settings.AntiVoidEnabled, o(), function(state)
        Settings.AntiVoidEnabled = state
        if state then startAntiVoid() else stopAntiVoid() end
        toast("Anti-Void " .. (state and "ON" or "OFF"), state and Theme.Accent or Theme.TextDim)
    end)

    sectionHeader(tab, "Controls", o())
    local controls = Instance.new("TextLabel")
    controls.Size = UDim2.new(1, -8, 0, 58)
    controls.BackgroundColor3 = Theme.Panel
    controls.TextColor3 = Theme.TextDim
    controls.Font = Enum.Font.GothamMedium
    controls.TextSize = 11
    controls.Text = "  W/A/S/D — move relative to camera\n  Space / Shift — up / down\n  Works with Noclip and Fly"
    controls.TextXAlignment = Enum.TextXAlignment.Left
    controls.TextYAlignment = Enum.TextYAlignment.Center
    controls.LayoutOrder = o()
    controls.Parent = tab
    Instance.new("UICorner", controls).CornerRadius = UDim.new(0, 8)
end

-- ---------- Character ----------
do
    local tab = tabFrames.Character
    local order = 0
    local function o() order += 1 return order end

    sectionHeader(tab, "Appearance", o())
    toggleRow(tab, "Invisible", Settings.Invisible, o(), function(state)
        Settings.Invisible = state
        local char = localPlayer.Character
        if char then applyInvisibility(char, state) end
        toast("Invisible " .. (state and "ON" or "OFF"), state and Theme.Accent or Theme.TextDim)
    end)

    sectionHeader(tab, "Defense", o())
    toggleRow(tab, "God Mode (client)", Settings.GodModeEnabled, o(), function(state)
        Settings.GodModeEnabled = state
        if state then enableGodMode() else disableGodMode() end
        toast("God Mode " .. (state and "ON" or "OFF"), state and Theme.Accent or Theme.TextDim)
    end)

    sectionHeader(tab, "Movement", o())
    sliderRow(tab, "WalkSpeed", 0, 200, Settings.WalkSpeed, o(),
        function(v) return math.floor(v) end,
        function(v)
            Settings.WalkSpeed = v
            local char = localPlayer.Character
            local hum = char and char:FindFirstChildWhichIsA("Humanoid")
            if hum then hum.WalkSpeed = v end
        end)

    sliderRow(tab, "JumpPower", 0, 300, Settings.JumpPower, o(),
        function(v) return math.floor(v) end,
        function(v)
            Settings.JumpPower = v
            local char = localPlayer.Character
            local hum = char and char:FindFirstChildWhichIsA("Humanoid")
            if hum then hum.JumpPower = v end
        end)

    sliderRow(tab, "Gravity", 0, 300, Settings.Gravity, o(),
        function(v) return math.floor(v) end,
        function(v)
            Settings.Gravity = v
            workspace.Gravity = v
        end)
end

-- ---------- Players ----------
local PL_SCROLL = tabFrames.Players
local plEntries = {}
local joinOrderCounter = 0
local playerSearch = ""

do
    local tab = tabFrames.Players
    local order = 0
    local function o() order += 1 return order end

    sectionHeader(tab, "Search", o())
    textInputRow(tab, "Filter players...", o(), function(text)
        playerSearch = text:lower()
        for player, data in pairs(plEntries) do
            local matches = playerSearch == "" or player.Name:lower():find(playerSearch, 1, true) ~= nil
            data.entry.Visible = matches
        end
    end)
end

local function createPlayerEntry(player)
    if plEntries[player] then return end
    joinOrderCounter += 1

    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -4, 0, 32)
    entry.BackgroundColor3 = Theme.PanelLight
    entry.BorderSizePixel = 0
    entry.LayoutOrder = joinOrderCounter
    entry.Parent = PL_SCROLL
    Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 6)

    local teamBar = Instance.new("Frame")
    teamBar.Size = UDim2.new(0, 3, 1, -10)
    teamBar.Position = UDim2.new(0, 5, 0, 5)
    teamBar.BackgroundColor3 = getTeamColor(player)
    teamBar.BorderSizePixel = 0
    teamBar.Parent = entry
    Instance.new("UICorner", teamBar).CornerRadius = UDim.new(1, 0)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -110, 1, 0)
    nameLbl.Position = UDim2.new(0, 14, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = player.Name
    nameLbl.TextColor3 = Theme.Text
    nameLbl.Font = Enum.Font.GothamMedium
    nameLbl.TextSize = 12
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Parent = entry

    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0, 40, 0, 20)
    tpBtn.Position = UDim2.new(1, -86, 0, 6)
    tpBtn.BackgroundColor3 = Theme.Accent
    tpBtn.TextColor3 = Theme.Background
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 10
    tpBtn.Text = "TP"
    tpBtn.AutoButtonColor = false
    tpBtn.Parent = entry
    Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 4)

    local specBtn = Instance.new("TextButton")
    specBtn.Size = UDim2.new(0, 40, 0, 20)
    specBtn.Position = UDim2.new(1, -42, 0, 6)
    specBtn.BackgroundColor3 = Theme.Danger
    specBtn.TextColor3 = Theme.Text
    specBtn.Font = Enum.Font.GothamBold
    specBtn.TextSize = 10
    specBtn.Text = "SPEC"
    specBtn.AutoButtonColor = false
    specBtn.Parent = entry
    Instance.new("UICorner", specBtn).CornerRadius = UDim.new(0, 4)

    tpBtn.MouseButton1Click:Connect(function()
        local char = localPlayer.Character
        local myHrp = char and char:FindFirstChild("HumanoidRootPart")
        local targetHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if myHrp and targetHrp then
            myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3)
            toast("Teleported to " .. player.Name, Theme.Success)
        end
    end)

    local spectating = false
    specBtn.MouseButton1Click:Connect(function()
        spectating = not spectating
        specBtn.Text = spectating and "STOP" or "SPEC"
        if spectating then
            local tHum = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
            camera.CameraSubject = tHum
        else
            local myHum = localPlayer.Character and localPlayer.Character:FindFirstChildWhichIsA("Humanoid")
            camera.CameraSubject = myHum
        end
    end)

    local conn = player:GetPropertyChangedSignal("TeamColor"):Connect(function()
        teamBar.BackgroundColor3 = getTeamColor(player)
    end)

    plEntries[player] = { entry = entry, conn = conn }
end

local function removePlayerEntry(player)
    local data = plEntries[player]
    if not data then return end
    data.conn:Disconnect()
    data.entry:Destroy()
    plEntries[player] = nil
end

-- ---------- Info ----------
do
    local tab = tabFrames.Info
    local order = 0
    local function o() order += 1 return order end

    sectionHeader(tab, "Overlays", o())
    toggleRow(tab, "Show Ping", Settings.ShowPing, o(), function(state)
        Settings.ShowPing = state
        if statusPing then statusPing.Visible = state end
    end)
    toggleRow(tab, "Show Position", Settings.ShowPosition, o(), function(state)
        Settings.ShowPosition = state
        if statusPos then statusPos.Visible = state end
    end)
    toggleRow(tab, "Show Velocity", Settings.ShowVelocity, o(), function(state)
        Settings.ShowVelocity = state
        if statusVel then statusVel.Visible = state end
    end)

    sectionHeader(tab, "Server Info", o())
    local infoBox = Instance.new("TextLabel")
    infoBox.Size = UDim2.new(1, -8, 0, 100)
    infoBox.BackgroundColor3 = Theme.Panel
    infoBox.TextColor3 = Theme.TextDim
    infoBox.Font = Enum.Font.GothamMedium
    infoBox.TextSize = 11
    infoBox.TextXAlignment = Enum.TextXAlignment.Left
    infoBox.TextYAlignment = Enum.TextYAlignment.Top
    infoBox.Text = "  Loading..."
    infoBox.LayoutOrder = o()
    infoBox.Parent = tab
    Instance.new("UICorner", infoBox).CornerRadius = UDim.new(0, 8)

    task.spawn(function()
        while infoBox.Parent do
            infoBox.Text = string.format(
                "  Players: %d\n  Place ID: %d\n  Job ID: %s\n  User: %s (%d)\n  Persistence: %s",
                #Players:GetPlayers(),
                game.PlaceId,
                tostring(game.JobId):sub(1, 12) .. "...",
                localPlayer.Name,
                localPlayer.UserId,
                PersistBackend
            )
            task.wait(2)
        end
    end)
end

-- ---------- Settings ----------
do
    local tab = tabFrames.Settings
    local order = 0
    local function o() order += 1 return order end

    sectionHeader(tab, "Hotkeys", o())
    for _, name in ipairs({"Aimlock", "SilentAim", "TriggerBot", "Noclip", "Fly", "ESP", "ToggleMenu"}) do
        hotkeyRow(tab, name, o())
    end

    sectionHeader(tab, "Interface", o())
    toggleRow(tab, "Toast Notifications", Settings.ToastEnabled, o(), function(state)
        Settings.ToastEnabled = state
    end)
    toggleRow(tab, "Status Bar", Settings.ShowStatusBar, o(), function(state)
        Settings.ShowStatusBar = state
        if statusBar then statusBar.Visible = state end
    end)

    sliderRow(tab, "Menu Scale", 0.7, 1.4, Settings.MenuScale, o(),
        function(v) return string.format("%.2f", v) end,
        function(v)
            Settings.MenuScale = v
            root.Size = UDim2.new(0, PANEL_W * v, 0, PANEL_H * v)
        end)

    sliderRow(tab, "Menu Opacity", 0.4, 1.0, Settings.MenuOpacity, o(),
        function(v) return string.format("%.2f", v) end,
        function(v)
            Settings.MenuOpacity = v
            if capsState == 0 then
                root.BackgroundTransparency = 1 - v
            end
        end)

    sectionHeader(tab, "Profiles", o())
    local profileNameInput = textInputRow(tab, "Profile name...", o())
    actionRow(tab, "  Save Current as Profile", o(), function()
        local name = profileNameInput.Text
        if name == "" then
            toast("Enter a name first", Theme.Warning)
            return
        end
        Profiles[name] = buildPayload()
        saveProfiles()
        toast("Saved profile: " .. name, Theme.Success)
    end)

    actionRow(tab, "  Load Named Profile", o(), function()
        local name = profileNameInput.Text
        if name == "" or not Profiles[name] then
            toast("No profile with that name", Theme.Danger)
            return
        end
        applyPayload(Profiles[name])
        saveSettingsNow()
        toast("Loaded profile: " .. name, Theme.Success)
    end, Theme.Warning)

    actionRow(tab, "✕  Delete Named Profile", o(), function()
        local name = profileNameInput.Text
        if Profiles[name] then
            Profiles[name] = nil
            saveProfiles()
            toast("Deleted: " .. name, Theme.Danger)
        else
            toast("No profile with that name", Theme.Danger)
        end
    end, Theme.Danger)

    sectionHeader(tab, "Data", o())
    actionRow(tab, "↻  Save Settings", o(), function()
        saveSettingsNow()
        toast("Settings saved", Theme.Success)
    end)
    actionRow(tab, "↺  Reload Settings", o(), function()
        loadSettings()
        toast("Settings loaded", Theme.Success)
    end, Theme.Warning)
    actionRow(tab, "✕  Reset All", o(), function()
        memoryCache[PERSIST_KEY] = nil
        if PersistBackend == "file" and delfile then
            pcall(delfile, PERSIST_KEY .. ".json")
        end
        toast("Reset — reload script to apply", Theme.Danger)
    end, Theme.Danger)

    sectionHeader(tab, "Info", o())
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -8, 0, 70)
    info.BackgroundColor3 = Theme.Panel
    info.TextColor3 = Theme.TextDim
    info.Font = Enum.Font.GothamMedium
    info.TextSize = 11
    info.Text = string.format(
        "  Persistence: %s\n  User: %s (%d)\n  Place: %d",
        PersistBackend, localPlayer.Name, localPlayer.UserId, game.PlaceId
    )
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Center
    info.LayoutOrder = o()
    info.Parent = tab
    Instance.new("UICorner", info).CornerRadius = UDim.new(0, 8)
end

-- ============================================================
-- 9. OVERLAYS
-- ============================================================
local statusBar = Instance.new("Frame")
statusBar.Name = "StatusBar"
statusBar.Size = UDim2.new(1, -24, 0, 26)
statusBar.Position = UDim2.new(0, 12, 1, -34)
statusBar.BackgroundColor3 = Theme.Panel
statusBar.BorderSizePixel = 0
statusBar.Visible = Settings.ShowStatusBar
statusBar.Parent = root
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 6)

local function makeStatusLabel(xPos, width, alignRight)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, width, 1, 0)
    lbl.Position = UDim2.new(0, xPos, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Theme.TextMuted
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 10
    lbl.TextXAlignment = alignRight and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    lbl.Parent = statusBar
    return lbl
end

local statusFps    = makeStatusLabel(10, 60, false)
local statusPing   = makeStatusLabel(75, 60, false)
local statusTarget = makeStatusLabel(140, 130, false)
local statusPos    = makeStatusLabel(275, 130, false)
local statusVel    = makeStatusLabel(-120, 60, false)
local statusBack   = makeStatusLabel(-10, 110, true)

statusBack.Text = PersistBackend .. "  "
statusPing.Visible = Settings.ShowPing
statusPos.Visible  = Settings.ShowPosition
statusVel.Visible  = Settings.ShowVelocity

local function createFovCircle(color, initialSize, thickness, transparency)
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, initialSize, 0, initialSize)
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Position = UDim2.new(0.5, 0, 0.5, 0)
    circle.BackgroundTransparency = 1
    circle.Visible = false
    circle.Parent = screenGui
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness
    stroke.Color = color
    stroke.Transparency = transparency or 0
    stroke.Parent = circle
    return circle
end

local fovCircle        = createFovCircle(Theme.Accent, Settings.AimlockDistance, 2, 0)
local silentFovCircle  = createFovCircle(Color3.fromRGB(255, 80, 80), Settings.SilentAimFOV * 2, 1, 0.4)
local triggerFovCircle = createFovCircle(Theme.Trigger, Settings.TriggerBotFOVPixels * 2, 1, 0.3)

fovCircle.Visible        = Settings.AimlockEnabled
silentFovCircle.Visible  = Settings.SilentAimEnabled
triggerFovCircle.Visible = Settings.TriggerBotEnabled

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 100, 0, 22)
fpsLabel.Position = UDim2.new(1, -120, 0, 10)
fpsLabel.BackgroundColor3 = Theme.Panel
fpsLabel.BackgroundTransparency = 0.15
fpsLabel.BorderSizePixel = 0
fpsLabel.TextColor3 = Theme.Text
fpsLabel.Font = Enum.Font.GothamSemibold
fpsLabel.TextSize = 12
fpsLabel.Text = "  FPS ..."
fpsLabel.Parent = screenGui
Instance.new("UICorner", fpsLabel).CornerRadius = UDim.new(0, 6)

local lastTime, frameCount = os.clock(), 0
RunService.RenderStepped:Connect(function()
    frameCount += 1
    sharedFrameId += 1
    local now = os.clock()
    if now - lastTime >= 1 then
        local fps = math.floor(frameCount / (now - lastTime))
        fpsLabel.Text = "  FPS " .. fps
        statusFps.Text = "  " .. fps .. " FPS"
        frameCount, lastTime = 0, now
    end
end)

RunService.Heartbeat:Connect(function()
    if Settings.ShowPing then
        local ok, ping = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        statusPing.Text = ok and ("  " .. math.floor(ping) .. " ms") or "  -- ms"
    end
    if Settings.ShowPosition then
        local char = localPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local p = hrp.Position
            statusPos.Text = string.format("  XYZ %.0f/%.0f/%.0f", p.X, p.Y, p.Z)
        end
    end
    if Settings.ShowVelocity then
        local char = localPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local v = hrp.AssemblyLinearVelocity.Magnitude
            statusVel.Text = string.format("  %.0f st/s", v)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local now = os.clock()
    for player, entry in pairs(espRetryQueue) do
        if now - entry.firstTry > 8 then
            espRetryQueue[player] = nil
        else
            if espWanted[player] and not ESPs[player] then
                local ok = createESP(player)
                if ok then
                    espRetryQueue[player] = nil
                else
                    entry.attempts = entry.attempts + 1
                end
            else
                espRetryQueue[player] = nil
            end
        end
    end

    local camPos = camera.CFrame.Position
    for p, data in pairs(ESPs) do
        if not data.gui or not data.gui.Parent or not data.gui.Adornee then
            removeESP(p)
        else
            local owner = p
            if not isESPReady(owner.Character) then
                removeESP(owner)
            else
                local pos = data.gui.Adornee.Position
                local dist = (pos - camPos).Magnitude

                if Settings.ESPShowDistance and data.distLabel then
                    data.distLabel.Text = formatDistance(dist)
                end

                if Settings.ESPDistanceFade then
                    local alpha = computeESPAlpha(dist)
                    if math.abs(alpha - (data.lastAlpha or -1)) > 0.05 then
                        data.lastAlpha = alpha
                        if data.highlight then
                            data.highlight.FillTransparency = 1 - alpha
                            data.highlight.OutlineTransparency = 1 - alpha
                        end
                        if data.frameGui then
                            data.frameGui.BackgroundTransparency = 1 - alpha * 0.6
                        end
                    end
                elseif data.lastAlpha ~= 1 then
                    data.lastAlpha = 1
                    if data.highlight then
                        data.highlight.FillTransparency = 0
                        data.highlight.OutlineTransparency = 0
                    end
                    if data.frameGui then
                        data.frameGui.BackgroundTransparency = 0.4
                    end
                end

                if Settings.ESPOnlyVisible then
                    local target = getTargetPart(owner.Character)
                    local vis = target and isVisible(target) or false
                    if data.gui.Enabled ~= vis then
                        data.gui.Enabled = vis
                        if data.highlight then data.highlight.Enabled = vis end
                    end
                elseif data.gui and not data.gui.Enabled then
                    data.gui.Enabled = true
                    if data.highlight then data.highlight.Enabled = true end
                end
            end
        end
    end

    if Settings.ShowStatusBar then
        if silentAimTarget then
            local char = silentAimTarget:FindFirstAncestorOfClass("Model")
            local owner = char and Players:GetPlayerFromCharacter(char)
            statusTarget.Text = "  ◎ " .. (owner and owner.Name or "?")
            statusTarget.TextColor3 = Theme.Accent
        else
            statusTarget.Text = "  ○ no target"
            statusTarget.TextColor3 = Theme.TextMuted
        end
    end
end)

-- Kill notifier hook
RunService.Heartbeat:Connect(function()
    if not Settings.KillNotifierEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and isEnemy(player) then
            local hum = player.Character:FindFirstChildWhichIsA("Humanoid")
            if hum then
                local prev = lastEnemyHealth[player] or hum.MaxHealth
                if hum.Health <= 0 and prev > 0 then
                    if silentAimTarget then
                        local char = silentAimTarget:FindFirstAncestorOfClass("Model")
                        if char == player.Character then
                            showKillNotifier(player.Name)
                        end
                    end
                end
                lastEnemyHealth[player] = hum.Health
            end
        end
    end
end)

-- ============================================================
-- 10. PLAYER LIST INIT
-- ============================================================
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= localPlayer then createPlayerEntry(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= localPlayer then createPlayerEntry(p) end
end)
Players.PlayerRemoving:Connect(removePlayerEntry)

local function trackPlayer(player)
    player.CharacterRemoving:Connect(function()
        removeESP(player)
        markPlayerDying(player, player.Character)
    end)

    player.CharacterAdded:Connect(function(char)
        DyingPlayers[player] = nil
        RecentlyDead[player] = nil

        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hum.Died:Connect(function()
                removeESP(player)
                markPlayerDying(player, char)
            end)
            hum.HealthChanged:Connect(function(h)
                if h <= 0 then
                    removeESP(player)
                    markPlayerDying(player, char)
                end
            end)
        end

        if Settings.ESPEnabled and player ~= localPlayer then
            espWanted[player] = true
            task.wait(0.05)
            local ok = createESP(player)
            if not ok and char and char.Parent then
                queueESPRetry(player, char)
            end
        end
    end)

    if player.Character and Settings.ESPEnabled and player ~= localPlayer then
        espWanted[player] = true
        local ok = createESP(player)
        if not ok and player.Character.Parent then
            queueESPRetry(player, player.Character)
        end
    end
end

for _, p in ipairs(Players:GetPlayers()) do trackPlayer(p) end
Players.PlayerAdded:Connect(trackPlayer)
Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    DyingPlayers[player] = nil
    RecentlyDead[player] = nil
    espWanted[player] = nil
    espRetryQueue[player] = nil
end)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= localPlayer and p.Character then cacheTriggerParts(p, p.Character) end
    p.CharacterAdded:Connect(function(char) cacheTriggerParts(p, char) end)
end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char) cacheTriggerParts(p, char) end)
    if p.Character then cacheTriggerParts(p, p.Character) end
end)
Players.PlayerRemoving:Connect(function(p) triggerParts[p] = nil end)

-- ============================================================
-- 11. CORPSE CLEANUP
-- ============================================================
local modifiedQuery = {}
local deadChars = {}

local function fastCorpseCleanup()
    if next(deadChars) == nil and next(modifiedQuery) == nil then
        local anyDead = false
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Character then
                local hum = player.Character:FindFirstChildWhichIsA("Humanoid")
                if hum and hum.Health <= 0 then
                    deadChars[player.Character] = true
                    anyDead = true
                end
            end
        end
        if not anyDead then return end
    end

    for char in pairs(deadChars) do
        if not char.Parent then deadChars[char] = nil end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local hum = player.Character:FindFirstChildWhichIsA("Humanoid")
            if hum and hum.Health <= 0 then
                deadChars[player.Character] = true
            else
                deadChars[player.Character] = nil
            end
        end
    end
    for char in pairs(deadChars) do
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") and d.CanQuery then
                d.CanQuery = false
                modifiedQuery[d] = true
            end
        end
    end
    for part in pairs(modifiedQuery) do
        if not part.Parent then
            modifiedQuery[part] = nil
        else
            local hum = part.Parent and part.Parent:FindFirstChildWhichIsA("Humanoid")
            if hum and hum.Health > 0 then
                part.CanQuery = true
                modifiedQuery[part] = nil
            end
        end
    end
end
RunService.Heartbeat:Connect(fastCorpseCleanup)

-- ============================================================
-- 12. RUNTIME LOOPS
-- ============================================================
RunService.RenderStepped:Connect(function()
    local needsTarget = Settings.AimlockEnabled or Settings.SilentAimEnabled
    if not needsTarget then
        if Settings.SilentAimEnabled then silentAimTarget = nil end
        return
    end

    if Settings.SilentAimEnabled then
        if silentAimTarget and not isTargetStillValid(silentAimTarget) then
            silentAimTarget = nil
        end
        if not silentAimTarget then
            silentAimTarget = getSharedTarget(Settings.SilentAimFOV, Settings.AimlockDistance)
        end

        if Settings.SilentAimDebug then
            local now = os.clock()
            if now - lastDebugPrint >= Settings.SilentAimDebugRate then
                lastDebugPrint = now
                if silentAimTarget then
                    local char = silentAimTarget:FindFirstAncestorOfClass("Model")
                    local owner = char and Players:GetPlayerFromCharacter(char)
                    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
                    print(("[SilentAim] target=%s hp=%s dying=%s"):format(
                        owner and owner.Name or "?",
                        hum and string.format("%.0f", hum.Health) or "?",
                        owner and tostring(DyingPlayers[owner]) or "?"
                    ))
                else
                    print("[SilentAim] no target")
                end
            end
        end
    end

    if Settings.AimlockEnabled then
        local closestPart, bestScore = getSharedTarget(Settings.AimlockFOV, Settings.AimlockDistance)
        if closestPart and bestScore then
            local camPos = camera.CFrame.Position
            local predicted = getPredictedPosition(closestPart)
            local strongFactor = math.clamp(1 / (bestScore / Settings.AimlockDistance), 1, Settings.StrongLockBoost)
            local baseLerp = math.clamp(Settings.AimSmoothness / strongFactor, 0.05, Settings.AimSmoothness)
            local lerpAmount = applyAimCurve(baseLerp)
            camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camPos, predicted), lerpAmount)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if not Settings.TriggerBotEnabled then return end
    if not TriggerBot.debugDot then return end

    local target, part = findTriggerTarget()
    if not target then
        TriggerBot.debugDot.BackgroundColor3 = Theme.Danger
    elseif Settings.TriggerBotRequireLMB
        and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        TriggerBot.debugDot.BackgroundColor3 = Theme.Warning
    else
        TriggerBot.debugDot.BackgroundColor3 = Theme.Success
        local now = os.clock()
        if now - TriggerBot.lastFire >= Settings.TriggerBotDelay then
            if fireWeapon() then
                TriggerBot.lastFire = now
                -- Burst mode
                if Settings.TriggerBurst > 1 then
                    for i = 2, Settings.TriggerBurst do
                        task.delay(Settings.TriggerBurstDelay * (i - 1), function()
                            if Settings.TriggerBotEnabled then
                                fireWeapon()
                            end
                        end)
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- 13. CHARACTER LIFECYCLE
-- ============================================================
localPlayer.CharacterAdded:Connect(function(char)
    local ok, err = pcall(applyCharacterSettings, char)
    if not ok then warn("[Donkey] applyCharacterSettings: " .. tostring(err)) end

    task.wait(0.2)
    if Settings.NoclipEnabled then startNoclip()
    elseif Settings.FlyEnabled then startFly() end
end)

if localPlayer.Character then
    pcall(applyCharacterSettings, localPlayer.Character)
end

localPlayer.CharacterRemoving:Connect(function()
    if Settings.SilentAimEnabled then silentAimTarget = nil end
    task.spawn(saveSettings)
end)

-- ============================================================
-- 14. INPUT
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and listeningAction then
        listeningAction = nil
        for actionName, badge in pairs(hotkeyBadges) do
            if Hotkeys[actionName] then badge.Text = Hotkeys[actionName].Name end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if listeningAction and not gp and input.UserInputType == Enum.UserInputType.Keyboard then
        local actionName = listeningAction
        Hotkeys[actionName] = input.KeyCode
        listeningAction = nil

        if hotkeyBadges[actionName] then
            hotkeyBadges[actionName].Text = input.KeyCode.Name
        end

        toast("Hotkey rebound · " .. actionName .. " = " .. input.KeyCode.Name, Theme.Success)
        task.spawn(saveSettings)
        return
    end

    if gp then return end

    if input.KeyCode == Hotkeys.ToggleMenu then
        if capsState == 0 then
            capsState = 1
            TweenService:Create(root, TweenInfo.new(0.2), { BackgroundTransparency = 0.5 }):Play()
        elseif capsState == 1 then
            capsState = 2
            root.Visible = false
        else
            capsState = 0
            root.Visible = true
            TweenService:Create(root, TweenInfo.new(0.2), { BackgroundTransparency = 1 - Settings.MenuOpacity }):Play()
        end
        return
    end

    if input.KeyCode == Enum.KeyCode.L then enablePhaseView() end

    if input.KeyCode == Hotkeys.Aimlock then
        Settings.AimlockEnabled = not Settings.AimlockEnabled
        if aimToggleAPI then aimToggleAPI.SetState(Settings.AimlockEnabled, true) end
        fovCircle.Visible = Settings.AimlockEnabled
        toast("Aimlock " .. (Settings.AimlockEnabled and "ON" or "OFF"),
            Settings.AimlockEnabled and Theme.Accent or Theme.TextDim)
        task.spawn(saveSettings)

    elseif input.KeyCode == Hotkeys.SilentAim then
        Settings.SilentAimEnabled = not Settings.SilentAimEnabled
        if silentToggleAPI then silentToggleAPI.SetState(Settings.SilentAimEnabled, true) end
        silentFovCircle.Visible = Settings.SilentAimEnabled
        if Settings.SilentAimEnabled then enableSilentAimHook() else silentAimTarget = nil end
        toast("Silent Aim " .. (Settings.SilentAimEnabled and "ON" or "OFF"),
            Settings.SilentAimEnabled and Theme.Accent or Theme.TextDim)
        task.spawn(saveSettings)

    elseif input.KeyCode == Hotkeys.TriggerBot then
        toggleTriggerBot()
        triggerFovCircle.Visible = Settings.TriggerBotEnabled
        task.spawn(saveSettings)

    elseif input.KeyCode == Hotkeys.Noclip then
        toggleNoclip()

    elseif input.KeyCode == Hotkeys.Fly then
        toggleFly()

    elseif input.KeyCode == Hotkeys.ESP then
        toggleESP()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.L then disablePhaseView() end
end)

-- ============================================================
-- 15. STARTUP RESTORE
-- ============================================================
if Settings.SilentAimEnabled then enableSilentAimHook() end
if Settings.NoclipEnabled then startNoclip() end
if Settings.FlyEnabled then startFly() end
workspace.Gravity = Settings.Gravity

if Settings.FullbrightEnabled then enableFullbright() end
if Settings.NoFogEnabled then enableNoFog() end
if Settings.GodModeEnabled then enableGodMode() end
if Settings.InfiniteJumpEnabled then startInfiniteJump() end
if Settings.AntiFlingEnabled then startAntiFling() end
if Settings.AntiVoidEnabled then startAntiVoid() end
if Settings.NoRecoilEnabled then startNoRecoil() end
if Settings.RapidFireEnabled then startRapidFire() end
if Settings.HitMarkerEnabled then startHitMarker() end

root.Size = UDim2.new(0, PANEL_W * Settings.MenuScale, 0, PANEL_H * Settings.MenuScale)
if capsState == 0 then
    root.BackgroundTransparency = 1 - Settings.MenuOpacity
end

if Settings.ESPEnabled then
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer then
            espWanted[p] = true
            local ok = createESP(p)
            if not ok and p.Character and p.Character.Parent then
                queueESPRetry(p, p.Character)
            end
        end
    end
end

task.delay(1, function()
    if PersistBackend ~= "memory" then
        toast("Loaded · " .. PersistBackend .. " backend", Theme.Accent)
    else
        toast("Loaded · settings won't persist", Theme.Warning)
    end
end)
