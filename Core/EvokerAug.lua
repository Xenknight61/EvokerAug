local addonName = ...
---@class EvokerAug: AceConsole-3.0
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
---@cast addon +AceConsole-3.0
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local icon = LibStub("LibDBIcon-1.0")
local EvokerAugOptions = {}
local checkboxStates = {}
local selectedPlayerFrames = {}
local selectedPlayerFrameContainer
local distanceTimer
local progressBar
-- Map Icon ---

---@diagnostic disable-next-line: missing-fields
local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject(addonName,
{
    type = "launcher",
    text = addonName,
    icon = "Interface\\AddOns\\EvokerAug\\Media\\augevoker-logo",
    OnClick = function(self, btn)
        if btn == "LeftButton" then
            addon:OpenOptions()
        elseif btn == "RightButton" then
            HideAllSubFrames()
        end
    end,
    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then return end
        tooltip:AddLine(addonName)
        tooltip:AddLine(" ")
        tooltip:AddLine("|cffeda55fLeft Click|r to open settings.", 0.2, 1, 0.2)
        tooltip:AddLine("|cffeda55fRight Click|r to show/hide frame.", 0.2, 1, 0.2)
    end,
})


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

-- Minimap Icon

local function HideAllSubFrames()
    if selectedPlayerFrameContainer:IsShown() then
        selectedPlayerFrameContainer:Hide()
    else
        selectedPlayerFrameContainer:Show()
    end
    for k, v in ipairs(selectedPlayerFrames) do
        if v:IsShown() then
            v:Hide()
        else
            v:Show()
        end
    end
end

local function createMiniMapIcon()
    ---@diagnostic disable-next-line: param-type-mismatch
    icon:Register(addonName, miniButton, addon.db.profile.minimap)
end

-- Ebon Might Proggres Bar

function CreateProgressBar()

    if addon.db.profile.ebonmightProgressBarEnable then
        if not progressBar then
            progressBar = CreateFrame("StatusBar", "MyProgressBar", UIParent)
            progressBar:SetSize(200, 20) -- Boyutları ayarlayın
            progressBar:SetPoint("CENTER", selectedPlayerFrameContainer, "CENTER", 0, 20) -- Konumu ayarlayın
            progressBar:SetMinMaxValues(0, 100) -- Minimum ve maksimum değerleri ayarlayın
            progressBar:SetValue(0) -- Mevcut değeri ayarlayın
            progressBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar") -- Progress barın görünümü
            progressBar:SetStatusBarColor(0, 1, 0) -- Progress bar rengi (RGB)

            local text = progressBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("CENTER", progressBar, "CENTER")
            text:SetText("Ebon Might")
        else
            progressBar:Show()
        end


        selectedPlayerFrameContainer:SetScript("OnUpdate", function ()
            local aura = C_UnitAuras.GetAuraDataBySpellName("player", "Ebon Might", "HELPFUL") -- Buffun bilgilerini al
            if (not aura) then return end
            if aura.expirationTime then
                local currentTime = GetTime()
                local remainingTime = aura.expirationTime - currentTime
                local duration = aura.duration / 100
                local progress = remainingTime / duration
                progressBar:SetValue(progress)
            else
                progressBar:SetValue(0)
            end
        end)
    elseif not addon.db.profile.ebonmightProgressBarEnable and progressBar then
        selectedPlayerFrameContainer:SetScript("OnUpdate", nil)
        if progressBar then
            progressBar:Hide()
        end
    end

end


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
    for k, icon in pairs(playerFrame["buff"]) do
        if type(icon) == "table" and not string.match(k, "Text$") then
            icon:SetPoint("LEFT", playerFrame, "RIGHT", playerFrame["buff"].xOffset, 0)
            playerFrame["buff"].xOffset = playerFrame["buff"].xOffset + addon.db.profile.buttonHeight
        end
    end
end

local function RemoveBuffIcon(playerFrame, buffID)
    if playerFrame and buffID then
        if playerFrame["buff"][buffID] then
            if playerFrame["buff"][buffID].iconid == 5199639 and addon.db.profile.prescienceBuffSoundName ~= "None" then
                PlaySoundFile(addon.db.profile.prescienceBuffSoundFile, "Master")
            end
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


