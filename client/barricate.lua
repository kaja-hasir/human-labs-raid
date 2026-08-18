local function spawn_barricate(location)
    local model_hash = GetHashKey(Config.barricates.model)
    RequestModel(model_hash)
    if RepeatFunctionUntilTrueWithTimeout(HasModelLoaded, { model_hash }) then
        warn("Unable to load barricate object model")
        return nil, nil
    end

    local barricate = CreateObject(
        model_hash,
        location.x,
        location.y,
        location.z,
        true,
        true,
        false
    )
    SetEntityHeading(barricate, location.w)
    SetEntityCanBeDamaged(barricate, false)
    SetEntityDynamic(barricate, false)
    FreezeEntityPosition(barricate, true)
    SetModelAsNoLongerNeeded(model_hash)

    return barricate, NetworkGetNetworkIdFromEntity(barricate)
end

RegisterNetEvent('human_labs_raid:client:barricate:spawn_await_response', function(id, location)
    local obj, obj_net_id = spawn_barricate(location)
    if obj and obj_net_id then
        TriggerServerEvent('human_labs_raid:server:barricate:spawn_response', id, obj_net_id)
    else
        TriggerServerEvent('human_labs_raid:server:barricate:spawn_response_failed', id)
    end
end)
