local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

task.spawn(function()
    local Sound = Instance.new("Sound")
    Sound.SoundId = "rbxassetid://127416115159040"
    Sound.Volume = 0.8  
    Sound.Looped = false 
    Sound.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    Sound.TimePosition = 5 
    Sound:Play()
    Sound.Ended:Connect(function()
        if Sound and Sound.Parent then
            Sound:Destroy()
        end
    end)
end)

local Window = Rayfield:CreateWindow({
    Name = "通用脚本", 
    LoadingTitle = "通用脚本", 
    LoadingSubtitle = "通用功能合集",
    ShowText = "通用脚本", 
    Icon = 128981664025072, 
    Style = 3,
    DisableRayfieldPrompts = true, 
    ConfigurationSaving = { Enabled = false },
})

local Tab1 = Window:CreateTab("通用功能")

-- ================= 服务与基础变量 =================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Connections = {}

-- ================= 1. NPC透视 =================
local NPCESP = { Enabled = false, Color = Color3.fromRGB(0,162,255), Highlights = {} }

local function GetNPCPart(model)
    if not model then return nil end
    if model:FindFirstChild("HumanoidRootPart") then return model.HumanoidRootPart end
    for _, part in pairs(model:GetDescendants()) do
        if part:IsA("BasePart") then return part end
    end
    return nil
end

local function AddNPCESP(model)
    if not model then return end
    if NPCESP.Highlights[model] then return end
    if not model:FindFirstChildWhichIsA("Humanoid") then return end
    if Players:GetPlayerFromCharacter(model) then return end
    local part = GetNPCPart(model)
    if not part then return end
    local success, hl = pcall(function()
        local h = Instance.new("Highlight")
        h.Name = "NPCESP"
        h.Adornee = model
        h.FillColor = NPCESP.Color
        h.OutlineColor = Color3.fromRGB(255,255,255)
        h.FillTransparency = 0.4
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = game.CoreGui
        return h
    end)
    if success and hl then
        NPCESP.Highlights[model] = hl
        task.delay(1, function()
            if hl and hl.Parent and (not hl.Adornee or hl.Adornee ~= model) then
                pcall(function() hl.Adornee = model end)
            end
        end)
        pcall(function()
            hl.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    pcall(function() hl:Destroy() end)
                    NPCESP.Highlights[model] = nil
                end
            end)
        end)
    end
end

local function RemoveNPCESP(model)
    if not model then return end
    if NPCESP.Highlights[model] then
        pcall(function() if NPCESP.Highlights[model] and NPCESP.Highlights[model].Parent then NPCESP.Highlights[model]:Destroy() end end)
        NPCESP.Highlights[model] = nil
    end
end

local function ToggleNPCESP(state)
    NPCESP.Enabled = state
    if state then
        task.spawn(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") then task.spawn(AddNPCESP, obj) end
            end
        end)
        if not Connections.NPC then
            Connections.NPC = Workspace.DescendantAdded:Connect(function(child)
                task.delay(0.5, function()
                    if child and child:IsA("Model") then AddNPCESP(child)
                    elseif child and child:IsA("Humanoid") and child.Parent then AddNPCESP(child.Parent) end
                end)
            end)
        end
        task.spawn(function()
            while NPCESP.Enabled do
                for model, hl in pairs(NPCESP.Highlights) do
                    if not model or not model.Parent or not hl or not hl.Parent then NPCESP.Highlights[model] = nil end
                end
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") then AddNPCESP(obj) end
                end
                task.wait(2)
            end
        end)
    else
        local toRemove = {}
        for model, _ in pairs(NPCESP.Highlights) do table.insert(toRemove, model) end
        for _, model in ipairs(toRemove) do RemoveNPCESP(model) end
        if Connections.NPC then pcall(function() Connections.NPC:Disconnect() end); Connections.NPC = nil end
    end
end

-- ================= 2. 旧版互动透视 =================
local InteractESP = { Enabled = false, Color = Color3.fromRGB(0,255,0), Highlights = {} }

