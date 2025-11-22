Config = {}

-- Framework Selection: 'qbcore', 'qbx', 'esx'
Config.Framework = 'qbcore' -- Auto-detects if set to 'auto'

-- Core Settings
Config.UseTarget = true -- Use targeting system (qb-target/ox_target)
Config.UseOxLib = true -- Use ox_lib for menus and notifications
Config.PlanningBoardCooldown = 3600 -- Cooldown in seconds (1 hour)
Config.MinimumCrew = 2 -- Minimum crew members required
Config.MaximumCrew = 6 -- Maximum crew members allowed
Config.PoliceJobName = 'police' -- Police job name
Config.MinPolice = 2 -- Minimum police required online

-- Notification Settings
Config.NotificationDuration = 5000 -- Duration in milliseconds

-- Planning Board Locations
Config.PlanningBoards = {
    {
        name = "planning_board_1",
        coords = vector3(1275.63, -1720.93, 54.65),
        heading = 120.0,
        blip = {
            enabled = true,
            sprite = 486,
            color = 1,
            scale = 0.7,
            label = "Heist Planning"
        }
    },
    {
        name = "planning_board_2",
        coords = vector3(-1159.45, -2217.83, 13.16),
        heading = 45.0,
        blip = {
            enabled = true,
            sprite = 486,
            color = 1,
            scale = 0.7,
            label = "Heist Planning"
        }
    }
}

-- Available Heist Locations
Config.HeistLocations = {
    {
        id = "fleeca_main",
        label = "Fleeca Bank - Legion Square",
        difficulty = "easy",
        coords = vector3(147.46, -1046.11, 29.37),
        requiredCrew = 2,
        approaches = {"stealth", "loud"},
        equipment = {
            {item = "drill", label = "Thermal Drill", price = 5000, required = true},
            {item = "thermite", label = "Thermite Charge", price = 3000, required = false},
            {item = "hackerdevice", label = "Hacking Device", price = 4000, required = true},
            {item = "duffle_bag", label = "Duffle Bag", price = 500, required = true},
        },
        rewards = {
            min = 15000,
            max = 35000,
            items = {
                {item = "goldbar", min = 1, max = 3, chance = 30},
                {item = "rolex", min = 1, max = 5, chance = 50},
                {item = "markedbills", min = 2, max = 6, chance = 70},
            }
        },
        hackTime = 30,
        drillTime = 45,
        copAlertChance = 75,
        cooldown = 3600, -- 1 hour
    },
    {
        id = "fleeca_highway",
        label = "Fleeca Bank - Great Ocean Highway",
        difficulty = "easy",
        coords = vector3(-2957.6, 481.45, 15.69),
        requiredCrew = 2,
        approaches = {"stealth", "loud"},
        equipment = {
            {item = "drill", label = "Thermal Drill", price = 5000, required = true},
            {item = "hackerdevice", label = "Hacking Device", price = 4000, required = true},
            {item = "duffle_bag", label = "Duffle Bag", price = 500, required = true},
        },
        rewards = {
            min = 12000,
            max = 30000,
            items = {
                {item = "goldbar", min = 1, max = 2, chance = 25},
                {item = "rolex", min = 1, max = 4, chance = 45},
                {item = "markedbills", min = 2, max = 5, chance = 65},
            }
        },
        hackTime = 30,
        drillTime = 45,
        copAlertChance = 70,
        cooldown = 3600,
    },
    {
        id = "jewelry_vangelico",
        label = "Vangelico Jewelry Store",
        difficulty = "medium",
        coords = vector3(-622.29, -230.77, 38.06),
        requiredCrew = 3,
        approaches = {"smash_grab", "stealth", "loud"},
        equipment = {
            {item = "crowbar", label = "Crowbar", price = 500, required = false},
            {item = "duffle_bag", label = "Duffle Bag (x3)", price = 600, required = true},
            {item = "glasscutter", label = "Glass Cutter", price = 2500, required = false},
            {item = "thermite", label = "Thermite", price = 3500, required = true},
        },
        rewards = {
            min = 25000,
            max = 55000,
            items = {
                {item = "diamond", min = 1, max = 5, chance = 25},
                {item = "goldchain", min = 2, max = 8, chance = 60},
                {item = "rolex", min = 3, max = 10, chance = 80},
                {item = "diamond_ring", min = 1, max = 6, chance = 45},
            }
        },
        hackTime = 25,
        grabTime = 120,
        copAlertChance = 85,
        cooldown = 5400, -- 1.5 hours
    },
    {
        id = "paleto_bank",
        label = "Paleto Bay Bank",
        difficulty = "hard",
        coords = vector3(-104.71, 6472.39, 31.63),
        requiredCrew = 4,
        approaches = {"loud", "stealth"},
        equipment = {
            {item = "drill", label = "Heavy Duty Drill", price = 8000, required = true},
            {item = "thermite", label = "Thermite (x2)", price = 6000, required = true},
            {item = "hackerdevice", label = "Advanced Hacking Device", price = 7000, required = true},
            {item = "body_armor", label = "Heavy Body Armor", price = 3000, required = false},
            {item = "weapon_assaultrifle", label = "Assault Rifles (Team)", price = 15000, required = false},
        },
        rewards = {
            min = 50000,
            max = 120000,
            items = {
                {item = "goldbar", min = 3, max = 10, chance = 55},
                {item = "diamond", min = 1, max = 6, chance = 35},
                {item = "markedbills", min = 5, max = 20, chance = 100},
                {item = "rolex", min = 3, max = 12, chance = 70},
            }
        },
        hackTime = 45,
        drillTime = 60,
        copAlertChance = 95,
        cooldown = 7200, -- 2 hours
    },
    {
        id = "pacific_standard",
        label = "Pacific Standard Bank",
        difficulty = "extreme",
        coords = vector3(255.24, 220.72, 106.28),
        requiredCrew = 6,
        approaches = {"loud"},
        equipment = {
            {item = "drill", label = "Military Grade Drill", price = 15000, required = true},
            {item = "thermite", label = "Thermite (x4)", price = 12000, required = true},
            {item = "hackerdevice", label = "Military Hacking Device", price = 15000, required = true},
            {item = "body_armor", label = "Heavy Body Armor (Team)", price = 8000, required = true},
            {item = "weapon_assaultrifle", label = "Assault Rifles (Team)", price = 25000, required = true},
            {item = "electronickit", label = "Electronic Bypass Kit", price = 10000, required = true},
        },
        rewards = {
            min = 150000,
            max = 350000,
            items = {
                {item = "goldbar", min = 10, max = 25, chance = 80},
                {item = "diamond", min = 5, max = 15, chance = 60},
                {item = "markedbills", min = 20, max = 50, chance = 100},
                {item = "rolex", min = 10, max = 30, chance = 90},
            }
        },
        hackTime = 60,
        drillTime = 90,
        copAlertChance = 100,
        cooldown = 10800, -- 3 hours
    }
}

