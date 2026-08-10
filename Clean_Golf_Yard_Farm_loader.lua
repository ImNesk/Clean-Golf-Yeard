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
local tween = game:GetService("TweenService")
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
    bg = Color3.fromRGB(9, 12, 20),
    card = Color3.fromRGB(16, 21, 34),
    panel = Color3.fromRGB(24, 31, 48),
    border = Color3.fromRGB(52, 62, 88),
    text = Color3.fromRGB(240, 246, 255),
    sub = Color3.fromRGB(148, 160, 185),
    green = Color3.fromRGB(70, 230, 150),
    violet = Color3.fromRGB(140, 110, 255),
    gold = Color3.fromRGB(255, 200, 90),
    red = Color3.fromRGB(255, 95, 105),
}

local gui = Instance.new("ScreenGui")
gui.Name = "GolfFarmKey"
gui.ResetOnSpawn = false
gui.Parent = playerGui
gui.IgnoreGuiInset = true
gui.DisplayOrder = 500

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = C.bg
backdrop.BackgroundTransparency = 0.55
backdrop.Parent = gui

local card = Instance.new("Frame")
card.Name = "Card"
card.Size = UDim2.new(0, 368, 0, 470)
card.Position = UDim2.new(0.5, -184, 0.5, -235)
card.BackgroundColor3 = C.card
card.BorderSizePixel = 0
card.BackgroundTransparency = 0.06
card.ClipsDescendants = true
card.Parent = gui

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 22)
cardCorner.Parent = card

local cardGrad = Instance.new("UIGradient")
cardGrad.Color = ColorSequence.new(
    Color3.fromRGB(20, 26, 42),
    Color3.fromRGB(15, 18, 30)
)
cardGrad.Rotation = 45
cardGrad.Parent = card

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = C.border
cardStroke.Thickness = 1
cardStroke.Transparency = 0.35
cardStroke.Parent = card

local bottomGlow = Instance.new("Frame")
bottomGlow.Size = UDim2.new(1, 0, 0, 90)
bottomGlow.Position = UDim2.new(0, 0, 1, 0)
bottomGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
bottomGlow.BorderSizePixel = 0
local glowGrad = Instance.new("UIGradient")
glowGrad.Color = ColorSequence.new(
    Color3.fromRGB(70, 230, 150),
    Color3.fromRGB(140, 110, 255),
    Color3.fromRGB(255, 130, 220)
)
glowGrad.Rotation = 60
glowGrad.Transparency = ColorSequence.new(
    ColorSequenceKeypoint.new(0, 1),
    ColorSequenceKeypoint.new(0.55, 1),
    ColorSequenceKeypoint.new(1, 0.35)
)
glowGrad.Parent = bottomGlow
bottomGlow.Parent = card

