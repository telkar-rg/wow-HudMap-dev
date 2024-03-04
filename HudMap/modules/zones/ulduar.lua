local encounters = HudMap:GetModule("Encounters")
local HudMap = _G.HudMap
local UnitName, UnitIsDead = _G.UnitName, _G.UnitIsDead
local parent = HudMap
local L = LibStub("AceLocale-3.0"):GetLocale("HudMap")
local SN = parent.SN
local SN_Link = parent.SN_Link

local function register(e)
	encounters:RegisterEncounterMarker(e)
	return e
end

local free = parent.free

-- TODO: Mark void zone radii/durations
local xt = {
	name = L["XT-002 Deconstructor"],
	options = {
		-- searingLight = SN[65598],
		-- gravityBomb = SN[63024],
		-- searingLight = SN_Link[65598],
		-- gravityBomb = SN_Link[63024],
		searingLight = "$spell:65598",
		gravityBomb = "$spell:63024",
	},
	startEncounterIDs = 33293,
	endEncounterIDs = 33293,
	defaults = {
		searingLightColor = {r = 1, g = 0.8, b = 0.13, a = 0.6},
		gravityBombColor = {r = 0.1, g = 0.4, b = 1, a = 0.6}
	},
	hardmode = false,
	Start = function(self)
		self.hardmode = false
	end,
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		-- Light bomb
		if spellID == 65737 then
			self.hardmode = true
		elseif (spellID == 63018 or spellID == 65121) and self:Option("searingLightEnabled") then
			local r, g, b, a = self:Option("searingLightColor")
			register(HudMap:PlaceRangeMarkerOnPartyMember("timer", destName, 10, 9, r, g, b, a):Appear():Rotate(360, 9):SetLabel(destName):RegisterForAlerts())
		elseif (spellID == 63024 or spellID == 64234) and self:Option("gravityBombEnabled") then
			local r, g, b, a = self:Option("gravityBombColor")
			register(HudMap:PlaceRangeMarkerOnPartyMember("timer", destName, 12, 9, r, g, b, a):Appear():Rotate(360, 9):SetLabel(destName):RegisterForAlerts())
		end
	end,
	SPELL_AURA_REMOVED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if (spellID == 63024 or spellID == 64234) and self:Option("gravityBombEnabled") and self.hardmode then
			local r, g, b, a = self:Option("gravityBombColor")
			register(HudMap:PlaceRangeMarker("highlight", x, y, 12, 180, r, g, b, a):Appear():Rotate(360, 9):RegisterForAlerts())
		end
	end
}

local hodir = {
	name = L["Hodir"],
	options = {
		stormCloud = SN[65123]
	},
	defaults = {
		stormCloudColor = {r = 1, g = 1, b = 0, a = 0.6}
	},	
	startEncounterIDs = 32845,
	endEncounterIDs = 32845,
	clouds = {},	
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if (spellID == 65123 or spellID == 65133) and self:Option("stormCloudEnabled") then
			free(self.clouds[destName], self, destName)
			local r, g, b, a = self:Option("stormCloudColor")
			self.clouds[destName] = register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, 3, 30, r, g, b, a):Appear():Rotate(360, 30):Identify(self, destName))
		end
	end,
	SPELL_AURA_REMOVED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if self.clouds[destName] and (spellID == 65123 or spellID == 65133) then
			self.clouds[destName] = free(self.clouds[destName], self, destName)
		end
	end	
}

local freya = {
	name = L["Freya"],
	startEncounterIDs = 32906,
	endEncounterIDs = 32906,
	options = {
		roots = SN[62861],
		fury = SN[63571],		
	},
	defaults = {
		rootsColor = {r = 0.1, g = 1, b = 0.4, a = 0.6},
		furyColor = {r = 0.9, g = 0.4, b = 1, a = 0.6}
	},
	roots = {},
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if (spellID == 62438 or spellID == 62861) and self:Option("rootsEnabled") then
			local r, g, b, a = self:Option("rootsColor")
			self.roots[destName] = register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, 7, 10, r, g, b, a):Appear():Rotate(360, 10):Identify(self, destName):SetLabel(destName))
		elseif (spellID == 63571 or spellID == 62589) and self:Option("furyEnabled") then
			local r, g, b, a = self:Option("furyColor")
			register(HudMap:PlaceRangeMarkerOnPartyMember("highlight", destName, 8, 10, r, g, b, a):Appear():Rotate(360, 10):Identify(self, destName):SetLabel(destName):RegisterForAlerts())
		end
	end,
	SPELL_AURA_REMOVED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if (spellID == 62438 or spellID == 62861) and self.roots[destName] then
			self.roots[destName] = free(self.roots[destName], self, destName)
		end
	end
}

