local elevator_top = nil
local elevator_bottom = nil


function StartElevator()
    if not Config.zones.elevator_target_enabled then return end
    if elevator_top ~= nil then Target:removeZone(elevator_top) end
    elevator_top = Target:addBoxZone({
        name = "elevator_top",
        coords = Config.zones.elevator_top_zone_coords,
        size = Config.zones.elevator_top_zone_size,
        rotation = Config.zones.elevator_top_zone_rotation,
        debug = Config.debug_poly,
        options = {{
            label = Locale.elevator.go_down,
            name = "elevator_use",
            icon = "fa-solid fa-elevator",
            distance = 2.0,
            onSelect = function()
                local target = Config.zones.elevator_bottom_spawn
                StartPlayerTeleport(PlayerId(), target.x, target.y, target.z, target.w, false, false, false)
            end
        }}
    })
    if elevator_bottom ~= nil then Target:removeZone(elevator_bottom) end
    elevator_bottom = Target:addBoxZone({
        name = "elevator_bottom",
        coords = Config.zones.elevator_bottom_zone_coords,
        size = Config.zones.elevator_bottom_zone_size,
        rotation = Config.zones.elevator_bottom_zone_rotation,
        debug = Config.debug_poly,
        options = {{
            label = Locale.elevator.go_up,
            name = "elevator_use",
            icon = "fa-solid fa-elevator",
            distance = 2.0,
            onSelect = function()
                local target = Config.zones.elevator_top_spawn
                StartPlayerTeleport(PlayerId(), target.x, target.y, target.z, target.w, false, false, false)
            end
        }}
    })
end

function StopElevator()
    if elevator_top ~= nil then Target:removeArea(elevator_top) end
    if elevator_bottom ~= nil then Target:removeArea(elevator_bottom) end

    elevator_top = nil
    elevator_bottom = nil
end