-- Heist Approach Modifiers
Config.ApproachModifiers = {
    stealth = {
        label = "Stealth Approach",
        description = "Sneak in quietly, lower cop alert chance but takes longer",
        copAlertModifier = -20,
        timeModifier = 1.5,
        rewardModifier = 1.3,
        icon = "🤫",
    },
    loud = {
        label = "Loud & Fast",
        description = "Go in guns blazing, faster but higher police response",
        copAlertModifier = 15,
        timeModifier = 0.8,
        rewardModifier = 1.0,
        icon = "💥",
    },
    smash_grab = {
        label = "Smash & Grab",
        description = "Quick and dirty, get in and out as fast as possible",
        copAlertModifier = 10,
        timeModifier = 0.6,
        rewardModifier = 0.85,
        icon = "⚡",
    }
}

-- Reputation System
Config.Reputation = {
    enabled = true,
    levels = {
        {min = 0, max = 100, label = "Novice Thief", unlocks = {"fleeca_main", "fleeca_highway"}},
        {min = 101, max = 500, label = "Amateur Criminal", unlocks = {"fleeca_main", "fleeca_highway", "jewelry_vangelico"}},
        {min = 501, max = 1500, label = "Professional Robber", unlocks = {"fleeca_main", "fleeca_highway", "jewelry_vangelico", "paleto_bank"}},
        {min = 1501, max = 5000, label = "Expert Heister", unlocks = {"fleeca_main", "fleeca_highway", "jewelry_vangelico", "paleto_bank", "pacific_standard"}},
        {min = 5001, max = 999999, label = "Legendary Mastermind", unlocks = {"fleeca_main", "fleeca_highway", "jewelry_vangelico", "paleto_bank", "pacific_standard"}},
    },
    gainOnSuccess = {
        easy = 25,
        medium = 60,
        hard = 120,
        extreme = 250,
    },
    loseOnFail = {
        easy = 10,
        medium = 25,
        hard = 50,
        extreme = 100,
    }
}

