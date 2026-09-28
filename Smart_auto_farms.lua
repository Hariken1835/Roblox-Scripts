if _G.UltimateGuiLoaded then return end
_G.UltimateGuiLoaded = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    humanoid = newChar:WaitForChild("Humanoid")
end)

local isAutoFarm = false
local isFly = false
local scanRadius = 200
local farmSpeed = 100
local flySpeed = 500
local flyConnection
local noclipConnection

-- Tạo GUI tổng hợp
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "UltimateGui"
screenGui.ResetOnSpawn = false

-- Khung chính chứa toàn bộ giao diện
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 240, 0, 115)
mainFrame.Position = UDim2.new(0.5, -120, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 32, 35)
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)
local uiStroke = Instance.new("UIStroke", mainFrame)
uiStroke.Color = Color3.fromRGB(50, 50, 50)
uiStroke.Thickness = 1

-- 1. Thanh tiêu đề (Dùng để kéo thả GUI và chứa nút X)
local dragBar = Instance.new("Frame", mainFrame)
dragBar.Size = UDim2.new(1, 0, 0, 35)
dragBar.BackgroundTransparency = 1

local dragLabel = Instance.new("TextLabel", dragBar)
dragLabel.Size = UDim2.new(1, -35, 1, 0)
dragLabel.Position = UDim2.new(0, 10, 0, 0)
dragLabel.BackgroundTransparency = 1
dragLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
dragLabel.TextSize = 12
dragLabel.Font = Enum.Font.GothamBold
dragLabel.Text = "Kéo để di chuyển GUI"
dragLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Nút X tắt hẳn script
local closeBtn = Instance.new("TextButton", dragBar)
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -28, 0.5, -12)
closeBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "X"
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- 2. Nút Smart Auto Farm (Dòng giữa)
local farmBtn = Instance.new("TextButton", mainFrame)
farmBtn.Size = UDim2.new(1, -16, 0, 32)
farmBtn.Position = UDim2.new(0, 8, 0, 38)
farmBtn.BackgroundColor3 = Color3.fromRGB(44, 46, 51)
farmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
farmBtn.TextSize = 13
farmBtn.Font = Enum.Font.GothamBold
farmBtn.Text = "Smart Auto Farm: OFF"
Instance.new("UICorner", farmBtn).CornerRadius = UDim.new(0, 6)

-- 3. Nút Fly + Noclip (Dòng dưới cùng)
local flyBtn = Instance.new("TextButton", mainFrame)
flyBtn.Size = UDim2.new(1, -16, 0, 32)
flyBtn.Position = UDim2.new(0, 8, 0, 75)
flyBtn.BackgroundColor3 = Color3.fromRGB(44, 46, 51)
flyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
flyBtn.TextSize = 13
flyBtn.Font = Enum.Font.GothamBold
flyBtn.Text = "Fly + Noclip: OFF"
Instance.new("UICorner", flyBtn).CornerRadius = UDim.new(0, 6)

--// Logic kéo thả cửa sổ GUI
local dragging, dragInput, dragStart, startPos

dragBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end)

