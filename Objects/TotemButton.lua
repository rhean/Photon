-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

--the shaman totem bar on Forever: a Call spell, the four totem slots of the Call's page, and Totemic Recall.
--left click casts, right click picks a slot's totem or the Call. totems can only be picked out of combat

local _, addonTable = ...
local Photon = addonTable.Photon

---@class TotemButton : Button @define class TotemButton inherits from class Button
local TotemButton = setmetatable({}, { __index = Photon.Button })
Photon.TotemButton = TotemButton

local L = LibStub("AceLocale-3.0"):GetLocale("Photon")

local SUMMON = 1 --button 1 is the Call spell, 2-5 the slots and 6 Totemic Recall
local RECALL = 6

--each slot's action within a page, Earth, Fire, Water, Air as Blizzard's totem bar lays them out. the offset is the totem element too
local SLOT_OFFSETS = {2, 1, 3, 4}

local SUMMON_SPELLS = TOTEM_MULTI_CAST_SUMMON_SPELLS or {66842, 66843, 66844}
local RECALL_SPELL = TOTEM_MULTI_CAST_RECALL_SPELLS and TOTEM_MULTI_CAST_RECALL_SPELLS[1] or 36936
local SLOTS_PER_PAGE = NUM_MULTI_CAST_BUTTONS_PER_PAGE or 4

--Blizzard's empty slot art for each totem element, as left, right, top, bottom in pixels of the 128x256 texture
local EMPTY_TEXTURE = "Interface\\Buttons\\UI-TotemBar"
local EMPTY_COORDS = {
	[1] = {67, 97, 100, 130}, --fire
	[2] = {66, 96, 3, 33}, --earth
	[3] = {39, 69, 209, 239}, --water
	[4] = {66, 96, 36, 66}, --air
}

--an empty slot's tooltip, by element
local EMPTY_NAMES = {
	[1] = L["Fire Totem"],
	[2] = L["Earth Totem"],
	[3] = L["Water Totem"],
	[4] = L["Air Totem"],
}

local SPACING = 4 --between the picker's buttons, and from the button it opens from
local AUTOHIDE = 1 --seconds the picker stays open once the mouse leaves it

--what each event updates. the slots, page and spells change seldom, cooldowns and usability often
local EVENTS = {
	PLAYER_ENTERING_WORLD = "UpdateAll",
	SPELLS_CHANGED = "UpdateAll",
	UPDATE_MULTI_CAST_ACTIONBAR = "UpdateAll",
	ACTIONBAR_SLOT_CHANGED = "UpdateAll",
	ACTIONBAR_UPDATE_COOLDOWN = "UpdateCooldown",
	SPELL_UPDATE_COOLDOWN = "UpdateCooldown",
	ACTIONBAR_UPDATE_USABLE = "UpdateUsable",
	SPELL_UPDATE_USABLE = "UpdateUsable",
	PLAYER_REGEN_ENABLED = "UpdateAll",
	PLAYER_REGEN_DISABLED = "UpdateAll",
}

---the first action of the totem pages, 133 on Forever
local function firstAction()
	local barIndex = GetMultiCastBarIndex and GetMultiCastBarIndex() or 12
	return (barIndex - 1) * (NUM_ACTIONBAR_BUTTONS or 12) + 1
end

---the Call pages the player has the spell for
local function knownPages()
	local pages = {}
	for page, spellID in ipairs(SUMMON_SPELLS) do
		if IsSpellKnown(spellID) then
			table.insert(pages, page)
		end
	end
	return pages
end

-------------------------------------------------------------------------------
------------------------------------ picker -----------------------------------
-------------------------------------------------------------------------------

--one picker for every totem button, it lists spells and calls back with the one clicked
local picker = CreateFrame("Frame", "PhotonTotemPicker", UIParent)
picker:Hide()
picker:SetSize(1, 1)
picker:SetFrameStrata("DIALOG")
local pickerButtons = {}

