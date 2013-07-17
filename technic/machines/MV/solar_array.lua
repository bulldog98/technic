
minetest.register_craft({
	output = 'technic:MV_solar_array 1',
	recipe = {
		{'technic:LV_solar_array', 'technic:LV_solar_array',  'technic:LV_solar_array'},
		{'technic:LV_solar_array', 'technic:mv_transformer',  'technic:LV_solar_array'},
		{'default:steel_ingot',    'technic:MV_cable_000000', 'default:steel_ingot'},
	}
})

technic.register_solar_array("MV", 100)

