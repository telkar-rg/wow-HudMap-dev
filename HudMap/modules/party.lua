local modName = "Party & Raid"
local modName = "Party & Raid"
local parent = HudMap
local L = LibStub("AceLocale-3.0"):GetLocale("HudMap")
local mod = HudMap:NewModule(modName, "AceEvent-3.0")

local modNameLocalized = L["Party & Raid"]

--[[ Default upvals 
     This has a slight performance benefit, but upvalling these also makes it easier to spot leaked globals. ]]--
local _G = _G.getfenv(0)
local wipe, type, pairs, tinsert, tremove, tonumber = _G.wipe, _G.type, _G.pairs, _G.tinsert, _G.tremove, _G.tonumber
local math, math_abs, math_pow, math_sqrt, math_sin, math_cos, math_atan2 = _G.math, _G.math.abs, _G.math.pow, _G.math.sqrt, _G.math.sin, _G.math.cos, _G.math.atan2
local error, rawset, rawget, print = _G.error, _G.rawset, _G.rawget, _G.print
local tonumber, tostring = _G.tonumber, _G.tostring
local getmetatable, setmetatable, pairs, ipairs, select, unpack = _G.getmetatable, _G.setmetatable, _G.pairs, _G.ipairs, _G.select, _G.unpack
--[[ -------------- ]]--

local db
local group = parent.group
local currentTarget, highlight

local frame = CreateFrame("Frame")
local partyMembers = {}
local highlight
local targetArrow

local roles = {}
local playerName

local free = parent.free

