local modName = "Totem Ranges"
local parent = HudMap
local L = LibStub("AceLocale-3.0"):GetLocale("HudMap")
local mod = HudMap:NewModule(modName, "AceEvent-3.0")

local modNameLocalized = "Totem Ranges" -- no localization!!

--[[ Default upvals 
     This has a slight performance benefit, but upvalling these also makes it easier to spot leaked globals. ]]--
local _G = _G.getfenv(0)
local wipe, type, pairs, tinsert, tremove, tonumber = _G.wipe, _G.type, _G.pairs, _G.tinsert, _G.tremove, _G.tonumber
local math, math_abs, math_pow, math_sqrt, math_sin, math_cos, math_atan2 = _G.math, _G.math.abs, _G.math.pow, _G.math.sqrt, _G.math.sin, _G.math.cos, _G.math.atan2
local error, rawset, rawget, print = _G.error, _G.rawset, _G.rawget, _G.print
local tonumber, tostring = _G.tonumber, _G.tostring
local getmetatable, setmetatable, pairs, ipairs, select, unpack = _G.getmetatable, _G.setmetatable, _G.pairs, _G.ipairs, _G.select, _G.unpack
--[[ -------------- ]]--

local FIRENOVA = "fireNova::"
local db
local free = parent.free
local TotemicRecall = { id = 36936, name = GetSpellInfo(36936) }
local isShaman = select(2, UnitClass("player")) == "SHAMAN"

local textureOptions = {
	radius = L["Dots"],
	radius_lg = L["Large Dots"],
	ring = L["Solid"],
	fuzzyring = L["Ring 2"],
	fatring = L["Ring 3"],
}

local totemRangesTimes = {
	-- Fire
	{
		[3599] =	{ 30,	50 },	-- Searing
		[8181] =	{ 30, 	300 },	-- Frost Resist
		[8190] =	{ 8, 	20 },	-- Magma
		[8227] =	{ 30, 	300 },	-- Flametongue
		[30706] =	{ 40, 	300 },	-- Totem of Wrath
	},

	-- Earth
	{ 								
		[2484] =	{ 10, 	45 },	-- Earthbind
		[5730] =	{ 8, 	15 },	-- Stoneclaw
		[8071] =	{ 30, 	300 },	-- Stoneskin
		[8075] =	{ 30, 	300 },	-- Strength of Earth
		[8143] =	{ 30, 	300 },	-- Tremor
	},

	-- Water
	{
		[5675] =	{ 30, 	300 },	-- Mana Spring
		[8170] =	{ 30, 	300 },	-- Cleansing
		[8184] =	{ 30, 	300 },	-- Fire Resist
		[16190] =	{ 30, 	12 },	-- Mana Tide
		[5394] =	{ 30, 	300 },	-- Healing Stream
	},

	-- Wind
	{ 								
		[3738] =	{ 30, 	300 },	-- Wrath of Air
		[8177] =	{ 20, 	45 },	-- Grounding
		[8512] =	{ 30, 	300 },	-- Windfury
		[10595] =	{ 30, 	300 },	-- Nature Resist
	},
}

local options = {
	type = "group",
	name = L["Totems"],
	args = {
		myTotems = {
			type = "group",
			name = L["My Totems"],
			disabled = function() return not isShaman end,
			args = {
				enable = {
					type = "toggle",
					name = L["Enable My Totems"],
					order = 100,
					get = function()
						return db.myTotems.enable
					end,
					set = function(info, v)
						db.myTotems.enable = v
						mod:UpdateTotems()
					end
				}
			}
		},
		partyTotems = {
			type = "group",
			name = L["Party Totems"],
			args = {
				enable = {
					type = "toggle",
					name = L["Enable Party Totems"],
					order = 101,
					get = function()
						return db.partyTotems.enable
					end,
					set = function(info, v)
						db.partyTotems.enable = v
						mod:UpdateTotems()
					end
				}
			}
		},
		fireNova = {
			type = "group",
			order = 200,
			name = L["Fire Nova"],
			disabled = function() return not db.myTotems.enable end,
			args = {
				enable = {
					type = "toggle",
					name = L["Show Fire Nova Range"],
					get = function()
						return db.fireNova.enable
					end,
					set = function(info, v)
						db.fireNova.enable = v
						mod:UpdateTotems()
					end,
					order = 100
				},
				color = {
					disabled = function() return not db.fireNova.enable end,
					name = L["Color"],
					type = "color",
					hasAlpha = true,
					get = function()
						return unpack(db.fireNova.slotColor)
					end,
					set = function(info, r, g, b, a)
						db.fireNova.slotColor[1] = r
						db.fireNova.slotColor[2] = g
						db.fireNova.slotColor[3] = b
						db.fireNova.slotColor[4] = a
						mod:UpdateTotems()
					end,
					order = 200
				},
				texture = {
					type = "select",
					name = L["Ring Style"],
					values = textureOptions,
					get = function()
						return db.fireNova.texture
					end,
					set = function(info, v)
						db.fireNova.texture = v
						mod:UpdateTotems()
					end,
					order = 201
				}
			}
		}
	}
}
local totemNames = {}
local totemGUIDs = {}
local totemShamans = {}
local totemCircles = {}
local groups = {
	L["Fire Totems"],
	L["Earth Totems"],
	L["Water Totems"],
	L["Air Totems"]
}

