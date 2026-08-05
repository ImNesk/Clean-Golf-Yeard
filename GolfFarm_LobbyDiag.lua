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
            local target = game.ReplicatedStorage
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
    "PetSpace", "PetBagCapacity", "Upgrade_PetEquip", "Unlocked_SuperEasy",
    "Unlocked_Easy", "Unlocked_Normal", "Unlocked_Hard", "Unlocked_Extreme",
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
frame.Size = UDim2.new(0, 290, 0, 500)
frame.Position = UDim2.new(0, 15, 0.25, 0)
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
title.Text = "LOBBY DIAG v6 (DEEP)"
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
status.Position = UDim2.new(0, 10, 0, 472)
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
        return false
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
    return true
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
end)

local btnSweep = makeButton("BARRIO SPIN (todos los args)", 104)
btnSweep.MouseButton1Click:Connect(function()
    local r = getRemote("RequestWheelSpin")
    if not r then
        log("RequestWheelSpin NO ENCONTRADO")
        return
    end
    local argsList = { "Basic", "Gold", "Lucky", "Free", "Daily", "Wheel", "Normal", "normal", "f", "free", "gem", "gems", 0, 1, 2, true, false, "" }
    log("== BARRIO SPIN (1.5s entre fires) ==")
    for _, arg in ipairs(argsList) do
        local before = player:GetAttribute("Fragments")
        pcall(function()
            r:FireServer(arg)
        end)
        task.wait(1.5)
        local after = player:GetAttribute("Fragments")
        local delta = (after or 0) - (before or 0)
        log(string.format("spin(%s) -> Fragments %s -> %s (delta %s)", tostring(arg), tostring(before), tostring(after), tostring(delta)))
    end
    log("== BARRIO TERMINADO ==")
end)

local btnSkip = makeButton("FIRE SkipTimer", 136)
btnSkip.MouseButton1Click:Connect(function()
    fired("SkipTimer")
    task.wait(0.4)
    fired("SkipTimer", 0)
    task.wait(0.4)
    fired("SkipTimer", "Wheel")
end)

local btnDaily = makeButton("FIRE ClaimDailyReward", 168)
btnDaily.MouseButton1Click:Connect(function()
    fired("ClaimDailyReward")
    task.wait(0.4)
    fired("ClaimDailyReward", true)
end)

local btnAura = makeButton("FIRE AuraRoll", 200)
btnAura.MouseButton1Click:Connect(function()
    fired("AuraRoll")
    task.wait(0.4)
    fired("AuraRoll", 0)
    task.wait(0.4)
    fired("AuraRoll", "Lucky")
end)

local btnHatch = makeButton("FIRE HatchEgg", 232)
btnHatch.MouseButton1Click:Connect(function()
    fired("HatchEgg", 0)
    task.wait(0.4)
    fired("HatchEgg", "Basic")
end)

local btnUpgrade = makeButton("FIRE UpgradeAll", 264)
btnUpgrade.MouseButton1Click:Connect(function()
    fired("UpgradeAll")
end)

local btnPets = makeButton("PETS 21 (equipar masivo)", 296)
btnPets.MouseButton1Click:Connect(function()
    player:SetAttribute("PetSpace", 21)
    player:SetAttribute("PetBagCapacity", 21)
    player:SetAttribute("Upgrade_PetEquip", 21)
    log("> PetSpace/PetBagCapacity/Upgrade_PetEquip = 21")
    local petModels = game.ReplicatedStorage:FindFirstChild("PetModels")
    if petModels then
        local n = 0
        for _, pet in ipairs(petModels:GetChildren()) do
            if pet:IsA("Model") then
                pcall(function()
                    getRemote("EquipPet"):FireServer(pet.Name)
                end)
                n = n + 1
                task.wait(0.2)
            end
        end
        log("> EquipPet fired con " .. n .. " nombres de pets")
    else
        log("PetModels NO ENCONTRADO")
    end
    status.Text = "Pets equipados intentados. Mira EquippedPets en el log."
end)

