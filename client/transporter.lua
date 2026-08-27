local function is_spawn_clear(coords, radius)
    local center = vec3(coords.x, coords.y, coords.z) -- coords is vec4

    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if #(GetEntityCoords(veh) - center) < radius then
            return false
        end
    end

    for _, ped in ipairs(GetGamePool('CPed')) do
        if DoesEntityExist(ped)
        and not IsPedDeadOrDying(ped, true)
        and not IsPedInAnyVehicle(ped, false) then
            if #(GetEntityCoords(ped) - center) < radius then
                return false
            end
        end
    end

    return true
end

local function is_clear_of_players(coords, radius)
    local center = vec3(coords.x, coords.y, coords.z) -- coords is vec4

    for _, playerId in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(playerId)

        if DoesEntityExist(ped) then
            if #(GetEntityCoords(ped) - center) < radius then
                return false
            end
        end
    end

    return true
end

local function place_vehicle(location)
    local vehicle_hash = GetHashKey(Config.transporter.delivery_cars.vehicle)

    RequestModel(vehicle_hash)
    if RepeatFunctionUntilTrueWithTimeout(HasModelLoaded, { vehicle_hash }) then
        warn("Unable to load vehicle model when placing vehicle")
        return nil, nil
    end

    local vehicle = CreateVehicle(vehicle_hash, location.x, location.y, location.z, location.w, true, true)
    SetModelAsNoLongerNeeded(vehicle_hash)
    if RepeatFunctionUntilTrueWithTimeout(DoesEntityExist, { vehicle }) then return nil, nil end
    SetEntityAsMissionEntity(vehicle, true, true)

    return vehicle, NetworkGetNetworkIdFromEntity(vehicle)
end

local function place_driver(vehicle)
    if RepeatFunctionUntilTrueWithTimeout(DoesEntityExist, { vehicle }) then return nil, nil end
    local driver_ped_hash = GetHashKey(Config.transporter.delivery_cars.ped_models.driver)

    RequestModel(driver_ped_hash)
    if RepeatFunctionUntilTrueWithTimeout(HasModelLoaded, { driver_ped_hash }) then
        warn("Unable to load driver ped model")
        return nil, nil
    end

    local driver = CreatePedInsideVehicle(vehicle, 4, driver_ped_hash, -1, true, true)
    SetModelAsNoLongerNeeded(driver_ped_hash)
    if RepeatFunctionUntilTrueWithTimeout(DoesEntityExist, { driver }) then return nil, nil end
    SetEntityAsMissionEntity(driver, true, true)

    return driver, NetworkGetNetworkIdFromEntity(driver)
end

local function place_passenger(vehicle)
    if RepeatFunctionUntilTrueWithTimeout(DoesEntityExist, { vehicle }) then return nil, nil end
    local passenger_ped_hash = GetHashKey(Config.transporter.delivery_cars.ped_models.passenger)

    RequestModel(passenger_ped_hash)
    if RepeatFunctionUntilTrueWithTimeout(HasModelLoaded, { passenger_ped_hash }) then
        warn("Unable to load passenger ped model")
        return nil, nil
    end

    local passenger = CreatePedInsideVehicle(vehicle, 3, passenger_ped_hash, 0, true, true)
    SetModelAsNoLongerNeeded(passenger_ped_hash)
    if RepeatFunctionUntilTrueWithTimeout(DoesEntityExist, { passenger }) then return nil, nil end
    SetEntityAsMissionEntity(passenger, true, true)

    return passenger, NetworkGetNetworkIdFromEntity(passenger)
end

local function is_transporter_active(vehicle, driver)
    return DoesEntityExist(vehicle)
        and DoesEntityExist(driver)
        and IsPedInVehicle(driver, vehicle, false)
        and not IsPedDeadOrDying(driver, true)
        and (GetScriptTaskStatus(driver, GetHashKey("SCRIPT_TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE")) <= 1
            or GetScriptTaskStatus(driver, GetHashKey("SCRIPT_TASK_VEHICLE_DRIVE_TO_COORD")) <= 1)
