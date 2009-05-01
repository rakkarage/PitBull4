-- Update.lua : Code to collect the auras on a unit, create the
-- aura frames and set the data to display the auras.

if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local _G = getfenv(0)
local PitBull4 = _G.PitBull4
local PitBull4_Aura = PitBull4:GetModule("Aura")
local L = PitBull4.L
local UnitAura = _G.UnitAura
local GetWeaponEnchantInfo = _G.GetWeaponEnchantInfo
local ceil = _G.math.ceil
local GetTime = _G.GetTime
local unpack = _G.unpack
local sort = _G.table.sort
local wipe = _G.table.wipe

-- The table we use for gathering the aura data, filtering
-- and then sorting them.  This table is reused without
-- wiping it ever, so care must be taken to use it in ways
-- that don't break this optimization.
--
-- The table consists of indexed entries of other tables.
-- These tables contains a list of values that are returned
-- from UnitAura or in the case of other sources of auras
-- generated by PitBull.  PitBull's own extra values must
-- be in the positions ahead of those used by UnitAura() otherwise
-- any new returns from UnitAura will break the module.
--
-- The entry values are as follows
-- [1] = index used to get the Aura with UnitAura or 0 for non UnitAura entries
-- [2] = slot of the weapon enchant or nil if not a weapon enchant
-- [3] = quality of the weapon or nil if not a weapon enchant
-- [4] = is_buff
-- [5] = name
-- [6] = rank
-- [7] = icon
-- [8] = count
-- [9] = debuff_type
-- [10] = duration
-- [11] = expiration_time
-- [12] = caster 
-- [13] = is_stealable
local list = {}

-- pool of available entries to be used in list
local pool = {}

-- The final index of the entries.  We need this so we can always
-- get all values when copying or using unpack.
local ENTRY_END = 13

-- Table we store the weapon enchant info in.
-- This table is never cleared and entries are reused.
-- The entry tables follow the same format as those used for the aura
-- list.  Since they are simply copied into that list.  To avoid
-- GC'ing entries constantly when there is no MH or OH enchant the
-- index 2 (the slot value) is set to nil.
local weapon_list = {}

-- cache for weapon enchant durations
-- contains the name of the enchant and the value of the duration
local weapon_durations = {}

-- constants for the slot ids
local MAINHAND = PitBull4_Aura.MAINHAND
local OFFHAND = PitBull4_Aura.OFFHAND

-- constants for building sample auras
local sample_buff_icon   = [[Interface\Icons\Spell_ChargePositive]]
local sample_debuff_icon = [[Interface\Icons\Spell_ChargeNegative]]
local sample_debuff_types = { 'Poison', 'Magic', 'Disease', 'Curse', 'Enrage', 'nil', }

-- constants for formating time
local HOUR_ONELETTER_ABBR = _G.HOUR_ONELETTER_ABBR:gsub("%s", "") -- "%dh"
local MINUTE_ONELETTER_ABBR = _G.MINUTE_ONELETTER_ABBR:gsub("%s", "") -- "%dm"

-- units to consider mine
local my_units = {
	player = true,
	pet = true,
	vehicle = true,
}


-- table of dispel types we can dispel
local can_dispel = PitBull4_Aura.can_dispel.player

local function new_entry()
	local t = next(pool)
	if t then
		pool[t] = nil
	else
		t = {}
	end
	return t
end

local function del_entry(t)
	wipe(t)
	pool[t] = true
	return nil
end

-- Fills an array of arrays with the information about the auras
local function get_aura_list(list, unit, db, is_buff, frame)
	if not unit then return end
	local filter = is_buff and "HELPFUL" or "HARMFUL"
	local id = 1
	local index = 1

	-- Loop through the auras
	while true do
		local entry = list[index]
		if not entry then
			entry = new_entry()
			list[index] = entry
		end

		-- Note entry[2] says if the aura is a weapon enchant
		entry[1], entry[2], entry[3], entry[4], entry[5], entry[6],
			entry[7], entry[8], entry[9], entry[10], entry[11],
			entry[12], entry[13] =
			id, nil, nil, is_buff, UnitAura(unit, id, filter)

		-- Hack to get around a Blizzard bug.  The Enrage debuff_type
		-- gets set to "" instead of "Enrage" like it should.
		-- Once this is fixed this code should be removed.
		if entry[9] == "" then
			entry[9] = "Enrage"
		end

		-- Make pre 3.1.0 clients emulate the return of the caster
		-- argument in the new 3.1.0 clients.  Once 3.1.0 is
		-- live for everyone this can be removed
		if entry[12] == 1 then
			entry[12] = "player"
		end

		if not entry[5] then
			-- No more auras, break the outer loop
			break
		end

		-- Pass the entry through to the Highlight system
		if db.highlight then
			PitBull4_Aura:HighlightFilter(db, entry, frame)
		end

		-- Filter the list if not true
		local pb4_filter_name = is_buff and db.layout.buff.filter or db.layout.debuff.filter
		if PitBull4_Aura:FilterEntry(pb4_filter_name, entry, frame) then
			-- Reuse this index position if the aura was
			-- filtered.
			index = index + 1
		end

		id = id + 1

	end

	-- Clear the list of extra entries
	for i = index, #list do
		list[i] = del_entry(list[i])
	end

	return list
