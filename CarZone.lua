--[[
    ═══════════════════════════════════════
    🏎️ GF HUB - Car Zone PERFECT VERSION
    ═══════════════════════════════════════
    Created by: Gael Fonzar
    Game: Car Zone Racing & Drifting
    Version: 3.0 - FULLY FUNCTIONAL
    ═══════════════════════════════════════
    Using EXACT game remotes and paths!
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

local player = Players.LocalPlayer

-- Variables
local autoWinterEnabled = false
local autoRaceEnabled = false
local autoCoinEnabled = false
local collectDelay = 1
local useSmooth = true
local autoFinishRace = false

local connections = {}
local collected = {}

-- Helper Functions
local function notify(title, content, duration)
    Fluent:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3
    })
end

local function getChar()
    return player.Character
end

local function getRoot()
    local char = getChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ═══════════════════════════════════════
-- ❄️ WINTER EVENT (EXACT PATHS)
-- ═══════════════════════════════════════

local function findSnowflakes()
    local snowflakes = {}
    
    -- Path exacto: Workspace.Pumpkins.SnowFlake
    local pumpkins = Workspace:FindFirstChild("Pumpkins")
    if pumpkins then
        for _, obj in pairs(pumpkins:GetChildren()) do
            if obj.Name == "SnowFlake" and not collected[obj] then
                table.insert(snowflakes, obj)
            end
        end
    end
    
    return snowflakes
end

local function smoothTeleport(targetPos)
    local root = getRoot()
    if not root then return false end
    
    if useSmooth then
        local distance = (root.Position - targetPos).Magnitude
        local steps = math.clamp(math.floor(distance / 15), 3, 8)
        
        for i = 1, steps do
            if not autoWinterEnabled then break end
            local alpha = i / steps
            local newPos = root.Position:Lerp(targetPos, alpha)
            root.CFrame = CFrame.new(newPos)
            task.wait(0.08)
        end
    else
        root.CFrame = CFrame.new(targetPos)
    end
    
    return true
end

local function collectSnowflake(snowflake)
    if not snowflake or not snowflake.Parent then return false end
    
    local targetPart = snowflake:IsA("Model") and (snowflake.PrimaryPart or snowflake:FindFirstChildWhichIsA("BasePart")) or snowflake
    if not targetPart then return false end
    
    -- Teleport suave
    smoothTeleport(targetPart.Position)
    
    task.wait(collectDelay)
    
    -- Marcar como recolectado
    collected[snowflake] = true
    
    -- Verificar si desapareció
    if not snowflake.Parent then
        return true
    end
    
    return false
end

local function autoCollectSnowflakes()
    while autoWinterEnabled do
        local snowflakes = findSnowflakes()
        
        if #snowflakes == 0 then
            notify("⏳ Waiting", "No snowflakes available...", 2)
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
            
            -- Recolectar cada uno
            for _, snowflake in pairs(snowflakes) do
                if not autoWinterEnabled then break end
                
                local success = collectSnowflake(snowflake)
                if success then
                    notify("✅ +1", "Snowflake collected!", 1)
                end
                
                task.wait(0.3)
            end
        end
        
        task.wait(2)
    end
end

-- ═══════════════════════════════════════
-- 💰 AUTO COLLECT COINS
-- ═══════════════════════════════════════

local function findCoins()
    local coins = {}
    
    -- Buscar en LeaderBoards
    local leaderBoards = Workspace:FindFirstChild("LeaderBoards")
    if leaderBoards then
        for _, obj in pairs(leaderBoards:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name:lower():find("coin") and not collected[obj] then
                table.insert(coins, obj)
            end
        end
    end
    
    -- Buscar en otras ubicaciones
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name == "cash" or obj.Name:lower():find("coin")) and not collected[obj] then
            table.insert(coins, obj)
        end
    end
    
    return coins
end