end
local function move_transporter_to(vehicle_net_id, vehicle_hash, driver_net_id, destination)
    if RepeatFunctionUntilTrueWithTimeout(NetworkDoesEntityExistWithNetworkId, { vehicle_net_id }) then return false end
    if not NetworkDoesEntityExistWithNetworkId(vehicle_net_id) then return end
    local vehicle = NetworkGetEntityFromNetworkId(vehicle_net_id)
    if RepeatFunctionUntilTrueWithTimeout(DoesEntityExist, { vehicle }) then return false end

    if RepeatFunctionUntilTrueWithTimeout(NetworkDoesEntityExistWithNetworkId, { driver_net_id }) then return false end
    if not NetworkDoesEntityExistWithNetworkId(driver_net_id) then return end
    local driver = NetworkGetEntityFromNetworkId(driver_net_id)
    if RepeatFunctionUntilTrueWithTimeout(DoesEntityExist, { driver }) then return false end

    TaskVehicleDriveToCoordLongrange(driver, vehicle, destination.x, destination.y, destination.z, 30.0, 786571, 5.0)

    local coords = GetEntityCoords(vehicle)
    while is_transporter_active(vehicle, driver)
    and GetDistanceBetweenCoords(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z, true) > 40.0 do
        coords = GetEntityCoords(vehicle)
        Wait(1000)
    end

    if not is_transporter_active(vehicle, driver) then
        while coords and not is_clear_of_players(coords, 200.0) do
            coords = GetEntityCoords(vehicle)
            Wait(500)
        end
        return false
    end

    SetDriverAggressiveness(driver, 0.0)
    TaskVehicleDriveToCoord(driver, vehicle, destination.x, destination.y, destination.z, 10.0, 0, vehicle_hash, 786603, 2.0, true)

    while is_transporter_active(vehicle, driver)
    and GetDistanceBetweenCoords(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z, true) > 10.0 do
        coords = GetEntityCoords(vehicle)
        Wait(500)
    end

    if not is_transporter_active(vehicle, driver) then
        while coords and not is_clear_of_players(coords, 200.0) do
            coords = GetEntityCoords(vehicle)
            Wait(500)
        end
        return false
    end

    Wait(5000)

    return true
end

local function can_rob(vehicle, driver)
    return Config.transporter.robbing_enabled
        and IsPedArmed(PlayerPedId(), 4)
        and IsPedInVehicle(driver, vehicle, false)
        and not IsPedDeadOrDying(driver, true)
        and not Entity(vehicle).state.robbed
end
local function can_search_driver_seat(vehicle, driver)
    return Config.transporter.searching_enabled.driver_seat
        and not Entity(vehicle).state.driver_searched
        and not Entity(vehicle).state.robbed
        and (not IsPedInVehicle(driver, vehicle, false)
            or IsPedDeadOrDying(driver, true))
end
local function can_search_passenger_seat(vehicle, driver)
    return Config.transporter.searching_enabled.passenger_seat
        and not Entity(vehicle).state.passenger_searched
        and (not IsPedInVehicle(driver, vehicle, false)
            or IsPedDeadOrDying(driver, true))
end
local function can_search_trunk(vehicle, driver)
    return Config.transporter.searching_enabled.trunk
        and not Entity(vehicle).state.trunk_searched
        and (not IsPedInVehicle(driver, vehicle, false)
            or IsPedDeadOrDying(driver, true))
end

local function inform_about_robbing_if_peds_alive(vehicle_net_id, ped1, ped2)
    if (DoesEntityExist(ped1) and not IsPedDeadOrDying(ped1, true))
    or (DoesEntityExist(ped2) and not IsPedDeadOrDying(ped2, true)) then
        TriggerServerEvent('human_labs_raid:server:transporter:inform_robbing', vehicle_net_id)
    end
end

