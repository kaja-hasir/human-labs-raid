local spawned_ped_net_ids = {}
local spawn_failed = {}
local spawn_net_id = {}

local spawn_id_for_response = 0

function NextIdForResponses()
    spawn_id_for_response = spawn_id_for_response + 1
    return spawn_id_for_response
end

function PlacePed(client_event, location_arg)
    local response_id = NextIdForResponses()
    spawn_failed[response_id] = false
    spawn_net_id[response_id] = nil

    local target_player = GetRandomPlayerInside()
    if target_player == nil then return nil end

    if location_arg and location_arg ~= 0 then
        TriggerClientEvent(client_event, target_player, response_id, location_arg)
    else
        TriggerClientEvent(client_event, target_player, response_id)
    end

    local timeout = 0
    while spawn_net_id[response_id] == nil
        and not spawn_failed[response_id]
        and timeout < 5000
        and IsPlayerStillConnected(target_player) do
        Wait(100)
        timeout = timeout + 100
    end

    return spawn_net_id[response_id]
end

function PedCount()
    local ped_counter = 0
    for _, _ in pairs(spawned_ped_net_ids) do
        ped_counter = ped_counter + 1
    end
    return ped_counter
end

function GetSpawnedPeds()
    return spawned_ped_net_ids
end

function RemoveAllPeds()
    for net_id, _ in pairs(spawned_ped_net_ids) do
        local ped = NetworkGetEntityFromNetworkId(net_id)
        if ped and ped ~= 0 and DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    spawned_ped_net_ids = {}
end

RegisterNetEvent('human_labs_raid:server:peds:spawn_response', function(id, net_id)
    spawn_net_id[id] = net_id
    spawned_ped_net_ids[net_id] = true
end)

RegisterNetEvent('human_labs_raid:server:peds:spawn_response_failed', function(id)
    spawn_failed[id] = true
end)

RegisterNetEvent('human_labs_raid:server:peds:remove_ped_slowly', function(net_id)
    local ped = NetworkGetEntityFromNetworkId(net_id)
    RunForPlayersInside(function(src)
        TriggerClientEvent('human_labs_raid:client:blip:remove_blip', src, net_id)
    end)

    Wait(10000)

    if ped and ped ~= 0 and DoesEntityExist(ped) then
        DeleteEntity(ped)
    end
    spawned_ped_net_ids[net_id] = nil
end)

RegisterNetEvent('human_labs_raid:server:peds:as_owner_play_ped_task_scenario', function(net_id, scenario_name, time_to_leave, play_intro_clip)
    local ped = NetworkGetEntityFromNetworkId(net_id)
    if not ped then return end
    local owner = NetworkGetEntityOwner(ped)
    if owner and owner ~= nil and owner > 0 then
        TriggerClientEvent('human_labs_raid:client:ped:as_owner_play_task_scenario', owner, net_id, scenario_name, time_to_leave, play_intro_clip)
    end
end)