local function AddBuffIcon(playerFrame, auraInstanceID, timestamp, icon, startTimer)
    if playerFrame == nil then
        return
    end
    if playerFrame["buff"][auraInstanceID] then
        if playerFrame["buff"][auraInstanceID.."Text"] then
            playerFrame["buff"][auraInstanceID.."Text"].timestamp = timestamp
            playerFrame["buff"][auraInstanceID.."Text"].starttimestamp = startTimer
        end
        return
    end
    playerFrame["buff"][auraInstanceID] =  playerFrame:CreateTexture(nil, "OVERLAY")
    playerFrame["buff"][auraInstanceID].iconid = icon
    playerFrame["buff"][auraInstanceID]:SetTexture(icon)
    playerFrame["buff"][auraInstanceID]:SetSize(addon.db.profile.spellIconSize, addon.db.profile.spellIconSize)
    playerFrame["buff"][auraInstanceID]:SetPoint("LEFT", playerFrame, "RIGHT", playerFrame["buff"].xOffset, 0)
    playerFrame["buff"][auraInstanceID]:SetVertexColor(1, 1, 1, 1)
    playerFrame["buff"][auraInstanceID]:Show()
    playerFrame["buff"][auraInstanceID.."Text"] = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerFrame["buff"][auraInstanceID.."Text"]:SetPoint("CENTER", playerFrame["buff"][auraInstanceID], "CENTER", 0, 0)
    playerFrame["buff"][auraInstanceID.."Text"]:SetTextColor(1, 1, 1)
    playerFrame["buff"][auraInstanceID.."Text"]:SetFont("Fonts\\ARIALN.TTF", addon.db.profile.spellIconTextSize, "OUTLINE")
    playerFrame["buff"][auraInstanceID.."Text"]:Show()
    playerFrame["buff"][auraInstanceID.."Text"].timestamp = timestamp
    playerFrame["buff"][auraInstanceID.."Text"].starttimestamp = startTimer
    playerFrame["buff"][auraInstanceID.."Text"].ticker = C_Timer.NewTicker(1, function()
        if playerFrame["buff"] == nil and playerFrame["buff"][auraInstanceID.."Text"] then
            return
        end
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

        if addon.db.profile.prescienceBarEnable and icon == 5199639 then
            local remainingWidth = 150 * (duration / playerFrame["buff"][auraInstanceID.."Text"].starttimestamp)
            if duration <= 0 then
                playerFrame.texture:SetSize(1, addon.db.profile.buttonHeight)
            else
                playerFrame.texture:SetSize(remainingWidth, addon.db.profile.buttonHeight)
            end
        end
    end)
    playerFrame["buff"].xOffset = playerFrame["buff"].xOffset + addon.db.profile.buttonHeight

    -- if timestamp then
    --     local remainingTime = timestamp - GetTime()
    --     C_Timer.After(remainingTime, function()
    --         if playerFrame["buff"][auraInstanceID] == nil then
    --             return
    --         end
    --         playerFrame["buff"][auraInstanceID.."Text"].ticker:Cancel()

    --         RemoveBuffIcon(playerFrame, auraInstanceID)
    --     end)
    -- end
end

local function AddBuffIcons(playerFrame, playerName)
    if not playerFrame["buff"] then
        playerFrame["buff"] = {}
        playerFrame["buff"].xOffset = 0
    end

    for k, v in pairs(addon.db.profile.buffList) do
        local spellTable = C_UnitAuras.GetAuraDataBySpellName(playerName, v, "HELPFUL")
        if spellTable then
            AddBuffIcon(playerFrame, spellTable.auraInstanceID, spellTable.expirationTime, spellTable.icon, spellTable.duration)
        end
    end
end




--- Create Player Frame ----

local function CheckDistance(playerFrame)
    local unit = playerFrame.unit
    if unit ~= "player" and UnitExists(unit) then
        local inRange = UnitInRange(unit)
        if inRange then
            playerFrame:SetAlpha(0.9);
        else
            playerFrame:SetAlpha(0.3);
        end
    end
end


local function UpdateDistance()
    for _, playerFrame in ipairs(selectedPlayerFrames) do
        CheckDistance(playerFrame)
    end
end

