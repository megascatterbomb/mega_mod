// PLR Overtime System - Team-Agnostic Architecture
// This file should be included at the very start of the map-specific file.
// PLR_InitTeams() MUST be called in OnGameEvent_teamplay_round_start() before any other code.
//
// Team state is stored in PLR_TEAMS, indexed by TF2 team number (2=RED, 3=BLU, etc.)
// For 4-team maps, register teams 4 and 5 as well.

// ============================================================================
// CORE DATA STRUCTURE
// ============================================================================

::PLR_TEAMS <- {}  // team_num => state table
::PLR_UPDATE_DEPTH <- 0
::PLR_NEXT_CROSSING_ID <- 1
const PLR_MAX_UPDATE_DEPTH = 8  // N teams + safety margin

function PLR_RegisterTeam(team, config) {
    local rollbackSpeed = -1.0;
    local speed1 = 0.55;
    local speed2 = 0.77;
    local speed3 = 1.0;
    local overtimeSpeed = 0.22;

    if (config) {
        if ("rollbackSpeed" in config) rollbackSpeed = config.rollbackSpeed;
        if ("speed1" in config) speed1 = config.speed1;
        if ("speed2" in config) speed2 = config.speed2;
        if ("speed3" in config) speed3 = config.speed3;
        if ("overtimeSpeed" in config) overtimeSpeed = config.overtimeSpeed;
    }

    PLR_TEAMS[team] <- {
        cartsparks = null,
        flashinglight = null,
        pushzone = null,
        logiccase = null,
        train = null,
        watcher = null,
        rollstate = 0,
        pushstate = 0,
        blocked = false,
        crossing = 0,
        lastUpdate = Time(),
        rollbackSpeed = rollbackSpeed,
        speed1 = speed1,
        speed2 = speed2,
        speed3 = speed3,
        overtimeSpeed = overtimeSpeed,
        custom = {}
    };
}

function PLR_GetTeam(team) {
    if (!(team in PLR_TEAMS)) return null;
    return PLR_TEAMS[team];
}

function PLR_GetTeamCount() {
    local count = 0;
    foreach (team, state in PLR_TEAMS) count++;
    return count;
}

function PLR_ForEachTeam(callback) {
    foreach (team, state in PLR_TEAMS) {
        callback(team, state);
    }
}

function PLR_CountPushingEnemies(team) {
    local count = 0;
    foreach (other, state in PLR_TEAMS) {
        if (other != team && state.pushstate >= 1) count++;
    }
    return count;
}

// ============================================================================
// INITIALIZATION
// ============================================================================

function InitGlobalVars() {
    PLR_InitStandardTeams();
    PLR_InitTeams();
}

function PLR_InitStandardTeams() {
    ::PLR_TEAMS <- {};
    PLR_RegisterTeam(2, {});  // RED
    PLR_RegisterTeam(3, {});  // BLU
}

// For 4-team maps, call this after PLR_InitStandardTeams():
// PLR_RegisterTeam(4, {});  // GREEN
// PLR_RegisterTeam(5, {});  // YELLOW

function PLR_InitTeams() {
    ::PLR_TIMER <- null;
    ::PLR_TIMER_NAME <- null;
    ::OVERTIME_ACTIVE <- false;
    ::ROLLBACK_DISABLED <- false;
    ::MM_PLR_TIME_UPPER_LIMIT <- 1800;
    ::MM_PLR_TIME_LOWER_LIMIT <- 180;
    ::MM_PLR_MINIMUM_SPEED_RATIO <- 0.35;
    ::MM_PLR_MINIMUM_DELTA_RATIO <- 0.25;
    ::MM_PLR_MAXIMUM_DELTA_RATIO <- 0.65;

    local gamerules = Gamerules();
    local tcpMaster = Entities.FindByClassname(null, "team_control_point_master");
    EntFireByHandle(gamerules, "SetStalemateOnTimelimit", "0", 0, null, null);
    EntFireByHandle(tcpMaster, "AddOutput", "play_all_rounds 1", 0, null, null);
}

