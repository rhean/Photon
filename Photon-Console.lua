-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Photon = addonTable.Photon

local L = LibStub("AceLocale-3.0"):GetLocale("Photon")

function Photon:PrintStateList()
	local data = {}
	local list

	local count = 1
	for _,v in pairs(Photon.MANAGED_BAR_STATES) do
		data[count] = v.localizedName
		count = count + 1
	end

	for _,v in ipairs(data) do

		if not list then
			list = L["Valid States"]..":"..v
		else
			list = list..", "..v
		end
	end

	Photon:Print(list..L["Custom_Option"])
end

function Photon:PrintBarTypes()
	Photon:Print("---------------------------------------------------")
	Photon:Print("     "..L["How to use"]..":   ".."/photon".." "..L["Create"]:lower().." <"..L["Option"]:lower()..">")
	Photon:Print("---------------------------------------------------")

	for k,v in pairs(Photon.registeredBarData) do
		Photon:Print("    |cff00ff00"..k..":|r "..v.barLabel)
	end
end
