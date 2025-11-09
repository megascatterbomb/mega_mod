// Credit to Mr. Burguers for figuring out how to inject code into existing VScript scopes.

local root = getroottable();
local prefix = DoUniqueString("mega");
local mega = root[prefix] <- {};

mega.OnGameEvent_teamplay_round_start <- function (event) {
    printl("MEGAMOD: Loading custom tf2ware logic...");

    // OVERRIDE: tf2ware_ultimate/main.nut::Ware_LoadSpecialRound
    // Allow loading of special rounds from mega_mod.
    ::Ware_LoadSpecialRound <- function (file_name, player_count, is_forced)
    {
        local mm_path = format("mega_mod/mapmods/workshop/tf2ware/specialrounds/%s", file_name)
        local path = format("tf2ware_ultimate/specialrounds/%s", file_name)
        local scope = {}
        try
        {
            IncludeScript(mm_path, scope)
        }
        catch (e)  {
            try {
                IncludeScript(path, scope)
            }
            catch (e) {
                Ware_Error("Failed to load special round '%s'", file_name)
                return null
            }
        }

        local min_players = scope.special_round.min_players
        local max_players = scope.special_round.max_players
        if (player_count >= min_players && player_count <= max_players)
        {
            if (!("OnPick" in scope) || scope.OnPick())
            {
                scope.special_round.file_name = file_name
                return scope
            }
            else if (is_forced)
            {
                Ware_Error("Not loading '%s' as it rejected the pick", file_name)
            }
        }
        else if (is_forced)
        {
            if (player_count < min_players)
                Ware_Error("Not enough players to load '%s', minimum is %d", file_name, min_players)
            else
                Ware_Error("Too many players to load '%s', maximum is %d", file_name, max_players)
        }

        return null
    }

    // OVERRIDE: tf2ware_ultimate/main.nut::Ware_LoadMinigame
    // Allow loading of minigames from mega_mod.
    // WARNING: While you CAN make custom minigames with this,
    // tf2ware uses the filename of the minigame to display the overlay,
    // so if the overlay for your custom minigame doesn't exist it will just chuck a massive fuckin error on ur screen -kiwi

    ::Ware_LoadMinigame <- function (file_name, player_count, is_boss, is_forced)
    {
        local mm_path = format("mega_mod/mapmods/workshop/tf2ware/%s/%s", is_boss ? "bossgames" : "minigames", file_name)
        local path = format("tf2ware_ultimate/%s/%s", is_boss ? "bossgames" : "minigames", file_name)
        local scope = {}
        try
        {
            IncludeScript(mm_path, scope)
        }
        catch (e)
        {
            try {
                IncludeScript(path, scope)
            }
            catch (e) {
                Ware_Error("Failed to load minigame '%s'", file_name)
                return null
            }

        }

        local min_players = scope.minigame.min_players
        local max_players = scope.minigame.max_players
        if (player_count >= min_players && player_count <= max_players)
        {
            if (!("OnPick" in scope) || scope.OnPick())
            {
                scope.minigame.boss = is_boss
                scope.minigame.file_name = file_name
                return scope
            }
            else if (is_forced)
            {
                Ware_Error("Not loading '%s' as it rejected the pick", file_name)
            }
        }
        else if (is_forced)
        {
            if (player_count < min_players)
                Ware_Error("Not enough players to load '%s', minimum is %d", file_name, min_players)
            else
                Ware_Error("Too many players to load '%s', maximum is %d", file_name, max_players)
        }

        return null
    }

    // Account for my nativevotes fork triggering map changes earlier than mp_maxrounds would imply.
    if (
        Convars.IsConVarOnAllowList("sm_mapvote_instant_change") &&
        Convars.IsConVarOnAllowList("sm_mapvote_startround") &&
        Convars.GetBool("sm_mapvote_instant_change")
    ) {
        if (::Ware_MaxRounds - Convars.GetInt("sm_mapvote_startround") > 0) {
            // Adjust max_rounds down to account for early map change.
            ::Ware_MaxRounds -= Convars.GetInt("sm_mapvote_startround");
        }
        if (Ware_CurrentMapRound + 1 > ::Ware_MaxRounds) {
            // Adjust max_rounds up after an extension.
            local old_maxrounds = ::Ware_MaxRounds;
            ::Ware_MaxRounds <- old_maxrounds + Convars.GetInt("sm_extendmap_roundstep");
        }
    }
}

mega.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
::ClearGameEventCallbacks <- function () {
    mega.ClearGameEventCallbacks()
    ::__CollectGameEventCallbacks(mega)
}
::__CollectGameEventCallbacks(mega);