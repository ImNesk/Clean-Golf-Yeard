-- ══════════ GOLF YARD FARM · LOADER (JNkie Premium) ══════════
local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
Junkie.service = "Clean the Golf Yard"
Junkie.identifier = "1176809"
Junkie.provider = "Golf"

local SCRIPT_URL = "https://api.jnkie.com/api/v1/luascripts/public/49dc99877e68161cbfb90e3d5963e28d9d4b1f67d3b1faa3bc04dd1d14903882/download"

if getgenv().SCRIPT_KEY then
    print("[GolfFarm] SCRIPT_KEY detected, loading farm...")
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
    pcall(function() setclipboard(text) end)
    pcall(function() Clipboard.set(text) end)
end

local C = {
    bg = Color3.fromRGB(8, 10, 17),
    card = Color3.fromRGB(15, 19, 31),
    panel = Color3.fromRGB(23, 30, 46),
    border = Color3.fromRGB(44, 54, 78),
    text = Color3.fromRGB(240, 246, 255),
    sub = Color3.fromRGB(148, 160, 185),
    green = Color3.fromRGB(66, 220, 145),
    violet = Color3.fromRGB(130, 105, 255),
    gold = Color3.fromRGB(255, 198, 92),
    red = Color3.fromRGB(255, 92, 102),
}

local gui = Instance.new("ScreenGui")
gui.Name = "GolfFarmKey"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 500
gui.Parent = playerGui

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = C.bg
backdrop.BackgroundTransparency = 0.55
backdrop.Parent = gui

local card = Instance.new("Frame")
card.Name = "Card"
card.Size = UDim2.new(0, 380, 0, 488)
card.Position = UDim2.new(0.5, -190, 0.5, -244)
card.BackgroundColor3 = C.card
card.BorderSizePixel = 0
card.ClipsDescendants = true
card.Parent = gui

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 24)
cardCorner.Parent = card

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = C.border
cardStroke.Thickness = 1
cardStroke.Parent = card

local accent = Instance.new("Frame")
accent.Size = UDim2.new(1, 0, 0, 4)
accent.Position = UDim2.new(0, 0, 1, -4)
accent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
accent.BorderSizePixel = 0
local accentGrad = Instance.new("UIGradient")
accentGrad.Color = ColorSequence.new(
    Color3.fromRGB(66, 220, 145),
    Color3.fromRGB(130, 105, 255),
    Color3.fromRGB(255, 120, 210)
)
accentGrad.Rotation = 40
accentGrad.Parent = accent
accent.Parent = card

local function text(parent, txt, size, font, color, pos, width, height)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, width or 380, 0, height or 20)
    lbl.Position = pos
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.TextColor3 = color or C.text
    lbl.TextSize = size
    lbl.Font = font or Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.Parent = parent
    return lbl
end

local title1 = Instance.new("TextLabel")
title1.Size = UDim2.new(0, 150, 0, 42)
title1.Position = UDim2.new(0, 26, 0, 24)
title1.BackgroundTransparency = 1
title1.Text = "GOLF YARD"
title1.TextColor3 = C.text
title1.TextSize = 26
title1.Font = Enum.Font.GothamBold
title1.TextXAlignment = Enum.TextXAlignment.Left
title1.Parent = card

local title2 = Instance.new("TextLabel")
title2.Size = UDim2.new(0, 94, 0, 42)
title2.Position = UDim2.new(0, 172, 0, 24)
title2.BackgroundTransparency = 1
title2.Text = "FARM"
title2.TextSize = 26
title2.Font = Enum.Font.GothamBold
title2.TextXAlignment = Enum.TextXAlignment.Left
title2.Parent = card
local title2Grad = Instance.new("UIGradient")
title2Grad.Color = ColorSequence.new(C.green, C.violet)
title2Grad.Rotation = 20
title2Grad.Parent = title2

text(card, "PREMIUM KEY VALIDATION", 10, Enum.Font.GothamMedium, C.sub, UDim2.new(0, 26, 0, 66), 240, 18)

local statusDot = Instance.new("TextLabel")
statusDot.Size = UDim2.new(0, 16, 0, 16)
statusDot.Position = UDim2.new(0, 27, 0, 100)
statusDot.BackgroundTransparency = 1
statusDot.Text = "●"
statusDot.TextColor3 = C.gold
statusDot.TextSize = 10
statusDot.Font = Enum.Font.GothamBold
statusDot.Parent = card

