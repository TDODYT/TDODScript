--[[
TDODScript
-----------------
Re - Worked by TDOD
------------------
Credit to
Code Worked From CodeScript
permission From  Code#1337
---------------------------
lancescript
-----------
Prisuhm
-------
-THEKING-
--------
]]--

local SCRIPT_VERSION = "0.3"

-- Auto Updater from https://github.com/hexarobi/stand-lua-auto-updater
local status, auto_updater = pcall(require, "auto-updater")
if not status then
    local auto_update_complete = nil util.toast("Installing auto-updater...", TOAST_ALL)
    async_http.init("raw.githubusercontent.com", "/hexarobi/stand-lua-auto-updater/main/auto-updater.lua",
        function(result, headers, status_code)
            local function parse_auto_update_result(result, headers, status_code)
                local error_prefix = "Error downloading auto-updater: "
                if status_code ~= 200 then util.toast(error_prefix..status_code, TOAST_ALL) return false end
                if not result or result == "" then util.toast(error_prefix.."Found empty file.", TOAST_ALL) return false end
                filesystem.mkdir(filesystem.scripts_dir() .. "lib")
                local file = io.open(filesystem.scripts_dir() .. "lib\\auto-updater.lua", "wb")
                if file == nil then util.toast(error_prefix.."Could not open file for writing.", TOAST_ALL) return false end
                file:write(result) file:close() util.toast("Successfully installed auto-updater lib", TOAST_ALL) return true
            end
            auto_update_complete = parse_auto_update_result(result, headers, status_code)
        end, function() util.toast("Error downloading auto-updater lib. Update failed to download.", TOAST_ALL) end)
    async_http.dispatch() local i = 1 while (auto_update_complete == nil and i < 40) do util.yield(250) i = i + 1 end
    if auto_update_complete == nil then error("Error downloading auto-updater lib. HTTP Request timeout") end
    auto_updater = require("auto-updater")
end
if auto_updater == true then error("Invalid auto-updater lib. Please delete your Stand/Lua Scripts/lib/auto-updater.lua and try again") end

util.require_natives(1651208000)

if not SCRIPT_SILENT_START and players.get_name(players.user()) ~= "UNKNOWN" then
    util.toast("Hello, " .. players.get_name(players.user()) .. "! \nWelcome To TDODScript!\n" .. "Check Extra's | To Join The Discord!")
end

-- Run Auto Update
auto_updater.run_auto_update({
    source_url="https://raw.githubusercontent.com/TDODYT/TDODScript/main/TDODScript.lua",
    script_relpath=SCRIPT_RELPATH,
    verify_file_begins_with="--"
})


root = menu.my_root()
self_root = menu.list(root, "Self", {"Selfoptions"}, "Your Options")
online_root = menu.list(root, "Online",{}, "Online Option" )
locations_root = menu.list(root, "Locations",{}, "Online Option" )
render_root = menu.list(root, "Extra", {" Extra"}, "")
buttonslist = menu.list(root, "Buttons", {}, "")
friendly_root = menu.list(online_root, "Friendly", {""}, "Friendly Options")
toxic_root = menu.list(online_root, "Toxic", {""}, "Toxic Options")
chat_root = menu.list(online_root, "Chat", {""}, "Chat Options")
all_players_root = menu.list(friendly_root, "All players", {"AllPlayers"}, "Commands to use on everybody")
menu.divider(all_players_root, 'Applies to Everybody')
fun_root = menu.list(all_players_root, "Spawn Cars to Players", {""}, "Spawn on Players")
fun_root = menu.list(fun_root, "Vehicles", {"Vehicles"}, "You Can Spawn Vehicles for Everyone!")
friendly_root = menu.list(all_players_root, "Friendly", {""}, "Friendly Options")
render_root2 = menu.list(render_root, "People Who Helped Me!", {"Helpers"}, "")

local Attacker_ = 0
local Victim_ = 0

local function onPlayerKilled(victimPed, attackerPed, weaponUsedHash)
    local victimPid = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(victimPed)
    local attackerPid = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(attackerPed)
    Victim_ = victimPid
    Attacker_ = attackerPid
end

local function onPlayerDamaged(victimPed, attackerPed, weaponUsedHash, damage)
    local victimPid = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(victimPed)
    local attackerPid = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(attackerPed)
    Victim_ = victimPid
    Attacker_ = attackerPid
end

local function bitTest(addr, offset)
    return (memory.read_int(addr) & (1 << offset)) ~= 0
end

function reclaimAll() 
	local count = memory.read_int(memory.script_global(1586468))
    for i = 0, count do
        local canFix = (bitTest(memory.script_global(1586468 + 1 + (i * 142) + 103), 1) and bitTest(memory.script_global(1586468 + 1 + (i * 142) + 103), 2))
        if canFix then
            MISC.CLEAR_BIT(memory.script_global(1586468 + 1 + (i * 142) + 103), 1)
            MISC.CLEAR_BIT(memory.script_global(1586468 + 1 + (i * 142) + 103), 3)
            MISC.CLEAR_BIT(memory.script_global(1586468 + 1 + (i * 142) + 103), 16)
            util.toast("Your personal vehicle was destroyed. It has been automatically claimed.")
        end
    end
end

local function request_control_of_entity(ent, time)
    if ent and ent ~= 0 then
        local end_time = os.clock() + (time or 3)
        while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(ent) and os.clock() < end_time do
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(ent)
            util.yield()
        end
        return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(ent)
    end
    return false
end

local function shake_player(pid, power)
    local entity = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local coords = ENTITY.GET_ENTITY_COORDS(entity, true)
    FIRE.ADD_EXPLOSION(coords['x'], coords['y'], coords['z'], 7, 0, false, true, power)
end



local function send_player_vehicle_flying(pid)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if vehicle == 0 then
        return
    end

    request_control_of_entity(vehicle)

    if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(vehicle, 1, 0, 100, 40, true, true, true, true)
        util.toast(players.get_name(pid) .. " is now flying ;)")
    else
        util.toast("could not request control of " .. players.get_name(pid) .. "'s vehicle")
    end
end

local function boost_vehicle(vehicle, speed)

    request_control_of_entity(vehicle)

    if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(vehicle, 1, 0, speed, 0, true, true, true, true)
        util.toast("done :D")
    else
        util.toast("failed to request control of vehicle :(")
    end
end

local function kill_player(pid)
    local entity = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local coords = ENTITY.GET_ENTITY_COORDS(entity, true)
    FIRE.ADD_EXPLOSION(coords['x'], coords['y'], coords['z'] + 2, 7, 1000, false, true, 0)
end

local function vehicle_emp(pid)
    local entity = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local coords = ENTITY.GET_ENTITY_COORDS(entity, true)
    FIRE.ADD_EXPLOSION(coords['x'], coords['y'], coords['z'], 65, 999, false, true, 0)
end

local function fake_explosion(pid)
    local entity = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local coords = ENTITY.GET_ENTITY_COORDS(entity, true)
    FIRE.ADD_EXPLOSION(coords['x'], coords['y'], coords['z'], 7, 0, true, true, 0)
end

local function load_model(hash) -- lancescript
    local request_time = os.time()
    if not STREAMING.IS_MODEL_VALID(hash) then
        return
    end

    STREAMING.REQUEST_MODEL(hash)

    while not STREAMING.HAS_MODEL_LOADED(hash) do
        if os.time() - request_time >= 10 then
            break
        end
        util.yield()
    end
