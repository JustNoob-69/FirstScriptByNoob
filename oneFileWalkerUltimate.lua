local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local cfgPath = "TweensCFG1.json"

local function DeleteOld()
    for _, name in ipairs({"Board", "WalkerSpheres", "ClimbBars"}) do
        local obj = workspace:FindFirstChild(name)
        if obj then obj:Destroy() end
    end
end

local function LoadPath(path)
    if not isfile or not readfile then return nil end
    if not isfile(path) then return nil end
    local raw = readfile(path)
    local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok or type(data.position) ~= "table" then return nil end

    DeleteOld()
    local points = {}
    local folder = Instance.new("Folder", workspace)
    folder.Name = "WalkerSpheres"

    for i, p in ipairs(data.position) do
        local vec = Vector3.new(p.X, p.Y, p.Z)
        table.insert(points, vec)
        local dot = Instance.new("Part", folder)
        dot.Shape = Enum.PartType.Ball
        dot.Anchored = true
        dot.CanCollide = false
        dot.Size = Vector3.new(1.5, 1.5, 1.5)
        dot.Position = vec
        dot.Color = Color3.new(1, 0, 0)
        dot.Transparency = 0.25
        dot.Name = "WalkerDot_" .. i
    end

    return points
end

local function AutoFindSegments(points, threshold)
    local segments = {}
    for i = 1, #points - 1 do
        if math.abs(points[i].Y - points[i+1].Y) > threshold then
            table.insert(segments, {i, i+1})
        end
    end
    return segments
end

local function CreateClimbBars(points, segments)
    local folder = Instance.new("Folder", workspace)
    folder.Name = "ClimbBars"
    for _, seg in ipairs(segments) do
        local p1, p2 = points[seg[1]], points[seg[2]]
        local mid = (p1 + p2) / 2
        local dist = (p1 - p2).Magnitude
        local bar = Instance.new("Part", folder)
        bar.Anchored = true
        bar.CanCollide = true
        bar.Size = Vector3.new(0.5, 0.5, dist)
        bar.Material = Enum.Material.Wood
        bar.Color = Color3.fromRGB(150, 100, 50)
        bar.CFrame = CFrame.new(mid, p2)
    end
end

local function WalkPath(points)
    local lp = Players.LocalPlayer
    local char = lp.Character or lp.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    hum.WalkSpeed = _G.speed
    for _, pos in ipairs(points) do
        hum:MoveTo(pos + Vector3.new(0, _G.height, 0))
        hum.MoveToFinished:Wait()
        task.wait(0.1)
    end
end

local function EnableMountainClimber()
    local lp = Players.LocalPlayer
    local function applyProps(char)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name:lower():find("leg") then
                part.CustomPhysicalProperties = PhysicalProperties.new(2, 0.3, 1, 1, 1)
            end
        end
    end
    if lp.Character then applyProps(lp.Character) end
    lp.CharacterAdded:Connect(applyProps)
end

local function AutoAttack()
    local lp = Players.LocalPlayer
    local char = lp.Character or lp.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    while _G.autoAttack do
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj.Name ~= lp.Name then
                local part = obj.PrimaryPart
                if part and (part.Position - root.Position).Magnitude < 15 then
                    obj.Humanoid:TakeDamage(10)
                end
            end
        end
        task.wait(0.7)
    end
end

local dropList = {"Stone", "Wood", "Iron"}
local function AutoDrop()
    local lp = Players.LocalPlayer
    while _G.autoDrop do
        for _, item in ipairs(lp.Backpack:GetChildren()) do
            if item:IsA("Tool") and table.find(dropList, item.Name) then
                item.Parent = workspace
                if item:FindFirstChild("Handle") then
                    item.Handle.CFrame = lp.Character.HumanoidRootPart.CFrame * CFrame.new(0, -3, 0)
                end
            end
        end
        task.wait(2)
    end
end

local function AutoHeal()
    local lp = Players.LocalPlayer
    local hum = (lp.Character or lp.CharacterAdded:Wait()):WaitForChild("Humanoid")
    while _G.autoHeal do
        if hum.Health < hum.MaxHealth then
            hum.Health = hum.Health + 2
        end
        task.wait(1)
    end
end

local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
gui.Name = "WalkerPanel"
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 240, 0, 500)
frame.Position = UDim2.new(0, 12, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.2
frame.Active = true
frame.Draggable = true

local function addButton(text, y, callback)
    local b = Instance.new("TextButton", frame)
    b.Position = UDim2.new(0, 10, 0, y)
    b.Size = UDim2.new(1, -20, 0, 30)
    b.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 16
    b.Text = text
    b.MouseButton1Click:Connect(callback)
end

local function addSlider(label, min, max, default, y, callback)
    local t = Instance.new("TextLabel", frame)
    t.Position = UDim2.new(0, 10, 0, y)
    t.Size = UDim2.new(1, -20, 0, 20)
    t.BackgroundTransparency = 1
    t.TextColor3 = Color3.new(1, 1, 1)
    t.Font = Enum.Font.SourceSans
    t.TextSize = 14
    t.Text = label .. ": " .. default

    local s = Instance.new("TextButton", frame)
    s.Position = UDim2.new(0, 10, 0, y + 20)
    s.Size = UDim2.new(1, -20, 0, 20)
    s.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    s.Text = ""

    s.MouseButton1Down:Connect(function()
        local conn
        conn = RunService.RenderStepped:Connect(function()
            local mouse = game:GetService("UserInputService"):GetMouseLocation()
            local rel = math.clamp(mouse.X - s.AbsolutePosition.X, 0, s.AbsoluteSize.X)
            local val = min + (max - min) * (rel / s.AbsoluteSize.X)
            callback(val)
            t.Text = label .. ": " .. string.format("%.1f", val)
        end)
        game:GetService("UserInputService").InputEnded:Wait()
        conn:Disconnect()
    end)
    callback(default)
end

addSlider("Скорость", 5, 24, 16, 10, function(v) _G.speed = v end)
addSlider("Высота", 0, 6, 0, 60, function(v) _G.height = v end)

addButton("Удалить всё", 100, DeleteOld)
addButton("Загрузить путь", 140, function() _G.walkPts = LoadPath(cfgPath) end)
addButton("Начать движение", 180, function() if _G.walkPts then task.spawn(WalkPath, _G.walkPts) end end)
addButton("Включить антискольжение", 220, EnableMountainClimber)
addButton("Автоатака NPC", 260, function() _G.autoAttack = not _G.autoAttack if _G.autoAttack then task.spawn(AutoAttack) end end)
addButton("Автодроп ресурсов", 300, function() _G.autoDrop = not _G.autoDrop if _G.autoDrop then task.spawn(AutoDrop) end end)
addButton("Автолечение", 340, function() _G.autoHeal = not _G.autoHeal if _G.autoHeal then task.spawn(AutoHeal) end end)
addButton("Построить балки", 380, function()
    if _G.walkPts then
        local segs = AutoFindSegments(_G.walkPts, 4)
        CreateClimbBars(_G.walkPts, segs)
    end
end)