--plain buttons, not secure ones: picking a totem works only out of combat anyway, and the picker can then always hide
local function newPickerButton(index)
	local button = CreateFrame("CheckButton", "PhotonTotemPickerButton"..index, picker)
	button:Hide()
	button:RegisterForClicks("AnyUp")

	button.Icon = button:CreateTexture(nil, "BACKGROUND")
	button.Icon:SetAllPoints()
	button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
	button.Normal = button:GetNormalTexture()
	button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
	button.Pushed = button:GetPushedTexture()
	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	button.Highlight = button:GetHighlightTexture()
	button:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")
	button.Checked = button:GetCheckedTexture()
	button.Checked:SetBlendMode("ADD")

	button:SetScript("OnClick", function(self)
		self:SetChecked(false)
		if not InCombatLockdown() and picker.onPick then
			picker.onPick(self.spellID)
		end
		picker:Hide()
	end)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetSpellByID(self.spellID)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", GameTooltip_Hide)

	Photon.Button.SetSkinned(button, true)
	pickerButtons[index] = button
	return button
end

--closes a while after the mouse leaves the picker and the button it opened from
picker:SetScript("OnUpdate", function(self, elapsed)
	local over = self.owner and self.owner:IsMouseOver()
	for _, button in ipairs(pickerButtons) do
		over = over or (button:IsShown() and button:IsMouseOver())
	end
	self.away = over and 0 or (self.away or 0) + elapsed
	if self.away > AUTOHIDE then
		self:Hide()
	end
end)

picker:SetScript("OnHide", function(self)
	self.owner = nil
	self.onPick = nil
end)

---@param owner TotemButton
---@param spells number[] @spellIDs to choose from
---@param current number|nil @the one picked now, it shows checked
---@param onPick fun(spellID:number)
local function openPicker(owner, spells, current, onPick)
	if picker:IsShown() and picker.owner == owner then
		picker:Hide()
		return
	end
	picker:Hide()

	if #spells == 0 then
		return
	end

	--opens away from the screen edge it is nearest to, up or down
	local _, y = owner:GetCenter()
	local up = not y or y * owner:GetEffectiveScale() < UIParent:GetHeight() * UIParent:GetEffectiveScale() / 2
	local point, relPoint, dy = "BOTTOM", "TOP", SPACING
	if not up then
		point, relPoint, dy = "TOP", "BOTTOM", -SPACING
	end

	picker:SetScale(owner:GetEffectiveScale() / UIParent:GetEffectiveScale())
	picker:ClearAllPoints()
	picker:SetPoint("CENTER", owner, "CENTER")

	local anchor = owner
	for index, spellID in ipairs(spells) do
		local button = pickerButtons[index] or newPickerButton(index)
		button:SetSize(owner:GetSize())
		--the slot border reaches past the icon, as on an action button. a Masque skin places its own
		if not button.__MSQ_NormalSkin then
			button.Normal:ClearAllPoints()
			button.Normal:SetPoint("CENTER")
			button.Normal:SetSize(owner:GetWidth() * 66/36, owner:GetHeight() * 66/36)
		end
		button.spellID = spellID
		button.Icon:SetTexture(C_Spell.GetSpellTexture(spellID))
		button.Icon:Show()
		button:SetChecked(spellID == current)
		button:ClearAllPoints()
		button:SetPoint(point, anchor, relPoint, 0, dy)
		button:Show()
		anchor = button
	end
	for index = #spells + 1, #pickerButtons do
		pickerButtons[index]:Hide()
	end

	picker.owner = owner
	picker.onPick = onPick
	picker.away = 0
	picker:Show()
end

-------------------------------------------------------------------------------
------------------------------------ buttons ----------------------------------
-------------------------------------------------------------------------------

---Constructor: Create a new Photon Button object (this is the base object for all Photon button types)
---@param bar Bar @Bar Object this button will be a child of
---@param buttonID number @Button ID that this button will be assigned
---@param defaults table @Default options table to be loaded onto the given button
---@return TotemButton @ A newly created TotemButton object
function TotemButton.new(bar, buttonID, defaults)
	--call the parent object constructor with the provided information specific to this button type
	local newButton = Photon.Button.new(bar, buttonID, TotemButton, "TotemBar", "TotemButton", "PhotonActionButtonTemplate")

	if defaults then
		newButton:SetDefaults(defaults)
	end

	return newButton
