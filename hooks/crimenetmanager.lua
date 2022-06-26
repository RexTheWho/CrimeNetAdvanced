
-- MultiLocationItemGui
dofile(ModPath .. "classes/MultiLocationItemGui.lua")

CrimeNetManager.MOBILE_JOBS_SPEED = 7.0
CrimeNetManager.log_presets = false
CrimeNetManager.dont_build_presets = true


function CrimeNetGui:_get_random_location()
	log("CrimeNetGui:_get_random_location()")
	return self._pan_panel_job_border_x + math.random(self._map_size_w - 2 * self._pan_panel_job_border_x), self._pan_panel_job_border_y + math.random(self._map_size_h - 2 * self._pan_panel_job_border_y)
end

-- setup
function CrimeNetManager:_setup()
	if self._presets or CrimeNetManager.dont_build_presets then
		return
	end

	self._presets = {}
	local plvl = managers.experience:current_level()
	
	-- Override
	-- plvl = 50
	
	local stars = math.clamp(math.ceil((plvl + 1) / 10), 1, 10)
	local jc = math.lerp(0, 100, stars / 10)-----------------------------------------------JC 7-10
	local inf_lvl = managers.experience:current_rank()-------------------------------------infamy
	local jcs = tweak_data.narrative:get_jcs_from_stars(stars, inf_lvl > 0)
	local no_jcs = #jcs
	local chance_curve = tweak_data.narrative.STARS_CURVES[stars]
	local start_chance = tweak_data.narrative.JC_CHANCE
	local jobs_by_jc = self:_get_jobs_by_jc()
	local no_picks = self:_number_of_jobs(jcs, jobs_by_jc)
	local j = 0
	local tests = 0
	
	if log_presets then
		_G.PrintTable({
			"plvl",				plvl,
			"stars",			stars,
			"jc",				jc,
			"inf_lvl",			inf_lvl,
			"jcs",				jcs,
			"no_jcs",			no_jcs,
			"chance_curve",		chance_curve,
			"start_chance",		start_chance,
			"jobs_by_jc",		jobs_by_jc,
			"no_picks",			no_picks,
			"j",				j,
			"tests",			tests
		})
		log("JCS:")
		_G.PrintTable( jcs )
	end

	while j < no_picks do
		for i = 1, no_jcs do
			local chance = nil

			if no_jcs - 1 == 0 then
				chance = 1
			else
				chance = math.lerp(start_chance, 1, math.pow((i - 1) / (no_jcs - 1), chance_curve))
			end

			if not jobs_by_jc[jcs[i]] then
				-- Nothing
			elseif #jobs_by_jc[jcs[i]] ~= 0 then
				local job_data = nil

				if self._debug_mass_spawning then
					job_data = jobs_by_jc[jcs[i]][math.random(#jobs_by_jc[jcs[i]])]
				else
					job_data = table.remove(jobs_by_jc[jcs[i]], math.random(#jobs_by_jc[jcs[i]]))
				end

				local job_tweak = tweak_data.narrative:job_data(job_data.job_id)
				local chance_multiplier = job_tweak and job_tweak.spawn_chance_multiplier or 1
				job_data.chance = chance * chance_multiplier
				local difficulty_filter_index = managers.user:get_setting("crimenet_filter_difficulty")

				if difficulty_filter_index > 0 then
					job_data.difficulty = tweak_data:index_to_difficulty(difficulty_filter_index)
					job_data.difficulty_id = difficulty_filter_index
				end
				
				-- add job
				table.insert(self._presets, job_data)

				j = j + 1

				break
			end
		end

		tests = tests + 1

		if self._debug_mass_spawning then
			if tweak_data.gui.crime_net.debug_options.mass_spawn_limit <= tests then
				break
			end
		elseif no_picks <= tests then
			break
		end
	end

	local old_presets = self._presets
	self._presets = {}

	while #old_presets > 0 do
		table.insert(self._presets, table.remove(old_presets, math.random(#old_presets)))
	end
	
	if CrimeNetManager.log_presets == true then
		self:_log_job_presets(self._presets, plvl)
	end
end


function CrimeNetManager:_log_job_presets(presets, level)
	
	local number_of_diff_ids = {}
	for k,v in pairs(presets) do
	
	
		if number_of_diff_ids[v.difficulty] then
			number_of_diff_ids[v.difficulty] = number_of_diff_ids[v.difficulty] + 1
		else
			number_of_diff_ids[v.difficulty] = 1
		end
		
		
	end
	
	-- local file = "cn_jobs_player_level_"..tostring(level)..".txt"
	-- local log_string = "LOG FOR PLAYER LEVEL " .. tostring(level) .. "\n"
	
	-- for k,v in pairs(number_of_diff_ids) do
		-- local diff = CrimeNetManager.difficulty_converts[k]
		-- log_string = log_string .. "\n" .. diff .. ": " .. tostring(v)
	-- end
	
	-- if not _G.ignore_me_im_just_testing then
		-- _G.ignore_me_im_just_testing = {log_string}
	-- else
		-- table.insert(_G.ignore_me_im_just_testing, log_string)
	-- end
	
	-- log(log_string)
	-- log("STORING JOB PRESETS TO: "..file)
	-- _G.SaveTable( self._presets, file )
	-- _G.SaveTable( _G.ignore_me_im_just_testing, file )
end

CrimeNetManager.difficulty_converts = {
	normal = "Normal",
	hard = "Hard",
	overkill = "Very Hard",
	overkill_145 = "Overkill",
	easy_wish = "Mayhem",
	overkill_290 = "Death Wish",
	sm_wish = "Death Sentence"
}

--
function CrimeNetManager:update(t, dt)
	if not self._active then
		return
	end

	if self._getting_hacked then
		managers.menu_component:update_crimenet_gui(t, dt)

		return
	end
	
	-- real stuff
	
	-- actually spawn/update the job
	for id, job in pairs(self._active_jobs) do
		local preset_job = self._presets[id]
		if not job.added then
			job.added = true
			
			-- IS MOBILE
			local preset_job_id = preset_job.job_id
			local is_mobile = tweak_data.narrative:is_mobile_job(preset_job_id)
			job.mobile = is_mobile
			
			-- 100% MOBILE
			if is_mobile then
				job.active_timer = job.active_timer * 0.667
				
				local to_pos_x = math.round(math.random(2)-1)
				local to_pos_y = math.round(math.random(2)-1)
				
				job.mobile_to_x = to_pos_x * CrimeNetManager.MOBILE_JOBS_SPEED
				job.mobile_to_y = to_pos_y * CrimeNetManager.MOBILE_JOBS_SPEED
				
				if job.mobile_to_x == 0 and job.mobile_to_y == 0 then -- lazy
					job.mobile_to_x = CrimeNetManager.MOBILE_JOBS_SPEED
				end
			end
			
			-- TEMP
			job.active_timer = 0.01
			
			-- log("______________________ JOB ______________________")
			-- log("ADDED: idx" .. id)
			-- _G.PrintTable(job)
			-- log("//")
			-- _G.PrintTable(self._presets[id])
			
			managers.menu_component:add_crimenet_gui_preset_job(id)
		end

		managers.menu_component:update_crimenet_job(id, t, dt)
		
		-- UPDATE JOB
		if job.active_timer then
			job.active_timer = job.active_timer - dt
			local _active_job_time = self._active_job_time
			
			if job.mobile then -- Shorter duration
				_active_job_time = _active_job_time * 0.667
			end
			
			managers.menu_component:feed_crimenet_job_timer(id, job.active_timer, _active_job_time)
			
			if job.active_timer < 0 then
				managers.menu_component:remove_crimenet_gui_job(id)

				self._active_jobs[id] = nil
			
			-- is alive...
			elseif job.mobile == true then
				local cngui = self:_crimenet_gui()
				
				if cngui:does_job_exist(id) then
					local gui_data = cngui:get_job(id)
					
					if gui_data.mouse_over ~= 1 then
						gui_data.job_x = gui_data.job_x + (job.mobile_to_x * dt)
						gui_data.job_y = gui_data.job_y + (job.mobile_to_y * dt)
						
						cngui:_force_update_job(id)
					end
				end
			end
		end
	end
	
	-- max job listings
	local max_active_jobs = 0

	if not CrimeNetManager.dont_build_presets then
		max_active_jobs = math.min(self._MAX_ACTIVE_JOBS, #self._presets)
	elseif self._debug_mass_spawning then
		max_active_jobs = math.min(tweak_data.gui.crime_net.debug_options.mass_spawn_limit, #self._presets)
	end
	
	-- activate new job
	if table.size(self._active_jobs) < max_active_jobs and table.size(self._active_jobs) + table.size(self._active_server_jobs) < tweak_data.gui.crime_net.job_vars.total_active_jobs then
		self._next_job_timer = self._next_job_timer - dt

		if self._next_job_timer < 0 then
			self._next_job_timer = math.rand(self._NEW_JOB_MIN_TIME, self._NEW_JOB_MAX_TIME)

			self:activate_job()

			if self._debug_mass_spawning then
				self._next_job_timer = tweak_data.gui.crime_net.debug_options.mass_spawn_timer
			end
		end
	end

	for id, job in pairs(self._active_server_jobs) do
		job.alive_time = job.alive_time + dt

		managers.menu_component:update_crimenet_job(id, t, dt)
		managers.menu_component:feed_crimenet_server_timer(id, job.alive_time)
	end
	
	--
	managers.menu_component:update_crimenet_gui(t, dt)
	
	--
	if not self._skip_servers then
		if self._refresh_server_t < Application:time() then
			self._refresh_server_t = Application:time() + self._REFRESH_SERVERS_TIME

			self:find_online_games(Global.game_settings.search_friends_only)
		end
	elseif self._refresh_server_t < Application:time() then
		self._refresh_server_t = Application:time() + self._REFRESH_SERVERS_TIME
	end
	
	--
	managers.custom_safehouse:tick_safehouse_spawn()
end




function CrimeNetManager:open_quick_location_select()
	local dialog_data = {
		title = "CRIME.NET/TRAVEL_DATABASE",
		text = "Select a location:",
		button_list = {}
	}
	local narr = tweak_data.narrative
	for idx, loc_id in pairs(narr:get_locations_in_job_count_order()) do
		local text = loc_id
		local clean_name = string.gsub(utf8.to_upper(text), "_", " ")
		local amount = string.format("%03d", narr:get_location_used_count(loc_id))
		local new_jobs = narr:is_location_holding_new_job(loc_id)
		local text_final = clean_name .. " Jobs: " .. amount
		
		if new_jobs then -- prefix NEW!
			text_final = managers.localization:to_upper_text("menu_new") .. " -- " .. text_final
		end
		
		table.insert(dialog_data.button_list, {
			text = text_final,
			callback_func = function()
				self:set_crimenet_location(idx)
			end,
			focus_callback_func = function()
				-- nothing
			end
		})
	end

	local divider = {
		no_text = true,
		no_selection = true
	}

	table.insert(dialog_data.button_list, divider)

	local no_button = {
		text = managers.localization:text("dialog_cancel"),
		focus_callback_func = function()
			-- nothing
		end,
		cancel_button = true
	}

	table.insert(dialog_data.button_list, no_button)

	dialog_data.image_blend_mode = "normal"
	dialog_data.text_blend_mode = "add"
	dialog_data.use_text_formating = true
	dialog_data.w = 600
	dialog_data.h = 532
	dialog_data.title_font = tweak_data.menu.pd2_medium_font
	dialog_data.title_font_size = tweak_data.menu.pd2_medium_font_size
	dialog_data.font = tweak_data.menu.pd2_small_font
	dialog_data.font_size = tweak_data.menu.pd2_small_font_size
	dialog_data.text_formating_color = Color.white
	dialog_data.text_formating_color_table = {}
	dialog_data.clamp_to_screen = true

	managers.system_menu:show_buttons(dialog_data)
end



function CrimeNetManager:set_crimenet_location(idx)
	local cn_gui = managers.menu_component._crimenet_gui
	cn_gui._multi_location_item:set_location_index(idx)
	cn_gui:update_location(idx)
end

--
function CrimeNetManager:_log_all_presets(pre)
	for k,v in ipairs(pre) do
	log("\n"..tostring(k))
		_G.PrintTable(v)
	end
end


------------------------------------------
----------------CRIME-NET-----------------
-------------------GUI--------------------
------------------------------------------

-- Use JC level as level lock for jobs.
CrimeNetGui._use_crimenet_jc_level_locking = false

-- Ignore level locking at this level of infamy and higher
CrimeNetGui._infamy_level_ignore_jc_lock = 10

-- For development use, logs XY coords on click.
CrimeNetGui._debug_cn_drawing = false

-- For development use, logs XY coords on click.
CrimeNetGui._missing_job_icon = {
		texture = "guis/dlcs/trk/textures/pd2/achievements_atlas5",
		texture_rect = {870,174,85,85}
	}

-- INIT (REPLACEMENT)
function CrimeNetGui:init(ws, fullscreeen_ws, node)
	
	self._tweak_data = tweak_data.gui.crime_net
	self._crimenet_enabled = true
	
	self._jobs = {}
	self._deleting_jobs = {}

	managers.crimenet:set_getting_hacked(false)
	managers.menu_component:post_event("crime_net_startup")
	managers.menu_component:close_contract_gui()

	local no_servers = node:parameters().no_servers

	if no_servers then
		managers.crimenet:start_no_servers()
	else
		managers.crimenet:start()
	end

	managers.menu:active_menu().renderer.ws:hide()

	local safe_scaled_size = managers.gui_data:safe_scaled_size()
	self._ws = ws
	self._fullscreen_ws = fullscreeen_ws
	self._fullscreen_panel = self._fullscreen_ws:panel():panel({
		name = "fullscreen"
	})
	self._panel = self._ws:panel():panel({
		name = "main"
	})
	local full_16_9 = managers.gui_data:full_16_9_size()

	self._fullscreen_panel:bitmap({
		texture = "guis/textures/test_blur_df",
		name = "blur_top",
		render_template = "VertexColorTexturedBlur3D",
		rotation = 360,
		x = 0,
		layer = 1001,
		w = self._fullscreen_ws:panel():w(),
		h = full_16_9.convert_y * 2,
		y = -full_16_9.convert_y
	})
	self._fullscreen_panel:bitmap({
		texture = "guis/textures/test_blur_df",
		name = "blur_right",
		render_template = "VertexColorTexturedBlur3D",
		rotation = 360,
		y = 0,
		layer = 1001,
		w = full_16_9.convert_x * 2,
		h = self._fullscreen_ws:panel():h(),
		x = self._fullscreen_ws:panel():w() - full_16_9.convert_x
	})
	self._fullscreen_panel:bitmap({
		texture = "guis/textures/test_blur_df",
		name = "blur_bottom",
		render_template = "VertexColorTexturedBlur3D",
		rotation = 360,
		x = 0,
		layer = 1001,
		w = self._fullscreen_ws:panel():w(),
		h = full_16_9.convert_y * 2,
		y = self._fullscreen_ws:panel():h() - full_16_9.convert_y
	})
	self._fullscreen_panel:bitmap({
		texture = "guis/textures/test_blur_df",
		name = "blur_left",
		render_template = "VertexColorTexturedBlur3D",
		rotation = 360,
		y = 0,
		layer = 1001,
		w = full_16_9.convert_x * 2,
		h = self._fullscreen_ws:panel():h(),
		x = -full_16_9.convert_x
	})
	self._panel:rect({
		blend_mode = "add",
		h = 2,
		y = 0,
		x = 0,
		layer = 1,
		w = self._panel:w(),
		color = tweak_data.screen_colors.crimenet_lines
	})
	self._panel:rect({
		blend_mode = "add",
		h = 2,
		y = 0,
		x = 0,
		layer = 1,
		w = self._panel:w(),
		color = tweak_data.screen_colors.crimenet_lines
	}):set_bottom(self._panel:h())
	self._panel:rect({
		blend_mode = "add",
		y = 0,
		w = 2,
		x = 0,
		layer = 1,
		h = self._panel:h(),
		color = tweak_data.screen_colors.crimenet_lines
	}):set_right(self._panel:w())
	self._panel:rect({
		blend_mode = "add",
		y = 0,
		w = 2,
		x = 0,
		layer = 1,
		h = self._panel:h(),
		color = tweak_data.screen_colors.crimenet_lines
	})

	self._rasteroverlay = self._fullscreen_panel:bitmap({
		texture = "guis/textures/crimenet_map_rasteroverlay",
		name = "rasteroverlay",
		layer = 3,
		wrap_mode = "wrap",
		blend_mode = "mul",
		texture_rect = {
			0,
			0,
			32,
			256
		},
		color = Color(1, 1, 1, 1),
		w = self._fullscreen_panel:w(),
		h = self._fullscreen_panel:h()
	})

	self._fullscreen_panel:bitmap({
		texture = "guis/textures/crimenet_map_vignette",
		name = "vignette",
		blend_mode = "mul",
		layer = 2,
		color = Color(1, 1, 1, 1),
		w = self._fullscreen_panel:w(),
		h = self._fullscreen_panel:h()
	})

	local bd_light = self._fullscreen_panel:bitmap({
		texture = "guis/textures/pd2/menu_backdrop/bd_light",
		name = "bd_light",
		layer = 4
	})

	bd_light:set_size(self._fullscreen_panel:size())
	bd_light:set_alpha(0)
	bd_light:set_blend_mode("add")

	local function light_flicker_animation(o)
		local alpha = 0
		local acceleration = 0
		local wanted_alpha = math.rand(1) * 0.3
		local flicker_up = true

		while true do
			wait(0.009, self._fixed_dt)
			over(0.045, function (p)
				o:set_alpha(math.lerp(alpha, wanted_alpha, p))
			end, self._fixed_dt)

			flicker_up = not flicker_up
			alpha = o:alpha()
			wanted_alpha = math.rand(flicker_up and alpha or 0.2, not flicker_up and alpha or 0.3)
		end
	end

	bd_light:animate(light_flicker_animation)

	local back_button = self._panel:text({
		vertical = "bottom",
		name = "back_button",
		blend_mode = "add",
		align = "right",
		layer = 40,
		text = managers.localization:to_upper_text("menu_back"),
		font_size = tweak_data.menu.pd2_large_font_size,
		font = tweak_data.menu.pd2_large_font,
		color = tweak_data.screen_colors.button_stage_3
	})

	self:make_fine_text(back_button)
	back_button:set_right(self._panel:w() - 10)
	back_button:set_bottom(self._panel:h() - 10)
	back_button:set_visible(managers.menu:is_pc_controller())

	local blur_object = self._panel:bitmap({
		texture = "guis/textures/test_blur_df",
		name = "controller_legend_blur",
		render_template = "VertexColorTexturedBlur3D",
		layer = back_button:layer() - 1
	})

	blur_object:set_shape(back_button:shape())

	if not managers.menu:is_pc_controller() then
		blur_object:set_size(self._panel:w() * 0.5, tweak_data.menu.pd2_medium_font_size)
		blur_object:set_rightbottom(self._panel:w() - 2, self._panel:h() - 2)
	end

	WalletGuiObject.set_wallet(self._panel)
	WalletGuiObject.set_layer(30)
	WalletGuiObject.move_wallet(10, -10)
	
	
	-- Player Count or Offline
	local text_id = Global.game_settings.single_player and "menu_crimenet_offline" or "cn_menu_num_players_offline"
	local num_players_text = self._panel:text({
		vertical = "top",
		name = "num_players_text",
		align = "left",
		layer = 40,
		text = managers.localization:to_upper_text(text_id, {
			amount = "1"
		}),
		font_size = tweak_data.menu.pd2_small_font_size,
		font = tweak_data.menu.pd2_small_font,
		color = tweak_data.screen_colors.text
	})

	self:make_fine_text(num_players_text)
	num_players_text:set_left(10)
	num_players_text:set_top(10)

	local blur_object = self._panel:bitmap({
		texture = "guis/textures/test_blur_df",
		name = "num_players_blur",
		render_template = "VertexColorTexturedBlur3D",
		layer = num_players_text:layer() - 1
	})

	blur_object:set_shape(num_players_text:shape())
	
	
	-- Custom, Zoom Level
	self._zoom_text = self._panel:text({
		vertical = "top",
		name = "map_coord_text",
		align = "left",
		layer = 40,
		text = managers.localization:to_upper_text("cn_menu_mapcoords", {
			zoom = self._zoom or 1,
			x = "000.00",
			y = "000.00"
		}),
		font_size = tweak_data.menu.pd2_small_font_size,
		font = tweak_data.menu.pd2_small_font,
		color = tweak_data.screen_colors.text
	})

	self:make_fine_text(self._zoom_text)
	self._zoom_text:set_left(10)
	self._zoom_text:set_top(10 + 6 + tweak_data.menu.pd2_small_font_size)

	local blur_object = self._panel:bitmap({
		texture = "guis/textures/test_blur_df",
		name = "map_coord_text_blur",
		render_template = "VertexColorTexturedBlur3D",
		layer = self._zoom_text:layer() - 1
	})

	blur_object:set_shape(self._zoom_text:shape())
	
	
	-- Crimenet Country/State Button
	self._multi_location_item = MultiLocationItemGui:new(self._ws, self._panel)
	
	
	
	-- START OF LEGEND KEY PANEL
	local legends_button = self._panel:text({
		name = "legends_button",
		blend_mode = "add",
		layer = 40,
		text = managers.localization:to_upper_text("menu_cn_legend_show", {
			BTN_X = managers.localization:btn_macro("menu_toggle_legends")
		}),
		font_size = tweak_data.menu.pd2_small_font_size,
		font = tweak_data.menu.pd2_small_font,
		color = tweak_data.screen_colors.text
	})

	self:make_fine_text(legends_button)
	legends_button:set_right(self._panel:w() - 10)
	legends_button:set_top(10)
	legends_button:set_align("right")

	local blur_object = self._panel:bitmap({
		texture = "guis/textures/test_blur_df",
		name = "legends_button_blur",
		render_template = "VertexColorTexturedBlur3D",
		layer = legends_button:layer() - 1
	})

	blur_object:set_shape(legends_button:shape())

	if managers.menu:is_pc_controller() then
		legends_button:set_color(tweak_data.screen_colors.button_stage_3)
	end

	local w, h = nil
	local mw = 0
	local mh = nil
	local legend_panel = self._panel:panel({
		name = "legend_panel",
		visible = false,
		x = 10,
		layer = 40,
		y = legends_button:bottom() + 4
	})
	local host_icon = legend_panel:bitmap({
		texture = "guis/textures/pd2/crimenet_legend_host",
		x = 10,
		y = 10
	})
	local host_text = legend_panel:text({
		blend_mode = "add",
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		x = host_icon:right() + 2,
		y = host_icon:top(),
		text = managers.localization:to_upper_text("menu_cn_legend_host")
	})
	mw = math.max(mw, self:make_fine_text(host_text))
	local next_y = host_text:bottom()
	local join_icon = legend_panel:bitmap({
		texture = "guis/textures/pd2/crimenet_legend_join",
		x = 10,
		y = next_y
	})
	local join_text = legend_panel:text({
		blend_mode = "add",
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		x = host_text:left(),
		y = next_y,
		text = managers.localization:to_upper_text("menu_cn_legend_join")
	})
	mw = math.max(mw, self:make_fine_text(join_text))

	self:make_color_text(join_text, tweak_data.screen_colors.regular_color)

	next_y = join_text:bottom()
	local friends_icon = legend_panel:bitmap({
		texture = "guis/textures/pd2/crimenet_legend_join",
		x = 10,
		y = next_y,
		color = tweak_data.screen_colors.friend_color
	})
	local friends_text = legend_panel:text({
		blend_mode = "add",
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		x = host_text:left(),
		y = next_y,
		text = managers.localization:to_upper_text("menu_cn_legend_friends")
	})
	mw = math.max(mw, self:make_fine_text(friends_text))

	self:make_color_text(friends_text, tweak_data.screen_colors.friend_color)

	next_y = friends_text:bottom()

	if managers.crimenet:no_servers() or is_xb1 then
		next_y = host_text:bottom()

		join_icon:hide()
		join_text:hide()
		friends_icon:hide()
		friends_text:hide()
		friends_text:set_bottom(next_y)
	end

	local mutated_icon = legend_panel:bitmap({
		texture = "guis/textures/pd2/crimenet_legend_join",
		x = 10,
		y = next_y,
		color = tweak_data.screen_colors.mutators_color_text
	})
	local mutated_text = legend_panel:text({
		blend_mode = "add",
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		x = host_text:left(),
		y = next_y,
		text = managers.localization:to_upper_text("menu_cn_legend_mutated"),
		color = tweak_data.screen_colors.mutators_color_text
	})
	mw = math.max(mw, self:make_fine_text(mutated_text))
	next_y = mutated_text:bottom()
	local spree_icon = legend_panel:bitmap({
		texture = "guis/textures/pd2/crimenet_legend_join",
		x = 10,
		y = next_y,
		color = tweak_data.screen_colors.crime_spree_risk
	})
	local spree_text = legend_panel:text({
		blend_mode = "add",
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		x = host_text:left(),
		y = next_y,
		text = managers.localization:to_upper_text("cn_crime_spree"),
		color = tweak_data.screen_colors.crime_spree_risk
	})
	mw = math.max(mw, self:make_fine_text(spree_text))
	next_y = spree_text:bottom()
	local skirmish_icon = legend_panel:bitmap({
		texture = "guis/textures/pd2/crimenet_legend_join",
		x = 10,
		y = next_y,
		color = tweak_data.screen_colors.skirmish_color
	})
	local skirmish_text = legend_panel:text({
		blend_mode = "add",
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		x = host_text:left(),
		y = next_y,
		text = managers.localization:to_upper_text("menu_cn_skirmish"),
		color = tweak_data.screen_colors.skirmish_color
	})
	mw = math.max(mw, self:make_fine_text(skirmish_text))
	next_y = skirmish_text:bottom()
	local risk_icon = legend_panel:bitmap({
		texture = "guis/textures/pd2/crimenet_legend_risklevel",
		x = 10,
		y = next_y
	})
	local risk_text = legend_panel:text({
		blend_mode = "add",
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		x = host_text:left(),
		y = next_y,
		text = managers.localization:to_upper_text("menu_cn_legend_risk"),
		color = tweak_data.screen_colors.risk
	})
	mw = math.max(mw, self:make_fine_text(risk_text))
	next_y = risk_text:bottom()
	local ghost_icon = legend_panel:bitmap({
		texture = "guis/textures/pd2/cn_minighost",
		x = 7,
		y = next_y + 4,
		color = tweak_data.screen_colors.ghost_color
	})
	local ghost_text = legend_panel:text({
		blend_mode = "add",
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		x = host_text:left(),
		y = next_y,
		text = managers.localization:to_upper_text("menu_cn_legend_ghostable"),
		color = tweak_data.screen_colors.ghost_color
	})
	mw = math.max(mw, self:make_fine_text(ghost_text))
	next_y = ghost_text:bottom()
	local kick_none_icon = legend_panel:bitmap({
		texture = "guis/textures/pd2/cn_kick_marker",
		x = 10,
		y = next_y + 2
	})
	local kick_none_text = legend_panel:text({
		blend_mode = "add",
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		x = host_text:left(),
		y = next_y,
		text = managers.localization:to_upper_text("menu_cn_kick_disabled")
	})
	mw = math.max(mw, self:make_fine_text(kick_none_text))
	local kick_vote_icon = legend_panel:bitmap({
		texture = "guis/textures/pd2/cn_votekick_marker",
		x = 10,
		y = kick_none_text:bottom() + 2
	})
	local kick_vote_text = legend_panel:text({
		blend_mode = "add",
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		x = host_text:left(),
		y = kick_none_text:bottom(),
		text = managers.localization:to_upper_text("menu_kick_vote")
	})
	mw = math.max(mw, self:make_fine_text(kick_vote_text))
	local last_text = kick_vote_text
	local job_plan_loud_icon, job_plan_loud_text, job_plan_stealth_icon, job_plan_stealth_text = nil

	if MenuCallbackHandler:bang_active() then
		job_plan_loud_icon = legend_panel:bitmap({
			texture = "guis/textures/pd2/cn_playstyle_loud",
			x = 10,
			y = kick_vote_text:bottom() + 2
		})
		job_plan_loud_text = legend_panel:text({
			blend_mode = "add",
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size,
			x = host_text:left(),
			y = kick_vote_text:bottom(),
			text = managers.localization:to_upper_text("menu_plan_loud")
		})
		mw = math.max(mw, self:make_fine_text(job_plan_loud_text))
		job_plan_stealth_icon = legend_panel:bitmap({
			texture = "guis/textures/pd2/cn_playstyle_stealth",
			x = 10,
			y = job_plan_loud_text:bottom() + 2
		})
		job_plan_stealth_text = legend_panel:text({
			blend_mode = "add",
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size,
			x = host_text:left(),
			y = job_plan_loud_text:bottom(),
			text = managers.localization:to_upper_text("menu_plan_stealth")
		})
		mw = math.max(mw, self:make_fine_text(job_plan_stealth_text))
		last_text = job_plan_stealth_text
	end

	if managers.crimenet:no_servers() or is_xb1 then
		kick_none_icon:hide()
		kick_none_text:hide()
		kick_vote_icon:hide()
		kick_vote_text:hide()
		kick_vote_text:set_bottom(ghost_text:bottom())

		if MenuCallbackHandler:bang_active() then
			job_plan_loud_icon:hide()
			job_plan_loud_text:hide()
			job_plan_stealth_icon:hide()
			job_plan_stealth_text:hide()
		end
	end

	legend_panel:set_size(host_text:left() + mw + 10, last_text:bottom() + 10)
	legend_panel:rect({
		alpha = 0.4,
		layer = -1,
		color = Color.black
	})
	BoxGuiObject:new(legend_panel, {
		sides = {
			1,
			1,
			1,
			1
		}
	})
	legend_panel:bitmap({
		texture = "guis/textures/test_blur_df",
		render_template = "VertexColorTexturedBlur3D",
		layer = -1,
		w = legend_panel:w(),
		h = legend_panel:h()
	})
	legend_panel:set_right(self._panel:w() - 10)
	-- END OF LEGEND KEY PANEL

	local w, h = nil
	local mw = 0
	local mh = nil
	local global_bonuses_panel = self._panel:panel({
		y = 10,
		name = "global_bonuses_panel",
		layer = 40,
		h = tweak_data.menu.pd2_small_font_size * 3
	})

	local function mul_to_procent_string(multiplier)
		local pro = math.round(multiplier * 100)
		local procent_string = nil

		if pro == 0 and multiplier ~= 0 then
			procent_string = string.format("%0.2f", math.abs(multiplier * 100))
		else
			procent_string = tostring(math.abs(pro))
		end

		return procent_string, multiplier >= 0
	end

	local has_ghost_bonus = managers.job:has_ghost_bonus()

	if has_ghost_bonus then
		local ghost_bonus_mul = managers.job:get_ghost_bonus()
		local job_ghost_string = mul_to_procent_string(ghost_bonus_mul)
		local ghost_text = global_bonuses_panel:text({
			blend_mode = "add",
			align = "center",
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_small_font_size,
			text = managers.localization:to_upper_text("menu_ghost_bonus", {
				exp_bonus = job_ghost_string
			}),
			color = tweak_data.screen_colors.ghost_color
		})
	end

	if false then
		local skill_bonus = managers.player:get_skill_exp_multiplier()
		skill_bonus = skill_bonus - 1

		if skill_bonus > 0 then
			local skill_string = mul_to_procent_string(skill_bonus)
			local skill_text = global_bonuses_panel:text({
				blend_mode = "add",
				align = "center",
				font = tweak_data.menu.pd2_small_font,
				font_size = tweak_data.menu.pd2_small_font_size,
				text = managers.localization:to_upper_text("menu_cn_skill_bonus", {
					exp_bonus = skill_string
				}),
				color = tweak_data.screen_colors.skill_color
			})
		end

		local infamy_bonus = managers.player:get_infamy_exp_multiplier()
		infamy_bonus = infamy_bonus - 1

		if infamy_bonus > 0 then
			local infamy_string = mul_to_procent_string(infamy_bonus)
			local infamy_text = global_bonuses_panel:text({
				blend_mode = "add",
				align = "center",
				font = tweak_data.menu.pd2_small_font,
				font_size = tweak_data.menu.pd2_small_font_size,
				text = managers.localization:to_upper_text("menu_cn_infamy_bonus", {
					exp_bonus = infamy_string
				}),
				color = tweak_data.lootdrop.global_values.infamy.color
			})
		end

		local limited_bonus = managers.player:get_limited_exp_multiplier(nil, nil)
		limited_bonus = limited_bonus - 1

		if limited_bonus > 0 then
			local limited_string = mul_to_procent_string(limited_bonus)
			local limited_text = global_bonuses_panel:text({
				blend_mode = "add",
				align = "center",
				font = tweak_data.menu.pd2_small_font,
				font_size = tweak_data.menu.pd2_small_font_size,
				text = managers.localization:to_upper_text("menu_cn_limited_bonus", {
					exp_bonus = limited_string
				}),
				color = tweak_data.screen_colors.button_stage_2
			})
		end
	end

	if #global_bonuses_panel:children() > 1 then
		for i, child in ipairs(global_bonuses_panel:children()) do
			child:set_alpha(0)
		end

		local function global_bonuses_anim(panel)
			local child_num = 1
			local viewing_child = panel:children()[child_num]
			local t = 0
			local dt = 0

			while alive(viewing_child) do
				if not self._crimenet_enabled then
					coroutine.yield()
				else
					viewing_child:set_alpha(0)
					over(0.5, function (p)
						viewing_child:set_alpha(math.sin(p * 90))
					end)
					viewing_child:set_alpha(1)
					over(4, function (p)
						viewing_child:set_alpha((math.cos(p * 360 * 2) + 1) * 0.5 * 0.2 + 0.8)
					end)
					over(0.5, function (p)
						viewing_child:set_alpha(math.cos(p * 90))
					end)
					viewing_child:set_alpha(0)

					child_num = child_num % #panel:children() + 1
					viewing_child = panel:children()[child_num]
				end
			end
		end

		global_bonuses_panel:animate(global_bonuses_anim)
	elseif #global_bonuses_panel:children() == 1 then
		local function global_bonuses_anim(panel)
			while alive(panel) do
				if not self._crimenet_enabled then
					coroutine.yield()
				else
					over(2, function (p)
						panel:set_alpha((math.sin(p * 360) + 1) * 0.5 * 0.2 + 0.8)
					end)
				end
			end
		end

		global_bonuses_panel:animate(global_bonuses_anim)
	end

	if not no_servers and not is_xb1 then
		local id = is_x360 and "menu_cn_friends" or "menu_cn_filter"
	elseif not no_servers and is_xb1 then
		local id = "menu_cn_smart_matchmaking"
		local smart_matchmaking_button = self._panel:text({
			name = "smart_matchmaking_button",
			blend_mode = "add",
			layer = 40,
			text = managers.localization:to_upper_text(id, {
				BTN_Y = managers.localization:btn_macro("menu_toggle_filters")
			}),
			font_size = tweak_data.menu.pd2_large_font_size,
			font = tweak_data.menu.pd2_large_font,
			color = tweak_data.screen_colors.button_stage_3
		})

		self:make_fine_text(smart_matchmaking_button)
		smart_matchmaking_button:set_right(self._panel:w() - 10)
		smart_matchmaking_button:set_top(10)

		local blur_object = self._panel:bitmap({
			texture = "guis/textures/test_blur_df",
			name = "smart_matchmaking_button_blur",
			render_template = "VertexColorTexturedBlur3D",
			layer = smart_matchmaking_button:layer() - 1
		})

		blur_object:set_shape(smart_matchmaking_button:shape())
	end

	self._map_size_w = 1024*2
	self._map_size_h = 1024*2
	
	local gui_width, gui_height = managers.gui_data:get_base_res()
	local aspect = gui_width / gui_height
	local sw = math.min(self._map_size_w, self._map_size_h * aspect)
	local sh = math.min(self._map_size_h, self._map_size_w / aspect)
	local dw = self._map_size_w / sw
	local dh = self._map_size_h / sh
	self._map_size_w = dw * gui_width
	self._map_size_h = dh * gui_height
	local pw = self._map_size_w
	local ph = self._map_size_h
	self._pan_panel_border = 2.7777777777777777
	self._pan_panel_job_border_x = full_16_9.convert_x + self._pan_panel_border * 2
	self._pan_panel_job_border_y = full_16_9.convert_y + self._pan_panel_border * 2
	self._pan_panel = self._panel:panel({
		name = "pan",
		layer = 0,
		w = pw,
		h = ph
	})

	self._pan_panel:set_center(self._fullscreen_panel:w() / 2, self._fullscreen_panel:h() / 2)


	self._map_panel = self._fullscreen_panel:panel({
		name = "map",
		w = pw,
		h = ph
	})

	self._map_panel:bitmap({
		-- texture = "guis/textures/crimenet_map",
		texture = "guis/textures/cn_map/washington_dc",
		name = "map",
		layer = 0,
		color = tweak_data.screen_colors.cn_map_color_default,
		w = pw,
		h = ph
	})
	self._map_panel:child("map"):set_halign("scale")
	self._map_panel:child("map"):set_valign("scale")
	self._map_panel:set_shape(self._pan_panel:shape())

	self._map_x, self._map_y = self._map_panel:position()

	if not managers.menu:is_pc_controller() then
		managers.mouse_pointer:confine_mouse_pointer(self._panel)
		managers.menu:active_menu().input:activate_controller_mouse()
		managers.mouse_pointer:set_mouse_world_position(managers.gui_data:safe_to_full(self._panel:world_center()))
	end

	self.MIN_ZOOM = 1 -- zoom locked at and starts at
	self.MAX_ZOOM = 4
	self._zoom = self.MIN_ZOOM
	local cross_indicator_h1 = self._fullscreen_panel:bitmap({
		texture = "guis/textures/pd2/skilltree/dottedline",
		name = "cross_indicator_h1",
		h = 2,
		alpha = 0.1,
		wrap_mode = "wrap",
		blend_mode = "add",
		layer = 17,
		w = self._fullscreen_panel:w(),
		color = tweak_data.screen_colors.crimenet_lines
	})
	local cross_indicator_h2 = self._fullscreen_panel:bitmap({
		texture = "guis/textures/pd2/skilltree/dottedline",
		name = "cross_indicator_h2",
		h = 2,
		alpha = 0.1,
		wrap_mode = "wrap",
		blend_mode = "add",
		layer = 17,
		w = self._fullscreen_panel:w(),
		color = tweak_data.screen_colors.crimenet_lines
	})
	local cross_indicator_v1 = self._fullscreen_panel:bitmap({
		texture = "guis/textures/pd2/skilltree/dottedline",
		name = "cross_indicator_v1",
		w = 2,
		alpha = 0.1,
		wrap_mode = "wrap",
		blend_mode = "add",
		layer = 17,
		h = self._fullscreen_panel:h(),
		color = tweak_data.screen_colors.crimenet_lines
	})
	local cross_indicator_v2 = self._fullscreen_panel:bitmap({
		texture = "guis/textures/pd2/skilltree/dottedline",
		name = "cross_indicator_v2",
		w = 2,
		alpha = 0.1,
		wrap_mode = "wrap",
		blend_mode = "add",
		layer = 17,
		h = self._fullscreen_panel:h(),
		color = tweak_data.screen_colors.crimenet_lines
	})
	local line_indicator_h1 = self._fullscreen_panel:rect({
		blend_mode = "add",
		name = "line_indicator_h1",
		h = 2,
		w = 0,
		alpha = 0.1,
		layer = 17,
		color = tweak_data.screen_colors.crimenet_lines
	})
	local line_indicator_h2 = self._fullscreen_panel:rect({
		blend_mode = "add",
		name = "line_indicator_h2",
		h = 2,
		w = 0,
		alpha = 0.1,
		layer = 17,
		color = tweak_data.screen_colors.crimenet_lines
	})
	local line_indicator_v1 = self._fullscreen_panel:rect({
		blend_mode = "add",
		name = "line_indicator_v1",
		h = 0,
		w = 2,
		alpha = 0.1,
		layer = 17,
		color = tweak_data.screen_colors.crimenet_lines
	})
	local line_indicator_v2 = self._fullscreen_panel:rect({
		blend_mode = "add",
		name = "line_indicator_v2",
		h = 0,
		w = 2,
		alpha = 0.1,
		layer = 17,
		color = tweak_data.screen_colors.crimenet_lines
	})
	local fw = self._fullscreen_panel:w()
	local fh = self._fullscreen_panel:h()

	cross_indicator_h1:set_texture_coordinates(Vector3(0, 0, 0), Vector3(fw, 0, 0), Vector3(0, 2, 0), Vector3(fw, 2, 0))
	cross_indicator_h2:set_texture_coordinates(Vector3(0, 0, 0), Vector3(fw, 0, 0), Vector3(0, 2, 0), Vector3(fw, 2, 0))
	cross_indicator_v1:set_texture_coordinates(Vector3(0, 2, 0), Vector3(0, 0, 0), Vector3(fh, 2, 0), Vector3(fh, 0, 0))
	cross_indicator_v2:set_texture_coordinates(Vector3(0, 2, 0), Vector3(0, 0, 0), Vector3(fh, 2, 0), Vector3(fh, 0, 0))
	self:_create_locations()

	self._num_layer_jobs = 0
	local player_level = managers.experience:current_level()
	local positions_tweak_data = tweak_data.gui.crime_net.map_start_positions
	local start_position = nil

	for _, position in ipairs(positions_tweak_data) do
		if player_level <= position.max_level then
			start_position = position

			break
		end
	end

	if start_position then
		self:_goto_map_position(start_position.x, start_position.y)
	end

	self._special_contracts_id = {}

	self:add_special_contracts(node:parameters().no_casino, no_servers)

	if not false or not managers.features:can_announce("crimenet_hacked") then
		managers.features:announce_feature("crimenet_welcome")

		if is_win32 then
			managers.features:announce_feature("thq_feature")
		end

		if is_win32 and SystemInfo:distribution() == Idstring("STEAM") and Steam:logged_on() and not managers.dlc:is_dlc_unlocked("pd2_clan") and math.random() < 0.2 then
			managers.features:announce_feature("join_pd2_clan")
		end

		if managers.dlc:is_dlc_unlocked("gage_pack_jobs") then
			managers.features:announce_feature("dlc_gage_pack_jobs")
		end
	end

	managers.challenge:fetch_challenges()
end



-- INIT (POSTHOOK)
-- managers.menu_component
Hooks:PostHook(CrimeNetGui, "init", "init_advanced", function(self)
	if not self._crimenet_ambience then
		self._crimenet_ambience = managers.menu_component:post_event( "crimenet_ambience" )
	end
	
	-- self:_change_map()
	
	-- Line up the map like the original map position
	self._zoom = 2
	self:_set_zoom("out", 0, 0)
	
	
	local map_pos = tweak_data.narrative.cn_locations_default_camera["default"]
	self:_goto_map_position( map_pos[1], map_pos[2] )
end)


Hooks:PreHook(CrimeNetGui, "_remove_gui_job", "_remove_gui_job_advanced", function(self, data)
	self._pan_panel:remove(data.marker_panel_bg)
end)


-- UPDATE GUI POSTHOOK
Hooks:PostHook(CrimeNetGui, "update", "update_advanced", function(self, t, dt)
	if self._zoom_text then
		local x = (self._fullscreen_panel:child( "cross_indicator_v1" ):x() + self._fullscreen_panel:child( "cross_indicator_v2" ):x()) / 2
		local y = (self._fullscreen_panel:child( "cross_indicator_h1" ):y() + self._fullscreen_panel:child( "cross_indicator_h2" ):y()) / 2
		
		x = string.format( "%.1f", x )
		y = string.format( "%.1f", y )
		
		local zoom_string = string.format( "%.2f", self._zoom or 1 )
		
		self._panel:child("map_coord_text"):set_text( utf8.to_upper( managers.localization:text( "cn_menu_mapcoords", {zoom=zoom_string, x=x, y=y} ) ) )
	end
end)


-- both move_players_online and set_players_online_pos need updating
Hooks:PostHook(CrimeNetGui, "move_players_online", "move_players_online_advanced", function(self, x, y)
	local zoom_text = self._zoom_text

	zoom_text:move(x or 0, y or 0)
	self._panel:child("map_coord_text_blur"):set_shape(zoom_text:shape())
	
	self._multi_location_item:recenter(self._panel, x)
end)


Hooks:PostHook(CrimeNetGui, "set_players_online_pos", "set_players_online_pos_advanced", function(self, x, y)
	local zoom_text = self._zoom_text

	if x then
		zoom_text:set_x(x)
	end

	if y then
		zoom_text:set_y(y)
	end

	self._panel:child("map_coord_text_blur"):set_shape(zoom_text:shape())
	
	self._multi_location_item:recenter(self._panel, x)
end)

-- _change_map
function CrimeNetGui:update_location(idx)
	local location_id = tweak_data.narrative:get_locations_in_job_count_order()[idx]
	
	local map = self._map_panel:child("map")
	
	local pw,ph = map:w(), map:h()
	
	self._map_panel:remove( self._map_panel:child("map") )
	map = self._map_panel:bitmap({
		texture = "guis/textures/cn_map/"..location_id,
		name = "map",
		layer = 0,
		w = pw,
		h = ph
	})
	map:set_halign("scale")
	map:set_valign("scale")
	self._map_panel:set_w(1024*4)
	self._map_panel:set_h(1024*4)
	
	
	-- fade
	managers.menu_component:play_transition()
	
	
	-- clear jobs
	local all_jobs = {}

	for i, data in pairs(self._jobs) do
		if not data.is_server then
			all_jobs[i] = data
		end
	end
	
	for i, job in pairs(all_jobs) do
		self:remove_job(i, true)
	end
	
	self:add_special_contracts(false, false)
	
	-- fixes zoom/position when changing map.
	local map_pos = tweak_data.narrative.cn_locations_default_camera[location_id]
		and tweak_data.narrative.cn_locations_default_camera[location_id]
		or tweak_data.narrative.cn_locations_default_camera["default"]
		
	self:_goto_map_position( map_pos[1], map_pos[2] )
end

Hooks:PostHook(CrimeNetGui, "enable_crimenet", "enable_crimenet_advanced", function(self)
	if not self._crimenet_ambience then
		self._crimenet_ambience = managers.menu_component:post_event( "crimenet_ambience" )
	end
	self._multi_location_item:show()
end)

Hooks:PostHook(CrimeNetGui, "disable_crimenet", "disable_crimenet_advanced", function(self)
	if self._crimenet_ambience then
		self._crimenet_ambience:stop()
		self._crimenet_ambience = nil
	end
	self._multi_location_item:hide()
end)

Hooks:PostHook(CrimeNetGui, "close", "close_advanced", function(self)
	if self._crimenet_ambience then
		self._crimenet_ambience:stop()
		self._crimenet_ambience = nil
	end
end)

Hooks:PostHook(CrimeNetGui, "update_job_gui", "update_job_gui_advanced", function(self, job, inside)
	if job.marker_panel_bg then
		local marker_panel_bg = job.marker_panel_bg
		local marker_panel = job.marker_panel
		
		
		-- outline fades in/out (time * speed * amount + remaining)
		local sintime = math.abs(math.sin(Application:time() * 400)*0.3)+0.7
		
		marker_panel_bg:set_alpha( sintime )
		
	end
	
	-- Todo possibly make it so hovering affects the fade
	if inside == 1 then
		self:_update_job_by_zoom(job, true, 1)
	elseif inside ~= 1 then
		self:_update_job_by_zoom(job)
	end
	
end)

Hooks:PostHook(CrimeNetGui, "_set_zoom", "_set_zoom_advanced", function(self, zoom, x, y)
		
	local all_jobs = {}

	for i, data in pairs(self._jobs) do
		all_jobs[i] = data
	end

	for i, data in pairs(self._deleting_jobs) do
		all_jobs[i] = data
	end
	
	for _, job in pairs(all_jobs) do
		self:_update_job_by_zoom(job)
	end
	
	--[[ local job = {
		-- room_id = data.room_id,
		-- info = data.info,
		-- job_id = data.job_id,
		-- host_id = data.host_id,
		-- level_id = level_id,
		-- level_data = level_data,
		-- marker_panel = marker_panel,
		-- marker_panel_bg = marker_panel_bg,
		-- peers_panel = peers_panel,
		-- kick_option = data.kick_option,
		-- job_plan = data.job_plan,
		-- container_panel = container_panel,
		-- is_friend = data.is_friend,
		-- marker_dot = marker_dot,
		-- timer_rect = timer_rect,
		-- side_panel = side_panel,
		-- icon_panel = icon_panel,
		-- focus = focus,
		-- one_down = data.one_down,
		-- num_plrs = data.num_plrs,
		-- job_x = x,
		-- job_y = y,
		-- state = data.state,
		-- layer = 11 + self._num_layer_jobs * 3,
		-- glow_panel = glow_panel,
		-- callout = callout,
		-- text_on_right = text_on_right,
		-- location = location,
		-- heat_glow = heat_glow,
		-- mutators = data.mutators,
		-- is_crime_spree = data.crime_spree and data.crime_spree >= 0,
		-- crime_spree = data.crime_spree,
		-- crime_spree_mission = data.crime_spree_mission,
		-- color_lerp = data.color_lerp,
		-- server_data = data,
		-- mods = data.mods,
		-- is_skirmish = data.skirmish and data.skirmish > 0,
		-- skirmish = data.skirmish,
		-- skirmish_wave = data.skirmish_wave,
		-- skirmish_weekly_modifiers = data.skirmish_weekly_modifiers,
		-- is_unlocked = is_unlocked)
	]]--
end)


-- mouse moved post hook
Hooks:PostHook(CrimeNetGui, "mouse_moved", "mouse_moved_advanced", function(self, o, x, y)
	self._multi_location_item:mouse_moved(x, y)
end)


-- replaced the function since had dragging issues with _multi_location_item
function CrimeNetGui:mouse_pressed(o, button, x, y)
	if not self._crimenet_enabled then
		return
	end

	if self._getting_hacked then
		return
	end

	if not self:input_focus() then
		return
	end

	if self:mouse_button_click(button) then
		if self._panel:child("back_button"):inside(x, y) then
			managers.menu:back()

			return
		end

		if self._panel:child("legends_button"):inside(x, y) then
			self:toggle_legend()

			return
		end
		
		if self._multi_location_item:panel():inside(x, y) then
			self._multi_location_item:mouse_pressed(button, x, y)
			
			return
		end

		if self._panel:child("filter_button") and self._panel:child("filter_button"):inside(x, y) then
			managers.menu_component:post_event("menu_enter")
			managers.menu:open_node("crimenet_filters", {})

			return
		end

		if self:check_job_pressed(x, y) then
			return true
		end

		if self._panel:inside(x, y) then
			self._released_map = nil
			self._grabbed_map = {
				x = x,
				y = y,
				dirs = {}
			}
		end
	elseif self:button_wheel_scroll_down(button) then
		if self._one_scroll_out_delay then
			self._one_scroll_out_delay = nil
		end

		self:_set_zoom("out", x, y)

		return true
	elseif self:button_wheel_scroll_up(button) then
		if self._one_scroll_in_delay then
			self._one_scroll_in_delay = nil
		end

		self:_set_zoom("in", x, y)

		return true
	end

	return true
end


-- button version
function CrimeNetGui:special_btn_pressed(button)
	if not self._crimenet_enabled then
		return false
	end

	if self._getting_hacked then
		return
	end

	if button == Idstring("menu_toggle_legends") then
		self:toggle_legend()

		return true
	elseif button == Idstring("menu_change_profile_right") then
		self._multi_location_item:trigger_next_location()
		return true
	elseif button == Idstring("menu_change_profile_left") then
		self._multi_location_item:trigger_previous_location()
		
		return true
	end

	if not managers.network:session() and not Global.game_settings.single_player and button == Idstring("menu_toggle_filters") then
		managers.menu_component:post_event("menu_enter")

		if is_x360 then
			XboxLive:show_friends_ui(managers.user:get_platform_id())
		elseif is_xb1 then
			managers.menu:open_node("crimenet_contract_smart_matchmaking", {})
		else
			managers.menu:open_node("crimenet_filters", {})
		end

		return true
	end

	return false
end


-- SCALE ICONS
function CrimeNetGui:_update_job_by_zoom(job, ignore_zoom, icon_zoom_scale)
	
	ignore_zoom = ignore_zoom or false
	icon_zoom_scale = icon_zoom_scale or self:get_icon_zoom_scale()
	local default_zoom = icon_zoom_scale == 1
	-- log("icon_zoom_scale "..tostring(icon_zoom_scale))

	local marker_panel = job.marker_panel
	
	if not marker_panel then log("fail") return end
	
	local select_panel = marker_panel:child("select_panel")
	
	-- Cheating for looping over a bunch if icons to either show or hide based on zoom
	local toggle_childs = {
		job.side_panel,
		-- job.side_panel:child("job_name"),
		-- job.side_panel:child("contact_name"),
		-- job.side_panel:child("info_name"),
		-- job.side_panel:child("stars_panel"),
		job.icon_panel,
		job.container_panel,
		job.marker_panel_bg
	}
	
	-- icons
	for _,child in ipairs(job.icon_panel:children()) do
		table.insert(toggle_childs, child)
	end
	
	-- side
	for _,child in ipairs(job.side_panel:children()) do
		table.insert(toggle_childs, child)
	end
	
	for _,item in ipairs(toggle_childs) do
		if item then
			if icon_zoom_scale >= 1 then
				item:show()
			else
				item:hide()
			end
		end
	end
	
	local marker_panel_ico = job.marker_panel:child("marker_dot_icon")
	if marker_panel_ico then
		marker_panel_ico:set_w(42 * icon_zoom_scale)
		marker_panel_ico:set_h(30 * icon_zoom_scale)
		marker_panel_ico:set_world_center(select_panel:world_center())
	end
	
	local marker_panel_dot = job.marker_panel:child("marker_dot")
	if marker_panel_dot then
		marker_panel_dot:set_w(42 * icon_zoom_scale)
		marker_panel_dot:set_h(30 * icon_zoom_scale)
		marker_panel_dot:set_world_center(select_panel:world_center())
	end
	
	if job.marker_panel_bg then
		job.marker_panel_bg:set_w(96 * icon_zoom_scale)
		job.marker_panel_bg:set_h(64 * icon_zoom_scale)
		job.marker_panel_bg:set_world_center(select_panel:world_center())
	end
	
	if job.heat_glow then
		local heat_size = 256 * icon_zoom_scale
		job.heat_glow:set_w(heat_size)
		job.heat_glow:set_h(heat_size)
		job.heat_glow:set_world_center(job.marker_panel:child("select_panel"):world_center())
	end
	
	if job.peers_panel then
		job.peers_panel:set_visible(default_zoom)
		job.peers_panel:set_center_y( (marker_panel:center_y() - 16) - (8 * icon_zoom_scale) )
	end
end


function CrimeNetGui:get_icon_zoom_scale()
	local zoom_threshold = 1.75
	local zoom_threshold_in = 2.5
	
	local icon_zoom_scale = (ignore_zoom and ignore_zoom == true) and 1 or
							(self._zoom < zoom_threshold) and self._zoom/zoom_threshold or
							-- (self._zoom > zoom_threshold_in) and self._zoom/zoom_threshold_in or
							1
	
	return icon_zoom_scale
end


-- kill random jobs
function CrimeNetGui:add_preset_job(preset_id) end


function CrimeNetGui:add_server_job(data)
	local gui_data = self:_create_static_job_gui(data, "server")
	gui_data.server = true
	gui_data.host_name = data.host_name
	self._jobs[data.id] = gui_data
end


-- update (random) server job
function CrimeNetGui:update_server_job(data, i)
	-- log("update_server_job "..tostring(data).." "..tostring(data))
	local job_index = data.id or i
	local job = self._jobs[job_index]

	if not job then
		-- log("[CrimeNetGui] server no job")
		return
	end

	local level_id = data.level_id
	local level_data = tweak_data.levels[level_id]
	local updated_room = self:_update_job_variable(job_index, "room_id", data.room_id)
	local updated_job = self:_update_job_variable(job_index, "job_id", data.job_id)
	local updated_level_id = self:_update_job_variable(job_index, "level_id", level_id)
	local updated_level_data = self:_update_job_variable(job_index, "level_data", level_data)
	local updated_difficulty = self:_update_job_variable(job_index, "difficulty", data.difficulty)
	local updated_difficulty_id = self:_update_job_variable(job_index, "difficulty_id", data.difficulty_id)
	local updated_one_down = self:_update_job_variable(job_index, "one_down", data.one_down)
	local updated_state = self:_update_job_variable(job_index, "state", data.state)
	local updated_friend = self:_update_job_variable(job_index, "is_friend", data.is_friend)
	local updated_job_plan = self:_update_job_variable(job_index, "job_plan", data.job_plan)
	local job_overlapping = self:is_job_position_overlapping(job)
	
	
	-- log(
		-- "UPDATE SERVER JOB\n updated_room "..tostring(updated_room)..
		-- "\n updated_job "..tostring(updated_job)..
		-- "\n updated_level_id "..tostring(updated_level_id)..
		-- "\n updated_level_data "..tostring(updated_level_data)..
		-- "\n updated_difficulty "..tostring(updated_difficulty)..
		-- "\n updated_difficulty "..tostring(data.difficulty)..
		-- "\n updated_difficulty_id "..tostring(updated_difficulty_id)..
		-- "\n updated_difficulty_id "..tostring(difficulty_id)..
		-- "\n updated_one_down "..tostring(updated_one_down)..
		-- "\n updated_state "..tostring(updated_state)..
		-- "\n updated_friend "..tostring(updated_friend)..
		-- "\n updated_job_plan "..tostring(updated_job_plan)..
		-- "\n job_overlapping "..tostring(job_overlapping)
	-- )
	
	
	--
	local recreate_job =	updated_room or			updated_job or			updated_level_id or
							updated_level_data or	updated_difficulty or	updated_difficulty_id or
							updated_one_down or		updated_state or		updated_friend or
							updated_job_plan or		job_overlapping
	
	job.server_data = data
	job.mutators = data.mutators
	job.mods = data.mods

	self:_update_job_variable(job_index, "state_name", data.state_name)

	if self:_update_job_variable(job_index, "num_plrs", data.num_plrs) and job.peers_panel then
		for i, peer_icon in ipairs(job.peers_panel:children()) do
			peer_icon:set_visible(i <= job.num_plrs)
		end
	end

	local new_color = Color.white
	local new_text_color = Color.white
	local mutator = data.mutators and next(data.mutators) or false
	local mutator_category = mutator and managers.mutators:get_mutator_from_id(mutator):main_category() or "mutator"

	if data.mutators then
		new_color = managers.mutators:get_category_color(mutator_category) or new_color
	end

	if data.mutators then
		new_text_color = managers.mutators:get_category_text_color(mutator_category) or new_text_color
	end

	if data.is_crime_spree then
		new_color = tweak_data.screen_colors.crime_spree_risk or new_color
	end

	if data.is_crime_spree then
		new_text_color = tweak_data.screen_colors.crime_spree_risk or new_text_color
	end

	if data.is_skirmish then
		new_color = tweak_data.screen_colors.skirmish_color or new_color
	end

	if data.is_skirmish then
		new_text_color = tweak_data.screen_colors.skirmish_color or new_text_color
	end

	if job.peers_panel then
		for i, peer_icon in ipairs(job.peers_panel:children()) do
			peer_icon:set_color(new_color)
		end
	end

	if job.marker_panel then
		job.marker_panel:child("marker_dot"):set_color(new_color)
	end

	if job.side_panel then
		job.side_panel:child("job_name"):set_color(new_text_color)
		job.side_panel:child("contact_name"):set_color(new_text_color)
		job.side_panel:child("info_name"):set_color(new_text_color)
	end

	if recreate_job then -- frequently updated en mass
		-- log("[CrimeNetGui] update_server_job" .. " job_index " .. tostring(job_index))

		local is_server = job.server
		local x = job.job_x
		local y = job.job_y
		local location = job.location

		self:remove_job(job_index, true)

		local gui_data = self:_create_static_job_gui(data, is_server and "server" or "contract", x, y, location)
		gui_data.server = is_server
		self._jobs[job_index] = gui_data
	end
end


-- special contract icons spawn from gui tweakdata
function CrimeNetGui:add_special_contracts(no_casino, no_quickplay)
	for index, special_contract in ipairs(tweak_data.gui.crime_net.special_contracts) do
		local skip = false

		if managers.custom_safehouse:unlocked() and special_contract.id == "challenge" or not managers.custom_safehouse:unlocked() and special_contract.id == "safehouse" then
			skip = true
		end

		skip = skip or special_contract.sp_only and not Global.game_settings.single_player
		skip = skip or special_contract.mp_only and Global.game_settings.single_player
		skip = skip or special_contract.no_session_only and managers.network:session()
		
		local job_data = tweak_data.narrative:job_data(special_contract.job_id)
		if job_data then
			local cn_locations = tweak_data.narrative:get_locations_in_job_count_order()
			local filter_loc = cn_locations[self._multi_location_item._current_name_index]
			local cn_map_loc = job_data.cn_map or cn_locations[1]
			-- log("Check: " .. special_contract.job_id .. " - " .. cn_map_loc .. " / " .. filter_loc)
			skip = skip or cn_map_loc ~= filter_loc
		end
		
		-- not skip, add special contract
		if not skip then
			self:add_special_contract(special_contract, no_casino, no_quickplay)
		end
	end
	
	
	-- fix icon overlapping positions
	-- log("Updating Job Alignments")
	local safe_bounds = tweak_data.crimenet_map.border_safe_rect
	local safe_icon_x_left = tweak_data.crimenet_map.safe_x_left
	local safe_icon_x_right = tweak_data.crimenet_map.safe_x_right
	local safe_icon_y = tweak_data.crimenet_map.safe_y
	
	-- for all jobs
	for heist_name, gui_data in pairs(self._jobs) do
		--log("______________________________________________")
		--log("> THIS JOB IS CHECKING IF IT MUST MOVE: "..tostring(heist_name))
		
		local attempts = 1
		local is_clear
		local moved_job = false
		while attempts > 0 and not is_clear do
			for check_heist_name, check_gui_data in pairs(self._jobs) do
				if check_heist_name ~= heist_name then
					--log("\t...test "..check_heist_name)
					--log("\t...Y: main"..tostring(gui_data.job_y).." /check "..tostring(check_gui_data.job_y).."  diff:"..tostring(gui_data.job_y-check_gui_data.job_y))
					--log("\t...X: main"..tostring(gui_data.job_x).." /check "..tostring(check_gui_data.job_x).."  diff:"..tostring(gui_data.job_x-check_gui_data.job_x))
					
					-- EZ mode
					local identical_xy = (gui_data.job_y == check_gui_data.job_y) and (gui_data.job_x == check_gui_data.job_x)
					if identical_xy then
						--log("RESULT - needs_update: identical xy")
						gui_data.job_y = gui_data.job_y + safe_icon_y
						moved_job = true
						is_clear = false
						break
					end
					
					-- Math time
					local dif_x, dif_y = gui_data.job_x - check_gui_data.job_x, gui_data.job_y - check_gui_data.job_y
					
					local close_y_down = dif_y > -safe_icon_y
					local close_y_up = dif_y < safe_icon_y
					
					--log("\t...close_y_down "..tostring(close_y_down))
					--log("\t...close_y_up "..tostring(close_y_up))
					
					local close_x_right = dif_x > -safe_icon_x_left
					local close_x_left = dif_x < safe_icon_x_right
					
					--log("\t...close_x_right "..tostring(close_x_right))
					--log("\t...close_x_left "..tostring(close_x_left))
					
					-- betweens
					local close_between_y = close_y_down and close_y_up
					local close_between_x = close_x_right and close_x_left
					
					--log("\t...close_between_y "..tostring(close_between_y))
					--log("\t...close_between_x "..tostring(close_between_x))
					
					local needs_update = close_between_y and close_between_x -- AND overlapping
					is_clear = needs_update
					
					local diff_y_pos = dif_y > 0
					local diff_x_pos = dif_x > 0
					local diff_x_over_y = math.abs(dif_x) > math.abs(dif_y)
					
					-- Movers
					if needs_update then
						if not diff_x_over_y and close_between_y then
							--log("RESULT - needs_update: y")
							if diff_y_pos then
								gui_data.job_y = gui_data.job_y + (safe_icon_y - math.abs(dif_y))
								moved_job = true
								break
							else
								gui_data.job_y = gui_data.job_y - (safe_icon_y - math.abs(dif_y))
								moved_job = true
								break
							end
						end
						
						if close_between_x then
							--log("RESULT - needs_update: x")
							if diff_x_pos then
								gui_data.job_x = gui_data.job_x + (safe_icon_x_right - math.abs(dif_x))
								moved_job = true
								break
							else
								gui_data.job_x = gui_data.job_x - (safe_icon_x_left - math.abs(dif_x))
								moved_job = true
								break
							end
						end
						--log("RESULT - needs_update: failed")
					else	
						-- log("clear")
						is_clear = true
					end
				else
					--log("\t...test "..check_heist_name.."   ...hey thats me!")
				end
				--log("----------------------------------------------")
			end
			
			attempts = attempts - 1
			-- log("finished attempt, remaining "..tostring(attempts))
		end
		
		if is_clear and moved_job then
			-- log("is clear, update: "..tostring(heist_name))
			self:_force_update_job(heist_name)
		end
	end
end


function CrimeNetGui:is_job_position_overlapping(gui_data)
	local safe_icon_x_left = tweak_data.crimenet_map.safe_x_left
	local safe_icon_x_right = tweak_data.crimenet_map.safe_x_right
	local safe_icon_y = tweak_data.crimenet_map.safe_y
	for _, check_gui_data in pairs(self._jobs) do
		if not check_gui_data.host_id or check_gui_data.host_id ~= gui_data.host_id then
			local identical_xy = (gui_data.job_y == check_gui_data.job_y) and (gui_data.job_x == check_gui_data.job_x)
			
			if identical_xy then
				return true
			end
			
			local dif_x, dif_y = gui_data.job_x - check_gui_data.job_x, gui_data.job_y - check_gui_data.job_y
			
			local close_y_down = dif_y > -safe_icon_y
			local close_y_up = dif_y < safe_icon_y
			
			local close_x_right = dif_x > -safe_icon_x_left
			local close_x_left = dif_x < safe_icon_x_right
			
			local close_between_y = close_y_down and close_y_up
			local close_between_x = close_x_right and close_x_left
			
			if close_between_y and close_between_x then
				return true
			end
		end
	end
	return false
end


-- This is not a replacement, this is a NEW function based on the original.
function CrimeNetGui:add_special_contract(special_contract, no_casino, no_quickplay)
	local id = special_contract.id
	
	local allow_cs = (special_contract.id ~= "crime_spree" or managers.crime_spree:unlocked())
	local allow_qp = (special_contract.id ~= "quickplay" or not no_quickplay)
	local allow_casino = (special_contract.id ~= "casino" or not no_casino)
	local allow_lv = (not special_contract.unlock or special_contract.unlock and tweak_data:get_value(special_contract.id, special_contract.unlock) <= managers.experience:current_level())
	
	local allow = id and not self._jobs[id] and allow_lv and allow_casino and allow_qp and allow_cs

	if allow then
		local type = "special"
		
		-- If using JC Level locking AND account for infamy if needed
		local is_infamy = managers.experience:current_rank() >= CrimeNetGui._infamy_level_ignore_jc_lock
		
		if CrimeNetGui._use_crimenet_jc_level_locking == true and not is_infamy then
			local level_unlocked = (not special_contract.level_requirement or special_contract.level_requirement and special_contract.level_requirement <= managers.experience:current_level())
			
			if not level_unlocked then
				log("ICON NOT UNLOCKED")
				-- special_contract.icon = "contract_locked"
				special_contract.level_locked = true
			end
		end
		
		if id == "crime_spree" then
			type = "crime_spree"
		end
		
		
		local gui_data = self:_create_static_job_gui(special_contract, type) -- < JOB GUI MADE HERE
		
		gui_data.server = false
		gui_data.special_node = special_contract.menu_node
		gui_data.dlc = special_contract.dlc
		
		if special_contract.pulse and (not special_contract.pulse_level or managers.experience:current_level() <= special_contract.pulse_level and managers.experience:current_rank() == 0) then
			local function animate_pulse(o)
				while true do
					over(1, function (p)
						o:set_alpha(math.sin(p * 180) * 0.4 + 0.2)
					end)
				end
			end

			gui_data.glow_panel:animate(special_contract.pulse_func or animate_pulse)

			gui_data.pulse = special_contract.pulse and 21
		end

		if special_contract.mutators_color and (managers.mutators:are_mutators_enabled() or managers.mutators:are_mutators_active()) then
			gui_data.side_panel:child("job_name"):set_color(tweak_data.screen_colors.mutators_color_text)
			gui_data.side_panel:child("contact_name"):set_color(tweak_data.screen_colors.mutators_color_text)
			gui_data.side_panel:child("info_name"):set_color(tweak_data.screen_colors.mutators_color_text)
			gui_data.marker_panel:child("marker_dot"):set_color(tweak_data.screen_colors.mutators_color_text)
		end

		if special_contract.id == "crime_spree" then
			gui_data.side_panel:child("job_name"):set_color(tweak_data.screen_colors.crime_spree_risk)
			gui_data.side_panel:child("contact_name"):set_color(tweak_data.screen_colors.crime_spree_risk)
			gui_data.side_panel:child("info_name"):set_color(tweak_data.screen_colors.crime_spree_risk)
			gui_data.marker_panel:child("marker_dot"):set_color(tweak_data.screen_colors.crime_spree_risk)
		end

		self._jobs[id] = gui_data

		table.insert(self._special_contracts_id, id)
	end
end


--
function CrimeNetGui:_force_update_job(id)
	local job  = self._jobs[id]
	
	job.marker_panel:set_center(job.job_x * self._zoom, job.job_y * self._zoom)
	job.glow_panel:set_world_center(job.marker_panel:child("select_panel"):world_center())

	if job.heat_glow then
		job.heat_glow:set_world_center(job.marker_panel:child("select_panel"):world_center())
	end

	if job.focus then job.focus:set_center(job.marker_panel:center()) end

	if job.container_panel then
		job.container_panel:set_center_x(job.marker_panel:center_x())
		job.container_panel:set_bottom(job.marker_panel:top())
		job.container_panel:set_x(math.round(job.container_panel:x()))
	end

	if job.text_on_right then
		job.side_panel:set_left(job.marker_panel:right())
	else
		job.side_panel:set_right(job.marker_panel:left())
	end

	job.side_panel:set_top(job.marker_panel:top() - job.side_panel:child("job_name"):top() + 1)

	if job.icon_panel then
		if job.text_on_right then
			job.icon_panel:set_right(job.marker_panel:left() + 2)
		else
			job.icon_panel:set_left(job.marker_panel:right() - 2)
		end

		job.icon_panel:set_top(math.round(job.marker_panel:top() + 1))
	end

	if job.peers_panel then
		job.peers_panel:set_center_x(job.marker_panel:center_x())
		job.peers_panel:set_center_y(job.marker_panel:center_y())
	end
end


--
function CrimeNetGui:get_job(id)
	if self._jobs and self._jobs[id] ~= nil then
		return self._jobs[id]
	end
	return nil
end


-- icons use primary and secondary, secondary is outlines and glowies
function CrimeNetGui:get_job_colors(is_unlocked, is_dlc_unowned, is_professional, is_job_new)
	local color = is_unlocked and Color.white or tweak_data.screen_colors.cn_locked										-- Normal or Faded
	
	local color_secondary = (not is_unlocked and is_dlc_unowned)	and tweak_data.screen_colors.cn_dlc_color_dark or	-- Semi-Faded
							(not is_unlocked)						and tweak_data.screen_colors.cn_locked_dark or      -- Faded
							is_professional							and tweak_data.screen_colors.pro_color or           -- Red
							is_job_new								and tweak_data.screen_colors.brand_new or           -- Green
							is_dlc_unowned							and tweak_data.screen_colors.dlc_color or           -- Yellow
																	tweak_data.screen_colors.regular_color              -- Normal

	return color, color_secondary
end


-- HELL
function CrimeNetGui:_create_static_job_gui(data, type, fixed_x, fixed_y, fixed_location)

	-- _G.PrintTable(data)
	--[[
		"x" = 1745
		["icon"] = table
		"id" = heist_rat
		"y" = 410
		"desc_id" = heist_contact_bain
		"name_id" = heist_rat
		"job_id" = rat
		"level_requirement" = 60
	]]--
	
	local level_id = data.level_id
	local level_data = tweak_data.levels[level_id]
	local narrative_data = data.job_id and tweak_data.narrative:job_data(data.job_id)
	local is_special = type == "special" or type == "crime_spree"
	local is_server = type == "server"
	local is_crime_spree = type == "crime_spree"
	local is_professional = narrative_data and narrative_data.professional
	local got_job = data.job_id and true or false
	local x = fixed_x
	local y = fixed_y
	local location = fixed_location
	local is_job_new = tweak_data.narrative:is_job_new(data.job_id)
	
	local dlc_unowned = false
	if data.dlc then
		dlc_unowned = not managers.dlc:is_dlc_unlocked(data.dlc)
	end
	
	-- General bool for if the icon should be locked
	local is_unlocked = not (data.level_locked and data.level_locked == true) and not dlc_unowned
	
	--
	if is_special then
		x = data.x
		y = data.y

		if x and y then
			local tw = math.max(self._map_panel:child("map"):texture_width(), 1)
			local th = math.max(self._map_panel:child("map"):texture_height(), 1)
			x = math.round(x / tw * self._map_size_w)
			y = math.round(y / th * self._map_size_h)
		end
	end
	
	--
	if (not x and not y) or is_server then
		x, y, location = self:_get_job_location(data)
	end
	
	-- *shrug*
	if location and location[3] then
		Application:error("[CrimeNetGui:_create_job_gui] Location already taken!", x, y)
	end
	
	-- inside gui box stuff
	local marker_panel_size_x = 48 + 2
	local marker_panel_size_y = 32
	local marker_panel_margin_x = (marker_panel_size_x - 64)/2
	local marker_panel_margin_y = (marker_panel_size_y - 32)/2
	
	
	local color, color_secondary = self:get_job_colors(is_unlocked, dlc_unowned, is_professional, is_job_new)
	
	
	local friend_color = tweak_data.screen_colors.friend_color
	local brand_new_color = tweak_data.screen_colors.brand_new
	local regular_color = tweak_data.screen_colors.regular_color
	local pro_color = tweak_data.screen_colors.pro_color
	local dlc_color = tweak_data.screen_colors.dlc_color
	local mutator_category = data.mutators and managers.mutators:get_mutator_from_id(next(data.mutators)):main_category() or "mutator"
	local mutator_color = managers.mutators:get_category_color(mutator_category)
	local mutator_text_color = managers.mutators:get_category_text_color(mutator_category)
	local side_panel = self._pan_panel:panel({
		alpha = 0,
		layer = 26
	})
	local heat_glow = nil
	local stars_panel = side_panel:panel({
		w = 100,
		name = "stars_panel",
		visible = true,
		layer = -1
	})


	
	local num_stars = 0
	local job_days = #tweak_data.narrative:job_chain(data.job_id)
	local job_cash = managers.experience:cash_string(math.round(narrative_data.payout[1]))
	
	
	-- There must be text here or else dont apply.
	local difficulty_name = side_panel:text({
		text = " ",--empty for now, text/color applied later
		name = "difficulty_name",
		vertical = "center",
		blend_mode = "add",
		layer = 0,
		font = tweak_data.menu.pd2_tiny_font,
		font_size = tweak_data.menu.pd2_tiny_font_size,
		color = tweak_data.screen_colors.risk
	})
	
	
	local one_down_active = data.one_down == 1
	-- local one_down_active = true
	
	local one_down_label = one_down_active and side_panel:text({
		name = "one_down_label",
		vertical = "center",
		blend_mode = "add",
		layer = 0,
		text = managers.localization:to_upper_text("menu_one_down"),
		font = tweak_data.menu.pd2_tiny_font,
		font_size = tweak_data.menu.pd2_tiny_font_size,
		color = tweak_data.screen_colors.one_down
	})
	
	local heat_name = side_panel:text({
		text = "",
		name = "heat_name",
		vertical = "center",
		blend_mode = "add",
		layer = 0,
		font = tweak_data.menu.pd2_tiny_font,
		font_size = tweak_data.menu.pd2_tiny_font_size,
		color = color
	})
	local got_heat = false
	local range_colors = {}
	local text_string = managers.localization:to_upper_text("menu_exp_short")



	
	local function mul_to_procent_string(multiplier)
		local pro = math.round(multiplier * 100)
		local procent_string = nil

		if pro == 0 and multiplier ~= 0 then
			procent_string = string.format("%0.2f", math.abs(multiplier * 100))
		else
			procent_string = tostring(math.abs(pro))
		end

		return (multiplier < 0 and " -" or " +") .. procent_string .. "%"
	end

	local got_heat_text = false
	local has_ghost_bonus = managers.job:has_ghost_bonus() and is_unlocked

	if has_ghost_bonus then
		local ghost_bonus_mul = managers.job:get_ghost_bonus()
		local job_ghost_string = mul_to_procent_string(ghost_bonus_mul)
		local s = utf8.len(text_string)
		text_string = text_string .. job_ghost_string

		table.insert(range_colors, {
			s,
			utf8.len(text_string),
			tweak_data.screen_colors.ghost_color
		})

		got_heat_text = true
	end



	-- always off
	if false then
		local skill_bonus = managers.player:get_skill_exp_multiplier()
		skill_bonus = skill_bonus - 1

		if skill_bonus > 0 then
			local s = utf8.len(text_string)
			local skill_string = mul_to_procent_string(skill_bonus)
			text_string = text_string .. skill_string

			table.insert(range_colors, {
				s,
				utf8.len(text_string),
				tweak_data.screen_colors.skill_color
			})

			got_heat_text = true
		end

		local infamy_bonus = managers.player:get_infamy_exp_multiplier()
		infamy_bonus = infamy_bonus - 1

		if infamy_bonus > 0 then
			local s = utf8.len(text_string)
			local infamy_string = mul_to_procent_string(infamy_bonus)
			text_string = text_string .. infamy_string

			table.insert(range_colors, {
				s,
				utf8.len(text_string),
				tweak_data.lootdrop.global_values.infamy.color
			})

			got_heat_text = true
		end

		local limited_bonus = managers.player:get_limited_exp_multiplier(data.job_id, data.level_id)
		limited_bonus = limited_bonus - 1

		if limited_bonus > 0 then
			local s = utf8.len(text_string)
			local limited_string = mul_to_procent_string(limited_bonus)
			text_string = text_string .. limited_string

			table.insert(range_colors, {
				s,
				utf8.len(text_string),
				tweak_data.screen_colors.button_stage_2
			})

			got_heat_text = true
		end
	end


	

	local job_heat = managers.job:get_job_heat(data.job_id) or 0
	local job_heat_mul = managers.job:heat_to_experience_multiplier(job_heat) - 1



	-- STARS AND HEAT
	local star_size = 16
	local job_jc = tweak_data.narrative:job_data(data.job_id).jc
	if data.job_id then
		local star_full = "guis/textures/pd2/crimenet_star"
		local star_half = "guis/textures/pd2/crimenet_star_half"
		local star_skull = "guis/textures/pd2/crimenet_skull"
		local x = 0
		local y = 0
		
		
		local job_skulls = not not data.difficulty_id and data.difficulty_id-2 or 0 -- difficulty_id starts at 2 for normal
		local is_skull = job_skulls > 0
		local job_stars = is_skull and job_skulls or math.ceil(job_jc / 10) -- 
		local needs_half_star = not data.is_server and (job_jc - job_stars*10) ~= 0 or false
		
		
		for i = 1, job_stars do
			local skull_fin = i > 3 and star_skull.."_"..tostring(i) or star_skull -- N / H, VH, OV, (>3) M, DW, DS
			
			stars_panel:bitmap({
				texture = is_skull and skull_fin or (needs_half and i == needs_half_star) and star_half or star_full,
				h = star_size,
				w = star_size,
				layer = 0,
				x = x,
				y = y - 2,
				texture_rect = {
					0,
					0,
					star_size,
					star_size
				},
				alpha = 1,
				blend_mode = "normal",
				color = is_skull and tweak_data.screen_colors.risk or color
			})

			x = x + 11
			num_stars = num_stars + 1
		end


		local difficulty_string = managers.localization:to_upper_text(tweak_data.difficulty_name_ids[tweak_data.difficulties[data.difficulty_id]])

		difficulty_name:set_text(difficulty_string)
		difficulty_name:set_color(num_stars > 0 and tweak_data.screen_colors.risk or tweak_data.screen_colors.text)
		
		
		local heat_alpha = math.abs(job_heat) / 100
		local heat_size = 1
		local heat_color = managers.job:get_job_heat_color(data.job_id)
		heat_glow = self._pan_panel:bitmap({
			texture = "guis/textures/pd2/hot_cold_glow",
			blend_mode = "add",
			alpha = 0,
			layer = 11,
			w = 256 * heat_size,
			h = 256 * heat_size,
			color = heat_color
		})

		if job_heat_mul ~= 0 then
			local s = utf8.len(text_string)
			local heat_string = mul_to_procent_string(job_heat_mul)
			text_string = text_string .. heat_string

			table.insert(range_colors, {
				s,
				utf8.len(text_string),
				heat_color
			})

			got_heat = true
			got_heat_text = true

			heat_glow:set_alpha(heat_alpha)
		end
	end
	
	-- Apply plusminus xp text (Ghost bonus and Heat bonus)
	heat_name:set_text(text_string)

	for i, range in ipairs(range_colors) do
		if i == 1 then
			local s, e, c = unpack(range)

			heat_name:set_range_color(0, e, c)
		else
			heat_name:set_range_color(unpack(range))
		end
	end



	
	local job_tweak = tweak_data.narrative:job_data(data.job_id)
	
	
	local host_string = data.host_name or is_professional and managers.localization:to_upper_text("cn_menu_pro_job") or " "
	host_string = is_job_new and managers.localization:to_upper_text("menu_new") or host_string
	
	
	local job_string = data.job_id and managers.localization:to_upper_text(job_tweak.name_id) or data.level_name or "NO JOB"
	local contact_string = utf8.to_upper(data.job_id and managers.localization:text(tweak_data.narrative.contacts[job_tweak.contact].name_id)) or "BAIN"
	contact_string = contact_string .. ": "
	
	-- 'Day(s)' and Cash
	
	local info_string = (
		-- Level locked
		data.level_locked and
		managers.localization:to_upper_text(("bm_menu_level_req"), {level = job_jc}) or
		
		-- DLC locked
		data.dlc and dlc_unowned and
		managers.localization:to_upper_text(tweak_data.lootdrop.global_values[data.dlc].unlock_id) or
		
		-- Just day info
		managers.localization:to_upper_text("cn_menu_contract_short_" .. (job_days > 1 and "plural" or "singular"), {
			days = job_days,
			money = job_cash
		})
	)
	
	info_string = info_string .. (data.state_name and " / " .. data.state_name or "")

	if is_special then
		-- job_string = data.name_id and managers.localization:to_upper_text(data.name_id) or ""
		-- info_string = data.desc_id and managers.localization:to_upper_text(data.desc_id) or ""

		if is_crime_spree then
			job_string = data.name_id and managers.localization:to_upper_text(data.name_id) or "" -- copy
			if managers.crime_spree:in_progress() then
				info_string = "cn_crime_spree_help_continue"
			else
				info_string = "cn_crime_spree_help_start"
			end

			info_string = managers.localization:to_upper_text(info_string) or ""
		end
	end



	-- Loud/Stealth icons
	local job_plan_icon = nil
	
	if is_server and data.job_plan and data.job_plan ~= -1 then
		local texture = data.job_plan == 1 and "guis/textures/pd2/cn_playstyle_loud" or "guis/textures/pd2/cn_playstyle_stealth"
		job_plan_icon = side_panel:bitmap({
			name = "job_plan_icon",
			h = 16,
			w = 16,
			alpha = 1,
			blend_mode = "normal",
			y = 0,
			x = 0,
			layer = 0,
			texture = texture,
			color = Color.white
		})
	end



	
	local host_name = side_panel:text({
		name = "host_name",
		vertical = "center",
		blend_mode = "add",
		text = host_string,
		font = tweak_data.menu.pd2_tiny_font,
		font_size = tweak_data.menu.pd2_tiny_font_size,
		color = color_secondary
	})
	
	local job_name = side_panel:text({
		name = "job_name",
		vertical = "center",
		blend_mode = "normal",
		layer = 0,
		text = job_string,
		font = tweak_data.menu.pd2_tiny_font,
		font_size = tweak_data.menu.pd2_tiny_font_size,
		color = color
	})
	
	local contact_name = side_panel:text({
		name = "contact_name",
		vertical = "center",
		blend_mode = "normal",
		layer = 0,
		text = contact_string,
		font = tweak_data.menu.pd2_tiny_font,
		font_size = tweak_data.menu.pd2_tiny_font_size,
		color = color
	})
	
	local info_name = side_panel:text({
		name = "info_name",
		vertical = "center",
		blend_mode = "normal",
		layer = 0,
		text = info_string,
		font = tweak_data.menu.pd2_tiny_font,
		font_size = tweak_data.menu.pd2_tiny_font_size,
		color = color
	})


	if data.mutators then
		job_name:set_color(mutator_text_color)
		contact_name:set_color(mutator_text_color)
		info_name:set_color(mutator_text_color)
	end

	
	if is_crime_spree or data.is_crime_spree then
		job_name:set_color(tweak_data.screen_colors.crime_spree_risk)
		contact_name:set_color(tweak_data.screen_colors.crime_spree_risk)
		info_name:set_color(tweak_data.screen_colors.crime_spree_risk)

		if is_crime_spree then
			stars_panel:text({
				name = "spree_level",
				vertical = "center",
				blend_mode = "normal",
				layer = 0,
				text = managers.localization:to_upper_text("menu_cs_level", {
					level = managers.experience:cash_string(managers.crime_spree:spree_level(), "")
				}),
				font = tweak_data.menu.pd2_tiny_font,
				font_size = tweak_data.menu.pd2_tiny_font_size,
				color = tweak_data.screen_colors.crime_spree_risk
			})
		end
	end
	
	
	-- if skirmish make or ogrange
	if data.is_skirmish then
		contact_name:set_color(tweak_data.screen_colors.skirmish_color)
		job_name:set_color(tweak_data.screen_colors.skirmish_color)
	end


	stars_panel:set_w(star_size * math.min(11, #stars_panel:children()))
	stars_panel:set_h(star_size)
	
	
	-- Job popin glow ring // attempting to remove this requires changing other functions.
	local focus
	focus = self._pan_panel:bitmap({
		texture = "guis/textures/crimenet_map_circle",
		name = "focus",
		blend_mode = "add",
		layer = 10,
		-- color = color:with_alpha(0.6)
		color = color:with_alpha(0.0)
	})
	
	--
	local jpi_x = job_plan_icon and job_plan_icon:right() + 2 or 0
	local _, _, w, h = host_name:text_rect()

	host_name:set_size(w, h)
	host_name:set_position(jpi_x, 0)
	-- setting Y position here has an offset effect on other parts
	
	
	--
	local _, _, w, h = job_name:text_rect()

	job_name:set_size(w, h)
	job_name:set_position(0, host_name:bottom() - 2)

	
	--
	local _, _, w, h = contact_name:text_rect()

	contact_name:set_size(w, h)
	contact_name:set_top(job_name:top())
	contact_name:set_right(0)

	--
	local _, _, w, h = info_name:text_rect()

	info_name:set_size(w, h - 3)
	info_name:set_top(contact_name:bottom() - 3)
	info_name:set_right(0)

	--
	local _, _, w, h = difficulty_name:text_rect()

	-- difficulty_name:set_size(w, h)
	difficulty_name:set_size(w, (difficulty_name:text() ~= " ") and h or 6) -- diff isnt used here
	difficulty_name:set_top(info_name:bottom() - 3)
	difficulty_name:set_right(0)

	--
	if one_down_active then
		local _, _, w, h = one_down_label:text_rect()

		one_down_label:set_size(w, h - 4)
		one_down_label:set_top(difficulty_name and difficulty_name:bottom() - 3 or info_name:bottom() - 3)
		one_down_label:set_right(0)
	end

	--
	local _, _, w, h = heat_name:text_rect()

	heat_name:set_size(w, h - 4)
	
	
	heat_name:set_top(one_down_active and one_down_label:bottom() + (h/2) - 3 or difficulty_name and difficulty_name:bottom() + (h/2) - 3 or contact_name:bottom())
	heat_name:set_right(0)

	if not got_heat_text then
		heat_name:set_text(" ")
		heat_name:set_w(1)
		heat_name:set_position(0, host_name:bottom() - 3)
	end


--[[
	-- SPECIAL
	if is_special then
		contact_name:set_text(" ")
		contact_name:set_size(0, 0)
		contact_name:set_position(0, host_name:bottom())
		difficulty_name:set_text(" ")
		difficulty_name:set_w(0, 0)
		difficulty_name:set_position(0, host_name:bottom())
		heat_name:set_text(" ")
		heat_name:set_w(0, 0)
		heat_name:set_position(0, host_name:bottom())
	
	-- CRIME SPREE
	elseif data.is_crime_spree then
		local text = ""

		if tweak_data:server_state_to_index("in_lobby") < data.state then
			local mission_data = managers.crime_spree:get_mission(data.crime_spree_mission)

			if mission_data then
				local tweak = tweak_data.levels[mission_data.level.level_id]
				text = managers.localization:text(tweak and tweak.name_id or "No level")
			else
				text = "No mission ID"
			end
		else
			text = managers.localization:text("menu_lobby_server_state_in_lobby")
		end

		job_name:set_text(utf8.to_upper(text))

		local _, _, w, h = job_name:text_rect()

		job_name:set_size(w, h)
		job_name:set_position(0, host_name:bottom())
		contact_name:set_text(" ")
		contact_name:set_w(0, 0)
		contact_name:set_position(0, host_name:bottom())
		info_name:set_text(" ")
		info_name:set_size(0, 0)
		info_name:set_position(0, host_name:bottom())
		difficulty_name:set_text(" ")
		difficulty_name:set_w(0, 0)
		difficulty_name:set_position(0, host_name:bottom())
		heat_name:set_text(" ")
		heat_name:set_w(0, 0)
		heat_name:set_position(0, host_name:bottom())
	
	-- SKIRMISH
	elseif data.is_skirmish then
		local is_weekly = data.skirmish == SkirmishManager.LOBBY_WEEKLY
		local text = managers.localization:text(is_weekly and "menu_weekly_skirmish" or "menu_skirmish") .. ": "

		contact_name:set_text(utf8.to_upper(text))

		local _, _, w, h = contact_name:text_rect()

		contact_name:set_size(w, h)
		contact_name:set_top(job_name:top())
		contact_name:set_right(0)
		info_name:set_text(" ")
		info_name:set_size(0, 0)
		info_name:set_position(0, host_name:bottom())
		difficulty_name:set_text(" ")
		difficulty_name:set_w(0, 0)
		difficulty_name:set_position(0, host_name:bottom())
		heat_name:set_text(" ")
		heat_name:set_w(0, 0)
		heat_name:set_position(0, host_name:bottom())
	
	-- NO JOB?
	elseif not got_job then
		job_name:set_text(data.state_name or managers.localization:to_upper_text("menu_lobby_server_state_in_lobby"))

		local _, _, w, h = job_name:text_rect()

		job_name:set_size(w, h)
		job_name:set_position(0, host_name:bottom())
		contact_name:set_text(" ")
		contact_name:set_w(0, 0)
		contact_name:set_position(0, host_name:bottom())
		info_name:set_text(" ")
		info_name:set_size(0, 0)
		info_name:set_position(0, host_name:bottom())
		difficulty_name:set_text(" ")
		difficulty_name:set_w(0, 0)
		difficulty_name:set_position(0, host_name:bottom())
		heat_name:set_text(" ")
		heat_name:set_w(0, 0)
		heat_name:set_position(0, host_name:bottom())
	end
	]]--

	stars_panel:set_position(0, job_name:bottom())
	side_panel:set_h(math.round(host_name:h() + job_name:h() + stars_panel:h()))
	side_panel:set_w(300)

	self._num_layer_jobs = (self._num_layer_jobs + 1) % 1
	
	
	-- Oversize main marker panel
	local marker_panel_bg = self._pan_panel:panel({
		w = marker_panel_size_x*2,
		h = marker_panel_size_y*2,
		alpha = 1,
		layer = 11 + self._num_layer_jobs * 3
	})
	
	
	-- Whole main marker panel
	local marker_panel = self._pan_panel:panel({
		w = marker_panel_size_x,
		h = marker_panel_size_y,
		alpha = 0,
		layer = 12 + self._num_layer_jobs * 3
	})
	
	
	-- Selection Hitbox
	local select_panel = marker_panel:panel({
		name = "select_panel",
		w = marker_panel_size_x,
		h = marker_panel_size_y
	})
	
	
	-- BG Glows
	local glow_panel = self._pan_panel:panel({
		w = 960,
		alpha = 0,
		h = 192,
		layer = 10
	})
	--
	local glow_center = glow_panel:bitmap({
		texture = "guis/textures/pd2/crimenet_marker_glow",
		name = "glow_center",
		h = 192,
		blend_mode = "add",
		w = 192,
		alpha = 0.55,
		color = data.pulse_color or color_secondary
	})
	glow_center:set_center(glow_panel:w() / 2, glow_panel:h() / 2)
	--
	local glow_stretch = glow_panel:bitmap({
		texture = "guis/textures/pd2/crimenet_marker_glow",
		name = "glow_stretch",
		h = 75,
		blend_mode = "add",
		w = 960,
		alpha = 0.55,
		color = data.pulse_color or color_secondary
	})
	glow_stretch:set_center(glow_panel:w() / 2, glow_panel:h() / 2)
	--
	local glow_center_dark = glow_panel:bitmap({
		texture = "guis/textures/pd2/crimenet_marker_glow",
		name = "glow_center_dark",
		h = 175,
		blend_mode = "normal",
		w = 175,
		alpha = 0.7,
		layer = -1,
		color = Color.black
	})
	glow_center_dark:set_center(glow_panel:w() / 2, glow_panel:h() / 2)
	--
	local glow_stretch_dark = glow_panel:bitmap({
		texture = "guis/textures/pd2/crimenet_marker_glow",
		name = "glow_stretch_dark",
		h = 75,
		blend_mode = "normal",
		w = 990,
		alpha = 0.75,
		layer = -1,
		color = Color.black
	})
	glow_stretch_dark:set_center(glow_panel:w() / 2, glow_panel:h() / 2)
	
	
	-- JOB ICON
	-- texture uses data.icon ID, otherwise uses its job ID icon
	
	local pd2_cn_marker = "guis/textures/pd2/crimenet_marker_"
	local marker_dot = marker_panel:bitmap({
		name = "marker_dot",
		texture = pd2_cn_marker.."contract"..(is_server and "_server" or ""),
		texture_rect = {0,0,96,64},
		w = 48,
		h = 32,
		-- x = marker_panel_margin_x,
		-- y = marker_panel_margin_y,
		layer = 1,
		-- alpha = 0.0,
		color = data.marker_dot_color or color
	})
	
	-- INNER MARKER ICON
	local icon_offline = not is_server and CrimeNetAdvanced.Options:GetValue("cnmap_job_icon_offline")
	local icon_online = is_server and CrimeNetAdvanced.Options:GetValue("cnmap_job_icon_online")
	if icon_offline or icon_online then
		local icon_steam = CrimeNetAdvanced.Options:GetValue("cnmap_job_icon_steam")
		local cn_final_icon_atlas
		
		if icon_steam and data.host_id then
			Steam:friend_avatar(1, tostring(data.host_id or 1), function(texture)
				cn_final_icon_atlas = {texture = texture}
			end)
		else
			-- trimming for overkill reasons
			cn_final_icon_atlas = (not not data.icon) and deep_clone(data.icon) or deep_clone(CrimeNetGui._missing_job_icon)
			cn_final_icon_atlas.texture_rect[1] = cn_final_icon_atlas.texture_rect[1] + 3
			cn_final_icon_atlas.texture_rect[2] = cn_final_icon_atlas.texture_rect[2] + 3
			cn_final_icon_atlas.texture_rect[3] = cn_final_icon_atlas.texture_rect[3] - 6
			cn_final_icon_atlas.texture_rect[4] = 58
		end
		
		if cn_final_icon_atlas and cn_final_icon_atlas.texture then
			local marker_dot_icon = marker_panel:bitmap({
				name = "marker_dot_icon",
				texture = cn_final_icon_atlas.texture,
				texture_rect = cn_final_icon_atlas.texture_rect,
				w = 42,
				h = 30,
				x = 3,
				y = 1,
				layer = -1,
				color = data.marker_dot_color or color
			})
		end
	end
	
	
	-- OUTLINE
	if is_professional or data.mutators or dlc_unowned or is_job_new then
		-- local outline_type = (not not data.mutators) and "mutator" or (dlc_unowned) and "dlc" or "pro"
		local outline_type = (not not data.mutators) and "mutator" or "normal"
		local outline_tex = pd2_cn_marker.. outline_type .."_outline"
		local marker_outline = marker_panel_bg:bitmap({
			name = "marker_outline",
			texture = outline_tex,
			texture_rect = {0,0,96,64},
			w = 96,
			h = 64,
			rotation = 0,
			alpha = 0.75,
			blend_mode = "add",
			layer = 0
		})
		
		marker_outline:set_color(color_secondary)
		
		marker_outline:set_center(marker_panel_bg:w() / 2, marker_panel_bg:h() / 2)
	end


	if data.mutators then
		marker_dot:set_color(mutator_color)
	end


	if data.is_crime_spree then
		marker_dot:set_color(tweak_data.screen_colors.crime_spree_risk)
	end


	if data.is_skirmish then
		marker_dot:set_color(tweak_data.screen_colors.skirmish_color)
	end



	
	local timer_rect, peers_panel = nil
	local icon_panel = self._pan_panel:panel({
		alpha = 1,
		w = 18,
		h = 64,
		layer = 26
	})
	
	if not is_unlocked then icon_panel:set_visible(false) end
	
	-- each detail icon gets offset after being applied
	local next_icon_right_off = 12
	local next_icon_right = 16
	local side_icons_top = 0

	for child in ipairs(icon_panel:children()) do
		side_icons_top = math.max(side_icons_top, child:bottom())
	end
	
	-- Recommended order: Ghost, OneDown, XMas

	-- Stealthable job icon
	if data.job_id and managers.job:is_job_ghostable(data.job_id) then
		local ghost_icon = icon_panel:bitmap({
			texture = "guis/textures/pd2/cn_minighost",
			name = "ghost_icon",
			blend_mode = "add",
			color = tweak_data.screen_colors.ghost_color
		})

		ghost_icon:set_top(side_icons_top)
		ghost_icon:set_right(next_icon_right)

		next_icon_right = next_icon_right - next_icon_right_off
	end

	-- 1 (One) Down mode icon
	if one_down_active then
		local one_down_icon = icon_panel:bitmap({
			blend_mode = "add",
			name = "one_down_icon",
			texture = "guis/textures/pd2/cn_mini_onedown",
			rotation = 360,
			color = tweak_data.screen_colors.one_down
		})

		one_down_icon:set_top(side_icons_top)
		one_down_icon:set_right(next_icon_right)

		next_icon_right = next_icon_right - next_icon_right_off
	end
	
	-- xmas values are completely nuked now, this's for testing
	local christmas_active = false
	if christmas_active then
		local xmas_icon = icon_panel:bitmap({
			blend_mode = "add",
			name = "xmas_icon",
			texture = "guis/textures/pd2/cn_mini_xmas",
			rotation = 360,
			color = Color.green
		})

		xmas_icon:set_top(side_icons_top)
		xmas_icon:set_right(next_icon_right)

		next_icon_right = next_icon_right - next_icon_right_off
	end


	-- unused in static jobs
	if is_server then
		peers_panel = self._pan_panel:panel({
			alpha = 0,
			h = 16,
			visible = true,
			w = 32,
			layer = 11 + self._num_layer_jobs * 3
		})
		local cx = 0
		local cy = 0

		for i = 1, 4 do
			cx = 8 * (i - 1)
			cy = 6
			local slot_taken = i <= data.num_plrs
			local player_marker = peers_panel:bitmap({
				-- texture = "guis/textures/pd2/crimenet_marker_peerflag",
				texture = "guis/textures/pd2/crimenet_peerflag",
				h = 8,
				w = 8,
				texture_rect = {slot_taken and 8 or 0,0,8,8},
				blend_mode = "normal",
				layer = 2,
				name = tostring(i),
				color = color,
				visible = true
			})

			player_marker:set_position(cx, cy)

			if data.mutators then
				player_marker:set_color(mutator_color)
			end

			if data.is_crime_spree then
				player_marker:set_color(tweak_data.screen_colors.crime_spree_risk)
			end

			if data.is_skirmish then
				player_marker:set_color(tweak_data.screen_colors.skirmish_color)
			end
		end

		local kick_none_icon = icon_panel:bitmap({
			texture = "guis/textures/pd2/cn_kick_marker",
			name = "kick_none_icon",
			blend_mode = "add",
			alpha = 0
		})
		local kick_vote_icon = icon_panel:bitmap({
			texture = "guis/textures/pd2/cn_votekick_marker",
			name = "kick_vote_icon",
			blend_mode = "add",
			alpha = 0
		})
		local y = 0

		for i = 1, #icon_panel:children() - 1 do
			y = math.max(y, icon_panel:children()[i]:bottom())
		end

		kick_none_icon:set_y(y)
		kick_vote_icon:set_y(y)
	
	elseif not is_special then -- Create timer
		timer_rect = marker_panel:bitmap({
			texture = "guis/textures/pd2/crimenet_timer",
			name = "timer_rect",
			h = 32,
			x = 1,
			w = 32,
			y = 2,
			render_template = "VertexColorTexturedRadial",
			layer = 2,
			color = Color.white
		})

		timer_rect:set_texture_rect(32, 0, -32, 32)
	end



	
	marker_panel:set_center(x * self._zoom, y * self._zoom)
	if focus then focus:set_center(marker_panel:center()) end
	marker_panel_bg:set_world_center(marker_panel:child("select_panel"):world_center())
	glow_panel:set_world_center(marker_panel:child("select_panel"):world_center())

	if heat_glow then
		heat_glow:set_world_center(marker_panel:child("select_panel"):world_center())
	end

	local num_containers = managers.job:get_num_containers()
	local middle_container = math.ceil(num_containers / 2)
	local job_container_index = managers.job:get_job_container_index(data.job_id) or middle_container
	local diff_containers = job_container_index - middle_container

	if diff_containers == 0 then
		if job_heat_mul < 0 then
			diff_containers = -1
		elseif job_heat_mul > 0 then
			diff_containers = 1
		end
	end

	local container_panel = nil

	if diff_containers ~= 0 and job_heat_mul ~= 0 then
		container_panel = self._pan_panel:panel({
			alpha = 0,
			layer = 11 + self._num_layer_jobs * 3
		})

		container_panel:set_w(math.abs(num_containers - middle_container) * 10 + 6)
		container_panel:set_h(8)
		container_panel:set_center_x(marker_panel:center_x())
		container_panel:set_bottom(marker_panel:top())
		container_panel:set_x(math.round(container_panel:x()))

		local texture = "guis/textures/pd2/blackmarket/stat_plusminus"
		local texture_rect = diff_containers > 0 and {
			0,
			0,
			8,
			8
		} or {
			8,
			0,
			8,
			8
		}

		for i = 1, math.abs(diff_containers) do
			container_panel:bitmap({
				texture = texture,
				texture_rect = texture_rect,
				x = (i - 1) * 10 + 3
			})
		end
	end

	-- local text_on_right = x < self._map_size_w - 200
	local text_on_right = true

	side_panel:set_left(marker_panel:right())

	-- DOES NOT WORK AS A SOLUTION TO MARGIN ISSUES
	-- side_panel:set_x(side_panel:x() - 16)
	-- side_panel:set_y(side_panel:y() + 16)

	side_panel:set_top(marker_panel:top() - job_name:top() + 1)

	if icon_panel then
		if text_on_right then
			icon_panel:set_right(marker_panel:left() + 2)
		else
			icon_panel:set_left(marker_panel:right() - 2)
		end

		icon_panel:set_top(math.round(marker_panel:top() + 1))
	end

	if peers_panel then
		peers_panel:set_center_x(marker_panel:center_x())
		peers_panel:set_center_y(marker_panel:center_y() - 16)
	end

	
	-- Crimenet voiceline callouts
	local callout = nil

	if is_unlocked and narrative_data and narrative_data.crimenet_callouts and #narrative_data.crimenet_callouts > 0 then
		local variant = math.random(#narrative_data.crimenet_callouts)
		callout = narrative_data.crimenet_callouts[variant]
	end

	if location then
		location[3] = true
	end
	
	-- forced jobs dont need this
	-- managers.menu:post_event("job_appear")
	
	local job = {
		room_id = data.room_id,
		info = data.info,
		job_id = data.job_id,
		host_id = data.host_id,
		level_id = level_id,
		level_data = level_data,
		marker_panel = marker_panel,
		marker_panel_bg = marker_panel_bg,
		peers_panel = peers_panel,
		kick_option = data.kick_option,
		job_plan = data.job_plan,
		container_panel = container_panel,
		is_friend = data.is_friend,
		marker_dot = marker_dot,
		timer_rect = timer_rect,
		side_panel = side_panel,
		icon_panel = icon_panel,
		focus = focus,
		difficulty = data.difficulty or tweak_data.difficulties[2],
		difficulty_id = data.difficulty_id or 2,
		one_down = data.one_down,
		num_plrs = data.num_plrs,
		job_x = x,
		job_y = y,
		state = data.state,
		layer = 11 + self._num_layer_jobs * 3,
		glow_panel = glow_panel,
		callout = callout,
		text_on_right = text_on_right,
		location = location,
		heat_glow = heat_glow,
		mutators = data.mutators,
		is_crime_spree = data.crime_spree and data.crime_spree >= 0,
		crime_spree = data.crime_spree,
		crime_spree_mission = data.crime_spree_mission,
		color_lerp = data.color_lerp,
		server_data = data,
		mods = data.mods,
		is_skirmish = data.skirmish and data.skirmish > 0,
		skirmish = data.skirmish,
		skirmish_wave = data.skirmish_wave,
		skirmish_weekly_modifiers = data.skirmish_weekly_modifiers,
		dlc_unowned = dlc_unowned,
		is_unlocked = is_unlocked
	}


	if is_crime_spree or data.is_crime_spree then
		stars_panel:set_visible(false)

		local spree_panel = side_panel:panel({
			visible = true,
			name = "spree_panel",
			layer = -1,
			h = tweak_data.menu.pd2_tiny_font_size
		})

		spree_panel:set_bottom(side_panel:h())

		local level = is_crime_spree and managers.crime_spree:spree_level() or tonumber(data.crime_spree)

		if level >= 0 then
			local spree_level = spree_panel:text({
				halign = "left",
				vertical = "center",
				layer = 1,
				align = "left",
				y = 0,
				x = 0,
				valign = "center",
				text = managers.experience:cash_string(level or 0, "") .. managers.localization:get_default_macro("BTN_SPREE_TICKET"),
				color = tweak_data.screen_colors.crime_spree_risk,
				font = tweak_data.menu.pd2_tiny_font,
				font_size = tweak_data.menu.pd2_tiny_font_size
			})
		end
	end
	
	
	if data.is_skirmish then
		stars_panel:set_visible(false)

		local skirmish_panel = side_panel:panel({
			visible = true,
			name = "skirmish_panel",
			layer = -1,
			h = tweak_data.menu.pd2_tiny_font_size
		})

		skirmish_panel:set_bottom(side_panel:h())

		local wave = data.skirmish_wave
		local text = nil

		if data.state == tweak_data:server_state_to_index("in_game") then
			text = managers.localization:to_upper_text("menu_skirmish_wave_number", {
				wave = wave
			})
		else
			text = managers.localization:to_upper_text("menu_lobby_server_state_" .. tweak_data:index_to_server_state(data.state))
		end

		local skirmish_wave = skirmish_panel:text({
			layer = 1,
			vertical = "center",
			blend_mode = "add",
			align = "left",
			halign = "left",
			valign = "center",
			text = text,
			color = tweak_data.screen_colors.skirmish_color,
			font = tweak_data.menu.pd2_tiny_font,
			font_size = tweak_data.menu.pd2_tiny_font_size
		})
	end
	
	self:update_job_gui(job, 3)
	
	return job
end


--
function CrimeNetGui:check_job_pressed(x, y)

	-- jank unfinished coord thing
	if CrimeNetGui._debug_cn_drawing then
		
		local realx = (x / 720) * 2048
		local realy = (y / 1280) * 1024
		
		log("PRESSED " .. tostring(x) .. " " .. tostring(y))
		
		self._temp_drawing = self._temp_drawing or {{},{}}
		
		self._temp_drawing[1][#self._temp_drawing[1]+1] = 2048-x
		self._temp_drawing[2][#self._temp_drawing[2]+1] = y
		
		_G.SaveTable( self._temp_drawing, "cn_map_drawing.txt" )
		
	end
	
	for id, job in pairs(self._jobs) do
		if job.mouse_over == 1 then
			job.expanded = not job.expanded
			local job_data = tweak_data.narrative:job_data(job.job_id)
			local is_professional = job_data.professional or false
			
			-- Hard set data table
			local broker_costs = not job.server
			local data = {
				-- customize_difficulty = broker_costs,		--allow diff settings
				customize_contract = broker_costs,			--allow diff settings at a cost
				difficulty = not not job.difficulty and job.difficulty or is_professional and "hard" or "normal",
				difficulty_id = not not job.difficulty_id and job.difficulty_id or is_professional and 3 or 2,
				one_down = job.one_down or false,
				job_id = job.job_id,
				level_id = job.level_id,
				id = id,
				room_id = job.room_id,
				server = job.server or false,
				num_plrs = job.num_plrs or 0,
				state = job.state,
				host_name = job.host_name,
				host_id = job.host_id,
				special_node = job.special_node,
				dlc = job.dlc,
				contract_visuals = job_data and job_data.contract_visuals,
				info = job.info,
				mutators = job.mutators,
				is_crime_spree = job.crime_spree and job.crime_spree >= 0,
				crime_spree = job.crime_spree,
				crime_spree_mission = job.crime_spree_mission,
				server_data = job.server_data,
				mods = job.mods,
				skirmish = job.skirmish,
				skirmish_wave = job.skirmish_wave,
				skirmish_weekly_modifiers = job.skirmish_weekly_modifiers
			}
			
			-- DLC check if owned
			if not data.dlc or managers.dlc:is_dlc_unlocked(data.dlc) then
				local node = job.special_node

				if not node then
					if Global.game_settings.single_player then
						-- log("crimenet_contract_singleplayer")
						node = "crimenet_contract_singleplayer"
					
					elseif job.server then
						-- log("crimenet_contract_join")
						node = "crimenet_contract_join"

						if job.is_crime_spree then
							-- log("crimenet_contract_crime_spree_join")
							node = "crimenet_contract_crime_spree_join"
						end

						if job.is_skirmish then
							-- log("skirmish_contract_join")
							node = "skirmish_contract_join"
						end
					else
						-- log("crimenet_contract_host")
						node = "crimenet_contract_host"
					end
				end
				
				-- If level locked dont open
				if job.is_unlocked then
					managers.menu:open_node(node, {data})
				else
					managers.menu_component:post_event("menu_error")
				end
				
			
			-- Im not expecting this mod to get on consoles and 'is_win32' wasnt working so its this now
			elseif true then
				local dlc_data = Global.dlc_manager.all_dlc_data[data.dlc]
				local app_id = dlc_data and dlc_data.app_id

				if app_id and SystemInfo:distribution() == Idstring("STEAM") then
					Steam:overlay_activate("store", app_id)
				end
			end
			
			if job.expanded then
				for id2, job2 in pairs(self._jobs) do
					if job2 ~= job then
						job2.expanded = false
					end
				end
			end

			return true
		end
	end
end
