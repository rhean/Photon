-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Photon = addonTable.Photon

--the first GUI file to load, see Photon-GUI.xml
Photon.PhotonGUI = Photon.PhotonGUI or {}
local PhotonGUI = Photon.PhotonGUI

local L = LibStub("AceLocale-3.0"):GetLocale("Photon")

local UI = addonTable.ui
local Style = UI.Style

-----------------------------------------------------------------------------
--------------------------Bar Config Window----------------------------------
-----------------------------------------------------------------------------
--draws BarConfigLayout.lua with the settings from Options.lua. it is open while bars are edited

local UNITS = 8
local WIDTH_UNITS = {half = 1, normal = 2, double = 4, full = 8}

local STRIP_HEIGHT = Style.stripHeight

--bar types that also get the status bar appearance tabs
local STATUS_BARS = {XPBar = true, RepBar = true, CastBar = true, MirrorBar = true}

local window, barDropdown, wrapper, tabs, pageTabs, emptyText
--the window's boxes.
local mainView

--the shown tab and page, kept while the window is open
local selected = {}
local lastTab

local render
local renderPending

--a field of an AceConfig option, which may be a function
local function resolve(field)
	if type(field) == "function" then
		return field({})
	end
	return field
end

local function widthUnits(width)
	if type(width) == "number" then
		return math.max(1, math.min(UNITS, math.floor(width * 2 + 0.5)))
	end
	return WIDTH_UNITS[width] or 2
end

local function sliderHeld(view)
	for _, slider in ipairs(view.pools.range and view.pools.range.used or {}) do
		if slider.dragging then
			return true
		end
	end
	return false
end

--a setting can change what others show, so redraw on the next frame. not while a slider is held, its release asks again
local function requestRender()
	if renderPending then
		return
	end
	renderPending = true
	C_Timer.After(0, function()
		renderPending = false
		if mainView and not sliderHeld(mainView) then
			render()
		end
	end)
end

local function changed()
	requestRender()
end

