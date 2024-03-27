local addonName = ...
---@class EvokerAug: AceConsole-3.0
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@cast addon +AceConsole-3.0
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local EvokerAugOptions = {}
local checkboxStates = {}
local selectedPlayerFrames = {}
local selectedPlayerFrameContainer


local function sortFramesByName(a, b)
    return a.playerName < b.playerName
end

local function sortFramesByClass(a, b)
    return a.class < b.class
end

local function sortFramesByRole(a, b)
    return a.role < b.role
end

local isFound
local changelog = (addon.Config["changelog"]:gsub("^[ \t\n]*", "|cff99cdff"):gsub("\n\nv([%d%.]+)", function(ver)
	if not isFound and ver ~= addon.Config["version"] then
		isFound = true
		return "|cff808080\n\nv" .. ver
	end
end):gsub("\t", "\32\32\32\32\32\32\32\32")or "|cff808080\n\nv") .. "|r"

local sortTypes = {
    ["NAME"] = sortFramesByName,
    ["CLASS"] = sortFramesByClass,
    ["ROLE"] = sortFramesByRole,
}


---- Player Buffs Icon -----
local function GetCharacterName(fullName)
    if fullName then
        local characterName = string.match(fullName, "([^%-]+)")
        return characterName
    else
        return nil
    end
end

local function RepositionBuffIcons(playerFrame)

    playerFrame["buff"].xOffset = 0

    -- İkonları yerleştir
    for k, icon in pairs(playerFrame["buff"]) do
        if type(icon) == "table" and not string.match(k, "Text$") then
            icon:SetPoint("LEFT", playerFrame, "RIGHT", playerFrame["buff"].xOffset, 0)
            playerFrame["buff"].xOffset = playerFrame["buff"].xOffset + 20
        end
    end


end

local function RemoveBuffIcon(playerFrame, buffID)
    if playerFrame and buffID then
        if playerFrame["buff"][buffID] then

            playerFrame["buff"][buffID.."Text"].ticker:Cancel()
            playerFrame["buff"][buffID.."Text"]:Hide()
            playerFrame["buff"][buffID.."Text"]:ClearAllPoints()
            playerFrame["buff"][buffID.."Text"] = nil


            playerFrame["buff"][buffID]:Hide()
            playerFrame["buff"][buffID]:ClearAllPoints()
            playerFrame["buff"][buffID]:SetParent(nil)
            playerFrame["buff"][buffID] = nil

            RepositionBuffIcons(playerFrame)
        end
    end
end

local function AddBuffIcon(playerFrame, auraInstanceID, timestamp, icon)
    if playerFrame == nil then
        return
    end
    if playerFrame["buff"][auraInstanceID] then
        if playerFrame["buff"][auraInstanceID.."Text"] then
            playerFrame["buff"][auraInstanceID.."Text"].timestamp = timestamp
        end
        return
    end
    playerFrame["buff"][auraInstanceID] =  playerFrame:CreateTexture(nil, "OVERLAY")
    playerFrame["buff"][auraInstanceID]:SetTexture(icon)
    playerFrame["buff"][auraInstanceID]:SetSize(addon.db.profile.spellIconSize, addon.db.profile.spellIconSize)
    playerFrame["buff"][auraInstanceID]:SetPoint("LEFT", playerFrame, "RIGHT", playerFrame["buff"].xOffset, 0)
    playerFrame["buff"][auraInstanceID]:SetVertexColor(1, 1, 1, 1)
    playerFrame["buff"][auraInstanceID]:Show()
    playerFrame["buff"][auraInstanceID.."Text"] = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerFrame["buff"][auraInstanceID.."Text"]:SetPoint("CENTER", playerFrame["buff"][auraInstanceID], "CENTER", 0, 0)
    playerFrame["buff"][auraInstanceID.."Text"]:SetTextColor(1, 1, 1)
    playerFrame["buff"][auraInstanceID.."Text"]:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
    playerFrame["buff"][auraInstanceID.."Text"]:Show()
    playerFrame["buff"][auraInstanceID.."Text"].timestamp = timestamp
    playerFrame["buff"][auraInstanceID.."Text"].ticker = C_Timer.NewTicker(1, function()
        local duration = playerFrame["buff"][auraInstanceID.."Text"].timestamp - GetTime()
        if duration <= 0 then
            playerFrame["buff"][auraInstanceID.."Text"]:Hide()
            playerFrame["buff"][auraInstanceID.."Text"].ticker:Cancel()
        end
        if duration <= 20 then
            playerFrame["buff"][auraInstanceID.."Text"]:SetText(math.floor(duration))
        else
            playerFrame["buff"][auraInstanceID.."Text"]:SetText(nil)
        end

        if duration > 10 then
            playerFrame["buff"][auraInstanceID.."Text"]:SetTextColor(1, 1, 1)
        else
            playerFrame["buff"][auraInstanceID.."Text"]:SetTextColor(1, 0, 0)
        end
    end)
    playerFrame["buff"].xOffset = playerFrame["buff"].xOffset + 20

    if timestamp then
        local remainingTime = timestamp - GetTime()
        C_Timer.After(remainingTime, function()
            if playerFrame["buff"][auraInstanceID] == nil then
                return
            end
            playerFrame["buff"][auraInstanceID.."Text"].ticker:Cancel()

            RemoveBuffIcon(playerFrame, auraInstanceID)
        end)
    end
