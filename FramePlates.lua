--------------
-- Settings --
--------------
-- Visuals
local frameCount = 15
local rows = 15
local growthDirection = "VERTICAL"  -- VERTICAL, HORIZONTAL
local reverseX = false
local reverseY = false
local frameWidth = 80
local frameHeight = 20
local framePadding = 1
local backgroundColor = {r = 0, g = 0, b = 0, a = 1}
local healthBarTexture = "Interface\\ChatFrame\\ChatFrameBackground"  --"Interface\\TargetingFrame\\UI-StatusBar"
local healthBarColorTrivial = {r = 0.4, g = 0.4, b = 0.4, a = 1}
local healthBarBorder = true
local healthBarBorderColor = {r = 0, g = 0, b = 0, a = 1}
local font = "Fonts\\FRIZQT__.TTF"
local fontHeight = 8
local fontFlag = "NONE"  -- "MONOCHROMEOUTLINE" etc.
local fontShadow = true
local fontColor = {r = 1, g = 1, b = 1, a = 1}
local highlightTexture = "Interface\\ChatFrame\\ChatFrameBackground"
local highlightColor = {r = 0.5, g = 0.5, b = 0.5, a = 0.5}
local targetedTexture = "Interface\\ChatFrame\\ChatFrameBackground"
local targetedColor = {r = 0.5, g = 0.5, b = 0.5, a = 0.5}
local colorFunctionString = [[
	self, unitID, r, g, b, a = ...
	if UnitIsTrivial(unitID) then
		return 0.4, 0.4, 0.4, 1
	else
		return r, g, b, a
	end
]]
local auraDirection = "RIGHT"  -- RIGHT, DOWN, LEFT, RIGHT

-- Auras
local auras = {}
auras.Warlock = {
	[1] = {  -- Affliction
		[1] = {
			aura = GetSpellInfo(980),  -- Agony
			icon = select(3, GetSpellInfo(980))
		},
		[2] = {
			aura = GetSpellInfo(172),  -- Corruption
			icon = select(3, GetSpellInfo(172))
		},
		[3] = {
			aura = GetSpellInfo(27243),  -- Seed of Corruption
			icon = select(3, GetSpellInfo(27243))
		}
	},
	[2] = {  -- Demonology
		[1] = {
			aura = GetSpellInfo(603),  -- Doom
			icon = select(3, GetSpellInfo(603))
		}
	}
}
auras.Druid = {
	[1] = {
		[1] = {
			aura = GetSpellInfo(8921),  -- Moonfire
			icon = select(3, GetSpellInfo(8921))
		},
		[2] = {
			aura = GetSpellInfo(93402),  -- Sunfire
			icon = select(3, GetSpellInfo(93402))
		}
	}
}


--------------
-- Upvalues --
--------------
local C_NamePlate_GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local CreateFrame = CreateFrame
local GetTime = GetTime
local pairs = pairs
local UnitAura = UnitAura
local UnitDebuff = UnitDebuff
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
local colorFunction = assert(loadstring(colorFunctionString))
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
local borderBackdrop = {
	bgFile = nil,
	edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
	tile = false,
	edgeSize = 1
}


------------
-- Lookup --
------------
local oppositePoint = {
	RIGHT = "LEFT",
	DOWN = "UP",
	RIGHT = "LEFT",
	UP = "DOWN"
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
	local function getHealthBar(unitID)
		return C_NamePlate_GetNamePlateForUnit(unitID).UnitFrame.healthBar
	end
	
	local function setHealthBarColor(self)
		local unitID = self.unitID
		if not UnitExists(unitID) then
			return
		end
		if not self.healthBar then
			self.healthBar = getHealthBar(unitID)
		end
		if UnitIsUnit(unitID, "target") then
			self.targeted:Show()
		else
			self.targeted:Hide()
		end
		self.statusbar:SetStatusBarColor(colorFunction(self, unitID, self.healthBar.r, self.healthBar.g, self.healthBar.b, self.healthBar.a))
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
	
	local function dotEventHandler(self, event, unitID)
		if event == "NAME_PLATE_UNIT_ADDED" then
			self.duration = nil
			self.expires = nil
		end
		
		local _, _, _, _, _, duration, expires = UnitDebuff(unitID, self.aura, nil, "PLAYER")
		if duration then
			if duration ~= self.duration or expires ~= self.expires then
				self:Show()
				self.cooldown:SetCooldown(expires - duration, duration)
				self.duration = duration
				self.expires = expires
			end
		else
			self:Hide()
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
		
		-- Border
		local border = CreateFrame("Frame", nil, frame.statusbar)
		border:SetAllPoints()
		border:SetBackdrop(borderBackdrop)
		border:SetBackdropBorderColor(healthBarBorderColor.r, healthBarBorderColor.b, healthBarBorderColor.g, healthBarBorderColor.a)
		frame.statusbar.border = border
		
		-- Text
		frame.fontString = frame:CreateFontString()
		frame.fontString:SetAllPoints()
		frame.fontString:SetFont(font, fontHeight, fontFlag)
		frame.fontString:SetTextColor(fontColor.r, fontColor.g, fontColor.b, fontColor.a)
		frame.fontString:SetText(UnitName(unitID))
		if fontShadow then
			frame.fontString:SetShadowOffset(1, -1)
		end
		
		-- Highlighted
		frame.highlight = frame:CreateTexture(nil, "HIGHLIGHT")
		frame.highlight:SetAllPoints()
		frame.highlight:SetTexture(highlightTexture)
		frame.highlight:SetVertexColor(highlightColor.r, highlightColor.g, highlightColor.b, highlightColor.a)
		frame:SetHighlightTexture(frame.highlight, "ADD")
		
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
		
		-- DoTs
		do
			local classAuras = auras[UnitClass("player")]
			if classAuras then
				for specNumber, specAuras in pairs(classAuras) do
					if specAuras then
						local xOffset = 0
						local yOffset = 0
						for k, v in pairs(specAuras) do
							-- DoT parent frame
							local dotFrame = CreateFrame("Frame", nil, frame)
							dotFrame.aura = v.aura
							dotFrame:SetPoint(oppositePoint[auraDirection], frame, auraDirection, xOffset, yOffset)
							dotFrame:SetHeight(frameHeight)  -- TODO: implement proper logic
							dotFrame:SetWidth(frameHeight)
							frame[v.aura] = dotFrame
							
							-- DoT frame texture
							local texture = dotFrame:CreateTexture(nil, "BACKGROUND")
							texture:SetAllPoints()
							texture:SetTexture(v.icon)
							dotFrame.texture = texture
							
							-- DoT cooldown
							local cooldown = CreateFrame("Cooldown", nil, dotFrame, "CooldownFrameTemplate")
							cooldown:SetAllPoints()
							dotFrame.cooldown = cooldown
							
							dotFrame:RegisterUnitEvent("UNIT_AURA", unitID)
							dotFrame:RegisterUnitEvent("NAME_PLATE_UNIT_ADDED", unitID)
							dotFrame:SetScript("OnEvent", dotEventHandler)
							
							xOffset = xOffset + frameHeight  -- TODO: implement proper logic
							-- yOffset
						end
					end
				end
			end
		end
		
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