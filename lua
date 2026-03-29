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
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    error("[Daw1dkGlassRaw] LocalPlayer is not available.")
end

local GlobalEnv = getgenv and getgenv() or _G
if type(GlobalEnv.__DAW1DK_GLASS_ACTIVE) == "table" and type(GlobalEnv.__DAW1DK_GLASS_ACTIVE.Destroy) == "function" then
    pcall(GlobalEnv.__DAW1DK_GLASS_ACTIVE.Destroy)
end

local Library = {
    Version = "3.1.0",
    Theme = {
        Background = Color3.fromRGB(78, 48, 59),
        Surface = Color3.fromRGB(104, 71, 84),
        SurfaceAlt = Color3.fromRGB(91, 65, 81),
        SurfaceBright = Color3.fromRGB(132, 99, 113),
        Sidebar = Color3.fromRGB(68, 48, 62),
        Overlay = Color3.fromRGB(16, 12, 18),
        Frost = Color3.fromRGB(255, 248, 250),
        FrostSoft = Color3.fromRGB(255, 240, 246),
        WarmGlow = Color3.fromRGB(255, 140, 116),
        CoolGlow = Color3.fromRGB(164, 128, 255),
        Outline = Color3.fromRGB(255, 255, 255),
        OutlineSoft = Color3.fromRGB(233, 227, 231),
        Text = Color3.fromRGB(252, 247, 250),
        MutedText = Color3.fromRGB(226, 213, 220),
        Success = Color3.fromRGB(227, 239, 233),
        Danger = Color3.fromRGB(240, 188, 193),
        Hover = Color3.fromRGB(255, 255, 255)
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

local KeybindMethods = {}
KeybindMethods.__index = KeybindMethods

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

local function normalizeKeyName(name)
    local cleaned = tostring(name or ""):gsub("%s+", "")
    if cleaned == "" then
        return nil
    end

    if #cleaned == 1 then
        return string.upper(cleaned)
    end

    return string.upper(cleaned:sub(1, 1)) .. cleaned:sub(2)
end

local function resolveKeybind(value)
    if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then
        return value
    end

    if type(value) == "string" then
        local normalized = normalizeKeyName(value)
        if normalized and Enum.KeyCode[normalized] then
            return Enum.KeyCode[normalized]
        end
    end

    return Enum.KeyCode.K
end

local function keybindToText(keyCode)
    if typeof(keyCode) ~= "EnumItem" or keyCode.EnumType ~= Enum.KeyCode then
        return "K"
    end

    local name = keyCode.Name
    name = name:gsub("Control", "Ctrl")
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
        CornerRadius = UDim.new(0, radius or 6),
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
        Transparency = transparency or 0.42,
        Color = Library.Theme.Outline,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Round,
        Parent = parent
    })

    pcall(function()
        newObject("UIGradient", {
            Rotation = 0,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(224, 224, 229)),
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
            ColorSequenceKeypoint.new(0, Library.Theme.Frost),
            ColorSequenceKeypoint.new(1, Library.Theme.FrostSoft)
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.72),
            NumberSequenceKeypoint.new(0.28, 0.84),
            NumberSequenceKeypoint.new(0.65, 0.94),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Parent = sheen
    })

    return sheen
end

local function makeGlow(parent, properties)
    local glow = newObject("Frame", {
        Parent = parent,
        BackgroundColor3 = properties.BackgroundColor3,
        BackgroundTransparency = properties.BackgroundTransparency or 0.78,
        BorderSizePixel = 0,
        Size = properties.Size,
        Position = properties.Position,
        AnchorPoint = properties.AnchorPoint or Vector2.new(),
        Rotation = properties.Rotation or 0,
        ZIndex = properties.ZIndex
    })

    makeCorner(glow, properties.Radius or 999)

    if properties.ColorSequence or properties.TransparencySequence then
        newObject("UIGradient", {
            Parent = glow,
            Rotation = properties.GradientRotation or 0,
            Color = properties.ColorSequence or ColorSequence.new({
                ColorSequenceKeypoint.new(0, properties.BackgroundColor3),
                ColorSequenceKeypoint.new(1, properties.BackgroundColor3)
            }),
            Transparency = properties.TransparencySequence
        })
    end

    return glow
end

local function makeInnerBorder(parent, radius, transparency)
    local inner = newObject("Frame", {
        Parent = parent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2)
    })

    makeCorner(inner, math.max((radius or 8) - 1, 2))
    makeStroke(inner, 1, transparency or 0.72)
    return inner
end

