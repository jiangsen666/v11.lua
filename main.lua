[file name]: main.txt
[file content begin]
-- 江森脚本v17终极优化版 | 完整功能增强 (修复版)
-- 修复内容：
-- 1. 完全修复飞行系统，添加精确速度控制
-- 2. 自瞄系统添加玩家选择界面
-- 3. 透视显示全地图玩家和距离
-- 4. 天线系统独立运行，范围可输入
-- 5. 防封禁系统全面增强
-- 6. 手机端全面适配

local Players, UIS, RunService, CoreGui, TS = game:GetService("Players"), game:GetService("UserInputService"), game:GetService("RunService"), game:GetService("CoreGui"), game:GetService("TweenService")
local player = Players.LocalPlayer
repeat task.wait() until player.Character
local character, humanoid, rootPart = player.Character, player.Character:WaitForChild("Humanoid"), player.Character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- [增强] 防封禁系统 (全面优化)
local antiBan = {
    active = true,
    lastClean = tick(),
    cleanInterval = math.random(20,40),
    lastRandom = tick(),
    randomInterval = math.random(10,30),
    scramble = function()
        if tick()-antiBan.lastClean > antiBan.cleanInterval then
            collectgarbage("collect")
            antiBan.lastClean = tick()
            antiBan.cleanInterval = math.random(20,40)
        end
        
        -- 随机行为伪装
        if tick()-antiBan.lastRandom > antiBan.randomInterval then
            -- 模拟正常玩家操作
            if math.random(1,10) > 7 then
                player:SetAttribute("LastActivity", tick())
            end
            antiBan.lastRandom = tick()
            antiBan.randomInterval = math.random(10,30)
        end
    end
}

-- [优化] 配置参数增强版
local config = {
    Flight = false, 
    Speed = 50, 
    VSpeed = 30,
    FlightGravity = false, -- [新增] 飞行重力开关
    FlightKeybind = Enum.KeyCode.F,
    Aimbot = false, 
    AimbotKey = "MouseButton2", 
    AimbotTarget = nil, -- [修改] 直接存储目标玩家
    AimSmoothness = 0.25,
    ESP = true, 
    Antenna = true, 
    AntennaRange = 200,
    TeleportCooldown = 3, 
    lastTeleport = 0,
    NoClip = false,
    AutoFarm = false
}

local effects = {
    antennas = {}, 
    espGuis = {}, 
    flightUI = nil, 
    teleportUI = nil,
    aimbotUI = nil, -- [新增] 自瞄UI
    rangeUI = nil,
    mainUI = nil,
    noclipConn = nil,
    flightVelocity = nil -- [新增] 飞行速度控制器
}

-- [优化] 通知函数 (手机端适配)
local function notify(title, text, duration)
    duration = duration or 3
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title, 
        Text = text, 
        Duration = duration,
        Icon = "rbxassetid://6726578260" -- 手机端兼容图标
    })
end

