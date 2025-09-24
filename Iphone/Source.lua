--!/usr/bin/env lua
-- iOSNotifFinalSource.lua (Version 5.2 - User-Specified Apple Logo)
-- This version sets the user-provided Apple logo ID as the default icon.
-- v0.8

local module = {}

-- Services
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- --- Theme Configuration ---
local themes = {
    Light = { Background = Color3.fromRGB(240, 240, 240), Transparency = 0.25, PrimaryText = Color3.fromRGB(15, 15, 15), SecondaryText = Color3.fromRGB(120, 120, 120) },
    Dark = { Background = Color3.fromRGB(40, 40, 40), Transparency = 0.3, PrimaryText = Color3.fromRGB(240, 240, 240), SecondaryText = Color3.fromRGB(160, 160, 160) },
    Success = { Background = Color3.fromRGB(60, 110, 75), Transparency = 0.2, PrimaryText = Color3.fromRGB(230, 255, 235), SecondaryText = Color3.fromRGB(180, 220, 190) },
    Warning = { Background = Color3.fromRGB(120, 100, 50), Transparency = 0.2, PrimaryText = Color3.fromRGB(255, 245, 220), SecondaryText = Color3.fromRGB(220, 200, 160) },
    Error = { Background = Color3.fromRGB(120, 55, 55), Transparency = 0.2, PrimaryText = Color3.fromRGB(255, 230, 230), SecondaryText = Color3.fromRGB(220, 180, 180) },
    Info = { Background = Color3.fromRGB(50, 90, 120), Transparency = 0.2, PrimaryText = Color3.fromRGB(220, 235, 255), SecondaryText = Color3.fromRGB(160, 190, 220) }
}

-- --- UI & Script Configuration ---
local NOTIFICATION_WIDTH = 350; local BASE_HEIGHT = 65; local PADDING = 12; local ICON_SIZE = 24; local SPACING = 10; local TOP_PADDING = 20; local FONT = Enum.Font.SourceSans; local FONT_BOLD = Enum.Font.SourceSansBold; local DEFAULT_DURATION = 7; local SWIPE_THRESHOLD = 0.3

-- --- UI Template Creation (Done Once) ---
local NotifGui = CoreGui:FindFirstChild("iOSNotifGui")
if NotifGui then NotifGui:Destroy() end
NotifGui = Instance.new("ScreenGui"); NotifGui.Name = "iOSNotifGui"; NotifGui.ResetOnSpawn = false; NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; NotifGui.Parent = CoreGui
local NotificationTemplate = Instance.new("Frame"); NotificationTemplate.Name = "NotificationTemplate"; NotificationTemplate.Visible = false; NotificationTemplate.Size = UDim2.new(0, NOTIFICATION_WIDTH, 0, BASE_HEIGHT); NotificationTemplate.AnchorPoint = Vector2.new(0.5, 0); NotificationTemplate.Position = UDim2.new(0.5, 0, 0, -BASE_HEIGHT - 20); NotificationTemplate.Parent = NotifGui
local UICorner = Instance.new("UICorner"); UICorner.CornerRadius = UDim.new(0, 24); UICorner.Parent = NotificationTemplate
local AppIcon = Instance.new("ImageLabel"); AppIcon.Name = "AppIcon"; AppIcon.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE); AppIcon.Position = UDim2.new(0, PADDING, 0, PADDING); AppIcon.BackgroundTransparency = 1; AppIcon.Image = "rbxassetid://526339621"; AppIcon.Parent = NotificationTemplate -- <-- YOUR SPECIFIC APPLE LOGO ID
local AppIconCorner = Instance.new("UICorner"); AppIconCorner.CornerRadius = UDim.new(0, 6); AppIconCorner.Parent = AppIcon
local TitleLabel = Instance.new("TextLabel"); TitleLabel.Name = "TitleLabel"; TitleLabel.Font = FONT_BOLD; TitleLabel.TextXAlignment = Enum.TextXAlignment.Left; TitleLabel.TextYAlignment = Enum.TextYAlignment.Top; TitleLabel.TextSize = 15; TitleLabel.BackgroundTransparency = 1; TitleLabel.Position = UDim2.new(0, PADDING + ICON_SIZE + 8, 0, PADDING); TitleLabel.Size = UDim2.new(1, -(PADDING*3 + ICON_SIZE + 40), 0, 18); TitleLabel.Parent = NotificationTemplate
local TimestampLabel = Instance.new("TextLabel"); TimestampLabel.Name = "TimestampLabel"; TimestampLabel.Font = FONT; TimestampLabel.TextXAlignment = Enum.TextXAlignment.Right; TimestampLabel.TextYAlignment = Enum.TextYAlignment.Top; TimestampLabel.TextSize = 14; TimestampLabel.BackgroundTransparency = 1; TimestampLabel.Position = UDim2.new(1, -PADDING - 40, 0, PADDING); TimestampLabel.Size = UDim2.new(0, 40, 0, 18); TimestampLabel.Parent = NotificationTemplate
local DescriptionLabel = Instance.new("TextLabel"); DescriptionLabel.Name = "DescriptionLabel"; DescriptionLabel.Font = FONT; DescriptionLabel.TextXAlignment = Enum.TextXAlignment.Left; DescriptionLabel.TextYAlignment = Enum.TextYAlignment.Top; DescriptionLabel.TextWrapped = true; DescriptionLabel.TextSize = 15; DescriptionLabel.BackgroundTransparency = 1; DescriptionLabel.Position = UDim2.new(0, PADDING, 0, PADDING + 18); DescriptionLabel.Size = UDim2.new(1, -PADDING * 2, 0, 0); DescriptionLabel.Parent = NotificationTemplate