StaticPopupDialogs["NEURON_BARCONFIG_CONFIRM"] = UI.RaisePopup{
	text = "%s",
	button1 = YES,
	button2 = NO,
	OnAccept = function(_, func)
		func()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

--the option's desc on hover, only over its label text. text gets no mouse, so a frame over it takes the hover.
--FitLabel sizes it after the text changes
local function labelTooltip(control)
	local hover = CreateFrame("Frame", nil, control)
	hover:SetPoint("TOPLEFT", control.label)
	hover:SetPoint("BOTTOMLEFT", control.label)
	--motion only, so a click on a checkbox's label still ticks it. older clients have no motion only
	if hover.EnableMouseMotion then
		hover:EnableMouseMotion(true)
	else
		hover:EnableMouse(true)
	end
	hover:SetScript("OnEnter", function(self)
		local desc = control.option and resolve(control.option.desc)
		if desc and desc ~= "" then
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:SetText(resolve(control.option.title or control.option.name) or "", 1, 1, 1)
			GameTooltip:AddLine(desc, nil, nil, nil, true)
			GameTooltip:Show()
		end
	end)
	hover:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	control.labelHover = hover

	function control:FitLabel()
		self.labelHover:SetWidth(math.max(1, self.label:GetStringWidth()))
	end
end

--a caption above a widget, in the same font as a slider's or checkbox's name
local function labelled(parent)
	local frame = CreateFrame("Frame", nil, parent)
	frame.label = UI.Text(frame)
	frame.label:SetPoint("TOPLEFT")
	frame.label:SetPoint("TOPRIGHT")
	frame.label:SetWordWrap(false)

	function frame:CaptionHeight()
		return math.ceil(self.label:GetStringHeight())
	end

	return frame
end

local function placeUnder(widget, frame)
	widget:SetPoint("TOPLEFT", frame.label, "BOTTOMLEFT", 0, -3)
	widget:SetPoint("TOPRIGHT", frame.label, "BOTTOMRIGHT", 0, -3)
end

-----------------------------------------------------------------------------
--------------------------Controls-------------------------------------------
-----------------------------------------------------------------------------
--one per AceConfig option type. create makes the frame, Bind shows an option on it,
--Measure gives its height for a width. control.changed runs after the option is set

local CONTROLS = {}

CONTROLS.toggle = function(parent)
	local control = UI.Checkbox(parent)
	labelTooltip(control)

	function control:Bind(option)
		self:SetLabel(resolve(option.name))
		self:FitLabel()
		self:SetChecked(option.get({}))
		self:SetDisabled(resolve(option.disabled))
		self.onChange = function(value)
			option.set({}, value)
			self.changed()
		end
	end

	function control:Measure()
		return Style.rowHeight
	end

	return control
end

CONTROLS.color = function(parent)
	local control = UI.ColorSwatch(parent)

	function control:Bind(option)
		self:SetLabel(resolve(option.name))
		self:SetColor(option.get({}))
		self:SetDisabled(resolve(option.disabled))
		--colors change nothing else, and the picker keeps sending them, so no redraw
		self.onChange = function(r, g, b, a)
			option.set({}, r, g, b, a)
		end
	end

	function control:Measure()
		return Style.rowHeight
	end

	--just the square, so colors sit side by side
	function control:FixedWidth()
		return self.swatch:GetWidth()
	end

	return control
end

CONTROLS.select = function(parent)
	local control = labelled(parent)
	control.dropdown = UI.Dropdown(control, function(value)
		control.onSelect(value)
	end)
	placeUnder(control.dropdown, control)
	labelTooltip(control)

	function control:Bind(option)
		self.label:SetText(resolve(option.name))
		self:FitLabel()

		--without a sorting, lists keep their order and the rest go by name
		local values = resolve(option.values) or {}
		local order = option.sorting
		if not order then
			order = {}
			local numbered = true
			for key in pairs(values) do
				table.insert(order, key)
				numbered = numbered and type(key) == "number"
			end
			table.sort(order, function(a, b)
				if numbered then
					return a < b
				end
				return tostring(values[a]) < tostring(values[b])
			end)
		end
		--disabledValues are on the list greyed out, valueTooltips show on hover.
		local disabledValues = resolve(option.disabledValues) or {}
		local valueTooltips = resolve(option.valueTooltips) or {}
		local items = {}
		for _, key in ipairs(order) do
			table.insert(items, {value = key, text = values[key], disabled = disabledValues[key], tooltip = valueTooltips[key]})
		end

		self.dropdown:SetItems(items)
		self.dropdown:SetValue(option.get({}))
		--an option's onHover gets the item under the mouse, nil when there is none
		self.dropdown.onHover = option.onHover
		self.dropdown:SetEnabled(not resolve(option.disabled))
		self.onSelect = function(value)
			option.set({}, value)
			self.changed()
		end
	end

	--blizzard's dropdown is taller than the flat one
	function control:Measure()
		return self:CaptionHeight() + 3 + math.max(self.dropdown:GetHeight(), Style.rowHeight)
	end

	return control
end

--a side, corner or the center of a frame, picked on a 3x3 grid. the picked one is gold
local GRID_CELL, GRID_GAP = 16, 2

CONTROLS.point = function(parent)
	local control = labelled(parent)
	labelTooltip(control)
	control.grid = CreateFrame("Frame", nil, control)
	control.grid:SetSize(GRID_CELL * 3 + GRID_GAP * 2, GRID_CELL * 3 + GRID_GAP * 2)
	control.grid:SetPoint("TOPLEFT", control.label, "BOTTOMLEFT", 0, -3)

	control.cells = {}
	for index, point in ipairs(Photon.Bar.ANCHOR_POINTS) do
		local cell = CreateFrame("Button", nil, control.grid)
		Style.Flat(cell, Style.strip)
		cell:SetSize(GRID_CELL, GRID_CELL)
		local column, row = (index - 1) % 3, math.floor((index - 1) / 3)
		cell:SetPoint("TOPLEFT", column * (GRID_CELL + GRID_GAP), -row * (GRID_CELL + GRID_GAP))
		local hover = cell:CreateTexture(nil, "HIGHLIGHT")
		hover:SetAllPoints()
		hover:SetColorTexture(unpack(Style.hover))
		cell:SetScript("OnClick", function()
			if control.onPick then
				control.onPick(point)
			end
		end)
		control.cells[point] = cell
	end

	function control:Bind(option)
		self.label:SetText(resolve(option.name))
		self:FitLabel()
		local value = option.get({})
		for point, cell in pairs(self.cells) do
			cell.photonFlat.bg:SetColorTexture(unpack(point == value and Style.accent or Style.strip))
		end
		local disabled = resolve(option.disabled)
		self.grid:SetAlpha(disabled and 0.5 or 1)
		self.onPick = not disabled and function(point)
			option.set({}, point)
			self.changed()
		end or nil
	end

	function control:Measure()
		return self:CaptionHeight() + 3 + self.grid:GetHeight()
	end

	return control
end

CONTROLS.input = function(parent)
	local control = labelled(parent)
	local box = UI.EditBox(control)
	placeUnder(box, control)
	labelTooltip(control)
	control.box = box

	--saved on enter or when leaving the box, escape puts it back
	box:HookScript("OnEditFocusLost", function(self)
		if control.commit and self:GetText() ~= control.committed then
			control.committed = self:GetText()
			control.commit(control.committed)
		end
	end)
	box:SetScript("OnEscapePressed", function(self)
		self:SetText(control.committed or "")
		self:ClearFocus()
	end)

	function control:Bind(option)
		self.label:SetText(resolve(option.name))
		self:FitLabel()
		self.commit = nil
		self.committed = option.get({}) or ""
		box:SetText(self.committed)
		box:SetEnabled(not resolve(option.disabled))
		self.commit = function(text)
			option.set({}, text)
			self.changed()
		end
	end

	function control:Measure()
		return self:CaptionHeight() + 3 + Style.rowHeight
	end

	return control
end

CONTROLS.range = function(parent)
	local control = UI.Slider(parent)
	labelTooltip(control)

	function control:Bind(option)
		self:SetLabel(resolve(option.name))
		self:FitLabel()
		self:SetRange(option.min or 0, option.max or 100, option.step, option.softMax, option.isPercent)
		--nudge = true gives it arrows either side that step it, see UI.Slider
		self:SetSteppers(option.nudge == true)
		self:SetValue(option.get({}) or option.min or 0)
		self:SetDisabled(resolve(option.disabled))
		--the bar follows while dragging, both windows catch up once it is let go
		self.onChange = function(value)
			option.set({}, value)
			if not self.dragging then
				self.changed()
			end
		end
		self.onRelease = self.changed
	end

	function control:Measure()
		return self.naturalHeight
	end

	return control
end

CONTROLS.execute = function(parent)
	local control = UI.Button(parent, "", function(self)
		local option = self.option
		local function run()
			option.func({})
			self.changed()
		end
		local confirm = resolve(option.confirm)
		if confirm then
			local text = type(confirm) == "string" and confirm or resolve(option.name).."?"
			StaticPopup_Show("NEURON_BARCONFIG_CONFIRM", text, nil, run)
		else
			run()
		end
	end)

	control.label = control:GetFontString()
	labelTooltip(control)

	function control:Bind(option)
		self.option = option
		self:SetText(resolve(option.name))
		self:FitLabel()
		self:SetEnabled(not resolve(option.disabled))
	end

	function control:Measure()
		return Style.rowHeight
	end

	return control
end

--a title strip like a box's
CONTROLS.header = function(parent)
	local control = CreateFrame("Frame", nil, parent)
	Style.Flat(control, Style.strip)
	control.text = UI.Text(control, nil, Style.accent)
	control.text:SetPoint("LEFT", Style.padding, 0)
	control.text:SetPoint("RIGHT", -Style.padding, 0)
	control.text:SetJustifyH("CENTER")
	control.text:SetWordWrap(false)

	function control:Bind(option)
		self.text:SetText(resolve(option.name) or "")
	end

	function control:Measure()
		return STRIP_HEIGHT
	end

	return control
end

--wrapping text. a single line is centered in a row's height, to line up with checkboxes beside it
CONTROLS.description = function(parent)
	local control = CreateFrame("Frame", nil, parent)
	control.text = UI.Text(control)
	control.text:SetPoint("LEFT")
	control.text:SetWordWrap(true)
	
	control.label = control.text
	labelTooltip(control)

	function control:Bind(option)
		self.text:SetText(resolve(option.name) or "")
	end

	function control:Measure(width)
		self.text:SetWidth(width)
		self.labelHover:SetWidth(math.max(1, math.min(width, self.text:GetStringWidth())))
		return math.max(self.text:GetStringHeight(), Style.rowHeight)
	end

	return control
end

--empty room
CONTROLS.spacer = function(parent)
	local control = CreateFrame("Frame", nil, parent)
	function control:Bind() end
	function control:Measure()
		return 1
	end
	return control
end

---a control for an AceConfig option type, for other panels in the same style. nil for a type there is none for
function PhotonGUI.CreateOptionControl(kind, parent)
	return CONTROLS[kind] and CONTROLS[kind](parent)
end

local layoutLines

--a box inside a box, with a border and/or a lighter background. it has as many slots inside
--as it takes, so settings keep their size in it
CONTROLS.box = function(parent)
	local control = CreateFrame("Frame", nil, parent)
	Style.Flat(control, Style.panel)
	control.title = UI.Text(control, nil, Style.accent)
	control.title:SetJustifyH("CENTER")
	control.title:SetWordWrap(false)

	function control:Bind(item)
		self.border = item.border ~= false
		self.light = item.light == true
		self.titleText = addonTable.optionDefinitions.localized(item.name or "")
		self.photonFlat.bg:SetColorTexture(unpack(self.light and Style.panelLight or Style.panel))
		Style.SetFlatShown(self, self.border or self.light, self.border)
	end

	function control:Measure(width)
		local left, top, right, bottom = 0, 0, 0, 0
		if self.light then
			local inset = Style.lightInset
			left, top, right, bottom = inset.left, inset.top, inset.right, inset.bottom
		elseif self.border then
			left, top, right, bottom = Style.padding, Style.padding, Style.padding, Style.padding
		end
		local y = top

		self.title:ClearAllPoints()
		if self.titleText ~= "" then
			self.title:SetPoint("TOPLEFT", left, -top)
			self.title:SetPoint("TOPRIGHT", -right, -top)
			self.title:SetText(self.titleText)
			self.title:Show()
			y = y + self.title:GetStringHeight() + Style.gap
		else
			self.title:Hide()
		end

		local unit = (width - left - right + Style.gap) / self.units
		local nextLine = layoutLines(self, self.rows, unit, self.units, left, y)
		return math.max(math.max(nextLine - Style.gap, top) + bottom, 1)
	end

	return control
end

-----------------------------------------------------------------------------
--------------------------Boxes----------------------------------------------
-----------------------------------------------------------------------------

---a control for the option, in the box. nil for a type there is no control for
local function addControl(view, box, line, kind, option, units)
	if not CONTROLS[kind] then
		return
	end
	view.pools[kind] = view.pools[kind] or UI.Pool(function()
		return CONTROLS[kind](view.scroll.child)
	end)

	local control = view.pools[kind]:Acquire()
	control:SetParent(box)
	control.changed = view.changed
	control.option = option
	control.units = math.min(units, UNITS)
	control:Bind(option)
	control.hidden = addonTable.optionDefinitions.isHidden(option)
	control:SetShown(not control.hidden)
	table.insert(line, control)
	return control
end

---a line of controls per row, and how many settings they have and how many show
local function buildRows(view, container, rows, entry)
	local defs = addonTable.optionDefinitions
	local lines = {}
	local settings, shown = 0, 0

	for _, row in ipairs(rows) do
		local line = {}
		--a row's text goes when none of its settings show, like a label beside them
		local rowSettings, rowShown, texts = 0, 0, {}
		for _, item in ipairs(row) do
			if item.box then
				local box = addControl(view, container, line, "box", item, widthUnits(item.width or "double"))
				local boxSettings, boxShown
				--an old style items list is one row
				box.rows, boxSettings, boxShown = buildRows(view, box, item.rows or {item.items or {}}, entry)
				settings, shown = settings + boxSettings, shown + boxShown
				box.hidden = boxSettings > 0 and boxShown == 0
				box:SetShown(not box.hidden)
			elseif item.header then
				addControl(view, container, line, "header", {name = defs.localized(item.header)}, UNITS)
			elseif item.text then
				local described = item.descFor and entry.definitions[item.descFor]
				local desc = item.desc and rawget(L, "BarDesc_"..item.desc) or described and described.desc
				table.insert(texts, addControl(view, container, line, "description", {name = defs.localized(item.text), desc = desc}, widthUnits(item.width or "full")))
			elseif item.spacer then
				addControl(view, container, line, "spacer", {}, widthUnits(item.width))
			else
				local option = entry.definitions[item.id]
				if option then
					--the layout can give a setting a shorter label for where it sits
					if item.name then
						--the hover title keeps the full name, "Pressed" alone doesn't say what is pressed
						option.title = option.title or option.name
						option.name = defs.localized(item.name)
					end
				elseif defs.PLACEHOLDER_TYPES[item.type] then
					option = defs.placeholder(item)
				end

				rowSettings = rowSettings + 1
				if option then
					local control = addControl(view, container, line, option.type, option, widthUnits(item.width))
					if control then
						settings = settings + 1
						if not control.hidden then
							shown = shown + 1
							rowShown = rowShown + 1
						end
					end
				else
					--unknown, or not in this game version: counts as hidden, so a box of only those goes
					settings = settings + 1
				end
			end
		end
		if rowSettings > 0 and rowShown == 0 then
			for _, text in ipairs(texts) do
				text.hidden = true
				text:Hide()
			end
		end
		table.insert(lines, line)
	end

	return lines, settings, shown
end

---one box of the layout with its rows of controls. a page of a tab of pages has no title
local function buildBox(view, group, entry, asPage)
	local box = view.boxPool:Acquire()
	box.titleText = asPage and "" or addonTable.optionDefinitions.localized(group.name or "")
	box.slots = tonumber(group.slots) or UNITS

	--an old style items list is one row
	local settings, shown
	box.rows, settings, shown = buildRows(view, box, group.rows or {group.items or {}}, entry)

	--no empty box when this bar type has none of its settings. one with only text or headers still shows
	box.hidden = settings > 0 and shown == 0
	table.insert(view.boxes, box)
end

---places lines of controls in frame, slots wide, wrapping when a line is full. a line's settings
---share its bottom so checkboxes line up with captioned dropdowns, a line with a box shares its top.
---returns where the next line would go
function layoutLines(frame, lines, unit, slots, left, top)
	local gap = Style.gap
	local placed, lineHeight = {}, 0

	local available = slots * unit - gap

	--colors at the end of a line go to its right edge and the setting before them stretches to them
	local function alignTrailing()
		local last = #placed
		while last > 0 and placed[last].control.FixedWidth do
			last = last - 1
		end
		if last == 0 or last == #placed then
			return
		end
		local x = left + available
		for i = #placed, last + 1, -1 do
			x = x - placed[i].width
			placed[i].x = x
			x = x - gap
		end
		local grower = placed[last]
		local width = x - grower.x
		if width > grower.width then
			grower.width = width
			grower.control:SetWidth(width)
		end
	end

	local function finishLine()
		alignTrailing()
		--a line with a box lines up at the top, so the box's first row matches what is beside it
		local hasBox = false
		for _, entry in ipairs(placed) do
			hasBox = hasBox or entry.control.rows ~= nil
		end
		for _, entry in ipairs(placed) do
			local y = hasBox and top or top + lineHeight - entry.height
			entry.control:ClearAllPoints()
			entry.control:SetPoint("TOPLEFT", frame, "TOPLEFT", entry.x, -y)
		end
		if #placed > 0 then
			top = top + lineHeight + gap
		end
		placed, lineHeight = {}, 0
	end

	--a control takes its slots, or just its own width when it has one, like a color square
	for _, line in ipairs(lines) do
		local x = 0
		for _, control in ipairs(line) do
			if not control.hidden then
				local controlWidth = control.FixedWidth and control:FixedWidth()
					or math.min(control.units, slots) * unit - gap
				if #placed > 0 and x + controlWidth > available + 0.5 then
					finishLine()
					x = 0
				end
				control:SetWidth(controlWidth)
				local height = control:Measure(controlWidth)
				control:SetHeight(height)
				table.insert(placed, {control = control, x = left + x, width = controlWidth, height = height})
				lineHeight = math.max(lineHeight, height)
				x = x + controlWidth + gap
			end
		end
		finishLine()
	end
	return top
end

---places a box's controls for a width and returns its height
local function layoutBox(view, box, width, y)
	local pad, gap = Style.padding, Style.gap
	box:ClearAllPoints()
	box:SetPoint("TOPLEFT", view.scroll.child, "TOPLEFT", 0, -y)
	box:SetWidth(width)

	local top = pad
	if box.titleText ~= "" then
		box.title:SetText(box.titleText)
		box.strip:Show()
		top = box.edge + STRIP_HEIGHT + pad
	else
		box.strip:Hide()
	end

	local bottom = layoutLines(box, box.rows, (width - 2 * pad + gap) / box.slots, box.slots, pad, top)
	local height = math.max(bottom - gap, pad) + pad
	box:SetHeight(height)
	return height
end

--room between the window's boxes, more than inside them
local BOX_GAP = Style.gap + 10

local function layout(view)
	local width = view.scroll:GetContentWidth()
	local y = 0
	for _, box in ipairs(view.boxes) do
		box:SetShown(not box.hidden)
		if not box.hidden then
			y = y + layoutBox(view, box, width, y) + BOX_GAP
		end
	end
	view.scroll:SetContentHeight(math.max(0, y - BOX_GAP))
end

local function releaseAll(view)
	for _, pool in pairs(view.pools) do
		pool:ReleaseAll()
	end
	view.boxPool:ReleaseAll()
	wipe(view.boxes)
end

---a scroll area of boxes in parent, with its own controls. changed runs after a setting is set
local function createView(parent, changed)
	local view = {pools = {}, boxes = {}, changed = changed}
	view.scroll = UI.ScrollArea(parent)
	view.scroll.OnResize = function()
		layout(view)
	end
	view.boxPool = UI.Pool(function()
		return UI.Box(view.scroll.child)
	end)
	return view
end

---boxes of BarConfigLayout.lua in another window, see VisualOverrideWindow.lua. place view.scroll in it
function PhotonGUI.CreateLayoutView(parent, changed)
	local view = createView(parent, changed)

	---groups are the layout's, definitions the settings they place, as Options.lua makes them
	function view:Draw(groups, definitions)
		local offset = self.scroll:GetVerticalScroll()
		releaseAll(self)
		for _, group in ipairs(groups) do
			buildBox(self, group, {definitions = definitions})
		end
		layout(self)
		self.scroll:ScrollTo(offset)
	end

	return view
end

-----------------------------------------------------------------------------
--------------------------Window---------------------------------------------
-----------------------------------------------------------------------------

---tabs and page tabs are only there when there is a choice
local function placeScroll()
	local pad = Style.padding
	local anchor

	--stacks frame under the last one, or at the top of the frame around them
	local function below(frame, space)
		frame:ClearAllPoints()
		if anchor then
			frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -space)
			frame:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -space)
		else
			frame:SetPoint("TOPLEFT", wrapper, "TOPLEFT", pad, -pad)
			frame:SetPoint("TOPRIGHT", wrapper, "TOPRIGHT", -pad, -pad)
		end
		anchor = frame
	end

	if tabs:IsShown() then
		below(tabs, pad)
	end
	if pageTabs:IsShown() then
		below(pageTabs, Style.gap)
	end
	below(mainView.scroll, pad)
	mainView.scroll:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", -pad, pad)
