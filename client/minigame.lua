local function start_minigame(game_type, data, crafting_speed, location)
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'start_minigame',
        game_type = game_type,
        crafting_speed = crafting_speed,
        location = location,
        data = data
    })
end

RegisterNetEvent('human_labs_raid:client:minigame:start', function(game_type, data, location)
    start_minigame(game_type, data, Config.crafting.crafting_speed, location)
end)

RegisterNUICallback('collect_gas', function(data, cb)
    TriggerServerEvent('human_labs_raid:server:crafting:collect_gas', data.purity)
    TriggerServerEvent('human_labs_raid:server:crafting:extraction_gas_done_inform', data.purity, data.world_location)

    local player_ped = PlayerPedId()
    local player_still_alive = DoesEntityExist(player_ped) and not IsEntityDead(player_ped)
    cb({ success = ExtractionPossible and player_still_alive })
end)
RegisterNUICallback('collect_compressed_gas', function(data, cb)
    TriggerServerEvent('human_labs_raid:server:crafting:collect_compressed_gas', data.quality)
    TriggerServerEvent('human_labs_raid:server:crafting:compressed_gas_done_inform', data.purity, data.world_location)
    cb({ success = true })
end)
RegisterNUICallback('collect_packaged_liquid', function(data, cb)
    TriggerServerEvent('human_labs_raid:server:crafting:collect_packaged_liquid', data.quality)
    TriggerServerEvent('human_labs_raid:server:crafting:packaged_liquid_done_inform', data.purity, data.world_location)
    cb({ success = true })
end)

RegisterNUICallback('minigame_cancel', function(data, cb)
    SetNuiFocus(false, false)

    TriggerServerEvent('human_labs_raid:server:crafting:crafting_cancelled', data)
    cb({ success = true })
end)