end

local function AddBuffIcons(playerFrame, playerName)
    if not playerFrame["buff"] then
        playerFrame["buff"] = {}
        playerFrame["buff"].xOffset = 0
    end

    for k, v in pairs(addon.db.profile.buffList) do
        local spellTable = C_UnitAuras.GetAuraDataBySpellName(playerName, v, "HELPFUL")
        if spellTable then
            AddBuffIcon(playerFrame, spellTable.auraInstanceID, spellTable.expirationTime, spellTable.icon)
        end
    end
end




--- Create Player Frame ----
local function MacroUpdate(frame)
    if frame.role == "TANK" then
        frame:SetAttribute("spell", addon.db.profile.charSpell[addon.db.profile.tankSpellLeftClick]);
        if addon.db.profile.macroAltClick then
            frame:SetAttribute("alt-spell*", addon.db.profile.charSpell[addon.db.profile.AltTankSpellLeftClick]);
        else
            frame:SetAttribute("alt-spell*", nil)
        end
        if addon.db.profile.macroShiftClick then
            frame:SetAttribute("shift-spell*", addon.db.profile.charSpell[addon.db.profile.ShiftankSpellLeftClick]);
        else
            frame:SetAttribute("shift-spell*", nil)
        end
        if addon.db.profile.macroCtrlClick then
            frame:SetAttribute("ctrl-spell*", addon.db.profile.charSpell[addon.db.profile.CtrlTankSpellLeftClick]);
        else
            frame:SetAttribute("ctrl-spell*", nil)
        end
    else
        frame:SetAttribute("spell", addon.db.profile.charSpell[addon.db.profile.dpsSpellLeftClick])
        if addon.db.profile.macroAltClick then
            frame:SetAttribute("alt-spell*", addon.db.profile.charSpell[addon.db.profile.AltDpsSpellLeftClick])
        else
            frame:SetAttribute("alt-spell*", nil)
        end
        if addon.db.profile.macroShiftClick then
            frame:SetAttribute("shift-spell*", addon.db.profile.charSpell[addon.db.profile.ShifdpsSpellLeftClick])
        else
            frame:SetAttribute("shift-spell*", nil)
        end
        if addon.db.profile.macroCtrlClick then
            frame:SetAttribute("ctrl-spell*", addon.db.profile.charSpell[addon.db.profile.CtrlDpsSpellLeftClick])
        else
            frame:SetAttribute("ctrl-spell*", nil)
        end
    end
end

local function UpdatePlayerFrame()
    for i, frame in ipairs(selectedPlayerFrames) do
        MacroUpdate(frame)
    end
end

