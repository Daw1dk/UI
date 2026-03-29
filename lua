--[[
    Daw1dk Glass Raw Library
    Single-file Roblox LuaU UI library built for raw GitHub loading.

    Example:
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/Daw1dkGlassRaw.lua"))()

    local Window = Library:CreateWindow({
        Name = "Session UI",
        LoadingTitle = "Loading",
        LoadingSubtitle = "Preparing interface",
        KeySystem = true,
        KeySettings = {
            Title = "Key System",
            Subtitle = "Enter your key to continue",
            FileName = "SessionKey",
            SaveKey = true,
            Key = {"Test", "Daw1dk"}
        }
    })

    local Tab = Window:CreateTab("Main", 4483362458)
    Tab:CreateButton({
        Name = "Hello",
        Callback = function()
            print("Hello from Daw1dkGlassRaw")
        end
    })
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    error("[Daw1dkGlassRaw] LocalPlayer is not available.")
end

local GlobalEnv = getgenv and getgenv() or _G
if type(GlobalEnv.__DAW1DK_GLASS_ACTIVE) == "table" and type(GlobalEnv.__DAW1DK_GLASS_ACTIVE.Destroy) == "function" then
    pcall(GlobalEnv.__DAW1DK_GLASS_ACTIVE.Destroy)
end

local Library = {
    Version = "1.1.0",
    Theme = {
        Background = Color3.fromRGB(8, 11, 18),
        Surface = Color3.fromRGB(14, 18, 28),
        SurfaceAlt = Color3.fromRGB(19, 24, 36),
        SurfaceBright = Color3.fromRGB(28, 34, 48),
        Accent = Color3.fromRGB(255, 255, 255),
        AccentSoft = Color3.fromRGB(210, 220, 238),
        Text = Color3.fromRGB(245, 247, 255),
        MutedText = Color3.fromRGB(167, 176, 198),
        Success = Color3.fromRGB(214, 226, 244),
        Danger = Color3.fromRGB(255, 184, 191)
    },
    _controller = nil
}

local Controller = {}
Controller.__index = Controller

local WindowMethods = {}
WindowMethods.__index = WindowMethods

local TabMethods = {}
TabMethods.__index = TabMethods

local ParagraphMethods = {}
ParagraphMethods.__index = ParagraphMethods

local ToggleMethods = {}
ToggleMethods.__index = ToggleMethods

local SliderMethods = {}
SliderMethods.__index = SliderMethods

local function newObject(className, properties)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    return object
end

local function safeCall(callback, ...)
    if type(callback) ~= "function" then
        return
    end

    task.spawn(function(...)
        local success, message = pcall(callback, ...)
        if not success then
            warn("[Daw1dkGlassRaw] Callback error:", message)
        end
    end, ...)
end

local function formatNumber(value)
    if math.abs(value - math.round(value)) < 0.001 then
        return tostring(math.round(value))
    end

    local text = string.format("%.2f", value)
    text = text:gsub("0+$", ""):gsub("%.$", "")
    return text
end

local function roundToIncrement(value, minValue, maxValue, increment)
    local step = increment or 1
    if step <= 0 then
        step = 1
    end

    local rounded = minValue + math.round((value - minValue) / step) * step
    return math.clamp(rounded, minValue, maxValue)
end

local function withExtension(fileName)
    local name = tostring(fileName or "daw1dk_key")
    if not string.find(name, "%.") then
        name ..= ".txt"
    end
    return name
end

local function isValidKey(validKeys, candidate)
    local compare = tostring(candidate or "")

    if type(validKeys) == "table" then
        for _, key in ipairs(validKeys) do
            if tostring(key) == compare then
                return true
            end
        end
        return false
    end

    return tostring(validKeys or "") == compare
end

local function readExecutorFile(path)
    if type(isfile) == "function" and type(readfile) == "function" and isfile(path) then
        return readfile(path)
    end
    return nil
end

local function writeExecutorFile(path, content)
    if type(writefile) == "function" then
        writefile(path, content)
    end
end

local function protectGui(screenGui)
    if syn and syn.protect_gui then
        pcall(function()
            syn.protect_gui(screenGui)
        end)
    end
end

local function resolveGuiParent(screenGui)
    if gethui then
        local success, holder = pcall(gethui)
        if success and holder then
            return holder
        end
    end

    protectGui(screenGui)

    local success, parent = pcall(function()
        return CoreGui
    end)
    if success and parent then
        return parent
    end

    return LocalPlayer:WaitForChild("PlayerGui")
end

local function makeCorner(parent, radius)
    return newObject("UICorner", {
        CornerRadius = UDim.new(0, radius or 12),
        Parent = parent
    })
end

local function makePadding(parent, left, right, top, bottom)
    return newObject("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0),
        Parent = parent
    })
end

local function makeStroke(parent, thickness, transparency)
    local stroke = newObject("UIStroke", {
        Thickness = thickness or 1,
        Transparency = transparency or 0.18,
        Color = Library.Theme.Accent,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Round,
        Parent = parent
    })

    pcall(function()
        newObject("UIGradient", {
            Rotation = 35,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.55, Color3.fromRGB(216, 225, 241)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
            }),
            Parent = stroke
        })
    end)

    return stroke
