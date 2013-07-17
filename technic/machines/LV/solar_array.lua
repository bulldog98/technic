-- The solar array is an assembly of panels into a powerful array
-- The assembly can deliver more energy than the individual panel because
-- of the transformer unit which converts the panel output variations into
-- a stable supply.
-- Solar arrays are not able to store large amounts of energy.
-- The LV arrays are used to make medium voltage arrays.

minetest.register_craft({
	output = 'technic:solar_array_lv 1',
	recipe = {
		{'technic:solar_panel', 'technic:solar_panel',     'technic:solar_panel'},
		{'technic:solar_panel', 'technic:lv_transformer',  'technic:solar_panel'},
		{'default:steel_ingot', 'technic:lv_cable_000000', 'default:steel_ingot'},
	}
})

technic.register_solar_array("LV", 10)