-- [修复] 飞行控制UI (完全重写)
local function createFlightUI()
    if effects.flightUI then effects.flightUI:Destroy() end
    
    local gui = Instance.new("ScreenGui", CoreGui)
    gui.Name = "FlightSettings_"..tostring(math.random(10000,99999)) -- 随机名称防检测
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- 手机端适配
    
    local frame = Instance.new("Frame", gui)
    frame.Size, frame.Position = UDim2.new(0.25,0,0.25,0), UDim2.new(0.01,0,0.4,0) -- 放大UI
    frame.BackgroundColor3 = Color3.fromRGB(40,50,80)
    frame.BackgroundTransparency = 0.1
    frame.Active, frame.Draggable = true, true
    frame.BorderSizePixel = 0
    
    -- [优化] UI布局增强 (手机端适配)
    local title = Instance.new("TextLabel", frame)
    title.Text = "✈️ 飞行控制 ✈️"
    title.Size, title.Position = UDim2.new(1,0,0.15,0), UDim2.new(0,0,0.05,0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.TextScaled = true -- 手机端适配

    -- [优化] 水平速度滑块 (放大触摸区域)
    local hSpeedLabel = Instance.new("TextLabel", frame)
    hSpeedLabel.Text = "水平速度: "..config.Speed
    hSpeedLabel.Size, hSpeedLabel.Position = UDim2.new(0.9,0,0.12,0), UDim2.new(0.05,0,0.2,0)
    hSpeedLabel.BackgroundTransparency = 1
    hSpeedLabel.TextScaled = true -- 手机端适配

    local hSlider = Instance.new("Frame", frame)
    hSlider.Size, hSlider.Position = UDim2.new(0.9,0,0.08,0), UDim2.new(0.05,0,0.32,0)
    hSlider.BackgroundColor3 = Color3.fromRGB(100,100,100)
    hSlider.BorderSizePixel = 0
    
    local hFill = Instance.new("Frame", hSlider)
    hFill.Size = UDim2.new(config.Speed/100,0,1,0)
    hFill.BackgroundColor3 = Color3.fromRGB(0,200,255)
    hFill.BorderSizePixel = 0
    hFill.ZIndex = 2
    
    -- [优化] 垂直速度滑块 (放大触摸区域)
    local vSpeedLabel = Instance.new("TextLabel", frame)
    vSpeedLabel.Text = "垂直速度: "..config.VSpeed
    vSpeedLabel.Size, vSpeedLabel.Position = UDim2.new(0.9,0,0.12,0), UDim2.new(0.05,0,0.42,0)
    vSpeedLabel.BackgroundTransparency = 1
    vSpeedLabel.TextScaled = true -- 手机端适配

    local vSlider = Instance.new("Frame", frame)
    vSlider.Size, vSlider.Position = UDim2.new(0.9,0,0.08,0), UDim2.new(0.05,0,0.54,0)
    vSlider.BackgroundColor3 = Color3.fromRGB(100,100,100)
    vSlider.BorderSizePixel = 0
    
    local vFill = Instance.new("Frame", vSlider)
    vFill.Size = UDim2.new(config.VSpeed/60,0,1,0)
    vFill.BackgroundColor3 = Color3.fromRGB(0,200,255)
    vFill.BorderSizePixel = 0
    vFill.ZIndex = 2
    
    -- [新增] 重力开关
    local gravityBtn = Instance.new("TextButton", frame)
    gravityBtn.Text = "重力: "..(config.FlightGravity and "开" or "关")
    gravityBtn.Size, gravityBtn.Position = UDim2.new(0.45,0,0.1,0), UDim2.new(0.05,0,0.65,0)
    gravityBtn.BackgroundColor3 = Color3.fromRGB(80,90,140)
    gravityBtn.TextScaled = true -- 手机端适配
    gravityBtn.MouseButton1Click:Connect(function()
        config.FlightGravity = not config.FlightGravity
        gravityBtn.Text = "重力: "..(config.FlightGravity and "开" or "关")
        notify("飞行重力", config.FlightGravity and "已开启" or "已关闭")
    end)
    
    -- [新增] 穿墙模式开关
    local noclipBtn = Instance.new("TextButton", frame)
    noclipBtn.Text = "穿墙: "..(config.NoClip and "开" or "关")
    noclipBtn.Size, noclipBtn.Position = UDim2.new(0.45,0,0.1,0), UDim2.new(0.5,0,0.65,0)
    noclipBtn.BackgroundColor3 = Color3.fromRGB(80,90,140)
    noclipBtn.TextScaled = true -- 手机端适配
    noclipBtn.MouseButton1Click:Connect(function()
        config.NoClip = not config.NoClip
        noclipBtn.Text = "穿墙: "..(config.NoClip and "开" or "关")
        notify("穿墙模式", config.NoClip and "已开启" or "已关闭")
    end)
    
    -- [优化] 滑块控制函数 (手机端适配)
    local function updateSlider(slider, fill, value, max, label, prefix)
        local percent = math.clamp(value/max, 0, 1)
        fill.Size = UDim2.new(percent,0,1,0)
        label.Text = prefix..": "..math.floor(value)
    end
    
    local function setupSlider(slider, fill, label, prefix, max, configValue)
        local function updateFromMouse(input)
            local percent = math.clamp(
                (input.Position.X - slider.AbsolutePosition.X)/slider.AbsoluteSize.X, 0, 1
            )
            local value = math.floor(percent * max)
            
            if prefix == "水平速度" then
                config.Speed = value
            else
                config.VSpeed = value
            end
            
            updateSlider(slider, fill, value, max, label, prefix)
        end
        
        slider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local conn; conn = RunService.Heartbeat:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then 
                        conn:Disconnect() 
                    else
                        updateFromMouse(input)
                    end
                end)
            end
        end)
        
        -- 手机端拖动手势
        slider.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                updateFromMouse(input)
            end
        end)
        
        updateSlider(slider, fill, configValue, max, label, prefix)
    end
    
    setupSlider(hSlider, hFill, hSpeedLabel, "水平速度", 100, config.Speed)
    setupSlider(vSlider, vFill, vSpeedLabel, "垂直速度", 60, config.VSpeed)
    
    effects.flightUI = gui
    return gui
end

