print("TEST 1: inicio")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
print("TEST 2: player = " .. tostring(player))
if player then
	local gui = Instance.new("ScreenGui")
	gui.Name = "TestGUI"
	gui.Parent = player:WaitForChild("PlayerGui")
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, 400, 0, 100)
	lbl.Position = UDim2.new(0.5, -200, 0.2, 0)
	lbl.BackgroundColor3 = Color3.new(1, 0, 0)
	lbl.Text = "GUI FUNCIONA"
	lbl.TextSize = 30
	lbl.Parent = gui
	print("TEST 3: gui creado, espera 3s...")
	task.wait(3)
	gui:Destroy()
	print("TEST 4: fin")
end
