local teleport_done = false

Active = false

local function ensure_population_clear()
    CreateThread(function()
        while Active do
            Wait(0) -- Critical but required and toggleable
            SetPedDensityMultiplierThisFrame(0.0)
        end
    end)
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

local function init()
    StartLocalZones()
    StartCraftingAreas()
    StartScubaAreas()
    StartElevator()
    SetupSuspicionPanel()
    SetupOutfits()
    SetupSecurity()

    Active = true
    if Config.clear_population_every_frame then
        ensure_population_clear()
    end
end
local function cleanup()
    CleanupSecurity()
    LoadNormalOutfitGracefully()
    HideSuspicionPanel()
    StopCraftingAreas()
    StopScubaAreas()
    StopElevator()
    ClearLocalZones()
    RemovePedBlips()

    Active = false
end

local function teleport_outside()
    local outside_location = Config.reconnect_location
    StartPlayerTeleport(PlayerId(), outside_location.x, outside_location.y, outside_location.z, outside_location.w, false, true, false)

    local timeout = 0
    while IsPlayerTeleportActive() and timeout < 10000 do
        Wait(100)
        timeout = timeout + 100
    end
end

local function wait_for_teleport_response()
    while not teleport_done do Wait(50) end -- Rather client fails than spawning in zone
end

RegisterNetEvent('human_labs_raid:client:initiate', function()
    init()
end)
RegisterNetEvent('human_labs_raid:client:cleanup', function()
    cleanup()
end)

RegisterNetEvent('human_labs_raid:client:teleport_outside', function(should_teleport)
    if should_teleport then
        teleport_outside()
    end
    teleport_done = true
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    TriggerServerEvent('human_labs_raid:server:client_ready')
    wait_for_teleport_response()
    CreateGlobalBlip()
    StartGlobalZone()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    cleanup()
    LoadNormalOutfit()
end)