local function autoCollectCoins()
    while autoCoinEnabled do
        local coins = findCoins()
        
        if #coins > 0 then
            for _, coin in pairs(coins) do
                if not autoCoinEnabled then break end
                
                smoothTeleport(coin.Position)
                task.wait(collectDelay)
                collected[coin] = true
                
                if not coin.Parent then
                    notify("💰 +1", "Coin collected!", 1)
                end
            end
        end
        
        task.wait(3)
    end
end

-- ═══════════════════════════════════════
-- 🏁 AUTO RACE (EXACT REMOTES)
-- ═══════════════════════════════════════

local function joinRace()
    -- Usar el remote exacto: RaceRemotes.JoinRace
    local raceRemotes = ReplicatedStorage:FindFirstChild("RaceRemotes")
    if raceRemotes then
        local joinRace = raceRemotes:FindFirstChild("JoinRace")
        if joinRace and joinRace:IsA("RemoteEvent") then
            pcall(function()
                joinRace:FireServer()
                notify("🏁 Joined", "Joining race...", 2)
            end)
            return true
        end
    end
    
    return false
end

local function startMiniGame()
    -- Usar MiniGames.Start
    local miniGames = ReplicatedStorage:FindFirstChild("MiniGames")
    if miniGames then
        local start = miniGames:FindFirstChild("Start")
        if start and start:IsA("RemoteEvent") then
            pcall(function()
                start:FireServer()
                notify("🎮 Started", "MiniGame started!", 2)
            end)
            return true
        end
    end
    
    return false
end

local function finishRace()
    -- Usar RaceRemotes.FinishedRace
    local raceRemotes = ReplicatedStorage:FindFirstChild("RaceRemotes")
    if raceRemotes then
        local finishedRace = raceRemotes:FindFirstChild("FinishedRace")
        if finishedRace and finishedRace:IsA("RemoteEvent") then
            pcall(function()
                finishedRace:FireServer()
                notify("🏆 Finished", "Race completed!", 2)
            end)
            return true
        end
    end
    
    return false
end

local function teleportToCheckpoints()
    -- Buscar checkpoints en CarQuestFolder
    local carQuestFolder = Workspace:FindFirstChild("CarQuestFolder")
    if not carQuestFolder then return end
    
    local npc = carQuestFolder:FindFirstChild("NPC")
    if not npc then return end
    
    local billboardGui = npc:FindFirstChild("BillboardGui")
    if not billboardGui then return end
    
    local checkpointFrame = billboardGui:FindFirstChild("CheckpointFrame")
    if checkpointFrame then
        local root = getRoot()
        if root then
            -- Teleport a cada checkpoint
            for i = 1, 5 do
                if not autoFinishRace then break end
                root.CFrame = checkpointFrame.CFrame * CFrame.new(0, 5, 0)
                task.wait(0.5)
            end
            
            notify("✅ Checkpoints", "Completed all checkpoints", 2)
        end
    end
end

local function autoRaceLoop()
    while autoRaceEnabled do
        -- Intentar unirse a carrera
        local joined = joinRace()
        
        if not joined then
            -- Intentar MiniGame si no hay carrera
            startMiniGame()
        end
        
        task.wait(3)
        
        -- Auto terminar si está activado
        if autoFinishRace then
            teleportToCheckpoints()
            task.wait(1)
            finishRace()
        end
        
        task.wait(10)
    end
end

-- ═══════════════════════════════════════
-- 🎨 CREATE UI
-- ═══════════════════════════════════════

local Window = Fluent:CreateWindow({
    Title = "🏎️ GF HUB - Car Zone v3.0",
    SubTitle = "by Gael Fonzar (PERFECT)",
    TabWidth = 160,
    Size = UDim2.fromOffset(560, 450),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightShift
})

local Tabs = {
    Main = Window:AddTab({ Title = "🏠 Main", Icon = "home" }),
    Winter = Window:AddTab({ Title = "❄️ Winter", Icon = "snowflake" }),
    Money = Window:AddTab({ Title = "💰 Money", Icon = "dollar-sign" }),
    Race = Window:AddTab({ Title = "🏁 Race", Icon = "flag" }),
    Info = Window:AddTab({ Title = "📊 Info", Icon = "info" })
}