end

local function upgrade_vehicle(vehicle) -- lancescript
    for i = 0, 49 do
        local num = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, i)
        VEHICLE.SET_VEHICLE_MOD(vehicle, i, num - 1, true)
    end
end

local function give_vehicle(pid,vehicle)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local c = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 5.0, 0.0)
    local hash = util.joaat(vehicle)
    if not STREAMING.HAS_MODEL_LOADED(hash) then
        load_model(hash)
    end
    local tank = entities.create_vehicle(hash, c, ENTITY.GET_ENTITY_HEADING(ped))
    ENTITY.SET_ENTITY_INVINCIBLE(tank)
    upgrade_vehicle(tank)
end

local function make_car_jump(vehicle, jump)
    if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
    end
    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(vehicle, 1, 0, 0, jump, true, false, true, true)
end

local function ped_explosion(pid, model_name, amount)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local coords = ENTITY.GET_ENTITY_COORDS(ped, false)
    for i = 1, (amount or 5) do
        local hash = util.joaat(model_name or "a_c_shepherd")
        load_model(hash)
        local dog = entities.create_ped(28, hash, coords, math.random(0, 270))
        local size = 20
        local x = math.random(-size, size)
        local y = math.random(-size, size)
        local z = 5
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(dog, 1, x, y, z, true, false, true, true)
        AUDIO.PLAY_PAIN(dog, 7, 0)
    end
end

local function player_vehicle_options(pid, menu_list)
    menu.divider(menu_list, "Vehicle")
    menu.action(
        menu_list,
        "Spawn vehicle",
        {"spawnfor"},
        "Spawn a vehicle for " .. players.get_name(pid),

        function (click_type)
            menu.show_command_box_click_based(click_type, "spawnfor" .. players.get_name(pid) .. " ")
        end,

        function(txt)
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
            local c = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 5.0, 0.0)
            local hash = util.joaat(txt)
            if not STREAMING.HAS_MODEL_LOADED(hash) then
                load_model(hash)
            end
            local vehicle = entities.create_vehicle(hash, c, 0)

            request_control_of_entity(vehicle)

            AUDIO._SOUND_VEHICLE_HORN_THIS_FRAME(vehicle)

            --AUDIO.SET_HORN_PERMANENTLY_ON_TIME(vehicle, 3 * 1000)
        end
    )

    menu.action(menu_list,"Repair vehicle",{},"Repair " .. players.get_name(pid) .. "'s vehicle",function ()
            local ped = PLAYER.GET_PLAYER_PED(pid)
            local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, true)
            if vehicle ~= 0 then

                request_control_of_entity(vehicle)

                if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
                    VEHICLE.SET_VEHICLE_FIXED(vehicle)
                end
            end
        end)

    menu.action(menu_list, "Fully upgrade vehicle",{},"Upgrade the players car",function()
            local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
            local vehicle = PED.GET_VEHICLE_PED_IS_USING(player_ped)

            request_control_of_entity(vehicle)

            upgrade_vehicle(vehicle)

        end)
end



local function load_weapon_asset(hash)
    while not WEAPON.HAS_WEAPON_ASSET_LOADED(hash) do
        WEAPON.REQUEST_WEAPON_ASSET(hash)
        util.yield(50)
    end
end

local function passive_mode_kill(pid)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local hash = 0x787F0BB
    local audible = true
    local visible = true

    load_weapon_asset(hash)

    for i = 0, 50 do
        if PLAYER.IS_PLAYER_DEAD(pid) then
            util.toast("Successfully killed " .. players.get_name(pid))
            return
        end

        local coords = ENTITY.GET_ENTITY_COORDS(ped)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(coords.x, coords.y, coords.z, coords.x, coords.y, coords.z - 2, 100, 0, hash, 0, audible, not visible, 2500)
        util.yield(10)
    end
    util.toast("Could not kill " .. players.get_name(pid) .. ". Are they in god mode or no ragdoll?")
end

local function shoot_ped(ped, hash, damage, ownerPed)
    local audible = true
    local visible = true
    local speed = 1

    load_weapon_asset(hash)

    local ik_head = 0x322c
    local to = PED.GET_PED_BONE_COORDS(ped, ik_head, 0, 0, 0)
    local from = {}
    from.x = to.x - 0.2
    from.y = to.y
    from.z = to.z
    GRAPHICS.DRAW_LINE(from.x, from.y, from.z, to.x, to.y, to.z, 255, 100, 255, 255)
    MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(from.x, from.y, from.z, to.x, to.y, to.z, damage, false, hash, ownerPed, audible, not visible, speed)
end



local function remove_vehicle_god(vehicle)

    request_control_of_entity(vehicle)

    if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
        ENTITY.SET_ENTITY_INVINCIBLE(vehicle, false)
    else
        util.toast("Was not able to gain control over a vehicle")
    end
end

local function explosion_circle(ped, angle, radius)
    local ped_coords = ENTITY.GET_ENTITY_COORDS(ped)
    local offset_x = ped_coords.x
    local offset_y = ped_coords.y
    local x = offset_x + radius * math.cos(angle)
    local y = offset_y + radius * math.sin(angle)
    FIRE.ADD_EXPLOSION(x, y, ped_coords.z, 4, 1, true, false, 0)
end

local function player_general_toxic_options(pid, menu_list)
    menu.divider(menu_list, "General")
    menu.toggle_loop(menu_list, "Extreme camera shake", {}, "Shake the players screen", function()
        shake_player(pid, 5000)
        util.yield(200)
    end)

    menu.action(menu_list, "Kill silently", {}, "Kill the player without loud explosions", function()
        kill_player(pid)
    end)

    menu.action(menu_list, "Passive mode kill", {}, "(DOESN'T WORK ON NO RAGDOLL PLAYERS) Kill player in passive mode", function ()
        passive_mode_kill(pid)
    end)

    menu.toggle_loop(menu_list, "Bullet spam", {}, "Spams bullets...", function ()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        if not PED.IS_PED_DEAD_OR_DYING(ped) then
            local WEAPON_MG = 0x9D07F764

            shoot_ped(ped, WEAPON_MG, 100, 0)

        end
        util.yield(5)
    end)

    local explosion_circle_angle = 0
    menu.toggle_loop(menu_list, "Explosion circle", {}, "Circle Of Explosion [On/Off]", function ()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)

        explosion_circle(ped, explosion_circle_angle, 25)

        explosion_circle_angle += 0.15

        util.yield(50)
    end)
end

local function player_vehicle_toxic_options(pid, menu_list)
    menu.divider(menu_list, "Vehicle")
    menu.action(menu_list, "Invisible vehicle EMP", {"vehicleemp"}, "Vehicle EMP", function()

        vehicle_emp(pid)

    end)

    menu.action(menu_list, "Launch vehicle in the air", {"vehiclefly"}, "Sends players vehicle flying", function()

        send_player_vehicle_flying(pid)

    end)

    menu.action(menu_list, "Boost vehicle", {}, "Makes the car move forward faster :)", function ()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)
        if vehicle == 0 then
            util.toast("that player is not driving a vehicle")
            return
        end
        boost_vehicle(vehicle, 50)
    end)

    menu.action(menu_list, "Remove vehicle god mode", {}, "Removes the players god mode (won't work if the player has protections)", function ()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)
        if vehicle ~= 0 then

            remove_vehicle_god(vehicle)

        end
    end)
end