local function CreateSelectedPlayerFrame(playerName, class, PlayerRole, unitIndex)
    local frameIndex = #selectedPlayerFrames + 1
    selectedPlayerFrames[frameIndex] = CreateFrame("Button", selectedPlayerFrameContainer, UIParent, BackdropTemplateMixin and "BackdropTemplate, SecureUnitButtonTemplate")
    selectedPlayerFrames[frameIndex]:SetSize(150, addon.db.profile.buttonHeight)-- Boyutu ayarla
    selectedPlayerFrames[frameIndex]["buff"] = {}
    selectedPlayerFrames[frameIndex]["buff"].xOffset = 0
    selectedPlayerFrames[frameIndex].playerName = playerName
    selectedPlayerFrames[frameIndex].class = class
    selectedPlayerFrames[frameIndex].role = PlayerRole
    selectedPlayerFrames[frameIndex].texture = selectedPlayerFrames[frameIndex]:CreateTexture()
    selectedPlayerFrames[frameIndex].unit = unitIndex


    AddBuffIcons(selectedPlayerFrames[frameIndex], playerName)

    selectedPlayerFrames[frameIndex]:RegisterUnitEvent("UNIT_AURA")
    selectedPlayerFrames[frameIndex]:SetScript("OnEvent", function(self, event, unit, info)
        local playerNam = GetCharacterName(UnitName(unit))
        if event == "UNIT_AURA" and playerName == playerNam then
            if info.addedAuras then
                for _, v in pairs(info.addedAuras) do
                    if addon.db.profile.buffList[v.spellId] then
                        if v.expirationTime > 0 then
                            AddBuffIcon(selectedPlayerFrames[frameIndex], v.auraInstanceID, v.expirationTime, v.icon)
                        end
                    end
                end
            end
            if info.updatedAuraInstanceIDs then
                for _, v in pairs(info.updatedAuraInstanceIDs) do
                    local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, v)
                    if aura and addon.db.profile.buffList[aura.spellId] then
                        if aura.expirationTime > 0 then
                            AddBuffIcon(selectedPlayerFrames[frameIndex], aura.auraInstanceID, aura.expirationTime, aura.icon)
                        end
                    end
                end
            end
            if info.removedAuraInstanceIDs then
                for _, buffID in ipairs(info.removedAuraInstanceIDs) do
                    RemoveBuffIcon(selectedPlayerFrames[frameIndex], buffID)
                end
            end
        end
    end)

    selectedPlayerFrames[frameIndex]:SetAttribute('unitName',playerName)
    selectedPlayerFrames[frameIndex]:SetAttribute('unitID', unitIndex)
    selectedPlayerFrames[frameIndex]:SetAttribute("unit", unitIndex);
    selectedPlayerFrames[frameIndex]:SetAttribute("type", "spell")
    -- selectedPlayerFrames[frameIndex]:SetAttribute("*helpbutton1", "slot")


    MacroUpdate(selectedPlayerFrames[frameIndex])

    local classColor = RAID_CLASS_COLORS[class] or {r = 0.5, g = 0.5, b = 0.5}
    selectedPlayerFrames[frameIndex]:SetBackdrop({
        bgFile = [=[Interface\Tooltips\UI-Tooltip-Background]=],
        insets = {top = -1, left = -1, bottom = -1, right = -1}
    })
    selectedPlayerFrames[frameIndex]:SetBackdropColor(classColor.r, classColor.g, classColor.b, 0.9)

    selectedPlayerFrames[frameIndex].texture:SetPoint('TOP', selectedPlayerFrames[frameIndex], 'TOP')
    selectedPlayerFrames[frameIndex].texture:SetPoint('BOTTOM', selectedPlayerFrames[frameIndex], 'BOTTOM')
    selectedPlayerFrames[frameIndex].texture:SetPoint('LEFT', selectedPlayerFrames[frameIndex], 'LEFT')
    selectedPlayerFrames[frameIndex].texture:SetSize(150, 20)
    selectedPlayerFrames[frameIndex].texture:SetTexture(addon.db.profile.backgroundTextTexture)
    selectedPlayerFrames[frameIndex].texture:SetVertexColor(classColor.r, classColor.g, classColor.b, 0.9)

    -- Oyuncu adını gösteren bir metin oluştur
    local playerNameText = selectedPlayerFrames[frameIndex]:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    playerNameText:SetPoint("CENTER", selectedPlayerFrames[frameIndex], "CENTER", 0, 0)
    playerNameText:SetText(playerName)
    playerNameText:SetJustifyH("CENTER")
    playerNameText:SetJustifyV("MIDDLE")

    -- Tüm çerçeveleri oyuncu isimlerine göre sırala
    --table.sort(selectedPlayerFrames, sortFramesByName)

    -- Sıralama sonrası çerçevelerin konumlarını güncelle
    local tankCount = 0
    for i, frame in ipairs(selectedPlayerFrames) do
        if frame.role == "TANK" then
            tankCount = tankCount + 1
            frame:ClearAllPoints()
            frame:SetPoint("TOP", selectedPlayerFrameContainer, "TOP", 0, tankCount * addon.db.profile.buttonHeight)
        else
            frame:ClearAllPoints()
            frame:SetPoint("BOTTOM", selectedPlayerFrameContainer, "BOTTOM", 0, (i - tankCount) * -addon.db.profile.buttonHeight)
        end
    end

end

