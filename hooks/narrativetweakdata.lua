NarrativeTweakData.RELEASE_WINDOW = 7 -- days
NarrativeTweakData.FACTION_TO_LOCATION = {
	federales = "mexico",
	russia = "russia"
}

Hooks:PostHook(NarrativeTweakData, "init", "init_advanced", function(self, tweak_data)
	
	
	-- guis/textures/cn_map/..id
	self.cn_locations = {
		"washington_dc",
		"new_york",
		"nevada",
		"los_angeles",
		"texas",
		"mexico",
		"florida",
		"russia",
		"minecraft",
		"san_francisco"
	}
	
	
	
	-- Map Locations
	self.cn_locations_default_camera = {
		default = {1200,900},
		washington_dc = {1242,918},
		new_york = {1300,970},
		nevada = {1350,520},
		los_angeles = {700,600},
		texas = {900,700},
		mexico = {960,1150},
		florida = {1190,1100},
		russia = {980,820},
		minecraft = {600,600},
		san_francisco = {1380,918}
	}
	
	
	-- Mark mobile jobs
	self.jobs.arm_wrapper.cn_mobile = true
	self.jobs.arm_cro.cn_mobile = true
	self.jobs.arm_und.cn_mobile = true
	self.jobs.arm_hcm.cn_mobile = true
	self.jobs.arm_par.cn_mobile = true
	self.jobs.arm_fac.cn_mobile = true
	
	
	-- Release date fix
	self.jobs.ranc.date_added = {2022,6,23}
	
	
	-- JC tweaking
	-- self.jobs.vit.jc = 80
	-- self.jobs.branchbank_gold_prof.jc = 35
	
	
	-- Guess Locations
	self:assume_cn_job_locations_from_levels(self, tweak_data)
	
	-- Set Locations (Default's "dc")
	self.jobs.red2.cn_map = "new_york"
	self.jobs.run.cn_map = "new_york"
	self.jobs.flat.cn_map = "new_york"
	self.jobs.glace.cn_map = "new_york"
	self.jobs.dah.cn_map = "new_york"
	self.jobs.fish.cn_map = "new_york"
	self.jobs.spa.cn_map = "new_york"
	self.jobs.brb.cn_map = "new_york"
	self.jobs.moon.cn_map = "new_york"
	
	self.jobs.kenaz.cn_map = "nevada"
	self.jobs.pbr.cn_map = "nevada"
	self.jobs.pbr2.cn_map = "nevada"
	self.jobs.born.cn_map = "nevada"
	self.jobs.des.cn_map = "nevada"
	
	self.jobs.rvd.cn_map = "los_angeles"
	self.jobs.jolly.cn_map = "los_angeles"
	
	self.jobs.mex.cn_map = "mexico"
	self.jobs.mex_cooking.cn_map = "mexico"
	self.jobs.bex.cn_map = "mexico"
	self.jobs.pex.cn_map = "mexico"
	self.jobs.fex.cn_map = "mexico"
	
	self.jobs.dinner.cn_map = "texas"
	self.jobs.ranc.cn_map = "texas"
	
	self.jobs.mad.cn_map = "russia"
	
	self.jobs.pal.cn_map = "florida"
	self.jobs.friend.cn_map = "florida"
	self.jobs.mia.cn_map = "florida"
	
	self.jobs.chas.cn_map = "san_francisco"
	self.jobs.sand.cn_map = "san_francisco"
	self.jobs.chca.cn_map = "san_francisco"
	self.jobs.pent.cn_map = "san_francisco"
	self.jobs.bph.cn_map = "san_francisco"
	
	if self.jobs["mc_jewelrystore"]	then self.jobs.mc_jewelrystore.cn_map = "minecraft"	end
	if self.jobs["mc_branchbank"]	then self.jobs.mc_branchbank.cn_map = "minecraft"	end
	if self.jobs["mc_shoveforge"]	then self.jobs.mc_shoveforge.cn_map = "minecraft"	end
	
	
	-- Job story connections (Unused)
	self.jobs.welcome_to_the_jungle_wrapper_prof.cn_job_next = {"mus"}
	self.jobs.mus.cn_job_next = {"election_day"}
	
	
	-- Dev
	self.job_safety = {
		border = 160,
		safe_y = 36,
		safe_x = 160
	}
	
	local SAFE_BORDER = self.job_safety.border
	local SAFE_Y = self.job_safety.safe_y
	local SAFE_X = self.job_safety.safe_x
	
	-- DC
	self.jobs.man.cn_position = {1215,783}
	self.jobs.family.cn_position = {1344,1096}
	self.jobs.four_stores.cn_position = {715,787}
	self.jobs.mallcrasher.cn_position = {772,837}
	
	self:cn_position_list(true, {945,704}, {
		"branchbank_prof",
		"branchbank_deposit",
		"branchbank_cash",
		"branchbank_gold_prof"
	})
	
	self:cn_position_list(true, {752,870}, {
		"jewelry_store",
		"ukrainian_job_prof"
	})
	
	self:cn_position_list(true, {1070,1060}, {
		"hox",
		"tag"
	})
	
	self:cn_position_list(true, {1712,778}, {
		"alex",
		"rat",
		"nail"
	},{-16,nil})
	
	self:cn_position_list(true, {1451,1100}, {
		"framing_frame",
		"gallery"
	})
	
	self:cn_position_list(true, {585,955}, {
		"kosugi",
		"shoutout_raid"
	},{16,nil})
	
	self:cn_position_list(true, {1208,1736}, {
		"crojob1",
		"crojob_wrapper"
	})
	
	self.jobs.firestarter.cn_position = {1256, 1600}
	self.jobs.nightclub.cn_position = {893,910}
	self.jobs.watchdogs_wrapper.cn_position = {1295,1386}
	self.jobs.welcome_to_the_jungle_wrapper_prof.cn_position = self:offset_cn_position(self.jobs.watchdogs_wrapper.cn_position, {-24,SAFE_Y})
	self.jobs.haunted.cn_position = self:offset_cn_position(self.jobs.welcome_to_the_jungle_wrapper_prof.cn_position, {-24,SAFE_Y})
	self.jobs.cage.cn_position = {1270,1259}
	self.jobs.arm_cro.cn_position = {1336,863}
	self.jobs.arm_wrapper.cn_position = self:offset_cn_position(self.jobs.arm_cro.cn_position, {0,-SAFE_Y})
	self.jobs.arm_und.cn_position = {1057,1251}
	self.jobs.arm_hcm.cn_position = {1099,874}
	self.jobs.peta.cn_position = self:offset_cn_position(self.jobs.arm_hcm.cn_position, {70,-40})
	self.jobs.arm_par.cn_position = {1166,943}
	self.jobs.arm_fac.cn_position = {838,991}
	
	self.jobs.big.cn_position = {2193/2,1956/2}
	self.jobs.vit.cn_position = {2059/2,1019}
	self.jobs.mus.cn_position = {2245/2,2277/2}
	self.jobs.election_day.cn_position = {1430,600}
	self.jobs.hox_3.cn_position = {359,603}
	self.jobs.cane.cn_position = {1420,1510}
	self.jobs.dark.cn_position = {1721,1013}
	self.jobs.nmh.cn_position = {658,522} -- due for reposition once less clutter
	self.jobs.chill.cn_position = {787,1092}
	self.jobs.chill_combat.cn_position = self.jobs.chill.cn_position
	self.jobs.hvh.cn_position = self:offset_cn_position(self.jobs.chill.cn_position, {-6,-SAFE_Y})
	self.jobs.arena.cn_position = {1681,1105}
	self.jobs.roberts.cn_position = {1008,568}
	self.jobs.pines.cn_position = {890,361}
	self.jobs.arm_for.cn_position = {1024,SAFE_BORDER}
	self.jobs.wwh.cn_position = self:offset_cn_position(self.jobs.arm_for.cn_position, {SAFE_X,12})
	self.jobs.mad.cn_position = self:offset_cn_position(self.jobs.wwh.cn_position, {SAFE_X,24})
	self.jobs.sah.cn_position = self:offset_cn_position(self.jobs.mad.cn_position, {SAFE_X,48})
	self.jobs.help.cn_position = {790,310}
	-- DC
	
	-- NEW YORK
	self.jobs.red2.cn_position = {950,930}
	self.jobs.run.cn_position = {915,1200}
	self.jobs.flat.cn_position = {1431,1169}
	self.jobs.glace.cn_position = {950,1600}
	self.jobs.dah.cn_position = {1030,780}
	self.jobs.fish.cn_position = {471,1740}
	self.jobs.spa.cn_position = {1370,1685}
	self.jobs.brb.cn_position = {1011,1800}
	self.jobs.moon.cn_position = {1691,776}
	-- NEW YORK
	
	-- NEVADA
	self:cn_position_list(true, {1218,252}, {
		"pbr",
		"pbr2",
		"des"
	},{140,100})
	self.jobs.born.cn_position = {1348,579}
	self.jobs.kenaz.cn_position = {545,1154}
	-- NEVADA
	
	-- LOS ANGELES
	self.jobs.rvd.cn_position = {502,826}
	self.jobs.jolly.cn_position = {528,456}
	-- LOS ANGELES
	
	-- TEXAS
	self.jobs.dinner.cn_position = {903,773}
	self.jobs.ranc.cn_position = {634,693}
	-- TEXAS
	
	-- MEXICO
	self:cn_position_list(true, {1308,1030}, {
		"mex",
		"mex_cooking"
	})
	self.jobs.bex.cn_position = {809,1300}
	self.jobs.pex.cn_position = {561,1000}
	self.jobs.fex.cn_position = {324,758}
	-- MEXICO
	
	-- FLORIDA
	self.jobs.friend.cn_position = {743,1309}
	self.jobs.pal.cn_position = {1578,1059}
	self.jobs.mia.cn_position = {1364,533}
	-- FLORIDA
	
	-- SAN FRANCISCO
	self.jobs.chas.cn_position = {1442,1125}
	self.jobs.sand.cn_position = {1156,653}
	self.jobs.chca.cn_position = {1550,380}
	self.jobs.pent.cn_position = {1580,1163}
	self.jobs.bph.cn_position = {1001,233}
	-- SAN FRANCISCO
	
	-- RUSSIA
	self.jobs.mad.cn_position = {957,796}
	-- RUSSIA
	
	
	
	--[[ EXAMPLE JOB FOR CUSTOM ICONS, strictly 85 by 60!*
	self.jobs.example.cn_icon_id = {
		texture = "guis/custom/texture",
		texture_rect = {0,0,85,60}
	}
	]]--
	
	-- Achievement icons to job icons
	-- I cant even automate this because of the weird names :(
	
	-- bain
	self.jobs.arena.cn_icon_id = tweak_data.hud_icons.C_Bain_H_Arena_AllDiffs_D0
	self.jobs.gallery.cn_icon_id = tweak_data.hud_icons.C_Bain_H_ArtGallery_AllDiffs_D0
	self.jobs.branchbank_cash.cn_icon_id = tweak_data.hud_icons.C_Bain_H_BankC_AllDiffs_D0
	self.jobs.branchbank_deposit.cn_icon_id = tweak_data.hud_icons.C_Bain_H_BankD_AllDiffs_D0
	self.jobs.branchbank_gold_prof.cn_icon_id = tweak_data.hud_icons.C_Bain_H_BankG_AllDiffs_D0
	self.jobs.branchbank_prof.cn_icon_id = tweak_data.hud_icons.C_Bain_H_BankR_AllDiffs_D0
	self.jobs.cage.cn_icon_id = tweak_data.hud_icons.C_Bain_H_Car_AllDiffs_D0
	self.jobs.family.cn_icon_id = tweak_data.hud_icons.C_Bain_H_DiamondStore_AllDiffs_D0
	self.jobs.roberts.cn_icon_id = tweak_data.hud_icons.C_Bain_H_GOBank_AllDiffs_D0
	self.jobs.jewelry_store.cn_icon_id = tweak_data.hud_icons.C_Bain_H_JewelryStore_AllDiffs_D0
	self.jobs.kosugi.cn_icon_id = tweak_data.hud_icons.C_Bain_H_ShadowRaid_AllDiffs_D0
	self.jobs.arm_cro.cn_icon_id = tweak_data.hud_icons.C_Bain_H_TransportCrossroads_AllDiffs_D0
	self.jobs.arm_hcm.cn_icon_id = tweak_data.hud_icons.C_Bain_H_TransportDowntown_AllDiffs_D0
	self.jobs.arm_fac.cn_icon_id = tweak_data.hud_icons.C_Bain_H_TransportHarbor_AllDiffs_D0
	self.jobs.arm_par.cn_icon_id = tweak_data.hud_icons.C_Bain_H_TransportPark_AllDiffs_D0
	self.jobs.arm_und.cn_icon_id = tweak_data.hud_icons.C_Bain_H_TransportUnderpass_AllDiffs_D0
	self.jobs.arm_for.cn_icon_id = tweak_data.hud_icons.C_Bain_H_TrainHeist_AllDiffs_D0
	self.jobs.rvd.cn_icon_id = tweak_data.hud_icons.C_Bain_H_ReservoirDogs_AllDiffs_D0
	
	-- butcher
	self.jobs.crojob1.cn_icon_id = tweak_data.hud_icons.C_Butcher_H_BombDock_AllDiffs_D0
	self.jobs.crojob_wrapper.cn_icon_id = tweak_data.hud_icons.C_Butcher_H_BombForest_AllDiffs_D0
	self.jobs.friend.cn_icon_id = tweak_data.hud_icons.C_Butcher_H_Scarface_AllDiffs_D0
	
	-- classics
	self.jobs.pal.cn_icon_id = tweak_data.hud_icons.C_Classics_H_Counterfeit_AllDiffs_D0
	self.jobs.red2.cn_icon_id = tweak_data.hud_icons.C_Classics_H_FirstWorldBank_AllDiffs_D0
	self.jobs.glace.cn_icon_id = tweak_data.hud_icons.C_Classics_H_GreenBridge_AllDiffs_D0
	self.jobs.run.cn_icon_id = tweak_data.hud_icons.C_Classics_H_HeatStreet_AllDiffs_D0
	self.jobs.flat.cn_icon_id = tweak_data.hud_icons.C_Classics_H_PanicRoom_AllDiffs_D0
	self.jobs.dinner.cn_icon_id = tweak_data.hud_icons.C_Classics_H_Slaughterhouse_AllDiffs_D0
	self.jobs.man.cn_icon_id = tweak_data.hud_icons.C_Classics_H_Undercover_AllDiffs_D0
	self.jobs.dah.cn_icon_id = tweak_data.hud_icons.C_Classics_H_DiamondHesit_AllDiffs_D0
	self.jobs.nmh.cn_icon_id = tweak_data.hud_icons.C_Classics_H_NoMercy_AllDiffs_D0
	
	-- continental
	self.jobs.spa.cn_icon_id = tweak_data.hud_icons.C_Continental_H_Brooklyn_AllDiffs_D0
	self.jobs.fish.cn_icon_id = tweak_data.hud_icons.C_Continental_H_YachtHeist_AllDiffs_D0
	
	-- dentist
	self.jobs.big.cn_icon_id = tweak_data.hud_icons.C_Dentist_H_BigBank_AllDiffs_D0
	self.jobs.mus.cn_icon_id = tweak_data.hud_icons.C_Dentist_H_Diamond_AllDiffs_D0
	self.jobs.kenaz.cn_icon_id = tweak_data.hud_icons.C_Dentist_H_GoldenGrinCasino_AllDiffs_D0
	self.jobs.mia.cn_icon_id = tweak_data.hud_icons.C_Dentist_H_HotlineMiami_AllDiffs_D0
	self.jobs.hox.cn_icon_id = tweak_data.hud_icons.C_Dentist_H_HoxtonBreakout_AllDiffs_D0
	self.jobs.hox_3.cn_icon_id = tweak_data.hud_icons.C_Dentist_H_HoxtonRevenge_AllDiffs_D0
	
	-- elephant
	self.jobs.welcome_to_the_jungle_wrapper_prof.cn_icon_id = tweak_data.hud_icons.C_Elephant_H_BigOil_AllDiffs_D0
	self.jobs.born.cn_icon_id = tweak_data.hud_icons.C_Elephant_H_Biker_AllDiffs_D0
	self.jobs.election_day.cn_icon_id = tweak_data.hud_icons.C_Elephant_H_ElectionDay_AllDiffs_D0
	self.jobs.framing_frame.cn_icon_id = tweak_data.hud_icons.C_Elephant_H_FramingFrame_AllDiffs_D0
	
	-- events
	self.jobs.nail.cn_icon_id = tweak_data.hud_icons.C_Event_H_LabRats_AllDiffs_D0
	self.jobs.help.cn_icon_id = tweak_data.hud_icons.C_Event_H_PrisonNightmare_AllDiffs_D0
	self.jobs.haunted.cn_icon_id = tweak_data.hud_icons.C_Event_H_SafeHouseNightmare_AllDiffs_D0
	self.jobs.hvh.cn_icon_id = tweak_data.hud_icons.C_Event_H_CursedKillRoom_AllDiffs_D0
	
	-- hector
	self.jobs.firestarter.cn_icon_id = tweak_data.hud_icons.C_Hector_H_Firestarter_AllDiffs_D0
	self.jobs.alex.cn_icon_id = tweak_data.hud_icons.C_Hector_H_Rats_AllDiffs_D0
	self.jobs.rat.cn_icon_id = tweak_data.hud_icons.C_Bain_H_CookOff_AllDiffs_D0
	self.jobs.watchdogs_wrapper.cn_icon_id = tweak_data.hud_icons.C_Hector_H_Watchdogs_AllDiffs_D0
	
	-- jimmy
	self.jobs.mad.cn_icon_id = tweak_data.hud_icons.C_Jimmy_H_Boiling_AllDiffs_D0
	self.jobs.dark.cn_icon_id = tweak_data.hud_icons.C_Jimmy_H_MurkyStation_AllDiffs_D0
	
	-- locke
	self.jobs.pbr.cn_icon_id = tweak_data.hud_icons.C_Locke_H_Beneath_AllDiffs_D0
	self.jobs.pbr2.cn_icon_id = tweak_data.hud_icons.C_Locke_H_BirthOfSky_AllDiffs_D0
	self.jobs.bph.cn_icon_id = tweak_data.hud_icons.C_Locke_H_HellsIsland_AllDiffs_D0
	self.jobs.mex.cn_icon_id = tweak_data.hud_icons.C_Locke_H_BorderCrossing_AllDiffs_D0
	self.jobs.pex.cn_icon_id = tweak_data.hud_icons.C_Locke_H_BreakfastInTijuana_AllDiffs_D0
	self.jobs.mex_cooking.cn_icon_id = tweak_data.hud_icons.C_Locke_H_BorderCrystals_AllDiffs_D0
	self.jobs.tag.cn_icon_id = tweak_data.hud_icons.C_Locke_H_BreakinFeds_AllDiffs_D0
	self.jobs.des.cn_icon_id = tweak_data.hud_icons.C_Locke_H_HenrysRock_AllDiffs_D0
	self.jobs.sah.cn_icon_id = tweak_data.hud_icons.C_Locke_H_Shacklethorne_AllDiffs_D0
	self.jobs.brb.cn_icon_id = tweak_data.hud_icons.C_Locke_H_BrooklynBank_AllDiffs_D0
	self.jobs.wwh.cn_icon_id = tweak_data.hud_icons.C_Locke_H_AlsDeal_AllDiffs_D0
	self.jobs.vit.cn_icon_id = tweak_data.hud_icons.C_Locke_H_WhiteHouse_AllDiffs_D0
	
	-- vlad
	self.jobs.jolly.cn_icon_id = tweak_data.hud_icons.C_Vlad_H_Ashock_AllDiffs_D0
	self.jobs.four_stores.cn_icon_id = tweak_data.hud_icons.C_Vlad_H_FourStores_AllDiffs_D0
	self.jobs.peta.cn_icon_id = tweak_data.hud_icons.C_Vlad_H_GoatSim_AllDiffs_D0
	self.jobs.mallcrasher.cn_icon_id = tweak_data.hud_icons.C_Vlad_H_Mallcrasher_AllDiffs_D0
	self.jobs.shoutout_raid.cn_icon_id = tweak_data.hud_icons.C_Vlad_H_Meltdown_AllDiffs_D0
	self.jobs.nightclub.cn_icon_id = tweak_data.hud_icons.C_Vlad_H_Nightclub_AllDiffs_D0
	self.jobs.cane.cn_icon_id = tweak_data.hud_icons.C_Vlad_H_Santa_AllDiffs_D0
	self.jobs.moon.cn_icon_id = tweak_data.hud_icons.C_Vlad_H_StealingXmas_AllDiffs_D0
	self.jobs.ukrainian_job_prof.cn_icon_id = tweak_data.hud_icons.C_Vlad_H_Ukrainian_AllDiffs_D0
	self.jobs.pines.cn_icon_id = tweak_data.hud_icons.C_Vlad_H_XMas_AllDiffs_D0
	self.jobs.chca.cn_icon_id = tweak_data.hud_icons.C_Vlad_H_BlackCat_AllDiffs_D0
	self.jobs.bex.cn_icon_id = tweak_data.hud_icons.C_Vlad_H_SanMartinBank_AllDiffs_D0
	self.jobs.fex.cn_icon_id = tweak_data.hud_icons.C_Vlad_H_BulocsMansion_AllDiffs_D0
	
	-- jiu feng
	self.jobs.chas.cn_icon_id = tweak_data.hud_icons.C_JiuFeng_H_DragonHeist_AllDiffs_D0
	self.jobs.sand.cn_icon_id = tweak_data.hud_icons.C_JiuFeng_H_UkrainianPrisoner_AllDiffs_D0
	
	-- shayu
	self.jobs.pent.cn_icon_id = tweak_data.hud_icons.C_Shayu_H_MountainMaster_AllDiffs_D0
	
	-- shayu
	self.jobs.ranc.cn_icon_id = tweak_data.hud_icons.C_McShay_H_MindlandRanch_AllDiffs_D0 
	
	
	--
	self:generate_cn_locations(self, tweak_data)
end)


function NarrativeTweakData:generate_cn_locations(self, tweak_data)
	for _,job in ipairs(self._jobs_index) do
		if self.jobs[job] and self.jobs[job].cn_map and not table.contains(self.cn_locations, self.jobs[job].cn_map) then
			-- log("inserting new cn map location: "..self.jobs[job].cn_map)
			table.insert(self.cn_locations, self.jobs[job].cn_map)
		end
	end
end



-- assumes location by chains level factions
function NarrativeTweakData:assume_cn_job_locations_from_levels(self, tweak_data)
	local levels_tweak = tweak_data.levels
	if not levels_tweak then log("levels_tweak "..tostring(levels_tweak)) return end
	
	for _,job_id in ipairs(self._jobs_index) do
		local job = self.jobs[job_id]
		if job then
			for _,level in ipairs(job.chain) do
				local level_id = level.level_id
				local faction = not not levels_tweak[level_id] and levels_tweak[level_id].ai_group_type or nil
				if faction and levels_tweak[level_id] and NarrativeTweakData.FACTION_TO_LOCATION[faction] then
					self.jobs[job_id].cn_map = NarrativeTweakData.FACTION_TO_LOCATION[faction]
					break
				end
			end
		end
	end
end


function NarrativeTweakData:get_locations_in_job_count_order()
	local narr = tweak_data.narrative
	
	-- cached
	if narr._get_locations_in_job_count_order then
		return narr._get_locations_in_job_count_order
	end
	
	local counted_locations = {} -- washington_dc = 68
	
	for _,job_id in ipairs(narr._jobs_index) do
		local cn_map = narr.jobs[job_id].cn_map or narr.cn_locations[1]
		if counted_locations[cn_map] then
			counted_locations[cn_map] = counted_locations[cn_map] + 1
		else
			counted_locations[cn_map] = 1
		end
	end
	
	
	local nums = {}
	for _,num in pairs(counted_locations) do
		table.insert(nums,-num)--inverted
	end
	
	table.sort(nums)
	
	local ordered_locations = {} -- 4321
	for _,_num in ipairs(nums) do
		local num = -_num--uninvert after sort
		for k,cn_map in pairs(counted_locations) do
			if counted_locations[k] == num and not table.contains(ordered_locations,k) then
				table.insert(ordered_locations,k)
			end
		end
	end
	
	narr._get_locations_in_job_count_order = ordered_locations
	return ordered_locations
end


function NarrativeTweakData:get_location_used_count(location)
	local narr = tweak_data.narrative
	
	-- cached
	if narr._get_location_used_count then
		return narr._get_location_used_count[location]
	end
	
	local counted_locations = {} -- washington_dc = 68
	
	for _,job_id in ipairs(narr._jobs_index) do
		local cn_map = narr.jobs[job_id].cn_map or narr.cn_locations[1]
		if counted_locations[cn_map] then
			counted_locations[cn_map] = counted_locations[cn_map] + 1
		else
			counted_locations[cn_map] = 1
		end
	end
	
	narr._get_location_used_count = counted_locations
	return narr._get_location_used_count[location]
end


function NarrativeTweakData:is_location_holding_new_job(location)
	local narr = tweak_data.narrative
	
	for _,job_id in ipairs(narr._jobs_index) do
		local a = narr:is_job_new(job_id)
		local b = narr.jobs[job_id] and (narr.jobs[job_id].cn_map or narr.cn_locations[1]) == location or false
		if a and b then
			return true
		end
	end
	
	return false
end


function NarrativeTweakData:cn_position_list(vertical, position, jobs, offset)
	for i,v in ipairs(jobs) do
		if self.jobs[v] then
			local fin = not not offset and {
				position[1] + ((not not offset[1] and offset[1] or (vertical and 0 or self.job_safety.safe_x)) * i),
				position[2] + ((not not offset[2] and offset[2] or (vertical and self.job_safety.safe_y or 0)) * i)
			}or{
				position[1] + (vertical and 0 or self.job_safety.safe_x * i),
				position[2] + (vertical and self.job_safety.safe_y * i or 0)
			}
			self.jobs[v].cn_position = fin
		end
	end
end


function NarrativeTweakData:offset_cn_position(postable, offsettable)
	return {
		postable[1] + offsettable[1],
		postable[2] + offsettable[2]
	}
end


function NarrativeTweakData:is_mobile_job(job_id)
	return self.jobs[job_id] and self.jobs[job_id].cn_mobile and self.jobs[job_id].cn_mobile == true or false
end


function NarrativeTweakData:is_job_locked(job_id)
    return false
end


function NarrativeTweakData:is_job_new(job_id)
	local current_date_value = {
		tonumber(os.date("%Y")),
		tonumber(os.date("%m")),
		tonumber(os.date("%d"))
	}
	
	current_date_value = current_date_value[1] * 30 * 12 + current_date_value[2] * 30 + current_date_value[3]
	local job_tweak, date_value = nil

	job_tweak = self:job_data(job_id)
	
	date_value = job_tweak.date_added and job_tweak.date_added[1] * 30 * 12 + job_tweak.date_added[2] * 30 + job_tweak.date_added[3] - current_date_value or false
	
	return date_value ~= false and date_value >= -self.RELEASE_WINDOW
end