local function makeGlass(parent, properties)
    local frame = newObject("Frame", {
        Parent = parent,
        BorderSizePixel = 0,
        BackgroundColor3 = properties.BackgroundColor3 or Library.Theme.Surface,
        BackgroundTransparency = properties.BackgroundTransparency or 0.56,
        Size = properties.Size or UDim2.fromScale(1, 1),
        Position = properties.Position or UDim2.new(),
        AnchorPoint = properties.AnchorPoint or Vector2.new(),
        Visible = properties.Visible ~= false,
        ClipsDescendants = properties.ClipsDescendants == true
    })

    frame.Name = properties.Name or frame.Name
    if properties.ZIndex then
        frame.ZIndex = properties.ZIndex
    end

    makeCorner(frame, properties.Radius or 12)
    makeStroke(frame, properties.StrokeThickness or 1, properties.StrokeTransparency or 0.42)
    makeSheen(frame, properties.Radius or 12)
    makeInnerBorder(frame, properties.Radius or 12, properties.InnerStrokeTransparency or 0.82)

    local tint = newObject("Frame", {
        Parent = frame,
        BackgroundColor3 = properties.TintColor or Library.Theme.Frost,
        BackgroundTransparency = properties.TintTransparency or 0.88,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1)
    })
    makeCorner(tint, properties.Radius or 12)

    newObject("UIGradient", {
        Parent = tint,
        Rotation = properties.TintRotation or 120,
        Color = properties.TintSequence or ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library.Theme.Frost),
            ColorSequenceKeypoint.new(0.5, Library.Theme.FrostSoft),
            ColorSequenceKeypoint.new(1, Library.Theme.SurfaceAlt)
        }),
        Transparency = properties.TintTransparencySequence or NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.42),
            NumberSequenceKeypoint.new(0.45, 0.76),
            NumberSequenceKeypoint.new(1, 0.94)
        })
    })

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
        Radius = 8,
        BackgroundColor3 = Library.Theme.SurfaceAlt,
        BackgroundTransparency = 0.44,
        StrokeTransparency = 0.38,
        InnerStrokeTransparency = 0.82,
        TintTransparency = 0.9,
        TintTransparencySequence = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4),
            NumberSequenceKeypoint.new(0.5, 0.72),
            NumberSequenceKeypoint.new(1, 0.94)
        })
    })
end

function Controller:_animateStroke(frame, speed)
    local stroke = frame:FindFirstChildOfClass("UIStroke")
    if not stroke then
        return
    end

    local gradient = stroke:FindFirstChildOfClass("UIGradient")
    if not gradient then
        return
    end

    table.insert(self.AnimatedStrokes, {
        Gradient = gradient,
        Phase = math.random(),
        Speed = speed or 0.28
    })
end

function Controller:_refreshAnimatedStrokes(deltaTime)
    for index = #self.AnimatedStrokes, 1, -1 do
        local item = self.AnimatedStrokes[index]
        if not item.Gradient or not item.Gradient.Parent then
            table.remove(self.AnimatedStrokes, index)
        else
            item.Phase = (item.Phase + (deltaTime * item.Speed)) % 2
            item.Gradient.Offset = Vector2.new(-1 + item.Phase, 0)
        end
    end
end

