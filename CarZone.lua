--[[
    ═══════════════════════════════════════
    🏎️ GF HUB - Car Zone Auto Farm
    ═══════════════════════════════════════
    Created by: Gael Fonzar
    Game: Car Zone Racing & Drifting
    Game ID: 80200604311136
    ═══════════════════════════════════════
    Features:
    • Auto Race (Highest Reward)
    • Auto Collect Winter Event Snowflakes
    • Auto Finish Races
    • ESP for Snowflakes
    ═══════════════════════════════════════
]]

-- Load Fluent Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Variables
local autoRaceEnabled = false
local autoWinterEnabled = false
local snowflakeESPEnabled = false
local autoFinishEnabled = false

local connections = {}
local espObjects = {}

-- Helper Functions
local function getChar()
    return player.Character
end

local function getRoot()
    local char = getChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- Notify Function
local function notify(title, content, duration)
    Fluent:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3
    })
end

-- Find Snowflakes in Workspace
local function findSnowflakes()
    local snowflakes = {}
    
    -- Buscar en diferentes ubicaciones posibles
    local searchLocations = {
        Workspace:FindFirstChild("Snowflakes"),
        Workspace:FindFirstChild("Winter"),
        Workspace:FindFirstChild("Event"),
        Workspace:FindFirstChild("Collectibles"),
        Workspace:FindFirstChild("Items"),
        Workspace
    }
    
    for _, location in pairs(searchLocations) do
        if location then
            for _, obj in pairs(location:GetDescendants()) do
                -- Buscar objetos que parezcan copos de nieve
                if obj:IsA("BasePart") or obj:IsA("Model") then
                    local name = obj.Name:lower()
                    if name:find("snow") or name:find("flake") or name:find("winter") or name:find("collect") then
                        table.insert(snowflakes, obj)
                    end
                end
            end
        end
    end
    
    return snowflakes
end

-- ESP for Snowflakes
local function createSnowflakeESP(snowflake)
    if not snowflake or espObjects[snowflake] then return end
    
    local part = snowflake:IsA("Model") and snowflake:FindFirstChildWhichIsA("BasePart") or snowflake
    if not part then return end
    
    -- Create Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "GF_SnowflakeESP"
    highlight.Adornee = snowflake:IsA("Model") and snowflake or nil
    highlight.FillColor = Color3.fromRGB(135, 206, 250)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    
    if snowflake:IsA("Model") then
        highlight.Parent = snowflake
    else
        highlight.Adornee = snowflake
        highlight.Parent = snowflake
    end
    
    -- Create BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "GF_SnowflakeLabel"
    billboard.Adornee = part
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "❄️ Snowflake"
    label.TextColor3 = Color3.fromRGB(135, 206, 250)
    label.TextStrokeTransparency = 0.5
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Parent = billboard
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "0m"
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.TextStrokeTransparency = 0.5
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.TextSize = 12
    distanceLabel.Parent = billboard
    
    espObjects[snowflake] = {
        highlight = highlight,
        billboard = billboard,
        distanceLabel = distanceLabel,
        part = part
    }
end

local function removeSnowflakeESP(snowflake)
    if espObjects[snowflake] then
        pcall(function()
            if espObjects[snowflake].highlight then
                espObjects[snowflake].highlight:Destroy()
            end
            if espObjects[snowflake].billboard then
                espObjects[snowflake].billboard:Destroy()
            end
        end)
        espObjects[snowflake] = nil
    end
end

local function updateSnowflakeESP()
    if not snowflakeESPEnabled then return end
    
    local myRoot = getRoot()
    if not myRoot then return end
    
    for snowflake, espData in pairs(espObjects) do
        if snowflake and snowflake.Parent and espData.part and espData.distanceLabel then
            local distance = math.floor((myRoot.Position - espData.part.Position).Magnitude)
            espData.distanceLabel.Text = distance .. "m"
        else
            removeSnowflakeESP(snowflake)
        end
    end
end

