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
    if not packageRoot then return nil end
    local candidates = {}
    local direct = packageRoot:FindFirstChild("Networker")
    if direct then table.insert(candidates, direct) end
    local packages = packageRoot:FindFirstChild("Packages")
    local packed = packages and packages:FindFirstChild("Networker")
    if packed then table.insert(candidates, packed) end
    for _, module in ipairs(candidates) do
        logReport("module Networker candidato: " .. module:GetFullName())
        local ok, inst = pcall(require, module)
        logReport("require: " .. tostring(ok))
        if ok and inst then
            if type(inst) == "table" and inst.FireServer then
                logReport("usando modulo directo (tiene FireServer)")
                return inst
            end
            local ok2, nw = pcall(function()
                return inst.new()
            end)
            logReport("inst.new(): " .. tostring(ok2))
            if ok2 and nw and type(nw) == "table" and nw.FireServer then
                return nw
            end
        end
    end
    return nil
end

local networker = findNetworker()
logReport("networker: " .. tostring(networker and "SI" or "NIL"))

local collectRemote = remotes and remotes:FindFirstChild("Collect")
logReport("remote Collect: " .. tostring(collectRemote and "SI" or "NO"))

local function attr(n, d)
    local v = player:GetAttribute(n)
    if v == nil then return d end
    return v
end
local cap = attr("BagCapacity", 10)
logReport("BagCount=" .. tostring(attr("BagCount", 0)) .. " BagCapacity=" .. tostring(cap) .. " CollectionRange=" .. tostring(attr("CollectionRange", "?")) .. " CollectCooldown=" .. tostring(attr("CollectCooldown", "?")))

local function ballPos(ball)
    if not ball or ball.Parent == nil then return nil end
    local ok, p = pcall(function()
        return ball.Position
    end
)
    if ok and p then return p end
    return nil
end

local char = player.Character
local root = char and char:FindFirstChild("HumanoidRootPart")
logReport("character root: " .. tostring(root and "SI" or "NO"))

if root and collectRemote then
    local origin = root.Position
    local near = {}
    local total = 0
    for _, b in ipairs(balls:GetChildren()) do
        local p = ballPos(b)
        if p then
            total = total + 1
            local d = (p - origin).Magnitude
            if d <= 20 and #near < 3 then
                table.insert(near, b)
            end
        end
    end
    logReport("bolas totales accesibles: " .. total .. " | 3 mas cercanas: " .. #near)
    if #near > 0 then
        local before = attr("BagCount", 0)
        local okFire = pcall(function()
            if networker then
                networker:FireServer("Collect", near)
            else
                collectRemote:FireServer(near)
            end
        end)
        logReport("fire Collect enviado: " .. tostring(okFire) .. " | bolsa antes: " .. tostring(before))
        task.wait(1.5)
        local after = attr("BagCount", 0)
        logReport("bolsa despues: " .. tostring(after) .. " | delta: " .. tostring(after - before))
    else
        logReport("NO hay bolas cerca (parate encima de un grupo de bolas y repite)")
    end
end

local okWrite = pcall(function()
    writefile("golffarm_diag.txt", table.concat(report, "\n"))
end)
logReport("writefile: " .. tostring(okWrite))
print("[Diag] FIN")