local function player_chat_options(pid, menu_list)
    menu.divider(menu_list, "Chat")
    menu.action(menu_list, "Send private chat message", {"chatto"}, "Sends message to this player only",
        function (click_type)
            menu.show_command_box_click_based(click_type, "chatto" .. players.get_name(pid) .. " ")
        end,
        function (txt)
            local from = players.user()
            local me = players.user()
            local to = pid
            local message = txt
            chat.send_targeted_message(to, from, message, false)
            chat.send_targeted_message(me, from, '(shows for you and ' .. players.get_name(to) .. ') ' .. message, false)
        end)

    menu.action(menu_list, "Send message to everyone except this player", {"chatexcept"}, "Sends message to this player only",
        function (click_type)
            menu.show_command_box_click_based(click_type, "chatexcept" .. players.get_name(pid) .. " ")
        end,
        function (txt)
            for k,v in pairs(players.list(true, true, true)) do
                if v ~= pid then
                    chat.send_targeted_message(v, players.user(), txt, false)
                end
            end
        end)
end

    local message = "Subscribe to TDOD Disease on YouTube thanks"
    local delay = 80
    local max = 100
        -- chat.send_message has some sort of rate limit for some reason
    menu.divider(chat_root, "Advanced")
    menu.slider(chat_root, "Spam speed", {},  "spam delay", 0, max, delay, 2, function (v)
        delay = v
    end)

local function player_toxic_chat_options(pid, menu_list)
    menu.divider(menu_list, "Chat")
    menu.action(menu_list, "Chat as " .. players.get_name(pid), {"chatasplayer"}, "Spoofs your chat username name",
        function (click_type)
            menu.show_command_box_click_based(click_type, "chatasplayer" .. players.get_name(pid) .. " ")
        end,
        function (txt)
            local from = pid
            local message = txt
            for k,v in pairs(players.list(true, true, true)) do
                chat.send_targeted_message(v, from, message, false)
            end
        end)

    player_chat_spammer = menu.list(menu_list, "Spam " .. players.get_name(pid), {"chatspam"}, "spam this user")

    player_chat_spam(pid, player_chat_spammer)

    -- menu.toggle_loop(menu_list, "Spam " .. players.get_name(pid), {}, )
end

local function player_trolling_options(pid, menu_list)
    menu.divider(menu_list, "Neutral")
    menu.action(menu_list, "Dog explosion", {}, "Woof", function ()

        ped_explosion(pid, "a_c_retriever")

    end)

    menu.action(menu_list, "Cat explosion", {}, "Meow", function ()

        ped_explosion(pid, "a_c_cat_01")

    end)
end

players.on_join(
    function(pid)
        menu.divider(menu.player_root(pid), "TDODScript (" .. players.get_name(pid) .. ")")
        player_toxic_root = menu.list(menu.player_root(pid), "Toxic", {}, "Toxic options for " .. players.get_name(pid))
        player_friendly_root = menu.list(menu.player_root(pid), "Friendly", {}, "Friendly options for " .. players.get_name(pid))
        player_neutral_root = menu.list(menu.player_root(pid), "Neutral", {}, "Neutral options for " .. players.get_name(pid))

        -- toxic

        player_general_toxic_options(pid, player_toxic_root)

        player_vehicle_toxic_options(pid, player_toxic_root)

        -- friendly

        player_vehicle_options(pid, player_friendly_root)

        -- neutral

        player_trolling_options(pid, player_neutral_root)

    end
    
) players.dispatch_on_join()

local function everyone_toxic_options(menu_list)

    menu.divider(menu_list, "Toxic / Troll")
    menu.toggle_loop(menu_list, 'Spawn Trash Bags', {}, 'After you kill a Player it will put trash bags on their Dead Body and also sends a Toxic text to them! [on/off]', function()
        if Attacker_ == players.user() and PED.IS_PED_DEAD_OR_DYING(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(Victim_), 1)then 
         menu.trigger_commands('smstext'..players.get_name(Victim_)..' Congrats your Trash at GTA') menu.trigger_commands('smssend'..players.get_name(Victim_))
         while true do
        local victim_coords = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(Victim_))
        local bags = entities.create_object(1138881502, victim_coords)
        entities.get_all_objects_as_handles(bags)
         util.yield(500)
         break
         end
     end
     end)

    menu.toggle_loop(menu_list, "Screen shaker", {"shakeeveryone"}, "Shakes everyones screen [on/off]", function()
        for k,v in pairs(players.list(true, true, true)) do
            shake_player(v, 5000)
            util.yield()
        end

        util.yield(1000)

    end)



    menu.action(menu_list, "Kill without explosion", {"killeveryone"}, "Silently kill everyone", function()

        for k,v in pairs(players.list(false, true, true)) do

            kill_player(v)

            util.yield()

        end

    end)



    menu.action(menu_list, "Passive mode kill", {"passivekilleveryone"}, "Passive mode kill everyone", function()

        for k,v in pairs(players.list(false, true, true)) do

            passive_mode_kill(v)

        end

    end)



    menu.divider(menu_list, "")

    menu.divider(menu_list, "Vehicle Trolls")



    menu.toggle_loop(menu_list, "Jumpy car", {"jumpycareveryone"}, "Makes everyone's car jump", function()

        for k,v in pairs(players.list(true, true, true)) do

            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(v)

    

            if PED.IS_PED_IN_ANY_VEHICLE(ped) then

                local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)



                request_control_of_entity(vehicle)

    

                if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then

                    make_car_jump(vehicle, 5)

                end

    

                util.yield(300)

            end

        end

    end)



    menu.toggle_loop(menu_list, "Ultra jumpy car", {"jumpycareveryone"}, "Makes everyone's car jump", function()

        for k,v in pairs(players.list(true, true, true)) do

            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(v)

    

            if PED.IS_PED_IN_ANY_VEHICLE(ped) then

                local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)



                request_control_of_entity(vehicle)

    

                if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then

                    make_car_jump(vehicle, 25)

                end

            end

        end

    

        util.yield(1000)

    end)



    menu.action(menu_list, "Launch vehicle in the air", {}, "Send everyones car flying", function ()

        for k,v in pairs(players.list(true, true, true)) do

            send_player_vehicle_flying(v)

            

        end

    end)



    local explosion_circle_angle = 0

    menu.toggle_loop(menu_list, "Explosion circle", {}, "Circle Of Explosion [On/Off]", function ()

        for k,v in pairs(players.list(true, true, true)) do

            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(v)

            explosion_circle(ped, explosion_circle_angle, 25)

        end



        explosion_circle_angle += 0.15

        util.yield(50)

    end)



    menu.action(menu_list, "Invisible vehicle EMP", {}, "Makes everyone's car stall", function ()

        for k,v in pairs(players.list(true, true, true)) do

            vehicle_emp(v)

            

        end

    end)



    menu.action(menu_list, "Remove vehicle god mode", {}, "Remove Vehicle God mode makes players cars not God mode!", function ()

        for k,v in pairs(players.list(false, true, true)) do

            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(v)

            local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped)

    

            if vehicle ~= 0 then

                remove_vehicle_god(vehicle)

                

            end

        end

    end)

end



