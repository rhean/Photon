-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Photon = addonTable.Photon

local PhotonGUI = Photon.PhotonGUI

local L = LibStub("AceLocale-3.0"):GetLocale("Photon")

local Spec = addonTable.utilities.Spec
local UI = addonTable.ui
local Style = UI.Style

-----------------------------------------------------------------------------
--------------------------Button Editor Window-------------------------------
-----------------------------------------------------------------------------
--a button's macros as spec > action bar page > default or form > modifier pages.
--the buttons on a row share their modifiers, on every page

local window
local render

--kept while the window is open, so clicking another button keeps the place
local selected = {}

--what is on show: pages in order, their editors by page and the modifiers that can be added
local view = {pages = {}, editors = {}, available = {}, column = {}, row = {}}

--modifier pages folded by hand, for the same button, spec, action bar page and tab. the rest fold when empty
local expanded, expandedFor = {}, nil

--made with the window, see createWindow
local specRow, specLabel, specDropdown, helpButton, pageTabs, tabs, body, emptyText
local addButton, removeButton, expandButton, rowPool
local left, editors, editorPool
local overrideCheck, modifierRow

--the button on show last, so picking another one opens its own visuals
local lastButton

--the window's width before side by side widened it
local narrowWidth

--blizzard's action bars take over the buttons in these, so there is no macro to edit
local ACTION_BAR_STATES = {vehicle = true, dragonriding = true, possess = true, override = true, extrabar = true}

local HOME_STATE_ORDER = {paged = 1, stance = 2, pet = 3}

--the conditions in the bar config's order, see BarConfigLayout.lua. section is the box they are in there
local CONDITION_ORDER = {}
do
	local count = 0
	local function collect(rows, section)
		for _, row in ipairs(rows) do
			for _, item in ipairs(row) do
				if item.rows then
					collect(item.rows, section)
				elseif item.id and item.id:find("^state_") then
					count = count + 1
					CONDITION_ORDER[item.id:sub(7)] = {order = count, section = section}
				end
			end
		end
	end
	for _, tab in ipairs(addonTable.barConfigLayout.bar) do
		for _, group in ipairs(tab.groups or {}) do
			if group.id == "states" then
				for section, row in ipairs(group.rows or {}) do
					collect({row}, section)
				end
			end
		end
	end
end

local ALL_PAGES = {"paged1", "paged2", "paged3", "paged4", "paged5", "paged6"}

local ICON_SIZE = 42

--above and below the spec and modifier row
local SPEC_ROW_SPACE = 12