end

local function makeSheen(parent, radius)
    local sheen = newObject("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Parent = parent
    })

    makeCorner(sheen, radius or 12)

    newObject("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(175, 190, 225))
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.96),
            NumberSequenceKeypoint.new(0.4, 0.985),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Parent = sheen
    })

    return sheen
end

local function makeGlass(parent, properties)
    local frame = newObject("Frame", {
        Parent = parent,
        BorderSizePixel = 0,
        BackgroundColor3 = properties.BackgroundColor3 or Library.Theme.Surface,
        BackgroundTransparency = properties.BackgroundTransparency or 0.2,
        Size = properties.Size or UDim2.fromScale(1, 1),
        Position = properties.Position or UDim2.new(),
        AnchorPoint = properties.AnchorPoint or Vector2.new(),
        Visible = properties.Visible ~= false
    })

    frame.Name = properties.Name or frame.Name
    if properties.ZIndex then
        frame.ZIndex = properties.ZIndex
    end

    makeCorner(frame, properties.Radius or 14)
    makeStroke(frame, properties.StrokeThickness or 1, properties.StrokeTransparency or 0.18)
    makeSheen(frame, properties.Radius or 14)

    return frame
end

function Controller:_trackConnection(connection)
    table.insert(self.Connections, connection)
    return connection
end

function Controller:_trackTween(tween)
    table.insert(self.Tweens, tween)
    return tween
end

function Controller:_trackInstance(instance)
    table.insert(self.Instances, instance)
    return instance
end

function Controller:_connect(signal, callback)
    return self:_trackConnection(signal:Connect(callback))
end

function Controller:_tween(instance, tweenInfo, properties)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    self:_trackTween(tween)
    tween:Play()
    return tween
end

function Controller:_makeInteractiveSurface(parent, size)
    return makeGlass(parent, {
        Size = size or UDim2.new(1, 0, 0, 42),
        Radius = 12,
        BackgroundColor3 = Library.Theme.SurfaceAlt,
        BackgroundTransparency = 0.22,
        StrokeTransparency = 0.16
    })
end

function Controller:_addHoverAnimation(surface, button, normalTransparency, hoverTransparency)
    local scale = newObject("UIScale", {
        Scale = 1,
        Parent = surface
    })

    self:_connect(button.MouseEnter, function()
        self:_tween(surface, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = hoverTransparency or 0.12
        })
        self:_tween(scale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Scale = 1.01
        })
    end)

    self:_connect(button.MouseLeave, function()
        self:_tween(surface, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = normalTransparency or 0.2
        })
        self:_tween(scale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Scale = 1
        })
    end)

    self:_connect(button.MouseButton1Down, function()
        self:_tween(scale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Scale = 0.985
        })
    end)

    self:_connect(button.MouseButton1Up, function()
        self:_tween(scale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Scale = 1.01
        })
    end)
end

function Controller:_enableDragging(handle, target)
    local dragging = false
    local dragStart
    local startPosition

    self:_connect(handle.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        dragging = true
        dragStart = input.Position
        startPosition = target.Position
    end)

    self:_connect(handle.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    self:_connect(UserInputService.InputChanged, function(input)
        if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        local delta = input.Position - dragStart
        target.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)
end

function Controller:_updateScrollCanvas(scroll, layout)
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end

function Controller:_setBlur(size)
    if not self.Blur then
        return
    end

    self:_tween(self.Blur, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = size
    })
end

function Controller:_buildRoot()
    self.ScreenGui = newObject("ScreenGui", {
        Name = "Daw1dkGlassRaw_" .. tostring(math.random(1000, 9999)),
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    self.ScreenGui.Parent = resolveGuiParent(self.ScreenGui)
    self:_trackInstance(self.ScreenGui)

    self.Blur = newObject("BlurEffect", {
        Name = "Daw1dkGlassBlur_" .. tostring(math.random(1000, 9999)),
        Size = 0,
        Enabled = true,
        Parent = Lighting
    })
    self:_trackInstance(self.Blur)

    self.Root = newObject("Frame", {
        Parent = self.ScreenGui,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1)
    })
end

function Controller:_buildLoadingOverlay()
    self.LoadingOverlay = newObject("Frame", {
        Parent = self.Root,
        BackgroundColor3 = Color3.fromRGB(68, 72, 79),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 2
    })

    self.LoadingPanel = makeGlass(self.LoadingOverlay, {
        Name = "LoadingPanel",
        Size = UDim2.fromOffset(430, 154),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.54),
        BackgroundColor3 = Library.Theme.Surface,
        BackgroundTransparency = 0.14,
        Radius = 20,
        ZIndex = 3
    })

    self.LoadingScale = newObject("UIScale", {
        Scale = 0.96,
        Parent = self.LoadingPanel
    })

    makePadding(self.LoadingPanel, 26, 26, 22, 22)

    newObject("TextLabel", {
        Parent = self.LoadingPanel,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = self.Config.LoadingTitle or "Loading interface",
        TextColor3 = Library.Theme.Text,
        TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 30),
        ZIndex = 4
    })

    newObject("TextLabel", {
        Parent = self.LoadingPanel,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = self.Config.LoadingSubtitle or "Preparing components",
        TextColor3 = Library.Theme.MutedText,
        TextSize = 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 0, 0, 38),
        Size = UDim2.new(1, 0, 0, 42),
        ZIndex = 4
    })

    local progressBack = self:_makeInteractiveSurface(self.LoadingPanel, UDim2.new(1, 0, 0, 10))
    progressBack.Position = UDim2.new(0, 0, 1, -10)
    progressBack.BackgroundTransparency = 0.12
    progressBack.ZIndex = 4

    self.LoadingFill = newObject("Frame", {
        Parent = progressBack,
        BackgroundColor3 = Color3.fromRGB(245, 248, 255),
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 5
    })
    makeCorner(self.LoadingFill, 999)

    newObject("UIGradient", {
        Parent = self.LoadingFill,
        Rotation = 0,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(208, 219, 243))
        })
    })
