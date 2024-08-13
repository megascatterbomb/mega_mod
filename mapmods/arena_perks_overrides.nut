function PerkGameStateVote::OnEnter() {
    // NetProps.SetPropInt(GAMERULES, "m_iRoundState", Constants.ERoundState.GR_STATE_RND_RUNNING);

    // MEGAMOD: Replace round timer
    GAME_TIMER.Kill()
    ::GAME_TIMER <- SpawnEntityFromTable("team_round_timer", {
        reset_time = 1,
        setup_length = 30,
        start_paused = 0,
        targetname = "game_timer",
        timer_length = 8,
        "OnSetupFinished#1" : "!self,RunScriptFile,perks/callback/setup_end,0,1"
    });
    EntFireByHandle(GAME_TIMER, "ShowInHud", "1", 0, null, null);
    EntFireByHandle(GAME_TIMER, "Resume", "1", 0, null, null);

    EntFire("arena_spawnpoints", "Disable", "", -1, null);
    EntFire("music_perk_phase", "PlaySound", "", 0, null);
    EntFire("perk_glow", "ShowSprite", "", 0, null);
    EntFire("perk_beam", "Enable", "", 0, null);
    EntFire("perk_particles", "Start", "", 0, null);
    EntFire("t_waiting_regenerate", "ForceSpawn", "", 0, null);

    foreach (manager in ::PerkGamemode.PerkManagers) {
        manager.RollPerks();
    }
}

function PerkGameStateRound::OnEnter() {
    EntFire("arena_spawnpoints", "Enable", "", -1, null);
    EntFire("vote_spawnpoints", "Disable", "", -1, null);

    GAME_TIMER.Kill();
    ::GAME_TIMER <- SpawnEntityFromTable("team_round_timer", {
        reset_time = 1,
        setup_length = 0,
        start_paused = 0,
        targetname = "game_timer",
        timer_length = 230,
        "OnFinished#1" : "!self,RunScriptFile,mega_mod/mapmods/arena_perks_stalemate,0,1"
    });
    EntFireByHandle(GAME_TIMER, "ShowInHud", "1", 0, null, null);
    EntFireByHandle(GAME_TIMER, "Resume", "1", 0, null, null);

    foreach (player in GetAllPlayers()) {
        ClearWeaponCache(player);
    }

    foreach (manager in ::PerkGamemode.PerkManagers) {
        manager.OnRoundStart();
    }

    // RunWithDelay(function() {
    //     foreach (player in GetAllPlayers()) {

    //         player.Regenerate(true);
    //         player.ForceRespawn();
    //     }
    // }, 0.1);

    EntFire("game_forcerespawn", "ForceRespawn", "", 0.3, null);
    EntFire("arena_spawnpoints", "Disable", "", 1, null);
    EntFire("trap_spawnpoint", "Enable", "", 1, null);

    // NetProps.SetPropInt(GAMERULES, "m_iRoundState", Constants.ERoundState.GR_STATE_STALEMATE);

    EntFireByHandle(CENTRAL_CP, "SetLocked", "1", 0, null, null);
    EntFireByHandle(CENTRAL_CP, "SetUnlockTime", "50", 0, null, null);
    EntFireByHandle(CENTRAL_CP, "HideModel", "", 0, null, null);

    RunWithDelay(CountAlivePlayers, 0.5, [this, false]);
}

function PerkGameStateRound::WinRound(winnerTeam) {
    EntFireByHandle(GAME_TIMER, "Disable", "", 0, null, null);
    if (winnerTeam) {
        EntFireByHandle(PLAYER_DESTRUCTION_LOGIC, "Score"+TeamName(winnerTeam, true)+"Points", "", 0, null, null);
        EntFire("text_win_"+TeamName(winnerTeam), "Display", "", 0, null);
    } else {
        // MEGAMOD: Since round can end via timeout, award win to whichever team has more players alive

        local redAlive = GetAliveTeamPlayerCount(Constants.ETFTeam.TF_TEAM_RED);
        local bluAlive = GetAliveTeamPlayerCount(Constants.ETFTeam.TF_TEAM_BLUE);
        if(redAlive > bluAlive) {
            EntFireByHandle(PLAYER_DESTRUCTION_LOGIC, "ScoreRedPoints", "", 0, null, null);
            EntFire("text_win_red", "Display", "", 0, null);
            winnerTeam = Constants.ETFTeam.TF_TEAM_RED;
        } else if (redAlive < bluAlive) {
            EntFireByHandle(PLAYER_DESTRUCTION_LOGIC, "ScoreBluePoints", "", 0, null, null);
            EntFire("text_win_blu", "Display", "", 0, null);
            winnerTeam = Constants.ETFTeam.TF_TEAM_BLUE;

        // MEGAMOD: If tied, award points to both teams (like vanilla perks), but award first to whichever team died last (makes overall wins from ties less arbitrary)
        } else if(MOST_RECENT_DEATH_TEAM == Constants.ETFTeam.TF_TEAM_RED) {
            EntFireByHandle(PLAYER_DESTRUCTION_LOGIC, "ScoreRedPoints", "", 0, null, null);
            EntFireByHandle(PLAYER_DESTRUCTION_LOGIC, "ScoreBluePoints", "", 0.5, null, null);
            EntFire("text_win_none", "Display", "", 0, null);
        } else {
            EntFireByHandle(PLAYER_DESTRUCTION_LOGIC, "ScoreBluePoints", "", 0, null, null);
            EntFireByHandle(PLAYER_DESTRUCTION_LOGIC, "ScoreRedPoints", "", 0.5, null, null);
            EntFire("text_win_none", "Display", "", 0, null);
        }
    }

   foreach (player in GetAllPlayers()) {
        local team = player.GetTeam();
        if (!winnerTeam || team != winnerTeam) {
            StunPlayer(player, 9999);
        } else {
            player.AddCondEx(Constants.ETFCond.TF_COND_CRITBOOSTED_FIRST_BLOOD, 9999, null);
        }
    }

    EntFire("trigger_stun", "Kill", "", 0.1, null);
    ::PerkGamemode.ChangeState("round_end");
}