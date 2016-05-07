--------------
-- Settings --
--------------
local frameCount = 10
local rows = 10
local growthDirection = "VERTICAL"  -- VERTICAL, HORIZONTAL
local reverseX = false
local reverseY = false
local frameWidth = 80
local frameHeight = 20
local framePadding = 1
local healthbarTexture = "Interface\\TargetingFrame\\UI-StatusBar"
local healthbarColor = {r = 0, g = 0.7, b = 0, a = 1}
local font = "Fonts\\FRIZQT__.TTF"
local fontHeight = 8
local fontColor = {r = 1, g = 1, b = 1, a = 1}


--------------
-- Upvalues --
--------------
local CreateFrame = CreateFrame
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitName = UnitName

---------------
-- Constants --
---------------


---------------
-- Variables --
---------------
local anchorPoint = (reverseY and "TOP" or "BOTTOM") .. (reverseX and "RIGHT" or "LEFT")
local columns = math.ceil(frameCount/rows)
local db
local backdrop = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = nil,
	tile = false,
	edgeSize = 0
}
local statusbarBackdrop = {
	bgFile = "Interface\\TargetingFrame\\UI-StatusBar",
	edgeFile = nil,
	tile = false,
	edgeSize = 0
}

------------------
-- Parent Frame --
------------------
local FramePlatesParent = CreateFrame("Frame", "FramesPlates")
FramePlatesParent.background = CreateFrame("Frame", nil, FramePlatesParent)
FramePlatesParent.background:SetAllPoints()
FramePlatesParent.background:SetBackdrop(backdrop)
FramePlatesParent.background:SetBackdropColor(0.5, 0.5, 0.5, 0.5)
FramePlatesParent.background:Hide()
FramePlatesParent:SetWidth(frameWidth * columns + framePadding * (columns - 1))
FramePlatesParent:SetHeight(frameHeight * rows + framePadding * (rows - 1))
FramePlatesParent:EnableMouse(true)
FramePlatesParent:SetMovable(true)
FramePlatesParent:Show()

---------------
-- Functions --
---------------
do
	local function eventHandler(self, event, unitID)
		if event == "UNIT_HEALTH_FREQUENT" then
			self.statusbar:SetValue(UnitHealth(unitID))
		elseif event == "UNIT_MAXHEALTH" then
			self.statusbar:SetMinMaxValues(0, UnitHealthMax(unitID))
		elseif event == "UNIT_NAME_UPDATE" then
			self.fontString:SetText(UnitName(unitID))
		elseif event == "NAME_PLATE_UNIT_ADDED" then
			self.statusbar:SetMinMaxValues(0, UnitHealthMax(unitID))
			self.statusbar:SetValue(UnitHealth(unitID))
			self.fontString:SetText(UnitName(unitID))
		end
	end

	function FramePlatesParent:CreateFramePlate(unitID, posX, posY)
		-- Secure frame
		local frame = CreateFrame("BUTTON", nil, self, "SecureUnitButtonTemplate")
		self[unitID] = frame
		frame.unitID = unitID
		frame:SetAttribute("type", "target")
		frame:SetAttribute("target", unitID)
		frame:SetAttribute("unit", unitID)
		RegisterUnitWatch(frame)
		frame:SetWidth(frameWidth)
		frame:SetHeight(frameHeight)
		frame:SetPoint(anchorPoint, posX, posY)
		frame:Show()
		
		-- Background
		frame.background = CreateFrame("Frame", nil, frame)
		frame.background:SetAllPoints()
		frame.background:SetBackdrop(statusbarBackdrop)
		frame.background:SetBackdropColor(0, 0, 0, 1)
		
		-- Healthbar
		frame.statusbar = CreateFrame("StatusBar", nil, frame)
		frame.statusbar.unitID = unitID
		frame.statusbar:SetAllPoints()
		frame.statusbar:SetStatusBarTexture(healthbarTexture)
		frame.statusbar:SetStatusBarColor(healthbarColor.r, healthbarColor.g, healthbarColor.b, healthbarColor.a)
		frame.statusbar:SetMinMaxValues(0, UnitHealthMax(unitID))
		
		-- Text
		frame.fontString = frame.statusbar:CreateFontString()
		frame.fontString:SetAllPoints()
		frame.fontString:SetFont(font, fontHeight)
		frame.fontString:SetTextColor(fontColor.r, fontColor.g, fontColor.b, fontColor.a)
		frame.fontString:SetText(UnitName(unitID))
		
		-- Events
		frame:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", unitID)
		frame:RegisterUnitEvent("UNIT_MAXHEALTH", unitID)
		frame:RegisterUnitEvent("UNIT_NAME_UPDATE", unitID)
		frame:RegisterUnitEvent("NAME_PLATE_UNIT_ADDED", unitID)
		frame:SetScript("OnEvent", eventHandler)
		
		return frame
	end