local function run_robbing(vehicle, vehicle_net_id, driver, passenger)
    local player_ped = PlayerPedId()
    local anim_dict = 'weapons@pistol@'
    local anim = 'grip'

    local vehicle_coords = GetEntityCoords(vehicle)
    local player_coords = GetEntityCoords(player_ped)

    local heading = GetHeadingFromVector_2d(
        vehicle_coords.x - player_coords.x,
        vehicle_coords.y - player_coords.y
    )

    Entity(vehicle).state.robbed = true
    SetEntityHeading(player_ped, heading)

    if IsPedInVehicle(driver, vehicle, false) then
        TaskHandsUp(driver, Config.transporter.delivery_cars.rob_time, -1, -1, false)
    end
    if IsPedInVehicle(passenger, vehicle, false) then
        TaskHandsUp(passenger, Config.transporter.delivery_cars.rob_time, -1, -1, false)
    end

    SetVehicleEngineOn(vehicle, false, true, true)
    FreezeEntityPosition(vehicle, true)

    RequestAnimDict(anim_dict)
    if not RepeatFunctionUntilTrueWithTimeout(HasAnimDictLoaded, { anim_dict }) then
        TaskPlayAnim(player_ped, anim_dict, anim, 8.0, -8.0, Config.transporter.delivery_cars.rob_time, 49, 0.0, false, false, false)
    end

    local success = Notify:progressBar(Config.transporter.delivery_cars.rob_time, Locale.transporter.robbing_transporter, true, false)
    if success then
        TriggerServerEvent('human_labs_raid:server:crafting:collect_transporter_driver_loot_robbing', vehicle_net_id)
    end

    if DoesEntityExist(driver) and IsPedInVehicle(driver, vehicle, false) then
        ClearPedTasks(driver)
        TaskLeaveVehicle(driver, vehicle, 256)
    end
    if DoesEntityExist(passenger) and IsPedInVehicle(passenger, vehicle, false) then
        ClearPedTasks(passenger)
        TaskLeaveVehicle(passenger, vehicle, 256)
    end

    Wait(200)

    FreezeEntityPosition(vehicle, false)
    TaskReactAndFleePed(driver, player_ped)
    TaskReactAndFleePed(passenger, player_ped)
    ClearPedTasks(player_ped)
end
local function search_driver_seat(vehicle, vehicle_net_id)
    local player_ped = PlayerPedId()
    local anim_dict = 'anim@heists@prison_heiststation@cop_reactions'
    local anim = 'cop_b_idle'

    TaskEnterVehicle(player_ped, vehicle, -1, -1, 1.0, 8, 0)
    if RepeatFunctionUntilTrueWithTimeout(IsPedInVehicle, { player_ped, vehicle, false }) then
        ClearPedTasks(player_ped)
        return
    end

    RequestAnimDict(anim_dict)
    if not RepeatFunctionUntilTrueWithTimeout(HasAnimDictLoaded, { anim_dict }) then
        TaskPlayAnim(player_ped, anim_dict, anim, 800.0, -800.0, Config.transporter.delivery_cars.search_time, 49, 0.0, false, false, false)
        RemoveAnimDict(anim_dict)
    end

    local success = Notify:progressBar(Config.transporter.delivery_cars.search_time, Locale.transporter.searching_transporter, true, true)
    if success then
        Entity(vehicle).state.driver_searched = true
        TriggerServerEvent('human_labs_raid:server:crafting:collect_transporter_driver_loot', vehicle_net_id)
        Wait(200)
    end

    ClearPedTasks(player_ped)
    TaskLeaveVehicle(player_ped, vehicle, 0)
end
local function search_passanger_seat(vehicle, vehicle_net_id)
    local player_ped = PlayerPedId()
    local anim_dict = 'mini@repair'
    local anim = 'fixing_a_ped'

    TaskEnterVehicle(player_ped, vehicle, -1, 0, 1.0, 8, 0)
    if RepeatFunctionUntilTrueWithTimeout(IsPedInVehicle, { player_ped, vehicle, false }) then
        ClearPedTasks(player_ped)
        return
    end

    RequestAnimDict(anim_dict)
    if not RepeatFunctionUntilTrueWithTimeout(HasAnimDictLoaded, { anim_dict }) then
        TaskPlayAnim(player_ped, anim_dict, anim, 800.0, -800.0, Config.transporter.delivery_cars.search_time, 49, 0.0, false, false, false)
        RemoveAnimDict(anim_dict)
    end

    local success = Notify:progressBar(Config.transporter.delivery_cars.search_time, Locale.transporter.searching_transporter, true, true)
    if success then
        Entity(vehicle).state.passenger_searched = true
        TriggerServerEvent('human_labs_raid:server:crafting:collect_transporter_passenger_loot', vehicle_net_id)
        Wait(200)
    end

    ClearPedTasks(player_ped)
    TaskLeaveVehicle(player_ped, vehicle, 0)
