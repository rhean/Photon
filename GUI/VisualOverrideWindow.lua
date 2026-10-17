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
--------------------------Visual Override Window-----------------------------
-----------------------------------------------------------------------------
--the bar config's Visuals box for the selected button, while it has Override Visuals ticked in the
--button editor. it changes only that button, see Button:GetVisuals

local window, view
local render
local renderPending

--the Visuals box of BarConfigLayout.lua
local function visualsGroup()
	for _, tab in ipairs(addonTable.barConfigLayout.bar) do
		for _, group in ipairs(tab.groups or {}) do
			if group.id == "visuals" then
				return group
			end
		end
	end
end

--a setting can change what others show, so redraw on the next frame
local function requestRender()
	if renderPending then
		return
	end
	renderPending = true
	C_Timer.After(0, function()
		renderPending = false
		render()
	end)
end

local function createWindow()
	window = UI.Window("PhotonVisualOverrideFrame", L["Button Visuals"])
	window:SetSize(560, 460)
	window:SetMinSize(420, 300)

	--beside the button editor the first time, then where it was moved to
	local editor = _G.PhotonButtonEditorFrame
	if editor and editor:GetRight() then
		window:ClearAllPoints()
		window:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", editor:GetRight() + Style.gap, editor:GetTop())
	end

	view = PhotonGUI.CreateLayoutView(window.content, requestRender)
	view.scroll:SetPoint("TOPLEFT")
	view.scroll:SetPoint("BOTTOMRIGHT")
end

function render()
	if not window or not window:IsShown() then
		return
	end

	--nothing of its own to show, the bar config has the bar's
	local button = Photon.currentButton
	if not button or button.bar.class ~= "ActionBar" or not button:HasVisualOverride() then
		window:Hide()
		return
	end

	window:SetStatus(string.format(L["VisualOverride_Own"], button.bar:GetBarName(), button.id))
	view:Draw({visualsGroup()}, addonTable.optionDefinitions.buttonVisuals(button))
end

function PhotonGUI:OpenVisualOverride()
	if not window then
		createWindow()
	end
	window:Show()
	render()
end

function PhotonGUI:CloseVisualOverride()
	if window then
		window:Hide()
	end
end