local function IsInteractive_Old(obj) return obj and (obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector")) end
local function FindAdornPart_Old(target)
    if not target then return nil end
    if target:IsA("BasePart") then return target end
    if target:IsA("Model") then
        if target.PrimaryPart then return target.PrimaryPart end
        for _, c in pairs(target:GetChildren()) do if c:IsA("BasePart") then return c end end
    end
    return nil
end

local function AddInteractESP(target)
    if not target then return end
    if InteractESP.Highlights[target] then return end
    if not (target:IsA("BasePart") or target:IsA("Model")) then return end
    local ok, hl = pcall(function()
        local h = Instance.new("Highlight")
        h.Name = "InteractESP"
        h.Adornee = target
        h.FillColor = InteractESP.Color
        h.OutlineColor = Color3.fromRGB(255,255,255)
        h.FillTransparency = 0.5
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = target
        return h
    end)
    if not ok then return end
    InteractESP.Highlights[target] = hl
    local adornPart = FindAdornPart_Old(target)
    if adornPart then
        if adornPart:FindFirstChild("InteractLabel") then return end
        local prompt = target:FindFirstChildWhichIsA("ProximityPrompt") or (target.Parent and target.Parent:FindFirstChildWhichIsA("ProximityPrompt"))
        local text = (prompt and (prompt.ActionText ~= "" and prompt.ActionText)) or "可互动"
        local bb = Instance.new("BillboardGui")
        bb.Name = "InteractLabel"
        bb.Adornee = adornPart
        bb.Size = UDim2.new(0,120,0,30)
        bb.StudsOffset = Vector3.new(0,3,0)
        bb.AlwaysOnTop = true
        bb.Parent = adornPart
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,0,1,0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = InteractESP.Color
        label.TextStrokeTransparency = 0.5
        label.TextStrokeColor3 = Color3.new(0,0,0)
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 14
        label.Parent = bb
    end
    pcall(function()
        target.AncestryChanged:Connect(function(_, parent)
            if not parent and InteractESP.Highlights[target] then
                pcall(function() InteractESP.Highlights[target]:Destroy() end)
                InteractESP.Highlights[target] = nil
                pcall(function()
                    if target.GetDescendants then
                        for _, v in pairs(target:GetDescendants()) do
                            if v:IsA("BillboardGui") and v.Name == "InteractLabel" then pcall(function() v:Destroy() end) end
                        end
                    end
                end)
            end
        end)
    end)
end

local function RemoveInteractESP(target)
    if not target then return end
    if InteractESP.Highlights[target] then
        pcall(function() if InteractESP.Highlights[target] and InteractESP.Highlights[target].Parent then InteractESP.Highlights[target]:Destroy() end end)
        InteractESP.Highlights[target] = nil
    end
    pcall(function()
        if target and target.GetDescendants then
            for _, v in pairs(target:GetDescendants()) do
                if v:IsA("BillboardGui") and v.Name == "InteractLabel" then pcall(function() v:Destroy() end) end
            end
        end
    end)
end

local function ToggleInteractESP(state)
    InteractESP.Enabled = state
    if state then
        task.spawn(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if IsInteractive_Old(obj) and obj.Parent then pcall(function() AddInteractESP(obj.Parent) end) end
            end
        end)
        if not Connections.Interact then
            Connections.Interact = Workspace.DescendantAdded:Connect(function(child)
                task.delay(1, function()
                    if child and IsInteractive_Old(child) and child.Parent then AddInteractESP(child.Parent)
                    elseif child and child:IsA("BasePart") and child.Parent then
                        for _, c in pairs(child:GetDescendants()) do
                            if IsInteractive_Old(c) and c.Parent then AddInteractESP(c.Parent) end
                        end
                    end
                end)
            end)
        end
    else
        local toRemove = {}
        for target, _ in pairs(InteractESP.Highlights) do table.insert(toRemove, target) end
        for _, target in ipairs(toRemove) do RemoveInteractESP(target) end
        if Connections.Interact then pcall(function() Connections.Interact:Disconnect() end); Connections.Interact = nil end
    end
end

-- ================= 3. 新版互动透视 =================
local NewInteractESP = { Enabled = false, Color = Color3.fromRGB(0,255,0), Highlights = {} }

local function IsInteractive_New(o) return o and (o:IsA("ProximityPrompt") or o:IsA("ClickDetector")) end
local function GetInteractiveTarget(node)
    local p = node
    while p do if p:IsA("BasePart") or p:IsA("Model") then return p end p = p.Parent end
    return nil
end
local function FindAdornPart_New(t)
    if not t then return nil end
    if t:IsA("BasePart") then return t end
    if t:IsA("Model") then
        if t.PrimaryPart then return t.PrimaryPart end
        for _, c in pairs(t:GetChildren()) do if c:IsA("BasePart") then return c end end
    end
    return nil
end

local function AddNewInteractESP(target)
    if not target then return end
    if NewInteractESP.Highlights[target] then return end
    local ok, h = pcall(function()
        local hl = Instance.new("Highlight")
        hl.Name = "NewInteractESP"
        hl.Adornee = target
        hl.FillColor = NewInteractESP.Color
        hl.OutlineColor = Color3.new(1,1,1)
        hl.FillTransparency = .5
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = target
        return hl
    end)
    if not ok or not h then return end
    NewInteractESP.Highlights[target] = h
    local part = FindAdornPart_New(target)
    if part and not part:FindFirstChild("NewInteractLabel") then
        pcall(function()
            local bb = Instance.new("BillboardGui")
            bb.Name = "NewInteractLabel"
            bb.Adornee = part
            bb.Size = UDim2.new(0,120,0,30)
            bb.StudsOffset = Vector3.new(0,3,0)
            bb.AlwaysOnTop = true
            bb.Parent = part
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1,0,1,0)
            label.BackgroundTransparency = 1
            label.TextStrokeTransparency = .4
            label.TextStrokeColor3 = Color3.new(0,0,0)
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = 14
            label.TextColor3 = NewInteractESP.Color
            label.Parent = bb
            local displayName = target.Name or ""
            if displayName == "" or displayName == "Part" or displayName == "Model" or displayName == "BasePart" then label.Text = "可互动" else label.Text = displayName end
        end)
    end
    pcall(function()
        target.AncestryChanged:Connect(function(_, parent)
            if not parent then
                if NewInteractESP.Highlights[target] then
                    pcall(function() NewInteractESP.Highlights[target]:Destroy() end)
                    NewInteractESP.Highlights[target] = nil
                end
                pcall(function()
                    for _, obj in pairs(Workspace:GetDescendants()) do
                        if obj:IsA("BillboardGui") and obj.Name == "NewInteractLabel" then
                            local ador = obj.Adornee
                            if not ador or not ador:IsDescendantOf(game) then pcall(function() obj:Destroy() end) end
                        end
                    end
                end)
            end
        end)
    end)
