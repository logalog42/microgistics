function Microgistics.is_rail(pos)
	local node_name = minetest.get_node(pos).name
	if node_name == "ignore" then
		local vm = minetest.get_voxel_manip()
		local emin, emax = vm:read_from_map(pos, pos)
		local area = VoxelArea:new{
			MinEdge = emin,
			MaxEdge = emax,
		}
		local data = vm:get_data()
		local vi = area:indexp(pos)
		node_name = minetest.get_name_from_content_id(data[vi])
	end
	if minetest.get_item_group(node_name, "rail") ~= 0 then
		return true
	end
end


local directions = {
	vector.new(0, 0, 1),
	vector.new(-1, 0, 0),
	vector.new(1, 0, 0),
	vector.new(0, 1, 0),
	vector.new(0, -1, 0),
	vector.new(0, 0, -1),
}

local a = vector.new(0, 0, 1)
local b = vector.new(-1, 0, 0)
local c = vector.new(1, 0, 0)
local d = vector.new(0, 0, -1)

-- foo
local function yaw_to_dir(yaw)
	yaw = (yaw / math.pi)
	if yaw <= 0.25 then return a, b, c, d
	elseif yaw <= 0.75 then return b, d, a, c
	elseif yaw <= 1.25 then return d, c, b, a
	elseif yaw <= 1.75 then return c, a, d, b
	end
end

function Microgistics.dir_to_yaw(dir)
	if dir.z == 1 then return 0
	elseif dir.x == -1 then return 0.5 * math.pi
	elseif dir.x == 1 then return 1.5 * math.pi
	elseif dir.z == -1 then return math.pi
	end
	return 0.25 * math.pi
end

local vector_zero = vector.zero()
function Microgistics.get_next_pos(train, dtime)
	local pos = train.object:get_pos()
	local node_pos = vector.round(pos)

	local front, left, right, back = yaw_to_dir(train.object:get_yaw())
	local distance = train.speed * dtime

	local new_pos = pos + (front * distance)
	local next_node = new_pos + (front * 0.501)

	-- not prety, but if the train is about to cross the middle of a break_rail node it will stop
	if (pos + (front * 0.501)):round() == node_pos and node_pos ~= next_node:round() and minetest.get_node(node_pos).name == "Microgistics:brake_rail" then
		return node_pos, front, true
	end

	-- if we are standing in the middle of a node we need to decied where to go next
	if pos == node_pos then
		if Microgistics.is_rail(pos + front) then
			return pos + (front * distance), front
		elseif Microgistics.is_rail(pos + left) then
			return pos + (left * distance), left
		elseif Microgistics.is_rail(pos + right) then
			return pos + (right * distance), right
		elseif Microgistics.is_rail(pos + back) then
			return pos + (back * distance), back
		else
			-- there are no surounding nodes
			return pos, vector.zero(), true
		end
	end

	if Microgistics.is_rail(next_node) then
		-- go straight
		return new_pos, front
	else
		if (not Microgistics.is_rail(pos + left)) and (not Microgistics.is_rail(pos + right)) and Microgistics.is_rail(pos + back) then
			-- when we reach a dead end, put in a break
			return node_pos, front, true
		end
		-- if we reach a corner we go to the center of the node
		return node_pos, front
	end

	-- I don't think this is reachable
	return pos, vector.zero(), true
end

function microgistics.register_station(name, def)
	minetest.register_node(name .. "station_build", {
		description = "Place were a stopped train can load and unload items to adjecent inventories",
		tiles = def.tiles.building,
		groups = {dig_immediate=2, structures=1},
		drawtype = def.drawtype.building,
		mesh = def.obj,
		wield_image = def.wield_image,
		inventory_image = def.inventory_image,
		on_place = function(itemstack, placer, pointed_thing)
			--for index, value in pairs(pointed_thing) do
				--minetest.log("default", "Index = " .. tostring(index) .. " Value = " .. tostring(value))
			--end
			--minetest.item_place(itemstack, placer, pointed_thing.above)
			--minetest.item_place(ItemStack("microgistics:brake_rail"), placer, pointed_thing)
			
			--return minetest.item_place(itemstack, placer, pointed_thing)

			local above = pointed_thing.above
			local node = minetest.get_node(above)
			local udef = minetest.registered_nodes[node.name]
			if udef and udef.on_rightclick and	not (placer and placer:is_player()) then
				return udef.on_rightclick(under, node, placer, itemstack, pointed_thing) or itemstack
			end

			local pos
			if udef and udef.buildable_to then
				pos = above
			else
				pos = pointed_thing.above
			end

			local player_name = placer and placer:get_player_name() or ""

			if minetest.is_protected(pos, player_name) and
					not minetest.check_player_privs(player_name, "protection_bypass") then
				minetest.record_protection_violation(pos, player_name)
				return itemstack
			end

			local node_def = minetest.registered_nodes[minetest.get_node(pos).name]
			if not node_def or not node_def.buildable_to then
				return itemstack
			end

			minetest.set_node(pos, {name = name .. "_bottom"})
			minetest.set_node(pointed_thing, {name = name .. "_top", param2 = dir})

			if not minetest.is_creative_enabled(player_name) then
				itemstack:take_item()
			end
			return itemstack

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
	minetest.register_node(name .. "stop_point", {
		drawtype = "nodebox",
		tiles = def.tiles.stop_point,
		is_ground_content = false,
		pointable = false,
		groups = {oddly_breakable_by_hand = 2, not_in_creative_inventory = 1},
		sounds = def.sounds or default.node_sound_wood_defaults(),
		drop = name .. "_station_building",
		node_box = {
			type = "fixed",
			fixed = def.nodebox.stop_point,
		},
		on_destruct = function(pos)
			destruct_bed(pos, 2)
		end,
		can_dig = function(pos, player)
			local node = minetest.get_node(pos)
			local dir = minetest.facedir_to_dir(node.param2)
			local p = vector.add(pos, dir)
			return beds.can_dig(p)
		end,
	})
end