local status = Instance.new("TextLabel")
status.Size = UDim2.new(0, 320, 0, 34)
status.Position = UDim2.new(0, 42, 0, 99)
status.BackgroundTransparency = 1
status.Text = "Preparing your secure link..."
status.TextColor3 = C.sub
status.TextSize = 11
status.Font = Enum.Font.Gotham
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.TextWrapped = true
status.Parent = card

local STEP_Y = 150
local steps = {}
local stepLabels = { "GET KEY", "PASTE KEY", "ACTIVATE" }
for i = 1, 3 do
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 26, 0, 26)
    dot.Position = UDim2.new(0, 66 + (i - 1) * 110, 0, STEP_Y)
    dot.BackgroundColor3 = C.panel
    dot.BorderSizePixel = 0
    local dCorner = Instance.new("UICorner")
    dCorner.CornerRadius = UDim.new(1, 0)
    dCorner.Parent = dot
    local dStroke = Instance.new("UIStroke")
    dStroke.Color = C.border
    dStroke.Thickness = 1
    dStroke.Parent = dot
    text(dot, tostring(i), 12, Enum.Font.GothamBold, C.sub, UDim2.new(0, 0, 0, 0), 26, 26)
    dot.Parent = card

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 110, 0, 18)
    lbl.Position = UDim2.new(0, 79 + (i - 1) * 110, 0, STEP_Y + 30)
    lbl.AnchorPoint = Vector2.new(0.5, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = stepLabels[i]
    lbl.TextColor3 = C.sub
    lbl.TextSize = 9
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.Parent = card

    steps[i] = { dot = dot, stroke = dStroke, num = text, color = C.sub, label = lbl }
end

local function setStep(step)
    for i, s in ipairs(steps) do
        local on = i <= step
        s.dot.BackgroundColor3 = on and C.green or C.panel
        s.stroke.Color = on and C.green or C.border
        s.stroke.Thickness = on and 1.5 or 1
        s.label.TextColor3 = on and C.green or C.sub
    end
end

local function setStatus(txt, color)
    status.Text = txt
    status.TextColor3 = color or C.sub
    statusDot.TextColor3 = color or C.gold
end

local function makeBtn(size, pos, textStr, textSize, base)
    local btn = Instance.new("TextButton")
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = base or C.panel
    btn.BorderSizePixel = 0
    btn.Text = textStr
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = textSize or 13
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = btn
    btn.MouseEnter:Connect(function()
        btn.BackgroundTransparency = 0.25
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundTransparency = 0
    end)
    btn.Parent = card
    return btn
end

local getBtn = makeBtn(UDim2.new(0, 166, 0, 44), UDim2.new(0, 24, 0, 224), "GET KEY", 13, C.green)
getBtn.TextColor3 = Color3.fromRGB(8, 12, 20)
local getGrad = Instance.new("UIGradient")
getGrad.Color = ColorSequence.new(C.green, Color3.fromRGB(48, 196, 128))
getGrad.Rotation = 30
getGrad.Parent = getBtn

local copyBtn = makeBtn(UDim2.new(0, 166, 0, 44), UDim2.new(0, 190, 0, 224), "COPY LINK", 12)
local copyStroke = Instance.new("UIStroke")
copyStroke.Color = C.border
copyStroke.Thickness = 1
copyStroke.Parent = copyBtn

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(0, 332, 0, 46)
keyBox.Position = UDim2.new(0, 24, 0, 284)
keyBox.BackgroundColor3 = Color3.fromRGB(10, 14, 23)
keyBox.BorderSizePixel = 0
keyBox.PlaceholderText = "Paste your key here..."
keyBox.PlaceholderColor3 = C.sub
keyBox.Text = ""
keyBox.TextColor3 = C.text
keyBox.TextSize = 13
keyBox.Font = Enum.Font.GothamMedium
keyBox.ClearTextOnFocus = false
local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 12)
boxCorner.Parent = keyBox
local boxStroke = Instance.new("UIStroke")
boxStroke.Color = C.border
boxStroke.Thickness = 1
boxStroke.Parent = keyBox
keyBox.Parent = card

keyBox.Focused:Connect(function()
    boxStroke.Color = C.green
    boxStroke.Thickness = 1.5
end)
keyBox.FocusLost:Connect(function()
    boxStroke.Color = C.border
    boxStroke.Thickness = 1
end)

