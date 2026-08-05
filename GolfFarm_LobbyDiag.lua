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

local function findRemote(name)
    local found = {}
    for _, full in ipairs(findAllRemotes()) do
        if full:match("[^%.]*$") == name then
            table.insert(found, full)
        end
    end
    return found
end

local function dumpAttributes()
    local t = {}
    for name, value in pairs(player:GetAttributes()) do
        table.insert(t, name .. " = " .. tostring(value))
    end
    table.sort(t)
    return t
end

log("== ATRIBUTOS ACTUALES ==")
for _, line in ipairs(dumpAttributes()) do
    log(line)
end

local MONITOR = {
    "Money", "WheelSpinsRemaining", "GP_VIP", "GP_TriplePets", "GP_SuperLucky",
    "GP_UnlimitedAbilities", "GP_TripleValue", "GP_Capacity50", "GP_InfiniteBackpack",
    "GP_RoboVacuumForever", "GP_PremiumNets", "BagCapacity", "BallValue",
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

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 270, 0, 330)
frame.Position = UDim2.new(0, 15, 0.35, 0)
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
title.Text = "LOBBY DIAG v2"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 24)
status.Position = UDim2.new(0, 10, 0, 302)
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
    local found = findRemote(name)
    if #found == 0 then
        log(name .. " NO ENCONTRADO (ningun remote con ese nombre)")
        return
    end
    local args = { ... }
    local desc = {}
    for i, v in ipairs(args) do
        desc[i] = type(v) == "table" and "tabla" or tostring(v)
    end
    for _, full in ipairs(found) do
        log("> fire " .. full .. "(" .. table.concat(desc, ", ") .. ")")
        local target = game:GetService("ReplicatedStorage")
        for part in full:gmatch("[^%.]+") do
            local nextTarget = target:FindFirstChild(part)
            if not nextTarget then
                target = nil
                break
            end
            target = nextTarget
        end
        if target then
            pcall(function()
                target:FireServer(unpack(args))
            end)
        end
    end
    status.Text = "Hecho: " .. name .. ". Espera 5s y mira el log."
end

local btnDump = makeButton("DUMP REMOTES", 40)
btnDump.MouseButton1Click:Connect(function()
    log("== TODOS LOS REMOTES ==")
    for _, full in ipairs(findAllRemotes()) do
        log(full)
    end
    status.Text = "Remotes escritos al log."
end)

local btnSpins = makeButton("TIENDAS 999 (Spins)", 74)
btnSpins.MouseButton1Click:Connect(function()
    player:SetAttribute("WheelSpinsRemaining", 999)
    log("> SetAttribute WheelSpinsRemaining = 999")
    status.Text = "Spins puestos en 999. Abre la ruleta."
end)

local btnMoney = makeButton("ADMIN DINERO", 108)
btnMoney.MouseButton1Click:Connect(function()
    fired("AdminGiveMoney", 100000)
    task.wait(0.5)
    fired("AdminGiveMoney", player, 100000)
end)

local btnGP = makeButton("GAMEPASSES TRUE (todos)", 142)
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

local btnPurchase = makeButton("FIRE PURCHASE GP", 176)
btnPurchase.MouseButton1Click:Connect(function()
    fired("PurchaseGamepassVfx", 0)
    task.wait(0.5)
    fired("PurchaseGamepassVfx", "VIP")
end)

local btnAd = makeButton("FIRE AD REWARD", 210)
btnAd.MouseButton1Click:Connect(function()
    fired("RewardedAdEvent", true)
end)

local btnReset = makeButton("RESET TODO", 244)
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

log("== LOBBY DIAG v2 LISTO ==")
