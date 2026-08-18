local maximum_players_raiding = 0
local players_inside = {}

local function count_non_ignored_players_inside()
    local count = 0
    for src, _ in pairs(players_inside) do
        if not Config.security.player_ignored_by_security(src) then
            count = count + 1
        end
    end
    return count
end

function GetRandomPlayerInside()
    local players = {}
    for src in pairs(players_inside) do
        players[#players + 1] = src
    end
    if #players == 0 then
        return nil
    end
    return players[math.random(#players)]
end

function CountPlayersInside()
    local count = 0
    for _ in pairs(players_inside) do
        count = count + 1
    end
    return count
end

function GetMaximumPlayersRaiding()
    return maximum_players_raiding
end

function PlayersInside()
    return players_inside
end
function RunForPlayersInside(fn)
    for src in pairs(players_inside) do
        fn(src)
    end
end

RegisterNetEvent('human_labs_raid:server:zone:global_enter', function()
    players_inside[source] = true
    maximum_players_raiding = math.max(maximum_players_raiding, count_non_ignored_players_inside())

    SetupClient(source)

    local first_player_entered = CountPlayersInside() == 1
    if first_player_entered then
        Trigger:on_first_player_enter(source)
        StartServer()
    end
end)
RegisterNetEvent('human_labs_raid:server:zone:global_exit', function()
    players_inside[source] = nil

    CleanupClient(source)

    local no_player_inside = next(players_inside) == nil
    if no_player_inside then
        Trigger:on_last_player_exited(maximum_players_raiding)
        CleanupServer()
    end
end)

RegisterNetEvent('human_labs_raid:server:zone:perimeter_enter', function()
    TriggerClientEvent('human_labs_raid:client:suspicious:inform_perimeter_zone', source, true)

    if not IsAccessGranted() and not Config.security.player_ignored_by_security(source) then
        TriggerAlarm()
    end
end)
RegisterNetEvent('human_labs_raid:server:zone:perimeter_exit', function()
    TriggerClientEvent('human_labs_raid:client:suspicious:inform_perimeter_zone', source, false)
end)

RegisterNetEvent('human_labs_raid:server:zone:lab_enter', function()
    PlayersInsideLab[source] = true
    TriggerClientEvent('human_labs_raid:client:suspicious:inform_suspicious_lab', source, true, Locale.suspicion.in_lab)
end)
RegisterNetEvent('human_labs_raid:server:zone:lab_exit', function()
    PlayersInsideLab[source] = nil
    TriggerClientEvent('human_labs_raid:client:suspicious:inform_suspicious_lab', source, false, "")
end)

AddEventHandler('playerDropped', function()
    if players_inside[source] then
        players_inside[source] = nil

        if next(players_inside) == nil then
            CleanupServer()
        end
    end
end)
