local Players = game:GetService("Players")
print("[GolfFarm] Iniciando...")

local player
for i = 1, 20 do
    player = Players.LocalPlayer
    if player then break end
    task.wait(0.5)
end
if not player then
    print("[GolfFarm] ERROR: LocalPlayer nil")
    return
end

local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then
    print("[GolfFarm] ERROR: PlayerGui nil")
    return
end

local config = {
    AutoFarm = true,
    TeleportMode = true,
    AutoSell = true,
    SellOnlyWhenFull = true,
    AutoUpgrade = true,
    GrabAll = true,
}

local balls = nil
local remotes = nil
local networker = nil
local found = false
local lastSell = -math.huge

local function findBallsFolder()
    local names = { "ActiveGolfBalls2", "ActiveGolfBalls", "GolfBalls", "Balls" }
    for _, n in ipairs(names) do
        local direct = workspace:FindFirstChild(n)
        if direct then return direct end
    end
    for _, v in ipairs(workspace:GetChildren()) do
        if v:IsA("Folder") and v.Name:lower():find("ball") and #v:GetChildren() > 50 then
            return v
        end
    end
    return nil
end

local function findRemotesFolder()
    local rs = game:GetService("ReplicatedStorage")
    local names = { "RemotesNew", "Remotes", "RemoteEvents" }
    for _, n in ipairs(names) do
        local direct = rs:FindFirstChild(n)
        if direct then return direct end
    end
    for _, v in ipairs(rs:GetChildren()) do
        if v:IsA("Folder") and v.Name:lower():find("remote") then
            return v
        end
    end
    return nil
end

local function findNetworker()
    local rs = game:GetService("ReplicatedStorage")
    local modules = rs:FindFirstChild("Modules")
    local packageRoot = modules and modules:FindFirstChild("rwque")
    local packages = packageRoot and packageRoot:FindFirstChild("Packages")
    local module = packages and packages:FindFirstChild("Networker")
    if module then
        local ok, inst = pcall(require, module)
        if ok and inst then
            local ok2, nw = pcall(function()
                return inst.new()
            end)
            if ok2 and nw then return nw end
        end
    end
    return nil
end

local function locateGame()
    task.spawn(function()
        while true do
            if not balls then balls = findBallsFolder() end
            if not remotes then remotes = findRemotesFolder() end
            if not networker then networker = findNetworker() end
            if balls and remotes then
                found = true
                return
            end
            task.wait(2)
        end
    end)
end

local function fire(name, arg)
    if networker then
        return pcall(function()
            if arg ~= nil then
                networker:FireServer(name, arg)
            else
                networker:FireServer(name)
            end
        end)
    end
    local r = remotes and remotes:FindFirstChild(name)
    if not r then return false end
    return pcall(function()
        if arg ~= nil then
            r:FireServer(arg)
        else
            r:FireServer()
        end
    end)
end

local function attr(name, default)
    local v = player:GetAttribute(name)
    if v == nil then return default end
    return v
end

local function bagCapacity()
    return math.max(1, math.floor(attr("BagCapacity", 10)))
end

local function bagCount()
    return math.floor(attr("BagCount", 0))
end

local function collectBatch(origin, radius, maxCount)
    local batch = {}
    for _, ball in ipairs(balls:GetChildren()) do
        if ball:IsA("BasePart") and (ball.Position - origin).Magnitude <= radius then
            table.insert(batch, ball)
            if #batch >= maxCount then break end
        end
    end
    return batch
end

local function nextTarget(origin)
    local best, bestDist = nil, math.huge
    for _, ball in ipairs(balls:GetChildren()) do
        if ball:IsA("BasePart") then
            local d = (ball.Position - origin).Magnitude
            if d < bestDist then
                best, bestDist = ball, d
            end
        end
    end
    return best
end

local function collectAllChunks(chunkSize)
    local collected = 0
    local chunk = {}
    for _, ball in ipairs(balls:GetChildren()) do
        if ball:IsA("BasePart") then
            table.insert(chunk, ball)
            collected = collected + 1
            if #chunk >= chunkSize then
                fire("Collect", chunk)
                chunk = {}
                task.wait(0.05)
            end
        end
    end
    if #chunk > 0 then
        fire("Collect", chunk)
    end
    return collected
end