InitGlobalVars();

// ============================================================================
// TEAM-AGNOSTIC CORE FUNCTIONS
// ============================================================================

function PLR_Advance(team, baseSpeed, dynamic = true) {
    local t = PLR_GetTeam(team);
    if (dynamic) baseSpeed = PLR_CalculateDynamicSpeed(baseSpeed, team);

    foreach (spark in t.cartsparks) {
        EntFireByHandle(spark, "StopSpark", "", 0, null, null);
    }
    if (t.flashinglight) EntFireByHandle(t.flashinglight, "Start", "", 0, null, null);
    EntFireByHandle(t.train, "SetSpeedDirAccel", "" + baseSpeed, 0, null, null);

    t.lastUpdate = Time();
}

function PLR_Stop(team) {
    local t = PLR_GetTeam(team);

    foreach (spark in t.cartsparks) {
        EntFireByHandle(spark, "StopSpark", "", 0, null, null);
    }
    if (t.flashinglight) EntFireByHandle(t.flashinglight, "Stop", "", 0, null, null);
    EntFireByHandle(t.train, "SetSpeedDirAccel", "0.0", 0, null, null);

    local currentSpeed = NetProps.GetPropFloat(t.train, "m_flSpeed");
    if (currentSpeed == 0) EntFireByHandle(t.train, "Stop", "", 0, null, null);

    t.lastUpdate = Time();
}

function PLR_TriggerRollback(team, multiplier = 1.0) {
    local t = PLR_GetTeam(team);

    foreach (spark in t.cartsparks) {
        EntFireByHandle(spark, "StartSpark", "", 0, null, null);
    }
    if (t.flashinglight) EntFireByHandle(t.flashinglight, "Stop", "", 0, null, null);
    EntFireByHandle(t.train, "SetSpeedDirAccel", "" + (t.rollbackSpeed * multiplier), 0, null, null);

    t.lastUpdate = Time();
}

// ============================================================================
// UPDATE CART - MAIN STATE MACHINE
// ============================================================================

function PLR_UpdateCart(team, pushstate) {
    if (++PLR_UPDATE_DEPTH > PLR_MAX_UPDATE_DEPTH) {
        --PLR_UPDATE_DEPTH;
        return;  // Safety abort - prevent infinite loops
    }

    local t = PLR_GetTeam(team);
    local previousPushstate = t.pushstate;
    t.pushstate = pushstate;
    local N = PLR_GetTeamCount();

    // Early exit if blocked
    if (t.blocked) {
        --PLR_UPDATE_DEPTH;
        return;
    }

    // Phase 1: Pusher count
    if (pushstate == -1) {
        PLR_Stop(team);
        --PLR_UPDATE_DEPTH;
        return;
    }

    if (pushstate == 1) {
        PLR_Advance(team, t.speed1);
    } else if (pushstate == 2) {
        PLR_Advance(team, t.speed2);
    } else if (pushstate >= 3) {
        PLR_Advance(team, t.speed3);
    }

    // Phase 2: Zero pushers
    if (pushstate == 0) {
        if (OVERTIME_ACTIVE) {
            local k = PLR_CountPushingEnemies(team);

            // Calculate pressure-based multipliers
            local crawlMult = 0;
            if (k >= N - 1) {
                crawlMult = 0;  // Special case: full stop
            } else {
                crawlMult = 1.0 / (k + 1);
            }

            if (t.rollstate == -1 && !(OVERTIME_ACTIVE && ROLLBACK_DISABLED)) {
                // On uphill - decide between crawl and rollback based on pressure
                if (k >= N - 1) {
                    // All enemies pushing - full rollback
                    PLR_TriggerRollback(team, 1.0);
                } else if (k > 0) {
                    // Some enemies pushing - rollback at reduced speed
                    local rollbackMult = 1.0 / (N - k);
                    PLR_TriggerRollback(team, rollbackMult);
                } else {
                    // No enemies pushing - crawl
                    PLR_Advance(team, t.overtimeSpeed * crawlMult);
                }
            } else {
                // Flat ground or rollback disabled
                if (crawlMult > 0) {
                    PLR_Advance(team, t.overtimeSpeed * crawlMult);
                } else {
                    PLR_Stop(team);
                }
            }
        } else if (t.rollstate == -1 && !ROLLBACK_DISABLED) {
            PLR_TriggerRollback(team, 1.0);
        } else {
            PLR_Stop(team);
        }
    }

    // Phase 3: Overtime cascade
    if (OVERTIME_ACTIVE && pushstate >= 1) {
        // I just started pushing - reevaluate idle teams
        PLR_ForEachTeam(function(other, otherState) {
            if (other != team && otherState.pushstate == 0) {
                PLR_UpdateCart(other, 0);
            }
        });
    } else if (OVERTIME_ACTIVE && pushstate == 0 && previousPushstate >= 1) {
        // I just stopped pushing - check if all are now idle
        local allIdle = true;
        foreach (other, otherState in PLR_TEAMS) {
            if (other != team && otherState.pushstate >= 1) {
                allIdle = false;
                break;
            }
        }
        if (allIdle) {
            // Everyone idle during overtime - all crawl at full speed
            PLR_ForEachTeam(function(t2, s) {
                if (!s.blocked) {
                    PLR_Advance(t2, s.overtimeSpeed);
                }
            });
        }
    }

    --PLR_UPDATE_DEPTH;
}

