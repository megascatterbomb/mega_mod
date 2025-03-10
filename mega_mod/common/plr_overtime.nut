::MM_PLR_TIME_UPPER_LIMIT <- 600;
::MM_PLR_TIME_LOWER_LIMIT <- 90;

// If true, disables the rollback zones entirely after 5 minutes pass during overtime.
// If false, then rollback zones still work if the other cart is actively pushed.
::MM_PLR_DISABLE_ROLLBACK_IF_OVERTIME_LONG <- false;

// REQUIRED GLOBAL VARIABLES
// This file should be included at the very start of the map-specific file.
// Every global variable MUST be set by the map-specific file in OnGameEvent_teamplay_round_start() after a call to InitGlobalVars()

function InitGlobalVars() {

    // team_round_timer
    ::PLR_TIMER <- null;
    ::PLR_TIMER_NAME <- null;

    // Array of all env_spark handles for each cart.
    ::RED_CARTSPARKS_ARRAY <- null;
    ::BLU_CARTSPARKS_ARRAY <- null;

    // info_particle_system for the cart's light
    ::RED_FLASHINGLIGHT <- null;
    ::BLU_FLASHINGLIGHT <- null;

    // trigger_capture_area for the cart
    ::RED_PUSHZONE <- null;
    ::BLU_PUSHZONE <- null;

    // logic_case which accepts OnNumCappersChanged2 inputs
    ::RED_LOGICCASE <- null;
    ::BLU_LOGICCASE <- null;

    // 0 if on flat ground, -1 if rolling back, 1 if rolling forward
    ::RED_ROLLSTATE <- 0;
    ::BLU_ROLLSTATE <- 0;

    // func_tracktrain for the cart itself
    ::RED_TRAIN <- null;
    ::BLU_TRAIN <- null;

    // Number of players on the cart, as decided by the logic_case (does not correspond to case numbers within the logic_case)
    // -1 means cart is blocked, anything >= 0 means the number of cappers.
    ::CASE_RED <- 0
    ::CASE_BLU <- 0

    // Is the cart being controlled by something else? (e.g. is it being guided through a crossing?)
    ::BLOCK_RED <- false;
    ::BLOCK_BLU <- false;

    // Which crossing is the cart currently at?
    // Crossings should be numbered by the order they're encountered for the BLU cart, starting at 1.
    // 0 means the cart hasn't encountered a crossing.
    // >0 means the cart has reached/is going through a crossing.
    // <0 means the cart has completely passed through said crossing. It will keep this value until another crossing is reached.
    ::CROSSING_RED <- 0;
    ::CROSSING_BLU <- 0;

    ::TIMES_1_SPEED_RED <- 0.55;
    ::TIMES_2_SPEED_RED <- 0.77;
    ::TIMES_3_SPEED_RED <- 1.0;

    ::TIMES_1_SPEED_BLU <- 0.55;
    ::TIMES_2_SPEED_BLU <- 0.77;
    ::TIMES_3_SPEED_BLU <- 1.0;

    ::OVERTIME_SPEED_RED <- 0.22;
    ::OVERTIME_SPEED_BLU <- 0.22;

    ::OVERTIME_ACTIVE <- false;
    ::ROLLBACK_DISABLED <- false;
}

InitGlobalVars();

function GetRoundTimeString() {
    return "" + GetRoundTime();
}

function GetRoundTime() {
    local time = MM_PLR_TIME_UPPER_LIMIT;
    local gamerules = Entities.FindByClassname(null, "tf_gamerules");
    local mp_timelimit = Convars.GetInt("mp_timelimit");
    // If mp_timelimit is close, adjust the round timer to prevent excessive maptime.
    if (mp_timelimit != null && mp_timelimit > 0) {
        local remainingTime = (mp_timelimit * 60) - (Time() - NetProps.GetPropFloat(gamerules, "m_flMapResetTime"));

        if(remainingTime < time) {
            time = ceil(remainingTime / 30) * 30;
        }
    }

    if (time > MM_PLR_TIME_UPPER_LIMIT) time = MM_PLR_TIME_UPPER_LIMIT;
    if (time < MM_PLR_TIME_LOWER_LIMIT) time = MM_PLR_TIME_LOWER_LIMIT;

    return time;
}

