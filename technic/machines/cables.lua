
technic.cables = {}


function technic.register_cable(tier, size)
	local tier_name = technic.tiers[tier].description
	local ltier = string.lower(tier)

	for x1 = 0, 1 do
	for x2 = 0, 1 do
	for y1 = 0, 1 do
	for y2 = 0, 1 do
	for z1 = 0, 1 do
	for z2 = 0, 1 do
		local id = tostring(x1)..tostring(x2)..tostring(y1)..tostring(y2)..tostring(z1)..tostring(z2)

		technic.cables["technic:"..ltier.."_cable_"..id] = tier

		local groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2}
		if id ~= "000000" then
			groups.not_in_creative_inventory = 1
		end

		minetest.register_node("technic:"..ltier.."_cable_"..id, {
			description = tier_name.." Cable",
			tiles = {"technic_"..ltier.."_cable.png"},
			inventory_image = "technic_"..ltier.."_cable_wield.png",
			wield_image = "technic_"..ltier.."_cable_wield.png",
			groups = groups,
			sounds = default.node_sound_wood_defaults(),
			drop = "technic:"..ltier.."_cable_000000",
			paramtype = "light",
			sunlight_propagates = true,
			drawtype = "nodebox",
			node_box = {
				type = "fixed",
				fixed = technic.gen_cable_nodebox(x1, y1, z1, x2, y2, z2, size)
			},
			after_place_node = function(pos)
				local name = minetest.get_node(pos).name
				technic.update_cables(pos, name, technic.get_cable_tier(name))
			end,
			after_dig_node = function(pos, oldnode)
				local tier = technic.get_cable_tier(oldnode.name)
				technic.update_cables(pos, oldnode.name, tier, true)
			end
		})
	end
	end
	end
	end
	end
	end
end


minetest.register_on_placenode(function(pos, node)
	for tier, machine_list in pairs(technic.machines) do
		for machine_name, _ in pairs(machine_list) do
			if node.name == machine_name then
				technic.update_cables(pos, node.name, tier, true)
			end
		end
	end
end)


minetest.register_on_dignode(function(pos, node)
	for tier, machine_list in pairs(technic.machines) do
		for machine_name, _ in pairs(machine_list) do
			if node.name == machine_name then
				technic.update_cables(pos, node.name, tier, true)
			end
		end
	end
end)


function technic.update_cables(pos, name, tier, no_set, secondrun)
	local link_positions = {
		{x=pos.x+1, y=pos.y,   z=pos.z},
		{x=pos.x-1, y=pos.y,   z=pos.z},
		{x=pos.x,   y=pos.y+1, z=pos.z},
		{x=pos.x,   y=pos.y-1, z=pos.z},
		{x=pos.x,   y=pos.y,   z=pos.z+1},
		{x=pos.x,   y=pos.y,   z=pos.z-1}}

	local links = {0, 0, 0, 0, 0, 0}

	for i, link_pos in pairs(link_positions) do
		local connect_type = technic.cables_should_connect(pos, link_pos, tier)
		if connect_type then
			links[i] = 1
			-- Have cables next to us update theirselves, but only once.
			-- (We don't want to update the entire network, or start an infinite loop of updates)
			if not secondrun and connect_type == "cable" then
				technic.update_cables(link_pos, name, tier, false, true)
			end
		end
	end
	-- We don't want to set ourselves if we have been removed or we are updating a machine
	if not no_set then
		hacky_swap_node(pos, "technic:"..string.lower(tier).."_cable_"..table.concat(links))

	end
end


function technic.is_tier_cable(name, tier)
	return technic.cables[name] and technic.cables[name] == tier
end


function technic.get_cable_tier(name)
	return technic.cables[name]
end


function technic.cables_should_connect(pos1, pos2, tier)
	local name = minetest.get_node(pos2).name

	if technic.is_tier_cable(name, tier) then
		return "cable"
	elseif technic.machines[tier][name] and
			vector.new(pos2) - vector.new(pos1) == vector.new(0, 1, 0) then
		return "machine"
	end
	return false
end



function technic.gen_cable_nodebox(x1, y1, z1, x2, y2, z2, size)
	-- Nodeboxes
	local box_center = {-size, -size, -size, size,  size, size}
	local box_y1 =     {-size, -size, -size, size,  0.5,  size} -- y+
	local box_x1 =     {-size, -size, -size, 0.5,   size, size} -- x+
	local box_z1 =     {-size, -size,  size, size,  size, 0.5}   -- z+
	local box_z2 =     {-size, -size, -0.5,  size,  size, size} -- z-
	local box_y2 =     {-size, -0.5,  -size, size,  size, size} -- y-
	local box_x2 =     {-0.5,  -size, -size, size,  size, size} -- x-

	local box = {box_center}
	if x1 == 1 then
		table.insert(box, box_x1)
	end
	if y1 == 1 then
		table.insert(box, box_y1)
	end
	if z1 == 1 then
		table.insert(box, box_z1)
	end
	if x2 == 1 then
		table.insert(box, box_x2)
	end
	if y2 == 1 then
		table.insert(box, box_y2)
	end
	if z2 == 1 then
		table.insert(box, box_z2)
	end
	return box
end