local vezax = {
	name = L["General Vexaz"],
	startEncounterIDs = 33271,
	endEncounterIDs = 33271,
	options = {
		crash = SN[60835],
		mark = SN[63276]
	},
	defaults = {
		crashColor = {r = 0.1, g = 0.4, b = 1, a = 0.6},
		markColor = {r = 0.9, g = 0.4, b = 1, a = 0.6}
	},
	crash = function(self)
		local crashTarget = encounters:GetMobTarget(33271)
		if crashTarget then
			local x, y = HudMap:GetUnitPosition(crashTarget)
			local r, g, b, a = self:Option("crashColor")
			register(HudMap:PlaceRangeMarker("timer", x, y, 10, 5, r, g, b, a):Appear():Rotate(360, 5):RegisterForAlerts())
		end
	end,
	SPELL_CAST_SUCCESS = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if (spellID == 60835 or spellID == 62660) and self:Option("crashEnabled") then
			-- self.invoker = self.invoker or function() self:crash() end
			-- encounters:Delay(self.invoker, 0.1)
			local x, y = HudMap:GetUnitPosition(destName)
			if x and x>0 then
				local r, g, b, a = self:Option("crashColor")
				register(HudMap:PlaceRangeMarker("timer", x, y, 10, 5, r, g, b, a):Appear():Rotate(360, 5):RegisterForAlerts())
			end
			
		elseif spellID == 63276 and self:Option("markEnabled") then
			local r, g, b, a = self:Option("markColor")
			register(HudMap:PlaceRangeMarkerOnPartyMember("timer", destName, 15, 10, r, g, b, a):Appear():Rotate(360, 10):RegisterForAlerts():SetLabel(destName))
		end
	end
}