// We use a logic case to capture the value obtained from OnNumCappersChanged2
// name: targetname of logic_case
// team: "Red" or "Blu"
function CreateLogicCase(name, team) {
    local logicCase = SpawnEntityFromTable("logic_case", {
        targetname = name,
        Case01 = "-1",
        Case02 = "0",
        Case03 = "1",
        Case04 = "2"
    });
    AddCaptureOutputsToLogicCase(logicCase, team);
    return logicCase;
}

// entity: handle of logic_case
// team: "Red" or "Blu"
function AddCaptureOutputsToLogicCase(entity, team) {
    EntityOutputs.AddOutput(entity, "OnCase01", "!self", "RunScriptCode", "Update" + team + "Cart(-1)", 0, -1); // Blocked
    EntityOutputs.AddOutput(entity, "OnCase02", "!self", "RunScriptCode", "Update" + team + "Cart(0)", 0, -1); // 0 cap
    EntityOutputs.AddOutput(entity, "OnCase03", "!self", "RunScriptCode", "Update" + team + "Cart(1)", 0, -1); // 1 cap
    EntityOutputs.AddOutput(entity, "OnCase04", "!self", "RunScriptCode", "Update" + team + "Cart(2)", 0, -1); // 2 cap
    EntityOutputs.AddOutput(entity, "OnDefault", "!self", "RunScriptCode", "Update" + team + "Cart(3)", 0, -1); // 3+ cap
}

function StartOvertime() {
    ::OVERTIME_ACTIVE <- true;
    if(ROLLBACK_DISABLED && MM_PLR_DISABLE_ROLLBACK_IF_OVERTIME_LONG) {
        AnnounceRollbackDisabled();
    } else if (MM_PLR_DISABLE_ROLLBACK_IF_OVERTIME_LONG) {
        if(PLR_TIMER && PLR_TIMER.IsValid()) PLR_TIMER.Kill();
        ::PLR_TIMER <- SpawnEntityFromTable("team_round_timer", {
            reset_time = 1,
            setup_length = 0,
            start_paused = 0,
            targetname = PLR_TIMER_NAME,
            timer_length = 300,
            "OnFinished#1" : "!self,RunScriptCode,DisableRollback(),0,1"
        });
        local text_tf = SpawnEntityFromTable("game_text_tf", {
            message = "Overtime!",
            icon = "timer_icon",
            background = 0,
            display_to_team = 0
        });

        EntFireByHandle(PLR_TIMER, "ShowInHud", "1", 0, null, null);
        EntFireByHandle(PLR_TIMER, "Resume", "1", 0, null, null);
        EntFireByHandle(text_tf, "Display", "", 0.1, self, self);
        EntFireByHandle(text_tf, "Kill", "", 7, self, self);
    } else {
        if(PLR_TIMER && PLR_TIMER.IsValid()) PLR_TIMER.Kill();
    }

    UpdateRedCart(CASE_RED);
    UpdateBluCart(CASE_BLU);
}

// These functions determine the cart behaviour depending on number of pushing players.

function UpdateRedCart(caseNumber) {
    ::CASE_RED = caseNumber;

    if(BLOCK_RED) return;

    if(CASE_RED == 1) {
        AdvanceRed(TIMES_1_SPEED_RED);
    } else if(CASE_RED == 2) {
        AdvanceRed(TIMES_2_SPEED_RED);
    } else if(CASE_RED >= 3) {
        AdvanceRed(TIMES_3_SPEED_RED);
    } else if (CASE_RED == -1) {
        StopRed();
    }

    if(CASE_RED == 0) {
        if(CASE_BLU == 0 && OVERTIME_ACTIVE) {
            AdvanceRed(OVERTIME_SPEED_RED);
            if(!BLOCK_BLU) AdvanceBlu(OVERTIME_SPEED_BLU);
        } else if (!(OVERTIME_ACTIVE && ROLLBACK_DISABLED) && RED_ROLLSTATE == -1) {
            TriggerRollbackRed();
        } else {
            StopRed();
        }
    } else if (OVERTIME_ACTIVE && CASE_BLU == 0) {
        UpdateBluCart(0);
    }
}

