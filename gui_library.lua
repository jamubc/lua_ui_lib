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
    Background = Color3.fromRGB(15, 15, 20),
    TitleBar = Color3.fromRGB(20, 20, 28),
    Section = Color3.fromRGB(18, 18, 24),
    Button = Color3.fromRGB(35, 35, 45),
    ButtonHover = Color3.fromRGB(70, 130, 180),
    ButtonActive = Color3.fromRGB(85, 145, 195),
    Slider = Color3.fromRGB(35, 35, 45),
    SliderFill = Color3.fromRGB(70, 130, 180),
    SliderHandle = Color3.fromRGB(90, 150, 200),
    Text = Color3.fromRGB(220, 220, 220),
    TextDim = Color3.fromRGB(150, 150, 150),
    Border = Color3.fromRGB(60, 60, 70),
    Accent = Color3.fromRGB(70, 130, 180),

    -- Dimensions
    Padding = 8,
    Spacing = 6,
    CornerRadius = UDim.new(0, 8),
    BorderThickness = 1,

    -- Transparency
    BackgroundTransparency = 0.3,
    TitleBarTransparency = 0.2,
    SectionTransparency = 0.4,
    ButtonTransparency = 0.15,

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
    self.TextBox.BackgroundTransparency = theme.ButtonTransparency
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
    self.Container.Size = UDim2.new(1, 0, 0, 38)
    self.Container.BackgroundTransparency = 1
    self.Container.Parent = parent

    -- Button
    self.Button = Instance.new("TextButton")
    self.Button.Name = "Button"
    self.Button.Size = UDim2.new(1, 0, 1, 0)
    self.Button.BackgroundColor3 = theme.Button
    self.Button.BackgroundTransparency = theme.ButtonTransparency
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

    -- Subtle border/stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = theme.Accent
    stroke.Thickness = 0
    stroke.Transparency = 0.7
    stroke.Parent = self.Button

    -- Events
    self.Callback = config.Callback or function() end

    self.Button.MouseEnter:Connect(function()
        CreateTween(self.Button, {BackgroundColor3 = theme.ButtonHover, BackgroundTransparency = 0})
        CreateTween(stroke, {Thickness = 1.5, Transparency = 0})
    end)

    self.Button.MouseLeave:Connect(function()
        CreateTween(self.Button, {BackgroundColor3 = theme.Button, BackgroundTransparency = theme.ButtonTransparency})
        CreateTween(stroke, {Thickness = 0, Transparency = 0.7})
    end)

    self.Button.MouseButton1Down:Connect(function()
        CreateTween(self.Button, {BackgroundColor3 = theme.ButtonActive, BackgroundTransparency = 0}, 0.1)
    end)

    self.Button.MouseButton1Up:Connect(function()
        CreateTween(self.Button, {BackgroundColor3 = theme.ButtonHover, BackgroundTransparency = 0}, 0.1)
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
    self.SliderBack.BackgroundTransparency = theme.ButtonTransparency
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
-- DROPDOWN COMPONENT (with Search)
-- ============================================================================

local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown:new(parent, config, theme)
    local self = setmetatable({}, Dropdown)
    theme = theme or DefaultTheme

    self.Items = config.Items or {}
    self.SelectedValue = config.Default or nil
    self.Callback = config.Callback or function() end
    self.IsOpen = false
    self.ItemButtons = {}

    -- Container
    self.Container = Instance.new("Frame")
    self.Container.Name = "DropdownContainer"
    self.Container.Size = UDim2.new(1, 0, 0, 70)
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
    self.Label.Text = config.Text or "Dropdown"
    self.Label.Parent = self.Container

    -- Header Button (shows selected value)
    self.HeaderButton = Instance.new("TextButton")
    self.HeaderButton.Name = "HeaderButton"
    self.HeaderButton.Size = UDim2.new(1, 0, 0, 38)
    self.HeaderButton.Position = UDim2.new(0, 0, 0, 24)
    self.HeaderButton.BackgroundColor3 = theme.Button
    self.HeaderButton.BackgroundTransparency = theme.ButtonTransparency
    self.HeaderButton.BorderSizePixel = 0
    self.HeaderButton.Font = Enum.Font.Gotham
    self.HeaderButton.TextSize = 14
    self.HeaderButton.TextColor3 = theme.Text
    self.HeaderButton.TextXAlignment = Enum.TextXAlignment.Left
    self.HeaderButton.Text = "  " .. (self.SelectedValue or config.Placeholder or "Select...")
    self.HeaderButton.AutoButtonColor = false
    self.HeaderButton.Parent = self.Container

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = theme.CornerRadius
    headerCorner.Parent = self.HeaderButton

    local headerPadding = Instance.new("UIPadding")
    headerPadding.PaddingLeft = UDim.new(0, 10)
    headerPadding.PaddingRight = UDim.new(0, 10)
    headerPadding.Parent = self.HeaderButton

    -- Arrow Icon
    self.ArrowIcon = Instance.new("TextLabel")
    self.ArrowIcon.Name = "Arrow"
    self.ArrowIcon.Size = UDim2.new(0, 20, 1, 0)
    self.ArrowIcon.Position = UDim2.new(1, -25, 0, 0)
    self.ArrowIcon.BackgroundTransparency = 1
    self.ArrowIcon.Font = Enum.Font.GothamBold
    self.ArrowIcon.TextSize = 14
    self.ArrowIcon.TextColor3 = theme.TextDim
    self.ArrowIcon.Text = "▼"
    self.ArrowIcon.Parent = self.HeaderButton

    -- Dropdown Panel (expandable)
    self.DropdownPanel = Instance.new("Frame")
    self.DropdownPanel.Name = "DropdownPanel"
    self.DropdownPanel.Size = UDim2.new(1, 0, 0, 0)
    self.DropdownPanel.Position = UDim2.new(0, 0, 0, 66)
    self.DropdownPanel.BackgroundColor3 = theme.Section
    self.DropdownPanel.BackgroundTransparency = theme.SectionTransparency
    self.DropdownPanel.BorderSizePixel = 0
    self.DropdownPanel.ClipsDescendants = true
    self.DropdownPanel.Visible = false
    self.DropdownPanel.Parent = self.Container

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = theme.CornerRadius
    panelCorner.Parent = self.DropdownPanel

    -- Search Box
    self.SearchBox = Instance.new("TextBox")
    self.SearchBox.Name = "SearchBox"
    self.SearchBox.Size = UDim2.new(1, -12, 0, 32)
    self.SearchBox.Position = UDim2.new(0, 6, 0, 6)
    self.SearchBox.BackgroundColor3 = theme.Button
    self.SearchBox.BackgroundTransparency = theme.ButtonTransparency
    self.SearchBox.BorderSizePixel = 0
    self.SearchBox.Font = Enum.Font.Gotham
    self.SearchBox.TextSize = 13
    self.SearchBox.TextColor3 = theme.Text
    self.SearchBox.PlaceholderText = "Search..."
    self.SearchBox.Text = ""
    self.SearchBox.ClearTextOnFocus = false
    self.SearchBox.Parent = self.DropdownPanel

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 6)
    searchCorner.Parent = self.SearchBox

    local searchPadding = Instance.new("UIPadding")
    searchPadding.PaddingLeft = UDim.new(0, 8)
    searchPadding.PaddingRight = UDim.new(0, 8)
    searchPadding.Parent = self.SearchBox

    -- Item List Container (Scrollable)
    self.ItemList = Instance.new("ScrollingFrame")
    self.ItemList.Name = "ItemList"
    self.ItemList.Size = UDim2.new(1, -12, 1, -50)
    self.ItemList.Position = UDim2.new(0, 6, 0, 44)
    self.ItemList.BackgroundTransparency = 1
    self.ItemList.BorderSizePixel = 0
    self.ItemList.ScrollBarThickness = 4
    self.ItemList.ScrollBarImageColor3 = theme.Accent
    self.ItemList.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.ItemList.Parent = self.DropdownPanel

    local itemLayout = Instance.new("UIListLayout")
    itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
    itemLayout.Padding = UDim.new(0, 2)
    itemLayout.Parent = self.ItemList

    -- Auto-resize canvas
    itemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.ItemList.CanvasSize = UDim2.new(0, 0, 0, itemLayout.AbsoluteContentSize.Y)
    end)

    -- Header Button Click (Toggle)
    self.HeaderButton.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    -- Header Hover Effects
    self.HeaderButton.MouseEnter:Connect(function()
        CreateTween(self.HeaderButton, {BackgroundColor3 = theme.ButtonHover, BackgroundTransparency = 0})
    end)

    self.HeaderButton.MouseLeave:Connect(function()
        CreateTween(self.HeaderButton, {BackgroundColor3 = theme.Button, BackgroundTransparency = theme.ButtonTransparency})
    end)

    -- Search Filter
    self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self:UpdateFilter(self.SearchBox.Text)
    end)

    -- Store theme for later use
    self.Theme = theme

    -- Render initial items
    self:RenderItems()

    return self