function Controller:_addHoverAnimation(surface, button, normalTransparency, hoverTransparency)
    local scale = newObject("UIScale", {
        Scale = 1,
        Parent = surface
    })

    self:_connect(button.MouseEnter, function()
        self:_tween(surface, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = hoverTransparency or 0.1
        })
        self:_tween(scale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Scale = 1.008
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
            Scale = 0.986
        })
    end)

    self:_connect(button.MouseButton1Up, function()
        self:_tween(scale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Scale = 1.004
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

    if size <= 0 then
        self:_tween(self.Blur, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = 0
        })
        task.delay(0.22, function()
            if self.Destroyed then
                return
            end
            if self.Blur and self.Blur.Size <= 0.05 then
                self.Blur.Enabled = false
            end
        end)
        return
    end

    self.Blur.Enabled = true
    self:_tween(self.Blur, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
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
        Name = "Daw1dkGlassRawBlur_" .. tostring(math.random(1000, 9999)),
        Enabled = false,
        Size = 0,
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
        BackgroundColor3 = Library.Theme.Overlay,
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
        BackgroundTransparency = 0.48,
        Radius = 16,
        ZIndex = 3
    })
    self:_animateStroke(self.LoadingPanel, 0.26)

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
    progressBack.BackgroundTransparency = 0.5
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
        BackgroundColor3 = Library.Theme.Overlay,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 4
    })

    self.MainBackdrop = newObject("Frame", {
        Parent = self.MainOverlay,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 4
    })

    makeGlow(self.MainBackdrop, {
        BackgroundColor3 = Library.Theme.WarmGlow,
        BackgroundTransparency = 0.78,
        Position = UDim2.new(0.5, 140, 0.1, -10),
        Size = UDim2.fromOffset(720, 320),
        Rotation = 8,
        Radius = 999,
        ZIndex = 4,
        ColorSequence = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 142, 129)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(133, 51, 62))
        }),
        TransparencySequence = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.76),
            NumberSequenceKeypoint.new(0.7, 0.9),
            NumberSequenceKeypoint.new(1, 1)
        })
    })

    makeGlow(self.MainBackdrop, {
        BackgroundColor3 = Library.Theme.CoolGlow,
        BackgroundTransparency = 0.83,
        Position = UDim2.new(0.2, -120, 0.82, -120),
        Size = UDim2.fromOffset(560, 260),
        Rotation = -20,
        Radius = 999,
        ZIndex = 4,
        ColorSequence = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(116, 93, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(79, 50, 120))
        }),
        TransparencySequence = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.82),
            NumberSequenceKeypoint.new(0.72, 0.94),
            NumberSequenceKeypoint.new(1, 1)
        })
    })

    makeGlow(self.MainBackdrop, {
        BackgroundColor3 = Color3.fromRGB(255, 180, 147),
        BackgroundTransparency = 0.88,
        Position = UDim2.new(0.68, -120, 0.88, -100),
        Size = UDim2.fromOffset(460, 180),
        Rotation = 6,
        Radius = 999,
        ZIndex = 4,
        ColorSequence = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 199)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(165, 86, 78))
        }),
        TransparencySequence = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.84),
            NumberSequenceKeypoint.new(0.7, 0.95),
            NumberSequenceKeypoint.new(1, 1)
        })
    })

    self.MainShadow = newObject("Frame", {
        Parent = self.MainOverlay,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(900, 610),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        ZIndex = 4
    })
    makeCorner(self.MainShadow, 20)

    self.MainPanel = makeGlass(self.MainOverlay, {
        Name = "MainPanel",
        Size = UDim2.fromOffset(900, 560),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.54),
        BackgroundColor3 = Library.Theme.Background,
        BackgroundTransparency = 0.6,
        Radius = 18,
        ZIndex = 5,
        Visible = false,
        ClipsDescendants = true,
        StrokeTransparency = 0.38,
        InnerStrokeTransparency = 0.78,
        TintTransparency = 0.88,
        TintRotation = 90,
        TintSequence = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library.Theme.Frost),
            ColorSequenceKeypoint.new(0.45, Library.Theme.FrostSoft),
            ColorSequenceKeypoint.new(1, Library.Theme.SurfaceAlt)
        }),
        TintTransparencySequence = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.32),
            NumberSequenceKeypoint.new(0.45, 0.64),
            NumberSequenceKeypoint.new(1, 0.9)
        })
    })
    self:_animateStroke(self.MainPanel, 0.22)

    newObject("UIGradient", {
        Parent = self.MainPanel,
        Rotation = 135,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(128, 76, 87)),
            ColorSequenceKeypoint.new(0.45, Color3.fromRGB(84, 58, 74)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(63, 47, 61))
        })
    })

    local frost = newObject("Frame", {
        Parent = self.MainPanel,
        BackgroundColor3 = Library.Theme.Frost,
        BackgroundTransparency = 0.86,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 5
    })
    makeCorner(frost, 18)
    newObject("UIGradient", {
        Parent = frost,
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library.Theme.Frost),
            ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 233, 241)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(146, 100, 110))
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.08),
            NumberSequenceKeypoint.new(0.28, 0.34),
            NumberSequenceKeypoint.new(0.68, 0.64),
            NumberSequenceKeypoint.new(1, 0.82)
        })
    })

    self.MainScale = newObject("UIScale", {
        Scale = 0.965,
        Parent = self.MainPanel
    })

    local dragBar = newObject("Frame", {
        Parent = self.MainPanel,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -180, 0, 60),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 6
    })
    self:_enableDragging(dragBar, self.MainPanel)

    newObject("Frame", {
        Parent = self.MainPanel,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.92,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 72),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 7
    })

    self.Sidebar = newObject("Frame", {
        Parent = self.MainPanel,
        BackgroundColor3 = Library.Theme.Sidebar,
        BackgroundTransparency = 0.46,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 73),
        Size = UDim2.new(0, 236, 1, -73),
        ZIndex = 6
    })
    makeCorner(self.Sidebar, 18)
    makeInnerBorder(self.Sidebar, 18, 0.82)

    newObject("Frame", {
        Parent = self.Sidebar,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.92,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        ZIndex = 7
    })

    self.SearchBar = makeGlass(self.MainPanel, {
        Name = "SearchBar",
        Size = UDim2.new(1, -32, 0, 54),
        Position = UDim2.new(0, 16, 0, 10),
        BackgroundColor3 = Color3.fromRGB(88, 61, 73),
        BackgroundTransparency = 0.56,
        Radius = 14,
        ZIndex = 8,
        StrokeTransparency = 0.52,
        InnerStrokeTransparency = 0.84,
        TintTransparency = 0.86
    })
    self:_animateStroke(self.SearchBar, 0.24)

    local backSurface = self:_makeInteractiveSurface(self.SearchBar, UDim2.fromOffset(34, 34))
    backSurface.Position = UDim2.new(0, 10, 0.5, -17)
    backSurface.BackgroundTransparency = 0.5
    backSurface.ZIndex = 9

    local backButton = newObject("TextButton", {
        Parent = backSurface,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = "<",
        TextColor3 = Library.Theme.Text,
        TextSize = 16,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 10
    })
    self:_addHoverAnimation(backSurface, backButton, 0.5, 0.38)
    self:_connect(backButton.MouseButton1Click, function()
        self:_toggleWindow()
    end)

    self.SearchInput = newObject("TextBox", {
        Parent = self.SearchBar,
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderText = "Search for commands and content...",
        PlaceholderColor3 = Library.Theme.MutedText,
        Text = "",
        TextColor3 = Library.Theme.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 56, 0, 0),
        Size = UDim2.new(1, -230, 1, 0),
        ZIndex = 10
    })

    local askBadge = makeGlass(self.SearchBar, {
        Size = UDim2.fromOffset(116, 34),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(92, 66, 79),
        BackgroundTransparency = 0.6,
        Radius = 12,
        ZIndex = 9,
        StrokeTransparency = 0.58
    })

    newObject("TextLabel", {
        Parent = askBadge,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "Ask AI   Tab",
        TextColor3 = Library.Theme.MutedText,
        TextSize = 12,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 10
    })

    local titleBlock = newObject("Frame", {
        Parent = self.Sidebar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 18),
        Size = UDim2.new(1, -32, 0, 60),
        ZIndex = 7
    })

    newObject("TextLabel", {
        Parent = titleBlock,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = self.Config.Name or "Daw1dk Glass",
        TextColor3 = Library.Theme.Text,
        TextSize = 15,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Size = UDim2.new(1, 0, 0, 22),
        ZIndex = 7
    })

    newObject("TextLabel", {
        Parent = titleBlock,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "Categories",
        TextColor3 = Library.Theme.MutedText,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Position = UDim2.new(0, 0, 0, 24),
        Size = UDim2.new(1, 0, 0, 30),
        ZIndex = 7
    })

    self.TabScroll = newObject("ScrollingFrame", {
        Parent = self.Sidebar,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, 84),
        Size = UDim2.new(1, -24, 1, -96),
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
        Position = UDim2.new(0, 252, 0, 88),
        Size = UDim2.new(1, -268, 1, -104),
        ZIndex = 6
    })

    local topBlock = newObject("Frame", {
        Parent = rightSide,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 62),
        ZIndex = 6
    })

    self.CommandBar = makeGlass(topBlock, {
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = Color3.fromRGB(92, 64, 79),
        BackgroundTransparency = 0.62,
        Radius = 14,
        ZIndex = 7,
        StrokeTransparency = 0.58,
        InnerStrokeTransparency = 0.88
    })
    self.CommandBar.Position = UDim2.new(0, 0, 0, 0)
    self.CommandBar.ZIndex = 7
    self:_animateStroke(self.CommandBar, 0.3)

    self.CurrentTabLabel = newObject("TextLabel", {
        Parent = self.CommandBar,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "Results",
        TextColor3 = Library.Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 18, 0, 7),
        Size = UDim2.new(0.44, 0, 0, 20),
        ZIndex = 8
    })

    self.CommandHint = newObject("TextLabel", {
        Parent = self.CommandBar,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "Suggestions and actions",
        TextColor3 = Library.Theme.MutedText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 18, 0, 28),
        Size = UDim2.new(0.56, -12, 0, 16),
        ZIndex = 8
    })

    local toggleBadge = makeGlass(topBlock, {
        Size = UDim2.fromOffset(122, 34),
        Radius = 12,
        BackgroundColor3 = Color3.fromRGB(93, 68, 80),
        BackgroundTransparency = 0.62,
        StrokeTransparency = 0.66,
        ZIndex = 7
    })
    toggleBadge.AnchorPoint = Vector2.new(1, 0)
    toggleBadge.Position = UDim2.new(1, 0, 0, 0)
    toggleBadge.ZIndex = 7

    self.ToggleHintLabel = newObject("TextLabel", {
        Parent = toggleBadge,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "Toggle K",
        TextColor3 = Library.Theme.MutedText,
        TextSize = 12,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 8
    })

    self.PageHolder = newObject("Frame", {
        Parent = rightSide,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 74),
        Size = UDim2.new(1, 0, 1, -134),
        ZIndex = 6
    })

    self.ActionBar = makeGlass(rightSide, {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Color3.fromRGB(92, 64, 78),
        BackgroundTransparency = 0.62,
        Radius = 14,
        ZIndex = 7,
        StrokeTransparency = 0.62
    })
    self.ActionBar.AnchorPoint = Vector2.new(0, 1)
    self.ActionBar.Position = UDim2.new(0, 0, 1, -6)
    self.ActionBar.ZIndex = 7
    self:_animateStroke(self.ActionBar, 0.26)

    self.ActionLabel = newObject("TextLabel", {
        Parent = self.ActionBar,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "Enter Select    " .. keybindToText(self.ToggleKeybind) .. " Toggle UI    M Minimize",
        TextColor3 = Library.Theme.MutedText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -28, 1, 0),
        ZIndex = 8
    })

    local buttonsHolder = newObject("Frame", {
        Parent = self.MainPanel,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -18, 0, 18),
        Size = UDim2.fromOffset(112, 34),
        ZIndex = 8
    })

    self.HideSurface = makeGlass(buttonsHolder, {
        Size = UDim2.fromOffset(52, 34),
        BackgroundColor3 = Color3.fromRGB(90, 62, 76),
        BackgroundTransparency = 0.6,
        Radius = 12,
        ZIndex = 8,
        StrokeTransparency = 0.68
    })
    self.HideSurface.Position = UDim2.new(0, 0, 0, 0)
    self.HideSurface.ZIndex = 8

    local hideButton = newObject("TextButton", {
        Parent = self.HideSurface,
        BackgroundTransparency = 1,
        Text = "Hide",
        Font = Enum.Font.GothamMedium,
        TextColor3 = Library.Theme.Text,
        TextSize = 13,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 9
    })

    self.MinimizeSurface = makeGlass(buttonsHolder, {
        Size = UDim2.fromOffset(52, 34),
        BackgroundColor3 = Color3.fromRGB(90, 62, 76),
        BackgroundTransparency = 0.6,
        Radius = 12,
        ZIndex = 8,
        StrokeTransparency = 0.68
    })
    self.MinimizeSurface.Position = UDim2.new(0, 60, 0, 0)
    self.MinimizeSurface.ZIndex = 8

    local minimizeButton = newObject("TextButton", {
        Parent = self.MinimizeSurface,
        BackgroundTransparency = 1,
        Text = "Min",
        Font = Enum.Font.GothamMedium,
        TextColor3 = Library.Theme.Text,
        TextSize = 13,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 9
    })

    self:_addHoverAnimation(self.HideSurface, hideButton, 0.6, 0.46)
    self:_addHoverAnimation(self.MinimizeSurface, minimizeButton, 0.6, 0.46)

    self:_connect(hideButton.MouseButton1Click, function()
        self:_toggleWindow()
    end)

    self:_connect(minimizeButton.MouseButton1Click, function()
        self:_minimizeWindow()
    end)

    self.DockSurface = makeGlass(self.MainOverlay, {
        Size = UDim2.fromOffset(240, 44),
        BackgroundColor3 = Color3.fromRGB(91, 64, 77),
        BackgroundTransparency = 0.58,
        Radius = 14,
        ZIndex = 10,
        StrokeTransparency = 0.56
    })
    self.DockSurface.AnchorPoint = Vector2.new(1, 1)
    self.DockSurface.Position = UDim2.new(1, -18, 1, -18)
    self.DockSurface.Visible = false
    self.DockSurface.ZIndex = 10
    self:_animateStroke(self.DockSurface, 0.28)

    local dockButton = newObject("TextButton", {
        Parent = self.DockSurface,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = (self.Config.Name or "Daw1dk Glass") .. "  [" .. keybindToText(self.ToggleKeybind) .. "]",
        TextColor3 = Library.Theme.Text,
        TextSize = 13,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 11
    })
    self.DockLabel = dockButton
    self:_addHoverAnimation(self.DockSurface, dockButton, 0.12, 0.04)
    self:_connect(dockButton.MouseButton1Click, function()
        self:_restoreWindow()
    end)
