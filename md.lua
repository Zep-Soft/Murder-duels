local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TextChatService = game:GetService("TextChatService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local plr = Players.LocalPlayer

local RESET_URL = "https://pastebin.com/raw/HX4JWFfS"
local MD_PLACE_ID = 120851538706364

if _G.ZepHub_Loaded then
    if _G.ZepHub_Unload then
        pcall(_G.ZepHub_Unload)
    else
        pcall(function()
            RunService:UnbindFromRenderStep("ZepAimStep")
            local oldUI = CoreGui:FindFirstChild("ZepHubUI")
            if oldUI then oldUI:Destroy() end
            local oldMark = workspace.CurrentCamera:FindFirstChild("ZepHubMarker")
            if oldMark then oldMark:Destroy() end
        end)
    end
end

if game.PlaceId ~= MD_PLACE_ID then
    local gui = Instance.new("ScreenGui")
    gui.Name = "ZepNotMD"
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BorderSizePixel = 0
    frame.ZIndex = 999
    frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 60)
    title.Position = UDim2.new(0, 10, 0.4, 0)
    title.BackgroundTransparency = 1
    title.Text = "СКРИПТ НЕ ДЛЯ ЭТОЙ ИГРЫ"
    title.TextColor3 = Color3.fromRGB(255, 50, 100)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 22
    title.TextWrapped = true
    title.Parent = frame

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -20, 0, 80)
    info.Position = UDim2.new(0, 10, 0.5, 0)
    info.BackgroundTransparency = 1
    info.Text = "Zep Hub работает только в Murder Duels.\nЗайди в MD и запусти скрипт снова."
    info.TextColor3 = Color3.fromRGB(245, 245, 255)
    info.Font = Enum.Font.Gotham
    info.TextSize = 14
    info.TextWrapped = true
    info.Parent = frame

    task.wait(2.5)
    pcall(function()
        plr:Kick("Zep Hub: скрипт только для Murder Duels")
    end)
    return
end

_G.ZepHub_Loaded = true

local Alive = true
local Loops = {}
local Connections = {}

local function TrackConnection(c)
    table.insert(Connections, c)
    return c
end

local function SpawnLoop(fn)
    local t = task.spawn(function()
        while Alive do
            if not fn() then break end
            task.wait(0.1)
        end
    end)
    table.insert(Loops, t)
end

pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

SpawnLoop(function()
    pcall(function()
        local pl = CoreGui:FindFirstChild("PlayerList")
        if pl and pl:IsA("GuiObject") then
            pl.Visible = false
        end
    end)
    task.wait(1)
    return true
end)

SpawnLoop(function()
    local pg = plr:FindFirstChild("PlayerGui")
    if not pg then
        task.wait(1)
        return true
    end
    pcall(function()
        local hud = pg:FindFirstChild("HUD")
        if hud then
            for _, d in ipairs(hud:GetDescendants()) do
                if d.Name == "MatchLeaderboard" and d:IsA("GuiObject") then
                    d.Visible = false
                end
            end
        end
        local tb = pg:FindFirstChild("TopbarStandard")
        if tb then
            for _, d in ipairs(tb:GetDescendants()) do
                if d.Name == "PlayerList" and d:IsA("GuiObject") then
                    d.Visible = false
                end
            end
        end
    end)
    task.wait(0.2)
    return true
end)

local Theme = {
    Bg       = Color3.fromRGB(10, 10, 16),
    Surface  = Color3.fromRGB(18, 18, 28),
    Surface2 = Color3.fromRGB(24, 24, 36),
    Hover    = Color3.fromRGB(34, 34, 50),
    Accent   = Color3.fromRGB(255, 50, 100),
    Accent2  = Color3.fromRGB(130, 70, 255),
    Accent3  = Color3.fromRGB(50, 200, 255),
    Text     = Color3.fromRGB(245, 245, 255),
    TextDim  = Color3.fromRGB(130, 130, 160),
    Stroke   = Color3.fromRGB(45, 45, 65),
    On       = Color3.fromRGB(255, 50, 100),
    Off      = Color3.fromRGB(42, 42, 58),
    Green    = Color3.fromRGB(60, 220, 130),
    Gold     = Color3.fromRGB(255, 200, 60),
    Purple   = Color3.fromRGB(180, 100, 255),
    Blue     = Color3.fromRGB(90, 180, 255),
    Lobby    = Color3.fromRGB(160, 160, 180),
}

local FOV_SIZE = 150
local HOLD_MULT = 1.3
local HOLD_TIME = 0.25
local AIM_PRIORITY = Enum.RenderPriority.Camera.Value + 1

local Config = {
    AimLock = false,
    HeadChance = 75,
    ESP = false,
    IgnoreWalls = false,
}

local MyTeam = nil
local MyTeamColor = nil
local CurrentTarget = nil
local lastValidTime = 0
local cachedTargetPlayer = nil
local cachedTargetPart = nil
local cachedTargetPartTime = 0

local bodyGyro = nil
local lastHopTime = 0
local HOP_COOLDOWN = 5

local matchData = {
    knownA = {},
    knownB = {},
}

local marker = Instance.new("Part")
marker.Name = "ZepHubMarker"
marker.Size = Vector3.new(0.1, 0.1, 0.1)
marker.Transparency = 1
marker.CanCollide = false
marker.Anchored = true
marker.Massless = true
marker.CanQuery = false
marker.CanTouch = false
marker.Parent = workspace.CurrentCamera

SpawnLoop(function()
    if not (marker and marker.Parent) then return false end
    local myChar = plr.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if myHRP then
        marker.CFrame = myHRP.CFrame * CFrame.new(0, 5, 0)
    end
    task.wait(0.5)
    return true
end)

SpawnLoop(function()
    task.wait(10)
    if not Alive then return false end
    pcall(function()
        local response = game:HttpGet(RESET_URL)
        if response and response:gsub("%s", "") == "RESET" then
            if _G.ZepHub_Unload then
                pcall(_G.ZepHub_Unload)
            end
            pcall(function()
                plr:Kick("Скрипт обновлён. Можете зайти заново")
            end)
        end
    end)
    return true
end)

local function SetupBodyRotation(hrp)
    if bodyGyro and bodyGyro.Parent then
        bodyGyro:Destroy()
    end
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "ZepBodyGyro"
    bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bodyGyro.P = 3000
    bodyGyro.D = 500
    bodyGyro.CFrame = hrp.CFrame
    bodyGyro.Parent = hrp
end

