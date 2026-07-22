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
local Tab2 = Window:CreateTab("透视功能")
local Tab3 = Window:CreateTab("自瞄")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Connections = {}

local OriginalLighting = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale or 1,
    EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale or 0,
    ColorShift_Top = Lighting.ColorShift_Top,
    ColorShift_Bottom = Lighting.ColorShift_Bottom
}

local OriginalAtmosphere = {}

local function Notify(Title, Text, Duration)
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = Title, Text = Text, Duration = Duration or 2, Icon = "rbxassetid://128981664025072" })
end

Tab1:CreateButton({
    Name = "一键飞行",
    Ext = true,
    Callback = function()
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ylt410/roblox-Script/refs/heads/main/flyab.lua"))() end)
        Notify("功能提示", "飞行已加载", 2)
    end,
})

Tab1:CreateButton({
    Name = "绕过群组检测",
    Ext = true,
    Callback = function()
        pcall(function()
            local getnamecallmethod = getnamecallmethod
            local Speaker = cloneref(game:GetService("Players")).LocalPlayer
            local OldNameCall
            OldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
                if self ~= Speaker or getnamecallmethod() ~= "IsInGroup" then return OldNameCall(self, ...) end
                return true
            end)
            hookfunction(Speaker.IsInGroup, function(self, ...) return true end)
        end)
        Notify("功能提示", "已绕过群组检测", 2)
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
    Ext = true,
    Callback = function(Value)
        AntiFallEnabled = Value
        if Value then
            local char = LocalPlayer.Character
            if char then StartAntiFall(char) end
            Notify("功能提示", "已开启防坠落伤害", 2)
        else
            if AntiFallConnection then AntiFallConnection:Disconnect(); AntiFallConnection = nil end
            Notify("功能提示", "已关闭防坠落伤害", 2)
        end
    end,
})

Tab1:CreateButton({
    Name = "夜自瞄",
    Ext = true,
    Callback = function()
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ylt410/roblox-Script/refs/heads/main/ye%20aimbot"))() end)
        Notify("功能提示", "夜自瞄已加载", 2)
    end,
})

Tab1:CreateButton({
    Name = "强制显示聊天框（清屏）",
    Ext = true,
    Callback = function()
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ylt410/roblox-Script/refs/heads/main/djejhebr"))() end)
        Notify("功能提示", "清屏开关已加载", 2)
    end,
})

local NoclipConnection = nil
local OriginalCollision = {}