end

local function ToggleNewInteractESP(state)
    NewInteractESP.Enabled = state
    if state then
        task.spawn(function()
            for _, v in ipairs(Workspace:GetDescendants()) do
                if IsInteractive_New(v) then local t = GetInteractiveTarget(v) if t then AddNewInteractESP(t) end end
            end
        end)
        if not Connections.NewInteract then
            Connections.NewInteract = Workspace.DescendantAdded:Connect(function(c)
                task.delay(0.05, function()
                    if c and c.GetDescendants then
                        for _, d in pairs(c:GetDescendants()) do if IsInteractive_New(d) then local t = GetInteractiveTarget(d) if t then AddNewInteractESP(t) end end end
                    end
                    if IsInteractive_New(c) then local t = GetInteractiveTarget(c) if t then AddNewInteractESP(t) end end
                end)
            end)
        end
    else
        for t, h in pairs(NewInteractESP.Highlights) do pcall(function() h:Destroy() end) end
        NewInteractESP.Highlights = {}
        pcall(function()
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("BillboardGui") and obj.Name == "NewInteractLabel" then pcall(function() obj:Destroy() end) end
            end
        end)
        if Connections.NewInteract then pcall(function() Connections.NewInteract:Disconnect() end); Connections.NewInteract = nil end
    end
end

-- ================= 4. 玩家透视 =================
local PLAYER_ESP = {
    Enabled = false, HighlightEnabled = false, BoxEnabled = false, TeamCheck = false,
    ShowName = false, ShowHealth = false, ShowDist = false
}

local function ClearPlayerESP()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "PlayerESP_Highlight" or obj.Name == "PlayerESP_Info" or obj.Name == "PlayerESP_Box" then
            obj:Destroy()
        end
    end