local colors = {
	{1, 36/255, 0, 0.7},
	{200/255, 121/255, 43/255, 0.7},
	{0, 138/255, 1, 0.7},
	{150/255, 1, 0, 0.7}	
}

local defaults = {
	profile = {
		myTotems = {
			enable = isShaman,
			texture = "radius"
		},
		partyTotems = {
			enable = true,
			texture = "radius"
		},
		fireNova = {
			enable = false,
			slotColor = {1, 0.7, 0, 0.7},
			texture = "ring"
		}
	}
}

local function getSlotForTotem(totem)
	for index, set in ipairs(totemRangesTimes) do
		for id, _ in pairs(set) do
			if id == totem then
				return index
			end
		end
	end
end

for _, key in ipairs({"myTotems", "partyTotems"}) do
	for index, name in ipairs(groups) do
		local skey = "slotColor" .. index
		local opts = {
			name = L["%s Color"]:format(name),
			type = "color",
			hasAlpha = true,
			get = function()
				return unpack(db[key][skey])
			end,
			set = function(info, r, g, b, a)
				db[key][skey][1] = r
				db[key][skey][2] = g
				db[key][skey][3] = b
				db[key][skey][4] = a
				mod:UpdateTotems()
			end,
			order = 200 + index
		}
		defaults.profile[key][skey] = colors[index]
		options.args[key].args[skey] = opts
		options.args[key].args.texture = {
			type = "select",
			name = L["Ring Style"],
			values = textureOptions,
			get = function()
				return db[key].texture
			end,
			set = function(info, v)
				db[key].texture = v
				mod:UpdateTotems()
			end,
			order = 150
		}
	end
	
	for index, v in ipairs(totemRangesTimes) do
		local optGroup = {
			name = groups[index],
			type = 'group',
			args = {},
			disabled = function()
				return not db[key].enable
			end
		}
		for id, _ in pairs(v) do
			local n, _, icon = GetSpellInfo(id)
      if not n then
        print(id, "failed lookup")
      end
			local sid = key .. n
			defaults.profile[key][n] = key == "myTotems" or (id == 30706 or id == 16190 or id == 3738 or id == 8170 or id == 8227 or id == 8143)
			-- ChatFrame3:AddMessage("--"..tostring(key) )
			optGroup.args[n:gsub(" ", "")] = {
				name = n,
				type = "toggle",
				get = function()
					return db[key][n]
				end,
				set = function(info, v)
					db[key][n] = v
					mod:UpdateTotems()
				end
			}
		end
		options.args[key].args[groups[index]:gsub(" ", "")] = optGroup
	end
end

local effectiveTotemRanges = {}

local talents = {
	earths_grasp = {totem_ids = {[2484] = 1}, range_per_point = 10, tab_index = 2, talent_index = 2}
}
local offsets = {
	{-1, 1},
	{1, 1},
	{1, -1},
	{-1, -1},
}

function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile
	parent:RegisterModuleOptions(modName, options, modNameLocalized)
end

function mod:OnEnable()
	db = self.db.profile
	if not isShaman then db.myTotems.enable = false end
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_TOTEM_UPDATE")
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateTotemInformation")
	self:UpdateTotemInformation()
end