local function clusterBalls(cellSize)
    local map = {}
    local order = {}
    for _, ball in ipairs(balls:GetChildren()) do
        if ball:IsA("BasePart") then
            local cx = math.floor(ball.Position.X / cellSize)
            local cz = math.floor(ball.Position.Z / cellSize)
            local key = cx .. "," .. cz
            local c = map[key]
            if not c then
                c = {}
                map[key] = c
                table.insert(order, c)
            end
            table.insert(c, ball)
        end
    end
    return order
end

local function grabAllPass(root)
    local clusters = clusterBalls(40)
    local total = 0
    for _, cluster in ipairs(clusters) do
        local sum = Vector3.zero
        for _, b in ipairs(cluster) do
            sum = sum + b.Position
        end
        local center = sum / #cluster
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = CFrame.new(center + Vector3.new(0, 3, 0))
        end)
        task.wait(0.04)
        local cap = bagCapacity()
        local batch = {}
        for _, b in ipairs(cluster) do
            table.insert(batch, b)
            if #batch >= cap then
                fire("Collect", batch)
                batch = {}
                task.wait(0.04)
                if config.AutoSell and bagCount() >= cap then
                    sellBag()
                    task.wait(0.15)
                end
            end
        end
        if #batch > 0 then
            fire("Collect", batch)
        end
        total = total + #cluster
        if config.AutoSell and bagCount() >= bagCapacity() then
            sellBag()
            task.wait(0.15)
        end
    end
    return total
end

local function sellBag()
    if os.clock() - lastSell < 0.25 then return end
    local ok = fire("FillNet")
    if ok then lastSell = os.clock() end
end

local function farmLoop()
    while config.AutoFarm do
        if not found then
            status.Text = "Falta: " .. (balls and "remotes" or "pelotas")
            task.wait(1)
        else
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then
                task.wait(1)
            elseif config.GrabAll then
                local n = grabAllPass(root)
                status.Text = "GRAB ALL: " .. n .. " pelotas barridas"
                if config.AutoSell then
                    sellBag()
                    task.wait(0.3)
                    sellBag()
                end
                task.wait(0.5)
            else
                local cooldown = math.max(0.05, attr("CollectCooldown", 0.5))
                local radius = attr("CollectionRange", 20)
                if config.AutoSell and bagCount() >= bagCapacity() then
                    sellBag()
                    task.wait(cooldown)
                else
                    if config.TeleportMode then
                        local target = nextTarget(root.Position)
                        if target then
                            pcall(function()
                                root.AssemblyLinearVelocity = Vector3.zero
                                root.AssemblyAngularVelocity = Vector3.zero
                                root.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
                            end)
                            task.wait(0.05)
                        end
                    end
                    local batch = collectBatch(root.Position, math.max(radius, 40), bagCapacity())
                    if #batch > 0 then
                        fire("Collect", batch)
                        if config.AutoSell and not config.SellOnlyWhenFull then
                            sellBag()
                        end
                    end
                    task.wait(cooldown)
                end
            end
        end
    end
end

local function upgradeLoop()
    while config.AutoUpgrade do
        fire("BuyAllShop")
        task.wait(0.5)
    end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GolfFarm"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 215)
frame.Position = UDim2.new(0, 15, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
title.Text = "GOLF YARD FARM"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.Parent = frame

local drag = { dragging = false, offset = Vector2.new() }
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        drag.dragging = true
        drag.offset = input.Position - Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)
    end
end)
title.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        drag.dragging = false
    end
end)
frame.InputChanged:Connect(function(input)
    if drag.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        frame.Position = UDim2.new(0, input.Position.X - drag.offset.X, 0, input.Position.Y - drag.offset.Y)
    end
end)

local function makeButton(text, posY, fontSize)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = fontSize or 13
    btn.Font = Enum.Font.GothamBold
    btn.Parent = frame
    return btn
end

local farmBtn = makeButton("FARM: OFF  [F]", 34)
local grabBtn = makeButton("GRAB ALL: OFF  [H]", 68)
local sellBtn = makeButton("AUTO SELL: OFF  [S]", 102, 12)
local upgradeBtn = makeButton("UPGRADES: OFF  [U]", 136, 12)
local tpBtn = makeButton("TELEPORT: ON  [T]", 170, 12)

