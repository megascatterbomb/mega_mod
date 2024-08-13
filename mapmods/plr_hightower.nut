::RED_CARTSPARKS <- null
::BLU_CARTSPARKS <- null

::RED_FLASHINGLIGHT <- null
::BLU_FLASHINGLIGHT <- null

::RED_PUSHZONE <- null
::BLU_PUSHZONE <- null

::RED_ROLLBACK <- null
::BLU_ROLLBACK <- null

::RED_TRAIN <- null
::BLU_TRAIN <- null

::CASE_RED <- 0
::CASE_BLU <- 0

::OVERTIME_ACTIVE <- false;
::ROLLBACK_DISABLED <- false;

function OnGameEvent_teamplay_round_start(params) {

    ::RED_CARTSPARKS <- Entities.FindByName(null, "plr_red_cartsparks");
    ::BLU_CARTSPARKS <- Entities.FindByName(null, "plr_blu_cartsparks");

    ::RED_FLASHINGLIGHT <- Entities.FindByName(null, "plr_red_flashinglight");
    ::BLU_FLASHINGLIGHT <- Entities.FindByName(null, "plr_blu_flashinglight");

    ::RED_PUSHZONE <- Entities.FindByName(null, "plr_red_pushzone");
    ::BLU_PUSHZONE <- Entities.FindByName(null, "plr_blu_pushzone");

    ::RED_ROLLBACK <- Entities.FindByName(null, "plr_red_rollback");
    ::BLU_ROLLBACK <- Entities.FindByName(null, "plr_blu_rollback");

    ::RED_TRAIN <- Entities.FindByName(null, "plr_red_train");
    ::BLU_TRAIN <- Entities.FindByName(null, "plr_blu_train");

    local redPushingCase = Entities.FindByName(null, "plr_red_pushingcase");
    local bluPushingCase = Entities.FindByName(null, "plr_blu_pushingcase");

    // When a cart changes player count, call respective update function
    EntityOutputs.AddOutput(redPushingCase, "OnCase01", "!self", "RunScriptCode", "UpdateRedCart(-1)", 0, -1); // Blocked
    EntityOutputs.AddOutput(redPushingCase, "OnCase02", "!self", "RunScriptCode", "UpdateRedCart(0)", 0, -1); // 0 cap
    EntityOutputs.AddOutput(redPushingCase, "OnCase03", "!self", "RunScriptCode", "UpdateRedCart(1)", 0, -1); // 1 cap
    EntityOutputs.AddOutput(redPushingCase, "OnCase04", "!self", "RunScriptCode", "UpdateRedCart(2)", 0, -1); // 2 cap
    EntityOutputs.AddOutput(redPushingCase, "OnDefault", "!self", "RunScriptCode", "UpdateRedCart(3)", 0, -1); // 3+ cap

    EntityOutputs.AddOutput(bluPushingCase, "OnCase01", "!self", "RunScriptCode", "UpdateBluCart(-1)", 0, -1); // Blocked
    EntityOutputs.AddOutput(bluPushingCase, "OnCase02", "!self", "RunScriptCode", "UpdateBluCart(0)", 0, -1); // 0 cap
    EntityOutputs.AddOutput(bluPushingCase, "OnCase03", "!self", "RunScriptCode", "UpdateBluCart(1)", 0, -1); // 1 cap
    EntityOutputs.AddOutput(bluPushingCase, "OnCase04", "!self", "RunScriptCode", "UpdateBluCart(2)", 0, -1); // 2 cap
    EntityOutputs.AddOutput(bluPushingCase, "OnDefault", "!self", "RunScriptCode", "UpdateBluCart(3)", 0, -1); // 3+ cap

    local plrTimer = Entities.FindByName(null, "plr_timer");
    EntityOutputs.RemoveOutput(plrTimer, "OnSetupFinished", "plr_timer", "Disable", "");
    EntityOutputs.AddOutput(plrTimer, "OnSetupFinished", "plr_timer", "SetTime", "600", 0, -1);
    EntityOutputs.AddOutput(plrTimer, "OnFinished", "!self", "RunScriptCode", "OvertimeHightower()", 0, -1);
}

//
function OvertimeHightower() {

    local redRollbackRelay = Entities.FindByName(null, "plr_red_rollback_relay");
    local bluRollbackRelay = Entities.FindByName(null, "plr_blu_rollback_relay");

    // Prevent other calls to overtime logic
    EntFireByHandle(redRollbackRelay, "Disable", "", 0, null, null);
    EntFireByHandle(bluRollbackRelay, "Disable", "", 0, null, null);

    ::OVERTIME_ACTIVE <- true;

    UpdateRedCart(CASE_RED);
    UpdateBluCart(CASE_BLU);
}

function UpdateRedCart(caseNumber) {
    ::CASE_RED = caseNumber;
    if(!OVERTIME_ACTIVE) return;

    if(CASE_RED == 0) {
        if(CASE_BLU == 0) {
            AdvanceRed();
            AdvanceBlu();
        } else if (!ROLLBACK_DISABLED) {
            EntFireByHandle(RED_ROLLBACK, "Test", "", 0, null, null)
        } else {
            AdvanceRed();
        }
    } else if (CASE_BLU == 0) {
        UpdateBluCart(0);
    }
}

function UpdateBluCart(caseNumber) {
    ::CASE_BLU = caseNumber;
    if(!OVERTIME_ACTIVE) return;

    if(CASE_BLU == 0) {
        if(CASE_RED == 0) {
            AdvanceBlu();
            AdvanceRed();
        } else if (!ROLLBACK_DISABLED) {
            EntFireByHandle(BLU_ROLLBACK, "Test", "", 0, null, null)
        } else {
            AdvanceBlu();
        }
    } else if (CASE_RED == 0) {
        UpdateRedCart(0);
    }
}

function AdvanceRed() {
    EntFireByHandle(RED_CARTSPARKS, "StartSpark", "", 0.1, null, null);
    EntFireByHandle(RED_FLASHINGLIGHT, "Start", "", 0.1, null, null);
    EntFireByHandle(RED_TRAIN, "SetSpeedDirAccel", "0.22", 0.1, null, null);
}

function AdvanceBlu() {
    EntFireByHandle(BLU_CARTSPARKS, "StartSpark", "", 0.1, null, null);
    EntFireByHandle(BLU_FLASHINGLIGHT, "Start", "", 0.1, null, null);
    EntFireByHandle(BLU_TRAIN, "SetSpeedDirAccel", "0.22", 0.1, null, null);
}

// After a time, we disable rollback zones to prevent theoretically infinite rounds.
function DisableRollback() {
    ::ROLLBACK_DISABLED <- true;
}


__CollectGameEventCallbacks(this)