end

function Controller:_buildMainWindow()
    self.MainOverlay = newObject("Frame", {
        Parent = self.Root,
        BackgroundColor3 = Color3.fromRGB(24, 26, 32),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 4
    })

    self.MainPanel = makeGlass(self.MainOverlay, {
        Name = "MainPanel",
        Size = UDim2.fromOffset(860, 560),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.54),
        BackgroundColor3 = Library.Theme.Background,
        BackgroundTransparency = 0.12,
        Radius = 22,
        ZIndex = 5,
        Visible = false
    })

    newObject("UIGradient", {
        Parent = self.MainPanel,
        Rotation = 120,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(23, 29, 44)),
            ColorSequenceKeypoint.new(0.48, Color3.fromRGB(10, 14, 24)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 24, 36))
        })
    })

    self.MainScale = newObject("UIScale", {
        Scale = 0.965,
        Parent = self.MainPanel
    })

    local dragBar = newObject("Frame", {
        Parent = self.MainPanel,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -72, 0, 58),
        ZIndex = 6
    })
    self:_enableDragging(dragBar, self.MainPanel)

    local sidebar = newObject("Frame", {
        Parent = self.MainPanel,
        BackgroundColor3 = Library.Theme.Surface,
        BackgroundTransparency = 0.24,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 218, 1, 0),
        ZIndex = 6
    })
    makeCorner(sidebar, 22)

    newObject("Frame", {
        Parent = sidebar,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        ZIndex = 7
    })

    local titleBlock = newObject("Frame", {
        Parent = sidebar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 16),
        Size = UDim2.new(1, -28, 0, 86),
        ZIndex = 7
    })

    newObject("TextLabel", {
        Parent = titleBlock,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = self.Config.Name or "Daw1dk Glass",
        TextColor3 = Library.Theme.Text,
        TextSize = 20,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Size = UDim2.new(1, 0, 0, 42),
        ZIndex = 7
    })

    newObject("TextLabel", {
        Parent = titleBlock,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = self.Config.LoadingSubtitle or "Minimal black glass interface",
        TextColor3 = Library.Theme.MutedText,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 0, 36),
        ZIndex = 7
    })

    self.TabScroll = newObject("ScrollingFrame", {
        Parent = sidebar,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, 108),
        Size = UDim2.new(1, -24, 1, -120),
        ScrollBarThickness = 2,
        ScrollBarImageTransparency = 0.72,
        CanvasSize = UDim2.new(),
        ZIndex = 7
    })

    self.TabLayout = newObject("UIListLayout", {
        Parent = self.TabScroll,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    self:_connect(self.TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        self:_updateScrollCanvas(self.TabScroll, self.TabLayout)
    end)

    local rightSide = newObject("Frame", {
        Parent = self.MainPanel,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 236, 0, 0),
        Size = UDim2.new(1, -252, 1, 0),
        ZIndex = 6
    })

    local topBlock = newObject("Frame", {
        Parent = rightSide,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 92),
        ZIndex = 6
    })

    self.CurrentTabLabel = newObject("TextLabel", {
        Parent = topBlock,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "Main",
        TextColor3 = Library.Theme.Text,
        TextSize = 24,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 4, 0, 20),
        Size = UDim2.new(1, -8, 0, 28),
        ZIndex = 7
    })

    newObject("TextLabel", {
        Parent = topBlock,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "Dark glass panels with subtle motion and clean controls.",
        TextColor3 = Library.Theme.MutedText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 4, 0, 48),
        Size = UDim2.new(1, -8, 0, 20),
        ZIndex = 7
    })

    self.PageHolder = newObject("Frame", {
        Parent = rightSide,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 88),
        Size = UDim2.new(1, 0, 1, -102),
        ZIndex = 6
    })

    local closeSurface = self:_makeInteractiveSurface(self.MainPanel, UDim2.fromOffset(38, 38))
    closeSurface.AnchorPoint = Vector2.new(1, 0)
    closeSurface.Position = UDim2.new(1, -18, 0, 18)
    closeSurface.BackgroundTransparency = 0.2
    closeSurface.ZIndex = 8

    local closeButton = newObject("TextButton", {
        Parent = closeSurface,
        BackgroundTransparency = 1,
        Text = "x",
        Font = Enum.Font.GothamBold,
        TextColor3 = Library.Theme.Text,
        TextSize = 18,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 9
    })
    self:_addHoverAnimation(closeSurface, closeButton, 0.2, 0.08)
    self:_connect(closeButton.MouseButton1Click, function()
        Library:Destroy()
    end)
