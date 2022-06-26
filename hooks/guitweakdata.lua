Hooks:PostHook(GuiTweakData, "init", "init_advanced", function(self, tweak_data)
	
	self.crime_net.job_vars.max_active_jobs = 16
	self.crime_net.job_vars.active_job_time = 20
	self.crime_net.job_vars.new_job_min_time = 100.5
	self.crime_net.job_vars.new_job_max_time = 102.0
	
	
	
	self._cn_x_start = 400
	self._cn_y_start = 200
	self._cn_x_next = 0
	self._cn_y_next = 0
	
	
	self.crime_net.special_contracts = {}
	self:build_missing_special_contracts(self, tweak_data)
	
	
	
	--
	self.crime_net.regions = {
		-- {
			-- {
				-- 1358,
				-- 1389,
				-- 1390,
				-- 1367,
				-- 1338,
				-- 1320,
				-- 1318
				
			-- },
			-- {
				-- 182,
				-- 200,
				-- 224,
				-- 247,
				-- 244,
				-- 222,
				-- 192
			-- },
			-- closed = true,
			-- text = {
				-- title_id = "cn_menu_foggy_bottom_title",
				-- x = 858,
				-- y = 704
			-- }
		-- }
	}
	
	-- map scale 
	local NEW_MAP_SCALE = 1
	for i, region in ipairs(self.crime_net.regions) do
		
		
		if NEW_MAP_SCALE ~= 1 then
			-- X
			if region[1] and type(region[1]) == "table" then
				local xarr = {}
				for _,v in ipairs(region[1]) do
					table.insert(xarr, v * NEW_MAP_SCALE)
				end
				self.crime_net.regions[i][1] = xarr
			end
			
			-- Y
			if region[2] and type(region[2]) == "table" then
				local yarr = {}
				for _,v in ipairs(region[2]) do
					table.insert(yarr, v * NEW_MAP_SCALE)
				end
				self.crime_net.regions[i][2] = yarr
			end
			
			-- TEXT X/Y
			if self.crime_net.regions[i].text then
				self.crime_net.regions[i].text.x = region.text.x * NEW_MAP_SCALE
				self.crime_net.regions[i].text.y = region.text.y * NEW_MAP_SCALE
			end
		end
		
		-- TEXT SubTitle
		if self.crime_net.regions[i].text then
			if not self.crime_net.regions[i].text.sub_id then
				local title = self.crime_net.regions[i].text.title_id
				self.crime_net.regions[i].text.sub_id = string.gsub(title, "title", "sub")
			end
		end
	end
	
end)

function GuiTweakData:build_missing_special_contracts(self, tweak_data)
	for id, data in pairs(tweak_data.narrative.jobs) do
		-- log("Checking... "..id)
		
		for _, special_contract in ipairs(self.crime_net.special_contracts) do
			if special_contract.id == id then goto continue end
		end
		
		local is_wrapped = tweak_data.narrative:is_wrapped_to_job(id)
		-- log("Wrapped "..tostring(is_wrapped))
		if is_wrapped then goto continue end
		
		local in_job_index = tweak_data.narrative:get_index_from_job_id(id) ~= 0
		-- log("JobIDX "..tostring(in_job_index))
		if not in_job_index then goto continue end
		
		local is_hidden = data.hidden or false
		-- log("JobHidden "..tostring(is_hidden))
		if is_hidden then goto continue end
		
		local narr_contact = tweak_data.narrative.contacts[data.contact]
		-- log("ConName "..narr_contact.name_id or "NIL")
		
		local has_contact = not not narr_contact
		-- log("HasCon "..tostring(has_contact))
		if not has_contact then goto continue end
		
		if has_contact then
			local contact_hidden = narr_contact.hidden or false
			-- log("Hidden "..tostring(contact_hidden))
			if contact_hidden then goto continue end
		end
		
		
		-- Temp, ignore non positionsed jobs
		if not tweak_data.narrative.jobs[id].cn_position then goto continue end
		
		
		local cn_x
		local cn_y
		
		if tweak_data.narrative.jobs[id].cn_position then
			cn_x = tweak_data.narrative.jobs[id].cn_position[1]
			cn_y = tweak_data.narrative.jobs[id].cn_position[2]
		else
			cn_x = self._cn_x_start + self._cn_x_next
			cn_y = self._cn_y_start + self._cn_y_next
			
			self._cn_x_next = self._cn_x_next + 180
			if self._cn_x_next > self._cn_x_start + 600 then
				self._cn_x_next = 0
				self._cn_y_next = self._cn_y_next + 40
			end
		end
		
		
		local special_contract = {
			job_id = id,
			id = "heist_"..id,
			
			level_requirement = data.jc or nil,
			dlc = data.dlc or nil,
			
			name_id = data.name_id or "heist_"..id,
			
			desc_id = narr_contact.name_id, -- needs a use
			
			icon = data.cn_icon_id or nil,
			
			x = cn_x,
			y = cn_y
		}
		
		table.insert(self.crime_net.special_contracts, special_contract)
		
		::continue::
	end
end



