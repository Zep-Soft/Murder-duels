local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TextChatService = game:GetService("TextChatService")
local plr = Players.LocalPlayer

local MD_PLACE_ID = 120851538706364
local SCRIPT_URL = "https://raw.githubusercontent.com/Zep-Soft/Murder-duels/refs/heads/main/md.lua"

if game.PlaceId ~= MD_PLACE_ID then
    pcall(function()
        queue_on_teleport('loadstring(game:HttpGet("' .. SCRIPT_URL .. '"))()')
    end)

    local TpGui = Instance.new("ScreenGui")
    TpGui.Name = "ZepTeleport"
    TpGui.ResetOnSpawn = false
    TpGui.Parent = CoreGui

    local TpFrame = Instance.new("Frame")
    TpFrame.Size = UDim2.new(0, 340, 0, 110)
    TpFrame.Position = UDim2.new(0.5, -170, 0.5, -55)
    TpFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
    TpFrame.BorderSizePixel = 0
    TpFrame.Parent = TpGui

    local TpC = Instance.new("UICorner")
    TpC.CornerRadius = UDim.new(0, 14)
    TpC.Parent = TpFrame

    local TpS = Instance.new("UIStroke")
    TpS.Color = Color3.fromRGB(255, 50, 100)
    TpS.Thickness = 1.5
    TpS.Parent = TpFrame

    local TpTitle = Instance.new("TextLabel")
    TpTitle.Size = UDim2.new(1, -20, 0, 30)
    TpTitle.Position = UDim2.new(0, 14, 0, 12)
    TpTitle.BackgroundTransparency = 1
    TpTitle.Text = "ZEP HUB"
    TpTitle.TextColor3 = Color3.fromRGB(255, 50, 100)
    TpTitle.Font = Enum.Font.GothamBlack
    TpTitle.TextSize = 16
    TpTitle.TextXAlignment = Enum.TextXAlignment.Left
    TpTitle.Parent = TpFrame

    local TpStatus = Instance.new("TextLabel")
    TpStatus.Size = UDim2.new(1, -20, 0, 20)
    TpStatus.Position = UDim2.new(0, 14, 0, 44)
    TpStatus.BackgroundTransparency = 1
    TpStatus.Text = "Телепорт в Murder Duels..."
    TpStatus.TextColor3 = Color3.fromRGB(245, 245, 255)
    TpStatus.Font = Enum.Font.Gotham
    TpStatus.TextSize = 12
    TpStatus.TextXAlignment = Enum.TextXAlignment.Left
    TpStatus.Parent = TpFrame

    local TpInfo = Instance.new("TextLabel")
    TpInfo.Size = UDim2.new(1, -20, 0, 20)
    TpInfo.Position = UDim2.new(0, 14, 0, 68)
    TpInfo.BackgroundTransparency = 1
    TpInfo.Text = "Скрипт загрузится автоматически"
    TpInfo.TextColor3 = Color3.fromRGB(130, 130, 160)
    TpInfo.Font = Enum.Font.Gotham
    TpInfo.TextSize = 10
    TpInfo.TextXAlignment = Enum.TextXAlignment.Left
    TpInfo.Parent = TpFrame

    task.wait(1.5)

    local ok, err = pcall(function()
        TeleportService:Teleport(MD_PLACE_ID, plr)
    end)

    if not ok then
        TpStatus.Text = "Ошибка: " .. tostring(err)
        TpStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
        TpInfo.Text = "Зайди в Murder Duels вручную"
    end

    return
end

if _G.ZepHub_Loaded then
    local old = CoreGui:FindFirstChild("ZepHubUI")
    if old then old:Destroy() end
end
_G.ZepHub_Loaded = true

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
}

local FOV_SIZE = 250
local RENDER_PRIORITY = 3000
local HOLD_MULT = 2.0
local HOLD_TIME = 1.0

local Config = {
    AimLock = false,
    AimHold = false,
    HeadChance = 75,
    ESP = false,
    HeadDot = false,
    AntiAFK = false,
    IgnoreWalls = false,
}

local MyTeam = nil
local MyTeamColor = nil
local CurrentTarget = nil
local lastValidTime = 0

