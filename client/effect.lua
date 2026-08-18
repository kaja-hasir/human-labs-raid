local function load_ptfx()
    RequestNamedPtfxAsset('core')
    return not RepeatFunctionUntilTrueWithTimeout(HasNamedPtfxAssetLoaded, { 'core' })
end

local function start_effect(name, coords, rotation, scale, duration)
    if not load_ptfx() then return end
    UseParticleFxAssetNextCall('core')

    local handle = StartParticleFxLoopedAtCoord(name, coords.x, coords.y, coords.z, rotation.x, rotation.y, rotation.z, scale, false, false, false, false)
    SetParticleFxLoopedColour(handle, 1.0, 1.0, 1.0, false)
    CreateThread(function()
        Wait(duration)
        StopParticleFxLooped(handle, false)
    end)
end

local function start_extraction_effect(location)
    start_effect('weap_hvy_turbulance_water', location, vec3(45.0, 0.0, 90.0), 0.7, 300)
    start_effect('exp_grd_grenade_smoke', location, vec3(45.0, 0.0, 0.0), 3.0, 15000)
end
local function start_compress_effect(location)
    local new_location = vec3(location.x + 0.3, location.y + 0.0, location.z + 1.25)
    local new_location2 = vec3(new_location.x, new_location.y, new_location.z - 0.5)
    start_effect('exp_grd_grenade_smoke', new_location2, vec3(0.0, 0.0, 0.0), 1.0, 1400)
    Wait(800)
    start_effect('proj_missile_trail', new_location, vec3(0.0, 0.0, 0.0), 0.05, 800)
end
local function start_packaging_effect(location)
    local new_location = vec3(
        location.x - 0.7 + 1.4 * math.random(),
        location.y - 0.2 + 0.4 * math.random(),
        location.z + 0.3
    )
    start_effect('ent_sht_gloopy_liquid', new_location, vec3(0.0, 0.0, 0.0), 0.8, 1000)
end

RegisterNetEvent('human_labs_raid:client:effect:extraction', start_extraction_effect)
RegisterNetEvent('human_labs_raid:client:effect:compress', start_compress_effect)
RegisterNetEvent('human_labs_raid:client:effect:packaging', start_packaging_effect)
