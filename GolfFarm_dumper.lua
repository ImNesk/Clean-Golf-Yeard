local lines = {}

local function add(msg)
    table.insert(lines, msg)
end

add("== WORKSPACE (nivel 1) ==")
for _, v in ipairs(workspace:GetChildren()) do
    local n = #v:GetChildren()
    add(v.ClassName .. " : " .. v.Name .. "  [" .. n .. " hijos]")
end

add("")
add("== REPLICATEDSTORAGE ==")
local function walk(root, depth)
    if depth > 8 then return end
    for _, v in ipairs(root:GetChildren()) do
        add(string.rep("  ", depth) .. v.ClassName .. " : " .. v.Name)
        walk(v, depth + 1)
    end
end
walk(game.ReplicatedStorage, 0)

add("")
add("== REMOTES ==")
for _, v in ipairs(game.ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("UnreliableRemoteEvent") then
        add(v.ClassName .. " : " .. v.Name .. "  [padre: " .. v.Parent.Name .. "]")
    end
end

add("")
add("== ATRIBUTOS DEL JUGADOR ==")
local plr = game.Players.LocalPlayer
for k, val in pairs(plr:GetAttributes()) do
    add(k .. " = " .. tostring(val))
end

local text = table.concat(lines, "\n")
print("[Dumper] Lineas: " .. #lines)
local okw = pcall(function()
    writefile("golffarm_dump.txt", text)
end)
print("[Dumper] writefile: " .. tostring(okw))
if not okw then
    print(text)
end