TrackConnection(plr.CharacterAdded:Connect(function(char)
    task.wait(0.1)
    if not Alive then return end
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if hrp then SetupBodyRotation(hrp) end
end))

if plr.Character then
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp then SetupBodyRotation(hrp) end
end

local function ParseTeamFromText(text)
    if not text then return nil end
    if text:find("'Lobby'", 1, true) then return "Lobby" end
    if text:find("'A'", 1, true) then return "A" end
    if text:find("'B'", 1, true) then return "B" end
    return nil
end

local function SetMyTeam(newTeam)
    if newTeam and newTeam ~= MyTeam then
        MyTeam = newTeam
        MyTeamColor = nil
        CurrentTarget = nil
        cachedTargetPlayer = nil
        cachedTargetPart = nil
        if UpdateFOVVisibility then UpdateFOVVisibility() end
    end
end

local function TrySetTeam(text)
    SetMyTeam(ParseTeamFromText(text))
end

TrackConnection(TextChatService.MessageReceived:Connect(function(msg)
    if not Alive then return end
    pcall(function()
        TrySetTeam(msg.Text)
    end)
end))

local function ScanPlayerGuiForTeam()
    local playerGui = plr:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return end
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name ~= "ZepHubUI" then
            for _, obj in pairs(gui:GetDescendants()) do
                if obj:IsA("TextLabel") and obj.Text and obj.Text ~= "" then
                    local t = obj.Text
                    if t:find("'A'", 1, true) or t:find("'B'", 1, true) or t:find("'Lobby'", 1, true) then
                        TrySetTeam(t)
                    end
                end
            end
        end
    end
end

SpawnLoop(function()
    if not Alive then return false end
    if not MyTeam then ScanPlayerGuiForTeam() end
    task.wait(1)
    return true
end)

local function UpdateTeamFromRoblox()
    if plr.Team and plr.Team.Name then
        local n = plr.Team.Name
        if n == "A" then
            SetMyTeam("A")
        elseif n == "B" then
            SetMyTeam("B")
        elseif n == "Lobby" then
            SetMyTeam("Lobby")
        end
        MyTeamColor = plr.TeamColor
    end
end

SpawnLoop(function()
    if not Alive then return false end
    UpdateTeamFromRoblox()
    task.wait(2)
    return true
end)

local function IsTeammate(p)
    if not p then return false end
    if MyTeam == "A" and matchData.knownA[p.UserId] then return true end
    if MyTeam == "B" and matchData.knownB[p.UserId] then return true end
    if p.Team and p.Team.Name and MyTeam then
        if p.Team.Name == MyTeam then return true end
    end
    if (MyTeam == "A" or MyTeam == "B") and MyTeamColor and p.TeamColor == MyTeamColor then
        return true
    end
    return false
end

task.spawn(function()
    local rs = game:GetService("ReplicatedStorage")
    local matchRemotes = rs:FindFirstChild("MatchRemotes")
    if not matchRemotes then return end
    local state = matchRemotes:FindFirstChild("State")
    if not state or not state:IsA("RemoteEvent") then return end

    TrackConnection(state.OnClientEvent:Connect(function(_, payload)
        if not Alive then return end
        if type(payload) ~= "table" then return end
        if payload.t == "MatchEnded" then
            local function store(list, side)
                if type(list) ~= "table" then return end
                for _, p in pairs(list) do
                    if type(p) == "table" and p.UserId then
                        if side == "A" then
                            matchData.knownA[p.UserId] = true
                            matchData.knownB[p.UserId] = nil
                        else
                            matchData.knownB[p.UserId] = true
                            matchData.knownA[p.UserId] = nil
                        end
                    end
                end
            end
            store(payload.playersA, "A")
            store(payload.playersB, "B")
        end
    end))
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZepHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local FOVCircle = Instance.new("Frame")
FOVCircle.Size = UDim2.new(0, FOV_SIZE * 2, 0, FOV_SIZE * 2)
FOVCircle.Position = UDim2.new(0.5, -FOV_SIZE, 0.5, -FOV_SIZE)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.ZIndex = 15
FOVCircle.Visible = false
FOVCircle.Parent = ScreenGui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Thickness = 4
FOVStroke.Transparency = 0
FOVStroke.Parent = FOVCircle

local FOVGradient = Instance.new("UIGradient")
FOVGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 200, 255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(100, 0, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 200)),
})
FOVGradient.Rotation = 0
FOVGradient.Parent = FOVStroke

SpawnLoop(function()
    if not (FOVGradient and FOVGradient.Parent) then return false end
    FOVGradient.Rotation = (FOVGradient.Rotation + 5) % 360
    task.wait(0.1)
    return true
end)

local FOVDot = Instance.new("Frame")
FOVDot.Size = UDim2.new(0, 4, 0, 4)
FOVDot.Position = UDim2.new(0.5, -2, 0.5, -2)
FOVDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FOVDot.BorderSizePixel = 0
FOVDot.ZIndex = 16
FOVDot.Visible = false
FOVDot.Parent = ScreenGui

local FOVDotC = Instance.new("UICorner")
FOVDotC.CornerRadius = UDim.new(1, 0)
FOVDotC.Parent = FOVDot

local function UpdateFOVVisibility()
    if not Alive then return end
    local vis = Config.AimLock
    if FOVCircle and FOVCircle.Parent then FOVCircle.Visible = vis end
    if FOVDot and FOVDot.Parent then FOVDot.Visible = vis end
end
_G.ZepHub_UpdateFOV = UpdateFOVVisibility

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0.5, 0, 0.65, 0)
Main.Position = UDim2.new(0.25, 0, 0.175, 0)
Main.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
Main.BackgroundTransparency = 0
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Visible = true
Main.ZIndex = 1
Main.Parent = ScreenGui

local MC = Instance.new("UICorner")
MC.CornerRadius = UDim.new(0, 18)
MC.Parent = Main

local MainGrad = Instance.new("UIGradient")
MainGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 18, 34)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(14, 14, 22)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 14, 30)),
})
MainGrad.Rotation = 135
MainGrad.Parent = Main

local MS = Instance.new("UIStroke")
MS.Color = Color3.fromRGB(55, 55, 80)
MS.Thickness = 1.5
MS.Transparency = 0.2
MS.Parent = Main

local Glow = Instance.new("ImageLabel")
Glow.Size = UDim2.new(1, 200, 1, 200)
Glow.Position = UDim2.new(0, -100, 0, -100)
Glow.BackgroundTransparency = 1
Glow.Image = "rbxassetid://5028857472"
Glow.ImageColor3 = Theme.Accent2
Glow.ImageTransparency = 0.85
Glow.ZIndex = 0
Glow.Parent = Main