end

local function UpdatePlayerESP()
    if not PLAYER_ESP.Enabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local char = p.Character
            local hum = char:FindFirstChild("Humanoid")
            local head = char:FindFirstChild("Head")
            local root = char:FindFirstChild("HumanoidRootPart")

            if hum and head and root and hum.Health > -500 then
                local isTeam = (p.Team == LocalPlayer.Team)
                local filtered = PLAYER_ESP.TeamCheck and isTeam
                local color = p.TeamColor.Color

                -- 高亮
                local high = char:FindFirstChild("PlayerESP_Highlight")
                if PLAYER_ESP.HighlightEnabled then
                    if not high then
                        high = Instance.new("Highlight", char)
                        high.Name = "PlayerESP_Highlight"
                    end
                    high.FillColor = color
                    high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                elseif high then
                    high:Destroy()
                end

                -- 方框
                local box = char:FindFirstChild("PlayerESP_Box")
                if PLAYER_ESP.BoxEnabled and not filtered then
                    if not box then
                        box = Instance.new("BillboardGui", char)
                        box.Name = "PlayerESP_Box"
                        box.Size = UDim2.new(4.5,0,6,0)
                        box.AlwaysOnTop = true
                        box.Adornee = root
                        local f = Instance.new("Frame", box)
                        f.Size = UDim2.new(1,0,1,0)
                        f.BackgroundTransparency = 1
                        local s = Instance.new("UIStroke", f)
                        s.Thickness = 1.5
                    end
                    box.Frame.UIStroke.Color = color
                elseif box then
                    box:Destroy()
                end

                -- 信息
                local info = char:FindFirstChild("PlayerESP_Info")
                if not filtered then
                    if not info then
                        info = Instance.new("BillboardGui", char)
                        info.Name = "PlayerESP_Info"
                        info.Size = UDim2.new(0,200,0,50)
                        info.AlwaysOnTop = true
                        info.Adornee = head
                        info.ExtentsOffset = Vector3.new(0,3.5,0)
                        local txt = Instance.new("TextLabel", info)
                        txt.Name = "Label"
                        txt.Size = UDim2.new(1,0,1,0)
                        txt.BackgroundTransparency = 1
                        txt.RichText = true
                        txt.TextStrokeTransparency = 0.5
                        txt.Font = Enum.Font.GothamMedium
                    end
                    local text = ""
                    if PLAYER_ESP.ShowName then
                        text = "<font color='#ffffff'><b>"..p.DisplayName.."</b></font>\n"
                    end
                    if PLAYER_ESP.ShowHealth then
                        local hp = math.floor(hum.Health)
                        local hpColor = (hp > 50 and "#55ff55" or "#ff5555")
                        text = text .. "<font color='"..hpColor.."'>HP: "..hp.."</font> "
                    end
                    if PLAYER_ESP.ShowDist then
                        local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude)
                        text = text .. "<font color='#ffffff'>| "..dist.."m</font>"
                    end
                    info.Label.Text = text
                elseif info then
                    info:Destroy()
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    if PLAYER_ESP.Enabled then UpdatePlayerESP() end
end)

-- ================= UI：透视功能 =================
Tab1:CreateSection("透视功能")

