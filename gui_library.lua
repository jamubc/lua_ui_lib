--[[
    Roblox UI Library
    A sleek, fast, and dynamic UI library for creating menus and interfaces in Roblox
    Features: Buttons, Labels, Sections, Sliders, Hotkey toggling, smooth animations

    Example Usage:
        local UILib = require(script.Parent.gui_library)
        local ui = UILib:new()

        local window = ui:CreateWindow({
            Title = "My Menu",
            Size = UDim2.new(0, 400, 0, 500),
            Position = UDim2.new(0.5, -200, 0.5, -250)
        })

        local section = window:AddSection({Title = "Main"})
        section:AddButton({Text = "Click Me", Callback = function() print("Clicked!") end})
        section:AddSlider({Text = "Volume", Min = 0, Max = 100, Default = 50, Callback = function(val) print(val) end})

        ui:RegisterHotkey(Enum.KeyCode.Insert, function() window:Toggle() end)
]]

local UILibrary = {}
UILibrary.__index = UILibrary

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ============================================================================
-- THEME SYSTEM
-- ============================================================================

local DefaultTheme = {
    -- Colors (using Color3.fromRGB)
    Background = Color3.fromRGB(20, 20, 25),
    TitleBar = Color3.fromRGB(30, 30, 40),
    Section = Color3.fromRGB(25, 25, 30),
    Button = Color3.fromRGB(45, 45, 55),
    ButtonHover = Color3.fromRGB(60, 60, 75),
    ButtonActive = Color3.fromRGB(70, 130, 180),
    Slider = Color3.fromRGB(45, 45, 55),
    SliderFill = Color3.fromRGB(70, 130, 180),
    SliderHandle = Color3.fromRGB(90, 150, 200),
    Text = Color3.fromRGB(220, 220, 220),
    TextDim = Color3.fromRGB(150, 150, 150),
    Border = Color3.fromRGB(60, 60, 70),
    Accent = Color3.fromRGB(70, 130, 180),

    -- Dimensions
    Padding = 8,
    Spacing = 6,
    CornerRadius = UDim.new(0, 6),
    BorderThickness = 1,

    -- Transparency
    BackgroundTransparency = 0.05,

    -- Animation
    AnimationSpeed = 0.2,
    EasingStyle = Enum.EasingStyle.Quad,
    EasingDirection = Enum.EasingDirection.Out
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function CreateTween(instance, properties, duration, easingStyle, easingDirection)
    duration = duration or DefaultTheme.AnimationSpeed
    easingStyle = easingStyle or DefaultTheme.EasingStyle
    easingDirection = easingDirection or DefaultTheme.EasingDirection

    local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

local function MakeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame

    local dragging = false
    local dragInput, mousePos, framePos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            CreateTween(frame, {
                Position = UDim2.new(
                    framePos.X.Scale,
                    framePos.X.Offset + delta.X,
                    framePos.Y.Scale,
                    framePos.Y.Offset + delta.Y
                )
            }, 0.1)
        end
    end)
end

-- ============================================================================
-- LABEL COMPONENT
-- ============================================================================

local Label = {}
Label.__index = Label

function Label:new(parent, config, theme)
    local self = setmetatable({}, Label)
    theme = theme or DefaultTheme

    self.Instance = Instance.new("TextLabel")
    self.Instance.Name = "Label"
    self.Instance.Size = UDim2.new(1, 0, 0, 25)
    self.Instance.BackgroundTransparency = 1
    self.Instance.Font = Enum.Font.Gotham
    self.Instance.TextSize = 14
    self.Instance.TextColor3 = theme.Text
    self.Instance.TextXAlignment = Enum.TextXAlignment.Left
    self.Instance.Text = config.Text or "Label"
    self.Instance.Parent = parent

    if config.TextSize then
        self.Instance.TextSize = config.TextSize
    end

    if config.TextColor then
        self.Instance.TextColor3 = config.TextColor
    end

    return self
end

function Label:SetText(text)
    self.Instance.Text = text
end

function Label:Destroy()
    self.Instance:Destroy()
end

-- ============================================================================
-- TEXTBOX COMPONENT
-- ============================================================================

local TextBox = {}
TextBox.__index = TextBox