local function MacroUpdate(frame)
    if frame.role == "TANK" then
        frame:SetAttribute("spell", addon.db.profile.charSpell[addon.db.profile.tankMacros.LeftSpell]);
        if addon.db.profile.macro.AltClick then
            frame:SetAttribute("alt-spell", addon.db.profile.charSpell[addon.db.profile.tankMacros.AltSpell]);
        else
            frame:SetAttribute("alt-spell", nil)
        end
        if addon.db.profile.macro.ShiftClick then
            frame:SetAttribute("shift-spell", addon.db.profile.charSpell[addon.db.profile.tankMacros.ShiftSpell]);
        else
            frame:SetAttribute("shift-spell", nil)
        end
        if addon.db.profile.macro.CtrlClick then
            frame:SetAttribute("ctrl-spell", addon.db.profile.charSpell[addon.db.profile.tankMacros.CtrlSpell]);
        else
            frame:SetAttribute("ctrl-spell", nil)
        end
        if addon.db.profile.macro.RightClick then
            frame:SetAttribute("spell2", addon.db.profile.charSpell[addon.db.profile.tankMacros.RightSpell]);
        else
            frame:SetAttribute("spell2", "")
            frame:SetAttribute("ctrl-spell2", "");
            frame:SetAttribute("alt-spell2", "");
            frame:SetAttribute("shift-spell2", "");
        end

    else
        frame:SetAttribute("spell", addon.db.profile.charSpell[addon.db.profile.dpsMacros.LeftSpell])
        if addon.db.profile.macro.AltClick then
            frame:SetAttribute("alt-spell1", addon.db.profile.charSpell[addon.db.profile.dpsMacros.AltSpell])
        else
            frame:SetAttribute("alt-spell1", nil)
        end
        if addon.db.profile.macro.ShiftClick then
            frame:SetAttribute("shift-spell1", addon.db.profile.charSpell[addon.db.profile.dpsMacros.ShiftSpell])
        else
            frame:SetAttribute("shift-spell1", nil)
        end
        if addon.db.profile.macro.CtrlClick then
            frame:SetAttribute("ctrl-spell1", addon.db.profile.charSpell[addon.db.profile.dpsMacros.CtrlSpell])
        else
            frame:SetAttribute("ctrl-spell1", nil)
        end
        if addon.db.profile.macro.RightClick then
            frame:SetAttribute("spell2", addon.db.profile.charSpell[addon.db.profile.dpsMacros.RightSpell]);
            frame:SetAttribute("ctrl-spell2", "");
            frame:SetAttribute("alt-spell2", "");
            frame:SetAttribute("shift-spell2", "");
        else
            frame:SetAttribute("spell2", "")
            frame:SetAttribute("ctrl-spell2", "");
            frame:SetAttribute("alt-spell2", "");
            frame:SetAttribute("shift-spell2", "");
        end
    end


end

local function UpdatePlayerFrame()
    for i, frame in ipairs(selectedPlayerFrames) do
        MacroUpdate(frame)
    end
end