--// Logic Fly + Xuyên tường (Noclip) tích hợp
local function toggleFly(state)
    isFly = state
    if isFly then
        flyBtn.Text = "Fly + Noclip: ON"
        flyBtn.TextColor3 = Color3.fromRGB(88, 101, 242)
        if humanoid then humanoid.PlatformStand = true end
        
        noclipConnection = RunService.Stepped:Connect(function()
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        
        flyConnection = RunService.RenderStepped:Connect(function(dt)
            if not rootPart or not workspace.CurrentCamera then return end
            local cam = workspace.CurrentCamera
            local moveDir = Vector3.new(0,0,0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
            
            rootPart.Velocity = moveDir * flySpeed
            rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + cam.CFrame.LookVector)
        end)
    else
        flyBtn.Text = "Fly + Noclip: OFF"
        flyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        if flyConnection then flyConnection:Disconnect() end
        if noclipConnection then noclipConnection:Disconnect() end
        
        if humanoid then humanoid.PlatformStand = false end
        if rootPart then rootPart.Velocity = Vector3.new(0,0,0) end
        
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

--// Hàm quét danh sách quái (Đã lọc sạch NPC máu 100)
local function scanMobs()
    local mobsList = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            local isPlayer = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character == obj then isPlayer = true break end
            end
            
            if not isPlayer then
                local h = obj.Humanoid
                local r = obj.HumanoidRootPart
                local dist = (rootPart.Position - r.Position).Magnitude
                if dist <= scanRadius and h.Health > 0 and h.MaxHealth ~= 100 then
                    table.insert(mobsList, obj)
                end
            end
        end
    end
    return mobsList
end

--// Hàm Tween Teleport đến quái (Đã nâng trục Y lên 10 đơn vị để không bị dính vào thân quái)
local function tweenToTarget(targetPart)
    if not rootPart or not targetPart then return end
    local dist = (rootPart.Position - targetPart.Position).Magnitude
    local timeToTravel = dist / farmSpeed
    
    -- Trục Y = 10 giúp nhân vật đứng lơ lửng trên đầu, không sợ bị dính/kẹt vào quái
    local targetCFrame = targetPart.CFrame + Vector3.new(0, 10, 0)
    local tween = TweenService:Create(rootPart, TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    tween:Play()
    
    local completed = false
    local conn
    conn = tween.Completed:Connect(function() completed = true if conn then conn:Disconnect() end end)
    while not completed and isAutoFarm do task.wait(0.05) end
    if not isAutoFarm then tween:Cancel() end
end

--// Vòng lặp Auto Click ngầm
task.spawn(function()
    while _G.UltimateGuiLoaded do
        if isAutoFarm then
            pcall(function()
                VirtualUser:Button1Down(Vector2.new(0,0))
                task.wait(0.02)
                VirtualUser:Button1Up(Vector2.new(0,0))
            end)
            task.wait(0.08)
        else
            task.wait(0.2)
        end
    end
end)

--// Vòng lặp Smart Auto Farm (Bám sát đỉnh đầu quái)
task.spawn(function()
    while _G.UltimateGuiLoaded do
        if isAutoFarm then
            local currentMobs = scanMobs()
            if #currentMobs > 0 then
                for _, mob in ipairs(currentMobs) do
                    if not isAutoFarm or not _G.UltimateGuiLoaded then break end
                    if mob and mob.Parent and mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") then
                        local h = mob.Humanoid
                        local r = mob.HumanoidRootPart
                        
                        tweenToTarget(r)
                        
                        while isAutoFarm and _G.UltimateGuiLoaded and mob.Parent ~= nil and h.Health > 0 do
                            if rootPart and r then 
                                rootPart.CFrame = r.CFrame + Vector3.new(0, 10, 0) -- Giữ khoảng cách trên đầu quái
                            end
                            task.wait(0.1)
                        end
                        task.wait(0.3)
                    end
                end
            else
                task.wait(1)
            end
        else
            task.wait(0.2)
        end
    end
end)

--// Sự kiện nút Smart Auto Farm
farmBtn.MouseButton1Click:Connect(function()
    isAutoFarm = not isAutoFarm
    if isAutoFarm then
        farmBtn.Text = "Smart Auto Farm: ON"
        farmBtn.TextColor3 = Color3.fromRGB(88, 101, 242)
    else
        farmBtn.Text = "Smart Auto Farm: OFF"
        farmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

--// Sự kiện nút Fly + Noclip
flyBtn.MouseButton1Click:Connect(function()
    toggleFly(not isFly)
end)

--// Sự kiện nút X tắt hẳn script
closeBtn.MouseButton1Click:Connect(function()
    isAutoFarm = false
    toggleFly(false)
    _G.UltimateGuiLoaded = nil
    screenGui:Destroy()
end)
