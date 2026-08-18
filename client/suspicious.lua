local nui_ready = false
local panel_is_shown = false
local suspicion_loop_active = false

local is_in_restricted_perimeter = false
local is_behaving_suspicious = false
local is_suspicious = false
local spottable = false
local is_spotted = false
local is_in_alarm = false
local is_in_lab = false
local raid_disabled_for_s = 0

local suspicion_text = ""
local suspicion_timer = 0
local spotted_trigger_time = 4000
local spotted_progress = {}
local paused_spotteds = {}
local alarm_trigger_time = 10000


local function get_time()
    local years, months, days, hours, minutes, seconds = GetLocalTime()
    return 31557600*years + 2629800*months + 86400*days + 3600*hours + 60*minutes + seconds
end

local function show_panel()
    if panel_is_shown then return end
    panel_is_shown = true

    SendNUIMessage({ action = 'show_suspicion_panel' })
end

local function update_suspicious_level()
    local suspicion_level
    local suspicion_text_inner = ""
    local suspicion_amount = 0
    if is_in_alarm then
        suspicion_level = 4
    elseif is_spotted
    and not StayNonHostile
    and not Config.security.player_ignored_by_security(PlayerPedId()) then
        suspicion_level = 3
        for _, value in pairs(spotted_progress) do
            if suspicion_amount < value / alarm_trigger_time then
                suspicion_amount = value / alarm_trigger_time
            end
        end
    elseif (is_behaving_suspicious or is_suspicious or is_in_lab)
    and is_in_restricted_perimeter
    and not StayNonHostile
    and not Config.security.player_ignored_by_security(PlayerPedId()) then
        suspicion_level = 2
        suspicion_text_inner = suspicion_text
        suspicion_amount = suspicion_timer / spotted_trigger_time
    elseif is_in_restricted_perimeter or Config.security.player_ignored_by_security(PlayerPedId()) then
        suspicion_level = 1
    else
        suspicion_level = 0
    end

    if get_time() < raid_disabled_for_s then
        local total_minutes = math.floor((raid_disabled_for_s % 86400) / 60)
        local hours = math.floor(total_minutes / 60)
        local minutes = total_minutes % 60

        suspicion_text_inner = string.format(Locale.suspicion.disabled_until, hours, minutes)
    end

    SendNUIMessage({
        action = 'suspicion_level',
        suspicion_level = suspicion_level,
        suspicion_amount = suspicion_amount,
        suspicion_text = suspicion_text_inner
    })
end

local function ensure_suspicion_loop()
    if suspicion_loop_active then return end
    suspicion_loop_active = true

    CreateThread(function()
        local ped = PlayerPedId()

        while Active do
            Wait(150)

            if not is_suspicious then
                if IsPedShooting(ped) then
                    is_behaving_suspicious = true
                    suspicion_text = Locale.suspicion.suspicious_shooting
                elseif IsPedDoingDriveby(ped) then
                    is_behaving_suspicious = true
                    suspicion_text = Locale.suspicion.suspicious_driveby
                elseif IsPedReloading(ped) then
                    is_behaving_suspicious = true
                    suspicion_text = Locale.suspicion.suspicious_reloading
                elseif IsPlayerFreeAiming(PlayerId()) then
                    is_behaving_suspicious = true
                    suspicion_text = Locale.suspicion.suspicious_aiming
                elseif IsPedArmed(ped, 7) then
                    is_behaving_suspicious = true
                    suspicion_text = Locale.suspicion.suspicious_weapon_drawn
                elseif IsPedInMeleeCombat(ped) then
                    is_behaving_suspicious = true
                    suspicion_text = Locale.suspicion.suspicious_melee
                elseif IsPedGoingIntoCover(ped) then
                    is_behaving_suspicious = true
                    suspicion_text = Locale.suspicion.suspicious_cover
                elseif GetPedStealthMovement(ped) or IsPedDucking(ped) or GetPedMovementClipset(ped) == GetHashKey("move_ped_crouched") then
                    is_behaving_suspicious = true
                    suspicion_text = Locale.suspicion.suspicious_sneaking
                elseif IsPedVaulting(ped) or IsPedClimbing(ped) or IsPedSprinting(ped) or IsPedRunning(ped) or IsPedJumping(ped) then
                    is_behaving_suspicious = true
                    suspicion_text = Locale.suspicion.suspicious_movement
                elseif IsPedInAnyVehicle(ped, false) then
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    if IsHornActive(vehicle) then
                        is_behaving_suspicious = true
                        suspicion_text = Locale.suspicion.suspicious_vehicle_honking
                    elseif GetEntitySpeed(vehicle) * 3.6 > 50.0 then
                        is_behaving_suspicious = true
                        suspicion_text = Locale.suspicion.suspicious_vehicle_speeding
                    else
                        is_behaving_suspicious = false
                    end
                else
                    is_behaving_suspicious = false
                end
            end

            if suspicion_timer > 0 then
                local old_is_behaving_suspicious = is_behaving_suspicious
                is_behaving_suspicious = true -- sketchy but only here modified so okay
                update_suspicious_level()
                is_behaving_suspicious = old_is_behaving_suspicious
            else
                update_suspicious_level()
            end

            if is_in_restricted_perimeter and is_suspicious then
                suspicion_timer = suspicion_timer + 80 -- slower build up
            elseif is_in_restricted_perimeter and is_behaving_suspicious then
                suspicion_timer = suspicion_timer + 150
            elseif not is_in_lab then
                suspicion_timer = suspicion_timer - 150
            end
            if suspicion_timer > spotted_trigger_time then suspicion_timer = spotted_trigger_time end
            if suspicion_timer < 0 then suspicion_timer = 0 end

            for key, value in pairs(spotted_progress) do
                local is_paused = false
                for id, _ in pairs(paused_spotteds) do
                    if key == id then
                        is_paused = true
                        break
                    end
                end

                if not is_paused then
                    if is_spotted then
                        spotted_progress[key] = value + 150
                    else
                        spotted_progress[key] = value - 150
                    end
                    if spotted_progress[key] > alarm_trigger_time then spotted_progress[key] = alarm_trigger_time end
                    if spotted_progress[key] < 0 then spotted_progress[key] = 0 end
                end
            end

            if suspicion_timer >= spotted_trigger_time - 300 then
                if not spottable then
                    spottable = true
                    TriggerServerEvent('human_labs_raid:server:security:prohibited_lab_entry')
                end
            else
                spottable = false
            end
        end
        suspicion_loop_active = false
    end)
