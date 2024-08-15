// REQUIRED GLOBAL VARIABLES
// This file should be included at the very start of the map-specific file.
// Everything to do with entities must be set by the map-specific file in OnGameEvent_teamplay_round_start().

// team_round_timer
::PLR_TIMER <- null;

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

function AddCaptureOutputsToEntity(entity, team) {
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
            targetname = "plr_timer",
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
    if(!OVERTIME_ACTIVE || BLOCK_RED || (CROSSING_RED > 0 && CROSSING_RED == CROSSING_BLU)) return;

    if(CASE_RED == 0) {
        if(CASE_BLU == 0) {
            AdvanceRed();
            AdvanceBlu();
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
    if(!OVERTIME_ACTIVE || BLOCK_BLU || (CROSSING_BLU > 0 && CROSSING_BLU == CROSSING_RED)) return;

    if(CASE_BLU == 0) {
        if(CASE_RED == 0) {
            AdvanceBlu();
            AdvanceRed();
        } else if (!ROLLBACK_DISABLED) {
            EntFireByHandle(BLU_ROLLBACK_BRANCH, "Test", "", 0, null, null)
        } else {
            StopBlu();
        }
    } else if (CASE_RED == 0) {
        UpdateRedCart(0);
    }
}

function AdvanceRed() {
    foreach(spark in RED_CARTSPARKS_ARRAY) {
        EntFireByHandle(spark, "StartSpark", "", 0.1, null, null);
    }
    EntFireByHandle(RED_FLASHINGLIGHT, "Start", "", 0.1, null, null);
    EntFireByHandle(RED_TRAIN, "SetSpeedDirAccel", "0.22", 0.1, null, null);
}

function StopRed() {
    foreach(spark in RED_CARTSPARKS_ARRAY) {
        EntFireByHandle(spark, "StopSpark", "", 0.1, null, null);
    }
    EntFireByHandle(RED_FLASHINGLIGHT, "Stop", "", 0.1, null, null);
    EntFireByHandle(RED_TRAIN, "SetSpeedDirAccel", "0.0", 0.1, null, null);
}

function AdvanceBlu() {
    foreach(spark in BLU_CARTSPARKS_ARRAY) {
        EntFireByHandle(spark, "StartSpark", "", 0.1, null, null);
    }
    EntFireByHandle(BLU_FLASHINGLIGHT, "Start", "", 0.1, null, null);
    EntFireByHandle(BLU_TRAIN, "SetSpeedDirAccel", "0.22", 0.1, null, null);
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
    if(!BLOCK_RED) {
        UpdateRedCart(CASE_RED);
        UpdateBluCart(CASE_BLU);
    }
}

function BlockBluCart(blocked) {
    ::BLOCK_BLU <- blocked;
    if(!BLOCK_BLU) {
        UpdateBluCart(CASE_BLU);
        UpdateRedCart(CASE_RED);
    }
}

// These functions set the crossing value, then block the cart from being updated
// if it's the first cart to reach that crossing.
function SetRedCrossing(crossing) {
    ::CROSSING_RED <- crossing;
    BlockRedCart(CROSSING_RED > 0 && (CROSSING_RED >= CROSSING_BLU && CROSSING_RED > -CROSSING_BLU));
}

function SetBluCrossing(crossing) {
    ::CROSSING_BLU <- crossing;
    BlockRedCart(CROSSING_BLU > 0 && (CROSSING_BLU >= CROSSING_RED && CROSSING_BLU > -CROSSING_RED));
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
