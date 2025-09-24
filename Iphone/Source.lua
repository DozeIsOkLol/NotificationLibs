--!/usr/bin/env lua
-- ModuleScript in ReplicatedStorage
local NotificationManager = {}

local TweenService = game:GetService("TweenService")
local notificationGui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("NotificationGui")
local notificationFrame = notificationGui.NotificationFrame

local notificationQueue = {}
local isShowingNotification = false

local function showNotification(notificationInfo)
    isShowingNotification = true

    notificationFrame.Title.Text = notificationInfo.title
    notificationFrame.Message.Text = notificationInfo.message
    notificationFrame.Icon.Image = notificationInfo.icon or "rbxassetid://YOUR_DEFAULT_ICON_ID" -- Set a default icon

    -- Animation for the notification to appear
    local slideInTween = TweenService:Create(notificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 20)})
    slideInTween:Play()
    slideInTween.Completed:Wait()

    wait(notificationInfo.duration or 5)

    -- Animation for the notification to disappear
    local slideOutTween = TweenService:Create(notificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0, -100)})
    slideOutTween:Play()
    slideOutTween.Completed:Wait()

    isShowingNotification = false

    -- If there are more notifications in the queue, show the next one
    if #notificationQueue > 0 then
        local nextNotification = table.remove(notificationQueue, 1)
        showNotification(nextNotification)
    end
end

function NotificationManager.show(notificationInfo)
    if not isShowingNotification then
        showNotification(notificationInfo)
    else
        table.insert(notificationQueue, notificationInfo)
    end
end

return NotificationManager
