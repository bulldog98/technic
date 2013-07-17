
minetest.register_craft({
	output = 'technic:HV_cable_000000 3',
	recipe = {
		{'technic:rubber',          'technic:rubber',          'technic:rubber'},
		{'technic:MV_cable_000000', 'technic:MV_cable_000000', 'technic:MV_cable_000000'},
		{'technic:rubber',          'technic:rubber',          'technic:rubber'},
	}
}) 

technic.register_cable("HV", 0.12)

