VGAC_BuffInfo = {
	-- Debugging
	["Frost Armor"] = {icon = "Interface\\Icons\\Spell_Frost_FrostArmor02", duration = 1800, priority = 0},

	["Blessing of Protection"] = {icon = "Interface\\Icons\\Spell_Holy_SealOfProtection", duration = 10, priority = 0},
	["Free Action"] = {icon = "Interface\\Icons\\INV_Potion_04", duration = 30, priority = 0},
	["Invulnerability"] = {icon = "Interface\\Icons\\INV_Potion_62", duration = 6, priority = 0},
	["Blessing of Freedom"] = {icon = "Interface\\Icons\\Spell_Holy_SealOfValor", duration = 16, priority = 0},
	["Living Free Action"] = {icon = "Interface\\Icons\\INV_Potion_07", duration = 5, priority = 0},

	["Power Word: Shield"] = {icon = "Interface\\Icons\\Spell_Holy_PowerWordShield", duration = 30, priority = 1},
	["Ice Barrier"] = {icon = "Interface\\Icons\\Spell_Ice_Lament", duration = 60, priority = 1},
	["Sacrifice"] = {icon = "Interface\\Icons\\Spell_Shadow_SacrificialShield", duration = 30, priority = 1},
	["Fear Ward"] = {icon = "Interface\\Icons\\Spell_Holy_Excorcism", duration = 600, priority = 1},
	["Mana Shield"] = {icon = "Interface\\Icons\\Spell_Shadow_DetectLesserInvisibility", duration = 60, priority = 1},

	["Arcane Power"] = {icon = "Interface\\Icons\\Spell_Nature_Lightning", duration = 15, priority = 2},
	["Power Infusion"] = {icon = "Interface\\Icons\\Spell_Holy_PowerInfusion", duration = 15, priority = 2},
	["Rapid Fire"] = {icon = "Interface\\Icons\\Ability_Hunter_RunningShot", duration = 15, priority = 2},

	["Restoration"] = {icon = "Interface\\Icons\\INV_Potion_01", duration = 30, priority = 3},
	["Arcane Protection"] = {icon = "Interface\\Icons\\INV_Potion_83", duration = 3600, priority = 3},
	["Fire Protection"] = {icon = "Interface\\Icons\\INV_Potion_24", duration = 3600, priority = 3},
	["Frost Protection"] = {icon = "Interface\\Icons\\INV_Potion_20", duration = 3600, priority = 3},
	["Nature Protection"] = {icon = "Interface\\Icons\\INV_Potion_22", duration = 3600, priority = 3},
	["Shadow Protection"] = {icon = "Interface\\Icons\\INV_Potion_23", duration = 3600, priority = 3},

	["Speed"] = {icon = "Interface\\Icons\\INV_Potion_19", duration = 15, priority = 4},
	["Barkskin"] = {icon = "Interface\\Icons\\Spell_Nature_StoneClawTotem", duration = 15, priority = 4},
	["Innervate"] = {icon = "Interface\\Icons\\Spell_Nature_Lightning", duration = 20, priority = 4},
	["Abolish Poison"] = {icon = "Interface\\Icons\\Spell_Nature_NullifyPoison_02", duration = 8, priority = 4},
	["Blessing of Sacrifice"] = {icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice", duration = 30, priority = 4},
	["Clearcasting"] = {icon = "Interface\\Icons\\Spell_Shadow_ManaBurn", duration = 15, priority = 4},

	-- ["Nature's Swiftness"] = {icon = "Interface\\Icons\\Spell_Nature_RavenForm", duration = -1, priority = -1},
	-- ["Divine Favor"] = {icon = "Interface\\Icons\\Spell_Holy_Heal", duration = -1, priority = -1},
	-- ["Presence of Mind"] = {icon = "Interface\\Icons\\Spell_Nature_EnchantArmor", duration = -1, priority = -1},
	-- ["Combustion"] = {icon = "Interface\\Icons\\Spell_Fire_SealOfFire", duration = -1, priority = -1},
}
VGAC_defaultConfig = {x = 0, y = 0, isUnlocked = true, scale = 1.0, defaultHeight = 50, defaultWidth = 50, defaultTextSize = 16, numSlots = 15}

VGAC_UpdateInterval = 0.05
VGAC_LastUpdate = GetTime()
VGAC_ActiveBuffs = nil
VGAC_NumActiveBuffs = 0
VGAC_GroupLevel = 0 -- Not in a group: 0; In a party: 1; In a raid group: 2
VGAC_RecentTargets = {}

VanguardAntiCooldownFrame = CreateFrame("Frame", nil, UIParent)
VanguardAntiCooldownFrame:RegisterEvent("VARIABLES_LOADED")
VanguardAntiCooldownFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- VanguardAntiCooldownFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE") -- You cast Purge on blabla.
VanguardAntiCooldownFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS")
VanguardAntiCooldownFrame:RegisterEvent("CHAT_MSG_SPELL_BREAK_AURA")
VanguardAntiCooldownFrame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
VanguardAntiCooldownFrame:RegisterEvent("CHAT_MSG_ADDON")
VanguardAntiCooldownFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
VanguardAntiCooldownFrame:RegisterEvent("RAID_ROSTER_UPDATE")
VanguardAntiCooldownFrame.Tooltip = CreateFrame("GameTooltip", "VGACTooltip", nil, "GameTooltipTemplate")
VanguardAntiCooldownFrame.Tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

VGAC_Bars = nil

function VGAC_OnDragStart()
	if (VGACConfig.isUnlocked == true) then
		VGAC_Bars.mainFrame:StartMoving()
	end
end

function VGAC_OnDragStop()
	VGAC_Bars.mainFrame:StopMovingOrSizing()
	VGACConfig.x = VGAC_Bars.mainFrame:GetLeft()
	VGACConfig.y = VGAC_Bars.mainFrame:GetBottom()
end

function VGAC_SecondsToTime(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds - m * 60
	if (m > 0) then
		if (s < 10) then
			s = "0"..s
		end
		return m..":"..s
	else
		return s
	end
end

function VGAC_InitializeBars()
	if (VGAC_Bars == nil) then VGAC_Bars = {} end
	if (VGAC_Bars.mainFrame ~= nil) then VGAC_Bars.mainFrame = CreateFrame("Frame", nil, UIParent) end
	VGAC_Bars.mainFrame = CreateFrame("Frame", nil, UIParent)
	VGAC_Bars.mainFrame:SetPoint("BOTTOMLEFT", VGACConfig.x, VGACConfig.y)
	VGAC_Bars.mainFrame:SetWidth(VGACConfig.numSlots * VGACConfig.defaultWidth)
	VGAC_Bars.mainFrame:SetHeight(VGACConfig.defaultHeight * 1.2)
	VGAC_Bars.mainFrame:SetBackdrop({bgFile = "Interface/RaidFrame/UI-RaidFrame-GroupBg", tile = true, tileSize = VGACConfig.defaultHeight})
	VGAC_Bars.mainFrame:RegisterForDrag("LeftButton")
	VGAC_Bars.mainFrame:SetScript("OnDragStart", function() VGAC_OnDragStart() end)
	VGAC_Bars.mainFrame:SetScript("OnDragStop", function() VGAC_OnDragStop() end)
	VGAC_Bars.mainFrame:SetAlpha(0)
	VGAC_Bars.mainFrame:EnableMouse(false)

	VGAC_Bars.BuffFrames = {}
	for i = 1, VGACConfig.numSlots do
		VGAC_Bars.BuffFrames[i] = CreateFrame("Frame", nil, VGAC_Bars.mainFrame)
		local frame = VGAC_Bars.BuffFrames[i]
		frame:SetPoint("TOPLEFT", VGACConfig.defaultWidth * (i - 1), 0)
		frame:SetWidth(VGACConfig.defaultWidth)
		frame:SetHeight(VGACConfig.defaultHeight * 1.2)
		frame:SetBackdrop({edgeFile = "Interface/DialogFrame/UI-DialogBox-Border", edgeSize = "10", tile = true})

		frame.auraName = "None"

		frame.texture = frame:CreateTexture(nil, "BACKGROUND")
		local texture = frame.texture
		texture:SetPoint("TOPLEFT", 0, 0);
		texture:SetHeight(VGACConfig.defaultHeight)
		texture:SetWidth(VGACConfig.defaultWidth)
		texture:SetTexture("Interface\\Icons\\Spell_Holy_SealOfValor")
		
		frame.timer = frame:CreateFontString(nil, "ARTWORK")
		local timer = frame.timer
		timer:SetAllPoints(frame)
		timer:SetShadowColor(0, 0, 0, 1.0)
		timer:SetShadowOffset(0.80, -0.80)
		timer:SetFont("Fonts\\FRIZQT__.TTF", VGACConfig.defaultTextSize, "OUTLINE")
		timer:SetText(VGAC_SecondsToTime(0))
		timer:SetTextColor(1, 1, 1)

		frame.buffOwner = frame:CreateFontString(nil, "ARTWORK")
		local buffOwner = frame.buffOwner
		buffOwner:SetPoint("BOTTOMLEFT", 3, 3);
		buffOwner:SetHeight(VGACConfig.defaultHeight * 0.2)
		buffOwner:SetWidth(VGACConfig.defaultWidth - 6)
		buffOwner:SetShadowColor(0, 0, 0, 1.0)
		buffOwner:SetShadowOffset(0.80, -0.80)
		buffOwner:SetFont("Fonts\\FRIZQT__.TTF", VGACConfig.defaultTextSize * 0.6, "OUTLINE")
		buffOwner:SetText("None")
		buffOwner:SetTextColor(1, 1, 1)
	end
	if (VGACConfig.scale ~= 1.0) then
		VGAC_UpdateScale()
	end
	if (VGACConfig.isUnlocked == true) then
		VGACConfig.isUnlocked = false
		VGAC_SlashCommand("move")
	end
end

function VGAC_PurgeHostile()
	_,playerClass = UnitClass("player")
	local spellName = "None"
	if (playerClass == "PRIEST") then
		spellName = "Dispel Magic"
	elseif (playerClass == "SHAMAN") then
		spellName = "Purge"
	else
		return
	end
	VGAC_PurgeTargets = {}
	VGAC_BucketSize = {}
	local s = 100
	local e = -100
	-- Find all candidate targets
	for buffOwner, val in pairs(VGAC_ActiveBuffs) do
		if (VGAC_RecentTargets[buffOwner] == nil) then
			local minPriority = 100
			for auraName, entry in pairs(VGAC_ActiveBuffs[buffOwner]) do
				if (entry.priority < minPriority) then minPriority = entry.priority end
			end
			if (minPriority < 100) then
				if (VGAC_BucketSize[minPriority] == nil) then
					VGAC_BucketSize[minPriority] = 0
					VGAC_PurgeTargets[minPriority] = {}
				end
				local n = VGAC_BucketSize[minPriority] + 1
				VGAC_PurgeTargets[minPriority][n] = buffOwner
				VGAC_BucketSize[minPriority] = n
				if (s > minPriority) then s = minPriority end
				if (e < minPriority) then e = minPriority end
			end
		end
	end
	-- Try to purge in order of priority
	-- local scStatus = GetCVar("autoSelfCast")
	-- SetCVar("autoSelfCast", 0)
	for i = s, e do
		if (VGAC_PurgeTargets[i] ~= nil) then
			for j = 1, VGAC_BucketSize[i] do
				local buffOwner = VGAC_PurgeTargets[i][j]
				TargetByName(buffOwner, true)
				if (UnitExists("target") and UnitIsEnemy("player", "target") and UnitName("target") == buffOwner) then
					if (CheckInteractDistance("target", 4)) then
						CastSpellByName(spellName)
						VGAC_RecentTargets[buffOwner] = GetTime()
						return
					end
				end
			end
		end
	end
	-- SetCVar("autoSelfCast", scStatus)
end

function VGAC_AddBuff(buffOwner, auraName, castBefore)
	if (VGAC_BuffInfo[auraName] == nil) then return end
	local skipUpdate = false
	if (VGAC_ActiveBuffs == nil) then VGAC_ActiveBuffs = {} end
	if (VGAC_ActiveBuffs[buffOwner] == nil) then VGAC_ActiveBuffs[buffOwner] = {} end
	if (VGAC_ActiveBuffs[buffOwner][auraName] ~= nil) then
		skipUpdate = true -- We already have this buff tracked, and it only needs its duration refreshed
	end
	VGAC_ActiveBuffs[buffOwner][auraName] = {duration = VGAC_BuffInfo[auraName].duration, castAt = GetTime() - tonumber(castBefore), priority = VGAC_BuffInfo[auraName].priority}

	if (skipUpdate == false) then -- the buff is new and your bars need updating
		VGAC_UpdateTrackedBuffs()
	end
end

function VGAC_UpdateTrackedBuffs()
	local VGAC_BuffCheck = {}
	if (VGAC_ActiveBuffs == nil) then VGAC_ActiveBuffs = {} end
	-- Check if your currently displayed buffs need to be removed (someone else purged them)
	local n = 0
	for i = 1, VGAC_NumActiveBuffs do
		local buffOwner = VGAC_Bars.BuffFrames[i].buffOwner:GetText()
		local auraName = VGAC_Bars.BuffFrames[i].auraName

		if (VGAC_ActiveBuffs[buffOwner] ~= nil and VGAC_ActiveBuffs[buffOwner][auraName] ~= nil) then -- The displayed buff is still present
			n = n + 1
			VGAC_Bars.BuffFrames[n].auraName = auraName
			VGAC_Bars.BuffFrames[n].texture:SetTexture(VGAC_BuffInfo[auraName].icon)
			VGAC_Bars.BuffFrames[n].timer:SetText(VGAC_Bars.BuffFrames[i].timer:GetText())
			VGAC_Bars.BuffFrames[n].buffOwner:SetText(buffOwner)
			VGAC_Bars.BuffFrames[n]:Show()
			if (VGAC_BuffCheck[buffOwner] == nil) then VGAC_BuffCheck[buffOwner] = {} end
			VGAC_BuffCheck[buffOwner][auraName] = true
		end
	end
	-- Hide the frames for removed buffs
	for i = n + 1, VGAC_NumActiveBuffs do
		VGAC_Bars.BuffFrames[i]:Hide()
	end
	VGAC_NumActiveBuffs = n
	-- Check if additional buffs need to be displayed
	for buffOwner, val in pairs(VGAC_ActiveBuffs) do
		for auraName, entry in pairs(VGAC_ActiveBuffs[buffOwner]) do
			if (VGAC_BuffCheck == nil or VGAC_BuffCheck[buffOwner] == nil or VGAC_BuffCheck[buffOwner][auraName] == nil) then
				if (VGAC_NumActiveBuffs < VGACConfig.numSlots) then
					VGAC_NumActiveBuffs = VGAC_NumActiveBuffs + 1
					local n = VGAC_NumActiveBuffs
					VGAC_Bars.BuffFrames[n].auraName = auraName
					VGAC_Bars.BuffFrames[n].texture:SetTexture(VGAC_BuffInfo[auraName].icon)
					VGAC_Bars.BuffFrames[n].timer:SetText(VGAC_SecondsToTime(math.floor(GetTime() - entry.castAt)))
					VGAC_Bars.BuffFrames[n].buffOwner:SetText(buffOwner)
					VGAC_Bars.BuffFrames[n]:Show()
				end
			end
		end
	end
end

function VGAC_OnEvent()
	local playerName = UnitName("player")
	if (event == "VARIABLES_LOADED" or event == "PLAYER_ENTERING_WORLD") then
		if (VGACConfig == nil) then
			VGACConfig = VGAC_defaultConfig
		else
			VGACConfig.defaultHeight = VGAC_defaultConfig.defaultHeight
			VGACConfig.defaultWidth = VGAC_defaultConfig.defaultWidth
			VGACConfig.defaultTextSize = VGAC_defaultConfig.defaultTextSize
			VGACConfig.numSlots = VGAC_defaultConfig.numSlots
		end
		if (VGAC_Bars == nil) then VGAC_InitializeBars() end


	elseif (event == "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS") then
		for buffOwner, auraName in string.gfind(arg1, "(.*) gains (.*).") do
			if (VGAC_BuffInfo[auraName] ~= nil) then
				if (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) then
					local zone = GetZoneText()
					local channel = "RAID"
					if (zone == "Warsong Gulch" or zone == "Arathi Basin" or zone == "Alterac Valley") then channel = "BATTLEGROUND" end
					SendAddonMessage("VGAC_NewBuff", buffOwner.."!"..auraName.."!"..(0), channel)
				else
					VGAC_AddBuff(buffOwner, auraName, 0)
				end
			end
		end

	elseif (event == "CHAT_MSG_SPELL_BREAK_AURA") then
		for buffOwner, auraName in string.gfind(arg1, "(.*)'s (.*) is removed.") do
			if (VGAC_BuffInfo[auraName] ~= nil) then
				if (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) then
					local zone = GetZoneText()
					local channel = "RAID"
					if (zone == "Warsong Gulch" or zone == "Arathi Basin" or zone == "Alterac Valley") then channel = "BATTLEGROUND" end
					SendAddonMessage("VGAC_RemoveBuff", buffOwner.."!"..auraName, channel)
				else
					if (VGAC_ActiveBuffs ~= nil and VGAC_ActiveBuffs[buffOwner] ~= nil) then
						VGAC_ActiveBuffs[buffOwner][auraName] = nil
					end
				end
			end
		end

	elseif (event == "CHAT_MSG_COMBAT_HOSTILE_DEATH") then
		local deadGuysName = nil
		for deadGuy in string.gfind(arg1, "You have slain (.*)!") do
			deadGuysName = deadGuy
		end
		for deadGuy in string.gfind(arg1, "(.*) dies.") do
			deadGuysName = deadGuy
		end
		if (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) then
			local zone = GetZoneText()
			local channel = "RAID"
			if (zone == "Warsong Gulch" or zone == "Arathi Basin" or zone == "Alterac Valley") then channel = "BATTLEGROUND" end
			SendAddonMessage("VGAC_RemovePlayer", deadGuysName, channel)
		else
			if (VGAC_ActiveBuffs ~= nil and VGAC_ActiveBuffs[deadGuysName] ~= nil) then
				VGAC_ActiveBuffs[deadGuysName] = nil
			end
		end

	elseif (event == "CHAT_MSG_ADDON" and arg1 == "VGAC_NewBuff") then
		for buffOwner, auraName, castBefore in string.gfind(arg2, "(.+)!(.+)!(.+)") do
			VGAC_AddBuff(buffOwner, auraName, castBefore)
		end

	elseif (event == "CHAT_MSG_ADDON" and arg1 == "VGAC_RemoveBuff") then
		for buffOwner, auraName in string.gfind(arg2, "(.+)!(.+)") do
			if (VGAC_ActiveBuffs ~= nil and VGAC_ActiveBuffs[buffOwner] ~= nil) then
				VGAC_ActiveBuffs[buffOwner][auraName] = nil
			end
		end

	elseif (event == "CHAT_MSG_ADDON" and arg1 == "VGAC_RemovePlayer") then
		local buffOwner = arg2
		if (VGAC_ActiveBuffs ~= nil and VGAC_ActiveBuffs[buffOwner] ~= nil) then
			VGAC_ActiveBuffs[buffOwner] = nil
		end

	elseif (event == "CHAT_MSG_ADDON" and arg1 == "VGAC_HiImBob") then -- A new player joined the group and is asking for active buff info
		for buffOwner, val in pairs(VGAC_ActiveBuffs) do
			for auraName, entry in pairs(VGAC_ActiveBuffs[buffOwner]) do
				local zone = GetZoneText()
				local channel = "RAID"
				if (zone == "Warsong Gulch" or zone == "Arathi Basin" or zone == "Alterac Valley") then channel = "BATTLEGROUND" end
				SendAddonMessage("VGAC_HiBob!"..arg2, buffOwner.."!"..auraName.."!"..(GetTime() - entry.castAt), channel)
			end
		end

	elseif (event == "CHAT_MSG_ADDON" and string.find(arg1, "VGAC_HiBob!")) then
		for recipient in string.gfind(arg1, "VGAC_HiBob!(.*)") do
			if (recipient == playerName) then -- our call for buff info sharing was answered
				for buffOwner, auraName, castBefore in string.gfind(arg2, "(.+)!(.+)!(.+)!(.+)") do
					VGAC_AddBuff(buffOwner, auraName, castBefore)
				end
			end
		end

	elseif (event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE") then
		local oldGroupLevel = VGAC_GroupLevel
		local zone = GetZoneText()
		local channel = "RAID"
		if (zone == "Warsong Gulch" or zone == "Arathi Basin" or zone == "Alterac Valley") then channel = "BATTLEGROUND" end
		if (oldGroupLevel < VGAC_GroupLevel) then -- Since you joined a new group, it's time to tell everyone about the buffs that you know of and ask for them to share theirs
			SendAddonMessage("VGAC_HiImBob", playerName, channel)
			if (VGAC_ActiveBuffs ~= nil) then
				for buffOwner, val in pairs(VGAC_ActiveBuffs) do
					for auraName, entry in pairs(VGAC_ActiveBuffs) do
						SendAddonMessage("VGAC_NewBuff", buffOwner.."!"..auraName.."!"..(GetTime() - entry.castAt), channel)
					end
				end
			end
		end
	end
end

function VGAC_OnUpdate()
	local currentTime = GetTime()
	local delta = currentTime - VGAC_LastUpdate
	local needsCleanup = false
	if (delta >= VGAC_UpdateInterval) then
		local playerName = UnitName("player")
		-- Update targets that should be available for purge again
		for buffOwner, timestamp in pairs(VGAC_RecentTargets) do
			if (currentTime - timestamp >= 1.5) then
				VGAC_RecentTargets[buffOwner] = nil
			end
		end
		-- Update time for ALL buffs that you are aware of
		if (VGAC_ActiveBuffs ~= nil) then
			for buffOwner, val in pairs(VGAC_ActiveBuffs) do
				for auraName, entry in pairs(val) do
					if (VGAC_ActiveBuffs[buffOwner][auraName].castAt + VGAC_ActiveBuffs[buffOwner][auraName].duration <= currentTime) then
						VGAC_ActiveBuffs[buffOwner][auraName] = nil
					end
				end
			end
		end
		-- Update timers that you have displayed
		for i = 1, VGAC_NumActiveBuffs do
			local buffOwner = VGAC_Bars.BuffFrames[i].buffOwner:GetText()
			local auraName = VGAC_Bars.BuffFrames[i].auraName
			if (VGAC_ActiveBuffs ~= nil and VGAC_ActiveBuffs[buffOwner] ~= nil and VGAC_ActiveBuffs[buffOwner][auraName] ~= nil) then
				if (VGAC_ActiveBuffs[buffOwner][auraName].castAt + VGAC_ActiveBuffs[buffOwner][auraName].duration > currentTime) then
					local remaining = math.floor(VGAC_ActiveBuffs[buffOwner][auraName].duration - (currentTime - VGAC_ActiveBuffs[buffOwner][auraName].castAt))
					VGAC_Bars.BuffFrames[i].timer:SetText(VGAC_SecondsToTime(remaining))
				end
			elseif (VGAC_ActiveBuffs ~= nil and (VGAC_ActiveBuffs[buffOwner] == nil or VGAC_ActiveBuffs[buffOwner][auraName] == nil)) then
				needsCleanup = true
			end
		end
		VGAC_LastUpdate = currentTime
	end
	if (VGACConfig.isUnlocked == true) then
		for i = VGAC_NumActiveBuffs + 1, VGACConfig.numSlots do
			if (not VGAC_Bars.BuffFrames[i]:IsShown()) then VGAC_Bars.BuffFrames[i]:Show() end
		end
	elseif (VGACConfig.isUnlocked == false) then
		for i = VGAC_NumActiveBuffs + 1, VGACConfig.numSlots do
			if (VGAC_Bars.BuffFrames[i]:IsShown()) then VGAC_Bars.BuffFrames[i]:Hide() end
		end
	end
	if (needsCleanup == true) then
		VGAC_UpdateTrackedBuffs()
	end
end

VanguardAntiCooldownFrame:SetScript("OnEvent", VGAC_OnEvent)
VanguardAntiCooldownFrame:SetScript("OnUpdate", VGAC_OnUpdate)

function VGAC_UpdateScale()
	local scale = VGACConfig.scale
	-- VGAC_Bars.mainFrame:SetScale(scale)
	for i = 1, VGACConfig.numSlots do
		local frame = VGAC_Bars.BuffFrames[i]
		local texture = frame.texture
		local timer = frame.timer
		local buffOwner = frame.buffOwner
		frame:SetPoint("TOPLEFT", scale * VGACConfig.defaultWidth * (i - 1), 0)
		frame:SetWidth(scale * VGACConfig.defaultWidth)
		frame:SetHeight(scale * VGACConfig.defaultHeight * 1.2)
		texture:SetHeight(scale * VGACConfig.defaultHeight)
		texture:SetWidth(scale * VGACConfig.defaultWidth)
		timer:SetFont("Fonts\\FRIZQT__.TTF", scale * VGACConfig.defaultTextSize, "OUTLINE")
		timer:SetAllPoints(frame)
		buffOwner:SetFont("Fonts\\FRIZQT__.TTF", scale * VGACConfig.defaultTextSize * 0.6, "OUTLINE")
		buffOwner:SetWidth(scale * VGACConfig.defaultWidth - 6)
		buffOwner:SetHeight(scale * VGACConfig.defaultHeight * 0.2)
		buffOwner:SetPoint("BOTTOMLEFT", 3, 3);
	end
	local frame = VGAC_Bars.mainFrame
	frame:SetWidth(scale * VGACConfig.defaultWidth * VGACConfig.numSlots)
	frame:SetHeight(scale * VGACConfig.defaultHeight)
end

function VGAC_SlashCommand(msg)
	if (msg == "reset") then
		VGACConfig = VGAC_defaultConfig
		VGAC_InitializeBars()
	elseif (msg == "move") then
		if (VGACConfig.isUnlocked == false) then
			VGACConfig.isUnlocked = true
			VGAC_Bars.mainFrame:SetAlpha(0.5)
			VGAC_Bars.mainFrame:EnableMouse(true)
			for i = 1, VGACConfig.numSlots do
				VGAC_Bars.BuffFrames[i]:SetAlpha(0.5)
			end
			VGAC_Bars.mainFrame:SetMovable(true)
		else
			VGAC_Bars.mainFrame:EnableMouse(false)
			VGACConfig.isUnlocked = false
			VGAC_Bars.mainFrame:SetAlpha(0)
			for i = 1, VGACConfig.numSlots do
				VGAC_Bars.BuffFrames[i]:SetAlpha(1)
			end
			VGAC_Bars.mainFrame:SetMovable(false)
		end
	elseif (string.find(msg, "scale ")) then
		for scale in string.gfind(msg, "scale (.*)") do
			VGACConfig.scale = scale
			VGAC_UpdateScale()
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("VanguardAntiCooldown (vgac), by Threewords <Vanguard> of Kronos, Twinstar")
		DEFAULT_CHAT_FRAME:AddMessage("/vgac reset")
		DEFAULT_CHAT_FRAME:AddMessage("/vgac move")
		DEFAULT_CHAT_FRAME:AddMessage("/vgac scale "..VGACConfig.scale)
	end
end

SLASH_VGAC1 = "/vgac"
SlashCmdList["VGAC"] = function(msg) VGAC_SlashCommand(msg) end