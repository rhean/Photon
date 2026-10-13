-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Photon = addonTable.Photon

local PhotonGUI = Photon.PhotonGUI

local L = LibStub("AceLocale-3.0"):GetLocale("Photon")

local UI = addonTable.ui
local Style = UI.Style

-----------------------------------------------------------------------------
-----------------------------What's New Window-------------------------------
-----------------------------------------------------------------------------
--the release notes, shown once per account for each new version, see Photon:LoginMessage.
--the text is WhatsNew_Text in the locale, or the key Photon.lua picks instead

local window

---@param version string
---@param textKey string the locale key of the text to show
function PhotonGUI:ShowWhatsNew(version, textKey)
	if window then
		window:Show()
		return
	end

	window = UI.Window("PhotonWhatsNewFrame", string.format(L["WhatsNew_Title"], version))
	window:SetSize(460, 380)
	window:SetMinSize(320, 240)

	local content = window.content

	local okay = UI.Button(content, OKAY, function()
		window:Hide()
	end)
	okay:SetPoint("BOTTOMRIGHT")

	local scroll = UI.ScrollArea(content)
	scroll:SetPoint("TOPLEFT")
	scroll:SetPoint("BOTTOMRIGHT", okay, "TOPRIGHT", 0, Style.gap)

	local text = UI.Text(scroll.child)
	text:SetPoint("TOPLEFT")
	text:SetJustifyH("LEFT")
	text:SetJustifyV("TOP")
	text:SetSpacing(2)
	text:SetText(L[textKey])

	--the text wraps to the window's width, and scrolls when it is longer than the window
	function scroll:OnResize()
		text:SetWidth(self:GetContentWidth())
		self:SetContentHeight(text:GetStringHeight())
	end

	window:Show()
	scroll:OnResize()
end
