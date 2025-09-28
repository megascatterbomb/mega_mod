// Credit to Mr. Burguers for figuring this out and sharing how to do it in the TF2Maps discord.

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


    // OVERRIDE: tf2ware_ultimate/dev.nut::Ware_DevCommands["nextspecial"]
    // Allows "double_trouble" to be forced with up to 5 specified special rounds.
    ::Ware_DevCommands["nextspecial"] <- function (player, text)
    {
        local args = split(text, " ")
        if (args.len() >= 1)
        {
            if (args.len() >= 2)
            {
                Ware_DebugNextSpecialRound = "double_trouble"
                Ware_DebugNextSpecialRound2 = args
            }
            else if (args[0] == "any1" || args[0] == "any")
            {
                Ware_ForceSpecialRound()
            }
            else if (args[0] == "multiple") {
                Ware_DebugNextSpecialRound = "double_trouble";
                ::Ware_DoubleTroubleSpecialRoundCount <- 0
            }
            else if (args[0] == "any2" || args[0] == "double_trouble")
            {
                Ware_DebugNextSpecialRound = "double_trouble";
                ::Ware_DoubleTroubleSpecialRoundCount <- 2;
            }
            else if (args[0] == "any3" || args[0] == "oh_baby_a_triple")
            {
                Ware_DebugNextSpecialRound = "double_trouble";
                ::Ware_DoubleTroubleSpecialRoundCount <- 3;
            }
            else if (args[0] == "any4" || args[0] == "quad")
            {
                Ware_DebugNextSpecialRound = "double_trouble";
                ::Ware_DoubleTroubleSpecialRoundCount <- 4;
            }
            else if (args[0] == "any5" || args[0] == "what_have_you_done")
            {
                Ware_DebugNextSpecialRound = "double_trouble";
                ::Ware_DoubleTroubleSpecialRoundCount <- 5;
            }
            else
            {
                Ware_DebugNextSpecialRound = args[0]
            }
        }
        else
        {
            Ware_DebugNextSpecialRound = ""
        }
        Ware_ChatPrint(null, "{str} forced next special round to '{str}'", Ware_DevCommandTitle(player), Ware_DebugNextSpecialRound)
    }
}

mega.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
::ClearGameEventCallbacks <- function () {
    mega.ClearGameEventCallbacks()
    ::__CollectGameEventCallbacks(mega)
}
::__CollectGameEventCallbacks(mega);