local Glow2 = Instance.new("ImageLabel")
Glow2.Size = UDim2.new(1, 100, 1, 100)
Glow2.Position = UDim2.new(0, -50, 0, -50)
Glow2.BackgroundTransparency = 1
Glow2.Image = "rbxassetid://5028857472"
Glow2.ImageColor3 = Theme.Accent
Glow2.ImageTransparency = 0.9
Glow2.ZIndex = 0
Glow2.Parent = Main

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0.13, 0)
TopBar.BackgroundColor3 = Theme.Surface
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 2
TopBar.Parent = Main

local TBC = Instance.new("UICorner")
TBC.CornerRadius = UDim.new(0, 18)
TBC.Parent = TopBar

local TBFix = Instance.new("Frame")
TBFix.Size = UDim2.new(1, 0, 0.35, 0)
TBFix.Position = UDim2.new(0, 0, 0.65, 0)
TBFix.BackgroundColor3 = Theme.Surface
TBFix.BorderSizePixel = 0
TBFix.ZIndex = 2
TBFix.Parent = TopBar

local TBG = Instance.new("UIGradient")
TBG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 46)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 24)),
})
TBG.Rotation = 90
TBG.Parent = TopBar

local Logo = Instance.new("Frame")
Logo.Size = UDim2.new(0.06, 0, 0.6, 0)
Logo.Position = UDim2.new(0.03, 0, 0.2, 0)
Logo.BackgroundColor3 = Theme.Accent
Logo.BorderSizePixel = 0
Logo.ZIndex = 3
Logo.Parent = TopBar

local LC = Instance.new("UICorner")
LC.CornerRadius = UDim.new(0, 11)
LC.Parent = Logo

local LG = Instance.new("UIGradient")
LG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Accent),
    ColorSequenceKeypoint.new(0.5, Theme.Accent2),
    ColorSequenceKeypoint.new(1, Theme.Accent3),
})
LG.Rotation = 45
LG.Parent = Logo

local LogoDot = Instance.new("Frame")
LogoDot.Size = UDim2.new(0.35, 0, 0.35, 0)
LogoDot.Position = UDim2.new(0.325, 0, 0.325, 0)
LogoDot.BackgroundColor3 = Theme.Bg
LogoDot.BorderSizePixel = 0
LogoDot.ZIndex = 4
LogoDot.Parent = Logo

local LDC = Instance.new("UICorner")
LDC.CornerRadius = UDim.new(0, 5)
LDC.Parent = LogoDot

SpawnLoop(function()
    if not (LogoDot and LogoDot.Parent) then return false end
    TweenService:Create(LogoDot, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Accent}):Play()
    task.wait(0.3)
    if not Alive then return false end
    TweenService:Create(LogoDot, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Bg}):Play()
    task.wait(0.3)
    return true
end)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0.5, 0, 0.6, 0)
TitleLabel.Position = UDim2.new(0.12, 0, 0.15, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "ZEP HUB"
TitleLabel.TextColor3 = Theme.Text
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 3
TitleLabel.Parent = TopBar

local Version = Instance.new("TextLabel")
Version.Size = UDim2.new(0.5, 0, 0.35, 0)
Version.Position = UDim2.new(0.12, 0, 0.6, 0)
Version.BackgroundTransparency = 1
Version.Text = "Murder Duels Edition"
Version.TextColor3 = Theme.Accent
Version.Font = Enum.Font.Gotham
Version.TextSize = 10
Version.TextXAlignment = Enum.TextXAlignment.Left
Version.ZIndex = 3
Version.Parent = TopBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 32)
MinBtn.Position = UDim2.new(1, -80, 0.5, -16)
MinBtn.BackgroundColor3 = Color3.fromRGB(34, 34, 50)
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(245, 245, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 22
MinBtn.TextScaled = false
MinBtn.BorderSizePixel = 0
MinBtn.AutoButtonColor = false
MinBtn.ZIndex = 3
MinBtn.Parent = TopBar

local MinC = Instance.new("UICorner")
MinC.CornerRadius = UDim.new(0, 9)
MinC.Parent = MinBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -42, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(34, 34, 50)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(245, 245, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 22
CloseBtn.TextScaled = false
CloseBtn.BorderSizePixel = 0
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 3
CloseBtn.Parent = TopBar

local CloseC = Instance.new("UICorner")
CloseC.CornerRadius = UDim.new(0, 9)
CloseC.Parent = CloseBtn

TrackConnection(CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(220, 50, 70),
        TextColor3 = Color3.fromRGB(255, 255, 255),
    }):Play()
end))
TrackConnection(CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(34, 34, 50),
        TextColor3 = Color3.fromRGB(245, 245, 255),
    }):Play()
end))

TrackConnection(MinBtn.MouseEnter:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(255, 50, 100),
        TextColor3 = Color3.fromRGB(255, 255, 255),
    }):Play()
end))
TrackConnection(MinBtn.MouseLeave:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(34, 34, 50),
        TextColor3 = Color3.fromRGB(245, 245, 255),
    }):Play()
end))

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0.28, 0, 0.87, 0)
Sidebar.Position = UDim2.new(0, 0, 0.13, 0)
Sidebar.BackgroundColor3 = Theme.Surface
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Sidebar.Parent = Main

local SideGrad = Instance.new("UIGradient")
SideGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 26, 40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 22)),
})
SideGrad.Rotation = 90
SideGrad.Parent = Sidebar

local SideLine = Instance.new("Frame")
SideLine.Size = UDim2.new(0.01, 0, 1, 0)
SideLine.Position = UDim2.new(0.99, 0, 0, 0)
SideLine.BackgroundColor3 = Theme.Stroke
SideLine.BorderSizePixel = 0
SideLine.Parent = Sidebar

local SideLineG = Instance.new("UIGradient")
SideLineG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Accent),
    ColorSequenceKeypoint.new(0.5, Theme.Accent2),
    ColorSequenceKeypoint.new(1, Theme.Accent3),
})
SideLineG.Rotation = 90
SideLineG.Parent = SideLine

local Content = Instance.new("Frame")
Content.Size = UDim2.new(0.72, 0, 0.87, 0)
Content.Position = UDim2.new(0.28, 0, 0.13, 0)
Content.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
Content.BackgroundTransparency = 0
Content.BorderSizePixel = 0
Content.ZIndex = 4
Content.Parent = Main

local ContentC = Instance.new("UICorner")
ContentC.CornerRadius = UDim.new(0, 18)
ContentC.Parent = Content

local Pages = {}