end
local function search_trunk(vehicle, vehicle_net_id)
    local player_ped = PlayerPedId()
    local anim_dict = 'mini@repair'
    local anim = 'fixing_a_ped'

    TaskEnterVehicle(player_ped, vehicle, -1, 1, 1.0, 8, 0)
    if RepeatFunctionUntilTrueWithTimeout(function()
        return GetVehicleDoorAngleRatio(vehicle, 2) > 0.6
    end, {}) then
        ClearPedTasks(player_ped)
        return
    end

    ClearPedTasksImmediately(player_ped)
    if IsPedInVehicle(player_ped, vehicle, false) then return end

    TaskEnterVehicle(player_ped, vehicle, -1, 2, 1.0, 8, 0)
    if RepeatFunctionUntilTrueWithTimeout(function()
        return GetVehicleDoorAngleRatio(vehicle, 3) > 0.6
    end, {}) then
        ClearPedTasks(player_ped)
        return
    end

    ClearPedTasksImmediately(player_ped)
    if IsPedInVehicle(player_ped, vehicle, false) then return end

    TaskTurnPedToFaceEntity(player_ped, vehicle, Config.transporter.delivery_cars.search_time)
    Wait(300)

    RequestAnimDict(anim_dict)
    if not RepeatFunctionUntilTrueWithTimeout(HasAnimDictLoaded, { anim_dict }) then
        TaskPlayAnim(player_ped, anim_dict, anim, 800.0, -800.0, Config.transporter.delivery_cars.search_time, 49, 0.0, false, false, false)
        RemoveAnimDict(anim_dict)
    end

    local success = Notify:progressBar(Config.transporter.delivery_cars.search_time, Locale.transporter.searching_transporter, true, true)
    if success then
        Entity(vehicle).state.trunk_searched = true
        TriggerServerEvent('human_labs_raid:server:crafting:collect_transporter_trunk_loot', vehicle_net_id)
        Wait(200)
    end
    ClearPedTasks(player_ped)
end

