// If a neutral point is present when mp_timelimit expires, end the map.
// Intended for use on koth and 5cp maps to prevent indefinite stalling of a mapchange

// Include this file in OnGameEvent_teamplay_round_start

::MM_NEUTRAL_POINT_STALEMATE_TRIGGERED <- false;

::MM_NEUTRAL_POINT_STALEMATE_THINK <- function () {

    local neutralPointPresent = false;

    for (local cp = null; cp = Entities.FindByClassname(cp, "team_control_point");) {
        local owner = cp.GetTeam();
        if (owner == 0) {
            neutralPointPresent = true;
            break;
        }
    }

    if (neutralPointPresent) {
        local gamerules = Entities.FindByClassname(null, "tf_gamerules");
        local mp_timelimit = Convars.GetInt("mp_timelimit");

        if (mp_timelimit != null && mp_timelimit > 0 && !MM_NEUTRAL_POINT_STALEMATE_TRIGGERED) {

            local remainingTime = (mp_timelimit * 60) - (Time() - NetProps.GetPropFloat(gamerules, "m_flMapResetTime"));
            if(remainingTime < 0) {
                ::MM_NEUTRAL_POINT_STALEMATE_TRIGGERED <- true;
                local stalemate = SpawnEntityFromTable("game_round_win", {
                    force_map_reset = true // prevents crashes
                    TeamNum = 0
                });
                EntFireByHandle(stalemate, "RoundWin", "", 0, null, null);
            }
        }
    }

    return 1;
}

// Force mp_match_end_at_timelimit to 0 as we don't want the game ending the map for us.
local matchEndAtTimelimit = Convars.GetBool("mp_match_end_at_timelimit");

if(matchEndAtTimelimit) {
    Convars.SetValue("mp_match_end_at_timelimit", 0);
}

EntFireByHandle(Entities.FindByClassname(null, "tf_gamerules"), "SetStalemateOnTimelimit", "0", 5, null, null);


MM_CreateDummyThink("MM_NEUTRAL_POINT_STALEMATE_THINK");