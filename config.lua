Config = {}


----------- GLOBAL -----------
Config.print_current_outfit = true -- Put false after setting up outfits (prints for clients globally)
Config.debug = false

Config.language = 'de' -- Supports: 'de', 'en'

-- ONLY httpRequest in script to send version and server id (telemetry.lua)
-- I use it to get the server count who use this skript, language, version:
-- "x Servers use and love the script - Release more updates!"
Config.support_the_creator_telemetry = true

Config.clear_population_every_frame = true -- Remove if all peds are cleared either way to save performance
Config.raid_reentry_cooldown = 60*60*1000 -- 1 hour cooldown after raid end
Config.reconnect_location = vec4(2911.7893, 4320.9497, 50.2861, 286.2869) -- Position for reconnecting players; default is where transporters despawn near containers
Config.general_loading_wait_time_ms = 100 -- Decrease (>30) makes more responsive; Increase (<5000) improves performance

Config.blips = {
    global_blip = true,
    global_human_labs = vec3(3449.1243, 3769.8928, 30.5197),

    transporters = Config.debug, -- Set true to enforce transporter blips driving on minimap

    security = true,
    security_cones = false,
    interactable_npcs = true,

    stealth_relevant = true,
    stealth_relevant_cones = true,
    show_cones_only_in_stealth = true
}
Config.outfits = {
    lab_coat_m = {
        -- THIS IS AN EXAMPLE HERE. REPLACE THE WHOLE LINE WITH:
        --   Paste outfit (male) here by using print_current_outfit flag (client F8 console)
        components = { [1] = { texture = 0, drawable = 0, palette = 2 }, [3] = { texture = 0, drawable = 4, palette = 2 }, [4] = { texture = 1, drawable = 0, palette = 2 }, [5] = { texture = 0, drawable = 0, palette = 2 }, [6] = { texture = 0, drawable = 32, palette = 2 }, [7] = { texture = 0, drawable = 128, palette = 0 }, [8] = { texture = 0, drawable = 15, palette = 2 }, [9] = { texture = 0, drawable = 0, palette = 0 }, [10] = { texture = 0, drawable = 0, palette = 2 }, [11] = { texture = 5, drawable = 349, palette = 2 } }, props = { [0] = { texture = -1, drawable = -1 }, [1] = { texture = -1, drawable = -1 }, [2] = { texture = -1, drawable = -1 }, [6] = { texture = -1, drawable = -1 }, [7] = { texture = -1, drawable = -1 } }
    },
    lab_coat_f = {
        -- THIS IS AN EXAMPLE HERE. REPLACE THE WHOLE LINE WITH:
        --   Paste outfit (female) here by using print_current_outfit flag (client F8 console)
        components = { [1] = { texture = 0, drawable = 0, palette = 0 }, [3] = { texture = 0, drawable = 0, palette = 0 }, [4] = { texture = 0, drawable = 76, palette = 0 }, [5] = { texture = 0, drawable = 0, palette = 0 }, [6] = { texture = 0, drawable = 118, palette = 0 }, [7] = { texture = 0, drawable = 98, palette = 0 }, [8] = { texture = 0, drawable = 7, palette = 0 }, [9] = { texture = 0, drawable = 0, palette = 0 }, [10] = { texture = 0, drawable = 0, palette = 0 }, [11] = { texture = 0, drawable = 367, palette = 0 } }, props = { [0] = { texture = -1, drawable = -1 }, [1] = { texture = -1, drawable = -1 }, [2] = { texture = -1, drawable = -1 }, [6] = { texture = -1, drawable = -1 }, [7] = { texture = -1, drawable = -1 } }
    },
    scuba_m = {
        -- THIS IS AN EXAMPLE HERE. REPLACE THE WHOLE LINE WITH:
        --   Paste outfit (female) here by using print_current_outfit flag (client F8 console)
        components = { [1] = { texture = 0, drawable = 0, palette = 2 }, [3] = { texture = 0, drawable = 4, palette = 2 }, [4] = { texture = 0, drawable = 143, palette = 2 }, [5] = { texture = 0, drawable = 0, palette = 2 }, [6] = { texture = 0, drawable = 67, palette = 2 }, [7] = { texture = 0, drawable = 0, palette = 0 }, [8] = { texture = 0, drawable = 15, palette = 2 }, [9] = { texture = 0, drawable = 0, palette = 0 }, [10] = { texture = 0, drawable = 0, palette = 2 }, [11] = { texture = 0, drawable = 431, palette = 2 } }, props = { [0] = { texture = -1, drawable = -1 }, [1] = { texture = -1, drawable = -1 }, [2] = { texture = -1, drawable = -1 }, [6] = { texture = -1, drawable = -1 }, [7] = { texture = -1, drawable = -1 } }
    },
    scuba_f = {
        -- THIS IS AN EXAMPLE HERE. REPLACE THE WHOLE LINE WITH:
        --   Paste outfit (female) here by using print_current_outfit flag (client F8 console)
        components = { [1] = { texture = 0, drawable = 0, palette = 0 }, [3] = { texture = 0, drawable = 4, palette = 0 }, [4] = { texture = 8, drawable = 97, palette = 0 }, [5] = { texture = 0, drawable = 0, palette = 0 }, [6] = { texture = 0, drawable = 70, palette = 0 }, [7] = { texture = 0, drawable = 0, palette = 0 }, [8] = { texture = 0, drawable = 15, palette = 0 }, [9] = { texture = 0, drawable = 0, palette = 0 }, [10] = { texture = 0, drawable = 0, palette = 0 }, [11] = { texture = 0, drawable = 342, palette = 0 } }, props = { [0] = { texture = -1, drawable = -1 }, [1] = { texture = -1, drawable = -1 }, [2] = { texture = -1, drawable = -1 }, [6] = { texture = -1, drawable = -1 }, [7] = { texture = -1, drawable = -1 } }
    }
}
Config.zones = {
    global_zone_coords = vec3(3526.6445, 3721.6362, 36.6426),
    global_zone_radius = 400.0,

    perimeter_poly = {
        vec3(3404.2625, 3642.4021, 47.2986),
        vec3(3586.0642, 3608.7810, 47.2762),
        vec3(3584.4426, 3601.0420, 47.2761),
        vec3(3610.4353, 3596.1858, 47.2213),
        vec3(3616.7817, 3632.5022, 46.5606),
        vec3(3619.8550, 3649.3650, 42.3656),
        vec3(3608.2788, 3651.7368, 42.3686),
        vec3(3615.3696, 3692.9404, 41.7713),
        vec3(3651.3801, 3729.4221, 41.7667),
        vec3(3651.3792, 3731.7900, 41.7548),
        vec3(3644.8501, 3737.1416, 36.5283),
        vec3(3648.4685, 3761.2234, 35.6212),
        vec3(3640.6165, 3783.4993, 35.6182),
        vec3(3627.2505, 3803.0210, 35.6196),
        vec3(3610.3447, 3816.3254, 35.6069),
        vec3(3588.0513, 3818.7788, 35.9348),
        vec3(3501.7429, 3821.1604, 37.7745),
        vec3(3478.3718, 3814.0784, 37.8039),
        vec3(3463.4302, 3801.6716, 37.8095),
        vec3(3456.2979, 3785.0571, 37.7882),
        vec3(3431.6626, 3773.6995, 30.5476),
        vec3(3440.2661, 3753.7720, 30.6430),
        vec3(3431.7869, 3748.8174, 30.9273),
        vec3(3409.9160, 3676.1790, 47.4474)
    },
    perimeter_thickness = 55.0,

    lab_entry_warning_coords = vec3(3606.7385, 3711.6802, 29.6894),
    lab_entry_warning_size = vec3(5.0, 7.55, 2.0),
    lab_entry_warning_rotation = 325.2532,
    lab_entry_trigger_coords = vec3(3602.4026, 3705.2936, 29.6894),
    lab_entry_trigger_size = vec3(5.0, 7.55, 2.0),
    lab_entry_trigger_rotation = 325.2532,

    lab_zone_coords = vec3(3561.2, 3672.6758, 29.0),
    lab_zone_size = vec3(6.0, 9.0, 5.0),
    lab_zone_rotation = 350.0,

    elevator_target_enabled = true, -- Sometimes no native elevator exists, so this is an alternative elevator
    elevator_top_zone_coords = vec3(3540.7695, 3676.3013, 28.5),
    elevator_top_zone_size = vec3(3.5, 2.5, 3.0),
    elevator_top_zone_rotation = 349.0,
    elevator_top_spawn = vec4(3540.4463, 3675.2473, 27.1211, 171.6435),
    elevator_bottom_zone_coords = vec3(3540.7336, 3676.34, 21.3),
    elevator_bottom_zone_size = vec3(3.5, 2.5, 3.0),
    elevator_bottom_zone_rotation = 349.0,
    elevator_bottom_spawn = vec4(3540.6404, 3675.5139, 19.9918, 169.1046),
}
Config.framework = {
    inventory = {
        use_auto = true,
        use_ox_inventory = false,
        use_custom = false,
        custom = {
            get_item_count = function(target, item, metadata) return 0 end, -- Server fn(target, item, metadata) and Client fn(item, metadata)
            add_item = function(target, item, amount, metadata) end, -- Server only, on fail uses notify
            remove_item = function(target, item, amount) end, -- Server only
            can_carry_item = function(target, item, amount) end, -- Server only
        }
    },
    notify = {
        use_auto = true,
        use_ox_lib = false, -- Make sure to include '@ox_lib/init.lua' in shared_scripts of fxmanifest.lua if using ox
        use_custom = false,
        custom = {
            notify = function(target, title, description) end, -- Server only
            progress_bar = function(duration, label, can_cancel, disable_move) end, -- Client only
        }
    },
    target = {
        use_auto = true,
        use_ox_target = false, -- Make sure to include '@ox_lib/init.lua' in shared_scripts of fxmanifest.lua if using ox
        use_proximity = false, -- No library, fully native
        use_custom = false,
        custom = {
            -- To understand parameters look at definition of ox_target:addBoxZone and ox_target:addLocalEntity(data)
            dependencies_ready = function() return true end, -- True if no libraries required

            -- Areas:
            add_box_zone = function(data) end, -- Client only
            add_local_entity = function(entity, data) end, -- Client only
            remove_area = function(id) end, -- Client only

            -- Zones:
            poly = function(data) end, -- Client only
            box = function(data) end, -- Client only
            sphere = function(data) end, -- Client only
            remove_zone = function(zone) end -- Client only
        }
    }
}