local function DeleteSelectedPlayerFrame(playerName)
    local playerIndex = nil
    for i, frame in ipairs(selectedPlayerFrames) do
        if frame.playerName == playerName then
            playerIndex = i
            break
        end
    end
    if playerIndex then
        selectedPlayerFrames[playerIndex]:Hide()
        selectedPlayerFrames[playerIndex]:ClearAllPoints()
        selectedPlayerFrames[playerIndex]:SetParent(nil)
        selectedPlayerFrames[playerIndex]:UnregisterEvent("UNIT_AURA")
        table.remove(selectedPlayerFrames, playerIndex)

        checkboxStates[playerName] = false


        table.sort(selectedPlayerFrames, sortFramesByName)

        local tankCount = 0
        for i, frame in ipairs(selectedPlayerFrames) do
            if frame.role == "TANK" then
                tankCount = tankCount + 1
                frame:SetPoint("TOP", selectedPlayerFrameContainer, "TOP", 0, tankCount * addon.db.profile.buttonHeight)
            else
                frame:SetPoint("BOTTOM", selectedPlayerFrameContainer, "BOTTOM", 0, (i - tankCount) * -addon.db.profile.buttonHeight)
            end
        end
    end
end

local function GroupUpdate()
    local partyMembers = GetHomePartyInfo()

    for _, frame in ipairs(selectedPlayerFrames) do
        local playerName = frame.playerName
        local memberInParty = false
        local unit

        for i, member in ipairs(partyMembers) do
            if member.name == playerName then
                memberInParty = true
                if playerName == UnitName("player") then
                    unit = "player"
                else
                    unit = (IsInRaid() and "raid" .. i) or (IsInGroup() and "party" .. i) or "player"
                end
                break
            end
        end

        if memberInParty then
            frame.unit = unit
            frame:SetAttribute("unit", frame.unit);
        else
            DeleteSelectedPlayerFrame(playerName)
        end
    end


    local isMenuOpen = UIDROPDOWNMENU_OPEN_MENU ~= nil
    if isMenuOpen then
        RightMenu()
    end
end

local function GetClasses()
    local Augment = {}
    for k, v in pairs(AllSpellList["Augmentation"]) do
        local spellName, _, icon = GetSpellInfo(v)
        Augment[v] = {icon = icon, name = spellName}
    end

    return Augment
end