Tab1:CreateToggle({
    Name = "穿墙",
    CurrentValue = false,
    Flag = "NoclipToggle",
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
            Notify("功能提示", "已开启穿墙", 2)
        else
            if NoclipConnection then NoclipConnection:Disconnect(); NoclipConnection = nil end
            for part, state in pairs(OriginalCollision) do
                if typeof(part) == "Instance" and part.Parent then part.CanCollide = state end
            end
            OriginalCollision = {}
            Notify("功能提示", "已关闭穿墙", 2)
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
            if g.Rank >= 200 then suspicious = true; reason = "高Rank玩家" end
        end
    end)
    if suspicious then
        flaggedAdmins[player] = true
        Notify("⚠️ 管理员警告", player.Name .. " - " .. reason, 5)
    end
end

Players.PlayerAdded:Connect(function(p) task.wait(1) CheckAdmin(p) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(function() CheckAdmin(p) end) end
task.spawn(function()
    while true do
        if AdminDetectEnabled then for _, p in ipairs(Players:GetPlayers()) do CheckAdmin(p) end end
        task.wait(2)
    end
end)
Players.PlayerRemoving:Connect(function(p) flaggedAdmins[p] = nil end)

Tab1:CreateToggle({
    Name = "管理员通知",
    CurrentValue = true,
    Flag = "AdminNotifyToggle",
    Ext = true,
    Callback = function(Value)
        AdminDetectEnabled = Value
        Notify("功能提示", Value and "已开启管理员通知" or "已关闭管理员通知", 2)
    end,
})

local HealthGui = Instance.new("ScreenGui")
HealthGui.Name = "SelfHealthDisplay"
HealthGui.ResetOnSpawn = false
HealthGui.Parent = game.CoreGui

local HealthLabel = Instance.new("TextLabel")
HealthLabel.Size = UDim2.new(0, 140, 0, 20)
HealthLabel.Position = UDim2.new(0, 10, 0, 10)
HealthLabel.BackgroundTransparency = 1
HealthLabel.TextStrokeTransparency = 0.5
HealthLabel.Font = Enum.Font.SourceSansBold
HealthLabel.TextSize = 14
HealthLabel.Text = "HP: -- / --"
HealthLabel.TextXAlignment = Enum.TextXAlignment.Left
HealthLabel.Parent = HealthGui

local HealthToggleConnection = nil
local HealthEnabled = false

local function ToggleHealthDisplay(state)
    HealthEnabled = state
    HealthLabel.Visible = state
    if state then
        if not HealthToggleConnection then
            HealthToggleConnection = RunService.RenderStepped:Connect(function()
                if not HealthEnabled then return end
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local current = math.floor(hum.Health)
                        local max = math.floor(hum.MaxHealth)
                        local percent = current / max
                        local color
                        if percent > 0.6 then color = Color3.fromRGB(0,255,0)
                        elseif percent > 0.3 then color = Color3.fromRGB(255,170,0)
                        else color = Color3.fromRGB(255,0,0) end
                        HealthLabel.TextColor3 = color
                        HealthLabel.Text = "HP: " .. current .. " / " .. max
                    end
                end
            end)
        end
    else
        if HealthToggleConnection then HealthToggleConnection:Disconnect(); HealthToggleConnection = nil end
    end
end

Tab1:CreateToggle({
    Name = "自身血量显示",
    CurrentValue = false,
    Flag = "HealthDisplayToggle",
    Ext = true,
    Callback = function(Value) ToggleHealthDisplay(Value) end,
})

local FpsGui = Instance.new("ScreenGui")
FpsGui.Name = "FPSDisplay"
FpsGui.ResetOnSpawn = false
FpsGui.Parent = game.CoreGui

local FpsLabel = Instance.new("TextLabel")
FpsLabel.Size = UDim2.new(0, 80, 0, 20)
FpsLabel.Position = UDim2.new(1, -90, 0, 10)
FpsLabel.BackgroundTransparency = 1
FpsLabel.TextStrokeTransparency = 0.5
FpsLabel.Font = Enum.Font.SourceSansBold
FpsLabel.TextSize = 14
FpsLabel.Text = "FPS: 0"
FpsLabel.TextXAlignment = Enum.TextXAlignment.Right
FpsLabel.Parent = FpsGui

local FpsEnabled = false
local FrameCount = 0
local TimeAccumulator = 0

local function ToggleFpsDisplay(state)
    FpsEnabled = state
    FpsLabel.Visible = state
    if state then
        FrameCount = 0
        TimeAccumulator = 0
        task.spawn(function()
            while FpsEnabled do
                FrameCount = FrameCount + 1
                task.wait()
            end
        end)
        if not FpsGui:FindFirstChild("FpsUpdater") then
            local updater = RunService.RenderStepped:Connect(function(dt)
                if not FpsEnabled then return end
                TimeAccumulator = TimeAccumulator + dt
                if TimeAccumulator >= 1 then
                    FpsLabel.Text = "FPS: " .. math.floor(FrameCount / TimeAccumulator)
                    FrameCount = 0
                    TimeAccumulator = 0
                end
            end)
            updater.Name = "FpsUpdater"
            FpsGui:SetAttribute("FpsUpdater", updater)
        end
    else
        local old = FpsGui:GetAttribute("FpsUpdater")
        if old then old:Disconnect(); FpsGui:SetAttribute("FpsUpdater", nil) end
    end
end

Tab1:CreateToggle({
    Name = "帧率显示",
    CurrentValue = false,
    Flag = "FpsDisplayToggle",
    Ext = true,
    Callback = function(Value) ToggleFpsDisplay(Value) end,
})

local VisualModule = { NormalNightVision=false, SuperNightVision=false, NoFog=false }

local function ApplyNormalNightVision(enable)
    VisualModule.NormalNightVision = enable
    if enable then
        Lighting.Brightness=10; Lighting.Ambient=Color3.fromRGB(220,220,220); Lighting.OutdoorAmbient=Color3.fromRGB(220,220,220)
        Lighting.EnvironmentDiffuseScale=1; Lighting.EnvironmentSpecularScale=1; Lighting.GlobalShadows=false; Lighting.ClockTime=8
        Lighting.ColorShift_Top=Color3.new(0,0,0); Lighting.ColorShift_Bottom=Color3.new(0,0,0)
        Notify("功能提示", "已开启夜视", 2)
    else
        for k,v in pairs(OriginalLighting) do pcall(function() Lighting[k] = v end) end
        Notify("功能提示", "已关闭夜视", 2)
    end
end

local function ApplySuperNightVision(enable)
    VisualModule.SuperNightVision = enable
    if enable then
        Lighting.Brightness = 70; Lighting.Ambient = Color3.fromRGB(255,255,255); Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        Lighting.GlobalShadows = false; Lighting.ClockTime = 12; Lighting.FogEnd = 100000; Lighting.EnvironmentDiffuseScale = 1
        Notify("功能提示", "已开启超级夜视", 2)
    else
        for k,v in pairs(OriginalLighting) do pcall(function() Lighting[k] = v end) end
        Notify("功能提示", "已关闭超级夜视", 2)
    end
end

local function ApplyNoFog(enable)
    VisualModule.NoFog = enable
    if enable then
        Lighting.FogStart = 0; Lighting.FogEnd = math.huge; Lighting.FogColor = Color3.fromRGB(200,200,220)
        for _, obj in pairs(Lighting:GetChildren()) do
            if obj:IsA("Atmosphere") then
                if not OriginalAtmosphere[obj] then OriginalAtmosphere[obj] = { Density=obj.Density, Offset=obj.Offset, Glare=obj.Glare, Haze=obj.Haze } end
                pcall(function() obj.Density=0; obj.Offset=0; obj.Glare=0; obj.Haze=0 end)
            end
        end
        Notify("功能提示", "已开启去雾", 2)
    else
        Lighting.FogStart = OriginalLighting.FogStart; Lighting.FogEnd = OriginalLighting.FogEnd; Lighting.FogColor = OriginalLighting.FogColor
        for obj, props in pairs(OriginalAtmosphere) do
            if obj and obj.Parent then pcall(function() obj.Density = props.Density; obj.Offset = props.Offset; obj.Glare = props.Glare; obj.Haze = props.Haze end) end
        end
        OriginalAtmosphere = {} 
        Notify("功能提示", "已关闭去雾", 2)
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if VisualModule.NormalNightVision then ApplyNormalNightVision(true) end
    if VisualModule.SuperNightVision then ApplySuperNightVision(true) end
    if VisualModule.NoFog then ApplyNoFog(true) end
end)

Tab1:CreateToggle({
    Name = "夜视",
    CurrentValue = false,
    Flag = "NightVisionToggle",
    Ext = true,
    Callback = function(Value)
        if Value then ApplyNormalNightVision(true)
        else ApplyNormalNightVision(false) end
    end,
})

Tab1:CreateToggle({
    Name = "超级夜视",
    CurrentValue = false,
    Flag = "SuperNightVisionToggle",
    Ext = true,
    Callback = function(Value)
        if Value then ApplySuperNightVision(true)
        else ApplySuperNightVision(false) end
    end,
})

Tab1:CreateToggle({
    Name = "彻底去雾",
    CurrentValue = false,
    Flag = "NoFogToggle",
    Ext = true,
    Callback = function(Value)
        if Value then ApplyNoFog(true)
        else ApplyNoFog(false) end
    end,
})

Tab1:CreateButton({
    Name = "关闭所有夜视/去雾",
    Ext = true,
    Callback = function()
        ApplyNormalNightVision(false); ApplySuperNightVision(false); ApplyNoFog(false)
        Notify("功能提示", "已关闭所有视觉特效", 2)
    end,
})

local NPCESP = { Enabled = false, Color = Color3.fromRGB(0,162,255), Highlights = {} }

local function GetNPCPart(model)
    if not model then return nil end
    if model:FindFirstChild("HumanoidRootPart") then return model.HumanoidRootPart end
    for _, part in pairs(model:GetDescendants()) do if part:IsA("BasePart") then return part end end
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
        h.Name = "NPCESP"; h.Adornee = model; h.FillColor = NPCESP.Color
        h.OutlineColor = Color3.fromRGB(255,255,255); h.FillTransparency = 0.4; h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; h.Parent = game.CoreGui
        return h
    end)
    if success and hl then
        NPCESP.Highlights[model] = hl
        task.delay(1, function() if hl and hl.Parent and (not hl.Adornee or hl.Adornee ~= model) then pcall(function() hl.Adornee = model end) end end)
        pcall(function() hl.AncestryChanged:Connect(function(_, parent) if not parent then pcall(function() hl:Destroy() end) NPCESP.Highlights[model] = nil end end) end)
    end
