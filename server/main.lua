local raid_disabled_thread_active = false

RaidDisabled = false

local function spawn_barricates_when_ready()
    CreateThread(function()
        while RaidDisabled do
            Wait(500)
            if CountPlayersInside() == 0 then
                break
            end
        end
        while RaidDisabled do
            Wait(500)
            if GetActiveTransporters() == 0 then
                break
            end
        end
        if RaidDisabled then
            PlaceBarricatesNextTime()
        end
    end)
end

local function teleport_on_connect(client)
    local player_ped = GetPlayerPed(client)
    local coords = GetEntityCoords(player_ped)
    local global_zone_coords = Config.zones.global_zone_coords
    local global_zone_radius = Config.zones.global_zone_radius

    local should_teleport = false
    if Config.reconnect_teleport_outside
    and not Config.security.player_ignored_by_security(client)
    and #(coords - global_zone_coords) < global_zone_radius then
        should_teleport = true
    end
    TriggerClientEvent('human_labs_raid:client:teleport_outside', client, should_teleport)
end

function SetupClient(client)
    TriggerClientEvent('human_labs_raid:client:initiate', client)
    TriggerClientEvent('human_labs_raid:client:suspicious:inform_raid_disabled', client, Trigger:raid_disabled_message())

    if Hostile then
        TriggerClientEvent('human_labs_raid:client:security:set_area_hostile', client)
        TriggerClientEvent('human_labs_raid:client:suspicious:inform_alarm', client, true)
    end

    if RaidDisabled then
        TriggerClientEvent('human_labs_raid:client:crafting:change_extraction_possible', client, false)
    else
        TriggerClientEvent('human_labs_raid:client:crafting:change_extraction_possible', client, true)
        ScubaGearTakenClient(client)
        MakeNpcInterableClient(client)
        InitiateBlipsForPlayer(client)
    end
end
function CleanupClient(client)
    TriggerClientEvent('human_labs_raid:client:cleanup', client)
end

function StartServer()
    SpawnInitialEntities()
    PlaceAllScubaGear()
    PlaceBarricatesIfShould()
    EnsureSecurityLoop()
end
function CleanupServer()
    ClearNpcInteractions()
    RemoveBarricates()
    CleanupScubaGear()
    ResetCombatZone()
    RemoveAllPeds()
end

function EntityHasOwner(entity)
    if not DoesEntityExist(entity) then return false end
    local response = NetworkGetEntityOwner(entity)
    return response and response > 0
end

function IsPlayerStillConnected(source)
    return GetPlayerPed(source) ~= 0
end

local timeout_wait_time = Config.general_loading_wait_time_ms
function RepeatFunctionUntilTrueWithTimeout(func, args)
    local timeout = 0
    while not func(table.unpack(args)) do
        timeout = timeout + timeout_wait_time
        Wait(timeout_wait_time)
        if timeout > 5000 then
            return true
        end
    end
    return false
end

RegisterNetEvent('human_labs_raid:server:inform_client_suspicous_panel_suspicious_instant', function(target, ...)
    TriggerClientEvent('human_labs_raid:client:suspicious:inform_suspicious_instant', target, ...)
end)

RegisterNetEvent('human_labs_raid:server:notify_self', function(title, descirption)
    Notify:message(source, title, descirption)
end)

RegisterNetEvent('human_labs_raid:server:client_ready', function()
    MakeTransporterInteractableClient(source)
    teleport_on_connect(source)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if raid_disabled_thread_active then return end
    raid_disabled_thread_active = true

    while true do
        Wait(5000)

        RaidDisabled = Trigger:is_raid_disabled()
        if RaidDisabled then
            spawn_barricates_when_ready()

            while Trigger:is_raid_disabled() do Wait(5000) end
            RaidDisabled = Trigger:is_raid_disabled()
            RunForPlayersInside(function(src)
                CleanupClient(src)
                SetupClient(src)
            end)
            RemoveBarricatesNextTime()
            RemoveBarricates()
        end
    end
    raid_disabled_thread_active = false
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    CleanupServer()
    RemoveAllTransporters()
end)