local function GetOptions()
    local profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(addon.db)
    profiles.order = 600
	profiles.disabled = false
    local orderNumber = 2
    EvokerAugOptions = {
        name = addonName,
        type = "group",
        childGroups = "tab",
        args = {
            home = {
                order = 1,
                name = "EvokerAug",
                type = "group",
                args={
                    evokerAug = {
                        order = 0,
                        image = "Interface\\Addons\\EvokerAug\\Media\\augevoker-logo",
                        imageWidth = 64, imageHeight = 64, imageCoords = { 0, 1, 0, 1 },
                        type = "description",
                        name = "EvokerAug",
                        fontSize = "large",
                    },
                    pd1 = {
                        name = "\n\n\n", order = 1, type = "description",
                    },
                    version = {
                        name = "|cffffff00 Version |r |cff00ff00 1.0.0 |r",
                        order = 2,
                        type = "description",
                    },
                    author = {
                        name = "|cffffff00 Author |r |cff00ff00  Xenknight |r",
                        order = 3,
                        type = "description",
                    },
                    pd2 = {
                        name = "\n\n\n", order = 4, type = "description",
                    },
                    h1 = {
                        type = 'header',
                        name = 'Changelog',
                        order = 5,
                    },
                    changenlog = {
                        type = "group",
                        name = " ",
                        inline = true,
                        order = 6,
                        args = {
                            pd3 = {
                                name = "\n", order = 1, type = "description",
                            },
                            changelog = {
                                order = 1,
                                type = "description",
                                name = changelog,
                            },
                        },
                    },
                }
            },
            settings = {
                order = 2,
                name = "Settings",
                type = "group",
                args = {
                    h1 = {
                        type = 'header',
                        name = 'Settings',
                        order = 10,
                    },
                    sortType = {
                        order = 12,
                        type = 'select',
                        name = "Sort Type",
                        desc = "Choose which attribute to sort player frames by",
                        values = {
                            ["NAME"] = "Name",
                            ["CLASS"] = "Class",
                            ["ROLE"] = "Role",
                        },
                        get = function() return addon.db.profile.sortType end,
                        set = function(info, value)
                            addon.db.profile.sortType = value
                            local tank = 0
                            table.sort(selectedPlayerFrames, sortTypes[value])
                            for i, frame in ipairs(selectedPlayerFrames) do
                                if frame.role == "TANK" then
                                    tank = tank + 1
                                    frame:SetPoint("TOP", selectedPlayerFrameContainer, "TOP", 0, tank * addon.db.profile.buttonHeight)
                                else
                                    local dpsCheck = i - tank
                                    frame:SetPoint("BOTTOM", selectedPlayerFrameContainer, "BOTTOM", 0, dpsCheck * -addon.db.profile.buttonHeight)
                                end
                            end
                        end,
                    },
                    l1 = {
                        type = 'description',
                        width = 0.3,
                        name = '',
                        order = 13,
                    },
                    buttontexture = {
                        order = 14,
                        type = 'select',
                        name = "Button Texture",
                        desc = "Change Texture",
                        values = AceGUIWidgetLSMlists.statusbar,
                        dialogControl = 'LSM30_Statusbar',
                        get = function() return addon.db.profile.backgroundTextTexture2 or "EvokerAug" end,
                        set = function(info, key)
                            addon.db.profile.backgroundTextTexture = AceGUIWidgetLSMlists.statusbar[key]
                            addon.db.profile.backgroundTextTexture2 = key
                            if addon.db.profile.backgroundTextTexture and #selectedPlayerFrames ~= 0 then
                                for i, frame in ipairs(selectedPlayerFrames) do
                                    frame.texture:SetTexture(addon.db.profile.backgroundTextTexture)
                                end
                            end
                        end
                    },
                    h4 = {
                        type = 'description',
                        name = '    ',
                        order = 15,
                        width = 3
                    },
                    buttonHeight = {
                        type = 'range',
                        name = 'Button height',
                        desc = 'Height of the assist buttons (a positive value)',
                        min = 20, max = 40, step = 1,
                        get = function() return addon.db.profile.buttonHeight end,
                        set = function(info, value)
                            local tank = 0
                            addon.db.profile.buttonHeight = value
                            for i, frame in ipairs(selectedPlayerFrames) do
                                frame:SetSize(150, addon.db.profile.buttonHeight)
                            end
                            for i, frame in ipairs(selectedPlayerFrames) do
                                if frame.role == "TANK" then
                                    tank = tank + 1
                                    frame:SetPoint("TOP", selectedPlayerFrameContainer, "TOP", 0, tank * addon.db.profile.buttonHeight)
                                else
                                    local dpsCheck = i - tank
                                    frame:SetPoint("BOTTOM", selectedPlayerFrameContainer, "BOTTOM", 0, dpsCheck * -addon.db.profile.buttonHeight)
                                end
                            end
                        end,
                        order = 16,
                    },
                    l2 = {
                        type = 'description',
                        width = 0.3,
                        name = '',
                        order = 17,
                    },
                    IconbuttonHeight = {
                        type = 'range',
                        name = 'Spell Size',
                        desc = 'Size of spells',
                        min = 20, max = 40, step = 1,
                        get = function() return addon.db.profile.spellIconSize end,
                        set = function(info, value)

                            addon.db.profile.spellIconSize = value

                            for k, v in pairs(selectedPlayerFrames) do
                                if v["buff"] then
                                    for k2, v2 in pairs(selectedPlayerFrames[k]["buff"]) do
                                        if type(v2) == "table" and not string.match(k2, "Text$") then
                                            v2:SetSize(addon.db.profile.spellIconSize, addon.db.profile.spellIconSize)
                                        end
                                    end
                                end
                            end

                        end,
                        order = 18,
                    },
                    h3 = {
                        type = 'description',
                        name = '    ',
                        order = 19,
                        width = 3
                    },
                    unlockHeader = {
                        order = 20,
                        type = 'toggle',
                        name = "UnLock Header",
                        desc = " ",
                        width = 1,
                        get = function() return
                            addon.db.profile.headerunlock
                        end,
                        set = function(info, value)
                            addon.db.profile.headerunlock = value
                        end,
                    },
                    h2 = {
                        type = 'header',
                        name = 'Makrolar',
                        order = 40,
                    },
                    allowModifierAlt = {
                        name = "Alt key usage",
                        type = "toggle",
                        order = 42,
                        get = function(info) return addon.db.profile.macroAltClick end,
                        set = function(_, value)
                            addon.db.profile.macroAltClick = value
                            UpdatePlayerFrame()
                        end,
                        width = 0.8,
                    },
                    allowModifierShift = {
                        name = "Shift key usage",
                        type = "toggle",
                        order = 42,
                        get = function(info) return addon.db.profile.macroShiftClick end,
                        set = function(_, value)
                            addon.db.profile.macroShiftClick = value
                            UpdatePlayerFrame()
                        end,
                        width = 0.8,
                    },
                    allowModifierCtrl = {
                        name = "Ctrl key usage",
                        type = "toggle",
                        order = 43,
                        get = function(info) return addon.db.profile.macroCtrlClick end,
                        set = function(_, value)
                            addon.db.profile.macroCtrlClick = value
                            UpdatePlayerFrame()
                        end,
                        width = 0.8,
                    },
                    tankClickSpell = {
                        name = "Tank click",
                        type = "select",
                        values = addon.db.profile.charSpell,
                        order = 45,
                        desc = "Select the spell to be used when left click key is pressed",
                        set = function(info, value)
                            addon.db.profile.tankSpellLeftClick = value
                            UpdatePlayerFrame()
                        end,
                        get = function() return addon.db.profile.tankSpellLeftClick end,
                    },
                    l3 = {
                        type = 'description',
                        width = 0.3,
                        name = '',
                        order = 46,
                    },
                    dpsClickSpell = {
                        name = "DPS click",
                        type = "select",
                        values = addon.db.profile.charSpell,
                        order = 47,
                        desc = "Select the spell to be used when left click key is pressed",
                        set = function(info, value)
                            addon.db.profile.dpsSpellLeftClick = value
                            UpdatePlayerFrame()
                        end,
                        get = function() return addon.db.profile.dpsSpellLeftClick end,
                    },
                    ShifttankClickSpell = {
                        name = "Shift Tank click",
                        type = "select",
                        values = addon.db.profile.charSpell,
                        order = 48,
                        desc = "Select the spell to be used when shift click key is pressed",
                        set = function(info, value)
                            addon.db.profile.ShiftankSpellLeftClick = value
                            UpdatePlayerFrame()
                        end,
                        get = function() return addon.db.profile.ShiftankSpellLeftClick end,
                    },
                    l4 = {
                        type = 'description',
                        width = 0.3,
                        name = '',
                        order = 49,
                    },
                    ShiftdpsClickSpell = {
                        name = "Shift DPS click",
                        type = "select",
                        values = addon.db.profile.charSpell,
                        order = 50,
                        desc = "Select the spell to be used when shift click key is pressed",
                        set = function(info, value)
                            addon.db.profile.ShifdpsSpellLeftClick = value
                            UpdatePlayerFrame()
                        end,
                        get = function() return addon.db.profile.ShifdpsSpellLeftClick end,
                    },
                    CtrlttankClickSpell = {
                        name = "Ctrl Tank click",
                        type = "select",
                        values = addon.db.profile.charSpell,
                        order = 51,
                        desc = "Select the spell to be used when ctrl click key is pressed",
                        set = function(info, value)
                            addon.db.profile.CtrlTankSpellLeftClick = value
                            UpdatePlayerFrame()
                        end,
                        get = function() return addon.db.profile.CtrlTankSpellLeftClick end,
                    },
                    l5 = {
                        type = 'description',
                        width = 0.3,
                        name = '',
                        order = 52,
                    },
                    CtrltdpsClickSpell = {
                        name = "Ctrl DPS click",
                        type = "select",
                        values = addon.db.profile.charSpell,
                        order = 53,
                        desc = "Select the spell to be used when ctrl click key is pressed",
                        set = function(info, value)
                            addon.db.profile.CtrlDpsSpellLeftClick = value
                            UpdatePlayerFrame()
                        end,
                        get = function() return addon.db.profile.CtrlDpsSpellLeftClick end,
                    },
                    AltttankClickSpell = {
                        name = "Alt Tank click",
                        type = "select",
                        values = addon.db.profile.charSpell,
                        order = 54,
                        desc = "Select the spell to be used when alt click key is pressed",
                        set = function(info, value)
                            addon.db.profile.AltTankSpellLeftClick = value
                            UpdatePlayerFrame()
                        end,
                        get = function() return addon.db.profile.AltTankSpellLeftClick end,
                    },
                    l6 = {
                        type = 'description',
                        width = 0.3,
                        name = '',
                        order = 55,
                    },
                    AlttdpsClickSpell = {
                        name = "Alt DPS click",
                        type = "select",
                        values = addon.db.profile.charSpell,
                        order = 56,
                        desc = "Select the spell to be used when alt click key is pressed",
                        set = function(info, value)
                            addon.db.profile.AltDpsSpellLeftClick = value
                            UpdatePlayerFrame()
                        end,
                        get = function() return addon.db.profile.AltDpsSpellLeftClick end,
                    },
                },
            },
            customSpells = {
                order = 5,
                name = "Spell",
                type = "group",
                args = {
                    spellId_info = {
                        order = 1,
                        type = "description",
                        name = "You can add any spells you want and see these spells on the frame",
                    },
                    spellId = {
                        name = "Spell ID",
                        type = "input",
                        order = 2,
                        desc = "Spell ID",
                        validate = function(_, value)
                            local num = tonumber(value)
                            if num then
                                return true
                            else
                                return "Please enter a number"
                            end
                        end,
                        set = function(_, state)
                            local spellId = tonumber(state)
                            if spellId then
                                local name, _, icon = GetSpellInfo(spellId)
                                if name and not addon.db.profile.buffList[spellId] then
                                    EvokerAugOptions.args.customSpells.args.buffList.args[name] = {  -- !TODO: yeni bir fonksiyon oluştur ve ona aktar
                                        order = orderNumber,
                                        type = 'toggle',
                                        name = name,
                                        imageCoords = { 0.07, 0.93, 0.07, 0.93 },
                                        image = icon,
                                        arg = spellId,
                                        set = function(_, value)
                                            if value then
                                                addon.db.profile.buffList[spellId] = name
                                            else
                                                addon.db.profile.buffList[spellId] = nil
                                            end
                                        end,
                                        get = function()
                                            return addon.db.profile.buffList[spellId] ~= nil
                                        end,
                                    }
                                    orderNumber = orderNumber + 1
                                    AceConfigRegistry:NotifyChange(addonName)
                                end
                            end
                        end,
                    },
                    buffList = {
                        type = 'group',
                        name = 'Spell List',
                        inline = true,
                        order = 3,
                        args = {
                            h1 = {
                                type = 'header',
                                name = 'Buff List',
                                order = 1,
                            },
                        },
                    },
                },
            },
            profiles = profiles,
        },

    }

    for k, v in pairs(GetClasses()) do
        EvokerAugOptions.args.customSpells.args.buffList.args[v.name] = {
            order = orderNumber,
            type = 'toggle',
            name = v.name,
            imageCoords = { 0.07, 0.93, 0.07, 0.93 },
            image = v.icon,
            arg = k,
            set = function(_, value)
                if value then
                    addon.db.profile.buffList[k] = v.name
                else
                    addon.db.profile.buffList[k] = nil
                end
            end,
            get = function()
                return addon.db.profile.buffList[k] ~= nil
            end,
        }

        orderNumber = orderNumber + 1
    end

    return EvokerAugOptions
