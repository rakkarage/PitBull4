local _G = _G
local PitBull4 = _G.PitBull4

local CustomTextModule = PitBull4:NewModuleType("custom_text", {
	size = 1,
	attach_to = "root",
	location = "edge_top_left",
	position = 1,
	side = false,
	enabled = true,
})

--- Does nothing. This should be implemented by the module.
-- When implementing, this should return whether :UpdateLayout(frame) should be called.
-- @param frame the Unit Frame to update
-- @usage local update_layout = MyModule:UpdateFrame(frame)
-- @return false
function CustomTextModule:UpdateFrame(frame)
	return false
end

--- Does nothing. This should be implemented by the module.
-- When implementing, this should return whether :UpdateLayout(frame) should be called.
-- @param frame the Unit Frame to update
-- @usage local update_layout = MyModule:ClearFrame(frame)
function CustomTextModule:ClearFrame(frame)
	return false
end

local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
if not LibSharedMedia then
	LoadAddOn("LibSharedMedia-3.0")
	LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
end

local DEFAULT_FONT, DEFAULT_FONT_SIZE = ChatFontNormal:GetFont()

--- Return the font and size to use for the given frame.
-- @param frame the unit frame
-- @return the font path
-- @return the font size
-- @usage local font, size = MyModule:GetFont(some_frame)
-- some_frame.MyModule:SetFont(font, size)
function CustomTextModule:GetFont(frame)
	local db = self:GetLayoutDB(frame)
	local font
	if LibSharedMedia then
		font = LibSharedMedia:Fetch("font", db.font or frame.layout_db.font or "")
	end
	return font or DEFAULT_FONT, DEFAULT_FONT_SIZE * db.size
end
