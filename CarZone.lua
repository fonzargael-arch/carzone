--[[
    ═══════════════════════════════════════
    🏎️ GF HUB - Car Zone Auto Farm (FIXED)
    ═══════════════════════════════════════
    Created by: Gael Fonzar
    Game: Car Zone Racing & Drifting
    Version: 1.1 (Anti-Kick + Optimized)
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
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

-- Variables
local autoRaceEnabled = false
local autoWinterEnabled = false
local snowflakeESPEnabled = false
local collectDelay = 1.5 -- Delay anti-kick
local useSmooth = true -- Movimiento suave

local connections = {}
local espObjects = {}
local collectedSnowflakes = {}

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

-- Find Snowflakes (OPTIMIZED)
local function findSnowflakes()
    local snowflakes = {}
    
    -- Buscar solo en lugares específicos para evitar crash
    local searchLocations = {
        Workspace:FindFirstChild("Snowflakes"),
        Workspace:FindFirstChild("Winter"),
        Workspace:FindFirstChild("Map")
    }
    
    for _, location in pairs(searchLocations) do
        if location then
            for _, obj in pairs(location:GetChildren()) do
                -- Buscar solo BaseParts para evitar lag
                if obj:IsA("BasePart") and not collectedSnowflakes[obj] then
                    local name = obj.Name:lower()
                    if name:find("snow") or name:find("flake") or name:find("winter") then
                        table.insert(snowflakes, obj)
                    end
                elseif obj:IsA("Model") then
                    local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if primary and not collectedSnowflakes[obj] then
                        local name = obj.Name:lower()
                        if name:find("snow") or name:find("flake") or name:find("winter") then
                            table.insert(snowflakes, obj)
                        end
                    end
                end
            end
        end
    end
    
    return snowflakes
end

-- ESP for Snowflakes (FIXED - NO CRASH)
local function createSnowflakeESP(snowflake)
    if not snowflake or espObjects[snowflake] then return end
    
    pcall(function()
        local part = snowflake:IsA("Model") and (snowflake.PrimaryPart or snowflake:FindFirstChildWhichIsA("BasePart")) or snowflake
        if not part or not part:IsA("BasePart") then return end
        
        -- Solo crear BillboardGui (más ligero que Highlight)
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "GF_SnowESP"
        billboard.Adornee = part
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = part
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(135, 206, 250)
        frame.BackgroundTransparency = 0.7
        frame.BorderSizePixel = 2
        frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
        frame.Parent = billboard
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0.6, 0)
        label.BackgroundTransparency = 1
        label.Text = "❄️"
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Parent = frame
        
        local distLabel = Instance.new("TextLabel")
        distLabel.Size = UDim2.new(1, 0, 0.4, 0)
        distLabel.Position = UDim2.new(0, 0, 0.6, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = "0m"
        distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        distLabel.TextScaled = true
        distLabel.Font = Enum.Font.Gotham
        distLabel.Parent = frame
        
        espObjects[snowflake] = {
            billboard = billboard,
            distLabel = distLabel,
            part = part
        }
    end)
end

local function removeSnowflakeESP(snowflake)
    if espObjects[snowflake] then
        pcall(function()
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
        pcall(function()
            if snowflake and snowflake.Parent and espData.part and espData.distLabel then
                local distance = math.floor((myRoot.Position - espData.part.Position).Magnitude)
                espData.distLabel.Text = distance .. "m"
            else
                removeSnowflakeESP(snowflake)
            end
        end)
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

-- SMOOTH TELEPORT (Anti-Kick)
local function smoothTeleport(targetPos)
    local root = getRoot()
    if not root then return false end
    
    if useSmooth then
        -- Movimiento suave en vez de teleport instantáneo
        local distance = (root.Position - targetPos).Magnitude
        local steps = math.clamp(math.floor(distance / 10), 3, 10)
        
        for i = 1, steps do
            if not autoWinterEnabled then break end
            
            local alpha = i / steps
            local newPos = root.Position:Lerp(targetPos, alpha)
            root.CFrame = CFrame.new(newPos)
            
            task.wait(0.1)
        end
    else
        root.CFrame = CFrame.new(targetPos)
    end
    
    return true
end

-- Auto Collect Snowflakes (FIXED - ANTI-KICK)
local function autoCollectSnowflakes()
    while autoWinterEnabled do
        local snowflakes = findSnowflakes()
        
        if #snowflakes == 0 then
            notify("⚠️ No Snowflakes", "Waiting for snowflakes...", 2)
            task.wait(5)
        else
            -- Ordenar por distancia
            local root = getRoot()
            if root then
                table.sort(snowflakes, function(a, b)
                    local partA = a:IsA("Model") and (a.PrimaryPart or a:FindFirstChildWhichIsA("BasePart")) or a
                    local partB = b:IsA("Model") and (b.PrimaryPart or b:FindFirstChildWhichIsA("BasePart")) or b
                    
                    if partA and partB then
                        return (root.Position - partA.Position).Magnitude < (root.Position - partB.Position).Magnitude
                    end
                    return false
                end)
            end
            
            for _, snowflake in pairs(snowflakes) do
                if not autoWinterEnabled then break end
                
                if snowflake and snowflake.Parent then
                    local targetPart = snowflake:IsA("Model") and (snowflake.PrimaryPart or snowflake:FindFirstChildWhichIsA("BasePart")) or snowflake
                    
                    if targetPart then
                        -- Teleport suave
                        local success = smoothTeleport(targetPart.Position)
                        
                        if success then
                            -- Esperar a recoger
                            task.wait(collectDelay)
                            
                            -- Marcar como recolectado
                            collectedSnowflakes[snowflake] = true
                            
                            -- Verificar si fue removido
                            if not snowflake.Parent then
                                notify("✅ Collected", "Snowflake +1", 1)
                            end
                        end
                    end
                end
            end
        end
        
        task.wait(2)
    end
end

-- FIND RACE REMOTES (FIXED)
local function findRaceRemotes()
    local remotes = {}
    
    -- Buscar en ReplicatedStorage
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("race") or name:find("start") or name:find("join") or name:find("event") then
                table.insert(remotes, obj)
            end
        end
    end
    
    return remotes
end

-- Start Race (MULTIPLE METHODS)
local function startRace()
    -- Método 1: Buscar botones en UI
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in pairs(playerGui:GetDescendants()) do
            if gui:IsA("TextButton") then
                local text = gui.Text:lower()
                if text:find("start") or text:find("race") or text:find("join") or text:find("play") then
                    -- Intentar hacer click
                    for _, connection in pairs(getconnections(gui.MouseButton1Click)) do
                        pcall(function()
                            connection:Fire()
                        end)
                    end
                    
                    -- También simular click visual
                    pcall(function()
                        gui.MouseButton1Click:Fire()
                    end)
                    
                    notify("🏁 Race Started", "Method: UI Button", 2)
                    return true
                end
            end
        end
    end
    
    -- Método 2: Buscar RemoteEvents
    local remotes = findRaceRemotes()
    for _, remote in pairs(remotes) do
        pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer()
                notify("🏁 Race Started", "Method: RemoteEvent", 2)
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer()
                notify("🏁 Race Started", "Method: RemoteFunction", 2)
            end
        end)
        task.wait(0.5)
    end
    
    return false
end

-- Auto Race Loop
local function autoRaceLoop()
    while autoRaceEnabled do
        notify("🔄 Trying Race", "Attempting to start...", 2)
        
        local started = startRace()
        
        if started then
            task.wait(10) -- Esperar tiempo de carrera
        else
            task.wait(5)
        end
    end
end

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "🏎️ GF HUB - Car Zone v1.1",
    SubTitle = "by Gael Fonzar (Fixed)",
    TabWidth = 160,
    Size = UDim2.fromOffset(550, 420),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightShift
})

