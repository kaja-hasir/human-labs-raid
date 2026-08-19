local stay_non_hostile = false
local guards_alarming_on_radio = {}
local patrolling_scientists = 0

local disable_alarm_loop_active = false
local alarm_trigger_loop_active = false
local scientist_loop_active = false
local raider_spawn_loop_active = false

Hostile = false
PlayersInsideLab = {}

local function spawn_combat_peds()
    for _, location in ipairs(Config.security.static_ped_locations) do
        local ped_net_id = PlacePed('human_labs_raid:client:security:spawn_guard_stationary', location)
        GivePedBlip(ped_net_id, PedTypeForBlip.CombatStatic)
    end
    for _, location in ipairs(Config.security.inside_building_ped_locations) do
        local ped_net_id = PlacePed('human_labs_raid:client:security:spawn_guard_stationary', location)
        GivePedBlip(ped_net_id, PedTypeForBlip.CombatInsideBuilding)
    end
    for _, location in ipairs(Config.security.patrolling_ped_locations) do
        local ped_net_id = PlacePed('human_labs_raid:client:security:spawn_guard_patrolling', location)
        GivePedBlip(ped_net_id, PedTypeForBlip.CombatPatrolling)
    end
end

local function spawn_raider()
    local raider_net_id = PlacePed('human_labs_raid:client:security:spawn_raider', PlayersInside())
    GivePedBlip(raider_net_id, PedTypeForBlip.CombatRaiding)
end