----------- Suspicion -----------
Config.suspicion_panel = {
    vignette_effect = true,
    position = {
        left = "0.0px", -- css
        top = "0.0px", -- css
        scale = 1.0, -- test on multiple screens after changing
        justify_h = "center", -- left, center, right
        justify_v = "top", -- top, center, bottom
    },
    theme = {
        -- For each level you can add and modify the following properties:
        --   color = 'rgba(138,184,160,1)',
        --   color_dim = 'rgba(58,90,72,1)',
        --   color_glow = 'rgba(138,184,160,0.12)',
        --   bg_color = 'rgba(4,12,8,0.78)',
        --   border_color = 'rgba(138,184,160,0.28)',
        --   icon = '◈',
        --   bar_count = 0,
        --   scan_speed = 0.12,
        --   ring_count = 0,
        --   pulse_speed = 0,
        --   icon_scale = 1.0,
        --   blink_rate = 0,
        --   rotate_icon = false,
        --   shake_icon = false,
        levels = { -- Golden Theme
            [0] = { -- Undetected
                -- color = 'rgba(207,168,73,1)',
            },
            [1] = { -- Restricted Area
            },
            [2] = { -- Suspicious Activity
            },
            [3] = { -- Spotted
            },
            [4] = { -- Alarm
            }
        },
        background = {
            shape = 'hexagon', -- hexagon, triangle, square, dots, lines, none
            size = 12,
            opacity = 0.03,
            scroll_speed = 8,
            line_width = 0.5
        },
        particles = {
            enabled = true,
            count = 10,
            size_min = 0.8,
            size_max = 1.8,
            opacity_min = 0.08,
            opacity_max = 0.2
        }
    }
}