Tab1:CreateToggle({
    Name = "NPC透视",
    CurrentValue = false,
    Flag = "NPCESP_Toggle",
    Icon = 128981664025072,
    Ext = true,
    Callback = function(Value)
        ToggleNPCESP(Value)
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "功能提示", Text = Value and "已开启NPC透视" or "已关闭NPC透视", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab1:CreateToggle({
    Name = "旧版互动透视",
    CurrentValue = false,
    Flag = "InteractESP_Toggle",
    Icon = 128981664025072,
    Ext = true,
    Callback = function(Value)
        ToggleInteractESP(Value)
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "功能提示", Text = Value and "已开启旧版互动透视" or "已关闭旧版互动透视", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab1:CreateToggle({
    Name = "新版互动透视",
    CurrentValue = false,
    Flag = "NewInteractESP_Toggle",
    Icon = 128981664025072,
    Ext = true,
    Callback = function(Value)
        ToggleNewInteractESP(Value)
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "功能提示", Text = Value and "已开启新版互动透视" or "已关闭新版互动透视", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab1:CreateButton({
    Name = "刷新新版ESP",
    Icon = 128981664025072,
    Ext = true,
    Callback = function()
        ToggleNewInteractESP(false)
        task.wait(0.2)
        ToggleNewInteractESP(true)
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "功能提示", Text = "已刷新新版ESP", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab1:CreateToggle({
    Name = "玩家透视总开关",
    CurrentValue = false,
    Flag = "PlayerESP_Main",
    Icon = 128981664025072,
    Ext = true,
    Callback = function(Value)
        PLAYER_ESP.Enabled = Value
        if not Value then ClearPlayerESP() end
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "功能提示", Text = Value and "已开启玩家透视" or "已关闭玩家透视", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab1:CreateToggle({
    Name = "高亮",
    CurrentValue = false,
    Flag = "PlayerESP_Highlight",
    Icon = 128981664025072,
    Ext = true,
    Callback = function(Value) PLAYER_ESP.HighlightEnabled = Value end,
})

Tab1:CreateToggle({
    Name = "方框",
    CurrentValue = false,
    Flag = "PlayerESP_Box",
    Icon = 128981664025072,
    Ext = true,
    Callback = function(Value) PLAYER_ESP.BoxEnabled = Value end,
})

Tab1:CreateToggle({
    Name = "名字",
    CurrentValue = false,
    Flag = "PlayerESP_Name",
    Icon = 128981664025072,
    Ext = true,
    Callback = function(Value) PLAYER_ESP.ShowName = Value end,
})

Tab1:CreateToggle({
    Name = "血量",
    CurrentValue = false,
    Flag = "PlayerESP_Health",
    Icon = 128981664025072,
    Ext = true,
    Callback = function(Value) PLAYER_ESP.ShowHealth = Value end,
})

Tab1:CreateToggle({
    Name = "距离",
    CurrentValue = false,
    Flag = "PlayerESP_Dist",
    Icon = 128981664025072,
    Ext = true,
    Callback = function(Value) PLAYER_ESP.ShowDist = Value end,
})

Tab1:CreateToggle({
    Name = "队伍检测",
    CurrentValue = false,
    Flag = "PlayerESP_Team",
    Icon = 128981664025072,
    Ext = true,
    Callback = function(Value) PLAYER_ESP.TeamCheck = Value end,
})

-- ================= 其他旧功能 =================
Tab1:CreateSection("其他通用功能")

Tab1:CreateButton({
    Name = "一键飞行",
    Icon = 128981664025072,
    Ext = true,
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/ylt410/roblox-Script/refs/heads/main/flyab.lua"))()
        end)
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "功能提示", Text = "飞行已加载", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab1:CreateButton({
    Name = "绕过群组检测",
    Icon = 128981664025072,
    Ext = true,
    Callback = function()
        pcall(function()
            local getnamecallmethod = getnamecallmethod
            local Speaker = cloneref(game:GetService("Players")).LocalPlayer
            local OldNameCall
            OldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
                if self ~= Speaker or getnamecallmethod() ~= "IsInGroup" then
                    return OldNameCall(self, ...)
                end
                return true
            end)
            hookfunction(Speaker.IsInGroup, function(self, ...)
                return true
            end)
        end)
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "功能提示", Text = "已绕过群组检测", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

local AntiFallEnabled = false
local AntiFallConnection = nil

local function StartAntiFall(character)
    local root = character:WaitForChild("HumanoidRootPart")
    if AntiFallConnection then AntiFallConnection:Disconnect() end
    AntiFallConnection = RunService.Heartbeat:Connect(function()
        if not AntiFallEnabled or not root or not root.Parent then return end
        local velocity = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.zero
        RunService.RenderStepped:Wait()
        root.AssemblyLinearVelocity = velocity
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if AntiFallEnabled then StartAntiFall(char) end
end)

Tab1:CreateToggle({
    Name = "防坠落伤害",
    CurrentValue = false,
    Flag = "AntiFallToggle",
    Icon = 128981664025072,
    Ext = true,
    Callback = function(Value)
        AntiFallEnabled = Value
        if Value then
            local char = LocalPlayer.Character
            if char then StartAntiFall(char) end
            game:GetService("StarterGui"):SetCore("SendNotification", { Title = "功能提示", Text = "已开启防坠落伤害", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            if AntiFallConnection then AntiFallConnection:Disconnect(); AntiFallConnection = nil end
            game:GetService("StarterGui"):SetCore("SendNotification", { Title = "功能提示", Text = "已关闭防坠落伤害", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

Tab1:CreateButton({
    Name = "夜自瞄",
    Icon = 128981664025072,
    Ext = true,
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/ylt410/roblox-Script/refs/heads/main/ye%20aimbot"))()
        end)
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "功能提示", Text = "夜自瞄已加载", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

Tab1:CreateButton({
    Name = "强制显示聊天框（清屏）",
    Icon = 128981664025072,
    Ext = true,
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/ylt410/roblox-Script/refs/heads/main/djejhebr"))()
        end)
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "功能提示", Text = "清屏开关已加载", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

local NoclipConnection = nil
local OriginalCollision = {}

Tab1:CreateToggle({
    Name = "穿墙",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Icon = 128981664025072,
    Ext = true,
    Callback = function(Value)
        if Value then
            OriginalCollision = {}
            if NoclipConnection then NoclipConnection:Disconnect() end
            NoclipConnection = RunService.Stepped:Connect(function()
                local character = LocalPlayer.Character
                if not character then return end
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if OriginalCollision[part] == nil then OriginalCollision[part] = part.CanCollide end
                        part.CanCollide = false
                    end
                end
            end)
            game:GetService("StarterGui"):SetCore("SendNotification", { Title = "功能提示", Text = "已开启穿墙", Duration = 2, Icon = "rbxassetid://128981664025072" })
        else
            if NoclipConnection then NoclipConnection:Disconnect(); NoclipConnection = nil end
            for part, state in pairs(OriginalCollision) do
                if typeof(part) == "Instance" and part.Parent then part.CanCollide = state end
            end
            OriginalCollision = {}
            game:GetService("StarterGui"):SetCore("SendNotification", { Title = "功能提示", Text = "已关闭穿墙", Duration = 2, Icon = "rbxassetid://128981664025072" })
        end
    end,
})

local AdminDetectEnabled = true
local flaggedAdmins = {}

local function CheckAdmin(player)
    if not AdminDetectEnabled or flaggedAdmins[player] or not player or not player.Parent then return end
    local suspicious = false
    local reason = ""
    pcall(function()
        for _, g in ipairs(player:GetGroups()) do
            if g.Rank >= 200 then
                suspicious = true; reason = "高Rank玩家"
            end
        end
    end)
    if suspicious then
        flaggedAdmins[player] = true
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "⚠️ 管理员警告", Text = player.Name .. " - " .. reason, Duration = 5, Icon = "rbxassetid://128981664025072" })
    end
end

Players.PlayerAdded:Connect(function(p) task.wait(1) CheckAdmin(p) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(function() CheckAdmin(p) end) end
task.spawn(function()
    while true do
        if AdminDetectEnabled then
            for _, p in ipairs(Players:GetPlayers()) do CheckAdmin(p) end
        end
        task.wait(2)
    end
end)
Players.PlayerRemoving:Connect(function(p) flaggedAdmins[p] = nil end)

Tab1:CreateToggle({
    Name = "管理员通知",
    CurrentValue = true,
    Flag = "AdminNotifyToggle",
    Icon = 128981664025072,
    Ext = true,
    Callback = function(Value)
        AdminDetectEnabled = Value
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "功能提示", Text = Value and "已开启管理员通知" or "已关闭管理员通知", Duration = 2, Icon = "rbxassetid://128981664025072" })
    end,
})

-- ================= 启动通知 =================
task.spawn(function()
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = "通用脚本已加载", Text = " ", Duration = 3, Icon = "rbxassetid://128981664025072" })
    task.wait(3)
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = "每天周日更新", Text = " ", Duration = 3, Icon = "rbxassetid://128981664025072" })
    task.wait(3)
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = "感谢你的支持", Text = " ", Duration = 3, Icon = "rbxassetid://128981664025072" })
end)