local function updateAllSnowflakeESP()
    -- Clear old ESP
    for snowflake, _ in pairs(espObjects) do
        removeSnowflakeESP(snowflake)
    end
    
    if snowflakeESPEnabled then
        local snowflakes = findSnowflakes()
        for _, snowflake in pairs(snowflakes) do
            createSnowflakeESP(snowflake)
        end
        notify("ESP Updated", "Found " .. #snowflakes .. " snowflakes", 2)
    end
end

-- Auto Collect Snowflakes
local function teleportToSnowflake(snowflake)
    local root = getRoot()
    if not root then return false end
    
    local targetPart = snowflake:IsA("Model") and snowflake:FindFirstChildWhichIsA("BasePart") or snowflake
    if not targetPart then return false end
    
    root.CFrame = targetPart.CFrame
    return true
end

local function autoCollectSnowflakes()
    while autoWinterEnabled do
        local snowflakes = findSnowflakes()
        
        if #snowflakes == 0 then
            notify("⚠️ No Snowflakes", "No snowflakes found in workspace", 3)
            task.wait(5)
        else
            for _, snowflake in pairs(snowflakes) do
                if not autoWinterEnabled then break end
                
                if snowflake and snowflake.Parent then
                    local success = teleportToSnowflake(snowflake)
                    if success then
                        task.wait(0.5) -- Esperar a que se recoja
                        
                        -- Verificar si fue removido (recolectado)
                        if not snowflake.Parent then
                            notify("✅ Collected", "Snowflake collected!", 1)
                        end
                    end
                    
                    task.wait(0.3)
                end
            end
        end
        
        task.wait(2)
    end
end

-- Find Race with Highest Reward
local function findBestRace()
    -- Buscar en lugares comunes de UI de carreras
    local raceUI = player:FindFirstChild("PlayerGui")
    if not raceUI then return nil end
    
    -- Buscar frames de carreras
    for _, gui in pairs(raceUI:GetDescendants()) do
        if gui:IsA("TextLabel") or gui:IsA("TextButton") then
            local text = gui.Text:lower()
            -- Buscar texto que indique recompensas altas
            if text:find("race") or text:find("start") or text:find("join") then
                return gui
            end
        end
    end
    
    return nil
end

-- Auto Start Race
local function startRace()
    local raceButton = findBestRace()
    
    if raceButton and raceButton:IsA("TextButton") then
        -- Simular click
        for _, connection in pairs(getconnections(raceButton.MouseButton1Click)) do
            connection:Fire()
        end
        notify("🏁 Race Started", "Starting race...", 2)
        return true
    end
    
    -- Método alternativo: buscar RemoteEvents de carreras
    for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            local name = remote.Name:lower()
            if name:find("race") or name:find("start") or name:find("join") then
                pcall(function()
                    if remote:IsA("RemoteEvent") then
                        remote:FireServer()
                    else
                        remote:InvokeServer()
                    end
                end)
                notify("🏁 Race Started", "Attempting to start race...", 2)
                return true
            end
        end
    end
    
    return false
end

-- Auto Finish Race
local function findRaceCheckpoints()
    local checkpoints = {}
    
    -- Buscar checkpoints en workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("checkpoint") or name:find("finish") or name:find("gate") then
                table.insert(checkpoints, obj)
            end
        end
    end
    
    return checkpoints
end

local function autoCompleteRace()
    if not autoFinishEnabled then return end
    
    local checkpoints = findRaceCheckpoints()
    
    if #checkpoints > 0 then
        -- Ordenar checkpoints por distancia
        table.sort(checkpoints, function(a, b)
            local rootPos = getRoot().Position
            local partA = a:IsA("Model") and a:FindFirstChildWhichIsA("BasePart") or a
            local partB = b:IsA("Model") and b:FindFirstChildWhichIsA("BasePart") or b
            
            if partA and partB then
                return (rootPos - partA.Position).Magnitude < (rootPos - partB.Position).Magnitude
            end
            return false
        end)
        
        -- Teleport a cada checkpoint
        for _, checkpoint in pairs(checkpoints) do
            if not autoFinishEnabled then break end
            
            local root = getRoot()
            if root then
                local targetPart = checkpoint:IsA("Model") and checkpoint:FindFirstChildWhichIsA("BasePart") or checkpoint
                if targetPart then
                    root.CFrame = targetPart.CFrame
                    task.wait(0.5)
                end
            end
        end
        
        notify("✅ Race Completed", "Finished race!", 2)
    end
end

-- Auto Race Loop
local function autoRaceLoop()
    while autoRaceEnabled do
        -- Intentar iniciar carrera
        local started = startRace()
        
        if started then
            task.wait(2) -- Esperar a que cargue
            
            -- Auto completar si está activado
            if autoFinishEnabled then
                autoCompleteRace()
            end
            
            task.wait(5) -- Esperar antes de siguiente carrera
        else
            task.wait(3)
        end
    end
end

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "🏎️ GF HUB - Car Zone",
    SubTitle = "by Gael Fonzar",
    TabWidth = 160,
    Size = UDim2.fromOffset(550, 400),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightShift
})

