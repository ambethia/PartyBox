local ADDON, NS = ...
local FRAME = CreateFrame("Frame", ADDON .. "Frame")

local GRID_SIZE = 320

local X_LOCATIONS = {
	player = 0,
	-- party1 = -GRID_SIZE * 2,
	party1 = -200,
	party2 = -GRID_SIZE,
	party3 = GRID_SIZE,
	party4 = GRID_SIZE * 2
}

local LOOT_ITEM_PATTERN = LOOT_ITEM_SELF:gsub("%%s", "(.+)"):gsub("^", "^")
local LOOT_ITEM_MULTIPLE_PATTERN = LOOT_ITEM_SELF_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)"):gsub("^", "^")

local LOOT_ITEM_CREATED_PATTERN = LOOT_ITEM_CREATED_SELF:gsub("%%s", "(.+)"):gsub("^", "^")
local LOOT_ITEM_CREATED_MULTIPLE_PATTERN =
	LOOT_ITEM_CREATED_SELF_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)"):gsub("^", "^")

local LOOT_ITEM_PUSHED_PATTERN = LOOT_ITEM_PUSHED_SELF:gsub("%%s", "(.+)"):gsub("^", "^")
local LOOT_ITEM_PUSHED_MULTIPLE_PATTERN =
	LOOT_ITEM_PUSHED_SELF_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)"):gsub("^", "^")

FRAME.castingBars = {}
FRAME.lootLogs = {}
FRAME.partyMembers = {}

FRAME:SetScript(
	"OnEvent",
	function(self, event, ...)
		if self[event] then
			self[event](self, ...)
		end
	end
)

function FRAME:UpdateCastingBars()
	for unit, bar in pairs(self.castingBars) do
		name = UnitName(unit)
		if name then
			self.partyMembers[name] = unit
			bar.label:SetText(name)
		end
	end
end

function FRAME:GROUP_ROSTER_UPDATE()
	self:UpdateCastingBars()
end

function FRAME:CHAT_MSG_LOOT(message, playerName)
	local link, quantity = message:match(LOOT_ITEM_MULTIPLE_PATTERN)
	if not link then
		link, quantity = message:match(LOOT_ITEM_PUSHED_MULTIPLE_PATTERN)
		if not link then
			link, quantity = message:match(LOOT_ITEM_CREATED_MULTIPLE_PATTERN)
			if not link then
				quantity, link = 1, message:match(LOOT_ITEM_PATTERN)
				if not link then
					quantity, link = 1, message:match(LOOT_ITEM_PUSHED_PATTERN)
					if not link then
						quantity, link = 1, message:match(LOOT_ITEM_CREATED_PATTERN)
					end
				end
			end
		end
	end

	if not link then
		return
	end

	-- self:LogLoot("player", link, quantity)
	C_ChatInfo.SendAddonMessage(ADDON, link .. ";" .. quantity, "PARTY")
end

function FRAME:CHAT_MSG_ADDON(prefix, message, _, sender)
	print(prefix, ADDON)
	if prefix ~= ADDON then
		return
	end

	local link, quantity = message:match("(.*);(%d+)")
	print(link, quantity)
	local unit = self.partyMembers[sender:gsub("%-[^|]+", "")]
	print(unit)
	if unit then
		self:LogLoot(unit, link, quantity)
	end
end

function FRAME:LogLoot(unit, link, quantity)
	local log = self.lootLogs[unit]
	if tonumber(quantity) > 1 then
		log:AddMessage(link .. " x" .. quantity)
	else
		log:AddMessage(link)
	end
end

function FRAME:PLAYER_ENTERING_WORLD()
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("CHAT_MSG_LOOT")
	self:RegisterEvent("CHAT_MSG_ADDON")

	for unit in pairs(X_LOCATIONS) do
		local bar = CreateFrame("STATUSBAR", ADDON .. "_CastBar_" .. unit, UIParent, "SmallCastingBarFrameTemplate")
		bar:SetPoint("CENTER", X_LOCATIONS[unit], -(GRID_SIZE / 2 + 20))
		bar.label = bar:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		bar.label:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", 4, 2)
		CastingBarFrame_SetUnit(bar, unit, true, true)
		self.castingBars[unit] = bar

		local log = CreateFrame("MESSAGEFRAME", ADDON .. "_MessageFrame_" .. unit, UIParent)
		log:SetSize(200, 44)
		log:SetPoint("TOP", bar, "BOTTOM", 0, -10)
		log:SetInsertMode("TOP")
		log:SetFrameStrata("HIGH")
		log:SetTimeVisible(8)
		log:SetFadeDuration(4)
		log:SetFontObject(GameFontWhiteSmall)
		self.lootLogs[unit] = log
	end
	self:UpdateCastingBars()
end

function FRAME:ADDON_LOADED()
	CastingBarFrame:UnregisterAllEvents()
	C_ChatInfo.RegisterAddonMessagePrefix(ADDON)
end

FRAME:RegisterEvent("PLAYER_ENTERING_WORLD")
FRAME:RegisterEvent("VARIABLES_LOADED")
FRAME:RegisterEvent("ADDON_LOADED")
