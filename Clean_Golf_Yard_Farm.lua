local Players = game:GetService("Players")
local uis = game:GetService("UserInputService")
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
    AutoFarm = false,
    TeleportMode = false,
    AutoSell = false,
    SellOnlyWhenFull = true,
    AutoUpgrade = false,
    OP = false,
}

local balls = nil
local remotes = nil
local networker = nil
local found = false
local lastSell = -math.huge
local status = nil
local farming = false
local ensureFarming = nil
local logLines = {}

local function log(msg)
    table.insert(logLines, tostring(msg))
    if #logLines > 150 then
        table.remove(logLines, 1)
    end
end

local function saveLog()
    pcall(function()
        writefile("golffarm_log.txt", table.concat(logLines, "\n"))
    end)
end

task.spawn(function()
    while true do
        task.wait(3)
        saveLog()
    end
end)

local function findBallsFolder()
    local names = { "ActiveGolfBalls2", "ActiveGolfBalls", "GolfBalls", "Balls" }
    for _, n in ipairs(names) do
        local direct = workspace:FindFirstChild(n)
        if direct and #direct:GetChildren() > 0 then return direct end
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
    if not packageRoot then return nil end
    local candidates = {}
    local direct = packageRoot:FindFirstChild("Networker")
    if direct then table.insert(candidates, direct) end
    local packages = packageRoot:FindFirstChild("Packages")
    local packed = packages and packages:FindFirstChild("Networker")
    if packed then table.insert(candidates, packed) end
    for _, module in ipairs(candidates) do
        local ok, inst = pcall(require, module)
        if ok and inst then
            if type(inst) == "table" and inst.FireServer then
                return inst
            end
            local ok2, nw = pcall(function()
                return inst.new()
            end)
            if ok2 and nw and type(nw) == "table" and nw.FireServer then
                return nw
            end
        end
    end
    return nil
end

local lastRelocate = -math.huge

local function refreshGame()
    if not balls or balls.Parent == nil then balls = findBallsFolder() end
    if not remotes or remotes.Parent == nil then remotes = findRemotesFolder() end
    if not networker then networker = findNetworker() end
    if balls and remotes then found = true end
end

local function locateGame()
    task.spawn(function()
        while true do
            refreshGame()
            if balls and remotes then
                found = true
                return
            end
            task.wait(2)
        end
    end)
end

local rejectedCount = 0
task.spawn(function()
    while not found do
        task.wait(1)
    end
    pcall(function()
        local cr = remotes and remotes:FindFirstChild("CollectRejected")
        if cr then
            cr.OnClientEvent:Connect(function()
                rejectedCount = rejectedCount + 1
            end)
        end
    end)
end)

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

local function sellBag()
    if os.clock() - lastSell < 0.25 then return end
    local ok = fire("FillNet")
    if ok then lastSell = os.clock() end
end

local function sellNow()
    fire("FillNet")
end

local function ballPos(ball)
    if not ball or ball.Parent == nil then return nil end
    local ok, p = pcall(function()
        return ball.Position
    end)
    if ok and p then return p end
    return nil
end

local function allBallParts()
    if not balls or balls.Parent == nil then
        balls = findBallsFolder()
    end
    local sources = {}
    if balls then table.insert(sources, balls) end
    for _, v in ipairs(workspace:GetChildren()) do
        if v:IsA("Folder") and v.Name:lower():find("ball") and v ~= balls then
            table.insert(sources, v)
        elseif v:IsA("BasePart") then
            local n = v.Name:lower()
            if n:find("ball") and not n:find("prompt") and #v:GetChildren() == 0 then
                table.insert(sources, v)
            end
        end
    end
    local seen = {}
    local out = {}
    for _, src in ipairs(sources) do
        if src:IsA("BasePart") then
            if not seen[src] then
                seen[src] = true
                table.insert(out, src)
            end
        else
            for _, b in ipairs(src:GetChildren()) do
                if b:IsA("BasePart") and not seen[b] then
                    seen[b] = true
                    table.insert(out, b)
                end
            end
        end
    end
    return out
end

local ballCache = nil
local ballCacheTime = -math.huge
local posCache = {}

