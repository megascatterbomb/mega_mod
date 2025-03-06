function ShouldApply() {
    return MM_GetGamemode() == MM_Gamemodes.ZI;
}

function LoadAlongsideMapMods() {
    return false;
}

ApplyMod <- function () {
    local root = getroottable();
    IncludeScript("mega_mod/common/zi_mod.nut", root);

    this.OnGameEvent_teamplay_round_start <- function (event) {
        if(IsInWaitingForPlayers()) return;
        printl("MEGAMOD: Loading Zombie Infection mod...");
        MM_Zombie_Infection();
    }.bindenv(this);

    this.OnGameEvent_player_team <- function (event) {
        MM_ZI_OnPlayerTeam(event);
    }.bindenv(this);

    local scope = this;
    scope.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
    ::ClearGameEventCallbacks <- function () {
        scope.ClearGameEventCallbacks()
        ::__CollectGameEventCallbacks(scope)
    };

    ::__CollectGameEventCallbacks(this);
}.bindenv(this);