-- Create Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "🏠 Main", Icon = "home" }),
    Winter = Window:AddTab({ Title = "❄️ Winter Event", Icon = "snowflake" }),
    Race = Window:AddTab({ Title = "🏁 Race", Icon = "flag" }),
    Settings = Window:AddTab({ Title = "⚙️ Settings", Icon = "settings" })
}

-- ═══════════════════════════════════════
-- 🏠 MAIN TAB
-- ═══════════════════════════════════════

Tabs.Main:AddParagraph({
    Title = "Welcome to GF HUB v1.1!",
    Content = "FIXES:\n• ESP Optimized (No Crash)\n• Anti-Kick System\n• Smooth Teleport\n• Better Race Detection"
})

Tabs.Main:AddParagraph({
    Title = "⚠️ Important",
    Content = "Snowflake collection uses SMOOTH movement to avoid kicks.\n\nIncrease 'Collect Delay' if you still get kicked."
})

-- ═══════════════════════════════════════
-- ❄️ WINTER EVENT TAB
-- ═══════════════════════════════════════

Tabs.Winter:AddParagraph({
    Title = "Winter Event (FIXED)",
    Content = "Now with anti-kick protection!"
})

local SnowflakeESPToggle = Tabs.Winter:AddToggle("SnowflakeESP", {
    Title = "👁️ Snowflake ESP",
    Description = "Optimized - Won't crash",
    Default = false,
    Callback = function(Value)
        snowflakeESPEnabled = Value
        if Value then
            updateAllSnowflakeESP()
        else
            for snowflake, _ in pairs(espObjects) do
                removeSnowflakeESP(snowflake)
            end
        end
        notify(Value and "❄️ ESP ON" or "ESP OFF", "", 2)
    end
})

