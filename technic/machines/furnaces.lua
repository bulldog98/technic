
function technic.check_furnace_upgrades(meta)
	-- Get the names of the upgrades
	local inv = meta:get_inventory()
	local upg_item1
	local upg_item1_name = ""
	local upg_item2
	local upg_item2_name = ""
	local srcstack = inv:get_stack("upgrade1", 1)
	if srcstack then
		upg_item1 = srcstack:to_table()
	end
	srcstack = inv:get_stack("upgrade2", 1)
	if srcstack then
		upg_item2 = srcstack:to_table()
	end
	if upg_item1 then
		upg_item1_name = upg_item1.name
	end
	if upg_item2 then
		upg_item2_name = upg_item2.name
	end

	-- Save some power by installing battery upgrades. Fully upgraded makes this
	-- furnace use the same amount of power as the LV version
	local EU_saving_upgrade = 0
	if upg_item1_name == "technic:battery" then
		EU_saving_upgrade = EU_saving_upgrade + 1
	end
	if upg_item2_name == "technic:battery" then
		EU_saving_upgrade = EU_saving_upgrade + 1
	end

	-- Tube loading speed can be upgraded using control logic units
	local tube_speed_upgrade = 0
	if upg_item1_name == "technic:control_logic_unit" then
		tube_speed_upgrade = tube_speed_upgrade + 1
	end
	if upg_item2_name == "technic:control_logic_unit" then
		tube_speed_upgrade = tube_speed_upgrade + 1
	end

	return EU_saving_upgrade, tube_speed_upgrade
end


function technic.send_cooked_items(pos, x_velocity, z_velocity)
	-- Send items on their way in the pipe system.
	local meta = minetest.get_meta(pos) 
	local inv = meta:get_inventory()
	local i = 0
	for _, stack in ipairs(inv:get_list("dst")) do
		i = i + 1
		if stack then
			local item0 = stack:to_table()
			if item0 then 
				item0["count"] = "1"
				local item1 = tube_item({x=pos.x, y=pos.y, z=pos.z}, item0)
				item1:get_luaentity().start_pos = {x=pos.x, y=pos.y, z=pos.z}
				item1:setvelocity({x=x_velocity, y=0, z=z_velocity})
				item1:setacceleration({x=0, y=0, z=0})
				stack:take_item(1);
				inv:set_stack("dst", i, stack)
				return
			end
		end
	end
end


function technic.smelt_item(pos)
	local meta = minetest.get_meta(pos) 
	local inv = meta:get_inventory()
	meta:set_int("src_time", meta:get_int("src_time") + 3) -- Cooking time 3x faster
	local result = minetest.get_craft_result({method = "cooking", width = 1, items = inv:get_list("src")})
	dst_stack = {}
	--dst_stack["name"] = alloy_recipes[dst_index].dst_name
	--dst_stack["count"] = alloy_recipes[dst_index].dst_count

	if result and result.item and meta:get_int("src_time") >= result.time then
		meta:set_int("src_time", 0)
		-- check if there's room for output in "dst" list
		if inv:room_for_item("dst",result) then
			-- take stuff from "src" list
			srcstack = inv:get_stack("src", 1)
			srcstack:take_item()
			inv:set_stack("src", 1, srcstack)
			-- Put result in "dst" list
			inv:add_item("dst", result.item)
			return 1
		else
			return 0 -- done
		end
	end
	return 0 -- done
end

function technic.handle_furnace_pipeworks(pos, next_state, tube_speed_upgrade)
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local pos1={x=pos.x, y=pos.y, z=pos.z}
	local x_velocity = 0
	local z_velocity = 0

	-- Output is on the left side of the furnace
	if node.param2 == 3 then pos1.z = pos1.z - 1  z_velocity = -1 end
	if node.param2 == 2 then pos1.x = pos1.x - 1  x_velocity = -1 end
	if node.param2 == 1 then pos1.z = pos1.z + 1  z_velocity =  1 end
	if node.param2 == 0 then pos1.x = pos1.x + 1  x_velocity =  1 end

	local output_tube_connected = false
	local meta1 = minetest.get_meta(pos1) 
	if meta1:get_int("tubelike") == 1 then
		output_tube_connected = true
	end
	tube_time = meta:get_int("tube_time")
	tube_time = tube_time + tube_speed_upgrade
	if tube_time > 3 then
		tube_time = 0
		if output_tube_connected then
			technic.send_cooked_items(pos, x_velocity, z_velocity)
		end
	end
	meta:set_int("tube_time", tube_time)

	-- The machine shuts down if we have nothing to smelt and no tube is connected
	-- or if we have nothing to send with a tube connected.
	if (not output_tube_connected and inv:is_empty("src")) or
	   (    output_tube_connected and inv:is_empty("dst")) then
		next_state = 1
	end
	return next_state
end