end

local function RemoveNPCESP(model)
    if not model then return end
    if NPCESP.Highlights[model] then pcall(function() if NPCESP.Highlights[model] and NPCESP.Highlights[model].Parent then NPCESP.Highlights[model]:Destroy() end end); NPCESP.Highlights[model] = nil end
end

local function ToggleNPCESP(state)
    NPCESP.Enabled = state
    if state then
        task.spawn(function() for _, obj in ipairs(Workspace:GetDescendants()) do if obj:IsA("Model") then task.spawn(AddNPCESP, obj) end end end)
        if not Connections.NPC then
            Connections.NPC = Workspace.DescendantAdded:Connect(function(child)
                task.delay(0.5, function() if child and child:IsA("Model") then AddNPCESP(child) elseif child and child:IsA("Humanoid") and child.Parent then AddNPCESP(child.Parent) end end)
            end)
        end
        task.spawn(function() while NPCESP.Enabled do for model, hl in pairs(NPCESP.Highlights) do if not model or not model.Parent or not hl or not hl.Parent then NPCESP.Highlights[model] = nil end end for _, obj in ipairs(Workspace:GetDescendants()) do if obj:IsA("Model") then AddNPCESP(obj) end end task.wait(2) end end)
    else
        local toRemove = {}
        for model, _ in pairs(NPCESP.Highlights) do table.insert(toRemove, model) end
        for _, model in ipairs(toRemove) do RemoveNPCESP(model) end
        if Connections.NPC then pcall(function() Connections.NPC:Disconnect() end); Connections.NPC = nil end
    end
