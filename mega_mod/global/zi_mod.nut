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

if (!ShouldApply()) return;

local root = getroottable();
local prefix = DoUniqueString("zi_mod");
local zi_mod = root[prefix] <- {};

IncludeScript("mega_mod/common/zi_mod/main.nut");

zi_mod.OnGameEvent_teamplay_round_start <- function (event) {
    if(IsInWaitingForPlayers()) return;
    printl("MEGAMOD: Loading Zombie Infection mod...");
    MM_Zombie_Infection();
}

zi_mod.OnGameEvent_player_team <- function (event) {
    MM_ZI_OnPlayerTeam(event);
}

zi_mod.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
::ClearGameEventCallbacks <- function () {
    zi_mod.ClearGameEventCallbacks()
    ::__CollectGameEventCallbacks(zi_mod)
}

::__CollectGameEventCallbacks(zi_mod);