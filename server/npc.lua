local prohibited_lab_area_player_count = 0

local entry_attendant_net_id = nil
local smoking_scientist_net_id = nil
local lab_entry_security_net_id = nil
local cat_net_id = nil

function MakeNpcInterableClient(client)
    TriggerClientEvent('human_labs_raid:client:npc:make_entry_attendant_interactable', client, entry_attendant_net_id)
    TriggerClientEvent('human_labs_raid:client:npc:make_ped_smoking_scientist_interactable', client, smoking_scientist_net_id)
    TriggerClientEvent('human_labs_raid:client:npc:make_cat_interactable', client, cat_net_id)
end

function SpawnEntryAttendant()
    entry_attendant_net_id = PlacePed('human_labs_raid:client:npc:spawn_entry_attendant', nil)
    RunForPlayersInside(function(src)
        if not RaidDisabled then
            TriggerClientEvent('human_labs_raid:client:npc:make_entry_attendant_interactable', src, entry_attendant_net_id)
        end
    end)
    GivePedBlip(entry_attendant_net_id, PedTypeForBlip.EntryNpc)
end

function SpawnWaver()
    local _waver_net_id = PlacePed('human_labs_raid:client:npc:spawn_waver', nil)
end

function SpawnSmokingScientist()
    smoking_scientist_net_id = PlacePed('human_labs_raid:client:npc:spawn_smoking_scientist', nil)
    RunForPlayersInside(function(src)
        TriggerClientEvent('human_labs_raid:client:npc:make_ped_smoking_scientist_interactable', src, smoking_scientist_net_id)
    end)
    GivePedBlip(smoking_scientist_net_id, PedTypeForBlip.SmokingScientist)
end

function SpawnLabEntrySecurity()
    lab_entry_security_net_id = PlacePed('human_labs_raid:client:spawn_lab_entry_security', PlayersInside())
    GivePedBlip(lab_entry_security_net_id, PedTypeForBlip.LabEntrySecurity)
end

function SpawnCat()
    cat_net_id = PlacePed('human_labs_raid:client:npc:spawn_cat', nil)
    RunForPlayersInside(function(src)
        TriggerClientEvent('human_labs_raid:client:npc:make_cat_interactable', src, cat_net_id)
    end)
end

function ClearNpcInteractions()
    entry_attendant_net_id = nil
    smoking_scientist_net_id = nil
    lab_entry_security_net_id = nil
    cat_net_id = nil
end

RegisterNetEvent('human_labs_raid:server:npc:prohibited_lab_entry_warning', function(entered)
    local area_empty_before = prohibited_lab_area_player_count == 0
    if entered then
        prohibited_lab_area_player_count = prohibited_lab_area_player_count + 1
    else
        prohibited_lab_area_player_count = math.max(0, prohibited_lab_area_player_count - 1)
    end

    if not lab_entry_security_net_id then return end
    local ped = NetworkGetEntityFromNetworkId(lab_entry_security_net_id)
    if not ped or not DoesEntityExist(ped) then return end
    local owner = NetworkGetEntityOwner(ped)
    if not owner or owner == 0 then return end

    if not area_empty_before and prohibited_lab_area_player_count == 0 then
        TriggerClientEvent('human_labs_raid:client:npc:turn_ped_lab_entry_security_to_warn', owner, lab_entry_security_net_id, false)
    elseif area_empty_before and prohibited_lab_area_player_count ~= 0 then
        TriggerClientEvent('human_labs_raid:client:npc:turn_ped_lab_entry_security_to_warn', owner, lab_entry_security_net_id, true)
    end
end)
