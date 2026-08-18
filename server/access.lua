local access_granted = Config.access_not_required

function IsAccessGranted()
    return access_granted
end

function ResetAccess()
    access_granted = Config.access_not_required
end

RegisterNetEvent('human_labs_raid:server:access:npc_permit_check', function(ped)
    if not RaidDisabled and Inventory:GetItemCount(source, Config.entry_attendant.permit_item) > 0 then
        access_granted = true
        Inventory:RemoveItem(source, Config.entry_attendant.permit_item, 1)
        TriggerClientEvent('human_labs_raid:client:npc:permit_approved', source, ped)
        UpdateBlips()

        Trigger:on_permit_activated()
    else
        TriggerClientEvent('human_labs_raid:client:npc:permit_declined', source, ped)
    end
end)
