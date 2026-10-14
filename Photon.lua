-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)


local _, addonTable = ...

local Spec = addonTable.utilities.Spec
local DBFixer = addonTable.utilities.DBFixer
local Array = addonTable.utilities.Array
local ButtonBinder = addonTable.overlay.ButtonBinder
local ButtonEditor = addonTable.overlay.ButtonEditor
local BarEditor = addonTable.overlay.BarEditor

---@class Photon : AceAddon-3.0 @define The main addon object for the Photon Action Bar addon
addonTable.Photon = LibStub("AceAddon-3.0"):NewAddon(CreateFrame("Frame", nil, UIParent), "Photon", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
local Photon = addonTable.Photon

local DB

local L = LibStub("AceLocale-3.0"):GetLocale("Photon")

--the What's New popup, shown once per account when LATEST_VERSION_NUM changes, see Photon:LoginMessage
local LATEST_VERSION_NUM = "0.1" --change it with WhatsNew_Text in the locale, everyone sees the new release notes once
local SHOW_WHATS_NEW = true --false for a version that shouldn't pop up, like a small fix
local WHATS_NEW_TEXT = "WhatsNew_Text" --the locale key it shows. another key, like "WhatsNew_Override", shows that text instead

--prepare the Photon table with some sub-tables that will be used down the road
Photon.bars = {} --this table will be our main handle for all of our bars.

Photon.registeredBarData = {}

--these are the database tables that are going to hold our data. They are global because every .lua file needs access to them
Photon.itemCache = {} --Stores a cache of all items that have been seen by a Photon button
Photon.spellCache = {} --Stores a cache of all spells that have been seen by a Photon button

Photon.barEditMode = false
Photon.buttonEditMode = false
Photon.bindingMode = false

local tocVersion = select(4, GetBuildInfo())
Photon.isWoWForever = (WOW_PROJECT_CAMELOT ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT) or (tocVersion >= 16000 and tocVersion < 20000)
Photon.isWoWRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and not Photon.isWoWForever
Photon.isWoWClassicEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
Photon.isWoWMists = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC

Photon.STRATAS = {
	[1] = "BACKGROUND",
	[2] = "LOW",
	[3] = "MEDIUM",
	[4] = "HIGH",
	[5] = "DIALOG",
	[6] = "TOOLTIP"
}

Photon.TIMERLIMIT = 4

Photon.DEBUG = false

-------------------------------------------------------------------------
--------------------Start of Functions-----------------------------------
-------------------------------------------------------------------------

--- EasyMenu was removed in 11.0. This shows a menu table in the old EasyMenu
--- format with MenuUtil instead. Spacers (disabled entries) become dividers
---@param menuList table
function Photon.EasyMenu(menuList)
	local function build(parent, list)
		for _, entry in ipairs(list) do
			local text = entry.colorCode and entry.colorCode..entry.text.."|r" or entry.text
			local onClick = function() entry.func(entry, entry.arg1, entry.arg2) end

			if entry.isTitle then
				parent:CreateTitle(text)
			elseif entry.disabled then
				parent:CreateDivider()
			elseif entry.hasArrow then
				build(parent:CreateButton(text), entry.menuList)
			elseif entry.notCheckable then
				parent:CreateButton(text, onClick)
			else
				parent:CreateRadio(text, function() return entry.checked end, onClick)
			end
		end
	end

	MenuUtil.CreateContextMenu(UIParent, function(_, rootDescription)
		build(rootDescription, menuList)
	end)
end

--- **OnInitialize**, which is called directly after the addon is fully loaded.
--- do init tasks here, like loading the Saved Variables
--- or setting up slash commands.
function Photon:OnInitialize()
	Photon.db = LibStub("AceDB-3.0"):New("PhotonProfilesDB", addonTable.databaseDefaults)

	--Check if the current database needs to be migrated, and attempt the migration
	Photon.db = DBFixer.databaseMigration(Photon.db)
	DB = Photon.db.profile

	Photon.db.RegisterCallback(Photon, "OnProfileChanged", "RefreshConfig")
	Photon.db.RegisterCallback(Photon, "OnProfileCopied", "RefreshConfig")
	Photon.db.RegisterCallback(Photon, "OnProfileReset", "RefreshConfig")
	Photon.db.RegisterCallback(Photon, "OnDatabaseReset", "RefreshConfig")

	--load saved variables into working variable containers
	Photon.itemCache = DB.PhotonItemCache
	Photon.spellCache = DB.PhotonSpellCache

	Photon.class = select(2, UnitClass("player"))
	Photon:UpdateStanceStrings()

	StaticPopupDialogs["ReloadUI"] = {
		text = L["ReloadUI"],
		button1 = YES,
		button2 = NO,
		OnAccept = function()
			ReloadUI()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}

	--Initialize the Minimap Icon
	Photon:Minimap_IconInitialize()

	--Initialize the chat commands (i.e. /photon)
	Photon:RegisterChatCommand("photon", "slashHandler")

	--build all bar and button frames and run initial setup
	Photon.registeredBarData = Photon:RegisterBars(DB)
	if DB.firstRun then
		Photon:InitializeEmptyDatabase(DB)
	end
	Photon:CreateBarsAndButtons(DB)
end

--- **OnEnable** which gets called during the PLAYER_LOGIN event, when most of the data provided by the game is already present.
--- Do more initialization here, that really enables the use of your addon.
--- Register Events, Hook functions, Create Frames, Get information from
--- the game that wasn't available in OnInitialize
function Photon:OnEnable()
	if Photon.DEBUG then
		_G.Photon = Photon
	end

	Photon:RegisterEvent("PLAYER_REGEN_DISABLED")
	Photon:RegisterEvent("PLAYER_ENTERING_WORLD")
	Photon:RegisterEvent("SPELLS_CHANGED")
	Photon:RegisterEvent("CHARACTER_POINTS_CHANGED")
	Photon:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE")
	Photon:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")

	Photon:UpdateStanceStrings()

	--this allows for the "Esc" key to disable the Edit Mode instead of bringing up the game menu, but only if an edit mode is activated.

	if not Photon:IsHooked(GameMenuFrame, "OnUpdate") then
		Photon:HookScript(GameMenuFrame, "OnUpdate", function(self)

			if Photon.barEditMode then
				HideUIPanel(self)
				Photon:ToggleBarEditMode(false)
			end

			if Photon.buttonEditMode then
				HideUIPanel(self)
				Photon:ToggleButtonEditMode(false)
			end

			if Photon.bindingMode then
				HideUIPanel(self)
				Photon:ToggleBindingMode(false)
			end

		end)
	end

	Photon:LoginMessage()

	--Load all bars and buttons
	for _,v in pairs(Photon.bars) do
		v:Load()
	end

	--this is a hack for 10.0. They broke everything with regard to the way addons interface with
	--SecureActionButtons see SecureTemplates.lua SecureActionButton_OnClick() for more information
	SetCVar("ActionButtonUseKeyDown", 0)

	Photon.PhotonGUI:LoadInterfaceOptions()

end

--- **OnDisable**, which is only called when your addon is manually being disabled.
--- Unhook, Unregister Events, Hide frames that you created.
--- You would probably only use an OnDisable if you want to
--- build a "standby" mode, or be able to toggle modules on/off.
function Photon:OnDisable()
	SetCVar("ActionButtonUseKeyDown", 1)
end

-------------------------------------------------

function Photon:PLAYER_REGEN_DISABLED()
	--bars and buttons can't be changed in combat, so the editors close
	Photon.PhotonGUI:CloseButtonEditor()
	Photon.PhotonGUI:CloseBarConfig()

	if Photon.buttonEditMode then
		Photon:ToggleButtonEditMode(false)
	end

	if Photon.bindingMode then
		Photon:ToggleBindingMode(false)
	end

	if Photon.barEditMode then
		Photon:ToggleBarEditMode(false)
	end
end


function Photon:PLAYER_ENTERING_WORLD()
	DB.firstRun = false

	Photon:UpdateSpellCache()
	Photon:UPDATE_SHAPESHIFT_FORMS() --catches up bars saved before a form was learned

	--Fix for Titan causing the Main Bar to not be hidden
	if C_AddOns.IsAddOnLoaded("Titan") then
		TitanUtils_AddonAdjust("MainMenuBar", true)
	end

	Photon:HideBlizzardUI(DB)
end

function Photon:ACTIVE_TALENT_GROUP_CHANGED()
	Photon:UpdateSpellCache()
	Photon:UpdateStanceStrings()
end

function Photon:LEARNED_SPELL_IN_SKILL_LINE()
	Photon:UpdateSpellCache()
	Photon:UpdateStanceStrings()
end

function Photon:CHARACTER_POINTS_CHANGED()
	Photon:UpdateSpellCache()
	Photon:UpdateStanceStrings()
end

function Photon:SPELLS_CHANGED()
	Photon:UpdateSpellCache()
	Photon:UpdateStanceStrings()
end

--a newly learned form needs a page on every stance bar
function Photon:UPDATE_SHAPESHIFT_FORMS()
	Photon:UpdateStanceStrings()

	--level ups happen in combat, where the drivers can't be changed
	if InCombatLockdown() then
		Photon:RegisterEvent("PLAYER_REGEN_ENABLED", "UPDATE_SHAPESHIFT_FORMS")
		return
	end
	Photon:UnregisterEvent("PLAYER_REGEN_ENABLED")

	for _, bar in pairs(Photon.bars) do
		bar:UpdateStanceRemap()
	end
end

-------------------------------------------------------------------------
--------------------Profiles---------------------------------------------
-------------------------------------------------------------------------


function Photon:RefreshConfig(db, profile)
	Photon.pendingReload = true
	StaticPopup_Show("ReloadUI")
end

-----------------------------------------------------------------


function Photon:LoginMessage()
	--the release notes, once per account for each new version, fresh installs included.
	--this runs under the loading screen, and entering the world closes windows, so it waits until after
	if SHOW_WHATS_NEW and Photon.db.global.whatsNewSeen ~= LATEST_VERSION_NUM then
		local waiter = CreateFrame("Frame")
		waiter:RegisterEvent("PLAYER_ENTERING_WORLD")
		waiter:SetScript("OnEvent", function(self)
			self:UnregisterAllEvents()
			C_Timer.After(2, function()
				Photon.PhotonGUI:ShowWhatsNew(LATEST_VERSION_NUM, WHATS_NEW_TEXT)
				Photon.db.global.whatsNewSeen = LATEST_VERSION_NUM
			end)
		end)
	end


	--Shadowlands warning that will show as long as a player has one button on their ZoneAbilityBar for Shadowlands content
	if not Photon.isWoWForever and UnitLevel("player") >= 50 and Photon.db.profile.ZoneAbilityBar[1] and #Photon.db.profile.ZoneAbilityBar[1].buttons == 1 then
		print(" ")
		Photon:Print(WrapTextInColorCode("IMPORTANT: Shadowlands content now requires multiple Zone Ability Buttons. Please add at least 3 buttons to your Zone Ability Bar to support this new functionality.", "FF00FFEC"))
		print(" ")
	end
end



--- Creates a table containing provided data
-- @param index, bookType, spellName, altName, spellID, altSpellID, spellType, icon
-- @return curSpell:  Table containing provided data
function Photon:SetSpellInfo(index, bookType, spellType, spellName, spellID, icon, altName, altSpellID, altIcon)
	local curSpell = {}

	curSpell.index = index
	curSpell.booktype = bookType

	curSpell.spellType = spellType
	curSpell.spellName = spellName
	curSpell.spellID = spellID
	curSpell.icon = icon

	curSpell.altName = altName
	curSpell.altSpellID = altSpellID
	curSpell.altIcon = altIcon

	return curSpell
end

--- "()" indexes added because the Blizzard macro parser uses that to determine the difference of a spell versus a usable item if the two happen to have the same name.
--- I forgot this fact and removed using "()" and it made some macros not represent the right spell /sigh. This note is here so I do not forget again :P - Maul


--- Scans Character Spell Book and creates a table of all known spells.  This table is used to refrence macro spell info to generate tooltips and cooldowns.
---	If a spell is not displaying its tooltip or cooldown, then the spell in the macro probably is not in the database
function Photon:UpdateSpellCache()
	local C_SpellBook = addonTable.utilities.SpellBook --falls back to the older functions on Classic Era, see Utilities/SpellBook.lua
	local sIndexMax = 0
	local numSkillLines = C_SpellBook.GetNumSpellBookSkillLines()

	for i=1,numSkillLines do
		local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)

		sIndexMax = sIndexMax + skillLineInfo.numSpellBookItems
	end

	for i = 1,sIndexMax do
		local spellName, _ = C_SpellBook.GetSpellBookItemName(i, Enum.SpellBookSpellBank.Player) --this returns the baseSpell name, even if it is augmented by talents. I.e. Roll and Chi Torpedo
		local itemInfo = C_SpellBook.GetSpellBookItemInfo(i, Enum.SpellBookSpellBank.Player)
		local spellType = itemInfo and itemInfo.itemType
		local spellID = itemInfo and itemInfo.spellID
		local isPassive
		if spellName then
			isPassive = C_SpellBook.IsSpellBookItemPassive(i, Enum.SpellBookSpellBank.Player)
		end
		local icon = spellID and C_Spell.GetSpellTexture(spellID)

		local altName
		local altSpellID
		local altIcon

		if (spellName and spellType ~= Enum.SpellBookItemType.FutureSpell) and not isPassive then

			local altSpellInfo = C_Spell.GetSpellInfo(spellName)
			if altSpellInfo then
				altName, altIcon, altSpellID = altSpellInfo.name, altSpellInfo.iconID, altSpellInfo.spellID
			end

			if spellID == altSpellID then
				altSpellID = nil
				altName = nil
				altIcon = nil
			end

			local spellData = Photon:SetSpellInfo(i, Enum.SpellBookSpellBank.Player, spellType, spellName, spellID, icon, altName, altSpellID, altIcon)

			Photon.spellCache[(spellName):lower()] = spellData
			Photon.spellCache[(spellName):lower().."()"] = spellData


			--reverse main and alt so we can put both in the table accurately
			local altSpellData = Photon:SetSpellInfo(i, Enum.SpellBookSpellBank.Player, spellType, altName, altSpellID, altIcon, spellName, spellID, icon)

			if altName and altName ~= spellName then
				Photon.spellCache[(altName):lower()] = altSpellData
				Photon.spellCache[(altName):lower().."()"] = altSpellData
			end

		end
	end

	--Classic Era has no professions tab, its profession spells are in the General tab and cached above
	if not GetProfessions then
		return
	end

	for i = 1, select("#", GetProfessions()) do
		local index = select(i, GetProfessions())

		if index then
			local _, _, _, _, numSpells, spelloffset = GetProfessionInfo(index)

			for j=1,numSpells do

				local offsetIndex = j + spelloffset
				local spellName, _ = C_SpellBook.GetSpellBookItemName(offsetIndex, Enum.SpellBookSpellBank.Player)
				local itemInfo = C_SpellBook.GetSpellBookItemInfo(offsetIndex, Enum.SpellBookSpellBank.Player)
				local spellType = itemInfo and itemInfo.itemType
				local spellID = itemInfo and itemInfo.spellID
				local icon

				if spellName and spellID and spellType ~= Enum.SpellBookItemType.FutureSpell then
					icon = C_Spell.GetSpellTexture(spellID)
					local spellData = Photon:SetSpellInfo(offsetIndex, Enum.SpellBookSpellBank.Player, spellType, spellName, spellID, icon,nil,  nil, nil)

					Photon.spellCache[(spellName):lower()] = spellData
					Photon.spellCache[(spellName):lower().."()"] = spellData

				end
			end
		end
	end