end


--------------------
-- Frame Creation --
--------------------
do
	local i = 1
	local posX = 0
	local posXIncrement = (frameWidth + framePadding) * (reverseX and - 1 or 1)
	local posY = 0
	local posYIncrement = (frameHeight + framePadding) * (reverseY and - 1 or 1)
	if growthDirection == "VERTICAL" then
		for r = 1, rows do
			for c = 1, columns do
				FramePlatesParent:CreateFramePlate("nameplate"..i, posX, posY)
				posX = posX + posXIncrement
				i = i + 1
			end
			posX = 0
			posY = posY + posYIncrement
		end
	else
		for c = 1, columns do
			for r = 1, rows do
				FramePlatesParent:CreateFramePlate("nameplate"..i, posX, posY)
				posY = posY + posYIncrement
				i = i + 1
			end
			posY = 0
			posX = posX + posXIncrement
		end
	end
end


--------------
-- Dragging --
--------------
do
	local function dragStop(self)
		self:StopMovingOrSizing()
		local _, _, _, posX, posY = self:GetPoint()
		db.posX = posX
		db.posY = posY
	end

	function FramePlatesParent:Unlock()
		self.background:Show()
		self:SetScript("OnMouseDown", function(self, button)
			if button == "RightButton" then
				dragStop(self)  -- in case user right clicks while dragging the frame
				self:Lock()
			elseif button == "LeftButton" then
				self:StartMoving()
			end
		end)
		self:SetScript("OnMouseUp", function(self, button)
			dragStop(self)
		end)
		self:SetScript("OnMouseWheel", function(self, delta)
			if IsShiftKeyDown() then
				db.posX = db.posX + delta
			else
				db.posY = db.posY + delta
			end
			self:SetPoint("CENTER", db.posX, db.posY)
		end)
		self.unlocked = true
		print("Frame Plates unlocked")
	end

	function FramePlatesParent:Lock()
		self.background:Hide()
		self:EnableMouse(false)
		self:SetScript("OnMouseDown", nil)
		self:SetScript("OnMouseUp", nil)
		self:SetScript("OnMouseWheel", nil)
		self.unlocked = false
		print("Frame Plates locked")
	end
end


--------------------
-- Initialization --
--------------------
do
	local eventHandler = function(self, event, loadedAddon)
		if loadedAddon == "FramePlates" then
			FramePlatesDB = FramePlatesDB or {}
			db = FramePlatesDB
			db.posX = db.posX or 0
			db.posY = db.posY or 0
			FramePlatesParent:SetPoint("CENTER", db.posX, db.posY)
			FramePlatesParent:UnregisterEvent("ADDON_LOADED")
		end
	end
	FramePlatesParent:RegisterEvent("ADDON_LOADED")
	FramePlatesParent:SetScript("OnEvent", eventHandler)
end


-------------------
-- Slash Command --
-------------------
do
	SLASH_FRAMEPLATES1 = "/frameplates"
	SLASH_FRAMEPLATES2 = "/fp"
	SlashCmdList.FRAMEPLATES = function()
		if FramePlatesParent.unlocked then
			FramePlatesParent:Lock()
		else
			FramePlatesParent:Unlock()
		end
	end
end