function mod:OnDisable()
	for k, v in pairs(totemCircles) do
		totemCircles[k] = free(v, self, k)
	end
end

local function findRangeSlotTimer(targetID)
	local range, slot, timer
	for s, totems in ipairs(totemRangesTimes) do
		for id, rangesTimesTbl in pairs(totems) do
			if targetID == id then
				slot = s
				range = rangesTimesTbl[1]
				timer = rangesTimesTbl[2]
				break
			end
		end
		if range then break end
	end
	return range, slot, timer
end


local function freeTotemsByShamanGUID(shamanGUID)
	local key
	for i = 1, 4, 1 do
		key = ("%s:%s"):format(shamanGUID, i) -- go thorugh all four slots of the caster
		for k, v in pairs(totemGUIDs) do
			if v == key then
				free(totemCircles[key], self, key)
				totemGUIDs[k] = nil
				-- ChatFrame3:AddMessage("-- freed "..key)
			end
		end
	end
	totemShamans[shamanGUID] = nil -- delete this shaman from totem list
	-- ChatFrame3:AddMessage("-- totems freed from: "..shamanGUID ) -- DEBUG
end

function mod:COMBAT_LOG_EVENT_UNFILTERED(_, timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, ...)
	if event == "SPELL_CAST_SUCCESS" then	-- ##############################
		if spellID == TotemicRecall.id and (UnitInRaid(sourceName) or UnitInParty(sourceName)) then 
			-- ChatFrame3:AddMessage("-- "..event..": "..TotemicRecall.name.."\nsourceName "..tostring(sourceName)..", destName "..tostring(destName).."\nsourceGUID "..tostring(sourceGUID)..", destGUID "..tostring(destGUID) )
			freeTotemsByShamanGUID(sourceGUID)
		end
		
	elseif event == "SPELL_SUMMON" then	-- ##############################
		local totemName = GetSpellInfo(spellID)
		if totemNames[totemName] and (UnitInRaid(sourceName) or UnitInParty(sourceName)) then
			local targetID = totemNames[totemName]
			local range, slot, timer = findRangeSlotTimer(targetID)
			if not range or not slot then return end
			local x, y = HudMap:GetUnitPosition(sourceName)
			local r, g, b, a, tex, isPlayer
			if UnitIsUnit(sourceName, "player") then
				if not db.myTotems.enable then return end
				if not db.myTotems[totemName] then return end
				local offset = offsets[slot]
				local bearing = -GetPlayerFacing()
				local angle = math_atan2(offset[1], offset[2])
				local hyp = 2.9 -- math.sqrt(8)
				local nx, ny = math_sin(angle + bearing), math_cos(angle + bearing)
				x = x + (nx * hyp)
				y = y + (ny * hyp)
				range = effectiveTotemRanges[totemName]
				r, g, b, a = unpack(db.myTotems["slotColor" .. slot])
				tex = db.myTotems.texture
				isPlayer = true
			else
				local offset = offsets[slot]
				x = x + offset[1]/4
				y = y + offset[2]/4
				if not db.partyTotems.enable then return end
				if not db.partyTotems[totemName] then return end
				r, g, b, a = unpack(db.partyTotems["slotColor" .. slot])
				tex = db.partyTotems.texture
			end
			-- ChatFrame3:AddMessage("-- "..totemName..": "..r..", "..g..", "..b..", "..a )
			
			if  tex == "radius" and range < 20 then	-- fix small circle with dots
				tex = "radius_lg"
			end
			-- local tex = range > 25 and "radius" or "radius_lg"
			
			-- remove existing totem from list
			-- local key = ("%s:%s:%s"):format(sourceGUID, slot, totemName)
			local key = ("%s:%s"):format(sourceGUID, slot) -- there can only be one totem per slot!
			for k, v in pairs(totemGUIDs) do
				if v == key then
					totemGUIDs[k] = nil
				end
			end
			
			free(totemCircles[key], self, key)
			-- totemCircles[key] = HudMap:PlaceRangeMarker(tex, x, y, range, 300, r, g, b, a):Rotate(360 * (slot % 2 == 0 and 1 or -1), 175+(slot*3)):Appear():Identify(self, key)
			totemCircles[key] = HudMap:PlaceRangeMarker(tex, x, y, range, timer, r, g, b, a):Appear():RegisterForAlerts():Identify(self, key)
			totemCircles[key].RegisterCallback(self, "Free", "FreeCircle")
			if slot == 1 and isPlayer and db.fireNova.enable then
				key = FIRENOVA
				tex = db.fireNova.texture
				r, g, b, a = unpack(db.fireNova.slotColor)
				
				free(totemCircles[key], self, key)
				local talents = select(5, GetTalentInfo(1, 11))
				range = 10 + (talents * 3)
				-- totemCircles[key] = HudMap:PlaceRangeMarker(tex, x, y, range, 300, r, g, b, a):Rotate(360 * (slot % 2 == 0 and 1 or -1), 175+(slot*3)):Appear():Pulse(1.02, 0.5):Identify(self, key)
				totemCircles[key] = HudMap:PlaceRangeMarker(tex, x, y, range, timer, r, g, b, a):Appear():Pulse(1.02, 0.5):Identify(self, key)
				totemCircles[key].RegisterCallback(self, "Free", "FreeCircle")
			end
			-- ChatFrame3:AddMessage("-- "..destGUID.." = "..key ) -- DEBUG
			totemGUIDs[destGUID] = key
			
			if not totemShamans[sourceGUID] then totemShamans[sourceGUID] = {} end
			totemShamans[sourceGUID][slot] = destGUID
		end
	elseif event == "UNIT_DIED" then
		-- if the dead GUID is in the list of shamans, then free the totems
		if totemShamans[destGUID] then 
			freeTotemsByShamanGUID(destGUID)
		end
		
		if totemGUIDs[totemShamans] then
			-- ChatFrame3:AddMessage("-- a totem died: "..destName ) -- DEBUG
			local dot = totemCircles[totemGUIDs[destGUID]]
			local sourceGuid, slot, totemName = (":"):split(totemGUIDs[destGUID])
			slot = tonumber(slot)
			if dot then
				totemCircles[totemGUIDs[destGUID]] = dot:Free()
				totemGUIDs[destGUID] = nil
			end
			if slot == 1 and sourceGuid == UnitGUID("player") then
				free(dot, self, FIRENOVA)
			end
		end
	end