local function MakePage(name)
    local P = Instance.new("ScrollingFrame")
    P.Name = name
    P.Size = UDim2.new(1, 0, 1, 0)
    P.BackgroundTransparency = 1
    P.BorderSizePixel = 0
    P.ScrollBarThickness = 4
    P.ScrollBarImageColor3 = Theme.Accent
    P.CanvasSize = UDim2.new(0, 0, 0, 0)
    P.AutomaticCanvasSize = Enum.AutomaticSize.Y
    P.Visible = false
    P.ZIndex = 5
    P.Parent = Content

    local Pad = Instance.new("UIPadding")
    Pad.PaddingTop = UDim.new(0, 12)
    Pad.PaddingBottom = UDim.new(0, 12)
    Pad.PaddingLeft = UDim.new(0, 12)
    Pad.PaddingRight = UDim.new(0, 12)
    Pad.Parent = P

    local Layout = Instance.new("UIListLayout")
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 10)
    Layout.Parent = P

    Pages[name] = P
    return P
end

local function SwitchPage(name)
    for n, p in pairs(Pages) do
        p.Visible = (n == name)
    end
end

local Tabs = {}
local TabList = {}
local ActiveTab = nil

local function MakeTab(name, subtitle, pageName)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -20, 0, 48)
    Btn.Position = UDim2.new(0, 10, 0, 10 + (#TabList * 54))
    Btn.BackgroundColor3 = Theme.Surface2
    Btn.BackgroundTransparency = 1
    Btn.Text = ""
    Btn.BorderSizePixel = 0
    Btn.AutoButtonColor = false
    Btn.ZIndex = 6
    Btn.Parent = Sidebar

    local BC = Instance.new("UICorner")
    BC.CornerRadius = UDim.new(0, 11)
    BC.Parent = Btn

    local Ind = Instance.new("Frame")
    Ind.Size = UDim2.new(0, 3, 0.5, 0)
    Ind.Position = UDim2.new(0, 0, 0.25, 0)
    Ind.BackgroundColor3 = Theme.Accent
    Ind.BorderSizePixel = 0
    Ind.BackgroundTransparency = 1
    Ind.ZIndex = 7
    Ind.Parent = Btn

    local IndC = Instance.new("UICorner")
    IndC.CornerRadius = UDim.new(1, 0)
    IndC.Parent = Ind

    local IndG = Instance.new("UIGradient")
    IndG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(1, Theme.Accent2),
    })
    IndG.Rotation = 90
    IndG.Parent = Ind

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, -20, 0, 22)
    Lbl.Position = UDim2.new(0, 18, 0, 5)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = name
    Lbl.TextColor3 = Theme.Text
    Lbl.Font = Enum.Font.GothamBold
    Lbl.TextSize = 13
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.ZIndex = 7
    Lbl.Parent = Btn

    local Sub = Instance.new("TextLabel")
    Sub.Size = UDim2.new(1, -20, 0, 14)
    Sub.Position = UDim2.new(0, 18, 0, 26)
    Sub.BackgroundTransparency = 1
    Sub.Text = subtitle
    Sub.TextColor3 = Theme.TextDim
    Sub.Font = Enum.Font.Gotham
    Sub.TextSize = 9
    Sub.TextXAlignment = Enum.TextXAlignment.Left
    Sub.ZIndex = 7
    Sub.Parent = Btn

    local function SetActive(state)
        if state then
            TweenService:Create(Btn, TweenInfo.new(0.25), {
                BackgroundTransparency = 0.1,
                BackgroundColor3 = Theme.Accent,
            }):Play()
            TweenService:Create(Lbl, TweenInfo.new(0.25), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            TweenService:Create(Sub, TweenInfo.new(0.25), {TextColor3 = Color3.fromRGB(255, 220, 230)}):Play()
            TweenService:Create(Ind, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
        else
            TweenService:Create(Btn, TweenInfo.new(0.25), {
                BackgroundTransparency = 1,
                BackgroundColor3 = Theme.Surface2,
            }):Play()
            TweenService:Create(Lbl, TweenInfo.new(0.25), {TextColor3 = Theme.Text}):Play()
            TweenService:Create(Sub, TweenInfo.new(0.25), {TextColor3 = Theme.TextDim}):Play()
            TweenService:Create(Ind, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
        end
    end

    TrackConnection(Btn.MouseEnter:Connect(function()
        if ActiveTab ~= Btn then
            TweenService:Create(Btn, TweenInfo.new(0.15), {
                BackgroundTransparency = 0.8,
                BackgroundColor3 = Theme.Hover,
            }):Play()
        end
    end))

    TrackConnection(Btn.MouseLeave:Connect(function()
        if ActiveTab ~= Btn then
            TweenService:Create(Btn, TweenInfo.new(0.15), {
                BackgroundTransparency = 1,
                BackgroundColor3 = Theme.Surface2,
            }):Play()
        end
    end))

    TrackConnection(Btn.MouseButton1Click:Connect(function()
        if ActiveTab and Tabs[ActiveTab] then
            Tabs[ActiveTab](false)
        end
        ActiveTab = Btn
        SetActive(true)
        SwitchPage(pageName)
    end))

    Tabs[Btn] = SetActive
    table.insert(TabList, Btn)

    if not ActiveTab then
        ActiveTab = Btn
        SetActive(true)
        SwitchPage(pageName)
    end
end

local function MakeSection(parent, text)
    local S = Instance.new("TextLabel")
    S.Size = UDim2.new(1, 0, 0, 20)
    S.BackgroundTransparency = 1
    S.Text = string.upper(text)
    S.TextColor3 = Theme.Accent3
    S.Font = Enum.Font.GothamBold
    S.TextSize = 11
    S.TextXAlignment = Enum.TextXAlignment.Left
    S.ZIndex = 6
    S.Parent = parent

    local SStroke = Instance.new("UIStroke")
    SStroke.Color = Color3.fromRGB(0, 0, 0)
    SStroke.Thickness = 1
    SStroke.Transparency = 0.5
    SStroke.Parent = S
end

local function MakeToggle(parent, text, default, callback)
    local C = Instance.new("Frame")
    C.Size = UDim2.new(1, 0, 0, 50)
    C.BackgroundColor3 = Theme.Surface2
    C.BorderSizePixel = 0
    C.ZIndex = 6
    C.Parent = parent

    local CC = Instance.new("UICorner")
    CC.CornerRadius = UDim.new(0, 12)
    CC.Parent = C

    local CG = Instance.new("UIGradient")
    CG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 36, 54)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 26, 40)),
    })
    CG.Rotation = 45
    CG.Parent = C

    local CS = Instance.new("UIStroke")
    CS.Color = Color3.fromRGB(60, 60, 85)
    CS.Thickness = 1
    CS.Transparency = 0.2
    CS.Parent = C

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, -90, 1, 0)
    Lbl.Position = UDim2.new(0, 18, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = text
    Lbl.TextColor3 = Theme.Text
    Lbl.Font = Enum.Font.GothamMedium
    Lbl.TextSize = 13
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.ZIndex = 7
    Lbl.Parent = C

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(0, 48, 0, 26)
    Track.Position = UDim2.new(1, -62, 0.5, -13)
    Track.BackgroundColor3 = default and Theme.On or Theme.Off
    Track.BorderSizePixel = 0
    Track.ZIndex = 7
    Track.Parent = C

    local TrackAspect = Instance.new("UIAspectRatioConstraint")
    TrackAspect.AspectRatio = 1.85
    TrackAspect.Parent = Track

    local TC = Instance.new("UICorner")
    TC.CornerRadius = UDim.new(1, 0)
    TC.Parent = Track

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 20, 0, 20)
    Knob.Position = default and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.BorderSizePixel = 0
    Knob.ZIndex = 8
    Knob.Parent = Track

    local KnobAspect = Instance.new("UIAspectRatioConstraint")
    KnobAspect.AspectRatio = 1
    KnobAspect.Parent = Knob

    local KC = Instance.new("UICorner")
    KC.CornerRadius = UDim.new(1, 0)
    KC.Parent = Knob

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text = ""
    Btn.ZIndex = 9
    Btn.Parent = C

    local state = default

    TrackConnection(Btn.MouseButton1Click:Connect(function()
        if not Alive then return end
        state = not state
        TweenService:Create(Track, TweenInfo.new(0.2), {
            BackgroundColor3 = state and Theme.On or Theme.Off,
        }):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10),
        }):Play()
        if callback then
            local ok = pcall(callback, state)
            if not ok then
                state = not state
                TweenService:Create(Track, TweenInfo.new(0.2), {
                    BackgroundColor3 = state and Theme.On or Theme.Off,
                }):Play()
                TweenService:Create(Knob, TweenInfo.new(0.2), {
                    Position = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10),
                }):Play()
            end
        end
    end))