end

function Controller:_buildKeyOverlay()
    self.KeyOverlay = newObject("Frame", {
        Parent = self.Root,
        BackgroundColor3 = Color3.fromRGB(78, 81, 88),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 10
    })

    self.KeyPanel = makeGlass(self.KeyOverlay, {
        Name = "KeyPanel",
        Size = UDim2.fromOffset(500, 340),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.56),
        BackgroundColor3 = Library.Theme.Surface,
        BackgroundTransparency = 0.12,
        Radius = 20,
        ZIndex = 11,
        Visible = false
    })

    self.KeyScale = newObject("UIScale", {
        Parent = self.KeyPanel,
        Scale = 0.94
    })

    makePadding(self.KeyPanel, 24, 24, 24, 24)

    local profileRow = newObject("Frame", {
        Parent = self.KeyPanel,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 116),
        ZIndex = 12
    })

    local avatarSurface = self:_makeInteractiveSurface(profileRow, UDim2.fromOffset(92, 92))
    avatarSurface.Position = UDim2.new(0, 0, 0, 10)
    avatarSurface.BackgroundTransparency = 0.18
    avatarSurface.ZIndex = 12

    local avatar = newObject("ImageLabel", {
        Parent = avatarSurface,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 6, 0, 6),
        Size = UDim2.new(1, -12, 1, -12),
        ScaleType = Enum.ScaleType.Crop,
        ZIndex = 13
    })
    makeCorner(avatar, 999)

    local thumbnail = ""
    pcall(function()
        thumbnail = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)
    avatar.Image = thumbnail

    local infoBlock = newObject("Frame", {
        Parent = profileRow,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 112, 0, 10),
        Size = UDim2.new(1, -112, 1, -20),
        ZIndex = 12
    })

    newObject("TextLabel", {
        Parent = infoBlock,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = (self.Config.KeySettings and self.Config.KeySettings.Title) or "Key System",
        TextColor3 = Library.Theme.Text,
        TextSize = 26,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 32),
        ZIndex = 13
    })

    newObject("TextLabel", {
        Parent = infoBlock,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = LocalPlayer.DisplayName,
        TextColor3 = Library.Theme.AccentSoft,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 0, 0, 38),
        Size = UDim2.new(1, 0, 0, 20),
        ZIndex = 13
    })

    newObject("TextLabel", {
        Parent = infoBlock,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "@" .. LocalPlayer.Name,
        TextColor3 = Library.Theme.MutedText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 0, 0, 60),
        Size = UDim2.new(1, 0, 0, 18),
        ZIndex = 13
    })

    newObject("TextLabel", {
        Parent = infoBlock,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = (self.Config.KeySettings and self.Config.KeySettings.Subtitle) or "Enter your access key to continue.",
        TextColor3 = Library.Theme.MutedText,
        TextSize = 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Position = UDim2.new(0, 0, 0, 82),
        Size = UDim2.new(1, 0, 0, 28),
        ZIndex = 13
    })

    self.KeyEntryBlock = newObject("Frame", {
        Parent = self.KeyPanel,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 24, 0, 160),
        Size = UDim2.new(1, -48, 0, 140),
        ZIndex = 12
    })

    local keyInputSurface = self:_makeInteractiveSurface(self.KeyEntryBlock, UDim2.new(1, 0, 0, 54))
    keyInputSurface.BackgroundTransparency = 0.18
    keyInputSurface.ZIndex = 12

    self.KeyInput = newObject("TextBox", {
        Parent = keyInputSurface,
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        Font = Enum.Font.GothamMedium,
        PlaceholderText = "Enter key here",
        PlaceholderColor3 = Color3.fromRGB(164, 174, 196),
        Text = "",
        TextColor3 = Library.Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -28, 1, 0),
        ZIndex = 13
    })

    local confirmSurface = self:_makeInteractiveSurface(self.KeyEntryBlock, UDim2.new(0.56, -6, 0, 48))
    confirmSurface.Position = UDim2.new(0, 0, 0, 70)
    confirmSurface.BackgroundTransparency = 0.16
    confirmSurface.ZIndex = 12

    local confirmButton = newObject("TextButton", {
        Parent = confirmSurface,
        BackgroundTransparency = 1,
        Text = "Confirm",
        Font = Enum.Font.GothamBold,
        TextColor3 = Library.Theme.Text,
        TextSize = 15,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 13
    })
    self:_addHoverAnimation(confirmSurface, confirmButton, 0.16, 0.06)

    local saveSurface = self:_makeInteractiveSurface(self.KeyEntryBlock, UDim2.new(0.44, -6, 0, 48))
    saveSurface.Position = UDim2.new(0.56, 6, 0, 70)
    saveSurface.BackgroundTransparency = 0.2
    saveSurface.ZIndex = 12

    newObject("TextLabel", {
        Parent = saveSurface,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = (self.Config.KeySettings and self.Config.KeySettings.SaveKey) and "Save Key: Enabled" or "Save Key: Disabled",
        TextColor3 = Library.Theme.MutedText,
        TextSize = 13,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 13
    })

    self.KeyStatus = newObject("TextLabel", {
        Parent = self.KeyEntryBlock,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "Awaiting key...",
        TextColor3 = Library.Theme.MutedText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 0, 0, 126),
        Size = UDim2.new(1, 0, 0, 14),
        ZIndex = 13
    })

    self:_connect(confirmButton.MouseButton1Click, function()
        self:_submitKey(self.KeyInput.Text)
    end)

    self:_connect(self.KeyInput.FocusLost, function(enterPressed)
        if enterPressed then
            self:_submitKey(self.KeyInput.Text)
        end
    end)