local function CreateSelectedPlayerFrame(playerName, class, PlayerRole, unitIndex, unittt)
    local frameIndex = #selectedPlayerFrames + 1
    checkboxStates[playerName] = true
    selectedPlayerFrames[frameIndex] = CreateFrame("Button", "EvokerAugPartyFrame"..unittt, UIParent, BackdropTemplateMixin and "BackdropTemplate, SecureUnitButtonTemplate")
    selectedPlayerFrames[frameIndex]:SetSize(150, addon.db.profile.buttonHeight)
    selectedPlayerFrames[frameIndex]["buff"] = {}
    selectedPlayerFrames[frameIndex]["buff"].xOffset = 0
    selectedPlayerFrames[frameIndex].playerName = playerName
    selectedPlayerFrames[frameIndex].class = class
    selectedPlayerFrames[frameIndex].role = PlayerRole
    selectedPlayerFrames[frameIndex].texture = selectedPlayerFrames[frameIndex]:CreateTexture()
    selectedPlayerFrames[frameIndex].unit = unitIndex
    selectedPlayerFrames[frameIndex]:RegisterForClicks("AnyDown")


    AddBuffIcons(selectedPlayerFrames[frameIndex], playerName)

    selectedPlayerFrames[frameIndex]:RegisterUnitEvent("UNIT_AURA")
    selectedPlayerFrames[frameIndex]:SetScript("OnEvent", function(self, event, unit, info)
        local playerNam = GetCharacterName(UnitName(unit))
        if event == "UNIT_AURA" and playerName == playerNam then
            if info.addedAuras then
                for _, v in pairs(info.addedAuras) do
                    if addon.db.profile.buffList[v.spellId] then
                        if v.expirationTime > 0 then
                            AddBuffIcon(selectedPlayerFrames[frameIndex], v.auraInstanceID, v.expirationTime, v.icon, v.duration)
                        end
                    end
                end
            end
            if info.updatedAuraInstanceIDs then
                for _, v in pairs(info.updatedAuraInstanceIDs) do
                    local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, v)
                    if aura and addon.db.profile.buffList[aura.spellId] then
                        if aura.expirationTime > 0 then
                            AddBuffIcon(selectedPlayerFrames[frameIndex], aura.auraInstanceID, aura.expirationTime, aura.icon, aura.duration)
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
    selectedPlayerFrames[frameIndex]:SetAttribute("type2", "spell")

    MacroUpdate(selectedPlayerFrames[frameIndex])

    selectedPlayerFrames[frameIndex]:SetBackdrop({
        bgFile = [=[Interface\Tooltips\UI-Tooltip-Background]=],
        insets = {top = -1, left = -1, bottom = -1, right = -1}
    })
    local classColor = RAID_CLASS_COLORS[class] or {r = 0.5, g = 0.5, b = 0.5}
    selectedPlayerFrames[frameIndex]:SetBackdropColor(classColor.r, classColor.g, classColor.b, 0.9)
    selectedPlayerFrames[frameIndex].texture:SetVertexColor(classColor.r, classColor.g, classColor.b, 0.9)
    CheckDistance(selectedPlayerFrames[frameIndex])



    selectedPlayerFrames[frameIndex].texture:SetPoint('TOP', selectedPlayerFrames[frameIndex], 'TOP')
    selectedPlayerFrames[frameIndex].texture:SetPoint('BOTTOM', selectedPlayerFrames[frameIndex], 'BOTTOM')
    selectedPlayerFrames[frameIndex].texture:SetPoint('LEFT', selectedPlayerFrames[frameIndex], 'LEFT')
    if addon.db.profile.prescienceBarEnable then
        selectedPlayerFrames[frameIndex].texture:SetSize(1, addon.db.profile.buttonHeight)
    else
        selectedPlayerFrames[frameIndex].texture:SetSize(150, addon.db.profile.buttonHeight)
    end
    selectedPlayerFrames[frameIndex].texture:SetTexture(addon.db.profile.backgroundTextTexture)


    local playerNameText = selectedPlayerFrames[frameIndex]:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    playerNameText:SetPoint("CENTER", selectedPlayerFrames[frameIndex], "CENTER", 0, 0)
    playerNameText:SetText(playerName)
    playerNameText:SetJustifyH("CENTER")
    playerNameText:SetJustifyV("MIDDLE")

    local tankCount = 0
    for i, frame in ipairs(selectedPlayerFrames) do
        if frame.role == "TANK" then
            tankCount = tankCount + 1
            frame:ClearAllPoints()
            local ebonMightCount = addon.db.profile.ebonmightProgressBarEnable and 20 or 0
            frame:SetPoint("TOP", selectedPlayerFrameContainer, "TOP", 0, ebonMightCount + (tankCount * addon.db.profile.buttonHeight))
        else
            frame:ClearAllPoints()
            frame:SetPoint("BOTTOM", selectedPlayerFrameContainer, "BOTTOM", 0, (i - tankCount) * -addon.db.profile.buttonHeight)
        end
    end

    if distanceTimer == nil then
        distanceTimer = C_Timer.NewTicker(1, UpdateDistance)
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
                local ebonMightCount = addon.db.profile.ebonmightProgressBarEnable and 20 or 0
                frame:SetPoint("TOP", selectedPlayerFrameContainer, "TOP", 0, ebonMightCount + (tankCount * addon.db.profile.buttonHeight))
            else
                frame:SetPoint("BOTTOM", selectedPlayerFrameContainer, "BOTTOM", 0, (i - tankCount) * -addon.db.profile.buttonHeight)
            end
        end
    end

    if #selectedPlayerFrames == 0 then
        if distanceTimer then
            distanceTimer:Cancel()
            distanceTimer = nil
        end
    end