function TextBox:new(parent, config, theme)
    local self = setmetatable({}, TextBox)
    theme = theme or DefaultTheme

    self.Callback = config.Callback or function() end

    -- Container
    self.Container = Instance.new("Frame")
    self.Container.Name = "TextBoxContainer"
    self.Container.Size = UDim2.new(1, 0, 0, 50)
    self.Container.BackgroundTransparency = 1
    self.Container.Parent = parent

    -- Label
    self.Label = Instance.new("TextLabel")
    self.Label.Name = "Label"
    self.Label.Size = UDim2.new(1, 0, 0, 20)
    self.Label.Position = UDim2.new(0, 0, 0, 0)
    self.Label.BackgroundTransparency = 1
    self.Label.Font = Enum.Font.Gotham
    self.Label.TextSize = 13
    self.Label.TextColor3 = theme.Text
    self.Label.TextXAlignment = Enum.TextXAlignment.Left
    self.Label.Text = config.Text or "Input"
    self.Label.Parent = self.Container

    -- TextBox
    self.TextBox = Instance.new("TextBox")
    self.TextBox.Name = "TextBox"
    self.TextBox.Size = UDim2.new(1, 0, 0, 30)
    self.TextBox.Position = UDim2.new(0, 0, 0, 22)
    self.TextBox.BackgroundColor3 = theme.Button
    self.TextBox.BorderSizePixel = 0
    self.TextBox.Font = Enum.Font.Gotham
    self.TextBox.TextSize = 14
    self.TextBox.TextColor3 = theme.Text
    self.TextBox.PlaceholderText = config.Placeholder or "Enter text..."
    self.TextBox.Text = config.Default or ""
    self.TextBox.ClearTextOnFocus = false
    self.TextBox.Parent = self.Container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = theme.CornerRadius
    corner.Parent = self.TextBox

    -- Padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = self.TextBox

    -- Events
    self.TextBox.FocusLost:Connect(function(enterPressed)
        self.Callback(self.TextBox.Text, enterPressed)
    end)

    return self
end

function TextBox:GetText()
    return self.TextBox.Text
end

function TextBox:SetText(text)
    self.TextBox.Text = text
end

function TextBox:Destroy()
    self.Container:Destroy()
end

-- ============================================================================
-- BUTTON COMPONENT
-- ============================================================================

local Button = {}
Button.__index = Button

function Button:new(parent, config, theme)
    local self = setmetatable({}, Button)
    theme = theme or DefaultTheme

    -- Container
    self.Container = Instance.new("Frame")
    self.Container.Name = "ButtonContainer"
    self.Container.Size = UDim2.new(1, 0, 0, 35)
    self.Container.BackgroundTransparency = 1
    self.Container.Parent = parent

    -- Button
    self.Button = Instance.new("TextButton")
    self.Button.Name = "Button"
    self.Button.Size = UDim2.new(1, 0, 1, 0)
    self.Button.BackgroundColor3 = theme.Button
    self.Button.BorderSizePixel = 0
    self.Button.Font = Enum.Font.GothamSemibold
    self.Button.TextSize = 14
    self.Button.TextColor3 = theme.Text
    self.Button.Text = config.Text or "Button"
    self.Button.AutoButtonColor = false
    self.Button.Parent = self.Container

    -- Corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = theme.CornerRadius
    corner.Parent = self.Button

    -- Events
    self.Callback = config.Callback or function() end

    self.Button.MouseEnter:Connect(function()
        CreateTween(self.Button, {BackgroundColor3 = theme.ButtonHover})
    end)

    self.Button.MouseLeave:Connect(function()
        CreateTween(self.Button, {BackgroundColor3 = theme.Button})
    end)

    self.Button.MouseButton1Down:Connect(function()
        CreateTween(self.Button, {BackgroundColor3 = theme.ButtonActive}, 0.1)
    end)

    self.Button.MouseButton1Up:Connect(function()
        CreateTween(self.Button, {BackgroundColor3 = theme.ButtonHover}, 0.1)
    end)

    self.Button.MouseButton1Click:Connect(function()
        self.Callback()
    end)

    return self
end

function Button:SetText(text)
    self.Button.Text = text
end

function Button:SetCallback(callback)
    self.Callback = callback
end

function Button:Destroy()
    self.Container:Destroy()
end

-- ============================================================================
-- SLIDER COMPONENT
-- ============================================================================

local Slider = {}
Slider.__index = Slider

