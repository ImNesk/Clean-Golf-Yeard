local Players = game:GetService("Players")
local player = Players.LocalPlayer

local farming = false
local speedEnabled = false
local Farmed = 0
local RESPAWN_WAIT = 60
local ARRIVE_DELAY = 0.6
local ROB_DELAY = 1.0
local waitStart = 0
local status, availableLabel, timerLabel

local function getCharacter()
    if not player.Character then player.CharacterAdded:Wait() end
    return player.Character
end

local function getHumanoidRootPart()
    local char = getCharacter()
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

local cachedATMs = {}
local scanDone = false

local function findATMs()
    local found = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local parent = v.Parent
            local pname = parent and string.lower(parent.Name) or ""
            local gname = parent and parent.Parent and string.lower(parent.Parent.Name) or ""
            if pname:find("atm") or pname:find("cajero") or gname:find("atm") or gname:find("cajero") then
                table.insert(found, v)
            end
        end
    end
    return found
end

local function startScan()
    scanDone = false
    task.spawn(function()
        cachedATMs = findATMs()
        scanDone = true
    end)
end

local function promptWorldPos(prompt)
    local parent = prompt.Parent
    if parent:IsA("BasePart") then
        return parent.Position
    elseif parent:IsA("Attachment") then
        return parent.WorldPosition
    end
    return nil
end

local function moveTo(hrp, goal)
    local dist = (goal.Position - hrp.Position).Magnitude
    if dist > 1500 then
        local mid = hrp.Position:Lerp(goal.Position, 0.5) + Vector3.new(0, 30, 0)
        hrp.CFrame = CFrame.lookAt(mid, goal.Position)
        task.wait(0.5)
    end
    hrp.CFrame = goal
end

local function farmATM(prompt)
    local char = getCharacter()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Sit then
        humanoid.Sit = false
        task.wait(0.4)
    end

    local hrp = getHumanoidRootPart()
    if not hrp then return end
    local pos = promptWorldPos(prompt)
    if not pos then return end

    local maxDist = prompt.MaxActivationDistance or 10
    local dir = (pos - hrp.Position)
    if dir.Magnitude < 1e-3 then dir = Vector3.new(1, 0, 0) end
    local goal = pos - dir.Unit * math.min(1.5, math.max(1, maxDist * 0.4))
    goal = goal + Vector3.new(0, 2, 0)

    moveTo(hrp, goal)
    task.wait(ARRIVE_DELAY)

    if prompt.Enabled and prompt.Parent then
        pcall(function()
            prompt.RequiresLineOfSight = false
            fireproximityprompt(prompt)
        end)
        Farmed = Farmed + 1
    end

    task.wait(ROB_DELAY)
end

local function farmLoop()
    waitStart = 0
    startScan()
    while farming do
        if not scanDone then
            status.Text = "Buscando ATMs..."
            availableLabel.Text = "ATMs disponibles: ..."
            timerLabel.Text = ""
            task.wait(0.1)
        else
        local atms = cachedATMs
        local available = {}
        for _, p in ipairs(atms) do
            if p and p.Enabled and p.Parent then
                table.insert(available, p)
            end
        end

        if #available > 0 then
            waitStart = 0
            status.Text = "Farmando... (" .. Farmed .. " robados)"
            availableLabel.Text = "ATMs disponibles: " .. #available .. " / " .. #atms
            timerLabel.Text = ""
            for _, prompt in ipairs(available) do
                if not farming then break end
                pcall(farmATM, prompt)
            end
        else
            if #atms == 0 then
                status.Text = "Buscando ATMs..."
                availableLabel.Text = "ATMs disponibles: 0"
                timerLabel.Text = ""
                task.wait(1)
            else
                if waitStart == 0 then waitStart = os.clock() end
                local elapsed = os.clock() - waitStart
                local remaining = math.max(0, RESPAWN_WAIT - elapsed)
                status.Text = "No queda nada por robar."
                availableLabel.Text = "ATMs disponibles: 0 / " .. #atms
                timerLabel.Text = "Próximo ATM en: " .. string.format("%02d:%02d", math.floor(remaining / 60), math.floor(remaining % 60))
                if remaining <= 0 then
                    waitStart = 0
                end
                task.wait(1)
            end
        end
        end
    end