-- Minigame Settings
Config.Minigames = {
    hack = {
        difficulty = {
            easy = {blocks = 5, time = 20},
            medium = {blocks = 7, time = 18},
            hard = {blocks = 9, time = 15},
            extreme = {blocks = 12, time = 12},
        }
    },
    drill = {
        difficulty = {
            easy = {duration = 30000},
            medium = {duration = 45000},
            hard = {duration = 60000},
            extreme = {duration = 90000},
        }
    },
    thermite = {
        difficulty = {
            easy = {gridSize = 6, timeToShow = 10, timeToLose = 15},
            medium = {gridSize = 7, timeToShow = 8, timeToLose = 12},
            hard = {gridSize = 8, timeToShow = 6, timeToLose = 10},
            extreme = {gridSize = 10, timeToShow = 4, timeToLose = 8},
        }
    }
}

-- Language
Config.Language = {
    -- General
    ["planning_board"] = "Heist Planning Board",
    ["open_board"] = "Open Planning Board",
    ["press_to_interact"] = "[E] Open Planning Board",
    
    -- Notifications
    ["not_enough_police"] = "Not enough police in the city (%s/%s required)",
    ["heist_cooldown"] = "This location is too hot right now. Come back in %s minutes",
    ["need_more_crew"] = "You need at least %s crew members for this heist",
    ["crew_full"] = "The crew is already full",
    ["not_enough_money"] = "You don't have enough money to purchase this equipment",
    ["equipment_purchased"] = "Equipment purchased: %s",
    ["heist_started"] = "The heist has begun! Get to the location marked on your GPS!",
    ["heist_success"] = "Heist completed successfully! You earned $%s",
    ["heist_failed"] = "The heist failed! Better luck next time",
    ["police_alerted"] = "🚨 The police have been alerted to your location!",
    ["invite_sent"] = "Crew invitation sent",
    ["no_player_nearby"] = "No players nearby",
    ["joined_crew"] = "You joined the heist crew",
    ["crew_member_joined"] = "%s joined the crew",
    ["heist_planning_started"] = "Heist planning started! Recruit your crew",
    ["rep_gained"] = "Reputation gained: +%s (Total: %s)",
    ["rep_lost"] = "Reputation lost: -%s (Total: %s)",
    ["insufficient_rep"] = "Your reputation is too low for this heist",
    
    -- Menu Headers
    ["reputation_display"] = "Reputation: %s (%s pts)",
    ["select_heist"] = "Select a Heist",
    ["select_approach"] = "Select Approach",
    ["equipment_shop"] = "Equipment Shop",
    ["crew_management"] = "Crew Management",
    ["heist_details"] = "Heist Details",
    
    -- Menu Options
    ["back"] = "⬅ Back",
    ["close"] = "❌ Close",
    ["confirm"] = "✅ Confirm",
    ["invite_player"] = "📞 Invite Player",
    ["start_heist"] = "🚀 Start Heist",
    ["cancel_heist"] = "❌ Cancel Heist",
    ["purchase_equipment"] = "💰 Purchase Equipment",
    ["view_crew"] = "👥 View Crew (%s/%s)",
    
    -- Heist Info
    ["difficulty"] = "Difficulty: %s",
    ["required_crew"] = "Required Crew: %s+",
    ["payout_range"] = "Payout: $%s - $%s",
    ["approach_type"] = "Approach: %s",
    ["equipment_required"] = "Required Equipment",
    ["optional_equipment"] = "Optional Equipment",
    
    -- Police
    ["police_alert_title"] = "🚨 ROBBERY IN PROGRESS",
    ["police_alert_message"] = "%s - Armed suspects reported!",
    
    -- Progress Bars
    ["hacking_system"] = "Hacking security system...",
    ["drilling_vault"] = "Drilling vault door...",
    ["placing_thermite"] = "Placing thermite charge...",
    ["grabbing_loot"] = "Grabbing valuables...",
    ["loading_equipment"] = "Loading equipment...",
}

-- Debug Mode
Config.Debug = false -- Enable debug prints