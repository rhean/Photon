-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

--Blizzard's spell flyouts: teleports, Call Pet and the like. a button holds one as the macro "/flyout blizz:<flyoutID>".
--one shared secure popup opens from whichever button is clicked, so it works in combat.
--what each flyout holds can only change out of combat, see syncFlyouts

local _, addonTable = ...
local Photon = addonTable.Photon

local ActionButton = Photon.ActionButton

ActionButton.FLYOUT_PATTERN = "^%s*/flyout blizz:(%d+)"

local SPACING = 4 --between the popup's buttons, and from the button it opens from
local AUTOHIDE = 1 --seconds the popup stays open once the mouse leaves it

--the arrow on the side the popup opens to
local ARROWS = {UP = "FlyoutTop", DOWN = "FlyoutBottom", LEFT = "FlyoutLeft", RIGHT = "FlyoutRight"}

local flyoutInfo = {} --flyoutID = {name, icon}, from the spellbook
local wanted = {} --flyoutIDs on buttons, synced even when they aren't in the spellbook
local popupButtons = {}
local initialized, pending, queued

local handler = CreateFrame("Frame", "PhotonFlyoutHandler", UIParent, "SecureHandlerBaseTemplate")
local popup = CreateFrame("Frame", "PhotonFlyoutPopup", UIParent, "SecureHandlerBaseTemplate")
popup:Hide()

--runs on the clicked button, before its macro. opens or closes the popup for a flyout and stops the macro
local CLICK = [[
	if not POPUP or self:GetAttribute("type") ~= "macro" then
		return
	end
	local text = self:GetAttribute("*macrotext*")
	local id = text and tonumber(text:match("^%s*/flyout blizz:(%d+)"))
	if not id then
		return
	end

	if POPUP:IsVisible() and OPEN_FOR == self then
		POPUP:Hide()
		return false
	end

	local point, relPoint, dx, dy = "BOTTOM", "TOP", 0, 1
	local direction = self:GetAttribute("flyoutDirection")
	if direction == "DOWN" then
		point, relPoint, dx, dy = "TOP", "BOTTOM", 0, -1
	elseif direction == "LEFT" then
		point, relPoint, dx, dy = "RIGHT", "LEFT", -1, 0
	elseif direction == "RIGHT" then
		point, relPoint, dx, dy = "LEFT", "RIGHT", 1, 0
	end

	--on the button, so it takes the button's scale, layer and visibility
	POPUP:Hide()
	POPUP:SetParent(self)
	POPUP:ClearAllPoints()
	POPUP:SetAllPoints(self)

	local spells = FLYOUTS[id]
	local anchor, shown = self, 0
	for i = 1, NUM_BUTTONS do
		local child = BUTTONS[i]
		local spell = spells and spells[i]
		if spell then
			child:SetAttribute("spell", spell)
			child:ClearAllPoints()
			child:SetPoint(point, anchor, relPoint, dx*SPACING, dy*SPACING)
			child:Show()
			anchor = child
			shown = shown + 1
		else
			child:Hide()
		end
	end

	if shown > 0 then
		OPEN_FOR = self
		POPUP:Show()
		POPUP:RegisterAutoHide(AUTOHIDE)
		POPUP:AddToAutoHide(self)
		for i = 1, shown do
			POPUP:AddToAutoHide(BUTTONS[i])
		end
	end
	return false
]]

-------------------------------------------------------------------------------
--------------------------------- popup buttons -------------------------------
-------------------------------------------------------------------------------

local function updateCooldown(button)
	local spell = button:GetAttribute("spell")
	local info = spell and C_Spell.GetSpellCooldown(spell)
	if info and info.duration > 0 then
		button.Cooldown:SetCooldown(info.startTime, info.duration, info.modRate)
	else
		button.Cooldown:Clear()
	end
end

local function newPopupButton(index)
	local button = CreateFrame("CheckButton", "PhotonFlyoutButton"..index, popup, "PhotonActionButtonTemplate")
	button:Hide()
	button.Hotkey:Hide()
	button.Count:Hide()
	button.Name:Hide()
	button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
	button:RegisterForClicks("AnyUp")
	button:SetAttribute("type", "spell")

	--the secure click sets the spell, this follows it even in combat
	button:SetScript("OnAttributeChanged", function(self, name, value)
		if name == "spell" then
			self.Icon:SetTexture(value and C_Spell.GetSpellTexture(value))
			updateCooldown(self)
		end
	end)
	button:SetScript("OnEnter", function(self)
		local spell = self:GetAttribute("spell")
		if spell then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetSpellByID(spell)
			GameTooltip:Show()
		end
	end)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	button:SetScript("PostClick", function(self) self:SetChecked(false) end)

	--the popup closes once a spell is cast from it
	handler:WrapScript(button, "OnClick", [[ return nil, "close" ]], [[ POPUP:Hide() ]])

	Photon.Button.SetSkinned(button, true)

	handler:SetFrameRef("button", button)
	handler:Execute(([[
		BUTTONS[%d] = self:GetFrameRef("button")
		NUM_BUTTONS = %d
	]]):format(index, index))

	popupButtons[index] = button
end

-------------------------------------------------------------------------------
------------------------------------ syncing ----------------------------------
-------------------------------------------------------------------------------