end

function Controller:_showLoading()
    self.LoadingOverlay.Visible = true
    self.LoadingPanel.Visible = true
    self.LoadingOverlay.BackgroundTransparency = 1
    self.LoadingPanel.Position = UDim2.fromScale(0.5, 0.54)
    self.LoadingScale.Scale = 0.96
    self.LoadingFill.Size = UDim2.new(0, 0, 1, 0)

    self:_tween(self.LoadingOverlay, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.4
    })
    self:_tween(self.LoadingPanel, TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.fromScale(0.5, 0.5)
    })
    self:_tween(self.LoadingScale, TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Scale = 1
    })
    self:_tween(self.LoadingFill, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 1, 0)
    })
end

function Controller:_hideLoading()
    self:_tween(self.LoadingOverlay, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1
    })
    self:_tween(self.LoadingPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.fromScale(0.5, 0.47)
    })
    self:_tween(self.LoadingScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Scale = 0.96
    })

    task.delay(0.22, function()
        if self.Destroyed then
            return
        end
        self.LoadingOverlay.Visible = false
    end)
end

function Controller:_showKeyOverlay()
    self.KeyOverlay.Visible = true
    self.KeyPanel.Visible = true
    self.KeyOverlay.BackgroundTransparency = 1
    self.KeyPanel.Position = UDim2.fromScale(0.5, 0.56)
    self.KeyScale.Scale = 0.94
    self.KeyEntryBlock.Position = UDim2.new(0, 24, 0, 174)

    self:_setBlur(16)
    self:_tween(self.KeyOverlay, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.28
    })
    self:_tween(self.KeyPanel, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.fromScale(0.5, 0.5)
    })
    self:_tween(self.KeyScale, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Scale = 1
    })

    task.delay(0.12, function()
        if self.Destroyed then
            return
        end
        self:_tween(self.KeyEntryBlock, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 24, 0, 160)
        })
    end)
end

function Controller:_hideKeyOverlay()
    self:_tween(self.KeyOverlay, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1
    })
    self:_tween(self.KeyPanel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.fromScale(0.5, 0.46)
    })
    self:_tween(self.KeyScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Scale = 0.96
    })

    task.delay(0.22, function()
        if self.Destroyed then
            return
        end
        self.KeyOverlay.Visible = false
    end)
end

function Controller:_showMainWindow()
    self.MainOverlay.Visible = true
    self.MainPanel.Visible = true
    self.MainOverlay.BackgroundTransparency = 1
    self.MainPanel.Position = UDim2.fromScale(0.5, 0.54)
    self.MainScale.Scale = 0.965

    self:_setBlur(18)
    self:_tween(self.MainOverlay, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.42
    })
    self:_tween(self.MainPanel, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.fromScale(0.5, 0.5)
    })
    self:_tween(self.MainScale, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Scale = 1
    })
end

function Controller:_hideMainWindow()
    self:_tween(self.MainOverlay, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1
    })
    self:_tween(self.MainPanel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.fromScale(0.5, 0.54)
    })
    self:_tween(self.MainScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Scale = 0.965
    })
end

function Controller:_tryLoadSavedKey()
    local settings = self.Config.KeySettings or {}
    if not settings.SaveKey then
        return false
    end

    local fileName = withExtension(settings.FileName)
    local saved = readExecutorFile(fileName)
    if not saved or saved == "" then
        return false
    end

    saved = tostring(saved):gsub("%s+", "")
    return isValidKey(settings.Key, saved)
end

function Controller:_saveKey(value)
    local settings = self.Config.KeySettings or {}
    if not settings.SaveKey then
        return
    end

    local fileName = withExtension(settings.FileName)
    pcall(writeExecutorFile, fileName, tostring(value))
end

