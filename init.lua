local S, PS = core.get_translator("fakery")

fakery = {}

fakery.S = S
fakery.PS = PS

local recipes = {}
fakery.recipes = recipes

local items = core.registered_items
local register_fake = function(name, item, dye)
	local def = items[item]
	core.register_craftitem(name, {
		description = def.description,
		inventory_image = def.inventory_image,
	})
	recipes[dye] = name
end

fakery.register = register_fake

if core.get_modpath("default") then
	register_fake("fakery:diamond","default:diamond","dye:cyan")
	register_fake("fakery:mese","default:mese_crystal","dye:yellow")
end
if minetest.get_modpath("moreores") then
	register_fake("fakery:mithril","moreores:mithril_ingot","dye:blue")
end
if minetest.get_modpath("cloud_items") then
	register_fake("fakery:cloud","cloud_items:cloud_ingot","dye:white")
end
if minetest.get_modpath("lavastuff") then
	register_fake("fakery:lava","lavastuff:ingot","dye:red")
end
if minetest.get_modpath("overpowered") then
	register_fake("fakery:op","overpowered:ingot","dye:green")
end
--formspecs
if minetest.get_modpath("basic_materials") then
	fakery.base = "basic_materials:plastic_sheet"
	fakery.base_image = "fakery_plastic.png"
elseif core.get_modpath("default") then
	fakery.base = "default:steel_ingot"
	fakery.base_image = "fakery_ingot.png"
end
fakery.formspec = {
	bench = "size[10,10]"..
		"image[4.5,2;1,1;sfinv_crafting_arrow.png]"..
		"list[context;base;2,1.5;1,1]"..
		"image[2,1.5;1,1;"fakery.base_image"]"..
		"list[context;dye;2,2.5;1,1]"..
		"image[2,2.5;1,1;fakery_dye.png]"..
		"list[context;dest;7,2;1,1]"..
		"list[current_player;main;1,5;8,4;]",
	progress = "size[10,10]"..
		"label[4,2;"..S("Forgery in progress...").."]"..
		"list[current_player;main;1,5;8,4;]"
}

function fakery.set_base_image(image)
	fakery.base_image = image
	fakery.formspec.bench = "size[10,10]"..
		"image[4.5,2;1,1;sfinv_crafting_arrow.png]"..
		"list[context;base;2,1.5;1,1;1]"..
		"image[2,1.5;1,1;"..fakery.base_image.."]"..
		"list[context;dye;2,2.5;1,1;1]"..
		"image[2,2.5;1,1;fakery_dye.png]"..
		"list[context;dest;7,2;1,1;1]"..
		"list[current_player;main;1,5;8,4;]"
end
--workbench
local function register_recipe(dye,base,result,pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local timer = minetest.get_node_timer(pos)
		if inv:contains_item("dye", dye) == true and inv:contains_item("base", base) == true and inv:is_empty("dest") then
			inv:remove_item("dye", dye)
			inv:remove_item("base", base)
			local dye_s = inv:get_stack("dye", 0)
			local base_s = inv:get_stack("base", 0)
			inv:set_stack("dye", 2, dye_s)
			inv:set_stack("base", 2, base_s)
			inv:set_stack("dest", 2, result)
			meta:set_string("formspec", fakery.formspec.progress)
			timer:start(7)
		end
end
local function update(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local timer = minetest.get_node_timer(pos)
	
	local base_s = inv:get_stack("base", 0)
	if base_s:is_empty() then return end
	local dye_s = inv:get_stack("dye", 0)
	if dye_s:is_empty() then return end
	local out = recipes[dye_s:get_name()]
	if not out then return end
	local out_s = inv:get_stack("dest", 0)
	if not out_s:is_empty() then return end
	inv:take_item("base", 1)
	inv:set_stack("dye", 0, ItemStack(""))
	inv:set_stack("dest", 0, ItemStack(out))
	meta:set_string("formspec", fakery.formspec.progress)
	timer:start(7)
end
minetest.register_node("fakery:table", {
		description = S("Forgery Workbench"),
		tiles = {"fakery_bench_top.png", "fakery_bench_top.png", "fakery_bench_side.png", "fakery_bench_side.png","fakery_bench_side.png", "fakery_bench_side.png"},
		groups = {oddly_breakable_by_hand = 1},
		on_construct = function(pos, node)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			inv:set_size("dye", 1)
			inv:set_size("base", 1)
			inv:set_size("dest", 1)
			meta:set_string("formspec", fakery.formspec.bench)
		end,
		on_timer = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec", fakery.formspec.bench)
			return false
		end,
		on_metadata_inventory_put = function(pos, listname, index, stack, player)
			update(pos)
		end,
		on_metadata_inventory_take = function(pos, listname, index, stack, player)
			update(pos)
		end,
		allow_metadata_inventory_move = function()
			return 0
		end,
		allow_metadata_inventory_put = function(pos, listname, index, stack, player)
			if listname == "dest" then return 0 end
			if listname == "base"
		end,
		allow_metadata_inventory_take = function(pos, listname, index, stack, player)
			if listname ~= "dest" then return 0 end
			return stack:get_count()
		end
})
minetest.register_craft({
		output = "fakery:table",
		recipe = {
			{"default:sword_steel", "default:pick_steel", "default:axe_steel"},
			{"default:desert_sandstone_block", "default:bronzeblock", "default:desert_sandstone_block"},
			{"default:desert_sandstone_block", "default:bronzeblock", "default:desert_sandstone_block"}
		}
})