-- --- Logic ---
local activeNotifications = {}

local function calculateTextHeight(text)
    local sizeVector = TextService:GetTextSize(text, DescriptionLabel.TextSize, DescriptionLabel.Font, Vector2.new(NOTIFICATION_WIDTH - PADDING*2, 1000))
    return sizeVector.Y
end

local function repositionAll()
    local currentY = TOP_PADDING
    for _, notifFrame in ipairs(activeNotifications) do
        local tween = TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(notifFrame.Position.X.Scale, notifFrame.Position.X.Offset, 0, currentY) })
        tween:Play()
        currentY = currentY + notifFrame.AbsoluteSize.Y + SPACING
    end
end

local function dismissNotification(notifFrame, swipeDirection)
    if not notifFrame or notifFrame:GetAttribute("IsDismissing") then return end
    notifFrame:SetAttribute("IsDismissing", true)

    for i, v in ipairs(activeNotifications) do if v == notifFrame then table.remove(activeNotifications, i); break end end
    repositionAll()
    
    local exitPosition = swipeDirection and UDim2.new(0.5 + (0.6 * swipeDirection), 0, notifFrame.Position.Y.Scale, notifFrame.Position.Y.Offset) or UDim2.new(0.5, 0, 0, -notifFrame.AbsoluteSize.Y)
    local slideOut = TweenService:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Position = exitPosition })
    slideOut:Play()
    slideOut.Completed:Wait()
    notifFrame:Destroy()
end

function module.Notify(data)
    if typeof(data) ~= "table" then warn("iOSNotif Error: Notify data must be a table."); return end

    local newNotif = NotificationTemplate:Clone()
    
    local themeName = data.Theme or "Light"; local selectedTheme = themes[themeName] or themes.Light
    newNotif.BackgroundColor3 = selectedTheme.Background; newNotif.BackgroundTransparency = selectedTheme.Transparency
    newNotif.TitleLabel.TextColor3 = selectedTheme.PrimaryText; newNotif.DescriptionLabel.TextColor3 = selectedTheme.PrimaryText; newNotif.TimestampLabel.TextColor3 = selectedTheme.SecondaryText

    newNotif.TitleLabel.Text = data.Title or "Notification"
    newNotif.DescriptionLabel.Text = data.Description or ""
    newNotif.AppIcon.Image = data.Icon or newNotif.AppIcon.Image
    newNotif.TimestampLabel.Text = data.Timestamp or "now"
    local duration = data.Duration or DEFAULT_DURATION

    local descriptionHeight = calculateTextHeight(newNotif.DescriptionLabel.Text)
    local totalHeight = PADDING + 18 + descriptionHeight + PADDING
    if totalHeight < BASE_HEIGHT then totalHeight = BASE_HEIGHT end
    newNotif.DescriptionLabel.Size = UDim2.new(1, -PADDING*2, 0, descriptionHeight)
    newNotif.Size = UDim2.new(0, NOTIFICATION_WIDTH, 0, totalHeight)
    newNotif.Position = UDim2.new(0.5, 0, 0, -totalHeight)
    newNotif.Parent = NotifGui; newNotif.Visible = true

    table.insert(activeNotifications, 1, newNotif)
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
end

return module
