--!/usr/bin/env lua
-- iOSNotifProSource.lua (Version 7.0 - Global Config & Programmatic Control)
-- This version adds SetConfig, Update(id), and Dismiss(id) for advanced control.

local module = {}

-- Services
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- --- Configuration ---
local themes = {
    Light = { Background = Color3.fromRGB(240, 240, 240), Transparency = 0.25, PrimaryText = Color3.fromRGB(15, 15, 15), SecondaryText = Color3.fromRGB(120, 120, 120) },
    Dark = { Background = Color3.fromRGB(40, 40, 40), Transparency = 0.3, PrimaryText = Color3.fromRGB(240, 240, 240), SecondaryText = Color3.fromRGB(160, 160, 160) },
    Success = { Background = Color3.fromRGB(60, 110, 75), Transparency = 0.2, PrimaryText = Color3.fromRGB(230, 255, 235), SecondaryText = Color3.fromRGB(180, 220, 190) },
    Warning = { Background = Color3.fromRGB(120, 100, 50), Transparency = 0.2, PrimaryText = Color3.fromRGB(255, 245, 220), SecondaryText = Color3.fromRGB(220, 200, 160) },
    Error = { Background = Color3.fromRGB(120, 55, 55), Transparency = 0.2, PrimaryText = Color3.fromRGB(255, 230, 230), SecondaryText = Color3.fromRGB(220, 180, 180) },
    Info = { Background = Color3.fromRGB(50, 90, 120), Transparency = 0.2, PrimaryText = Color3.fromRGB(220, 235, 255), SecondaryText = Color3.fromRGB(160, 190, 220) }
}
local globalConfig = {} -- Stores default settings
local NOTIFICATION_WIDTH = 350; local BASE_HEIGHT = 65; local PADDING = 12; local SPACING = 10; local TOP_PADDING = 20; local FONT = Enum.Font.SourceSans; local FONT_BOLD = Enum.Font.SourceSansBold; local DEFAULT_DURATION = 7; local SWIPE_THRESHOLD = 0.3

-- --- UI Template Creation ---
local NotifGui = CoreGui:FindFirstChild("iOSNotifGui")
if NotifGui then NotifGui:Destroy() end
NotifGui = Instance.new("ScreenGui"); NotifGui.Name = "iOSNotifGui"; NotifGui.ResetOnSpawn = false; NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; NotifGui.Parent = CoreGui
local NotificationTemplate = Instance.new("Frame"); NotificationTemplate.Name = "NotificationTemplate"; NotificationTemplate.Visible = false; NotificationTemplate.Size = UDim2.new(0, NOTIFICATION_WIDTH, 0, BASE_HEIGHT); NotificationTemplate.AnchorPoint = Vector2.new(0.5, 0); NotificationTemplate.Position = UDim2.new(0.5, 0, 0, -BASE_HEIGHT - 20); NotificationTemplate.Parent = NotifGui
local UICorner = Instance.new("UICorner"); UICorner.CornerRadius = UDim.new(0, 24); UICorner.Parent = NotificationTemplate
local TitleLabel = Instance.new("TextLabel"); TitleLabel.Name = "TitleLabel"; TitleLabel.Font = FONT_BOLD; TitleLabel.TextXAlignment = Enum.TextXAlignment.Left; TitleLabel.TextYAlignment = Enum.TextYAlignment.Top; TitleLabel.TextSize = 15; TitleLabel.BackgroundTransparency = 1; TitleLabel.Position = UDim2.new(0, PADDING, 0, PADDING); TitleLabel.Size = UDim2.new(1, -(PADDING*2 + 40), 0, 18); TitleLabel.Parent = NotificationTemplate
local TimestampLabel = Instance.new("TextLabel"); TimestampLabel.Name = "TimestampLabel"; TimestampLabel.Font = FONT; TimestampLabel.TextXAlignment = Enum.TextXAlignment.Right; TimestampLabel.TextYAlignment = Enum.TextYAlignment.Top; TimestampLabel.TextSize = 14; TimestampLabel.BackgroundTransparency = 1; TimestampLabel.Position = UDim2.new(1, -PADDING - 40, 0, PADDING); TimestampLabel.Size = UDim2.new(0, 40, 0, 18); TimestampLabel.Parent = NotificationTemplate
local DescriptionLabel = Instance.new("TextLabel"); DescriptionLabel.Name = "DescriptionLabel"; DescriptionLabel.Font = FONT; DescriptionLabel.TextXAlignment = Enum.TextXAlignment.Left; DescriptionLabel.TextYAlignment = Enum.TextYAlignment.Top; DescriptionLabel.TextWrapped = true; DescriptionLabel.TextSize = 15; DescriptionLabel.BackgroundTransparency = 1; DescriptionLabel.Position = UDim2.new(0, PADDING, 0, PADDING + 18); DescriptionLabel.Size = UDim2.new(1, -PADDING * 2, 0, 0); DescriptionLabel.Parent = NotificationTemplate

