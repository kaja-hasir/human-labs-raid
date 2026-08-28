-- An alternative to ox_target i.e. a variation that is used in target.lua

ProximityTarget = {}

local custom_zone = {}
local interactions = {}
local interaction_loop_active = {}
local progressing_zone_id = 0

local KEYCODE_INTERACT = 38 -- E
local KEYCODE_UP = 172 -- Arrow up
local KEYCODE_DOWN = 173 -- Arrow down

local DISTANCE_DEFAULT = 2.0
local RAYCAST_BONE_DISTANCE = 1.0
local raycasting = false

local function get_next_id()
    progressing_zone_id = progressing_zone_id + 1
    return progressing_zone_id
end

local function can_player_interact()
    local player_ped = PlayerPedId()
    return not IsPedDeadOrDying(player_ped, true)
        and not IsPedFalling(player_ped)
        and not IsPedRagdoll(player_ped)
        -- and not IsPedInMeleeCombat(player_ped)
        and not IsPedShooting(player_ped)
end

local function draw_text_3d(x, y, z, text, is_selected)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(true)
        if is_selected then
            SetTextColour(255, 255, 255, 255) -- Blue for selected
        else
            SetTextColour(150, 150, 150, 215)
        end
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

local function interaction_loop(data, id)
    if interaction_loop_active[id]
    or IsControlPressed(0, KEYCODE_INTERACT)
    or IsControlPressed(0, KEYCODE_UP)
    or IsControlPressed(0, KEYCODE_DOWN) then
        return
    end

    interaction_loop_active[id] = true

    CreateThread(function()
        local hovering_over_list_index = 1
        while true do
            Wait(0)

            if not can_player_interact() then break end

            local interaction_list = {}
            for i, _ in ipairs(data) do
                if interactions[id][i] ~= false then
                    interaction_list[#interaction_list + 1] = interactions[id][i]
                end
            end

            local interaction_list_size = #interaction_list
            if interaction_list_size == 0 then break end

            if hovering_over_list_index > interaction_list_size then
                hovering_over_list_index = interaction_list_size
            elseif hovering_over_list_index < 1 then
                hovering_over_list_index = 1
            end

            if IsControlJustPressed(0, KEYCODE_UP) then
                hovering_over_list_index = math.max(1, hovering_over_list_index - 1)
            elseif IsControlJustPressed(0, KEYCODE_DOWN) then
                hovering_over_list_index = math.min(interaction_list_size, hovering_over_list_index + 1)
            end

            for i, item in ipairs(interaction_list) do
                local text_pos = item.text_pos
                local is_selected = (i == hovering_over_list_index)
                local text = item.option.label
                if text == nil then text = "unknown" end
                if is_selected then text = "> " .. item.option.label .. " <" end

                local z_offset = 0.4 - ((i - 1) * 0.08)
                draw_text_3d(text_pos.x, text_pos.y, text_pos.z + z_offset, text, is_selected)
            end

            -- BeginTextCommandDisplayHelp("STRING")
            -- AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to interact")
            -- EndTextCommandDisplayHelp(0, false, true, -1)

            if IsControlJustPressed(0, KEYCODE_INTERACT) then
                local selected_interaction = interaction_list[hovering_over_list_index]
                if type(selected_interaction.option.onSelect) == "function" then
                    selected_interaction.option.onSelect()
                end
                break
            end
        end
        interaction_loop_active[id] = false
    end)
end

local function get_maximum_raycast_length(data)
    local maximum_raycast_length = 0.0
    for _, option in ipairs(data) do
        local distance = option.distance
        if distance == nil then
            maximum_raycast_length = DISTANCE_DEFAULT
        elseif distance > maximum_raycast_length then
            maximum_raycast_length = distance
        end
    end
    return maximum_raycast_length
end

local function get_maximum_bone_offset(entity, data)
    local maximum_bone_offset = 0.0
    local entity_coords = GetEntityCoords(entity)
    for _, option in ipairs(data) do
        local bones = option.bones
        if bones ~= nil then
            for _, bone_name in ipairs(bones) do
                local bone_index = GetEntityBoneIndexByName(entity, bone_name)
                if bone_index ~= -1 then
                    local bone_coords = GetWorldPositionOfEntityBone(entity, bone_index)
                    local diff = #(entity_coords - bone_coords)
                    if diff > maximum_bone_offset then
                        maximum_bone_offset = diff
                    end
                end
            end
        end
    end
    return maximum_bone_offset
end

local function throw_raycast(target_entity)
    local start = GetGameplayCamCoord()
    local camera_rotation = GetGameplayCamRot(2)

    local pitch = math.rad(camera_rotation.x)
    local yaw = math.rad(camera_rotation.z)
    local scale = math.abs(math.cos(pitch))

    local direction = vec3(
        -math.sin(yaw) * scale,
        math.cos(yaw) * scale,
        math.sin(pitch)
    )
    local dest = start + direction * 15.0 -- Cast long ray and check later for distance

    while raycasting do Wait(0) end
    raycasting = true
    local ray = StartShapeTestLosProbe(
        start.x, start.y, start.z,
        dest.x, dest.y, dest.z,
        -1, PlayerPedId(), 4)

    local retval, hit, hit_coords, entity_hit = 1, false, vec3(0, 0, 0), 1
    while retval == 1 do
        retval, hit, hit_coords, _, entity_hit = GetShapeTestResult(ray) -- hit is integer not bool
        Wait(0)
    end
    raycasting = false

    if hit == 1 and (target_entity == nil or entity_hit == target_entity) then
        return hit_coords
    end
    return nil
end

local function values_debug_rectangle(coords, size, rotation)
    local rad = math.rad(rotation)
    local cos = math.cos(rad)
    local sin = math.sin(rad)

    local x1 = coords.x - size.x / 2 * cos + size.y / 2 * sin
    local y1 = coords.y - size.x / 2 * sin - size.y / 2 * cos

    local x2 = coords.x + size.x / 2 * cos + size.y / 2 * sin
    local y2 = coords.y + size.x / 2 * sin - size.y / 2 * cos

    local x3 = coords.x + size.x / 2 * cos - size.y / 2 * sin
    local y3 = coords.y + size.x / 2 * sin + size.y / 2 * cos

    local x4 = coords.x - size.x / 2 * cos - size.y / 2 * sin
    local y4 = coords.y - size.x / 2 * sin + size.y / 2 * cos

    local z1 = coords.z - size.z / 2
    local z2 = coords.z + size.z / 2

    return table.pack(x1, y1, x2, y2, x3, y3, x4, y4, z1, z2)
end
local function draw_debug_rectangle(values)
    local x1, y1, x2, y2, x3, y3, x4, y4, z1, z2 = table.unpack(values)

    -- Bottom
    DrawPoly(x1,y1,z1, x2,y2,z1, x3,y3,z1, 0,255,0, 30)
    DrawPoly(x1,y1,z1, x3,y3,z1, x4,y4,z1, 0,255,0, 30)
    -- Top
    DrawPoly(x1,y1,z2, x3,y3,z2, x2,y2,z2, 0,255,0, 30)
    DrawPoly(x1,y1,z2, x4,y4,z2, x3,y3,z2, 0,255,0, 30)
    -- Vertical sides
    DrawPoly(x1,y1,z1, x4,y4,z1, x4,y4,z2, 0,255,0, 30)
    DrawPoly(x1,y1,z1, x4,y4,z2, x1,y1,z2, 0,255,0, 30)
    DrawPoly(x2,y2,z1, x2,y2,z2, x3,y3,z2, 0,255,0, 30)
    DrawPoly(x2,y2,z1, x3,y3,z2, x3,y3,z1, 0,255,0, 30)
    DrawPoly(x1,y1,z1, x1,y1,z2, x2,y2,z2, 0,255,0, 30)
    DrawPoly(x1,y1,z1, x2,y2,z2, x2,y2,z1, 0,255,0, 30)
    DrawPoly(x4,y4,z1, x3,y3,z1, x3,y3,z2, 0,255,0, 30)
    DrawPoly(x4,y4,z1, x3,y3,z2, x4,y4,z2, 0,255,0, 30)
end

local function values_debug_poly(points, thickness)
    local min_z, max_z = math.huge, -math.huge

    for i = 1, #points do
        local z = points[i].z
        if z < min_z then min_z = z end
        if z > max_z then max_z = z end
    end

    min_z = (min_z + max_z) / 2 - thickness / 2
    max_z = (min_z + max_z) / 2 + thickness / 2
    return table.pack(points, min_z, max_z)
end
local function draw_debug_poly(values)
    local points, min_z, max_z = table.unpack(values)
    for i = 2, #points - 1 do
        DrawPoly(
            points[1].x, points[1].y, min_z,
            points[i].x, points[i].y, min_z,
            points[i + 1].x, points[i + 1].y, min_z,
            0, 255, 0, 30
        )
        DrawPoly(
            points[1].x, points[1].y, max_z,
            points[i + 1].x, points[i + 1].y, max_z,
            points[i].x, points[i].y, max_z,
            0, 255, 0, 30
        )
        DrawLine(
            points[1].x, points[1].y, min_z,
            points[1].x, points[1].y, max_z,
            0, 255, 0, 100
        )
    end
    for i = 1, #points do
        local j = i % #points + 1
        DrawLine(
            points[i].x, points[i].y, min_z,
            points[j].x, points[j].y, min_z,
            0, 255, 0, 100
        )
        DrawLine(
            points[i].x, points[i].y, max_z,
            points[j].x, points[j].y, max_z,
            0, 255, 0, 100
        )
        DrawLine(
            points[i].x, points[i].y, min_z,
            points[i].x, points[i].y, max_z,
            0, 255, 0, 100
        )
    end
end

local function is_inside_box(p, coords, size, rotation)
    local rad = math.rad(rotation)
    local x = (p.x - coords.x) * math.cos(rad) + (p.y - coords.y) * math.sin(rad)
    local y = (p.x - coords.x) * math.sin(rad) - (p.y - coords.y) * math.cos(rad)

    return math.abs(x) <= size.x / 2
        and math.abs(y) <= size.y / 2
        and math.abs(p.z - coords.z) <= size.z / 2
end

local function is_inside_poly(p, poly_values)
    local points, min_z, max_z = table.unpack(poly_values)
    if p.z < min_z or p.z > max_z then return false end

    local is_inside = false
    local j = #points

    for i = 1, #points do
        if (points[i].y > p.y) ~= (points[j].y > p.y)
            and p.x < (p.y - points[i].y)
                * (points[j].x - points[i].x)
                / (points[j].y - points[i].y) + points[i].x
        then
            is_inside = not is_inside
        end
        j = i
    end

    return is_inside
end

function ProximityTarget:loaded()
    return true
end
function ProximityTarget:addBoxZone(data)
    local coords = data.coords
    local size = data.size
    local rotation = data.rotation
    local debug = data.debug
    local options = data.options

    if coords == nil or size == nil or rotation == nil or options == nil or options == {} then return end

    local zone_id = get_next_id()
    custom_zone[zone_id] = true
    interactions[zone_id] = {}

    local maximum_raycast_length = get_maximum_raycast_length(data.options)

    if debug then
        local values = values_debug_rectangle(coords, size, rotation)
        CreateThread(function()
            while custom_zone[zone_id] do
                draw_debug_rectangle(values)
                Wait(0)
            end
        end)
    end

    CreateThread(function()
        local player_ped = PlayerPedId()

        while custom_zone[zone_id] do
            local player_coords = GetEntityCoords(player_ped)
            local is_close = #(player_coords - coords) < maximum_raycast_length
            if is_close and can_player_interact() then
                local some_interaction_possible = false
                for i, option in ipairs(data.options) do
                    local distance = option.distance
                    if distance == nil then distance = DISTANCE_DEFAULT end
                    local canInteract = option.canInteract

                    if type(canInteract) ~= "function" or canInteract() then
                        local hit_coords = throw_raycast(nil)
                        if hit_coords ~= nil and #(player_coords - hit_coords) < distance
                            and is_inside_box(hit_coords, coords, size, rotation) then
                            interactions[zone_id][i] = {
                                option = option,
                                text_pos = coords
                            }
                            some_interaction_possible = true
                        else
                            interactions[zone_id][i] = false
                        end
                    else
                        interactions[zone_id][i] = false
                    end
                end
                if some_interaction_possible then
                    interaction_loop(data.options, zone_id)
                end
            else
                interactions[zone_id] = {}
            end

            Wait(500)
        end
    end)

    return zone_id
end
function ProximityTarget:addLocalEntity(entity, data)
    if data == nil or data == {} then return end

    local zone_id = get_next_id()
    custom_zone[zone_id] = true
    interactions[zone_id] = {}

    local maximum_raycast_length = get_maximum_raycast_length(data) + get_maximum_bone_offset(entity, data)

    CreateThread(function()
        local player_ped = PlayerPedId()

        while custom_zone[zone_id] and DoesEntityExist(entity) do
            local entity_coords = GetEntityCoords(entity)
            local player_coords = GetEntityCoords(player_ped)
            local are_close = #(player_coords - entity_coords) < maximum_raycast_length

            if are_close and can_player_interact() then
                local some_interaction_possible = false
                for i, option in ipairs(data) do
                    local distance = option.distance
                    if distance == nil then distance = DISTANCE_DEFAULT end
                    local canInteract = option.canInteract

                    if type(canInteract) ~= "function" or canInteract() then
                        local bones = option.bones
                        local hit_coords = throw_raycast(entity)
                        local target_coords = entity_coords

                        local valid_interaction = false
                        if hit_coords ~= nil and bones then
                            local closest_to_rc = math.huge

                            for _, bone_name in ipairs(bones) do
                                local bone_index = GetEntityBoneIndexByName(entity, bone_name)
                                if bone_index ~= -1 then
                                    local bone_coords = GetWorldPositionOfEntityBone(entity, bone_index)
                                    local diff = #(hit_coords - bone_coords)
                                    if diff < closest_to_rc then
                                        closest_to_rc = diff
                                        target_coords = bone_coords
                                    end
                                end
                            end

                            valid_interaction = #(player_coords - hit_coords) < distance
                                and #(hit_coords - target_coords) < RAYCAST_BONE_DISTANCE
                        elseif hit_coords ~= nil then
                            valid_interaction = #(player_coords - hit_coords) < distance
                        end

                        if valid_interaction then
                            interactions[zone_id][i] = {
                                option = option,
                                text_pos = target_coords
                            }
                            some_interaction_possible = true
                        else
                            interactions[zone_id][i] = false
                        end
                    else
                        interactions[zone_id][i] = false
                    end
                end
                if some_interaction_possible then
                    interaction_loop(data, zone_id)
                end
            else
                interactions[zone_id] = {}
            end

            Wait(400)
        end
    end)

    return zone_id
end
function ProximityTarget:removeArea(id)
    custom_zone[id] = nil
end
function ProximityTarget:poly(data)
    local points = data.points
    local thickness = data.thickness
    local debug = data.debug
    local onEnter = data.onEnter
    local onExit = data.onExit
    local inside = data.inside

    if not points or #points < 3 or not thickness then return end

    local zone_id = get_next_id()
    custom_zone[zone_id] = true
    local player_is_inside = false
    local poly_values = values_debug_poly(points, thickness)

    if debug then
        CreateThread(function()
            while custom_zone[zone_id] do
                draw_debug_poly(poly_values)
                Wait(0)
            end
        end)
    end

    CreateThread(function()
        while custom_zone[zone_id] do
            local player_coords = GetEntityCoords(PlayerPedId())
            local now_inside = is_inside_poly(player_coords, poly_values)

            if not player_is_inside and now_inside then
                player_is_inside = true
                if type(onEnter) == "function" then onEnter() end
            elseif player_is_inside and now_inside then
                if type(inside) == "function" then inside() end
            elseif player_is_inside and not now_inside then
                player_is_inside = false
                if type(onExit) == "function" then onExit() end
            end

            Wait(1000)
        end
    end)

    return zone_id
end
function ProximityTarget:box(data)
    local coords = data.coords
    local size = data.size
    local rotation = data.rotation
    local debug = data.debug
    local onEnter = data.onEnter
    local onExit = data.onExit
    local inside = data.inside

    if not coords or not size or not rotation then return end

    local zone_id = get_next_id()
    custom_zone[zone_id] = true
    local player_is_inside = false

    if debug then
        local values = values_debug_rectangle(coords, size, rotation)
        CreateThread(function()
            while custom_zone[zone_id] do
                draw_debug_rectangle(values)
                Wait(0)
            end
        end)
    end

    CreateThread(function()
        local player_ped = PlayerPedId()

        while custom_zone[zone_id] do
            local player_coords = GetEntityCoords(player_ped)
            local is_now_inside = is_inside_box(player_coords, coords, size, rotation)

            if not player_is_inside and is_now_inside then
                player_is_inside = true
                if type(onEnter) == "function" then onEnter() end
            elseif player_is_inside and is_now_inside then
                if type(inside) == "function" then inside() end
            elseif player_is_inside and not is_now_inside then
                player_is_inside = false
                if type(onExit) == "function" then onExit() end
            end

            Wait(500)
        end
    end)

    return zone_id
end
function ProximityTarget:sphere(data)
    local coords = data.coords
    local radius = data.radius
    local debug = data.debug
    local onEnter = data.onEnter
    local onExit = data.onExit
    local inside = data.inside

    if coords == nil or radius == nil then return end

    local zone_id = get_next_id()
    custom_zone[zone_id] = true
    local player_is_inside = false

    if debug then
        CreateThread(function()
            while custom_zone[zone_id] do
                DrawSphere(coords.x, coords.y, coords.z, radius, 0, 255, 0, 0.3)
                Wait(0)
            end
        end)
    end

    CreateThread(function()
        local player_ped = PlayerPedId()
        while custom_zone[zone_id] do
            local player_coords = GetEntityCoords(player_ped)
            local is_now_inside = #(player_coords - coords) < radius

            if not player_is_inside and is_now_inside then
                player_is_inside = true
                if type(onEnter) == "function" then
                    onEnter()
                end
            elseif player_is_inside and is_now_inside then
                if type(inside) == "function" then
                    inside()
                end
            elseif player_is_inside and not is_now_inside then
                player_is_inside = false
                if type(onExit) == "function" then
                    onExit()
                end
            end

            Wait(1000)
        end
    end)

    return zone_id
end
function ProximityTarget:removeZone(zone)
    custom_zone[zone] = nil
end
