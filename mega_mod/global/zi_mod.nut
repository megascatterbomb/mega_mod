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
    IncludeScript("mega_mod/common/zi_mod.nut");

    this.OnGameEvent_teamplay_round_start <- function (event) {
        if(IsInWaitingForPlayers()) return;
        printl("MEGAMOD: Loading Zombie Infection mod...");
        MM_Zombie_Infection();
    }
    
    this.OnGameEvent_player_team <- function (event) {
        MM_ZI_OnPlayerTeam(event);
    }
    
    this.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
    ::ClearGameEventCallbacks <- function () {
        this.ClearGameEventCallbacks()
        ::__CollectGameEventCallbacks(this)
    }.bindenv(this);
    
    ::__CollectGameEventCallbacks(this);
}.bindenv(this);

