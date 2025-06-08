local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Kahan Hub",
    SubTitle = "Hi its my 1 script",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Combat = Window:AddTab({ Title = "Combat", Icon = "sword" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local attackRemote = ReplicatedStorage:WaitForChild("jdskhfsIIIllliiIIIdchgdIiIIIlIlIli")
local dummiesFolder = workspace:WaitForChild("MAP"):WaitForChild("dummies")

local running, attackRunning, bossAttackRunning, killAuraEnabled, autoFarmKillsEnabled = false, false, false, false, false
local coinDelay, attackDelay, bossAttackDelay, killAuraDelay = 1, 0.1, 1, 0.2
local currentTarget, hasTeleported = nil, false
local normalWalkSpeed = 16

local bosses = {
    "ROCKY", "Griffin", "BOOSBEAR", "BOSSDEER",
    "CENTAUR", "CRABBOSS", "DragonGiraffe", "LavaGorilla"
}

local function getCharacterAndRoot()
    local character = player.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        return character, rootPart
    end
    return nil, nil
end

local function getNearestEnemy()
    local closest, shortestDist = nil, math.huge
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local char = otherPlayer.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                if dist < 30 and dist < shortestDist then
                    shortestDist = dist
                    closest = otherPlayer
                end
            end
        end
    end
    return closest
end

local function collectCoins()
    while running do
        local coinContainer = workspace:FindFirstChild("CoinContainer")
        local coinEvent = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("CoinEvent")
        if coinContainer and coinEvent then
            for _, template in pairs(coinContainer:GetChildren()) do
                local coin = template:FindFirstChild("Coin")
                if coin and (coin:IsA("Part") or coin:IsA("MeshPart")) then
                    coinEvent:FireServer()
                    task.wait(coinDelay)
                end
            end
        end
        task.wait(1)
    end
end

local function findFirstAliveDummy()
    for _, dummy in ipairs(dummiesFolder:GetChildren()) do
        if dummy.Name == "Dummy" and dummy:FindFirstChild("Humanoid") and dummy.Humanoid.Health > 0 then
            return dummy
        end
    end
    return nil
end

local function attackDummies()
    hasTeleported = false
    currentTarget = nil
    while attackRunning do
        local character, rootPart = getCharacterAndRoot()
        if not character or not rootPart then
            player.CharacterAdded:Wait()
            character, rootPart = getCharacterAndRoot()
        end
        if currentTarget and currentTarget.Parent and currentTarget:FindFirstChild("Humanoid") and currentTarget.Humanoid.Health > 0 then
            if rootPart then
                attackRemote:FireServer(currentTarget.Humanoid, 6)
                task.wait(attackDelay)
            end
        else
            local dummy = findFirstAliveDummy()
            if dummy then
                currentTarget = dummy
                if not hasTeleported and rootPart then
                    local dummyRoot = dummy:FindFirstChild("HumanoidRootPart") or dummy.PrimaryPart
                    if dummyRoot then
                        rootPart.CFrame = dummyRoot.CFrame * CFrame.new(0, 0, 3)
                        hasTeleported = true
                        task.wait(attackDelay)
                    end
                end
            else
                task.wait(2)
            end
        end
    end
end

local function attackAllBosses()
    while bossAttackRunning do
        for _, bossName in ipairs(bosses) do
            local boss = workspace:FindFirstChild("NPC") and workspace.NPC:FindFirstChild(bossName)
            if boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
                coroutine.wrap(function()
                    while bossAttackRunning and boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 do
                        attackRemote:FireServer(boss.Humanoid, 5)
                        task.wait(bossAttackDelay)
                    end
                end)()
            end
        end
        task.wait(1)
    end
end

local function killAura()
    while killAuraEnabled do
        local character, root = getCharacterAndRoot()
        if not character or not root then
            player.CharacterAdded:Wait()
            character, root = getCharacterAndRoot()
        end
        local enemy = getNearestEnemy()
        if enemy and enemy.Character then
            local humanoid = enemy.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                attackRemote:FireServer(humanoid, 1)
            end
        end
        task.wait(killAuraDelay)
    end
end

local function getAlivePlayers()
    local alivePlayers = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            table.insert(alivePlayers, p)
        end
    end
    return alivePlayers
end

local function autoFarmKills()
    player.CharacterAdded:Connect(function(char)
        local humanoid = char:WaitForChild("Humanoid")
        humanoid.Died:Wait()
        killAuraEnabled = false
    end)
    while autoFarmKillsEnabled do
        local myChar, myRoot = getCharacterAndRoot()
        if not myChar or not myRoot or myChar:FindFirstChild("Humanoid") == nil or myChar.Humanoid.Health <= 0 then
            player.CharacterAdded:Wait()
            task.wait(1)
        else
            local alivePlayers = getAlivePlayers()
            if #alivePlayers == 0 then
                task.wait(2)
            else
                for _, targetPlayer in pairs(alivePlayers) do
                    if not autoFarmKillsEnabled then break end
                    local targetChar = targetPlayer.Character
                    local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                    local targetHum = targetChar and targetChar:FindFirstChild("Humanoid")
                    if targetHRP and targetHum and targetHum.Health > 0 then
                        myRoot.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
                        killAuraEnabled = true
                        coroutine.wrap(killAura)()
                        task.wait(1.5)
                    end
                end
            end
        end
        task.wait(0.5)
    end
    killAuraEnabled = false
end

player.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid")
    humanoid.WalkSpeed = attackRunning and 0 or normalWalkSpeed
end)

player.CharacterRemoving:Connect(function()
    currentTarget = nil
end)

local CoinToggle = Tabs.Combat:AddToggle("CoinToggle", {Title = "Auto Farm Coin", Default = false})
CoinToggle:OnChanged(function(Value)
    running = Value
    if Value then coroutine.wrap(collectCoins)() end
end)

local DummyToggle = Tabs.Combat:AddToggle("DummyToggle", {Title = "Auto Farm Dummy", Default = false})
DummyToggle:OnChanged(function(Value)
    attackRunning = Value
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then humanoid.WalkSpeed = Value and 0 or normalWalkSpeed end
    if Value then coroutine.wrap(attackDummies)() end
end)

local BossToggle = Tabs.Combat:AddToggle("BossToggle", {Title = "Bosses Auto Farm", Default = false})
BossToggle:OnChanged(function(Value)
    bossAttackRunning = Value
    if Value then coroutine.wrap(attackAllBosses)() end
end)

local KillAuraToggle = Tabs.Combat:AddToggle("KillAuraToggle", {Title = "Kill Aura", Default = false})
KillAuraToggle:OnChanged(function(Value)
    killAuraEnabled = Value
    if Value then coroutine.wrap(killAura)() end
end)

local AutoFarmKillsToggle = Tabs.Combat:AddToggle("AutoFarmKillsToggle", {Title = "Auto Farm Kills", Default = false})
AutoFarmKillsToggle:OnChanged(function(Value)
    autoFarmKillsEnabled = Value
    if Value then coroutine.wrap(autoFarmKills)() end
end)
