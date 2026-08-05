local logLines = {}
local function log(s)
    table.insert(logLines, tostring(s))
    print("[LobbyDiag] " .. tostring(s))
    writefile("golffarm_lobby_diag.txt", table.concat(logLines, "\n"))
end

local player = game.Players.LocalPlayer

local function findAllRemotes()
    local list = {}
    local function rec(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                table.insert(list, child:GetFullName())
            end
            rec(child)
        end
    end
    rec(game.ReplicatedStorage)
    return list
end

local function getRemote(name)
    for _, full in ipairs(findAllRemotes()) do
        if full:match("[^%.]*$") == name then
            local parts = {}
            for part in full:gmatch("[^%.]+") do
                table.insert(parts, part)
            end
            local target = game
            local ok = true
            for i = 2, #parts do
                local nextTarget = target:FindFirstChild(parts[i])
                if not nextTarget then
                    ok = false
                    break
                end
                target = nextTarget
            end
            if ok then
                return target
            end
        end
    end
    return nil
end

local MONITOR = {
    "Money", "Fragments", "BasicSpins", "GoldSpins", "LuckySpins",
    "WheelSpinsRemaining", "NextWheelSpinAt", "BasicPity", "GoldPity", "LuckyPity",
    "GP_VIP", "GP_TriplePets", "GP_UnlimitedAbilities", "GP_TripleValue",
    "EquippedPets", "AuraSlotsJson", "SelectedAuraSlot", "RobuxDonated",
    "Unlocked_SuperEasy", "Unlocked_Easy", "Unlocked_Normal", "Unlocked_Hard", "Unlocked_Extreme",
}
local baseline = {}
for _, name in ipairs(MONITOR) do
    baseline[name] = player:GetAttribute(name)
end

task.spawn(function()
    while true do
        for _, name in ipairs(MONITOR) do
            local v = player:GetAttribute(name)
            if tostring(v) ~= tostring(baseline[name]) then
                log(string.format("[CAMBIADO %s] %s: %s -> %s", os.time(), name, tostring(baseline[name]), tostring(v)))
                baseline[name] = v
            end
        end
        task.wait(0.5)
    end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LobbyDiag"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local uis = game:GetService("UserInputService")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 392)
frame.Position = UDim2.new(0, 15, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(14, 18, 26)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 14)
frameCorner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 10, 0, 6)
title.BackgroundTransparency = 1
title.Text = "LOBBY DIAG v3"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.Parent = frame

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

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 24)
status.Position = UDim2.new(0, 10, 0, 364)
status.BackgroundTransparency = 1
status.Text = "Esperando..."
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextSize = 11
status.Font = Enum.Font.Gotham
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextWrapped = true
status.Parent = frame

local function makeButton(text, posY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 28)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    btn.Parent = frame
    return btn
end

local function fired(name, ...)
    local r = getRemote(name)
    if not r then
        log(name .. " NO ENCONTRADO")
        return
    end
    local args = { ... }
    local desc = {}
    for i, v in ipairs(args) do
        desc[i] = type(v) == "table" and "tabla" or tostring(v)
    end
    log("> fire " .. name .. "(" .. table.concat(desc, ", ") .. ")")
    pcall(function()
        r:FireServer(unpack(args))
    end)
    status.Text = "Hecho: " .. name .. ". Espera 5s y mira el log + pantalla."
end

local btnSpins = makeButton("SPINS 999 + TIMER 0", 40)
btnSpins.MouseButton1Click:Connect(function()
    player:SetAttribute("BasicSpins", 999)
    player:SetAttribute("GoldSpins", 999)
    player:SetAttribute("LuckySpins", 999)
    player:SetAttribute("WheelSpinsRemaining", 999)
    player:SetAttribute("NextWheelSpinAt", 0)
    log("> Spins(999x4) + NextWheelSpinAt=0")
    status.Text = "Hecho. ABRE LA RULETA: contador y giro."
end)

local btnWheel = makeButton("FIRE RequestWheelSpin", 72)
btnWheel.MouseButton1Click:Connect(function()
    fired("RequestWheelSpin")
    task.wait(0.4)
    fired("RequestWheelSpin", 0)
    task.wait(0.4)
    fired("RequestWheelSpin", "Basic")
end)

local btnSkip = makeButton("FIRE SkipTimer", 104)
btnSkip.MouseButton1Click:Connect(function()
    fired("SkipTimer")
    task.wait(0.4)
    fired("SkipTimer", 0)
    task.wait(0.4)
    fired("SkipTimer", "Wheel")
end)

local btnDaily = makeButton("FIRE ClaimDailyReward", 136)
btnDaily.MouseButton1Click:Connect(function()
    fired("ClaimDailyReward")
    task.wait(0.4)
    fired("ClaimDailyReward", true)
end)

local btnAura = makeButton("FIRE AuraRoll", 168)
btnAura.MouseButton1Click:Connect(function()
    fired("AuraRoll")
    task.wait(0.4)
    fired("AuraRoll", 0)
    task.wait(0.4)
    fired("AuraRoll", "Lucky")
end)

local btnHatch = makeButton("FIRE HatchEgg", 200)
btnHatch.MouseButton1Click:Connect(function()
    fired("HatchEgg", 0)
    task.wait(0.4)
    fired("HatchEgg", "Basic")
end)

local btnUpgrade = makeButton("FIRE UpgradeAll", 232)
btnUpgrade.MouseButton1Click:Connect(function()
    fired("UpgradeAll")
end)

local btnDump = makeButton("DUMP REMOTES", 264)
btnDump.MouseButton1Click:Connect(function()
    log("== TODOS LOS REMOTES ==")
    for _, full in ipairs(findAllRemotes()) do
        log(full)
    end
    status.Text = "Remotes escritos al log."
end)

local btnReset = makeButton("RESET TODO", 296)
btnReset.MouseButton1Click:Connect(function()
    local n = 0
    for _, name in ipairs(MONITOR) do
        if baseline[name] ~= nil then
            player:SetAttribute(name, baseline[name])
            n = n + 1
        end
    end
    log("> RESET: " .. n .. " atributos restaurados")
    status.Text = "Todo restaurado al baseline."
end)

local btnPity = makeButton("PITY GRATIS", 328)
btnPity.MouseButton1Click:Connect(function()
    player:SetAttribute("BasicPity", 0)
    player:SetAttribute("GoldPity", 0)
    player:SetAttribute("LuckyPity", 0)
    log("> Pity reset a 0 (siguiente tirada gratis?)")
    status.Text = "Pity en 0. Tira una vez y mira."
end)

log("== LOBBY DIAG v3 LISTO ==")
