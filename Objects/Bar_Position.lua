-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Photon = addonTable.Photon

local Bar = Photon.Bar

-----------------------------------------------------------------------------
--------------------------Bar Position---------------------------------------
-----------------------------------------------------------------------------
--a bar's anchorPoint sits on a point of the screen or of another bar, moved by x and y:
--  data.anchorPoint  the bar's own point, CENTER when not set
--  data.anchorTo     the bar it is anchored to as "ActionBar:2", the screen when not set
--  data.point        the point on the screen or that bar
--  data.x, data.y    the offset
--bars saved before anchors have their CENTER on a point of the screen, which needs nothing new

--in reading order, as the bar editor's grid shows them
Bar.ANCHOR_POINTS = {"TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}

---where a point of a frame is, in screen pixels. nil while the frame has no place yet
local function pointOnScreen(frame, point)
	local left, bottom, width, height = frame:GetRect()
	if not left then
		return
	end
	local x = point:find("LEFT") and left or point:find("RIGHT") and left + width or left + width / 2
	local y = point:find("TOP") and bottom + height or point:find("BOTTOM") and bottom or bottom + height / 2
	local scale = frame:GetEffectiveScale()
	return x * scale, y * scale
end

-------------------------------- anchoring to bars --------------------------------

local function parseKey(key)
	local class, index = key:match("^(%a+):(%d+)$")
	return class, tonumber(index)
end

---a bar's type and place among its type's saved bars, which stays the same across reloads
function Bar:GetAnchorKey()
	for index, data in ipairs(Photon.registeredBarData[self.class].barDB) do
		if data == self.data then
			return self.class..":"..index
		end
	end
end

---the bar with that anchor key, nil when there is none
function Bar.FromAnchorKey(key)
	local class, index = parseKey(key)
	local registered = class and Photon.registeredBarData[class]
	local data = registered and registered.barDB[index]
	if not data then
		return
	end
	for _, bar in ipairs(Photon.bars) do
		if bar.data == data then
			return bar
		end
	end
end

---the bar this one is anchored to, nil for the screen
function Bar:GetAnchorBar()
	return self.data.anchorTo and Bar.FromAnchorKey(self.data.anchorTo)
end

---true when this bar follows the other, directly or through bars in between
function Bar:IsAnchoredTo(other)
	local bar, seen = self:GetAnchorBar(), {}
	while bar and not seen[bar] do
		if bar == other then
			return true
		end
		seen[bar] = true
		bar = bar:GetAnchorBar()
	end
	return false
end

---the frame the bar sits on. a bar that is gone, or that would anchor back to this one, falls back to the screen
function Bar:GetAnchorFrame()
	local target = self:GetAnchorBar()
	if not target or target == self or target:IsAnchoredTo(self) then
		return UIParent
	end
	return target
end

-------------------------------- position --------------------------------

function Bar:SetPosition()
	--bars saved while snapped by the old snapping have "SnapTo: TL" as their point
	if self.data.point:find("SnapTo") then
		self.data.point = "CENTER"
	end

	self:SetUserPlaced(false)
	self:ClearAllPoints()
	self:SetPoint(self.data.anchorPoint or "CENTER", self:GetAnchorFrame(), self.data.point, self:GetXAxis(), self:GetYAxis())
	self:SetUserPlaced(true)
	self:SetFrameStrata(Photon.STRATAS[self:GetStrata()])

	--a flyout opens away from the screen edge, which may now be another one
	for _, button in ipairs(self.buttons or {}) do
		if button.UpdateFlyout then
			button:UpdateFlyout()
		end
	end
end

---the offset that puts the bar where frame is now, on its current anchor, in whole pixels.
---frame is the bar, or its overlay while dragging
function Bar:OffsetFor(frame)
	local x, y = pointOnScreen(frame, self.data.anchorPoint or "CENTER")
	local targetX, targetY = pointOnScreen(self:GetAnchorFrame(), self.data.point)
	if not x or not targetX then
		return self:GetXAxis(), self:GetYAxis()
	end
	local scale = self:GetEffectiveScale()
	return math.floor((x - targetX) / scale + 0.5), math.floor((y - targetY) / scale + 0.5)
end

---changes the anchor, keeping the bar where it is on screen. anchorTo is an anchor key, nil for the screen
function Bar:SetAnchor(anchorTo, anchorPoint, point)
	self.data.anchorTo = anchorTo
	self.data.anchorPoint = anchorPoint ~= "CENTER" and anchorPoint or nil
	self.data.point = point
	self.data.x, self.data.y = self:OffsetFor(self)
	self:SetPosition()
	self:UpdateBarStatus()
end

function Bar:SetOffset(x, y)
	self.data.x, self.data.y = x, y
	self:SetPosition()
	self:UpdateBarStatus()
end

function Bar:Nudge(dx, dy)
	if InCombatLockdown() then
		return
	end
	self:SetOffset(self:GetXAxis() + dx, self:GetYAxis() + dy)
end

---a locked bar can't be dragged, the bar editor can still move it
function Bar:SetPositionLocked(locked)
	self.data.positionLocked = locked or nil

	if self.editFrame then
		addonTable.overlay.BarEditor.refresh(self.editFrame)
	end
end

function Bar:GetPositionLocked()
	return self.data.positionLocked == true
end

---before the bar is deleted: bars anchored to it stay where they are, on the screen,
---and anchors to later bars of its type move up one, as those bars' saved places do
function Bar:ReleaseAnchors()
	local key = self:GetAnchorKey()
	if not key then
		return
	end
	local class, index = parseKey(key)

	for _, bar in ipairs(Photon.bars) do
		local anchorTo = bar ~= self and bar.data.anchorTo
		if anchorTo == key then
			bar:SetAnchor(nil, bar.data.anchorPoint or "CENTER", bar.data.point)
		elseif anchorTo then
			local otherClass, otherIndex = parseKey(anchorTo)
			if otherClass == class and otherIndex > index then
				bar.data.anchorTo = otherClass..":"..(otherIndex - 1)
			end
		end
	end
end