-- [优化] 玩家选择UI (瞬移甩飞增强版)
local function createTeleportUI()
    if effects.teleportUI then effects.teleportUI:Destroy() end
    
    local gui = Instance.new("ScreenGui", CoreGui)
    gui.Name = "TeleportUI_"..tostring(math.random(10000,99999)) -- 随机名称防检测
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- 手机端适配
    
    local frame = Instance.new("Frame", gui)
    frame.Size, frame.Position = UDim2.new(0.3,0,0.6,0), UDim2.new(0.35,0,0.2,0) -- 放大UI
    frame.BackgroundColor3 = Color3.fromRGB(40,50,80)
    frame.BackgroundTransparency = 0.1
    frame.Active, frame.Draggable = true, true
    frame.BorderSizePixel = 0
    
    local title = Instance.new("TextLabel", frame)
    title.Text = "🚀 选择目标玩家 🚀"
    title.Size, title.Position = UDim2.new(1,0,0.1,0), UDim2.new(0,0,0,0)
    title.BackgroundColor3 = Color3.fromRGB(60,70,100)
    title.Font = Enum.Font.SourceSansBold
    title.TextScaled = true -- 手机端适配

    local scroll = Instance.new("ScrollingFrame", frame)
    scroll.Size, scroll.Position = UDim2.new(1,0,0.9,0), UDim2.new(0,0,0.1,0)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.ScrollBarThickness = 8 -- 手机端适配
    
    -- [新增] 玩家搜索框 (放大尺寸)
    local searchBox = Instance.new("TextBox", frame)
    searchBox.Size, searchBox.Position = UDim2.new(0.85,0,0.1,0), UDim2.new(0.075,0,0,0)
    searchBox.PlaceholderText = "搜索玩家..."
    searchBox.ClearTextOnFocus = false
    searchBox.TextScaled = true -- 手机端适配

    local function addPlayerButton(p, index)
        if p == player then return end
        
        local button = Instance.new("TextButton", scroll)
        button.Size = UDim2.new(0.95, -10, 0, 45) -- 放大按钮
        button.Position = UDim2.new(0.025,5,0,index*50) -- 增加间距
        button.Text = p.Name
        button.BackgroundColor3 = Color3.fromRGB(70,80,120)
        button.AutoButtonColor = false
        button.TextScaled = true -- 手机端适配
        
        -- [新增] 玩家距离显示
        local distanceLabel = Instance.new("TextLabel", button)
        distanceLabel.Text = "点击选择"
        distanceLabel.Size = UDim2.new(0.45,0,1,0)
        distanceLabel.Position = UDim2.new(0.55,0,0,0)
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.TextXAlignment = Enum.TextXAlignment.Right
        distanceLabel.TextScaled = true -- 手机端适配
        
        -- [优化] 实时更新距离
        local conn; conn = RunService.Heartbeat:Connect(function()
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and rootPart then
                local dist = (p.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                distanceLabel.Text = string.format("%.1f米", dist)
            else
                distanceLabel.Text = "不可见"
            end
        end)
        
        button.MouseButton1Click:Connect(function()
            if tick()-config.lastTeleport < config.TeleportCooldown then
                notify("冷却中", string.format("请等待%d秒", math.ceil(config.TeleportCooldown-(tick()-config.lastTeleport))), 2)
                return
            end
            
            if p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    -- [优化] 更流畅的瞬移效果
                    local tween = TS:Create(
                        rootPart,
                        TweenInfo.new(0.15, Enum.EasingStyle.Quad),
                        {CFrame = hrp.CFrame * CFrame.new(0,0,-2)}
                    )
                    tween:Play()
                    
                    task.wait(0.2)
                    local bv = Instance.new("BodyVelocity", hrp)
                    bv.Velocity = Vector3.new(math.random(-25,25),160,math.random(-25,25))
                    bv.MaxForce = Vector3.new(0,1e4,0)
                    game:GetService("Debris"):AddItem(bv, 0.4)
                    notify("成功", "已甩飞 "..p.Name)
                    config.lastTeleport = tick()
                    gui:Destroy()
                    conn:Disconnect()
                end
            end
        end)
        
        -- [新增] 鼠标悬停效果
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(90,100,150)
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(70,80,120)
        end)
        
        -- 手机端触摸效果
        button.TouchLongPress:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(90,100,150)
            wait(0.2)
            button.BackgroundColor3 = Color3.fromRGB(70,80,120)
        end)
        
        scroll.CanvasSize = UDim2.new(0,0,0,index*50)
        return button
    end

    -- [优化] 玩家列表生成
    local playerButtons = {}
    for i, p in pairs(Players:GetPlayers()) do
        playerButtons[p] = addPlayerButton(p, i-1)
    end

    -- [新增] 搜索功能
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local searchText = searchBox.Text:lower()
        for p, btn in pairs(playerButtons) do
            if p:IsA("Player") then
                btn.Visible = p.Name:lower():find(searchText) ~= nil or searchText == ""
            end
        end
    end)

    Players.PlayerAdded:Connect(function(p)
        playerButtons[p] = addPlayerButton(p, #Players:GetPlayers()-1)
    end)
    
    Players.PlayerRemoving:Connect(function(p)
        if playerButtons[p] then
            playerButtons[p]:Destroy()
            playerButtons[p] = nil
        end
    end)
    
    effects.teleportUI = gui
    return gui
end

-- [新增] 自瞄玩家选择UI
local function createAimbotUI()
    if effects.aimbotUI then effects.aimbotUI:Destroy() end
    
    local gui = Instance.new("ScreenGui", CoreGui)
    gui.Name = "AimbotUI_"..tostring(math.random(10000,99999)) -- 随机名称防检测
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- 手机端适配
    
    local frame = Instance.new("Frame", gui)
    frame.Size, frame.Position = UDim2.new(0.3,0,0.6,0), UDim2.new(0.35,0,0.2,0) -- 放大UI
    frame.BackgroundColor3 = Color3.fromRGB(40,50,80)
    frame.BackgroundTransparency = 0.1
    frame.Active, frame.Draggable = true, true
    frame.BorderSizePixel = 0
    
    local title = Instance.new("TextLabel", frame)
    title.Text = "🎯 选择自瞄目标 🎯"
    title.Size, title.Position = UDim2.new(1,0,0.1,0), UDim2.new(0,0,0,0)
    title.BackgroundColor3 = Color3.fromRGB(60,70,100)
    title.Font = Enum.Font.SourceSansBold
    title.TextScaled = true -- 手机端适配

    local scroll = Instance.new("ScrollingFrame", frame)
    scroll.Size, scroll.Position = UDim2.new(1,0,0.9,0), UDim2.new(0,0,0.1,0)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.ScrollBarThickness = 8 -- 手机端适配
    
    -- [新增] 玩家搜索框 (放大尺寸)
    local searchBox = Instance.new("TextBox", frame)
    searchBox.Size, searchBox.Position = UDim2.new(0.85,0,0.1,0), UDim2.new(0.075,0,0,0)
    searchBox.PlaceholderText = "搜索玩家..."
    searchBox.ClearTextOnFocus = false
    searchBox.TextScaled = true -- 手机端适配

    local function addPlayerButton(p, index)
        if p == player then return end
        
        local button = Instance.new("TextButton", scroll)
        button.Size = UDim2.new(0.95, -10, 0, 45) -- 放大按钮
        button.Position = UDim2.new(0.025,5,0,index*50) -- 增加间距
        button.Text = p.Name
        button.BackgroundColor3 = Color3.fromRGB(70,80,120)
        button.AutoButtonColor = false
        button.TextScaled = true -- 手机端适配
        
        -- [新增] 玩家距离显示
        local distanceLabel = Instance.new("TextLabel", button)
        distanceLabel.Text = "点击选择"
        distanceLabel.Size = UDim2.new(0.45,0,1,0)
        distanceLabel.Position = UDim2.new(0.55,0,0,0)
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.TextXAlignment = Enum.TextXAlignment.Right
        distanceLabel.TextScaled = true -- 手机端适配
        
        -- [优化] 实时更新距离
        local conn; conn = RunService.Heartbeat:Connect(function()
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and rootPart then
                local dist = (p.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                distanceLabel.Text = string.format("%.1f米", dist)
            else
                distanceLabel.Text = "不可见"
            end
        end)
        
        button.MouseButton1Click:Connect(function()
            config.AimbotTarget = p
            notify("自瞄目标", "已锁定: "..p.Name)
            gui:Destroy()
            conn:Disconnect()
        end)
        
        -- [新增] 鼠标悬停效果
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(90,100,150)
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(70,80,120)
        end)
        
        -- 手机端触摸效果
        button.TouchLongPress:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(90,100,150)
            wait(0.2)
            button.BackgroundColor3 = Color3.fromRGB(70,80,120)
        end)
        
        scroll.CanvasSize = UDim2.new(0,0,0,index*50)
        return button
    end

    -- [优化] 玩家列表生成
    local playerButtons = {}
    for i, p in pairs(Players:GetPlayers()) do
        playerButtons[p] = addPlayerButton(p, i-1)
    end

    -- [新增] 搜索功能
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local searchText = searchBox.Text:lower()
        for p, btn in pairs(playerButtons) do
            if p:IsA("Player") then
                btn.Visible = p.Name:lower():find(searchText) ~= nil or searchText == ""
            end
        end
    end)

    Players.PlayerAdded:Connect(function(p)
        playerButtons[p] = addPlayerButton(p, #Players:GetPlayers()-1)
    end)
    
    Players.PlayerRemoving:Connect(function(p)
        if playerButtons[p] then
            playerButtons[p]:Destroy()
            playerButtons[p] = nil
        end
    end)
    
    effects.aimbotUI = gui
    return gui
end

-- [优化] 范围调节UI (添加输入框)
local function createRangeUI()
    if effects.rangeUI then effects.rangeUI:Destroy() end
    
    local gui = Instance.new("ScreenGui", CoreGui)
    gui.Name = "RangeUI_"..tostring(math.random(10000,99999)) -- 随机名称防检测
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- 手机端适配
    
    local frame = Instance.new("Frame", gui)
    frame.Size, frame.Position = UDim2.new(0.25,0,0.14,0), UDim2.new(0.01,0,0.7,0) -- 放大UI
    frame.BackgroundColor3 = Color3.fromRGB(40,50,80)
    frame.BackgroundTransparency = 0.1
    frame.Active, frame.Draggable = true, true
    frame.BorderSizePixel = 0
    
    local title = Instance.new("TextLabel", frame)
    title.Text = "📡 天线范围: "..config.AntennaRange.."米"
    title.Size, title.BackgroundTransparency = UDim2.new(1,0,0.3,0), 1
    title.Font = Enum.Font.SourceSansBold
    title.TextScaled = true -- 手机端适配
    
    local slider = Instance.new("Frame", frame)
    slider.Size, slider.Position = UDim2.new(0.9,0,0.2,0), UDim2.new(0.05,0,0.4,0)
    slider.BackgroundColor3 = Color3.fromRGB(100,100,100)
    slider.BorderSizePixel = 0
    
    local fill = Instance.new("Frame", slider)
    fill.Size = UDim2.new((config.AntennaRange-50)/200,0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(0,200,255)
    fill.BorderSizePixel = 0
    fill.ZIndex = 2
    
    -- [新增] 范围输入框
    local inputBox = Instance.new("TextBox", frame)
    inputBox.Size, inputBox.Position = UDim2.new(0.4,0,0.2,0), UDim2.new(0.55,0,0.65,0)
    inputBox.Text = tostring(config.AntennaRange)
    inputBox.PlaceholderText = "输入范围"
    inputBox.BackgroundColor3 = Color3.fromRGB(60,70,100)
    inputBox.TextScaled = true -- 手机端适配
    
    inputBox.FocusLost:Connect(function()
        local num = tonumber(inputBox.Text)
        if num then
            config.AntennaRange = math.clamp(num, 50, 250)
            inputBox.Text = tostring(config.AntennaRange)
            title.Text = "📡 天线范围: "..config.AntennaRange.."米"
            fill.Size = UDim2.new((config.AntennaRange-50)/200,0,1,0)
        else
            inputBox.Text = tostring(config.AntennaRange)
        end
    end)
    
    local function updateSlider(input)
        local percent = math.clamp(
            (input.Position.X - slider.AbsolutePosition.X)/slider.AbsoluteSize.X, 0, 1
        )
        config.AntennaRange = 50 + math.floor(percent*200)
        title.Text = "📡 天线范围: "..config.AntennaRange.."米"
        fill.Size = UDim2.new(percent,0,1,0)
        inputBox.Text = tostring(config.AntennaRange)
    end
    
    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local conn; conn = RunService.Heartbeat:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then 
                    conn:Disconnect() 
                else
                    updateSlider(input)
                end
            end)
        end
    end)
    
    -- 手机端拖动手势
    slider.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            updateSlider(input)
        end
    end)
    
    effects.rangeUI = gui
    return gui
