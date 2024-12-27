function ShouldApply() {
    local exceptionsAlways = ["ctf_haarp"];
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

function IsGlobal() {
    return false;
}

ApplyMod <- function () {
    local root = getroottable();
    IncludeScript("mega_mod/common/respawn_mod.nut", root);

    this.OnGameEvent_teamplay_round_start <- function (event) {
        if(IsInWaitingForPlayers()) return;
        printl("MEGAMOD: Loading respawn mod...");
        MM_Respawn_Mod();
    }.bindenv(this);
    
    local scope = this;
    scope.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
    ::ClearGameEventCallbacks <- function () {
        scope.ClearGameEventCallbacks()
        ::__CollectGameEventCallbacks(scope)
    };
    
    ::__CollectGameEventCallbacks(this);
}.bindenv(this);