local sellModeBtn = makeButton("Vender solo lleno: SI", 204, 11)
sellModeBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 105)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.new(0, 10, 0, 240)
status.BackgroundTransparency = 1
status.Text = "Listo. F = farm, H = grab all."
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextSize = 11
status.Font = Enum.Font.Gotham
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

frame.Size = UDim2.new(0, 250, 0, 265)

local function toggleFarm()
    config.AutoFarm = not config.AutoFarm
    farmBtn.BackgroundColor3 = config.AutoFarm and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(200, 60, 60)
    farmBtn.Text = config.AutoFarm and "FARM: ON  [F]" or "FARM: OFF  [F]"
    if config.AutoFarm then
        task.spawn(farmLoop)
    end
end

local function toggleGrabAll()
    config.GrabAll = not config.GrabAll
    grabBtn.BackgroundColor3 = config.GrabAll and Color3.fromRGB(200, 150, 40) or Color3.fromRGB(70, 70, 85)
    grabBtn.Text = config.GrabAll and "GRAB ALL: ON  [H]" or "GRAB ALL: OFF  [H]"
end

local function toggleSell()
    config.AutoSell = not config.AutoSell
    sellBtn.BackgroundColor3 = config.AutoSell and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(70, 70, 85)
    sellBtn.Text = config.AutoSell and "AUTO SELL: ON  [S]" or "AUTO SELL: OFF  [S]"
end

local function toggleUpgrade()
    config.AutoUpgrade = not config.AutoUpgrade
    upgradeBtn.BackgroundColor3 = config.AutoUpgrade and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(70, 70, 85)
    upgradeBtn.Text = config.AutoUpgrade and "UPGRADES: ON  [U]" or "UPGRADES: OFF  [U]"
    if config.AutoUpgrade then
        task.spawn(upgradeLoop)
    end
end

local function toggleTeleport()
    config.TeleportMode = not config.TeleportMode
    tpBtn.BackgroundColor3 = config.TeleportMode and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(120, 70, 70)
    tpBtn.Text = config.TeleportMode and "TELEPORT: ON  [T]" or "TELEPORT: OFF  [T]"
end

local function toggleSellMode()
    config.SellOnlyWhenFull = not config.SellOnlyWhenFull
    sellModeBtn.Text = config.SellOnlyWhenFull and "Vender solo lleno: SI" or "Vender solo lleno: NO"
end

farmBtn.MouseButton1Click:Connect(toggleFarm)
grabBtn.MouseButton1Click:Connect(toggleGrabAll)
sellBtn.MouseButton1Click:Connect(toggleSell)
upgradeBtn.MouseButton1Click:Connect(toggleUpgrade)
tpBtn.MouseButton1Click:Connect(toggleTeleport)
sellModeBtn.MouseButton1Click:Connect(toggleSellMode)

local inputService = game:GetService("UserInputService")
inputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then toggleFarm() end
    if input.KeyCode == Enum.KeyCode.H then toggleGrabAll() end
    if input.KeyCode == Enum.KeyCode.S then toggleSell() end
    if input.KeyCode == Enum.KeyCode.U then toggleUpgrade() end
    if input.KeyCode == Enum.KeyCode.T then toggleTeleport() end
end)

task.spawn(function()
    while true do
        if found then
            local mode = config.GrabAll and "GRAB ALL" or (config.AutoFarm and "FARM" or "OFF")
            status.Text = string.format("Bolsa: %s/%s  Rango: %s  [%s]",
                tostring(bagCount()),
                tostring(bagCapacity()),
                tostring(attr("CollectionRange", "?")),
                mode)
        else
            status.Text = "Falta: " .. (balls and "remotes" or (remotes and "pelotas" or "pelotas+remotes"))
        end
        task.wait(0.25)
    end
end)

locateGame()

farmBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
farmBtn.Text = "FARM: ON  [F]"
grabBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 40)
grabBtn.Text = "GRAB ALL: ON  [H]"
sellBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
sellBtn.Text = "AUTO SELL: ON  [S]"
upgradeBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
upgradeBtn.Text = "UPGRADES: ON  [U]"

task.spawn(farmLoop)
task.spawn(upgradeLoop)
print("[GolfFarm] Modo automatico: TODO activo sin botones. F=farm, H=grab all, S=venta, U=mejoras")
