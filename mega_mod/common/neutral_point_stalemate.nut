// If the netural point hasn't been capped when mp_timelimit expires, end the map.
// Intended for use on koth and 5cp maps to prevent indefinite stalling of a mapchange.

// Recommended to use alongside no_truce mod for koth_lakeside_event and koth_viaduct_event for best results,
// otherwise the map will end whenever a boss spawns.

// Include this file in OnGameEvent_teamplay_round_start

::MM_NEUTRAL_POINT_STALEMATE_TRIGGERED <- false;
::MM_NEUTRAL_POINT_CAPPED <- false;

::MM_NEUTRAL_POINT_STALEMATE_THINK <- function () {

    local neutralPointPresent = false;
    local neutralPointPresentAndUnlocked = false;

    for (local cp = null; cp = Entities.FindByClassname(cp, "team_control_point");) {
        local owner = cp.GetTeam();
        local locked = NetProps.GetPropBool(cp, "m_bLocked");

        // Point may be locked if there's a halloween boss active, let the bossfight play out then stalemate.
        if (owner == 0) {
            neutralPointPresent = true;
            if (!locked) {
                neutralPointPresentAndUnlocked = true;
            }
            break;
        }
    }

    if (neutralPointPresentAndUnlocked && !MM_NEUTRAL_POINT_CAPPED) {
        local gamerules = Gamerules();
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
    } else if (!neutralPointPresent) {
        MM_NEUTRAL_POINT_CAPPED <- true;
    }

    return 1;
}

// Force mp_match_end_at_timelimit to 0 as we don't want the game ending the map for us.
local matchEndAtTimelimit = Convars.GetBool("mp_match_end_at_timelimit");

if(matchEndAtTimelimit) {
    Convars.SetValue("mp_match_end_at_timelimit", 0);
}

EntFireByHandle(Gamerules(), "SetStalemateOnTimelimit", "0", 5, null, null);


MM_CreateDummyThink("MM_NEUTRAL_POINT_STALEMATE_THINK");