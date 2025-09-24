--!/usr/bin/env lua
-- iOSNotifStackedSource.lua
-- This version supports multiple, stacked notifications.

local module = {}

-- Services
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- --- Configuration ---
local NOTIFICATION_WIDTH = 350
local BASE_HEIGHT = 65
local PADDING = 12
local ICON_SIZE = 24
local SPACING = 10 -- The vertical gap between notifications
local TOP_PADDING = 20 -- The space from the top of the screen
local FONT = Enum.Font.SourceSans
local FONT_BOLD = Enum.Font.SourceSansBold
local DEFAULT_DURATION = 5

-- --- UI Template Creation (Done Once) ---
local NotifGui = CoreGui:FindFirstChild("iOSNotifGui")
if NotifGui then NotifGui:Destroy() end

NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "iOSNotifGui"
NotifGui.ResetOnSpawn = false
NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
NotifGui.Parent = CoreGui

-- This frame is a template that we will clone for each notification
local NotificationTemplate = Instance.new("Frame")
NotificationTemplate.Name = "NotificationTemplate"
NotificationTemplate.Visible = false -- Keep the template hidden
NotificationTemplate.Size = UDim2.new(0, NOTIFICATION_WIDTH, 0, BASE_HEIGHT)
NotificationTemplate.AnchorPoint = Vector2.new(0.5, 0)
NotificationTemplate.Position = UDim2.new(0.5, 0, 0, -BASE_HEIGHT - 20)
NotificationTemplate.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
NotificationTemplate.BackgroundTransparency = 0.25
NotificationTemplate.Parent = NotifGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 24)
UICorner.Parent = NotificationTemplate

local AppIcon = Instance.new("ImageLabel")
AppIcon.Name = "AppIcon"
AppIcon.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
AppIcon.Position = UDim2.new(0, PADDING, 0, PADDING)
AppIcon.BackgroundTransparency = 1
AppIcon.Image = "rbxassetid://6031999801"
AppIcon.Parent = NotificationTemplate

local AppIconCorner = Instance.new("UICorner")
AppIconCorner.CornerRadius = UDim.new(0, 6)
AppIconCorner.Parent = AppIcon

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Font = FONT_BOLD
TitleLabel.TextColor3 = Color3.fromRGB(15, 15, 15)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextYAlignment = Enum.TextXAlignment.Top
TitleLabel.TextSize = 15
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, PADDING + ICON_SIZE + 8, 0, PADDING)
TitleLabel.Size = UDim2.new(1, -(PADDING*3 + ICON_SIZE + 40), 0, 18)
TitleLabel.Parent = NotificationTemplate

local TimestampLabel = Instance.new("TextLabel")
TimestampLabel.Name = "TimestampLabel"
TimestampLabel.Font = FONT
TimestampLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
TimestampLabel.TextXAlignment = Enum.TextXAlignment.Right
TimestampLabel.TextYAlignment = Enum.TextXAlignment.Top
TimestampLabel.TextSize = 14
TimestampLabel.BackgroundTransparency = 1
TimestampLabel.Position = UDim2.new(1, -PADDING - 40, 0, PADDING)
TimestampLabel.Size = UDim2.new(0, 40, 0, 18)
TimestampLabel.Parent = NotificationTemplate

local DescriptionLabel = Instance.new("TextLabel")
DescriptionLabel.Name = "DescriptionLabel"
DescriptionLabel.Font = FONT
DescriptionLabel.TextColor3 = Color3.fromRGB(15, 15, 15)
DescriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
DescriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
DescriptionLabel.TextWrapped = true
DescriptionLabel.TextSize = 15
DescriptionLabel.BackgroundTransparency = 1
DescriptionLabel.Position = UDim2.new(0, PADDING, 0, PADDING + 18)
DescriptionLabel.Size = UDim2.new(1, -PADDING * 2, 0, 0)
DescriptionLabel.Parent = NotificationTemplate

-- --- Logic ---
local activeNotifications = {}

local function calculateTextHeight(text)
    local descSize = DescriptionLabel.AbsoluteSize
    local sizeVector = TextService:GetTextSize(text, DescriptionLabel.TextSize, DescriptionLabel.Font, Vector2.new(NOTIFICATION_WIDTH - PADDING*2, 1000))
    return sizeVector.Y
end

-- This function repositions all notifications. Can be called when one is added or removed.
local function repositionAll()
    local currentY = TOP_PADDING
    for i, notifFrame in ipairs(activeNotifications) do
        local tween = TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0, currentY)
        })
        tween:Play()
        currentY = currentY + notifFrame.AbsoluteSize.Y + SPACING
    end
end

function module.Notify(data)
    if typeof(data) ~= "table" then
        warn("iOSNotif Error: Notify data must be a table.")
        return
    end

    -- Create a new notification by cloning the template
    local newNotif = NotificationTemplate:Clone()

    -- Populate the new notification with data
    newNotif.TitleLabel.Text = data.Title or "Notification"
    newNotif.DescriptionLabel.Text = data.Description or ""
    newNotif.AppIcon.Image = data.Icon or "rbxassetid://6031999801"
    newNotif.TimestampLabel.Text = "now"
    local duration = data.Duration or DEFAULT_DURATION

    -- Calculate dynamic height and apply it
    local descriptionHeight = calculateTextHeight(newNotif.DescriptionLabel.Text)
    local totalHeight = PADDING + 18 + descriptionHeight + PADDING
    if totalHeight < BASE_HEIGHT then totalHeight = BASE_HEIGHT end
    
    newNotif.DescriptionLabel.Size = UDim2.new(1, -PADDING*2, 0, descriptionHeight)
    newNotif.Size = UDim2.new(0, NOTIFICATION_WIDTH, 0, totalHeight)

    -- Set its starting position off-screen, above the first notification spot
    newNotif.Position = UDim2.new(0.5, 0, 0, -totalHeight)
    newNotif.Parent = NotifGui
    newNotif.Visible = true

    -- Add to the top of the active notifications list
    table.insert(activeNotifications, 1, newNotif)

    -- Reposition all existing notifications to make space
    repositionAll()

    -- Coroutine to handle the life of this single notification
    coroutine.wrap(function()
        -- Wait for the notification's duration
        wait(duration)

        -- Animate out
        local slideOut = TweenService:Create(newNotif, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 0, -totalHeight - 20)
        })
        slideOut:Play()

        -- Remove from the active list
        for i, v in ipairs(activeNotifications) do
            if v == newNotif then
                table.remove(activeNotifications, i)
                break
            end
        end

        -- Reposition the remaining notifications to fill the gap
        repositionAll()
        
        -- Wait for animation to finish, then destroy
        slideOut.Completed:Wait()
        newNotif:Destroy()
    end)()
end

return module
