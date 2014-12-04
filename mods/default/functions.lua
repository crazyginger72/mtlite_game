-- mods/default/functions.lua

--
-- Sounds
--

function default.node_sound_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name="", gain=1.0}
	table.dug = table.dug or
			{name="default_dug_node", gain=0.25}
	table.place = table.place or
			{name="default_place_node_hard", gain=1.0}
	return table
end

function default.node_sound_stone_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name="default_hard_footstep", gain=0.5}
	table.dug = table.dug or
			{name="default_hard_footstep", gain=1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_dirt_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name="default_dirt_footstep", gain=1.0}
	table.dug = table.dug or
			{name="default_dirt_footstep", gain=1.5}
	table.place = table.place or
			{name="default_place_node", gain=1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_sand_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name="default_sand_footstep", gain=0.2}
	table.dug = table.dug or
			{name="default_sand_footstep", gain=0.4}
	table.place = table.place or
			{name="default_place_node", gain=1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_wood_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name="default_wood_footstep", gain=0.5}
	table.dug = table.dug or
			{name="default_wood_footstep", gain=1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_leaves_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name="default_grass_footstep", gain=0.35}
	table.dug = table.dug or
			{name="default_grass_footstep", gain=0.7}
	table.dig = table.dig or
			{name="default_dig_crumbly", gain=0.4}
	table.place = table.place or
			{name="default_place_node", gain=1.0}
	default.node_sound_defaults(table)
	return table
end

function default.node_sound_glass_defaults(table)
	table = table or {}
	table.footstep = table.footstep or
			{name="default_glass_footstep", gain=0.5}
	table.dug = table.dug or
			{name="default_break_glass", gain=1.0}
	default.node_sound_defaults(table)
	return table
end

--
-- Legacy
--

function default.spawn_falling_node(p, nodename)
	spawn_falling_node(p, nodename)
end

-- Horrible crap to support old code
-- Don't use this and never do what this does, it's completely wrong!
-- (More specifically, the client and the C++ code doesn't get the group)
function default.register_falling_node(nodename, texture)
	minetest.log("error", debug.traceback())
	minetest.log('error', "WARNING: default.register_falling_node is deprecated")
	if minetest.registered_nodes[nodename] then
		minetest.registered_nodes[nodename].groups.falling_node = 1
	end
end

--
-- Global callbacks
--

-- Global environment step function
function on_step(dtime)
	-- print("on_step")
end
minetest.register_globalstep(on_step)

function on_placenode(p, node)
	--print("on_placenode")
end
minetest.register_on_placenode(on_placenode)

function on_dignode(p, node)
	--print("on_dignode")
end
minetest.register_on_dignode(on_dignode)

function on_punchnode(p, node)
end
minetest.register_on_punchnode(on_punchnode)


--
-- Lavacooling
--

default.cool_lava_source = function(pos)
	minetest.set_node(pos, {name="default:obsidian"})
	minetest.sound_play("default_cool_lava", {pos = pos,  gain = 0.25})
end

default.cool_lava_flowing = function(pos)
	minetest.set_node(pos, {name="default:stone"})
	minetest.sound_play("default_cool_lava", {pos = pos,  gain = 0.25})
end

minetest.register_abm({
	nodenames = {"default:lava_flowing"},
	neighbors = {"group:water"},
	interval = 2,
	chance = 4,
	action = function(pos, node, active_object_count, active_object_count_wider)
		default.cool_lava_flowing(pos, node, active_object_count, active_object_count_wider)
	end,
})

minetest.register_abm({
	nodenames = {"default:lava_source"},
	neighbors = {"group:water"},
	interval = 2,
	chance = 4,
	action = function(pos, node, active_object_count, active_object_count_wider)
		default.cool_lava_source(pos, node, active_object_count, active_object_count_wider)
	end,
})

--
-- dig upwards
--

function default.dig_up(pos, node, digger)
	if digger == nil then return end
	local np = {x = pos.x, y = pos.y + 1, z = pos.z}
	local nn = minetest.get_node(np)
	if nn.name == node.name and nn.param2 == node.param2 then
		minetest.node_dig(np, nn, digger)
	end
end

--
-- Leafdecay
--

-- To enable leaf decay for a node, add it to the "leafdecay" group.
--
-- The rating of the group determines how far from a node in the group "tree"
-- the node can be without decaying.
--
-- If param2 of the node is ~= 0, the node will always be preserved. Thus, if
-- the player places a node of that kind, you will want to set param2=1 or so.
--
-- If the node is in the leafdecay_drop group then the it will always be dropped
-- as an item

--rewrite by crazyginger72 for speed

minetest.register_abm({
	nodenames = {"group:leafdecay"},
	neighbors = {"air", "group:liquid"},
	interval = 5,
	chance = 10,

	action = function(pos, node, _, _)
		local pos1 = {x=pos.x, y=pos.y-1, z=pos.z}
		local node_under = minetest.get_node(pos1)
		local decay = minetest.registered_nodes[node.name].groups.leafdecay
		local nodes_around = minetest.find_node_near(pos, decay, {"group:tree","ignore"})
		local node = minetest.get_node(pos)

		if node.param2 ~= 0 then
			return
		end

		if not decay or decay == 0 then
			return
		elseif decay ~= 1 and nodes_around then
			return
		else
			itemstacks = minetest.get_node_drops(node.name)
			for _, itemname in ipairs(itemstacks) do
				local p_drop = {
					x = pos.x - 0.5,
					y = pos.y - 0.5,
					z = pos.z - 0.5,
				}
				minetest.add_item(p_drop, itemname)
			end
			minetest.remove_node(pos)
			nodeupdate(pos)
		end
	end
})




minetest.register_abm({
	nodenames = {"group:treedecay"},
	neighbors = {"air", "group:liquid"},
	interval = 5,
	chance = 10,

	action = function(pos, node, _, _)
		local pos_under = {x=pos.x, y=pos.y-1, z=pos.z}
		local node_under = minetest.get_node(pos_under)
		local node = minetest.get_node(pos)
		local decay = minetest.registered_nodes[node.name].groups.treedecay

		if node.param2 ~= 0 then
			return
		end

		if minetest.get_item_group(node_under.name, "tree") ~= 0 or minetest.get_item_group(node_under.name, "soil") ~= 0 then
			return
		elseif decay == 2 and (minetest.get_item_group(node_under.name, "tree") ~= 0 or minetest.get_item_group(node_under.name, "sand") ~= 0) then
			return
		else

			itemstacks = minetest.get_node_drops(node.name)
			for _, itemname in ipairs(itemstacks) do
				local p_drop = {
					x = pos.x - 0.5,
					y = pos.y - 0.5,
					z = pos.z - 0.5,
				}
				minetest.add_item(p_drop, itemname)
			end
			minetest.remove_node(pos)
			nodeupdate(pos)
		end
	end
})