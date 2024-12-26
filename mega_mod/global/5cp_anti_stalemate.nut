function ShouldApply() {
    local exceptionsAlways = [];
    local exceptionsNever = [];

    local mapName = GetMapName();

    if (exceptionsNever.find(mapName) != null) {
        return false;
    } else if (exceptionsAlways.find(mapName) != null) {
        return true;
    } else if (!startswith(mapName,  "cp_")) {
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

    // Check for 3CP or 5CP by looking at default owners of control points.
    if (countRed >= 1 && countRed == countBlu && countNeutral == 1) {
        return true;
    }
    return false;
}

function IsGlobal() {
    return false;
}

ApplyMod <- function () {
    IncludeScript("mega_mod/common/5cp_anti_stalemate.nut");

    this.OnGameEvent_teamplay_round_start <- function (event) {
        if(IsInWaitingForPlayers()) return;
        printl("MEGAMOD: Loading 5cp mod...");
        MM_5CP_Activate();
    }

    this.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
    ::ClearGameEventCallbacks <- function () {
        this.ClearGameEventCallbacks()
        ::__CollectGameEventCallbacks(this)
    }.bindenv(this);

    ::__CollectGameEventCallbacks(this);
}.bindenv(this);