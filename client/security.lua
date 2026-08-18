Hostile = false
StayNonHostile = false

AddRelationshipGroup("LAB_GUARDS")
AddRelationshipGroup("REGULAR_PLAYER")
AddRelationshipGroup("IGNORED_PLAYER")

local function make_scientist_patrolling(ped, net_id, all_players)
    local end_location = Config.scientist.patrolling.end_location

    CreateThread(function() -- Terminates on ped removal
        local total_timer = 0
        local close_timer = 0
        local still_timer = 0
        local delete_anyways_time = Config.scientist.patrolling.delete_anyway_time

        local is_paused = true
        local first_player_spotted = nil
        local players_spotted = {}
        for src in pairs(all_players) do
            players_spotted[src] = 0
        end

        while DoesEntityExist(ped) and not IsPedDeadOrDying(ped, true) and not StayNonHostile do
            Wait(100)

            total_timer = total_timer + 100
            if not is_paused then
                close_timer = close_timer + 100
            end

            local arrived = #(GetEntityCoords(ped) - vector3(end_location.x, end_location.y, end_location.z)) < 2.0
            if (arrived and close_timer >= 3000)
            or total_timer > delete_anyways_time then
                TriggerServerEvent('human_labs_raid:server:security:remove_patrolling_scientist', net_id)
            elseif not arrived then
                close_timer = 0
            end

            local any_spotted = false
            for src in pairs(all_players) do
                if not Config.security.player_ignored_by_security(PlayerPedId()) then
                    local player_ped = GetPlayerPed(GetPlayerFromServerId(src))
                    if player_ped and player_ped ~= 0 and not Entity(player_ped).state.is_in_lab_zone then
                        local is_increasing = false
                        local is_decreasing = false

                        local dist = #(GetEntityCoords(ped) - GetEntityCoords(player_ped))
                        if dist <= 8.0
                        and HasEntityClearLosToEntity(ped, player_ped, 17)
                        and IsPedFacingPed(ped, player_ped, 60.0) then
                            players_spotted[src] = players_spotted[src] + 1
                            if players_spotted[src] > 5 then
                                players_spotted[src] = 5
                            else
                                is_increasing = true
                            end
                        else
                            players_spotted[src] = players_spotted[src] - 1
                            if players_spotted[src] < 0 then
                                players_spotted[src] = 0
                            else
                                is_decreasing = true
                            end
                        end

                        if is_increasing and players_spotted[src] == 5 then
                            TriggerServerEvent('human_labs_raid:server:inform_client_suspicous_panel_suspicious_instant', src, true, Locale.suspicion.spotted_by_scientist, 0.3)
                            if not first_player_spotted then
                                first_player_spotted = player_ped
                            end
                        elseif is_decreasing and players_spotted[src] == 0 then
                            TriggerServerEvent('human_labs_raid:server:inform_client_suspicous_panel_suspicious_instant', src, false, "", 0.0)
                        end

                        if players_spotted[src] > 0 then
                            any_spotted = true
                        end
                    end
                end

                if any_spotted and not is_paused then
                    is_paused = true
                    still_timer = 0
                    TaskStandStill(ped, -1)
                    TaskStartScenarioInPlace(ped, "CODE_HUMAN_POLICE_INVESTIGATE", 0, true)
                elseif any_spotted
                and is_paused
                and first_player_spotted
                and DoesEntityExist(first_player_spotted) then
                    local ped_coords    = GetEntityCoords(ped)
                    local target_coords = GetEntityCoords(first_player_spotted)
                    local dx = target_coords.x - ped_coords.x
                    local dy = target_coords.y - ped_coords.y

                    local target_heading = (math.deg(math.atan(-dx, dy)) + 360) % 360
                    local ped_heading = GetEntityHeading(ped)
                    local diff = math.abs(((target_heading - ped_heading + 540) % 360) - 180)

                    if diff > 40.0 then
                        TaskTurnPedToFaceEntity(ped, first_player_spotted, 5000)
                    end
                elseif not any_spotted and is_paused and still_timer > 2500 then
                    is_paused = false
                    first_player_spotted = nil
                    TaskFollowNavMeshToCoord(ped, end_location.x, end_location.y, end_location.z, 1.0, -1, 0.5, 0, 0.0)
                elseif not any_spotted and is_paused then
                    still_timer = still_timer + 100
                end
            end
        end
    end)
end