local function newText(parent, text, size, font, color, pos, anchor)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, size + 12)
    lbl.Position = pos
    lbl.AnchorPoint = anchor or Vector2.new(0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or C.text
    lbl.TextSize = size
    lbl.Font = font or Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.Parent = parent
    return lbl
end

local title1 = Instance.new("TextLabel")
title1.Size = UDim2.new(0, 170, 0, 40)
title1.Position = UDim2.new(0, 24, 0, 24)
title1.BackgroundTransparency = 1
title1.Text = "GOLF YARD"
title1.TextColor3 = C.text
title1.TextSize = 24
title1.Font = Enum.Font.GothamBold
title1.TextXAlignment = Enum.TextXAlignment.Left
title1.Parent = card

local farmLbl = Instance.new("TextLabel")
farmLbl.Size = UDim2.new(0, 90, 0, 40)
farmLbl.Position = UDim2.new(0, 174, 0, 24)
farmLbl.BackgroundTransparency = 1
farmLbl.Text = "FARM"
farmLbl.TextSize = 24
farmLbl.Font = Enum.Font.GothamBold
farmLbl.TextXAlignment = Enum.TextXAlignment.Left
farmLbl.Parent = card
local farmAccent = Instance.new("UIGradient")
farmAccent.Color = ColorSequence.new(C.green, C.violet)
farmAccent.Rotation = 20
farmAccent.Parent = farmLbl

local subLbl = newText(card, "PREMIUM KEY VALIDATION", 11, Enum.Font.GothamMedium, C.sub, UDim2.new(0, 0, 0, 62))

local versionTag = Instance.new("Frame")
versionTag.Size = UDim2.new(0, 42, 0, 20)
versionTag.Position = UDim2.new(1, -56, 0, 26)
versionTag.BackgroundColor3 = C.panel
versionTag.BorderSizePixel = 0
local vCorner = Instance.new("UICorner")
vCorner.CornerRadius = UDim.new(1, 0)
vCorner.Parent = versionTag
newText(versionTag, "v1.0", 10, Enum.Font.GothamBold, C.gold, UDim2.new(0, 0, 0, 0))
versionTag.Parent = card

local steps = {}
local stepLabels = { "GET KEY", "PASTE KEY", "ACTIVATE" }
do
    local y = 100
    for i = 1, 3 do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 22, 0, 22)
        dot.Position = UDim2.new(0, (366 / 3) * (i - 1) + (366 / 3) / 2 - 11, 0, y - 11)
        dot.BackgroundColor3 = C.panel
        dot.BorderSizePixel = 0
        local dCorner = Instance.new("UICorner")
        dCorner.CornerRadius = UDim.new(1, 0)
        dCorner.Parent = dot
        local dStroke = Instance.new("UIStroke")
        dStroke.Color = C.border
        dStroke.Thickness = 1
        dStroke.Parent = dot
        local num = newText(dot, tostring(i), 11, Enum.Font.GothamBold, C.sub, UDim2.new(0, 0, 0, 0))
        dot.Parent = card
        steps[i] = { dot = dot, stroke = dStroke, num = num, active = false }

        local lbl = newText(card, stepLabels[i], 9, Enum.Font.GothamMedium, C.sub, UDim2.new(0, (366 / 3) * (i - 1) - 40, 0, y + 16), Vector2.new(0.5, 0))
        lbl.Size = UDim2.new(0, 160, 0, 20)

        if i > 1 then
            local line = Instance.new("Frame")
            line.Size = UDim2.new(0, 76, 0, 2)
            line.Position = UDim2.new(0, (366 / 3) * (i - 2) + (366 / 3) / 2 + 7, 0, y - 1)
            line.BackgroundColor3 = C.border
            line.BorderSizePixel = 0
            line.Parent = card
            steps[i].line = line
        end
    end
end

local function setStep(step)
    for i, s in ipairs(steps) do
        local on = i <= step
        s.dot.BackgroundColor3 = on and C.green or C.panel
        s.stroke.Color = on and C.green or C.border
        s.stroke.Thickness = on and 1.5 or 1
        s.num.TextColor3 = on and Color3.fromRGB(9, 12, 20) or C.sub
        if s.line then
            s.line.BackgroundColor3 = i <= step and C.green or C.border
        end
        s.active = on
    end
end

local status = newText(card, "Your key link is being prepared...", 11, Enum.Font.Gotham, C.sub, UDim2.new(0, 24, 0, 148))
status.Size = UDim2.new(1, -48, 0, 34)
status.TextWrapped = true
status.TextYAlignment = Enum.TextYAlignment.Top

local dotFlash = newText(card, "●", 9, Enum.Font.GothamBold, C.gold, UDim2.new(0, 24, 0, 146))
dotFlash.TextXAlignment = Enum.TextXAlignment.Left

local function setStatus(text, color, step)
    status.Text = text
    status.TextColor3 = color or C.sub
    if step then setStep(step) end
end

local function makeButton(size, pos, bg, text, textSize)
    local btn = Instance.new("TextButton")
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = bg
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = textSize or 13
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = btn
    btn.Parent = card
    return btn
end

local getBtn = makeButton(UDim2.new(0, 166, 0, 42), UDim2.new(0, 24, 0, 196), C.green, "GET KEY", 13)
local getGrad = Instance.new("UIGradient")
getGrad.Color = ColorSequence.new(C.green, Color3.fromRGB(50, 200, 130))
getGrad.Rotation = 30
getGrad.Parent = getBtn
getBtn.TextColor3 = Color3.fromRGB(9, 12, 20)