function Controller:_submitKey(candidate)
    local settings = self.Config.KeySettings or {}
    local key = tostring(candidate or ""):gsub("^%s+", ""):gsub("%s+$", "")

    if not isValidKey(settings.Key, key) then
        self.KeyStatus.Text = "Invalid key"
        self.KeyStatus.TextColor3 = Library.Theme.Danger

        self:_tween(self.KeyPanel, TweenInfo.new(0.08, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
            Position = UDim2.fromScale(0.505, 0.5)
        })
        task.delay(0.08, function()
            if self.Destroyed then
                return
            end
            self:_tween(self.KeyPanel, TweenInfo.new(0.08, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
                Position = UDim2.fromScale(0.495, 0.5)
            })
            task.delay(0.08, function()
                if self.Destroyed then
                    return
                end
                self:_tween(self.KeyPanel, TweenInfo.new(0.08, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
                    Position = UDim2.fromScale(0.5, 0.5)
                })
            end)
        end)

        return false
    end

    self.KeyStatus.Text = "Access granted"
    self.KeyStatus.TextColor3 = Library.Theme.Success
    self:_saveKey(key)
    self:_hideKeyOverlay()

    task.delay(0.18, function()
        if self.Destroyed then
            return
        end
        self:_showMainWindow()
    end)

    return true
end

function Controller:_selectTab(tabRecord)
    if self.SelectedTab == tabRecord then
        return
    end

    for _, record in ipairs(self.Tabs) do
        local selected = record == tabRecord
        record.Indicator.Visible = selected
        record.Page.Visible = selected
        record.Page.Position = selected and UDim2.new(0, 10, 0, 0) or UDim2.new()

        self:_tween(record.ButtonSurface, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = selected and 0.08 or 0.18
        })

        self:_tween(record.TitleLabel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextColor3 = selected and Library.Theme.Text or Library.Theme.MutedText
        })

        if record.IconLabel then
            self:_tween(record.IconLabel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                ImageTransparency = selected and 0 or 0.2
            })
        end

        if selected then
            self:_tween(record.Page, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new()
            })
        end
    end

    self.SelectedTab = tabRecord
    self.CurrentTabLabel.Text = tabRecord.Name
end

