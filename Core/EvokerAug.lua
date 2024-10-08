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
local addonNameText
local combatLockdown = false
local isCombatButton = false
local discordLinkDialog = "EvokerAUG_General_Settings_Discord_Dialog"
local LibCustomGlow = LibStub("LibCustomGlow-1.0")
local DeadorGhostData = {}
-- Map Icon ---

---@diagnostic disable-next-line: missing-fields
local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject(addonName,
    {
        type = "launcher",
        text = addonName,
        icon = "Interface\\AddOns\\EvokerAug\\Media\\augevoker-logo",
        OnClick = function(self, btn)
            if btn == "LeftButton" then
                if not combatLockdown then
                    addon:OpenOptions()
                end
            elseif btn == "RightButton" then
                if not combatLockdown then
                    CheckShoworHide()
                end
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

AddonCompartmentFrame:RegisterAddon({
    text = addonName,
    icon = "Interface\\AddOns\\EvokerAug\\Media\\augevoker-logo",
    notCheckable = true,
    func = function()
        if not combatLockdown then
            addon:OpenOptions()
        end
    end,
})

local function sortFramesByName(a, b)
    local favList = addon.db.profile.favoriPlayer
    for i, v in ipairs(favList) do
        local playerName = GetCharacterName(v)
        if a.playerName == playerName then
            return true
        elseif b.playerName == playerName then
            return false
        end
    end
    return a.playerName < b.playerName
end

local function sortFramesByClass(a, b)
    local favList = addon.db.profile.favoriPlayer
    for i, v in ipairs(favList) do
        local playerName = GetCharacterName(v)
        if a.playerName == playerName then
            return true
        elseif b.playerName == playerName then
            return false
        end
    end
    return a.class < b.class
end

local function sortFramesByRole(a, b)
    local favList = addon.db.profile.favoriPlayer
    for i, v in ipairs(favList) do
        local playerName = GetCharacterName(v)
        if a.playerName == playerName then
            return true
        elseif b.playerName == playerName then
            return false
        end
    end
    return a.role < b.role
end

local isFound
local changelog = (addon.Config["changelog"]:gsub("^[ \t\n]*", "|cff99cdff"):gsub("\n\nv([%d%.]+)", function(ver)
    if not isFound and ver ~= addon.Config["version"] then
        isFound = true
        return "|cff808080\n\nv" .. ver
    end
end):gsub("\t", "\32\32\32\32\32\32\32\32") or "|cff808080\n\nv") .. "|r"

local sortTypes = {
    ["NAME"] = sortFramesByName,
    ["CLASS"] = sortFramesByClass,
    ["ROLE"] = sortFramesByRole,
}

-- Minimap Icon

function CheckShoworHide()
    if selectedPlayerFrameContainer and selectedPlayerFrameContainer:IsShown() then
        HideAllSubFrames()
    else
        EnableAllFrame()
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
            progressBar:SetSize(200, 20)
            progressBar:SetPoint("CENTER", selectedPlayerFrameContainer, "CENTER", 0, 20)
            progressBar:SetMinMaxValues(0, 100)
            progressBar:SetValue(0)
            progressBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
            progressBar:SetStatusBarColor(0, 1, 0)

            progressBar.text = progressBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            progressBar.text:SetPoint("CENTER", progressBar, "CENTER")
            progressBar.text:SetText("Ebon Might")
        else
            progressBar:Show()
        end


        selectedPlayerFrameContainer:SetScript("OnUpdate", function()
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
function GetCharacterName(fullName)
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
            if playerFrame["buff"][buffID].glow then
                LibCustomGlow.PixelGlow_Stop(playerFrame)
            end
            playerFrame["buff"][buffID .. "Text"].ticker:Cancel()
            playerFrame["buff"][buffID .. "Text"]:Hide()
            playerFrame["buff"][buffID .. "Text"]:ClearAllPoints()
            playerFrame["buff"][buffID .. "Text"] = nil

            playerFrame["buff"][buffID]:Hide()
            playerFrame["buff"][buffID]:ClearAllPoints()
            playerFrame["buff"][buffID]:SetParent(nil)
            playerFrame["buff"][buffID] = nil

            RepositionBuffIcons(playerFrame)
        end
    end
end

local function AddBuffIcon(playerFrame, auraInstanceID, timestamp, icon, startTimer, spellID)
    if playerFrame == nil then
        return
    end
    if playerFrame["buff"][auraInstanceID] then
        if playerFrame["buff"][auraInstanceID .. "Text"] then
            playerFrame["buff"][auraInstanceID .. "Text"].timestamp = timestamp
            playerFrame["buff"][auraInstanceID .. "Text"].starttimestamp = startTimer
        end
        return
    end
    playerFrame["buff"][auraInstanceID] = playerFrame:CreateTexture(nil, "OVERLAY")
    playerFrame["buff"][auraInstanceID].iconid = icon
    playerFrame["buff"][auraInstanceID].glow = false
    playerFrame["buff"][auraInstanceID]:SetTexture(icon)
    playerFrame["buff"][auraInstanceID]:SetSize(addon.db.profile.spellIconSize, addon.db.profile.spellIconSize)
    playerFrame["buff"][auraInstanceID]:SetPoint("LEFT", playerFrame, "RIGHT", playerFrame["buff"].xOffset, 0)
    playerFrame["buff"][auraInstanceID]:SetVertexColor(1, 1, 1, 1)
    playerFrame["buff"][auraInstanceID]:Show()
    playerFrame["buff"][auraInstanceID .. "Text"] = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerFrame["buff"][auraInstanceID .. "Text"]:SetPoint("CENTER", playerFrame["buff"][auraInstanceID], "CENTER", 0, 0)
    playerFrame["buff"][auraInstanceID .. "Text"]:SetTextColor(1, 1, 1)
    playerFrame["buff"][auraInstanceID .. "Text"]:SetFont("Fonts\\ARIALN.TTF", addon.db.profile.spellIconTextSize,
        "OUTLINE")
    playerFrame["buff"][auraInstanceID .. "Text"]:Show()
    playerFrame["buff"][auraInstanceID .. "Text"].timestamp = timestamp
    playerFrame["buff"][auraInstanceID .. "Text"].starttimestamp = startTimer
    playerFrame["buff"][auraInstanceID .. "Text"].ticker = C_Timer.NewTicker(1, function()
        if playerFrame["buff"] == nil then
            return
        end
        local duration = playerFrame["buff"][auraInstanceID .. "Text"].timestamp - GetTime()
        if addon.db.profile.prescienceBarEnable and icon == 5199639 then
            local remainingWidth = 150 * (duration / playerFrame["buff"][auraInstanceID .. "Text"].starttimestamp)
            if duration <= 0 then
                playerFrame.texture:SetSize(1, addon.db.profile.buttonHeight)
            else
                playerFrame.texture:SetSize(remainingWidth, addon.db.profile.buttonHeight)
            end
        end
        if duration > 10 then
            playerFrame["buff"][auraInstanceID .. "Text"]:SetTextColor(1, 1, 1)
        else
            playerFrame["buff"][auraInstanceID .. "Text"]:SetTextColor(1, 0, 0)
        end
        if duration <= 0 then
            playerFrame["buff"][auraInstanceID .. "Text"]:Hide()
            playerFrame["buff"][auraInstanceID .. "Text"].ticker:Cancel()
            RemoveBuffIcon(playerFrame, auraInstanceID)
        elseif duration <= 20 then
            playerFrame["buff"][auraInstanceID .. "Text"]:SetText(math.floor(duration))
        else
            playerFrame["buff"][auraInstanceID .. "Text"]:SetText(nil)
        end
    end)
    playerFrame["buff"].xOffset = playerFrame["buff"].xOffset + addon.db.profile.buttonHeight

    if spellID == 361022 then
        playerFrame["buff"][auraInstanceID].glow = true
        LibCustomGlow.PixelGlow_Start(playerFrame, { 0.95, 0.95, 0.32, 1 }, 8, 0.25, 10, 3, 0, 0, true, nil)
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
            AddBuffIcon(playerFrame, spellTable.auraInstanceID, spellTable.expirationTime, spellTable.icon,
                spellTable.duration, spellTable.spellId)
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
            frame:SetAttribute("alt-spell1", addon.db.profile.charSpell[addon.db.profile.tankMacros.AltSpell]);
        else
            frame:SetAttribute("alt-spell1", nil)
        end
        if addon.db.profile.macro.ShiftClick then
            frame:SetAttribute("shift-spell1", addon.db.profile.charSpell[addon.db.profile.tankMacros.ShiftSpell]);
        else
            frame:SetAttribute("shift-spell1", nil)
        end
        if addon.db.profile.macro.CtrlClick then
            frame:SetAttribute("ctrl-spell1", addon.db.profile.charSpell[addon.db.profile.tankMacros.CtrlSpell]);
        else
            frame:SetAttribute("ctrl-spell1", nil)
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

local function SortType()
    table.sort(selectedPlayerFrames, sortTypes[addon.db.profile.sortType])
    local tankCount = 0
    for i, frame in ipairs(selectedPlayerFrames) do
        if frame.role == "TANK" then
            tankCount = tankCount + 1
            frame:ClearAllPoints()
            local ebonMightCount = addon.db.profile.ebonmightProgressBarEnable and 20 or 0
            frame:SetPoint("TOP", selectedPlayerFrameContainer, "TOP", 0,
                ebonMightCount + (tankCount * addon.db.profile.buttonHeight))
        else
            frame:ClearAllPoints()
            frame:SetPoint("BOTTOM", selectedPlayerFrameContainer, "BOTTOM", 0,
                (i - tankCount) * -addon.db.profile.buttonHeight)
        end
    end
end

local function CreateSelectedPlayerFrame(playerName, class, PlayerRole, unitIndex, unittt)
    if combatLockdown then
        return
    end
    local frameIndex = #selectedPlayerFrames + 1
    checkboxStates[playerName] = true
    selectedPlayerFrames[frameIndex] = CreateFrame("Button", "EvokerAugPartyFrame" .. unittt, UIParent,
        BackdropTemplateMixin and "BackdropTemplate, SecureUnitButtonTemplate")
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

    selectedPlayerFrames[frameIndex]:SetAttribute('unitName', playerName)
    selectedPlayerFrames[frameIndex]:SetAttribute('unitID', unitIndex)
    selectedPlayerFrames[frameIndex]:SetAttribute("unit", unitIndex);
    selectedPlayerFrames[frameIndex]:SetAttribute("type", "spell")
    selectedPlayerFrames[frameIndex]:SetAttribute("type2", "spell")

    MacroUpdate(selectedPlayerFrames[frameIndex])

    selectedPlayerFrames[frameIndex]:SetBackdrop({
        bgFile = [=[Interface\Tooltips\UI-Tooltip-Background]=],
        insets = { top = -1, left = -1, bottom = -1, right = -1 }
    })
    local classR, classG, classB = GetClassColor(class)
    selectedPlayerFrames[frameIndex]:SetBackdropColor(classR, classG, classB, 0.9)
    selectedPlayerFrames[frameIndex].texture:SetVertexColor(classR, classG, classB, 0.9)
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


    selectedPlayerFrames[frameIndex].playerNameText = selectedPlayerFrames[frameIndex]:CreateFontString(nil, "OVERLAY",
        "GameFontHighlight")
    selectedPlayerFrames[frameIndex].playerNameText:SetPoint("CENTER", selectedPlayerFrames[frameIndex], "CENTER", 0, 0)
    selectedPlayerFrames[frameIndex].playerNameText:SetText(playerName)
    selectedPlayerFrames[frameIndex].playerNameText:SetJustifyH("CENTER")
    selectedPlayerFrames[frameIndex].playerNameText:SetJustifyV("MIDDLE")

    SortType()

    if distanceTimer == nil then
        distanceTimer = C_Timer.NewTicker(1, UpdateDistance)
    end
end

local function GetPlayerFrameIndexByUnit(unit)
    for i, frame in ipairs(selectedPlayerFrames) do
        if frame.unit == unit then
            return i
        end
    end
    return nil
end

local function GetPlayerFrameIndexByName(name)
    for i, frame in ipairs(selectedPlayerFrames) do
        if frame.playerName == name then
            return i
        end
    end
    return nil
end

local function IsPlayerFrameByName(name)
    for i, frame in ipairs(selectedPlayerFrames) do
        if frame.playerName == name then
            return true
        end
    end
    return false
end

local function DeleteSelectedPlayerFrame(playerName)
    local playerIndex = GetPlayerFrameIndexByName(playerName)
    if playerIndex and selectedPlayerFrames[playerIndex] then
        selectedPlayerFrames[playerIndex]:Hide()
        selectedPlayerFrames[playerIndex]:ClearAllPoints()
        selectedPlayerFrames[playerIndex]:SetParent(nil)
        table.remove(selectedPlayerFrames, playerIndex)
        checkboxStates[playerName] = false
        SortType()
    end

    if #selectedPlayerFrames == 0 then
        if distanceTimer then
            distanceTimer:Cancel()
            distanceTimer = nil
        end
    end
end

local function AddFrameFavorite()
    --- Favorite Check
    local in_group = IsInGroup() or IsInRaid()
    if in_group then
        for i = 1, GetNumGroupMembers() do
            local unitID = (IsInRaid() and "raid" .. i) or (IsInGroup() and "party" .. i) or "player"
            local fullName, realm = UnitName(unitID)
            if fullName then
                local class = UnitClass(unitID)
                if not realm then
                    realm = GetRealmName()
                    fullName = fullName .. "-" .. realm
                end
                if fullName and class then
                    local isFav = IsFavorite(fullName)
                    if isFav then
                        local combatRole = UnitGroupRolesAssigned(unitID)
                        local name = GetCharacterName(fullName)
                        if combatRole == "DAMAGER" then
                            combatRole = "DPS"
                        end
                        if name and class and combatRole and not IsPlayerFrameByName(name) then
                            class = strupper(string.gsub(class, "%s+", ""))
                            CreateSelectedPlayerFrame(name, class, combatRole, unitID, unitID)
                        end
                    end
                end
            end
        end
    end
end

local function FrameAutoFill()
    if combatLockdown then
        isCombatButton = true
        addonNameText:SetText(addonName .. " (Waiting for combat to end)")
        return
    end
    local partyMembers = GetHomePartyInfos()
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
    local partyMembers = GetHomePartyInfos()

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
end

local function GetClasses()
    local Augment = {}
    for k, v in pairs(AllSpellList["Augmentation"]) do
        local spell = C_Spell.GetSpellInfo(k)
        Augment[k] = { icon = spell.iconID, name = spell.name }
    end

    return Augment
end

local function SpellListAdd(spellId)
    if spellId then
        local Spell = C_Spell.GetSpellInfo(spellId)
        if Spell and Spell.name and not addon.db.profile.buffList[spellId] then
            EvokerAugOptions.args.customSpells.args.buffList.args[Spell.name .. "" .. spellId] = {
                order = spellId,
                type = 'toggle',
                name = Spell.iconID,
                imageCoords = { 0.07, 0.93, 0.07, 0.93 },
                image = icon,
                arg = spellId,
                set = function(_, value)
                    if value then
                        addon.db.profile.buffList[spellId] = Spell.name
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
    local favList = addon.db.profile.favoriPlayer
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
                args = {
                    evokerAug = {
                        order = 0,
                        image = "Interface\\Addons\\EvokerAug\\Media\\augevoker-logo",
                        imageWidth = 64,
                        imageHeight = 64,
                        imageCoords = { 0, 1, 0, 1 },
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
                        name = "|cffffff00 Discord |r |cff00ff00 https://discord.gg/D9jb6zwn3j |r",
                        order = 3,
                        type = "description",
                    },
                    discordcopy = {
                        type = "execute",
                        name = "Join the Discord",
                        order = 4,
                        func = function()
                            StaticPopup_Show(discordLinkDialog)
                            addon:OpenOptions()
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
                            SortType()
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
                        min = 20,
                        max = 40,
                        step = 1,
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
                                    frame:SetPoint("TOP", selectedPlayerFrameContainer, "TOP", 0,
                                        tank * addon.db.profile.buttonHeight)
                                else
                                    local dpsCheck = i - tank
                                    frame:SetPoint("BOTTOM", selectedPlayerFrameContainer, "BOTTOM", 0,
                                        dpsCheck * -addon.db.profile.buttonHeight)
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
                        min = 20,
                        max = 40,
                        step = 1,
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
                        min = 12,
                        max = 20,
                        step = 1,
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
                        name = "UnLock Frame",
                        desc = "Unlock the frame to move it",
                        get = function()
                            return
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
                        desc = "Hide the frame",
                        get = function()
                            if not selectedPlayerFrameContainer then
                                return false
                            end
                            return selectedPlayerFrameContainer:IsShown()
                        end,
                        set = function(info, value)
                            HideAllSubFrames()
                        end,
                    },
                    autoFrame = {
                        order = 20,
                        type = 'toggle',
                        name = "Auto Frame Fill",
                        desc =
                        "When you enter the dungeon, it will automatically fill the frame and delete it when you exit.",
                        get = function()
                            return addon.db.profile.autoFrameFill
                        end,
                        set = function(info, value)
                            if value then
                                selectedPlayerFrameContainer:RegisterEvent("PLAYER_ENTERING_WORLD")
                            else
                                selectedPlayerFrameContainer:UnregisterEvent("PLAYER_ENTERING_WORLD")
                            end
                            addon.db.profile.autoFrameFill = value
                        end,
                    },
                    raid = {
                        order = 21,
                        type = 'toggle',
                        name = "Show Raid",
                        desc = "Show Raid",
                        get = function()
                            return addon.db.profile.showRaid
                        end,
                        set = function(info, value)
                            addon.db.profile.showRaid = value
                        end,
                    },
                    mythic = {
                        order = 21,
                        type = 'toggle',
                        name = "Show Mythic+",
                        desc = "Show Mythic+",
                        get = function()
                            return addon.db.profile.showMythic
                        end,
                        set = function(info, value)
                            addon.db.profile.showMythic = value
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
                        get = function()
                            return
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
                        get = function()
                            return
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
            favPlayerList = {
                order = 3,
                name = "Favorite Player List",
                type = "group",
                args = {
                    h1 = {
                        type = 'header',
                        name = 'Favorite Player List',
                        order = 1,
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
                            local state = C_AddOns.GetAddOnEnableState("OmniCD", UnitName('player'))
                            if state == 2 then
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
        EvokerAugOptions.args.customSpells.args.buffList.args[v.name .. "" .. k] = {
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

    orderNumber = 2
    for k, v in pairs(favList) do
        EvokerAugOptions.args.favPlayerList.args[v .. "" .. k] = {
            order = orderNumber,
            type = 'toggle',
            name = v,
            arg = k,
            set = function(_, value)
                if value then
                    addon.db.profile.favoriPlayer[k] = v
                else
                    addon.db.profile.favoriPlayer[k] = nil
                end
            end,
            get = function()
                return addon.db.profile.favoriPlayer[k] ~= nil
            end,
        }

        orderNumber = orderNumber + 1
    end

    return EvokerAugOptions
end

function addon:OnInitialize()
    self.db = LibStub('AceDB-3.0'):New(addonName .. "DB", self.DefaultProfile, true)
    self.db.RegisterCallback(self, "OnProfileReset", "Reconfigure")
    self:RegisterChatCommand("aug", function(cmd)
        addon:OpenOptions(strsplit(' ', cmd or ""))
    end, true)
    createMiniMapIcon()

    StaticPopupDialogs[discordLinkDialog] = {
        text = "CTRL+C to copy",
        button1 = "Done",
        hasEditBox = true,
        OnShow = function(dialog)
            local function HidePopup()
                dialog:Hide();
            end
            dialog.editBox:SetScript("OnEscapePressed", HidePopup)
            dialog.editBox:SetScript("OnKeyUp", function(_, key)
                if IsControlKeyDown() and key == "C" then
                    HidePopup()
                end
            end)
            dialog.editBox:SetText("https://discord.gg/D9jb6zwn3j")
            dialog.editBox:SetFocus()
            dialog.editBox:HighlightText()
        end,
        OnHide = function() addon:OpenOptions() end,
        editBoxWidth = 230,
        timeout = 0,
        hideOnEscape = true,
        whileDead = true,
    }
end

function addon:OnEnable() -- PLAYER_LOGIN
    local lib = LibStub("LibSharedMedia-3.0")
    lib:Register(lib.MediaType.STATUSBAR, "EvokerAug", [[Interface\AddOns\EvokerAug\Media\bar]])

    selectedPlayerFrameContainer = CreateFrame("Frame", "EvokerAug", UIParent,
        BackdropTemplateMixin and "BackdropTemplate")
    selectedPlayerFrameContainer:SetPoint(self.db.profile.positions.point, self.db.profile.positions.xOffset,
        self.db.profile.positions.yOffset)
    selectedPlayerFrameContainer:SetSize(200, 20)
    selectedPlayerFrameContainer:SetMovable(true)
    selectedPlayerFrameContainer:EnableMouse(true)
    selectedPlayerFrameContainer:RegisterForDrag("LeftButton")
    selectedPlayerFrameContainer:RegisterEvent("GROUP_ROSTER_UPDATE")
    selectedPlayerFrameContainer:RegisterEvent("PLAYER_REGEN_ENABLED")
    selectedPlayerFrameContainer:RegisterEvent("PLAYER_REGEN_DISABLED")
    selectedPlayerFrameContainer:RegisterEvent("UNIT_AURA")
    selectedPlayerFrameContainer:RegisterEvent("UNIT_FLAGS")
    selectedPlayerFrameContainer:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    if addon.db.profile.autoFrameFill then
        selectedPlayerFrameContainer:RegisterEvent("PLAYER_ENTERING_WORLD")
    end

    local addonNameTexture = selectedPlayerFrameContainer:CreateTexture(nil, "OVERLAY")
    addonNameTexture:SetAllPoints()
    addonNameTexture:SetTexture("Interface\\Addons\\EvokerAug\\Media\\bar")
    addonNameTexture:SetVertexColor(0.24, 0.24, 0.24, 1.0)

    addonNameText = selectedPlayerFrameContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    addonNameText:SetPoint("CENTER", selectedPlayerFrameContainer, "CENTER", 0, 0)
    addonNameText:SetText(addonName)
    addonNameText:SetJustifyH("CENTER")
    addonNameText:SetJustifyV("MIDDLE")

    selectedPlayerFrameContainer:SetScript("OnDragStart", function(sel)
        if self.db.profile.headerunlock then
            sel:StartMoving()
        end
    end)

    selectedPlayerFrameContainer:SetScript("OnDragStop", function(sel)
        sel:StopMovingOrSizing()
        local x, _, _, l, p = selectedPlayerFrameContainer:GetPoint()
        self.db.profile.positions.point = x
        self.db.profile.positions.xOffset = l
        self.db.profile.positions.yOffset = p
    end)

    selectedPlayerFrameContainer:SetScript("OnEvent", function(self, event, unit, info)
        if event == "GROUP_ROSTER_UPDATE" then
            GroupUpdate()
            --- Favorite Check
            AddFrameFavorite()
        elseif event == "PLAYER_REGEN_DISABLED" then
            combatLockdown = true
        elseif event == "PLAYER_REGEN_ENABLED" then
            combatLockdown = false
            if isCombatButton then
                addonNameText:SetText(addonName)
                isCombatButton = false
                FrameAutoFill()
            end
        elseif event == "PLAYER_ENTERING_WORLD" then
            if addon.db.profile.autoFrameFill then
                local _, instanceType = IsInInstance()
                if instanceType == "party" then
                    C_Timer.After(4.5, function()
                        local size = GetNumGroupMembers()
                        if size > 0 then
                            FrameAutoFill()
                        end
                    end)
                elseif instanceType == "none" then
                    C_Timer.After(4.5, function()
                        for i, frame in pairs(checkboxStates) do
                            DeleteSelectedPlayerFrame(i)
                        end
                    end)
                end
            end
            if not addon.db.profile.showRaid then
                local _, instanceType = IsInInstance()
                if instanceType == "raid" then
                    for i, frame in pairs(checkboxStates) do
                        DeleteSelectedPlayerFrame(i)
                    end
                    HideAllSubFrames()
                end
            elseif not addon.db.profile.showMythic then
                local _, instanceType = IsInInstance()
                if instanceType == "party" then
                    for i, frame in pairs(checkboxStates) do
                        DeleteSelectedPlayerFrame(i)
                    end
                    HideAllSubFrames()
                end
            end
        elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
            if unit == "player" then
                local currentSpec = GetSpecialization()
                if currentSpec then
                    if currentSpec ~= 3 then
                        HideAllSubFrames()
                    else
                        EnableAllFrame()
                    end
                end
            end
        elseif event == "UNIT_AURA" then
            if info == nil then
                return
            end
            local frameIndex = GetPlayerFrameIndexByUnit(unit)
            if info.addedAuras and #info.addedAuras > 0 and selectedPlayerFrames[frameIndex] then
                for _, v in ipairs(info.addedAuras) do
                    if addon.db.profile.buffList[v.spellId] then
                        if v.expirationTime > 0 and selectedPlayerFrames[frameIndex] then
                            AddBuffIcon(selectedPlayerFrames[frameIndex], v.auraInstanceID, v.expirationTime, v.icon,
                                v.duration, v.spellId)
                        end
                    end
                end
            end
            if info.updatedAuraInstanceIDs and #info.updatedAuraInstanceIDs > 0 and selectedPlayerFrames[frameIndex] then
                for _, v in ipairs(info.updatedAuraInstanceIDs) do
                    local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, v)
                    if aura and addon.db.profile.buffList[aura.spellId] then
                        if aura.expirationTime > 0 then
                            AddBuffIcon(selectedPlayerFrames[frameIndex], aura.auraInstanceID, aura.expirationTime,
                                aura.icon, aura.duration, aura.spellId)
                        end
                    end
                end
            end
            if info.removedAuraInstanceIDs and #info.removedAuraInstanceIDs > 0 and selectedPlayerFrames[frameIndex] then
                for _, instance in ipairs(info.removedAuraInstanceIDs) do
                    RemoveBuffIcon(selectedPlayerFrames[frameIndex], instance)
                end
            end
        elseif event == "UNIT_FLAGS" then
            if unit ~= "player" then
                local isDeadOrGhost = UnitIsDeadOrGhost(unit)
                if isDeadOrGhost then
                    local frameIndex = GetPlayerFrameIndexByUnit(unit)
                    if selectedPlayerFrames[frameIndex] then
                        local frame = selectedPlayerFrames[frameIndex]
                        DeadorGhostData[unit] = true
                        frame:SetBackdropColor(0.5, 0.5, 0.5, 0.5)
                        frame.texture:SetVertexColor(0.5, 0.5, 0.5, 0.5)
                        frame.playerNameText:SetText(frame.playerName .. " (Dead)")
                    end
                elseif DeadorGhostData[unit] then
                    local frameIndex = GetPlayerFrameIndexByUnit(unit)
                    if selectedPlayerFrames[frameIndex] then
                        local frame = selectedPlayerFrames[frameIndex]
                        local clasxs = frame.class
                        local classR, classG, classB = GetClassColor(clasxs)
                        frame:SetBackdropColor(classR, classG, classB, 0.9)
                        frame.texture:SetVertexColor(classR, classG, classB, 0.9)
                        frame.playerNameText:SetText(frame.playerName)
                        DeadorGhostData[unit] = nil
                    end
                end
            end
        end
    end)

    selectedPlayerFrameContainer:SetScript("OnMouseUp", function(sel, button)
        if button == "RightButton" then
            MenuUtil.CreateContextMenu(UIParent, RightMenu)
        elseif button == "LeftButton" then
            addon:OpenOptions()
        end
    end)

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

    local class = select(2, UnitClass("player"))
    if class ~= "EVOKER" then
        HideAllSubFrames()
    else
        local currentSpec = GetSpecialization()
        if currentSpec then
            if currentSpec ~= 3 then
                HideAllSubFrames()
            else
                AddFrameFavorite()
            end
        end

        AddItemsWithMenu()
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
            local playerIndex = i
            selectedPlayerFrames[playerIndex]:Hide()
            selectedPlayerFrames[playerIndex]:ClearAllPoints()
            selectedPlayerFrames[playerIndex]:SetParent(nil)
            table.remove(selectedPlayerFrames, playerIndex)
            break
        end
    end
    checkboxStates = {}
    selectedPlayerFrames = {}
    selectedPlayerFrameContainer:ClearAllPoints()
    selectedPlayerFrameContainer:SetPoint(self.db.profile.positions.point, self.db.profile.positions.xOffset,
        self.db.profile.positions.yOffset)
end

function GetHomePartyInfos()
    local partyMembers = {}
    local in_group = IsInGroup() or IsInRaid()
    if in_group then
        for i = 1, GetNumGroupMembers() do
            local unit = (IsInRaid() and "raid" .. i) or (IsInGroup() and "party" .. i) or "player"
            local fullName, class = UnitName(unit), UnitClass(unit)
            if fullName == nil then
                unit = "player"
                fullName, class = UnitName(unit), UnitClass(unit)
            end
            local combatRole = UnitGroupRolesAssigned(unit)
            local name = GetCharacterName(fullName)
            if combatRole == "DAMAGER" then
                combatRole = "DPS"
            end
            if name and class and combatRole then
                table.insert(partyMembers,
                    { name = name, class = strupper(string.gsub(class, "%s+", "")), role = combatRole, unit = i })
            end
        end
    else
        local name, class = UnitName("player"), UnitClass("player")
        local specializationIndex = GetSpecialization() or 0
        local _, _, _, _, combatRole, _ = GetSpecializationInfo(specializationIndex)
        if combatRole == "DAMAGER" then
            combatRole = "DPS"
        end
        table.insert(partyMembers,
            { name = name, class = strupper(string.gsub(class, "%s+", "")), role = combatRole, unit = 1 })
    end

    return partyMembers
end

function RightMenu(owner, MenuDesc)
    MenuDesc:SetTag("AUGEVOKER_RIGHT_MENU");
    local PartyList = {}
    local partyMembers = GetHomePartyInfos()

    for i, member in ipairs(partyMembers) do
        table.insert(PartyList, {
            text = member.name .. ' (' .. member.role .. ')',
            checked = function() return checkboxStates[member.name] end,
            func = function(xxxx, arg1, arg2)
                if checkboxStates[member.name] then
                    DeleteSelectedPlayerFrame(member.name)
                else
                    local unit = nil
                    if member.name == UnitName("player") then
                        unit = "player"
                    else
                        unit = (IsInRaid() and "raid" .. i) or (IsInGroup() and "party" .. i) or "player"
                    end
                    CreateSelectedPlayerFrame(member.name, member.class, member.role, unit, member.unit)
                end
            end,
            index = i,
        })
    end

    MenuDesc:CreateTitle(addonName)
    local party = MenuDesc:CreateButton("Party members")
    for i, v in ipairs(PartyList) do
        party:CreateCheckbox(v.text, v.checked, v.func, v.index)
    end
    MenuDesc:CreateButton('Auto Fill (M+)', function() FrameAutoFill() end)
    MenuDesc:CreateButton('Clear Frame', function()
        for i, frame in pairs(checkboxStates) do
            local playerName = i
            DeleteSelectedPlayerFrame(playerName)
        end
    end)
    MenuDesc:CreateDivider()
    MenuDesc:CreateTitle('Setting')
    MenuDesc:CreateButton('Setting panel', function() addon:OpenOptions() end)

    local function IsSelected()
        return addon.db.profile.headerunlock;
    end
    local function SetSelected()
        addon.db.profile.headerunlock = not addon.db.profile.headerunlock
    end
    MenuDesc:CreateCheckbox('Unlock Frame', IsSelected, SetSelected)
end

LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, GetOptions)
function addon:OpenOptions(...)
    if not combatLockdown then
        AceConfigDialog:SetDefaultSize(addonName, 460, 750)
        if select('#', ...) > 0 then
            AceConfigDialog:Open(addonName)
            AceConfigDialog:SelectGroup(addonName, ...)
        elseif not AceConfigDialog:Close(addonName) then
            AceConfigDialog:Open(addonName)
        end
    end
end

function HideAllSubFrames()
    for i, frame in pairs(selectedPlayerFrames) do
        frame:Hide()
    end
    selectedPlayerFrameContainer:Hide()
    addonNameText:Hide()
    if progressBar then
        progressBar:Hide()
        progressBar.text:Hide()
    end
end

function EnableAllFrame()
    for i, frame in pairs(selectedPlayerFrames) do
        frame:Show()
    end
    if selectedPlayerFrameContainer then
        selectedPlayerFrameContainer:Show()
    end
    addonNameText:Show()
    if progressBar then
        progressBar:Show()
        progressBar.text:Show()
    end
end

function IsFavorite(name)
    local favList = addon.db.profile.favoriPlayer
    for i, v in ipairs(favList) do
        if v == name then
            return true
        end
    end
    return false
end

function MenuHandler(owner, rootDescription, contextData)
    local name = contextData.name
    if not contextData.server then
        name = name .. "-" .. GetRealmName()
    else
        name = name .. "-" .. contextData.server
    end
    rootDescription:CreateDivider();
    rootDescription:CreateTitle("EvokerAug");
    local text = IsFavorite(name) and "Remove from Favorite" or "Add to favorite"
    rootDescription:CreateButton(text, function()
        if not IsFavorite(name) then
            table.insert(addon.db.profile.favoriPlayer, name)
        else
            for i, v in ipairs(addon.db.profile.favoriPlayer) do
                if v == name then
                    table.remove(addon.db.profile.favoriPlayer, i)
                end
            end
        end
    end)
end

function AddItemsWithMenu()
    if not Menu or not Menu.ModifyMenu then return end

    local menuTags = {
        ["MENU_UNIT_PLAYER"] = true,
        ["MENU_UNIT_ENEMY_PLAYER"] = true,
        ["MENU_UNIT_PARTY"] = true,
        ["MENU_UNIT_RAID_PLAYER"] = true,
        ["MENU_UNIT_FRIEND"] = true,
        ["MENU_UNIT_COMMUNITIES_GUILD_MEMBER"] = true,
        ["MENU_UNIT_COMMUNITIES_MEMBER"] = true,
        ["MENU_LFG_FRAME_SEARCH_ENTRY"] = true,
        ["MENU_LFG_FRAME_MEMBER_APPLY"] = true,
    }

    for tag, enabled in pairs(menuTags) do
        if enabled then
            Menu.ModifyMenu(tag, MenuHandler)
        end
    end
end