end

function mod:FreeCircle(cbk, c)
	-- do return end
	for k, v in pairs(totemCircles) do
		if v == c then
			totemCircles[k] = nil
			return
		end
	end
end

function mod:UpdateTotemInformation()
	wipe(effectiveTotemRanges)
	wipe(totemNames)
	for set, totems in ipairs(totemRangesTimes) do
		for id, rangesTimesTbl in pairs(totems) do 
			local range = rangesTimesTbl[1]
			local name, _, icon = GetSpellInfo(id)
			totemNames[name] = id
			-- ChatFrame3:AddMessage("-- "..name.." "--tostring(id) )
			for talent_name, talent_data in pairs(talents) do
				if talent_data.totem_ids[id] then
					local points = select(5, GetTalentInfo(talent_data.tab_index, talent_data.talent_index))
					range = range + (points * talent_data.range_per_point)
				end
			end
			effectiveTotemRanges[name] = range
		end
	end
end

function mod:PLAYER_TOTEM_UPDATE(event, slot)
	local haveTotem, totemName, startTime, duration, icon = GetTotemInfo(slot)
	if startTime == 0 then
		for key, v in pairs(totemCircles) do
			local guid, slotID, totemName = (":"):split(key)
			slotID = tonumber(slotID)
			if (guid == UnitGUID("player") and (slotID == slot)) or (slot == 1 and guid == "fireNova") then			
				totemCircles[key] = free(totemCircles[key], self, key)
			end
		end		
	end
end

function mod:UpdateTotems()
	for key, dot in pairs(totemCircles) do
		if not dot.freed and dot:Owned(self, key) then
			local guid, slotID, totemName = (":"):split(key)
			local dbkey = guid == UnitGUID("player") and "myTotems" or "partyTotems"
			if guid == "fireNova" then
				dbkey = "fireNova"
			end
			if not db[dbkey].enable or (dbkey ~= "fireNova" and not db[dbkey][totemName]) then
				totemCircles[key] = free(dot:Free(), self, key)
			else
				dot:SetTexture(db[dbkey].texture)
				dot:SetColor(unpack(db[dbkey]["slotColor" .. slotID]))
			end
		end		
	end
end