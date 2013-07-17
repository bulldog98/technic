
technic.alloy_furnace_formspec =
	"invsize[8,10;]"..
	"label[0,0;Alloy Furnace]"..
        "list[current_name;src;3,1;1,2;]"..
	"list[current_name;dst;5,1;2,2;]"..
	"list[current_player;main;0,6;8,4;]"..
	"list[current_name;upgrade1;1,4;1,1;]"..
	"list[current_name;upgrade2;2,4;1,1;]"..
	"label[1,5;Upgrade Slots]"

function technic.register_alloy_furnace(tier)
local ltier = string.lower(tier)

minetest.register_node("technic:"..ltier.."_alloy_furnace", {
	description = tier.." Alloy Furnace",
	tiles = {"technic_"..ltier.."_alloy_furnace_top.png",       "technic_"..ltier.."_alloy_furnace_bottom.png",
	         "technic_"..ltier.."_alloy_furnace_side_tube.png", "technic_"..ltier.."_alloy_furnace_side_tube.png",
	         "technic_"..ltier.."_alloy_furnace_side.png",      "technic_"..ltier.."_alloy_furnace_front.png"},
	paramtype2 = "facedir",
	groups = {cracky=2, tubedevice=1, tubedevice_receiver=1},
	tube = {
		insert_object = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("src", stack)
		end,
		can_insert = function(pos, node, stack, direction)
			local meta = minetest.env:get_meta(pos)
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

		meta:set_string("infotext", tier.." Alloy furnace")
		meta:set_int("tube_time",  0)
		meta:set_string("formspec", technic.alloy_furnace_formspec)
		local inv = meta:get_inventory()
		inv:set_size("src", 2)
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
})

minetest.register_node("technic:"..ltier.."_alloy_furnace_active",{
	description = "MV Alloy Furnace",
	tiles = {"technic_"..ltier.."_alloy_furnace_top.png",       "technic_"..ltier.."_alloy_furnace_bottom.png",
	         "technic_"..ltier.."_alloy_furnace_side_tube.png", "technic_"..ltier.."_alloy_furnace_side_tube.png",
	         "technic_"..ltier.."_alloy_furnace_side.png",      "technic_"..ltier.."_alloy_furnace_front_active.png"},
	paramtype2 = "facedir",
	light_source = 8,
	drop = "technic:"..ltier.."_alloy_furnace",
	groups = {cracky=2, tubedevice=1, tubedevice_receiver=1, not_in_creative_inventory=1},
	tube = {
		insert_object = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("src", stack)
		end,
		can_insert = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:room_for_item("src", stack)
		end,
	},
	legacy_facedir_simple = true,
	sounds = default.node_sound_stone_defaults(),
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
})

minetest.register_abm({
	nodenames = {"technic:"..ltier.."_alloy_furnace", "technic:"..ltier.."_alloy_furnace_active"},
	interval = 1,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local data         = minetest.registered_nodes[node.name].technic
		local meta         = minetest.get_meta(pos)
		local inv          = meta:get_inventory()
		local eu_input     = meta:get_int(data.tier.."_EU_input")
		local state        = meta:get_int("state")
		local next_state   = state

		-- Machine information
		local machine_name         = data.tier.." Alloy Furnace"
		local machine_node         = "technic:"..string.lower(data.tier).."_alloy_furnace"
		local machine_state_demand = { 50, 2000, 1500, 1000 }

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
			local EU_upgrade, tube_speed_upgrade = technic.check_furnace_upgrades(meta)

			-- Handle pipeworks (consumes tube_speed_upgrade)
			next_state = technic.handle_furnace_pipeworks(pos, next_state, tube_speed_upgrade)
			----------------------
			local empty  = 1
			local recipe = nil
			local result = nil

			-- Get what to cook if anything
			local srcstack  = inv:get_stack("src", 1)
			local src2stack = inv:get_stack("src", 2)
			local src_item1 = nil
			local src_item2 = nil
			if srcstack and src2stack then
				src_item1 = srcstack:to_table()
				src_item2 = src2stack:to_table()
				empty     = 0
			end

			if src_item1 and src_item2 then
				recipe = technic.get_alloy_recipe(src_item1, src_item2)
			end
			if recipe then
				result = {name=recipe.dst_name, count=recipe.dst_count}
			end

			if state == 1 then
				hacky_swap_node(pos, machine_node)
				meta:set_string("infotext", machine_name.." Idle")

				local inv = meta:get_inventory()
				if not inv:is_empty("src") then
					if empty == 0 and recipe and inv:room_for_item("dst", result) then
						meta:set_string("infotext", machine_name.." Active")
						meta:set_int("src_time", 0)
						next_state = 2 + EU_upgrade
						-- Next state is decided by the battery upgrade
						-- (state 2 = 0 batteries, state 3 = 1 battery, 4 = 2 batteries)
					end
				end

			elseif state == 2 or state == 3 or state == 4 then
				hacky_swap_node(pos, machine_node.."_active")
				meta:set_int("src_time", meta:get_int("src_time") + 1)
				if meta:get_int("src_time") == 4 then -- 4 ticks per output
					meta:set_string("src_time", 0)
					-- check if there's room for output in "dst" list and that we have the materials
					if recipe and inv:room_for_item("dst", result) then
						-- Take stuff from "src" list
						srcstack:take_item(recipe.src1_count)
						inv:set_stack("src", 1, srcstack)
						src2stack:take_item(recipe.src2_count)
						inv:set_stack("src2", 1, src2stack)
						-- Put result in "dst" list
						inv:add_item("dst", result)
					else
						next_state = 1
					end
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

technic.register_machine(tier, "technic:"..ltier.."_alloy_furnace",        technic.receiver)
technic.register_machine(tier, "technic:"..ltier.."_alloy_furnace_active", technic.receiver)

end -- End registration