end

local function applySpeed()
    task.spawn(function()
        while speedEnabled do
            local hrp = getHumanoidRootPart()
            if hrp then
                hrp.Velocity = hrp.Velocity * 1.15
            end
            task.wait(0.1)
        end
    end)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "YSOFarm"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 160)
frame.Position = UDim2.new(0, 15, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
title.Text = "YSO ATM FARM"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.Parent = frame

local drag = { dragging = false, offset = Vector2.new() }
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        drag.dragging = true
        drag.offset = input.Position - Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)
    end
end)
title.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        drag.dragging = false
    end
end)
frame.InputChanged:Connect(function(input)
    if drag.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        frame.Position = UDim2.new(0, input.Position.X - drag.offset.X, 0, input.Position.Y - drag.offset.Y)
    end
end)

local farmBtn = Instance.new("TextButton")
farmBtn.Size = UDim2.new(1, -20, 0, 30)
farmBtn.Position = UDim2.new(0, 10, 0, 34)
farmBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
farmBtn.Text = "FARM: OFF  [F]"
farmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
farmBtn.TextSize = 14
farmBtn.Font = Enum.Font.GothamBold
farmBtn.Parent = frame

local speedBtn = Instance.new("TextButton")
speedBtn.Size = UDim2.new(1, -20, 0, 30)
speedBtn.Position = UDim2.new(0, 10, 0, 68)
speedBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
speedBtn.Text = "SPEED: OFF  [G]"
speedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBtn.TextSize = 14
speedBtn.Font = Enum.Font.GothamBold
speedBtn.Parent = frame

status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.new(0, 10, 0, 102)
status.BackgroundTransparency = 1
status.Text = "Listo. Presiona F para farmear."
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextSize = 12
status.Font = Enum.Font.Gotham
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

availableLabel = Instance.new("TextLabel")
availableLabel.Size = UDim2.new(1, -20, 0, 18)
availableLabel.Position = UDim2.new(0, 10, 0, 122)
availableLabel.BackgroundTransparency = 1
availableLabel.Text = "ATMs disponibles: -"
availableLabel.TextColor3 = Color3.fromRGB(120, 220, 130)
availableLabel.TextSize = 12
availableLabel.Font = Enum.Font.Gotham
availableLabel.TextXAlignment = Enum.TextXAlignment.Left
availableLabel.Parent = frame

timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(1, -20, 0, 18)
timerLabel.Position = UDim2.new(0, 10, 0, 140)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = ""
timerLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
timerLabel.TextSize = 12
timerLabel.Font = Enum.Font.Gotham
timerLabel.TextXAlignment = Enum.TextXAlignment.Left
timerLabel.Parent = frame

local function toggleFarm()
    farming = not farming
    farmBtn.BackgroundColor3 = farming and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(200, 60, 60)
    farmBtn.Text = farming and "FARM: ON  [F]" or "FARM: OFF  [F]"
    if farming then
        status.Text = "Buscando ATMs..."
        task.spawn(farmLoop)
    else
        status.Text = "Farm detenido."
        availableLabel.Text = "ATMs disponibles: -"
        timerLabel.Text = ""
    end
end

local function toggleSpeed()
    speedEnabled = not speedEnabled
    speedBtn.BackgroundColor3 = speedEnabled and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(70, 70, 85)
    speedBtn.Text = speedEnabled and "SPEED: ON  [G]" or "SPEED: OFF  [G]"
    if speedEnabled then applySpeed() end
end

farmBtn.MouseButton1Click:Connect(toggleFarm)
speedBtn.MouseButton1Click:Connect(toggleSpeed)

local inputService = game:GetService("UserInputService")
inputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then toggleFarm() end
    if input.KeyCode == Enum.KeyCode.G then toggleSpeed() end
end)