function UpdateBluCart(caseNumber) {
    ::CASE_BLU = caseNumber;

    if(BLOCK_BLU) return;

    if(CASE_BLU == 1) {
        AdvanceBlu(TIMES_1_SPEED_BLU);
    } else if(CASE_BLU == 2) {
        AdvanceBlu(TIMES_2_SPEED_BLU);
    } else if(CASE_BLU >= 3) {
        AdvanceBlu(TIMES_3_SPEED_BLU);
    } else if (CASE_BLU == -1) {
        StopBlu();
    }

    if(CASE_BLU == 0) {
        if(CASE_RED == 0 && OVERTIME_ACTIVE) {
            AdvanceBlu(OVERTIME_SPEED_BLU);
            if(!BLOCK_RED) AdvanceRed(OVERTIME_SPEED_RED);
        } else if (!(OVERTIME_ACTIVE && ROLLBACK_DISABLED) && BLU_ROLLSTATE == -1) {
            TriggerRollbackBlu();
        } else {
            StopBlu();
        }
    } else if (OVERTIME_ACTIVE && CASE_RED == 0) {
        UpdateRedCart(0);
    }
}

// Called by other code to directly control the cart.

function AdvanceRed(speed) {
    foreach(spark in RED_CARTSPARKS_ARRAY) {
        EntFireByHandle(spark, "StopSpark", "", 0, null, null);
    }
    if(RED_FLASHINGLIGHT) EntFireByHandle(RED_FLASHINGLIGHT, "Start", "", 0, null, null);
    EntFireByHandle(RED_TRAIN, "SetSpeedDirAccel", "" + speed, 0, null, null);
}

function StopRed() {
    foreach(spark in RED_CARTSPARKS_ARRAY) {
        EntFireByHandle(spark, "StopSpark", "", 0, null, null);
    }
    if(RED_FLASHINGLIGHT) EntFireByHandle(RED_FLASHINGLIGHT, "Stop", "", 0, null, null);
    EntFireByHandle(RED_TRAIN, "SetSpeedDirAccel", "0.0", 0, null, null);
}

function TriggerRollbackRed() {
    foreach(spark in RED_CARTSPARKS_ARRAY) {
        EntFireByHandle(spark, "StartSpark", "", 0, null, null);
    }
    if(RED_FLASHINGLIGHT) EntFireByHandle(RED_FLASHINGLIGHT, "Stop", "", 0, null, null);
    EntFireByHandle(RED_TRAIN, "SetSpeedDirAccel", "-1", 0, null, null);
}

function AdvanceBlu(speed) {
    foreach(spark in BLU_CARTSPARKS_ARRAY) {
        EntFireByHandle(spark, "StopSpark", "", 0, null, null);
    }
    if(BLU_FLASHINGLIGHT) EntFireByHandle(BLU_FLASHINGLIGHT, "Start", "", 0, null, null);
    EntFireByHandle(BLU_TRAIN, "SetSpeedDirAccel", "" + speed, 0, null, null);
}

function StopBlu() {
    foreach(spark in BLU_CARTSPARKS_ARRAY) {
        EntFireByHandle(spark, "StopSpark", "", 0, null, null);
    }
    if(BLU_FLASHINGLIGHT) EntFireByHandle(BLU_FLASHINGLIGHT, "Stop", "", 0, null, null);
    EntFireByHandle(BLU_TRAIN, "SetSpeedDirAccel", "0.0", 0, null, null);
}

function TriggerRollbackBlu() {
    foreach(spark in BLU_CARTSPARKS_ARRAY) {
        EntFireByHandle(spark, "StartSpark", "", 0, null, null);
    }
    if(BLU_FLASHINGLIGHT) EntFireByHandle(BLU_FLASHINGLIGHT, "Stop", "", 0, null, null);
    EntFireByHandle(BLU_TRAIN, "SetSpeedDirAccel", "-1", 0, null, null);
}

