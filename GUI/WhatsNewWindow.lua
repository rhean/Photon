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
	window:SetSize(620, 420)
	window:SetMinSize(320, 240)

	local content = window.content

	local okay = UI.Button(content, OKAY, function()
		window:Hide()
	end)
	okay:SetPoint("BOTTOMRIGHT")

	local scroll = UI.ScrollArea(content)
	scroll:SetPoint("TOPLEFT")
	scroll:SetPoint("BOTTOMRIGHT", okay, "TOPRIGHT", 0, Style.gap)

	local function newText(parent)
		local text = UI.Text(parent)
		text:SetJustifyH("LEFT")
		text:SetJustifyV("TOP")
		text:SetSpacing(2)
		return text
	end

	--how far a point's text sits in from its bullet, and the room between points
	local BULLET_SIZE = 5
	local BULLET_INDENT = 14
	local POINT_GAP = 10

	--each "New in x:" starts a release in a box of its own, titled x.
	local function addReleases(source, releases)
		local intro = {}
		local release
		for line in (source.."\n"):gmatch("(.-)\n") do
			local title = line:match("^New in (.+):$")
			if title then
				local box = UI.Box(scroll.child)
				box.title:SetText(string.format(L["WhatsNew_Title"], title))
				release = {box = box, points = {}}
				table.insert(releases, release)
			elseif release then
				local point = line:match("^%s*%-%s+(.+)$")
				if point or strtrim(line) ~= "" then
					local text = newText(release.box)
					text:SetText(point or strtrim(line))
					if point then
						text.bullet = release.box:CreateTexture(nil, "ARTWORK")
						text.bullet:SetColorTexture(unpack(Style.accent))
						text.bullet:SetSize(BULLET_SIZE, BULLET_SIZE)
						text.bullet:SetRotation(math.rad(45))
						local _, fontHeight = text:GetFont()
						text.bullet:SetPoint("CENTER", text, "TOPLEFT", -BULLET_INDENT / 2, -fontHeight / 2)
					end
					table.insert(release.points, text)
				end
			else
				table.insert(intro, line)
			end
		end
		return strtrim(table.concat(intro, "\n"))
	end

	local intro = newText(scroll.child)
	intro:SetPoint("TOPLEFT")
	local releases, olderReleases = {}, {}
	intro:SetText(addReleases(L[textKey], releases))
	addReleases(L["WhatsNew_Older"], olderReleases)

	local showOlder = false

	--the text wraps to the window's width, the boxes stack under it, and it all scrolls when longer than the window
	function scroll:OnResize()
		local width = self:GetContentWidth()
		local y = 0
		intro:SetWidth(width)
		if intro:GetText() ~= "" then
			y = intro:GetStringHeight() + Style.gap
		end

		local function place(list, shown)
			for _, release in ipairs(list) do
				local box = release.box
				box:SetShown(shown)
				if shown then
					local left = box.edge + Style.padding
					local top = box.edge + Style.stripHeight + Style.padding
					for i, text in ipairs(release.points) do
						local indent = text.bullet and BULLET_INDENT or 0
						text:ClearAllPoints()
						text:SetPoint("TOPLEFT", left + indent, -top)
						text:SetWidth(width - 2 * left - indent)
						top = top + text:GetStringHeight() + (i < #release.points and POINT_GAP or 0)
					end
					local height = top + Style.padding + box.edge
					box:ClearAllPoints()
					box:SetPoint("TOPLEFT", 0, -y)
					box:SetSize(width, height)
					y = y + height + Style.gap
				end
			end
		end
		place(releases, true)
		place(olderReleases, showOlder)

		self:SetContentHeight(y)
	end

	local older = UI.Button(content, L["WhatsNew_ShowOlder"], function(self)
		showOlder = not showOlder
		self:SetLabel(showOlder and L["WhatsNew_HideOlder"] or L["WhatsNew_ShowOlder"])
		scroll:OnResize()
	end)
	older:SetPoint("BOTTOMLEFT")

	window:Show()
	scroll:OnResize()
end