-- --- Core Logic ---
local activeNotifications = {} -- Array for order
local idToFrameMap = {}      -- Dictionary for fast lookup
local nextNotifId = 1

local function calculateTextHeight(text)
    local sizeVector = TextService:GetTextSize(text, DescriptionLabel.TextSize, DescriptionLabel.Font, Vector2.new(NOTIFICATION_WIDTH - PADDING*2, 1000))
    return sizeVector.Y
end

local function repositionAll()
    local currentY = TOP_PADDING
    for _, notifFrame in ipairs(activeNotifications) do
        TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(notifFrame.Position.X.Scale, notifFrame.Position.X.Offset, 0, currentY) }):Play()
        currentY = currentY + notifFrame.AbsoluteSize.Y + SPACING
    end
end

local function dismissNotification(notifFrame, swipeDirection)
    if not notifFrame or notifFrame:GetAttribute("IsDismissing") then return end
    notifFrame:SetAttribute("IsDismissing", true)

    local id = notifFrame:GetAttribute("ID")
    if id then idToFrameMap[id] = nil end
    
    for i, v in ipairs(activeNotifications) do if v == notifFrame then table.remove(activeNotifications, i); break end end
    repositionAll()
    
    local exitPosition = swipeDirection and UDim2.new(0.5 + (0.6 * swipeDirection), 0, notifFrame.Position.Y.Scale, notifFrame.Position.Y.Offset) or UDim2.new(0.5, 0, 0, -notifFrame.AbsoluteSize.Y)
    local slideOut = TweenService:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Position = exitPosition })
    slideOut:Play()
    slideOut.Completed:Wait()
    notifFrame:Destroy()
end

