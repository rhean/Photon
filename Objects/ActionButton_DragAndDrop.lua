-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Photon = addonTable.Photon

---The functions in this file are part of the ActionButton class.
---It was just easier to put them all in their own file for organization.

local ActionButton = Photon.ActionButton

local macroDrag = {} --this is a table that holds onto the contents of the  current macro being dragged
local macroCache = {} --this will hold onto any previous contents of our button
local standIn = {} --what SetMouseCursor put on the cursor to show macroDrag
local dragSource --the button macroDrag was taken from, a drop that can't be placed goes back there

--picking something else up replaces our stand-in on the cursor, but nothing tells macroDrag.
--type and ID only, an item's link changes once the client has loaded it
local function holdingStandIn(cursorType, action1)
	return cursorType == standIn[1] and action1 == standIn[2]
end

local L = LibStub("AceLocale-3.0"):GetLocale("Photon")

--Mists Classic's mount journal puts a mount on the cursor as a companion.
local pickedMount = {}
if C_MountJournal and C_MountJournal.Pickup then
	hooksecurefunc(C_MountJournal, "Pickup", function(displayIndex)
		local cursorType, index = GetCursorInfo()
		pickedMount.index = cursorType == "companion" and index or nil
		pickedMount.mountID = C_MountJournal.GetDisplayedMountID(displayIndex)
	end)

	--a pickup that was let go of shouldn't match a later companion with the same index
	local cursorWatcher = CreateFrame("Frame")
	cursorWatcher:RegisterEvent("CURSOR_CHANGED")
	cursorWatcher:SetScript("OnEvent", function()
		if not GetCursorInfo() then
			wipe(pickedMount)
		end
	end)
end

--pet commands (Attack, Follow, Passive...) have no spell, they become their slash command
local petCommands = {
	PET_ACTION_ATTACK = "/petattack",
	PET_ACTION_FOLLOW = "/petfollow",
	PET_ACTION_WAIT = "/petstay",
	PET_ACTION_MOVE_TO = "/petmoveto",
	PET_MODE_PASSIVE = "/petpassive",
	PET_MODE_DEFENSIVE = "/petdefensive",
	PET_MODE_ASSIST = "/petassist",
	PET_MODE_AGGRESSIVE = "/petaggressive",
}

--the cursor can't tell commands apart (Stay and Passive both come back as 0), so we note which one was picked up
local pickedPetCommand

--a command let go of shouldn't be placed for a later pet ability
local petCursorWatcher = CreateFrame("Frame")
if not C_EventUtils or not C_EventUtils.IsEventValid or C_EventUtils.IsEventValid("CURSOR_CHANGED") then
	petCursorWatcher:RegisterEvent("CURSOR_CHANGED")
end
petCursorWatcher:SetScript("OnEvent", function()
	if not GetCursorInfo() then
		pickedPetCommand = nil
	end
end)

--what Photon's pet bar is about to pick up, PickupPetAction below takes it on
local pendingPetCommand

--Photon's pet bar calls this before it picks up, see PetButton:OnDragStart
function ActionButton.SetPickedPetAction(slot)
	local name, texture, isToken = GetPetActionInfo(slot)
	pendingPetCommand = isToken and petCommands[name] and {token = name, icon = _G[texture]} or nil
end

hooksecurefunc("PickupPetAction", function()
	pickedPetCommand = pendingPetCommand
	pendingPetCommand = nil
end)

--the spellbook names a command with its localized text, which is the global string of the same token
local function pickedFromSpellBook(index, bank)
	pickedPetCommand = nil
	if bank ~= Enum.SpellBookSpellBank.Pet then
		return
	end
	local info = addonTable.utilities.SpellBook.GetSpellBookItemInfo(index, bank)
	for token in pairs(petCommands) do
		if info and info.name == _G[token] then
			pickedPetCommand = {token = token, icon = info.iconID}
		end
	end
