function DisplayCountdown()
{
    local old_timer = Entities.FindByClassname(null, "team_round_timer");
    if(old_timer) {
        old_timer.Kill();
    }
    ::MM_ARENA_START_TIME <- Time();
    ::MM_ARENA_ROUND_TIME <- 180;
    local team_round_timer = SpawnEntityFromTableFix("team_round_timer", {
        auto_countdown = 1,
        max_length = 0,
        timer_length = MM_ARENA_ROUND_TIME,
        reset_time = 1,
        setup_length = ARENA_SETUP_LENGTH,
        show_in_hud = 1,
        show_time_remaining = 1,
        start_paused = 0,
        StartDisabled = 0
    });

    EntFireByHandle(team_round_timer, "Resume", "", 0, null, null);

    // EntFireByHandle(tf_gamerules, "PlayVO", "Announcer.RoundBegins10Seconds", ARENA_SETUP_LENGTH - 11, null, null);
    // EntFireByHandle(tf_gamerules, "PlayVO", "Announcer.RoundBegins5Seconds", ARENA_SETUP_LENGTH - 6, null, null);
    // EntFireByHandle(tf_gamerules, "PlayVO", "Announcer.RoundBegins4Seconds", ARENA_SETUP_LENGTH - 5, null, null);
    // EntFireByHandle(tf_gamerules, "PlayVO", "Announcer.RoundBegins3Seconds", ARENA_SETUP_LENGTH - 4, null, null);
    // EntFireByHandle(tf_gamerules, "PlayVO", "Announcer.RoundBegins2Seconds", ARENA_SETUP_LENGTH - 3, null, null);
    // EntFireByHandle(tf_gamerules, "PlayVO", "Announcer.RoundBegins1Seconds", ARENA_SETUP_LENGTH - 2, null, null);
    EntFireByHandle(tf_gamerules, "PlayVO", "Announcer.AM_RoundStartRandom", ARENA_SETUP_LENGTH, null, null);
    // EntFireByHandle(tf_gamerules, "PlayVO", "Ambient.Siren", ARENA_SETUP_LENGTH, null, null);

    EntityOutputs.AddOutput(team_round_timer, "On1SecRemain", "!self", "RunScriptCode", "CountdownEnd()", 1, -1);
}

::CountdownEnd <- function () {
    if (Time() - ::MM_ARENA_START_TIME < ::MM_ARENA_ROUND_TIME) {
        return;
    }
    local redAlive = GetAlivePlayers(TF_TEAM_RED).len();
    local bluAlive = GetAlivePlayers(TF_TEAM_BLUE).len();
    if (redAlive > bluAlive)
        EndMiniRound(TF_TEAM_RED, false);
    else if (redAlive < bluAlive)
        EndMiniRound(TF_TEAM_BLUE, false);
    else
        EndMiniRound(0, false);
}.bindenv(this);