end

--every bar, by name, for the picker
local function barItems()
	local items = {}
	for _, bar in pairs(Photon.bars) do
		table.insert(items, {value = bar, text = bar:GetBarName()})
	end
	table.sort(items, function(a, b)
		return a.text < b.text
	end)
	return items
end

local function createWindow()
	window = UI.Window("PhotonBarConfigFrame", "Bar Config")
	window:SetSize(700, GetScreenHeight() > 850 and 850 or 700)
	--wide enough for the bar picker and the new bar controls side by side
	window:SetMinSize(600, 400)
	window:SetScript("OnHide", function()
		if Photon.barEditMode then
			Photon:ToggleBarEditMode(false)
		end
	end)

	local content = window.content

	-------------------------------- bar picker --------------------------------
	local barRow = CreateFrame("Frame", nil, content)
	barRow:SetPoint("TOPLEFT")
	barRow:SetPoint("TOPRIGHT")

	local barLabel = UI.Text(barRow, Style.fontLarge, Style.accent)
	barLabel:SetPoint("LEFT")
	barLabel:SetText("Bar")

	--picking a bar selects it like clicking it does
	barDropdown = UI.Dropdown(barRow, function(bar)
		Photon.Bar.ChangeSelectedBar(bar)
		render()
	end)
	barDropdown:SetPoint("LEFT", barLabel, "RIGHT", Style.gap * 2, 0)
	barDropdown:SetWidth(220)
	barDropdown.onHover = addonTable.overlay.BarEditor.highlightBar
	barRow:SetHeight(math.max(barDropdown:GetHeight(), Style.rowHeight))

	-------------------------------- new bar --------------------------------
	--on the right: a bar type, and a button that makes a bar of it and selects it
	local newBarType
	local createButton = UI.Button(barRow, "Create", function()
		if newBarType then
			Photon.Bar:CreateNewBar(newBarType)
			render()
		end
	end)
	createButton:SetPoint("RIGHT")
	createButton:SetEnabled(false)

	local typeItems = {}
	for class, info in pairs(Photon.registeredBarData) do
		table.insert(typeItems, {value = class, text = info.barLabel})
	end
	table.sort(typeItems, function(a, b)
		return a.text < b.text
	end)

	local typeDropdown = UI.Dropdown(barRow, function(class)
		newBarType = class
		createButton:SetEnabled(true)
	end)
	typeDropdown:SetItems(typeItems)
	typeDropdown:SetValue(nil)
	typeDropdown:SetPoint("RIGHT", createButton, "LEFT", -Style.gap, 0)
	typeDropdown:SetWidth(160)

	local newLabel = UI.Text(barRow, nil, Style.dim)
	newLabel:SetPoint("RIGHT", typeDropdown, "LEFT", -Style.gap, 0)
	newLabel:SetText("New bar")

	--everything for the picked bar
	wrapper = CreateFrame("Frame", nil, content)
	Style.Flat(wrapper, Style.clear)
	wrapper:SetPoint("TOPLEFT", barRow, "BOTTOMLEFT", 0, -Style.padding)
	wrapper:SetPoint("BOTTOMRIGHT")

	emptyText = UI.Text(wrapper, nil, Style.dim)
	emptyText:SetPoint("TOPLEFT", Style.padding, -Style.padding)
	emptyText:SetText("Select a bar to begin.")

	tabs = UI.Tabs(wrapper, function(value)
		selected.tab = value
		selected.page = nil
		render()
	end)

	--a tab with childGroups shows one box at a time
	pageTabs = UI.Tabs(wrapper, function(value)
		selected.page = value
		render()
	end)

	-------------------------------- arrow keys --------------------------------
	--on the tab with the position box the arrow keys nudge the selected bar a pixel.
	local NUDGES = {LEFT = {-1, 0}, RIGHT = {1, 0}, UP = {0, 1}, DOWN = {0, -1}}
	local keys = CreateFrame("Frame", nil, window)
	keys:EnableKeyboard(true)
	keys:SetPropagateKeyboardInput(true)
	keys:SetScript("OnKeyDown", function(self, key)
		if InCombatLockdown() then
			return
		end
		local nudge = NUDGES[key]
		if nudge and selected.tab == "bar:general" and Photon.currentBar then
			self:SetPropagateKeyboardInput(false)
			Photon.currentBar:Nudge(nudge[1], nudge[2])
			requestRender()
		else
			self:SetPropagateKeyboardInput(true)
		end
	end)
	keys:SetScript("OnKeyUp", function(self)
		if not InCombatLockdown() then
			self:SetPropagateKeyboardInput(true)
		end
	end)

	mainView = createView(wrapper, changed)