local activateBtn = makeBtn(UDim2.new(0, 332, 0, 48), UDim2.new(0, 24, 0, 346), "ACTIVATE", 14, C.violet)
local actGrad = Instance.new("UIGradient")
actGrad.Color = ColorSequence.new(C.violet, Color3.fromRGB(88, 72, 220))
actGrad.Rotation = 30
actGrad.Parent = activateBtn

text(card, "Keys are hardware-bound · One key = one PC", 9, Enum.Font.Gotham, C.sub, UDim2.new(0, 24, 0, 408), 332, 18)
text(card, "Protected by JNkie", 9, Enum.Font.GothamMedium, Color3.fromRGB(105, 115, 140), UDim2.new(0, 0, 0, 452), 380, 18)

local dragBar = Instance.new("Frame")
dragBar.Size = UDim2.new(1, 0, 0, 62)
dragBar.BackgroundTransparency = 1
dragBar.Parent = card

local dragging = false
local dragOffset = Vector2.new()
dragBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragOffset = Vector2.new(input.Position.X, input.Position.Y) - Vector2.new(card.AbsolutePosition.X, card.AbsolutePosition.Y)
    end
end)
uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
uis.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        card.Position = UDim2.new(0, input.Position.X - dragOffset.X, 0, input.Position.Y - dragOffset.Y)
    end
end)

local glow = 0
local breath = task.spawn(function()
    while true do
        glow = (glow + 0.025) % 1
        cardStroke.Transparency = 0.55 + math.sin(glow * math.pi * 2) * 0.2
        task.wait(0.03)
    end
end)

local busy = false
local dots = 0
local function ellipsis()
    dots = dots + 1
    return string.rep(".", (dots % 3) + 1)
end

local function shake()
    local base = card.Position
    task.spawn(function()
        for _, dx in ipairs({ 7, -7, 5, -5, 3, 0 }) do
            card.Position = UDim2.new(base.X.Scale, base.X.Offset + dx, base.Y.Scale, base.Y.Offset)
            task.wait(0.03)
        end
        card.Position = base
    end)
end

local function openLink()
    local link, err = Junkie.get_key_link()
    if not link then
        setStatus(err == "RATE_LIMITTED" and "Wait ~5 min between link requests" or ("Error: " .. tostring(err or "unavailable")), C.red)
        shake()
        return nil
    end
    clipboard(link)
    return link
end

local function fetchLink(initial)
    if busy then return end
    busy = true
    setStep(1)
    setStatus("Opening secure link" .. ellipsis(), C.sub)
    task.spawn(function()
        if openLink() then
            setStep(2)
            setStatus("Link copied to clipboard — open it to get your key", C.green)
        end
        busy = false
    end)
end

getBtn.MouseButton1Click:Connect(function()
    fetchLink()
end)
copyBtn.MouseButton1Click:Connect(function()
    if busy then return end
    busy = true
    setStatus("Reopening link...", C.sub)
    task.spawn(function()
        if openLink() then
            setStatus("Link copied again — open it to get your key", C.green)
        end
        busy = false
    end)
end)

activateBtn.MouseButton1Click:Connect(function()
    if busy then return end
    local key = keyBox.Text:gsub("%s", "")
    if #key == 0 then
        setStatus("Paste your key first, then press ACTIVATE", C.gold)
        boxStroke.Color = C.gold
        shake()
        return
    end
    busy = true
    setStep(3)
    setStatus("Validating key" .. ellipsis(), C.sub)
    task.spawn(function()
        local res = Junkie.check_key(key)
        if not res or not res.valid then
            local msg = (res and (res.error or res.message)) or "Invalid key"
            busy = false
            setStatus("Error: " .. tostring(msg), C.red)
            shake()
            if msg == "HWID_BANNED" then
                pcall(function() player:Kick("Hardware banned") end)
            end
            return
        end
        getgenv().SCRIPT_KEY = key
        local premium = getgenv().JD_IS_PREMIUM == true
        setStatus(premium and "PREMIUM key activated — loading farm..." or "Key activated — loading farm...", C.green)
        print("[GolfFarm] Key validated | Premium:", tostring(premium))
        task.wait(0.6)
        gui:Destroy()
        loadstring(game:HttpGet(SCRIPT_URL))()
    end)
end)

keyBox.FocusLost:Connect(function(enter)
    if enter then activateBtn.MouseButton1Click:Fire() end
end)

task.spawn(function()
    task.wait(0.8)
    fetchLink(true)
end)