local function TrySetTeam(text)
    if not text then return end

    local newTeam = nil

    if text:find("'A'", 1, true) or text:find('"A"', 1, true) then
        newTeam = "A"
    elseif text:find("'B'", 1, true) or text:find('"B"', 1, true) then
        newTeam = "B"
    end

    if newTeam and newTeam ~= MyTeam then
        MyTeam = newTeam
        CurrentTarget = nil
        print("[Zep Hub] Team:", MyTeam)
    end
end

TextChatService.MessageReceived:Connect(function(msg)
    pcall(function()
        TrySetTeam(msg.Text)
    end)
end)

task.spawn(function()
    local playerGui = plr:WaitForChild("PlayerGui")

    local function scanAll()
        for _, gui in pairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, obj in pairs(gui:GetDescendants()) do
                    if obj:IsA("TextLabel") and obj.Text and obj.Text ~= "" then
                        TrySetTeam(obj.Text)
                    end
                end
            end
        end
    end

    task.spawn(function()
        while true do
            task.wait(0.5)
            if not MyTeam then
                scanAll()
            end
        end
    end)
end)

task.spawn(function()
    while true do
        task.wait(2)
        if plr.Team and plr.Team.Name then
            local n = plr.Team.Name
            if n == "A" or n:find("A") then
                if MyTeam ~= "A" then
                    MyTeam = "A"
                    CurrentTarget = nil
                end
            elseif n == "B" or n:find("B") then
                if MyTeam ~= "B" then
                    MyTeam = "B"
                    CurrentTarget = nil
                end
            end
            MyTeamColor = plr.TeamColor
        end
    end
end)

local function IsTeammate(p)
    if not MyTeam then return false end

    if p.Team and p.Team.Name then
        local n = p.Team.Name:upper()
        if n == MyTeam then return true end
        if n:find("A") and MyTeam == "A" then return true end
        if n:find("B") and MyTeam == "B" then return true end
    end

    if MyTeamColor and p.TeamColor == MyTeamColor then
        return true
    end

    return false
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZepHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
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

task.spawn(function()
    while FOVCircle and FOVCircle.Parent do
        task.wait(0.05)
        FOVGradient.Rotation = (FOVGradient.Rotation + 5) % 360
    end
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
    local show = Config.AimLock or Config.AimHold
    FOVCircle.Visible = show
    FOVDot.Visible = show
end

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 600, 0, 460)
Main.Position = UDim2.new(0.5, -300, 0.5, -230)
Main.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
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
TopBar.Size = UDim2.new(1, 0, 0, 60)
TopBar.BackgroundColor3 = Theme.Surface
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 2
TopBar.Parent = Main

local TBC = Instance.new("UICorner")
TBC.CornerRadius = UDim.new(0, 18)
TBC.Parent = TopBar

local TBFix = Instance.new("Frame")
TBFix.Size = UDim2.new(1, 0, 0, 20)
TBFix.Position = UDim2.new(0, 0, 1, -20)
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
Logo.Size = UDim2.new(0, 36, 0, 36)
Logo.Position = UDim2.new(0, 18, 0.5, -18)
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
LogoDot.Size = UDim2.new(0, 12, 0, 12)
LogoDot.Position = UDim2.new(0.5, -6, 0.5, -6)
LogoDot.BackgroundColor3 = Theme.Bg
LogoDot.BorderSizePixel = 0
LogoDot.ZIndex = 4
LogoDot.Parent = Logo

local LDC = Instance.new("UICorner")
LDC.CornerRadius = UDim.new(0, 5)
LDC.Parent = LogoDot

task.spawn(function()
    while LogoDot and LogoDot.Parent do
        task.wait(0.6)
        TweenService:Create(LogoDot, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Accent}):Play()
        task.wait(0.3)
        TweenService:Create(LogoDot, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Bg}):Play()
    end
end)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 200, 0, 24)
TitleLabel.Position = UDim2.new(0, 66, 0, 10)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "ZEP HUB"
TitleLabel.TextColor3 = Theme.Text
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 3
TitleLabel.Parent = TopBar

