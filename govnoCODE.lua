local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- cfg u can change it
local MAX_DISTANCE = 100
local MIN_SCALE = 2.6
local MAX_SCALE = 3.6
local BASE_SIZE = 70
local SMOOTH_FADE = 10
local SMOOTH_SCALE = 8
local ROT_ANGLE = 40
local ROT_SPEED = 2
local VERTICAL_OFFSET = 1.2

local PREDICTION_FACTOR = 0.45
local TP_DISTANCE = 4
local FORCE_HEIGHT = true

local character = lp.Character or lp.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

lp.CharacterAdded:Connect(function(c)
    character = c
    hrp = c:WaitForChild("HumanoidRootPart")
end)

local gui = Instance.new("ScreenGui")
gui.Name = "PredictTP"
gui.ResetOnSpawn = false
gui.Parent = lp:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 280)
frame.Position = UDim2.new(0.5, -110, 0.5, -140)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local fCorner = Instance.new("UICorner")
fCorner.CornerRadius = UDim.new(0, 10)
fCorner.Parent = frame

local fStroke = Instance.new("UIStroke")
fStroke.Color = Color3.fromRGB(60, 60, 60)
fStroke.Thickness = 1
fStroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "Predict TP"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame

local line = Instance.new("Frame")
line.Size = UDim2.new(1, 0, 0, 2)
line.Position = UDim2.new(0, 0, 0, 38)
line.BackgroundColor3 = Color3.fromRGB(41, 128, 185)
line.BorderSizePixel = 0
line.Parent = frame

local function createButton(text, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = frame
    
    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = btn
    
    return btn
end

local img = Instance.new("ImageLabel")
img.Size = UDim2.new(0, BASE_SIZE, 0, BASE_SIZE)
img.AnchorPoint = Vector2.new(0.5, 0.5)
img.BackgroundTransparency = 1
img.Image = "rbxassetid://133065276440430"
img.ImageColor3 = Color3.fromRGB(0, 0, 0)
img.Visible = false
img.ZIndex = 0
img.Parent = gui

local espEnabled = false
local tpEnabled = false

local btnEsp = createButton("Target ESP: OFF", 55)
btnEsp.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    btnEsp.Text = espEnabled and "Target ESP: ON" or "Target ESP: OFF"
    btnEsp.BackgroundColor3 = espEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
end)

local btnTp = createButton("Predict TP: OFF", 100)
btnTp.MouseButton1Click:Connect(function()
    tpEnabled = not tpEnabled
    btnTp.Text = tpEnabled and "Predict TP: ON" or "Predict TP: OFF"
    btnTp.BackgroundColor3 = tpEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
end)

local currentDistance = 50
local distLabel = Instance.new("TextLabel")
distLabel.Size = UDim2.new(1, 0, 0, 20)
distLabel.Position = UDim2.new(0, 0, 0, 145)
distLabel.BackgroundTransparency = 1
distLabel.Text = "Range: " .. currentDistance
distLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
distLabel.Font = Enum.Font.Gotham
distLabel.TextSize = 12
distLabel.Parent = frame

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(0.8, 0, 0, 4)
sliderBg.Position = UDim2.new(0.1, 0, 0, 170)
sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
sliderBg.BorderSizePixel = 0
sliderBg.Parent = frame
local sCorner = Instance.new("UICorner"); sCorner.CornerRadius = UDim.new(1,0); sCorner.Parent = sliderBg

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.2, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg
local sfCorner = Instance.new("UICorner"); sfCorner.CornerRadius = UDim.new(1,0); sfCorner.Parent = sliderFill

local sliderTrigger = Instance.new("TextButton")
sliderTrigger.Size = UDim2.new(1, 0, 2, 0)
sliderTrigger.Position = UDim2.new(0, 0, -0.5, 0)
sliderTrigger.BackgroundTransparency = 1
sliderTrigger.Text = ""
sliderTrigger.Parent = sliderBg

local isDragging = false
sliderTrigger.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = input.Position.X
        local relativePos = mousePos - sliderBg.AbsolutePosition.X
        local size = sliderBg.AbsoluteSize.X
        local clamp = math.clamp(relativePos / size, 0, 1)
        sliderFill.Size = UDim2.new(clamp, 0, 1, 0)
        currentDistance = math.floor(5 + (MAX_DISTANCE - 5) * clamp)
        distLabel.Text = "Range: " .. currentDistance
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
    end
end)

local colorCont = Instance.new("Frame")
colorCont.Size = UDim2.new(0.9, 0, 0, 20)
colorCont.Position = UDim2.new(0.05, 0, 0, 190)
colorCont.BackgroundTransparency = 1
colorCont.Parent = frame

