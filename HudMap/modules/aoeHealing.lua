-- Name your module whatever you want.
local modName = "AOE Healing"

local parent = HudMap
local L = LibStub("AceLocale-3.0"):GetLocale("HudMap")
local mod = HudMap:NewModule(modName, "AceEvent-3.0")
local db
local SN = parent.SN

local free = parent.free

-- This is an Ace3 options table.
-- http://www.wowace.com/addons/ace3/pages/ace-config-3-0-options-tables/
-- db is a handle to your module's current profile settings, so you can use it directly.
local options = {
	type = "group",
	name = L["AOE Healing"],
	args = {
		spells = {
			type = "group",
			name = L["Spells"],
			get = function(info)
				local t = db.spells[info[#info-1]][info[#info]]
				if type(t) == "table" then
					return unpack(t)
				else
					return t
				end
			end,
			set = function(info, ...)
				if select("#", ...) > 1 then
					for i = 1, select("#", ...) do
						db.spells[info[#info-1]][info[#info]][i] = select(i, ...)
					end
				else
					db.spells[info[#info-1]][info[#info]] = ...
				end
			end,
			args = {}			
		}
	}
}

-- Define your module's defaults here. Your options will toggle them.
local defaults = {
	profile = {
		spells = {
			-- Beacon of Light
			[SN[53563]:gsub(" ", "")] = {
				color = {1, 1, 0, 0.15},
				color_far = {1, 0, 0, 0.33},
				enable = true,
				size = 25
			},
			
			-- Chain Heal
			[SN[1064]:gsub(" ", "")] = {
				color = {0.5, 1, 0, 0.7},
				enable = true,
				size = 25
			},
			
			-- ProM
			[SN[33076]:gsub(" ", "")] = {
				color = {0.7, 1, 0, 0.7},
				enable = true,
				size = 25
			},
			
			-- Wild Growth
			[SN[48438]:gsub(" ", "")] = {
				color = {1, 0.88, 0.36, 0.7},
				enable = true,
				texture = "cyanstar",
				size = 25
			},

			-- CoH
			[SN[34861]:gsub(" ", "")] = {
				color = {1, 0.88, 0.36, 0.7},
				enable = true,
				texture = "cyanstar",
				size = 25
			},
			
			-- PoH
			[SN[596]:gsub(" ", "")] = {
				color = {1, 0.88, 0.36, 0.7},
				enable = true,
				texture = "cyanstar",
				size = 25
			},			
		}
	}
}


local bounceSpells = {
	[SN[1064]] = true,		-- Chain Heal
	[SN[33076]] = true		-- Prayer of Mending
}
local aoeSpells = {
	[SN[48438]] = true,		-- Wild Growth
	[SN[34861]] = true,		-- Circle of Healing
	[SN[596]]   = true		-- Prayer of Healing
}
local rangeSpells = { -- {range, duration}
	[SN[53563]] = {60, 90},		-- Beacon of Light
}

local storage_marker = {}
local BeaconOfLight_marker = nil

local textures = {
	cyanstar = L["Spark"],
	radius = L["Dots"],
	radius_lg = L["Large Dots"],
	ring = L["Solid"],
	fuzzyring = L["Ring 2"],
	fatring = L["Ring 3"],
	glow = L["Glow"]	
}
-- One-time setup code is done here.
function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	parent:RegisterModuleOptions(modName, options, modName)
	db = self.db.profile
	
	for k, v in pairs(rangeSpells) do
		local opt = {
			type = "group",
			name = k,
			args = {
				enable = {
					type = "toggle",
					name = L["Enable"]
				},
				-- texture = {
					-- type = "toggle",
					-- name = L["Texture"],
					-- type = "select",
					-- values = textures
				-- },
				color = {
					type = "color",
					name = L["Color"].." near",
					hasAlpha = true
				},
				color_far = {
					type = "color",
					name = L["Color"].." far",
					hasAlpha = true
				},
				-- size = {
					-- name = L["Size"],
					-- type = "range",
					-- min = 5,
					-- max = 50,
					-- step = 1,
					-- bigStep = 1
				-- }
			}
		}
		options.args.spells.args[k:gsub(" ", "")] = opt
	end
	
	for k, v in pairs(bounceSpells) do
		local opt = {
			type = "group",
			name = k,
			args = {
				enable = {
					type = "toggle",
					name = L["Enable"]
				},
				-- texture = {
					-- type = "toggle",
					-- name = L["Texture"],
					-- type = "select",
					-- values = textures
				-- },
				color = {
					type = "color",
					name = L["Color"],
					hasAlpha = true
				},
				-- size = {
					-- name = L["Size"],
					-- type = "range",
					-- min = 5,
					-- max = 50,
					-- step = 1,
					-- bigStep = 1
				-- }
			}
		}
		options.args.spells.args[k:gsub(" ", "")] = opt
	end
	
	for k, v in pairs(aoeSpells) do
		local opt = {
			type = "group",
			name = k,
			args = {
				enable = {
					type = "toggle",
					name = L["Enable"]
				},
				texture = {
					type = "toggle",
					name = L["Texture"],
					type = "select",
					values = textures
				},
				color = {
					type = "color",
					name = L["Color"],
					hasAlpha = true
				},
				size = {
					name = L["Size"],
					type = "range",
					min = 5,
					max = 50,
					step = 1,
					bigStep = 1
				}
			}
		}
		options.args.spells.args[k:gsub(" ", "")] = opt
	end
end

function mod:OnEnable()
	db = self.db.profile
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

local lastPlayer, lastPlayerTime = {}, {}
local playerGUID = UnitGUID("player")
local defaultColor, emptyTable = {0, 1, 0, 0.6}, {}
function mod:COMBAT_LOG_EVENT_UNFILTERED(ev, timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, ...)
	if event == "SPELL_CAST_START" or event == "SPELL_CAST_SUCCESS" then
		lastPlayer[spellName] = nil
	elseif event == "SPELL_AURA_REMOVED" then
		if sourceGUID and sourceGUID == playerGUID and spellName and rangeSpells[spellName] then
			free(BeaconOfLight_marker, self, "BeaconOfLight_marker")
		end
		return
	end
	
	local isPlayer = bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER
	if sourceGUID == playerGUID and destName and isPlayer then
		if bounceSpells[spellName] then
			local source = lastPlayer[spellName] or "player"
			lastPlayer[spellName] = destName
			
			local settings = db.spells[spellName:gsub(" ", "")] or emptyTable
			local r, g, b, a = unpack(settings.color or defaultColor)
			parent:AddEdge(r, g, b, a, 0.6, source, destName)
			
		elseif aoeSpells[spellName] then
			local settings = db.spells[spellName:gsub(" ", "")] or emptyTable
			local texture = settings.texture or "ring"
			local size = (settings.size or 25) .. "px"
			local r, g, b, a = unpack(settings.color or defaultColor)
			parent:PlaceRangeMarkerOnPartyMember(texture, destName, size, 0.9, r, g, b, a, "ADD"):Pulse(1.8, 0.9):Rotate(360, 2):Appear()
			
		elseif (event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH") and rangeSpells[spellName] then
			if (destGUID == playerGUID) then
				free(BeaconOfLight_marker, self, "BeaconOfLight_marker")
				return
			end
			
			local settings = db.spells[spellName:gsub(" ", "")] or emptyTable
			local r1, g1, b1, a1 = unpack(settings.color or defaultColor)
			local r2, g2, b2, a2 = unpack(settings.color_far or defaultColor)
			local distance = rangeSpells[spellName][1]
			local duration = rangeSpells[spellName][2]
			local rangeMod = {
				["dist"] = distance,
				["r"] = r2,
				["g"] = g2,
				["b"] = b2,
				["a"] = a2,
			}
			BeaconOfLight_marker = parent:AddEdge(r1, g1, b1, a1, duration, "player", destName, nil, nil, nil, nil, rangeMod):Identify(self, "BeaconOfLight_marker")
		end
	end
end


---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
if true then return end


do	
	function mod:PLAYER_TARGET_CHANGED()
		local n = UnitName("target")
		if currentTarget then currentTarget:SetLabel("") end
		free(highlight, self, "highlight")
		free(targetArrow, self, "targetArrow")
		if partyMembers[n] then
			currentTarget = partyMembers[n]
			if db.targetLabel then
				currentTarget:SetLabel(n, "BOTTOM", "TOP", nil, nil, nil, nil, 0, 5)
			end
		
			if db.highlightTarget then
				highlight = parent:PlaceRangeMarkerOnPartyMember([[Interface\BUTTONS\IconBorder-GlowRing.blp]], n, (db.iconSize + 5).. "px", nil, 1, 0.8, 0, 1, "ADD"):Pulse(1.3, 0.4):Appear():Identify(self, "highlight")
			end
			
			if db.arrowToTarget then
				local r, g, b, a = unpack(db.targetArrowColor)
				targetArrow = partyMembers[n]:EdgeTo("player", nil, nil, r, g, b, a):Identify(self, "targetArrow")
			end
		end
	end
end