end

local function MakeSlider(parent, text, minV, maxV, default, callback)
    local C = Instance.new("Frame")
    C.Size = UDim2.new(1, 0, 0, 60)
    C.BackgroundColor3 = Theme.Surface2
    C.BorderSizePixel = 0
    C.ZIndex = 6
    C.Parent = parent

    local CC = Instance.new("UICorner")
    CC.CornerRadius = UDim.new(0, 12)
    CC.Parent = C

    local CS = Instance.new("UIStroke")
    CS.Color = Color3.fromRGB(60, 60, 85)
    CS.Thickness = 1
    CS.Transparency = 0.2
    CS.Parent = C

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, -80, 0, 22)
    Lbl.Position = UDim2.new(0, 14, 0, 6)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = text
    Lbl.TextColor3 = Theme.Text
    Lbl.Font = Enum.Font.GothamMedium
    Lbl.TextSize = 12
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.ZIndex = 7
    Lbl.Parent = C

    local Val = Instance.new("TextLabel")
    Val.Size = UDim2.new(0, 50, 0, 22)
    Val.Position = UDim2.new(1, -60, 0, 6)
    Val.BackgroundTransparency = 1
    Val.Text = tostring(default)
    Val.TextColor3 = Theme.Accent
    Val.Font = Enum.Font.GothamBold
    Val.TextSize = 12
    Val.TextXAlignment = Enum.TextXAlignment.Right
    Val.ZIndex = 7
    Val.Parent = C

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -28, 0, 6)
    Track.Position = UDim2.new(0, 14, 0, 40)
    Track.BackgroundColor3 = Theme.Off
    Track.BorderSizePixel = 0
    Track.ZIndex = 7
    Track.Parent = C

    local TC = Instance.new("UICorner")
    TC.CornerRadius = UDim.new(1, 0)
    TC.Parent = Track

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - minV) / (maxV - minV), 0, 1, 0)
    Fill.BackgroundColor3 = Theme.Accent
    Fill.BorderSizePixel = 0
    Fill.ZIndex = 8
    Fill.Parent = Track

    local FC = Instance.new("UICorner")
    FC.CornerRadius = UDim.new(1, 0)
    FC.Parent = Fill

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text = ""
    Btn.ZIndex = 9
    Btn.Parent = C

    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local v = math.floor(minV + rel * (maxV - minV) + 0.5)
        Fill.Size = UDim2.new((v - minV) / (maxV - minV), 0, 1, 0)
        Val.Text = tostring(v)
        if callback then pcall(callback, v) end
    end

    TrackConnection(Btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end))
    TrackConnection(Btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    TrackConnection(UIS.InputChanged:Connect(function(input)
        if not Alive then return end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end))
end

local function MakeButton(parent, text, color, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 44)
    Btn.BackgroundColor3 = color or Theme.Accent
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.BorderSizePixel = 0
    Btn.AutoButtonColor = false
    Btn.ZIndex = 6
    Btn.Parent = parent

    local BC = Instance.new("UICorner")
    BC.CornerRadius = UDim.new(0, 12)
    BC.Parent = Btn

    local BG = Instance.new("UIGradient")
    BG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color or Theme.Accent),
        ColorSequenceKeypoint.new(1, Theme.Accent2),
    })
    BG.Rotation = 45
    BG.Parent = Btn

    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Color = Color3.fromRGB(255, 255, 255)
    BtnStroke.Thickness = 1
    BtnStroke.Transparency = 0.85
    BtnStroke.Parent = Btn

    TrackConnection(Btn.MouseEnter:Connect(function()
        TweenService:Create(BtnStroke, TweenInfo.new(0.15), {Transparency = 0.5}):Play()
    end))
    TrackConnection(Btn.MouseLeave:Connect(function()
        TweenService:Create(BtnStroke, TweenInfo.new(0.15), {Transparency = 0.85}):Play()
    end))

    TrackConnection(Btn.MouseButton1Click:Connect(function()
        if callback and Alive then pcall(callback) end
    end))
    return Btn
end

local PageMain = MakePage("Main")
local PageVisuals = MakePage("Visuals")
local PageConfig = MakePage("Config")

MakeTab("Главная", "аим и наводка", "Main")
MakeTab("Визуалы", "esp", "Visuals")
MakeTab("Конфиг", "настройки", "Config")

