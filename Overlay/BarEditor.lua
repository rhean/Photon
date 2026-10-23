-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...

addonTable.overlay = addonTable.overlay or {}

local L = LibStub("AceLocale-3.0"):GetLocale("Photon")

---type definition the contents of the xml file
---@class PhotonBarFrame:CheckButton,ScriptObject
---@field Text FontString
---@field Message FontString
---@field MessageBG Texture
---@field handles table<string, Frame> the resize handles, by the point they sit on

---@class BarOverlay
---@field active boolean
---@field bar Bar
---@field frame PhotonBarFrame
---@field onClick fun(overlay: BarOverlay, button:string, down: boolean):nil

---@type PhotonBarFrame[]
local framePool = {}

-------------------------------- resize handles --------------------------------
--the selected bar's corners and edges have handles that change its padding

--which way each handle grows the bar, x and y
local HANDLES = {
	TOPLEFT = {-1, 1}, TOP = {0, 1}, TOPRIGHT = {1, 1},
	LEFT = {-1, 0}, RIGHT = {1, 0},
	BOTTOMLEFT = {-1, -1}, BOTTOM = {0, -1}, BOTTOMRIGHT = {1, -1},
}
local SIDES_X = {[-1] = "LEFT", [1] = "RIGHT"}
local SIDES_Y = {[1] = "TOP", [-1] = "BOTTOM"}

--the padding sliders' range, see Options.lua
local MIN_PAD, MAX_PAD = -200, 200

---whether the padding can grow the bar sideways and upwards. a single row has nothing to spread upwards,
---a True Circle goes by the horizontal padding alone
---@param bar Bar
---@return boolean, boolean
local function resizableAxes(bar)
	local shape, count = bar:GetBarShape(), #bar.buttons
	if shape == "circle" or shape == "circle + one" then
		return true, not bar:GetCircleLocked()
	elseif shape == "square" or shape == "diamond" then
		return true, true
	end

	local columns = bar:GetColumns()
	if columns == 0 or columns > count then
		columns = count
	end
	return columns > 1, count > columns
end

---a side the bar is anchored by stays put, so a handle that would move it isn't shown
---@param bar Bar
---@param dir number[]
local function canResize(bar, dir)
	local anchor = bar.data.anchorPoint or "CENTER"
	local canX, canY = resizableAxes(bar)
	if dir[1] ~= 0 and (not canX or anchor:find(SIDES_X[dir[1]])) then
		return false
	end
	if dir[2] ~= 0 and (not canY or anchor:find(SIDES_Y[dir[2]])) then
		return false
	end
	return true
end

local function round(num)
	return math.floor(num + 0.5)
end

--the handle being dragged and where everything started, nil when none is
local resizing
local resizeDriver = CreateFrame("Frame")
resizeDriver:Hide()

local function stopResize()
	if not resizing then
		return
	end
	resizing = nil
	resizeDriver:Hide()
	addonTable.Photon.PhotonGUI:RefreshBarConfig()
end

---how much one step of padding grows the bar, in its own units. every shape spreads padding differently, so it is measured
---@param bar Bar
local function measureGrowth(bar, padH, padV, width, height)
	bar:SetPadding(padH + 10, padV)
	local growH = (bar:GetWidth() - width) / 10
	bar:SetPadding(padH, padV + 10)
	local growV = (bar:GetHeight() - height) / 10
	bar:SetPadding(padH, padV)
	return growH, growV
end

---@param overlay BarOverlay
---@param dir number[]
local function startResize(overlay, dir)
	local bar = overlay.bar
	if InCombatLockdown() or bar:GetPositionLocked() or not canResize(bar, dir) then
		return
	end

	local padH, padV = bar:GetHorizontalPad(), bar:GetVerticalPad()
	local width, height = bar:GetWidth(), bar:GetHeight()
	local growH, growV = measureGrowth(bar, padH, padV, width, height)
	local cursorX, cursorY = GetCursorPosition()
	local anchor = bar.data.anchorPoint or "CENTER"

	resizing = {
		overlay = overlay, bar = bar, dir = dir,
		padH = padH, padV = padV, growH = growH, growV = growV,
		width = width, height = height,
		cursorX = cursorX, cursorY = cursorY,
		x = bar:GetXAxis(), y = bar:GetYAxis(),
		--an anchor in the middle of a side lets the bar grow both ways, it is moved to keep the far side put
		centeredX = not anchor:find("LEFT") and not anchor:find("RIGHT"),
		centeredY = not anchor:find("TOP") and not anchor:find("BOTTOM"),
	}
	resizeDriver:Show()
end

