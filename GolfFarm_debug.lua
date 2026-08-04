local lines = {}

local function add(msg)
    table.insert(lines, msg)
    print(msg)
end

local player = game.Players.LocalPlayer
local balls = workspace:FindFirstChild("ActiveGolfBalls2")
local remotes = game.ReplicatedStorage:FindFirstChild("RemotesNew")
local collect = remotes and remotes:FindFirstChild("Collect")

if not balls then
    add("NO HAY CARPETA DE PELOTAS")
else
    local total = 0
    local parts = 0
    local firstNames = {}
    local maxDist = 0
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    for _, b in ipairs(balls:GetChildren()) do
        total = total + 1
        if b:IsA("BasePart") then
            parts = parts + 1
            if root then
                local d = (b.Position - root.Position).Magnitude
                if d > maxDist then maxDist = d end
            end
        end
        if #firstNames < 5 then
            table.insert(firstNames, b.ClassName .. ":" .. b.Name)
        end
    end
    add("Total hijos: " .. total .. " | BaseParts: " .. parts .. " | MaxDist: " .. math.floor(maxDist))
    add("Ejemplos: " .. table.concat(firstNames, ", "))
end

add("Collect remote: " .. tostring(collect and collect.ClassName))

if collect then
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local bagBefore = player:GetAttribute("BagCount") or 0
    add("BagCount antes: " .. tostring(bagBefore))

    local firstBall = nil
    local farBall = nil
    local farD = 0
    for _, b in ipairs(balls:GetChildren()) do
        if b:IsA("BasePart") then
            if not firstBall then firstBall = b end
            if root then
                local d = (b.Position - root.Position).Magnitude
                if d > farD then
                    farD = d
                    farBall = b
                end
            end
        end
    end

    if firstBall then
        add("Probando Collect con UNA pelota cerca...")
        pcall(function()
            collect:FireServer(firstBall)
        end)
        wait(0.5)
        add("BagCount despues de 1: " .. tostring(player:GetAttribute("BagCount") or 0))
    end

    if farBall and root then
        add("Pelota lejana a " .. math.floor(farD) .. " studs. Probando...")
        pcall(function()
            root.CFrame = CFrame.new(farBall.Position + Vector3.new(0, 3, 0))
        end)
        wait(0.5)
        pcall(function()
            collect:FireServer(farBall)
        end)
        wait(0.5)
        add("BagCount despues de lejana: " .. tostring(player:GetAttribute("BagCount") or 0))
    end
end

pcall(function()
    writefile("golffarm_debug.txt", table.concat(lines, "\n"))
end)
add("DEBUG LISTO")