local Version = Instance.new("TextLabel")
Version.Size = UDim2.new(0, 220, 0, 14)
Version.Position = UDim2.new(0, 66, 0, 34)
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
MinBtn.Position = UDim2.new(1, -78, 0.5, -16)
MinBtn.BackgroundColor3 = Theme.Surface2
MinBtn.Text = "−"
MinBtn.TextColor3 = Theme.TextDim
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.BorderSizePixel = 0
MinBtn.AutoButtonColor = false
MinBtn.ZIndex = 3
MinBtn.Parent = TopBar

local MinC = Instance.new("UICorner")
MinC.CornerRadius = UDim.new(0, 9)
MinC.Parent = MinBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -16)
CloseBtn.BackgroundColor3 = Theme.Surface2
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Theme.TextDim
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
CloseBtn.BorderSizePixel = 0
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 3
CloseBtn.Parent = TopBar

local CloseC = Instance.new("UICorner")
CloseC.CornerRadius = UDim.new(0, 9)
CloseC.Parent = CloseBtn

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(220, 50, 70),
        TextColor3 = Color3.fromRGB(255, 255, 255),
    }):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Theme.Surface2,
        TextColor3 = Theme.TextDim,
    }):Play()
end)

MinBtn.MouseEnter:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Theme.Accent,
        TextColor3 = Color3.fromRGB(255, 255, 255),
    }):Play()
end)
MinBtn.MouseLeave:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Theme.Surface2,
        TextColor3 = Theme.TextDim,
    }):Play()
end)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 170, 1, -60)
Sidebar.Position = UDim2.new(0, 0, 0, 60)
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
SideLine.Size = UDim2.new(0, 1, 1, 0)
SideLine.Position = UDim2.new(1, 0, 0, 0)
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
Content.Size = UDim2.new(1, -170, 1, -60)
Content.Position = UDim2.new(0, 170, 0, 60)
Content.BackgroundTransparency = 1
Content.ZIndex = 5
Content.Parent = Main

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
    Pad.PaddingTop = UDim.new(0, 14)
    Pad.PaddingBottom = UDim.new(0, 14)
    Pad.PaddingLeft = UDim.new(0, 16)
    Pad.PaddingRight = UDim.new(0, 16)
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
local ActiveTab = nil

local function MakeTab(name, subtitle, pageName)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -20, 0, 48)
    Btn.Position = UDim2.new(0, 10, 0, 10 + (#Tabs * 54))
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

    Btn.MouseEnter:Connect(function()
        if ActiveTab ~= Btn then
            TweenService:Create(Btn, TweenInfo.new(0.15), {
                BackgroundTransparency = 0.8,
                BackgroundColor3 = Theme.Hover,
            }):Play()
        end
    end)

    Btn.MouseLeave:Connect(function()
        if ActiveTab ~= Btn then
            TweenService:Create(Btn, TweenInfo.new(0.15), {
                BackgroundTransparency = 1,
                BackgroundColor3 = Theme.Surface2,
            }):Play()
        end
    end)

    Btn.MouseButton1Click:Connect(function()
        if ActiveTab and Tabs[ActiveTab] then
            Tabs[ActiveTab](false)
        end
        ActiveTab = Btn
        SetActive(true)
        SwitchPage(pageName)
    end)

    Tabs[Btn] = SetActive
    table.insert(Tabs, Btn)

    if not ActiveTab then
        ActiveTab = Btn
        SetActive(true)
        SwitchPage(pageName)
    end

    return Btn
end

local function MakeSection(parent, text)
    local S = Instance.new("TextLabel")
    S.Size = UDim2.new(1, 0, 0, 20)
    S.BackgroundTransparency = 1
    S.Text = string.upper(text)
    S.TextColor3 = Theme.Accent
    S.Font = Enum.Font.GothamBold
    S.TextSize = 10
    S.TextXAlignment = Enum.TextXAlignment.Left
    S.ZIndex = 6
    S.Parent = parent

    local Pad = Instance.new("UIPadding")
    Pad.PaddingLeft = UDim.new(0, 4)
    Pad.Parent = S

    return S
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
        ColorSequenceKeypoint.new(0, Color3.fromRGB(32, 28, 46)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 20, 32)),
    })
    CG.Rotation = 45
    CG.Parent = C

    local CS = Instance.new("UIStroke")
    CS.Color = Theme.Stroke
    CS.Thickness = 1
    CS.Transparency = 0.4
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
    Lbl.TextStrokeTransparency = 0.5
    Lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    Lbl.ZIndex = 7
    Lbl.Parent = C

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(0, 48, 0, 26)
    Track.Position = UDim2.new(1, -62, 0.5, -13)
    Track.BackgroundColor3 = default and Theme.On or Theme.Off
    Track.BorderSizePixel = 0
    Track.ZIndex = 7
    Track.Parent = C

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

    Btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(Track, TweenInfo.new(0.2), {
            BackgroundColor3 = state and Theme.On or Theme.Off,
        }):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10),
        }):Play()
        if callback then callback(state) end
    end)

    C.MouseEnter:Connect(function()
        TweenService:Create(C, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Hover}):Play()
    end)

    C.MouseLeave:Connect(function()
        TweenService:Create(C, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Surface2}):Play()
    end)

    return C
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
    Btn.TextStrokeTransparency = 0.4
    Btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
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

    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.15), {
            Size = UDim2.new(1, 6, 0, 46),
        }):Play()
    end)

    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.15), {
            Size = UDim2.new(1, 0, 0, 44),
        }):Play()
    end)

    Btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    return Btn
