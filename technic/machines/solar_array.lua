
function technic.register_solar_array(tier, power)
	local tier_name = technic.tiers[tier].description
	local ltier = string.lower(tier)
	minetest.register_node("technic:solar_array_"..ltier, {
		tiles = {"technic_"..ltier.."_solar_array_top.png",  "technic_"..ltier.."_solar_array_bottom.png",
			 "technic_"..ltier.."_solar_array_side.png", "technic_"..ltier.."_solar_array_side.png",
			 "technic_"..ltier.."_solar_array_side.png", "technic_"..ltier.."_solar_array_side.png"},
		groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2},
		sounds = default.node_sound_wood_defaults(),
		description = tier_name.." Solar Array",
		active = false,
		drawtype = "nodebox",
		paramtype = "light",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		},
		solar_array = {
			tier = tier,
			power = power,
		},
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			local name = minetest.get_node(pos).name
			local tier = minetest.registered_nodes[name].solar_array.tier
			meta:set_int(tier.."_EU_supply", 0)
		end,
	})

	minetest.register_abm({
		nodenames = {"technic:solar_array_"..ltier},
		interval = 1,
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			-- The action here is to make the solar array produce power
			-- Power is dependent on the light level and the height above ground
			-- 130m and above is optimal as it would be above cloud level.
			-- Height gives 1/4 of the effect, light 3/4. Max. effect is 2880EU for the array.
			-- There are many ways to cheat by using other light sources like lamps.
			-- As there is no way to determine if light is sunlight that is just a shame.
			-- To take care of some of it solar panels do not work outside daylight hours or if
			-- built below -10m
			local pos1 = {}
			pos1.y = pos.y + 1
			pos1.x = pos.x
			pos1.z = pos.z
			local light = minetest.get_node_light(pos1, nil)
			local time_of_day = minetest.get_timeofday()
			local meta = minetest.get_meta(pos)
			light = light or 0
			local array_data = minetest.registered_nodes[node.name].solar_array


			-- turn on array only during day time and if sufficient light
			-- I know this is counter intuitive when cheating by using other light sources.
			if light >= 12 and time_of_day >= 0.24 and time_of_day <= 0.76 and pos.y > 0 then
				local charge_to_give = array_data.power --math.floor(light + pos1.y / 130 * array_data.power)
				--charge_to_give = math.max(charge_to_give, 0)
				--charge_to_give = math.min(charge_to_give, array_data.power)
				meta:set_string("infotext", "Solar Array is active ("..charge_to_give.."EU)")
				meta:set_int(array_data.tier.."_EU_supply", charge_to_give)
			else
				meta:set_string("infotext", "Solar Array is inactive");
				meta:set_int(array_data.tier.."_EU_supply", 0)
			end
		end,
	})

	technic.register_machine(tier, "technic:solar_array_"..ltier, technic.producer)
end