----------- Triggers -----------
Config.triggers = {
    on_raid_started = function(players, started_silent)
        -- print("Human labs raid started")
    end,
    on_raid_end = function(maximum_players_raiding, each_players_px41_amount_crafted, total_stolen_px41, total_time_raiding_ms, time_players_stood_silent_ms, time_after_alarm_trigger_ms, players_stayed_fully_silent, permit_was_used)
        -- Use total_stolen_px41 for leaderboards e.g.; or generally to inform police as a dispatch that the raid is done
        -- If players are still in the territory but dead or knocked down, this will NOT be seen as ending the raid
        -- print("Human labs raid performed by " .. tostring(maximum_players_raiding) .. " players, who stole " .. tostring(total_stolen_px41) .. " PX41")
    end,
    on_security_alarm_trigger = function(players_inside, number_of_players)
        -- print("Human labs security alarm was triggered with " .. tostring(number_of_players) .. " suspects")
    end,
    on_transporter_robbing = function(player, fivem_player_name, vehicle, vehicle_location)
        -- print("Transporter being robbed by " .. tostring(fivem_player_name))
    end,

    --- Fine grain triggers
    on_first_player_enter = function(player) end,
    on_last_player_exited = function() end,
    on_permit_activated = function() end,
    on_px41_gas_extraction = function(player, quality, total_produced_so_far) end,
    on_px41_compression = function(player, quality, total_produced_so_far) end,
    on_px41_packaging = function(player, quality, total_produced_so_far) end
}


