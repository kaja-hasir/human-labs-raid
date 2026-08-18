local vehicles_on_route = 0
local vehicles_in_destination = 0
local is_clear = false
local is_clear_checking = false
local transporter_spawn_loop_active = false
local transporter_spawned_id = nil
local transporter_spawned_failed = false
local active_transporters = {}

local function get_best_fitting_player()
    local target_coords = Config.blips.global_human_labs
    local players = GetPlayers()

    if #players == 0 then
        return nil
    end

    local closest_player = tonumber(players[0])
    local min_distance = 100000.0
    for _, id in ipairs(players) do
        local source = tonumber(id)
        local ped = GetPlayerPed(id)
        local coords = GetEntityCoords(ped)
        local distance = #(coords - target_coords)
        if distance <= min_distance then
            min_distance = distance
            closest_player = source
        end
    end

    return closest_player
end

local function force_clear_area(location)
    local coords = vec3(location.x, location.y, location.z) -- vec4 to vec3
    local playerPeds = {}
    local radius = 12.0

    for _, playerId in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(playerId)
        playerPeds[ped] = true

        local playerCoords = GetEntityCoords(ped)
        if #(playerCoords - coords) < radius then
            return false
        end
    end

    for _, ped in ipairs(GetAllPeds()) do
        if not playerPeds[ped] then
            local pedCoords = GetEntityCoords(ped)
            if #(pedCoords - coords) < radius then
                DeleteEntity(ped)
            end
        end
    end

    for _, veh in ipairs(GetAllVehicles()) do
        local vehCoords = GetEntityCoords(veh)
        if #(vehCoords - coords) < radius then
            DeleteEntity(veh)
        end
    end

    return true
end

local function create_transporter(spawn_loc)
    local target_player = get_best_fitting_player()
    if not target_player then return nil end

    local timeout_clearing = 0
    while not is_clear do
        Wait(200)
        if not is_clear_checking then
            is_clear_checking = true
            TriggerClientEvent('human_labs_raid:client:transporter:is_spawn_clear', target_player, spawn_loc)
        elseif not IsPlayerStillConnected(target_player) then
            target_player = get_best_fitting_player()
            if not target_player then return nil end
        end

        timeout_clearing = timeout_clearing + 200
        if timeout_clearing > 2*60*1000 then
            timeout_clearing = 0
            if not force_clear_area(spawn_loc) then return nil end
        end
    end
    is_clear = false
    is_clear_checking = false
    Wait(0) -- Yield important before spawn event

    TriggerClientEvent('human_labs_raid:client:transporter:spawn', target_player, spawn_loc)

    local timeout_spawning = 0
    while timeout_spawning <= 30000
    and transporter_spawned_id == nil
    and not transporter_spawned_failed
    and IsPlayerStillConnected(target_player) do
        Wait(100)
        timeout_spawning = timeout_spawning + 100
    end

    transporter_spawned_failed = false
    local id = transporter_spawned_id
    transporter_spawned_id = nil

    if id and active_transporters[id] then
        local vehicle_net_id, driver_net_id, passenger_net_id = active_transporters[id].vehicle_net_id, active_transporters[id].driver_net_id, active_transporters[id].passenger_net_id
        TriggerClientEvent('human_labs_raid:client:transporter:make_interactable', -1, vehicle_net_id, driver_net_id, passenger_net_id)
    end

    return id
end

local function move_transporter(transporter, destination)
    if not transporter then return end

    local vehicle_hash = GetHashKey(Config.transporter.delivery_cars.vehicle)
    local vehicle_net_id = transporter.vehicle_net_id
    local driver_net_id = transporter.driver_net_id
    local spawn_frequency = Config.transporter.delivery_cars.frequency_driving_in_sec
    local vehicle = NetworkGetEntityFromNetworkId(vehicle_net_id)

    local transport_reached_destination = false
    local unable_to_reach_destination = false

    while not transport_reached_destination and not unable_to_reach_destination do
        if RepeatFunctionUntilTrueWithTimeout(EntityHasOwner, { vehicle }) then return false end
        local old_owner = NetworkGetEntityOwner(vehicle)
        TriggerClientEvent('human_labs_raid:client:transporter:move_to', old_owner, vehicle_net_id, vehicle_hash, driver_net_id, destination)

        local new_owner = old_owner
        local timeout_move = 0
        while old_owner == new_owner and not transport_reached_destination and not unable_to_reach_destination do
            transport_reached_destination = transporter.reached_destination
            unable_to_reach_destination = transporter.unable_to_continue

            if RepeatFunctionUntilTrueWithTimeout(EntityHasOwner, { vehicle }) then return end
            new_owner = NetworkGetEntityOwner(vehicle)
            Wait(500)

            timeout_move = timeout_move + 500
            if timeout_move > 5*60*1000 and timeout_move > spawn_frequency then
                return false
            end
        end

        Wait(0) -- Yield important
        if old_owner == new_owner then
            return transport_reached_destination
        end
    end
    return true
end

local function move_transporter_response(vehicle_net_id, successful)
    if active_transporters[vehicle_net_id] == nil then return end
    active_transporters[vehicle_net_id].reached_destination = successful
    active_transporters[vehicle_net_id].unable_to_continue = not successful
end

local function remove_ped(id)
    if not id then return end
    local ped = NetworkGetEntityFromNetworkId(id)
    if ped and ped ~= 0 then
        -- Must be server sided because client is not reachable after resource stop
        DeleteEntity(ped)
    end
end

local function remove_vehicle(id)
    if not id then return end
    local vehicle = NetworkGetEntityFromNetworkId(id)
    if vehicle and vehicle ~= 0 then
        -- Must be server sided because client is not reachable after resource stop
        DeleteEntity(vehicle)
    end