end

function Photon:ToggleMainMenu()
	Settings.OpenToCategory(Photon.optionsCategoryID)
end

---/photon opens the interface menu, /photon bar and /photon button open the editors, /photon bind starts keybind mode
function Photon:slashHandler(input)
	if InCombatLockdown() then
		Photon:Print(ERR_NOT_IN_COMBAT)
		return
	end

	local command = Photon:GetArgs(input, 1)
	command = command and command:lower()

	if command == "bar" then
		Photon.PhotonGUI:OpenBarConfig()
	elseif command == "button" then
		Photon.PhotonGUI:OpenButtonEditor()
	elseif command == "bind" then
		Photon:ToggleBindingMode(true)
	else
		Photon:ToggleMainMenu()
	end
end

function Photon:ToggleBarEditMode(show)
	if show then
		Photon.barEditMode = true
		Photon:ToggleButtonEditMode(false)
		Photon:ToggleBindingMode(false)

		for _, bar in pairs(Photon.bars) do
			bar.editFrame =
				bar.editFrame or
				BarEditor.allocate(bar, function(overlay, button, down)
					overlay.bar:OnClick(button, down)
				end)

			bar:UpdateObjectVisibility(true)
			bar:UpdateBarStatus(true)
			bar:UpdateObjectStatus()
		end

		--if there is no bar selected, default to the first in the BarList
		--TODO: This logic may be unintuitive. Should probably be fixed
		if not Photon.currentBar and #Photon.bars then
			Photon.Bar.ChangeSelectedBar(Photon.bars[1])
		elseif Photon.currentBar then
			BarEditor.activate(Photon.currentBar.editFrame)
		end
	else
		Photon.barEditMode = false
		for _, bar in pairs(Photon.bars) do
			local overlay = bar.editFrame
			bar.editFrame = nil
			if overlay then
				BarEditor.free(overlay)
			end

			bar:UpdateObjectVisibility()
			bar:UpdateBarStatus()
			bar:UpdateObjectStatus()
		end
	end