end

function Controller:_buildKeyOverlay()
    self.KeyOverlay = newObject("Frame", {
        Parent = self.Root,
        BackgroundColor3 = Library.Theme.Overlay,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 10
    })

    makeGlow(self.KeyOverlay, {
        BackgroundColor3 = Library.Theme.WarmGlow,
        BackgroundTransparency = 0.84,
        Position = UDim2.new(0.5, -260, 0.22, -30),
        Size = UDim2.fromOffset(520, 220),
        Rotation = -12,
        Radius = 999,
        ZIndex = 10,
        ColorSequence = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 165, 147)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(111, 48, 60))
        }),
        TransparencySequence = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.82),
            NumberSequenceKeypoint.new(0.7, 0.94),
            NumberSequenceKeypoint.new(1, 1)
        })
    })

    makeGlow(self.KeyOverlay, {
        BackgroundColor3 = Library.Theme.CoolGlow,
        BackgroundTransparency = 0.88,
        Position = UDim2.new(0.66, -100, 0.74, -90),
        Size = UDim2.fromOffset(420, 170),
        Rotation = 10,
        Radius = 999,
        ZIndex = 10,
        ColorSequence = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(171, 129, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(85, 55, 125))
        }),
        TransparencySequence = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.84),
            NumberSequenceKeypoint.new(0.68, 0.95),
            NumberSequenceKeypoint.new(1, 1)
        })
    })

    self.KeyPanel = makeGlass(self.KeyOverlay, {
        Name = "KeyPanel",
        Size = UDim2.fromOffset(560, 360),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.56),
        BackgroundColor3 = Library.Theme.Surface,
        BackgroundTransparency = 0.56,
        Radius = 18,
        ZIndex = 11,
        Visible = false,
        StrokeTransparency = 0.34,
        InnerStrokeTransparency = 0.72,
        TintTransparency = 0.88
    })
    self:_animateStroke(self.KeyPanel, 0.24)

    newObject("UIGradient", {
        Parent = self.KeyPanel,
        Rotation = 135,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(122, 76, 88)),
            ColorSequenceKeypoint.new(0.46, Color3.fromRGB(84, 59, 76)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(63, 46, 58))
        })
    })

    self.KeyScale = newObject("UIScale", {
        Parent = self.KeyPanel,
        Scale = 0.96
    })

    makePadding(self.KeyPanel, 28, 28, 28, 28)

    local profileRow = newObject("Frame", {
        Parent = self.KeyPanel,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 124),
        ZIndex = 12
    })

    local avatarSurface = makeGlass(profileRow, {
        Size = UDim2.fromOffset(96, 96),
        Position = UDim2.new(0, 0, 0, 10),
        BackgroundColor3 = Color3.fromRGB(84, 53, 64),
        BackgroundTransparency = 0.5,
        Radius = 16,
        ZIndex = 12,
        StrokeTransparency = 0.42
    })
    avatarSurface.ZIndex = 12

    local avatar = newObject("ImageLabel", {
        Parent = avatarSurface,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 6, 0, 6),
        Size = UDim2.new(1, -12, 1, -12),
        ScaleType = Enum.ScaleType.Crop,
        ZIndex = 13
    })
    makeCorner(avatar, 12)

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
        TextSize = 27,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 32),
        ZIndex = 13
    })

    newObject("TextLabel", {
        Parent = infoBlock,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = LocalPlayer.DisplayName,
        TextColor3 = Library.Theme.Text,
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
        Position = UDim2.new(0, 28, 0, 178),
        Size = UDim2.new(1, -56, 0, 148),
        ZIndex = 12
    })

    local keyInputSurface = makeGlass(self.KeyEntryBlock, {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = Color3.fromRGB(93, 64, 78),
        BackgroundTransparency = 0.56,
        Radius = 14,
        ZIndex = 12,
        StrokeTransparency = 0.4
    })
    keyInputSurface.ZIndex = 12

    self.KeyInput = newObject("TextBox", {
        Parent = keyInputSurface,
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        Font = Enum.Font.GothamMedium,
        PlaceholderText = "Enter key here",
        PlaceholderColor3 = Color3.fromRGB(146, 149, 156),
        Text = "",
        TextColor3 = Library.Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -28, 1, 0),
        ZIndex = 13
    })

    local confirmSurface = makeGlass(self.KeyEntryBlock, {
        Size = UDim2.new(0.56, -6, 0, 48),
        Position = UDim2.new(0, 0, 0, 76),
        BackgroundColor3 = Color3.fromRGB(108, 76, 90),
        BackgroundTransparency = 0.5,
        Radius = 14,
        ZIndex = 12,
        StrokeTransparency = 0.38
    })
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
    self:_addHoverAnimation(confirmSurface, confirmButton, 0.5, 0.36)

    local saveSurface = makeGlass(self.KeyEntryBlock, {
        Size = UDim2.new(0.44, -6, 0, 48),
        Position = UDim2.new(0.56, 6, 0, 76),
        BackgroundColor3 = Color3.fromRGB(90, 63, 76),
        BackgroundTransparency = 0.58,
        Radius = 14,
        ZIndex = 12,
        StrokeTransparency = 0.44
    })
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
        Position = UDim2.new(0, 0, 0, 132),
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
        BackgroundTransparency = 0.82
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
    self.KeyScale.Scale = 0.97
    self.KeyEntryBlock.Position = UDim2.new(0, 28, 0, 188)

    self:_tween(self.KeyOverlay, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.72
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
            Position = UDim2.new(0, 28, 0, 178)
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
    self.DockSurface.Visible = false
    self.MainOverlay.BackgroundTransparency = 1
    self.MainPanel.Position = UDim2.fromScale(0.5, 0.54)
    self.MainScale.Scale = 0.978
    self.WindowVisible = true
    self.Minimized = false
    self:_setBlur(22)

    self:_tween(self.MainOverlay, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.94
    })
    self:_tween(self.MainPanel, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.fromScale(0.5, 0.5)
    })
    self:_tween(self.MainScale, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Scale = 1
    })
