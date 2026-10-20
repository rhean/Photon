-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...

addonTable.overlay = addonTable.overlay or {}

local L = LibStub("AceLocale-3.0"):GetLocale("Photon")

---type definition the contents of the xml file
---@class OverlayFrameSelect:Frame
---@field Left Texture
---@field Reticle Texture
---@field Right Texture

---@class ButtonOverlayFrame:Button,ScriptObject
---@field label FontString
---@field select OverlayFrameSelect
---@field border? table<string, Texture> @the button editor's border, see setBorder

---@class ButtonOverlay
---@field active boolean
---@field button Button
---@field frame ButtonOverlayFrame
---@field onClick fun(button: Button):nil

---@type ButtonOverlayFrame[]
local framePool = {}

--light orange on every button, a sharp orange on the selected one.
local BORDER = {1, 0.7, 0.3, 0.5, 1}
local BORDER_SELECTED = {1, 0.5, 0, 1, 3}

---colors the border around the overlay
---@param frame ButtonOverlayFrame
---@param style number[] @BORDER or BORDER_SELECTED
local function setBorder(frame, style)
	if not frame.border then
		local border = {}
		for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
			border[side] = frame:CreateTexture(nil, "OVERLAY")
		end
		border.TOP:SetPoint("TOPLEFT")
		border.TOP:SetPoint("TOPRIGHT")
		border.BOTTOM:SetPoint("BOTTOMLEFT")
		border.BOTTOM:SetPoint("BOTTOMRIGHT")
		border.LEFT:SetPoint("TOPLEFT")
		border.LEFT:SetPoint("BOTTOMLEFT")
		border.RIGHT:SetPoint("TOPRIGHT")
		border.RIGHT:SetPoint("BOTTOMRIGHT")
		frame.border = border
	end

	local r, g, b, a, thickness = unpack(style)
	for side, line in pairs(frame.border) do
		line:SetColorTexture(r, g, b, a)
		if side == "TOP" or side == "BOTTOM" then
			line:SetHeight(thickness)
		else
			line:SetWidth(thickness)
		end
		line:Show()
	end
end

---@param overlay ButtonOverlay
local function onEnter(overlay)
	overlay.frame.select:Show()
	GameTooltip:SetOwner(overlay.frame, "ANCHOR_RIGHT")
	GameTooltip:Show()
end

---@param overlay ButtonOverlay
local function onLeave(overlay)
		if overlay.active == false then
			overlay.frame.select:Hide()
		end
		GameTooltip:Hide()
end

---@param overlay ButtonOverlay
local function onClick(overlay)
	overlay.onClick(overlay.button)
end

local ButtonEditor= {
	---@param button Button
	---@param recticle "sides"|"corners"
	---@param onClickCallback fun(button: Button): nil
	---@return ButtonOverlay
	allocate = function (button, recticle, onClickCallback)
		---@type ButtonOverlay
		local overlay = {
			active = false,
			button = button,
			frame = -- try to pop a frame off the stack, otherwise make a new one
				table.remove(framePool) or
				CreateFrame("Button", nil, UIParent, "PhotonOverlayFrameTemplate") --[[@as ButtonOverlayFrame]],
			onClick = onClickCallback,
		}

		overlay.frame:EnableMouseWheel(true)
		overlay.frame:RegisterForClicks("AnyDown")
		overlay.frame:SetAllPoints(button)
		overlay.frame:SetScript("OnEnter", function() onEnter(overlay) end)
		overlay.frame:SetScript("OnLeave", function() onLeave(overlay) end)
		overlay.frame:SetScript("OnClick", function() onClick(overlay) end)

		overlay.frame.label:SetText("")
		setBorder(overlay.frame, BORDER)

		if recticle == "corners" then
			overlay.frame.select.Left:Hide()
			overlay.frame.select.Right:Hide()
			overlay.frame.select.Reticle:Show()
		else
			overlay.frame.select.Left:ClearAllPoints()
			overlay.frame.select.Left:SetPoint("RIGHT", overlay.frame.select, "LEFT", 4, 0)
			overlay.frame.select.Left:SetTexture("Interface\\AddOns\\Photon\\Images\\flyout.tga")
			overlay.frame.select.Left:SetTexCoord(0.71875, 1, 0, 1)
			overlay.frame.select.Left:SetWidth(16)
			overlay.frame.select.Left:SetHeight(55)

			overlay.frame.select.Right:ClearAllPoints()
			overlay.frame.select.Right:SetPoint("LEFT", overlay.frame.select, "RIGHT", -4, 0)
			overlay.frame.select.Right:SetTexture("Interface\\AddOns\\Photon\\Images\\flyout.tga")
			overlay.frame.select.Right:SetTexCoord(0, 0.28125, 0, 1)
			overlay.frame.select.Right:SetWidth(16)
			overlay.frame.select.Right:SetHeight(55)

			overlay.frame.select.Left:Show()
			overlay.frame.select.Right:Show()
			overlay.frame.select.Reticle:Hide()
		end

		overlay.frame:Show()

		return overlay
	end,

	---@param overlay ButtonOverlay
	activate = function(overlay)
		overlay.active = true
		overlay.frame.select:Show()
		setBorder(overlay.frame, BORDER_SELECTED)
	end,

	---@param overlay ButtonOverlay
	deactivate = function(overlay)
		overlay.active = false
		overlay.frame.select:Hide()
		setBorder(overlay.frame, BORDER)
	end,

	---@param overlay ButtonOverlay
	free = function (overlay)
		overlay.frame:SetScript("OnEnter", nil)
		overlay.frame:SetScript("OnLeave", nil)
		overlay.frame:SetScript("OnClick", nil)
		overlay.frame.select:Hide()
		for _, line in pairs(overlay.frame.border) do
			line:Hide()
		end
		overlay.frame:Hide()
		table.insert(framePool, overlay.frame)

		-- just for good measure to make sure nothing else can mess with
		-- the frame after we put it back into the pool
		overlay.frame = nil
	end,
}

addonTable.overlay.ButtonEditor = ButtonEditor