end

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
            local char = p.Character; local hum = char:FindFirstChild("Humanoid"); local head = char:FindFirstChild("Head"); local root = char:FindFirstChild("HumanoidRootPart")
            if hum and head and root and hum.Health > -500 then
                local isTeam = (p.Team == LocalPlayer.Team); local filtered = PLAYER_ESP.TeamCheck and isTeam; local color = p.TeamColor.Color
                local high = char:FindFirstChild("PlayerESP_Highlight")
                if PLAYER_ESP.HighlightEnabled then
                    if not high then high = Instance.new("Highlight", char); high.Name = "PlayerESP_Highlight" end
                    high.FillColor = color; high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                elseif high then high:Destroy() end
                local box = char:FindFirstChild("PlayerESP_Box")
                if PLAYER_ESP.BoxEnabled and not filtered then
                    if not box then box = Instance.new("BillboardGui", char); box.Name = "PlayerESP_Box"; box.Size = UDim2.new(4.5,0,6,0); box.AlwaysOnTop = true; box.Adornee = root; local f = Instance.new("Frame", box); f.Size = UDim2.new(1,0,1,0); f.BackgroundTransparency = 1; local s = Instance.new("UIStroke", f); s.Thickness = 1.5 end
                    box.Frame.UIStroke.Color = color
                elseif box then box:Destroy() end
                local info = char:FindFirstChild("PlayerESP_Info")
                if not filtered then
                    if not info then info = Instance.new("BillboardGui", char); info.Name = "PlayerESP_Info"; info.Size = UDim2.new(0,200,0,50); info.AlwaysOnTop = true; info.Adornee = head; info.ExtentsOffset = Vector3.new(0,3.5,0); local txt = Instance.new("TextLabel", info); txt.Name = "Label"; txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.RichText = true; txt.TextStrokeTransparency = 0.5; txt.Font = Enum.Font.GothamMedium end
                    local text = ""
                    if PLAYER_ESP.ShowName then text = "<font color='#ffffff'><b>"..p.DisplayName.."</b></font>\n" end
                    if PLAYER_ESP.ShowHealth then local hp = math.floor(hum.Health); local hpColor = (hp > 50 and "#55ff55" or "#ff5555"); text = text .. "<font color='"..hpColor.."'>HP: "..hp.."</font> " end
                    if PLAYER_ESP.ShowDist then local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude); text = text .. "<font color='#ffffff'>| "..dist.."m</font>" end
                    info.Label.Text = text
                elseif info then info:Destroy() end
            end
        end
    end