local function getBalls()
    if os.clock() - ballCacheTime > 1.5 then
        local fresh = allBallParts()
        ballCache = fresh
        local seen = {}
        for _, b in ipairs(fresh) do seen[b] = true end
        for b in pairs(posCache) do
            if not seen[b] then posCache[b] = nil end
        end
        ballCacheTime = os.clock()
    end
    return ballCache
end

local function cachedPos(ball)
    if not ball or ball.Parent == nil then return nil end
    local p = posCache[ball]
    if p then return p end
    local ok, pp = pcall(function()
        return ball.Position
    end)
    if ok and pp then
        posCache[ball] = pp
        return pp
    end
    return nil
end
local function collectNearby(root, radius)
    if not root then return 0 end
    local okOrigin, origin = pcall(function()
        return root.Position
    end)
    if not okOrigin or not origin then return 0 end
    local ballsList = getBalls()
    local items = {}
    for _, ball in ipairs(ballsList) do
        local p = cachedPos(ball)
        if p then
            local d = (p - origin).Magnitude
            if d <= radius then
                table.insert(items, {
                    b = ball,
                    d = d,
                })
            end
        end
    end
    table.sort(items, function(a, b)
        return a.d < b.d
    end)
    local chunkSize = math.max(1, bagCapacity())
    local chunk = {}
    local sent = 0
    for _, item in ipairs(items) do
        table.insert(chunk, item.b)
        if #chunk >= chunkSize then
            fire("Collect", chunk)
            sent = sent + #chunk
            chunk = {}
        end
    end
    if #chunk > 0 then
        fire("Collect", chunk)
        sent = sent + #chunk
    end
    return sent
end

local function opGrab(root)
    local radius = math.max(attr("CollectionRange", 16) + 10, 26)
    local t0 = os.clock()
    local total = 0
    local lastBag = bagCount()
    local lastBagTime = os.clock()
    local lastReload = -math.huge
    local startRejected = rejectedCount
    while os.clock() - t0 < 5 do
        local n = collectNearby(root, radius)
        total = total + n
        if config.AutoSell and bagCount() >= bagCapacity() then
            sellNow()
        end
        if bagCount() > lastBag then
            lastBag = bagCount()
            lastBagTime = os.clock()
        end
        if os.clock() - lastBagTime > 2 then
            if os.clock() - lastReload > 10 then
                fire("ReloadBalls")
                lastReload = os.clock()
                log("OP: sin ganancias 2s, ReloadBalls intentado")
            end
            task.wait(0.8)
        elseif n == 0 then
            task.wait(0.6)
        else
            task.wait(0.1)
        end
    end
    local rej = rejectedCount - startRejected
    if rej > 0 then
        log("OP ciclo: rechazos=" .. rej)
    end
    return total
end

local function collectBatch(origin, radius, maxCount)
    local batch = {}
    for _, ball in ipairs(allBallParts()) do
        local p = ballPos(ball)
        if p and (p - origin).Magnitude <= radius then
            table.insert(batch, ball)
            if #batch >= maxCount then break end
        end
    end
    return batch
end

local function nextTarget(origin)
    local best, bestDist = nil, math.huge
    for _, ball in ipairs(allBallParts()) do
        local p = ballPos(ball)
        if p then
            local d = (p - origin).Magnitude
            if d < bestDist then
                best, bestDist = ball, d
            end
        end
    end
    return best
end