end

local PageMain = MakePage("Main")
local PageVisuals = MakePage("Visuals")
local PageConfig = MakePage("Config")

MakeTab("Главная", "аим и наводка", "Main")
MakeTab("Визуалы", "esp", "Visuals")
MakeTab("Конфиг", "настройки", "Config")

local function GetTargetPart(targetChar)
    local head = targetChar:FindFirstChild("Head")
    local torso = targetChar:FindFirstChild("UpperTorso")
        or targetChar:FindFirstChild("Torso")
        or targetChar:FindFirstChild("LowerTorso")
        or targetChar:FindFirstChild("HumanoidRootPart")

    if math.random(1, 100) <= Config.HeadChance then
        return head or torso
    else
        return torso or head
    end
end

local function HasLineOfSight(targetChar)
    local myChar = plr.Character
    if not myChar then return false end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return false end

    local targetHead = targetChar:FindFirstChild("Head")
    if not targetHead then return false end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {myChar}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local dir = targetHead.Position - myHRP.Position
    local result = workspace:Raycast(myHRP.Position, dir, rayParams)

    if result then
        if result.Instance:IsDescendantOf(targetChar) then
            return true
        end
        return false
    end
    return true
end

local function GetClosestTarget()
    local cam = workspace.CurrentCamera
    local myChar = plr.Character
    if not myChar then return nil, nil end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil, nil end

    local myPos = myHRP.Position
    local center = cam.ViewportSize / 2
    local now = tick()

    if CurrentTarget then
        local stillValid = true
        local hum = CurrentTarget:FindFirstChildOfClass("Humanoid")
        local head = CurrentTarget:FindFirstChild("Head")

        if not hum or hum.Health <= 0 or not head then
            stillValid = false
        else
            local player = Players:GetPlayerFromCharacter(CurrentTarget)
            if not player or IsTeammate(player) then
                stillValid = false
            elseif Config.IgnoreWalls and not HasLineOfSight(CurrentTarget) then
                stillValid = false
            end
        end

        if stillValid then
            local sp, onScreen = cam:WorldToViewportPoint(head.Position)
            if onScreen then
                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if d <= FOV_SIZE * HOLD_MULT then
                    lastValidTime = now
                    return CurrentTarget, GetTargetPart(CurrentTarget)
                end
            end

            if now - lastValidTime < HOLD_TIME then
                return CurrentTarget, GetTargetPart(CurrentTarget)
            end
        end

        CurrentTarget = nil
    end

    local bestChar = nil
    local bestPart = nil
    local bestDist = math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr and p.Character and not IsTeammate(p) then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local head = p.Character:FindFirstChild("Head")
                local targetHRP = p.Character:FindFirstChild("HumanoidRootPart")

                if head and targetHRP then
                    local sp, onScreen = cam:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local screenDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude

                        if screenDist <= FOV_SIZE then
                            local worldDist = (targetHRP.Position - myPos).Magnitude

                            if worldDist < bestDist then
                                if (not Config.IgnoreWalls) or HasLineOfSight(p.Character) then
                                    bestDist = worldDist
                                    bestChar = p.Character
                                    bestPart = GetTargetPart(p.Character)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if bestChar then
        CurrentTarget = bestChar
        lastValidTime = now
        return bestChar, bestPart
    end

    return nil, nil