// Called by path_track as the cart enters and exits rollback/rollforward zones

function RollbackStartRed() {
    ::RED_ROLLSTATE <- -1;
}

function RollbackEndRed() {
    ::RED_ROLLSTATE <- 0;
}

function RollforwardStartRed() {
    ::RED_ROLLSTATE <- 1;
    RED_PUSHZONE.AcceptInput("Disable", "", null, null);
    BlockRedCart(true);
    AdvanceRed(TIMES_3_SPEED_RED);
}

function RollforwardEndRed() {
    ::RED_ROLLSTATE <- 0;
    BlockRedCart(false);
    RED_PUSHZONE.AcceptInput("Enable", "", null, null);
}

function RollbackStartBlu() {
    ::BLU_ROLLSTATE <- -1;
}

function RollbackEndBlu() {
    ::BLU_ROLLSTATE <- 0;
}

function RollforwardStartBlu() {
    ::BLU_ROLLSTATE <- 1;
    BLU_PUSHZONE.AcceptInput("Disable", "", null, null);
    BlockBluCart(true);
    AdvanceBlu(1);
}

function RollforwardEndBlu() {
    ::BLU_ROLLSTATE <- 0;
    BlockBluCart(false);
    BLU_PUSHZONE.AcceptInput("Enable", "", null, null);
}

// This is for situations where the game takes control of the cart, like onboarding the cart to the Hightower elevators.
// Don't use these functions to handle crossings; use SetRedCrossing/SetBluCrossing instead.

function BlockRedCart(blocked) {
    ::BLOCK_RED <- blocked;
    UpdateRedCart(CASE_RED);
    UpdateBluCart(CASE_BLU);
}

function BlockBluCart(blocked) {
    ::BLOCK_BLU <- blocked;
    UpdateBluCart(CASE_BLU);
    UpdateRedCart(CASE_RED);
}

// These functions set the crossing value, then block the cart from being updated
// if it's the first cart to reach that crossing.
function SetRedCrossing(crossing) {
    ::CROSSING_RED <- crossing;
    // If we exited a crossing.
    if(CROSSING_RED <= 0) {
        RED_PUSHZONE.AcceptInput("Enable", "", null, null);
        BlockRedCart(false);
        // If the other cart is waiting at the crossing we just exited.
        if(CROSSING_RED == -CROSSING_BLU) {
            BLU_PUSHZONE.AcceptInput("Enable", "", null, null);
            BlockBluCart(false);
        }
    // If we entered a crossing and the other cart is going through the same crossing.
    } else if (CROSSING_RED == CROSSING_BLU) {
        RED_PUSHZONE.AcceptInput("Disable", "", null, null);
        BlockRedCart(true);
        StopRed();
    // If we entered a crossing and the other cart hasn't reached this crossing yet.
    } else if (CROSSING_RED > abs(CROSSING_BLU)) {
        RED_PUSHZONE.AcceptInput("Disable", "", null, null);
        BlockRedCart(true);
        EntFireByHandle(RED_TRAIN, "RunScriptCode", "AdvanceRed(TIMES_1_SPEED_RED)", 0.5, null, null);
    }
    // Do nothing if we entered a crossing and the other cart has already passed through the crossing.
}

function SetBluCrossing(crossing) {
    ::CROSSING_BLU <- crossing;
    // If we exited a crossing.
    if(CROSSING_BLU <= 0) {
        BLU_PUSHZONE.AcceptInput("Enable", "", null, null);
        BlockBluCart(false);
        // If the other cart is waiting at the crossing we just exited.
        if(CROSSING_BLU == -CROSSING_RED) {
            RED_PUSHZONE.AcceptInput("Enable", "", null, null);
            BlockRedCart(false);
        }
    // If we entered a crossing and the other cart is going through the same crossing.
    } else if (CROSSING_BLU == CROSSING_RED) {
        BLU_PUSHZONE.AcceptInput("Disable", "", null, null);
        BlockBluCart(true);
        StopBlu();
    // If we entered a crossing and the other cart hasn't reached this crossing yet.
    } else if (CROSSING_BLU > abs(CROSSING_RED)) {
        BLU_PUSHZONE.AcceptInput("Disable", "", null, null);
        BlockBluCart(true);
        EntFireByHandle(BLU_TRAIN, "RunScriptCode", "AdvanceBlu(TIMES_1_SPEED_BLU)", 0.5, null, null);
    }
    // Do nothing if we entered a crossing and the other cart has already passed through the crossing.
}