end

function TotemButton:InitializeButton()
	for event in pairs(EVENTS) do
		if not C_EventUtils or not C_EventUtils.IsEventValid or C_EventUtils.IsEventValid(event) then
			self:RegisterEvent(event, "OnEvent")
		end
	end

	self:RegisterForClicks("AnyUp")
	self:SetAttribute("hotkeypri", self.keys.hotKeyPri)
	self:SetAttribute("hotkeys", self.keys.hotKeys)

	--the right click has no secure action, it opens the picker
	self:SetScript("PostClick", function(_, mouseButton)
		self:SetChecked(false)
		if mouseButton == "RightButton" then
			self:OpenPicker()
		end
	end)
	self:SetScript("OnEnter", function() self:UpdateTooltip() end)
	self:SetScript("OnLeave", GameTooltip_Hide)

	self:UpdateAll()
	self:InitializeButtonSettings()
end

function TotemButton:InitializeButtonSettings()
	self.bar:SetShowGrid(false)
	self:SetFrameStrata(Photon.STRATAS[self.bar:GetStrata()-1])
	self:SetScale(self.bar:GetBarScale())
	self.Name:Hide()

	local visuals = self:GetVisuals()
	if visuals:GetShowBindText() then
		self.Hotkey:Show()
		self.Hotkey:SetTextColor(visuals:GetBindColor()[1],visuals:GetBindColor()[2],visuals:GetBindColor()[3])
	else
		self.Hotkey:Hide()
	end

	self:SetSkinned()
end

function TotemButton:OnEvent(event)
	if event == "PLAYER_REGEN_DISABLED" then
		picker:Hide()
		return
	elseif event == "PLAYER_REGEN_ENABLED" and not self.attributesPending then
		return
	end

	self[EVENTS[event]](self)
	if event == "PLAYER_ENTERING_WORLD" then
		self:ApplyBindings()
	end
end

---the Call page the slots show: the one picked if its spell is known, else the first known.
---a shaman gets totem slots before any Call spell, they are on the first page
---@return number
function TotemButton:GetPage()
	local pages = knownPages()
	for _, page in ipairs(pages) do
		if page == self.bar.data.totemPage then
			return page
		end
	end
	return pages[1] or 1
end

function TotemButton:OpenPicker()
	if InCombatLockdown() then
		UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1.0, 0.1, 0.1, 1.0)
		return
	end

	if self.id == SUMMON then
		local spells = {}
		for _, page in ipairs(knownPages()) do
			table.insert(spells, SUMMON_SPELLS[page])
		end
		openPicker(self, spells, self.spellID, function(spellID)
			self.bar.data.totemPage = tIndexOf(SUMMON_SPELLS, spellID)
			for _, button in ipairs(self.bar.buttons) do
				button:UpdateAll()
			end
		end)

	elseif self.actionID then
		local actionID = self.actionID
		local _, current = GetActionInfo(actionID)
		openPicker(self, {GetMultiCastTotemSpells(SLOT_OFFSETS[self.id - 1])}, current, function(spellID)
			SetMultiCastSpell(actionID, spellID)
		end)
	end
end


-----------------------------------------------------
--------------------- Overrides ---------------------
-----------------------------------------------------

--overwrite function in parent class Button
function TotemButton:UpdateData()
	local page = self:GetPage()

	self.actionID = nil
	self.spellID = nil
	self.spell = nil

	--the Call and Recall show before they are learned, greyed out and casting nothing
	if self.id == SUMMON then
		self.spellID = SUMMON_SPELLS[page]
	elseif self.id == RECALL then
		self.spellID = RECALL_SPELL
	elseif SLOT_OFFSETS[self.id - 1] then
		self.actionID = firstAction() + (page - 1) * SLOTS_PER_PAGE + SLOT_OFFSETS[self.id - 1] - 1
	end

	self.known = self.spellID == nil or IsSpellKnown(self.spellID)
	if self.spellID and self.known then
		self.spell = C_Spell.GetSpellName(self.spellID)
	end

	--what the left click casts, attributes can only change out of combat
	if InCombatLockdown() then
		self.attributesPending = true
	else
		self.attributesPending = nil
		if self.actionID then
			self:SetAttribute("type1", "action")
			self:SetAttribute("action1", self.actionID)
		elseif self.spell then
			self:SetAttribute("type1", "spell")
			self:SetAttribute("spell1", self.spell)
		else
			self:SetAttribute("type1", nil)
		end
	end

	self:UpdateVisibility()
