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
        autoFrameFill = true,
        sortByClass = false,
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
        },
        omniCDSupport = false,
    }
}

addon.Config = {
    ["version"] = "1.0.14",
    ["changelog"] = [=[
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

v1.0.7
    - Added frame clear to clear the frame
    - Added progress bar to keep track of Ebon Might Buff
    - The error that occurred when adding a new spell id during buff tracking has been fixed.

v1.0.6
    - OmniCD support has been added, you can see cooldown
        next to the frame (optional, you can turn it off and on)
    - Auto fill has been added. Frame will automatically select
        (Not suitable for Raid groups.)

v1.0.5
    - The issue of more than one ebon might appearing in buff tracking
        has been resolved
    - When the person in the frame goes offline, they will be
        automatically deleted from the frame.

v1.0.4
    - Discord information added
    - Added frame tracking feature for Prescience buff (on/off feature)
    - Added sound feature for Prescience buff
    - Fixed some typos
    - Added countdown size adjustment function in the icon

v1.0.3
    - Fixed the issue of making yourself appear transparent
    - Added right click feature to macros

v1.0.2
    - Fixed an issue that caused the icon to be deleted even though it was
        Buff
    - Range function has been added. If the player is not in range,
        it will appear transparent.
    - Fixed the Ebon Might icon not showing up.

v1.0.1
    - Added icon to map section
    - Frame hiding function added

v1.0.0
    - Initial release
]=]
}