end

function Controller:_hideMainWindow()
    self.WindowVisible = false
    self:_setBlur(0)
    self:_tween(self.MainOverlay, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1
    })
    self:_tween(self.MainPanel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.fromScale(0.5, 0.54)
    })
    self:_tween(self.MainScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Scale = 0.978
    })
    task.delay(0.2, function()
        if self.Destroyed then
            return
        end
        if not self.WindowVisible and not self.Minimized then
            self.MainOverlay.Visible = false
            self.MainPanel.Visible = false
        end
    end)
end

function Controller:_showDock()
    self.MainOverlay.Visible = true
    self.DockSurface.Visible = true
    self.MainOverlay.BackgroundTransparency = 1
    self.DockSurface.Position = UDim2.new(1, 8, 1, -18)
    self.WindowVisible = true
    self.Minimized = true
    self:_setBlur(0)

    self:_tween(self.DockSurface, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -18, 1, -18)
    })
end

function Controller:_hideDock()
    self.WindowVisible = false
    self:_setBlur(0)
    self:_tween(self.DockSurface, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(1, 8, 1, -18)
    })
    task.delay(0.2, function()
        if self.Destroyed then
            return
        end
        if not self.WindowVisible then
            self.DockSurface.Visible = false
            if not self.MainPanel.Visible then
                self.MainOverlay.Visible = false
            end
        end
    end)
