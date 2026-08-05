local logLines = {}
local function log(s)
    table.insert(logLines, tostring(s))
    print("[LobbyDiag] " .. tostring(s))
    writefile("golffarm_lobby_diag.txt", table.concat(logLines, "\n"))
end

local player = game.Players.LocalPlayer
local remotesNew = game.ReplicatedStorage:WaitForChild("RemotesNew", 10)
local function get(remoteName)
    return remotesNew:FindFirstChild(remoteName)
end

local MONITOR = {
    "Money", "WheelSpinsRemaining", "GP_VIP", "GP_TriplePets", "GP_SuperLucky",
    "GP_UnlimitedAbilities", "GP_TripleValue", "GP_Capacity50", "GP_InfiniteBackpack",
    "GP_RoboVacuumForever", "GP_PremiumNets", "GP_Checked", "BagCapacity", "BallValue",
}
local baseline = {}
for _, name in ipairs(MONITOR) do
    baseline[name] = player:GetAttribute(name)
end
log("== BASELINE ==")
for _, name in ipairs(MONITOR) do
    log(name .. " = " .. tostring(baseline[name]))
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

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 300)
frame.Position = UDim2.new(0, 15, 0.4, 0)
frame.BackgroundColor3 = Color3.fromRGB(14, 18, 26)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 14)
frameCorner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 10, 0, 6)
title.BackgroundTransparency = 1
title.Text = "LOBBY DIAG"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 24)
status.Position = UDim2.new(0, 10, 0, 272)
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
    btn.Size = UDim2.new(1, -20, 0, 30)
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
    local r = get(name)
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
    status.Text = "Hecho: " .. name .. ". Espera 5s y mira el log."
end

local btnSpins = makeButton("TIENDAS 999 (Spins)", 40)
btnSpins.MouseButton1Click:Connect(function()
    player:SetAttribute("WheelSpinsRemaining", 999)
    log("> SetAttribute WheelSpinsRemaining = 999")
    status.Text = "Spins puestos en 999. Abre la ruleta."
end)

local btnMoney = makeButton("ADMIN DINERO", 74)
btnMoney.MouseButton1Click:Connect(function()
    fired("AdminGiveMoney", 100000)
    task.wait(0.5)
    fired("AdminGiveMoney", player, 100000)
end)

local btnGP = makeButton("GAMEPASSES TRUE (todos)", 108)
btnGP.MouseButton1Click:Connect(function()
    local n = 0
    for name in pairs(player:GetAttributes()) do
        if name:sub(1, 3) == "GP_" then
            player:SetAttribute(name, true)
            n = n + 1
        end
    end
    log("> SetAttribute true en " .. n .. " gamepasses")
    status.Text = "Gamepasses puestos en true. Espera 5s."
end)

local btnPurchase = makeButton("FIRE PURCHASE GP", 142)
btnPurchase.MouseButton1Click:Connect(function()
    fired("PurchaseGamepassVfx", 0)
    task.wait(0.5)
    fired("PurchaseGamepassVfx", "VIP")
    task.wait(0.5)
    fired("PurchaseGamepassVfx", player, "VIP")
end)

local btnAd = makeButton("FIRE AD REWARD", 176)
btnAd.MouseButton1Click:Connect(function()
    fired("RewardedAdEvent", true)
end)

local btnReset = makeButton("RESET TODO", 210)
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

log("== LOBBY DIAG LISTO ==")
