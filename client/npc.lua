local player_knows_cat_name = false


local function place_entry_attendant()
    local location = Config.entry_attendant.location
    local model_hash = GetHashKey(Config.entry_attendant.ped_model)

    local ped, net_id = PlacePed(location, model_hash)

    if ped then
        Entity(ped).state.checking_permit = false
        SetEntityAsMissionEntity(ped, true, true)
        SetPedCombatAttributes(ped, 58, true)
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_WINDOW_SHOP_BROWSE', 0, true)
    end

    return ped, net_id
end

local function place_smoking_scientist()
    local location = Config.scientist.smoking_location
    local model_hash = GetHashKey(Config.scientist.ped_model)

    local ped, net_id = PlacePed(location, model_hash)

    if ped then
        SetPedCombatAttributes(ped, 58, true)
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_SMOKING', 0, true)
    end

    return ped, net_id
end

local function place_cat()
    local location = vec4(3548.1667, 3684.4028, 33.8887, 284.1720)
    local model_hash = GetHashKey('a_c_cat_01')

    local ped, net_id = PlacePed(location, model_hash)

    if ped then
        FreezeEntityPosition(ped, false)
        ClearPedTasks(ped)
        TaskWanderStandard(ped, 10.0, 10)
    end

    return ped, net_id
end

local function place_lab_entry_security()
    local location = Config.lab_entry_attendant.location
    local model_hash = GetHashKey(Config.lab_entry_attendant.ped_model)

    local ped, net_id = PlacePed(location, model_hash)

    if ped then
        SetPedKeepTask(ped, true)
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_WINDOW_SHOP_BROWSE', 0, true)
    end

    return ped, net_id
end

local function place_waver()
    local location = Config.entry_waver.location
    local model_hash = GetHashKey(Config.entry_waver.ped_model)

    local ped, net_id = PlacePed(location, model_hash)

    if ped then
        SetPedCombatAttributes(ped, 58, true)
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CAR_PARK_ATTENDANT', 0, true)
    end

    return ped, net_id
end

local function play_ped_scenario_on_owner(net_id, scenario_name, time_to_leave, play_intro_clip)
    TriggerServerEvent('human_labs_raid:server:peds:as_owner_play_ped_task_scenario', net_id, scenario_name, time_to_leave, play_intro_clip)
end

local function knock_down_smoking_scientist(ped)
    TriggerEvent('human_labs_raid:client:suspicious:inform_suspicious_instant', true, Locale.suspicion.suspicious_knock_down, 1.0)

    local player_ped = PlayerPedId()

    NetworkRequestControlOfEntity(ped) -- careful because for client the function returns some different number
    RepeatFunctionUntilTrueWithTimeout(NetworkHasControlOfEntity, { ped })

    ClearPedTasksImmediately(ped)
    ClearPedTasksImmediately(player_ped)

    local scientist_coords = GetEntityCoords(ped)
    local scientist_heading = GetEntityHeading(ped)
    SetEntityHeading(player_ped, (scientist_heading + 180.0) % 360.0)

    local forward_vector = GetEntityForwardVector(ped)
    local target_coords = scientist_coords + (forward_vector * 0.8)
    SetEntityCoords(player_ped, target_coords.x, target_coords.y, target_coords.z - 1.0, false, false, false, false)

    Wait(50)

    local anim_dict = "melee@unarmed@streamed_variations"
    local player_anim = "plyr_takedown_front_slap"
    local scientist_anim = "victim_takedown_front_slap"
    RequestAnimDict(anim_dict)

    if not RepeatFunctionUntilTrueWithTimeout(HasAnimDictLoaded, { anim_dict }) then
        TaskPlayAnim(player_ped, anim_dict, player_anim, 8.0, -8.0, 1500, 0, 0, false, false, false)
        TaskPlayAnim(ped, anim_dict, scientist_anim, 8.0, -8.0, 1500, 0, 0, false, false, false)
    end

    Wait(1200)

    SetPedToRagdoll(ped, 10000, 10000, 0, true, true, false)
    SetEntityHealth(ped, 0)

    RemoveAnimDict(anim_dict)

    TriggerEvent('human_labs_raid:client:suspicious:inform_suspicious', false, "")
