minetest.register_node("microgistics:brake_rail", {
	description = ("Brake Rail stops train so it interacts with station."),
	short_description = "Brake Rail",
	drawtype = "nodebox",
	paramtype = "light",
	groups = {dig_immediate = 2, rail = 1},
	tiles = {
		"train_new_top_brake.png",
		"train_new_bottom.png",
		"train_new_side.png",
	},
	node_box = rail_node_box,
	collision_box = rail_collision_box,
	selection_box = rail_collision_box,
	connects_to = {"group:rail"},
})


minetest.register_node("minegistics:Station", {
	description = "Place were a stopped train can load and unload items to adjecent inventories",
	tiles = {"station.png"},
	groups = {dig_immediate=2, structures=1},
	drawtype = "mesh",
	mesh = "trainStation.obj",
	wield_image = "station_wield.png",
	inventory_image = "station_wield.png",
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.above.y ~= 0 then
            minetest.chat_send_player(placer:get_player_name(), "You can't build here.")
            return
        end
        minetest.item_place(ItemStack("microgistics:brake_rail"), placer, pointed_thing)
        return minetest.item_place(itemstack, placer, pointed_thing)
    end,
	on_construct = function(pos)
      		local meta = minetest.get_meta(pos)
      		meta:set_string("formspec",
      			"size[8,9]"..
      			"list[context;main;0,0;8,4;]"..
      			"list[current_player;main;0,5;8,4;]" ..
      			"listring[]")
      		meta:set_string("infotext", "Train Station")
	end,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		
		minetest.forceload_free_block(pos, false)
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		return stack:get_count()
	end
})