local function everyone_fun_options(menu_list)



    menu.action(menu_list, "Spawn Oppressor", {"oppressorparty"}, "Spawn everyone an oppressor", function ()

        chat.send_message("", false, true, true)

        for k,v in pairs(players.list(true, true, true)) do

            give_vehicle(v,"oppressor2")

            util.yield()

        end

    end)

	

	 menu.action(menu_list, "Spawn Tank", {"tankparty"}, "Spawn everyone an tank", function ()

        chat.send_message("", false, true, true)

        for k,v in pairs(players.list(true, true, true)) do

            give_vehicle(v,"rhino")

            util.yield()

        end

    end)

	

	 menu.action(menu_list, "Spawn Space Docker", {"dockerparty"}, "Spawn everyone an Space Docker", function ()
        chat.send_message("", false, true, true)
        for k,v in pairs(players.list(true, true, true)) do
            give_vehicle(v,"dune2")
            util.yield()
        end
		end)

		menu.action(menu_list, "Spawn Deluxo", {"deluxoparty"}, "Spawn everyone an deluxo", function ()
        chat.send_message("", false, true, true)
        for k,v in pairs(players.list(true, true, true)) do
            give_vehicle(v,"deluxo")
            util.yield()
        end
    end)
	
	menu.action(menu_list, "Spawn Classique Broadway Taxi", {"broadwayparty"}, "Spawn everyone an Classique Broadway", function ()
        chat.send_message("", false, true, true)
        for k,v in pairs(players.list(true, true, true)) do
            give_vehicle(v,"broadway")
            util.yield()
        end
		end)
		
		menu.action(menu_list, "Spawn Cara4X4 Truck ", {"caracara2party"}, "Spawn everyone an Cara4X4 Truck", function ()
        chat.send_message("", false, true, true)
        for k,v in pairs(players.list(true, true, true)) do
            give_vehicle(v,"caracara2")
            util.yield()
        end
		end)
		
		menu.action(menu_list, "Spawn Panthere Super", {"panthereparty"}, "Spawn everyone an Panthere Super", function ()
        chat.send_message("", false, true, true)
        for k,v in pairs(players.list(true, true, true)) do
            give_vehicle(v,"panthere")
            util.yield()
        end
		end)
		
		menu.action(menu_list, "Spawn R300 Super", {"r300party"}, "Spawn everyone an R300 Super", function ()
        chat.send_message("", false, true, true)
        for k,v in pairs(players.list(true, true, true)) do
            give_vehicle(v,"r300")
            util.yield()
        end
		end)
		
		menu.action(menu_list, "Spawn Virtue Super", {"r300party"}, "Spawn everyone an Virtue Super", function ()
        chat.send_message("", false, true, true)
        for k,v in pairs(players.list(true, true, true)) do
            give_vehicle(v,"virtue")
            util.yield()
        end
		end)
		
		menu.action(menu_list, "Spawn Party Bus", {"r300party"}, "Spawn everyone an Spawn Party Bus", function ()
        chat.send_message("", false, true, true)
        for k,v in pairs(players.list(true, true, true)) do
            give_vehicle(v,"pbus2")
            util.yield()
        end
		end)

		menu.action(menu_list, "Spawn Scramjet", {"scramjetparty"}, "Spawn everyone an Scamjet", function ()
        chat.send_message("", false, true, true)
        for k,v in pairs(players.list(true, true, true)) do
            give_vehicle(v,"scramjet")
            util.yield()
        end
		end)
		
		menu.action(menu_list, "Spawn Tezeract", {"tezeractparty"}, "Spawn everyone an Tezeract", function ()
        chat.send_message("", false, true, true)
        for k,v in pairs(players.list(true, true, true)) do
            give_vehicle(v,"tezeract")
            util.yield()
        end
		end)
		
		menu.action(menu_list, "Spawn TDOD'S First GTA5 Online Car", {"rustonparty"}, "Spawn everyone an TDOD'S First GTA5 Car", function ()
        chat.send_message("", false, true, true)
        for k,v in pairs(players.list(true, true, true)) do
            give_vehicle(v,"ruston")
            util.yield()
        end
		end)
		
		menu.action(menu_list, "Spawn Ruiner 2000", {"ruiner2party"}, "Spawn everyone an Spawn Ruiner 2000", function ()
        chat.send_message("", false, true, true)
        for k,v in pairs(players.list(true, true, true)) do
            give_vehicle(v,"ruiner2")
            util.yield()
        end
		end)
		menu.action(menu_list, "Spawn Ramp Buggy", {"dune5party"}, "Spawn everyone an Ramp Buggy", function ()
        chat.send_message("", false, true, true)
        for k,v in pairs(players.list(true, true, true)) do
            give_vehicle(v,"dune5")
            util.yield()
        end
		end)
end

local function everyone_friendly_options(menu_list)
    menu.divider(menu_list, "Friendly (Everybody)")
    menu.action(menu_list, "Spawn vehicle", {"spawnvehicleeveryone"}, "Spawn Everyone a Vehicle",
    function (click_type)
        menu.show_command_box_click_based(click_type, "spawnvehicleeveryone ")
    end,

    function (txt)
        local hash = util.joaat(txt)
        if not STREAMING.HAS_MODEL_LOADED(hash) then
            load_model(hash)
        end

        for k,v in pairs(players.list(true, true, true)) do
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(v)
            local c = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 5.0, 0.0)
            local vehicle = entities.create_vehicle(hash, c, 0)
            request_control_of_entity(vehicle)
            util.yield()
        end
    end)
end

    local mode = 1
    local message = "Here is a fun fact. If you dont Subscribe to TDOD you are a fucking Brokie, not only that Uza Bitch #Stand on Top! "
    local delay = 80
    local max = 100

    menu.toggle_loop(chat_root, "Enable Chat Spammer", {}, "Lets you Spam Chat [On/Off]", function()
        local delay = (max - delay) * 10
        if mode == 1 then
            -- chat.send_message has some sort of rate limit for some reason
            for k,v in pairs(players.list(true, true, true)) do
                chat.send_targeted_message(v, players.user(), message, false)
            end
            util.yield(delay)
        elseif mode == 2 then
            for k1,v1 in pairs(players.list(true, true, true)) do
                for k2,v2 in pairs(players.list(true, true, true)) do
                    chat.send_targeted_message(v2, v1, message, false)
                end
                util.yield(delay)
            end
        end
    end)

    local options = {
		"Normal spam",
		"Everyone spamming"
	}

    menu.slider_text(chat_root, "Mode", {}, "", options, function(op)
        mode = op
        util.toast(op)
    end)

    menu.text_input(chat_root, "Message", {"spammessage"}, "(You can Change The Text yourself Example: 2Take1 Is a Waste of $120!)", function(txt)
        message = txt
    end, message)

    menu.slider(chat_root, "Chat Spam Spammer", {},  "spam delay", 0, max, delay, 2, function (v)
        delay = v
    end)

local function self_experimental_features(menu_list)
    menu.divider(menu_list, "Experimental features")
    menu.action(menu_list, "Spinny Car", {}, "", function()
        local c = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0.0, 5.0, 0.0)
        local hash = util.joaat("jester3")
        if not STREAMING.HAS_MODEL_LOADED(hash) then
            load_model(hash)
        end
        local vehicle = entities.create_vehicle(hash, c, 0)
        request_control_of_entity(vehicle)
        if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
            util.toast("has control")
        end
        util.create_tick_handler(function ()
            local heading = ENTITY.GET_ENTITY_HEADING(vehicle)
            heading = heading + 2.5
            ENTITY.SET_ENTITY_HEADING(vehicle, heading)
            util.yield_once()
        end)
    end)
end