local copyBtn = makeButton(UDim2.new(0, 154, 0, 42), UDim2.new(0, 202, 0, 196), C.panel, "COPY LINK", 12)
local copyStroke = Instance.new("UIStroke")
copyStroke.Color = C.border
copyStroke.Thickness = 1
copyStroke.Parent = copyBtn

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(1, -48, 0, 44)
keyBox.Position = UDim2.new(0, 24, 0, 250)
keyBox.BackgroundColor3 = Color3.fromRGB(11, 15, 25)
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

keyBox.FocusLost:Connect(function(enter)
    if enter then
        boxStroke.Color = C.border
    end
end)
keyBox.Focused:Connect(function()
    boxStroke.Color = C.green
    boxStroke.Thickness = 1.5
end)

local activateBtn = makeButton(UDim2.new(1, -48, 0, 46), UDim2.new(0, 24, 0, 306), C.violet, "ACTIVATE", 14)
local actGrad = Instance.new("UIGradient")
actGrad.Color = ColorSequence.new(C.violet, Color3.fromRGB(90, 75, 220))
actGrad.Rotation = 30
actGrad.Parent = activateBtn

local hint = newText(card, "Keys are bound to your hardware · One key = one PC", 9, Enum.Font.Gotham, C.sub, UDim2.new(0, 24, 0, 364))
hint.Size = UDim2.new(1, -48, 0, 20)
hint.TextWrapped = true

local footer = newText(card, "Protected by JNkie", 9, Enum.Font.GothamMedium, Color3.fromRGB(110, 120, 145), UDim2.new(0, 0, 0, 438))

do
    local spin = 0
    local glow = 0
    task.spawn(function()
        while true do
            spin = spin + 0.02
            glow = (glow + 0.03) % 1
            bottomGlow.Position = UDim2.new(0, 0, 1, 0)
            local trans = 0.35 + math.sin(glow * math.pi * 2) * 0.12
            cardStroke.Transparency = trans
            card.ClipsDescendants = true
            task.wait(0.03)
        end
    end)
end

local dragging = false
local dragOffset = Vector2.new()
local function startDrag(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragOffset = Vector2.new(input.Position.X, input.Position.Y) - Vector2.new(card.AbsolutePosition.X, card.AbsolutePosition.Y)
    end
end
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 60)
titleBar.BackgroundTransparency = 1
titleBar.Parent = card
titleBar.InputBegan:Connect(startDrag)
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

local busy = false
local dots = 0
local function busyDots()
    dots = dots + 1
    return string.rep(".", (dots % 3) + 1)
end

local function shake()
    local start = card.Position
    task.spawn(function()
        for _, dx in ipairs({ 6, -6, 4, -4, 2, 0 }) do
            card.Position = UDim2.new(start.X.Scale, start.X.Offset + dx, start.Y.Scale, start.Y.Offset)
            task.wait(0.03)
        end
    end)
end

local function fetchLink()
    if busy then return end
    busy = true
    setStep(1)
    setStatus("Opening secure link" .. busyDots(), C.sub)
    task.spawn(function()
        local link, err = Junkie.get_key_link()
        if not link then
            busy = false
            if err == "RATE_LIMITTED" then
                setStatus("Please wait ~5 minutes between link requests", C.gold)
            else
                setStatus("Error: " .. tostring(err or "unavailable"), C.red)
            end
            shake()
            return
        end
        clipboard(link)
        setStep(2)
        setStatus("Link copied to your clipboard! Open it to get your key.", C.green)
        busy = false
    end)
end

getBtn.MouseButton1Click:Connect(fetchLink)
copyBtn.MouseButton1Click:Connect(function()
    if busy then return end
    setStatus("Reopening link...", C.sub)
    local link, err = Junkie.get_key_link()
    if not link then
        setStatus(err == "RATE_LIMITTED" and "Please wait ~5 min between links" or "Error: " .. tostring(err or "unavailable"), C.red)
        shake()
        return
    end
    clipboard(link)
    setStatus("Link copied again — open it to get your key.", C.green)
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
    setStatus("Validating key" .. busyDots(), C.sub)
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
        setStatus(premium and "PREMIUM key activated. Loading farm..." or "Key activated. Loading farm...", C.green)
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
    fetchLink()
end)