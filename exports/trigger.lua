Trigger = {}

local config = Config.triggers

local last_raid_time = nil
local raid_start_time = 0
local alarm_trigger_time = 0
local permit_activation_time = 0
local raid_started = false

local stolen_px41_gas_count = 0
local stolen_px41_liquid_count = 0
local stolen_px41_count = 0
local stolen_px41_per_player = {}

local function raid_start(stealthy)
    raid_started = true
    raid_start_time = GetGameTimer()

    config.on_raid_started(PlayersInside(), stealthy)
end
local function raid_end(maximum_players_raiding)
    local permit_was_activated = permit_activation_time > 0
    local stayed_silent = alarm_trigger_time == 0

    last_raid_time = GetGameTimer()
    local raid_end_time = GetGameTimer()
    local total_raid_time = raid_end_time - raid_start_time
    local silent_time = 0
    local loud_time = 0
    if permit_was_activated and stayed_silent then
        silent_time = total_raid_time
    elseif permit_was_activated and not stayed_silent then
        silent_time = alarm_trigger_time - permit_activation_time
        loud_time = raid_end_time - alarm_trigger_time
    else
        loud_time = total_raid_time
    end

    config.on_raid_end(
        maximum_players_raiding,
        stolen_px41_per_player,
        stolen_px41_count,
        total_raid_time,
        silent_time,
        loud_time,
        stayed_silent,
        permit_was_activated
    )
end

function Trigger:on_first_player_enter(player)
    config.on_first_player_enter(player)
end

function Trigger:on_permit_activated()
    permit_activation_time = GetGameTimer()
    if not raid_started then
        raid_start(true)
    end

    config.on_permit_activated()
end

function Trigger:on_security_alarm_trigger()
    alarm_trigger_time = GetGameTimer()
    if not raid_started then
        raid_start(false)
    end

    local number_of_players = 0
    local players_inside = PlayersInside()
    RunForPlayersInside(function(_src)
        number_of_players = number_of_players + 1
    end)

    config.on_security_alarm_trigger(players_inside, number_of_players)
end

function Trigger:is_raid_disabled()
    if last_raid_time == nil then
        return false
    else
        return GetGameTimer() - last_raid_time < Config.raid_reentry_cooldown
    end
end
function Trigger:raid_disabled_for()
    if Trigger:is_raid_disabled() then
        return Config.raid_reentry_cooldown + last_raid_time - GetGameTimer()
    else
        return 0
    end
end

function Trigger:on_px41_gas_extraction(player, quality)
    stolen_px41_gas_count = stolen_px41_gas_count + 1

    config.on_px41_gas_extraction(player, quality, stolen_px41_gas_count)
end

function Trigger:on_px41_compression(player, quality)
    stolen_px41_liquid_count = stolen_px41_liquid_count + 1

    config.on_px41_compression(player, quality, stolen_px41_liquid_count)
end

function Trigger:on_px41_packaging(player, quality)
    stolen_px41_count = stolen_px41_count + 1
    if stolen_px41_per_player[player] == nil then stolen_px41_per_player[player] = 0 end
    stolen_px41_per_player[player] = stolen_px41_per_player[player] + 1

    config.on_px41_packaging(player, quality, stolen_px41_count)
end

function Trigger:on_last_player_exited(maximum_players_raiding)
    if raid_started then
        raid_end(maximum_players_raiding)
    end

    raid_started = false
    raid_start_time = 0
    alarm_trigger_time = 0
    permit_activation_time = 0

    stolen_px41_gas_count = 0
    stolen_px41_liquid_count = 0
    stolen_px41_count = 0
    stolen_px41_per_player = {}

    config.on_last_player_exited()
end

function Trigger:on_transporter_robbing(player, vehicle_net_id)
    local player_fivem_name = GetPlayerName(player)

    local vehicle_location = nil
    local vehicle = NetworkGetEntityFromNetworkId(vehicle_net_id)
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        vehicle_location = GetEntityCoords(vehicle)
    end

    config.on_transporter_robbing(player, player_fivem_name, vehicle_net_id, vehicle_location)
end