end

--a client can have both, and its spellbook may pick up with either
if C_SpellBook and C_SpellBook.PickupSpellBookItem then
	hooksecurefunc(C_SpellBook, "PickupSpellBookItem", pickedFromSpellBook)
end
if PickupSpellBookItem then
	hooksecurefunc("PickupSpellBookItem", function(index, book)
		local isPet = book == (BOOKTYPE_PET or "pet") or book == Enum.SpellBookSpellBank.Pet
		pickedFromSpellBook(index, isPet and Enum.SpellBookSpellBank.Pet or Enum.SpellBookSpellBank.Player)
	end)
end

--------------------------------------
--------------------------------------

--a macro, or only an icon picked in the button editor, both move with a drag
local function hasContent(self)
	return self:GetMacroText() ~= "" or not not self:GetMacroIcon()
end

---a Photon macro dropped on the pet bar can't go there, pet abilities only come from the pet spellbook.
---@return boolean
function ActionButton.DropOnPetBar()
	if #macroDrag == 0 or not holdingStandIn(GetCursorInfo()) then
		return false
	end

	Photon:Print(L["DragDrop_PetBar_Message"])

	--its button may have taken something else since, then it can't go back and stays on the cursor
	if not dragSource or hasContent(dragSource) then
		return true
	end

	ClearCursor()
	dragSource:PlaceMacro()
	dragSource:RefreshStateData()
	dragSource:InitializeButton()
	dragSource:UpdateAll()

	wipe(macroDrag)
	Photon.dragging = false
	return true
end

--this is the function that fires when you begin dragging an item
function ActionButton:OnDragStart()
	if InCombatLockdown() or not self.bar or self.actionID then
		return
	end

	local drag

	if not self.bar:GetBarLock() then
		drag = true
	elseif self.bar:GetBarLock() == "alt" and IsAltKeyDown() then
		drag = true
	elseif self.bar:GetBarLock() == "ctrl" and IsControlKeyDown() then
		drag = true
	elseif self.bar:GetBarLock() == "shift" and IsShiftKeyDown() then
		drag = true
	else
		drag = false
	end

	if drag and hasContent(self) then
		--an inherited macro belongs to another state, clearing this state would leave it showing
		if self:GetActiveData() ~= self.data then
			Photon:Print(L["DragDrop_Inherited_Message"])
			return
		end

		Photon.dragging = true

		if #macroCache==0 then --don't run if we have a cache, we will call it manually on the OnReceiveDrag on the new button
			self:SetMouseCursor()
		end

		self:PickUpMacro()
		dragSource = self
		self:RefreshStateData()

		self:InitializeButton()
		self:UpdateAll()

		for _,bar in pairs(Photon.bars) do
			if bar.class == "ActionBar" then
				bar:ACTIONBAR_SHOWHIDEGRID(true) --show the button grid if we have something picked up (i.e if macroDrag contains something)
			end
		end
	end

end