local function self_helpful_features(menu_list)
    menu.divider(menu_list, "Helpful features")
    reclaim = menu.list(menu_list, "Reclaim Vehicles")
    menu.toggle_loop(reclaim, "Auto Claim Destroyed Vehicles", {}, "Automatically claims destroyed vehicles so you won't have to.\nLess efficient performance-wise.", function()
        reclaimAll()
        util.yield(100)
    end)
    menu.action(reclaim, "Claim Destroyed Vehicles", {}, "Claims destroyed vehicles so you won't have to.", function()
        reclaimAll()
    end)
    
end

local function experimental_options(menu_list)
    local experimental_features = menu.list(menu_list, "Experimental Features", {}, "Features that are Experimental ")
    self_experimental_features(experimental_features)
end

local function helpful_options(menu_list)
    local helpfull_features = menu.list(menu_list, "Helpful Features", {""}, "")
    self_helpful_features(helpfull_features)
end

local function render_waypoint_at(loc)

    -- GRAPHICS._DRAW_SPHERE(loc.x, loc.y, loc.z, 0.4, 255, 100, 255, 100)

    GRAPHICS.DRAW_LINE(loc.x, loc.y, loc.z, loc.x, loc.y, loc.z + 100, 255, 100, 255, 100)

end


everyone_toxic_options(toxic_root)
everyone_fun_options(fun_root)
everyone_friendly_options(friendly_root)
experimental_options(online_root)
helpful_options(online_root)

menu.divider(render_root, '(Close Friends!)')

menu.divider(render_root2, '(Special thanks too!)')
menu.divider(render_root2, '-THEKING-')
menu.divider(render_root2, 'Davus')
menu.divider(render_root2, 'Brick')
menu.divider(render_root2, 'Prisuhm')
menu.divider(render_root2, 'Igieusz')

friends_list = {'Igieusz', 'Prisuhm', 'MrSus', 'XI-GHOST̸-IX', 'LurryG4', 'diorr'}
random_numbers = {}
random_numbers[1] = math.random(1, 6)
random_numbers[2] = math.random(1, 6)
random_numbers[3] = math.random(1, 6)

while random_numbers[1] == random_numbers[2] do 
    random_numbers[2] = math.random(1, 6)
    util.yield()
end

while random_numbers[2] == random_numbers[3] or random_numbers[1] == random_numbers[3] do 
    random_numbers[3] = math.random(1, 6)
    util.yield()
end
        menu.divider(render_root, tostring(friends_list[random_numbers[1]]))
        menu.divider(render_root, tostring(friends_list[random_numbers[2]]))
        menu.divider(render_root, tostring(friends_list[random_numbers[3]]))

menu.divider(render_root, "YouTube/Discord!")

menu.hyperlink(render_root, 'TDOD Youtube', "https://www.youtube.com/@TDODYT", 'Click this!')

menu.hyperlink(render_root, 'TDOD Discord', "https://discord.gg/R4DPNQjddv", 'Click this!')

-- GUI CODE

local window_x = 0.01
local window_y = 0.03
local text_margin = 0.003
local text_height = 0.018 -- (not accurate lol)
local window_width = 0.12
local window_height = 0.2
local menu_items = {
    "menu option 1",
    "menu option 2",
    "menu option 3",
    "menu option 4",
    "menu option 5"
}
local selected_index = 0
local blur_rect_instance

local function colour(r, g, b, a)
    return { -- colour values go between 0 and 1
        r = r / 255,
        g = g / 255,
        b = b / 255,
        a = a / 255
    }
end

local function gui_background(x, y, width, height, blur_radius)
    local background = colour(10, 0, 10, 100)
    local border_color_left = colour(255, 0, 255, 255)
    local border_color_right = colour(0, 0, 0, 255)
    directx.blurrect_draw(
        blur_rect_instance, 
        x, y, width, height,
        blur_radius or 5
    )

    directx.draw_rect(
        x, y,
        width, height,
        background
    )
    -- left border line
    directx.draw_line(
        x, y,
        x, y + height,
        border_color_left
    )

    -- top border line
    directx.draw_line(
        x, y,
        x + width, y,
        border_color_left, border_color_right
    )

    directx.draw_line(
        x + width, y,
        x + width, y + height,
        border_color_right
    )
    -- bottom border line
    directx.draw_line(
        x, y + height,
        x + width, y + height,
        border_color_left, border_color_right
    )
end

local function text(text, x, y, text_scale, highlighted)

    if highlighted then

        directx.draw_rect(

            x, y,

            window_width - (text_margin * 2), text_height,

            colour(15, 15, 15, 0)

        )

    end



    directx.draw_text(

        x, y, text, ALIGN_TOP_LEFT, text_scale,

        colour(255, 255, 255, 255)

    )

end



local function render_list(x, y, list, selected_index)

    local ty = 0

    local text_scale = 0.5 -- dont change :)



    for i,v in pairs(list) do

        local highlighed = i == selected_index - 1



        text(v, x, y + ty, text_scale, highlighed)

        ty = ty + text_height

    end

end



local function edition_string()

    local edition = menu.get_edition()



    if edition == 0 then

        return "free"

    elseif edition == 1 then

        return "basic"

    elseif edition == 2 then

        return "regular"

    elseif edition == 3 then

        return "ultimate"

    end

end



local function render_menu()

    local width = window_width

    local height = window_height



    gui_background(window_x, window_y,

        width, height)



    text("Stand " .. edition_string(),

        window_x + text_margin,

        window_y + text_margin,

        0.6, false)

    

    local top_margin = 0.025

    

    render_list(

        window_x + text_margin,

        window_y + text_margin + top_margin,

        menu_items, selected_index

    )

end



local function set_menu_open(toggle) end -- this needs to be defined before input_handler but after tick_handler



local menu_is_open = false



local function input_handler()

    if menu.is_open() then return end



    local VK_NUMPAD8 = 0x68

    local VK_NUMPAD2 = 0x62



    if util.is_key_down(VK_NUMPAD2) then

        selected_index = selected_index + 1



    elseif util.is_key_down(VK_NUMPAD8) then

        selected_index = selected_index - 1



    end

end



local function tick_handler()
    if menu_is_open then
        render_menu()
    end
    input_handler()
    return true
end

blur_rect_instance = directx.blurrect_new()
util.create_tick_handler(tick_handler) -- start the loop (it stops when menu_is_open is false)

function set_menu_open(toggle)
    if toggle and not menu_is_open then
        menu_is_open = true
    elseif not toggle and menu_is_open then
        menu_is_open = false
    end
end

local screenx, screeny = 1920, 1080

local kick_box_x, kick_box_y= 0, 0 -- position
local kick_box_s_x, kick_box_s_y = 0, 0 -- scale
local kick_text_x, kick_text_y = 0, 0 -- position
local kick_scale = 0 -- scale

local crash_box_x, crash_box_y= 0, 0 -- position
local crash_box_s_x, crash_box_s_y = 0, 0 -- scale
local crash_text_x, crash_text_y = 0, 0 -- position
local crash_scale = 0 -- scale



local tp_box_x, tp_box_y= 0, 0 -- position
local tp_box_s_x, tp_box_s_y = 0, 0 -- scale
local tp_text_x, tp_text_y = 0, 0 -- position
local tp_scale = 0 -- scale

local summon_box_x, summon_box_y= 0, 0 -- position
local summon_box_s_x, summon_box_s_y = 0, 0 -- scale
local summon_text_x, summon_text_y = 0, 0 -- position
local summon_scale = 0 -- scale