-- Create Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "🏠 Main", Icon = "home" }),
    Race = Window:AddTab({ Title = "🏁 Auto Race", Icon = "flag" }),
    Winter = Window:AddTab({ Title = "❄️ Winter Event", Icon = "snowflake" }),
    Settings = Window:AddTab({ Title = "⚙️ Settings", Icon = "settings" })
}

-- ═══════════════════════════════════════
-- 🏠 MAIN TAB
-- ═══════════════════════════════════════

Tabs.Main:AddParagraph({
    Title = "Welcome to GF HUB!",
    Content = "Car Zone Auto Farm Script\n\nFeatures:\n• Auto Race (Highest Rewards)\n• Auto Winter Event\n• Auto Collect Snowflakes\n• Snowflake ESP"
})

Tabs.Main:AddParagraph({
    Title = "How to Use:",
    Content = "1. Go to 🏁 Auto Race tab\n2. Enable Auto Race\n3. Enable Auto Finish for instant completion\n\nFor Winter Event:\n1. Go to ❄️ Winter Event tab\n2. Enable Snowflake ESP to see them\n3. Enable Auto Collect"
})

-- ═══════════════════════════════════════
-- 🏁 AUTO RACE TAB
-- ═══════════════════════════════════════

Tabs.Race:AddParagraph({
    Title = "Auto Race System",
    Content = "Automatically starts and completes races for maximum rewards"
})

local AutoRaceToggle = Tabs.Race:AddToggle("AutoRace", {
    Title = "🏁 Auto Start Races",
    Description = "Automatically join and start races",
    Default = false,
    Callback = function(Value)
        autoRaceEnabled = Value
        
        if Value then
            notify("🏁 Auto Race ON", "Starting auto race...", 2)
            task.spawn(autoRaceLoop)
        else
            notify("Auto Race OFF", "", 2)
        end
    end
})

local AutoFinishToggle = Tabs.Race:AddToggle("AutoFinish", {
    Title = "⚡ Auto Finish Races",
    Description = "Instantly complete races (teleport to checkpoints)",
    Default = false,
    Callback = function(Value)
        autoFinishEnabled = Value
        notify(Value and "⚡ Auto Finish ON" or "Auto Finish OFF", "", 2)
    end
})

Tabs.Race:AddSection("Manual Controls")

Tabs.Race:AddButton({
    Title = "🏁 Start Race Manually",
    Description = "Try to start a race now",
    Callback = function()
        startRace()
    end
})

Tabs.Race:AddButton({
    Title = "⚡ Complete Race Now",
    Description = "Teleport through checkpoints",
    Callback = function()
        autoCompleteRace()
    end
})

-- ═══════════════════════════════════════
-- ❄️ WINTER EVENT TAB
-- ═══════════════════════════════════════

Tabs.Winter:AddParagraph({
    Title = "Winter Event",
    Content = "Auto collect snowflakes during races or free roam"
})

local SnowflakeESPToggle = Tabs.Winter:AddToggle("SnowflakeESP", {
    Title = "👁️ Snowflake ESP",
    Description = "See snowflakes through walls",
    Default = false,
    Callback = function(Value)
        snowflakeESPEnabled = Value
        updateAllSnowflakeESP()
        notify(Value and "❄️ ESP ON" or "ESP OFF", "", 2)
    end
})

local AutoWinterToggle = Tabs.Winter:AddToggle("AutoWinter", {
    Title = "❄️ Auto Collect Snowflakes",
    Description = "Automatically teleport and collect snowflakes",
    Default = false,
    Callback = function(Value)
        autoWinterEnabled = Value
        
        if Value then
            notify("❄️ Auto Winter ON", "Collecting snowflakes...", 2)
            task.spawn(autoCollectSnowflakes)
        else
            notify("Auto Winter OFF", "", 2)
        end
    end
})

