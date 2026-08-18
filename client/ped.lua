function PlacePed(location, model_hash)
    RequestModel(model_hash)
    if RepeatFunctionUntilTrueWithTimeout(HasModelLoaded, { model_hash }) then
        warn("Unable to load ped model")
        return nil, nil
    end

    local ped = CreatePed(4, model_hash, location.x, location.y, location.z, location[4], true, true)
    SetModelAsNoLongerNeeded(model_hash)
    if RepeatFunctionUntilTrueWithTimeout(DoesEntityExist, { ped }) then return nil, nil end

    return ped, NetworkGetNetworkIdFromEntity(ped)
end

function SpawnPedWithResponse(place_ped_fn, id, args)
    local ped, ped_net_id = place_ped_fn(table.unpack(args))
    if ped and ped_net_id then
        TriggerServerEvent('human_labs_raid:server:peds:spawn_response', id, ped_net_id)
    else
        TriggerServerEvent('human_labs_raid:server:peds:spawn_response_failed', id)
    end
end

RegisterNetEvent('human_labs_raid:client:ped:as_owner_play_task_scenario', function(net_id, animation, time_to_leave, play_intro_clip)
    if RepeatFunctionUntilTrueWithTimeout(NetworkDoesEntityExistWithNetworkId, { net_id }) then return end
    if not NetworkDoesEntityExistWithNetworkId(net_id) then return end
    local ped = NetworkGetEntityFromNetworkId(net_id)
    if RepeatFunctionUntilTrueWithTimeout(DoesEntityExist, { ped }) then return end

    -- ClearPedTasksImmediately(ped)
    TaskStartScenarioInPlace(ped, animation, time_to_leave, play_intro_clip)
end)

RegisterNetEvent('human_labs_raid:client:ped:remove', function(net_id)
    if not NetworkDoesEntityExistWithNetworkId(net_id) then return end
    local ped = NetworkGetEntityFromNetworkId(net_id)
    if ped and DoesEntityExist(ped) then DeletePed(ped) end
end)


AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end

    local victim = args[1]
    local is_dead = args[6] == 1 -- 1 = the damage was fatal

    if is_dead and DoesEntityExist(victim) and IsPedAPlayer(victim) == false and Entity(victim).state.is_combat_ped == true then
        local net_id = NetworkGetNetworkIdFromEntity(victim)
        TriggerServerEvent('human_labs_raid:server:peds:remove_ped_slowly', net_id)
    end
end)
