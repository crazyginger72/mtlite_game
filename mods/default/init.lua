-- Minetest 0.4 mod: default
-- See README.txt for licensing and other information.


-- The API documentation in here was moved into doc/lua_api.txt


WATER_ALPHA = 160
WATER_VISC = 1
LAVA_VISC = 7
LIGHT_MAX = 14


-- Definitions made by this mod that other mods can use too
default = {}


-- GUI related stuff
default.gui_bg = "bgcolor[#080808BB;true]"
default.gui_bg_img = "background[5,5;1,1;gui_formbg.png;true]"
default.gui_slots = "listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]"


function default.get_hotbar_bg(x,y)
	local out = ""
	for i=0,7,1 do
		out = out .."image["..x+i..","..y..";1,1;gui_hb_bg.png]"
	end
	return out
end


default.gui_suvival_form = "size[8,8.5]"..
			default.gui_bg..
			default.gui_bg_img..
			default.gui_slots..
			"list[current_player;main;0,4.25;8,1;]"..
			"list[current_player;main;0,5.5;8,3;8]"..
			"list[current_player;craft;1.75,0.5;3,3;]"..
			"list[current_player;craftpreview;5.75,1.5;1,1;]"..
			"image[4.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
			default.get_hotbar_bg(0,4.25)


-- Load files
dofile(minetest.get_modpath("default").."/functions.lua")
dofile(minetest.get_modpath("default").."/nodes.lua")
dofile(minetest.get_modpath("default").."/tools.lua")
dofile(minetest.get_modpath("default").."/craftitems.lua")
dofile(minetest.get_modpath("default").."/crafting.lua")
dofile(minetest.get_modpath("default").."/mapgen.lua")
dofile(minetest.get_modpath("default").."/player.lua")
dofile(minetest.get_modpath("default").."/trees.lua")
dofile(minetest.get_modpath("default").."/aliases.lua")
dofile(minetest.get_modpath("default").."/sethome.lua")
dofile(minetest.get_modpath("default").."/creative.lua")
dofile(minetest.get_modpath("default").."/item_drop.lua")


minetest.register_on_newplayer(function(player)
	if minetest.setting_getbool("give_initial_stuff") then
		minetest.chat_send_player(player:get_player_name(), "You have been given items to help you begin your adventure!")
		minetest.log("action", "Giving initial stuff to player "..player:get_player_name())
		player:get_inventory():add_item('main', 'default:pick_steel')
		player:get_inventory():add_item('main', 'default:torch 99')
		player:get_inventory():add_item('main', 'default:axe_steel')
		player:get_inventory():add_item('main', 'default:shovel_steel')
		player:get_inventory():add_item('main', 'default:cobble 99')
	end
end)


--------------------------------------------------------------------------------
-------Minetest Time--kazea's code tweaked by cg72 with help from crazyR--------
----------------Zeno` simplified some math and additional tweaks ---------------
--------------------------------------------------------------------------------
     
    player_hud = {}
    player_hud.time = {}
    player_hud.lag = {}
    local timer = 0;
    local function explode(sep, input)
            local t={}
                    local i=0
            for k in string.gmatch(input,"([^"..sep.."]+)") do
                t[i]=k;i=i+1
            end
            return t
    end
    local function floormod ( x, y )
            return (math.floor(x) % y);
    end
    local function get_lag(raw)
            local a = explode(", ",minetest.get_server_status())
            local b = explode("=",a[4])
                    local lagnum = tonumber(string.format("%.2f", b[1]))
 		    local clag = 0
		    if lagnum > clag then 
			    clag = lagnum 
		    else
			    clag = clag * .75
		    end
                    if raw ~= nil then
                            return clag
                    else
                            return ("Current Lag: %s sec"):format(clag);
                    end
    end
    local function get_time ()
    local t, m, h, d
    t = 24*60*minetest.get_timeofday()
    m = floormod(t, 60)
    t = t / 60
    h = floormod(t, 60)
           
        
    if h == 12 then
        d = "pm"
    elseif h >= 13 then
        h = h - 12
        d = "pm"
    elseif h == 0 then
        h = 12
        d = "am"
    else
        d = "am"
    end
        return ("Minetest time %02d:%02d %s"):format(h, m, d);
    end
    local function generatehud(player)
            local name = player:get_player_name()
            player_hud.time[name] = player:hud_add({
                    hud_elem_type = "text",
                    name = "player_hud:time",
                    position = {x=0.20, y=0.965},
                    text = get_time(),
                    scale = {x=100,y=100},
                    alignment = {x=0,y=0},
                    number = 0xFFFFFF,
            })
            player_hud.lag[name] = player:hud_add({
                    hud_elem_type = "text",
                    name = "player_hud:lag",
                    position = {x=0.80, y=0.965},
                    text = get_lag(),
                    scale = {x=100,y=100},
                    alignment = {x=0,y=0},
                    number = 0xFFFFFF,
            })
    end
    local function updatehud(player, dtime)
            local name = player:get_player_name()
            timer = timer + dtime;
            if (timer >= 1.0) then
                    timer = 0;
                    if player_hud.time[name] then player:hud_change(player_hud.time[name], "text", get_time()) end
                    if player_hud.lag[name] then player:hud_change(player_hud.lag[name], "text", get_lag()) end
            end
    end
    local function removehud(player)
            local name = player:get_player_name()
            if player_hud.time[name] then
                    player:hud_remove(player_hud.time[name])
            end
            if player_hud.lag[name] then
                    player:hud_remove(player_hud.lag[name])
            end
    end
    minetest.register_globalstep(function ( dtime )
            for _,player in ipairs(minetest.get_connected_players()) do
                    updatehud(player, dtime)
            end
    end);
    minetest.register_on_joinplayer(function(player)
            minetest.after(0,generatehud,player)
    end)
    minetest.register_on_leaveplayer(function(player)
            minetest.after(1,removehud,player)
    end)