end

local aimHeld = false

UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimHeld = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimHeld = false
    end
end)

RunService:BindToRenderStep("ZepAimStep", RENDER_PRIORITY, function()
    if Config.AimLock or (Config.AimHold and aimHeld) then
        local char, part = GetClosestTarget()
        if char and part then
            local cam = workspace.CurrentCamera
            cam.CFrame = CFrame.new(cam.CFrame.Position, part.Position)

            local myChar = plr.Character
            local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if hrp then
                local lookPos = Vector3.new(part.Position.X, hrp.Position.Y, part.Position.Z)
                hrp.CFrame = CFrame.new(hrp.Position, lookPos)
            end
        end
    end
end)

MakeSection(PageMain, "Aim Assist")
MakeToggle(PageMain, "Aim Lock (всегда)", false, function(v)
    Config.AimLock = v
    UpdateFOVVisibility()
end)

MakeToggle(PageMain, "Aim Hold (на ПКМ)", false, function(v)
    Config.AimHold = v
    UpdateFOVVisibility()
end)

MakeToggle(PageMain, "Игнорировать стены (аим через стены)", false, function(v)
    Config.IgnoreWalls = v
end)

MakeSection(PageMain, "Статус")
local TeamLabel = Instance.new("TextLabel")
TeamLabel.Size = UDim2.new(1, 0, 0, 30)
TeamLabel.BackgroundColor3 = Theme.Surface2
TeamLabel.Text = "Команда: определяется..."
TeamLabel.TextColor3 = Theme.Text
TeamLabel.Font = Enum.Font.GothamMedium
TeamLabel.TextSize = 12
TeamLabel.ZIndex = 6
TeamLabel.Parent = PageMain

local TLC = Instance.new("UICorner")
TLC.CornerRadius = UDim.new(0, 10)
TLC.Parent = TeamLabel

task.spawn(function()
    while true do
        task.wait(1)
        if MyTeam then
            TeamLabel.Text = "Команда: " .. MyTeam
            TeamLabel.TextColor3 = Theme.Green
        else
            TeamLabel.Text = "Команда: не определена"
            TeamLabel.TextColor3 = Theme.TextDim
        end
    end
end)

MakeSection(PageMain, "Прочее")
MakeToggle(PageMain, "Anti-AFK", false, function(v)
    Config.AntiAFK = v
    if v then
        task.spawn(function()
            while Config.AntiAFK do
                task.wait(60)
                pcall(function()
                    game:GetService("VirtualUser"):CaptureController()
                    game:GetService("VirtualUser"):ClickButton1(Vector2.new())
                end)
            end
        end)
    end
end)

MakeSection(PageVisuals, "ESP")
MakeToggle(PageVisuals, "ESP игроков (без тиммейтов)", false, function(v)
    Config.ESP = v
end)

MakeToggle(PageVisuals, "Head Dot (точка на голове)", false, function(v)
    Config.HeadDot = v
end)

local espObjects = {}