local yogg = {
	name = L["Yogg-Saron"],
	startEncounterIDs = 33134,
	endEncounterIDs = 33288,
	options = {
		malady = SN[63830],
		showPortalsEnabled = {
			type = "toggle",
			name = L["Enable"] .. " " .. L["Brain Portals"].." (25)",
			desc = "Will show the portals (estimated) position in phase 2.\nRELOAD the UI after changing these options for them to take effect!",
			order = 200
		},
		portalLeftColor = {
			type = "color",
			name = "Left Portals".. " " .. L["Color"],
			hasAlpha = true,
			order = 201
		},
		portalMiddleColor = {
			type = "color",
			name = "Door Portals".. " " .. L["Color"],
			hasAlpha = true,
			order = 202
		},
		portalRightColor = {
			type = "color",
			name = "Right Portals".. " " .. L["Color"],
			hasAlpha = true,
			order = 203
		},
	},
	defaults = {
		maladyColor = {r = 0.9, g = 0.4, b = 1, a = 0.6},
		showPortalsEnabled = true,
		portalLeftColor = 	{r = 1, g = 0.2, b = 0.2, a = 1},	-- 7-10
		portalMiddleColor = {r = 0.2, g = 1, b = 0.2, a = 1},	-- 5-6
		portalRightColor = 	{r = 0.2, g = 0.2, b = 1, a = 1},	-- 1-4
	},
	SPELL_AURA_APPLIED = function(self, spellID, sourceName, destName, sourceGUID, destGUID)
		if (spellID == 63830 or spellID == 63881) and self:Option("maladyEnabled") then
			local r, g, b, a = self:Option("maladyColor")
			register(HudMap:PlaceRangeMarkerOnPartyMember("timer", destName, 10, 4, r, g, b, a):Appear():Rotate(360, 10):SetLabel(destName):RegisterForAlerts())
		end
	end,
	yoggPrisonZone = "Ulduar3",	--dungeon level for yoggs prison
	portalPos = {
		["c"] = {0.681031, 0.393267},
		
		{0.681031, 0.356199},
		{0.695205, 0.362903},
		{0.703943, 0.379381},
		{0.705289, 0.400340},
		{0.699395, 0.418070},
		{0.681031, 0.430334},
		{0.662667, 0.418070},
		{0.656773, 0.400340},
		{0.658119, 0.379381},
		{0.666857, 0.362903},
	},
	markerTblPortals = {},
	phase2Active = false,
	showPortals25 = false,
	Start = function(self)
		if self:Option("showPortalsEnabled") then
			ChatFrame3:AddMessage("-- START FUNC")
			-- self.startZone = parent.currentZone	-- store name of zone where encounter started
			
			local _,_,_,_,raidsize = GetInstanceInfo()	-- get raid size
			self.showPortals25 = (raidsize == 25)
			
		end
	end,
	ShowAgain = function(self)
		ChatFrame3:AddMessage(string.format("parent.currentZone: %s (%s)", tostring(parent.currentZone), tostring(self.yoggPrisonZone == parent.currentZone) ) )
		
		-- check if ENABLED and if we are in the correct dungeon level
		if self.phase2Active and self.yoggPrisonZone == parent.currentZone then
			ChatFrame3:AddMessage("-- ShowAgain: TRUE")
			
			table.insert(self.markerTblPortals, HudMap:PlaceRangeMarkerCoords("ring", self.portalPos["c"][1], self.portalPos["c"][2], "20yd", nil, 0, 1, 1, 0.5) )
			-- HudMap:PlaceRangeMarker("ring", self.portalPos["c"][1], self.portalPos["c"][2], "20yd", nil, 0, 1, 1, 0.5)	-- place yogg indicator ring
			
			for i = 1,10 do 	-- calc every portal psition
				local px,py, r,g,b,a
				px = self.portalPos[i][1]
				py = self.portalPos[i][2]

				if i < 5 then	-- fetch portal colors
					r,g,b,a = self:Option("portalRightColor")	-- 1-4
				elseif i > 6 then
					r,g,b,a = self:Option("portalLeftColor")	-- 7-10
				else
					r,g,b,a = self:Option("portalMiddleColor")	-- 5-6
				end
				
				-- create and add every Marker to table (to wipe them all later)
				-- table.insert(self.markerTblPortals, HudMap:PlaceRangeMarkerCoords("highlight", px,py, "4yd", nil, r,g,b,a ):SetLabel( tostring(i), nil, nil, 1, 1, 1, 1, 0, -5))
				table.insert(self.markerTblPortals, HudMap:PlaceRangeMarkerCoords("highlight", px,py, "4yd", nil, r,g,b,a ):SetLabel( tostring(i), nil, nil, 1, 1, 1, 1, 0, -5))
				
			end
			
		end
	end,
	CheckZoneChange = function(self,...)
		if self:Option("showPortalsEnabled") and self.showPortals25 then 
			self:UpdateZoneData()
			self:ShowAgain()
		end
	end,
	ZONE_CHANGED = function(self,...)
		ChatFrame3:AddMessage("UpdateZoneData: ZONE_CHANGED")
		self:CheckZoneChange()
	end,
	ZONE_CHANGED_NEW_AREA = function(self,...)
		ChatFrame3:AddMessage("UpdateZoneData: ZONE_CHANGED_NEW_AREA") 
		self:CheckZoneChange()
	end,
	ZONE_CHANGED_INDOORS = function(self,...)
		ChatFrame3:AddMessage("UpdateZoneData: ZONE_CHANGED_INDOORS") 
		self:CheckZoneChange()
	end,
	CHAT_MSG_MONSTER_YELL = function(self, msg)
		if self:Option("showPortalsEnabled") and self.showPortals25 then
		
			if msg:find(L["UR_YOGG_P2_TRIGGER"]) then
				ChatFrame3:AddMessage("-----UR_YOGG_P2_TRIGGER")
				self.phase2Active = true
				
				self:ShowAgain()
			end
		
			if msg:find(L["UR_YOGG_P3_TRIGGER"]) then
				ChatFrame3:AddMessage("-----UR_YOGG_P3_TRIGGER")
				self.phase2Active = false
				
				for k,v in pairs(self.markerTblPortals) do
					free(self.markerTblPortals[k])
					self.markerTblPortals[k]=nil
				end
			end
			
		end
	end,
}

encounters:RegisterModule(L["Ulduar"], xt, hodir, freya, vezax, yogg)