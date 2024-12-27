function ShouldApply() {
    local exceptionsAlways = [];
    local exceptionsNever = [];

    local mapName = GetMapName();

    if (exceptionsNever.find(mapName) != null) {
        return false;
    } else if (exceptionsAlways.find(mapName) != null) {
        return true;
    } else if (!startswith(mapName,  "zi_")) {
        return false;
    }
    return true;
}

function IsGlobal() {
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