end

function addon:OnInitialize()
    self.db = LibStub('AceDB-3.0'):New(addonName.."DB", self.DefaultProfile, true)
    self.db.RegisterCallback(self, "OnProfileReset", "Reconfigure")
	self:RegisterChatCommand("aug", function(cmd)
		addon:OpenOptions(strsplit(' ', cmd or ""))
	end, true)
end

function addon:OnEnable()-- PLAYER_LOGIN

    local lib = LibStub("LibSharedMedia-3.0")
    lib:Register(lib.MediaType.STATUSBAR, "EvokerAug", [[Interface\AddOns\EvokerAug\Media\bar]])


    selectedPlayerFrameContainer = CreateFrame("Frame", "EvokerAug", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    selectedPlayerFrameContainer:SetPoint(self.db.profile.positions.point, self.db.profile.positions.xOffset, self.db.profile.positions.yOffset)
    selectedPlayerFrameContainer:SetSize(200, 20)
    selectedPlayerFrameContainer:SetMovable(true)
    selectedPlayerFrameContainer:EnableMouse(true)
    selectedPlayerFrameContainer:RegisterForDrag("LeftButton")
    selectedPlayerFrameContainer:RegisterEvent("GROUP_ROSTER_UPDATE")

    selectedPlayerFrameContainer:SetScript("OnDragStart", function(sel)
        if self.db.profile.headerunlock then
            sel:StartMoving()
        end
    end)

    selectedPlayerFrameContainer:SetScript("OnDragStop", function(sel)
        sel:StopMovingOrSizing()
        local x,_,_,l, p = selectedPlayerFrameContainer:GetPoint()
        self.db.profile.positions.point = x
        self.db.profile.positions.xOffset = l
        self.db.profile.positions.yOffset = p
    end)

    selectedPlayerFrameContainer:SetScript("OnEvent", function(self, event, unit)
        if event == "GROUP_ROSTER_UPDATE" then
            GroupUpdate()
        end
    end)

    selectedPlayerFrameContainer:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            addon:OpenOptions()
        end
    end)

    selectedPlayerFrameContainer:SetScript("OnMouseDown", function(sel, button)
        if button == "RightButton" then
            RightMenu()
        end
    end)


    local addonNameTexture = selectedPlayerFrameContainer:CreateTexture(nil, "OVERLAY")
    addonNameTexture:SetAllPoints(selectedPlayerFrameContainer)
    addonNameTexture:SetTexture("Interface\\Addons\\EvokerAug\\Media\\bar")
    addonNameTexture:SetVertexColor(0.24, 0.24, 0.24, 1.0)

    local addonNameText = selectedPlayerFrameContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    addonNameText:SetPoint("CENTER", selectedPlayerFrameContainer, "CENTER", 0, 0)
    addonNameText:SetText(addonName)
    addonNameText:SetJustifyH("CENTER")
    addonNameText:SetJustifyV("MIDDLE")

    for i, spell in ipairs(spell_list["EVOKER"]["AUGMENTATION"]) do
        self.db.profile.charSpell[spell.spellID] = spell.name
    end