function Controller:_createTab(name, icon)
    local record = {
        Name = tostring(name or "Tab")
    }

    local buttonSurface = self:_makeInteractiveSurface(self.TabScroll, UDim2.new(1, -4, 0, 46))
    buttonSurface.BackgroundTransparency = 0.18
    buttonSurface.LayoutOrder = #self.Tabs + 1
    buttonSurface.ZIndex = 8

    local hitbox = newObject("TextButton", {
        Parent = buttonSurface,
        BackgroundTransparency = 1,
        Text = "",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 9
    })

    local indicator = newObject("Frame", {
        Parent = buttonSurface,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.06,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.19, 0),
        Size = UDim2.new(0, 2, 0.62, 0),
        Visible = false,
        ZIndex = 10
    })
    makeCorner(indicator, 999)

    local iconLabel = newObject("ImageLabel", {
        Parent = buttonSurface,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0.5, -10),
        Size = UDim2.fromOffset(20, 20),
        Image = "",
        ImageColor3 = Color3.fromRGB(255, 255, 255),
        ImageTransparency = 0.2,
        ZIndex = 10
    })

    if typeof(icon) == "number" then
        iconLabel.Image = "rbxassetid://" .. tostring(icon)
    elseif typeof(icon) == "string" then
        if string.find(icon, "rbxassetid://") then
            iconLabel.Image = icon
        elseif tonumber(icon) then
            iconLabel.Image = "rbxassetid://" .. tostring(icon)
        end
    end

    local titleLabel = newObject("TextLabel", {
        Parent = buttonSurface,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = record.Name,
        TextColor3 = Library.Theme.MutedText,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 46, 0, 0),
        Size = UDim2.new(1, -54, 1, 0),
        ZIndex = 10
    })

    local page = newObject("ScrollingFrame", {
        Parent = self.PageHolder,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(),
        Size = UDim2.fromScale(1, 1),
        ScrollBarThickness = 3,
        ScrollBarImageTransparency = 0.72,
        CanvasSize = UDim2.new(),
        Visible = false,
        ZIndex = 7
    })
    makePadding(page, 4, 10, 4, 0)

    local layout = newObject("UIListLayout", {
        Parent = page,
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    self:_connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        self:_updateScrollCanvas(page, layout)
    end)

    self:_addHoverAnimation(buttonSurface, hitbox, 0.18, 0.1)
    self:_connect(hitbox.MouseButton1Click, function()
        self:_selectTab(record)
    end)

    record.ButtonSurface = buttonSurface
    record.TitleLabel = titleLabel
    record.IconLabel = iconLabel
    record.Indicator = indicator
    record.Page = page
    record.Layout = layout

    table.insert(self.Tabs, record)

    local tabObject = setmetatable({
        _controller = self,
        _record = record
    }, TabMethods)

    if #self.Tabs == 1 then
        self:_selectTab(record)
    end

    return tabObject
end

function Controller:_start()
    self:_buildRoot()
    self:_buildLoadingOverlay()
    self:_buildMainWindow()
    self:_buildKeyOverlay()
    self:_showLoading()

    task.delay(0.95, function()
        if self.Destroyed then
            return
        end

        self:_hideLoading()

        if self.Config.KeySystem then
            if self:_tryLoadSavedKey() then
                self:_showMainWindow()
            else
                self:_showKeyOverlay()
            end
        else
            self:_showMainWindow()
        end
    end)
end

function Controller:Destroy()
    if self.Destroyed then
        return
    end

    self.Destroyed = true
    self:_hideKeyOverlay()
    self:_hideMainWindow()
    self:_setBlur(0)

    task.delay(0.22, function()
        for _, connection in ipairs(self.Connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end

        for _, tween in ipairs(self.Tweens) do
            pcall(function()
                tween:Cancel()
            end)
        end

        for _, instance in ipairs(self.Instances) do
            pcall(function()
                if typeof(instance) == "Instance" then
                    instance:Destroy()
                end
            end)
        end

        if Library._controller == self then
            Library._controller = nil
        end

        if GlobalEnv.__DAW1DK_GLASS_ACTIVE and GlobalEnv.__DAW1DK_GLASS_ACTIVE.Controller == self then
            GlobalEnv.__DAW1DK_GLASS_ACTIVE = nil
        end
    end)
end

function Library:CreateWindow(config)
    if self._controller then
        self:Destroy()
    end

    local controller = setmetatable({
        Config = config or {},
        Tabs = {},
        Connections = {},
        Tweens = {},
        Instances = {},
        Destroyed = false
    }, Controller)

    self._controller = controller
    controller:_start()

    GlobalEnv.__DAW1DK_GLASS_ACTIVE = {
        Controller = controller,
        Destroy = function()
            Library:Destroy()
        end
    }

    return setmetatable({
        _controller = controller
    }, WindowMethods)
end

function Library:Destroy()
    if self._controller then
        self._controller:Destroy()
    end
end

function WindowMethods:CreateTab(name, icon)
    return self._controller:_createTab(name, icon)
end

function WindowMethods:Destroy()
    self._controller:Destroy()
end

function WindowMethods:SelectTab(tabOrName)
    if typeof(tabOrName) == "string" then
        for _, record in ipairs(self._controller.Tabs) do
            if record.Name == tabOrName then
                self._controller:_selectTab(record)
                return
            end
        end
        return
    end

    if getmetatable(tabOrName) == TabMethods then
        self._controller:_selectTab(tabOrName._record)
    end
end

function TabMethods:_newItem(height)
    local panel = self._controller:_makeInteractiveSurface(self._record.Page, UDim2.new(1, -6, 0, height))
    panel.BackgroundTransparency = 0.18
    panel.ZIndex = 8
    return panel
end

function TabMethods:CreateDivider()
    local holder = newObject("Frame", {
        Parent = self._record.Page,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -6, 0, 12),
        ZIndex = 8
    })

    local line = newObject("Frame", {
        Parent = holder,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 9
    })

    return {
        Instance = holder,
        Line = line
    }
end

function TabMethods:CreateParagraph(options)
    local config = options or {}

    local panel = self:_newItem(0)
    panel.AutomaticSize = Enum.AutomaticSize.Y
    panel.Size = UDim2.new(1, -6, 0, 0)
    makePadding(panel, 16, 16, 14, 14)

    newObject("UIListLayout", {
        Parent = panel,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local title = newObject("TextLabel", {
        Parent = panel,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = config.Title or "Paragraph",
        TextColor3 = Library.Theme.Text,
        TextSize = 16,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 22),
        ZIndex = 9
    })

    local content = newObject("TextLabel", {
        Parent = panel,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = config.Content or "",
        TextColor3 = Library.Theme.MutedText,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Size = UDim2.new(1, 0, 0, 0),
        ZIndex = 9
    })

    return setmetatable({
        _panel = panel,
        _title = title,
        _content = content
    }, ParagraphMethods)
end

function ParagraphMethods:Set(options)
    local config = options or {}

    if config.Title ~= nil then
        self._title.Text = tostring(config.Title)
    end

    if config.Content ~= nil then
        self._content.Text = tostring(config.Content)
    end
end

function TabMethods:CreateButton(options)
    local config = options or {}
    local panel = self:_newItem(52)
    panel.BackgroundTransparency = 0.16
    makePadding(panel, 14, 14, 0, 0)

    local button = newObject("TextButton", {
        Parent = panel,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = config.Name or "Button",
        TextColor3 = Library.Theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 9
    })

    self._controller:_addHoverAnimation(panel, button, 0.16, 0.06)
    self._controller:_connect(button.MouseButton1Click, function()
        safeCall(config.Callback)
    end)

    return {
        Instance = panel,
        Button = button
    }
end

function TabMethods:CreateToggle(options)
    local config = options or {}
    local state = not not config.CurrentValue

    local panel = self:_newItem(58)
    panel.BackgroundTransparency = 0.18
    makePadding(panel, 16, 16, 0, 0)

    newObject("TextLabel", {
        Parent = panel,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = config.Name or "Toggle",
        TextColor3 = Library.Theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -76, 1, 0),
        ZIndex = 9
    })

    local switch = self._controller:_makeInteractiveSurface(panel, UDim2.fromOffset(56, 28))
    switch.AnchorPoint = Vector2.new(1, 0.5)
    switch.Position = UDim2.new(1, 0, 0.5, 0)
    switch.BackgroundTransparency = 0.2
    switch.ZIndex = 9

    local knob = newObject("Frame", {
        Parent = switch,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 5, 0.5, -9),
        Size = UDim2.fromOffset(18, 18),
        ZIndex = 10
    })
    makeCorner(knob, 999)

    local hitbox = newObject("TextButton", {
        Parent = panel,
        BackgroundTransparency = 1,
        Text = "",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 11
    })

    local function setState(value, shouldCallback)
        state = not not value

        self._controller:_tween(switch, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = state and 0.08 or 0.2
        })

        self._controller:_tween(knob, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = state and UDim2.new(1, -23, 0.5, -9) or UDim2.new(0, 5, 0.5, -9),
            BackgroundTransparency = state and 0 or 0.04
        })

        if shouldCallback ~= false then
            safeCall(config.Callback, state)
        end
    end

    self._controller:_addHoverAnimation(panel, hitbox, 0.18, 0.08)
    self._controller:_connect(hitbox.MouseButton1Click, function()
        setState(not state, true)
    end)

    setState(state, false)

    return setmetatable({
        Instance = panel,
        Set = function(_, value, shouldCallback)
            setState(value, shouldCallback)
        end,
        Get = function()
            return state
        end
    }, ToggleMethods)