--This is the function that fires when a button is receiving a dragged item
function ActionButton:OnReceiveDrag()
	if InCombatLockdown() then --don't allow moving or changing macros while in combat. This will cause taint
		return
	end

	local cursorType, action1, action2, spellID = GetCursorInfo()

	--read before SetMouseCursor below clears the cursor, that can wipe pickedMount and pickedPetCommand, see cursorWatcher and petCursorWatcher
	local journalMountID = cursorType == "companion" and action2 == "MOUNT" and pickedMount.index == action1 and pickedMount.mountID
	local petCommand = cursorType == "petaction" and pickedPetCommand or nil

	--the macro was swapped off a button and something else picked up since, place that instead
	if #macroDrag > 0 and not holdingStandIn(cursorType, action1) then
		wipe(macroDrag)
		Photon.dragging = false
		if not cursorType then
			for _,bar in pairs(Photon.bars) do
				bar:ACTIONBAR_SHOWHIDEGRID()
			end
			return
		end
	end

	local home = #macroDrag > 0 and dragSource

	if hasContent(self) and self:GetActiveData() == self.data then --if our button being dropped onto already has content, we need to cache that content. inherited content stays where it is
		macroCache[1] = self:GetDragAction()
		macroCache[2] = self:GetMacroText()
		macroCache[3] = self:GetMacroIcon()
		macroCache[4] = self:GetMacroName()
		macroCache[5] = self:GetMacroNote()
		macroCache[6] = self:GetMacroUseNote()
		macroCache[7] = self:GetMacroBlizzMacro()
		macroCache[8] = self:GetMacroEquipmentSet()
	else
		wipe(macroCache)
	end

	if #macroCache > 0 then --if we have a cache, pickup the current icon before replacing it with the new content
		self:SetMouseCursor()
	end

	self.data.forceBlank = nil

	if #macroDrag > 0 then --checks to see if the thing we are placing is a Photon created macro vs something from the spellbook
		self:PlaceMacro()
	elseif cursorType == "spell" then
		self:PlaceSpell(action1, action2, spellID)

	elseif cursorType == "item" then
		self:PlaceItem(action1, action2)

	elseif cursorType == "macro" then
		self:PlaceBlizzMacro(action1)

	elseif cursorType == "equipmentset" then
		self:PlaceBlizzEquipSet(action1)

	elseif cursorType == "mount" then
		self:PlaceMount(action1, action2)

	elseif cursorType == "flyout" then
		self:PlaceFlyout(action1, action2)

	elseif cursorType == "battlepet" then
		self:PlaceBattlePet(action1, action2)
	elseif cursorType == "companion" then
		self:PlaceCompanion(action1, action2, journalMountID)
	elseif cursorType == "petaction" then
		self:PlacePetAbility(action1, action2, petCommand)
	end

	wipe(macroDrag)

	if #macroCache>0 then
		self:OnDragStart() --If we picked up a new ability after dropping this one we have to manually call OnDragStart
		if home then
			dragSource = home
		end
		for _,bar in pairs(Photon.bars) do
			bar:ACTIONBAR_SHOWHIDEGRID(true) --show the button grid if we have something picked up (i.e if macroDrag contains something)
		end
	else
		SetCursor(nil)
		ClearCursor() --if we did not pick up a new spell, clear the cursor
		Photon.dragging = false
		for _,bar in pairs(Photon.bars) do
			bar:ACTIONBAR_SHOWHIDEGRID() --show the button grid if we have something picked up (i.e if macroDrag contains something)
		end
	end

	self:RefreshStateData()
	self:InitializeButton()

	self:UpdateAll()
end


function ActionButton:PostClick() --this is necessary because if you are daisy-chain dragging spells to the bar you wont be able to place the last one due to it not firing an OnReceiveDrag
	if #macroDrag>0 then
		self:OnReceiveDrag()
	end
	self:UpdateStatus()
end

--we need to hook to the WorldFrame OnReceiveDrag and OnMouseDown so that we can "let go" of the spell when we drag it off the bar
function ActionButton:WorldFrame_OnReceiveDrag()
	--CAREFUL! see brittyazel/Photon/issues/468
	--only do something if there's currently data in macroDrag. Otherwise it is
	--just for normal Blizzard behavior.
	if #macroDrag > 0 then
		SetCursor(nil)
		ClearCursor()
		Photon.dragging = false

		wipe(macroDrag)
		wipe(macroCache)
	end

	for _,bar in pairs(Photon.bars) do
		bar:ACTIONBAR_SHOWHIDEGRID()
	end
end

--------------------------------------
--------------------------------------