end

function Controller:_minimizeWindow()
    if not self.Authenticated or self.Minimized then
        return
    end

    self.Minimized = true
    self.WindowVisible = false
    self:_setBlur(0)

    self:_tween(self.MainPanel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.fromScale(0.5, 0.54)
    })
    self:_tween(self.MainScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Scale = 0.978
    })

    task.delay(0.1, function()
        if self.Destroyed then
            return
        end
        self.MainPanel.Visible = false
        self:_showDock()
    end)
end

function Controller:_restoreWindow()
    if not self.Authenticated then
        return
    end

    self.DockSurface.Visible = false
    self.Minimized = false
    self:_showMainWindow()
end

function Controller:_hideInterface()
    if self.Minimized then
        self:_hideDock()
    else
        self:_hideMainWindow()
    end
end

function Controller:_toggleWindow()
    if not self.Authenticated then
        return
    end

    if self.WindowVisible then
        self:_hideInterface()
    else
        if self.Minimized then
            self:_showDock()
        else
            self:_showMainWindow()
        end
    end
end

function Controller:_setToggleKeybind(value)
    self.ToggleKeybind = resolveKeybind(value)

    if self.ToggleHintLabel then
        self.ToggleHintLabel.Text = "Toggle " .. keybindToText(self.ToggleKeybind)
    end

    if self.ActionLabel then
        self.ActionLabel.Text = "Enter Select    " .. keybindToText(self.ToggleKeybind) .. " Toggle UI    M Minimize"
    end

    if self.DockLabel then
        self.DockLabel.Text = (self.Config.Name or "Daw1dk Glass") .. "  [" .. keybindToText(self.ToggleKeybind) .. "]"
    end