// ============================================================================
// DYNAMIC SPEED CALCULATION
// ============================================================================

function PLR_CalculateDynamicSpeed(baseSpeed, teamNum) {
    local t = PLR_GetTeam(teamNum);
    local myProgress = NetProps.GetPropFloat(t.watcher, "m_flTotalProgress");

    // For 2-team: compare against the other team
    if (PLR_GetTeamCount() == 2) {
        local otherTeam = teamNum == 2 ? 3 : 2;
        local otherState = PLR_GetTeam(otherTeam);
        local otherProgress = NetProps.GetPropFloat(otherState.watcher, "m_flTotalProgress");

        // If this cart is behind, don't slow down
        if (teamNum == 3 && myProgress < otherProgress) return baseSpeed;
        if (teamNum == 2 && myProgress > otherProgress) return baseSpeed;

        local distance = fabs(myProgress - otherProgress);

        if (distance < MM_PLR_MINIMUM_DELTA_RATIO) return baseSpeed;
        else if (distance > MM_PLR_MAXIMUM_DELTA_RATIO) return baseSpeed * MM_PLR_MINIMUM_SPEED_RATIO;

        local scaledDistance = (distance - MM_PLR_MINIMUM_DELTA_RATIO) / (MM_PLR_MAXIMUM_DELTA_RATIO - MM_PLR_MINIMUM_DELTA_RATIO);
        local speedRatio = 1 - scaledDistance * (1 - MM_PLR_MINIMUM_SPEED_RATIO);
        return baseSpeed * speedRatio;
    }

    // For 4-team: compare against the closest competitor
    local closestDistance = 1.0;
    foreach (other, otherState in PLR_TEAMS) {
        if (other == teamNum) continue;
        local otherProgress = NetProps.GetPropFloat(otherState.watcher, "m_flTotalProgress");
        local distance = fabs(myProgress - otherProgress);
        if (distance < closestDistance) closestDistance = distance;
    }

    if (closestDistance < MM_PLR_MINIMUM_DELTA_RATIO) return baseSpeed;
    else if (closestDistance > MM_PLR_MAXIMUM_DELTA_RATIO) return baseSpeed * MM_PLR_MINIMUM_SPEED_RATIO;

    local scaledDistance = (closestDistance - MM_PLR_MINIMUM_DELTA_RATIO) / (MM_PLR_MAXIMUM_DELTA_RATIO - MM_PLR_MINIMUM_DELTA_RATIO);
    local speedRatio = 1 - scaledDistance * (1 - MM_PLR_MINIMUM_SPEED_RATIO);
    return baseSpeed * speedRatio;
}

