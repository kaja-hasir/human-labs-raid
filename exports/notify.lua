Notify = {}

local config = Config.framework.notify
local use_auto = config.use_auto
local use_ox_lib = config.use_ox_lib
local use_custom = config.use_custom

if use_auto then
    use_ox_lib = GetResourceState('ox_lib') == 'started'
end

if use_ox_lib then
    function Notify:message(target, title, description)
        if IsDuplicityVersion() then
            lib.notify(target, {
                title = title,
                description = description,
                type = 'inform'
            })
        else
            TriggerServerEvent('human_labs_raid:server:notify_self', title, description)
        end
    end
    function Notify:progressBar(duration, label, can_cancel, disable_move)
        return lib.progressBar({
            duration = duration,
            label = label,
            useWhileDead = false,
            canCancel = can_cancel,
            disable = {
                move = disable_move,
                car = true,
                combat = true
            }
        })
    end
else
    if not use_custom then
        warn("No Notify library specified, disabling notification function completely")
    end

    function Notify:message(target, title, description)
        if IsDuplicityVersion() then
            config.custom.message(target, title, description)
        else
            TriggerServerEvent('human_labs_raid:server:notify_self', title, description)
        end
    end
    function Notify:progressBar(duration, label, can_cancel, disable_move)
        return config.custom.progress_bar(duration, label, can_cancel, disable_move)
    end
end