local options = {
	type = "group",
	name = L["Party & Raid"],
	args = {
		general = {
			type = "group",
			name = L["General"],
			args = {
				showSpellTargets = {
					type = "toggle",
					name = L["Show Spell Targets"],
					order = 111,
					get = function()
						return db.showSpellTargets
					end,
					set = function(info, v)
						db.showSpellTargets = v
					end
				},
				dotSize = {
					type = "range",
					name = L["Dot Size"],
					order = 120,
					min = 4,
					max = 50,
					step = 1,
					bigStep = 1,
					get = function()
						return db.iconSize
					end,
					set = function(info, v)
						db.iconSize = v
						for k, dot in pairs(partyMembers) do
							dot:SetSize(v .. "px")
						end
						if highlight then
							highlight:SetSize((v+5) .. "px")
						end
					end
				},
				showFeasts = {
					type = "toggle",
					name = "Show Feasts",
					order = 130,
					get = function()
						return db.showFeasts
					end,
					set = function(info, v)
						db.showFeasts = v
					end
				},
			}
		},
		target = {
			name = L["Target"],
			type = "group",
			args = {
				targetLabel = {
					type = "toggle",
					name = L["Target Name"],
					order = 125,
					get = function() return db.targetLabel end,
					set = function(info, v)
						db.targetLabel = v
						mod:PLAYER_TARGET_CHANGED()
					end
				},
				highlightTarget = {
					type = "toggle",
					name = L["Highlight Target"],
					order = 127,
					get = function() return db.highlightTarget end,
					set = function(info, v)
						db.highlightTarget = v
						mod:PLAYER_TARGET_CHANGED()
					end		
				},
				highlightMouseover = {
					type = "toggle",
					name = L["Highlight Mouseover"],
					order = 128,
					get = function() return db.highlightMouseover end,
					set = function(info, v)
						db.highlightMouseover = v
						mod:CURSOR_UPDATE()
					end		
				},
				arrowToTarget = {
					type = "toggle",
					name = L["Arrow To Target"],
					order = 109,
					get = function()
						return db.arrowToTarget
					end,
					set = function(info, v)
						db.arrowToTarget = v
					end
				},
				targetArrowColor = {
					type = "color",
					name = L["Target Arrow Color"],
					order = 109,
					hasAlpha = true,
					get = function()
						return unpack(db.targetArrowColor)
					end,
					set = function(info, r, g, b, a)						
						db.targetArrowColor[1] = r
						db.targetArrowColor[2] = g
						db.targetArrowColor[3] = b
						db.targetArrowColor[4] = a			
						if targetArrow and targetArrow:Owned(mod, "targetArrow") then
							targetArrow:SetColor(r, g, b, a)
						end
					end
				},
			}
		},
		healthBars = {
			type = "group",
			name = L["Health Bars"],
			get = function(info)
				return db.healthBars[info[#info]]
			end,
			set = function(info, v)
				db.healthBars[info[#info]] = v
				mod:UpdateHealthBars()
			end,
			args = {
				show = {
					type = "toggle",
					name = L["Show Health Bars"],					
					order = 1,
				},
				hideWhenFull = {
					type = "toggle",
					name = L["Hide When Full"],
					order = 2,
				},
				hideWhenEmpty = {
					type = "toggle",
					name = L["Hide When Empty"],
					order = 3,
				},
				width = {
					type = "range",
					name = L["Width"],
					min = 10,
					max = 50,
					step = 1,
					bigStep = 1,
					order = 10,
				},
				height = {
					type = "range",
					name = L["Height"],
					min = 3,
					max = 25,
					step = 1,
					bigStep = 1,
					order = 11,
				},
				edgeSize = {
					type = "range",
					name = L["Edge Size"],
					min = 0,
					max = 20,
					step = 1,
					bigStep = 1,
					order = 12
				},
				inset = {
					type = "range",
					name = L["Inset"],
					min = 0,
					max = 5,
					step = 0.1,
					bigStep = 0.1,
					order = 13
				},
				xoff = {
					type = "range",
					name = L["X Offset"],
					min = -50,
					max = 50,
					step = 1,
					bigStep = 1,
					order = 14
				},
				yoff = {
					type = "range",
					name = L["Y Offset"],
					min = -50,
					max = 50,
					step = 1,
					bigStep = 1,
					order = 15
				},
				bgAlpha = {
					type = "range",
					name = L["Background Opacity"],
					min = 0,
					max = 1,
					step = 0.01,
					bigStep = 0.05
				}
			}
		}		
	}
}

local defaults = {
	profile = {
		showSpellTargets = false,
		arrowToTarget = false,
		showFeasts = true,
		iconSize = 16,
		targetLabel = true,
		highlightTarget = true,
		highlightMouseover = false,
		targetArrowColor = {
			1,
			1,
			1,
			0.4
		},
		healthBars = {
			show = false,
			edgeSize = 7,
			width = 20,
			height = 7,
			hideWhenFull = true,
			hideWhenEmpty = true,
			inset = 1.8,
			xoff = 0,
			yoff = 0,
			bgAlpha = 0.7
		}
	}
}

local classLookup = setmetatable({}, {__index = function(t, k)
	local _, c = UnitClass(k)
	if c then
		rawset(t, k, c)
		return c
	end
	return nil
end})

local SN = parent.SN

local dinnerTableTextures = {
	[57426] = "feast_fish", 	--"Fischmahl",
	[57301] = "feast_misc", 	--"Großes Festmahl",
	[66476] = "feast_misc", 	--"Reichhaltiges Festmahl",
	[43987] = "food_mage",
	[58659] = "food_mage",
}

local spellMap = {
	-- Paladin
	[48825] = "healer",		-- Holy Shock
	[53562] = "healer",		-- Beacon of Light
	[54153] = "healer",		-- judgement of the pure
	[48952] = "tank",			-- Holy Shield
	[48827] = "tank",			-- avengers shield
	[53595] = "tank",			-- hammer of the righteous
	[35395] = "dps",		-- Crusader Strike
	[53385] = "dps",		-- Divine Storm
	
	-- Priest
	[53007] = "healer",		-- Penance
	[48089] = "healer",		-- Circle of Healing
	[15473] = "dps",			-- Shadowform
	[15286] = "dps",			-- vampiric embrace
	[65490] = "dps",			-- Vampiric Touch
	[48156] = "dps",			-- mind flay
	
	-- Druid
	[53251] = "healer",		-- Wild Growth
	[33891] = "healer",		-- Tree of Life
	-- [48441] = "healer",		-- Rejuv
	[6807]  = "tank",			-- Maul
	[9634]  = "tank",			-- Bear Form
	[48562] = "tank",			-- Swipe
	[768]   = "dps", 		-- Cat Form
	[48572] = "dps",		-- Shred
	[48468] = "dps",		-- Insect Swarm
	[24858] = "dps",		-- Moonkin Form
	[53201] = "dps",		-- Starfall
	
	-- Death Knight
	-- [56815] = "tank",			-- rune strike
	[48263] = "tank",			-- Frost presence
	[48266] = "dps",			-- Blood presence
	[48265] = "dps",			-- Unholy presence
	
	-- Warrior
	[12809] = "tank",			-- concussion blow
	[57823] = "tank",			-- Revenge
	[47498] = "tank",			-- devastate
	[46968] = "tank",			-- shockwave
	[47486] = "dps",			-- Mortal Strike
	[23885] = "dps",			-- Bloodthirst
	
	-- Shaman
	[61301] = "healer",   -- Riptide
	[49284] = "healer",   -- Earth Shield
	[16237] = "healer",   -- Ancestral Fortitude
	[57722] = "dps",   		-- Totem of Wrath
	[60103] = "dps",   		-- flame strike
	[17364] = "dps",   		-- Stormstrike
	[59159] = "dps"			-- Tunderstorm
}

local healthBarPool = {}
local backdrop = {
	bgFile = [[Interface\BUTTONS\WHITE8X8]],
	edgeFile = [[Interface\AddOns\HudMap\assets\SimpleSquare]],
	edgeSize = 7
}

local function setHealth(self, unit)
	local uh = UnitHealth(unit)
	local uhm = UnitHealthMax(unit)
	local pct = uh / uhm
	if (db.healthBars.hideWhenFull and pct == 1) or (db.healthBars.hideWhenEmpty and uh <= 1) or not db.healthBars.show then
		self:StopAnimating()
		self.fadeOutGroup:Play()
	else
		self.health:SetTexCoord(0.5 - 0.5 * pct, 1 - 0.5 * pct, 0, 1)
		if not self:IsVisible() then
			self:Show()
			self:StopAnimating()
			self:SetAlpha(1)
			self.fadeInGroup:Play()
		end
	end
end

local function updateBar(self)
	local width, height, inset = db.healthBars.width, db.healthBars.height, db.healthBars.inset
	local edgeSize, bgAlpha = db.healthBars.edgeSize, db.healthBars.bgAlpha
	local xoff, yoff = db.healthBars.xoff, db.healthBars.yoff
	if width ~= self.lastWidth or height ~= self.lastHeight then
		self.lastWidth, self.lastHeight = width, height
		self:SetSize(width, height)
	end
	if edgeSize ~= self.lastEdgeSize or bgAlpha ~= self.lastBgAlpha then
		self.lastEdgeSize = edgeSize
		self.lastBgAlpha = bgAlpha
		backdrop.edgeSize = edgeSize
		self:SetBackdrop(backdrop)
		self:SetBackdropBorderColor(0, 0, 0, 1)
		self:SetBackdropColor(0, 0, 0, bgAlpha)
	end
	if inset ~= self.lastInset then
		self.lastInset = inset
		self.health:ClearAllPoints()
		self.health:SetPoint("TOPLEFT", self, "TOPLEFT", inset, -inset)
		self.health:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -inset, inset)
	end
	if xoff ~= self.lastxoff or yoff ~= self.lastyoff then
		self.lastxoff = xoff
		self.lastyoff = yoff
		self:ClearAllPoints()
		self:SetPoint("TOP", self:GetParent(), "BOTTOM", xoff, yoff)
	end
end

local fadeOutFinished = function(self) self:GetRegionParent():Hide() end
local fadeInFinished = function(self) self:GetRegionParent():SetAlpha(1) end
local function acquireHealthBar(parent)
	local bar = tremove(healthBarPool)
	if not bar then
		bar = CreateFrame("Frame")
		bar.health = bar:CreateTexture()
		bar.health:SetTexture([[Interface\AddOns\HudMap\assets\healthbar]])
		bar.fadeInGroup = bar:CreateAnimationGroup()
		
		local alphaOut = bar.fadeInGroup:CreateAnimation("alpha")
		alphaOut:SetDuration(0)
		alphaOut:SetChange(-1)
		alphaOut:SetOrder(1)
		
		local fadeIn = bar.fadeInGroup:CreateAnimation("alpha")
		fadeIn:SetDuration(0.2)
		fadeIn:SetChange(1)
		fadeIn:SetOrder(2)
		fadeIn:SetScript("OnFinished", fadeInFinished)
		fadeIn:SetScript("OnStop", fadeInFinished)
		
		bar.fadeOutGroup = bar:CreateAnimationGroup()
		local fadeOut = bar.fadeOutGroup:CreateAnimation("alpha")
		fadeOut:SetChange(-1)
		fadeOut:SetDuration(0.15)
		fadeOut:SetScript("OnFinished", fadeOutFinished)
		fadeOut:SetScript("OnStop", fadeOutFinished)
	end
	bar.lastWidth, bar.lastHeight, bar.lastEdgeSize, bar.lastInset = nil, nil, nil, nil
	bar.lastxoff, bar.lastxoff = nil, nil
	bar:SetParent(parent.frame)
	bar:Show()
	bar.SetHealth = setHealth
	bar.UpdateBar = updateBar
	local _, c = UnitClass(parent.follow)
	local ct = RAID_CLASS_COLORS[c]
	bar.health:SetVertexColor(ct.r, ct.g, ct.b, ct.a)
	bar:SetBackdropBorderColor(ct.r * 0, ct.g * 0, ct.b * 0, ct.a)
	bar:UpdateBar()
	bar:SetHealth(parent.follow)
	return bar
end

local function freeHealthBar(bar)
	if bar then
		tinsert(healthBarPool, bar)
		bar:Hide()
		bar:SetParent(UIParent)
	end
	return nil
end

local bestGuess = {
	DEATHKNIGHT = function(unit)
		if UnitAura(unit, SN[48263]) then return "tank" end -- Frost presence
		return "dps"
	end,
	DRUID = function(unit)
		if UnitAura(unit, SN[9634])  then return "tank" end		-- bear
		if UnitAura(unit, SN[24858]) then return "dps" end	-- eule
		if UnitAura(unit, SN[768]) then return "dps" end	-- katze
		if UnitAura(unit, SN[33891]) then return "healer" end	-- tree
		return "dps"
	end,
	MAGE = "dps",
	HUNTER = "dps",	
	PALADIN = function(unit)
		if UnitLevel(unit) == 80 and UnitManaMax(unit) > 20000 then return "healer" end
		if UnitAura(unit, SN[25780]) then return "tank" end	-- righteous fury
		return "dps"
	end,
	PRIEST = function(unit)
		if UnitAura(unit, SN[15473]) then return "dps" end	-- shadowform
		if UnitAura(unit, SN[15286]) then return "dps" end	-- vampiric embrace
		return "healer"
	end,
	ROGUE = "dps",
	SHAMAN = function(unit)
		if UnitAura(unit, SN[57960]) then return "healer" end	-- water shield
		return "dps"
	end,
	WARLOCK = "dps",
	WARRIOR = function(unit)
		if UnitLevel(unit) == 80 and UnitHealthMax(unit) > 40000 then return "tank" end
		return "dps"
	end
}

local spellNameMap = {}
for k, v in pairs(spellMap) do
  if not SN[k] then
    print(k, "is nil")
  else
    spellNameMap[SN[k]] = v
  end
end

local UnitIsMappable = HudMap.UnitIsMappable

function mod:UpdatePartyUnit(unit)
	local n = UnitName(unit)
	if not n then return end
	if not UnitIsMappable(unit) and partyMembers[n] then
		partyMembers[n] = free(partyMembers[n], self, n)
	elseif UnitIsMappable(unit) and (not partyMembers[n] or partyMembers[n].freed) then
		local cl = RAID_CLASS_COLORS[classLookup[n]]
		if cl then
			local _, uc = UnitClass(unit)
			local r, g , b, a = cl.r, cl.g, cl.b, 1
			
			
			if not roles[n] then
				local guess = bestGuess[uc]
				if type(guess) == "function" then guess = guess(unit) end
				if guess then roles[n] = guess end
				-- ChatFrame3:AddMessage("-- HudMap: "..n.." is "..guess.." (BEST GUESS)" ) -- DEBUG
			end
			local c = parent:PlaceRangeMarkerOnPartyMember(roles[n] or "party", n, db.iconSize .. "px", nil, r, g, b, a, "BLEND"):Identify(self, n)
			-- c.healthBar = acquireHealthBar(c)
			c.RegisterCallback(self, "Free", "FreeDot")
			partyMembers[n] = c
			-- mod:UNIT_HEALTH(nil, unit)
		end
	end
end

function mod:FreeDot(cbk, dot)
	if dot.follow then
		partyMembers[dot.follow] = nil
	end
	dot.healthBar = freeHealthBar(dot.healthBar)
end

function mod:UpdateParty()
	for index, unit in group() do
		self:UpdatePartyUnit(unit)
	end
	for name, dot in pairs(partyMembers) do
		if not UnitIsMappable(name) or dot.freed then
			partyMembers[name] = free(dot, self, name)
		end
	end
end

local throttle = 10
local counter = 0
local function update(self, t)
	mod:CURSOR_UPDATE()
	counter = counter + t
	if counter > throttle then
		counter = counter - throttle
		mod:UpdateParty()
	end
end

function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile
	parent:RegisterModuleOptions(modName, options, modNameLocalized)
end

function mod:OnEnable()
	db = self.db.profile
	frame:SetScript("OnUpdate", update)
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	-- self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("RAID_ROSTER_UPDATE", "UpdateParty")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "UpdateParty")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT", "CURSOR_UPDATE")	
	self:UpdateParty()
end

function mod:OnDisable()
	frame:SetScript("OnUpdate", nil)
	for k, v in pairs(partyMembers) do
		partyMembers[k] = free(v, self, k)
	end
end

local function validUnit(unit)
	return unit and (partyMembers[unit] or UnitIsUnit(unit, "player")) and UnitIsMappable(unit, true)
end



function mod:COMBAT_LOG_EVENT_UNFILTERED(ev, timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, ...)
	local isPlayer = bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER
	if isPlayer then
		
		
		-- -- DEBUG
		-- if event == "SPELL_HEAL" and spellID==48821 and sourceName=="Sareiha" then
			-- local x, y = HudMap:GetUnitPosition(sourceName, true)
			-- if x==0 and y==0 then return end
			
			-- local duration = 10
			-- local tex = dinnerTableTextures[57426]
			
			-- HudMap:PlaceRangeMarker(tex, x, y, "20px", duration, 1,1,1,0.5):Appear()
			-- print("try to place mark")
			-- return
		-- end
		
		-- if spellNameMap[spellName] and partyMembers[sourceName] and roles[sourceName] ~= spellNameMap[spellName] then
			-- partyMembers[sourceName]:SetTexture(spellNameMap[spellName], "BLEND")
			-- roles[sourceName] = spellNameMap[spellName]
			
		if spellMap[spellID] and partyMembers[sourceName] and roles[sourceName] ~= spellMap[spellID] then
			partyMembers[sourceName]:SetTexture(spellMap[spellID], "BLEND")
			roles[sourceName] = spellMap[spellID]
			-- ChatFrame3:AddMessage("-- HudMap: "..sourceName.." is "..roles[sourceName].." ("..tostring(spellID)..", "..SN[spellID]..")" ) -- DEBUG
		end
		
		if event == "SPELL_CAST_START" or event == "SPELL_CAST_SUCCESS" or event == "SPELL_HEAL" then
			if db.showSpellTargets and sourceName and destName then
				if validUnit(destName) and parent:UnitDistance(sourceName, destName) <= 50 then
					if partyMembers[sourceName] and partyMembers[destName] then
						partyMembers[sourceName]:EdgeFrom(partyMembers[destName], nil, 1, 0.5, 1, 0.5, 0.7)
					end
				end
			end
		end
		
	end
	
	isPlayer = bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER
	if event == "SPELL_CREATE" then
		-- print(event, spellID)
		-- print(db.showFeasts , sourceName , (partyMembers[sourceName] or UnitIsUnit("player",sourceName)) , spellID , dinnerTableTextures[spellID])
		
		if db.showFeasts and sourceName and (partyMembers[sourceName] or UnitIsUnit("player",sourceName)) and spellID and dinnerTableTextures[spellID] then
			
			local x, y = HudMap:GetUnitPosition(sourceName, true)
			if x==0 and y==0 then return end
			
			local duration = 60*3
			local tex = dinnerTableTextures[spellID]
			
			HudMap:PlaceRangeMarker(tex, x, y, "20px", duration, 1,1,1,0.5):Appear()
			HudMap:PlaceRangeMarkerOnPartyMember("targeting", destName, 3, duration/10, 1, 0.5, 0, 0.8):Appear():Rotate(360, 3)
			-- print("--placed icon")
			
			-- register(HudMap:PlaceRangeMarker("timer", x, y, 6, 10, r, g, b, a):Rotate(360, 10):Appear():RegisterForAlerts())
		end
	end
	
end

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

do
	local mouseover
	function mod:CURSOR_UPDATE()
		local n = UnitName("mouseover")
		if self.lastMouseover ~= n then
			self.lastMouseover = n
			free(mouseover, self, "mouseover", true)
			if partyMembers[n] and db.highlightMouseover then
				mouseover = parent:PlaceRangeMarkerOnPartyMember([[Interface\BUTTONS\IconBorder-GlowRing.blp]], n, (db.iconSize + 5).. "px", nil, 0, 0.8, 1, 1, "ADD"):Pulse(1.3, 0.4):Identify(self, "mouseover")
			end
		end
	end
end

function mod:UNIT_HEALTH(event, unit)
	local n = UnitName(unit)
	if partyMembers[n] then
		partyMembers[n].healthBar:SetHealth(unit)
	end
end

function mod:UpdateHealthBars()
	for k, v in pairs(partyMembers) do
		local unit = k
		if v.healthBar then
			v.healthBar:UpdateBar()
			v.healthBar:SetHealth(k)
		end
	end
end