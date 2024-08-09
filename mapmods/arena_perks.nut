// Credit to Mr. Burguers for figuring this out and sharing how to do it in the TF2Maps discord.

printl("MEGAMOD: arena_perks.nut started")

local root = getroottable()
local prefix = DoUniqueString("mega")
local mega = root[prefix] <- {}

mega.OnGameEvent_teamplay_round_start <- function (event) {
    EntFireByHandle(mainLogicEntity, "RunScriptCode", "MegaModRoundStart()", 0, null, null);
}

function MegaModRoundStart() {

    if(IsInWaitingForPlayers()) return;

    IncludeScript("mega_mod/mapmods/arena_perks_overrides.nut");

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
}

::MOST_RECENT_DEATH_TEAM <- 0;

mega.OnGameEvent_player_death <- function (params) {
    if (!(::PerkGamemode.CurrentState == "round") || (params.death_flags & 32))
        return;
    local player = GetPlayerFromUserID(params.userid)
    local team = player.GetTeam();
    MOST_RECENT_DEATH_TEAM <- team;
    printl("MEGAMOD: Death registered for Team " + MOST_RECENT_DEATH_TEAM);
}

mega.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
::ClearGameEventCallbacks <- function () {
    mega.ClearGameEventCallbacks()
    ::__CollectGameEventCallbacks(mega)
}
::__CollectGameEventCallbacks(mega)

printl("MEGAMOD: arena_perks.nut finished")