end

-- [优化] 主UI (手机端适配)
local function createMainUI()
    local gui = Instance.new("ScreenGui", CoreGui)
    gui.Name = "JiangSen_UI_"..tostring(math.random(10000,99999)) -- 随机名称防检测
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- 手机端适配
    
    local frame = Instance.new("Frame", gui)
    frame.Size, frame.Position = UDim2.new(0.3,0,0.55,0), UDim2.new(0.05,0,0.2,0) -- 放大UI
    frame.BackgroundColor3, frame.Active, frame.Draggable = Color3.fromRGB(30,40,60), true, true
    frame.BackgroundTransparency = 0.1
    frame.Visible = false -- 默认隐藏

    -- [新增] 标题栏
    local titleBar = Instance.new("Frame", frame)
    titleBar.Size, titleBar.Position = UDim2.new(1,0,0.1,0), UDim2.new(0,0,0,0)
    titleBar.BackgroundColor3 = Color3.fromRGB(60,70,100)
    titleBar.BorderSizePixel = 0
    
    local titleText = Instance.new("TextLabel", titleBar)
    titleText.Text = "江森脚本 v17"
    titleText.Size, titleText.Position = UDim2.new(1,0,1,0), UDim2.new(0,0,0,0)
    titleText.BackgroundTransparency = 1
    titleText.TextColor3 = Color3.new(1,1,1)
    titleText.Font = Enum.Font.SourceSansBold
    titleText.TextScaled = true -- 手机端适配

    -- [优化] 按钮列表 (放大按钮)
    local buttons = {
        {text="✈️ 飞行: OFF", pos=0.12, func=function()
            config.Flight = not config.Flight
            buttons[1].text = "✈️ 飞行: "..(config.Flight and "ON" or "OFF")
            notify("飞行", config.Flight and "已开启 (按"..config.FlightKeybind.Name..")" or "已关闭", 2)
            
            if config.Flight then
                createFlightUI()
                -- 创建飞行速度控制器
                if not effects.flightVelocity then
                    effects.flightVelocity = Instance.new("BodyVelocity", rootPart)
                    effects.flightVelocity.Velocity = Vector3.new()
                    effects.flightVelocity.MaxForce = Vector3.new(1e9,1e9,1e9)
                end
            elseif effects.flightUI then
                effects.flightUI:Destroy()
                -- 移除飞行速度控制器
                if effects.flightVelocity then
                    effects.flightVelocity:Destroy()
                    effects.flightVelocity = nil
                end
            end
        end},
        {text="🎯 自瞄: OFF", pos=0.22, func=function()
            config.Aimbot = not config.Aimbot
            buttons[2].text = "🎯 自瞄: "..(config.Aimbot and "ON" or "OFF")
            if config.Aimbot then
                createAimbotUI()
            end
            notify("自瞄", config.Aimbot and "已开启 (右键瞄准)" or "已关闭", 2)
        end},
        {text="🚀 瞬移甩飞", pos=0.32, func=function()
            createTeleportUI()
        end},
        {text="📡 天线: ON", pos=0.42, func=function()
            config.Antenna = not config.Antenna
            buttons[4].text = "📡 天线: "..(config.Antenna and "ON" or "OFF")
            if config.Antenna then
                for _,p in pairs(Players:GetPlayers()) do createAntenna(p) end
                createRangeUI()
            else
                for _,v in pairs(effects.antennas) do v:Destroy() end
                effects.antennas = {}
                if effects.rangeUI then effects.rangeUI:Destroy() end
            end
            notify("天线", config.Antenna and "已开启" or "已关闭", 2)
        end},
        {text="👁️ 透视: ON", pos=0.52, func=function()
            config.ESP = not config.ESP
            buttons[5].text = "👁️ 透视: "..(config.ESP and "ON" or "OFF")
            if config.ESP then
                for _,p in pairs(Players:GetPlayers()) do createESP(p) end
            else
                for _,v in pairs(effects.espGuis) do v:Destroy() end
                effects.espGuis = {}
            end
            notify("透视", config.ESP and "已开启" or "已关闭", 2)
        end},
        {text="⚙️ 飞行设置", pos=0.62, func=function()
            if config.Flight then
                createFlightUI()
            else
                notify("提示", "请先开启飞行功能", 2)
            end
        end},
        {text="🔄 穿墙模式: OFF", pos=0.72, func=function()
            config.NoClip = not config.NoClip
            buttons[7].text = "🔄 穿墙模式: "..(config.NoClip and "ON" or "OFF")
            notify("穿墙模式", config.NoClip and "已开启" or "已关闭", 2)
            
            if config.NoClip and not effects.noclipConn then
                effects.noclipConn = RunService.Stepped:Connect(function()
                    if character then
                        for _,v in pairs(character:GetDescendants()) do
                            if v:IsA("BasePart") then
                                v.CanCollide = false
                            end
                        end
                    end
                end)
            elseif not config.NoClip and effects.noclipConn then
                effects.noclipConn:Disconnect()
                effects.noclipConn = nil
            end
        end},
        {text="🤖 自动收集: OFF", pos=0.82, func=function()
            config.AutoFarm = not config.AutoFarm
            buttons[8].text = "🤖 自动收集: "..(config.AutoFarm and "ON" or "OFF")
            notify("自动收集", config.AutoFarm and "已开启" or "已关闭", 2)
        end}
    }

    -- [优化] 按钮生成 (手机端适配)
    for i,btn in pairs(buttons) do
        local b = Instance.new("TextButton", frame)
        b.Text, b.Size = btn.text, UDim2.new(0.9,0,0.09,0)
        b.Position, b.BackgroundColor3 = UDim2.new(0.05,0,btn.pos,0), Color3.fromRGB(60,70,120)
        b.BorderSizePixel = 0
        b.TextColor3 = Color3.new(1,1,1)
        b.TextScaled = true -- 手机端适配
        b.MouseButton1Click:Connect(btn.func)
        
        -- 鼠标悬停效果
        b.MouseEnter:Connect(function()
            b.BackgroundColor3 = Color3.fromRGB(80,90,150)
        end)
        
        b.MouseLeave:Connect(function()
            b.BackgroundColor3 = Color3.fromRGB(60,70,120)
        end)
        
        -- 手机端触摸效果
        b.TouchLongPress:Connect(function()
            b.BackgroundColor3 = Color3.fromRGB(80,90,150)
            wait(0.2)
            b.BackgroundColor3 = Color3.fromRGB(60,70,120)
        end)
    end

    -- [优化] 菜单切换按钮 (手机端适配)
    local eyeBtn = Instance.new("TextButton", gui)
    eyeBtn.Text, eyeBtn.Size, eyeBtn.Position = "👁️", UDim2.new(0.07,0,0.07,0), UDim2.new(0.01,0,0.01,0)
    eyeBtn.BackgroundColor3 = Color3.fromRGB(60,70,120)
    eyeBtn.BorderSizePixel = 0
    eyeBtn.TextScaled = true -- 手机端适配
    eyeBtn.MouseButton1Click:Connect(function() 
        frame.Visible = not frame.Visible 
    end)
    
    -- 手机端触摸支持
    eyeBtn.TouchTap:Connect(function()
        frame.Visible = not frame.Visible 
    end)

    return {gui=gui, frame=frame}