local AutoWinterToggle = Tabs.Winter:AddToggle("AutoWinter", {
    Title = "❄️ Auto Collect Snowflakes",
    Description = "With anti-kick protection",
    Default = false,
    Callback = function(Value)
        autoWinterEnabled = Value
        
        if Value then
            collectedSnowflakes = {} -- Reset
            notify("❄️ Auto Winter ON", "Using smooth movement", 2)
            task.spawn(autoCollectSnowflakes)
        else
            notify("Auto Winter OFF", "", 2)
        end
    end
})

local SmoothToggle = Tabs.Winter:AddToggle("SmoothMovement", {
    Title = "🌊 Smooth Movement",
    Description = "Prevents kicks (Recommended: ON)",
    Default = true,
    Callback = function(Value)
        useSmooth = Value
        notify(Value and "Smooth ON" or "Smooth OFF", "", 2)
    end
})

local CollectDelaySlider = Tabs.Winter:AddSlider("CollectDelay", {
    Title = "Collect Delay",
    Description = "Time between collections (Anti-Kick)",
    Default = 1.5,
    Min = 0.5,
    Max = 5,
    Rounding = 1,
    Callback = function(Value)
        collectDelay = Value
        notify("Delay Set", Value .. " seconds", 2)
    end
})

Tabs.Winter:AddSection("Manual Controls")

Tabs.Winter:AddButton({
    Title = "🔄 Refresh ESP",
    Description = "Find new snowflakes",
    Callback = function()
        updateAllSnowflakeESP()
    end
})

