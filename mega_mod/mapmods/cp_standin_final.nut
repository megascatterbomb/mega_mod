if (!MM_ModIsEnabled("5cp_anti_stalemate")) return;

ClearGameEventCallbacks();
IncludeScript("mega_mod/common/5cp_anti_stalemate.nut");

function OnGameEvent_teamplay_round_start(params)
{

    for (local ent = null; ent = Entities.FindByClassname(ent, "trigger_capture_area");) {
        // Check for end of round on cap break, since we don't want a team to win unless the points are uncontested.
        EntityOutputs.AddOutput(ent, "OnBreakTeam1", "!self", "RunScriptCode", "CheckIfAllPointsOwnedAndUncontested()", 0, -1);
        EntityOutputs.AddOutput(ent, "OnBreakTeam2", "!self", "RunScriptCode", "CheckIfAllPointsOwnedAndUncontested()", 0, -1);
    }

    // Override to prevent point I/O being attached to non-existent mid
    function AttachMid() {
        // Do nothing
    }

    function LockMidAtStart() {
        // Do nothing
    }

    function CheckEndOfRound() {
        if (CheckIfAllPointsOwnedAndUncontested()) return;
        UpdateKothClock();
    }

    function CheckIfAllPointsOwnedAndUncontested() {
        local winner = -1;
        local tf_objective_resource = Entities.FindByClassname(null, "tf_objective_resource");
        // Check if all points are owned by the same team (breaks if not).
        for (local cp = null; cp = Entities.FindByClassname(cp, "team_control_point");) {
            local owner = cp.GetTeam();
            local index = NetProps.GetPropInt(cp, "m_iPointIndex");
            local progress = NetProps.GetPropFloatArray(tf_objective_resource, "m_flCapPercentages", index);
            if (progress > 0) {
                winner = -1;
                break;
            }
            if (winner == -1) {
                winner = owner;
                continue;
            } else if (winner != owner) {
                winner = -1;
                break;
            }
        }
        if (winner == 2) {
            NetProps.SetPropInt(MM_GetEntByName("zz_gamewin_red"), "m_iWinReason", 1);
            EntFireByHandle(MM_GetEntByName("zz_gamewin_red"), "RoundWin", "", 0, null, null);
            return true;
        } else if (winner == 3) {
            NetProps.SetPropInt(MM_GetEntByName("zz_gamewin_blue"), "m_iWinReason", 1);
            EntFireByHandle(MM_GetEntByName("zz_gamewin_blue"), "RoundWin", "", 0, null, null);
            return true;
        }
        return false;
    }

    function UpdateKothClock() {
        // Check who has more points
        local delta = 0;
        for (local cp = null; cp = Entities.FindByClassname(cp, "team_control_point");) {
            local owner = cp.GetTeam();
            if (owner == 2) {
                delta++;
            } else if (owner == 3) {
                delta--;
            }
        }
        local gamerules = Gamerules();
        if(delta > 0) {
            gamerules.AcceptInput("SetRedKothClockActive", "", null, null);
        } else if (delta < 0) {
            gamerules.AcceptInput("SetBlueKothClockActive", "", null, null);
        } else {
            for(local timer = null; timer = Entities.FindByClassname(timer, "team_round_timer");) {
                timer.AcceptInput("Pause", "", null, null);
            }
        }
    }

    MM_5CP_Activate();
}

__CollectGameEventCallbacks(this);