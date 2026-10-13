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

---@class BarOverlay
---@field active boolean
---@field bar Bar
---@field frame PhotonBarFrame
---@field onClick fun(overlay: BarOverlay, button:string, down: boolean):nil

---@type PhotonBarFrame[]
local framePool = {}

---@param overlay BarOverlay
local function updateAppearance(overlay)
	local concealed = overlay.bar:GetBarConceal()
	if concealed and overlay.active then
		overlay.frame:SetBackdropColor(1,0,0,0.6)
	elseif not concealed and overlay.active then
		overlay.frame:SetBackdropColor(0,0,1,0.5)
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

	---@param overlay BarOverlay
	free = function (overlay)
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