end

-- Fills up to the maximum number of auras with sample auras
local function get_aura_list_sample(list, unit, max, db, is_buff)
	-- figure the slot to use for the mainhand and offhand slots
	local mainhand, offhand
	if is_buff and db.enabled_weapons and unit and UnitIsUnit(unit, "player") then
		if not weapon_list[MAINHAND] then
			mainhand = #list + 1
		end
		if not weapon_list[OFFHAND] then
			offhand = (mainhand and mainhand + 1) or #list + 1
		end
	end

	for i = #list + 1, max do
		local entry = list[i]
		if not entry then
			entry = new_entry()
			list[i] = entry
		end


		-- Create our bogus aura entry
		entry[1]  = 0 -- index 0 means PitBull generated aura
		if i == mainhand then
			entry[2] = MAINHAND
			local link = GetInventoryItemLink("player", OFFHAND)
			entry[3] = link and select(3,GetItemInfo(link)) or 4 -- quality or epic if no item
			entry[5] = L["Sample Weapon Buff"] -- name
			entry[9] = nil -- no debuff type
			entry[12] = "player" -- treat weapon enchants as yours
		elseif i == offhand then
			entry[2] = OFFHAND
			local link = GetInventoryItemLink("player", OFFHAND)
			entry[3] = link and select(3,GetItemInfo(link)) or 4 -- quality or epic if no item
			entry[5] = L["Sample Weapon Buff"] -- name
			entry[9] = nil -- no debuff type
			entry[12] = "player" -- treat weapon enchants as yours
		else
			entry[2]  = nil -- not a weapon enchant
			entry[3]  = nil -- no quality color
			entry[5]  = is_buff and L["Sample Buff"] or L["Sample Debuff"] -- name
			entry[9]  = sample_debuff_types[(i-1)% #sample_debuff_types]
			entry[12]  = ((random(2) % 2) == 1) and "player" or nil -- caster 
		end
		entry[4]  = is_buff
		entry[6]  = "" -- rank
		entry[7]  = is_buff and sample_buff_icon or sample_debuff_icon
		entry[8]  = i -- count set to index to make order show
		entry[10]  = 0 -- duration
		entry[11]  = 0 -- expiration_time
		entry[13] = nil -- is_stealable
	end
end

-- Get the name of the temporary enchant on a weapon from the tooltip
-- given the item slot the weapon is in.
local get_weapon_enchant_name
do
	local tt = CreateFrame("GameTooltip", "PitBull4_Aura_Tooltip", UIParent)
	tt:SetOwner(UIParent, "ANCHOR_NONE")
	local left = {}

	local g = tt:CreateFontString()
	g:SetFontObject(GameFontNormal)
	for i = 1, 30 do
		local f = tt:CreateFontString()
		f:SetFontObject(_G.GameFontNormal)
		tt:AddFontStrings(f, g)
		left[i] = f
	end

	get_weapon_enchant_name = function(slot)
		tt:ClearLines()
		if not tt:IsOwned(UIParent) then
			tt:SetOwner(UIParent, "ANCHOR_NONE")
		end
		tt:SetInventoryItem("player", slot)

		for i = 1, 30 do
			local text = left[i]:GetText()
			if text then
				local buff_name = text:match("^(.+) %(%d+ [^$)]+%)$")
				if buff_name then
					local buff_name_no_rank = buff_name:match("^(.*) %d+$")
					return buff_name_no_rank or buff_name
				end
			else
				break
			end
		end
	end
end

-- Looks for a spell with the name of the temporary weapon enchant
-- in its name.  This let's use display the spell icon instead of
-- the weapon icon for things like rogue poisons and shaman enchant
-- spells.
local guess_spell_icon = setmetatable({}, {__index=function(self, key)
	if not key then return false end
	for i = 1, 65535 do
		local name, _, texture = GetSpellInfo(i)
		if name and name:find(key) then
			self[key] = texture
			return texture
		end
	end

	-- Remember that we can't find it
	self[key] = false
	return false
end})

-- Takes the data for a weapon enchant and builds an aura entry
local function set_weapon_entry(list, is_enchant, time_left, expiration_time, count, slot)
	local entry = list[i]
	if not entry then
		entry = {}
		list[slot] = entry
	end

	-- No such enchant, clear the table
	if is_enchant ~= 1 then
		wipe(entry)
		return
	end

	local weapon, _, quality, _, _, _, _, _, _, texture = GetItemInfo(GetInventoryItemLink("player", slot))
	-- Try and get the name of the enchant from the tooltip, if not
	-- use the weapon name.
	local name = get_weapon_enchant_name(slot) or weapon
	if PitBull4_Aura.db.profile.global.guess_weapon_enchant_icon then
		texture = guess_spell_icon[name] or texture
	end

	-- Figure the duration by keeping track of the longest
	-- time_left we've seen.
	local duration = weapon_durations[name]
	time_left = ceil(time_left / 1000)
	if not duration or duration < time_left then
		duration = time_left
		weapon_durations[name] = duration
	end

	entry[1] = 0 -- index 0 means PitBull generated aura
	-- If there's no enchant set we set entry[2] to nil
	entry[2] = slot -- a weapon enchant
	entry[3] = quality
	entry[4] = true -- is_buff
	entry[5] = name
	entry[6] = "" -- rank
	entry[7] = texture
	entry[8] = count
	entry[9] = nil
	entry[10] = duration
	entry[11] = expiration_time
	entry[12] = "player" -- treat weapon enchants as always yours
	entry[13] = nil -- is_stealable
end

-- If the src table has a valid weapon enchant entry for the slot
-- copy it to the dst table.  Uses #dst + 1 to determine next entry
local function copy_weapon_entry(src, dst, slot)
	local src_entry = src[slot]
	-- If there's no src_entry or the slot value of the src_entry
	-- is empty don't copy anything.
	if not src_entry or not src_entry[2] then return end
	local i = #dst + 1
	local dst_entry = dst[i]
	if not dst_entry then
		dst_entry = new_entry()
		dst[i] = dst_entry
	end

	for pos = 1, ENTRY_END do
		dst_entry[pos] = src_entry[pos]
	end
end

local aura_sort__is_friend
local aura_sort__is_buff

local function aura_sort(a, b)
	if not a then
		return false
	elseif not b then
		return true
	end

	-- item buffs first
	local a_slot, b_slot = a[2], b[2]
	if a_slot and not b_slot then
		return true
	elseif not a_slot and b_slot then
		return false
	elseif a_slot and b_slot then
		return a_slot < b_slot
	end

	-- show your own auras first
	local a_mine, b_mine=  my_units[a[12]], my_units[b[12]]
	if a_mine~= b_mine then
		if a_mine then
			return true
		elseif b_mine then
			return false
		end
	end

	--  sort by debuff type
	if (aura_sort__is_buff and not aura_sort__is_friend) or (not aura_sort__is_buff and aura_sort__is_friend) then
		local a_debuff_type, b_debuff_type = a[9], b[9]
		if a_debuff_type ~= b_debuff_type then
			if not a_debuff_type then
				return false
			elseif not b_debuff_type then
				return true
			end
			local a_can_dispel = can_dispel[a_debuff_type]
			if not a_can_dispel ~= not can_dispel[b_debuff_type] then
				-- show debuffs you can dispel first
				if a_can_dispel then
					return true
				else
					return false
				end
			end
			return a_debuff_type < b_debuff_type
		end
	end

	-- sort real auras before samples
	local a_id, b_id = a[1], b[1]
	if a_id ~= 0 and b_id == 0 then
		return true
	elseif a_id == 0 and b_id ~= 0 then
		return false
	end

	-- sort by name
	local a_name, b_name = a[5], b[5]
	if a_name ~= b_name then
		if not a_name then
			return true
		elseif not b_name then
			return false
		end
		-- TODO: Add sort by ones we can cast
		return a_name < b_name
	end

	-- Use count for sample ids to preserve ID order.
	if a_id == 0 and b_id == 0 then
		local a_count, b_count = a[8], b[8]
		if not a_count then
			return false
		elseif not b_count then
			return true
		end
		return a_count < b_count
	end

	-- keep ID order
	if not a_id then
		return false
	elseif not b_id then
		return true
	end
	return a_id < b_id
end

-- Setups up the aura frame and fill it with the proper data
-- to display the proper aura.
local function set_aura(frame, db, aura_controls, aura, i, is_friend)
	local control = aura_controls[i]

	local id, slot, quality, is_buff, name, rank, icon, count, debuff_type, duration, expiration_time, caster, is_stealable = unpack(aura, 1, ENTRY_END)

	local is_mine = my_units[caster]
	local who = is_mine and "my" or "other"
	-- No way to know who applied a weapon buff so we have a separate
	-- category for them.
	if slot then who = "weapon" end
	local rule = who .. '_' .. (is_buff and "buffs" or "debuffs")

	if not control then
		control = PitBull4.Controls.MakeAura(frame)
		aura_controls[i] = control
	end

	control.id = id
	control.is_mine = is_mine
	control.is_buff = is_buff
	control.name = name
	control.count = count
	control.expiration_time = expiration_time
	control.debuff_type = debuff_type
	control.slot = slot

	local class_db = frame.classification_db
	if class_db and not class_db.click_through then
		control:EnableMouse(true)
	else
		control:EnableMouse(false)
	end

	local texture = control.texture
	texture:SetTexture(icon)
	if db.zoom_aura then
		texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	else
		texture:SetTexCoord(0, 1, 0, 1)
	end

	control.count_text:SetText(count > 1 and count or "")

	if db.cooldown[rule] and duration and duration > 0 then
		local cooldown = control.cooldown
		cooldown:Show()
		cooldown:SetCooldown(expiration_time - duration, duration)
	else
		control.cooldown:Hide()
	end

	if db.cooldown_text[rule] and duration and duration > 0 then
		control.cooldown_text:Show()
	else
		control.cooldown_text:Hide()
	end

	if db.border[rule] then
		local border = control.border
		local colors = PitBull4_Aura.db.profile.global.colors
		border:Show()
		if quality and colors.weapon.quality_color then
			local r,g,b = GetItemQualityColor(quality)
			border:SetVertexColor(r,g,b)
		elseif slot then
			border:SetVertexColor(unpack(colors.weapon[who]))
		elseif (is_buff and is_friend) or (not is_buff and not is_friend) then
			border:SetVertexColor(unpack(colors.friend[who]))
		else
			local color = colors.enemy[tostring(debuff_type)]
			if not color then
				-- Use the Other color if there's not
				-- a color for the specific debuff type.
				color = colors.enemy["nil"]
			end
			border:SetVertexColor(unpack(color))
		end
	else
		control.border:Hide()
	end
end

local function update_auras(frame, db, is_buff)
	-- Get the controls table
	local controls
	if is_buff then
		controls = frame.aura_buffs
		if not controls then
			controls = {}
			frame.aura_buffs = controls
		end
	else
		controls = frame.aura_debuffs
		if not controls then
			controls = {}
			frame.aura_debuffs = controls
		end
	end
	local unit = frame.unit
	local is_friend = unit and UnitIsFriend("player", unit)

	local max = is_buff and db.max_buffs or db.max_debuffs

	get_aura_list(list, unit, db, is_buff, frame)


	-- If weapons are enabled and the unit is the player
	-- copy the weapon entries into the aura list
	if is_buff and db.enabled_weapons and unit and UnitIsUnit(unit,"player") then
		local filter = db.layout.buff.filter
		copy_weapon_entry(weapon_list, list, MAINHAND)
		if list[#list] and not PitBull4_Aura:FilterEntry(filter, list[#list], frame) then
			list[#list] = del_entry(list[#list])
		end
		copy_weapon_entry(weapon_list, list, OFFHAND)
		if list[#list] and not PitBull4_Aura:FilterEntry(filter, list[#list], frame) then
			list[#list] = del_entry(list[#list])
		end
	end

	if frame.force_show then
		-- config mode so treat sample frames as friendly
		if not unit or not UnitExists(unit) then
			is_friend = true
		end

		-- Fill extra auras if we're in config mode
		get_aura_list_sample(list, unit, max, db, is_buff)
	end

	local layout = is_buff and db.layout.buff or db.layout.debuff
	if layout.sort then
		aura_sort__is_friend = is_friend
		aura_sort__is_buff = is_buff
		sort(list, aura_sort)
	end

	-- Limit the number of displayed buffs here after we
	-- have filtered and sorted to allow the most important
	-- auras to be displayed rather than randomly tossing
	-- some away that may not be our prefered auras
	local buff_count = (#list > max) and max or #list

	for i = 1, buff_count do
		set_aura(frame, db, controls, list[i], i, is_friend)
	end

	-- Remove unnecessary aura frames
	for i = buff_count + 1, #controls do
		controls[i] = controls[i]:Delete()
	end
end

-- TODO Configurable formatting
local function format_time(seconds)
	if seconds >= 3600 then
		return HOUR_ONELETTER_ABBR:format(ceil(seconds/3600))
	elseif seconds >= 180 then
		return MINUTE_ONELETTER_ABBR:format(ceil(seconds/60))
	elseif seconds > 60 then
		seconds = ceil(seconds)
		return ("%d:%d"):format(seconds/60, seconds%60)
	else
		return ("%d"):format(ceil(seconds))
	end
end

local function update_cooldown_text(aura)
	local cooldown_text = aura.cooldown_text
	if not cooldown_text:IsShown() then return end
	local expiration_time = aura.expiration_time
	if not expiration_time then return end

	local current_time = GetTime()
	local time_left = expiration_time - current_time
	if time_left >= 1 then
		cooldown_text:SetText(format_time(time_left))
	else
		cooldown_text:SetText("")
	end
end

local function clear_auras(frame, is_buff)
	local controls
	if is_buff then
		controls = frame.aura_buffs
	else
		controls = frame.aura_debuffs
	end

	if not controls then
		return
	end

	for i = 1, #controls do
		controls[i] = controls[i]:Delete()
	end
end

function PitBull4_Aura:ClearAuras(frame)
	clear_auras(frame, true) -- Buffs
	clear_auras(frame, false) -- Debuffs
end

function PitBull4_Aura:UpdateAuras(frame)
	local db = self:GetLayoutDB(frame)
	local highlight = db.highlight

	-- Start the Highlight Filter System
	if highlight then	
		self:HighlightFilterStart()
	end

	-- Buffs
	if db.enabled_buffs then
		update_auras(frame, db, true)
	else
		clear_auras(frame, true)
		if highlight then
			-- Iterate the auras for highlighting, normally
			-- this is done as part of the aura update process
			-- but we have to do it separately when it is disabled.
			self:HighlightFilterIterator(frame, db, true)
		end
	end

	-- Debuffs
	if db.enabled_debuffs then
		update_auras(frame, db, false)
	else
		clear_auras(frame, false)
		if highlight then
			-- Iterate the auras for highlighting, normally
			-- this is done as part of the aura update process
			-- but we have to do it separately when it is disabled.
			self:HighlightFilterIterator(frame, db, false)
		end
	end

	-- Finish the Highlight Filter System
	if highlight then
		self:SetHighlight(frame, db)
	end
end

function PitBull4_Aura:UpdateCooldownTexts()
	for frame in PitBull4:IterateFrames() do
		local aura_buffs = frame.aura_buffs
		if aura_buffs then
			for i = 1, #aura_buffs do
				update_cooldown_text(aura_buffs[i])
			end
		end

		local aura_debuffs = frame.aura_debuffs
		if aura_debuffs then
			for i = 1, #aura_debuffs do
				update_cooldown_text(aura_debuffs[i])
			end
		end
	end
end

-- Looks for changes to weapon enchants that we do not have cached
-- and if there is one updates all the frames set to display them.
-- If force is set then it clears the cache first.  Useful for
-- config changes that may invalidate our cache.
--
-- General operation of the Weapon Enchant aura system:
-- * Load changed weapon enchants into weapon_list which
--   is an table of aura entries identical in layout to list
-- * The aura entries are indexed by the slot id of the weapon.
-- * When a frames auras are updated (either normally or triggered
--   by a weapon enchant change) the weapon enchants are copied
--   into the list of auras built from UnitAura().
--
-- This design means that the tooltip scanning, duration calculations,
-- and spell icon guessing operations only happen once when the
-- weapon enchant is first seen.  Other arua changes for the player
-- simply cause the weapon enchant data to be copied again without
-- recalculation.
function PitBull4_Aura:UpdateWeaponEnchants(force)
	local updated = false
	if force then
		wipe(weapon_list)
	end
	local mh, mh_time_left, mh_count, oh, oh_time_left, oh_count = GetWeaponEnchantInfo()
	local current_time = GetTime()
	local mh_entry = weapon_list[MAINHAND]
	local oh_entry = weapon_list[OFFHAND]

	-- Grab the values from the weapon_list entries to use
	-- to compare against the current values to look for changes.
	local old_mh, old_mh_count, old_mh_expiration_time
	if mh_entry then
		old_mh = mh_entry[2] ~= nil and 1 or nil
		old_mh_count = mh_entry[8]
		old_mh_expiration_time = mh_entry[11]
	end

	local old_oh, old_oh_count, old_oh_expiration_time
	if oh_entry then
		old_oh = oh_entry[2] ~= nil and 1 or nil
		old_mh_count = oh_entry[8]
		old_mh_expiration_time = oh_entry[11]
	end

	-- GetWeaponEnchantInfo() briefly returns that there is
	-- an enchant but with the time_left set to zero.
	-- When this happens force it to appear to us as though
	-- the enchant isn't there.
	if mh_time_left == 0 then
		mh, mh_time_left, mh_count = nil, nil, nil
	end
	if oh_time_left == 0 then
		oh, oh_time_left, oh_count = nil, nil, nil
	end

	-- Calculate the expiration time from the time left.  We use
	-- expiration time since the normal Aura system uses it instead
	-- of time_left.
	local mh_expiration_time = mh_time_left and mh_time_left / 1000 + current_time
	local oh_expiration_time = oh_time_left and oh_time_left / 1000 + current_time

	-- Test to see if the enchant has changed and if so set the entry for it
	-- We check that the expiration time is at least 0.2 seconds further
	-- ahead than it was to avoid rebuilding auras for rounding errors.
	if mh ~= old_mh or mh_count ~= old_mh_count or (mh_expiration_time and old_mh_expiration_time and mh_expiration_time - old_mh_expiration_time > 0.2) then
		set_weapon_entry(weapon_list, mh, mh_time_left, mh_expiration_time, mh_count, MAINHAND)
		updated = true
	end
	if oh ~= old_oh or oh_count ~= old_oh_count or (oh_expiration_time and old_oh_expiration_time and oh_expiration_time - old_oh_expiration_time > 0.2) then
		set_weapon_entry(weapon_list, oh, oh_time_left, oh_expiration_time, oh_count, OFFHAND)
		updated = true
	end

	-- An enchant changed so find all the relevent frames and update
	-- their auras.
	if updated then
		for frame in PitBull4:IterateFrames() do
			local unit = frame.unit
			if unit and UnitIsUnit(unit, "player") then
				local db = self:GetLayoutDB(frame)
				if db.enabled and db.enabled_weapons then
					self:UpdateAuras(frame)
					self:LayoutAuras(frame)
				end
			end
		end
	end
end

-- table of frames to be updated on next filter update
local timed_filter_update = {}

--- Request that a frame is updated on the next timed update
-- The frame will only be updated once.  This is useful for
-- filters to request they be rerun on a frame for data that
-- changes with time.
-- @param frame the frame to update
-- @usage PitBull4_aura:RequestTimeFilterUpdate(my_frame)
-- @return nil
function PitBull4_Aura:RequestTimedFilterUpdate(frame)
	timed_filter_update[frame] = true
end

function PitBull4_Aura:UpdateFilters()
	for frame in pairs(timed_filter_update) do
		timed_filter_update[frame] = nil
		self:UpdateAuras(frame)
		self:LayoutAuras(frame)
	end
end

local guids_to_update = {}

function PitBull4_Aura:UNIT_AURA(event, unit)
	-- UNIT_AURA updates are throttled by collecting them in
	-- guids_to_update and then updating the relevent frames
	-- once every 0.2 seconds.  We capture the GUID at the event
	-- time because the unit ids can change between when we receive
	-- the event and do the throttled update
	guids_to_update[UnitGUID(unit)] = true
end

-- Function to execute the throttled updates
function PitBull4_Aura:OnUpdate()
	if next(guids_to_update) then
		for frame in PitBull4:IterateFrames() do
			if guids_to_update[frame.guid] then
				if self:GetLayoutDB(frame).enabled then
					self:UpdateFrame(frame)
				else
					self:ClearFrame(frame)
				end
			end
		end
		wipe(guids_to_update)
	end

	self:UpdateCooldownTexts()

	self:UpdateWeaponEnchants()

	self:UpdateFilters()
end
