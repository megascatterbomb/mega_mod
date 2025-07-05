// Credit to Mr. Burguers for figuring this out and sharing how to do it in the TF2Maps discord.

local root = getroottable()
local prefix = DoUniqueString("mega")
local mega = root[prefix] <- {}

mega.OnGameEvent_teamplay_round_start <- function (event) {
    printl("MEGAMOD: Loading custom arena_perks logic...");
    EntFireByHandle(mainLogicEntity, "RunScriptCode", "MegaModRoundStart()", 0, null, null);
}

function MegaModRoundStart() {

    if(IsInWaitingForPlayers()) return;

    IncludeScript("mega_mod/mapmods/arena_perks/overrides.nut");

    // Can't override the logic_script changing the game state so have to do this terribleness to
    // clean up the gamestate at the start of the round.

    // Remove all the perks
    foreach (manager in ::PerkGamemode.PerkManagers) {
        foreach (i, perkInfo in manager.RolledPerks) {
            local prop = Entities.FindByName(null, "p_"+perkInfo.perk.Identifier+"_"+TeamName(manager.Team)+"_prop");

            EntFireByHandle(prop, "Kill", "", 0, null, null);
            perkInfo.name.Destroy();
            perkInfo.description.Destroy();
        }
        manager.PerkPool = clone PERK_LIST;
        manager.RolledPerks.clear();
        manager.ActivePerks.clear();
    }
    // Re-enter the gamestate (this time with our overrides in place)
    ::PerkGamemode.CurrentState = "";
    ::PerkGamemode.ChangeState("vote");

    // Fix >32 players appearing inside the arena at the start of a new match.
    local redSpawn =  Vector(0.0, 5180.0, 160.0);
    local blueSpawn = Vector(0.0, -5180.0, 160.0);
    // These angles are backwards from what cl_showpos 1 suggests should be the case.
    local redAngles = QAngle(0, -90, 0);
    local blueAngles = QAngle(0, 90, 0);
    for (local i = 1; i <= MaxClients().tointeger() ; i++)
    {
        local player = PlayerInstanceFromIndex(i);
        if (player == null) continue;
        if(player.GetTeam() == Constants.ETFTeam.TF_TEAM_RED && player.GetOrigin().y < 4000) {
            player.SetAbsOrigin(redSpawn);
            player.SetAbsAngles(redAngles);
        } else if(player.GetTeam() == Constants.ETFTeam.TF_TEAM_BLUE && player.GetOrigin().y > -4000) {
            player.SetAbsOrigin(blueSpawn);
            player.SetAbsAngles(blueAngles);
        }
    }
}

::MOST_RECENT_DEATH_TEAM <- 0;

mega.OnGameEvent_player_death <- function (params) {
    if (!(::PerkGamemode.CurrentState == "round") || (params.death_flags & 32))
        return;
    local player = GetPlayerFromUserID(params.userid)
    local team = player.GetTeam();
    ::MOST_RECENT_DEATH_TEAM <- team;
}

mega.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
::ClearGameEventCallbacks <- function () {
    mega.ClearGameEventCallbacks()
    ::__CollectGameEventCallbacks(mega)
}
::__CollectGameEventCallbacks(mega);