// ============================================================================
// SETUP HELPERS
// ============================================================================

function PLR_CreateLogicCase(team, name) {
    local logicCase = SpawnEntityFromTable("logic_case", {
        targetname = name,
        Case01 = "-1",
        Case02 = "0",
        Case03 = "1",
        Case04 = "2"
    });
    PLR_AddCaptureOutputsToLogicCase(team, logicCase);
    return logicCase;
}

function PLR_AddCaptureOutputsToLogicCase(team, entity) {
    EntityOutputs.AddOutput(entity, "OnCase01", "!self", "RunScriptCode",
        "PLR_UpdateCart(" + team + ", -1)", 0, -1);
    EntityOutputs.AddOutput(entity, "OnCase02", "!self", "RunScriptCode",
        "PLR_UpdateCart(" + team + ", 0)", 0, -1);
    EntityOutputs.AddOutput(entity, "OnCase03", "!self", "RunScriptCode",
        "PLR_UpdateCart(" + team + ", 1)", 0, -1);
    EntityOutputs.AddOutput(entity, "OnCase04", "!self", "RunScriptCode",
        "PLR_UpdateCart(" + team + ", 2)", 0, -1);
    EntityOutputs.AddOutput(entity, "OnDefault", "!self", "RunScriptCode",
        "PLR_UpdateCart(" + team + ", 3)", 0, -1);
}

function PLR_AddRollbackZone(team, startPath, endPath, disablePath) {
    local t = PLR_GetTeam(team);
    local sparksName = t.cartsparks[0].GetName();

    EntityOutputs.AddOutput(MM_GetEntByName(startPath), "OnPass", sparksName,
        "StopSpark", "", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName(startPath), "OnPass", disablePath,
        "DisablePath", "", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName(startPath), "OnPass", "!self",
        "RunScriptCode", "PLR_RollbackStart(" + team + ")", 0, -1);
    if (endPath) {
        EntityOutputs.AddOutput(MM_GetEntByName(endPath), "OnPass", "!self",
            "RunScriptCode", "PLR_RollbackEnd(" + team + ")", 0, -1);
    }
}

function PLR_AddRollforwardZone(team, startPath, endPath, disablePath) {
    EntityOutputs.AddOutput(MM_GetEntByName(startPath), "OnPass", "!self",
        "RunScriptCode", "PLR_RollforwardStart(" + team + ")", 0, -1);
    if (endPath) {
        EntityOutputs.AddOutput(MM_GetEntByName(endPath), "OnPass", "!self",
            "RunScriptCode", "PLR_RollforwardEnd(" + team + ")", 0, -1);
        EntityOutputs.AddOutput(MM_GetEntByName(endPath), "OnPass", disablePath,
            "DisablePath", "", 0, -1);
    }
}

// AddCrossing: Register one or more teams on a shared crossing.
// teams: Array of [startPath, endPath, team] triplets.
// The crossing ID is auto-generated.
// Example: AddCrossing([["red_start", "red_end", 2], ["blu_start", "blu_end", 3]])
function AddCrossing(teams) {
    local crossingID = PLR_NEXT_CROSSING_ID++;
    if (teams.len() < 2) {
        throw "AddCrossing requires at least 2 teams";
    }
    local registeredTeams = {};
    for (local i = 0; i < teams.len(); i++) {
        local group = teams[i];
        if (group.len() != 3) {
            throw "AddCrossing team group must have exactly 3 elements: [startPath, endPath, team]";
        }
        local startPath = group[0];
        local endPath = group[1];
        local team = group[2];
        if (team in registeredTeams) {
            throw "AddCrossing: Team " + team + " registered twice on crossing " + crossingID;
        }
        registeredTeams[team] = true;
        EntityOutputs.AddOutput(MM_GetEntByName(startPath), "OnPass", "!self",
            "RunScriptCode", "PLR_SetCrossing(" + team + ", " + crossingID + ")", 0, -1);
        EntityOutputs.AddOutput(MM_GetEntByName(endPath), "OnPass", "!self",
            "RunScriptCode", "PLR_SetCrossing(" + team + ", 0)", 0, -1);
    }
}


