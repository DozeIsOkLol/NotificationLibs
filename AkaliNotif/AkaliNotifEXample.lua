local AkaliNotif = loadstring(
    game:HttpGet(
        'https://raw.githubusercontent.com/DozeIsOkLol/NotificationLibs/refs/heads/main/AkaliNotif/AkaliNotifSource.lua'
    )
)()
local Notify = AkaliNotif.Notify

wait(1)

Notify({
    Title = 'Brought to you by UI Lib',
    Description = 'made by Akali i think',
    Duration = 10,
})

Notify({
    Description = 'This is only a description ',
    Duration = 10,
})

Notify({
    Title = 'This is only a Title',
    Duration = 10,
})
