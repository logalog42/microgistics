-- Microgistics/init.lua

Microgistics = {}
Microgistics.modpath = minetest.get_modpath("microgistics")

dofile(Microgistics.modpath.. DIR_DELIM .. "functions.lua")
dofile(Microgistics.modpath.. DIR_DELIM .. "rails.lua")
dofile(Microgistics.modpath.. DIR_DELIM .. "train_entity.lua")
dofile(Microgistics.modpath.. DIR_DELIM .. "station.lua" )
