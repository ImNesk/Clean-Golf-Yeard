local report = {}
local function logReport(msg)
    table.insert(report, msg)
    print("[Diag] " .. msg)
end

logReport("Iniciando...")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
logReport("LocalPlayer: " .. tostring(player and player.Name))

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
logReport("balls folder: " .. tostring(balls and (balls.Name .. " (" .. #balls:GetChildren() .. " hijos)") or "NO ENCONTRADA"))

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
logReport("remotes folder: " .. tostring(remotes and remotes.Name or "NO ENCONTRADA"))

local function findNetworker()
    local modules = rs:FindFirstChild("Modules")
    local packageRoot = modules and modules:FindFirstChild("rwque")
    local packages = packageRoot and packageRoot:FindFirstChild("Packages")
    local module = packages and packages:FindFirstChild("Networker")
    logReport("Networker module: " .. tostring(module and module:GetFullName() or "NO ENCONTRADO"))
    if module then
        local ok, inst = pcall(require, module)
        logReport("require Networker: " .. tostring(ok))
        if ok and inst then
            local ok2, nw = pcall(function()
                return inst.new()
            end)
            logReport("inst.new(): " .. tostring(ok2))
            if ok2 and nw then return nw end
        end
    end
    return nil
end

local networker = findNetworker()
logReport("networker: " .. tostring(networker or "NIL"))

for _, name in ipairs({ "Collect", "FillNet", "BuyAllShop" }) do
    local r = remotes and remotes:FindFirstChild(name)
    logReport("remote " .. name .. ": " .. tostring(r and "SI" or "NO"))
end

local function attr(n, d)
    local v = player:GetAttribute(n)
    if v == nil then return d end
    return v
end
logReport("BagCount=" .. tostring(attr("BagCount", 0)) .. " BagCapacity=" .. tostring(attr("BagCapacity", 10)) .. " CollectionRange=" .. tostring(attr("CollectionRange", "?")) .. " CollectCooldown=" .. tostring(attr("CollectCooldown", "?")))

local okWrite = pcall(function()
    writefile("golffarm_diag.txt", table.concat(report, "\n"))
end)
logReport("writefile: " .. tostring(okWrite))
print("[Diag] FIN")