end

local function FrameAutoFill()
    local partyMembers = GetHomePartyInfo()
    if not IsInRaid() then
        for i, member in ipairs(partyMembers) do
            local memberInParty = false
            local unit
            if member.name == UnitName("player") then
                unit = "player"
            else
                unit = (IsInGroup() and "party" .. i) or "player"
            end
            if member.role ~= "HEALER" and unit ~= "player" then
                for _, frame in ipairs(selectedPlayerFrames) do
                    if frame.playerName == member.name then
                        memberInParty = true
                        break
                    end
                end
                if not memberInParty then
                    CreateSelectedPlayerFrame(member.name, member.class, member.role, unit, member.unit)
                end
            end
        end
    end
end

local function GroupUpdate()
    local partyMembers = GetHomePartyInfo()

    for _, frame in ipairs(selectedPlayerFrames) do
        local playerName = frame.playerName
        local memberInParty = false
        local unitCheckChanged = false
        local unittt
        local unit

        for i, member in ipairs(partyMembers) do

            if member.name == playerName then
                memberInParty = true
                if playerName == UnitName("player") then
                    unit = "player"
                else
                    unit = (IsInRaid() and "raid" .. i) or (IsInGroup() and "party" .. i) or "player"
                end
                local isOffline = not UnitIsConnected(unit)
                if not unitCheckChanged then
                    if frame.unit ~= unit then
                        unitCheckChanged = true
                        unittt = unit
                    end
                end
                if isOffline then
                    DeleteSelectedPlayerFrame(playerName)
                    break
                end
                break
            end
        end

        if memberInParty then
            if unitCheckChanged then
                DeleteSelectedPlayerFrame(playerName)
                CreateSelectedPlayerFrame(playerName, frame.class, frame.role, unit, unittt)
            end
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
        local spellName, _, icon = GetSpellInfo(k)
        Augment[k] = {icon = icon, name = spellName}
    end

    return Augment
end