end

function Photon:ToggleButtonEditMode(show)
	local isActionBar = function(bar)
		return bar and bar.class == "ActionBar"
	end

	local isStatusBar = function(bar)
		return
			bar and (
				bar.class == "XPBar" or
				bar.class == "RepBar" or
				bar.class == "CastBar" or
				bar.class == "MirrorBar"
			)
	end

	local bars = Array.concatenate(
		Array.filter(isActionBar, Photon.bars),
		Array.filter(isStatusBar, Photon.bars)
	)

	if show then
		Photon.buttonEditMode = true

		Photon:ToggleBarEditMode(false)
		Photon:ToggleBindingMode(false)

		local currentButton =
			Photon.currentButton or
			(
				(isActionBar(Photon.currentBar) or isStatusBar(Photon.currentBar))
				and unpack(Photon.currentBar.buttons)
			) or
			Array.foldl(
				function(button, bar) return button or unpack(bar.buttons) end,
				nil,
				bars
			)

		if not currentButton then
			Photon.buttonEditMode = false
			return
		end

		for _, bar in pairs(bars) do
			for _, button in pairs(bar.buttons) do
				button.editFrame = button.editFrame or ButtonEditor.allocate(
					button,
					isActionBar(bar) and "corners" or "sides",
					function(btn)
						Photon.Button.ChangeSelectedButton(btn)
						--a status bar's appearance in the bar editor follows the picked button
						Photon.PhotonGUI:RefreshBarConfig()
						if isActionBar(btn.bar) then
							Photon.PhotonGUI:OpenButtonEditor()
						else
							Photon.PhotonGUI:RefreshButtonEditor()
						end
					end
				)
			end

			bar:UpdateObjectVisibility(true)
			bar:UpdateBarStatus(true)
			bar:UpdateObjectStatus()
			bar:UpdateObjectUsability()
		end

		-- change the button, but also manually activate it
		-- just in case it was already the current button and
		-- so if the change is a noop, we still show the recticle
		Photon.Button.ChangeSelectedButton(currentButton)
		ButtonEditor.activate(currentButton.editFrame)
	else
		Photon.buttonEditMode = false

		for _, bar in pairs(bars) do
			for _, button in pairs(bar.buttons) do
				if button.editFrame then
					ButtonEditor.free(button.editFrame)
					button.editFrame = nil
				end
			end

			bar:UpdateObjectVisibility()
			bar:UpdateBarStatus()
			bar:UpdateObjectStatus()
			bar:UpdateObjectUsability()
		end
	end
