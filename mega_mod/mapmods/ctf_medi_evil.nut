ClearGameEventCallbacks();

// The map ships with a hardcoded 10 minute team_round_timer ("timer").
// Replace it at round start with one that matches the remaining mp_timelimit, with no setup time.

function OnGameEvent_teamplay_round_start(params) {

    local oldTimer = MM_GetEntByName("timer");
    if (oldTimer != null) oldTimer.Kill();

    local timeRemaining = MM_GetTimelimitRemaining();
    if (timeRemaining == null) timeRemaining = 600;

    local newTimer = SpawnEntityFromTable("team_round_timer", {
        targetname = "timer"
        auto_countdown = 1
        max_length = 0
        setup_length = 0
        timer_length = timeRemaining
        reset_time = 1
        show_in_hud = 1
        show_time_remaining = 1
        start_paused = 0
        StartDisabled = 0
    });
    newTimer.AcceptInput("Resume", "", null, null);

    // When the timer finishes, let the map's "compare" entity decide the round outcome.
    EntityOutputs.AddOutput(newTimer, "OnFinished", "compare", "Compare", "", 0, -1);
}

__CollectGameEventCallbacks(this)