local tv_box_x, tv_box_y= 0, 0 -- position
local tv_box_s_x, tv_box_s_y = 0, 0 -- scale
local tv_text_x, tv_text_y = 0, 0 -- position
local tv_scale = 0 -- scale

local show_box_x, show_box_y= 0, 0 -- position
local show_box_s_x, show_box_s_y = 0, 0 -- scale
local show_text_x, show_text_y = 0, 0 -- position
local show_scale = 0 -- scale

local vision
local presets = {
                 'NONE', 
                 'CELEBRATION_WINNER', 'CHARACTER_CREATOR_HERITAGE', 
                 'FACE_CREATION_CONFIRM', 'FACE_CREATION_PRESET', 
                 'MPLOBBY_ALL5SLOTS', 'PAUSE_SINGLE_LEFT', 
                 'PAUSE_SINGLE_MIDDLE', 'PAUSE_SINGLE_RIGHT'
                }

local showbuttons = false

local bsettings = menu.list(buttonslist, 'Button Setting', {'bs'}, '',
function()
	showbuttons = true
end, function()
	showbuttons = false
end)
menu.action(bsettings,'                           Restart Script', {'restartbuttons'},'', function() util.restart_script() end)

---------------------------------show+activate buttons--------------------------------------

local activated = false
menu.toggle_loop(bsettings, "Show Buttons", {}, '', function() 
    if not activated then activated = true 
        util.toast('Buttons activated') 
    end 
end, function() 
    if activated then activated = false 
        util.toast('Buttons deactivated')
    end   
end)

------------------------------------------Show-----------------------------------------------------

menu.list_select(bsettings, 'Show Preset', {}, '', presets, 1,  function(cam)
vision = presets[cam]
end)

-----------------------------------------------------------------------------------------------

menu.divider(bsettings, 'Kick')
local kick_boxsliders = menu.list(bsettings, 'Kick Box Slider', {}, '')
local kick_textsliders = menu.list(bsettings, 'Kick Text Slider', {}, '')

menu.divider(bsettings, 'Crash')
local crash_boxliders = menu.list(bsettings, 'Crash Box Slider', {}, '')
local crash_textsliders = menu.list(bsettings, 'Crash Text Slider', {}, '')

menu.divider(bsettings, 'TP')
local tp_boxliders = menu.list(bsettings, 'TP Box Slider', {}, '')
local tp_textsliders = menu.list(bsettings, 'TP Text Slider', {}, '')
local summon_boxliders = menu.list(bsettings, 'TP to ME Box Slider', {}, '')
local summon_textsliders = menu.list(bsettings, 'TP to ME Text Slider', {}, '')

menu.divider(bsettings, 'Spectate')
local tv_boxliders = menu.list(bsettings, 'Spectate Box Slider', {}, '')
local tv_textsliders = menu.list(bsettings, 'Spectate Text Slider', {}, '')
local show_boxliders = menu.list(bsettings, 'Show Box Slider', {}, '')
local show_textsliders = menu.list(bsettings, 'Show Text Slider', {}, '')

--------------------------------BOX/TEXT Kick------------------------------------------------

menu.slider(kick_boxsliders, "X:", {'kbx'}, "", 0, screenx, 0, 10, function(change)
    kick_box_x = change/screenx
end)

menu.slider(kick_boxsliders, "Y:", {'kby'}, "", 0, screeny, 0, 10, function(change)
    kick_box_y = change/screeny
end)

menu.slider(kick_boxsliders, "Scale X:", {}, "", 0, 1000, 0, 1, function(change)
    kick_box_s_x = change/1000
end)

menu.slider(kick_boxsliders, "Scale Y:", {}, "", 0, 1000, 0, 1, function(change)
    kick_box_s_y = change/1000
end)

menu.slider(kick_textsliders, "X:", {'ktx'}, "", 0, screenx, 0, 10, function(change)
    kick_text_x = change/screenx
end)

menu.slider(kick_textsliders, "Y:", {'kty'}, "", 0, screeny, 0, 10, function(change)
    kick_text_y = change/screeny
end)

menu.slider(kick_textsliders, "Scale:", {}, "", 0, 1000, 0, 1, function(change)
    kick_scale = change/100
end)
---------------------------------------------------------------------------------

--------------------------------BOX/TEXT Crash------------------------------------------------
menu.slider(crash_boxliders, "X:", {'cbx'}, "", 0, screenx, 0, 10, function(change)
    crash_box_x = change/screenx
end)

menu.slider(crash_boxliders, "Y:", {'cby'}, "", 0, screeny, 0, 10, function(change)
    crash_box_y = change/screeny
end)

menu.slider(crash_boxliders, "Scale X:", {}, "", 0, 1000, 0, 1, function(change)
    crash_box_s_x = change/1000
end)

menu.slider(crash_boxliders, "Scale Y:", {}, "", 0, 1000, 0, 1, function(change)
    crash_box_s_y = change/1000
end)

menu.slider(crash_textsliders, "X:", {'ctx'}, "", 0, screenx, 0, 10, function(change)
    crash_text_x = change/screenx
end)

menu.slider(crash_textsliders, "Y:", {'cty'}, "", 0, screeny, 0, 10, function(change)
    crash_text_y = change/screeny
end)

menu.slider(crash_textsliders, "Scale:", {}, "", 0, 1000, 0, 1, function(change)
    crash_scale = change/100
end)
---------------------------------------------------------------------------------

--------------------------------BOX/TEXT TP------------------------------------------------
menu.slider(tp_boxliders, "X:", {'tpbx'}, "", 0, screenx, 0, 10, function(change)
    tp_box_x = change/screenx
end)

menu.slider(tp_boxliders, "Y:", {'tpby'}, "", 0, screeny, 0, 10, function(change)
    tp_box_y = change/screeny
end)

menu.slider(tp_boxliders, "Scale X:", {}, "", 0, 1000, 0, 1, function(change)
    tp_box_s_x = change/1000
end)

menu.slider(tp_boxliders, "Scale Y:", {}, "", 0, 1000, 0, 1, function(change)
    tp_box_s_y = change/1000
end)

menu.slider(tp_textsliders, "X:", {'tptx'}, "", 0, screenx, 0, 10, function(change)
    tp_text_x = change/screenx
end)

menu.slider(tp_textsliders, "Y:", {'tpty'}, "", 0, screeny, 0, 10, function(change)
    tp_text_y = change/screeny
end)

menu.slider(tp_textsliders, "Scale:", {}, "", 0, 1000, 0, 1, function(change)
    tp_scale = change/100
end)
---------------------------------------------------------------------------------

--------------------------------BOX/TEXT summon------------------------------------------------

menu.slider(summon_boxliders, "X:", {'summonbx'}, "", 0, screenx, 0, 10, function(change)
    summon_box_x = change/screenx
end)

menu.slider(summon_boxliders, "Y:", {'summonby'}, "", 0, screeny, 0, 10, function(change)
    summon_box_y = change/screeny
end)

menu.slider(summon_boxliders, "Scale X:", {}, "", 0, 1000, 0, 1, function(change)
    summon_box_s_x = change/1000
end)

menu.slider(summon_boxliders, "Scale Y:", {}, "", 0, 1000, 0, 1, function(change)
    summon_box_s_y = change/1000
end)

menu.slider(summon_textsliders, "X:", {'summontx'}, "", 0, screenx, 0, 10, function(change)
    summon_text_x = change/screenx
end)

