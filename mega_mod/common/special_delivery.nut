::MM_Special_Delivery <- function() {
    printl("MEGAMOD: Loading Special Delivery mod...");

    local oldTimer = Entities.FindByClassname(null, "team_round_timer");
    if(oldTimer) {
        EntityOutputs.AddOutput(oldTimer, "OnSetupFinished", "!self", "RunScriptCode", "MM_SDSetupEnd()", 0, -1);
    }
}

::MM_SDSetupEnd <- function () {
    ::MM_SD_TIME_UPPER_LIMIT <- 900;
    ::MM_SD_TIME_LOWER_LIMIT <- 300;

    local gamerules = Entities.FindByClassname(null, "tf_gamerules");
    local mp_timelimit = Convars.GetInt("mp_timelimit");

    local time = MM_SD_TIME_UPPER_LIMIT;

    local oldTimer = Entities.FindByClassname(null, "team_round_timer");
    if(oldTimer) {
        oldTimer.Kill();
    }

    // If mp_timelimit is close, adjust the round timer to prevent excessive maptime.
    if (mp_timelimit != null && mp_timelimit > 0) {
        local remainingTime = (mp_timelimit * 60) - (Time() - NetProps.GetPropFloat(gamerules, "m_flMapResetTime"));

        if(remainingTime < time) {
            time = ceil(remainingTime / 30) * 30;
        }
    }

    if (time > MM_SD_TIME_UPPER_LIMIT) time = MM_SD_TIME_UPPER_LIMIT;
    if (time < MM_SD_TIME_LOWER_LIMIT) time = MM_SD_TIME_LOWER_LIMIT;

    local team_round_timer = SpawnEntityFromTable("team_round_timer", {
        auto_countdown = 1,
        max_length = 0,
        timer_length = time,
        reset_time = 1,
        setup_length = 0,
        show_in_hud = 1,
        show_time_remaining = 1,
        start_paused = 0,
        StartDisabled = 0
        "OnFinished#1": "!self,RunScriptCode,MM_SDRoundEnd(),0,1"
    });
    team_round_timer.AcceptInput("Resume", "", null, null);
}

::MM_SDRoundEnd <- function () {
    local game_round_win = SpawnEntityFromTable("game_round_win", {
        targetname = "mm_game_round_stalemate",
        force_map_reset = true,
        TeamNum = 0
    });
    game_round_win.AcceptInput("RoundWin", "", null, null);
}