resizeDriver:SetScript("OnUpdate", function()
	local r = resizing
	if not r or InCombatLockdown() then
		stopResize()
		return
	end
	local bar, dir = r.bar, r.dir

	--how far the dragged side has moved outwards, in the bar's units
	local scale = bar:GetEffectiveScale()
	local cursorX, cursorY = GetCursorPosition()
	local outX, outY = (cursorX - r.cursorX) / scale * dir[1], (cursorY - r.cursorY) / scale * dir[2]

	local padH, padV = r.padH, r.padV
	if dir[1] ~= 0 and math.abs(r.growH) > 0.01 then
		padH = math.min(MAX_PAD, math.max(MIN_PAD, round(r.padH + outX / r.growH)))
	end
	if dir[2] ~= 0 and math.abs(r.growV) > 0.01 then
		padV = math.min(MAX_PAD, math.max(MIN_PAD, round(r.padV + outY / r.growV)))
	end
	if padH == bar:GetHorizontalPad() and padV == bar:GetVerticalPad() then
		return
	end

	bar:SetPadding(padH, padV)

	--the bar grew both ways around its middle, half of it is moved over to the dragged side
	local x, y = r.x, r.y
	if dir[1] ~= 0 and r.centeredX then
		x = r.x + dir[1] * (bar:GetWidth() - r.width) / 2
	end
	if dir[2] ~= 0 and r.centeredY then
		y = r.y + dir[2] * (bar:GetHeight() - r.height) / 2
	end
	if x ~= r.x or y ~= r.y then
		bar:SetOffset(round(x), round(y))
	end
end)

---@param frame PhotonBarFrame
local function createHandles(frame)
	frame.handles = {}
	for point, dir in pairs(HANDLES) do
		local handle = CreateFrame("Frame", nil, frame)
		handle:SetSize(6, 6)
		handle:SetPoint("CENTER", frame, point)
		handle:EnableMouse(true)
		handle.dir = dir

		handle.texture = handle:CreateTexture(nil, "OVERLAY")
		handle.texture:SetAllPoints()
		handle.texture:SetColorTexture(1, 0.82, 0, 0.9)

		frame.handles[point] = handle
	end
end

---@param overlay BarOverlay
local function setUpHandles(overlay)
	if not overlay.frame.handles then
		createHandles(overlay.frame)
	end
	for _, handle in pairs(overlay.frame.handles) do
		handle:SetScript("OnMouseDown", function(_, button)
			if button == "LeftButton" then
				startResize(overlay, handle.dir)
			end
		end)
		handle:SetScript("OnMouseUp", stopResize)
		handle:SetScript("OnEnter", function() handle.texture:SetColorTexture(1, 1, 1, 1) end)
		handle:SetScript("OnLeave", function() handle.texture:SetColorTexture(1, 0.82, 0, 0.9) end)
	end
end

---@param overlay BarOverlay
local function updateHandles(overlay)
	local frame = overlay.frame
	local bar = overlay.bar
	local shown = bar == addonTable.Photon.currentBar and not bar:GetPositionLocked() and not InCombatLockdown()
	for _, handle in pairs(frame.handles) do
		handle:SetShown(shown and canResize(bar, handle.dir))
		handle:SetFrameLevel(frame:GetFrameLevel() + 5)
	end
end

---@param overlay BarOverlay
local function updateAppearance(overlay)
	local concealed = overlay.bar:GetBarConceal()
	if concealed and overlay.active then
		overlay.frame:SetBackdropColor(1,0,0,0.6)
	elseif not concealed and overlay.active then
		overlay.frame:SetBackdropColor(0.15,0.35,1,0.6)
	elseif concealed and not overlay.active then
		overlay.frame:SetBackdropColor(1,0,0,0.4)
	elseif not concealed and not overlay.active then
		overlay.frame:SetBackdropColor(0,0,0,0.4)
	end

	--gold while its name is under the mouse in a list of bars, see BarEditor.highlightBar
	if overlay.frame.highlighted then
		overlay.frame:SetBackdropColor(1,0.82,0,0.6)
	end

	--the name only shows on mouseover, for the selected bar too
	overlay.frame.Text:SetShown(overlay.frame.hovered == true or overlay.frame.highlighted == true)

	overlay.frame:SetFrameStrata(addonTable.Photon.STRATAS[overlay.bar:GetStrata()])

	--don't re-anchor to the bar mid-drag (OnEnter/OnLeave fire when the cursor crosses the edge),
	--it pins the overlay back to the bar while StartMoving drags one corner and stretches it
	if not overlay.frame.isDragging then
		overlay.frame:SetAllPoints(overlay.bar)
	end

	updateHandles(overlay)
end

-- forward declare it so the event handlers can use it
local BarEditor

---@param overlay BarOverlay
local function onEnter(overlay)
	overlay.frame.hovered = true

	-- we don't want to mutate the real overlay
	local fakeOverlay = CopyTable(overlay, true --[[shallow copy]])

	-- this will update the real overlay frame as if active
	BarEditor.activate(fakeOverlay)
end