function ActionButton:PickUpMacro()

	if macroCache[1] then  --triggers when picking up an existing button with a button in the cursor

		macroDrag = CopyTable(macroCache)
		wipe(macroCache) --once macroCache is loaded into macroDrag, wipe it

	elseif hasContent(self) then --not HasAction, macros without a spell or item (like /cancelaura) and lone icons have to move too

		macroDrag[1] = self:GetDragAction()
		macroDrag[2] = self:GetMacroText()
		macroDrag[3] = self:GetMacroIcon()
		macroDrag[4] = self:GetMacroName()
        macroDrag[5] = self:GetMacroNote()
		macroDrag[6] = self:GetMacroUseNote()
		macroDrag[7] = self:GetMacroBlizzMacro()
		macroDrag[8] = self:GetMacroEquipmentSet()

		self:SetMacroText()
		self:SetMacroIcon()
		self:SetMacroName()
        self:SetMacroNote()
		self:SetMacroUseNote()
		self:SetMacroBlizzMacro()
		self:SetMacroEquipmentSet()

		self.spell = nil
		self.spellID = nil
		self.item = nil

		self:InitializeButton()
	end


end


function ActionButton:PlaceMacro()
	self:SetMacroText(macroDrag[2])
	self:SetMacroIcon(macroDrag[3])
	self:SetMacroName(macroDrag[4])
	self:SetMacroNote(macroDrag[5])
	self:SetMacroUseNote(macroDrag[6])
	self:SetMacroBlizzMacro(macroDrag[7])
	self:SetMacroEquipmentSet(macroDrag[8])
end

function ActionButton:PlaceSpell(action1, action2, spellID)
	local C_SpellBook = addonTable.utilities.SpellBook --falls back to the older functions on Classic Era, see Utilities/SpellBook.lua
	local spell

	if action1 == 0 then
		-- I am unsure under what conditions (if any) we wouldn't have a spell ID
		if not spellID or spellID == 0 then
			return
		else
			spell = C_Spell.GetSpellName(spellID)
		end
	else
		--the cursor reports the book as a string, the C_SpellBook functions take an Enum.SpellBookSpellBank
		local spellBank = action2 == "pet" and Enum.SpellBookSpellBank.Pet or Enum.SpellBookSpellBank.Player
		spell = C_SpellBook.GetSpellBookItemName(action1, spellBank):lower()
		spellID = C_SpellBook.GetSpellBookItemInfo(action1, spellBank).spellID

		--some spellbook names are display only and can't be cast, i.e. Call Pet 1 shows as "Call Bird of Prey"
		if not C_Spell.GetSpellInfo(spell) then
			spell = C_Spell.GetSpellName(spellID) or spell
		end
	end


	local spellName = C_Spell.GetSpellName(spellID)
	local icon = C_Spell.GetSpellTexture(spellID)

	if not spellName then
		if Photon.spellCache[spell:lower()] then
			spellName = Photon.spellCache[spell:lower()].spellName
			icon = Photon.spellCache[spell:lower()].icon
		end
	end


	self:SetMacroText(self:AutoWriteMacro(spell))
	self:SetMacroIcon() --will pull icon automatically unless explicitly overridden
	self:SetMacroName()
	self:SetMacroNote()
	self:SetMacroUseNote()
	self:SetMacroBlizzMacro()
	self:SetMacroEquipmentSet()
end

function ActionButton:PlacePetAbility(action1, action2, petCommand)

	local spellID = action1
	local spellIndex = action2

	--passive, follow, defensive etc. have no spellIndex, and on some clients action1 isn't a spell we can name
	local spellInfoName = spellIndex and C_Spell.GetSpellName(spellID)

	--a command (passive, follow, defensive, etc) gets its slash command. checked first, the cursor
	--can carry another spell for one, like Move To coming as "Word of Recall Other" on Forever
	if petCommand then
		self:SetMacroText(petCommands[petCommand.token])
		self:SetMacroIcon(petCommand.icon) --need to set icon here, it won't pull it automatically
		self:SetMacroName()
		self:SetMacroNote()
		self:SetMacroUseNote()
		self:SetMacroBlizzMacro()
		self:SetMacroEquipmentSet()

	elseif spellInfoName then
		self:SetMacroText(self:AutoWriteMacro(spellInfoName))
		self:SetMacroIcon() --will pull icon automatically unless explicitly overridden
		self:SetMacroName()
		self:SetMacroNote()
		self:SetMacroUseNote()
		self:SetMacroBlizzMacro()
		self:SetMacroEquipmentSet()

	else --not a spell or a command we know, print a warning
		Photon:Print(L["DragDrop_Error_Message"])
	end
