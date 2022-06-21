-- Generic tweakdata goes in here.

tweak_data.screen_colors.brand_new = Color(255, 105, 254, 59) / 255
tweak_data.screen_colors.cn_locked = Color(0.5,1,1,1)
tweak_data.screen_colors.cn_locked_dark = Color(0,0,0,0)
tweak_data.screen_colors.cn_dlc_color_dark = deep_clone(tweak_data.screen_colors.dlc_color):with_alpha(0.5)

tweak_data.screen_colors.cn_map_color_default = Color(255, 255, 255, 255) / 255


-- tweak_data.crimenet_map.border_safe_rect / map edge safe zone
-- tweak_data.crimenet_map.icon_safe_rect / icon safe boundry
tweak_data.crimenet_map = {
	border_safe_rect = {160,160,260,160},
	safe_y = 18,
	safe_x_left = 18,
	safe_x_right = 90
}
