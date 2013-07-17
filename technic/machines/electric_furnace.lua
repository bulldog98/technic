
technic.electric_furnace_formspec =
	"invsize[8,10;]"..
	"list[current_name;src;3,1;1,1;]"..
	"list[current_name;dst;5,1;2,2;]"..
	"list[current_player;main;0,6;8,4;]"..
	"label[0,0;Electric Furnace]"..
	"list[current_name;upgrade1;1,4;1,1;]"..
	"list[current_name;upgrade2;2,4;1,1;]"..
	"label[1,5;Upgrade Slots]"

function technic.register_electric_furnace(tier)
local ltier = string.lower(tier)
local ndef = {
	description = tier.." Electric furnace",
	tiles = {"technic_"..ltier.."_electric_furnace_top.png",       "technic_"..ltier.."_electric_furnace_bottom.png",
	         "technic_"..ltier.."_electric_furnace_side_tube.png", "technic_"..ltier.."_electric_furnace_side_tube.png",
	         "technic_"..ltier.."_electric_furnace_side.png",      "technic_"..ltier.."_electric_furnace_front.png"},
	paramtype2 = "facedir",
	groups = {cracky=2, tubedevice=1, tubedevice_receiver=1},
	tube = {
		insert_object = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("src",stack)
		end,
		can_insert = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:room_for_item("src", stack)
		end,
	},
	technic = {
		tier = tier,
	},
	legacy_facedir_simple = true,
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local name = minetest.get_node(pos).name
		local tier = minetest.registered_nodes[name].technic.tier
		meta:set_string("infotext", tier.." Electric furnace")
		meta:set_int("tube_time",  0)
		meta:set_string("formspec", technic.electric_furnace_formspec)
		local inv = meta:get_inventory()
		inv:set_size("src", 1)
		inv:set_size("dst", 4)
		inv:set_size("upgrade1", 1)
		inv:set_size("upgrade2", 1)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		if not inv:is_empty("src") or not inv:is_empty("dst") or
		   not inv:is_empty("upgrade1") or not inv:is_empty("upgrade2") then
			minetest.chat_send_player(player:get_player_name(),
				"Machine cannot be removed because it is not empty");
			return false
		else
			return true
		end
	end,
}

minetest.register_node("technic:"..ltier.."_electric_furnace", ndef)
active_ndef = {
	description = tier.." Electric furnace",
	tiles = {"technic_"..ltier.."_electric_furnace_top.png",       "technic_"..ltier.."_electric_furnace_bottom.png",
	         "technic_"..ltier.."_electric_furnace_side_tube.png", "technic_"..ltier.."_electric_furnace_side_tube.png",
	         "technic_"..ltier.."_electric_furnace_side.png",      "technic_"..ltier.."_electric_furnace_front_active.png"},
	paramtype2 = "facedir",
	groups = {cracky=2, tubedevice=1, tubedevice_receiver=1, not_in_creative_inventory=1},
	light_source = 8,
	tube = {
		insert_object = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("src",stack)
		end,
		can_insert = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:room_for_item("src", stack)
		end,
	},
	technic = {
		tier = tier,
	},
	legacy_facedir_simple = true,
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local name = minetest.get_node(pos).name
		local tier = minetest.registered_nodes[name].technic.tier
		meta:set_string("infotext", tier.." Electric furnace")
		meta:set_int("tube_time",  0)
		meta:set_string("formspec", technic.electric_furnace_formspec)
		local inv = meta:get_inventory()
		inv:set_size("src", 1)
		inv:set_size("dst", 4)
		inv:set_size("upgrade1", 1)
		inv:set_size("upgrade2", 1)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		if not inv:is_empty("src") or not inv:is_empty("dst") or
		   not inv:is_empty("upgrade1") or not inv:is_empty("upgrade2") then
			minetest.chat_send_player(player:get_player_name(),
				"Machine cannot be removed because it is not empty");
			return false
		else
			return true
		end
	end,
	-- These three makes sure upgrades are not moved in or out while the furnace is active.
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if listname == "src" or listname == "dst" then
			return stack:get_stack_max()
		else
			return 0 -- Disallow the move
		end
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if listname == "src" or listname == "dst" then
			return stack:get_stack_max()
		else
			return 0 -- Disallow the move
		end
	end,
	allow_metadata_inventory_move = function(pos, from_list, to_list, to_list, to_index, count, player)
		return 0
	end,
}

minetest.register_node("technic:"..ltier.."_electric_furnace_active", active_ndef)


minetest.register_abm({
	nodenames = {"technic:"..ltier.."_electric_furnace", "technic:"..ltier.."_electric_furnace_active"},
	interval = 1,
	chance   = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local data         = minetest.registered_nodes[node.name].technic
		local meta         = minetest.env:get_meta(pos)
		local eu_input     = meta:get_int(data.tier.."_EU_input")
		local state        = meta:get_int("state")
		local next_state   = state

		-- Machine information
		local machine_name         = data.tier.." Electric Furnace"
		local machine_node         = "technic:"..string.lower(data.tier).."_electric_furnace"
		local machine_state_demand = {50, 2000, 1500, 1000}

		-- Setup meta data if it does not exist. state is used as an indicator of this
		if state == 0 then
			meta:set_int("state", 1)
			meta:set_int(data.tier.."_EU_demand", machine_state_demand[1])
			meta:set_int(data.tier.."_EU_input", 0)
			return
		end

		-- Power off automatically if no longer connected to a switching station
		technic.switching_station_timeout_count(pos, data.tier)

		-- Execute always logic
		-- CODE HERE --

		-- State machine
		if eu_input == 0 then
			-- Unpowered - go idle
			hacky_swap_node(pos, machine_node)
			meta:set_string("infotext", machine_name.." Unpowered")
			next_state = 1
		elseif eu_input == machine_state_demand[state] then
			-- Powered - do the state specific actions

			-- Check upgrade slots
			local EU_saving_upgrade, tube_speed_upgrade = technic.check_furnace_upgrades(meta)

			-- Handle pipeworks (consumes tube_speed_upgrade)
			next_state = technic.handle_furnace_pipeworks(pos, next_state, tube_speed_upgrade)

			if state == 1 then
				hacky_swap_node(pos, machine_node)
				meta:set_string("infotext", machine_name.." Idle")

				local meta = minetest.get_meta(pos) 
				local inv = meta:get_inventory()
				if not inv:is_empty("src") then
					local result = minetest.get_craft_result({method = "cooking", width = 1, items = inv:get_list("src")})
					if result then
						meta:set_string("infotext", machine_name.." Active")
						meta:set_int("src_time", 0)
						next_state = 2 + EU_saving_upgrade
						-- Next state is decided by the battery upgrade
						-- (state 2= 0 batteries, state 3 = 1 battery, 4 = 2 batteries)
					end
				end

			elseif state == 2 or state == 3 or state == 4 then
				hacky_swap_node(pos, machine_node.."_active")
				meta:set_string("infotext", machine_name.." Active")
				result = technic.smelt_item(pos)
				if result == 0 then
					next_state = 1
				end
			end
		end
		-- Change state?
		if next_state ~= state then
			meta:set_int(data.tier.."_EU_demand", machine_state_demand[next_state])
			meta:set_int("state", next_state)
		end
	end,
})

technic.register_machine(tier, "technic:"..ltier.."_electric_furnace",        technic.receiver)
technic.register_machine(tier, "technic:"..ltier.."_electric_furnace_active", technic.receiver)

end -- End registration