function PLR_CreateCartAutoUpdater(team, cart) {
    local thinkName = "PLR_CartThink_" + team;
    local capturedTeam = team;
    local root = getroottable();
    root[thinkName] <- function() { return PLR_CartThink(capturedTeam); };
    AddThinkToEnt(cart, thinkName);
}

// ============================================================================
// CROSSING LOGIC
// ============================================================================

function PLR_SetCrossing(team, crossingID) {
    local t = PLR_GetTeam(team);

    if (crossingID == 0) {
        // Exited a crossing - unblock this team
        t.crossing = 0;
        t.pushzone.AcceptInput("Enable", "", null, null);
        PLR_BlockCart(team, false);

        // Wake up any other team waiting on the same crossing
        PLR_ForEachTeam(function(other, otherState) {
            if (other != team && otherState.crossing == t._waitingCrossing) {
                // The crossing is now free - let the waiting team proceed slowly
                otherState._waitingCrossing = 0;
                otherState.pushzone.AcceptInput("Enable", "", null, null);
                PLR_BlockCart(other, false);
                EntFireByHandle(otherState.train, "RunScriptCode",
                    "PLR_Advance(" + other + ", " + otherState.speed1 + ", false)", 0.5, null, null);
            }
        });
    } else {
        // Entering a crossing
        local conflict = false;
        local waitingTeam = null;

        // Check if any other team is already in this crossing
        PLR_ForEachTeam(function(other, otherState) {
            if (other != team && otherState.crossing == crossingID) {
                conflict = true;
                waitingTeam = other;
            }
        });

        if (conflict) {
            // Another team is in this crossing - stop and wait
            t.crossing = crossingID;
            t._waitingCrossing <- crossingID;
            t.pushzone.AcceptInput("Disable", "", null, null);
            PLR_BlockCart(team, true);
            PLR_Stop(team);
        } else {
            // Crossing is clear - enter it
            t.crossing = crossingID;
        }
    }
}

// ============================================================================
// ROLLBACK/ROLLFORWARD
// ============================================================================

function PLR_RollbackStart(team) {
    PLR_TEAMS[team].rollstate = -1;
}

function PLR_RollbackEnd(team) {
    PLR_TEAMS[team].rollstate = 0;
}

function PLR_RollforwardStart(team) {
    local t = PLR_TEAMS[team];
    t.rollstate = 1;
    t.pushzone.AcceptInput("Disable", "", null, null);
    PLR_BlockCart(team, true);
    PLR_Advance(team, 1, false);
}

function PLR_RollforwardEnd(team) {
    local t = PLR_TEAMS[team];
    t.rollstate = 0;
    PLR_BlockCart(team, false);
    t.pushzone.AcceptInput("Enable", "", null, null);
}

// ============================================================================
// BLOCKING
// ============================================================================

function PLR_BlockCart(team, blocked) {
    PLR_TEAMS[team].blocked = blocked;
    PLR_ForEachTeam(function(other, state) {
        if (other != team) PLR_UpdateCart(other, state.pushstate);
    });
    PLR_UpdateCart(team, PLR_TEAMS[team].pushstate);
}

// ============================================================================
// CART THINK
// ============================================================================

function PLR_CartThink(team) {
    local t = PLR_GetTeam(team);
    local updateInterval = 2.5;
    if (Time() - t.lastUpdate > updateInterval && t.rollstate == 0) {
        t.lastUpdate = Time();
        PLR_UpdateCart(team, t.pushstate);
    }
    local timeUntilNextCheck = updateInterval - (Time() - t.lastUpdate);
    if (timeUntilNextCheck < 0.5) timeUntilNextCheck = 0.5;
    return timeUntilNextCheck;
}

// ============================================================================
// ROUND MANAGEMENT
// ============================================================================

