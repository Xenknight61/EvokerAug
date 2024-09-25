local addonName, root = ...
---@class EvokerAug: AceModule
local addon = LibStub("AceAddon-3.0"):NewAddon(root, addonName, "AceConsole-3.0")


addon.DefaultProfile = {
    profile = {
        enabled = true,
        positions = {
            point = "CENTER",
            xOffset = 0,
            yOffset = 0
        },
        minimap = {
            hide = false
        },
        buttonHeight = 25,
        spellIconSize = 25,
        spellIconTextSize = 12,
        backgroundTextTexture = "Interface\\Addons\\EvokerAug\\Media\\bar",
        backgroundTextTexture2 = "EvokerAug",
        headerunlock = false,
        autoFrameFill = false,
        showRaid = true,
        showMythic = true,
        sortByClass = true,
        sortType = "NAME",
        charSpell = {},
        prescienceBarEnable = true,
        prescienceBuffSoundFile = "",
        prescienceBuffSoundName = "None",
        ebonmightProgressBarEnable = true,
        macro = {
            AltClick = true,
            ShiftClick = true,
            CtrlClick = true,
            RightClick = true,
        },
        tankMacros = {
            LeftSpell = 360827,
            RightSpell = 360995,
            ShiftSpell = 395152,
            CtrlSpell = 361469,
            AltSpell = 361227,
        },
        dpsMacros = {
            LeftSpell = 409311,
            RightSpell = 360995,
            ShiftSpell = 395152,
            CtrlSpell = 355913,
            AltSpell = 361227,
        },
        buffList = {
            [410089] = "Prescience",
            [360827] = "Blistering Scales",
            [395296] = "Ebon Might",
            [395152] = "Ebon Might",
            [369459] = "Source of Magic",
            [361022] = "Sense Power",
        },
        omniCDSupport = false,
        favoriPlayer = {},
    }
}

addon.Config = {
    ["version"] = "1.0.20",
    ["changelog"] = [=[
v1.0.20
    - Changes have been made to the Party Members option to allow multiple selections.
    - Added Favorite Player option ( When the people added to the favorites enter the party, a frame will be added automatically. )
    - Added Show Raid and Mythic option

v1.0.18
    - Sense Power added. If someone has a buff, a glow is added to the frame
    - If the player is dead, the frame will be greyed out and DEAD will be written next to the name

v1.0.17
    - Fixed the issue where Alt, Shift and Ctrl keys sometimes did not work on the tank
    - Buff related corrections have been made

v1.0.16
    - LUA error fix

v1.0.15
    - Changed the UI of the drop-down menu
    - Unlock frame option added to drop-down menu
    - Changed unlock header option to unlock frame and added descriptions

v1.0.14
    - Prevented menu from opening when bar is clicked during combat

v1.0.13
    - Discord button unresponsive issue resolved
    - Frames will be automatically added when you enter the dungeons and deleted when you exit. (optional, you can turn it on or off)
    - If the spec is not aug it will be closed automatically

v1.0.12
    - Fixed the problem of the buff icon on the tank not being deleted

v1.0.11
    - Discord information update

v1.0.10
    - Fixed the problem of menu not opening
    - Buff not being deleted issue fixed

v1.0.9
    - TWW Update

v1.0.8
    - Frame overlapping problem with Ebon Might buff progress bar has been resolved
    - If the Prescience Bar is active, the bar will not appear full unless there is a buff on it.

]=]
}