--TODO: the overlay should not be mutating objects.
--put the movement code into the overlay controller
---@param overlay BarOverlay
---@param button string
local function onDragStart(overlay, button)
	if overlay.bar:GetPositionLocked() or InCombatLockdown() then
		return
	end
	overlay.frame.isDragging = true

	--off the bar first, so the bar can follow the overlay without the two pinned to each other
	local left, bottom, width, height = overlay.frame:GetRect()
	overlay.frame:ClearAllPoints()
	overlay.frame:SetSize(width, height)
	overlay.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)

	--bars anchored to this one follow too
	overlay.bar:ClearAllPoints()
	overlay.bar:SetPoint("CENTER", overlay.frame, "CENTER")

	overlay.frame:StartMoving()
end


---@param overlay BarOverlay
local function onDragStop(overlay)
	if not overlay.frame.isDragging then
		return
	end
	overlay.frame:StopMovingOrSizing()
	overlay.frame.isDragging = false

	--the bar keeps its anchor, only the offset changes. this also takes it off the overlay
	overlay.bar:SetOffset(overlay.bar:OffsetFor(overlay.frame))

	--re-attach the overlay to the bar at its new position
	overlay.frame:ClearAllPoints()
	updateAppearance(overlay)

	addonTable.Photon.PhotonGUI:RefreshBarConfig()
end


---@param overlay BarOverlay
local function onLeave(overlay)
	overlay.frame.hovered = nil
	updateAppearance(overlay)
end

---@param overlay BarOverlay
---@param button string
---@param down boolean
local function onClick(overlay, button, down)
	overlay.onClick(overlay, button, down)
end

BarEditor = {
	---@param bar Bar
	---@param onClickCallback fun(overlay: BarOverlay, button: string, down: boolean): nil
	---@return BarOverlay
	allocate = function (bar, onClickCallback)
		---@type BarOverlay
		local overlay = {
			active = false,
			bar = bar,
			frame = -- try to pop a frame off the stack, otherwise make a new one
				table.remove(framePool) or
				CreateFrame("CheckButton", nil, UIParent, "PhotonBarTemplate") --[[@as PhotonBarFrame]],
			onClick = onClickCallback,
		}
		overlay.frame:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			tile = true,
			tileSize = 16,
			insets = {left = 4, right = 4, top = 4, bottom = 4}
		})

		overlay.frame.Text:SetText(bar:GetBarName())

		overlay.frame:RegisterForClicks("AnyUp", "AnyDown")
		overlay.frame:RegisterForDrag("LeftButton")
		overlay.frame:SetScript("OnDragStart", function(_, button) onDragStart(overlay, button) end)
		overlay.frame:SetScript("OnDragStop", function(_) onDragStop(overlay) end)
		overlay.frame:SetScript("OnEnter", function() onEnter(overlay) end)
		overlay.frame:SetScript("OnLeave", function() onLeave(overlay) end)
		overlay.frame:SetScript("OnClick", function(_, button, down) onClick(overlay, button, down) end)
		setUpHandles(overlay)

		overlay.frame:Show()
		updateAppearance(overlay)

		return overlay
	end,

	---@param overlay BarOverlay
	activate = function(overlay)
		overlay.active = true
		updateAppearance(overlay)
	end,

	---@param overlay BarOverlay
	deactivate = function(overlay)
		overlay.active = false
		updateAppearance(overlay)
	end,

	---after a bar setting changes, like its shape or anchor, which can change its resize handles
	---@param overlay BarOverlay
	refresh = function(overlay)
		--a freed overlay has no frame
		if overlay.frame then
			updateAppearance(overlay)
		end
	end,

	---@param overlay BarOverlay
	free = function (overlay)
		if resizing and resizing.overlay == overlay then
			stopResize()
		end
		for _, handle in pairs(overlay.frame.handles) do
			handle:SetScript("OnMouseDown", nil)
			handle:SetScript("OnMouseUp", nil)
			handle:SetScript("OnEnter", nil)
			handle:SetScript("OnLeave", nil)
			handle:Hide()
		end

		overlay.frame:SetScript("OnDragStart", nil)
		overlay.frame:SetScript("OnDragStop", nil)
		overlay.frame:SetScript("OnEnter", nil)
		overlay.frame:SetScript("OnLeave", nil)
		overlay.frame:SetScript("OnClick", nil)
		overlay.frame.hovered = nil
		overlay.frame.highlighted = nil
		overlay.frame:RegisterForDrag()
		overlay.frame:RegisterForClicks()
		overlay.frame:Hide()
		table.insert(framePool, overlay.frame)

		-- just for good measure to make sure nothing else can mess with
		-- the frame after we put it back into the pool
		overlay.frame = nil
	end,

	---lights up one bar's overlay and no other, for a bar named under the mouse in a list. nil lights none
	---@param bar Bar|nil
	highlightBar = function(bar)
		for _, other in ipairs(addonTable.Photon.bars) do
			local overlay = other.editFrame
			if overlay then
				overlay.frame.highlighted = other == bar or nil
				updateAppearance(overlay)
			end
		end
	end,
}

addonTable.overlay.BarEditor = BarEditor
