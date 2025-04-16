function MM_Respawn_Mod(full_reset) {
    ::MM_RESPAWN_DELAY <- 0.2;
    ::MM_RESPAWN_DISABLE <- false;

    // Don't want to reapply mods on multistage maps.
    if (!full_reset) return;

    MM_RespawnEndOfRound();
    MM_RespawnSetupEnd();
    MM_RespawnRedOnCap();
}

function MM_RespawnEndOfRound() {
    local gamerules = Entities.FindByClassname(null, "tf_gamerules");
    EntityOutputs.AddOutput(gamerules, "OnWonByTeam1", "!self", "RunScriptCode", "::MM_RESPAWN_DISABLE <- true", 0, -1);
    EntityOutputs.AddOutput(gamerules, "OnWonByTeam2", "!self", "RunScriptCode", "::MM_RESPAWN_DISABLE <- true", 0, -1);
}

function MM_RespawnSetupEnd() {
    for (local timer = null; timer = Entities.FindByClassname(timer, "team_round_timer");) {
        // EntityOutputs.AddOutput(timer, "OnSetupFinished", "!self", "RunScriptCode", "MM_RespawnTeam(2)", MM_RESPAWN_DELAY, -1);
        EntityOutputs.AddOutput(timer, "OnSetupFinished", "!self", "RunScriptCode", "MM_RespawnTeam(3)", MM_RESPAWN_DELAY, -1);
    }
}

function MM_RespawnRedOnCap() {
    for (local cp = null; cp = Entities.FindByClassname(cp, "team_control_point");) {
        EntityOutputs.AddOutput(cp, "OnCapTeam2", "!self", "RunScriptCode", "MM_RespawnTeam(2)", MM_RESPAWN_DELAY, -1);
    }
}

function MM_RespawnTeam(team) {
    if (MM_RESPAWN_DISABLE || (team != 2 && team != 3)) return;
    local spawner = Entities.CreateByClassname("game_forcerespawn");
    spawner.AcceptInput("ForceTeamRespawn", "" + team, null, null);
    spawner.Kill();
}