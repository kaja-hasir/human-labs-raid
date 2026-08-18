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












-- Table to keep track of the peds spawned by this client
local spawnedPeds = {}

-- Define the outfits with explicit black hair and matched hair drawables
local outfits = {
    m = {
        hairColor = 0,
        components = { [0] = { texture = 0, drawable = 0, palette = 0 }, [1] = { texture = 0, drawable = 51, palette = 0 }, [2] = { texture = 0, drawable = 79, palette = 0 }, [3] = { texture = 0, drawable = 0, palette = 0 }, [4] = { texture = 7, drawable = 9, palette = 0 }, [5] = { texture = 0, drawable = 0, palette = 0 }, [6] = { texture = 0, drawable = 27, palette = 0 }, [7] = { texture = 0, drawable = 0, palette = 0 }, [8] = { texture = 0, drawable = 15, palette = 0 }, [9] = { texture = 0, drawable = 0, palette = 0 }, [10] = { texture = 0, drawable = 0, palette = 0 }, [11] = { texture = 0, drawable = 492, palette = 0 } },
        props = { [0] = { texture = -1, drawable = -1 }, [1] = { texture = -1, drawable = -1 }, [2] = { texture = -1, drawable = -1 }, [6] = { texture = -1, drawable = -1 }, [7] = { texture = -1, drawable = -1 } }
    },
    f = {
        hairColor = 0,
        components = { [0] = { texture = 0, drawable = 0, palette = 0 }, [1] = { texture = 0, drawable = 51, palette = 0 }, [2] = { texture = 0, drawable = 53, palette = 0 }, [3] = { texture = 0, drawable = 0, palette = 0 }, [4] = { texture = 0, drawable = 30, palette = 0 }, [5] = { texture = 0, drawable = 0, palette = 0 }, [6] = { texture = 0, drawable = 25, palette = 0 }, [7] = { texture = 0, drawable = 0, palette = 0 }, [8] = { texture = 0, drawable = 7, palette = 0 }, [9] = { texture = 0, drawable = 60, palette = 0 }, [10] = { texture = 0, drawable = 0, palette = 0 }, [11] = { texture = 0, drawable = 530, palette = 0 } },
        props = { [0] = { texture = -1, drawable = -1 }, [1] = { texture = -1, drawable = -1 }, [2] = { texture = -1, drawable = -1 }, [6] = { texture = -1, drawable = -1 }, [7] = { texture = -1, drawable = -1 } }
    },
    lab_m = {
        hairColor = 0,
        components = { [0] = { texture = 0, drawable = 0, palette = 0 }, [1] = { texture = 0, drawable = 0, palette = 2 }, [2] = { texture = 0, drawable = 79, palette = 0 }, [3] = { texture = 0, drawable = 4, palette = 2 }, [4] = { texture = 1, drawable = 0, palette = 2 }, [5] = { texture = 0, drawable = 0, palette = 2 }, [6] = { texture = 0, drawable = 32, palette = 2 }, [7] = { texture = 0, drawable = 128, palette = 0 }, [8] = { texture = 0, drawable = 15, palette = 2 }, [9] = { texture = 0, drawable = 0, palette = 0 }, [10] = { texture = 0, drawable = 0, palette = 2 }, [11] = { texture = 5, drawable = 349, palette = 2 } }, 
        props = { [0] = { texture = -1, drawable = -1 }, [1] = { texture = -1, drawable = -1 }, [2] = { texture = -1, drawable = -1 }, [6] = { texture = -1, drawable = -1 }, [7] = { texture = -1, drawable = -1 } }
    },
    lab_f = {
        hairColor = 0,
        components = { [0] = { texture = 0, drawable = 0, palette = 0 }, [1] = { texture = 0, drawable = 0, palette = 0 }, [2] = { texture = 0, drawable = 53, palette = 0 }, [3] = { texture = 0, drawable = 0, palette = 0 }, [4] = { texture = 0, drawable = 76, palette = 0 }, [5] = { texture = 0, drawable = 0, palette = 0 }, [6] = { texture = 0, drawable = 118, palette = 0 }, [7] = { texture = 0, drawable = 98, palette = 0 }, [8] = { texture = 0, drawable = 7, palette = 0 }, [9] = { texture = 0, drawable = 0, palette = 0 }, [10] = { texture = 0, drawable = 0, palette = 0 }, [11] = { texture = 0, drawable = 367, palette = 0 } }, 
        props = { [0] = { texture = -1, drawable = -1 }, [1] = { texture = -1, drawable = -1 }, [2] = { texture = -1, drawable = -1 }, [6] = { texture = -1, drawable = -1 }, [7] = { texture = -1, drawable = -1 } }
    },
    scuba_m = {
        hairColor = 0,
        components = { [0] = { texture = 0, drawable = 0, palette = 0 }, [1] = { texture = 0, drawable = 0, palette = 2 }, [2] = { texture = 0, drawable = 79, palette = 0 }, [3] = { texture = 0, drawable = 4, palette = 2 }, [4] = { texture = 0, drawable = 143, palette = 2 }, [5] = { texture = 0, drawable = 0, palette = 2 }, [6] = { texture = 0, drawable = 67, palette = 2 }, [7] = { texture = 0, drawable = 0, palette = 0 }, [8] = { texture = 0, drawable = 15, palette = 2 }, [9] = { texture = 0, drawable = 0, palette = 0 }, [10] = { texture = 0, drawable = 0, palette = 2 }, [11] = { texture = 0, drawable = 431, palette = 2 } }, 
        props = { [0] = { texture = -1, drawable = -1 }, [1] = { texture = -1, drawable = -1 }, [2] = { texture = -1, drawable = -1 }, [6] = { texture = -1, drawable = -1 }, [7] = { texture = -1, drawable = -1 } }
    },
    scuba_f = {
        hairColor = 0,
        components = { [0] = { texture = 0, drawable = 0, palette = 0 }, [1] = { texture = 0, drawable = 0, palette = 0 }, [2] = { texture = 0, drawable = 53, palette = 0 }, [3] = { texture = 0, drawable = 4, palette = 0 }, [4] = { texture = 8, drawable = 97, palette = 0 }, [5] = { texture = 0, drawable = 0, palette = 0 }, [6] = { texture = 0, drawable = 70, palette = 0 }, [7] = { texture = 0, drawable = 0, palette = 0 }, [8] = { texture = 0, drawable = 15, palette = 0 }, [9] = { texture = 0, drawable = 0, palette = 0 }, [10] = { texture = 0, drawable = 0, palette = 0 }, [11] = { texture = 0, drawable = 342, palette = 0 } }, 
        props = { [0] = { texture = -1, drawable = -1 }, [1] = { texture = -1, drawable = -1 }, [2] = { texture = -1, drawable = -1 }, [6] = { texture = -1, drawable = -1 }, [7] = { texture = -1, drawable = -1 } }
    }
}