local btnGpIds = makeButton("GP IDS (fire con ids reales)", 328)
btnGpIds.MouseButton1Click:Connect(function()
    local mod = game.ReplicatedStorage:FindFirstChild("Shared")
    local list = {}
    local function collect(tab)
        for _, v in pairs(tab) do
            if type(v) == "number" then
                table.insert(list, v)
            elseif type(v) == "table" then
                collect(v)
            end
        end
    end
    for _, name in ipairs({ "GamePasses", "DevProducts" }) do
        local child = mod and mod:FindFirstChild(name)
        if child then
            local ok, res = pcall(require, child)
            if ok and type(res) == "table" then
                collect(res)
                log("> " .. name .. " module cargado")
            else
                log("> " .. name .. " require fallo")
            end
        end
    end
    log("> ids encontrados: " .. table.concat(list, ", "))
    for _, id in ipairs(list) do
        fired("PurchaseGamepassVfx", id)
        task.wait(0.5)
    end
end)

local function serialize(value, depth)
    if depth > 3 then
        return "..."
    end
    local t = type(value)
    if t == "number" or t == "string" or t == "boolean" then
        return tostring(value)
    elseif t == "table" then
        local parts = {}
        local n = 0
        for k, v in pairs(value) do
            if n < 60 then
                table.insert(parts, tostring(k) .. "=" .. serialize(v, depth + 1))
                n = n + 1
            end
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    else
        return t
    end
end

local btnModules = makeButton("DUMP MODULES (profundo)", 360)
btnModules.MouseButton1Click:Connect(function()
    log("== DUMP MODULES ==")
    local shared = game.ReplicatedStorage:FindFirstChild("Shared")
    if shared then
        for _, name in ipairs({ "GamePasses", "DevProducts", "Perks", "Upgrades", "GlobalUpgrades", "Classes", "Pets", "Titles", "Auras", "StatMath", "SpecialBalls" }) do
            local child = shared:FindFirstChild(name)
            if child then
                local ok, res = pcall(require, child)
                if ok then
                    log(name .. " = " .. serialize(res, 0))
                else
                    log(name .. ": require fallo: " .. tostring(res))
                end
            else
                log(name .. ": no existe")
            end
        end
    end
    local configs = game.ReplicatedStorage:FindFirstChild("Configs")
    if configs then
        for _, name in ipairs({ "GameModesConfig", "StatConfig", "UIConfig" }) do
            local child = nil
            for _, folder in ipairs(configs:GetChildren()) do
                local found = folder:FindFirstChild(name)
                if found then
                    child = found
                    break
                end
            end
            if child then
                local ok, res = pcall(require, child)
                if ok then
                    log(name .. " = " .. serialize(res, 0))
                end
            end
        end
    end
    for _, full in ipairs(findAllRemotes()) do
        if full:match("Networker") then
            log("> Networker en: " .. full)
        end
    end
    log("== DUMP MODULES TERMINADO ==")
    status.Text = "Modulos escritos al log."
end)

local btnDump = makeButton("DUMP REMOTES", 392)
btnDump.MouseButton1Click:Connect(function()
    log("== TODOS LOS REMOTES ==")
    for _, full in ipairs(findAllRemotes()) do
        log(full)
    end
    status.Text = "Remotes escritos al log."
end)

local btnPity = makeButton("PITY GRATIS", 424)
btnPity.MouseButton1Click:Connect(function()
    player:SetAttribute("BasicPity", 0)
    player:SetAttribute("GoldPity", 0)
    player:SetAttribute("LuckyPity", 0)
    log("> Pity reset a 0")
    status.Text = "Pity en 0. Tira una vez y mira."
end)

local btnReset = makeButton("RESET TODO", 456)
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

log("== LOBBY DIAG v6 LISTO ==")
