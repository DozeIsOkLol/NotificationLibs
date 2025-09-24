--!/usr/bin/env lua
-- The Grand Tour - A comprehensive showcase of every feature in the iOSNotifFinal library.

-- IMPORTANT: Make sure this URL points to your final, stable source file (e.g., iOSNotifFinal.lua)
local githubUrl =
    'https://raw.githubusercontent.com/path/to/your/repo/iOSNotifFinal.lua'

-- Load the library from the raw GitHub link
local iOSNotif = loadstring(game:HttpGet(githubUrl))()
print(
    '--- iOSNotif Final Library Loaded. The Grand Tour will begin in 3 seconds... ---'
)
wait(3)

-- ===================================================================================
-- PART 1: THEME SHOWCASE - A visual tour of all available themes.
-- ===================================================================================
print('\n--- PART 1: THEME SHOWCASE ---')
print('We will now display one notification for each of the 6 built-in themes.')
wait(3)

iOSNotif.Notify({
    Title = 'Light Theme',
    Description = 'The default, clean look.',
    Theme = 'Light',
    Duration = 3,
})
wait(1.5)
iOSNotif.Notify({
    Title = 'Dark Theme',
    Description = 'For a sleek, modern feel.',
    Theme = 'Dark',
    Duration = 3,
})
wait(1.5)
iOSNotif.Notify({
    Title = 'Info Theme',
    Description = 'Perfect for general information.',
    Theme = 'Info',
    Duration = 3,
})
wait(1.5)
iOSNotif.Notify({
    Title = 'Success Theme',
    Description = 'For when things go right.',
    Theme = 'Success',
    Duration = 3,
})
wait(1.5)
iOSNotif.Notify({
    Title = 'Warning Theme',
    Description = 'For non-critical alerts.',
    Theme = 'Warning',
    Duration = 3,
})
wait(1.5)
iOSNotif.Notify({
    Title = 'Error Theme',
    Description = 'For critical failures.',
    Theme = 'Error',
    Duration = 3,
})
wait(4)

-- ===================================================================================
-- PART 2: CONFIGURATION & TEMPLATES - Set defaults and create reusable styles.
-- ===================================================================================
print('\n--- PART 2: CONFIGURATION & TEMPLATES ---')
print(
    "First, we'll create some 'templates' to pre-configure notification styles."
)
iOSNotif.CreateTemplate('Achievement', {
    Theme = 'Success',
    Timestamp = 'Unlocked',
    Sound = 'rbxassetid://4977298490', -- Valid "Success" sound
})
iOSNotif.CreateTemplate('SystemAlert', {
    Theme = 'Error',
    Timestamp = 'CRITICAL',
    Duration = 12,
})
print("Templates 'Achievement' and 'SystemAlert' created.")
wait(3)

print(
    "Now, let's use SetConfig to change the defaults for all future notifications."
)
iOSNotif.SetConfig({
    Position = 'BottomRight', -- Move to the bottom-right
    Animation = 'Fade', -- Use a fade animation
    RichText = true, -- Enable RichText by default
    Duration = 8, -- Set default duration to 8 seconds
})
print(
    'Global config set: Position = BottomRight, Animation = Fade, RichText = true.'
)
wait(4)

-- ===================================================================================
-- PART 3: INTERACTIVE & VISUAL FEATURES - Showcasing the dynamic elements.
-- ===================================================================================
print('\n--- PART 3: INTERACTIVE & VISUAL FEATURES ---')

-- HOVER-TO-PAUSE
print(
    'This next notification has a short timer. HOVER your mouse over it to pause the countdown!'
)
iOSNotif.Notify({
    Title = 'Hover to Pause!',
    Description = 'This will disappear in 5 seconds unless you hover your mouse over it.',
    Theme = 'Info',
    Duration = 5,
    RichText = false, -- Temporarily disable global setting for this one
    Sound = 'rbxassetid://9120386434', -- Valid pop sound
})
wait(6)

-- RICH TEXT
print(
    'This notification uses the default RichText setting we enabled with SetConfig.'
)
iOSNotif.Notify({
    Title = 'Rich Text Showcase',
    Description = "You can make text <b>bold</b>, <i>italic</i>, and <font color='rgb(0, 255, 127)'>colorful</font>.",
    Theme = 'Dark', -- This will appear in the bottom right and fade in
})
wait(9)

-- PROGRESS BAR & PROGRAMMATIC CONTROL
print(
    "Now, we'll create a notification, update its progress, and dismiss it manually."
)
local progressNotifID = iOSNotif.Notify({
    Template = 'SystemAlert',
    Position = 'TopCenter', -- Override global position for this one
    Animation = 'Slide', -- Override global animation
    Title = 'Downloading...',
    Description = 'Preparing assets...',
    Progress = 0, -- Set initial progress to 0%
    Duration = 999, -- Long duration because we control it
})

for i = 1, 10 do
    wait(0.3)
    iOSNotif.Update(progressNotifID, {
        Progress = i / 10,
        Description = 'Downloading assets... ' .. (i * 10) .. '%',
    })
end

iOSNotif.Update(progressNotifID, {
    Title = 'Download Complete!',
    Description = 'All assets have been downloaded successfully.',
    Template = 'Achievement', -- Apply a new template on the fly!
})

wait(3)
iOSNotif.Dismiss(progressNotifID) -- Manually dismiss the notification
wait(2)

-- ===================================================================================
-- PART 4: ADVANCED MANAGEMENT - Grouping and the Notification Center.
-- ===================================================================================
print('\n--- PART 4: ADVANCED MANAGEMENT ---')
iOSNotif.SetConfig({ Position = 'TopCenter', Animation = 'Slide' }) -- Reset position

-- NOTIFICATION GROUPING
print(
    "We'll now fire 4 notifications with the same GroupID. Watch them stack together!"
)
iOSNotif.Notify({
    Title = 'Player Joined',
    Description = 'DozeIsOkLol joined.',
    Theme = 'Dark',
    GroupID = 'PlayerUpdates',
})
wait(0.5)
iOSNotif.Notify({
    Title = 'Player Joined',
    Description = 'kalyaimak4u joined.',
    Theme = 'Dark',
    GroupID = 'PlayerUpdates',
})
wait(0.5)
iOSNotif.Notify({
    Title = 'Achievement',
    Description = 'DozeIsOkLol found a secret.',
    Template = 'Achievement',
    GroupID = 'PlayerUpdates',
})
wait(0.5)
iOSNotif.Notify({
    Title = 'Player Left',
    Description = 'SomePlayer left.',
    Theme = 'Dark',
    GroupID = 'PlayerUpdates',
})

print('The notifications have collapsed into a single, clean stack!')
wait(8)

-- NOTIFICATION CENTER
print(
    "Finally, let's open the Notification Center to see a history of every notification from this demo."
)
iOSNotif.ToggleCenter()
wait(7)
print('Toggling it again to hide it.')
iOSNotif.ToggleCenter()

print('\n--- THE GRAND TOUR IS COMPLETE ---')
