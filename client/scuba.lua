local interaction_areas = { nil, nil, nil, nil }
local gears_taken = { true, true, true, true }
local response = false
local response_recieved = false
local awaiting_response = false
local before_wearing_gear_outfit = Outfit.Normal


local function spawn_object(location, model_hash)
    RequestModel(model_hash)
    if RepeatFunctionUntilTrueWithTimeout(HasModelLoaded, { model_hash }) then
        warn("Unable to load tank model")
        return nil, nil
    end

    local obj = CreateObject(
        model_hash,
        location.x,
        location.y,
        location.z,
        true,
        true,
        false
    )
    SetEntityHeading(obj, location.w)
    SetEntityCanBeDamaged(obj, false)
    SetEntityDynamic(obj, false)
    FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(model_hash)

    return NetworkGetNetworkIdFromEntity(obj)
end

local function spawn_props(location, use_gear_props)
    if location == nil then return nil, nil, nil end
    local tank_location = location.tank
    local mask_location = location.mask
    local bag_location = location.clothes_bag
    if tank_location == nil or mask_location == nil or bag_location == nil then return nil, nil, nil end

    local tank_net_id = nil
    local mask_net_id = nil
    local bag_net_id = nil
    if use_gear_props then
        tank_net_id = spawn_object(tank_location, GetHashKey(Config.scuba.scuba_tank_model))
        mask_net_id = spawn_object(mask_location, GetHashKey(Config.scuba.scuba_mask_model))
    else
        bag_net_id = spawn_object(bag_location, GetHashKey(Config.scuba.clothes_bag_model))
    end

    return tank_net_id, mask_net_id, bag_net_id
end

local function has_enough_gas_items()
    local items_required = Config.scuba.gear_equip_item_required
    local amount_required = Config.scuba.gear_equip_amount_required
    local count = 0
    for _, item in pairs(items_required) do
        count = count + Inventory:GetItemCount(item, {})
    end
    return count >= amount_required
end
local function start_interaction_area(index)
    if not index or index < 1 or index > 4 then return end
    if interaction_areas[index] ~= nil then Target:removeArea(interaction_areas[index]) end

    interaction_areas[index] = Target:addBoxZone({
        name = "scuba_gear",
        coords = Config.scuba.interaction_areas[index].coords,
        size = Config.scuba.interaction_areas[index].size,
        rotation = Config.scuba.interaction_areas[index].rotation,
        debug = Config.debug_poly,
        options = {{
            label = string.format(Locale.scuba.wear_diving_gear_unable, Config.scuba.gear_equip_amount_required),
            name = "scuba_gear_wear_unable",
            icon = "fa-solid fa-ban",
            iconColor = '#CC0202',
            distance = 1.5,
            canInteract = function()
                return not has_enough_gas_items() and not gears_taken[index]
            end
        },{
            label = Locale.scuba.wear_diving_gear,
            name = "scuba_gear_wear",
            icon = "fa-solid fa-mask-ventilator",
            distance = 1.5,
            canInteract = function()
                return has_enough_gas_items()
                    and not gears_taken[index]
                    and not awaiting_response
                    and WearingPlayerOutfit ~= Outfit.Scuba
            end,
            onSelect = function()
                response_recieved = false
                TriggerServerEvent('human_labs_raid:server:scuba:change_gear_taken', index, true)

                awaiting_response = true
                while not response_recieved do Wait(100) end
                awaiting_response = false

                if not response then return end
                LoadOutfitWithAnimation(function()
                    before_wearing_gear_outfit = WearingPlayerOutfit
                    LoadScubaOutfit()
                end)
            end
        },{
            label = Locale.scuba.drop_diving_gear,
            name = "scuba_gear_drop",
            icon = "fa-solid fa-shirt",
            distance = 1.5,
            canInteract = function()
                return gears_taken[index]
                    and not awaiting_response
                    and WearingPlayerOutfit == Outfit.Scuba
            end,
            onSelect = function()
                response_recieved = false
                TriggerServerEvent('human_labs_raid:server:scuba:change_gear_taken', index, false)

                awaiting_response = true
                while not response_recieved do Wait(100) end
                awaiting_response = false

                if not response then return end
                LoadOutfitWithAnimation(function()
                    if before_wearing_gear_outfit == Outfit.Lab then
                        LoadLabOutfit()
                    else
                        LoadNormalOutfit()
                    end
                end)
            end
        }}
    })
end

function StartScubaAreas()
    while not Target:loaded() do Wait(100) end

    for index, _ in ipairs(gears_taken) do
        if index <= Config.scuba.maximum_scuba_gear then
            start_interaction_area(index)
        end
    end
end

function StopScubaAreas()
    for _, area in pairs(interaction_areas) do
        if area ~= nil then
            Target:removeArea(area)
        end
    end
    interaction_areas = { nil, nil, nil, nil }
end


RegisterNetEvent('human_labs_raid:client:scuba:change_gear_taken_response', function(successful)
    response = successful
    response_recieved = true
end)

RegisterNetEvent('human_labs_raid:client:scuba:update_gears_taken', function(new_state)
    gears_taken = new_state
end)

RegisterNetEvent('human_labs_raid:client:scuba:spawn_await_response', function(index, use_gear_props, location)
    local tank_net_id, mask_net_id, bag_net_id = spawn_props(location, use_gear_props)
    if (tank_net_id and mask_net_id) or bag_net_id then
        TriggerServerEvent('human_labs_raid:server:scuba:spawn_response', index, tank_net_id, mask_net_id, bag_net_id)
    else
        TriggerServerEvent('human_labs_raid:server:scuba:spawn_response_failed')
    end
end)