local function ClearESP()
    for _, obj in pairs(espObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    espObjects = {}
end

RunService.Heartbeat:Connect(function()
    if Config.ESP or Config.HeadDot then
        ClearESP()

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= plr and p.Character and not IsTeammate(p) then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local head = p.Character:FindFirstChild("Head")

                if hum and hum.Health > 0 and head then
                    if Config.ESP then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = Color3.fromRGB(255, 0, 0)
                        hl.OutlineColor = Color3.fromRGB(255, 0, 0)
                        hl.FillTransparency = 0.4
                        hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = p.Character
                        table.insert(espObjects, hl)
                    end

                    if Config.HeadDot then
                        local dot = Instance.new("BillboardGui")
                        dot.Size = UDim2.new(0, 10, 0, 10)
                        dot.AlwaysOnTop = true
                        dot.Parent = head

                        local circle = Instance.new("Frame")
                        circle.Size = UDim2.new(1, 0, 1, 0)
                        circle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                        circle.BorderSizePixel = 0
                        circle.Parent = dot

                        local cc = Instance.new("UICorner")
                        cc.CornerRadius = UDim.new(1, 0)
                        cc.Parent = circle

                        table.insert(espObjects, dot)
                    end
                end
            end
        end
    elseif #espObjects > 0 then
        ClearESP()
    end
end)

MakeSection(PageConfig, "Управление")
MakeButton(PageConfig, "Сбросить команду", Color3.fromRGB(255, 180, 50), function()
    MyTeam = nil
    MyTeamColor = nil
end)

MakeButton(PageConfig, "Выгрузить UI", Color3.fromRGB(255, 60, 80), function()
    Config.AimLock = false
    Config.AimHold = false
    Config.ESP = false
    Config.AntiAFK = false
    pcall(function()
        RunService:UnbindFromRenderStep("ZepAimStep")
    end)
    ScreenGui:Destroy()
    _G.ZepHub_Loaded = false
end)

local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 60, 0, 60)
FloatBtn.Position = UDim2.new(0, 22, 0.5, -30)
FloatBtn.BackgroundColor3 = Theme.Bg
FloatBtn.Text = ""
FloatBtn.BorderSizePixel = 0
FloatBtn.AutoButtonColor = false
FloatBtn.ZIndex = 20
FloatBtn.Parent = ScreenGui

local FBC = Instance.new("UICorner")
FBC.CornerRadius = UDim.new(1, 0)
FBC.Parent = FloatBtn

local FBS = Instance.new("UIStroke")
FBS.Color = Theme.Accent
FBS.Thickness = 2
FBS.Parent = FloatBtn

local FBIcon = Instance.new("Frame")
FBIcon.Size = UDim2.new(0, 28, 0, 28)
FBIcon.Position = UDim2.new(0.5, -14, 0.5, -14)
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
FBInner.Size = UDim2.new(0, 10, 0, 10)
FBInner.Position = UDim2.new(0.5, -5, 0.5, -5)
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

FloatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragF = true
        movedF = false
        dragFS = input.Position
        dragFP = FloatBtn.Position
    end
end)

FloatBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragF = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragF and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragFS
        if math.abs(d.X) > 3 or math.abs(d.Y) > 3 then movedF = true end
        FloatBtn.Position = UDim2.new(dragFP.X.Scale, dragFP.X.Offset + d.X, dragFP.Y.Scale, dragFP.Y.Offset + d.Y)
    end
end)

FloatBtn.MouseButton1Click:Connect(function()
    if movedF then return end
    if Main.Visible then
        local t = TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
        })
        t:Play()
        t.Completed:Connect(function()
            Main.Visible = false
        end)
    else
        Main.Size = UDim2.new(0, 0, 0, 0)
        Main.Position = UDim2.new(0.5, 0, 0.5, 0)
        Main.Visible = true
        task.wait(0.02)
        TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 600, 0, 460),
            Position = UDim2.new(0.5, -300, 0.5, -230),
        }):Play()
    end
end)

local dragM, dragMS, dragMP

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragM = true
        dragMS = input.Position
        dragMP = Main.Position
    end
end)

TopBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragM = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragM and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragMS
        Main.Position = UDim2.new(dragMP.X.Scale, dragMP.X.Offset + d.X, dragMP.Y.Scale, dragMP.Y.Offset + d.Y)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    Config.AimLock = false
    Config.AimHold = false
    pcall(function()
        RunService:UnbindFromRenderStep("ZepAimStep")
    end)
    ScreenGui:Destroy()
    _G.ZepHub_Loaded = false
end)

MinBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

print("Zep Hub Murder Duels loaded")
