// Credit to Mr. Burguers for figuring this out and sharing how to do it in the TF2Maps discord.

local root = getroottable();
local prefix = DoUniqueString("mega");
local mega = root[prefix] <- {};

if (MM_ModIsEnabled("5cp_anti_stalemate")) IncludeScript("mega_mod/common/5cp_anti_stalemate.nut");

::MM_CREDITS_RED <- 0;
::MM_CREDITS_BLU <- 0;

::MM_FREAKY_FAIR_ACTIVE <- false;

mega.OnGameEvent_teamplay_round_start <- function (event) {
    printl("MEGAMOD: Loading custom cp_freaky_fair logic...");

    ::MegaModRoundStart <- function () {
        if(IsInWaitingForPlayers()) return;

        // For reasons beyond my comprehension, the freaky_fair vscript is attached to an info_target.
        // This means the script only runs *once* when the map loads, meaning that if the line of code
        // below runs more than once, we end up assigning our AwardCreditsToTeam to the base handle as well,
        // creating an infinite loop. https://developer.valvesoftware.com/wiki/Info_target
        if (MM_FREAKY_FAIR_ACTIVE == false)
            AwardCreditsToTeamBase <- AwardCreditsToTeam;

        ::MM_FREAKY_FAIR_ACTIVE <- true;

        // Track credits awarded during the round.
        AwardCreditsToTeam <- function (team, amount)
        {
            if (team == Constants.ETFTeam.TF_TEAM_RED) {
                ::MM_CREDITS_RED <- MM_CREDITS_RED + amount;
            } else if (team == Constants.ETFTeam.TF_TEAM_BLUE) {
                ::MM_CREDITS_BLU <- MM_CREDITS_BLU + amount;
            }
            printl("Added " + amount + " credits to team " + team);
            AwardCreditsToTeamBase(team, amount);
        }.bindenv(MM_GetEntByName("scripto").GetScriptScope());

        // Set both team's credit values to the greater of the two.
        ::MM_CREDITS_RED <- MM_CREDITS_RED > MM_CREDITS_BLU ? MM_CREDITS_RED : MM_CREDITS_BLU;
        ::MM_CREDITS_BLU <- MM_CREDITS_RED;

        AwardCreditsToTeamBase(Constants.ETFTeam.TF_TEAM_RED, MM_CREDITS_RED);
        AwardCreditsToTeamBase(Constants.ETFTeam.TF_TEAM_BLUE, MM_CREDITS_BLU);

        // Modify the canteens to be less stupid.
        ::effectsTable["kritz"] <- {
            "behaviour": function(params) { params.player.AddCondEx(TF_COND_CRITBOOSTED_CARD_EFFECT,  params.duration, params.player); },
            "resetBehaviour": function(params) {},
            "requirementsCheck": function(player) { return true; },
            "duration": 8, // was 10
            "message": "",
            "canDisguiseDuring": true,
            "playerTLK": "",
            "soundsOnUse": ["weapons/weapon_crit_charged_off.wav"],
        }

        ::effectsTable["uber"] <- {
            "behaviour": function(params) { params.player.AddCondEx(TF_COND_INVULNERABLE_CARD_EFFECT,  params.duration, params.player); },
            "resetBehaviour": function(params) {},
            "requirementsCheck": function(player) { return true; },
            "duration": 5, // was 10
            "message": "",
            "canDisguiseDuring": true,
            "playerTLK": "",
            "soundsOnUse": ["player/invulnerable_on.wav"],
        };

        // Load the 5CP anti stalemate logic.
        if (MM_ModIsEnabled("5cp_anti_stalemate")) MM_5CP_Activate();

    }.bindenv(MM_GetEntByName("scripto").GetScriptScope())

    EntFireByHandle(MM_GetEntByName("scripto"), "RunScriptCode", "MegaModRoundStart()", 0, null, null);
}

mega.OnGameEvent_post_inventory_application <- function (params) {

    local player = GetPlayerFromUserID(params.userid)

    // Initialize the melee resistance to a base value of 1 (100% resistance)
    local calculated_melee_resistance = 1

    // List of custom attributes representing different types of damage resistance
    local resistances = [
        "dmg taken from bullets reduced",
        "dmg taken from fire reduced",
        "dmg taken from blast reduced",
    ]

    // Iterate through each resistance type
    foreach(item in resistances) {

        // If the player has a non-zero resistance for this damage type, adjust the melee resistance
        if (player.GetCustomAttribute(item, 0) != 0)
            calculated_melee_resistance -= (1 - player.GetCustomAttribute(item, 0)) / 4
    }

    // Set the player's melee resistance in their script scope
    // "but kiwi, why are u using a script scope?" because this shit sucks ass and the melee damage multipler attribute is capped for god knows why
    player.GetScriptScope().meleeResistance <- calculated_melee_resistance
}

mega.OnScriptHook_OnTakeDamage <- function (params) {

    local victim = params.const_entity

    // Check if the damage type is melee
    if (params.damage_type & 128)
    {
        // Get the player's melee resistance from the script scope
        local melee_resistance = victim.GetScriptScope().meleeResistance

        // Apply the melee resistance to reduce the damage
        params.damage *= melee_resistance
    }
}


mega.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
::ClearGameEventCallbacks <- function () {
    mega.ClearGameEventCallbacks()
    ::__CollectGameEventCallbacks(mega)
}
::__CollectGameEventCallbacks(mega);