local function SpellListAdd(spellId)
    if spellId then
        local name, _, icon = GetSpellInfo(spellId)
        if name and not addon.db.profile.buffList[spellId] then
            EvokerAugOptions.args.customSpells.args.buffList.args[name..""..spellId] = {
                order = spellId,
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
            AceConfigRegistry:NotifyChange(addonName)
        end
    end
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
                        name = "|cffffff00 Version |r |cff00ff00 " .. addon.Config["version"] .. "|r",
                        order = 2,
                        type = "description",
                    },
                    author = {
                        name = "|cffffff00 Author |r |cff00ff00  Xenknight |r",
                        order = 3,
                        type = "description",
                    },
                    discord = {
                        name = "|cffffff00 Discord |r |cff00ff00 discord.gg/jKGdPTrXQF |r",
                        order = 3,
                        type = "description",
                    },
                    discordcopy = {
                        type = "execute",
                        name = "Copy Discord Link",
                        order = 4,
                        func = function()
                            local editBox = ChatFrame1EditBox
                            editBox:SetText("discord.gg/jKGdPTrXQF")
                            editBox:HighlightText()
                            editBox:SetFocus()
                        end,
                    },
                    pd2 = {
                        name = "\n\n", order = 5, type = "description",
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
                        order = 11,
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
                    l8 = {
                        type = 'description',
                        width = 0.15,
                        name = '',
                        order = 12,
                    },
                    buttontexture = {
                        order = 13,
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

                    buttonHeight = {
                        type = 'range',
                        name = 'Frame Height',
                        desc = 'Set Frame height',
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
                        order = 14,
                    },
                    l9 = {
                        type = 'description',
                        width = 0.15,
                        name = '',
                        order = 15,
                    },
                    IconbuttonHeight = {
                        type = 'range',
                        name = 'Icon Size',
                        desc = 'Set icon size',
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
                        order = 16,
                    },
                    IconTextSize = {
                        type = 'range',
                        name = 'Timer Text Size',
                        desc = 'Set the size of the text in the icon',
                        min = 12, max = 20, step = 1,
                        get = function() return addon.db.profile.spellIconTextSize end,
                        set = function(info, value)

                            addon.db.profile.spellIconTextSize = value

                            for k, v in pairs(selectedPlayerFrames) do
                                if v["buff"] then
                                    for k2, v2 in pairs(selectedPlayerFrames[k]["buff"]) do
                                        if type(v2) == "table" and string.match(k2, "Text$") then
                                            v2:SetFont("Fonts\\ARIALN.TTF", addon.db.profile.spellIconTextSize, "OUTLINE")
                                        end
                                    end
                                end
                            end

                        end,
                        order = 16,
                    },
                    h3 = {
                        type = 'description',
                        name = '    ',
                        order = 17,
                        width = 3
                    },
                    unlockHeader = {
                        order = 18,
                        type = 'toggle',
                        name = "UnLock Header",
                        desc = " ",
                        get = function() return
                            addon.db.profile.headerunlock
                        end,
                        set = function(info, value)
                            addon.db.profile.headerunlock = value
                        end,
                    },
                    frameHide = {
                        order = 19,
                        type = 'toggle',
                        name = "Hide Frame",
                        desc = " ",
                        get = function() return
                            selectedPlayerFrameContainer:IsShown()
                        end,
                        set = function(info, value)
                            HideAllSubFrames()
                        end,
                    },
                    h5 = {
                        type = 'header',
                        name = 'Prescience Buff',
                        order = 22,
                    },
                    presciencebar = {
                        order = 23,
                        type = 'toggle',
                        name = "Prescience Bar",
                        desc = "When enabled for Prescience, the dynamic bar is shown; when disabled, it is hidden.",
                        get = function() return
                            addon.db.profile.prescienceBarEnable
                        end,
                        set = function(info, value)
                            addon.db.profile.prescienceBarEnable = value
                        end,
                    },
                    prescienceSound = {
                        order = 24,
                        type = 'select',
                        name = "Prescience Sound",
                        desc = "The sound to be heard when Buff is finished",
                        values = AceGUIWidgetLSMlists.sound,
                        dialogControl = 'LSM30_Sound',
                        get = function() return addon.db.profile.prescienceBuffSoundName or "None" end,
                        set = function(info, key)
                            addon.db.profile.prescienceBuffSoundFile = AceGUIWidgetLSMlists.sound[key]
                            addon.db.profile.prescienceBuffSoundName = key
                        end
                    },
                    ebonmight = {
                        order = 23,
                        type = 'toggle',
                        name = "Ebon Might Progress Bar",
                        desc = "When enabled for Ebon Might, the dynamic bar is shown; when disabled, it is hidden.",
                        get = function() return
                            addon.db.profile.ebonmightProgressBarEnable
                        end,
                        set = function(info, value)
                            addon.db.profile.ebonmightProgressBarEnable = value
                            CreateProgressBar()
                        end,
                    },
                    h2 = {
                        type = 'header',
                        name = 'Macros',
                        order = 40,
                    },
                    allowModifierAlt = {
                        name = "Alt Key usage",
                        type = "toggle",
                        order = 41,
                        get = function(info) return addon.db.profile.macro.AltClick end,
                        set = function(_, value)
                            addon.db.profile.macro.AltClick = value
                            UpdatePlayerFrame()
                        end,
                        width = 0.8,
                    },
                    l1 = {
                        type = 'description',
                        width = 0.3,
                        name = '',
                        order = 42,
                    },
                    allowModifierShift = {
                        name = "Shift Key usage",
                        type = "toggle",
                        order = 43,
                        get = function(info) return addon.db.profile.macro.ShiftClick end,
                        set = function(_, value)
                            addon.db.profile.macro.ShiftClick = value
                            UpdatePlayerFrame()
                        end,
                        width = 0.8,
                    },
                    allowModifierCtrl = {
                        name = "Ctrl Key usage",
                        type = "toggle",
                        order = 44,
                        get = function(info) return addon.db.profile.macro.CtrlClick end,
                        set = function(_, value)
                            addon.db.profile.macro.CtrlClick = value
                            UpdatePlayerFrame()
                        end,
                        width = 0.8,
                    },
                    l2 = {
                        type = 'description',
                        width = 0.3,
                        name = '',
                        order = 45,
                    },
                    rightModifier = {
                        name = "Right Key Usage",
                        type = "toggle",
                        order = 46,
                        get = function(info) return addon.db.profile.macro.RightClick end,
                        set = function(_, value)
                            addon.db.profile.macro.RightClick = value
                            UpdatePlayerFrame()
                        end,
                        width = 0.8,
                    },

                    tankClickSpell = {
                        name = "Tank click",
                        type = "select",
                        values = addon.db.profile.charSpell,
                        order = 47,
                        desc = "Select the spell to be used when left click key is pressed",
                        set = function(info, value)
                            addon.db.profile.tankMacros.LeftSpell = value
                            UpdatePlayerFrame()
                        end,
                        get = function() return addon.db.profile.tankMacros.LeftSpell end,
                    },
                    l3 = {
                        type = 'description',
                        width = 0.15,
                        name = '',
                        order = 48,
                    },
                    dpsClickSpell = {
                        name = "DPS click",
                        type = "select",
                        values = addon.db.profile.charSpell,
                        order = 49,
                        desc = "Select the spell to be used when left click key is pressed",
                        set = function(info, value)
                            addon.db.profile.dpsMacros.LeftSpell = value
                            UpdatePlayerFrame()
                        end,
                        get = function() return addon.db.profile.dpsMacros.LeftSpell end,
                    },

                    RightttankClickSpell = {
                        name = "Right Tank click",
                        type = "select",
                        values = addon.db.profile.charSpell,
                        order = 50,
                        desc = "Select the spell to be used when right click key is pressed",
                        set = function(info, value)
                            addon.db.profile.tankMacros.RightSpell = value
                            UpdatePlayerFrame()
                        end,
                        get = function() return addon.db.profile.tankMacros.RightSpell end,
                    },
                    l4 = {
                        type = 'description',
                        width = 0.15,
                        name = '',
                        order = 51,
                    },
                    RighttdpsClickSpell = {
                        name = "Right DPS click",
                        type = "select",
                        values = addon.db.profile.charSpell,
                        order = 52,
                        desc = "Select the spell to be used when right click key is pressed",
                        set = function(info, value)
                            addon.db.profile.dpsMacros.RightSpell = value
                            UpdatePlayerFrame()
                        end,
                        get = function() return addon.db.profile.dpsMacros.RightSpell end,
                    },


                    ShifttankClickSpell = {
                        name = "Shift Tank click",
                        type = "select",
                        values = addon.db.profile.charSpell,
                        order = 53,
                        desc = "Select the spell to be used when shift click key is pressed",
                        set = function(info, value)
                            addon.db.profile.tankMacros.ShiftSpell = value
                            UpdatePlayerFrame()
                        end,
                        get = function() return addon.db.profile.tankMacros.ShiftSpell end,
                    },
                    l5 = {
                        type = 'description',
                        width = 0.15,
                        name = '',
                        order = 54,
                    },
                    ShiftdpsClickSpell = {
                        name = "Shift DPS click",
                        type = "select",
                        values = addon.db.profile.charSpell,
                        order = 55,
                        desc = "Select the spell to be used when shift click key is pressed",
                        set = function(info, value)
                            addon.db.profile.dpsMacros.ShiftSpell = value
                            UpdatePlayerFrame()
                        end,
                        get = function() return addon.db.profile.dpsMacros.ShiftSpell end,
                    },


                    CtrlttankClickSpell = {
                        name = "Ctrl Tank click",
                        type = "select",
                        values = addon.db.profile.charSpell,
                        order = 56,
                        desc = "Select the spell to be used when ctrl click key is pressed",
                        set = function(info, value)
                            addon.db.profile.tankMacros.CtrlSpell = value
                            UpdatePlayerFrame()
                        end,
                        get = function() return addon.db.profile.tankMacros.CtrlSpell end,
                    },
                    l6 = {
                        type = 'description',
                        width = 0.15,
                        name = '',
                        order = 57,
                    },
                    CtrltdpsClickSpell = {
                        name = "Ctrl DPS click",
                        type = "select",
                        values = addon.db.profile.charSpell,
                        order = 58,
                        desc = "Select the spell to be used when ctrl click key is pressed",
                        set = function(info, value)
                            addon.db.profile.dpsMacros.CtrlSpell = value
                            UpdatePlayerFrame()
                        end,
                        get = function() return addon.db.profile.dpsMacros.CtrlSpell end,
                    },

                    AltttankClickSpell = {
                        name = "Alt Tank click",
                        type = "select",
                        values = addon.db.profile.charSpell,
                        order = 59,
                        desc = "Select the spell to be used when alt click key is pressed",
                        set = function(info, value)
                            addon.db.profile.tankMacros.AltSpell = value
                            UpdatePlayerFrame()
                        end,
                        get = function() return addon.db.profile.tankMacros.AltSpell end,
                    },
                    l7 = {
                        type = 'description',
                        width = 0.15,
                        name = '',
                        order = 60,
                    },
                    AlttdpsClickSpell = {
                        name = "Alt DPS click",
                        type = "select",
                        values = addon.db.profile.charSpell,
                        order = 61,
                        desc = "Select the spell to be used when alt click key is pressed",
                        set = function(info, value)
                            addon.db.profile.dpsMacros.AltSpell = value
                            UpdatePlayerFrame()
                        end,
                        get = function() return addon.db.profile.dpsMacros.AltSpell end,
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
                            SpellListAdd(spellId)

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
                    OmniCDSupport = {
                        order = 4,
                        type = 'toggle',
                        name = "OmniCD Support",
                        desc = "If you have OmniCD installed, you can see the cooldowns of the spells you have added.",
                        get = function() return addon.db.profile.omniCDSupport end,
                        set = function(_, value)
                            if GetAddOnEnableState(UnitName('player'), 2) then -- C_AddOns_GetAddOnEnableState("OmniCD", UnitName('player'))  == 2
                                addon.db.profile.omniCDSupport = value
                                C_UI.Reload()
                            end
                        end,
                    }
                },
            },
            profiles = profiles,
        },

    }

    for k, v in pairs(GetClasses()) do
        EvokerAugOptions.args.customSpells.args.buffList.args[v.name..""..k] = {
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
    createMiniMapIcon()

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
    addonNameTexture:SetAllPoints()
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

    if addon.db.profile.omniCDSupport then
        local ofunc = OmniCD and OmniCD.AddUnitFrameData
        if ofunc then
            ofunc("EvokerAug", "EvokerAugPartyFrame", "unit", 1)
        end
    end


    -----------------------------

    if addon.db.profile.ebonmightProgressBarEnable then
        CreateProgressBar()
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
                combatRole = UnitGroupRolesAssigned(unit)
            end
            local name = GetCharacterName(fullName)

            if name and class and combatRole then
                table.insert(partyMembers, {name = name, class = strupper(string.gsub(class, "%s+", "")), role = combatRole, unit = i})-- Sınıfı da tabloya ekliyoruz
            end
        end
    else
        local name, class = UnitName("player"), UnitClass("player")
        local specializationIndex = GetSpecialization() or 0
        local _, _, _, _, combatRole, _ = GetSpecializationInfo(specializationIndex)
        table.insert(partyMembers, {name = name, class = strupper(string.gsub(class, "%s+", "")), role = combatRole, unit = 1})
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
                    DeleteSelectedPlayerFrame(member.name)
                else
                    if member.name == UnitName("player") then
                        unit = "player"
                    else
                        unit = (IsInRaid() and "raid" .. i) or (IsInGroup() and "party" .. i) or "player"
                    end
                    CreateSelectedPlayerFrame(member.name, member.class, member.role, unit, member.unit)
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
            text = 'Auto Fill (M+)',
            notCheckable = true,
            func = function()
                FrameAutoFill()
            end,
        },
        {
            text = 'Clear Frame',
            notCheckable = true,
            func = function()
                for i, frame in pairs(checkboxStates) do
                    local playerName = i
                    DeleteSelectedPlayerFrame(playerName)
                end
            end,
        },
        {
            text = 'Setting',
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
    AceConfigDialog:SetDefaultSize(addonName, 460, 750)
	if select('#', ...) > 0 then
		AceConfigDialog:Open(addonName)
		AceConfigDialog:SelectGroup(addonName, ...)
	elseif not AceConfigDialog:Close(addonName) then
		AceConfigDialog:Open(addonName)
	end
end