end

function TabMethods:CreateSlider(options)
    local config = options or {}
    local minValue = (config.Range and config.Range[1]) or 0
    local maxValue = (config.Range and config.Range[2]) or 100
    local increment = config.Increment or 1
    local current = roundToIncrement(config.CurrentValue or minValue, minValue, maxValue, increment)

    local panel = self:_newItem(90)
    panel.BackgroundTransparency = 0.18
    makePadding(panel, 16, 16, 12, 12)

    newObject("TextLabel", {
        Parent = panel,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = config.Name or "Slider",
        TextColor3 = Library.Theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0.7, 0, 0, 20),
        ZIndex = 9
    })

    local valueLabel = newObject("TextLabel", {
        Parent = panel,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = formatNumber(current),
        TextColor3 = Library.Theme.AccentSoft,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(0.7, 0, 0, 0),
        Size = UDim2.new(0.3, 0, 0, 20),
        ZIndex = 9
    })

    local bar = self._controller:_makeInteractiveSurface(panel, UDim2.new(1, 0, 0, 16))
    bar.Position = UDim2.new(0, 0, 0, 38)
    bar.BackgroundTransparency = 0.22
    bar.ZIndex = 9

    local fill = newObject("Frame", {
        Parent = bar,
        BackgroundColor3 = Color3.fromRGB(244, 247, 255),
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 10
    })
    makeCorner(fill, 999)

    newObject("UIGradient", {
        Parent = fill,
        Rotation = 0,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(209, 220, 241))
        })
    })

    local knob = newObject("Frame", {
        Parent = bar,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        ZIndex = 11
    })
    makeCorner(knob, 999)

    newObject("TextLabel", {
        Parent = panel,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = formatNumber(minValue),
        TextColor3 = Library.Theme.MutedText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 0, 0, 62),
        Size = UDim2.new(0.5, 0, 0, 14),
        ZIndex = 9
    })

    newObject("TextLabel", {
        Parent = panel,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = formatNumber(maxValue),
        TextColor3 = Library.Theme.MutedText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(0.5, 0, 0, 62),
        Size = UDim2.new(0.5, 0, 0, 14),
        ZIndex = 9
    })

    local hitbox = newObject("TextButton", {
        Parent = bar,
        BackgroundTransparency = 1,
        Text = "",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 12
    })

    local dragging = false

    local function renderValue(value, shouldCallback)
        current = roundToIncrement(value, minValue, maxValue, increment)
        local alpha = maxValue == minValue and 0 or (current - minValue) / (maxValue - minValue)
        valueLabel.Text = formatNumber(current)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)

        if shouldCallback ~= false then
            safeCall(config.Callback, current)
        end
    end

    local function updateFromMouse()
        local mouse = UserInputService:GetMouseLocation()
        local absolute = bar.AbsolutePosition
        local size = bar.AbsoluteSize
        local alpha = math.clamp((mouse.X - absolute.X) / math.max(size.X, 1), 0, 1)
        local rawValue = minValue + ((maxValue - minValue) * alpha)
        renderValue(rawValue, true)
    end

    self._controller:_addHoverAnimation(bar, hitbox, 0.22, 0.14)
    self._controller:_connect(hitbox.MouseButton1Down, function()
        dragging = true
        updateFromMouse()
    end)

    self._controller:_connect(UserInputService.InputChanged, function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromMouse()
        end
    end)

    self._controller:_connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    renderValue(current, false)

    return setmetatable({
        Instance = panel,
        Set = function(_, value, shouldCallback)
            renderValue(value, shouldCallback)
        end,
        Get = function()
            return current
        end
    }, SliderMethods)
end

return Library