function Slider:new(parent, config, theme)
    local self = setmetatable({}, Slider)
    theme = theme or DefaultTheme

    self.Min = config.Min or 0
    self.Max = config.Max or 100
    self.Value = config.Default or self.Min
    self.Increment = config.Increment or 1
    self.Callback = config.Callback or function() end

    -- Container
    self.Container = Instance.new("Frame")
    self.Container.Name = "SliderContainer"
    self.Container.Size = UDim2.new(1, 0, 0, 50)
    self.Container.BackgroundTransparency = 1
    self.Container.Parent = parent

    -- Label
    self.Label = Instance.new("TextLabel")
    self.Label.Name = "Label"
    self.Label.Size = UDim2.new(0.7, 0, 0, 20)
    self.Label.Position = UDim2.new(0, 0, 0, 0)
    self.Label.BackgroundTransparency = 1
    self.Label.Font = Enum.Font.Gotham
    self.Label.TextSize = 13
    self.Label.TextColor3 = theme.Text
    self.Label.TextXAlignment = Enum.TextXAlignment.Left
    self.Label.Text = config.Text or "Slider"
    self.Label.Parent = self.Container

    -- Value Label
    self.ValueLabel = Instance.new("TextLabel")
    self.ValueLabel.Name = "Value"
    self.ValueLabel.Size = UDim2.new(0.3, 0, 0, 20)
    self.ValueLabel.Position = UDim2.new(0.7, 0, 0, 0)
    self.ValueLabel.BackgroundTransparency = 1
    self.ValueLabel.Font = Enum.Font.GothamBold
    self.ValueLabel.TextSize = 13
    self.ValueLabel.TextColor3 = theme.Accent
    self.ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    self.ValueLabel.Text = tostring(self.Value)
    self.ValueLabel.Parent = self.Container

    -- Slider Background
    self.SliderBack = Instance.new("Frame")
    self.SliderBack.Name = "SliderBack"
    self.SliderBack.Size = UDim2.new(1, 0, 0, 6)
    self.SliderBack.Position = UDim2.new(0, 0, 0, 30)
    self.SliderBack.BackgroundColor3 = theme.Slider
    self.SliderBack.BorderSizePixel = 0
    self.SliderBack.Parent = self.Container

    local backCorner = Instance.new("UICorner")
    backCorner.CornerRadius = UDim.new(0, 3)
    backCorner.Parent = self.SliderBack

    -- Slider Fill
    self.SliderFill = Instance.new("Frame")
    self.SliderFill.Name = "Fill"
    self.SliderFill.Size = UDim2.new(0, 0, 1, 0)
    self.SliderFill.BackgroundColor3 = theme.SliderFill
    self.SliderFill.BorderSizePixel = 0
    self.SliderFill.Parent = self.SliderBack

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = self.SliderFill

    -- Slider Handle
    self.Handle = Instance.new("Frame")
    self.Handle.Name = "Handle"
    self.Handle.Size = UDim2.new(0, 16, 0, 16)
    self.Handle.Position = UDim2.new(0, -8, 0.5, -8)
    self.Handle.BackgroundColor3 = theme.SliderHandle
    self.Handle.BorderSizePixel = 0
    self.Handle.Parent = self.SliderBack

    local handleCorner = Instance.new("UICorner")
    handleCorner.CornerRadius = UDim.new(1, 0)
    handleCorner.Parent = self.Handle

    -- Interaction
    local dragging = false

    local function UpdateSlider(input)
        local pos = math.clamp((input.Position.X - self.SliderBack.AbsolutePosition.X) / self.SliderBack.AbsoluteSize.X, 0, 1)
        local value = math.floor((self.Min + (self.Max - self.Min) * pos) / self.Increment + 0.5) * self.Increment
        value = math.clamp(value, self.Min, self.Max)

        self.Value = value
        self.ValueLabel.Text = tostring(value)

        local fillSize = (value - self.Min) / (self.Max - self.Min)
        CreateTween(self.SliderFill, {Size = UDim2.new(fillSize, 0, 1, 0)}, 0.1)
        CreateTween(self.Handle, {Position = UDim2.new(fillSize, -8, 0.5, -8)}, 0.1)

        self.Callback(value)
    end

    self.SliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            UpdateSlider(input)
        end
    end)

    self.SliderBack.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateSlider(input)
        end
    end)

    -- Set initial position
    local initialPos = (self.Value - self.Min) / (self.Max - self.Min)
    self.SliderFill.Size = UDim2.new(initialPos, 0, 1, 0)
    self.Handle.Position = UDim2.new(initialPos, -8, 0.5, -8)

    return self
end

