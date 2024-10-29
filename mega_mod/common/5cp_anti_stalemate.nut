function MM_5CP_Activate() {
    ::MM_5CP_POINT_COUNT <- 5;
    ::MM_5CP_HAS_SETUP <- false;
    if (IsInWaitingForPlayers()) return;

    Setup5CPKothTimer();
    AttachMid();
    ConfigureCaptureAreas();
    LockMidAtStart();
}

// INIT FUNCTIONS

// Kill old timer, swap in a KOTH one.
function Setup5CPKothTimer() {
    local oldTimer = Entities.FindByClassname(null, "team_round_timer");
    if (NetProps.GetPropInt(oldTimer, "m_nSetupTimeLength") > 0 && !MM_5CP_HAS_SETUP) {
        ::MM_5CP_HAS_SETUP <- true;
        HandleSetup();
        return;
    }
    local time = NetProps.GetPropInt(oldTimer, "m_nTimerInitialLength");
    oldTimer.Kill();

    local gamerules = Entities.FindByClassname(null, "tf_gamerules");
    local mp_timelimit = Convars.GetInt("mp_timelimit");

    local MM_5CP_TIME_UPPER_LIMIT = 600;
    local MM_5CP_TIME_LOWER_LIMIT = 300;

    // If mp_timelimit is close, adjust the round timer to prevent excessive maptime.
    if (mp_timelimit != null && mp_timelimit > 0) {
        local remainingTime = (mp_timelimit * 60) - (Time() - NetProps.GetPropFloat(gamerules, "m_flMapResetTime"));

        if(remainingTime < time) {
            time = ceil(remainingTime / 30) * 30;
        }
    }
    if (time > MM_5CP_TIME_UPPER_LIMIT) time = MM_5CP_TIME_UPPER_LIMIT;
    if (time < MM_5CP_TIME_LOWER_LIMIT) time = MM_5CP_TIME_LOWER_LIMIT;

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
}

function AttachMid() {
    local gamerules = Entities.FindByClassname(null, "tf_gamerules");
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

function HandleSetup() {
    local gamerules = Entities.FindByClassname(null, "tf_gamerules");
    NetProps.SetPropBool(gamerules, "m_bPlayingKoth", false);
    local logic = MM_GetEntByName("tf_logic_koth");
    if (logic) logic.Kill();

    local oldTimer = Entities.FindByClassname(null, "team_round_timer");
    local setupTime = NetProps.GetPropInt(oldTimer, "m_nSetupTimeLength");
    EntityOutputs.AddOutput(oldTimer, "OnSetupFinished", "!self", "RunScriptCode", "Setup5CPKothTimer()", 0, -1);
}

function ConfigureCaptureAreas() {
    local maxTime = 0;
    local count = 0;
    for (local ent = null; ent = Entities.FindByClassname(ent, "trigger_capture_area");) {
        local capTime = NetProps.GetPropFloat(ent, "m_flCapTime");
        maxTime = capTime > maxTime ? capTime : maxTime;
        count++;
    }
    ::MM_5CP_POINT_COUNT <- count;
    for (local ent = null; ent = Entities.FindByClassname(ent, "trigger_capture_area");) {
        // Force all control points to have the longest capture time present on the map.
        ent.AcceptInput("AddOutput", "area_time_to_cap " + maxTime, null,  null);
        ent.AcceptInput("SetControlPoint", NetProps.GetPropString(ent, "m_iszCapPointName"), null, null); // Prevent the capping HUD being jank (thanks ficool2)

        // Check for end of round since the KOTH logic messes with the vanilla method.
        EntityOutputs.AddOutput(ent, "OnCapTeam1", "!self", "RunScriptCode", "CheckEndOfRound()", 0, -1);
        EntityOutputs.AddOutput(ent, "OnCapTeam2", "!self", "RunScriptCode", "CheckEndOfRound()", 0, -1);
    }
}

// Identify the middle point and lock it for the first 30 seconds of a round.
function LockMidAtStart() {
    if (MM_5CP_HAS_SETUP) return;
    for (local cp = null; cp = Entities.FindByClassname(cp, "team_control_point");) {
        local owner = NetProps.GetPropInt(cp, "m_iDefaultOwner");
        local isLocked = NetProps.GetPropBool(cp, "m_bLocked");
        if (owner == 0) {
            cp.AcceptInput("SetLocked", "1", null, null);
            cp.AcceptInput("SetUnlockTime", "35", null, null);
            break;
        }
    }
}

// RUNTIME FUNCTIONS

function CheckEndOfRound() {
    local winner = -1;
    // Check if all points are owned by the same team (returns if not).
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
}