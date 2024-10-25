ClearGameEventCallbacks();

::MM_5CP_HAS_5_POINTS <- false;

function OnGameEvent_teamplay_round_start(params)
{
    if (IsInWaitingForPlayers()) return;
    Setup5CPKothTimer();

    ConfigureCaptureAreas();
}

// INIT FUNCTIONS

// Kill old timer, swap in a KOTH one.
function Setup5CPKothTimer() {
    local oldTimer = Entities.FindByClassname(null, "team_round_timer");
    local time = NetProps.GetPropInt(oldTimer,  "m_nTimerInitialLength")
    oldTimer.Kill();

    local gamerules = Entities.FindByClassname(null, "tf_gamerules");
    local mp_timelimit = Convars.GetInt("mp_timelimit");

    // If mp_timelimit is close, adjust the round timer to prevent excessive maptime.
    if (mp_timelimit != null && mp_timelimit > 0) {
        local remainingTime = (mp_timelimit * 60) - (Time() - NetProps.GetPropFloat(gamerules, "m_flMapResetTime"));

        if(remainingTime < time) {
            time = ceil(remainingTime / 30) * 30;
        }
        if (time < 180) time = 180;
    }

    ::MM_5CP_KOTH_LOGIC <- SpawnEntityFromTable("tf_logic_koth", {
        targetname = "tf_logic_koth"
        timer_length = time
    })

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

function ConfigureCaptureAreas() {
    local maxTime = 0;
    for (local ent = null; ent = Entities.FindByClassname(ent, "trigger_capture_area");) {
        local capTime = NetProps.GetPropFloat(ent, "m_flCapTime");
        maxTime = capTime > maxTime ? capTime : maxTime;
    }
    for (local ent = null; ent = Entities.FindByClassname(ent, "trigger_capture_area");) {
        // Force all control points to have the longest capture time present on the map.
        ent.AcceptInput("AddOutput", "area_time_to_cap " + maxTime, null,  null);
        ent.AcceptInput("SetControlPoint", NetProps.GetPropString(ent, "m_iszCapPointName"), null, null); // Prevent the capping HUD being jank (thanks ficool2)

        // Check for end of round since the KOTH logic messes with the vanilla method.
        EntityOutputs.AddOutput(ent, "OnCapTeam1", "!self", "RunScriptCode", "CheckEndOfRound()", 0, -1);
        EntityOutputs.AddOutput(ent, "OnCapTeam2", "!self", "RunScriptCode", "CheckEndOfRound()", 0, -1);
    }
}

// RUNTIME FUNCTIONS

// TODO: hook to points and test
function CheckEndOfRound() {
    local winner = -1;
    // Check if all points are owned by the same team (returns if not).
    for (local cp = null; cp = Entities.FindByClassname(cp, "team_control_point");) {
        local owner = cp.GetTeam()
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