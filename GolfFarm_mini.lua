local player = game.Players.LocalPlayer
print("[Golf] Inicio")

local balls = workspace:FindFirstChild("ActiveGolfBalls2")
local remotes = game.ReplicatedStorage:FindFirstChild("RemotesNew")
print("[Golf] balls:", balls and balls.Name or "NO")
print("[Golf] remotes:", remotes and remotes.Name or "NO")

if not balls or not remotes then
    print("[Golf] No encontrado. WS:")
    for _, v in ipairs(workspace:GetChildren()) do
        print("WS:", v.ClassName, v.Name)
    end
    print("[Golf] RS:")
    for _, v in ipairs(game.ReplicatedStorage:GetChildren()) do
        print("RS:", v.ClassName, v.Name)
    end
    return
end

local collect = remotes:FindFirstChild("Collect")
local fill = remotes:FindFirstChild("FillNet")
local buyAll = remotes:FindFirstChild("BuyAllShop")
print("[Golf] Collect:", collect and "OK" or "NO", "| FillNet:", fill and "OK" or "NO", "| BuyAllShop:", buyAll and "OK" or "NO")

while true do
    if buyAll then
        pcall(function()
            buyAll:FireServer()
        end)
    end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root and collect then
        local bagCount = player:GetAttribute("BagCount") or 0
        local bagCap = player:GetAttribute("BagCapacity") or 10
        if fill and bagCount >= bagCap then
            pcall(function()
                fill:FireServer()
            end)
            print("[Golf] Vendido!")
            wait(0.3)
        end
        local best = nil
        local bestD = math.huge
        for _, b in ipairs(balls:GetChildren()) do
            if b:IsA("BasePart") then
                local d = (b.Position - root.Position).Magnitude
                if d < bestD then
                    bestD = d
                    best = b
                end
            end
        end
        if best then
            root.CFrame = CFrame.new(best.Position + Vector3.new(0, 3, 0))
            wait(0.1)
            local batch = {}
            for _, b in ipairs(balls:GetChildren()) do
                if b:IsA("BasePart") and (b.Position - root.Position).Magnitude <= 60 then
                    table.insert(batch, b)
                    if #batch >= 100 then
                        break
                    end
                end
            end
            if #batch > 0 then
                pcall(function()
                    collect:FireServer(batch)
                end)
                print("[Golf] Recogidas:", #batch)
            end
        end
    end
    wait(0.2)
end