end

--- Processes the change to a key bind
--- @param targetButton Button
--- @param key string @The key to be used
local function processKeyBinding(targetButton, key)
	--if the button is locked, warn the user as to the locked status
	if targetButton.keys and targetButton.keys.hotKeyLock then
		UIErrorsFrame:AddMessage(L["Bindings_Locked_Notice"], 1.0, 1.0, 1.0, 1.0, UIERRORS_HOLD_TIME)
		return
	end

	--if the key being pressed is escape, clear the bindings on the button
	if key == "ESCAPE" then
		ClearOverrideBindings(targetButton)
		targetButton.keys.hotKeys = ":"
		targetButton:ApplyBindings()

		--if the key is anything else, keybind the button to this key
	elseif key then --checks to see if another keybind already has that key, and if so clears it from the other button
		--check to see if any other button has this key bound to it, ignoring locked buttons, and if so remove the key from the other button
		for _, bar in pairs(Photon.bars) do
			for _, button in pairs(bar.buttons) do
				if button.keys then
					if targetButton ~= button and not button.keys.hotKeyLock then
						button.keys.hotKeys:gsub("[^:]+", function(binding)
							if key == binding then
								local newkey = binding:gsub("%-", "%%-")
								button.keys.hotKeys = button.keys.hotKeys:gsub(newkey..":", "")
								button:ApplyBindings()
							end
						end)
					end
				end
			end
		end

		--search the current hotKeys to see if our new key is missing, and if so add it
		local found
		targetButton.keys.hotKeys:gsub("[^:]+", function(binding)
			if binding == key then
				found = true
			end
		end)

		if not found then
			targetButton.keys.hotKeys = targetButton.keys.hotKeys..key..":"
		end

		targetButton:ApplyBindings()
	end