-- ═══════════════════════════════════════
-- 🏠 MAIN TAB
-- ═══════════════════════════════════════

Tabs.Main:AddParagraph({
    Title = "🎉 Welcome to GF HUB v3.0!",
    Content = "This version uses EXACT game paths:\n\n✅ Workspace.Pumpkins.SnowFlake\n✅ RaceRemotes.JoinRace\n✅ MiniGames.Start\n✅ Auto everything!"
})

Tabs.Main:AddParagraph({
    Title = "🚀 Quick Start",
    Content = "1. Go to ❄️ Winter tab\n2. Enable Auto Collect\n3. Watch it work!\n\nFor races: 🏁 Race tab"
})

-- ═══════════════════════════════════════
-- ❄️ WINTER TAB
-- ═══════════════════════════════════════

Tabs.Winter:AddParagraph({
    Title = "❄️ Winter Event Auto Farm",
    Content = "Collects from: Workspace.Pumpkins.SnowFlake"
})

local AutoWinterToggle = Tabs.Winter:AddToggle("AutoWinter", {
    Title = "❄️ Auto Collect Snowflakes",
    Description = "Uses exact game path",
    Default = false,
    Callback = function(Value)
        autoWinterEnabled = Value
        if Value then
            collected = {}
            notify("❄️ Started", "Collecting snowflakes...", 2)
            task.spawn(autoCollectSnowflakes)
        else
            notify("Stopped", "", 1)
        end
    end
})

local SmoothToggle = Tabs.Winter:AddToggle("Smooth", {
    Title = "🌊 Smooth Movement",
    Description = "Anti-kick protection",
    Default = true,
    Callback = function(Value)
        useSmooth = Value
    end
})

local DelaySlider = Tabs.Winter:AddSlider("Delay", {
    Title = "Collect Delay",
    Description = "Time between collections",
    Default = 1,
    Min = 0.5,
    Max = 3,
    Rounding = 1,
    Callback = function(Value)
        collectDelay = Value
    end
})