end

local function copytable(dst, src)
	wipe(dst)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dst[k]) ~= "table" then
				dst[k] = {}
			end
			copytable(dst[k], v)
		else
			dst[k] = v
		end
	end
end

function addon:Reconfigure()
	copytable(self.db.profile, self.DefaultProfile.profile)
    for i, spell in ipairs(spell_list["EVOKER"]["AUGMENTATION"]) do
        self.db.profile.charSpell[spell.spellID] = spell.name
    end

    for i, frame in ipairs(selectedPlayerFrames) do
        if not string.match(i, "buff$") then
            playerIndex = i
            selectedPlayerFrames[playerIndex]:Hide()
            selectedPlayerFrames[playerIndex]:ClearAllPoints()
            selectedPlayerFrames[playerIndex]:SetParent(nil)
            selectedPlayerFrames[playerIndex]:UnregisterEvent("UNIT_AURA")
            table.remove(selectedPlayerFrames, playerIndex)
            break
        end
    end
    checkboxStates = {}
    selectedPlayerFrames = {}
    selectedPlayerFrameContainer:ClearAllPoints()
    selectedPlayerFrameContainer:SetPoint(self.db.profile.positions.point, self.db.profile.positions.xOffset, self.db.profile.positions.yOffset)

end

function GetHomePartyInfo()
    local partyMembers = {}
    local in_group = IsInGroup() or IsInRaid()
    if in_group then
        for i = 1, GetNumGroupMembers() do
            local unit =    (IsInRaid() and "raid" .. i) or (IsInGroup() and "party" .. i) or "player"
            local fullName, class = UnitName(unit), UnitClass(unit)
            if fullName == nil then
                unit = "player"
                fullName, class =  UnitName(unit), UnitClass(unit)
            end

            local _, _, _, _, combatRole = GetSpecializationInfo(GetSpecialization(unit) or 0)
            if not combatRole then
                combatRole = "NONE"
            end
            local name = GetCharacterName(fullName)-- Tam adı karakter adına ayır

            if name and class and combatRole then
                table.insert(partyMembers, {name = name, class = strupper(string.gsub(class, "%s+", "")), role = combatRole})-- Sınıfı da tabloya ekliyoruz
            end
        end
    else
        local name, class = UnitName("player"), UnitClass("player")
        local specializationIndex = GetSpecialization() or 0
        local _, _, _, _, combatRole, _ = GetSpecializationInfo(specializationIndex)
        table.insert(partyMembers, {name = name, class = strupper(string.gsub(class, "%s+", "")), role = combatRole})
    end

    return partyMembers
