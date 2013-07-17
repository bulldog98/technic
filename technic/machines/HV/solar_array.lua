-- The high voltage solar array is an assembly of medium voltage arrays.
-- The assembly can deliver high voltage levels and is a 20% less efficient
-- compared to 5 individual medium voltage arrays due to losses in the transformer.
-- However high voltage is supplied.
-- Solar arrays are not able to store large amounts of energy.

minetest.register_craft({
	output = 'technic:HV_solar_array 1',
	recipe = {
		{'technic:MV_solar_array', 'technic:MV_solar_array',  'technic:MV_solar_array'},
		{'technic:MV_solar_array', 'technic:hv_transformer',  'technic:MV_solar_array'},
		{'default:steel_ingot',    'technic:HV_cable_000000', 'default:steel_ingot'},
	}
})

technic.register_solar_array("HV", 1000)