local function place_combat_ped(location, model_hash)
    local ped, net_id = PlacePed(location, model_hash)
    if ped == nil then return end

    Entity(ped).state.is_combat_ped = true

    SetPedSeeingRange(ped, 40.0)
    SetPedVisualFieldMinAngle(ped, -60.0)
    SetPedVisualFieldMaxAngle(ped, 60.0)
    SetPedVisualFieldMinElevationAngle(ped, -40.0)
    SetPedVisualFieldMaxElevationAngle(ped, 40.0)
    SetPedVisualFieldPeripheralRange(ped, 20.0)
    SetPedHearingRange(ped, 30.0)

    GiveWeaponToPed(ped, Config.security.weapon, 250, true, false)
    SetPedAccuracy(ped, Config.security.accuracy)
    SetPedCombatAbility(ped, 1)
    SetPedKeepTask(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)  -- can investigate
    SetPedCombatAttributes(ped, 52, true)  -- will investigate

    SetPedRelationshipGroupHash(ped, 'LAB_GUARDS')

    return ped, net_id
end

local function place_guard_stationary(location)
    local model_hash = GetHashKey(Config.security.ped_model)
    local ped, net_id = place_combat_ped(location, model_hash)
    if ped == nil then return end

    SetPedCombatMovement(ped, 2) -- offensive
    SetPedCombatRange(ped, 1)
    SetPedAlertness(ped, 3) -- 3 is full alert

    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_GUARD_STAND', 0, true)

    return ped, net_id
end

local function place_guard_patrolling(location)
    local model_hash = GetHashKey(Config.security.ped_model)
    local ped, net_id = place_combat_ped(location, model_hash)
    if ped == nil then return end

    SetPedCombatMovement(ped, 2) -- offensive
    SetPedCombatRange(ped, 1)
    SetPedAlertness(ped, 1) -- 3 is full alert
    SetPedCombatAttributes(ped, 0, true) -- use cover

    TaskGuardCurrentPosition(ped, 35.0, 35.0, true)

    return ped, net_id
end

local function place_raider(location)
    local model_hash = GetHashKey(Config.security.ped_model)
    local ped, net_id = place_combat_ped(location, model_hash)
    if ped == nil then return end

    SetPedCombatMovement(ped, 3)
    SetPedCombatRange(ped, 0)
    SetPedAlertness(ped, 3)
    SetPedCombatAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 13, true) -- aggressive

    local lab_pos = Config.crafting.locations.gas_containers
    TaskFollowNavMeshToCoord(ped, lab_pos.x, lab_pos.y, lab_pos.z, 3.0, -1, 1.0, 0, 0.0)

    return ped, net_id
end

local function placing_patrolling_scientist(all_players)
    local start_location = Config.scientist.patrolling.start_location
    local model_hash = GetHashKey(Config.scientist.ped_model)

    local ped, net_id = PlacePed(start_location, model_hash)
    if ped == nil then return end

    Entity(ped).state.is_combat_ped = true
    SetPedCombatAttributes(ped, 58, true)
    TaskStandStill(ped, -1)

    SetPedSeeingRange(ped, 8.0)
    SetPedVisualFieldMinAngle(ped, -45.0)
    SetPedVisualFieldMaxAngle(ped, 45.0)
    SetPedVisualFieldMinElevationAngle(ped, -30.0)
    SetPedVisualFieldMaxElevationAngle(ped, 30.0)
    SetPedVisualFieldPeripheralRange(ped, 15.0)
    SetPedHearingRange(ped, 8.0)

    make_scientist_patrolling(ped, net_id, all_players)

    return ped, net_id
end

function SetupSecurity()
    Hostile = false
    StayNonHostile = false
    if Config.security.player_ignored_by_security(PlayerPedId()) then
        SetPedRelationshipGroupHash(PlayerPedId(), 'IGNORED_PLAYER')
    else
        SetPedRelationshipGroupHash(PlayerPedId(), 'REGULAR_PLAYER')
    end

    SetRelationshipBetweenGroups(2, 'LAB_GUARDS', 'REGULAR_PLAYER')
    SetRelationshipBetweenGroups(2, 'REGULAR_PLAYER', 'LAB_GUARDS')

    SetRelationshipBetweenGroups(0, 'LAB_GUARDS', 'IGNORED_PLAYER')
    SetRelationshipBetweenGroups(0, 'IGNORED_PLAYER', 'LAB_GUARDS')
end

function CleanupSecurity()
    Hostile = false
    StayNonHostile = false
    SetRelationshipBetweenGroups(2, 'LAB_GUARDS', 'REGULAR_PLAYER')
    SetRelationshipBetweenGroups(2, 'REGULAR_PLAYER', 'LAB_GUARDS')
end

RegisterNetEvent('human_labs_raid:client:security:spawn_patrolling_scientist', function(id, all_players)
    SpawnPedWithResponse(placing_patrolling_scientist, id, { all_players })
end)
RegisterNetEvent('human_labs_raid:client:security:spawn_guard_stationary', function(id, spawn_loc)
    SpawnPedWithResponse(place_guard_stationary, id, { spawn_loc })
end)
RegisterNetEvent('human_labs_raid:client:security:spawn_guard_patrolling', function(id, spawn_loc)
    SpawnPedWithResponse(place_guard_patrolling, id, { spawn_loc })
end)
RegisterNetEvent('human_labs_raid:client:security:spawn_raider', function(id, spawn_loc)
    SpawnPedWithResponse(place_raider, id, { spawn_loc })
end)

