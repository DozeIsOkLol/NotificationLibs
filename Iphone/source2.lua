--!/usr/bin/env lua
-- iOSNotifInteractiveSource.lua
-- This version supports stacking, timers, AND swipe-to-dismiss gestures.

--- v0.2

local module = {}

-- Services
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- --- Configuration ---
local NOTIFICATION_WIDTH = 350
local BASE_HEIGHT = 65
local PADDING = 12
local ICON_SIZE = 24
local SPACING = 10
local TOP_PADDING = 20
local FONT = Enum.Font.SourceSans
local FONT_BOLD = Enum.Font.SourceSansBold
local DEFAULT_DURATION = 7
local SWIPE_THRESHOLD = 0.3 -- Must swipe 30% of the width to dismiss

-- --- UI Template Creation (Done Once) ---
local NotifGui = CoreGui:FindFirstChild("iOSNotifGui")
if NotifGui then NotifGui:Destroy() end

NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "iOSNotifGui"
NotifGui.ResetOnSpawn = false
NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
NotifGui.Parent = CoreGui

-- Template to be cloned for each notification
local NotificationTemplate = Instance.new("Frame")
NotificationTemplate.Name = "NotificationTemplate"
NotificationTemplate.Visible = false
NotificationTemplate.Size = UDim2.new(0, NOTIFICATION_WIDTH, 0, BASE_HEIGHT)
NotificationTemplate.AnchorPoint = Vector2.new(0.5, 0)
NotificationTemplate.Position = UDim2.new(0.5, 0, 0, -BASE_HEIGHT - 20)
NotificationTemplate.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
NotificationTemplate.BackgroundTransparency = 0.25
NotificationTemplate.Parent = NotifGui
-- The rest of the template UI...
local UICorner = Instance.new("UICorner"); UICorner.CornerRadius = UDim.new(0, 24); UICorner.Parent = NotificationTemplate
local AppIcon = Instance.new("ImageLabel"); AppIcon.Name = "AppIcon"; AppIcon.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE); AppIcon.Position = UDim2.new(0, PADDING, 0, PADDING); AppIcon.BackgroundTransparency = 1; AppIcon.Image = "rbxassetid://6031999801"; AppIcon.Parent = NotificationTemplate
local AppIconCorner = Instance.new("UICorner"); AppIconCorner.CornerRadius = UDim.new(0, 6); AppIconCorner.Parent = AppIcon
local TitleLabel = Instance.new("TextLabel"); TitleLabel.Name = "TitleLabel"; TitleLabel.Font = FONT_BOLD; TitleLabel.TextColor3 = Color3.fromRGB(15, 15, 15); TitleLabel.TextXAlignment = Enum.TextXAlignment.Left; TitleLabel.TextYAlignment = Enum.TextYAlignment.Top; TitleLabel.TextSize = 15; TitleLabel.BackgroundTransparency = 1; TitleLabel.Position = UDim2.new(0, PADDING + ICON_SIZE + 8, 0, PADDING); TitleLabel.Size = UDim2.new(1, -(PADDING*3 + ICON_SIZE + 40), 0, 18); TitleLabel.Parent = NotificationTemplate
local TimestampLabel = Instance.new("TextLabel"); TimestampLabel.Name = "TimestampLabel"; TimestampLabel.Font = FONT; TimestampLabel.TextColor3 = Color3.fromRGB(120, 120, 120); TimestampLabel.TextXAlignment = Enum.TextXAlignment.Right; TimestampLabel.TextYAlignment = Enum.TextYAlignment.Top; TimestampLabel.TextSize = 14; TimestampLabel.BackgroundTransparency = 1; TimestampLabel.Position = UDim2.new(1, -PADDING - 40, 0, PADDING); TimestampLabel.Size = UDim2.new(0, 40, 0, 18); TimestampLabel.Parent = NotificationTemplate
local DescriptionLabel = Instance.new("TextLabel"); DescriptionLabel.Name = "DescriptionLabel"; DescriptionLabel.Font = FONT; DescriptionLabel.TextColor3 = Color3.fromRGB(15, 15, 15); DescriptionLabel.TextXAlignment = Enum.TextXAlignment.Left; DescriptionLabel.TextYAlignment = Enum.TextYAlignment.Top; DescriptionLabel.TextWrapped = true; DescriptionLabel.TextSize = 15; DescriptionLabel.BackgroundTransparency = 1; DescriptionLabel.Position = UDim2.new(0, PADDING, 0, PADDING + 18); DescriptionLabel.Size = UDim2.new(1, -PADDING * 2, 0, 0); DescriptionLabel.Parent = NotificationTemplate

-- --- Logic ---
local activeNotifications = {}