end

function render()
	if not window or not window:IsShown() then
		return
	end

	local scroll = mainView.scroll
	local offset = scroll:GetVerticalScroll()
	releaseAll(mainView)

	--a bar is always selected while there is one, the first in the picker's order
	if not Photon.currentBar then
		local first = barItems()[1]
		if first then
			Photon.Bar.ChangeSelectedBar(first.value)
		end
	end

	local bar = Photon.currentBar
	local defs = addonTable.optionDefinitions

	barDropdown:SetItems(barItems())
	barDropdown:SetValue(bar)

	if not bar or not defs then
		window:SetStatus("Select a bar to begin.")
		emptyText:Show()
		tabs:Hide()
		pageTabs:Hide()
		scroll:Hide()
		return
	end

	window:SetStatus("Pick a bar above, or left-click one, to change your selection.")
	emptyText:Hide()
	scroll:Show()

	-------------------------------- tabs --------------------------------
	local entries = {}
	local definitions = defs.bar()
	for _, tab in ipairs(addonTable.barConfigLayout.bar) do
		table.insert(entries, {key = "bar:"..tab.id, tab = tab, definitions = definitions})
	end
	if STATUS_BARS[bar.barType] then
		local statusDefinitions = defs.status()
		if statusDefinitions then
			for _, tab in ipairs(addonTable.barConfigLayout.status) do
				table.insert(entries, {key = "status:"..tab.id, tab = tab, definitions = statusDefinitions})
			end
		end
	end

	local entry
	for _, candidate in ipairs(entries) do
		if candidate.key == selected.tab then
			entry = candidate
		end
	end
	entry = entry or entries[1]
	if not entry then
		tabs:Hide()
		pageTabs:Hide()
		placeScroll()
		layout(mainView)
		return
	end
	selected.tab = entry.key

	if #entries > 1 then
		local list = {}
		for _, candidate in ipairs(entries) do
			table.insert(list, {value = candidate.key, text = defs.localized(candidate.tab.name)})
		end
		tabs:SetTabs(list, selected.tab)
		tabs:Show()
	else
		tabs:Hide()
	end

	-------------------------------- pages --------------------------------
	--"tab" and "tree" both show as page tabs for now
	local groups = entry.tab.groups or {}
	local asPages = entry.tab.childGroups ~= nil and #groups > 0
	if asPages then
		local list, page = {}, nil
		for index, group in ipairs(groups) do
			local name = (group.name ~= "" and group.name) or group.id
			table.insert(list, {value = index, text = defs.localized(name)})
			if index == selected.page then
				page = group
			end
		end
		if not page then
			selected.page, page = 1, groups[1]
		end
		pageTabs:SetTabs(list, selected.page)
		pageTabs:Show()
		groups = {page}
	else
		pageTabs:Hide()
	end

	placeScroll()

	-------------------------------- boxes --------------------------------
	for _, group in ipairs(groups) do
		buildBox(mainView, group, entry, asPages)
	end
	layout(mainView)

	--keep the place when the same tab is drawn again
	local place = selected.tab..":"..tostring(selected.page)
	scroll:ScrollTo(place == lastTab and offset or 0)
	lastTab = place
end

---opens the bar editor, in bar edit mode so a bar can be picked by clicking it
function PhotonGUI:OpenBarConfig()
	if not window then
		createWindow()
	end

	if not Photon.barEditMode then
		Photon:ToggleBarEditMode(true)
	end

	window:Show()
	render()
end

---after the selected bar or button changed elsewhere
function PhotonGUI:RefreshBarConfig()
	requestRender()
end

function PhotonGUI:CloseBarConfig()
	if window then
		window:Hide()
	end
end
