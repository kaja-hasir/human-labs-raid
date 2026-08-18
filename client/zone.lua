local global_zone = nil
local perimeter_zone = nil
local lab_entry_zone_1 = nil
local lab_entry_zone_2 = nil
local lab_zone = nil

local function start_perimeter()
    if perimeter_zone ~= nil then Target:removeZone(perimeter_zone) end
    perimeter_zone = Target:poly({ -- perimeter area
        points = Config.zones.perimeter_poly,
        thickness = Config.zones.perimeter_thickness,
        debug = Config.debug_poly,
        onEnter = function()
            TriggerServerEvent('human_labs_raid:server:zone:perimeter_enter')
        end,
        onExit = function()
            TriggerServerEvent('human_labs_raid:server:zone:perimeter_exit')
        end,
    })
end

local function start_lab_entry()
    if lab_entry_zone_1 ~= nil then Target:removeZone(lab_entry_zone_1) end
    lab_entry_zone_1 = Target:box({ -- to lab entry first (warning)
        coords = Config.zones.lab_entry_warning_coords,
        size = Config.zones.lab_entry_warning_size,
        rotation = Config.zones.lab_entry_warning_rotation,
        debug = Config.debug_poly,
        onEnter = function()
            if WearingPlayerOutfit ~= Outfit.Lab then
                TriggerEvent('human_labs_raid:client:suspicious:inform_suspicious', true, Locale.suspicion.suspicious_lab_entry)
                TriggerServerEvent('human_labs_raid:server:npc:prohibited_lab_entry_warning', true)
            end
        end,
        onExit = function()
            if WearingPlayerOutfit ~= Outfit.Lab then
                TriggerEvent('human_labs_raid:client:suspicious:inform_suspicious', false, "")
                TriggerServerEvent('human_labs_raid:server:npc:prohibited_lab_entry_warning', false)
            end
        end
    })
    if lab_entry_zone_2 ~= nil then Target:removeZone(lab_entry_zone_2) end
    lab_entry_zone_2 = Target:box({ -- to lab entry second (alarm)
        coords = Config.zones.lab_entry_trigger_coords,
        size = Config.zones.lab_entry_trigger_size,
        rotation = Config.zones.lab_entry_trigger_rotation,
        debug = Config.debug_poly,
        onEnter = function()
            if WearingPlayerOutfit ~= Outfit.Lab then
                TriggerServerEvent('human_labs_raid:server:security:prohibited_lab_entry')
            end
        end
    })
end

local function start_lab()
    local last_inside_trigger = 0
    if lab_zone ~= nil then Target:removeZone(lab_zone) end
    lab_zone = Target:box({ -- lab
        coords = Config.zones.lab_zone_coords,
        size = Config.zones.lab_zone_size,
        rotation = Config.zones.lab_zone_rotation,
        debug = Config.debug_poly,
        onEnter = function()
            local player_ped = PlayerPedId()
            Entity(player_ped).state.is_in_lab_zone = true
        end,
        inside = function()
            local now = GetGameTimer()
            if now - last_inside_trigger < 500 then return end
            last_inside_trigger = now
            TriggerServerEvent('human_labs_raid:server:zone:lab_enter')
        end,
        onExit = function()
            local player_ped = PlayerPedId()
            Entity(player_ped).state.is_in_lab_zone = false
            TriggerServerEvent('human_labs_raid:server:zone:lab_exit')
        end
    })
end

function StartLocalZones()
    while not Target:loaded() do Wait(100) end

    start_perimeter()
    start_lab_entry()
    start_lab()
end

function ClearLocalZones()
    if perimeter_zone ~= nil then Target:removeZone(perimeter_zone) end
    if lab_entry_zone_1 ~= nil then Target:removeZone(lab_entry_zone_1) end
    if lab_entry_zone_2 ~= nil then Target:removeZone(lab_entry_zone_2) end
    if lab_zone ~= nil then Target:removeZone(lab_zone) end

    perimeter_zone = nil
    lab_entry_zone_1 = nil
    lab_entry_zone_2 = nil
    lab_zone = nil
end

function StartGlobalZone()
    while not Target:loaded() do Wait(100) end

    if global_zone ~= nil then Target:removeZone(global_zone) end
    global_zone = Target:sphere({ -- loading sphere
        coords = Config.zones.global_zone_coords,
        radius = Config.zones.global_zone_radius,
        debug = Config.debug_poly,
        onEnter = function()
            TriggerServerEvent('human_labs_raid:server:zone:global_enter')
        end,
        onExit = function()
            TriggerServerEvent('human_labs_raid:server:zone:global_exit')
        end,
    })
end


AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Entity(PlayerPedId()).state.is_in_lab_zone = false
end)