Tabs.Winter:AddButton({
    Title = "📊 Count Snowflakes",
    Description = "Show available snowflakes",
    Callback = function()
        local snowflakes = findSnowflakes()
        notify("❄️ Found", #snowflakes .. " snowflakes available", 3)
    end
})

Tabs.Winter:AddButton({
    Title = "🗑️ Clear Collected List",
    Description = "Reset collected snowflakes",
    Callback = function()
        collectedSnowflakes = {}
        notify("✅ Cleared", "Collected list reset", 2)
    end
})

-- ═══════════════════════════════════════
-- 🏁 RACE TAB
-- ═══════════════════════════════════════

Tabs.Race:AddParagraph({
    Title = "Auto Race (Experimental)",
    Content = "Trying multiple methods to start races"
})

local AutoRaceToggle = Tabs.Race:AddToggle("AutoRace", {
    Title = "🏁 Auto Start Races",
    Description = "Experimental feature",
    Default = false,
    Callback = function(Value)
        autoRaceEnabled = Value
        
        if Value then
            notify("🏁 Auto Race ON", "Experimental mode", 2)
            task.spawn(autoRaceLoop)
        else
            notify("Auto Race OFF", "", 2)
        end
    end
})

Tabs.Race:AddButton({
    Title = "🔍 Find Race Remotes",
    Description = "Debug: Show race remotes",
    Callback = function()
        local remotes = findRaceRemotes()
        notify("🔍 Found", #remotes .. " race-related remotes", 3)
        
        for i, remote in pairs(remotes) do
            if i <= 5 then
                print("Remote " .. i .. ": " .. remote.Name .. " (" .. remote.ClassName .. ")")
            end
        end
    end
})

Tabs.Race:AddButton({
    Title = "🏁 Try Start Race",
    Description = "Manual attempt",
    Callback = function()
        startRace()
    end
})

-- ═══════════════════════════════════════
-- ⚙️ SETTINGS TAB
-- ═══════════════════════════════════════

Tabs.Settings:AddParagraph({
    Title = "Settings",
    Content = "Configure your experience"
})

Tabs.Settings:AddButton({
    Title = "Unload Script",
    Description = "Remove completely",
    Callback = function()
        autoRaceEnabled = false
        autoWinterEnabled = false
        
        for _, connection in pairs(connections) do
            if connection then
                connection:Disconnect()
            end
        end
        
        Fluent:Destroy()
    end
})

InterfaceManager:SetLibrary(Fluent)
SaveManager:SetLibrary(Fluent)

InterfaceManager:SetFolder("GFHub")
SaveManager:SetFolder("GFHub/CarZone")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Tabs.Settings:AddSection("Info")

Tabs.Settings:AddParagraph({
    Title = "👤 Created by: Gael Fonzar",
    Content = "Version: 1.1 (Fixed)\nGame: Car Zone\nStatus: ✅ Loaded"
})

-- ═══════════════════════════════════════
-- 🔄 LOOPS
-- ═══════════════════════════════════════

-- ESP Update (Optimized)
local espUpdateTime = 0
connections.ESPUpdate = RunService.RenderStepped:Connect(function(deltaTime)
    espUpdateTime = espUpdateTime + deltaTime
    if espUpdateTime >= 0.5 then -- Update every 0.5s instead of every frame
        espUpdateTime = 0
        updateSnowflakeESP()
    end
end)

-- Auto refresh snowflakes (Less frequent)
local refreshTime = 0
connections.SnowflakeRefresh = RunService.Heartbeat:Connect(function(deltaTime)
    refreshTime = refreshTime + deltaTime
    if refreshTime >= 15 and snowflakeESPEnabled then -- Every 15 seconds
        refreshTime = 0
        pcall(function()
            local snowflakes = findSnowflakes()
            for _, snowflake in pairs(snowflakes) do
                if not espObjects[snowflake] then
                    createSnowflakeESP(snowflake)
                end
            end
        end)
    end
end)

-- Cleanup
local function cleanup()
    autoRaceEnabled = false
    autoWinterEnabled = false
    
    for _, connection in pairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    
    for snowflake, _ in pairs(espObjects) do
        removeSnowflakeESP(snowflake)
    end
    
    notify("👋 Unloaded", "GF HUB removed", 2)
end

Window:OnUnload(cleanup)

-- Save
SaveManager:IgnoreThemeSettings()
SaveManager:LoadAutoloadConfig()

-- Done
notify("🏎️ GF HUB v1.1", "Fixed version loaded!\nPress RightShift", 4)

print("═══════════════════════════════════════")
print("🏎️ GF HUB - Car Zone v1.1 (FIXED)")
print("✅ ESP Optimized")
print("✅ Anti-Kick System")
print("✅ Smooth Teleport")
print("═══════════════════════════════════════")
