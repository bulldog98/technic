
minetest.register_alias("mv_cable", "technic:MV_cable_000000")

minetest.register_craft({
	output = 'technic:MV_cable_000000 3',
	recipe ={
		{'technic:rubber',          'technic:rubber',          'technic:rubber'},
		{'technic:LV_cable_000000', 'technic:LV_cable_000000', 'technic:LV_cable_000000'},
		{'technic:rubber',          'technic:rubber',          'technic:rubber'},
	}
}) 

technic.register_cable("MV", 0.10)

