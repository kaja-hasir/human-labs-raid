local global_blip = nil
local ped_blips = {}
local transporter_blips = {}

function CreateGlobalBlip()
    if not Config.blips.global_blip then return end
    local pos = Config.blips.global_human_labs

    global_blip = AddBlipForCoord(pos.x, pos.y, pos.z)

    SetBlipSprite(global_blip, 499)
    SetBlipDisplay(global_blip, 3)
    SetBlipScale(global_blip, 0.8)
    SetBlipColour(global_blip, 18)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Human Labs")
    EndTextCommandSetBlipName(global_blip)
end

function RemovePedBlips()
    for _, blip in pairs(ped_blips) do
        RemoveBlip(blip)
    end
    ped_blips = {}
end

RegisterNetEvent('human_labs_raid:client:blip:give_ped_blip', function(net_id, have_cone)
    if not NetworkDoesEntityExistWithNetworkId(net_id) then return end
    local ped = NetworkGetEntityFromNetworkId(net_id)
    if not DoesEntityExist(ped) then return end

    if Config.blips.security then
        local blip = AddBlipForEntity(ped)
        ped_blips[net_id] = blip

        SetBlipSprite(blip, 1)
        -- SetBlipAlpha(blip, 130)
        SetBlipAsShortRange(blip, true)
        SetBlipDisplay(blip, 5)
        SetBlipColour(blip, 0) -- white as unset color

        if have_cone then
            SetBlipShowCone(blip, true)
            ShowHeadingIndicatorOnBlip(blip, true)
            SetBlipHighDetail(blip, true)
        end
    end
end)

RegisterNetEvent('human_labs_raid:client:blip:give_transporter_blip', function(net_id)
    if not NetworkDoesEntityExistWithNetworkId(net_id) then return end
    local vehicle = NetworkGetEntityFromNetworkId(net_id)
    if not DoesEntityExist(vehicle) then return end

    local blip = AddBlipForEntity(vehicle)
    transporter_blips[net_id] = blip

    SetBlipSprite(blip, 67)
    SetBlipDisplay(blip, 2)
    SetBlipColour(blip, 18)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Humane Labs Transporter")
    EndTextCommandSetBlipName(blip)
end)

RegisterNetEvent('human_labs_raid:client:blip:set_color', function(net_id, new_color)
    local blip = ped_blips[net_id]
    if blip then
        if NetworkDoesEntityExistWithNetworkId(net_id) then
            local ped = NetworkGetEntityFromNetworkId(net_id)
            if DoesEntityExist(ped) or not IsPedDeadOrDying(ped, true) then
                SetBlipColour(blip, new_color)
            else
                RemoveBlip(blip)
                ped_blips[net_id] = nil
            end
        else
            RemoveBlip(blip)
            ped_blips[net_id] = nil
        end
    end
end)

RegisterNetEvent('human_labs_raid:client:blip:remove_blip', function(net_id)
    local blip = ped_blips[net_id]
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
    ped_blips[net_id] = nil
end)

RegisterNetEvent('human_labs_raid:client:blip:remove_transporter_blip', function(net_id)
    local blip = transporter_blips[net_id]
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
    transporter_blips[net_id] = nil
end)

RegisterNetEvent('human_labs_raid:client:blip:remove_ped_blips', function()
    for _, blip in pairs(ped_blips) do
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    ped_blips = {}
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if global_blip then
        RemoveBlip(global_blip)
    end
end)