----------- NPC -----------
Config.entry_attendant = {
    permit_item = 'labpermit',
    ped_model = 'ig_joeminuteman',
    location = vec4(3430.9600, 3763.7102, 29.85, 209.9357),
}
Config.entry_waver = {
    ped_model = 's_m_m_armoured_01',
    location = vec4(3421.2158, 3759.0042, 29.5591, 212.1312), -- Entrance
}
Config.scientist = {
    ped_model = 's_m_m_doctor_01',
    smoking_location = vec4(3605.8801, 3729.4133, 28.6894, 325.7733), -- In garage smoking
    patrolling = {
        number_of_active = 5,
        delay_between_ms = 35000,
        delete_anyway_time = 5*60*1000, -- 5min

        -- Takes 95 seconds from start to finish
        start_location = vec4(3594.4143, 3705.6697, 28.6894, 65.0107), -- Some door close to garage entry
        end_location = vec4(3541.4780, 3667.5422, 28.1219, 268.9370), -- Microscope near end
    }
}
Config.lab_entry_attendant = {
    ped_model = 'a_m_m_prolhost_01',
    location = vec4(3608.2798, 3715.4568, 29.6894, 328.0005), -- right after garage
    heading_normal = 328.0,
    heading_backwards = 185.0,
}


----------- SECURITY -----------
Config.security = {
    player_ignored_by_security = function(player_ped) -- Server and Client sided
        -- Jobs can be ignored such as police, medics, or admins
        --   Static i.e. only called once player enters human labs general area
        --   Use your framework and return true if player should be ignored, e.g.:
        --
        -- return QBCore.Functions.GetPlayerData(player_ped).job.name == 'police'
        -- if IsDuplicityVersion() then
        --     return exports["es_extended"]:getSharedObject().GetPlayerFromId(player_ped).job.name == 'police'
        -- else
        --     return exports["es_extended"]:getSharedObject().GetPlayerData().job.name == 'police'
        -- end
        -- return false
        return false
    end,
    disable_alarm = function(all_players_inside) -- Server sided
        -- Any sirens from police, medics or other could trigger alarm to stop
        -- Runs dynamically i.e. encapsulated in a thread (50ms)
        -- for src, _ in pairs(all_players_inside) do
        --     local ped = GetPlayerPed(src)
        --     if ped and ped ~= 0 and Config.security.player_ignored_by_security(src) then
        --         local vehicle = GetVehiclePedIsIn(ped, false)
        --         if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        --             if IsVehicleSirenOn(vehicle) then
        --                 return true
        --             end
        --         end
        --     end
        -- end
        -- return false
        return false
    end,
    max_combat_peds = 30, -- Will spawn initial combat peds either way, but limits infinitely spawning ones
    ped_model = 's_m_m_armoured_01',
    accuracy = 30, -- 0-100
    weapon = 'WEAPON_PISTOL',
    static_ped_locations = {
        vec4(3473.9810, 3781.7734, 29.4546, 112.9179), -- Entrance
        -- vec4(3474.9941, 3784.4866, 29.6031, 106.9323), -- Entrance
        -- vec4(3458.9214, 3763.6814, 42.3692, 101.3604), -- Entrance sniper position
        vec4(3418.5950, 3683.9182, 40.4, 350.6172), -- Right side of entry
        vec4(3429.4580, 3681.9978, 40.4, 343.9764), -- Right side of entry
        vec4(3622.5510, 3729.1318, 27.8, 19.5056), -- Garage entry
        -- vec4(3609.8049, 3729.9163, 28.8, 300.8600), -- Garage entry
        -- vec4(3610.0847, 3713.5151, 28.8, 327.9757), -- Garage entry
        vec4(3484.8018, 3814.8306, 29.6649, 152.4419), -- Road to garage
        vec4(3530.9722, 3804.7363, 29.4327, 84.2983), -- Road to garage
        vec4(3613.0376, 3764.1638, 29.8206, 259.1208), -- Cheeky angle towards garage
        vec4(3637.2468, 3749.1431, 27.5157, 74.2863), -- In front of garage
        vec4(3636.6875, 3748.0547, 27.5157, 69.8173), -- In front of garage
    },
    inside_building_ped_locations = {
        vec4(3601.0498, 3702.7766, 29.6894, 324.9755),
        vec4(3593.5718, 3713.2920, 28.6894, 352.4206),
        vec4(3598.2180, 3691.7991, 27.8214, 53.3011),
        vec4(3589.9988, 3684.4258, 26.6215, 300.3584),
        vec4(3572.7688, 3694.0203, 26.1220, 235.2735),
        vec4(3550.3193, 3656.0010, 27.1219, 336.6905), -- after lab
        vec4(3529.6047, 3655.2065, 26.5216, 191.8106), -- after lab
        vec4(3531.2427, 3669.0200, 27.1215, 177.1429), -- after lab
        vec4(3540.7913, 3670.3301, 27.1212, 79.5074), -- after lab
    },
    patrolling_ped_locations = {
        vec4(3597.9536, 3787.8330, 29.0, 83.1684), -- Parking lot
        -- vec4(3570.5886, 3769.0500, 29.0, 135.2743), -- Parking lot
        vec4(3519.2593, 3782.5078, 29.0, 121.2258), -- Parking lot
        -- vec4(3479.7275, 3772.0667, 29.1, 262.1909), -- Parking lot
        -- vec4(3457.2996, 3727.3628, 35.7, 234.8904), -- Near building 4
        -- vec4(3528.0002, 3727.3672, 35.5, 335.3977), -- Near building 2
        -- vec4(3580.4587, 3712.6895, 35.5, 244.2971), -- Near building 8
        vec4(3569.8323, 3677.7134, 40.0019, 113.1960), -- Other side of garage
        -- vec4(3597.5171, 3640.0771, 40.3404, 55.4422), -- Other side of garage
        vec4(3577.9277, 3816.2603, 30.4243, 169.0180), -- On the way to garage
    },

    -- Must be in the same interior. Peds become invisible when spawned outside of garage and move through garage inside of building
    endless_spawn = {
        vec4(3599.9219, 3699.6885, 29.6894, 345.6970), -- Elevator near garage
        vec4(3597.7456, 3696.4902, 28.8214, 147.9614), -- Elevator mid way
        vec4(3561.5212, 3688.8611, 28.1217, 255.6342), -- Elevator inside left
        vec4(3562.0088, 3691.8071, 28.1213, 255.1658), -- Elevator inside right
        vec4(3540.0984, 3672.9707, 28.1211, 172.7576), -- Elevator at the end
    },
    min_distance_for_endless_spawn = 10.0, -- Roughly so peds don't spawn right in front of them suddenly
    spawn_rate_on_alarm = function(number_of_players)
        if number_of_players >= 5 then
            return 6000.0
        elseif number_of_players >= 3 then
            return 11000.0
        else
            return 18000.0
        end
    end,
    endless_spawn_running_target_location = vec3(3562.9551, 3673.4189, 28.1219)
}
Config.barricates = {
    model = 'prop_barrier_work06a',
    locations = {
        vec4(3421.2954, 3767.8054, 29.4898, 297.3616),
        vec4(3422.3316, 3765.8030, 29.4898, 297.3616),
        vec4(3423.3678, 3763.8007, 29.4898, 297.3616),
        vec4(3424.4041, 3761.7984, 29.4898, 297.3616),
        vec4(3425.4403, 3759.7960, 29.4898, 297.3616),
        vec4(3426.4765, 3757.7937, 29.4898, 297.3616),
        vec4(3427.5127, 3755.7913, 29.4898, 297.3616)
    }
}