end

--overwrite function in parent class Button
function TotemButton:UpdateVisibility()
	--set alpha instead of :Show or :Hide, to avoid taint and to allow the button to appear in combat
	self.isShown = HasMultiCastActionBar() and (self.actionID ~= nil or self.spellID ~= nil)
	Photon.Button.UpdateVisibility(self) --call parent function
end

--overwrite function in parent class Button
function TotemButton:UpdateIcon()
	local texture
	if self.actionID then
		texture = GetActionTexture(self.actionID)
	elseif self.spellID then
		texture = C_Spell.GetSpellTexture(self.spellID)
	end

	self.Icon:SetTexture(texture)
	self.Icon:SetShown(texture ~= nil)
	self.Icon:SetDesaturated(not self.known)
	self.Icon:SetAlpha(self.known and 1 or 0.3)

	--an empty slot shows its element, on a texture of its own so Masque's crop of the icon stays as it is
	local coords = self.actionID and not texture and EMPTY_COORDS[SLOT_OFFSETS[self.id - 1]]
	if coords and not self.EmptyTotem then
		self.EmptyTotem = self:CreateTexture(nil, "ARTWORK")
		self.EmptyTotem:SetAllPoints(self.Icon)
		self.EmptyTotem:SetTexture(EMPTY_TEXTURE)
		self.EmptyTotem:SetDesaturated(true)
	end
	if self.EmptyTotem then
		if coords then
			self.EmptyTotem:SetTexCoord(coords[1]/128, coords[2]/128, coords[3]/256, coords[4]/256)
		end
		self.EmptyTotem:SetShown(not not coords)
	end
	--make sure our button gets the correct Normal texture if we're not using a Masque skin
	self:UpdateNormalTexture()
end

--overwrite function in parent class Button
function TotemButton:UpdateStatus()
	self:SetChecked(false)
	self:UpdateUsable()
end

--overwrite function in parent class Button
function TotemButton:UpdateUsable()
	if not self.known and not (Photon.buttonEditMode or Photon.bindingMode) then
		--not learned yet, UpdateIcon greys it out and fades it
		self.Icon:SetVertexColor(1.0, 1.0, 1.0)
	else
		Photon.Button.UpdateUsable(self) --call parent function
	end
end

--overwrite function in parent class Button
function TotemButton:UpdateCooldown()
	--a slot without a totem keeps no cooldown, like one left from the totem it had or another page's
	if self.actionID and not HasAction(self.actionID) then
		self:CancelCooldownTimer(true)
	else
		Photon.Button.UpdateCooldown(self) --call parent function
	end
end

--overwrite function in parent class Button
function TotemButton:UpdateTooltip()
	if not self.isShown or (InCombatLockdown() and not self:GetVisuals():GetTooltipCombat()) then
		return
	end

	local option = self:GetVisuals():GetTooltipOption()
	if option == "off" then
		return
	end

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if self.actionID and HasAction(self.actionID) then
		GameTooltip:SetAction(self.actionID)
	elseif self.spellID and option == "normal" then
		GameTooltip:SetSpellByID(self.spellID)
	elseif self.spellID then
		GameTooltip:SetText(C_Spell.GetSpellName(self.spellID), 1, 1, 1)
	elseif self.actionID then
		GameTooltip:SetText(EMPTY_NAMES[SLOT_OFFSETS[self.id - 1]], 1, 1, 1)
	else
		GameTooltip:SetText(EMPTY, 1, 1, 1)
	end
	GameTooltip:Show()
end
