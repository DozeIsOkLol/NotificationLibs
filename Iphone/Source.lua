--!/usr/bin/env lua
-- iOSNotifSource.lua
-- This is the main library file. Host this on GitHub.

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
local FONT = Enum.Font.SourceSans
local FONT_BOLD = Enum.Font.SourceSansBold
local DEFAULT_DURATION = 5 -- Default duration in seconds

-- --- UI Creation (Done Once) ---
local NotifGui = CoreGui:FindFirstChild("iOSNotifGui")
if NotifGui then NotifGui:Destroy() end

NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "iOSNotifGui"
NotifGui.ResetOnSpawn = false
NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
NotifGui.Parent = CoreGui

local NotificationFrame = Instance.new("Frame")
NotificationFrame.Name = "NotificationFrame"
NotificationFrame.Size = UDim2.new(0, NOTIFICATION_WIDTH, 0, BASE_HEIGHT)
NotificationFrame.AnchorPoint = Vector2.new(0.5, 0)
NotificationFrame.Position = UDim2.new(0.5, 0, 0, -BASE_HEIGHT - 20) -- Start off-screen
NotificationFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
NotificationFrame.BackgroundTransparency = 0.25
NotificationFrame.Parent = NotifGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 24)
UICorner.Parent = NotificationFrame

local AppIcon = Instance.new("ImageLabel")
AppIcon.Name = "AppIcon"
AppIcon.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
AppIcon.Position = UDim2.new(0, PADDING, 0, PADDING)
AppIcon.BackgroundTransparency = 1
AppIcon.Image = "rbxassetid://6031999801" -- Default Messages Icon
AppIcon.Parent = NotificationFrame

local AppIconCorner = Instance.new("UICorner")
AppIconCorner.CornerRadius = UDim.new(0, 6)
AppIconCorner.Parent = AppIcon

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Font = FONT_BOLD
TitleLabel.TextColor3 = Color3.fromRGB(15, 15, 15)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextYAlignment = Enum.TextYAlignment.Top
TitleLabel.TextSize = 15
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, PADDING + ICON_SIZE + 8, 0, PADDING)
TitleLabel.Size = UDim2.new(1, -(PADDING*3 + ICON_SIZE + 40), 0, 18)
TitleLabel.Parent = NotificationFrame

local TimestampLabel = Instance.new("TextLabel")
TimestampLabel.Name = "Timestamp"
TimestampLabel.Font = FONT
TimestampLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
TimestampLabel.TextXAlignment = Enum.TextXAlignment.Right
TimestampLabel.TextYAlignment = Enum.TextYAlignment.Top
TimestampLabel.TextSize = 14
TimestampLabel.BackgroundTransparency = 1
TimestampLabel.Position = UDim2.new(1, -PADDING - 40, 0, PADDING)
TimestampLabel.Size = UDim2.new(0, 40, 0, 18)
TimestampLabel.Parent = NotificationFrame

local DescriptionLabel = Instance.new("TextLabel")
DescriptionLabel.Name = "Description"
DescriptionLabel.Font = FONT
DescriptionLabel.TextColor3 = Color3.fromRGB(15, 15, 15)
DescriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
DescriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
DescriptionLabel.TextWrapped = true
DescriptionLabel.TextSize = 15
DescriptionLabel.BackgroundTransparency = 1
DescriptionLabel.Position = UDim2.new(0, PADDING, 0, PADDING + 18)
DescriptionLabel.Size = UDim2.new(1, -PADDING * 2, 0, 0) -- Height is dynamic
DescriptionLabel.Parent = NotificationFrame

-- --- Logic ---
local notificationQueue = {}
local isShowing = false

local function calculateTextHeight(text)
    local sizeVector = TextService:GetTextSize(
        text,
        DescriptionLabel.TextSize,
        DescriptionLabel.Font,
        Vector2.new(DescriptionLabel.AbsoluteSize.X, 1000)
    )
    return sizeVector.Y
end

local function processQueue()
    if isShowing or #notificationQueue == 0 then return end

    isShowing = true
    local data = table.remove(notificationQueue, 1)

    -- Update Content
    TitleLabel.Text = data.Title or "Notification"
    DescriptionLabel.Text = data.Description or ""
    AppIcon.Image = data.Icon or "rbxassetid://6031999801"
    TimestampLabel.Text = "now"
    local duration = data.Duration or DEFAULT_DURATION

    -- Calculate dynamic height
    local descriptionHeight = calculateTextHeight(DescriptionLabel.Text)
    local totalHeight = PADDING + 18 + descriptionHeight + PADDING
    if totalHeight < BASE_HEIGHT then totalHeight = BASE_HEIGHT end
    
    DescriptionLabel.Size = UDim2.new(1, -PADDING*2, 0, descriptionHeight)

    -- Pre-animation setup (resize while off-screen)
    NotificationFrame.Position = UDim2.new(0.5, 0, 0, -totalHeight - 20)
    NotificationFrame.Size = UDim2.new(0, NOTIFICATION_WIDTH, 0, totalHeight)

    -- Animate In
    local slideIn = TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0, 20)
    })
    slideIn:Play()
    slideIn.Completed:Wait()

    wait(duration)

    -- Animate Out
    local slideOut = TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, 0, 0, -totalHeight - 20)
    })
    slideOut:Play()
    slideOut.Completed:Wait()

    isShowing = false
    RunService.Heartbeat:Wait()
    processQueue()
end

function module.Notify(data)
    if typeof(data) ~= "table" then
        warn("iOSNotif Error: Notify data must be a table.")
        return
    end
    table.insert(notificationQueue, data)
    processQueue()
end

return module
