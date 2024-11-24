function ShouldApply() {
    local exceptionsAlways = [];
    local exceptionsNever = [];

    local mapName = GetMapName();

    if (exceptionsNever.find(mapName) != null) {
        return false;
    } else if (exceptionsAlways.find(mapName) != null) {
        return true;
    } else if (!startswith(mapName,  "pl_") && !startswith(mapName,  "cp_")) {
        return false;
    }
    local countNeutral = 0;
    local countRed = 0;
    local countBlu = 0

    for (local cp = null; cp = Entities.FindByClassname(cp, "team_control_point");) {
        local owner = NetProps.GetPropInt(cp, "m_iDefaultOwner");
        switch (owner) {
            case 0:
                countNeutral++;
                break;
            case 2:
                countRed++;
                break;
            case 3:
                countBlu++;
                break;
        }
    }

    // Check for Attack/Defend or Payload by checking for points not owned by RED.
    if (countBlu > 0 || countNeutral > 0) {
        return false;
    }
    return true;
}

if (!ShouldApply()) return;

IncludeScript("mega_mod/common/respawn_mod.nut");


local root = getroottable();
local prefix = DoUniqueString("mod_respawns");
local mod_respawns = root[prefix] <- {};

mod_respawns.OnGameEvent_teamplay_round_start <- function (event) {
    if(IsInWaitingForPlayers()) return;
    printl("MEGAMOD: Loading respawn mod...");
    MM_Respawn_Mod();
}

mod_respawns.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
::ClearGameEventCallbacks <- function () {
    mod_respawns.ClearGameEventCallbacks()
    ::__CollectGameEventCallbacks(mod_respawns)
}
::__CollectGameEventCallbacks(mod_respawns);