end

function Dropdown:RenderItems()
    -- Clear existing item buttons
    for _, btn in pairs(self.ItemButtons) do
        btn:Destroy()
    end
    self.ItemButtons = {}

    -- Get search filter
    local searchText = self.SearchBox.Text:lower()

    -- Create buttons for each item
    for _, item in ipairs(self.Items) do
        local displayText = type(item) == "table" and item.Display or tostring(item)
        local value = type(item) == "table" and item.Value or item

        -- Apply search filter
        if searchText == "" or displayText:lower():find(searchText, 1, true) then
            local itemButton = Instance.new("TextButton")
            itemButton.Name = "Item_" .. tostring(value)
            itemButton.Size = UDim2.new(1, 0, 0, 32)
            itemButton.BackgroundColor3 = self.Theme.Button
            itemButton.BackgroundTransparency = value == self.SelectedValue and 0.05 or self.Theme.ButtonTransparency
            itemButton.BorderSizePixel = 0
            itemButton.Font = Enum.Font.Gotham
            itemButton.TextSize = 13
            itemButton.TextColor3 = self.Theme.Text
            itemButton.TextXAlignment = Enum.TextXAlignment.Left
            itemButton.Text = "  " .. displayText
            itemButton.AutoButtonColor = false
            itemButton.Parent = self.ItemList

            local itemCorner = Instance.new("UICorner")
            itemCorner.CornerRadius = UDim.new(0, 6)
            itemCorner.Parent = itemButton

            -- Hover effects
            itemButton.MouseEnter:Connect(function()
                CreateTween(itemButton, {BackgroundColor3 = self.Theme.ButtonHover, BackgroundTransparency = 0}, 0.15)
            end)

            itemButton.MouseLeave:Connect(function()
                local targetTransparency = value == self.SelectedValue and 0.05 or self.Theme.ButtonTransparency
                CreateTween(itemButton, {BackgroundColor3 = self.Theme.Button, BackgroundTransparency = targetTransparency}, 0.15)
            end)

            -- Selection
            itemButton.MouseButton1Click:Connect(function()
                self:SetSelected(value)
                self:Close()
                self.Callback(value)
            end)

            table.insert(self.ItemButtons, itemButton)
        end
    end