-- Helper function to apply outfits
local function ApplyOutfitToPed(ped, outfitData)
    if not outfitData then return end

    -- Initialize Head Blend Data with Skin ID set to 4
    local model = GetEntityModel(ped)
    if model == GetHashKey("mp_m_freemode_01") then
        -- shapeFirstID, shapeSecondID, shapeThirdID, skinFirstID, skinSecondID, skinThirdID, shapeMix, skinMix, thirdMix, isParent
        SetPedHeadBlendData(ped, 0, 0, 0, 4, 4, 0, 0.5, 0.5, 0.0, false)
    elseif model == GetHashKey("mp_f_freemode_01") then
        SetPedHeadBlendData(ped, 21, 21, 0, 4, 4, 0, 0.5, 0.5, 0.0, false)
    end

    -- Set black hair color explicitly for freemode peds
    SetPedHairColor(ped, outfitData.hairColor or 0, 0)

    if outfitData.components then
        for compId, data in pairs(outfitData.components) do
            SetPedComponentVariation(ped, tonumber(compId), data.drawable, data.texture, data.palette)
        end
    end

    if outfitData.props then
        for propId, data in pairs(outfitData.props) do
            if data.drawable == -1 then
                ClearPedProp(ped, tonumber(propId))
            else
                SetPedPropIndex(ped, tonumber(propId), data.drawable, data.texture, true)
            end
        end
    end
end

-- Command to spawn the ped
RegisterCommand("pp", function(source, args, rawCommand)
    local option = args[1]
    
    if not option or not outfits[option] then
        print("^1[ERROR]^7 Invalid or missing option. Available options: m, f, lab_m, lab_f, scuba_m, scuba_f")
        return
    end

    local modelHash
    if option == "m" or option == "lab_m" or option == "scuba_m" then
        modelHash = GetHashKey("mp_m_freemode_01")
    elseif option == "f" or option == "lab_f" or option == "scuba_f" then
        modelHash = GetHashKey("mp_f_freemode_01")
    end

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(10)
    end

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    local ped = CreatePed(4, modelHash, coords.x, coords.y, coords.z, heading, true, false)
    
    ApplyOutfitToPed(ped, outfits[option])

    local netId = NetworkGetNetworkIdFromEntity(ped)
    SetNetworkIdExistsOnAllMachines(netId, true)
    
    table.insert(spawnedPeds, netId)
    
    print("^2[SUCCESS]^7 Spawned Ped ("..option..") - ^3NetID: " .. netId .. "^7")
    SetModelAsNoLongerNeeded(modelHash)
end, false)

-- Command to remove the ped(s)
RegisterCommand("rmpp", function(source, args, rawCommand)
    local targetNetId = args[1]
    
    if targetNetId then
        targetNetId = tonumber(targetNetId)
        local ped = NetToPed(targetNetId)
        
        if DoesEntityExist(ped) then
            NetworkRequestControlOfEntity(ped)
            DeleteEntity(ped)
            print("^2[SUCCESS]^7 Removed ped with NetID: ^3" .. targetNetId .. "^7")
        else
            print("^1[ERROR]^7 Ped with NetID ^3" .. targetNetId .. "^7 does not exist or is no longer in scope.")
        end
        
        for i, trackedNetId in ipairs(spawnedPeds) do
            if trackedNetId == targetNetId then
                table.remove(spawnedPeds, i)
                break
            end
        end
    else
        local count = 0
        for _, netId in ipairs(spawnedPeds) do
            local ped = NetToPed(netId)
            if DoesEntityExist(ped) then
                NetworkRequestControlOfEntity(ped)
                DeleteEntity(ped)
                count = count + 1
            end
        end
        
        spawnedPeds = {}
        print("^2[SUCCESS]^7 Removed ^3" .. count .. "^7 spawned peds.")
    end
end, false)