local function spawn_loop()
    if raider_spawn_loop_active then return end
    raider_spawn_loop_active = true

    CreateThread(function()
        local max_combat_peds = Config.security.max_combat_peds

        while Hostile do
            if PedCount() <= max_combat_peds and #PlayersInsideLab > 0 then
                spawn_raider()
                Wait(Config.security.spawn_rate_on_alarm(#PlayersInside) + math.random(0, 5000))
            else
                Wait(1000)
            end
        end
        raider_spawn_loop_active = false
    end)
end

function SpawnInitialEntities()
    SpawnEntryAttendant()
    SpawnWaver()
    SpawnLabEntrySecurity()
    SpawnSmokingScientist()
    SpawnCat()

    spawn_combat_peds()
end

function TriggerAlarm()
    if not stay_non_hostile and not Config.debug_enemies then
        RunForPlayersInside(function(src)
            TriggerClientEvent('human_labs_raid:client:security:set_area_hostile', src)
            TriggerClientEvent('human_labs_raid:client:suspicious:inform_alarm', src, true)
        end)

        local first_alarm_trigger = not Hostile
        if first_alarm_trigger then
            Trigger:on_security_alarm_trigger()
        end

        Hostile = true
        spawn_loop()
    end
end

local function disable_alarm()
    RunForPlayersInside(function(src)
        TriggerClientEvent('human_labs_raid:client:security:set_area_stay_non_hostile', src)
        TriggerClientEvent('human_labs_raid:client:suspicious:inform_alarm', src, false)
    end)

    Hostile = false
end

function EnsureSecurityLoop()
    if not disable_alarm_loop_active then
        disable_alarm_loop_active = true
        CreateThread(function()
            while not stay_non_hostile do
                Wait(500)
                if Config.security.disable_alarm(PlayersInside()) then
                    stay_non_hostile = true
                    disable_alarm()
                end
            end
            disable_alarm_loop_active = false
        end)
    end

    if not alarm_trigger_loop_active then
        alarm_trigger_loop_active = true
        CreateThread(function()
            while not Hostile do
                Wait(2000)

                local target_player = GetRandomPlayerInside()
                if target_player then
                    TriggerClientEvent('human_labs_raid:client:security:check_ped_states', target_player, PlayersInside(), GetSpawnedPeds())
                end
            end
            alarm_trigger_loop_active = false
        end)
    end

    if not scientist_loop_active then
        scientist_loop_active = true
        CreateThread(function()
            local scientist_spawn_trigger = Config.scientist.patrolling.delay_between_ms
            local max_active_scientists = Config.scientist.patrolling.number_of_active
            local time_before_last_scientist_spawn = scientist_spawn_trigger

            while not Hostile do
                Wait(500)

                if patrolling_scientists < max_active_scientists
                and time_before_last_scientist_spawn >= scientist_spawn_trigger then
                    time_before_last_scientist_spawn = math.random() * 3000

                    local players_inside_not_in_lab = {}
                    RunForPlayersInside(function(src)
                        if not PlayersInsideLab[src] then
                            players_inside_not_in_lab[src] = true
                        end
                    end)

                    local scientist_net_id = PlacePed('human_labs_raid:client:security:spawn_patrolling_scientist', players_inside_not_in_lab)
                    if scientist_net_id and scientist_net_id ~= 0 then
                        patrolling_scientists = patrolling_scientists + 1
                        GivePedBlip(scientist_net_id, PedTypeForBlip.PatrollingScientist)
                    end
                else
                    time_before_last_scientist_spawn = time_before_last_scientist_spawn + 500
                end
            end
            scientist_loop_active = false
        end)
    end
end

function ResetCombatZone()
    Hostile = false
    stay_non_hostile = false

    RemovePedBlips()
    ResetAccess()
    ClearNpcInteractions()
end

RegisterNetEvent('human_labs_raid:server:security:remove_patrolling_scientist', function(net_id)
    local ped = NetworkGetEntityFromNetworkId(net_id)
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        local owner = NetworkGetEntityOwner(ped)

        RunForPlayersInside(function(src)
            TriggerClientEvent('human_labs_raid:client:ped:remove', src, net_id)
        end)

        if owner and owner > 0 then
            TriggerClientEvent('human_labs_raid:client:ped:remove', owner, net_id)
        else
            DeleteEntity(ped)
        end
        patrolling_scientists = patrolling_scientists - 1
    end
end)

RegisterNetEvent('human_labs_raid:server:security:prohibited_lab_entry', function()
    TriggerClientEvent('human_labs_raid:client:security:check_prohibited_entry_los', source, GetSpawnedPeds())
end)

RegisterNetEvent('human_labs_raid:server:security:ped_alerts_on_radio', function(net_id)
    if not guards_alarming_on_radio[net_id] then
        local ped = NetworkGetEntityFromNetworkId(net_id)
        if ped and ped ~= 0 then
            if RepeatFunctionUntilTrueWithTimeout(EntityHasOwner, { ped }) then return end
            local owner = NetworkGetEntityOwner(ped)

            guards_alarming_on_radio[net_id] = true
            TriggerClientEvent('human_labs_raid:client:security:ped_alerts_on_radio', owner, net_id)

            SetBlipAlerted(net_id, true)

            RunForPlayersInside(function(src)
                TriggerClientEvent('human_labs_raid:client:suspicious:inform_spotted', src, true, net_id)
            end)
        end
    end
end)

RegisterNetEvent('human_labs_raid:server:security:ped_alerts_on_radio_pause', function(net_id)
    SetBlipAlerted(net_id, false)

    RunForPlayersInside(function(src)
        TriggerClientEvent('human_labs_raid:client:suspicious:inform_spotted_pause', src, false, net_id)
    end)
end)

RegisterNetEvent('human_labs_raid:server:security:ped_alerts_on_radio_resume', function(net_id)
    SetBlipAlerted(net_id, true)

    RunForPlayersInside(function(src)
        TriggerClientEvent('human_labs_raid:client:suspicious:inform_spotted_resume', src, net_id)
    end)
end)

RegisterNetEvent('human_labs_raid:server:security:ped_alerts_on_radio_success', function(net_id)
    guards_alarming_on_radio[net_id] = nil
    SetBlipAlerted(net_id, false)

    RunForPlayersInside(function(src)
        TriggerClientEvent('human_labs_raid:client:suspicious:inform_spotted', src, false, net_id)
    end)

    TriggerAlarm()
end)

RegisterNetEvent('human_labs_raid:server:security:ped_alerts_on_radio_failed', function(net_id)
    guards_alarming_on_radio[net_id] = nil
    SetBlipAlerted(net_id, false)

    RunForPlayersInside(function(src)
        TriggerClientEvent('human_labs_raid:client:suspicious:inform_spotted', src, false, net_id)
    end)
end)
