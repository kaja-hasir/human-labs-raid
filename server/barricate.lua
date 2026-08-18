local should_have_barricates = false
local barricate_net_ids = {}
local spawn_failed = {}
local spawn_net_id = {}

function PlaceBarricatesIfShould()
    if not should_have_barricates then return end
    local locations = Config.barricates.locations
    for _, location in ipairs(locations) do
        local target_player = GetRandomPlayerInside()
        if target_player ~= nil then
            local response_id = NextIdForResponses()
            spawn_failed[response_id] = false
            spawn_net_id[response_id] = nil
            TriggerClientEvent('human_labs_raid:client:barricate:spawn_await_response', target_player, response_id, location)

            local timeout = 0
            while spawn_net_id[response_id] == nil
            and not spawn_failed[response_id]
            and timeout < 5000
            and IsPlayerStillConnected(target_player) do
                Wait(100)
                timeout = timeout + 100
            end
        end
    end
end
function RemoveBarricates()
    for barricate_net_id, _ in pairs(barricate_net_ids) do
        if barricate_net_id then
            local barricate = NetworkGetEntityFromNetworkId(barricate_net_id)
            if barricate and barricate ~= 0 then
                DeleteEntity(barricate)
            end
        end
    end
end

function PlaceBarricatesNextTime()
    should_have_barricates = true
end
function RemoveBarricatesNextTime()
    should_have_barricates = false
end

RegisterNetEvent('human_labs_raid:server:barricate:spawn_response', function(id, net_id)
    spawn_net_id[id] = net_id
    barricate_net_ids[net_id] = true
end)
RegisterNetEvent('human_labs_raid:server:barricate:spawn_response_failed', function(id)
    spawn_failed[id] = true
end)