end

RunService.RenderStepped:Connect(function() if PLAYER_ESP.Enabled then UpdatePlayerESP() end end)

Tab2:CreateToggle({
    Name = "NPC透视",
    CurrentValue = false,
    Flag = "NPCESP_Toggle",
    Ext = true,
    Callback = function(Value) ToggleNPCESP(Value); Notify("功能提示", Value and "已开启NPC透视" or "已关闭NPC透视", 2) end,
})

Tab2:CreateToggle({
    Name = "玩家透视总开关",
    CurrentValue = false,
    Flag = "PlayerESP_Main",
    Ext = true,
    Callback = function(Value) PLAYER_ESP.Enabled = Value; if not Value then ClearPlayerESP() end; Notify("功能提示", Value and "已开启玩家透视" or "已关闭玩家透视", 2) end,
})

Tab2:CreateToggle({ Name = "高亮", CurrentValue = false, Flag = "PlayerESP_Highlight", Ext = true, Callback = function(Value) PLAYER_ESP.HighlightEnabled = Value end, })
Tab2:CreateToggle({ Name = "方框", CurrentValue = false, Flag = "PlayerESP_Box", Ext = true, Callback = function(Value) PLAYER_ESP.BoxEnabled = Value end, })
Tab2:CreateToggle({ Name = "名字", CurrentValue = false, Flag = "PlayerESP_Name", Ext = true, Callback = function(Value) PLAYER_ESP.ShowName = Value end, })
Tab2:CreateToggle({ Name = "血量", CurrentValue = false, Flag = "PlayerESP_Health", Ext = true, Callback = function(Value) PLAYER_ESP.ShowHealth = Value end, })
Tab2:CreateToggle({ Name = "距离", CurrentValue = false, Flag = "PlayerESP_Dist", Ext = true, Callback = function(Value) PLAYER_ESP.ShowDist = Value end, })
Tab2:CreateToggle({ Name = "队伍检测", CurrentValue = false, Flag = "PlayerESP_Team", Ext = true, Callback = function(Value) PLAYER_ESP.TeamCheck = Value end, })

local ESP_SETTINGS = { HighlightEnabled = false, TeamCheck = false, SmoothAim = false, DistanceCheck = false, WallCheck = false }
local FOV = 120; local Smoothness = 0.18; local AimPart = "Head"; local ShowFOVCircle = true; local MaxDistance = 1000
local LockTargetEnabled = false; local SelectedTarget = nil; local AimbotTeamWhitelist = {}; local AimbotTeamWhitelistEnabled = false

local circle = Instance.new("Frame")
circle.Name = "FOVCircle"
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Position = UDim2.new(0.5, 0, 0.5, 0)
circle.Size = UDim2.new(0, 240, 0, 240)
circle.BackgroundTransparency = 1
circle.Parent = game.CoreGui
circle.Visible = false
local stroke = Instance.new("UIStroke"); stroke.Thickness = 2; stroke.Color = Color3.fromRGB(128, 0, 128); stroke.Parent = circle
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1, 0); corner.Parent = circle