--- The main Notify function, now part of the returned module
function module.Notify(data)
    if typeof(data) ~= "table" then warn("iOSNotif Error: Notify data must be a table."); return end

    local newNotif = NotificationTemplate:Clone()
    local notifId = nextNotifId; nextNotifId += 1
    newNotif:SetAttribute("ID", notifId)
    
    local themeName = data.Theme or globalConfig.Theme or "Light"
    local selectedTheme = themes[themeName] or themes.Light
    newNotif.BackgroundColor3 = selectedTheme.Background; newNotif.BackgroundTransparency = selectedTheme.Transparency
    newNotif.TitleLabel.TextColor3 = selectedTheme.PrimaryText; newNotif.DescriptionLabel.TextColor3 = selectedTheme.PrimaryText; newNotif.TimestampLabel.TextColor3 = selectedTheme.SecondaryText

    newNotif.TitleLabel.Text = data.Title or "Notification"
    newNotif.DescriptionLabel.Text = data.Description or ""
    newNotif.TimestampLabel.Text = data.Timestamp or globalConfig.Timestamp or "now"
    local duration = data.Duration or globalConfig.Duration or DEFAULT_DURATION

    local descriptionHeight = calculateTextHeight(newNotif.DescriptionLabel.Text)
    local totalHeight = PADDING + 18 + descriptionHeight + PADDING
    if totalHeight < BASE_HEIGHT then totalHeight = BASE_HEIGHT end
    newNotif.DescriptionLabel.Size = UDim2.new(1, -PADDING*2, 0, descriptionHeight)
    newNotif.Size = UDim2.new(0, NOTIFICATION_WIDTH, 0, totalHeight)
    newNotif.Position = UDim2.new(0.5, 0, 0, -totalHeight)
    newNotif.Parent = NotifGui; newNotif.Visible = true

    table.insert(activeNotifications, 1, newNotif)
    idToFrameMap[notifId] = newNotif
    repositionAll()

    local isDragging = false; local startX, startPos; local mouseMoveConn, mouseUpConn
    newNotif.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true; startX = UserInputService:GetMouseLocation().X; startPos = newNotif.Position.X.Offset
            mouseMoveConn = UserInputService.InputChanged:Connect(function(moveInput)
                if moveInput.UserInputType == Enum.UserInputType.MouseMovement and isDragging then
                    local deltaX = UserInputService:GetMouseLocation().X - startX
                    newNotif.Position = UDim2.new(0.5, startPos + deltaX, newNotif.Position.Y.Scale, newNotif.Position.Y.Offset)
                end
            end)
            mouseUpConn = UserInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1 then
                    isDragging = false; if mouseMoveConn then mouseMoveConn:Disconnect() end; if mouseUpConn then mouseUpConn:Disconnect() end
                    local totalDelta = UserInputService:GetMouseLocation().X - startX
                    if math.abs(totalDelta) / newNotif.AbsoluteSize.X > SWIPE_THRESHOLD then
                        dismissNotification(newNotif, math.sign(totalDelta))
                    else
                        TweenService:Create(newNotif, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, newNotif.Position.Y.Scale, newNotif.Position.Y.Offset) }):Play()
                    end
                end
            end)
        end
    end)
    
    coroutine.wrap(function()
        wait(duration)
        if not newNotif:GetAttribute("IsDismissing") then dismissNotification(newNotif, nil) end
    end)()
    
    return notifId
end

--- Sets the default configuration for subsequent notifications
function module.SetConfig(config)
    if typeof(config) == "table" then
        for key, value in pairs(config) do
            globalConfig[key] = value
        end
    else
        warn("iOSNotif Error: SetConfig data must be a table.")
    end
end

--- Updates a notification that is already on-screen
function module.Update(id, data)
    local notifFrame = idToFrameMap[id]
    if not notifFrame or typeof(data) ~= "table" then return end
    
    if data.Title then notifFrame.TitleLabel.Text = data.Title end
    if data.Description then notifFrame.DescriptionLabel.Text = data.Description end
    if data.Timestamp then notifFrame.TimestampLabel.Text = data.Timestamp end
    
    if data.Theme then
        local selectedTheme = themes[data.Theme] or themes.Light
        notifFrame.BackgroundColor3 = selectedTheme.Background; notifFrame.BackgroundTransparency = selectedTheme.Transparency
        notifFrame.TitleLabel.TextColor3 = selectedTheme.PrimaryText; notifFrame.DescriptionLabel.TextColor3 = selectedTheme.PrimaryText; notifFrame.TimestampLabel.TextColor3 = selectedTheme.SecondaryText
    end
    
    -- Recalculate height if description changed, and reposition everything
    if data.Description then
        local descriptionHeight = calculateTextHeight(notifFrame.DescriptionLabel.Text)
        local totalHeight = PADDING + 18 + descriptionHeight + PADDING
        if totalHeight < BASE_HEIGHT then totalHeight = BASE_HEIGHT end
        notifFrame.DescriptionLabel.Size = UDim2.new(1, -PADDING*2, 0, descriptionHeight)
        TweenService:Create(notifFrame, TweenInfo.new(0.3), { Size = UDim2.new(0, NOTIFICATION_WIDTH, 0, totalHeight) }):Play()
        repositionAll()
    end
end

--- Dismisses a specific notification
function module.Dismiss(id)
    local notifFrame = idToFrameMap[id]
    if notifFrame then
        dismissNotification(notifFrame, nil)
    end
end

return module