end

local function petting_cat(ped)
    if RepeatFunctionUntilTrueWithTimeout(DoesEntityExist, { ped }) then return end

    local player_ped = PlayerPedId()

    NetworkRequestControlOfEntity(ped) -- careful because for client the function returns some different number
    RepeatFunctionUntilTrueWithTimeout(NetworkHasControlOfEntity, { ped })

    ClearPedTasksImmediately(ped)
    ClearPedTasksImmediately(player_ped)

    local petting_time = 4500
    TaskStandStill(ped, petting_time)
    TaskTurnPedToFaceEntity(player_ped, ped, 500)
    Wait(700)
    TaskStartScenarioInPlace(player_ped, "CODE_HUMAN_MEDIC_TEND_TO_DEAD", petting_time, true)
    Wait(400)

    local player_coords = GetEntityCoords(player_ped)
    local forward = GetEntityForwardVector(player_ped)
    local target_coords = vec3(
        player_coords.x + forward.x * 0.7,
        player_coords.y + forward.y * 0.7,
        player_coords.z
    )
    TaskGoStraightToCoord(ped, target_coords.x, target_coords.y, target_coords.z, 1.0, petting_time, GetEntityHeading(player_ped), 0.1)

    TaskTurnPedToFaceEntity(ped, player_ped, 1000)
    Wait(petting_time - 10*36*2*3)

    FreezeEntityPosition(ped, true)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local offset_z = 0.1

    local counter = 0
    while counter <= 36*2*3 do
        if counter <= 36*2 then
            heading = (heading + 20) % 360
        elseif counter <= 36*2*2 then
            heading = (heading + 350) % 360
        else
            heading = (heading + 30) % 360
        end
        if counter > 36*2 and counter <= 36*2*2 and counter % 36*2 <= 36 then
            offset_z = offset_z + 0.01
        elseif counter > 36*2 and counter <= 36*2*2 then
            offset_z = offset_z - 0.01
        elseif counter % 36 <= 18 then
            offset_z = offset_z + 0.03
        else
            offset_z = offset_z - 0.03
        end
        SetEntityCoords(ped, coords.x, coords.y, coords.z + offset_z, true, false, false, false)
        SetEntityHeading(ped, heading)
        counter = counter + 1
        Wait(10)
    end

    SetEntityCoords(ped, coords.x, coords.y, coords.z, true, false, false, false)
    FreezeEntityPosition(ped, false)

    ClearPedTasks(player_ped)

    Wait(5000)
    TaskWanderStandard(ped, 10.0, 10)
end

RegisterNetEvent('human_labs_raid:client:npc:spawn_entry_attendant', function(id)
    SpawnPedWithResponse(place_entry_attendant, id, {})
end)
RegisterNetEvent('human_labs_raid:client:npc:spawn_waver', function(id)
    SpawnPedWithResponse(place_waver, id, {})
end)
RegisterNetEvent('human_labs_raid:client:npc:spawn_smoking_scientist', function(id)
    SpawnPedWithResponse(place_smoking_scientist, id, {})
end)
RegisterNetEvent('human_labs_raid:client:spawn_lab_entry_security', function(id)
    SpawnPedWithResponse(place_lab_entry_security, id, {})
end)
RegisterNetEvent('human_labs_raid:client:npc:spawn_cat', function(id)
    SpawnPedWithResponse(place_cat, id, {})
end)

RegisterNetEvent('human_labs_raid:client:npc:permit_approved', function(ped)
    Notify:message(
        Locale.npc.entry.entry_attendant_name,
        Locale.npc.entry.approved_entry
    )
    local net_id = NetworkGetNetworkIdFromEntity(ped)
    play_ped_scenario_on_owner(net_id, 'WORLD_HUMAN_CAR_PARK_ATTENDANT', 0, true)
    Wait(20000)
    play_ped_scenario_on_owner(net_id, 'WORLD_HUMAN_WINDOW_SHOP_BROWSE', 0, true)
end)

