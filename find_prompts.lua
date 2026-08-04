for _, v in ipairs(workspace:GetDescendants()) do
    if v:IsA("ProximityPrompt") then
        print("PROMPT:", v.Parent.Name, "| Objeto:", v.Parent.Parent and v.Parent.Parent.Name)
    end
end