function Slider:SetValue(value)
    value = math.clamp(value, self.Min, self.Max)
    self.Value = value
    self.ValueLabel.Text = tostring(value)

    local fillSize = (value - self.Min) / (self.Max - self.Min)
    CreateTween(self.SliderFill, {Size = UDim2.new(fillSize, 0, 1, 0)})
    CreateTween(self.Handle, {Position = UDim2.new(fillSize, -8, 0.5, -8)})
end

function Slider:Destroy()
    self.Container:Destroy()
end

-- ============================================================================
-- SECTION COMPONENT (Collapsible Container)
-- ============================================================================

local Section = {}
Section.__index = Section

function Section:new(parent, config, theme)
    local self = setmetatable({}, Section)
    theme = theme or DefaultTheme

    self.Collapsed = false
    self.Components = {}

    -- Section Container
    self.Container = Instance.new("Frame")
    self.Container.Name = "Section"
    self.Container.Size = UDim2.new(1, 0, 0, 100)
    self.Container.BackgroundColor3 = theme.Section
    self.Container.BorderSizePixel = 0
    self.Container.Parent = parent

    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = theme.CornerRadius
    sectionCorner.Parent = self.Container

    -- Title Bar
    self.TitleBar = Instance.new("TextButton")
    self.TitleBar.Name = "TitleBar"
    self.TitleBar.Size = UDim2.new(1, 0, 0, 30)
    self.TitleBar.BackgroundColor3 = theme.TitleBar
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.Font = Enum.Font.GothamBold
    self.TitleBar.TextSize = 14
    self.TitleBar.TextColor3 = theme.Text
    self.TitleBar.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleBar.Text = "  ▼ " .. (config.Title or "Section")
    self.TitleBar.AutoButtonColor = false
    self.TitleBar.Parent = self.Container

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = theme.CornerRadius
    titleCorner.Parent = self.TitleBar

    -- Content Container
    self.Content = Instance.new("Frame")
    self.Content.Name = "Content"
    self.Content.Size = UDim2.new(1, -theme.Padding * 2, 1, -40)
    self.Content.Position = UDim2.new(0, theme.Padding, 0, 35)
    self.Content.BackgroundTransparency = 1
    self.Content.ClipsDescendants = true
    self.Content.Parent = self.Container

    -- Layout
    self.Layout = Instance.new("UIListLayout")
    self.Layout.SortOrder = Enum.SortOrder.LayoutOrder
    self.Layout.Padding = UDim.new(0, theme.Spacing)
    self.Layout.Parent = self.Content

    -- Collapse/Expand
    self.TitleBar.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    -- Auto-resize
    self.Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if not self.Collapsed then
            self.Container.Size = UDim2.new(1, 0, 0, self.Layout.AbsoluteContentSize.Y + 45)
        end
    end)

    return self
end

function Section:Toggle()
    self.Collapsed = not self.Collapsed

    if self.Collapsed then
        self.TitleBar.Text = self.TitleBar.Text:gsub("▼", "▶")
        CreateTween(self.Container, {Size = UDim2.new(1, 0, 0, 30)})
        CreateTween(self.Content, {Size = UDim2.new(1, -16, 0, 0)})
    else
        self.TitleBar.Text = self.TitleBar.Text:gsub("▶", "▼")
        local targetHeight = self.Layout.AbsoluteContentSize.Y + 45
        CreateTween(self.Container, {Size = UDim2.new(1, 0, 0, targetHeight)})
        CreateTween(self.Content, {Size = UDim2.new(1, -16, 1, -40)})
    end
end

function Section:AddLabel(config)
    local label = Label:new(self.Content, config)
    table.insert(self.Components, label)
    return label
end

function Section:AddTextBox(config)
    local textbox = TextBox:new(self.Content, config)
    table.insert(self.Components, textbox)
    return textbox
end

function Section:AddButton(config)
    local button = Button:new(self.Content, config)
    table.insert(self.Components, button)
    return button
end

function Section:AddSlider(config)
    local slider = Slider:new(self.Content, config)
    table.insert(self.Components, slider)
    return slider
end

function Section:Destroy()
    self.Container:Destroy()
end

-- ============================================================================
-- WINDOW (Main Container)
-- ============================================================================

local Window = {}
Window.__index = Window