local colors = {
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(46, 204, 113),
    Color3.fromRGB(52, 152, 219),
    Color3.fromRGB(241, 196, 15),
    Color3.fromRGB(231, 76, 60),
    Color3.fromRGB(0, 0, 0),
    Color3.fromRGB(30, 30, 30),
    Color3.fromRGB(255, 124, 115),
    Color3.fromRGB(115, 255, 232)
}

for i, col in ipairs(colors) do
    local cBtn = Instance.new("TextButton")
    cBtn.Size = UDim2.new(0, 18, 0, 37)
    cBtn.Position = UDim2.new(0, (i-1)*24, 0, 0)
    cBtn.BackgroundColor3 = col
    cBtn.Text = ""
    cBtn.Parent = colorCont
    local cCorner = Instance.new("UICorner"); cCorner.CornerRadius = UDim.new(0, 4); cCorner.Parent = cBtn
    
    cBtn.MouseButton1Click:Connect(function()
        img.ImageColor3 = col
    end)
end

local btnUnload = Instance.new("TextButton")
btnUnload.Size = UDim2.new(0.9, 0, 0, 30)
btnUnload.Position = UDim2.new(0.05, 0, 0, 235)
btnUnload.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
btnUnload.Text = "Unload GUI"
btnUnload.TextColor3 = Color3.fromRGB(200, 200, 200)
btnUnload.Font = Enum.Font.Gotham
btnUnload.TextSize = 12
btnUnload.Parent = frame
local uCorner = Instance.new("UICorner"); uCorner.CornerRadius = UDim.new(0, 6); uCorner.Parent = btnUnload

btnUnload.MouseButton1Click:Connect(function()
    gui:Destroy()
    espEnabled = false
    tpEnabled = false
    script:Destroy()
end)

local function lerp(a, b, t) return a + (b - a) * t end

local function GetNearest()
    local closest, dist = nil, currentDistance
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            local h = p.Character:FindFirstChild("Humanoid")
            if r and h and h.Health > 0 then
                local d = (r.Position - hrp.Position).Magnitude
                if d < dist then
                    closest = p
                    dist = d
                end
            end
        end
    end
    return closest, dist
end

local function TeleportLogic(target)
    if not target.Character then return end
    local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end
    
    local vel = tRoot.AssemblyLinearVelocity
    local speed = vel.Magnitude
    local factor = (speed < 2) and 0.1 or PREDICTION_FACTOR
    
    local future = tRoot.Position + (vel * factor) + (tRoot.CFrame.LookVector * 1.5)
    
    local goalCF = CFrame.lookAt(future, future + vel) * CFrame.new(0, 0, -TP_DISTANCE)
    
    if speed < 2 then
        goalCF = tRoot.CFrame * CFrame.new(0, 0, -TP_DISTANCE)
    end
    
    local finalPos = goalCF.Position
    if FORCE_HEIGHT then
        finalPos = Vector3.new(finalPos.X, tRoot.Position.Y, finalPos.Z)
    end
    
    hrp.CFrame = CFrame.lookAt(finalPos, Vector3.new(future.X, future.Y, future.Z))
    hrp.AssemblyLinearVelocity = Vector3.zero
end

local currentTransparency = 0
local currentScale = 1
local tclock = 0

RunService.RenderStepped:Connect(function(dt)
    tclock += dt * ROT_SPEED
    
    local target, dist = GetNearest()
    
    if tpEnabled and target and dist <= currentDistance then
        TeleportLogic(target)
    end
    
    local tRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local shouldBeVisible = espEnabled and tRoot and dist <= currentDistance
    
    local targetTransparency = shouldBeVisible and 0 or 1
    currentTransparency = lerp(currentTransparency, targetTransparency, dt * SMOOTH_FADE)
    img.ImageTransparency = currentTransparency
    
    if shouldBeVisible and img.ImageTransparency < 0.99 then
        local targetPos = tRoot.Position + Vector3.new(0, VERTICAL_OFFSET, 0)
        local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
        
        if onScreen then
            img.Visible = true
            img.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
            
            local alpha = math.clamp(dist / currentDistance, 0, 1)
            local targetScale = MAX_SCALE * (1 - alpha) + MIN_SCALE * alpha
            
            currentScale = lerp(currentScale, targetScale, dt * SMOOTH_SCALE)
            
            img.Size = UDim2.new(0, BASE_SIZE * currentScale, 0, BASE_SIZE * currentScale)
            img.Rotation = math.sin(tclock) * ROT_ANGLE
        else
            img.Visible = false
        end
    else
        img.Visible = false
    end
end)
