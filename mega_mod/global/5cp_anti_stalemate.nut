function ShouldApply() {

    local exceptionsAlways = [];
    local exceptionsNever = [];

    local mapName = GetMapName();

    if (exceptionsNever.indexOf(mapName) != -1) {
        return false;
    } else if (exceptionsAlways.indexOf(mapName) != -1) {
        return true;
    }

    local countNeutral = 0;
    local countRed = 0;
    local countBlu = 0

    for (local cp = null; cp = Entities.FindByClassname(cp, "team_control_point");) {
        local owner = NetProps.GetPropBool(cp, "m_iDefaultOwner");
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

if (ShouldApply()) {
    IncludeScript("mega_mod/common/5cp_anti_stalemate.nut");
}