local function scanSpellbook()
	wipe(flyoutInfo)
	local bank = Enum.SpellBookSpellBank.Player
	for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
		local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(line)
		for slot = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
			local info = C_SpellBook.GetSpellBookItemInfo(slot, bank)
			if info and info.itemType == Enum.SpellBookItemType.Flyout then
				flyoutInfo[info.actionID] = {name = info.name, icon = info.iconID}
			end
		end
	end
end

---the spells a flyout shows: known ones, and no empty Call Pet slots
local function flyoutSpells(flyoutID)
	local spells = {}
	local _, _, numSlots = GetFlyoutInfo(flyoutID)
	for slot = 1, numSlots or 0 do
		local spellID, _, isKnown = GetFlyoutSlotInfo(flyoutID, slot)
		local petIndex, petName = GetCallPetSpellInfo(spellID)
		if isKnown and not (petIndex and (not petName or petName == "")) then
			table.insert(spells, spellID)
		end
	end
	return spells
end

---hands every flyout's spells to the secure code. waits for combat to end
local function syncFlyouts()
	if InCombatLockdown() then
		pending = true
		return
	end
	pending = nil

	if not initialized then
		handler:SetFrameRef("popup", popup)
		handler:Execute(([[
			FLYOUTS = newtable()
			BUTTONS = newtable()
			NUM_BUTTONS = 0
			SPACING = %d
			AUTOHIDE = %d
			POPUP = self:GetFrameRef("popup")
		]]):format(SPACING, AUTOHIDE))
		initialized = true
	end

	local ids = {}
	for id in pairs(flyoutInfo) do
		ids[id] = true
	end
	for id in pairs(wanted) do
		ids[id] = true
	end

	local snippet, most = {"FLYOUTS = newtable()"}, 0
	for id in pairs(ids) do
		local spells = flyoutSpells(id)
		most = math.max(most, #spells)
		table.insert(snippet, ("FLYOUTS[%d] = newtable(%s)"):format(id, table.concat(spells, ",")))
	end

	for index = #popupButtons + 1, most do
		newPopupButton(index)
	end

	handler:Execute(table.concat(snippet, "\n"))
end

--many events can fire at once, sync once after them
local function queueSync()
	if not queued then
		queued = true
		C_Timer.After(0, function()
			queued = nil
			syncFlyouts()
		end)
	end
end

--created before any button registers its events, so the spellbook is scanned before buttons update their icons
local events = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_ENTERING_WORLD", "SPELLS_CHANGED", "SPELL_FLYOUT_UPDATE", "PET_STABLE_UPDATE", "PLAYER_REGEN_ENABLED", "SPELL_UPDATE_COOLDOWN"}) do
	events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event)
	if event == "SPELL_UPDATE_COOLDOWN" then
		for _, button in ipairs(popupButtons) do
			if button:IsVisible() then
				updateCooldown(button)
			end
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if pending then
			queueSync()
		end
	else
		scanSpellbook()
		queueSync()
	end
end)

-------------------------------------------------------------------------------
-------------------------------- action buttons -------------------------------
-------------------------------------------------------------------------------

---which way the popup opens: away from the screen edge the button is nearest to
local function openDirection(button)
	local x, y = button:GetCenter()
	if not x then
		return "UP"
	end

	local scale = button:GetEffectiveScale() / UIParent:GetEffectiveScale()
	x, y = x*scale, y*scale
	local width, height = UIParent:GetSize()

	local nearest = math.min(x, width-x, y, height-y)
	if nearest == y then
		return "UP"
	elseif nearest == height-y then
		return "DOWN"
	elseif nearest == x then
		return "RIGHT"
	else
		return "LEFT"
	end
end

function ActionButton:SetupFlyoutClick()
	if not self.flyoutClickWrapped then
		handler:WrapScript(self, "OnClick", CLICK)
		self.flyoutClickWrapped = true
	end
end

---the open direction for the secure click, and the arrow when the active state holds a flyout
function ActionButton:UpdateFlyout()
	local direction = openDirection(self)
	if not InCombatLockdown() and self:GetAttribute("flyoutDirection") ~= direction then
		self:SetAttribute("flyoutDirection", direction)
	end

	for side, key in pairs(ARROWS) do
		self[key]:SetShown(self.flyoutID ~= nil and side == direction)
	end

	if self.flyoutID then
		if not wanted[self.flyoutID] then
			wanted[self.flyoutID] = true
			queueSync()
		end

		--an autohiding bar stays up while its popup is moused
		self.bar.watchframes = self.bar.watchframes or {}
		for _, button in ipairs(popupButtons) do
			self.bar.watchframes[button] = true
		end
	end
end

function ActionButton:UpdateFlyoutTooltip()
	local name, description = GetFlyoutInfo(self.flyoutID)
	GameTooltip:SetText(name or self:GetMacroName(), 1, 1, 1)
	if description and #description > 0 and self.bar:GetTooltipOption() == "normal" then
		GameTooltip:AddLine(description, nil, nil, nil, true)
	end
end

---the flyout's spellbook icon, else its first spell's
function ActionButton.GetFlyoutIcon(flyoutID)
	if flyoutInfo[flyoutID] then
		return flyoutInfo[flyoutID].icon
	end
	local spellID = flyoutSpells(flyoutID)[1]
	return spellID and C_Spell.GetSpellTexture(spellID)
end