function Window:new(parent, config, theme)
    local self = setmetatable({}, Window)
    theme = theme or DefaultTheme
    self.Theme = theme

    self.Visible = true
    self.Components = {}

    -- Main Frame
    self.Frame = Instance.new("Frame")
    self.Frame.Name = "Window"
    self.Frame.Size = config.Size or UDim2.new(0, 400, 0, 500)
    self.Frame.Position = config.Position or UDim2.new(0.5, -200, 0.5, -250)
    self.Frame.BackgroundColor3 = theme.Background
    self.Frame.BorderSizePixel = 0
    self.Frame.Active = true
    self.Frame.Parent = parent

    local windowCorner = Instance.new("UICorner")
    windowCorner.CornerRadius = theme.CornerRadius
    windowCorner.Parent = self.Frame

    -- Title Bar
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Name = "TitleBar"
    self.TitleBar.Size = UDim2.new(1, 0, 0, 40)
    self.TitleBar.BackgroundColor3 = theme.TitleBar
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.Parent = self.Frame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = theme.CornerRadius
    titleCorner.Parent = self.TitleBar

    -- Title Text
    self.Title = Instance.new("TextLabel")
    self.Title.Name = "Title"
    self.Title.Size = UDim2.new(1, -20, 1, 0)
    self.Title.Position = UDim2.new(0, 10, 0, 0)
    self.Title.BackgroundTransparency = 1
    self.Title.Font = Enum.Font.GothamBold
    self.Title.TextSize = 16
    self.Title.TextColor3 = theme.Text
    self.Title.TextXAlignment = Enum.TextXAlignment.Left
    self.Title.Text = config.Title or "UI Window"
    self.Title.Parent = self.TitleBar

    -- Content Container
    self.Content = Instance.new("ScrollingFrame")
    self.Content.Name = "Content"
    self.Content.Size = UDim2.new(1, -theme.Padding * 2, 1, -50 - theme.Padding)
    self.Content.Position = UDim2.new(0, theme.Padding, 0, 45)
    self.Content.BackgroundTransparency = 1
    self.Content.BorderSizePixel = 0
    self.Content.ScrollBarThickness = 4
    self.Content.ScrollBarImageColor3 = theme.Accent
    self.Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.Content.Parent = self.Frame

    -- Layout
    self.Layout = Instance.new("UIListLayout")
    self.Layout.SortOrder = Enum.SortOrder.LayoutOrder
    self.Layout.Padding = UDim.new(0, theme.Spacing)
    self.Layout.Parent = self.Content

    -- Auto-resize canvas
    self.Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.Content.CanvasSize = UDim2.new(0, 0, 0, self.Layout.AbsoluteContentSize.Y)
    end)

    -- Make draggable
    MakeDraggable(self.Frame, self.TitleBar)

    return self
end

function Window:AddSection(config)
    local section = Section:new(self.Content, config, self.Theme)
    table.insert(self.Components, section)
    return section
end

function Window:AddLabel(config)
    local label = Label:new(self.Content, config, self.Theme)
    table.insert(self.Components, label)
    return label
end

function Window:AddTextBox(config)
    local textbox = TextBox:new(self.Content, config, self.Theme)
    table.insert(self.Components, textbox)
    return textbox
end

function Window:AddButton(config)
    local button = Button:new(self.Content, config, self.Theme)
    table.insert(self.Components, button)
    return button
end

function Window:AddSlider(config)
    local slider = Slider:new(self.Content, config, self.Theme)
    table.insert(self.Components, slider)
    return slider
end

function Window:Show()
    self.Visible = true
    self.Frame.Visible = true
end

function Window:Hide()
    self.Visible = false
    self.Frame.Visible = false
end

function Window:Toggle()
    self.Visible = not self.Visible
    self.Frame.Visible = self.Visible
end

function Window:Destroy()
    self.Frame:Destroy()
end

-- ============================================================================
-- UI MANAGER (Main Entry Point)
-- ============================================================================

function UILibrary:new()
    local self = setmetatable({}, UILibrary)

    -- Create ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "Pischokiller"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.Parent = game:GetService("CoreGui")

    self.Windows = {}
    self.Hotkeys = {}
    self.Theme = DefaultTheme

    -- Hotkey Handler
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if self.Hotkeys[input.KeyCode] then
            self.Hotkeys[input.KeyCode]()
        end
    end)

    return self
end

function UILibrary:CreateWindow(config)
    config = config or {}
    local window = Window:new(self.ScreenGui, config, self.Theme)
    table.insert(self.Windows, window)
    return window
end

function UILibrary:RegisterHotkey(keyCode, callback)
    self.Hotkeys[keyCode] = callback
    return self
end

function UILibrary:SetTheme(theme)
    self.Theme = theme
    return self
end

function UILibrary:Destroy()
    self.ScreenGui:Destroy()
end

return UILibrary
