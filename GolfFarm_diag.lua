print("[Diag] Iniciando...")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
print("[Diag] LocalPlayer: " .. tostring(player and player.Name))

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

local balls = findBallsFolder()
print("[Diag] balls folder: " .. tostring(balls and (balls.Name .. " (" .. #balls:GetChildren() .. " hijos)") or "NO ENCONTRADA"))

local rs = game:GetService("ReplicatedStorage")
local function findRemotesFolder()
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

local remotes = findRemotesFolder()
print("[Diag] remotes folder: " .. tostring(remotes and remotes.Name or "NO ENCONTRADA"))

local function findNetworker()
    local modules = rs:FindFirstChild("Modules")
    local packageRoot = modules and modules:FindFirstChild("rwque")
    local packages = packageRoot and packageRoot:FindFirstChild("Packages")
    local module = packages and packages:FindFirstChild("Networker")
    print("[Diag] Networker module: " .. tostring(module and module:GetFullName() or "NO ENCONTRADO"))
    if module then
        local ok, inst = pcall(require, module)
        print("[Diag] require Networker: " .. tostring(ok))
        if ok and inst then
            local ok2, nw = pcall(function()
                return inst.new()
            end)
            print("[Diag] inst.new(): " .. tostring(ok2))
            if ok2 and nw then return nw end
        end
    end
    return nil
end

local networker = findNetworker()
print("[Diag] networker: " .. tostring(networker or "NIL"))

for _, name in ipairs({ "Collect", "FillNet", "BuyAllShop" }) do
    local r = remotes and remotes:FindFirstChild(name)
    print("[Diag] remote " .. name .. ": " .. tostring(r and "SI" or "NO"))
end

local function attr(n, d)
    local v = player:GetAttribute(n)
    if v == nil then return d end
    return v
end
print("[Diag] BagCount=" .. tostring(attr("BagCount", 0)) .. " BagCapacity=" .. tostring(attr("BagCapacity", 10)) .. " CollectionRange=" .. tostring(attr("CollectionRange", "?")) .. " CollectCooldown=" .. tostring(attr("CollectCooldown", "?")))

local okWrite = pcall(function()
    writefile("golffarm_diag.txt", "diag ejecutado correctamente")
end)
print("[Diag] writefile: " .. tostring(okWrite))
print("[Diag] FIN")