----------- CRAFTING -----------
Config.crafting = {
    -- BALANCING INFORMATION:
    --   Default speed (best case): 1 extraction --[40-60secs]--> 5 PX41
    --   1 Player in 10 Minutes: 10-15 extractions --> 50-75 PX41
    --   I recommend a crafting limit of 15min for 5 players i.e. 75min for a single player
    --     which leads to 75-113 --> 375-565 total

    extraction_possible = function(number_of_gas_extractions)
        -- Run everytime an extraction is done
        -- Used to limit maximum loot or to ensure no player is hiding and grinding items nonstop
        return number_of_gas_extractions < 113 -- Not accurate: <113 leads to 115 extractions
    end,
    crafting_speed = 1.0, -- 0.75 extra slow; 1.0 default; 1.5 fast
    locations = {
        gas_containers = vec3(3563.4, 3673.4, 27.9), -- Extraction 1st minigame
        radiation_box_1 = vec3(3563.6, 3675.5, 27.9), -- Compression 2nd minigame
        radiation_box_2 = vec3(3562.7, 3670.4, 27.9),
        radiation_box_3 = vec3(3562.3, 3668.4, 27.9),
        lab_desk_1 = vec3(3559.7, 3672.9, 28.0), -- Packaging 3rd and last minigame
        lab_desk_2 = vec3(3559.9, 3673.9, 28.0),
    },
    quality_with_colors = {
        { name = 'perfect_quality', color = '#3CFCFF' },
        { name = 'high_quality', color = '#63A6A7' },
        { name = 'medium_quality', color = '#769899' },
        { name = 'low_quality', color = '#5F6363' },
    },
    gas_items = {
        perfect_quality = "px41gas_perfect_quality",
        high_quality = "px41gas_high_quality",
        medium_quality = "px41gas_medium_quality",
        low_quality = "px41gas_low_quality",
    },
    compressed_gas_items = {
        name = "compressed_px41gas",
        perfect_quality = "compressed_px41gas_perfect_quality",
        high_quality = "compressed_px41gas_high_quality",
        medium_quality = "compressed_px41gas_medium_quality",
        low_quality = "compressed_px41gas_low_quality",
    },
    packaged_gas_items = {
        name = "px41",
        perfect_quality = "px41_perfect_quality",
        high_quality = "px41_high_quality",
        medium_quality = "px41_medium_quality",
        low_quality = "px41_low_quality",
    },
    compression_gas_required = 1,
    packaging_compressed_gas_required = 1,

    extraction_effect = true,
    compression_effect = true,
    packaging_effect = true
}


