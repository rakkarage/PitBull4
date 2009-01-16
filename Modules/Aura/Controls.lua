-- Controls.lua : Implement the controls we need for the Aura module.

if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local _G = getfenv(0)
local PitBull4 = _G.PitBull4
local L = PitBull4.L
local PitBull4_Aura = PitBull4:GetModule("Aura")

local MAINHAND = PitBull4_Aura.MAINHAND
local OFFHAND = PitBull4_Aura.OFFHAND

-- Table of functions included into the aura controls
local Aura = {}

-- Table of scripts set on a control
local Aura_scripts = {}

-- Calculate the path to the texture for the borders.
local border_path
do
	local module_path = _G.debugstack():match("[d%.][d%.][O%.]ns\\(.-)\\[A-Za-z0-9]-%.lua")
	border_path = "Interface\\AddOns\\" .. module_path .. "\\border"
end

-- Get the unit the aura applies to.
function Aura:GetUnit()
      return self:GetParent().unit
end


-- Update handler for tooltips.
-- Not in the Aura table since it is only active when the
-- tooltip is displayed.
local last_aura_OnUpdate = 0
local function OnUpdate(self)
	local current_time = GetTime()
	if last_aura_OnUpdate+0.2 > current_time then
		return
	end
	last_aura_onUpdate = current_time
	if self.id > 0 then
		-- Real Buffs
		if self.is_buff then
			GameTooltip:SetUnitBuff(self:GetUnit(), self.id)
		else
			GameTooltip:SetUnitDebuff(self:GetUnit(), self.id)
		end
	elseif self.slot then
		GameTooltip:SetInventoryItem("player", self.slot)	
	else
		-- Sample auras for config mode
		GameTooltip:ClearLines()
		-- Note that debuff_type gets localized here when displaying it
		-- because it needs to be in English for sorting and border
		-- purposes.  However the debuff types still need to be in our
		-- localization tables.  They are L["Poison"], L["Magic"],
		-- L["Disease"], L["Enrage"]
		GameTooltip:AddDoubleLine(self.name, self.debuff_type and L[self.debuff_type] or "", 1, 0.82, 0, 1, 0.82, 0)
		GameTooltip:AddLine(L["Sample aura created by PitBull to allow you to see the results of your configuration easily."], 1, 1, 1, 1)
		if self.is_mine then
			GameTooltip:AddLine(L["Aura shown as if cast by you."], 1, 0.82, 0, 1)
		else
			GameTooltip:AddLine(L["Aura shown as if cast by someone else."], 1, 0.82, 0, 1)
		end
		GameTooltip:Show()
	end
end

-- Click handler to allow buffs to be canceled.
-- Not in the Aura table since it is only active on
-- buff aura controls.
local function OnClick(self)
	local slot = self.slot
	if not self.is_buff or (not self.is_mine and not slot) then return end
	if slot then
		if slot == MAINHAND then
			CancelItemTempEnchantment(1)
		elseif slot == OFFHAND then
			CancelItemTempEnchantment(2)
		end
	else
		CancelUnitBuff("player", self.id)
	end
end

function Aura:SetCancelable(is_cancelable)
	if is_cancelable then
		self:SetScript("OnClick", OnClick)
	else
		self:SetScript("OnClick", nil)
	end
end

function Aura_scripts:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	last_aura_OnUpdate = 0
	self:SetScript("OnUpdate", OnUpdate)
	OnUpdate(self)
end

function Aura_scripts:OnLeave()
	GameTooltip:Hide()
	self:SetScript("OnUpdate", nil)
end

-- Control for the Auras
PitBull4.Controls.MakeNewControlType("Aura", "Button", function(control)
	-- onCreate
	control:RegisterForClicks("RightButtonUp")

	local texture = PitBull4.Controls.MakeTexture(control, "BACKGROUND")
	control.texture = texture
	texture:SetAllPoints(control)

	local border = PitBull4.Controls.MakeTexture(control, "BORDER")
	control.border = border
	border:SetAllPoints(control)
	border:SetTexture(border_path)

	local count_text = PitBull4.Controls.MakeFontString(control, "OVERLAY")
	control.count_text = count_text
	-- TODO configurable font
	local font, font_size = ChatFontNormal:GetFont()
	count_text:SetFont(font, font_size, "OUTLINE")
	count_text:SetShadowColor(0, 0, 0, 1)
	count_text:SetShadowOffset(0.8, -0.8)
	count_text:SetPoint("BOTTOMRIGHT", control, "BOTTOMRIGHT", 0, 0)

	local cooldown = PitBull4.Controls.MakeCooldown(control)
	control.cooldown = cooldown
	cooldown:SetReverse(true)
	cooldown:SetAllPoints(control)

	local cooldown_text = PitBull4.Controls.MakeFontString(control, "OVERLAY")
	control.cooldown_text = cooldown_text
	-- TODO configurable font
	cooldown_text:SetFont(font, font_size, "OUTLINE")
	cooldown_text:SetShadowColor(0, 0, 0, 1)
	cooldown_text:SetShadowOffset(0.8, -0.8)
	cooldown_text:SetPoint("TOP", control, "TOP", 0, 0)

	for k,v in pairs(Aura) do
		control[k] = v
	end
	for k,v in pairs(Aura_scripts) do
		control:SetScript(k, v)
	end
end, function(control)
	-- onRetrieve
	-- It's important to note that you should never ever do something
	-- here that is dependent upon the actual aura being set or even
	-- the unit of the frame it is parented to.  It is fine to do things
	-- that depend upon the frame it is parented to here.  Other than
	-- that everything should be done when the actual aura is set on
	-- the control.  This is because the controls are recyled unless
	-- the number of them changes a new control will not be retrieved.
-- TODO: Fix frame levels.  Need to talk to ck about figuring out
-- standards for framelevels.
--	control:SetFrameLevel(control:GetParent():GetFrameLevel() + 2)
end, function(control)
	-- onDelete
	control:SetScript("OnClick", nil)
	control:SetScript("OnUpdate", nil)
end)

-- Control for the cooldown spinner
PitBull4.Controls.MakeNewControlType("Cooldown", "Cooldown", function(control)
	-- onCreate
end, function(control)
	-- onRetrieve
end, function(control)
end)