menu.slider(summon_textsliders, "Y:", {'summonty'}, "", 0, screeny, 0, 10, function(change)
    summon_text_y = change/screeny
end)

menu.slider(summon_textsliders, "Scale:", {}, "", 0, 1000, 0, 1, function(change)
    summon_scale = change/100
end)
---------------------------------------------------------------------------------

--------------------------------BOX/TEXT spectate------------------------------------------------
menu.slider(tv_boxliders, "X:", {'tvbx'}, "", 0, screenx, 0, 10, function(change)
    tv_box_x = change/screenx
end)

menu.slider(tv_boxliders, "Y:", {'tvby'}, "", 0, screeny, 0, 10, function(change)
    tv_box_y = change/screeny
end)

menu.slider(tv_boxliders, "Scale X:", {}, "", 0, 1000, 0, 1, function(change)
    tv_box_s_x = change/1000
end)

menu.slider(tv_boxliders, "Scale Y:", {}, "", 0, 1000, 0, 1, function(change)
    tv_box_s_y = change/1000
end)

menu.slider(tv_textsliders, "X:", {'tvtx'}, "", 0, screenx, 0, 10, function(change)
    tv_text_x = change/screenx
end)

menu.slider(tv_textsliders, "Y:", {'tvty'}, "", 0, screeny, 0, 10, function(change)
    tv_text_y = change/screeny
end)

menu.slider(tv_textsliders, "Scale:", {}, "", 0, 1000, 0, 1, function(change)
    tv_scale = change/100
end)
---------------------------------------------------------------------------------

--------------------------------BOX/TEXT spectate------------------------------------------------
menu.slider(show_boxliders, "X:", {'shbx'}, "", 0, screenx, 0, 10, function(change)
    show_box_x = change/screenx
end)

menu.slider(show_boxliders, "Y:", {'shby'}, "", 0, screeny, 0, 10, function(change)
    show_box_y = change/screeny
end)

menu.slider(show_boxliders, "Scale X:", {}, "", 0, 1000, 0, 1, function(change)
    show_box_s_x = change/1000
end)

menu.slider(show_boxliders, "Scale Y:", {}, "", 0, 1000, 0, 1, function(change)
    show_box_s_y = change/1000
end)

menu.slider(show_textsliders, "X:", {'shtx'}, "", 0, screenx, 0, 10, function(change)
    show_text_x = change/screenx
end)

menu.slider(show_textsliders, "Y:", {'shty'}, "", 0, screeny, 0, 10, function(change)
    show_text_y = change/screeny
end)

menu.slider(show_textsliders, "Scale:", {}, "", 0, 1000, 0, 1, function(change)
    show_scale = change/100
end)

---------------------------------------------------------------------------------
menu.action(locations_root, "Tp to Crack House" , {''}, "crack house", function()
    ENTITY.SET_ENTITY_COORDS(players.user_ped(), 21.451893, -1899.0763, 22.96029, true,true,true,false)
    end)
    
    menu.action(locations_root, "Tp to Humane Labs" , {''}, "Humane Labs", function()
        ENTITY.SET_ENTITY_COORDS(players.user_ped(), 3620.17, 3735.0544, 28.690018, true,true,true,false)
        end)

    menu.action(locations_root, "Tp to Airport Hideout1" , {''}, "Airport hideout1", function()
    ENTITY.SET_ENTITY_COORDS(players.user_ped(), -1570.0732, -3226.4028, 26.336178, true,true,true,false)
    end)
    
    menu.action(locations_root, "Tp to Airport Hideout2" , {''}, "Airport Hideout2", function()
        ENTITY.SET_ENTITY_COORDS(players.user_ped(), -1036.0248, -2858.7542, 37.976738 , true,true,true,false)
        end)
    
    menu.action(locations_root, "Tp to Tower" , {''}, "Tower", function()
    ENTITY.SET_ENTITY_COORDS(players.user_ped(), -2360.1743,  3243.625,  92.903656, true,true,true,false)
    end)
    
    menu.action(locations_root, "Tp to Strip Joint" , {''}, "Strip Club", function()
        ENTITY.SET_ENTITY_COORDS(players.user_ped(), 117.070625, -1285.9769, 28.25858, true,true,true,false)
        end)
    menu.action(locations_root, "Tp to Money Vault" , {''}, "Vault", function()
    ENTITY.SET_ENTITY_COORDS(players.user_ped(), -104.87469, 6476.4736, 31.62673, true,true,true,false)
    end)
    menu.action(locations_root, "Tp to Blaine County Sheriff's Office" , {''}, "Blaine County Sheriff's Office", function()
        ENTITY.SET_ENTITY_COORDS(players.user_ped(), -111.5643,  6466.7744, 31.626726, true,true,true,false)
        end)
        menu.action(locations_root, "Tp to City vault" , {''}, "City Vault", function()
    ENTITY.SET_ENTITY_COORDS(players.user_ped(), 256.18076, 217.24535, 101.68346, true,true,true,false)
    end)
    menu.action(locations_root, "Tp to Car Wash" , {''}, "Car Wash", function()
        ENTITY.SET_ENTITY_COORDS(players.user_ped(), 52.178577, -1392.2101, 28.978891, true,true,true,false)
        end)
    menu.action(locations_root, "Tp to TDOD'S Secret PC Set up" , {''}, "TDOD Secret PC Set up", function()
    ENTITY.SET_ENTITY_COORDS(players.user_ped(), -1056.7798, -233.37662, 44.021145, true,true,true,false)
    end)
    menu.action(locations_root, "Tp to GTA6 Room" , {''}, "GTA6 Room", function()
        ENTITY.SET_ENTITY_COORDS(players.user_ped(), 152.70825, -1003.62555, -98.99995, true,true,true,false)
        end)
        menu.action(locations_root, "Tp to Safe Room" , {''}, "Safe Room", function()
    ENTITY.SET_ENTITY_COORDS(players.user_ped(), 160.868, -745.831, 250.063, true,true,true,false)
    end)
    menu.action(locations_root, "Tp to Gun Store" , {''}, "Gun Store", function()
        ENTITY.SET_ENTITY_COORDS(players.user_ped(), 240.911, -44.41237, 69.70182, true,true,true,false)
        end)

    --[[locations_root = menu.list(menu.online_root(), "Locations", {}, "")
    LOCATIONS_MENU_ROOT = menu.attach_before(menu.ref_by_path("location>New Session"), locations_root)
    menu.action(LOCATIONS_MENU_ROOT, "An Action", {}, "", function()
        util.toast("Hi")
    end)]] --????

local spec_value = 'Spectate'
local show_value = 'Show' 

