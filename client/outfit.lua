local valid_component_ids = { 1, 3, 4, 5, 6, 7, 8, 9, 10, 11 } -- 0 is face, 2 is hair and are ignored
local valid_prop_ids = { 0, 1, 2, 6, 7 }
local outfit_normal = nil
local outfit_lab = nil
local outfit_scuba = nil

local loading_normal_outfit_gracefully_thread_active = false
local loading_outfit_with_animation_thread_active = false
local scuba_oxygen_thread_active = false

Outfit = {
    Normal = 0,
    Lab = 1,
    Scuba = 2
}
WearingPlayerOutfit = Outfit.Normal

local function print_outfit(outfit)
    local c, p = {}, {}
    for _, i in ipairs(valid_component_ids) do
        local comp = outfit.components[i]
        c[#c+1] = string.format("[%d] = { texture = %d, drawable = %d, palette = %d }", i, comp.texture, comp.drawable, comp.palette)
    end
    for _, i in ipairs(valid_prop_ids) do
        local prop = outfit.props[i]
        p[#p+1] = string.format("[%d] = { texture = %d, drawable = %d }", i, prop.texture, prop.drawable)
    end
    print("components = { " .. table.concat(c, ", ") .. " }, props = { " .. table.concat(p, ", ") .. " }")
end

local function save_current_as_normal_outfit()
    local ped = PlayerPedId()
    outfit_normal = {
        model = GetEntityModel(ped),
        components = {},
        props = {}
    }

    for _, i in ipairs(valid_component_ids) do
        outfit_normal.components[i] = {
            drawable = GetPedDrawableVariation(ped, i),
            texture = GetPedTextureVariation(ped, i),
            palette = GetPedPaletteVariation(ped, i)
        }
    end
    for _, i in ipairs(valid_prop_ids) do
        outfit_normal.props[i] = {
            drawable = GetPedPropIndex(ped, i),
            texture = GetPedPropTextureIndex(ped, i)
        }
    end
end

local function load_outfit(outfit)
    if not outfit then return end

    local ped = PlayerPedId()

    if outfit.model and GetEntityModel(ped) ~= outfit.model then
        RequestModel(outfit.model)
        if RepeatFunctionUntilTrueWithTimeout(HasModelLoaded, { outfit.model }) then return end
        SetPlayerModel(PlayerId(), outfit.model)
        SetModelAsNoLongerNeeded(outfit.model)
        ped = PlayerPedId()
    end

    if outfit.components then
        for id, data in pairs(outfit.components) do
            SetPedComponentVariation(ped, id, data.drawable, data.texture, data.palette or 0)
        end
    end

    if outfit.props then
        for id, data in pairs(outfit.props) do
            if data.drawable == -1 then
                ClearPedProp(ped, id)
            else
                SetPedPropIndex(ped, id, data.drawable, data.texture, true)
            end
        end
    end
end

local function is_male()
    return GetHashKey('mp_m_freemode_01') == GetEntityModel(PlayerPedId())
end

local function get_maximum_oxygen_in_scuba(time_per_bottle)
    local item_count = 0
    for _, item in pairs(Config.scuba.gear_equip_item_required) do
        item_count = item_count + Inventory:GetItemCount(item)
    end
    return item_count * time_per_bottle
end

local function wait_for_scuba_purpose_finish()
    while WearingPlayerOutfit == Outfit.Scuba
    and IsPedSwimming(PlayerPedId()) do
        Wait(500)
    end
end

local function ensure_scuba_oxygen_overwrite()
    if scuba_oxygen_thread_active then return end
    scuba_oxygen_thread_active = true

    CreateThread(function()
        local time_per_bottle = Config.scuba.estimated_diving_time_for_escape_ms / Config.scuba.gear_equip_amount_required
        while WearingPlayerOutfit == Outfit.Scuba do
            Wait(500)
            local maximum_breath = get_maximum_oxygen_in_scuba(time_per_bottle)
            local consuming_gas = false
            local under_water_time = 0
            while IsPedSwimmingUnderWater(PlayerPedId()) do
                Wait(100)
                under_water_time = under_water_time + 100

                if maximum_breath > 0.0 then
                    consuming_gas = true
                    local remaining_oxygen = math.max(0.0, 100.0 - ((100.0 * under_water_time) / maximum_breath))
                    SetPlayerUnderwaterTimeRemaining(PlayerId(), remaining_oxygen)
                end
            end
            if consuming_gas then
                local number_of_gas_consumed = math.floor((under_water_time / time_per_bottle) + 0.5)
                TriggerServerEvent('human_labs_raid:server:scuba:consume_gas', number_of_gas_consumed)
            end
        end
        scuba_oxygen_thread_active = false
    end)
end

function SetupOutfits()
    save_current_as_normal_outfit()

    if is_male() then
        outfit_lab = Config.outfits.lab_coat_m
        outfit_scuba = Config.outfits.scuba_m
    else
        outfit_lab = Config.outfits.lab_coat_f
        outfit_scuba = Config.outfits.scuba_f
    end

    if Config.print_current_outfit then
        print_outfit(outfit_normal)
    end
end

function LoadNormalOutfitGracefully()
    if loading_normal_outfit_gracefully_thread_active then return end
    loading_normal_outfit_gracefully_thread_active = true

    CreateThread(function()
        wait_for_scuba_purpose_finish()
        LoadNormalOutfit()
        loading_normal_outfit_gracefully_thread_active = false
    end)
end

function LoadOutfitWithAnimation(outfit_fn)
    if loading_outfit_with_animation_thread_active then return end
    loading_outfit_with_animation_thread_active = true

    CreateThread(function()
        local player_ped = PlayerPedId()
        TriggerEvent('human_labs_raid:client:suspicious:inform_suspicious_instant', true, Locale.suspicion.changing_clothes, 1.0)

        local search_dict = 'random@domestic'
        local search_anim = 'pickup_low'
        RequestAnimDict(search_dict)
        if not RepeatFunctionUntilTrueWithTimeout(HasAnimDictLoaded, { search_dict }) then
            TaskPlayAnim(player_ped, search_dict, search_anim, 8.0, -8.0, 2000, 0, 0.0, false, false, false)
            RemoveAnimDict(search_dict)
            Wait(2000)
            ClearPedTasks(player_ped)
            Wait(150)
        end

        local clothing_dict = 'clothingshirt'
        local clothing_anim = 'try_shirt_positive_a'
        RequestAnimDict(clothing_dict)
        if not RepeatFunctionUntilTrueWithTimeout(HasAnimDictLoaded, { clothing_dict }) then
            TaskPlayAnim(player_ped, clothing_dict, clothing_anim, 8.0, -8.0, 3500, 0, 0.0, false, false, false)
            RemoveAnimDict(clothing_dict)
            Wait(1200)
        end

        outfit_fn()
        Wait(2300)
        ClearPedTasks(player_ped)

        TriggerEvent('human_labs_raid:client:suspicious:inform_suspicious', false, "")
        loading_outfit_with_animation_thread_active = false
    end)
end

function LoadNormalOutfit()
    if WearingPlayerOutfit == Outfit.Normal then return end
    WearingPlayerOutfit = Outfit.Normal
    SetEnableScuba(PlayerPedId(), false)
    ClearPedScubaGearVariation(PlayerPedId())
    load_outfit(outfit_normal)
    TriggerServerEvent('human_labs_raid:server:blips:inform_wearing_lab_coat', false)
end

function LoadLabOutfit()
    if WearingPlayerOutfit == Outfit.Lab then return end
    WearingPlayerOutfit = Outfit.Lab
    SetEnableScuba(PlayerPedId(), false)
    ClearPedScubaGearVariation(PlayerPedId())
    load_outfit(outfit_lab)
    TriggerServerEvent('human_labs_raid:server:blips:inform_wearing_lab_coat', true)
end

function LoadScubaOutfit()
    if WearingPlayerOutfit == Outfit.Scuba then return end
    WearingPlayerOutfit = Outfit.Scuba
    load_outfit(outfit_scuba)
    SetEnableScuba(PlayerPedId(), true)
    SetPedScubaGearVariation(PlayerPedId())
    TriggerServerEvent('human_labs_raid:server:blips:inform_wearing_lab_coat', false)
    ensure_scuba_oxygen_overwrite()
end
