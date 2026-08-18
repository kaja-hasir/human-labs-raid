local extract_area = nil
local compress_area_1 = nil
local compress_area_2 = nil
local compress_area_3 = nil
local packaging_area_1 = nil
local packaging_area_2 = nil

ExtractionPossible = true

local function is_player_alive()
    local player_ped = PlayerPedId()
    return DoesEntityExist(player_ped) and not IsEntityDead(player_ped)
end

local function create_extract_area(quality_types_with_colors)
    if extract_area ~= nil then Target:removeArea(extract_area) end
    local gas_containers_coords = Config.crafting.locations.gas_containers
    extract_area = Target:addBoxZone({
        name = "gas_containers",
        coords = gas_containers_coords,
        size = vec3(0.75, 1.7, 2.0),
        rotation = 350.0,
        debug = Config.debug_poly,
        options = {{
            label = Locale.crafting.extract,
            name = "gas_containers-extraction",
            icon = "fa-solid fa-wind",
            iconColor = select(2, next(quality_types_with_colors)).color,
            distance = 1.5,
            canInteract = function()
                return ExtractionPossible
                and not Config.security.player_ignored_by_security(PlayerPedId())
                and is_player_alive()
            end,
            onSelect = function()
                TriggerEvent('human_labs_raid:client:minigame:start',
                    'extract',
                    {},
                    gas_containers_coords
                )
            end
        },{
            label = Locale.crafting.extract_disabled,
            name = "gas_containers-extraction-not-possible",
            icon = "fa-solid fa-ban",
            iconColor = '#CC0202',
            distance = 1.5,
            canInteract = function()
                return not ExtractionPossible
                and not Config.security.player_ignored_by_security(PlayerPedId())
                and is_player_alive()
            end,
        }}
    })
end

local function create_compress_area_helper(quality_types_with_colors, location)
    local options = {}

    for _, quality in ipairs(quality_types_with_colors) do
        local item_required = Config.crafting.gas_items[quality.name]
        local amount_required = Config.crafting.compression_gas_required

        options[#options + 1] = {
            label = Locale.crafting['stabilize_' .. quality.name],
            name = "gas_containers-compression_" .. quality.name,
            icon = "fa-solid fa-compress",
            iconColor = quality.color,
            distance = 1.5,
            canInteract = function()
                return Inventory:GetItemCount(item_required, {}) >= amount_required
                and not Config.security.player_ignored_by_security(PlayerPedId())
                and is_player_alive()
            end,
            onSelect = function()
                TriggerServerEvent('human_labs_raid:server:crafting:stabilize_check',
                {
                    quality = quality.name,
                    item_required = item_required,
                    amount_required = amount_required
                }, location)
            end
        }
    end

    return options
end
local function create_compress_area(quality_types_with_colors)
    if compress_area_1 ~= nil then Target:removeArea(compress_area_1) end
    local location = Config.crafting.locations.radiation_box_1
    local options = create_compress_area_helper(quality_types_with_colors, location)
    compress_area_1 = Target:addBoxZone({
        name = "radiation_box",
        coords = location,
        size = vec3(1.5, 1.7, 3.0),
        rotation = 350.0,
        debug = Config.debug_poly,
        options = options
    })

    if compress_area_2 ~= nil then Target:removeArea(compress_area_2) end
    location = Config.crafting.locations.radiation_box_2
    options = create_compress_area_helper(quality_types_with_colors, location)
    compress_area_2 = Target:addBoxZone({
        name = "radiation_box",
        coords = location,
        size = vec3(1.5, 1.7, 3.0),
        rotation = 350.0,
        debug = Config.debug_poly,
        options = options
    })

    if compress_area_3 ~= nil then Target:removeArea(compress_area_3) end
    location = Config.crafting.locations.radiation_box_3
    options = create_compress_area_helper(quality_types_with_colors, location)
    compress_area_3 = Target:addBoxZone({
        name = "radiation_box",
        coords = location,
        size = vec3(1.5, 1.7, 3.0),
        rotation = 350.0,
        debug = Config.debug_poly,
        options = options
    })
end

local function create_package_area_helper(quality_types_with_colors, location)
    local options = {}

    for _, quality in ipairs(quality_types_with_colors) do
        local item_required = Config.crafting.compressed_gas_items[quality.name]
        local amount_required = Config.crafting.packaging_compressed_gas_required

        options[#options + 1] = {
            label = Locale.crafting["package_" .. quality.name],
            name = "lab_desk-packaging_" .. quality.name,
            icon = "fa-solid fa-bottle-droplet",
            iconColor = quality.color,
            distance = 1.0,
            canInteract = function()
                return Inventory:GetItemCount(item_required, {}) >= amount_required
                and not Config.security.player_ignored_by_security(PlayerPedId())
                and is_player_alive()
            end,
            onSelect = function()
                TriggerServerEvent('human_labs_raid:server:crafting:package_check',
                {
                    quality = quality.name,
                    item_required = item_required,
                    amount_required = amount_required
                }, location)
            end
        }
    end

    return options
end
local function create_package_area(quality_types_with_colors)
    if packaging_area_1 ~= nil then Target:removeArea(packaging_area_1) end
    local location = Config.crafting.locations.lab_desk_1
    local options = create_package_area_helper(quality_types_with_colors, location)
    packaging_area_1 = Target:addBoxZone({
        name = "lab_desk",
        coords = location,
        size = vec3(1.9, 0.75, 1.0),
        rotation = 350.0,
        debug = Config.debug_poly,
        options = options
    })

    if packaging_area_2 then Target:removeArea(packaging_area_2) end
    location = Config.crafting.locations.lab_desk_2
    options = create_package_area_helper(quality_types_with_colors, location)
    packaging_area_2 = Target:addBoxZone({
        name = "lab_desk",
        coords = location,
        size = vec3(1.9, 0.75, 1.0),
        rotation = 350.0,
        debug = Config.debug_poly,
        options = options
    })
end

function StartCraftingAreas()
    while not Target:loaded() do Wait(100) end

    ExtractionPossible = true
    local quality_types_with_colors = Config.crafting.quality_with_colors
    create_extract_area(quality_types_with_colors)
    create_compress_area(quality_types_with_colors)
    create_package_area(quality_types_with_colors)
end

function StopCraftingAreas()
    if extract_area ~= nil then Target:removeArea(extract_area) end
    if compress_area_1 ~= nil then Target:removeArea(compress_area_1) end
    if compress_area_2 ~= nil then Target:removeArea(compress_area_2) end
    if compress_area_3 ~= nil then Target:removeArea(compress_area_3) end
    if packaging_area_1 ~= nil then Target:removeArea(packaging_area_1) end
    if packaging_area_2 ~= nil then Target:removeArea(packaging_area_2) end

    extract_area = nil
    compress_area_1 = nil
    compress_area_2 = nil
    compress_area_3 = nil
    packaging_area_1 = nil
    packaging_area_2 = nil
end

RegisterNetEvent('human_labs_raid:client:crafting:change_extraction_possible', function(new_possible)
    ExtractionPossible = new_possible
end)
