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
local backgroundColor = {r = 0, g = 0, b = 0, a = 1}
local healthBarTexture = "Interface\\TargetingFrame\\UI-StatusBar"
local healthBarColorTrivial = {r = 0.4, g = 0.4, b = 0.4, a = 1}
local font = "Fonts\\FRIZQT__.TTF"
local fontHeight = 8
local fontFlag = "OUTLINE"
local fontColor = {r = 1, g = 1, b = 1, a = 1}
local highlightTexture = "Interface\\ChatFrame\\ChatFrameBackground"
local highlightColor = {r = 0.5, g = 0.5, b = 0.5, a = 0.5}
local targetedTexture = "Interface\\ChatFrame\\ChatFrameBackground"
local targetedColor = {r = 0.5, g = 0.5, b = 0.5, a = 0.5}


--------------
-- Upvalues --
--------------
local C_NamePlate_GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local CreateFrame = CreateFrame
local UnitExists = UnitExists
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsEnemy = UnitIsEnemy
local UnitIsFriend = UnitIsFriend
local UnitIsTapDenied = UnitIsTapDenied
local UnitIsTrivial = UnitIsTrivial
local UnitIsUnit = UnitIsUnit
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
local FramePlatesParent = CreateFrame("Frame", "FramePlates")
FramePlatesParent.background = CreateFrame("Frame", nil, FramePlatesParent)
FramePlatesParent.background:SetAllPoints()
FramePlatesParent.background:SetBackdrop(backdrop)
FramePlatesParent.background:SetBackdropColor(0.5, 0.5, 0.5, 0.5)
FramePlatesParent.background:Hide()
FramePlatesParent:SetWidth(frameWidth * columns + framePadding * (columns - 1))
FramePlatesParent:SetHeight(frameHeight * rows + framePadding * (rows - 1))
FramePlatesParent:SetMovable(true)
FramePlatesParent:Show()

---------------
-- Functions --
---------------
do
	local trivialR, trivialG, trivialB, trivialA = healthBarColorTrivial.r, healthBarColorTrivial.g, healthBarColorTrivial.b, healthBarColorTrivial.a
	
	local function getHealthBar(unitID)
		return C_NamePlate_GetNamePlateForUnit(unitID).UnitFrame.healthBar
	end
	
	local function setHealthBarColor(self)
		local unitID = self.unitID
		if not UnitExists(unitID) then
			return
		end
		local statusbar = self.statusbar
		if not self.healthBar then
			self.healthBar = getHealthBar(unitID)
		end
		if UnitIsTrivial(unitID) then
			statusbar:SetStatusBarColor(trivialR, trivialG, trivialB, trivialA)
		else
			statusbar:SetStatusBarColor(self.healthBar.r, self.healthBar.g, self.healthBar.b, self.healthBar.a)
		end
		if UnitIsUnit(unitID, "target") then
			self.targeted:Show()
		else
			self.targeted:Hide()
		end
	end	
	
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
			self.healthBar = getHealthBar(unitID)
			self:SetHealthBarColor()
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
		frame.background:SetBackdropColor(backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundColor.a)
		
		-- Health Bar
		frame.statusbar = CreateFrame("StatusBar", nil, frame)
		frame.statusbar.unitID = unitID
		frame.statusbar:SetAllPoints()
		frame.statusbar:SetStatusBarTexture(healthBarTexture)
		frame.statusbar:SetMinMaxValues(0, UnitHealthMax(unitID))
		frame.SetHealthBarColor = setHealthBarColor
		frame:SetHealthBarColor()
		
		-- Text
		frame.fontString = frame:CreateFontString()
		frame.fontString:SetAllPoints()
		frame.fontString:SetFont(font, fontHeight, fontFlag)
		frame.fontString:SetTextColor(fontColor.r, fontColor.g, fontColor.b, fontColor.a)
		frame.fontString:SetText(UnitName(unitID))
		
		-- Highlighted
		frame.highlight = frame:CreateTexture(nil, "HIGHLIGHT")
		frame.highlight:SetAllPoints()
		frame.highlight:SetTexture(highlightTexture)
		frame.highlight:SetVertexColor(highlightColor.r, highlightColor.g, highlightColor.b, highlightColor.a)
		frame:SetHighlightTexture(frame.highlight, "BLEND")
		
		-- Targeted
		frame.targeted = frame:CreateTexture(nil, "ARTWORK")
		frame.targeted:SetAllPoints()
		frame.targeted:SetTexture(targetedTexture)
		frame.targeted:SetVertexColor(targetedColor.r, targetedColor.g, targetedColor.b, targetedColor.a)
		frame.targeted:Hide()
		
		-- Events
		frame:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", unitID)
		frame:RegisterUnitEvent("UNIT_MAXHEALTH", unitID)
		frame:RegisterUnitEvent("UNIT_NAME_UPDATE", unitID)
		frame:RegisterUnitEvent("NAME_PLATE_UNIT_ADDED", unitID)
		frame:SetScript("OnEvent", eventHandler)
		
		-- Frame levels
		frame:SetFrameStrata("LOW")
		frame.background:SetFrameStrata("BACKGROUND")
		frame.statusbar:SetFrameStrata("BACKGROUND")
		
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
				if i > frameCount then
					break
				end
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
				if i > frameCount then
					break
				end
			end
			posY = 0
			posX = posX + posXIncrement
		end
	end
end


------------
-- Ticker --
------------
do
	local tickerFrame = CreateFrame("Frame")
	local totalElapsed = 0
	local function tickerFunc(self, elapsed)
		totalElapsed = totalElapsed + elapsed
		if totalElapsed > 0.2 then
			for i = 1, frameCount do
				FramePlatesParent["nameplate"..i]:SetHealthBarColor()
			end
			totalElapsed = 0
		end
	end
	tickerFrame:SetScript("OnUpdate", tickerFunc)
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
		self:EnableMouse(true)
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