end

local function setup_panel()
    SendNUIMessage({
        action = 'setup_suspicion_level',
        data = {
            suspicion_titles = {
                Locale.suspicion.suspicion_title_0,
                Locale.suspicion.suspicion_title_1,
                Locale.suspicion.suspicion_title_2,
                Locale.suspicion.suspicion_title_3,
                Locale.suspicion.suspicion_title_4
            }
        }
    })
end

function SetupSuspicionPanel()
    while not nui_ready do Wait(100) end

    is_in_restricted_perimeter = false
    is_behaving_suspicious = false
    is_suspicious = false
    is_spotted = false
    is_in_alarm = false

    setup_panel()
    update_suspicious_level()
    ensure_suspicion_loop()
    show_panel()
end

function HideSuspicionPanel()
    if not panel_is_shown then return end
    panel_is_shown = false

    SendNUIMessage({ action = 'reset_suspicion_panel' })
end

RegisterNetEvent('human_labs_raid:client:suspicious:inform_perimeter_zone', function(new_state)
    is_in_restricted_perimeter = new_state
    update_suspicious_level()
end)

RegisterNetEvent('human_labs_raid:client:suspicious:inform_suspicious', function(new_state, text)
    is_suspicious = new_state
    suspicion_text = text
    update_suspicious_level()
end)

RegisterNetEvent('human_labs_raid:client:suspicious:inform_suspicious_instant', function(new_state, text, factor)
    is_suspicious = new_state
    suspicion_text = text

    local add_time = factor * spotted_trigger_time
    suspicion_timer = suspicion_timer + add_time
    if suspicion_timer > spotted_trigger_time then suspicion_timer = spotted_trigger_time end

    update_suspicious_level()
end)

RegisterNetEvent('human_labs_raid:client:suspicious:inform_suspicious_lab', function(new_state, text)
    is_in_lab = new_state
    suspicion_text = text

    if new_state then
        suspicion_timer = spotted_trigger_time
    else
        local sub_time = 0.5 * spotted_trigger_time
        suspicion_timer = suspicion_timer - sub_time
        if suspicion_timer < 0 then suspicion_timer = 0 end
    end

    update_suspicious_level()
end)

RegisterNetEvent('human_labs_raid:client:suspicious:inform_spotted', function(new_state, id)
    if new_state then
        spotted_progress[id] = 0
        is_spotted = true
    else
        spotted_progress[id] = nil
        paused_spotteds[id] = nil
        if next(spotted_progress) == nil then
            is_spotted = false
        end
    end

    update_suspicious_level()
end)

RegisterNetEvent('human_labs_raid:client:suspicious:inform_spotted_pause', function(id)
    paused_spotteds[id] = true
end)
RegisterNetEvent('human_labs_raid:client:suspicious:inform_spotted_resume', function(id)
    paused_spotteds[id] = nil
end)

RegisterNetEvent('human_labs_raid:client:suspicious:inform_alarm', function(new_state)
    is_in_alarm = new_state
    update_suspicious_level()
end)

RegisterNetEvent('human_labs_raid:client:suspicious:inform_raid_disabled', function(time_ms)
    raid_disabled_for_s = get_time() + time_ms / 1000
    update_suspicious_level()
end)


RegisterNUICallback('nui_ready', function(_data, cb)
    nui_ready = true
    cb({})
end)
