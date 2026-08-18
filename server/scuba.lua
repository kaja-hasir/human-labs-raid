local gears_taken = { false, false, false, false }
local tank_net_ids = { nil, nil, nil, nil }
local mask_net_ids = { nil, nil, nil, nil }
local clothes_bag_net_ids = { nil, nil, nil, nil }
local spawn_done = false


local function place_scuba_props(index, location)
    local target_player = GetRandomPlayerInside()
    if target_player == nil then return nil end

    TriggerClientEvent('human_labs_raid:client:scuba:spawn_await_response',
        target_player,
        index,
        not gears_taken[index],
        location
    )

    while not spawn_done and IsPlayerStillConnected(target_player) do
        Wait(100)
    end
    spawn_done = false
end

function ScubaGearTakenClient(client)
    TriggerClientEvent('human_labs_raid:client:scuba:update_gears_taken', client, gears_taken)
end

function PlaceAllScubaGear()
    gears_taken = { false, false, false, false }
    RunForPlayersInside(ScubaGearTakenClient)

    local locations = Config.scuba.gear_locations
    for index, location in ipairs(locations) do
        if index <= Config.scuba.maximum_scuba_gear then
            place_scuba_props(index, location)
        end
    end
end

function CleanupScubaGear()
    for _, net_id in ipairs(tank_net_ids) do
        if net_id then
            local tank = NetworkGetEntityFromNetworkId(net_id)
            if tank and tank ~= 0 and DoesEntityExist(tank) then
                DeleteEntity(tank)
            end
        end
    end
    for _, net_id in ipairs(mask_net_ids) do
        if net_id then
            local mask = NetworkGetEntityFromNetworkId(net_id)
            if mask and mask ~= 0 and DoesEntityExist(mask) then
                DeleteEntity(mask)
            end
        end
    end
    for _, net_id in ipairs(clothes_bag_net_ids) do
        if net_id then
            local clothes_bag = NetworkGetEntityFromNetworkId(net_id)
            if clothes_bag and clothes_bag ~= 0 and DoesEntityExist(clothes_bag) then
                DeleteEntity(clothes_bag)
            end
        end
    end

    tank_net_ids = { nil, nil, nil, nil }
    mask_net_ids = { nil, nil, nil, nil }
    clothes_bag_net_ids = { nil, nil, nil, nil }
end


RegisterNetEvent('human_labs_raid:server:scuba:change_gear_taken', function(index, new_state)
    if gears_taken[index] ~= new_state then
        local tank_net_id = tank_net_ids[index]
        local mask_net_id = mask_net_ids[index]
        local clothes_bag_net_id = clothes_bag_net_ids[index]
        if tank_net_id then
            local tank = NetworkGetEntityFromNetworkId(tank_net_id)
            if tank and tank ~= 0 then
                DeleteEntity(tank)
            end
        end
        if mask_net_id then
            local mask = NetworkGetEntityFromNetworkId(mask_net_id)
            if mask and mask ~= 0 then
                DeleteEntity(mask)
            end
        end
        if clothes_bag_net_id then
            local clothes_bag = NetworkGetEntityFromNetworkId(clothes_bag_net_id)
            if clothes_bag and clothes_bag ~= 0 then
                DeleteEntity(clothes_bag)
            end
        end

        gears_taken[index] = new_state
        RunForPlayersInside(ScubaGearTakenClient)
        TriggerClientEvent('human_labs_raid:client:scuba:change_gear_taken_response', source, true)

        place_scuba_props(index, Config.scuba.gear_locations[index]) -- clears source variable
    else
        TriggerClientEvent('human_labs_raid:client:scuba:change_gear_taken_response', source, false)
    end
end)

RegisterNetEvent('human_labs_raid:server:scuba:spawn_response', function(index, tank_net_id, mask_net_id, clothes_bag_net_id)
    spawn_done = true
    tank_net_ids[index] = tank_net_id
    mask_net_ids[index] = mask_net_id
    clothes_bag_net_ids[index] = clothes_bag_net_id
end)
RegisterNetEvent('human_labs_raid:server:scuba:spawn_response_failed', function()
    spawn_done = true
end)

RegisterNetEvent('human_labs_raid:server:scuba:consume_gas', function(amount)
    local items_required = Config.scuba.gear_equip_item_required
    for _, item in pairs(items_required) do
        local count = Inventory:GetItemCount(source, item)
        if count >= amount then
            Inventory:RemoveItem(source, item, amount)
            return
        elseif count > 0 then
            Inventory:RemoveItem(source, item, count)
            amount = amount - count
        end
    end
end)