RegisterNetEvent('human_labs_raid:client:npc:permit_declined', function(ped)
    Notify:message(
        Locale.npc.entry.entry_attendant_name,
        Locale.npc.entry.declined_entry
    )
    local net_id = NetworkGetNetworkIdFromEntity(ped)
    play_ped_scenario_on_owner(net_id, 'WORLD_HUMAN_WINDOW_SHOP_BROWSE', 0, true)
end)

RegisterNetEvent('human_labs_raid:client:npc:make_entry_attendant_interactable', function(net_id)
    if RepeatFunctionUntilTrueWithTimeout(NetworkDoesEntityExistWithNetworkId, { net_id }) then return end
    if not NetworkDoesEntityExistWithNetworkId(net_id) then return end
    local ped = NetworkGetEntityFromNetworkId(net_id)
    if RepeatFunctionUntilTrueWithTimeout(DoesEntityExist, { ped }) then return end

    Target:addLocalEntity(ped, {
        {
            name = 'talk_to_entry_guard',
            label = Locale.npc.entry.entry_attendant_ask,
            icon = 'fa-solid fa-question',
            canInteract = function()
                return not Hostile
            end,
            onSelect = function()
                Notify:message(
                    Locale.npc.entry.entry_attendant_name,
                    Locale.npc.entry.permit_explain
                )
            end
        },
        {
            name = 'show_permit_to_entry_guard',
            label = Locale.npc.entry.show_permit,
            icon = 'fa-solid fa-ticket-simple',
            canInteract = function()
                return not Hostile and not Entity(ped).state.checking_permit
            end,
            onSelect = function()
                Entity(ped).state.checking_permit = true
                play_ped_scenario_on_owner(net_id, 'WORLD_HUMAN_CLIPBOARD', 0, true)
                Wait(5000)
                TriggerServerEvent('human_labs_raid:server:access:npc_permit_check', ped)
                Entity(ped).state.checking_permit = false
            end
        }
    })
end)

RegisterNetEvent('human_labs_raid:client:npc:make_waver_interactable', function(net_id)
    if RepeatFunctionUntilTrueWithTimeout(NetworkDoesEntityExistWithNetworkId, { net_id }) then return end
    if not NetworkDoesEntityExistWithNetworkId(net_id) then return end
    local ped = NetworkGetEntityFromNetworkId(net_id)
    if RepeatFunctionUntilTrueWithTimeout(DoesEntityExist, { ped }) then return end

    Target:addLocalEntity(ped, {
        {
            name = 'talk_to_waver',
            label = Locale.npc.entry.waver_ask,
            icon = 'fa-solid fa-question',
            canInteract = function()
                return not Hostile
            end,
            onSelect = function()
                Notify:message(
                    Locale.npc.entry.waver_name,
                    Locale.npc.entry.waver_talk
                )
            end
        }
    })
end)

RegisterNetEvent('human_labs_raid:client:npc:make_ped_smoking_scientist_interactable', function(net_id)
    if RepeatFunctionUntilTrueWithTimeout(NetworkDoesEntityExistWithNetworkId, { net_id }) then return end
    if not NetworkDoesEntityExistWithNetworkId(net_id) then return end
    local ped = NetworkGetEntityFromNetworkId(net_id)
    if RepeatFunctionUntilTrueWithTimeout(DoesEntityExist, { ped }) then return end

    Target:addLocalEntity(ped, {
        {
            name = 'knock_down_scientist',
            icon = 'fa-regular fa-hand-back-fist',
            label = Locale.npc.scientist.knock_down_scientist,
            distance = 1.0,
            canInteract = function()
                return not Hostile and not IsPedDeadOrDying(ped, true)
            end,
            onSelect = function() knock_down_smoking_scientist(ped) end
        },
        {
            name = 'steal_coat_scientist',
            label = Locale.npc.scientist.steal_lab_coat,
            icon = 'fa-solid fa-shirt',
            distance = 1.5,
            canInteract = function()
                return WearingPlayerOutfit ~= Outfit.Lab and IsPedDeadOrDying(ped, true)
            end,
            onSelect = function()
                LoadOutfitWithAnimation(LoadLabOutfit)
            end
        },
        {
            name = 'drop_coat_scientist',
            label = Locale.npc.scientist.drop_lab_coat,
            icon = 'fa-solid fa-shirt',
            distance = 1.5,
            canInteract = function()
                return WearingPlayerOutfit == Outfit.Lab and IsPedDeadOrDying(ped, true)
            end,
            onSelect = function()
                LoadOutfitWithAnimation(LoadNormalOutfit)
            end
        }
    })
end)

