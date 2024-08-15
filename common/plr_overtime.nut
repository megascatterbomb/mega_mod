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

    // logic_branch governing whether the cart is in a rollback zone or not
    ::RED_ROLLBACK_BRANCH <- null;
    ::BLU_ROLLBACK_BRANCH <- null;

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

    ::OVERTIME_ACTIVE <- false;
    ::ROLLBACK_DISABLED <- false;
}

InitGlobalVars();

// When a cart changes player count, call respective update function
function AddCaptureOutputsToLogicCase(entity, team) {
    EntityOutputs.AddOutput(entity, "OnCase01", "!self", "RunScriptCode", "Update" + team + "Cart(-1)", 0, -1); // Blocked
    EntityOutputs.AddOutput(entity, "OnCase02", "!self", "RunScriptCode", "Update" + team + "Cart(0)", 0, -1); // 0 cap
    EntityOutputs.AddOutput(entity, "OnCase03", "!self", "RunScriptCode", "Update" + team + "Cart(1)", 0, -1); // 1 cap
    EntityOutputs.AddOutput(entity, "OnCase04", "!self", "RunScriptCode", "Update" + team + "Cart(2)", 0, -1); // 2 cap
    EntityOutputs.AddOutput(entity, "OnDefault", "!self", "RunScriptCode", "Update" + team + "Cart(3)", 0, -1); // 3+ cap
}

// Base logic for cart movement
function StartOvertime() {
    ::OVERTIME_ACTIVE <- true;
    if(ROLLBACK_DISABLED) {
        AnnounceRollbackDisabled();
    } else {
        if(PLR_TIMER) PLR_TIMER.Kill();
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
    }

    UpdateRedCart(CASE_RED);
    UpdateBluCart(CASE_BLU);
}

function UpdateRedCart(caseNumber) {
    ::CASE_RED = caseNumber;
    if(!OVERTIME_ACTIVE || BLOCK_RED) return;

    if(CASE_RED == 0) {
        if(CASE_BLU == 0) {
            AdvanceRed(0.22);
            AdvanceBlu(0.22);
        } else if (!ROLLBACK_DISABLED) {
            EntFireByHandle(RED_ROLLBACK_BRANCH, "Test", "", 0, null, null)
        } else {
            StopRed();
        }
    } else if (CASE_BLU == 0) {
        UpdateBluCart(0);
    }
}

function UpdateBluCart(caseNumber) {
    ::CASE_BLU = caseNumber;
    if(!OVERTIME_ACTIVE || BLOCK_BLU) return;

    if(CASE_BLU == 0) {
        if(CASE_RED == 0) {
            AdvanceBlu(0.22);
            AdvanceRed(0.22);
        } else if (!ROLLBACK_DISABLED) {
            EntFireByHandle(BLU_ROLLBACK_BRANCH, "Test", "", 0, null, null)
        } else {
            StopBlu();
        }
    } else if (CASE_RED == 0) {
        UpdateRedCart(0);
    }
}

function AdvanceRed(speed) {
    foreach(spark in RED_CARTSPARKS_ARRAY) {
        EntFireByHandle(spark, "StartSpark", "", 0.1, null, null);
    }
    EntFireByHandle(RED_FLASHINGLIGHT, "Start", "", 0.1, null, null);
    EntFireByHandle(RED_TRAIN, "SetSpeedDirAccel", "" + speed, 0.1, null, null);
}

function StopRed() {
    foreach(spark in RED_CARTSPARKS_ARRAY) {
        EntFireByHandle(spark, "StopSpark", "", 0.1, null, null);
    }
    EntFireByHandle(RED_FLASHINGLIGHT, "Stop", "", 0.1, null, null);
    EntFireByHandle(RED_TRAIN, "SetSpeedDirAccel", "0.0", 0.1, null, null);
}

function AdvanceBlu(speed) {
    foreach(spark in BLU_CARTSPARKS_ARRAY) {
        EntFireByHandle(spark, "StartSpark", "", 0.1, null, null);
    }
    EntFireByHandle(BLU_FLASHINGLIGHT, "Start", "", 0.1, null, null);
    EntFireByHandle(BLU_TRAIN, "SetSpeedDirAccel", "" + speed, 0.1, null, null);
}

function StopBlu() {
    foreach(spark in BLU_CARTSPARKS_ARRAY) {
        EntFireByHandle(spark, "StopSpark", "", 0.1, null, null);
    }
    EntFireByHandle(BLU_FLASHINGLIGHT, "Stop", "", 0.1, null, null);
    EntFireByHandle(BLU_TRAIN, "SetSpeedDirAccel", "0.0", 0.1, null, null);
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
        EntFireByHandle(RED_TRAIN, "RunScriptCode", "AdvanceRed(0.55)", 0.5, null, null);
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
        EntFireByHandle(BLU_TRAIN, "RunScriptCode", "AdvanceBlu(0.55)", 0.5, null, null);
    }
    // Do nothing if we entered a crossing and the other cart has already passed through the crossing.
}

// After a time, we disable rollback zones to prevent theoretically infinite rounds.
function DisableRollback() {
    if(ROLLBACK_DISABLED) return;
    ::ROLLBACK_DISABLED <- true;
    if(!OVERTIME_ACTIVE) return;
    AnnounceRollbackDisabled();
    if(PLR_TIMER) PLR_TIMER.Kill();
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