// After a time, we disable rollback zones to prevent theoretically infinite rounds.
function DisableRollback() {
    if(ROLLBACK_DISABLED || !MM_PLR_DISABLE_ROLLBACK_IF_OVERTIME_LONG) return;
    ::ROLLBACK_DISABLED <- true;
    if(!OVERTIME_ACTIVE) return;
    AnnounceRollbackDisabled();
    if(PLR_TIMER && PLR_TIMER.IsValid()) PLR_TIMER.Kill();
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

// The following functions are helpers to convert PLR maps from using team_train_watcher
// to handling all cart movement with VScript.

// startPath: The first path_track with "Part of an uphill path" checked.
// endPath: The last path_track with "Part of an uphill path" checked. Use null for the end of the track if it should roll back after reaching it (e.g. banana bay)
// disablePath: The path_track immediately before startPath that will be disabled when the cart enters the rollback zone.
// team: "Red" or "Blu"
function AddRollbackZone(startPath, endPath, disablePath, team) {
    local cartSparksName = (team == "Red" ? RED_CARTSPARKS_ARRAY : BLU_CARTSPARKS_ARRAY)[0].GetName();
    EntityOutputs.AddOutput(MM_GetEntByName(startPath), "OnPass", cartSparksName, "StopSpark", "", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName(startPath), "OnPass", disablePath, "DisablePath", "", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName(startPath), "OnPass", "!self", "RunScriptCode", "RollbackStart" + team + "()", 0, -1);
    if(endPath) EntityOutputs.AddOutput(MM_GetEntByName(endPath), "OnPass", "!self", "RunScriptCode", "RollbackEnd" + team + "()", 0, -1);
}

// startPath: The first path_track with "Part of a downhill path" checked.
// endPath: The last path_track with "Part of a downhill path" checked.
// disablePath: The path_track immediately before endPath that will be disabled when the cart leaves the rollforward zone.
// team: "Red" or "Blu"
function AddRollforwardZone(startPath, endPath, disablePath, team) {
    EntityOutputs.AddOutput(MM_GetEntByName(startPath), "OnPass", "!self", "RunScriptCode", "RollforwardStart" + team + "()", 0, -1);
    if(endPath) EntityOutputs.AddOutput(MM_GetEntByName(endPath), "OnPass", "!self", "RunScriptCode", "RollforwardEnd" + team + "()", 0, -1);
    if(endPath) EntityOutputs.AddOutput(MM_GetEntByName(endPath), "OnPass", disablePath, "DisablePath", "", 0, -1);
}

function AddCrossing(startPathRed, endPathRed, startPathBlu, endPathBlu, index) {
    EntityOutputs.AddOutput(MM_GetEntByName(startPathRed), "OnPass", "!self", "RunScriptCode", "SetRedCrossing(" + index + ")", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName(endPathRed), "OnPass", "!self", "RunScriptCode", "SetRedCrossing(" + -index + ")", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName(startPathBlu), "OnPass", "!self", "RunScriptCode", "SetBluCrossing(" + index + ")", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName(endPathBlu), "OnPass", "!self", "RunScriptCode", "SetBluCrossing(" + -index + ")", 0, -1);
}

// Called whenever a team wins a stage in a multi-stage map.
// Teams that win more get more of an advantage in overtime.

function CountWinRed() {
    ::OVERTIME_SPEED_RED <- OVERTIME_SPEED_RED + 0.02;
}

function CountWinBlu() {
    ::OVERTIME_SPEED_BLU <- OVERTIME_SPEED_BLU + 0.02;
}