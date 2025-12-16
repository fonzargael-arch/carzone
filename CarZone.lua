--[[
    ═══════════════════════════════════════
    🔍 GF HUB - Car Zone SCANNER
    ═══════════════════════════════════════
    Created by: Gael Fonzar
    Game: Car Zone Racing & Drifting
    Version: 2.0 - Full Scanner
    ═══════════════════════════════════════
    This script will SCAN and DETECT:
    • All RemoteEvents/Functions
    • Money systems
    • Winter event systems
    • Race systems
    • LocalScripts
    ═══════════════════════════════════════
]]

-- Load Fluent Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

-- Scanner Data Storage
local scanData = {
    remoteEvents = {},
    remoteFunctions = {},
    bindableEvents = {},
    moneyRelated = {},
    winterRelated = {},
    raceRelated = {},
    localScripts = {},
    moduleScripts = {}
}

-- Auto Farm Variables
local autoWinterEnabled = false
local autoRaceEnabled = false
local collectDelay = 1.5
local useSmooth = true

local connections = {}
local collectedSnowflakes = {}

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
-- 🔍 SCANNER FUNCTIONS
-- ═══════════════════════════════════════

local function scanForRemotes()
    print("════════════════════════════════")
    print("🔍 SCANNING FOR REMOTES...")
    print("════════════════════════════════")
    
    scanData.remoteEvents = {}
    scanData.remoteFunctions = {}
    scanData.bindableEvents = {}
    
    -- Scan ReplicatedStorage
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            table.insert(scanData.remoteEvents, obj)
            print("📡 RemoteEvent: " .. obj:GetFullName())
            
            -- Classify by keywords
            local name = obj.Name:lower()
            if name:find("money") or name:find("cash") or name:find("coin") or name:find("currency") then
                table.insert(scanData.moneyRelated, obj)
                print("   💰 [MONEY RELATED]")
            end
            if name:find("winter") or name:find("snow") or name:find("event") then
                table.insert(scanData.winterRelated, obj)
                print("   ❄️ [WINTER RELATED]")
            end
            if name:find("race") or name:find("start") or name:find("finish") or name:find("checkpoint") then
                table.insert(scanData.raceRelated, obj)
                print("   🏁 [RACE RELATED]")
            end
        elseif obj:IsA("RemoteFunction") then
            table.insert(scanData.remoteFunctions, obj)
            print("📞 RemoteFunction: " .. obj:GetFullName())
        elseif obj:IsA("BindableEvent") then
            table.insert(scanData.bindableEvents, obj)
            print("🔗 BindableEvent: " .. obj:GetFullName())
        end
    end
    
    print("════════════════════════════════")
    print("✅ SCAN COMPLETE!")
    print("📡 RemoteEvents: " .. #scanData.remoteEvents)
    print("📞 RemoteFunctions: " .. #scanData.remoteFunctions)
    print("💰 Money Related: " .. #scanData.moneyRelated)
    print("❄️ Winter Related: " .. #scanData.winterRelated)
    print("🏁 Race Related: " .. #scanData.raceRelated)
    print("════════════════════════════════")
    
    notify("✅ Scan Complete", 
        #scanData.remoteEvents .. " RemoteEvents found\n" ..
        #scanData.moneyRelated .. " Money remotes\n" ..
        #scanData.winterRelated .. " Winter remotes\n" ..
        #scanData.raceRelated .. " Race remotes", 5)
end

local function scanForScripts()
    print("════════════════════════════════")
    print("🔍 SCANNING FOR SCRIPTS...")
    print("════════════════════════════════")
    
    scanData.localScripts = {}
    scanData.moduleScripts = {}
    
    -- Scan PlayerGui
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, obj in pairs(playerGui:GetDescendants()) do
            if obj:IsA("LocalScript") then
                table.insert(scanData.localScripts, obj)
                print("📜 LocalScript: " .. obj:GetFullName())
            elseif obj:IsA("ModuleScript") then
                table.insert(scanData.moduleScripts, obj)
                print("📦 ModuleScript: " .. obj:GetFullName())
            end
        end
    end
    
    -- Scan Character
    local char = getChar()
    if char then
        for _, obj in pairs(char:GetDescendants()) do
            if obj:IsA("LocalScript") then
                table.insert(scanData.localScripts, obj)
                print("📜 LocalScript (Char): " .. obj:GetFullName())
            end
        end
    end
    
    print("════════════════════════════════")
    print("✅ SCRIPT SCAN COMPLETE!")
    print("📜 LocalScripts: " .. #scanData.localScripts)
    print("📦 ModuleScripts: " .. #scanData.moduleScripts)
    print("════════════════════════════════")
    
    notify("✅ Scripts Scanned", 
        #scanData.localScripts .. " LocalScripts\n" ..
        #scanData.moduleScripts .. " ModuleScripts", 3)
end

local function scanWorkspaceForCollectibles()
    print("════════════════════════════════")
    print("🔍 SCANNING WORKSPACE FOR COLLECTIBLES...")
    print("════════════════════════════════")
    
    local snowflakes = 0
    local coins = 0
    local checkpoints = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        
        if name:find("snow") or name:find("flake") then
            snowflakes = snowflakes + 1
            if snowflakes <= 3 then
                print("❄️ Snowflake: " .. obj:GetFullName())
            end
        end
        
        if name:find("coin") or name:find("money") or name:find("cash") then
            coins = coins + 1
            if coins <= 3 then
                print("💰 Coin: " .. obj:GetFullName())
            end
        end
        
        if name:find("checkpoint") or name:find("finish") or name:find("gate") then
            checkpoints = checkpoints + 1
            if checkpoints <= 3 then
                print("🏁 Checkpoint: " .. obj:GetFullName())
            end
        end
    end
    
    print("════════════════════════════════")
    print("✅ WORKSPACE SCAN COMPLETE!")
    print("❄️ Snowflakes: " .. snowflakes)
    print("💰 Coins: " .. coins)
    print("🏁 Checkpoints: " .. checkpoints)
    print("════════════════════════════════")
    
    notify("✅ Workspace Scanned", 
        snowflakes .. " Snowflakes\n" ..
        coins .. " Coins\n" ..
        checkpoints .. " Checkpoints", 3)
end

local function deepScanPlayerGui()
    print("════════════════════════════════")
    print("🔍 DEEP SCANNING PLAYER GUI...")
    print("════════════════════════════════")
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    local buttons = {}
    local frames = {}
    local textLabels = {}
    
    for _, obj in pairs(playerGui:GetDescendants()) do
        if obj:IsA("TextButton") then
            table.insert(buttons, obj)
            local text = obj.Text:lower()
            if text:find("start") or text:find("race") or text:find("join") or text:find("play") then
                print("🔘 RACE BUTTON: " .. obj:GetFullName() .. " | Text: '" .. obj.Text .. "'")
            end
            if text:find("claim") or text:find("collect") or text:find("reward") then
                print("🎁 REWARD BUTTON: " .. obj:GetFullName() .. " | Text: '" .. obj.Text .. "'")
            end
        elseif obj:IsA("Frame") and obj.Name:lower():find("race") then
            table.insert(frames, obj)
            print("🖼️ RACE FRAME: " .. obj:GetFullName())
        elseif obj:IsA("TextLabel") then
            local text = obj.Text:lower()
            if text:find("money") or text:find("$") or text:find("cash") then
                print("💰 MONEY LABEL: " .. obj:GetFullName() .. " | Text: '" .. obj.Text .. "'")
            end
        end
    end
    
    print("════════════════════════════════")
    print("✅ GUI SCAN COMPLETE!")
    print("🔘 Buttons: " .. #buttons)
    print("🖼️ Frames: " .. #frames)
    print("════════════════════════════════")
    
    notify("✅ GUI Scanned", #buttons .. " Buttons found", 2)
end

-- ═══════════════════════════════════════
-- 🎯 AUTO FARM FUNCTIONS (Using Scan Data)
-- ═══════════════════════════════════════

local function findSnowflakes()
    local snowflakes = {}
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if (name:find("snow") or name:find("flake")) and not collectedSnowflakes[obj] then
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

local function autoCollectSnowflakes()
    while autoWinterEnabled do
        local snowflakes = findSnowflakes()
        
        if #snowflakes == 0 then
            task.wait(5)
        else
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
                        smoothTeleport(targetPart.Position)
                        task.wait(collectDelay)
                        collectedSnowflakes[snowflake] = true
                        
                        if not snowflake.Parent then
                            notify("✅ +1", "Snowflake collected", 1)
                        end
                    end
                end
            end
        end
        
        task.wait(2)
    end
end

local function startRace()
    -- Try all race-related remotes found in scan
    for _, remote in pairs(scanData.raceRelated) do
        if remote.Name == "Start" then
            pcall(function()
                remote:FireServer()
                notify("🏁 Race Started", "Using: " .. remote.Name, 2)
            end)
            return true
        end
    end
    
    -- Try TeleportEvent first, then Start
    for _, remote in pairs(scanData.remoteEvents) do
        if remote.Name == "TeleportEvent" then
            pcall(function()
                remote:FireServer()
            end)
            task.wait(0.5)
        end
    end
    
    for _, remote in pairs(scanData.remoteEvents) do
        if remote.Name == "Start" then
            pcall(function()
                remote:FireServer()
                notify("🏁 Race Started", "Success!", 2)
            end)
            return true
        end
    end
    
    return false
end

local function autoRaceLoop()
    while autoRaceEnabled do
        startRace()
        task.wait(15)
    end
end

-- ═══════════════════════════════════════
-- 🎨 CREATE UI
-- ═══════════════════════════════════════

local Window = Fluent:CreateWindow({
    Title = "🔍 GF HUB - Car Zone SCANNER",
    SubTitle = "by Gael Fonzar v2.0",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 480),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightShift
})

local Tabs = {
    Scanner = Window:AddTab({ Title = "🔍 Scanner", Icon = "search" }),
    Winter = Window:AddTab({ Title = "❄️ Winter", Icon = "snowflake" }),
    Race = Window:AddTab({ Title = "🏁 Race", Icon = "flag" }),
    Info = Window:AddTab({ Title = "📊 Info", Icon = "info" })
}

-- ═══════════════════════════════════════
-- 🔍 SCANNER TAB
-- ═══════════════════════════════════════

Tabs.Scanner:AddParagraph({
    Title = "🔍 Game Scanner",
    Content = "This will scan the ENTIRE game to find:\n• RemoteEvents\n• Money systems\n• Winter event systems\n• Race systems\n• Scripts"
})

Tabs.Scanner:AddButton({
    Title = "🔍 FULL GAME SCAN",
    Description = "Scan everything (Recommended first!)",
    Callback = function()
        notify("🔍 Scanning...", "Please wait...", 2)
        scanForRemotes()
        task.wait(1)
        scanForScripts()
        task.wait(1)
        scanWorkspaceForCollectibles()
        task.wait(1)
        deepScanPlayerGui()
        notify("✅ SCAN COMPLETE!", "Check console (F9) for details", 5)
    end
})

Tabs.Scanner:AddSection("Individual Scans")

Tabs.Scanner:AddButton({
    Title = "📡 Scan Remotes Only",
    Description = "Find all RemoteEvents/Functions",
    Callback = function()
        scanForRemotes()
    end
})

Tabs.Scanner:AddButton({
    Title = "📜 Scan Scripts Only",
    Description = "Find LocalScripts and Modules",
    Callback = function()
        scanForScripts()
    end
})

Tabs.Scanner:AddButton({
    Title = "🌍 Scan Workspace Only",
    Description = "Find collectibles in workspace",
    Callback = function()
        scanWorkspaceForCollectibles()
    end
})

Tabs.Scanner:AddButton({
    Title = "🎨 Scan GUI Only",
    Description = "Find buttons and interfaces",
    Callback = function()
        deepScanPlayerGui()
    end
})

Tabs.Scanner:AddSection("Export Scan Data")

Tabs.Scanner:AddButton({
    Title = "📋 Print All Remotes",
    Description = "Print remote names to console",
    Callback = function()
        print("════════════════════════════════")
        print("📡 ALL REMOTEEVENTS:")
        for i, remote in pairs(scanData.remoteEvents) do
            print(i .. ". " .. remote.Name .. " | " .. remote:GetFullName())
        end
        print("════════════════════════════════")
        notify("✅ Printed", #scanData.remoteEvents .. " remotes in console (F9)", 3)
    end
})

-- ═══════════════════════════════════════
-- ❄️ WINTER TAB
-- ═══════════════════════════════════════

Tabs.Winter:AddParagraph({
    Title = "❄️ Winter Event Auto Farm",
    Content = "Auto collect snowflakes with anti-kick"
})

local AutoWinterToggle = Tabs.Winter:AddToggle("AutoWinter", {
    Title = "❄️ Auto Collect Snowflakes",
    Description = "With smooth movement",
    Default = false,
    Callback = function(Value)
        autoWinterEnabled = Value
        if Value then
            collectedSnowflakes = {}
            notify("❄️ Started", "Collecting snowflakes...", 2)
            task.spawn(autoCollectSnowflakes)
        else
            notify("Stopped", "", 2)
        end
    end
})

local SmoothToggle = Tabs.Winter:AddToggle("Smooth", {
    Title = "🌊 Smooth Movement",
    Description = "Anti-kick (Recommended)",
    Default = true,
    Callback = function(Value)
        useSmooth = Value
    end
})

local DelaySlider = Tabs.Winter:AddSlider("Delay", {
    Title = "Collect Delay",
    Description = "Seconds between collections",
    Default = 1.5,
    Min = 0.5,
    Max = 5,
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

-- ═══════════════════════════════════════
-- 🏁 RACE TAB
-- ═══════════════════════════════════════

Tabs.Race:AddParagraph({
    Title = "🏁 Auto Race System",
    Content = "Uses detected remotes from scanner"
})

local AutoRaceToggle = Tabs.Race:AddToggle("AutoRace", {
    Title = "🏁 Auto Start Races",
    Description = "Automatically start races",
    Default = false,
    Callback = function(Value)
        autoRaceEnabled = Value
        if Value then
            notify("🏁 Started", "Auto racing...", 2)
            task.spawn(autoRaceLoop)
        else
            notify("Stopped", "", 2)
        end
    end
})

Tabs.Race:AddButton({
    Title = "🏁 Start Race Now",
    Description = "Manual start",
    Callback = function()
        startRace()
    end
})

Tabs.Race:AddButton({
    Title = "📍 Teleport to Start",
    Description = "Use TeleportEvent",
    Callback = function()
        for _, remote in pairs(scanData.remoteEvents) do
            if remote.Name == "TeleportEvent" then
                pcall(function()
                    remote:FireServer()
                    notify("✅ Teleported", "", 2)
                end)
                return
            end
        end
        notify("❌ Not Found", "TeleportEvent not detected", 3)
    end
})

-- ═══════════════════════════════════════
-- 📊 INFO TAB
-- ═══════════════════════════════════════

Tabs.Info:AddParagraph({
    Title = "📊 Scan Results",
    Content = "Data from last scan"
})

Tabs.Info:AddButton({
    Title = "📡 Show Remote Stats",
    Description = "Display scan statistics",
    Callback = function()
        notify("📊 Scan Stats",
            "RemoteEvents: " .. #scanData.remoteEvents .. "\n" ..
            "Money Remotes: " .. #scanData.moneyRelated .. "\n" ..
            "Winter Remotes: " .. #scanData.winterRelated .. "\n" ..
            "Race Remotes: " .. #scanData.raceRelated, 5)
    end
})

Tabs.Info:AddParagraph({
    Title = "💡 How to Use",
    Content = "1. Go to 🔍 Scanner tab\n2. Click 'FULL GAME SCAN'\n3. Check console (F9) for results\n4. Use Winter/Race tabs\n\nThe scanner will find ALL game systems!"
})

Tabs.Info:AddParagraph({
    Title = "👤 Created by: Gael Fonzar",
    Content = "Version: 2.0 - Full Scanner\nGame: Car Zone\nStatus: ✅ Loaded"
})

-- ═══════════════════════════════════════
-- 🚀 STARTUP
-- ═══════════════════════════════════════

-- Auto scan on load
task.spawn(function()
    task.wait(2)
    notify("🔍 Auto-Scanning", "Scanning game systems...", 3)
    scanForRemotes()
    task.wait(1)
    scanWorkspaceForCollectibles()
end)

notify("🔍 GF SCANNER Loaded", "Press RightShift to open\nAuto-scan starting...", 5)

print("════════════════════════════════")
print("🔍 GF HUB - CAR ZONE SCANNER v2.0")
print("Created by: Gael Fonzar")
print("Full game detection system")
print("════════════════════════════════")