RegisterNetEvent('human_labs_raid:client:transporter:make_interactable', function(vehicle_net_id, driver_net_id, passenger_net_id)
    if RepeatFunctionUntilTrueWithTimeout(NetworkDoesEntityExistWithNetworkId, { vehicle_net_id }) then return end
    if not NetworkDoesEntityExistWithNetworkId(vehicle_net_id) then return end
    local vehicle = NetworkGetEntityFromNetworkId(vehicle_net_id)
    if RepeatFunctionUntilTrueWithTimeout(DoesEntityExist, { vehicle }) then return end

    if RepeatFunctionUntilTrueWithTimeout(NetworkDoesEntityExistWithNetworkId, { driver_net_id }) then return end
    if not NetworkDoesEntityExistWithNetworkId(driver_net_id) then return end
    local driver = NetworkGetEntityFromNetworkId(driver_net_id)
    if RepeatFunctionUntilTrueWithTimeout(DoesEntityExist, { driver }) then return end

    if RepeatFunctionUntilTrueWithTimeout(NetworkDoesEntityExistWithNetworkId, { passenger_net_id }) then return end
    if not NetworkDoesEntityExistWithNetworkId(passenger_net_id) then return end
    local passenger = NetworkGetEntityFromNetworkId(passenger_net_id)
    if RepeatFunctionUntilTrueWithTimeout(DoesEntityExist, { passenger }) then return end

    local informed_about_robbing = false
    Target:addLocalEntity(vehicle, {
        {
            name = 'rob_transporter',
            icon = 'fa-solid fa-gun',
            label = Locale.transporter.rob_driver,
            distance = Config.transporter.interaction_distance,
            canInteract = function() return can_rob(vehicle, driver) end,
            bones = { 'bonnet', 'door_dside_f', 'door_pside_f', 'wheel_lf', 'wheel_rf' },
            onSelect = function()
                CreateThread(function()
                    if informed_about_robbing then return end
                    Wait(3000)
                    inform_about_robbing_if_peds_alive(vehicle_net_id, driver, passenger)
                    informed_about_robbing = true
                end)
                run_robbing(vehicle, vehicle_net_id, driver, passenger)
            end
        },{
            name = 'search_transporter_driver_door',
            icon = 'fa-solid fa-magnifying-glass',
            label = Locale.transporter.search_transporter,
            canInteract = function() return can_search_driver_seat(vehicle, driver) end,
            distance = Config.transporter.interaction_distance,
            bones = { 'door_dside_f' },
            onSelect = function()
                CreateThread(function()
                    if informed_about_robbing then return end
                    Wait(3000)
                    inform_about_robbing_if_peds_alive(vehicle_net_id, driver, passenger)
                    informed_about_robbing = true
                end)
                search_driver_seat(vehicle, vehicle_net_id)
            end
        },{
            name = 'search_transporter_passenger_door',
            icon = 'fa-solid fa-magnifying-glass',
            label = Locale.transporter.search_transporter,
            canInteract = function() return can_search_passenger_seat(vehicle, driver) end,
            distance = Config.transporter.interaction_distance,
            bones = { 'door_pside_f' },
            onSelect = function()
                CreateThread(function()
                    if informed_about_robbing then return end
                    Wait(3000)
                    inform_about_robbing_if_peds_alive(vehicle_net_id, driver, passenger)
                    informed_about_robbing = true
                end)
                search_passanger_seat(vehicle, vehicle_net_id)
            end
        },{
            name = 'search_transporter_trunk',
            icon = 'fa-solid fa-magnifying-glass',
            label = Locale.transporter.search_transporter,
            canInteract = function() return can_search_trunk(vehicle, driver) end,
            distance = Config.transporter.interaction_distance,
            bones = { 'door_dside_r', 'door_pside_r' },
            onSelect = function()
                CreateThread(function()
                    if informed_about_robbing then return end
                    Wait(3000)
                    inform_about_robbing_if_peds_alive(vehicle_net_id, driver, passenger)
                    informed_about_robbing = true
                end)
                search_trunk(vehicle, vehicle_net_id)
            end
        }
    })
end)

RegisterNetEvent('human_labs_raid:client:transporter:move_to', function(vehicle_net_id, vehicle_hash, driver_net_id, destination)
    if move_transporter_to(vehicle_net_id, vehicle_hash, driver_net_id, destination) then
        TriggerServerEvent('human_labs_raid:server:transporter:reached_destination', vehicle_net_id)
    else
        TriggerServerEvent('human_labs_raid:server:transporter:reached_destination_failed', vehicle_net_id)
    end
end)

RegisterNetEvent('human_labs_raid:client:transporter:spawn', function(spawn_loc)
    local vehicle, vehicle_net_id = place_vehicle(spawn_loc)
    if not vehicle or not vehicle_net_id then
        TriggerServerEvent('human_labs_raid:server:transporter:spawn_response_failed', vehicle_net_id, nil, nil)
        return
    end
    local driver, driver_net_id = place_driver(vehicle)
    if not driver or not driver_net_id then
        TriggerServerEvent('human_labs_raid:server:transporter:spawn_response_failed', vehicle_net_id, driver_net_id, nil)
        return
    end
    local passenger, passenger_net_id = place_passenger(vehicle)
    if not passenger or not passenger_net_id then
        TriggerServerEvent('human_labs_raid:server:transporter:spawn_response_failed', vehicle_net_id, driver_net_id, passenger_net_id)
        return
    end

    SetDriverAbility(driver, 1.0)
    SetDriverAggressiveness(driver, 1.0)
    SetPedKeepTask(driver, true)

    Wait(1000) -- Wait for Network to register entities (for is_clear)

    TriggerServerEvent('human_labs_raid:server:transporter:spawn_response', vehicle_net_id, driver_net_id, passenger_net_id)
end)

RegisterNetEvent('human_labs_raid:client:transporter:is_spawn_clear', function(spawn_loc)
    Wait(100) -- Cooldown required
    local value = is_spawn_clear(spawn_loc, 10.0)
    TriggerServerEvent('human_labs_raid:server:transporter:is_spawn_clear_response', value)
end)