end

function Photon:ToggleBindingMode(show)
	local isBindable = function(bar)
		return bar and (
			bar.class == "ActionBar" or
			bar.class == "ExtraBar" or
			bar.class == "ZoneAbilityBar" or
			bar.class == "PetBar"
		)
	end

	local bars = Array.filter(isBindable, Photon.bars)

	if show then
		Photon.bindingMode = true
		Photon:ToggleButtonEditMode(false)
		Photon:ToggleBarEditMode(false)

		for _, bar in pairs(bars) do
			for _, button in pairs(bar.buttons) do
				button.keybindFrame = button.keybindFrame or ButtonBinder.allocate(button, processKeyBinding)
			end

			bar:UpdateObjectVisibility(true)
			bar:UpdateBarStatus(true)
			bar:UpdateObjectStatus()
			bar:UpdateObjectUsability()
		end

	else
		Photon.bindingMode = false
		for _, bar in pairs(bars) do
			for _, button in pairs(bar.buttons) do
				if button.keybindFrame then
					ButtonBinder.free(button.keybindFrame)
					button.keybindFrame = nil
				end
			end
			bar:UpdateObjectVisibility()
			bar:UpdateBarStatus()
			bar:UpdateObjectStatus()
			bar:UpdateObjectUsability()
		end
	end
end