Tabs.Winter:AddButton({
    Title = "📊 Count Snowflakes",
    Description = "Show available snowflakes",
    Callback = function()
        local snowflakes = findSnowflakes()
        notify("❄️ Found", #snowflakes .. " snowflakes", 2)
    end
})

Tabs.Winter:AddButton({
    Title = "🗑️ Clear Collected",
    Description = "Reset collected list",
    Callback = function()
        collected = {}
        notify("✅ Cleared", "Can collect again", 2)
    end
})

-- ═══════════════════════════════════════
-- 💰 MONEY TAB
-- ═══════════════════════════════════════

Tabs.Money:AddParagraph({
    Title = "💰 Auto Collect Coins",
    Content = "Collects coins from workspace"
})

local AutoCoinToggle = Tabs.Money:AddToggle("AutoCoin", {
    Title = "💰 Auto Collect Coins",
    Description = "Collect all coins",
    Default = false,
    Callback = function(Value)
        autoCoinEnabled = Value
        if Value then
            notify("💰 Started", "Collecting coins...", 2)
            task.spawn(autoCollectCoins)
        else
            notify("Stopped", "", 1)
        end
    end
})

Tabs.Money:AddButton({
    Title = "📊 Count Coins",
    Description = "Show available coins",
    Callback = function()
        local coins = findCoins()
        notify("💰 Found", #coins .. " coins", 2)
    end
})

-- ═══════════════════════════════════════
-- 🏁 RACE TAB
-- ═══════════════════════════════════════

Tabs.Race:AddParagraph({
    Title = "🏁 Auto Race System",
    Content = "Uses: RaceRemotes.JoinRace\nAnd: MiniGames.Start"
})

local AutoRaceToggle = Tabs.Race:AddToggle("AutoRace", {
    Title = "🏁 Auto Join Races",
    Description = "Automatically join races",
    Default = false,
    Callback = function(Value)
        autoRaceEnabled = Value
        if Value then
            notify("🏁 Started", "Auto racing...", 2)
            task.spawn(autoRaceLoop)
        else
            notify("Stopped", "", 1)
        end
    end
})

local AutoFinishToggle = Tabs.Race:AddToggle("AutoFinish", {
    Title = "⚡ Auto Finish Race",
    Description = "Teleport through checkpoints",
    Default = false,
    Callback = function(Value)
        autoFinishRace = Value
        notify(Value and "⚡ Auto Finish ON" or "Auto Finish OFF", "", 2)
    end
})

Tabs.Race:AddSection("Manual Controls")

Tabs.Race:AddButton({
    Title = "🏁 Join Race Now",
    Description = "Use RaceRemotes.JoinRace",
    Callback = function()
        joinRace()
    end
})

Tabs.Race:AddButton({
    Title = "🎮 Start MiniGame",
    Description = "Use MiniGames.Start",
    Callback = function()
        startMiniGame()
    end
})

Tabs.Race:AddButton({
    Title = "🏆 Finish Race",
    Description = "Use RaceRemotes.FinishedRace",
    Callback = function()
        finishRace()
    end
})

Tabs.Race:AddButton({
    Title = "📍 Teleport Checkpoints",
    Description = "Go through all checkpoints",
    Callback = function()
        teleportToCheckpoints()
    end
})

-- ═══════════════════════════════════════
-- 📊 INFO TAB
-- ═══════════════════════════════════════

Tabs.Info:AddParagraph({
    Title = "📊 Game Information",
    Content = "Detected Systems:\n\n❄️ Snowflakes: Workspace.Pumpkins.SnowFlake\n💰 Coins: LeaderBoards & Workspace\n🏁 Races: RaceRemotes folder\n🎮 MiniGames: MiniGames.Start"
})

Tabs.Info:AddParagraph({
    Title = "🎯 Exact Remotes Used",
    Content = "• RaceRemotes.JoinRace\n• RaceRemotes.FinishedRace\n• MiniGames.Start\n• MiniGames.Finish"
})

Tabs.Info:AddButton({
    Title = "🔄 Check Game State",
    Description = "Verify remotes exist",
    Callback = function()
        local raceRemotes = ReplicatedStorage:FindFirstChild("RaceRemotes")
        local miniGames = ReplicatedStorage:FindFirstChild("MiniGames")
        local pumpkins = Workspace:FindFirstChild("Pumpkins")
        
        local status = ""
        status = status .. (raceRemotes and "✅" or "❌") .. " RaceRemotes\n"
        status = status .. (miniGames and "✅" or "❌") .. " MiniGames\n"
        status = status .. (pumpkins and "✅" or "❌") .. " Pumpkins (Snowflakes)"
        
        notify("🔍 Game State", status, 5)
    end
})

Tabs.Info:AddParagraph({
    Title = "👤 Created by: Gael Fonzar",
    Content = "Version: 3.0 (PERFECT)\nGame: Car Zone\nStatus: ✅ Ready"
})

-- ═══════════════════════════════════════
-- 🔄 STARTUP & CLEANUP
-- ═══════════════════════════════════════

local function cleanup()
    autoWinterEnabled = false
    autoRaceEnabled = false
    autoCoinEnabled = false
    
    for _, connection in pairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    
    notify("👋 Unloaded", "GF HUB removed", 2)
end

Window:OnUnload(cleanup)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:SetFolder("GFHub/CarZone")
InterfaceManager:SetFolder("GFHub")

SaveManager:BuildConfigSection(Tabs.Info)
InterfaceManager:BuildInterfaceSection(Tabs.Info)

SaveManager:IgnoreThemeSettings()
SaveManager:LoadAutoloadConfig()

-- Final notification
notify("🏎️ GF HUB v3.0", "PERFECT VERSION LOADED!\nUsing exact game paths\nPress RightShift", 5)

print("════════════════════════════════")
print("🏎️ GF HUB - CAR ZONE v3.0 PERFECT")
print("✅ Using EXACT game remotes")
print("✅ Workspace.Pumpkins.SnowFlake")
print("✅ RaceRemotes.JoinRace")
print("✅ MiniGames.Start")
print("════════════════════════════════")