end

function Controller:_bindInputs()
    self:_connect(UserInputService.InputBegan, function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if self.PendingKeybindCapture then
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
                local widget = self.PendingKeybindCapture
                self.PendingKeybindCapture = nil
                widget:_applyKeybind(input.KeyCode, true)
            end
            return
        end

        if UserInputService:GetFocusedTextBox() then
            return
        end

        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == self.ToggleKeybind then
                self:_toggleWindow()
            elseif input.KeyCode == Enum.KeyCode.M and self.WindowVisible and not self.Minimized then
                self:_minimizeWindow()
            end
        end
    end)

    self:_connect(RunService.Heartbeat, function(deltaTime)
        self:_refreshAnimatedStrokes(deltaTime)
    end)
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
    self.Authenticated = true
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
            BackgroundTransparency = selected and 0.34 or 0.58
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
    if self.CommandHint then
        self.CommandHint.Text = "Browsing " .. tabRecord.Name
    end
end

function Controller:_createTab(name, icon)
    local record = {
        Name = tostring(name or "Tab")
    }

    local buttonSurface = self:_makeInteractiveSurface(self.TabScroll, UDim2.new(1, -4, 0, 42))
    buttonSurface.BackgroundTransparency = 0.58
    buttonSurface.LayoutOrder = #self.Tabs + 1
    buttonSurface.ZIndex = 8
    self:_animateStroke(buttonSurface, 0.16)

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
        BackgroundTransparency = 0.36,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0.18, 0),
        Size = UDim2.new(0, 3, 0.64, 0),
        Visible = false,
        ZIndex = 10
    })
    makeCorner(indicator, 999)

    local iconLabel = newObject("ImageLabel", {
        Parent = buttonSurface,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0.5, -8),
        Size = UDim2.fromOffset(16, 16),
        Image = "",
        ImageColor3 = Color3.fromRGB(255, 255, 255),
        ImageTransparency = 0.24,
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
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 44, 0, 0),
        Size = UDim2.new(1, -52, 1, 0),
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

    self:_addHoverAnimation(buttonSurface, hitbox, 0.58, 0.46)
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
    self:_bindInputs()
    self:_setToggleKeybind(self.ToggleKeybind or Enum.KeyCode.K)
    self:_showLoading()

    task.delay(0.95, function()
        if self.Destroyed then
            return
        end

        self:_hideLoading()

        if self.Config.KeySystem then
            if self:_tryLoadSavedKey() then
                self.Authenticated = true
                self:_showMainWindow()
            else
                self:_showKeyOverlay()
            end
        else
            self.Authenticated = true
            self:_showMainWindow()
        end
    end)
end

function Controller:Destroy()
    if self.Destroyed then
        return
    end

    self.Destroyed = true
    self.PendingKeybindCapture = nil
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
        AnimatedStrokes = {},
        Destroyed = false,
        WindowVisible = false,
        Minimized = false,
        Authenticated = false,
        ToggleKeybind = resolveKeybind((config and config.ToggleKeybind) or Enum.KeyCode.K)
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

function WindowMethods:Toggle()
    self._controller:_toggleWindow()
end

function WindowMethods:Minimize()
    self._controller:_minimizeWindow()
end

function WindowMethods:Restore()
    self._controller:_restoreWindow()
end

function WindowMethods:SetToggleKeybind(value)
    self._controller:_setToggleKeybind(value)
end