--data is what to do on yes
StaticPopupDialogs["NEURON_REMOVE_MODIFIER"] = UI.RaisePopup{
	text = L["ButtonEditor_RemoveModifier"],
	button1 = YES,
	button2 = NO,
	OnAccept = function(_, onAccept) onAccept() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

--forced blank counts as set, as in Button.lua
local function hasMacro(data)
	return data ~= nil and (data.forceBlank or (data.macro_Text ~= nil and data.macro_Text ~= "") or not not data.actionID)
end

--a macro or a label
local function hasText(data)
	return hasMacro(data) or (data ~= nil and data.macro_Name ~= nil and data.macro_Name ~= "")
end

---the bar's forms or pages and every modifier, enabled on the bar or not.
---unnamed states are dropped, which drops stance slots the class doesn't have
---@param bar Bar
---@return string[]
local function getStateList(bar)
	local barData = bar.data

	local stateList = {}
	for barState, stateInfo in pairs(Photon.MANAGED_BAR_STATES) do
		if (barData[barState] or Photon.MANAGED_SECONDARY_STATES[barState])
			and barState ~= "custom"
			and not ACTION_BAR_STATES[barState]
			--a rogue's stealth is a stance
			and not (Photon.class == "ROGUE" and barState == "stealth")
		then
			local driver = stateInfo.states
			if barData.remap and barState == "stance" then
				driver = driver.."; "..bar:BuildStateMap(barState)
			end

			local seen = {}
			for state in driver:gmatch("%a+%d+") do
				if not seen[state]
					and state:match("^"..barState.."%d+$")
					and (state ~= stateInfo.homestate or Photon.Bar.FormsArePages(barState))
					and Photon.STATES[state]
				then
					seen[state] = true
					table.insert(stateList, {state = state, barState = barState, num = tonumber(state:match("%d+$"))})
				end
			end
		end
	end

	table.sort(stateList, function(a, b)
		local orderA, orderB = HOME_STATE_ORDER[a.barState] or 99, HOME_STATE_ORDER[b.barState] or 99
		if orderA ~= orderB then
			return orderA < orderB
		elseif a.barState ~= b.barState then
			--conditions as in the bar config, any it doesn't list after them
			local conditionA, conditionB = CONDITION_ORDER[a.barState], CONDITION_ORDER[b.barState]
			if conditionA and conditionB then
				return conditionA.order < conditionB.order
			elseif conditionA or conditionB then
				return conditionA ~= nil
			end
			return a.barState < b.barState
		end
		return a.num < b.num
	end)

	local states = {}
	for _, entry in ipairs(stateList) do
		table.insert(states, entry.state)
	end
	return states
end

local function stateName(state)
	if state == "homestate" then
		return L["Default"]
	end
	return Photon.STATES[state] or state
end

--the hover text, the same as the state's in the bar editor
local function stateDesc(state)
	if state == "homestate" then
		return L["ButtonEditor_DefaultDesc"]
	end
	return rawget(L, "BarDesc_state_"..state:match("^%a+"))
end

--stance1_alt1, pet2_alt1, paged2_stance1_alt1
local function pageName(state)
	local form, rest = state:match("^(%a+%d+)_(.+)$")
	if form then
		return stateName(form).." - "..pageName(rest)
	end
	return stateName(state)
end

--page 1 keeps its keys, paged2_alt1 on page 2
local function onPage(actionPage, state)
	return (actionPage and actionPage ~= "paged1") and actionPage.."_"..state or state
end

---with multiSpec the default tree only shows until a spec is picked, see Button:CopyDefaultToSpec.
---@param bar Bar
local function getSpecs(bar)
	local multiSpec = bar:GetMultiSpec()
	local activeSpec = Spec.active(multiSpec)

	local specs = {}
	if not multiSpec or Photon.hasTalentGroups or activeSpec == "default" then
		table.insert(specs, {index = "default", name = Photon.hasTalentGroups and L["Spec 1"] or L["Default"]})
	end

	if multiSpec then
		local names = Spec.names(multiSpec)
		for index = 1, 4 do
			if names[index] then
				table.insert(specs, {index = index, name = names[index]})
			end
		end
	end

	return specs, activeSpec
end

---place in the row and row, from the top. the top row holds the leftovers, see Bar:SetObjectLoc.
---only linear bars have rows
---@return number, number|nil
local function buttonPosition(button)
	local bar = button.bar
	local count, columns = #bar.buttons, bar:GetColumns() or 0

	if bar:GetBarShape() ~= "linear" then
		return button.id, nil
	elseif columns == 0 or columns >= count then
		return button.id, 1
	end

	local topRow = count % columns
	if topRow == 0 then
		topRow = columns
	end

	if button.id <= topRow then
		return button.id, 1
	end
	local after = button.id - topRow - 1
	return after % columns + 1, math.floor(after / columns) + 2
end

--the page an empty page takes its macro from, see Button:GetResolvedData
local function sourceName(button, specData, specName, data)
	for state, stateData in pairs(specData) do
		if stateData == data then
			return specData == button.DB.default and pageName(state) or specName.." - "..pageName(state)
		end
	end
	for state, stateData in pairs(button.DB.default) do
		if stateData == data then
			return L["Default"].." - "..pageName(state)
		end
	end
end

--alt1 on the default, stance1_alt1 on a form
local function pageState(tab, modifier)
	return tab == "homestate" and modifier or tab.."_"..modifier
end

-------------------------------- selection --------------------------------

---marks the page in the list and its editor. scroll brings the editor to the top
local function selectPage(page, scroll)
	selected.page = page

	for _, row in ipairs(rowPool.used) do
		local isSelected = row.page == page
		row.selectedBg:SetShown(isSelected)
		row.marker:SetShown(isSelected)
		row.label:SetTextColor(unpack(isSelected and Style.text or Style.dim))
	end

	for editorPage, editor in pairs(view.editors) do
		local isSelected = editorPage == page
		editor.selectedBg:SetShown(isSelected)
		editor.marker:SetShown(isSelected)
	end

	removeButton:SetEnabled(view.editors[page] ~= nil and view.editors[page].onRemove ~= nil)

	if scroll and view.editors[page] then
		editors:ScrollTo(view.editors[page].offset)
	end
end

-------------------------------- page editor --------------------------------

---a title and a line of help on hover
local function addTooltip(frame, title, desc)
	frame:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(title, 1, 1, 1)
		GameTooltip:AddLine(desc, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	frame:HookScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

--the selected look, a light background with an accent line on the left, inset from the edge
local function addSelection(frame, inset)
	frame.selectedBg = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
	frame.selectedBg:SetPoint("TOPLEFT", inset, -inset)
	frame.selectedBg:SetPoint("BOTTOMRIGHT", -inset, inset)
	frame.selectedBg:SetColorTexture(unpack(Style.selected))

	frame.marker = frame:CreateTexture(nil, "ARTWORK")
	frame.marker:SetColorTexture(unpack(Style.accent))
	frame.marker:SetPoint("TOPLEFT", inset, -inset)
	frame.marker:SetPoint("BOTTOMLEFT", inset, inset)
	frame.marker:SetWidth(2)
end

local function createRow(parent)
	local row = CreateFrame("Button", nil, parent)
	row:SetHeight(Style.rowHeight)
	addSelection(row, 0)

	local hover = row:CreateTexture(nil, "HIGHLIGHT")
	hover:SetAllPoints()
	hover:SetColorTexture(unpack(Style.hover))

	row.label = UI.Text(row)
	row.label:SetPoint("LEFT", 8, 0)
	row.label:SetPoint("RIGHT", -4, 0)
	row.label:SetWordWrap(false)

	row:SetScript("OnEnter", function(self)
		if self.desc then
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:SetText(self.label:GetText(), 1, 1, 1)
			GameTooltip:AddLine(self.desc, nil, nil, nil, true)
			GameTooltip:Show()
		end
	end)
	row:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	row:SetScript("OnClick", function(self)
		local editor = view.editors[self.page]
		if editor and editor.collapsed then
			editor.onToggle()
		end
		selectPage(self.page, true)
	end)
	return row
end

local function createPageEditor(parent)
	local editor = UI.Box(parent)
	addSelection(editor, editor.edge)

	--folds a modifier page
	editor.header = CreateFrame("Button", nil, editor.strip)
	editor.header:SetAllPoints()
	editor.header:SetScript("OnClick", function()
		editor.onToggle()
	end)

	editor.arrow = UI.Text(editor.header, Style.fontLarge, Style.dim)
	editor.arrow:SetPoint("LEFT", Style.padding, 0)
	editor.arrow:SetWidth(12)
	editor.arrow:SetJustifyH("CENTER")


	editor.notice = UI.Text(editor, Style.fontSmall, Style.dim)
	editor.notice:SetWordWrap(true)

	--opens the icon selector
	editor.iconFrame = UI.IconButton(editor, ICON_SIZE)
	editor.icon = editor.iconFrame.icon
	editor.iconFrame:SetScript("OnClick", function()
		selectPage(editor.page)
		PhotonGUI:OpenIconSelector(function(icon)
			editor.onIcon(icon)
		end)
	end)
	addTooltip(editor.iconFrame, L["Icon"], L["ButtonEditor_IconDesc"])

	editor.labelCaption = UI.Text(editor, Style.fontSmall, Style.dim)
	editor.labelCaption:SetText(L["Edit Label"])
	editor.labelBox = UI.EditBox(editor, function(text)
		editor.onLabel(text)
	end)
	addTooltip(editor.labelBox, L["Edit Label"], L["ButtonEditor_LabelDesc"])

	editor.macroCaption = UI.Text(editor, Style.fontSmall, Style.dim)
	editor.macroCaption:SetText("Edit Macro")
	editor.macroBox = UI.MultiLineEditBox(editor, 4, function(text)
		editor.onMacro(text)
	end)

	editor.resetIcon = UI.Button(editor, L["Reset Icon"], function()
		editor.onResetIcon()
	end)
	addTooltip(editor.resetIcon, L["Reset Icon"], L["ButtonEditor_ResetIconDesc"])

	--empties the page, whatever it would fall back on
	editor.forceBlank = UI.Checkbox(editor, function(checked)
		editor.onForceBlank(checked)
	end)
	editor.forceBlank:SetLabel(L["Force Blank"])
	editor.forceBlank:SetWidth(16 + Style.gap + editor.forceBlank.label:GetStringWidth() + 4)
	editor.forceBlank:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(L["Force Blank"], 1, 1, 1)
		GameTooltip:AddLine(L["ButtonEditor_ForceBlankDesc"], nil, nil, nil, true)
		GameTooltip:Show()
	end)
	editor.forceBlank:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	--everything under the title row
	editor.parts = {
		editor.notice, editor.iconFrame, editor.labelCaption, editor.labelBox,
		editor.macroCaption, editor.macroBox, editor.forceBlank, editor.resetIcon,
	}

	--grayed out and locked while forced blank, all but the tickbox
	editor.blankParts = {
		editor.notice, editor.iconFrame, editor.labelCaption, editor.labelBox,
		editor.macroCaption, editor.macroBox, editor.resetIcon,
	}
	function editor:SetBlank(blank)
		self.forceBlank:SetChecked(blank)
		for _, part in ipairs(self.blankParts) do
			part:SetAlpha(blank and 0.4 or 1)
		end
		for _, control in ipairs({self.iconFrame, self.labelBox, self.macroBox.editBox, self.resetIcon}) do
			if blank and control.ClearFocus then
				control:ClearFocus()
			end
			control:SetEnabled(not blank)
		end
	end

	---collapsible pages show + or - and fold on a click on their title
	function editor:SetCollapsed(collapsible, collapsed)
		self.collapsed = collapsible and collapsed
		self.arrow:SetShown(collapsible)
		self.arrow:SetText(self.collapsed and "+" or "-")
		self.header:EnableMouse(collapsible)
	end

	--working in a page selects it, where it is
	for _, box in ipairs({editor.labelBox, editor.macroBox.editBox}) do
		box:HookScript("OnEditFocusGained", function()
			selectPage(editor.page)
		end)
	end
	editor:EnableMouse(true)
	editor:SetScript("OnMouseDown", function()
		selectPage(editor.page)
	end)

	return editor
end

---places the editor's parts for a width and returns its height
local function layoutPageEditor(editor, width)
	local pad, gap = Style.padding, Style.gap
	local y = editor.edge + Style.stripHeight

	for _, part in ipairs(editor.parts) do
		part:SetShown(not editor.collapsed)
	end
	if editor.collapsed then
		y = y + editor.edge
		editor:SetHeight(y)
		return y
	end
	editor.notice:SetShown(editor.showNotice)
	y = y + pad

	if editor.showNotice then
		editor.notice:ClearAllPoints()
		editor.notice:SetPoint("TOPLEFT", pad, -y)
		editor.notice:SetWidth(width - 2 * pad)
		y = y + editor.notice:GetStringHeight() + gap
	end

	editor.iconFrame:ClearAllPoints()
	editor.iconFrame:SetPoint("TOPLEFT", pad, -y)
	editor.labelCaption:ClearAllPoints()
	editor.labelCaption:SetPoint("TOPLEFT", pad + ICON_SIZE + gap, -y)
	editor.labelBox:ClearAllPoints()
	editor.labelBox:SetPoint("TOPLEFT", editor.labelCaption, "BOTTOMLEFT", 0, -3)
	editor.labelBox:SetWidth(width - 2 * pad - ICON_SIZE - gap)
	y = y + ICON_SIZE + gap

	editor.macroCaption:ClearAllPoints()
	editor.macroCaption:SetPoint("TOPLEFT", pad, -y)
	y = y + editor.macroCaption:GetStringHeight() + 3
	editor.macroBox:ClearAllPoints()
	editor.macroBox:SetPoint("TOPLEFT", pad, -y)
	editor.macroBox:SetWidth(width - 2 * pad)
	y = y + editor.macroBox:GetHeight() + gap

	editor.forceBlank:ClearAllPoints()
	editor.forceBlank:SetPoint("TOPLEFT", pad, -y)
	editor.resetIcon:ClearAllPoints()
	editor.resetIcon:SetPoint("LEFT", editor.forceBlank, "RIGHT", gap * 2, 0)
	y = y + Style.rowHeight + pad

	editor:SetHeight(y)
	return y
end

---stacks the editors in the scroll area, remembering where each starts
local function layoutEditors()
	local width = editors:GetContentWidth()
	local y = 0

	--side by side, a column per form, each row as tall as its tallest editor
	if view.columns then
		local columnWidth = math.floor((width - Style.gap * (view.columns - 1)) / view.columns)
		local rows = {}
		for _, page in ipairs(view.pages) do
			local row = view.row[page]
			rows[row] = rows[row] or {}
			table.insert(rows[row], page)
		end
		--a line across the columns between rows, in the middle of a wider gap
		view.dividers = view.dividers or {}
		for _, divider in ipairs(view.dividers) do
			divider:Hide()
		end
		local rowGap = Style.gap * 3
		for index, rowPages in ipairs(rows) do
			if index > 1 then
				local divider = view.dividers[index - 1]
				if not divider then
					divider = editors.child:CreateTexture(nil, "ARTWORK")
					divider:SetColorTexture(0.3, 0.3, 0.3, 1)
					divider:SetHeight(1)
					view.dividers[index - 1] = divider
				end
				divider:ClearAllPoints()
				divider:SetPoint("TOPLEFT", 0, -(y - math.ceil(rowGap / 2)))
				divider:SetPoint("TOPRIGHT", 0, -(y - math.ceil(rowGap / 2)))
				divider:Show()
			end
			local height = 0
			for _, page in ipairs(rowPages) do
				local editor = view.editors[page]
				editor:ClearAllPoints()
				editor:SetPoint("TOPLEFT", (view.column[page] - 1) * (columnWidth + Style.gap), -y)
				editor:SetWidth(columnWidth)
				editor.offset = y
				height = math.max(height, layoutPageEditor(editor, columnWidth))
			end
			y = y + height + rowGap
		end
		editors:SetContentHeight(math.max(0, y - rowGap))
		return
	end

	--tabs have no rows
	for _, divider in ipairs(view.dividers or {}) do
		divider:Hide()
	end

	for _, page in ipairs(view.pages) do
		local editor = view.editors[page]
		editor:ClearAllPoints()
		editor:SetPoint("TOPLEFT", 0, -y)
		editor:SetWidth(width)
		editor.offset = y
		y = y + layoutPageEditor(editor, width) + Style.gap
	end
	editors:SetContentHeight(math.max(0, y - Style.gap))
end

--a bar loads again once typing pauses, not on every key
local loadPending = {}
local combatWaiter = CreateFrame("Frame")
combatWaiter:SetScript("OnEvent", function(self)
	self:UnregisterAllEvents()
	for bar in pairs(loadPending) do
		loadPending[bar] = nil
		bar:Load()
	end
end)

local function loadSoon(bar)
	if loadPending[bar] then
		return
	end
	loadPending[bar] = true
	C_Timer.After(0.2, function()
		--combat started while typing, the bar loads when it ends
		if InCombatLockdown() then
			combatWaiter:RegisterEvent("PLAYER_REGEN_ENABLED")
			return
		end
		loadPending[bar] = nil
		bar:Load()
	end)
end

---@param collapsible boolean @modifier pages fold
local function bindPageEditor(editor, button, specIndex, specName, page, collapsible)
	local bar = button.bar
	local multiSpec = bar:GetMultiSpec()
	local specData = button.DB[specIndex]
	local own = rawget(specData, page)

	editor.page = page
	editor.title:SetText(specIndex == "default" and pageName(page) or specName.." - "..pageName(page))

	local function update(fields)
		local data = specData[page]
		for k, v in pairs(fields) do
			data[k] = v
		end

		if specIndex ~= "default" and Spec.active(multiSpec) ~= specIndex then
			-- don't update the button if the modified spec isn't active
			return
		end

		-- for some reason we need to do a full bar load or the buttons don't update
		loadSoon(bar)
	end

	local function refreshIcon()
		local data = button:GetResolvedData(page, specData)
		editor.icon:SetTexture(not data.forceBlank and button:GetAppearance(data) or "INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK")
	end

	--without a macro of its own, the one it uses shows grayed out
	editor.showFallback = function()
		refreshIcon()

		local fallback
		editor.showNotice = not hasMacro(own)
		if editor.showNotice then
			fallback = button:GetResolvedData(page, specData)
			local source = hasMacro(fallback) and sourceName(button, specData, specName, fallback)
			local notice = fallback.forceBlank and L["ButtonEditor_InheritsBlank"] or L["ButtonEditor_Inherits"]
			editor.notice:SetText(source and string.format(notice, source) or L["ButtonEditor_Empty"])
			--a blank one has nothing to show
			if not source or fallback.forceBlank then
				fallback = nil
			end
		end
		editor.labelBox:SetPlaceholder(fallback and fallback.macro_Name)

		--with a macro of its own, what it falls back on once that is deleted, grayed as soon as the box is empty
		local macroFallback = fallback
		if not editor.showNotice and not own.forceBlank then
			rawset(specData, page, nil)
			local data = button:GetResolvedData(page, specData)
			rawset(specData, page, own)
			macroFallback = hasMacro(data) and not data.forceBlank and data or nil
		end
		editor.macroBox:SetPlaceholder(macroFallback and type(macroFallback.macro_Text) == "string" and macroFallback.macro_Text)
	end

	editor.labelBox:SetText(own and own.macro_Name or "")
	editor.macroBox:SetText(own and type(own.macro_Text) == "string" and own.macro_Text or "")
	editor.showFallback()

	--the editor being typed in keeps its text and cursor, the rest show what they use now
	local function refreshOthers()
		for _, other in pairs(view.editors) do
			if other ~= editor then
				other.showFallback()
			end
		end
	end

	editor.onLabel = function(text)
		update{macro_Name = text}
		refreshOthers()
	end
	editor.onMacro = function(text)
		update{macro_Text = text}
		refreshIcon()
		refreshOthers()
	end
	editor.onResetIcon = function()
		update{macro_Icon = false}
		refreshIcon()
		refreshOthers()
	end
	editor.onIcon = function(icon)
		update{macro_Icon = icon}
		refreshIcon()
		refreshOthers()
	end
	--the page keeps its macro for when it is unticked. other pages may fall back on it, so all of them update
	editor:SetBlank(own ~= nil and own.forceBlank == true)
	editor.onForceBlank = function(checked)
		specData[page].forceBlank = checked or nil
		update{}
		render()
	end
	--modifier pages fold, and start folded without text
	local isExpanded = expanded[page]
	if isExpanded == nil then
		isExpanded = hasText(own)
	end
	editor:SetCollapsed(collapsible, not isExpanded)
	editor.onToggle = function()
		expanded[page] = editor.collapsed
		editor:SetCollapsed(true, not editor.collapsed)
		layoutEditors()
		selectPage(page)
	end
end

-------------------------------- tab --------------------------------

---the tab's own page, then one per modifier the row uses. actionPages is empty on a bar without pages.
---side by side, column is the tab's place and the pages add to the ones on show
local function fillTab(button, specIndex, specName, forms, modifiers, actionPages, tab, column)
	local bar = button.bar
	local multiSpec = bar:GetMultiSpec()
	local actionPage = selected.actionPage
	local tabStates = {"homestate", unpack(forms)}

	--a modifier's keys on every action bar page and form. allPages includes pages the bar has off, they keep their data
	local function modifierKeys(modifier, allPages)
		local keys = {}
		for _, page in ipairs(allPages and ALL_PAGES or #actionPages > 0 and actionPages or {"paged1"}) do
			for _, tabState in ipairs(tabStates) do
				table.insert(keys, onPage(page, pageState(tabState, modifier)))
			end
		end
		return keys
	end

	--a circle's buttons are all one row
	local _, row = buttonPosition(button)
	local rowButtons = {}
	for _, other in ipairs(bar.buttons) do
		if select(2, buttonPosition(other)) == row then
			table.insert(rowButtons, other)
		end
	end

	--added modifiers by row and spec, data.modifiers["2"]["1"].alt1 = true, so they show before they have a macro
	local rowKey, specKey = tostring(row or 1), tostring(specIndex)
	local added = bar.data.modifiers and bar.data.modifiers[rowKey] and bar.data.modifiers[rowKey][specKey] or {}

	--leaves no empty tables behind
	local function setAdded(modifier, value)
		local rows = bar.data.modifiers or {}
		local specs = rows[rowKey] or {}
		local rowAdded = specs[specKey] or {}
		rowAdded[modifier] = value
		specs[specKey] = next(rowAdded) and rowAdded or nil
		rows[rowKey] = next(specs) and specs or nil
		bar.data.modifiers = next(rows) and rows or nil
	end

	local function inUse(modifier)
		if added[modifier] then
			return true
		end
		local keys = modifierKeys(modifier)
		for _, rowButton in ipairs(rowButtons) do
			for _, key in ipairs(keys) do
				if hasMacro(rawget(rowButton.DB[specIndex], key)) then
					return true
				end
			end
		end
		return false
	end

	local pages, modifierOf = {onPage(actionPage, tab)}, {}
	view.available = {}
	for _, modifier in ipairs(modifiers) do
		if inUse(modifier) then
			local state = onPage(actionPage, pageState(tab, modifier))
			table.insert(pages, state)
			modifierOf[state] = modifier
		else
			table.insert(view.available, modifier)
		end
	end
	for index, page in ipairs(pages) do
		table.insert(view.pages, page)
		view.column[page] = column
		view.row[page] = index
	end

	if not column and not tContains(pages, selected.page) then
		selected.page = pages[1]
	end

	view.addModifier = function(modifier)
		--the pages only work with the modifier on for the bar
		local barState = modifier:match("^%a+")
		if not bar.data[barState] then
			bar:SetState(barState, true, true)
		end

		setAdded(modifier, true)
		selected.page = onPage(actionPage, pageState(tab, modifier))
		expanded[selected.page] = true
		render()
	end

	-------------------------------- page list --------------------------------
	--side by side has no page list
	local previous
	for _, page in ipairs(column and {} or pages) do
		local item = rowPool:Acquire()
		item.page = page
		--the tab already names the form
		item.label:SetText(modifierOf[page] and stateName(modifierOf[page]) or L["Default"])
		item.desc = stateDesc(modifierOf[page] or "homestate")
		if previous then
			item:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -2)
			item:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -2)
		else
			local inset = item:GetParent().edge + 3
			item:SetPoint("TOPLEFT", inset, -inset)
			item:SetPoint("TOPRIGHT", -inset, -inset)
		end
		previous = item
	end

	addButton:SetEnabled(#view.available > 0)

	-------------------------------- macros --------------------------------
	for _, page in ipairs(pages) do
		--clears the modifier from the whole row, on every page and form
		local modifier = modifierOf[page]
		local onRemove = modifier and function()
			StaticPopup_Show("NEURON_REMOVE_MODIFIER", stateName(modifier), string.format(L["ButtonEditor_RowOfSpec"], row or 1, specName), function()
				local keys = modifierKeys(modifier, true)
				for _, rowButton in ipairs(rowButtons) do
					for _, key in ipairs(keys) do
						rowButton.DB[specIndex][key] = nil
					end
				end
				setAdded(modifier, nil)
				selected.page = pages[1]

				if specIndex == "default" or Spec.active(multiSpec) == specIndex then
					bar:Load()
				end
				render()
			end)
		end or nil

		local editor = editorPool:Acquire()
		bindPageEditor(editor, button, specIndex, specName, page, modifier ~= nil)
		editor.onRemove = onRemove
		view.editors[page] = editor
	end
end

-------------------------------- window --------------------------------

---the page tabs are only there with action bar pages, the form tabs with forms
local function placeBody()
	local top = 0
	if specRow:IsShown() then
		top = top + SPEC_ROW_SPACE + specRow:GetHeight() + Style.gap + modifierRow:GetHeight() + SPEC_ROW_SPACE
	end
	local lastTabRow
	for _, tabRow in ipairs({pageTabs, tabs}) do
		if tabRow:IsShown() then
			tabRow:ClearAllPoints()
			tabRow:SetPoint("TOPLEFT", 0, -top)
			tabRow:SetPoint("TOPRIGHT", 0, -top)
			top = top + tabRow:GetHeight() + Style.gap
			lastTabRow = tabRow
		end
	end
	--the last tab on the tab row over the pages, or left of remove without tabs. it shows with what it sits on
	--expand is a tab before ?, it only shows with the forms' tabs
	expandButton:SetParent(tabs)
	expandButton:ClearAllPoints()
	local helpAfter = lastTabRow and lastTabRow.lastTab
	if lastTabRow == tabs then
		expandButton:SetHeight(tabs.lastTab:GetHeight())
		expandButton:SetPoint("LEFT", tabs.lastTab, "RIGHT", 2, 0)
		helpAfter = expandButton
	end
	helpButton:ClearAllPoints()
	if lastTabRow then
		helpButton:SetParent(lastTabRow)
		helpButton:SetHeight(lastTabRow.lastTab:GetHeight())
		helpButton:SetPoint("LEFT", helpAfter, "RIGHT", 2, 0)
	else
		helpButton:SetParent(modifierRow)
		helpButton:SetHeight(Style.rowHeight)
		helpButton:SetPoint("RIGHT", removeButton, "LEFT", -Style.gap, 0)
	end
	body:ClearAllPoints()
	body:SetPoint("TOPLEFT", 0, -top)
	body:SetPoint("BOTTOMRIGHT")
end

local function createWindow()
	window = UI.Window("PhotonButtonEditorFrame", L["Button Editor"])
	window:SetSize(660, 700)
	window:SetMinSize(560, 420)
	window:SetScript("OnHide", function()
		PhotonGUI:CloseIconSelector()
		PhotonGUI:CloseVisualOverride()
		lastButton = nil
		if Photon.buttonEditMode then
			Photon:ToggleButtonEditMode(false)
		end
	end)

	local content = window.content

	emptyText = UI.Text(content, nil, Style.dim)
	emptyText:SetPoint("TOPLEFT")
	emptyText:SetText(L["ButtonEditor_SelectButton"])

	-------------------------------- spec and modifiers --------------------------------
	specRow = CreateFrame("Frame", nil, content)
	specRow:SetPoint("TOPLEFT", 0, -SPEC_ROW_SPACE)
	specRow:SetPoint("TOPRIGHT", 0, -SPEC_ROW_SPACE)
	specRow:SetHeight(Style.rowHeight)

	specLabel = UI.Text(specRow, nil, Style.dim)
	specLabel:SetPoint("LEFT")
	specLabel:SetText(L["Specialization"])

	specDropdown = UI.Dropdown(specRow, function(value)
		selected.spec = value
		render()
	end)
	specDropdown:SetPoint("LEFT", specLabel, "RIGHT", Style.gap * 2, 0)
	specDropdown:SetWidth(220)

	--on the right in a light box: the button's own visuals over its bar's, set in a window of their own, see VisualOverrideWindow.lua
	local overrideBox = CreateFrame("Frame", nil, specRow)
	Style.Flat(overrideBox, Style.panelLight)
	overrideBox:SetPoint("RIGHT")
	overrideCheck = UI.Checkbox(overrideBox, function(checked)
		Photon.currentButton:SetVisualOverride(checked)
		if checked then
			PhotonGUI:OpenVisualOverride()
		else
			PhotonGUI:CloseVisualOverride()
		end
	end)
	overrideCheck:SetLabel(L["Override Visuals"])
	overrideCheck:SetWidth(16 + Style.gap + overrideCheck.label:GetStringWidth() + 4)
	overrideCheck:SetPoint("LEFT", Style.gap, 0)
	overrideBox:SetSize(overrideCheck:GetWidth() + Style.gap * 2, Style.rowHeight + 4)
	addTooltip(overrideCheck, L["Override Visuals"], L["OverrideVisuals_Desc"])

	modifierRow = CreateFrame("Frame", nil, specRow)
	modifierRow:SetPoint("TOPLEFT", specRow, "BOTTOMLEFT", 0, -Style.gap)
	modifierRow:SetPoint("TOPRIGHT", specRow, "BOTTOMRIGHT", 0, -Style.gap)
	modifierRow:SetHeight(Style.rowHeight)

	addButton = UI.MenuButton(modifierRow, L["Add page for condition"], function(root)
		local lastSection
		for _, modifier in ipairs(view.available) do
			--a gap between the bar config's boxes
			local condition = CONDITION_ORDER[modifier:match("^%a+")]
			local section = condition and condition.section
			if lastSection and section ~= lastSection and root.CreateSpacer then
				root:CreateSpacer()
			end
			lastSection = section

			local entry = root:CreateButton(stateName(modifier), function()
				view.addModifier(modifier)
			end)
			local desc = stateDesc(modifier)
			--older menus have no tooltips
			if desc and entry.SetTooltip then
				entry:SetTooltip(function(tooltip)
					GameTooltip_SetTitle(tooltip, stateName(modifier))
					GameTooltip_AddNormalLine(tooltip, desc)
				end)
			end
		end
	end)
	local conditionLabel = UI.Text(modifierRow, nil, Style.dim)
	conditionLabel:SetPoint("LEFT")
	conditionLabel:SetText(L["Condition"])
	--both captions as wide as the longer one, so the spec dropdown and adding a page line up
	local captionWidth = math.max(specLabel:GetStringWidth(), conditionLabel:GetStringWidth())
	for _, caption in ipairs({specLabel, conditionLabel}) do
		caption:SetWidth(captionWidth)
		caption:SetJustifyH("LEFT")
	end
	addButton:SetPoint("LEFT", conditionLabel, "RIGHT", Style.gap * 2, 0)

	--removes the selected page's modifier
	removeButton = UI.Button(modifierRow, L["Remove page"], function()
		view.editors[selected.page].onRemove()
	end)
	removeButton:SetPoint("RIGHT")
	addTooltip(removeButton, L["Remove page"], L["ButtonEditor_RemovePageDesc"])

	--a tab like the forms' that shows default and every form side by side, open while it is on.
	--a form's tab goes back to tabs, see the tabs' onSelect
	expandButton = CreateFrame("Button", nil, specRow)
	Style.Flat(expandButton, Style.strip)
	--gold like ?, open or not
	expandButton.label = UI.Text(expandButton, nil, Style.accent)
	expandButton.label:SetPoint("CENTER", 0, 1)
	expandButton.label:SetText(L["ButtonEditor_AllForms"])
	expandButton:SetWidth(expandButton.label:GetStringWidth() + 24)
	expandButton.opening = expandButton:CreateTexture(nil, "OVERLAY")
	expandButton.opening:SetColorTexture(unpack(Style.window))
	expandButton.opening:SetPoint("BOTTOMLEFT", 1, 0)
	expandButton.opening:SetPoint("BOTTOMRIGHT", -1, 0)
	expandButton.opening:SetHeight(1)
	local expandHover = expandButton:CreateTexture(nil, "HIGHLIGHT")
	expandHover:SetAllPoints()
	expandHover:SetColorTexture(unpack(Style.hover))
	function expandButton:SetOpen(open)
		self.photonFlat.bg:SetColorTexture(unpack(open and Style.window or Style.strip))
		self.opening:SetShown(open)
	end
	expandButton:SetScript("OnClick", function()
		if not selected.allForms then
			selected.allForms = true
			selected.page = nil
			render()
		end
	end)
	expandButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(L["ButtonEditor_AllForms"], 1, 1, 1)
		GameTooltip:AddLine((L["ButtonEditor_AllFormsDesc"]:gsub("{form}", addonTable.optionDefinitions.formWord())), nil, nil, nil, true)
		GameTooltip:Show()
	end)
	expandButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	--how default works on hover, placed with the tabs, see placeBody
	helpButton = CreateFrame("Button", nil, specRow)
	Style.Flat(helpButton, Style.strip)
	--a tab that is not open, with a gold ? to stand out
	local helpLabel = UI.Text(helpButton, nil, Style.accent)
	helpLabel:SetPoint("CENTER", 0, 1)
	helpLabel:SetText("?")
	helpButton:SetWidth(helpLabel:GetStringWidth() + 24)
	local helpHover = helpButton:CreateTexture(nil, "HIGHLIGHT")
	helpHover:SetAllPoints()
	helpHover:SetColorTexture(unpack(Style.hover))
	--a short blank line between the text's lines, a full one is too much
	local spacerFont = CreateFont("PhotonTooltipSpacerFont")
	local fontPath, _, fontFlags = GameTooltipText:GetFont()
	spacerFont:SetFont(fontPath, 4, fontFlags or "")

	--the tooltip is shared, so its width and the spacer lines' font go back when it hides
	local spacers, widened = {}, false
	GameTooltip:HookScript("OnHide", function(tooltip)
		for _, line in ipairs(spacers) do
			line:SetFontObject(GameTooltipText)
		end
		wipe(spacers)
		if widened then
			tooltip:SetMinimumWidth(0)
			widened = false
		end
	end)

	helpButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
		GameTooltip:SetText(L["Default"], 1, 1, 1)
		local help = L["ButtonEditor_DefaultHelp"]:gsub("{form}", addonTable.optionDefinitions.formWord())
		for paragraph in help:gmatch("[^\n]+") do
			if GameTooltip:NumLines() > 1 then
				GameTooltip:AddLine(" ")
				local spacer = _G["GameTooltipTextLeft"..GameTooltip:NumLines()]
				spacer:SetFontObject(spacerFont)
				table.insert(spacers, spacer)
			end
			GameTooltip:AddLine(paragraph, nil, nil, nil, true)
		end
		GameTooltip:Show()
		--twice the usual width, so the long text wraps less
		GameTooltip:SetMinimumWidth(GameTooltip:GetWidth() * 2)
		widened = true
		GameTooltip:Show()
	end)
	helpButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-------------------------------- action bar pages --------------------------------
	pageTabs = UI.Tabs(content, function(value)
		selected.actionPage = value
		selected.page = nil
		render()
	end)

	-------------------------------- default and forms --------------------------------
	tabs = UI.Tabs(content, function(value)
		selected.tab = value
		selected.allForms = nil
		selected.page = nil
		render()
	end)

	body = CreateFrame("Frame", nil, content)

	-------------------------------- page list --------------------------------
	left = UI.Box(body)
	left.strip:Hide()
	left:SetPoint("TOPLEFT")
	left:SetPoint("BOTTOMLEFT")

	rowPool = UI.Pool(function()
		return createRow(left)
	end)

	-------------------------------- macros --------------------------------
	editors = UI.ScrollArea(body)
	editors:SetPoint("BOTTOMRIGHT")
	editorPool = UI.Pool(function()
		return createPageEditor(editors.child)
	end)

	--the selected page stays in view as the window gets its size
	editors.OnResize = function()
		layoutEditors()
		if selected.page then
			selectPage(selected.page, true)
		end
	end

	body:SetScript("OnSizeChanged", function(_, width)
		left:SetWidth(math.floor(width * 0.28))
	end)
