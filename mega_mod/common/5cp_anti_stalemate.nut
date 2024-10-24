ClearGameEventCallbacks();

::MM_5CP_HAS_5_POINTS <- false;

function OnGameEvent_teamplay_round_start(params)
{
    Setup5CPKothTimer();
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
}

function MM_5CPTimeoutRed() {

}
function MM_5CPTimeoutBlu() {

}
__CollectGameEventCallbacks(this);