Tabs.Winter:AddSection("Manual Controls")

Tabs.Winter:AddButton({
    Title = "🔄 Refresh Snowflake ESP",
    Description = "Update ESP to find new snowflakes",
    Callback = function()
        updateAllSnowflakeESP()
    end
})

Tabs.Winter:AddButton({
    Title = "📍 Teleport to Nearest",
    Description = "Teleport to closest snowflake",
    Callback = function()
        local snowflakes = findSnowflakes()
        local root = getRoot()
        
        if #snowflakes > 0 and root then
            -- Find closest
            local closest = nil
            local closestDist = math.huge
            
            for _, snowflake in pairs(snowflakes) do
                local part = snowflake:IsA("Model") and snowflake:FindFirstChildWhichIsA("BasePart") or snowflake
                if part then
                    local dist = (root.Position - part.Position).Magnitude
                    if dist < closestDist then
                        closest = snowflake
                        closestDist = dist
                    end
                end
            end
            
            if closest then
                teleportToSnowflake(closest)
                notify("✅ Teleported", "Teleported to nearest snowflake", 2)
            end
        else
            notify("❌ No Snowflakes", "No snowflakes found!", 3)
        end
    end
})

Tabs.Winter:AddButton({
    Title = "📊 Show Snowflake Count",
    Description = "Display how many snowflakes are available",
    Callback = function()
        local snowflakes = findSnowflakes()
        notify("❄️ Snowflakes Found", #snowflakes .. " snowflakes in workspace", 3)
    end
})

-- ═══════════════════════════════════════
-- ⚙️ SETTINGS TAB
-- ═══════════════════════════════════════

Tabs.Settings:AddParagraph({
    Title = "GF HUB Settings",
    Content = "Configure your experience"
})

Tabs.Settings:AddButton({
    Title = "Unload Script",
    Description = "Remove GF HUB completely",
    Callback = function()
        autoRaceEnabled = false
        autoWinterEnabled = false
        Fluent:Destroy()
    end
})

InterfaceManager:SetLibrary(Fluent)
SaveManager:SetLibrary(Fluent)

InterfaceManager:SetFolder("GFHub")
SaveManager:SetFolder("GFHub/CarZone")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Tabs.Settings:AddSection("Credits")

Tabs.Settings:AddParagraph({
    Title = "👤 Created by: Gael Fonzar",
    Content = "Version: 1.0\nGame: Car Zone Racing & Drifting\nStatus: ✅ Loaded"
})

-- ═══════════════════════════════════════
-- 🔄 MAIN LOOP
-- ═══════════════════════════════════════

-- ESP Update Loop
connections.ESPUpdate = RunService.RenderStepped:Connect(function()
    updateSnowflakeESP()
end)

-- Auto refresh snowflakes every 10 seconds
connections.SnowflakeRefresh = RunService.Heartbeat:Connect(function()
    task.wait(10)
    if snowflakeESPEnabled then
        local snowflakes = findSnowflakes()
        
        -- Add ESP to new snowflakes
        for _, snowflake in pairs(snowflakes) do
            if not espObjects[snowflake] then
                createSnowflakeESP(snowflake)
            end
        end
    end
end)

-- Cleanup on character respawn
player.CharacterAdded:Connect(function()
    task.wait(2)
    if snowflakeESPEnabled then
        updateAllSnowflakeESP()
    end
end)

-- Cleanup Function
local function cleanup()
    autoRaceEnabled = false
    autoWinterEnabled = false
    
    for _, connection in pairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    for snowflake, _ in pairs(espObjects) do
        removeSnowflakeESP(snowflake)
    end
    
    notify("👋 GF HUB Unloaded", "Script removed successfully", 3)
end

Window:OnUnload(cleanup)

-- Save settings
SaveManager:IgnoreThemeSettings()
SaveManager:LoadAutoloadConfig()

-- Final notification
notify("🏎️ GF HUB Loaded", "Car Zone script ready!\nPress RightShift to toggle", 5)

print("═══════════════════════════════════════")
print("🏎️ GF HUB - Car Zone Auto Farm")
print("Created by: Gael Fonzar")
print("Game: Car Zone Racing & Drifting")
print("Features: Auto Race + Winter Event")
print("Press RightShift to open menu")
print("═══════════════════════════════════════")