end

function render()
	if not window or not window:IsShown() then
		return
	end

	--a pick would go to a page that is no longer on show
	PhotonGUI:CloseIconSelector()

	rowPool:ReleaseAll()
	editorPool:ReleaseAll()
	wipe(view.editors)
	wipe(view.column)
	wipe(view.row)
	view.pages = {}
	view.columns = nil

	local button = Photon.currentButton

	--the visuals window follows the selection: open for a button with its own visuals, closed for the rest
	if button ~= lastButton then
		lastButton = button
		if button and button.bar.class == "ActionBar" and button:HasVisualOverride() then
			PhotonGUI:OpenVisualOverride()
		else
			PhotonGUI:CloseVisualOverride()
		end
	end

	if not button or button.bar.class ~= "ActionBar" then
		window:SetStatus(L["ButtonEditor_SelectButton"])
		specRow:Hide()
		pageTabs:Hide()
		tabs:Hide()
		body:Hide()
		emptyText:Show()
		return
	end

	emptyText:Hide()
	body:Show()

	local bar = button.bar
	window:SetStatus(string.format(L["ButtonEditor_Status"], bar:GetBarName(), button.id))

	-------------------------------- spec --------------------------------
	local specs, activeSpec = getSpecs(bar)
	local spec, active
	for _, candidate in ipairs(specs) do
		if candidate.index == selected.spec then
			spec = candidate
		end
		if candidate.index == activeSpec then
			active = candidate
		end
	end
	spec = spec or active or specs[1]
	selected.spec = spec.index

	local items = {}
	for _, candidate in ipairs(specs) do
		table.insert(items, {value = candidate.index, text = candidate.name})
	end
	specDropdown:SetItems(items)
	specDropdown:SetValue(spec.index)
	specDropdown:SetEnabled(#specs > 1)
	specRow:Show()

	overrideCheck:SetChecked(button:HasVisualOverride())

	-------------------------------- default and forms --------------------------------
	--a pet bar has its pet page as a tab, in place of forms. action bar pages go around both
	local forms, modifiers, actionPages = {}, {}, {}
	for _, state in ipairs(getStateList(bar)) do
		if state:match("^paged%d+$") then
			table.insert(actionPages, state)
		elseif state:match("^stance%d+$") or state:match("^pet%d+$") then
			table.insert(forms, state)
		else
			table.insert(modifiers, state)
		end
	end

	-------------------------------- action bar pages --------------------------------
	--page 1 holds everything a bar has without pages, 2-6 fall back on it
	if #actionPages > 0 then
		table.insert(actionPages, 1, "paged1")
		if not tContains(actionPages, selected.actionPage) then
			selected.actionPage = "paged1"
		end
		local pageList = {}
		for _, page in ipairs(actionPages) do
			table.insert(pageList, {text = stateName(page), value = page})
		end
		pageTabs:SetTabs(pageList, selected.actionPage)
		pageTabs:Show()
	else
		selected.actionPage = nil
		pageTabs:Hide()
	end

	if not tContains(forms, selected.tab) then
		selected.tab = "homestate"
	end

	local sideBySide = selected.allForms and #forms > 0
	expandButton:SetOpen(sideBySide)

	--the window widens to fit the columns, and goes back after
	if sideBySide then
		narrowWidth = narrowWidth or window:GetWidth()
		local wanted = math.min(40 + (#forms + 1) * 280, UIParent:GetWidth())
		if window:GetWidth() < wanted then
			window:SetWidth(wanted)
		end
	elseif narrowWidth then
		window:SetWidth(narrowWidth)
		narrowWidth = nil
	end

	left:SetShown(not sideBySide)
	editors:ClearAllPoints()
	editors:SetPoint("BOTTOMRIGHT")
	if sideBySide then
		editors:SetPoint("TOPLEFT")
	else
		editors:SetPoint("TOPLEFT", left, "TOPRIGHT", Style.padding, 0)
	end

	--side by side no form's tab is open, expand is
	if #forms > 0 then
		--with a pet bar the default is what shows without a pet
		local tabList = {{text = bar.data.pet and L["No Pet"] or L["Default"], value = "homestate"}}
		for _, form in ipairs(forms) do
			table.insert(tabList, {text = stateName(form), value = form})
		end
		tabs:SetTabs(tabList, not sideBySide and selected.tab or nil)
		tabs:Show()
	else
		tabs:Hide()
	end

	local context = tostring(button)..":"..tostring(spec.index)..":"..tostring(selected.actionPage)..":"..(sideBySide and "all" or selected.tab)
	if context ~= expandedFor then
		wipe(expanded)
		expandedFor = context
	end

	placeBody()
	if sideBySide then
		local tabStates = {"homestate", unpack(forms)}
		view.columns = #tabStates
		for column, tab in ipairs(tabStates) do
			fillTab(button, spec.index, spec.name, forms, modifiers, actionPages, tab, column)
		end
		if not tContains(view.pages, selected.page) then
			selected.page = view.pages[1]
		end
	else
		fillTab(button, spec.index, spec.name, forms, modifiers, actionPages, selected.tab)
	end

	layoutEditors()
	selectPage(selected.page, true)
end

function PhotonGUI:OpenButtonEditor()
	if not Photon.buttonEditMode then
		Photon:ToggleButtonEditMode(true)
	end

	if not window then
		createWindow()
	end
	window:Show()

	render()
end

function PhotonGUI:RefreshButtonEditor()
	render()
end

---Override Visuals again, after Clear Button Overrides in the bar config
function PhotonGUI:UpdateVisualOverrideCheck()
	local button = Photon.currentButton
	if overrideCheck and button then
		overrideCheck:SetChecked(button:HasVisualOverride())
	end
end

function PhotonGUI:CloseButtonEditor()
	if window then
		window:Hide() --leaves button edit mode, see createWindow
	end
end