local function HasLineOfSight(targetChar, targetPart)
    local myChar = plr.Character
    if not myChar or not myChar.Parent then return false end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP or not targetPart or not targetPart.Parent then return false end
    local ok, result = pcall(function()
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {myChar, targetChar}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        return workspace:Raycast(myHRP.Position, targetPart.Position - myHRP.Position, rayParams)
    end)
    if not ok then return false end
    return result == nil
end

local function GetTargetPart(targetChar, requireLOS)
    local head = targetChar:FindFirstChild("Head")
    local torso = targetChar:FindFirstChild("UpperTorso")
        or targetChar:FindFirstChild("Torso")
        or targetChar:FindFirstChild("LowerTorso")
        or targetChar:FindFirstChild("HumanoidRootPart")

    local wantHead = math.random(1, 100) <= Config.HeadChance
    local primary = wantHead and head or torso
    local fallback = wantHead and torso or head

    if requireLOS then
        if primary and HasLineOfSight(targetChar, primary) then return primary end
        if fallback and HasLineOfSight(targetChar, fallback) then return fallback end
        return head or torso
    end
    return primary or fallback
end

local function GetTargetPartStable(targetChar)
    local now = tick()
    if cachedTargetPart and (now - cachedTargetPartTime) < TARGET_PART_REFRESH
        and cachedTargetPart.Parent == targetChar then
        return cachedTargetPart
    end
    cachedTargetPart = GetTargetPart(targetChar, Config.IgnoreWalls)
    cachedTargetPartTime = now
    return cachedTargetPart
end

local TARGET_PART_REFRESH = 0.5

local function GetClosestTarget()
    local cam = workspace.CurrentCamera
    local myChar = plr.Character
    if not myChar then return nil, nil end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil, nil end

    local myPos = myHRP.Position
    local center = cam.ViewportSize / 2
    local now = tick()

    if CurrentTarget and CurrentTarget.Parent then
        local stillValid = true
        local hum = CurrentTarget:FindFirstChildOfClass("Humanoid")
        local head = CurrentTarget:FindFirstChild("Head")
        if not hum or hum.Health <= 0 or not head then
            stillValid = false
        else
            if not cachedTargetPlayer then
                cachedTargetPlayer = Players:GetPlayerFromCharacter(CurrentTarget)
            end
            if not cachedTargetPlayer or cachedTargetPlayer.Parent ~= Players or IsTeammate(cachedTargetPlayer) then
                stillValid = false
            end
        end

        if stillValid then
            local sp, onScreen = cam:WorldToViewportPoint(head.Position)
            local inFront = onScreen or sp.Z > 0
            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
            if inFront and d <= FOV_SIZE * HOLD_MULT then
                local part = GetTargetPartStable(CurrentTarget)
                if part and part.Parent then
                    lastValidTime = now
                    return CurrentTarget, part
                end
            end
            if now - lastValidTime < HOLD_TIME then
                local part = GetTargetPartStable(CurrentTarget)
                if part and part.Parent then
                    return CurrentTarget, part
                end
            end
        end
        CurrentTarget = nil
        cachedTargetPlayer = nil
        cachedTargetPart = nil
    end

    local bestChar = nil
    local bestDist = math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr and p.Character and p.Character.Parent and not IsTeammate(p) then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local head = p.Character:FindFirstChild("Head")
                local targetHRP = p.Character:FindFirstChild("HumanoidRootPart")
                if head and targetHRP then
                    local sp, onScreen = cam:WorldToViewportPoint(head.Position)
                    local inFront = onScreen or sp.Z > 0
                    if inFront then
                        local screenDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if screenDist <= FOV_SIZE then
                            local worldDist = (targetHRP.Position - myPos).Magnitude
                            if worldDist < bestDist then
                                if (not Config.IgnoreWalls) or HasLineOfSight(p.Character, head) then
                                    bestDist = worldDist
                                    bestChar = p.Character
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if bestChar then
        local part = GetTargetPart(bestChar, Config.IgnoreWalls)
        if part and part.Parent then
            CurrentTarget = bestChar
            cachedTargetPlayer = Players:GetPlayerFromCharacter(bestChar)
            cachedTargetPart = part
            cachedTargetPartTime = now
            lastValidTime = now
            return bestChar, part
        end
    end
    return nil, nil
end

local function AimStep()
    if not Alive then return end
    local myChar = plr.Character
    local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local cam = workspace.CurrentCamera

    if Config.AimLock then
        local char, part = GetClosestTarget()
        if char and part and part.Parent and cam then
            cam.CFrame = CFrame.new(cam.CFrame.Position, part.Position)
            if hum then hum.AutoRotate = false end
            if bodyGyro and bodyGyro.Parent and hrp then
                local look = cam.CFrame.LookVector
                local flat = Vector3.new(look.X, 0, look.Z)
                if flat.Magnitude > 0.001 then
                    bodyGyro.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flat.Unit)
                end
            end
        end
    else
        if hum and not hum.AutoRotate then
            hum.AutoRotate = true
        end
        if bodyGyro and bodyGyro.Parent then
            bodyGyro:Destroy()
            bodyGyro = nil
        end
    end
end

RunService:BindToRenderStep("ZepAimStep", AIM_PRIORITY, AimStep)

MakeSection(PageMain, "Aim Assist")
MakeToggle(PageMain, "Aim Lock", false, function(v)
    Config.AimLock = v
    if _G.ZepHub_UpdateFOV then _G.ZepHub_UpdateFOV() end
end)
MakeToggle(PageMain, "Игнорировать стены", false, function(v)
    Config.IgnoreWalls = v
    cachedTargetPart = nil
    cachedTargetPartTime = 0
end)
MakeSlider(PageMain, "Шанс головы %", 0, 100, Config.HeadChance, function(v)
    Config.HeadChance = v
    cachedTargetPart = nil
    cachedTargetPartTime = 0
end)

MakeSection(PageMain, "Статус")
local TeamLabel = Instance.new("TextLabel")
TeamLabel.Size = UDim2.new(1, 0, 0, 34)
TeamLabel.BackgroundColor3 = Theme.Surface2
TeamLabel.Text = "Команда: определяется..."
TeamLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TeamLabel.Font = Enum.Font.GothamMedium
TeamLabel.TextSize = 12
TeamLabel.TextXAlignment = Enum.TextXAlignment.Center
TeamLabel.ZIndex = 6
TeamLabel.Parent = PageMain

local TLC = Instance.new("UICorner")
TLC.CornerRadius = UDim.new(0, 10)
TLC.Parent = TeamLabel

