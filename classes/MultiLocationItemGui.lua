MultiLocationItemGui = MultiLocationItemGui or class(MultiProfileItemGui)



function MultiLocationItemGui:hide()
	self._panel:hide()
	self._enabled = false
end


function MultiLocationItemGui:show()
	self._panel:show()
	self._enabled = true
end


function MultiLocationItemGui:init(ws, panel)
	self._current_name_index = 1
	self._enabled = true
	self._ws = ws
	local panel_w = self.profile_panel_w
	local panel_h = self.profile_panel_h

	if managers.menu:is_pc_controller() then
		panel_w = self.quick_panel_w + self.padding + self.profile_panel_w
		panel_h = math.max(self.quick_panel_h, self.profile_panel_h)
	end

	self._panel = self._panel or panel:panel({
		layer = 100,
		w = panel_w,
		h = panel_h
	})

	-- self._panel:set_bottom(panel:top() + self._panel:h() + 10)
	self._panel:set_bottom(panel:bottom() - 10)
	
	self._panel:set_center_x(panel:w() / 2)

	self._profile_panel = self._profile_panel or self._panel:panel({
		w = self.profile_panel_w,
		h = self.profile_panel_h
	})

	self._profile_panel:set_center_y(self._panel:h() / 2)
	self._profile_panel:set_top(math.round(self._profile_panel:top()))

	local box_panel_w = self._profile_panel:w()

	if managers.menu:is_pc_controller() then
		self._quick_select_panel = self._quick_select_panel or self._panel:panel({
			w = self.quick_panel_w,
			h = self.quick_panel_h
		})

		self._quick_select_panel:set_left(self._profile_panel:right() + self.padding)
		self._quick_select_panel:set_center_y(self._panel:h() / 2)
		self._quick_select_panel:set_top(math.round(self._quick_select_panel:top()))

		if not self._quick_select_panel_elements then
			local quick_select = self._quick_select_panel:bitmap({
				texture = "guis/textures/pd2/crimenet_globe",
				name = "quick_select",
				color = tweak_data.screen_colors.button_stage_3
			})
			
			quick_select:set_center(self._quick_select_panel:w() / 2, self._quick_select_panel:h() / 2)
		end

		box_panel_w = box_panel_w + self.quick_panel_w + self.padding
	end

	self._box_panel = self._panel:panel()

	self._box_panel:rect({
		alpha = 0.4,
		layer = -100,
		color = Color.black
	})

	self._box = BoxGuiObject:new(self._box_panel, {
		sides = {
			1,
			1,
			1,
			1
		}
	})
	self._caret = self._profile_panel:rect({
		blend_mode = "add",
		name = "caret",
		h = 0,
		y = 0,
		w = 0,
		x = 0,
		color = Color(0.1, 1, 1, 1)
	})
	
	local blue_object_parent = self._box_panel
	local blur_object = blue_object_parent:bitmap({
		texture = "guis/textures/test_blur_df",
		name = "locations_button_blur",
		render_template = "VertexColorTexturedBlur3D",
		layer = blue_object_parent:layer() - 1
	})
	blur_object:set_shape(blue_object_parent:shape())
	
	self._max_length = 15
	self._name_editing_enabled = true

	self:update()
end


function MultiLocationItemGui:update()
	if not self._enabled then return end
	
	local locations = tweak_data.narrative.cn_locations
	local name = self._current_name_index and locations[self._current_name_index] or locations[1]
	
	self._name_text = self._profile_panel:child("name")

	if alive(self._name_text) then
		self._profile_panel:remove(self._name_text)
	end
	
	local clean_name = string.gsub(utf8.to_upper(name), "_", " ")
	
	self._name_text = self._profile_panel:text({
		name = "name",
		vertical = "center",
		align = "center",
		text = clean_name,
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_medium_font_size,
		color = tweak_data.screen_colors.button_stage_3
	})
	local text_width = self._name_text:w()

	self._name_text:set_w(text_width * 0.8)
	self._name_text:set_left(text_width * 0.1)

	--
	local arrow_left = self._profile_panel:child("arrow_left")

	if not arrow_left then
		if managers.menu:is_pc_controller() and not managers.menu:is_steam_controller() then
			arrow_left = self._profile_panel:bitmap({
				texture = "guis/textures/menu_arrows",
				name = "arrow_left",
				texture_rect = {
					24,
					0,
					24,
					24
				},
				color = tweak_data.screen_colors.button_stage_3
			})
		else
			local BTN_TOP_L = managers.menu:is_steam_controller() and managers.localization:steam_btn("trigger_l") or managers.localization:get_default_macro("BTN_TOP_L")
			arrow_left = self._profile_panel:text({
				name = "arrow_left",
				h = 24,
				vertical = "center",
				w = 24,
				align = "center",
				text = BTN_TOP_L,
				color = tweak_data.screen_colors.button_stage_3,
				font = tweak_data.menu.pd2_small_font,
				font_size = tweak_data.menu.pd2_small_font_size
			})
		end
	end
	
	
	--
	local arrow_right = self._profile_panel:child("arrow_right")

	if not arrow_right then
		if managers.menu:is_pc_controller() and not managers.menu:is_steam_controller() then
			arrow_right = self._profile_panel:bitmap({
				texture = "guis/textures/menu_arrows",
				name = "arrow_right",
				size = 32,
				rotation = 180,
				texture_rect = {
					24,
					0,
					24,
					24
				},
				color = tweak_data.screen_colors.button_stage_3
			})
		else
			local BTN_TOP_R = managers.menu:is_steam_controller() and managers.localization:steam_btn("trigger_r") or managers.localization:get_default_macro("BTN_TOP_R")
			arrow_right = self._profile_panel:text({
				name = "arrow_right",
				h = 24,
				vertical = "center",
				w = 24,
				align = "center",
				text = BTN_TOP_R,
				color = tweak_data.screen_colors.button_stage_3,
				font = tweak_data.menu.pd2_small_font,
				font_size = tweak_data.menu.pd2_small_font_size
			})
		end
	end

	arrow_left:set_left(5)
	arrow_right:set_right(self._profile_panel:w() - 5)
	arrow_left:set_center_y(self._profile_panel:h() / 2)
	arrow_right:set_center_y(self._profile_panel:h() / 2)
	self:_update_caret()