function StartOvertime() {
    ::OVERTIME_ACTIVE <- true;
    if (PLR_TIMER && PLR_TIMER.IsValid()) PLR_TIMER.Kill();
    PLR_ForEachTeam(function(team, state) {
        PLR_UpdateCart(team, state.pushstate);
    });
}

function ForceStopCarts() {
    if (PLR_TIMER && PLR_TIMER.IsValid()) PLR_TIMER.Kill();
    ::OVERTIME_ACTIVE <- false;
    ::ROLLBACK_DISABLED <- false;
    PLR_ForEachTeam(function(team, state) {
        state.blocked = true;
        PLR_Stop(team);
    });
}

function ResetCartStates() {
    ::OVERTIME_ACTIVE <- false;
    ::ROLLBACK_DISABLED <- false;
    local now = Time();
    PLR_ForEachTeam(function(team, state) {
        state.rollstate = 0;
        state.blocked = false;
        state.lastUpdate = now;
    });
    PLR_ForEachTeam(function(team, state) {
        PLR_UpdateCart(team, 0);
    });
}

function DisableOvertimeRollback() {
    if (ROLLBACK_DISABLED) return;
    ::ROLLBACK_DISABLED <- true;
    if (!OVERTIME_ACTIVE) return;
    AnnounceRollbackDisabled();
    if (PLR_TIMER && PLR_TIMER.IsValid()) PLR_TIMER.Kill();
}

function AnnounceRollbackDisabled() {
    local text_tf = SpawnEntityFromTable("game_text_tf", {
        message = "Rollback zones disabled!",
        icon = "timer_icon",
        background = 0,
        display_to_team = 0
    });
    EntFireByHandle(text_tf, "Display", "", 0.1, self, self);
    EntFireByHandle(text_tf, "Kill", "", 7, self, self);
}

// ============================================================================
// TIMER HELPERS
// ============================================================================

function GetRoundTimeString(setup = 0) {
    return "" + GetRoundTime(setup);
}

function GetRoundTime(setup = 0) {
    local time = MM_PLR_TIME_UPPER_LIMIT;
    local timeRemaining = MM_GetTimelimitRemaining();
    if (timeRemaining != null) time = ceil(timeRemaining / 30) * 30;
    if (time > MM_PLR_TIME_UPPER_LIMIT) time = MM_PLR_TIME_UPPER_LIMIT;
    if (time < MM_PLR_TIME_LOWER_LIMIT) time = MM_PLR_TIME_LOWER_LIMIT;
    return time;
}

// ============================================================================
// ROUND WIN
// ============================================================================

function OnGameEvent_teamplay_round_win(params) {
    if (params.team == 2) {
        WinRed();
    } else if (params.team == 3) {
        WinBlu();
    } else {
        ForceStopCarts();
    }
}

function WinRed() {
    ForceStopCarts();
}

function WinBlu() {
    ForceStopCarts();
}

// ============================================================================
// LEGACY ALIASES (for entity output strings that use old function names)
// These use the team string "Red"/"Blu" to determine team number.
// Map mods should migrate to PLR_* versions.
// ============================================================================

function CreateLogicCase(name, team) {
    local t = team == "Red" ? 2 : 3;
    return PLR_CreateLogicCase(t, name);
}

function AddCaptureOutputsToLogicCase(entity, team) {
    local t = team == "Red" ? 2 : 3;
    PLR_AddCaptureOutputsToLogicCase(t, entity);
}

function AddRollbackZone(startPath, endPath, disablePath, team) {
    local t = team == "Red" ? 2 : 3;
    PLR_AddRollbackZone(t, startPath, endPath, disablePath);
}

function AddRollforwardZone(startPath, endPath, disablePath, team) {
    local t = team == "Red" ? 2 : 3;
    PLR_AddRollforwardZone(t, startPath, endPath, disablePath);
}


function CreateCartAutoUpdater(cart, team) {
    PLR_CreateCartAutoUpdater(team, cart);
}
