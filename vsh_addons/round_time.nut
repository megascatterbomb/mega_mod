// Clamp time for when hale kills mercs quickly.
// Prevents a round dragging on with few players.

local originalMaxTime = 999;

function ClampRoundTime()
{
    local maxTime = ceil(clampFloor(30, GetAliveMercCount() * 15));
    local currentTime = clampCeiling(GetPropFloat(team_round_timer, "m_flTimerEndTime") - Time(), GetPropFloat(team_round_timer, "m_flTimeRemaining"));
    if (currentTime > maxTime)
    {
        EntFireByHandle(team_round_timer, "SetTime", "" + maxTime, 0, null, null);
        EntFireByHandle(team_round_timer, "SetMaxTime", "" + originalMaxTime, 0, null, null);
    }
}

AddListener("death", 10, function(attacker, victim, params)
{
    RunWithDelay("ClampRoundTime()", null, 0.05);
});

// Increase setup time for very high player counts.
// Round start can be very laggy for high player counts; extra time helps the less fortunate.
// Also gives players more time to spread out.
// Negative ordering because this needs to run before the VO for setup is set in motion.
AddListener("setup_start", -10, function ()
{
    // We clamp to prevent the "mission begins in 30 seconds" from playing.
    local setupTime = clampCeiling(32, clampFloor(16, ceil(validMercs.len() / 3.0)));
    VSH_API_VALUES.setup_length <- setupTime - 5;
    EntFireByHandle(team_round_timer, "SetTime", "" + (setupTime - 5), 0, null, null);
    EntFireByHandle(team_round_timer, "Pause", "", 0, null, null);
    EntFireByHandle(team_round_timer, "Resume", "", 5, null, null);
});

// OVERRIDE: accomodate long setup time.
function PlayRoundStartVO()
{
    if (IsRoundOver())
        return;
    local boss = GetRandomBossPlayer();
    if (boss == null)
        return;
    local startDelay = clampFloor(0, API_GetFloat("setup_length") - 14);
    if (API_GetBool("long_setup_lines") && RandomInt(1, 10) <= 4)
        PlayAnnouncerVODelayed(boss, "round_start_long", startDelay);
    else
    {
        if (API_GetBool("beer_lines") && RandomInt(1, 10) <= 4)
            PlayAnnouncerVODelayed(boss, "round_start_beer", startDelay)
        else if (RandomInt(1, 5) == 1 && GetPersistentVar("last_round_winner") == TF_TEAM_BOSS)
            PlayAnnouncerVODelayed(boss, "round_start_after_loss", startDelay)
        else
            PlayAnnouncerVODelayed(boss, "round_start", startDelay)

        if (!API_GetBool("setup_countdown_lines"))
            return;
        local countdownDelay = API_GetFloat("setup_length") - 8;
        PlayAnnouncerVODelayed(boss, "count5", countdownDelay++);
        PlayAnnouncerVODelayed(boss, "count4", countdownDelay++);
        PlayAnnouncerVODelayed(boss, "count3", countdownDelay++);
        PlayAnnouncerVODelayed(boss, "count2", countdownDelay++);
        PlayAnnouncerVODelayed(boss, "count1", countdownDelay);
    }
    RunWithDelay2(this, startDelay, function() {
        PlayAnnouncerVOToPlayer(boss, boss, "round_start_4boss")
    });
}

// Scales round time based on playercount
AddListener("setup_end", 0, function()
{
    local time = clampFloor(30, ceil(validMercs.len() * 10));
    EntFireByHandle(team_round_timer, "SetTime", "" + time, 0, null, null);
    EntFireByHandle(team_round_timer, "SetMaxTime", "" + time, 0, null, null);
    originalMaxTime = time;
    RunWithDelay("ClampRoundTime()", null, 0.05);
});

// OVERRIDE: Replacement for listener in /_gamemode/round_logic.nut
// Removes vanilla logic for timer clamp.
EraseListener("tick_always", 8, 0);
AddListener("tick_always", 8, function(timeDelta)
{
    if (IsInWaitingForPlayers())
        return;
    if (IsRoundSetup())
    {
        if (GetValidPlayerCount() <= 1 && !IsAnyBossAlive())
        {
            SetPropInt(team_round_timer, "m_bTimerPaused", 1);
            return;
        }
        //Bailout
        if (!IsAnyBossAlive())
        {
            Convars.SetValue("mp_bonusroundtime", 5);
            EndRound(TF_TEAM_UNASSIGNED);
        }
        return;
    }

    // Removed as we have a replacement
    // if (GetAliveMercCount() <= 5 && GetPropFloat(team_round_timer, "m_flTimeRemaining") > 60)
    //    EntFireByHandle(team_round_timer, "SetTime", "60", 0, null, null);

    local noBossesAlive = !IsAnyBossAlive();
    local noMercsAlive = GetAliveMercCount() <= 0;

    if (noBossesAlive && noMercsAlive)
        EndRound(TF_TEAM_UNASSIGNED);
    else if (noBossesAlive)
        EndRound(TF_TEAM_MERCS);
    else if (noMercsAlive)
        EndRound(TF_TEAM_BOSS);
});