end

-- [优化] 天线系统 (独立运行)
local function createAntenna(p)
    if p == player or not p.Character or effects.antennas[p] then return end
    local head = p.Character:FindFirstChild("Head")
    if not head then return end
    
    local a1, a2 = Instance.new("Attachment", head), Instance.new("Attachment", head)
    a1.Position, a2.Position = Vector3.new(0,1.5,0), Vector3.new(0,6,0)
    
    local beam = Instance.new("Beam", head)
    beam.Attachment0, beam.Attachment1 = a1, a2
    beam.Color = ColorSequence.new(p.Team and p.Team.TeamColor.Color or Color3.new(1,1,1))
    beam.Width0, beam.Width1 = 0.3, 0.3
    beam.LightEmission = 0.5
    beam.Enabled = false -- 默认关闭
    
    effects.antennas[p] = beam
end

-- [优化] 透视系统 (显示距离)
local function createESP(p)
    if p == player or not p.Character or effects.espGuis[p] then return end
    local head = p.Character:FindFirstChild("Head")
    if not head then return end
    
    local gui = Instance.new("BillboardGui", head)
    gui.Size, gui.StudsOffset = UDim2.new(0,200,0,80), Vector3.new(0,3,0) -- 放大尺寸
    gui.AlwaysOnTop = true
    gui.Name = "ESP_"..p.Name..tostring(math.random(1000,9999)) -- 随机名称防检测
    
    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
    frame.BackgroundTransparency = 0.6
    frame.BorderSizePixel = 0
    
    local label = Instance.new("TextLabel", frame)
    label.Text, label.Size = p.Name, UDim2.new(1,0,0.4,0)
    label.TextColor3 = p.Team and p.Team.TeamColor.Color or Color3.new(1,0,0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSansBold
    label.TextScaled = true
    
    -- [新增] 距离显示
    local distLabel = Instance.new("TextLabel", frame)
    distLabel.Text, distLabel.Size = "0米", UDim2.new(1,0,0.3,0)
    distLabel.Position = UDim2.new(0,0,0.4,0)
    distLabel.TextColor3 = Color3.new(1,1,1)
    distLabel.BackgroundTransparency = 1
    distLabel.Font = Enum.Font.SourceSans
    
    -- [新增] 血量显示
    local healthLabel = Instance.new("TextLabel", frame)
    healthLabel.Text, healthLabel.Size = "100%", UDim2.new(1,0,0.3,0)
    healthLabel.Position = UDim2.new(0,0,0.7,0)
    healthLabel.TextColor3 = Color3.new(0,1,0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Font = Enum.Font.SourceSansBold
    
    -- 实时更新距离
    local distConn; distConn = RunService.Heartbeat:Connect(function()
        if p.Character and p.Character:FindFirstChild("Head") and rootPart then
            local dist = (p.Character.Head.Position - rootPart.Position).Magnitude
            distLabel.Text = string.format("%.1f米", dist)
        else
            distLabel.Text = "不可见"
        end
    end)
    
    -- 血量实时更新
    if p.Character:FindFirstChild("Humanoid") then
        local hum = p.Character.Humanoid
        local healthConn; healthConn = hum:GetPropertyChangedSignal("Health"):Connect(function()
            local percent = math.floor((hum.Health/hum.MaxHealth)*100)
            healthLabel.Text = string.format("血量: %d%%", percent)
            healthLabel.TextColor3 = Color3.fromHSV(percent/300,1,1)
        end)
        
        p.Character.AncestryChanged:Connect(function()
            if not p.Character:IsDescendantOf(workspace) then
                healthConn:Disconnect()
            end
        end)
    end
    
    -- 清理连接
    gui.AncestryChanged:Connect(function()
        if not gui:IsDescendantOf(game) then
            distConn:Disconnect()
        end
    end)
    
    effects.espGuis[p] = gui
end

-- [优化] 玩家管理
local function initPlayers()
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= player then
            if config.ESP then createESP(p) end
            if config.Antenna then createAntenna(p) end
        end
    end
    
    Players.PlayerAdded:Connect(function(p)
        if p ~= player then
            if config.ESP then createESP(p) end
            if config.Antenna then createAntenna(p) end
        end
    end)
    
    Players.PlayerRemoving:Connect(function(p)
        if effects.antennas[p] then effects.antennas[p]:Destroy(); effects.antennas[p] = nil end
        if effects.espGuis[p] then effects.espGuis[p]:Destroy(); effects.espGuis[p] = nil end
    end)
end

-- [优化] 自动收集功能
local function autoFarm()
    if not config.AutoFarm then return end
    
    -- 自动收集附近物品
    for _,item in pairs(workspace:GetChildren()) do
        if item:IsA("BasePart") and (item.Name:find("Coin") or item.Name:find("Money") or item.Name:find("Item")) then
            if (item.Position - rootPart.Position).Magnitude < 25 then
                firetouchinterest(rootPart, item, 0)
                firetouchinterest(rootPart, item, 1)
                task.wait(0.1)
            end
        end
    end
end

-- [修复] 主循环 (飞行系统重写)
local function mainLoop()
    -- 防封禁
    if antiBan.active then antiBan.scramble() end
    
    -- 飞行控制 (完全重写)
    if config.Flight and rootPart and effects.flightVelocity then
        humanoid.PlatformStand = true
        
        -- 计算移动方向
        local moveDir = Vector3.new(
            (UIS:IsKeyDown(Enum.KeyCode.D) and 1 or 0) + (UIS:IsKeyDown(Enum.KeyCode.A) and -1 or 0),
            0,
            (UIS:IsKeyDown(Enum.KeyCode.W) and -1 or 0) + (UIS:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
        )
        
        -- 应用相机方向
        local cameraCF = camera.CFrame
        local moveVector = cameraCF:VectorToWorldSpace(moveDir)
        
        -- 垂直移动
        local vertical = 0
        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            vertical = 1
        elseif UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
            vertical = -1
        end
        
        -- 计算最终速度
        local finalVelocity = Vector3.new(
            moveVector.X * config.Speed,
            vertical * config.VSpeed,
            moveVector.Z * config.Speed
        )
        
        -- 应用速度
        effects.flightVelocity.Velocity = finalVelocity
        
        -- 重力控制
        rootPart.AssemblyLinearVelocity = finalVelocity
        if config.FlightGravity then
            rootPart.AssemblyLinearVelocity += Vector3.new(0, workspace.Gravity/10, 0)
        end
    elseif not config.Flight and humanoid then
        humanoid.PlatformStand = false
    end
    
    -- 自瞄系统 (目标锁定)
    if config.Aimbot and config.AimbotTarget and config.AimbotTarget.Character then
        local head = config.AimbotTarget.Character:FindFirstChild("Head")
        if head then
            local currentCF = camera.CFrame
            local targetPos = head.Position
            local targetCF = CFrame.lookAt(currentCF.Position, targetPos)
            camera.CFrame = currentCF:Lerp(targetCF, config.AimSmoothness)
        else
            config.AimbotTarget = nil
        end
    end
    
    -- 天线距离控制
    if config.Antenna then
        for p, antenna in pairs(effects.antennas) do
            if p.Character and p.Character:FindFirstChild("Head") and rootPart then
                local dist = (p.Character.Head.Position - rootPart.Position).Magnitude
                antenna.Enabled = dist <= config.AntennaRange
            else
                antenna.Enabled = false
            end
        end
    end
    
    -- 自动收集
    if config.AutoFarm then
        autoFarm()
    end
end

-- [优化] 初始化
effects.mainUI = createMainUI()
initPlayers()
if config.Antenna then createRangeUI() end
notify("江森脚本 v17", "飞行: "..config.FlightKeybind.Name.."\n自瞄: 右键\n菜单: F5", 5)

-- [优化] 输入监听 (手机端适配)
UIS.InputBegan:Connect(function(input)
    -- 飞行快捷键
    if input.KeyCode == config.FlightKeybind then
        config.Flight = not config.Flight
        notify("飞行", config.Flight and "已开启" or "已关闭", 2)
        
        if config.Flight then
            createFlightUI()
            -- 创建飞行速度控制器
            if not effects.flightVelocity then
                effects.flightVelocity = Instance.new("BodyVelocity", rootPart)
                effects.flightVelocity.Velocity = Vector3.new()
                effects.flightVelocity.MaxForce = Vector3.new(1e9,1e9,1e9)
            end
        elseif effects.flightUI then
            effects.flightUI:Destroy()
            -- 移除飞行速度控制器
            if effects.flightVelocity then
                effects.flightVelocity:Destroy()
                effects.flightVelocity = nil
            end
        end
    end
    
    -- 自瞄目标选择
    if input.UserInputType.Name == config.AimbotKey and config.Aimbot then
        if not config.AimbotTarget then
            createAimbotUI()
        end
    end
    
    -- 菜单切换
    if input.KeyCode == Enum.KeyCode.F5 then
        effects.mainUI.frame.Visible = not effects.mainUI.frame.Visible
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType.Name == config.AimbotKey then
        -- 保留目标，不清除
    end
end)

-- [优化] 启动主循环
RunService.Heartbeat:Connect(mainLoop)
[file content end]