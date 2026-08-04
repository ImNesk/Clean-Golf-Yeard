local player = game.Players.LocalPlayer
print("[GolfFarm] Inicio")

local balls = workspace:FindFirstChild("ActiveGolfBalls")
local remotes = game.ReplicatedStorage:FindFirstChild("RemotesNew")
print("[GolfFarm] balls:", balls and balls.Name or "NO ENCONTRADO")
print("[GolfFarm] remotes:", remotes and remotes.Name or "NO ENCONTRADO")

if not balls or not remotes then
    print("[GolfFarm] Estructura no encontrada. Listando workspace:")
    for _, v in ipairs(workspace:GetChildren()) do
        print("WS:", v.ClassName, v.Name)
    end
    print("[GolfFarm] Listando ReplicatedStorage:")
    for _, v in ipairs(game.ReplicatedStorage:GetChildren()) do
        print("RS:", v.ClassName, v.Name)
    end
    return
end

local collect = remotes:FindFirstChild("Collect2")
local fill = remotes:FindFirstChild("Fill")
print("[GolfFarm] Collect2:", collect and "OK" or "NO", "| Fill:", fill and "OK" or "NO")

local function getRoot()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

task.spawn(function()
    while true do
        local root = getRoot()
        if root then
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
                task.wait(0.1)
                local batch = {}
                for _, b in ipairs(balls:GetChildren()) do
                    if b:IsA("BasePart") and (b.Position - root.Position).Magnitude <= 60 then
                        table.insert(batch, b)
                        if #batch >= 100 then
                            break
                        end
                    end
                end
                if #batch > 0 and collect then
                    pcall(function()
                        collect:FireServer(batch)
                    end)
                    print("[GolfFarm] Recogidas:", #batch)
                end
            end
        end
        task.wait(0.2)
    end
end)

print("[GolfFarm] Script listo")