end


function MultiLocationItemGui:mouse_moved(x, y)
	if not self._enabled then return end
	
	local function anim_func(o, large)
		local current_width = o:w()
		local current_height = o:h()
		local end_width = large and 32 or 24
		local end_height = end_width
		local cx, cy = o:center()

		over(0.2, function (p)
			o:set_size(math.lerp(current_width, end_width, p), math.lerp(current_height, end_height, p))
			o:set_center(cx, cy)
		end)
	end

	local pointer, used = nil
	self._arrow_selection = nil
	
	local arrow_left = self._profile_panel:child("arrow_left")

	if arrow_left then
		if arrow_left:inside(x, y) then
			if self._is_left_selected ~= true then
				arrow_left:set_color(tweak_data.screen_colors.button_stage_2)
				arrow_left:animate(anim_func, true)
				managers.menu_component:post_event("highlight")

				self._is_left_selected = true
			end

			self._arrow_selection = "left"
			pointer = "link"
			used = true
		elseif self._is_left_selected == true then
			arrow_left:set_color(tweak_data.screen_colors.button_stage_3)
			arrow_left:animate(anim_func, false)

			self._is_left_selected = false
		end
	end

	local arrow_right = self._profile_panel:child("arrow_right")

	if arrow_right then
		if arrow_right:inside(x, y) then
			if self._is_right_selected ~= true then
				arrow_right:set_color(tweak_data.screen_colors.button_stage_2)
				arrow_right:animate(anim_func, true)
				managers.menu_component:post_event("highlight")

				self._is_right_selected = true
			end

			self._arrow_selection = "right"
			pointer = "link"
			used = true
		elseif self._is_right_selected == true then
			arrow_right:set_color(tweak_data.screen_colors.button_stage_3)
			arrow_right:animate(anim_func, false)

			self._is_right_selected = false
		end
	end

	
	if alive(self._quick_select_panel) then
		local quick_select = self._quick_select_panel:child("quick_select")
		if self._quick_select_panel:inside(x, y) then
			if self._is_quick_selected ~= true then
				quick_select:set_color(tweak_data.screen_colors.button_stage_2)

				managers.menu_component:post_event("highlight")

				self._is_quick_selected = true
			end

			self._arrow_selection = "quick"
			pointer = "link"
			used = true
		elseif self._is_quick_selected == true then
			quick_select:set_color(tweak_data.screen_colors.button_stage_3)

			self._is_quick_selected = false
		end
	end

	if self._name_text:inside(x, y) then
		if not self._name_selection then
			self._name_text:set_color(tweak_data.screen_colors.button_stage_2)
			managers.menu_component:post_event("highlight")
		end

		self._name_selection = true
		pointer = "link"
		used = true
	elseif self._name_selection then
		self._name_text:set_color(tweak_data.screen_colors.button_stage_3)

		self._name_selection = false
	end

	return used, pointer
end


function MultiLocationItemGui:mouse_pressed(button, x, y)
	if not self._enabled then return end
	
	if button == Idstring("0") then
		if self:arrow_selection() == "left" then
			
			self:trigger_previous_location()
			managers.menu_component:post_event("menu_enter")

			return
		elseif self:arrow_selection() == "right" then
			
			self:trigger_next_location()
			managers.menu_component:post_event("menu_enter")

			return
		elseif self:arrow_selection() == "quick" or self._name_selection then
			managers.crimenet:open_quick_location_select()
			managers.menu_component:post_event("menu_enter")

			return
		end
	end
end


function MultiLocationItemGui:trigger() end


function MultiLocationItemGui:trigger_next_location()
	self._current_name_index = self._current_name_index - 1
	if self._current_name_index <= 0 then
		self._current_name_index = #tweak_data.narrative.cn_locations
	end
	self:update()
	managers.crimenet:set_crimenet_location(self._current_name_index)
end


function MultiLocationItemGui:trigger_previous_location()
	self._current_name_index = self._current_name_index + 1
	if self._current_name_index > #tweak_data.narrative.cn_locations then
		self._current_name_index = 1
	end
	self:update()
	managers.crimenet:set_crimenet_location(self._current_name_index)
end


function MultiLocationItemGui:set_location_index(idx)
	if idx > #tweak_data.narrative.cn_locations or idx < 1 then
		self._current_name_index = 1
	else
		self._current_name_index = idx
	end
	self:update()
end


function MultiLocationItemGui:recenter(panel, x)
	self._panel:set_center_x( (panel:w()/2) + (x/2) )
end