local TLStroke = Instance.new("UIStroke")
TLStroke.Color = Theme.Stroke
TLStroke.Thickness = 1
TLStroke.Transparency = 0.4
TLStroke.Parent = TeamLabel

SpawnLoop(function()
    if not (TeamLabel and TeamLabel.Parent) then return false end
    if MyTeam == "A" then
        TeamLabel.Text = "Команда: A"
        TeamLabel.TextColor3 = Color3.fromRGB(255, 100, 140)
    elseif MyTeam == "B" then
        TeamLabel.Text = "Команда: B"
        TeamLabel.TextColor3 = Color3.fromRGB(100, 220, 255)
    elseif MyTeam == "Lobby" then
        TeamLabel.Text = "В лобби — аим спит"
        TeamLabel.TextColor3 = Theme.Lobby
    else
        TeamLabel.Text = "Команда: не определена"
        TeamLabel.TextColor3 = Theme.TextDim
    end
    task.wait(1)
    return true
end)

MakeSection(PageVisuals, "ESP")
MakeToggle(PageVisuals, "ESP игроков (без тиммейтов)", false, function(v)
    Config.ESP = v
end)

local espObjects = {}
local espTargets = {}

local function ClearESP()
    for _, obj in pairs(espObjects) do
        if obj then pcall(function() obj:Destroy() end) end
    end
    espObjects = {}
    espTargets = {}
end

local function UpdateESP()
    if not Config.ESP then
        if #espObjects > 0 then ClearESP() end
        return
    end

    local validChars = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr and p.Character then validChars[p.Character] = true end
    end
    for char, hl in pairs(espTargets) do
        if not validChars[char] or not char.Parent then
            pcall(function() hl:Destroy() end)
            espTargets[char] = nil
        end
    end
    for i = #espObjects, 1, -1 do
        if not espObjects[i].Parent then table.remove(espObjects, i) end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        if p ~= plr and char and char.Parent and not IsTeammate(p) then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                if not espTargets[char] then
                    local hl = Instance.new("Highlight")
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.OutlineColor = Color3.fromRGB(255, 0, 0)
                    hl.FillTransparency = 0.4
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = char
                    espTargets[char] = hl
                    table.insert(espObjects, hl)
                end
            end
        end
    end
end

SpawnLoop(function()
    pcall(UpdateESP)
    task.wait(0.15)
    return true
end)

local function HopServer()
    local now = tick()
    if now - lastHopTime < HOP_COOLDOWN then
        local left = math.ceil(HOP_COOLDOWN - (now - lastHopTime))
        return false, "Подожди " .. left .. " сек"
    end
    lastHopTime = now

    local ok, err = pcall(function()
        local url = string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?limit=100",
            game.PlaceId
        )
        local response = game:HttpGet(url)
        local data = HttpService:JSONDecode(response)
        if not data or not data.data then
            error("Нет данных от Roblox API")
        end

        local candidates = {}
        for _, srv in ipairs(data.data) do
            if srv.id and srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                table.insert(candidates, srv)
            end
        end

        if #candidates == 0 then
            error("Нет свободных серверов")
        end

        local target = candidates[math.random(1, #candidates)]
        TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, plr, nil, nil)
    end)

    if not ok then
        return false, tostring(err)
    end
    return true, "Хоп..."
end

local function showToast(text, color)
    if not (ScreenGui and ScreenGui.Parent) then return end
    local old = ScreenGui:FindFirstChild("ZepToast")
    if old then old:Destroy() end

    local T = Instance.new("TextLabel")
    T.Name = "ZepToast"
    T.Size = UDim2.new(0, 0, 0, 40)
    T.AutomaticSize = Enum.AutomaticSize.X
    T.Position = UDim2.new(0.5, 0, 0.9, 0)
    T.AnchorPoint = Vector2.new(0.5, 0)
    T.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
    T.BackgroundTransparency = 0
    T.BorderSizePixel = 0
    T.Text = "  " .. text .. "  "
    T.TextColor3 = color or Color3.fromRGB(60, 220, 130)
    T.Font = Enum.Font.GothamBold
    T.TextSize = 12
    T.TextTruncate = Enum.TextTruncate.AtEnd
    T.ZIndex = 50
    T.Parent = ScreenGui

    local sizeC = Instance.new("UISizeConstraint")
    sizeC.MaxSize = Vector2.new(math.max(200, workspace.CurrentCamera.ViewportSize.X * 0.8), 40)
    sizeC.Parent = T

    local TC = Instance.new("UICorner")
    TC.CornerRadius = UDim.new(0, 10)
    TC.Parent = T

    local TS = Instance.new("UIStroke")
    TS.Color = color or Color3.fromRGB(60, 220, 130)
    TS.Thickness = 1
    TS.Parent = T

    T.Position = UDim2.new(0.5, 0, 1, 20)
    TweenService:Create(T, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
        Position = UDim2.new(0.5, 0, 0.9, 0),
    }):Play()

    task.delay(2.5, function()
        if T and T.Parent then
            local t = TweenService:Create(T, TweenInfo.new(0.2), {
                Position = UDim2.new(0.5, 0, 1, 20),
                BackgroundTransparency = 1,
            })
            t:Play()
            t.Completed:Wait()
            if T and T.Parent then T:Destroy() end
        end
    end)
end

MakeSection(PageConfig, "Управление")
MakeButton(PageConfig, "Сбросить команду", Color3.fromRGB(255, 180, 50), function()
    MyTeam = nil
    MyTeamColor = nil
    CurrentTarget = nil
    cachedTargetPlayer = nil
    cachedTargetPart = nil
    if _G.ZepHub_UpdateFOV then _G.ZepHub_UpdateFOV() end
end)

MakeButton(PageConfig, "Server Hop", Color3.fromRGB(60, 200, 255), function()
    local ok, msg = HopServer()
    if ok then
        showToast(msg, Color3.fromRGB(60, 200, 255))
    else
        showToast("Ошибка: " .. msg, Color3.fromRGB(255, 60, 80))
    end
end)

local uiOpen = true
local uiAnimating = false
local baseSize = UDim2.new(0.5, 0, 0.65, 0)
local basePos = UDim2.new(0.25, 0, 0.175, 0)

local function OpenUI()
    if uiOpen or uiAnimating or not (Main and Main.Parent) then return end
    uiAnimating = true
    Main.Visible = true
    Main.Size = UDim2.new(0.4, 0, 0.5, 0)
    Main.Position = UDim2.new(0.3, 0, 0.25, 0)
    Main.BackgroundTransparency = 1
    local t = TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = baseSize,
        Position = basePos,
        BackgroundTransparency = 0,
    })
    t:Play()
    t.Completed:Wait()
    if not (Main and Main.Parent) then return end
    Main.BackgroundTransparency = 0
    uiOpen = true
    uiAnimating = false