end


function ActionButton:PlaceItem(action1, action2)
	local item, link = C_Item.GetItemInfo(action2)

	if link and not Photon.itemCache[item:lower()] then --add the item to the itemcache if it isn't otherwise in it
		local _, itemID = link:match("(item:)(%d+)")
		Photon.itemCache[item:lower()] = itemID
	end

	if C_Item.IsEquippableItem(item) then
		self:SetMacroText("/equip "..item.."\n/use "..item)
	else
		self:SetMacroText("/use "..item)
	end

	self:SetMacroIcon() --will pull icon automatically unless explicitly overridden
	self:SetMacroName()
	self:SetMacroNote()
	self:SetMacroUseNote()
	self:SetMacroBlizzMacro()
	self:SetMacroEquipmentSet()

end


function ActionButton:PlaceBlizzMacro(action1)
	if action1 == 0 then
		return
	end

	local name, texture, body = GetMacroInfo(action1)

	if body then
		self:SetMacroText(body)
		self:SetMacroName()
		self:SetMacroIcon(texture)
		self:SetMacroBlizzMacro(name)
	else
		self:SetMacroText()
		self:SetMacroName()
		self:SetMacroIcon()
		self:SetMacroBlizzMacro()
	end

	self:SetMacroNote()
	self:SetMacroUseNote()
	self:SetMacroEquipmentSet()
end


function ActionButton:PlaceBlizzEquipSet(equipmentSetName)
	if equipmentSetName == 0 then
		return
	end

	local equipsetNameIndex --cycle through the equipment sets to find the index of the one with the right name

	for i = 0,C_EquipmentSet.GetNumEquipmentSets()-1 do
		if equipmentSetName == C_EquipmentSet.GetEquipmentSetInfo(i) then
			equipsetNameIndex = i
			break
		end
	end

	if not equipsetNameIndex then --bail out of we don't find an equipset index (should never happen but just in case
		return
	end

	local name, texture = C_EquipmentSet.GetEquipmentSetInfo(equipsetNameIndex)

	if texture then
		self:SetMacroText("/equipset "..equipmentSetName)
		self:SetMacroName()
		self:SetMacroIcon(texture)
		self:SetMacroEquipmentSet(equipmentSetName)
	else
		self:SetMacroText()
		self:SetMacroName()
		self:SetMacroIcon()
		self:SetMacroEquipmentSet()
	end

	self:SetMacroNote()
	self:SetMacroUseNote()
	self:SetMacroBlizzMacro()
end


--Hooks mount journal mount buttons on enter to pull spellid from tooltip--
--Based on discussion thread http://www.wowinterface.com/forums/showthread.php?t=49599&page=2
--More dynamic than the manual list that was originally implement

function ActionButton:PlaceMount(action1, action2)
	local mountName, mountSpellID, mountIcon = C_MountJournal.GetMountInfoByID(action1)
	local mountSpell

	if action1 == 0 or not mountSpellID or mountSpellID == 0 then
		return
	else
		mountSpell = C_Spell.GetSpellName(mountSpellID)
	end

	--The Summon Random Mount from the Mount Journal
	if action1 == 268435455 then
		self:SetMacroText("/run C_MountJournal.SummonByID(0);")
		self:SetMacroIcon("Interface\\ICONS\\ACHIEVEMENT_GUILDPERK_MOUNTUP")
		self:SetMacroName()
	else
		self:SetMacroText(self:AutoWriteMacro(mountSpell))
		self:SetMacroIcon() --will pull icon automatically unless explicitly overridden
		self:SetMacroName() --no label, as for spells
	end
	self:SetMacroNote()
	self:SetMacroUseNote()
	self:SetMacroBlizzMacro()
	self:SetMacroEquipmentSet()