util.create_tick_handler(function()
    while activated do
            local x = (PAD.GET_DISABLED_CONTROL_NORMAL(2, 239))
            local y = (PAD.GET_DISABLED_CONTROL_NORMAL(2, 240))
            local pid = players.get_focused()
            if ((pid[1] != nil and pid[2] == nil) or showbuttons) and menu.is_open() then
            --------------------------------------------kick----------------------------------------------------------------
            if x >= kick_box_x and x<= kick_box_x+kick_box_s_x and y >= kick_box_y and y <= kick_box_y+kick_box_s_y 
                and PAD.IS_CONTROL_JUST_PRESSED('INPUT_CELLPHONE_SELECT', 176) then 
                local pid = players.get_focused()
                if (pid[1] != nil and pid[2] == nil) and menu.is_open() then
                menu.trigger_commands('kick'..players.get_name(pid[1]))
                    end
                end
            --------------------------------------------crash----------------------------------------------------------------
            if x >= crash_box_x and x<= crash_box_x+crash_box_s_x and y >= crash_box_y and y <= crash_box_y+crash_box_s_y 
                and PAD.IS_CONTROL_JUST_PRESSED('INPUT_CELLPHONE_SELECT', 176) then 
                local pid = players.get_focused()
                if (pid[1] != nil and pid[2] == nil) and menu.is_open() then
                menu.trigger_commands('crash'..players.get_name(pid[1]))
                    end
                end
            --------------------------------------------tp----------------------------------------------------------------
            if x >= tp_box_x and x<= tp_box_x+tp_box_s_x and y >= tp_box_y and y <= tp_box_y+tp_box_s_y 
                and PAD.IS_CONTROL_JUST_PRESSED('INPUT_CELLPHONE_SELECT', 176) then 
                local pid = players.get_focused()
                if (pid[1] != nil and pid[2] == nil) and menu.is_open() then
                menu.trigger_commands('tp'..players.get_name(pid[1]))
                    end
                end
            -------------------------------------------summon----------------------------------------------------------------
            if x >= summon_box_x and x<= summon_box_x+summon_box_s_x and y >= summon_box_y and y <= summon_box_y+summon_box_s_y
                and PAD.IS_CONTROL_JUST_PRESSED('INPUT_CELLPHONE_SELECT', 176) then 
                local pid = players.get_focused()
                if (pid[1] != nil and pid[2] == nil) and menu.is_open() then
                menu.trigger_commands('summon'..players.get_name(pid[1]))
                    end
                end
                --------------------------------------------spectate----------------------------------------------------------------
            if x >= tv_box_x and x<= tv_box_x+tv_box_s_x and y >= tv_box_y and y <= tv_box_y+tv_box_s_y
            and PAD.IS_CONTROL_JUST_PRESSED('INPUT_CELLPHONE_SELECT', 176) then 
            local pid = players.get_focused()
            if (pid[1] != nil and pid[2] == nil) and menu.is_open() then
                if spec_value == 'Spectate' then spec_value = 'Stop' menu.trigger_commands('spectate'..players.get_name(pid[1]))
                elseif spec_value == 'Stop' then spec_value = 'Spectate' menu.trigger_commands('stopspectating')
                end
                end
            end
            --------------------------------------------show----------------------------------------------------------------
            if x >= show_box_x and x<= show_box_x+show_box_s_x and y >= show_box_y and y <= show_box_y+show_box_s_y
                and PAD.IS_CONTROL_JUST_PRESSED('INPUT_CELLPHONE_SELECT', 176) then 
                local pid = players.get_focused()
                if (pid[1] != nil and pid[2] == nil) and menu.is_open() then
                    if show_value == 'Show' then show_value = 'Hide'
                        elseif show_value == 'Hide' then show_value = 'Show'  
                    end

                    util.create_tick_handler(function()
                        local pid = players.get_focused()
                        if ((pid[1] != nil and pid[2] == nil) or showbuttons) and menu.is_open() and
                        GRAPHICS.UI3DSCENE_IS_AVAILABLE() then
                            if GRAPHICS.UI3DSCENE_PUSH_PRESET(tostring(vision)) then
                                GRAPHICS.UI3DSCENE_ASSIGN_PED_TO_SLOT(tostring(vision), PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid[1]), 0, 0.0, 0.0, 0)
                            end
                        end
                        if show_value == 'Show' then return false 
                        end
                    end)
                end
            end
---------------------------------kick
    directx.draw_rect(
        kick_box_x,
        kick_box_y,                
        kick_box_s_x,                
        kick_box_s_y,                
        0/255,0/255,0/255,100/255    
    )

    directx.draw_text(
        kick_text_x,
        kick_text_y,
        "Kick Player",
        ALIGN_CENTRE_LEFT,
        kick_scale,
        255/255,255/255,255/255,1,
        false)

----------------------------------------crash
    directx.draw_rect(
        crash_box_x,
        crash_box_y,                
        crash_box_s_x,                
        crash_box_s_y,                
        0/255,0/255,0/255,100/255    
    )

    directx.draw_text(
        crash_text_x,
        crash_text_y,
        "Crash Player",
        ALIGN_CENTRE_LEFT,
        crash_scale,
        255/255,255/255,255/255,1,
        false)

------------------------------------TP
    directx.draw_rect(
        tp_box_x,
        tp_box_y,                
        tp_box_s_x,                
        tp_box_s_y,                
        0/255,0/255,0/255,100/255    
    )

    directx.draw_text(
        tp_text_x,
        tp_text_y,
        "TP to Player",
        ALIGN_CENTRE_LEFT,
        tp_scale,
        255/255,255/255,255/255,1,
        false)

-------------------------------------------summon
    directx.draw_rect(
        summon_box_x,
        summon_box_y,                
        summon_box_s_x,                
        summon_box_s_y,                
        0/255,0/255,0/255,100/255    
    )

    directx.draw_text(
        summon_text_x,
        summon_text_y,
        "TP Player to ME",
        ALIGN_CENTRE_LEFT,
        summon_scale,
        255/255,255/255,255/255,1,
        false)

        -------------------------------------------spectate
    directx.draw_rect(
        tv_box_x,
        tv_box_y,                
        tv_box_s_x,                
        tv_box_s_y,                
        0/255,0/255,0/255,100/255    
    )
    directx.draw_text(
        tv_text_x,
        tv_text_y,
        spec_value,
        ALIGN_CENTRE_LEFT,
        tv_scale,
        255/255,255/255,255/255,1,
        false)

        -------------------------------------------show
    directx.draw_rect(
        show_box_x,
        show_box_y,                
        show_box_s_x,                
        show_box_s_y,                
        0/255,0/255,0/255,100/255    
    )
    directx.draw_text(
        show_text_x,
        show_text_y,
        show_value,
        ALIGN_CENTRE_LEFT,
        show_scale,
        255/255,255/255,255/255,1,
        false)
       end 
        util.yield() 
    end 
end)

util.on_stop(function ()
    directx.blurrect_free(blur_rect_instance)
    util.toast("TDODScript Disappears")
end)
--[[local eventData = memory.alloc(13 * 8)
util.create_tick_handler(function()
    for eventNum = 0, SCRIPT.GET_NUMBER_OF_EVENTS(1) - 1 do
        local eventId = SCRIPT.GET_EVENT_AT_INDEX(1, eventNum)
        if eventId == 186 then -- CEventNetworkEntityDamage
            if SCRIPT.GET_EVENT_DATA(1, eventNum, eventData, 13) then
                local victim = memory.read_int(eventData)
                local attacker = memory.read_int(eventData + 1 * 8)
                local damage = memory.read_float(eventData + 2 * 8)
                local victimDestroyed = memory.read_int(eventData + 5*8)
                local weaponUsedHash = memory.read_int(eventData + 6 * 8)

                if victim ~= attacker and victim ~= -1 and attacker ~= -1 then
                    if NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(attacker) ~= -1 and NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(victim) ~= -1 then
                        if victimDestroyed == 1 then --i dont think if victimDestroyed works in lua since lua sucks
                            onPlayerKilled(victim, attacker, weaponUsedHash)
                        elseif victimDestroyed == 0 then
                            onPlayerDamaged(victim, attacker, weaponUsedHash, damage) 
                        end
                    end
                end
            end
        end
    end
end) ]] --???