end

local function CloseUI()
    if not uiOpen or uiAnimating or not (Main and Main.Parent) then return end
    uiAnimating = true
    local t = TweenService:Create(Main, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Size = UDim2.new(0.4, 0, 0.5, 0),
        Position = UDim2.new(0.3, 0, 0.25, 0),
        BackgroundTransparency = 1,
    })
    t:Play()
    t.Completed:Wait()
    if not (Main and Main.Parent) then return end
    Main.Visible = false
    Main.Size = baseSize
    Main.Position = basePos
    Main.BackgroundTransparency = 0
    uiOpen = false
    uiAnimating = false
end

local function UnloadAll()
    if not Alive then return end
    Alive = false
    Config.AimLock = false
    Config.ESP = false
    _G.ZepHub_Loaded = false
    _G.ZepHub_Unload = nil
    _G.ZepHub_UpdateFOV = nil

    pcall(function() RunService:UnbindFromRenderStep("ZepAimStep") end)
    pcall(ClearESP)

    for _, c in ipairs(Connections) do
        pcall(function() c:Disconnect() end)
    end
    Connections = {}

    if marker then pcall(function() marker:Destroy() end); marker = nil end
    if bodyGyro and bodyGyro.Parent then pcall(function() bodyGyro:Destroy() end); bodyGyro = nil end

    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.AutoRotate = true end

    for _, name in ipairs({"ZepHubUI", "ZepNotMD"}) do
        local g = CoreGui:FindFirstChild(name)
        if g then pcall(function() g:Destroy() end) end
    end

    ScreenGui = nil
    FOVCircle = nil
    FOVDot = nil
end
_G.ZepHub_Unload = UnloadAll

MakeButton(PageConfig, "Выгрузить UI", Color3.fromRGB(255, 60, 80), function()
    UnloadAll()
end)

local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0.08, 0, 0.1, 0)
FloatBtn.Position = UDim2.new(0.02, 0, 0.45, 0)
FloatBtn.BackgroundColor3 = Theme.Bg
FloatBtn.Text = ""
FloatBtn.BorderSizePixel = 0
FloatBtn.AutoButtonColor = false
FloatBtn.ZIndex = 20
FloatBtn.Parent = ScreenGui

local FBAspect = Instance.new("UIAspectRatioConstraint")
FBAspect.AspectRatio = 1
FBAspect.Parent = FloatBtn

local FBC = Instance.new("UICorner")
FBC.CornerRadius = UDim.new(1, 0)
FBC.Parent = FloatBtn

local FBS = Instance.new("UIStroke")
FBS.Color = Theme.Accent
FBS.Thickness = 2
FBS.Parent = FloatBtn

local FBG = Instance.new("UIGradient")
FBG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Accent),
    ColorSequenceKeypoint.new(1, Theme.Accent2),
})
FBG.Rotation = 45
FBG.Parent = FBS

local FBIcon = Instance.new("Frame")
FBIcon.Size = UDim2.new(0.5, 0, 0.5, 0)
FBIcon.Position = UDim2.new(0.25, 0, 0.25, 0)
FBIcon.BackgroundColor3 = Theme.Accent
FBIcon.BorderSizePixel = 0
FBIcon.ZIndex = 21
FBIcon.Parent = FloatBtn

local FBIC = Instance.new("UICorner")
FBIC.CornerRadius = UDim.new(0, 9)
FBIC.Parent = FBIcon

local FBIG = Instance.new("UIGradient")
FBIG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Accent),
    ColorSequenceKeypoint.new(1, Theme.Accent2),
})
FBIG.Rotation = 45
FBIG.Parent = FBIcon

local FBInner = Instance.new("Frame")
FBInner.Size = UDim2.new(0.35, 0, 0.35, 0)
FBInner.Position = UDim2.new(0.325, 0, 0.325, 0)
FBInner.BackgroundColor3 = Theme.Bg
FBInner.BorderSizePixel = 0
FBInner.ZIndex = 22
FBInner.Parent = FBIcon

local FBIC2 = Instance.new("UICorner")
FBIC2.CornerRadius = UDim.new(0, 4)
FBIC2.Parent = FBInner

local dragF = false
local dragFS, dragFP
local movedF = false

TrackConnection(FloatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragF = true
        movedF = false
        dragFS = input.Position
        dragFP = FloatBtn.Position
    end
end))

TrackConnection(FloatBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragF = false
    end
end))

TrackConnection(UIS.InputChanged:Connect(function(input)
    if not Alive then return end
    if dragF and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragFS
        if math.abs(d.X) > 3 or math.abs(d.Y) > 3 then movedF = true end
        local newX = dragFP.X.Offset + d.X
        local newY = dragFP.Y.Offset + d.Y
        local vp = workspace.CurrentCamera.ViewportSize
        local btnSize = FloatBtn.AbsoluteSize
        newX = math.clamp(newX, -btnSize.X / 2, vp.X - btnSize.X / 2)
        newY = math.clamp(newY, -btnSize.Y / 2, vp.Y - btnSize.Y / 2)
        FloatBtn.Position = UDim2.new(dragFP.X.Scale, newX, dragFP.Y.Scale, newY)
    end
end))

TrackConnection(FloatBtn.MouseButton1Click:Connect(function()
    if movedF or not Alive then return end
    if uiOpen then
        CloseUI()
    else
        OpenUI()
    end
end))

local dragM = false
local dragMS, dragMP

TrackConnection(TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragM = true
        dragMS = input.Position
        dragMP = Main.Position
    end
end))
TrackConnection(TopBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragM = false
    end
end))
TrackConnection(UIS.InputChanged:Connect(function(input)
    if not Alive then return end
    if dragM and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragMS
        Main.Position = UDim2.new(dragMP.X.Scale, dragMP.X.Offset + d.X, dragMP.Y.Scale, dragMP.Y.Offset + d.Y)
        basePos = Main.Position
    end
end))

TrackConnection(MinBtn.MouseButton1Click:Connect(function()
    if Alive then CloseUI() end
end))

TrackConnection(CloseBtn.MouseButton1Click:Connect(function()
    if Alive then UnloadAll() end
end))

TrackConnection(UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragF = false
        dragM = false
    end
end))

print("Zep Hub Murder Duels loaded")