end

function Dropdown:UpdateFilter(searchText)
    self:RenderItems()
end

function Dropdown:AddItem(item)
    table.insert(self.Items, item)
    self:RenderItems()
end

function Dropdown:RemoveItem(value)
    for i, item in ipairs(self.Items) do
        local itemValue = type(item) == "table" and item.Value or item
        if itemValue == value then
            table.remove(self.Items, i)
            break
        end
    end
    self:RenderItems()
end

function Dropdown:ClearItems()
    self.Items = {}
    self.SelectedValue = nil
    self.HeaderButton.Text = "  " .. (config and config.Placeholder or "Select...")
    self:RenderItems()
end

function Dropdown:SetItems(items)
    self.Items = items
    self:RenderItems()
end

function Dropdown:SetSelected(value)
    self.SelectedValue = value

    -- Update header text
    for _, item in ipairs(self.Items) do
        local itemValue = type(item) == "table" and item.Value or item
        local displayText = type(item) == "table" and item.Display or tostring(item)

        if itemValue == value then
            self.HeaderButton.Text = "  " .. displayText
            break
        end
    end

    self:RenderItems()
end

function Dropdown:GetSelected()
    return self.SelectedValue
end

function Dropdown:Open()
    if self.IsOpen then return end
    self.IsOpen = true

    self.DropdownPanel.Visible = true
    self.ArrowIcon.Text = "▲"

    -- Calculate height (max 200px)
    local contentHeight = math.min(#self.ItemButtons * 34 + 50, 200)

    CreateTween(self.DropdownPanel, {Size = UDim2.new(1, 0, 0, contentHeight)})
    CreateTween(self.Container, {Size = UDim2.new(1, 0, 0, 70 + contentHeight + 6)})
end

function Dropdown:Close()
    if not self.IsOpen then return end
    self.IsOpen = false

    self.ArrowIcon.Text = "▼"
    self.SearchBox.Text = ""

    CreateTween(self.DropdownPanel, {Size = UDim2.new(1, 0, 0, 0)})
    CreateTween(self.Container, {Size = UDim2.new(1, 0, 0, 70)})

    task.wait(0.2)
    self.DropdownPanel.Visible = false
end

function Dropdown:Toggle()
    if self.IsOpen then
        self:Close()
    else
        self:Open()
    end
end

function Dropdown:Destroy()
    self.Container:Destroy()
end

-- ============================================================================
-- SEGMENTED CONTROL COMPONENT (Sliding Selector)
-- ============================================================================

local SegmentedControl = {}
SegmentedControl.__index = SegmentedControl

function SegmentedControl:new(parent, config, theme)
    local self = setmetatable({}, SegmentedControl)
    theme = theme or DefaultTheme

    self.Options = config.Options or {"Off", "On"}
    self.SelectedIndex = config.Default or 1
    self.Callback = config.Callback or function() end
    self.OptionButtons = {}

    -- Container
    self.Container = Instance.new("Frame")
    self.Container.Name = "SegmentedControlContainer"
    self.Container.Size = UDim2.new(1, 0, 0, 65)
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
    self.Label.Text = config.Text or "Toggle"
    self.Label.Parent = self.Container

    -- Control Container (holds all segments)
    self.ControlFrame = Instance.new("Frame")
    self.ControlFrame.Name = "ControlFrame"
    self.ControlFrame.Size = UDim2.new(1, 0, 0, 38)
    self.ControlFrame.Position = UDim2.new(0, 0, 0, 24)
    self.ControlFrame.BackgroundColor3 = theme.Slider
    self.ControlFrame.BackgroundTransparency = theme.ButtonTransparency
    self.ControlFrame.BorderSizePixel = 0
    self.ControlFrame.Parent = self.Container

    local controlCorner = Instance.new("UICorner")
    controlCorner.CornerRadius = theme.CornerRadius
    controlCorner.Parent = self.ControlFrame

    -- Sliding Selector (animated background)
    local segmentWidth = 1 / #self.Options
    self.Selector = Instance.new("Frame")
    self.Selector.Name = "Selector"
    self.Selector.Size = UDim2.new(segmentWidth, -4, 1, -4)
    self.Selector.Position = UDim2.new((self.SelectedIndex - 1) * segmentWidth, 2, 0, 2)
    self.Selector.BackgroundColor3 = theme.Accent
    self.Selector.BorderSizePixel = 0
    self.Selector.ZIndex = 1
    self.Selector.Parent = self.ControlFrame

    local selectorCorner = Instance.new("UICorner")
    selectorCorner.CornerRadius = UDim.new(0, 6)
    selectorCorner.Parent = self.Selector

    -- Store theme for later use
    self.Theme = theme
    self.SegmentWidth = segmentWidth

    -- Create option buttons
    for i, optionText in ipairs(self.Options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Name = "Option_" .. i
        optionButton.Size = UDim2.new(segmentWidth, 0, 1, 0)
        optionButton.Position = UDim2.new((i - 1) * segmentWidth, 0, 0, 0)
        optionButton.BackgroundTransparency = 1
        optionButton.BorderSizePixel = 0
        optionButton.Font = Enum.Font.GothamSemibold
        optionButton.TextSize = 14
        optionButton.TextColor3 = i == self.SelectedIndex and Color3.fromRGB(255, 255, 255) or theme.TextDim
        optionButton.Text = optionText
        optionButton.AutoButtonColor = false
        optionButton.ZIndex = 2
        optionButton.Parent = self.ControlFrame

        -- Click handler
        optionButton.MouseButton1Click:Connect(function()
            self:SetSelected(i)
        end)

        -- Hover effects (subtle)
        optionButton.MouseEnter:Connect(function()
            if i ~= self.SelectedIndex then
                CreateTween(optionButton, {TextColor3 = theme.Text}, 0.15)
            end
        end)

        optionButton.MouseLeave:Connect(function()
            if i ~= self.SelectedIndex then
                CreateTween(optionButton, {TextColor3 = theme.TextDim}, 0.15)
            end
        end)

        table.insert(self.OptionButtons, optionButton)
    end

    return self
end

function SegmentedControl:SetSelected(index)
    if index == self.SelectedIndex or index < 1 or index > #self.Options then
        return
    end

    local oldIndex = self.SelectedIndex
    self.SelectedIndex = index

    -- Animate selector sliding to new position
    local newPosition = UDim2.new((index - 1) * self.SegmentWidth, 2, 0, 2)
    CreateTween(self.Selector, {Position = newPosition}, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    -- Update text colors
    CreateTween(self.OptionButtons[oldIndex], {TextColor3 = self.Theme.TextDim}, 0.2)
    CreateTween(self.OptionButtons[index], {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)

    -- Fire callback with selected value
    self.Callback(self.Options[index], index)
end

function SegmentedControl:GetSelected()
    return self.Options[self.SelectedIndex], self.SelectedIndex
end

function SegmentedControl:GetSelectedIndex()
    return self.SelectedIndex
end

function SegmentedControl:GetSelectedValue()
    return self.Options[self.SelectedIndex]
end

function SegmentedControl:Destroy()
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
    self.Container.BackgroundTransparency = theme.SectionTransparency
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
    self.TitleBar.BackgroundTransparency = theme.TitleBarTransparency
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

function Section:AddDropdown(config)
    local dropdown = Dropdown:new(self.Content, config)
    table.insert(self.Components, dropdown)
    return dropdown
end

function Section:AddSegmentedControl(config)
    local segmented = SegmentedControl:new(self.Content, config)
    table.insert(self.Components, segmented)
    return segmented
end

function Section:Destroy()
    self.Container:Destroy()
end

-- ============================================================================
-- PAGE COMPONENT (Container for sections within a window)
-- ============================================================================

local Page = {}
Page.__index = Page

function Page:new(parent, config, theme)
    local self = setmetatable({}, Page)
    theme = theme or DefaultTheme
    self.Theme = theme

    self.Title = config.Title or "Page"
    self.Components = {}

    -- Page Container (ScrollingFrame)
    self.Container = Instance.new("ScrollingFrame")
    self.Container.Name = "Page_" .. self.Title
    self.Container.Size = UDim2.new(1, 0, 1, 0)
    self.Container.Position = UDim2.new(0, 0, 0, 0)
    self.Container.BackgroundTransparency = 1
    self.Container.BorderSizePixel = 0
    self.Container.ScrollBarThickness = 4
    self.Container.ScrollBarImageColor3 = theme.Accent
    self.Container.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.Container.Visible = false
    self.Container.Parent = parent

    -- Layout
    self.Layout = Instance.new("UIListLayout")
    self.Layout.SortOrder = Enum.SortOrder.LayoutOrder
    self.Layout.Padding = UDim.new(0, theme.Spacing)
    self.Layout.Parent = self.Container

    -- Auto-resize canvas
    self.Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.Container.CanvasSize = UDim2.new(0, 0, 0, self.Layout.AbsoluteContentSize.Y)
    end)

    return self
end

function Page:AddSection(config)
    local section = Section:new(self.Container, config, self.Theme)
    table.insert(self.Components, section)
    return section
end

function Page:AddLabel(config)
    local label = Label:new(self.Container, config, self.Theme)
    table.insert(self.Components, label)
    return label
end

function Page:AddTextBox(config)
    local textbox = TextBox:new(self.Container, config, self.Theme)
    table.insert(self.Components, textbox)
    return textbox
end

function Page:AddButton(config)
    local button = Button:new(self.Container, config, self.Theme)
    table.insert(self.Components, button)
    return button
end

function Page:AddSlider(config)
    local slider = Slider:new(self.Container, config, self.Theme)
    table.insert(self.Components, slider)
    return slider
end

function Page:AddDropdown(config)
    local dropdown = Dropdown:new(self.Container, config, self.Theme)
    table.insert(self.Components, dropdown)
    return dropdown
end

function Page:AddSegmentedControl(config)
    local segmented = SegmentedControl:new(self.Container, config, self.Theme)
    table.insert(self.Components, segmented)
    return segmented
end

function Page:Show()
    self.Container.Visible = true
end

function Page:Hide()
    self.Container.Visible = false
end

function Page:Destroy()
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
    self.Pages = {}
    self.CurrentPage = nil
    self.WindowTitle = config.Title or "UI Window"

    -- Main Frame
    self.Frame = Instance.new("Frame")
    self.Frame.Name = "Window"
    self.Frame.Size = config.Size or UDim2.new(0, 400, 0, 500)
    self.Frame.Position = config.Position or UDim2.new(0.5, -200, 0.5, -250)
    self.Frame.BackgroundColor3 = theme.Background
    self.Frame.BackgroundTransparency = theme.BackgroundTransparency
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
    self.TitleBar.BackgroundTransparency = theme.TitleBarTransparency
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.Parent = self.Frame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = theme.CornerRadius
    titleCorner.Parent = self.TitleBar

    -- Title Text (now clickable for page selection)
    self.TitleButton = Instance.new("TextButton")
    self.TitleButton.Name = "TitleButton"
    self.TitleButton.Size = UDim2.new(1, -20, 1, 0)
    self.TitleButton.Position = UDim2.new(0, 10, 0, 0)
    self.TitleButton.BackgroundTransparency = 1
    self.TitleButton.Font = Enum.Font.GothamBold
    self.TitleButton.TextSize = 16
    self.TitleButton.TextColor3 = theme.Text
    self.TitleButton.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleButton.Text = self.WindowTitle
    self.TitleButton.AutoButtonColor = false
    self.TitleButton.Parent = self.TitleBar

    -- Page Container (holds all pages)
    self.PageContainer = Instance.new("Frame")
    self.PageContainer.Name = "PageContainer"
    self.PageContainer.Size = UDim2.new(1, -theme.Padding * 2, 1, -50 - theme.Padding)
    self.PageContainer.Position = UDim2.new(0, theme.Padding, 0, 45)
    self.PageContainer.BackgroundTransparency = 1
    self.PageContainer.Parent = self.Frame

    -- Page Selector Dropdown (hidden initially)
    self.PageSelectorVisible = false
    self.PageSelectorPanel = Instance.new("Frame")
    self.PageSelectorPanel.Name = "PageSelector"
    self.PageSelectorPanel.Size = UDim2.new(0, 200, 0, 0)
    self.PageSelectorPanel.Position = UDim2.new(0, 10, 1, 5)
    self.PageSelectorPanel.BackgroundColor3 = theme.Section
    self.PageSelectorPanel.BackgroundTransparency = theme.SectionTransparency
    self.PageSelectorPanel.BorderSizePixel = 0
    self.PageSelectorPanel.ClipsDescendants = true
    self.PageSelectorPanel.Visible = false
    self.PageSelectorPanel.ZIndex = 10
    self.PageSelectorPanel.Parent = self.TitleBar

    local selectorCorner = Instance.new("UICorner")
    selectorCorner.CornerRadius = theme.CornerRadius
    selectorCorner.Parent = self.PageSelectorPanel

    self.PageSelectorList = Instance.new("ScrollingFrame")
    self.PageSelectorList.Name = "List"
    self.PageSelectorList.Size = UDim2.new(1, -8, 1, -8)
    self.PageSelectorList.Position = UDim2.new(0, 4, 0, 4)
    self.PageSelectorList.BackgroundTransparency = 1
    self.PageSelectorList.BorderSizePixel = 0
    self.PageSelectorList.ScrollBarThickness = 4
    self.PageSelectorList.ScrollBarImageColor3 = theme.Accent
    self.PageSelectorList.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.PageSelectorList.Parent = self.PageSelectorPanel

    local selectorLayout = Instance.new("UIListLayout")
    selectorLayout.SortOrder = Enum.SortOrder.LayoutOrder
    selectorLayout.Padding = UDim.new(0, 2)
    selectorLayout.Parent = self.PageSelectorList

    selectorLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.PageSelectorList.CanvasSize = UDim2.new(0, 0, 0, selectorLayout.AbsoluteContentSize.Y)
    end)

    -- Title Button Click (Toggle page selector)
    self.TitleButton.MouseButton1Click:Connect(function()
        if #self.Pages > 1 then
            self:TogglePageSelector()
        end
    end)

    -- Make draggable (only on the non-clickable part)
    MakeDraggable(self.Frame, self.TitleBar)

    return self
end

function Window:AddPage(config)
    local page = Page:new(self.PageContainer, config, self.Theme)
    table.insert(self.Pages, page)

    -- If this is the first page, show it
    if #self.Pages == 1 then
        self.CurrentPage = page
        page:Show()
        self:UpdateTitle()
    end

    -- Update page selector
    self:UpdatePageSelector()

    return page
end

function Window:SwitchPage(page)
    if self.CurrentPage == page then return end

    -- Hide current page
    if self.CurrentPage then
        self.CurrentPage:Hide()
    end

    -- Show new page
    self.CurrentPage = page
    page:Show()

    -- Update title
    self:UpdateTitle()

    -- Close selector
    if self.PageSelectorVisible then
        self:TogglePageSelector()
    end
end

function Window:UpdateTitle()
    if self.CurrentPage and #self.Pages > 1 then
        self.TitleButton.Text = self.WindowTitle .. " - " .. self.CurrentPage.Title .. " ▼"
    elseif self.CurrentPage then
        self.TitleButton.Text = self.WindowTitle .. " - " .. self.CurrentPage.Title
    else
        self.TitleButton.Text = self.WindowTitle
    end
end

function Window:UpdatePageSelector()
    -- Clear existing buttons
    for _, child in ipairs(self.PageSelectorList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- Create button for each page
    for _, page in ipairs(self.Pages) do
        local pageButton = Instance.new("TextButton")
        pageButton.Name = "PageBtn_" .. page.Title
        pageButton.Size = UDim2.new(1, 0, 0, 32)
        pageButton.BackgroundColor3 = self.Theme.Button
        pageButton.BackgroundTransparency = page == self.CurrentPage and 0.05 or self.Theme.ButtonTransparency
        pageButton.BorderSizePixel = 0
        pageButton.Font = Enum.Font.Gotham
        pageButton.TextSize = 14
        pageButton.TextColor3 = self.Theme.Text
        pageButton.TextXAlignment = Enum.TextXAlignment.Left
        pageButton.Text = "  " .. page.Title
        pageButton.AutoButtonColor = false
        pageButton.Parent = self.PageSelectorList

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = pageButton

        -- Hover effects
        pageButton.MouseEnter:Connect(function()
            CreateTween(pageButton, {BackgroundColor3 = self.Theme.ButtonHover, BackgroundTransparency = 0}, 0.15)
        end)

        pageButton.MouseLeave:Connect(function()
            local targetTransparency = page == self.CurrentPage and 0.05 or self.Theme.ButtonTransparency
            CreateTween(pageButton, {BackgroundColor3 = self.Theme.Button, BackgroundTransparency = targetTransparency}, 0.15)
        end)

        -- Click to switch page
        pageButton.MouseButton1Click:Connect(function()
            self:SwitchPage(page)
            self:UpdatePageSelector()
        end)
    end
end

function Window:TogglePageSelector()
    self.PageSelectorVisible = not self.PageSelectorVisible

    if self.PageSelectorVisible then
        self.PageSelectorPanel.Visible = true
        local height = math.min(#self.Pages * 34, 200)
        CreateTween(self.PageSelectorPanel, {Size = UDim2.new(0, 200, 0, height)})
    else
        CreateTween(self.PageSelectorPanel, {Size = UDim2.new(0, 200, 0, 0)})
        task.wait(0.2)
        self.PageSelectorPanel.Visible = false
    end
end

-- Backward compatibility: these methods auto-create a default page
function Window:AddSection(config)
    if #self.Pages == 0 then
        self:AddPage({Title = "Main"})
    end
    return self.CurrentPage:AddSection(config)
end

function Window:AddLabel(config)
    if #self.Pages == 0 then
        self:AddPage({Title = "Main"})
    end
    return self.CurrentPage:AddLabel(config)
end

function Window:AddTextBox(config)
    if #self.Pages == 0 then
        self:AddPage({Title = "Main"})
    end
    return self.CurrentPage:AddTextBox(config)
end

function Window:AddButton(config)
    if #self.Pages == 0 then
        self:AddPage({Title = "Main"})
    end
    return self.CurrentPage:AddButton(config)
end

function Window:AddSlider(config)
    if #self.Pages == 0 then
        self:AddPage({Title = "Main"})
    end
    return self.CurrentPage:AddSlider(config)
end

function Window:AddDropdown(config)
    if #self.Pages == 0 then
        self:AddPage({Title = "Main"})
    end
    return self.CurrentPage:AddDropdown(config)
end

function Window:AddSegmentedControl(config)
    if #self.Pages == 0 then
        self:AddPage({Title = "Main"})
    end
    return self.CurrentPage:AddSegmentedControl(config)
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
