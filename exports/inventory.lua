Inventory = {}

local config = Config.framework.inventory
local use_auto = config.use_auto
local use_ox_inventory = config.use_ox_inventory
local use_custom = config.use_custom

if use_auto then
    use_ox_inventory = GetResourceState('ox_inventory') == 'started'
end

if use_ox_inventory then
    function Inventory:GetItemCount(target, item, metadata)
        if IsDuplicityVersion() then
            return exports.ox_inventory:GetItemCount(target, item, metadata)
        else
            return exports.ox_inventory:GetItemCount(target, item)
        end
    end
    function Inventory:CanCarryItem(target, item, amount)
        return exports.ox_inventory:CanCarryItem(target, item, amount)
    end
    function Inventory:AddItem(target, item, amount, metadata)
        if Inventory:CanCarryItem(target, item, amount) then
            exports.ox_inventory:AddItem(target, item, amount, metadata)
        else
            Notify:message(target, Locale.crafting.unable_to_carry_more_title, Locale.crafting.unable_to_carry_more_message)
        end
    end
    function Inventory:RemoveItem(target, item, amount)
        exports.ox_inventory:RemoveItem(target, item, amount)
    end
else
    if not use_custom then
        warn("No inventory library specified, using custom function in config.lua")
    end

    function Inventory:GetItemCount(target, item, metadata)
        if IsDuplicityVersion() then
            return config.custom.get_item_count(target, item, metadata)
        else
            return config.custom.get_item_count(target, item)
        end
    end
    function Inventory:CanCarryItem(target, item, amount)
        return config.custom.can_carry_item(target, item, amount)
    end
    function Inventory:AddItem(target, item, amount, metadata)
        if Inventory:CanCarryItem(target, item, amount) then
            config.custom.add_item(target, item, amount, metadata)
        else
            Notify:message(target, Locale.crafting.unable_to_carry_more_title, Locale.crafting.unable_to_carry_more_message)
        end
    end
    function Inventory:RemoveItem(target, item, amount)
        config.custom.get_item_count(target, item, amount)
    end
end