local AimPartsList = { "Head", "HumanoidRootPart", "UpperTorso", "Torso" }

Tab3:CreateToggle({
    Name = "自瞄开关",
    CurrentValue = false,
    Flag = "AimbotMainToggle",
    Ext = true,
    Callback = function(Value)
        ESP_SETTINGS.HighlightEnabled = Value
        circle.Visible = Value and ShowFOVCircle
        Notify("功能提示", Value and "已开启自瞄" or "已关闭自瞄", 2)
    end,
})

Tab3:CreateToggle({
    Name = "显示FOV圈",
    CurrentValue = true,
    Flag = "ShowFOVCircleToggle",
    Ext = true,
    Callback = function(Value) ShowFOVCircle = Value; if ESP_SETTINGS.HighlightEnabled then circle.Visible = Value end end,
})

Tab3:CreateToggle({
    Name = "队伍检测",
    CurrentValue = false,
    Flag = "AimbotTeamCheck",
    Ext = true,
    Callback = function(Value) ESP_SETTINGS.TeamCheck = Value end,
})

Tab3:CreateToggle({
    Name = "墙体检测",
    CurrentValue = false,
    Flag = "AimbotWallCheck",
    Ext = true,
    Callback = function(Value) ESP_SETTINGS.WallCheck = Value end,
})

Tab3:CreateSlider({
    Name = "自瞄范围(FOV)",
    Value = { Min = 10, Max = 700, Default = FOV },
    Increment = 10,
    Callback = function(Value) FOV = Value end,
})

Tab3:CreateSlider({
    Name = "最大距离",
    Value = { Min = 50, Max = 6000, Default = MaxDistance },
    Increment = 50,
    Callback = function(Value) MaxDistance = Value end,
})

Tab3:CreateToggle({
    Name = "平滑自瞄",
    CurrentValue = false,
    Flag = "AimbotSmooth",
    Ext = true,
    Callback = function(Value) ESP_SETTINGS.SmoothAim = Value end,
})

Tab3:CreateDropdown({
    Name = "瞄准部位",
    Options = AimPartsList,
    CurrentOption = "Head",
    Flag = "AimbotPart",
    Callback = function(Value) AimPart = Value end,
})

Tab3:CreateToggle({
    Name = "指定自瞄目标",
    CurrentValue = false,
    Flag = "AimbotLockTarget",
    Ext = true,
    Callback = function(Value) LockTargetEnabled = Value end,
})

local AimbotPlayerList = {}
local PlayerDropdown = nil
local function RefreshAimbotPlayerList()
    AimbotPlayerList = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(AimbotPlayerList, p.Name) end end
    local lastSelected = SelectedTarget and SelectedTarget.Name or nil
    if PlayerDropdown then
        PlayerDropdown:Refresh(AimbotPlayerList, lastSelected)
    else
        PlayerDropdown = Tab3:CreateDropdown({
            Name = "选择玩家",
            Options = AimbotPlayerList,
            CurrentOption = lastSelected,
            Callback = function(Value)
                if typeof(Value) == "table" then Value = Value.Value or Value[1] end
                if not Value then return end
                local target = Players:FindFirstChild(Value)
                if target then SelectedTarget = target end
            end,
        })
    end
end

Tab3:CreateButton({
    Name = "刷新玩家列表",
    Ext = true,
    Callback = function() RefreshAimbotPlayerList() end,
})

task.delay(1, function() RefreshAimbotPlayerList() end)

task.spawn(function()
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = "通用脚本已加载", Text = " ", Duration = 3, Icon = "rbxassetid://128981664025072" })
    task.wait(3)
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = "每天周日更新", Text = " ", Duration = 3, Icon = "rbxassetid://128981664025072" })
    task.wait(3)
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = "感谢你的支持", Text = " ", Duration = 3, Icon = "rbxassetid://128981664025072" })
end)