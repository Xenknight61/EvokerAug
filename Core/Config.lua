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
        backgroundTextTexture = "Interface\\Addons\\EvokerAug\\Media\\bar",
        backgroundTextTexture2 = "EvokerAug",
        headerunlock = false,
        sortByClass = false,
        sortType = "NAME",
        charSpell = {},
        macroAltClick = true,
        macroShiftClick = true,
        macroCtrlClick = true,
        tankSpellLeftClick = 360827,
        ShiftankSpellLeftClick = 395152,
        CtrlTankSpellLeftClick = 361469,
        AltTankSpellLeftClick = 361227,
        dpsSpellLeftClick = 409311,
        ShifdpsSpellLeftClick = 395152,
        CtrlDpsSpellLeftClick = 355913,
        AltDpsSpellLeftClick = 361227,
        buffList = {
            [410089] = "Prescience",
            [360827] = "Blistering Scales",
            [395296] = "Ebon Might",
            [369459] = "Source of Magic",
        }
    }
}

addon.Config = {
    ["version"] = "1.0.1",
    ["changelog"] = [=[
v1.0.1
    - Added icon to map section
    - Frame hiding function added

v1.0.0
    - Initial release
]=]
}
