local lines = {}
local function add(s)
    table.insert(lines, tostring(s))
end
local function flush()
    writefile("ys_dump.txt", table.concat(lines, "\n"))
end

local player = game.Players.LocalPlayer
add("== WORKSPACE (nivel 1-2) ==")
local function rec(container, depth, maxDepth)
    if depth > maxDepth then return end
    for _, child in ipairs(container:GetChildren()) do
        add(string.rep("  ", depth) .. child.ClassName .. " : " .. child.Name .. (child:IsA("Model") or child:IsA("Folder") or child:IsA("Tool") or child:IsA("Part") or child:IsA("Model") and (#child:GetChildren() > 0) and "  [" .. #child:GetChildren() .. " hijos]" or ""))
        rec(child, depth + 1, maxDepth)
    end
end
rec(workspace, 1, 2)

add("")
add("== NPCs / MODELOS CON DINERO (nivel 1) ==")
for _, child in ipairs(workspace:GetChildren()) do
    if child:IsA("Model") and not child:IsA("RigidConstraint") then
        local hasHumanoid = child:FindFirstChildOfClass("Humanoid")
        local tag = hasHumanoid and "[NPC] " or "[Modelo] "
        add(tag .. child.Name)
    end
end

add("")
add("== REPLICATEDSTORAGE (nivel 1-2) ==")
rec(game.ReplicatedStorage, 1, 2)

add("")
add("== TODOS LOS REMOTES ==")
local function recRemotes(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") or child:IsA("BindableEvent") or child:IsA("BindableFunction") then
            add(child.ClassName .. " : " .. child:GetFullName())
        end
        recRemotes(child)
    end
end
recRemotes(game.ReplicatedStorage)

add("")
add("== ATRIBUTOS DEL JUGADOR ==")
local attrs = {}
for name, value in pairs(player:GetAttributes()) do
    table.insert(attrs, name .. " = " .. tostring(value))
end
table.sort(attrs)
for _, a in ipairs(attrs) do
    add(a)
end

add("")
add("== LEADERSTATS ==")
local ls = player:FindFirstChild("leaderstats")
if ls then
    for _, v in ipairs(ls:GetChildren()) do
        add(v.ClassName .. " : " .. v.Name .. " = " .. tostring(v.Value))
    end
else
    add("sin leaderstats")
end

add("")
add("== PLAYERGUI (nivel 1-2) ==")
local pg = player:FindFirstChild("PlayerGui")
if pg then
    rec(pg, 1, 2)
end

flush()
print("[YSDump] listo -> ys_dump.txt")