end

function RightMenu()
    local optionsDropDown = CreateFrame("frame", "RightMenuDown", nil, "UIDropDownMenuTemplate")
    local PartyList = {}
    local partyMembers = GetHomePartyInfo()

    for i, member in ipairs(partyMembers) do
        table.insert(PartyList, {
            text = member.name .. ' (' .. member.role .. ')',
            checked = function() return checkboxStates[member.name] end,
            func = function(_, arg1, arg2, checked)
                if checked then
                    checkboxStates[member.name] = false
                    DeleteSelectedPlayerFrame(member.name)
                else
                    if member.name == UnitName("player") then
                        unit = "player"
                    else
                        unit = (IsInRaid() and "raid" .. i) or (IsInGroup() and "party" .. i) or "player"
                    end
                    checkboxStates[member.name] = true
                    CreateSelectedPlayerFrame(member.name, member.class, member.role, unit)
                end
            end
        })
    end
    local menu = {
        {
            text = addonName,
            isTitle = true,
            notCheckable = true,
        },
        {
            text = "Party members",
            hasArrow = true,
            notCheckable = true,
            menuList = PartyList,
        },
        {
            text = 'Settings',
            isTitle = true,
            notCheckable = true,
        },
        {
            text = 'Setting panel',
            notCheckable = true,
            func = function()addon:OpenOptions() end,
        },
    }
    EasyMenu(menu, optionsDropDown, "cursor", 0, 0, "MENU")

end



LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, GetOptions)
function addon:OpenOptions(...)
    AceConfigDialog:SetDefaultSize(addonName, 465, 550)
	if select('#', ...) > 0 then
		AceConfigDialog:Open(addonName)
		AceConfigDialog:SelectGroup(addonName, ...)
	elseif not AceConfigDialog:Close(addonName) then
		AceConfigDialog:Open(addonName)
	end
end