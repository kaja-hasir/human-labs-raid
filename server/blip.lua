local ped_blips = {}
local player_wears_lab_outfit = {}
local BlipColor = {
    Red = 1,
    Blue = 3,
    Yellow = 5,
    Gray = 39,
    Orange = 81
}

PedTypeForBlip = {
    CombatStatic = 0,
    CombatPatrolling = 1,
    CombatInsideBuilding = 2,
    CombatRaiding = 3,
    EntryNpc = 4,
    SmokingScientist = 5,
    LabEntrySecurity = 6,
    PatrollingScientist = 7
}

local function should_ped_have_blip_cone(ped_type)
    return (not Config.blips.show_cones_only_in_stealth
        or not Hostile)
        and ((Config.blips.security_cones and (
                ped_type == PedTypeForBlip.CombatStatic
                or ped_type == PedTypeForBlip.CombatPatrolling
                or ped_type == PedTypeForBlip.CombatInsideBuilding
                or ped_type == PedTypeForBlip.CombatRaiding))
            or (Config.blips.stealth_relevant_cones and (
                ped_type == PedTypeForBlip.PatrollingScientist
            )))
end

local function should_display_blip(ped_type)
    if ped_type == nil then return false end
    return (
        (ped_type == PedTypeForBlip.CombatStatic and Config.blips.security)
        or (ped_type == PedTypeForBlip.CombatPatrolling and Config.blips.security)
        or (ped_type == PedTypeForBlip.CombatInsideBuilding and Config.blips.security)
        or (ped_type == PedTypeForBlip.CombatRaiding and Config.blips.security)
        or (ped_type == PedTypeForBlip.EntryNpc and Config.blips.interactable_npcs)
        or (ped_type == PedTypeForBlip.SmokingScientist and Config.blips.interactable_npcs)
        or (ped_type == PedTypeForBlip.LabEntrySecurity and Config.blips.security)
        or (ped_type == PedTypeForBlip.PatrollingScientist and Config.blips.stealth_relevant)
    )
end

local function get_blip_color(net_id, player_wears_coat)
    local collection = ped_blips[net_id]
    if collection == nil then return end

    local ped_type = collection.ped_type
    if ped_type == nil then return end

    local is_general_combat_ped = false
    if ped_type == PedTypeForBlip.CombatStatic
    or ped_type == PedTypeForBlip.CombatPatrolling
    or ped_type == PedTypeForBlip.CombatRaiding then
        is_general_combat_ped = true
    end

    if is_general_combat_ped then
        if Hostile or not IsAccessGranted() then
            return BlipColor.Red
        else
            return BlipColor.Yellow
        end
    elseif ped_type == PedTypeForBlip.CombatInsideBuilding then
        if Hostile or (player_wears_coat == nil or player_wears_coat == false) then
            return BlipColor.Red
        else
            return BlipColor.Yellow
        end
    elseif ped_type == PedTypeForBlip.EntryNpc then
        if Hostile then
            return BlipColor.Gray
        else
            return BlipColor.Blue
        end
    elseif ped_type == PedTypeForBlip.LabEntrySecurity then
        if Hostile then
            return BlipColor.Gray
        else
            return BlipColor.Orange
        end
    elseif ped_type == PedTypeForBlip.SmokingScientist then
        if Hostile then
            return BlipColor.Gray
        else
            return BlipColor.Blue
        end
    elseif ped_type == PedTypeForBlip.PatrollingScientist then
        if Hostile then
            return BlipColor.Gray
        else
            return BlipColor.Red
        end
    end


    if is_general_combat_ped and IsAccessGranted() and not Hostile then
        return BlipColor.Yellow
    elseif is_general_combat_ped and IsAccessGranted() and not Hostile and player_wears_coat == true then
        return BlipColor.Yellow
    elseif is_general_combat_ped then
        return BlipColor.Red
    elseif ped_type == PedTypeForBlip.CombatInsideBuilding then
        return BlipColor.Red
    elseif ped_type == PedTypeForBlip.EntryNpc and not Hostile then
        return BlipColor.Blue
    elseif ped_type == PedTypeForBlip.LabEntrySecurity and not Hostile then
        return BlipColor.Orange
    elseif ped_type == PedTypeForBlip.SmokingScientist and not Hostile then
        return BlipColor.Blue
    elseif ped_type == PedTypeForBlip.PatrollingScientist and not Hostile then
        return BlipColor.Red
    else
        return BlipColor.Gray
    end
end

local function update_blip_color(net_id)
    local collection = ped_blips[net_id]
    if collection then
        RunForPlayersInside(function(src)
            local new_color = get_blip_color(net_id, player_wears_lab_outfit[src])
            TriggerClientEvent('human_labs_raid:client:blip:set_color', src, net_id, new_color)
        end)
    end
end

function UpdateBlips()
    for net_id, _ in pairs(ped_blips) do
        update_blip_color(net_id)
    end
end

function GivePedBlip(net_id, ped_type)
    if not net_id then return end
    if not should_display_blip(ped_type) then return end

    ped_blips[net_id] = {
        ped_type = ped_type,
        alerted = false
    }

    RunForPlayersInside(function(src)
        local ped = NetworkGetEntityFromNetworkId(net_id)
        if ped and ped ~= 0 and DoesEntityExist(ped) then
            local have_cone = should_ped_have_blip_cone(ped_type)
            TriggerClientEvent('human_labs_raid:client:blip:give_ped_blip', src, net_id, have_cone)
        end
    end)

    update_blip_color(net_id)
end

function RemovePedBlips()
    RunForPlayersInside(function(src)
        TriggerClientEvent('human_labs_raid:client:blip:remove_ped_blips', src)
    end)
    ped_blips = {}
end

function SetBlipAlerted(net_id, new_state)
    local collection = ped_blips[net_id]
    if collection == nil then return end
    collection.alerted = new_state
    update_blip_color(net_id)
end

function InitiateBlipsForPlayer(source)
    for net_id, collection in pairs(ped_blips) do
        if net_id and collection then
            if should_display_blip(collection.ped_type) then
                local ped = NetworkGetEntityFromNetworkId(net_id)
                if ped and ped ~= 0 and DoesEntityExist(ped) then
                    local have_cone = should_ped_have_blip_cone(collection.ped_type)
                    TriggerClientEvent('human_labs_raid:client:GivePedBlip', source, net_id, have_cone)

                    local color = get_blip_color(net_id, player_wears_lab_outfit[source])
                    TriggerClientEvent('human_labs_raid:client:blip:set_color', source, net_id, color)
                end
            end
        end
    end
end

RegisterNetEvent('human_labs_raid:server:blips:inform_wearing_lab_coat', function(wears_lab_coat)
    player_wears_lab_outfit[source] = wears_lab_coat
    UpdateBlips()
end)
