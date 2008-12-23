if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_CastBar requires PitBull4")
end

local PitBull4_CastBar = PitBull4.NewModule("CastBar", "Cast Bar", "Show a cast bar", {}, {
	size = 1,
	position = 10,
}, "statusbar")

local castData = {}
PitBull4_CastBar.castData = castData

local new, del
do
	local pool = setmetatable({}, {__mode='k'})
	function new()
		local t = next(pool)
		if t then
			pool[t] = nil
			return t
		end
		
		return {}
	end
	function del(t)
		wipe(t)
		pool[t] = true
	end
end

function PitBull4_CastBar.GetValue(frame)
	local guid = frame.guid
	local data = castData[guid]
	if not data then
		return 0
	end
	
	if data.casting then
		local startTime = data.startTime
		return (GetTime() - startTime) / (data.endTime - startTime)
	elseif data.channeling then	
		local endTime = data.endTime
		return (endTime - GetTime()) / (endTime - data.startTime)
	elseif data.fadeOut then
		return frame.CastBar:GetValue()
	end
	return 0
end

function PitBull4_CastBar.GetColor(frame)
	local guid = frame.guid
	local data = castData[guid]
	if not data then
		return 0, 0, 0, 0
	end
	
	if data.casting then
		return 0, 1, 0, 1
	elseif data.channeling then
		return 0, 1, 0, 1
	elseif data.fadeOut then
		local alpha
		local stopTime = data.stopTime
		if stopTime then
			alpha = stopTime - GetTime() + 1
		else
			alpha = 0
		end
		if alpha >= 1 then
			alpha = 1
		end
		if alpha <= 0 then
			castData[guid] = del(data)
			return 0, 0, 0, 0
		else
			return 0, 1, 0, alpha
		end
	else
		castData[guid] = del(data)
	end
	return 0, 0, 0, 0
end

PitBull4_CastBar:SetValueFunction('GetValue')
PitBull4_CastBar:SetColorFunction('GetColor')

local function updateInfo(_, unit)
	local guid = UnitGUID(unit)
	if not guid then
		return
	end
	local data = castData[guid]
	if not data then
		data = new()
		castData[guid] = data
	end
	
	local spell, rank, displayName, icon, startTime, endTime = UnitCastingInfo(unit)
	local channeling = false
	if not spell then
		spell, rank, displayName, icon, startTime, endTime = UnitChannelInfo(unit)
		channeling = true
	end
	if spell then
		data.icon = icon
		data.startTime = startTime * 0.001
		data.endTime = endTime * 0.001
		data.casting = not channeling
		data.channeling = channeling
		data.fadeOut = false
		data.stopTime = nil
		return
	end
	
	if not data.icon then
		castData[guid] = del(data)
		return
	end
	
	data.casting = false
	data.channeling = false
	data.fadeOut = true
	if not data.stopTime then
		data.stopTime = GetTime()
	end
end

local playerGUID = UnitGUID("player")
function PitBull4_CastBar.FixCastData()
	local frame
	local currentTime = GetTime()
	for guid, data in pairs(castData) do
		local found = false
		for frame in PitBull4.IterateFramesForGUID(guid) do
			local castBar = frame.CastBar
			if castBar then
				found = true
				if data.casting then
					if currentTime > data.endTime and playerGUID ~= guid then
						data.casting = false
						data.fadeOut = true
						data.stopTime = currentTime
					end
				elseif data.channeling then
					if currentTime > data.endTime then
						data.channeling = false
						data.fadeOut = true
						data.stopTime = currentTime
					end
				elseif data.fadeOut then
					local alpha = 0
					local stopTime = data.stopTime
					if stopTime then
						alpha = stopTime - currentTime + 1
					end
					
					if alpha <= 0 then
						castData[guid] = del(data)
					end
				else
					castData[guid] = del(data)
				end
			end	
			break
		end
		if not found then
			castData[guid] = del(data)
		end
	end
end

function PitBull4_CastBar.OnUpdate(frame)
	if not frame.CastBar then
		return
	end
	
	local unit = frame.unitID
	if not frame.is_wacky and unit ~= "target" and unit ~= "focus" then
		return
	end
	
	updateInfo(nil, unit)
end

PitBull4.Utils.AddTimer(function()
	PitBull4_CastBar.FixCastData()
	PitBull4_CastBar:UpdateAll()
end)
PitBull4_CastBar:AddFrameScriptHook("OnUpdate", PitBull4_CastBar.OnUpdate)
PitBull4.Utils.AddEventListener("UNIT_SPELLCAST_START", updateInfo)
PitBull4.Utils.AddEventListener("UNIT_SPELLCAST_CHANNEL_START", updateInfo)
PitBull4.Utils.AddEventListener("UNIT_SPELLCAST_STOP", updateInfo)
PitBull4.Utils.AddEventListener("UNIT_SPELLCAST_FAILED", updateInfo)
PitBull4.Utils.AddEventListener("UNIT_SPELLCAST_INTERRUPTED", updateInfo)
PitBull4.Utils.AddEventListener("UNIT_SPELLCAST_DELAYED", updateInfo)
PitBull4.Utils.AddEventListener("UNIT_SPELLCAST_CHANNEL_UPDATE", updateInfo)
PitBull4.Utils.AddEventListener("UNIT_SPELLCAST_CHANNEL_STOP", updateInfo)