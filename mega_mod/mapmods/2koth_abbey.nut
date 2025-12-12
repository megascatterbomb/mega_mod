ClearGameEventCallbacks()

function RewireTimer(team, forceTimer) {
	// SetMaxValueNoFire does not exist in TF2, so we have to recreate the counters.
	MM_GetEntByName("math_counter_red").Kill();
	MM_GetEntByName("math_counter_blue").Kill();

	local redCounter = SpawnEntityFromTable("math_counter", {
		targetname = "math_counter_red"
		startvalue = "0"
		max = "1"
		"OnHitMax#1" : "relay_red_timer,Trigger,,0,-1"
	});
	local bluCounter = SpawnEntityFromTable("math_counter", {
		targetname = "math_counter_blue"
		startvalue = "0"
		max = "1"
		"OnHitMax#1" : "relay_blue_timer,Trigger,,0,-1"
	});

	// We don't need to fire the outputs if we expect the correct timer to already be ticking.
	local input = forceTimer ? "SetValue" : "SetValueNoFire";
	local targetCounter = team == 2 ? redCounter : bluCounter;
	EntFireByHandle(targetCounter, input, "1", 0, null, null);
}

::MM_NEUTRAL_POINT_STALEMATE_THINK <- function () {

	local redPoints = [];
	local bluPoints = [];
	local neutralPoints = [];

	for (local cp = null; cp = Entities.FindByClassname(cp, "team_control_point");) {
		local owner = cp.GetTeam();

		// Point may be locked if there's a halloween boss active, let the bossfight play out then stalemate.
		switch (owner) {
			case 0:
				neutralPoints.append(cp);
				break;
			case 2:
				redPoints.append(cp);
				break;
			case 3:
				bluPoints.append(cp);
				break;
		}
	}

	// TODO: Check for in-progress captures
	if (MM_NEUTRAL_POINT_STALEMATE_TRIGGERED) {
		return 1;
	}

	if (neutralPoints.len() == 2) { // Stalemate round
		local stalemate = SpawnEntityFromTable("game_round_win", {
			force_map_reset = true // prevents crashes
			TeamNum = 0
		});
		EntFireByHandle(stalemate, "RoundWin", "", 0, null, null);
	} else if (neutralPoints.len() == 1) { // Lock neutral point, play regular koth on remaining point.
		local neutralPoint = neutralPoints[0];
		local timerTeam = redPoints.len() == 1 ? 2 : 3;
		local pointToUse = redPoints.len() == 1 ? redPoints[0] : bluPoints[0];
		EntFireByHandle(neutralPoint, "SetLocked", "1", 0, null, null);
		RewireTimer(timerTeam, false);
	} else if (redPoints.len() == bluPoints.len()) { // Lock point for team with more time remaining
		local redTimer = MM_GetEntByName("zz_red_koth_timer");
		local bluTimer = MM_GetEntByName("zz_blue_koth_timer");

		local redTimeRemaining = min(GetPropFloat(redTimer, "m_flTimerEndTime") - Time(), GetPropFloat(redTimer, "m_flTimeRemaining"));
		local bluTimeRemaining = min(GetPropFloat(bluTimer, "m_flTimerEndTime") - Time(), GetPropFloat(bluTimer, "m_flTimeRemaining"));

		local timerTeam = redTimeRemaining > bluTimeRemaining ? 2 : 3;
		local pointToLock = redTimeRemaining > bluTimeRemaining ? redPoints[0] : bluPoints[0];
		local pointToUse = redTimeRemaining > bluTimeRemaining ? bluPoints[0] : redPoints[0];

		EntFireByHandle(pointToLock, "SetLocked", "1", 0, null, null);
		EntFireByHandle(pointToLock, "SetOwner", "0", 0, null, null);
		RewireTimer(timerTeam, true);
	} else { // One team controls both points, lock a random point.
		local timerTeam = redPoints.len() == 2 ? 2 : 3;
		local points = redPoints.len() == 2 ? redPoints : bluPoints;
		local i = RandomInt(0, 1);
		local pointToLock = points[i];
		EntFireByHandle(pointToLock, "SetLocked", "1", 0, null, null);
		EntFireByHandle(pointToLock, "SetOwner", "0", 0, null, null);
		local pointToUse = points[1 - i];
		RewireTimer(timerTeam, false);
	}

	return 1;
}

function OnGameEvent_teamplay_round_start(params)
{

	::MM_NEUTRAL_POINT_STALEMATE_TRIGGERED <- false;

    // Force mp_match_end_at_timelimit to 0 as we don't want the game ending the map for us.
    local matchEndAtTimelimit = Convars.GetBool("mp_match_end_at_timelimit");

    if(matchEndAtTimelimit) {
    	Convars.SetValue("mp_match_end_at_timelimit", 0);
    }

    EntFireByHandle(Gamerules(), "SetStalemateOnTimelimit", "0", 5, null, null);


    MM_CreateDummyThink("MM_NEUTRAL_POINT_STALEMATE_THINK");
}

__CollectGameEventCallbacks(this)