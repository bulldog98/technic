local path = technic.modpath.."/machines"

dofile(path.."/furnaces.lua")
dofile(path.."/alloy_furnace.lua")
dofile(path.."/electric_furnace.lua")
dofile(path.."/cables.lua")
dofile(path.."/solar_array.lua")
dofile(path.."/battery_box.lua")
dofile(path.."/LV/init.lua")
dofile(path.."/MV/init.lua")
dofile(path.."/HV/init.lua")
dofile(path.."/switching_station.lua")
--dofile(path.."/supply_converter.lua")
dofile(path.."/alloy_furnaces_commons.lua")
dofile(path.."/other/init.lua")
if minetest.get_modpath("gloopores") then
	dofile(path.."grinder_gloopores.lua")
end