----------- SCUBA -----------
Config.scuba = {
    scuba_escape_enabled = true,
    maximum_scuba_gear = 4,
    estimated_diving_time_for_escape_ms = 105*1000, -- Escape takes 1:30 min
    gear_equip_item_required = Config.crafting.gas_items,
    gear_equip_amount_required = 4, -- Good balancing to make this escape costly

    scuba_tank_model = "p_s_scuba_tank_s",
    scuba_mask_model = "p_s_scuba_mask_s",
    clothes_bag_model = "prop_cs_duffel_01",
    gear_locations = {
        {
            tank = vec4(3522.8757, 3713.2341, 19.9918, 349.967),
            mask = vec4(3522.8166, 3712.9001, 19.9918, 349.967),
            clothes_bag = vec4(3522.8757, 3713.2341, 19.9918, 349.967)
        },{
            tank = vec4(3524.0957, 3713.0164, 19.9918, 349.967),
            mask = vec4(3524.0366, 3712.6824, 19.9918, 349.967),
            clothes_bag = vec4(3524.0957, 3713.0164, 19.9918, 349.967)
        },{
            tank = vec4(3525.3374, 3712.7979, 19.9918, 349.967),
            mask = vec4(3525.2783, 3712.4639, 19.9918, 349.967),
            clothes_bag = vec4(3525.3374, 3712.7979, 19.9918, 349.967)
        },{
            tank = vec4(3526.5408, 3712.5859, 19.9918, 349.967),
            mask = vec4(3526.4817, 3712.2519, 19.9918, 349.967),
            clothes_bag = vec4(3526.5408, 3712.5859, 19.9918, 349.967)
        }
    },
    interaction_areas = {{
        coords = vec3(3522.8757, 3713.2341, 20.9918),
        size = vec3(1.0, 1.0, 1.0),
        rotation = 349.967
    },{
        coords = vec3(3524.0974, 3713.0180, 20.9918),
        size = vec3(1.0, 1.0, 1.0),
        rotation = 349.967
    },{
        coords = vec3(3525.3191, 3712.8019, 20.9918),
        size = vec3(1.0, 1.0, 1.0),
        rotation = 349.967
    },{
        coords = vec3(3526.5408, 3712.5859, 20.9918),
        size = vec3(1.0, 1.0, 1.0),
        rotation = 349.967
    }}
}


