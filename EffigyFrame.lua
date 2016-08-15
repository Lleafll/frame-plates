---------------
-- Libraries --
---------------
local LSM = LibStub("LibSharedMedia-3.0")



---------------
-- Constants --
---------------
local UI_SCALE = UIParent:GetScale()



--------------
-- Settings --
--------------
local frameCount = 15
local frameWidth = 163 / UI_SCALE
local frameHeight = 30 / UI_SCALE
local framePadding = 2
local backgroundColor = {r = 17/256, g = 17/256, b = 17/256, a = 1}
local healthBarTexture = LSM:Fetch("statusbar", "Smooth v2")
local healthBarBorder = true
local healthBarBorderColor = {r = 0, g = 0, b = 0, a = 1}
local font = LSM:Fetch("font", "PT Sans Narrow")
local fontHeight = 8 / UI_SCALE
local fontFlag = "NONE"  -- "MONOCHROMEOUTLINE" etc.
local fontShadow = true
local fontColor = {r = 1, g = 1, b = 1, a = 1}
local distanceFont = font
local distanceFontHeight = 8 / UI_SCALE
local distanceFontFlag = "NONE"  -- "MONOCHROMEOUTLINE" etc.
local distanceFontShadow = true
local distanceFontColor = {r = 1, g = 1, b = 1, a = 1}
local highlightTexture = "Interface\\ChatFrame\\ChatFrameBackground"
local highlightColor = {r = 0.5, g = 0.5, b = 0.5, a = 0.5}
local targetedTexture = "Interface\\ChatFrame\\ChatFrameBackground"
local targetedColor = {r = 0.5, g = 0.5, b = 0.5, a = 0.5}



--------------
-- Upvalues --
--------------
local C_NamePlate_GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local CreateFrame = CreateFrame
local GetTime = GetTime
local IsItemInRange = IsItemInRange
local ItemHasRange = ItemHasRange
local math_ceil = math.ceil
local math_floor = math.floor
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
-- Variables --
---------------
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
  edgeSize = 1,
  padding = 1
}



------------------
-- Parent Frame --
------------------
local EffigyFrameParent = CreateFrame("Frame", "EffigyFrame", UIParent)
EffigyFrameParent.background = CreateFrame("Frame", nil, EffigyFrameParent)
EffigyFrameParent.background:SetAllPoints()
EffigyFrameParent.background:SetBackdrop(backdrop)
EffigyFrameParent.background:SetBackdropColor(0.5, 0.5, 0.5, 0.5)
EffigyFrameParent.background:Hide()
EffigyFrameParent:SetWidth(UI_SCALE * frameWidth)
EffigyFrameParent:SetHeight(UI_SCALE * frameHeight)
EffigyFrameParent:SetMovable(true)
EffigyFrameParent:SetUserPlaced(false)
EffigyFrameParent:Show()



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
      self.NameFontString:SetText(UnitName(unitID))
    elseif event == "NAME_PLATE_UNIT_ADDED" then
      self.statusbar:SetMinMaxValues(0, UnitHealthMax(unitID))
      self.statusbar:SetValue(UnitHealth(unitID))
      self.NameFontString:SetText(UnitName(unitID))
      if UnitName(unitID) == "Soul Effigy" then
        self.parent:SetPoint("BOTTOMLEFT")
      end
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
      self.parent:SetPoint("BOTTOMLEFT", UIParent, "TOPRIGHT")
    end
  end

  function EffigyFrameParent:CreateEffigyFrame(unitID)
    -- Parent frame (for position manipulation)
    local parentFrame = CreateFrame("Frame", "$parent".."_"..unitID, self)
    parentFrame:SetWidth(UI_SCALE * frameWidth)
    parentFrame:SetHeight(UI_SCALE * frameHeight)
    parentFrame:SetPoint("BOTTOMLEFT", UIParent, "TOPRIGHT")
    parentFrame:Show()
    
    -- Secure frame
    local frame = CreateFrame("BUTTON", "$parentButton", parentFrame, "SecureUnitButtonTemplate")
    frame.parent = parentFrame
    self[unitID] = frame
    frame.unitID = unitID
    frame:SetAttribute("type", "target")
    frame:SetAttribute("target", unitID)
    frame:SetAttribute("unit", unitID)
    RegisterUnitWatch(frame)
    frame:SetWidth(UI_SCALE * frameWidth)
    frame:SetHeight(UI_SCALE * frameHeight)
    frame:SetPoint("BOTTOMLEFT")
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
    
    -- Border
    local border = CreateFrame("Frame", nil, frame.statusbar)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop(borderBackdrop)
    border:SetBackdropBorderColor(healthBarBorderColor.r, healthBarBorderColor.b, healthBarBorderColor.g, healthBarBorderColor.a)
    frame.statusbar.border = border
    
    -- Name
    frame.NameFontString = frame:CreateFontString()
    frame.NameFontString:SetAllPoints()
    frame.NameFontString:SetFont(font, fontHeight, fontFlag)
    frame.NameFontString:SetTextColor(fontColor.r, fontColor.g, fontColor.b, fontColor.a)
    frame.NameFontString:SetText(UnitName(unitID))
    if fontShadow then
      frame.NameFontString:SetShadowOffset(1, -1)
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
    frame:RegisterUnitEvent("NAME_PLATE_UNIT_REMOVED", unitID)
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
function EffigyFrameParent:CreateFrames()
  for i = 1, frameCount do
    self:CreateEffigyFrame("nameplate"..i)
  end
end



--------------
-- Dragging --
--------------
do
  local function dragStop(self)
    self:StopMovingOrSizing()
    
    local posX, posY = self:GetRect()
    
    db.posX = math_floor(posX / UI_SCALE + 0.5)
    db.posY = math_floor(posY / UI_SCALE + 0.5)
    
    self:SetPoint("BOTTOMLEFT", UI_SCALE * db.posX, UI_SCALE * db.posY)
  end

  function EffigyFrameParent:Unlock()
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
        db.posX = db.posX + delta / UI_SCALE
      else
        db.posY = db.posY + delta / UI_SCALE
      end
      self:SetPoint("BOTTOMLEFT", UI_SCALE * db.posX, UI_SCALE * db.posY)
    end)
    self.unlocked = true
    print("EffigyFrame unlocked")
  end

  function EffigyFrameParent:Lock()
    self.background:Hide()
    self:EnableMouse(false)
    self:SetScript("OnMouseDown", nil)
    self:SetScript("OnMouseUp", nil)
    self:SetScript("OnMouseWheel", nil)
    self.unlocked = false
    print("EffigyFrame locked")
  end
end



--------------------
-- Initialization --
--------------------
do
  local eventHandler = function(self, event, loadedAddon)
    if loadedAddon == "EffigyFrame" then
      EffigyFrameDB = EffigyFrameDB or {}
      db = EffigyFrameDB
      db.posX = db.posX or 300
      db.posY = db.posY or 300
      self:SetPoint("BOTTOMLEFT", UI_SCALE * db.posX, UI_SCALE * db.posY)
      self:UnregisterEvent("ADDON_LOADED")
      self:CreateFrames()
    end
  end 
  EffigyFrameParent:RegisterEvent("ADDON_LOADED")
  EffigyFrameParent:SetScript("OnEvent", eventHandler)
end



-------------------
-- Slash Command --
-------------------
SLASH_EFFIGYFRAME1 = "/effigyframe"
SLASH_EFFIGYFRAME2 = "/ef"
SlashCmdList.EFFIGYFRAME = function()
  if EffigyFrameParent.unlocked then
    EffigyFrameParent:Lock()
  else
    EffigyFrameParent:Unlock()
  end
end