RegisterNetEvent('human_labs_raid:client:security:set_area_hostile', function()
    Hostile = true
    if not Config.debug_enemies and not StayNonHostile then
        SetRelationshipBetweenGroups(5, 'LAB_GUARDS', 'REGULAR_PLAYER')
        SetRelationshipBetweenGroups(5, 'REGULAR_PLAYER', 'LAB_GUARDS')
    end
end)
RegisterNetEvent('human_labs_raid:client:security:set_area_stay_non_hostile', function()
    Hostile = false
    StayNonHostile = true
    SetRelationshipBetweenGroups(2, 'LAB_GUARDS', 'REGULAR_PLAYER')
    SetRelationshipBetweenGroups(2, 'REGULAR_PLAYER', 'LAB_GUARDS')
end)

RegisterNetEvent('human_labs_raid:client:security:ped_alerts_on_radio', function(net_id)
    if not NetworkDoesEntityExistWithNetworkId(net_id) then return end
    local ped = NetworkGetEntityFromNetworkId(net_id)
    if DoesEntityExist(ped) then
        local anim_dict = "random@arrests"
        local anim_name = "radio_chatter"

        RequestAnimDict(anim_dict)
        if RepeatFunctionUntilTrueWithTimeout(HasAnimDictLoaded, { anim_dict }) then return end

        local time_required_for_alarming = 10000
        local elapsed = 0
        local is_ragdoll = false
        while elapsed < time_required_for_alarming and DoesEntityExist(ped) and not IsPedDeadOrDying(ped, true) do
            while is_ragdoll and IsPedRagdoll(ped) do
                Wait(100)
            end

            if is_ragdoll then
                is_ragdoll = false
                Wait(2500)
                TriggerServerEvent('human_labs_raid:server:security:ped_alerts_on_radio_resume', net_id)
            end

            if HasAnimDictLoaded(anim_dict) then
                TaskPlayAnim(ped, anim_dict, anim_name, 8.0, -8.0, -1, 49, 0, false, false, false)
            end

            while elapsed < time_required_for_alarming do
                Wait(100)
                elapsed = elapsed + 100

                if not DoesEntityExist(ped) or IsPedDeadOrDying(ped, true) or IsPedRagdoll(ped) then
                    is_ragdoll = true
                    TriggerServerEvent('human_labs_raid:server:security:ped_alerts_on_radio_pause', net_id)
                    break
                end
            end
        end

        if DoesEntityExist(ped) then
            ClearPedSecondaryTask(ped)
        end
        RemoveAnimDict(anim_dict)

        if elapsed >= time_required_for_alarming then
            TriggerServerEvent('human_labs_raid:server:security:ped_alerts_on_radio_success', net_id)
        else
            TriggerServerEvent('human_labs_raid:server:security:ped_alerts_on_radio_failed', net_id)
        end
    end
end)

RegisterNetEvent('human_labs_raid:client:security:check_prohibited_entry_los', function(spawned_peds)
    local player_ped = PlayerPedId()

    for net_id, _ in pairs(spawned_peds) do
        if NetworkDoesEntityExistWithNetworkId(net_id) then
            local ped = NetworkGetEntityFromNetworkId(net_id)

            if DoesEntityExist(ped)
            and Entity(ped).state.is_combat_ped
            and not IsPedDeadOrDying(ped, true)
            and HasEntityClearLosToEntity(ped, player_ped, 17)
            and IsPedFacingPed(ped, player_ped, 90.0)
            and not StayNonHostile
            and not Config.security.player_ignored_by_security(player_ped) then
                TriggerServerEvent('human_labs_raid:server:security:ped_alerts_on_radio', net_id)
            end
        end
    end
end)

RegisterNetEvent('human_labs_raid:client:security:check_ped_states', function(all_players, spawned_peds)
    if StayNonHostile then return end

    for net_id, _ in pairs(spawned_peds) do
        if NetworkDoesEntityExistWithNetworkId(net_id) then
            local ped = NetworkGetEntityFromNetworkId(net_id)

            if DoesEntityExist(ped) and Entity(ped).state.is_combat_ped then
                local is_in_combat = false
                for src in pairs(all_players) do
                    if IsPedInCombat(ped, src) and not Config.security.player_ignored_by_security(src) then
                        is_in_combat = true
                        break
                    end
                end
                if is_in_combat then
                    TriggerServerEvent('human_labs_raid:server:security:ped_alerts_on_radio', net_id)
                end
            end
        end
    end
end)