end


---@param journalMountID? number @a mount from Mists Classic's mount journal, see pickedMount
function ActionButton:PlaceCompanion(action1, action2, journalMountID)
	if action1 == 0 then
		return
	end

	--checked first, the journal's index isn't a companion index
	if journalMountID then
		wipe(pickedMount)
		self:PlaceMount(journalMountID)
		return
	end

	local _, _, spellID, icon = GetCompanionInfo(action2, action1)
	local name = spellID and C_Spell.GetSpellName(spellID)

	if name then
		self:SetMacroName()
		self:SetMacroText(self:AutoWriteMacro(name))
	else
		self:SetMacroName()
		self:SetMacroText()
	end

	self:SetMacroIcon(icon) --need to set icon here, it won't pull it automatically
	self:SetMacroNote()
	self:SetMacroUseNote()
	self:SetMacroBlizzMacro()
	self:SetMacroEquipmentSet()
end

function ActionButton:PlaceBattlePet(action1, action2)
	if action1 == 0 then
		return
	end

	local _, _, _, _, _, _, _,petName, petIcon= C_PetJournal.GetPetInfoByPetID(action1)

	self:SetMacroText("/summonpet "..petName)
	self:SetMacroIcon(petIcon) --need to set icon here, it won't pull it automatically
	self:SetMacroName()
	self:SetMacroNote()
	self:SetMacroUseNote()
	self:SetMacroBlizzMacro()
	self:SetMacroEquipmentSet()
end


--action1 is the flyoutID. which way it opens is worked out from where the button is, see ActionButton_Flyout.lua
function ActionButton:PlaceFlyout(action1, action2)
	if action1 == 0 then
		return
	end

	self:SetMacroText("/flyout blizz:"..action1)
	self:SetMacroIcon()
	self:SetMacroName()
	self:SetMacroNote()
	self:SetMacroUseNote()
	self:SetMacroBlizzMacro()
	self:SetMacroEquipmentSet()
end


--This is all just to put an icon on the mouse cursor. Sadly we can't use SetCursor, because once you leave the frame the icon goes away. PickupSpell seems to work, but we need a valid spellID
--This trick here is that we ignore what is 'actually' and are just using it for the icon and the sound effects
local function pickUpStandIn(self)
	ClearCursor()

	if self.spell and self.spellID then
		C_Spell.PickupSpell(self.spellID)
		if GetCursorInfo() then
			return
		end
	end

	if self.item then
		C_Item.PickupItem(self.item) --this is to try to catch any stragglers that might not have a spellID on the button. Things like mounts and such. This only works on currently available items
		if GetCursorInfo() then --if this isn't a normal spell (like a flyout) or it is a pet abiity, revert to a question mark symbol
			return
		end

		local itemID = C_Item.GetItemInfoInstant(self.item) --nil for items the client doesn't know, like "Unknown Reward"
		if itemID then
			C_Item.PickupItem(itemID)
			if GetCursorInfo() then
				return
			end
		end

		if Photon.itemCache[self.item:lower()] then --try to pull the spellID from our ItemCache as a last resort
			C_Item.PickupItem(Photon.itemCache[self.item:lower()])
			if GetCursorInfo() then
				return
			end
		end
	end

	--failsafe so there is 'something' on the mouse cursor
	C_Item.PickupItem(1217) --questionmark symbol
end

function ActionButton:SetMouseCursor()
	pickUpStandIn(self)
	standIn = {GetCursorInfo()}
end