end

local function remove_active_transporter(id)
    if not active_transporters[id] then return end

    local vehicle_net_id, driver_net_id, passenger_net_id = active_transporters[id].vehicle_net_id, active_transporters[id].driver_net_id, active_transporters[id].passenger_net_id

    remove_ped(passenger_net_id)
    remove_ped(driver_net_id)
    remove_vehicle(vehicle_net_id)

    if Config.blips.transporters then
        TriggerClientEvent('human_labs_raid:client:blip:remove_transporter_blip', -1, vehicle_net_id)
    end

    active_transporters[id] = nil
end

local function spawn_transporter_at_start()
    local start_route_location = Config.transporter.delivery_cars.route_start
    local destination_route_location = Config.transporter.delivery_cars.route_destination

    local id = create_transporter(start_route_location)
    Wait(100)
    if not id then return end

    local transporter = active_transporters[id]
    if not transporter then return end
    local vehicle_net_id = transporter.vehicle_net_id

    CreateThread(function()
        vehicles_on_route = vehicles_on_route + 1
        local successful = move_transporter(transporter, destination_route_location)
        remove_active_transporter(vehicle_net_id)

        Wait(10000)

        if successful then
            vehicles_in_destination = vehicles_in_destination + 1
        end
        vehicles_on_route = vehicles_on_route - 1
    end)
end

local function spawn_transporter_at_end()
    local start_route_location = Config.transporter.delivery_cars.route_start
    local destination_route_location = Config.transporter.delivery_cars.route_destination

    local id = create_transporter(destination_route_location)
    Wait(100)
    if not id then return end

    local transporter = active_transporters[id]
    if not transporter then return end
    local vehicle_net_id = transporter.vehicle_net_id

    CreateThread(function()
        vehicles_on_route = vehicles_on_route + 1
        vehicles_in_destination = vehicles_in_destination - 1

        local _successful = move_transporter(transporter, start_route_location)
        remove_active_transporter(vehicle_net_id)

        vehicles_on_route = vehicles_on_route - 1
    end)
end

local function transporter_spawn_loop()
    if transporter_spawn_loop_active then return end
    transporter_spawn_loop_active = true

    CreateThread(function()
        local frequency = Config.transporter.delivery_cars.frequency_driving_in_sec
        local convoy_size = Config.transporter.delivery_cars.convoy_size

        local last_spawn = frequency

        while true do
            Wait(500)
            last_spawn = last_spawn + 500

            local vehicles_active = vehicles_on_route + vehicles_in_destination
            if vehicles_in_destination > 0 then
                spawn_transporter_at_end()
            elseif not RaidDisabled and last_spawn > frequency and vehicles_active < convoy_size then
                local number_of_spawns = convoy_size - vehicles_active
                while number_of_spawns > 0 do
                    number_of_spawns = number_of_spawns - 1
                    spawn_transporter_at_start()
                end

                if convoy_size > vehicles_active then
                    last_spawn = 0
                end
            end
        end
    end)
end

function MakeTransporterInteractableClient(client)
    for id, _ in pairs(active_transporters) do
        if id and active_transporters[id] then
            local vehicle_net_id, driver_net_id, passenger_net_id = active_transporters[id].vehicle_net_id, active_transporters[id].driver_net_id, active_transporters[id].passenger_net_id
            TriggerClientEvent('human_labs_raid:client:transporter:make_interactable', client, vehicle_net_id, driver_net_id, passenger_net_id)
        end
    end
end

function GetActiveTransporters()
    return vehicles_on_route + vehicles_in_destination
end

function RemoveAllTransporters() -- Waits for transporters to reach destination (Not great, but they still remove) | move_transporter_to is stalling even tho it is called inside a thread
    for id, _ in pairs(active_transporters) do
        remove_active_transporter(id)
    end

    active_transporters = {}
    vehicles_on_route = 0
    vehicles_in_destination = 0
end

RegisterNetEvent('human_labs_raid:server:transporter:is_spawn_clear_response', function(value)
    is_clear = value
    is_clear_checking = false
end)

RegisterNetEvent('human_labs_raid:server:transporter:inform_robbing', function(vehicle_net_id)
    Trigger:on_transporter_robbing(source, vehicle_net_id)
end)

RegisterNetEvent('human_labs_raid:server:transporter:reached_destination', function(vehicle_net_id)
    move_transporter_response(vehicle_net_id, true)
end)

RegisterNetEvent('human_labs_raid:server:transporter:reached_destination_failed', function(vehicle_net_id)
    move_transporter_response(vehicle_net_id, false)
end)

RegisterNetEvent('human_labs_raid:server:transporter:spawn_response', function(vehicle_net_id, driver_net_id, passenger_net_id)
    if Config.blips.transporters then
        TriggerClientEvent('human_labs_raid:client:blip:give_transporter_blip', -1, vehicle_net_id)
    end

    active_transporters[vehicle_net_id] = {
        vehicle_net_id = vehicle_net_id,
        driver_net_id = driver_net_id,
        passenger_net_id = passenger_net_id,
        reached_destination = false,
        unable_to_continue = false
    }
    transporter_spawned_id = vehicle_net_id
end)

RegisterNetEvent('human_labs_raid:server:transporter:spawn_response_failed', function(vehicle_net_id, driver_net_id, passenger_net_id)
    remove_ped(driver_net_id)
    remove_ped(passenger_net_id)
    remove_vehicle(vehicle_net_id)

    transporter_spawned_failed = true
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if Config.transporter.enabled then
        Wait(5000)
        transporter_spawn_loop()
    end
end)
