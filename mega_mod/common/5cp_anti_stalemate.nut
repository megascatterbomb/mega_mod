ClearGameEventCallbacks();

::MM_5CP_HAS_5_POINTS <- false;

function OnGameEvent_teamplay_round_start(params)
{
    Setup5CPKothTimer();

    FlattenCaptureTimes();
}


// Kill old timer, swap in a KOTH one with matching times.
function Setup5CPKothTimer() {
    local oldTimer = Entities.FindByClassname(null, "team_round_timer");
    local time = NetProps.GetPropInt(oldTimer,  "m_nTimerInitialLength")
    oldTimer.Kill();

    ::MM_5CP_KOTH_LOGIC <- SpawnEntityFromTable("tf_logic_koth", {
        targetname = "tf_logic_koth"
        timer_length = time
    })

    local gamerules = Entities.FindByClassname(null, "tf_gamerules");
    NetProps.SetPropBool(gamerules, "m_bPlayingKoth", true);
    MM_5CP_KOTH_LOGIC.AcceptInput("RoundSpawn", "", null, null);

    SpawnEntityFromTable("game_round_win", {
        targetname = "zz_gamewin_red"
        force_map_reset = true // prevents crashes
        TeamNum = 2
    });
    SpawnEntityFromTable("game_round_win", {
        targetname = "zz_gamewin_blue"
        force_map_reset = true // prevents crashes
        TeamNum = 3
    });

    EntityOutputs.AddOutput(MM_GetEntByName("zz_red_koth_timer"), "OnFinished", "zz_gamewin_red", "RoundWin", "", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("zz_blue_koth_timer"), "OnFinished", "zz_gamewin_blue", "RoundWin", "", 0, -1);

    // Identify the neutral point and get it to handle KOTH I/O.
    for (local cp = null; cp = Entities.FindByClassname(cp, "team_control_point");) {
        local owner = NetProps.GetPropInt(cp, "m_iDefaultOwner");
        if (owner == 0) {
            EntityOutputs.AddOutput(cp, "OnCapTeam1", gamerules.GetName(), "SetRedKothClockActive", "", 0, -1);
            EntityOutputs.AddOutput(cp, "OnCapTeam2", gamerules.GetName(), "SetBlueKothClockActive", "", 0, -1);
            break;
        }
    }
}

// Force all control points to have the longest capture time present on the map.
function FlattenCaptureTimes() {
    local maxTime = 0;
    for (local ent = null; ent = Entities.FindByClassname(ent, "trigger_capture_area");) {
        local capTime = NetProps.GetPropFloat(ent, "m_flCapTime");
        maxTime = capTime > maxTime ? capTime : maxTime;
    }
    for (local ent = null; ent = Entities.FindByClassname(ent, "trigger_capture_area");) {
        ent.AcceptInput("AddOutput", "area_time_to_cap " + maxTime, null,  null);
        ent.AcceptInput("SetControlPoint", NetProps.GetPropString(ent, "m_iszCapPointName"), null, null); // Prevent the capping HUD being jank (thanks ficool2)
    }
}

// TODO: hook to points and test
function CheckEndOfRound() {
    local winner = -1;
    // Check if all points are owned by the same team (returns if not).
    for (local cp = null; cp = Entities.FindByClassname(cp, "team_control_point");) {
        local owner = NetProps.GetPropInt(cp, "m_iTeam");
        if (winner == -1) {
            winner = owner;
            continue;
        } else if (winner != owner) {
            return;
        }
    }
    if (winner == 2) {
        EntFireByHandle(MM_GetEntByName("zz_gamewin_red"), "RoundWin", "", 0, null, null);
    } else if (winner == 3) {
        EntFireByHandle(MM_GetEntByName("zz_gamewin_blue"), "RoundWin", "", 0, null, null);
    }
}

__CollectGameEventCallbacks(this);