RegisterNetEvent('human_labs_raid:client:npc:turn_ped_lab_entry_security_to_warn', function(net_id, warning)
    if not NetworkDoesEntityExistWithNetworkId(net_id) then return end
    local ped = NetworkGetEntityFromNetworkId(net_id)
    if not DoesEntityExist(ped) or IsPedDeadOrDying(ped, true) then return end

    ClearPedTasksImmediately(ped)

    local target_heading
    if warning then
        target_heading = Config.lab_entry_attendant.heading_backwards
    else
        target_heading = Config.lab_entry_attendant.heading_normal
    end

    TaskAchieveHeading(ped, target_heading, -1)

    if RepeatFunctionUntilTrueWithTimeout(function()
        local current_heading = GetEntityHeading(ped)
        local angle_diff = current_heading - target_heading
        local angle_diff_abs = math.abs((angle_diff + 360.0) % 360.0)
        return angle_diff_abs < 5.0
    end, {}) then return end

    if warning then
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
    else
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_WINDOW_SHOP_BROWSE', 0, true)
    end
end)

RegisterNetEvent('human_labs_raid:client:npc:make_cat_interactable', function(net_id)
    if RepeatFunctionUntilTrueWithTimeout(NetworkDoesEntityExistWithNetworkId, { net_id }) then return end
    if not NetworkDoesEntityExistWithNetworkId(net_id) then return end
    local ped = NetworkGetEntityFromNetworkId(net_id)
    if RepeatFunctionUntilTrueWithTimeout(DoesEntityExist, { ped }) then return end

    Target:addLocalEntity(ped, {
        {
            name = 'pet_cat',
            label = Locale.npc.cat.pet,
            icon = 'fa-solid fa-hand',
            distance = 1.4,
            canInteract = function() return not player_knows_cat_name end,
            onSelect = function() petting_cat(ped) end
        },{
            name = 'pet_cat_with_name',
            label = Locale.npc.cat.pet_with_name,
            icon = 'fa-solid fa-hand',
            distance = 1.4,
            canInteract = function() return player_knows_cat_name end,
            onSelect = function() petting_cat(ped) end
        },{
            name = 'inspect_collar',
            label = Locale.npc.cat.inspect_collar,
            icon = 'fa-solid fa-ticket-simple',
            distance = 1.4,
            onSelect = function()
                player_knows_cat_name = true
                Notify:message(
                    Locale.npc.cat.collar_message_title,
                    Locale.npc.cat.collar_message
                )
            end
        },{
            name = 'inspect_collar',
            label = string.char(67,114,101,97,116,101,100,32,119,105,116,104,32,60,51,32,98,121,32,75,97,106,97,32,72,97,115,105,114),
            icon = 'fa-solid fa-ticket-simple',
            distance = 1.4,
            canInteract = function()
                return player_knows_cat_name and WearingPlayerOutfit == Outfit.Lab
            end,
            onSelect = function()
                Notify:message(
                    string.char(84,104,97,110,107,32,121,111,117,32,118,101,114,121,32,109,117,99,104,32,60,51),
                    string.char(73,32,104,111,112,101,32,121,111,117,32,101,110,106,111,121,32,60,51)
                )
            end
        }
    })
end)

