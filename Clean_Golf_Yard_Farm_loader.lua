-- ══════════ GOLF YARD FARM · LOADER (JNkie) ══════════
local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
Junkie.service = "GolfFarm"
Junkie.identifier = "1176809"
Junkie.provider = "Golf"

local SCRIPT_URL = "https://api.jnkie.com/api/v1/luascripts/public/49dc99877e68161cbfb90e3d5963e28d9d4b1f67d3b1faa3bc04dd1d14903882/download"

if getgenv().SCRIPT_KEY then
    print("[GolfFarm] SCRIPT_KEY detectado, cargando farm...")
    loadstring(game:HttpGet(SCRIPT_URL))()
    return
end

local Players = game:GetService("Players")
local uis = game:GetService("UserInputService")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then
    warn("[GolfFarm] PlayerGui nil")
    return
end

local function clipboard(text)
    pcall(function()
        setclipboard(text)
    end)
    pcall(function()
        Clipboard.set(text)
    end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "GolfFarmKey"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 250)
frame.Position = UDim2.new(0.5, -160, 0.5, -125)
frame.BackgroundColor3 = Color3.fromRGB(14, 18, 26)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70, 220, 140)
stroke.Thickness = 1
stroke.Transparency = 0.45
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 34)
title.Position = UDim2.new(0, 0, 0, 8)
title.BackgroundTransparency = 1
title.Text = "GOLF YARD FARM — KEY"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 17
title.Font = Enum.Font.GothamBold
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -24, 0, 30)
status.Position = UDim2.new(0, 12, 0, 46)
status.BackgroundTransparency = 1
status.Text = "Pulsa 'Obtener key' para empezar"
status.TextColor3 = Color3.fromRGB(200, 210, 225)
status.TextSize = 11
status.Font = Enum.Font.Gotham
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Center
status.Parent = frame

local function makeButton(text, posY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -24, 0, 30)
    btn.Position = UDim2.new(0, 12, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(55, 65, 85)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 9)
    c.Parent = btn
    btn.MouseEnter:Connect(function()
        btn.BackgroundTransparency = 0.25
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundTransparency = 0
    end)
    btn.Parent = frame
    return btn
end

local getBtn = makeButton("1 · OBTENER KEY (copia el link)", 82)
local copyBtn = makeButton("2 · COPIAR LINK DE NUEVO", 118)

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(1, -24, 0, 30)
keyBox.Position = UDim2.new(0, 12, 0, 154)
keyBox.BackgroundColor3 = Color3.fromRGB(24, 30, 42)
keyBox.PlaceholderText = "Pega tu key aqui"
keyBox.Text = ""
keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
keyBox.TextSize = 13
keyBox.Font = Enum.Font.GothamBold
keyBox.ClearTextOnFocus = false
local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 9)
keyCorner.Parent = keyBox
keyBox.Parent = frame

local valBtn = makeButton("3 · VALIDAR KEY", 190)
valBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)

local done = false

local function setStatus(text, color)
    status.Text = text
    if color then status.TextColor3 = color end
end

getBtn.MouseButton1Click:Connect(function()
    setStatus("Obteniendo link...", Color3.fromRGB(200, 210, 225))
    local link, err = Junkie.get_key_link()
    if not link then
        setStatus("Error: " .. tostring(err), Color3.fromRGB(255, 90, 90))
        return
    end
    clipboard(link)
    setStatus("Link copiado al portapapeles. Abrelo y saca tu key.", Color3.fromRGB(80, 255, 120))
end)

copyBtn.MouseButton1Click:Connect(function()
    local link = Junkie.get_key_link()
    if not link then
        setStatus("Espera ~5 min entre links", Color3.fromRGB(255, 170, 60))
        return
    end
    clipboard(link)
    setStatus("Link copiado de nuevo", Color3.fromRGB(80, 255, 120))
end)

valBtn.MouseButton1Click:Connect(function()
    if done then return end
    local key = keyBox.Text:gsub("%s", "")
    if #key == 0 then
        setStatus("Escribe o pega tu key primero", Color3.fromRGB(255, 170, 60))
        return
    end
    setStatus("Validando...", Color3.fromRGB(200, 210, 225))
    local res = Junkie.check_key(key)
    if res.valid then
        done = true
        getgenv().SCRIPT_KEY = key
        local premium = getgenv().JD_IS_PREMIUM == true
        setStatus("Key valida. Cargando farm...", Color3.fromRGB(80, 255, 120))
        print("[GolfFarm] Key validada | Premium:", tostring(premium))
        task.wait(0.4)
        gui:Destroy()
        loadstring(game:HttpGet(SCRIPT_URL))()
    else
        local msg = res.error or res.message or "Key invalida"
        setStatus("Error: " .. tostring(msg), Color3.fromRGB(255, 90, 90))
        if msg == "HWID_BANNED" then
            pcall(function()
                player:Kick("Hardware baneado")
            end)
        end
    end
end)

keyBox.FocusLost:Connect(function(enter)
    if enter then valBtn.MouseButton1Click:Fire() end
end)

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