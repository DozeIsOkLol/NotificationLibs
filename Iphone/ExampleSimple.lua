--!/usr/bin/env lua
-- This script demonstrates how to use the custom timestamps and all the new themes.

-- IMPORTANT: Make sure this URL points to your new iOSNotifFinalSource.lua file
local githubUrl =
    'https://raw.githubusercontent.com/DozeIsOkLol/NotificationLibs/refs/heads/main/Iphone/Source.lua'

local iOSNotif = loadstring(game:HttpGet(githubUrl))()
local Notify = iOSNotif.Notify


-- --- Examples ---
print('iOS Final Notification Library Loaded. Running examples.')

-- Example 1: Custom Timestamp

wait(1)
Notify({
    Title = 'Custom Timestamp',
    Description = 'This notification has a custom timestamp.',
    Theme = 'Info',
    Timestamp = '1m ago', -- <-- This is how you set the custom text!
    Duration = 10,
})

-- Example 2: Success Theme
wait(1)
Notify({
    Title = 'Success!',
    Description = 'The operation completed successfully.',
    Theme = 'Success',
    Duration = 10,
})

-- Example 3: Warning Theme
wait(1)
Notify({
    Title = 'Warning',
    Description = 'Your session is about to expire.',
    Theme = 'Warning',
    Duration = 10,
})

-- Example 4: Error Theme
wait(1)
Notify({
    Title = 'Error',
    Description = 'Failed to connect to the server.',
    Theme = 'Error',
    Duration = 10, -- Longer duration for important messages
})

-- Example 5: Dark Theme (for comparison)
wait(1)
Notify({
    Title = 'Dark Theme',
    Description = 'This is the standard dark theme.',
    Theme = 'Dark',
    Duration = 10,
})
wait(1)
Notify({
    Title = 'IOS Notification Lib',
    Description = 'This notification Library was made by UILib',
    Theme = '',
    Timestamp = 'Made By UILib', -- <-- This is how you set the custom text!
    Duration = 10,
})