function WindowMethods:GetToggleKeybind()
    return self._controller.ToggleKeybind
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
    panel.BackgroundTransparency = 0.5
    panel.ZIndex = 8
    self._controller:_animateStroke(panel, 0.14)
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
    panel.BackgroundTransparency = 0.54
    makePadding(panel, 18, 18, 16, 16)

    newObject("UIListLayout", {
        Parent = panel,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local title = newObject("TextLabel", {
        Parent = panel,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = config.Title or "Paragraph",
        TextColor3 = Library.Theme.Text,
        TextSize = 14,
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
        TextSize = 12,
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

function KeybindMethods:_applyKeybind(value, shouldCallback)
    self._value = resolveKeybind(value)
    self._button.Text = keybindToText(self._value)

    if type(self._changedCallback) == "function" and shouldCallback ~= false then
        safeCall(self._changedCallback, self._value)
    end
end

function KeybindMethods:Set(value)
    self:_applyKeybind(value, true)
end

function KeybindMethods:Get()
    return self._value
end

function TabMethods:CreateButton(options)
    local config = options or {}
    local panel = self:_newItem(48)
    panel.BackgroundTransparency = 0.5
    makePadding(panel, 18, 18, 0, 0)

    local button = newObject("TextButton", {
        Parent = panel,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = config.Name or "Button",
        TextColor3 = Library.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -70, 1, 0),
        ZIndex = 9
    })

    newObject("TextLabel", {
        Parent = panel,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "Enter",
        TextColor3 = Library.Theme.MutedText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(1, -56, 0, 0),
        Size = UDim2.new(0, 56, 1, 0),
        ZIndex = 9
    })

    self._controller:_addHoverAnimation(panel, button, 0.5, 0.4)
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

    local panel = self:_newItem(50)
    panel.BackgroundTransparency = 0.5
    makePadding(panel, 18, 18, 0, 0)

    newObject("TextLabel", {
        Parent = panel,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = config.Name or "Toggle",
        TextColor3 = Library.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -76, 1, 0),
        ZIndex = 9
    })

    local switch = self._controller:_makeInteractiveSurface(panel, UDim2.fromOffset(48, 24))
    switch.AnchorPoint = Vector2.new(1, 0.5)
    switch.Position = UDim2.new(1, 0, 0.5, 0)
    switch.BackgroundTransparency = 0.54
    switch.ZIndex = 9

    local switchFill = newObject("Frame", {
        Parent = switch,
        BackgroundColor3 = Library.Theme.Frost,
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 9
    })
    makeCorner(switchFill, 8)
    newObject("UIGradient", {
        Parent = switchFill,
        Rotation = 0,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 250, 252)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 211, 223))
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.14),
            NumberSequenceKeypoint.new(1, 0.38)
        })
    })

    local knob = newObject("Frame", {
        Parent = switch,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.06,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 4, 0.5, -8),
        Size = UDim2.fromOffset(16, 16),
        ZIndex = 10
    })
    makeCorner(knob, 8)

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
            BackgroundTransparency = state and 0.42 or 0.54
        })

        self._controller:_tween(switchFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = state and 0.46 or 0.72
        })

        self._controller:_tween(knob, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = state and UDim2.new(1, -20, 0.5, -8) or UDim2.new(0, 4, 0.5, -8),
            BackgroundTransparency = state and 0.02 or 0.06
        })

        if shouldCallback ~= false then
            safeCall(config.Callback, state)
        end
    end

    self._controller:_addHoverAnimation(panel, hitbox, 0.5, 0.42)
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

function TabMethods:CreateKeybind(options)
    local config = options or {}
    local panel = self:_newItem(50)
    panel.BackgroundTransparency = 0.5
    makePadding(panel, 18, 18, 0, 0)

    newObject("TextLabel", {
        Parent = panel,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = config.Name or "Keybind",
        TextColor3 = Library.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -116, 1, 0),
        ZIndex = 9
    })

    local keySurface = self._controller:_makeInteractiveSurface(panel, UDim2.fromOffset(104, 30))
    keySurface.AnchorPoint = Vector2.new(1, 0.5)
    keySurface.Position = UDim2.new(1, 0, 0.5, 0)
    keySurface.BackgroundTransparency = 0.5
    keySurface.ZIndex = 9

    local keyButton = newObject("TextButton", {
        Parent = keySurface,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = keybindToText(resolveKeybind(config.CurrentKeybind or "K")),
        TextColor3 = Library.Theme.Text,
        TextSize = 13,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 10
    })

    local widget

    widget = setmetatable({
        _controller = self._controller,
        _button = keyButton,
        _value = resolveKeybind(config.CurrentKeybind or "K"),
        _changedCallback = config.ChangedCallback or config.Callback
    }, KeybindMethods)

    self._controller:_addHoverAnimation(keySurface, keyButton, 0.5, 0.38)
    self._controller:_connect(keyButton.MouseButton1Click, function()
        self._controller.PendingKeybindCapture = widget
        keyButton.Text = "Press key"
    end)

    widget:_applyKeybind(widget._value, false)
    return widget
end

function TabMethods:CreateSlider(options)
    local config = options or {}
    local minValue = (config.Range and config.Range[1]) or 0
    local maxValue = (config.Range and config.Range[2]) or 100
    local increment = config.Increment or 1
    local current = roundToIncrement(config.CurrentValue or minValue, minValue, maxValue, increment)

    local panel = self:_newItem(84)
    panel.BackgroundTransparency = 0.5
    makePadding(panel, 18, 18, 14, 12)

    newObject("TextLabel", {
        Parent = panel,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = config.Name or "Slider",
        TextColor3 = Library.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0.7, 0, 0, 20),
        ZIndex = 9
    })

    local valueLabel = newObject("TextLabel", {
        Parent = panel,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = formatNumber(current),
        TextColor3 = Library.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(0.7, 0, 0, 0),
        Size = UDim2.new(0.3, 0, 0, 20),
        ZIndex = 9
    })

    local bar = self._controller:_makeInteractiveSurface(panel, UDim2.new(1, 0, 0, 12))
    bar.Position = UDim2.new(0, 0, 0, 42)
    bar.Size = UDim2.new(1, 0, 0, 8)
    bar.BackgroundTransparency = 0.58
    bar.ZIndex = 9

    local fill = newObject("Frame", {
        Parent = bar,
        BackgroundColor3 = Color3.fromRGB(253, 250, 252),
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 10
    })
    makeCorner(fill, 8)

    newObject("UIGradient", {
        Parent = fill,
        Rotation = 0,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(233, 223, 232))
        })
    })

    local knob = newObject("Frame", {
        Parent = bar,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.06,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        ZIndex = 11
    })
    makeCorner(knob, 8)

    newObject("TextLabel", {
        Parent = panel,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = formatNumber(minValue),
        TextColor3 = Library.Theme.MutedText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 0, 0, 58),
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
        Position = UDim2.new(0.5, 0, 0, 58),
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

    self._controller:_addHoverAnimation(bar, hitbox, 0.58, 0.46)
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
