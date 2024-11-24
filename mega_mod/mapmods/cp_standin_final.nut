ClearGameEventCallbacks();
IncludeScript("mega_mod/common/5cp_anti_stalemate.nut");

function OnGameEvent_teamplay_round_start(params)
{
    // Override to prevent point I/O being attached to non-existent mid
    function AttachMid() {
        // Do nothing
    }

    function LockMidAtStart() {
        // Do nothing
    }

    function CheckEndOfRound() {
        local winner = -1;
        // Check if all points are owned by the same team (breaks if not).
        for (local cp = null; cp = Entities.FindByClassname(cp, "team_control_point");) {
            local owner = cp.GetTeam();
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
        } else if (winner == 3) {
            NetProps.SetPropInt(MM_GetEntByName("zz_gamewin_blue"), "m_iWinReason", 1);
            EntFireByHandle(MM_GetEntByName("zz_gamewin_blue"), "RoundWin", "", 0, null, null);
        }
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
        local gamerules = Entities.FindByClassname(null, "tf_gamerules");
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