local function farmStep()
    local bagInfo = bagCount() .. "/" .. bagCapacity()
    local mode = config.OP and "OP" or "FARM"
    if not found then
        status.Text = "Falta: " .. (balls and "remotes" or "pelotas")
        log(mode .. " esperando estructura (bola=" .. tostring(balls and balls.Name) .. " remotes=" .. tostring(remotes and remotes.Name) .. ")")
        task.wait(1)
        return
    end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then
        log(mode .. " sin character/root, esperando respawn")
        task.wait(1)
        return
    end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if config.OP then
        local n = opGrab(root)
        status.Text = "OP roto: +" .. n .. " bolas"
        log("OP roto +" .. n .. " bolsa=" .. bagInfo)
    else
        if os.clock() - lastRelocate > 30 then
            refreshGame()
            lastRelocate = os.clock()
        end
        local cooldown = math.max(0.05, attr("CollectCooldown", 0.5))
        local radius = attr("CollectionRange", 20)
        if config.AutoSell and bagCount() >= bagCapacity() then
            sellBag()
            task.wait(cooldown)
            return
        end
        if config.TeleportMode then
            local target = nextTarget(root.Position)
            if target then
                pcall(function()
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    root.CFrame = CFrame.new(target.Position + Vector3.new(0, 5, 0))
                end)
                task.wait(0.1)
            end
        end
        local batch = collectBatch(root.Position, math.max(radius, 40), bagCapacity())
        if #batch > 0 then
            local ok = fire("Collect", batch)
            if not ok then
                refreshGame()
                task.wait(2)
            end
            if config.AutoSell and not config.SellOnlyWhenFull then
                sellBag()
            end
            log("FARM recolecto " .. #batch .. " bolsa=" .. bagInfo)
        end
        task.wait(cooldown)
    end
end

local function farmLoop()
    farming = true
    while config.AutoFarm or config.OP do
        local ok, err = pcall(farmStep)
        if not ok then
            status.Text = "Error leve: " .. tostring(err):sub(1, 35)
            log("ERROR en farmStep: " .. tostring(err))
            saveLog()
            task.wait(1)
        end
    end
    farming = false
    log("farmLoop termino")
    saveLog()
end

task.spawn(function()
    while true do
        task.wait(2)
        if (config.AutoFarm or config.OP) and not farming then
            log("watchdog: farm detenido, reiniciando")
            saveLog()
            ensureFarming()
        end
    end
end)

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
frame.Size = UDim2.new(0, 280, 0, 312)
frame.Position = UDim2.new(0, 15, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(14, 18, 26)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local frameGrad = Instance.new("UIGradient")
frameGrad.Color = ColorSequence.new(
    Color3.fromRGB(16, 26, 42),
    Color3.fromRGB(12, 44, 32),
    Color3.fromRGB(30, 18, 44)
)
frameGrad.Rotation = 30
frameGrad.Parent = frame

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 16)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(70, 220, 140)
frameStroke.Thickness = 1
frameStroke.Transparency = 0.45
frameStroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0, 36)
title.Position = UDim2.new(0, 12, 0, 8)
title.BackgroundTransparency = 1
title.Text = "GOLF YARD FARM"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 19
title.Font = Enum.Font.GothamBold
title.Parent = frame

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new(
    Color3.fromRGB(130, 255, 185),
    Color3.fromRGB(95, 190, 255),
    Color3.fromRGB(255, 120, 220)
)
titleGrad.Rotation = 90
titleGrad.Parent = title

task.spawn(function()
    local start = os.clock()
    while true do
        local t = (os.clock() - start) * 10
        frameGrad.Rotation = (t * 6) % 360
        titleGrad.Rotation = 90 + (t * 9) % 360
        task.wait(0.05)
    end
end)

local dragging = false
local dragOffset = Vector2.new()
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragOffset = Vector2.new(input.Position.X, input.Position.Y) - Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)
    end
end)
uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
uis.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        frame.Position = UDim2.new(0, input.Position.X - dragOffset.X, 0, input.Position.Y - dragOffset.Y)
    end
end)

local function makeButton(text, posY, fontSize)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -24, 0, 30)
    btn.Position = UDim2.new(0, 12, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = fontSize or 13
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 9)
    btnCorner.Parent = btn
    btn.MouseEnter:Connect(function()
        btn.BackgroundTransparency = 0.2
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundTransparency = 0
    end)
    btn.Parent = frame
    return btn
end

local farmBtn = makeButton("FARM: OFF", 52)
local opBtn = makeButton("OP MODE: OFF", 86)
local sellBtn = makeButton("AUTO SELL: OFF", 120, 12)
local upgradeBtn = makeButton("UPGRADES: OFF", 154, 12)
local tpBtn = makeButton("TELEPORT: OFF", 188, 12)

local sellModeBtn = makeButton("Vender solo lleno: SI", 222, 11)
sellModeBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 105)

local dot = Instance.new("TextLabel")
dot.Size = UDim2.new(0, 16, 0, 16)
dot.Position = UDim2.new(0, 14, 0, 260)
dot.BackgroundTransparency = 1
dot.Text = "●"
dot.TextColor3 = Color3.fromRGB(90, 90, 90)
dot.TextSize = 14
dot.Font = Enum.Font.GothamBold
dot.Parent = frame

