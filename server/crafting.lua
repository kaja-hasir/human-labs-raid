local number_of_gas_extractions = 0

RegisterNetEvent('human_labs_raid:server:crafting:collect_gas', function(purity)
    if not PlayersInsideLab[source] then return end

    local item
    if math.floor(purity) >= 95 then
        item = Config.crafting.gas_items.perfect_quality
    elseif math.floor(purity) >= 80 then
        item = Config.crafting.gas_items.high_quality
    elseif math.floor(purity) >= 50 then
        item = Config.crafting.gas_items.medium_quality
    else
        item = Config.crafting.gas_items.low_quality
    end

    Inventory:AddItem(source, item, 1, {})
end)

RegisterNetEvent('human_labs_raid:server:crafting:collect_compressed_gas', function(quality)
    if not PlayersInsideLab[source] then return end

    local item
    if quality == "perfect_quality" then
        item = Config.crafting.compressed_gas_items.perfect_quality
    elseif quality == "high_quality" then
        item = Config.crafting.compressed_gas_items.high_quality
    elseif quality == "medium_quality" then
        item = Config.crafting.compressed_gas_items.medium_quality
    else
        item = Config.crafting.compressed_gas_items.low_quality
    end

    Inventory:AddItem(source, item, 1, {})
end)

RegisterNetEvent('human_labs_raid:server:crafting:collect_packaged_liquid', function(quality)
    if not PlayersInsideLab[source] then return end

    local item
    if quality == "perfect_quality" then
        item = Config.crafting.packaged_gas_items.perfect_quality
    elseif quality == "high_quality" then
        item = Config.crafting.packaged_gas_items.high_quality
    elseif quality == "medium_quality" then
        item = Config.crafting.packaged_gas_items.medium_quality
    else
        item = Config.crafting.packaged_gas_items.low_quality
    end

    Inventory:AddItem(source, item, 1, {})
end)

RegisterNetEvent('human_labs_raid:server:crafting:stabilize_check', function(data, location)
    local item_required = data.item_required
    local amount_required = data.amount_required

    if Inventory:GetItemCount(source, item_required) >= amount_required then
        Inventory:RemoveItem(source, item_required, amount_required)

        TriggerClientEvent('human_labs_raid:client:minigame:start', source, 'stabilize', data, location)
    else
        Notify:message(
            source,
            'Crafting',
            string.format(Locale.crafting.crafting_requirements, amount_required, item_required)
        )
    end
end)

RegisterNetEvent('human_labs_raid:server:crafting:package_check', function(data, location)
    local item_required = data.item_required
    local amount_required = data.amount_required

    if Inventory:GetItemCount(source, item_required) >= amount_required then
        Inventory:RemoveItem(source, item_required, amount_required)

        TriggerClientEvent('human_labs_raid:client:minigame:start', source, 'package', data, location)
    else
        Notify:message(
            source,
            'Crafting',
            string.format(Locale.crafting.crafting_requirements, amount_required, item_required)
        )
    end
end)

RegisterNetEvent('human_labs_raid:server:crafting:crafting_cancelled', function(data)
    if not PlayersInsideLab[source] then return end
    if not data or next(data) == nil then return end

    local item_required = data.item_required
    local amount_required = data.amount_required

    if item_required == "" or amount_required == 0 then return end

    Inventory:AddItem(source, item_required, amount_required, {})
end)

RegisterNetEvent('human_labs_raid:server:crafting:extraction_gas_done_inform', function(quality, crafting_location)
    if Config.crafting.extraction_effect then
        RunForPlayersInside(function(src)
            TriggerClientEvent('human_labs_raid:client:effect:extraction', src, crafting_location)
        end)
    end

    number_of_gas_extractions = number_of_gas_extractions + 1
    Trigger:on_px41_gas_extraction(source, quality)
    RunForPlayersInside(function(src)
        TriggerClientEvent('human_labs_raid:client:crafting:change_extraction_possible', src, not RaidDisabled and Config.crafting.extraction_possible(number_of_gas_extractions))
    end)
end)
RegisterNetEvent('human_labs_raid:server:crafting:compressed_gas_done_inform', function(quality, crafting_location)
    if Config.crafting.compression_effect then
        RunForPlayersInside(function(src)
            TriggerClientEvent('human_labs_raid:client:effect:compress', src, crafting_location)
        end)
    end

    Trigger:on_px41_compression(source, quality)
end)
RegisterNetEvent('human_labs_raid:server:crafting:packaged_liquid_done_inform', function(quality, crafting_location)
    if Config.crafting.packaging_effect then
        RunForPlayersInside(function(src)
            TriggerClientEvent('human_labs_raid:client:effect:packaging', src, crafting_location)
        end)
    end

    Trigger:on_px41_packaging(source, quality)
end)
