Target = {}

local config = Config.framework.target
local use_auto = config.use_auto
local use_ox_target = config.use_ox_lib
local use_custom = config.use_custom

if use_auto then
    use_ox_target = GetResourceState('ox_target') == 'started'
end

if use_ox_target then
    function Target:loaded()
        return GetResourceState('ox_target') == 'started'
        and GetResourceState('ox_lib') == 'started'
    end
    function Target:addBoxZone(data)
        return exports.ox_target:addBoxZone(data)
    end
    function Target:addLocalEntity(entity, data)
        return exports.ox_target:addLocalEntity(entity, data)
    end
    function Target:removeArea(id)
        exports.ox_target:removeZone(id)
    end
    function Target:poly(data)
        return lib.zones.poly(data)
    end
    function Target:box(data)
        return lib.zones.box(data)
    end
    function Target:sphere(data)
        return lib.zones.sphere(data)
    end
    function Target:removeZone(zone)
        zone:remove()
    end
else
    if not use_custom then
        warn("No Target library specified, disabling notification function completely")
    end

    function Target:loaded()
        return config.custom.dependencies_ready()
    end
    function Target:addBoxZone(data)
        return config.custom.add_box_zone(data)
    end
    function Target:addLocalEntity(entity, data)
        return config.custom.add_local_entity(entity, data)
    end
    function Target:removeArea(id)
        config.custom.remove_area(id)
    end
    function Target:poly(data)
        return config.custom.poly(data)
    end
    function Target:box(data)
        return config.custom.box(data)
    end
    function Target:sphere(data)
        return config.custom.sphere(data)
    end
    function Target:removeZone(zone)
        config.custom.remove_zone(zone)
    end
end