status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -40, 0, 20)
status.Position = UDim2.new(0, 34, 0, 258)
status.BackgroundTransparency = 1
status.Text = "Todo desactivado. Activa con clic."
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextSize = 11
status.Font = Enum.Font.Gotham
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local function setModeButtons()
    farmBtn.BackgroundColor3 = config.AutoFarm and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(200, 60, 60)
    farmBtn.Text = config.AutoFarm and "FARM: ON" or "FARM: OFF"
    opBtn.BackgroundColor3 = config.OP and Color3.fromRGB(220, 60, 220) or Color3.fromRGB(70, 70, 85)
    opBtn.Text = config.OP and "OP MODE: ON" or "OP MODE: OFF"
end

ensureFarming = function()
    if not farming then
        task.spawn(farmLoop)
    end
end

local function toggleFarm()
    if config.AutoFarm then
        config.AutoFarm = false
        log("FARM OFF")
    else
        config.AutoFarm = true
        config.OP = false
        log("FARM ON")
    end
    setModeButtons()
    if config.AutoFarm then
        ensureFarming()
    end
end

local function toggleOP()
    if config.OP then
        config.OP = false
        log("OP OFF")
    else
        config.OP = true
        config.AutoFarm = false
        config.AutoSell = true
        sellBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
        sellBtn.Text = "AUTO SELL: ON"
        log("OP ON")
    end
    setModeButtons()
    if config.OP then
        ensureFarming()
    end
end

local function toggleSell()
    config.AutoSell = not config.AutoSell
    sellBtn.BackgroundColor3 = config.AutoSell and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(70, 70, 85)
    sellBtn.Text = config.AutoSell and "AUTO SELL: ON" or "AUTO SELL: OFF"
end

local function toggleUpgrade()
    config.AutoUpgrade = not config.AutoUpgrade
    upgradeBtn.BackgroundColor3 = config.AutoUpgrade and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(70, 70, 85)
    upgradeBtn.Text = config.AutoUpgrade and "UPGRADES: ON" or "UPGRADES: OFF"
    if config.AutoUpgrade then
        task.spawn(upgradeLoop)
    end
end

local function toggleTeleport()
    config.TeleportMode = not config.TeleportMode
    tpBtn.BackgroundColor3 = config.TeleportMode and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(120, 70, 70)
    tpBtn.Text = config.TeleportMode and "TELEPORT: ON" or "TELEPORT: OFF"
end

local function toggleSellMode()
    config.SellOnlyWhenFull = not config.SellOnlyWhenFull
    sellModeBtn.Text = config.SellOnlyWhenFull and "Vender solo lleno: SI" or "Vender solo lleno: NO"
end

farmBtn.MouseButton1Click:Connect(toggleFarm)
opBtn.MouseButton1Click:Connect(toggleOP)
sellBtn.MouseButton1Click:Connect(toggleSell)
upgradeBtn.MouseButton1Click:Connect(toggleUpgrade)
tpBtn.MouseButton1Click:Connect(toggleTeleport)
sellModeBtn.MouseButton1Click:Connect(toggleSellMode)

task.spawn(function()
    while true do
        if found then
            local mode = config.OP and "OP" or (config.AutoFarm and "FARM" or "OFF")
            dot.TextColor3 = (config.OP or config.AutoFarm) and Color3.fromRGB(80, 255, 120)
                or Color3.fromRGB(90, 90, 90)
            status.Text = string.format("Bolsa: %s/%s  Rango: %s  [%s]",
                tostring(bagCount()),
                tostring(bagCapacity()),
                tostring(attr("CollectionRange", "?")),
                mode)
        else
            dot.TextColor3 = Color3.fromRGB(255, 90, 90)
            status.Text = "Falta: " .. (balls and "remotes" or (remotes and "pelotas" or "pelotas+remotes"))
        end
        task.wait(0.25)
    end
end)

locateGame()
log("Script listo, todo desactivado")
saveLog()
print("[GolfFarm] Script listo. Todo desactivado: activa con los botones (clic).")