----------- TRANSPORTER -----------
Config.transporter = {
    -- Might slightly reduce performance
    -- Allows for delivery cars driving to a specific location every 15 minutes and back to human labs
    -- Makes the lab permit acquirable
    enabled = true,
    delivery_cars = {
        frequency_driving_in_sec = 15*60*1000, -- 15 Minutes
        convoy_size = 3,
        vehicle = 'boxville3',
        ped_models = {
            driver = 'a_m_m_farmer_01',
            passenger = 'cs_stevehains'
        },
        search_time = 10000,
        rob_time = 10000,
        -- This trip takes 230 seconds
        route_start = vec4(3476.3318, 3665.8723, 33.5051, 10.0),
        route_destination = vec4(2889.8984, 4378.2915, 49.8966, 293.8768)
    },
    interaction_distance = 1.5, -- 1.0 is lowest I would setup
    robbing_enabled = true,
    searching_enabled = {
        driver_seat = true,
        passenger_seat = true,
        trunk = true
    },
    loot = {
        driver_robbing = {
            {
                item = Config.entry_attendant.permit_item,
                amount = 1,
                chance = 0.6
            }
        },
        driver = {
            {
                item = Config.entry_attendant.permit_item,
                amount = 1,
                chance = 0.5
            }
        },
        passenger = {
            {
                item = Config.entry_attendant.permit_item,
                metadata = {},
                amount = 1,
                chance = 0.1
            }
        },
        trunk = {
            {
                item = Config.crafting.packaged_gas_items.perfect_quality,
                amount = 1,
                chance = 0.2,
            },{
                item = Config.crafting.packaged_gas_items.high_quality,
                custom_amount = 1,
                chance = 0.6,
            },{
                item = Config.crafting.packaged_gas_items.medium_quality,
                custom_amount = function()
                    local rnd = math.random(10)
                    if rnd <= 2 then -- 20%
                        return 1
                    elseif rnd <= 6 then -- 40%
                        return 2
                    elseif rnd <= 9 then -- 30%
                        return 3
                    else -- 10%
                        return 4
                    end
                end,
            },{
                item = Config.crafting.packaged_gas_items.low_quality,
                custom_amount = function()
                    return math.random(3, 11)
                end,
            }
        }
    }
}


----------- DEBUG -----------
Config.debug_poly = Config.debug
Config.debug_enemies = Config.debug
Config.access_not_required = Config.debug
Config.reconnect_teleport_outside = not Config.debug