local function calculateTextHeight(text)
    local sizeVector = TextService:GetTextSize(text, DescriptionLabel.TextSize, DescriptionLabel.Font, Vector2.new(NOTIFICATION_WIDTH - PADDING*2, 1000))
    return sizeVector.Y
end

local function repositionAll()
    local currentY = TOP_PADDING
    for _, notifFrame in ipairs(activeNotifications) do
        local tween = TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(notifFrame.Position.X.Scale, notifFrame.Position.X.Offset, 0, currentY)
        })
        tween:Play()
        currentY = currentY + notifFrame.AbsoluteSize.Y + SPACING
    end
end

-- Universal function to dismiss a notification, whether by timer or swipe
local function dismissNotification(notifFrame, swipeDirection)
    if not notifFrame or notifFrame:GetAttribute("IsDismissing") then return end
    notifFrame:SetAttribute("IsDismissing", true)

    -- Remove from the active list
    for i, v in ipairs(activeNotifications) do
        if v == notifFrame then
            table.remove(activeNotifications, i)
            break
        end
    end
    
    repositionAll()
    
    local exitPosition
    if swipeDirection then -- Swiped off screen
        exitPosition = UDim2.new(0.5 + (0.6 * swipeDirection), 0, notifFrame.Position.Y.Scale, notifFrame.Position.Y.Offset)
    else -- Timed out
         exitPosition = UDim2.new(0.5, 0, 0, -notifFrame.AbsoluteSize.Y)
    end

    local slideOut = TweenService:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Position = exitPosition })
    slideOut:Play()
    slideOut.Completed:Wait()
    notifFrame:Destroy()
end

function module.Notify(data)
    if typeof(data) ~= "table" then
        warn("iOSNotif Error: Notify data must be a table.")
        return
    end

    local newNotif = NotificationTemplate:Clone()
    -- Populate content...
    newNotif.TitleLabel.Text = data.Title or "Notification"
    newNotif.DescriptionLabel.Text = data.Description or ""
    newNotif.AppIcon.Image = data.Icon or "rbxassetid://6031999801"
    newNotif.TimestampLabel.Text = "now"
    local duration = data.Duration or DEFAULT_DURATION

    -- Calculate dynamic height
    local descriptionHeight = calculateTextHeight(newNotif.DescriptionLabel.Text)
    local totalHeight = PADDING + 18 + descriptionHeight + PADDING
    if totalHeight < BASE_HEIGHT then totalHeight = BASE_HEIGHT end
    newNotif.DescriptionLabel.Size = UDim2.new(1, -PADDING*2, 0, descriptionHeight)
    newNotif.Size = UDim2.new(0, NOTIFICATION_WIDTH, 0, totalHeight)
    newNotif.Position = UDim2.new(0.5, 0, 0, -totalHeight)
    newNotif.Parent = NotifGui
    newNotif.Visible = true

    -- Add to the top of the active notifications list
    table.insert(activeNotifications, 1, newNotif)
    repositionAll()

    -- Handle swipe input
    local inputBeganConn, inputChangedConn, inputEndedConn
    local isSwiping = false
    local startX, startPos

    inputBeganConn = newNotif.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSwiping = true
            startX = input.Position.X
            startPos = newNotif.Position.X.Offset
            
            inputChangedConn = input.Changed:Connect(function()
                if isSwiping then
                    local deltaX = input.Position.X - startX
                    newNotif.Position = UDim2.new(0.5, startPos + deltaX, newNotif.Position.Y.Scale, newNotif.Position.Y.Offset)
                end
            end)
            
            inputEndedConn = UserInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == input.UserInputType then
                    isSwiping = false
                    if inputChangedConn then inputChangedConn:Disconnect() end
                    if inputEndedConn then inputEndedConn:Disconnect() end

                    local deltaX = endInput.Position.X - startX
                    local swipePercent = math.abs(deltaX) / newNotif.AbsoluteSize.X
                    
                    if swipePercent > SWIPE_THRESHOLD then
                        dismissNotification(newNotif, math.sign(deltaX))
                    else
                        -- Not a full swipe, tween back to center
                        TweenService:Create(newNotif, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Position = UDim2.new(0.5, 0, newNotif.Position.Y.Scale, newNotif.Position.Y.Offset)
                        }):Play()
                    end
                end
            end)
        end
    end)
    
    -- Handle the timer in its own thread
    coroutine.wrap(function()
        wait(duration)
        -- The timer can only dismiss if it hasn't already been swiped
        if not newNotif:GetAttribute("IsDismissing") then
            dismissNotification(newNotif, nil)
        end
        if inputBeganConn then inputBeganConn:Disconnect() end -- cleanup
    end)()
end

return module
