ClearGameEventCallbacks();

function OnGameEvent_teamplay_round_start(params) {

    ::RED_CARTSPARKS <- MM_GetEntByName("plr_red_cartsparks");
    ::BLU_CARTSPARKS <- MM_GetEntByName("plr_blu_cartsparks");

    ::RED_FLASHINGLIGHT <- MM_GetEntByName("plr_red_flashinglight");
    ::BLU_FLASHINGLIGHT <- MM_GetEntByName("plr_blu_flashinglight");

    ::RED_PUSHZONE <- MM_GetEntByName("plr_red_pushzone");
    ::BLU_PUSHZONE <- MM_GetEntByName("plr_blu_pushzone");

    ::RED_ROLLBACK <- MM_GetEntByName("plr_red_rollback");
    ::BLU_ROLLBACK <- MM_GetEntByName("plr_blu_rollback");

    ::RED_TRAIN <- MM_GetEntByName("plr_red_train");
    ::BLU_TRAIN <- MM_GetEntByName("plr_blu_train");

    ::CASE_RED <- 0
    ::CASE_BLU <- 0

    // Is the cart being controlled by something else? (e.g. crossing logic)
    ::BLOCK_RED <- false;
    ::BLOCK_BLU <- false;

    // These are set once the cart is actually on the elevator.
    ::RED_ELV <- null;
    ::BLU_ELV <- null;

    ::OVERTIME_ACTIVE <- false;
    ::ROLLBACK_DISABLED <- false;

    // When a cart changes player count, call respective update function
    AddCaptureOutputsToEntity(MM_GetEntByName("plr_red_pushingcase"), "Red");
    AddCaptureOutputsToEntity(MM_GetEntByName("plr_blu_pushingcase"), "Blu")

    // Ensure overtime works on the crossover.
    EntityOutputs.AddOutput(MM_GetEntByName("plr_red_crossover1_branch"), "OnTrue", "!self", "RunScriptCode", "BlockRedCart(true)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("plr_red_crossover1_relay"), "OnTrigger", "!self", "RunScriptCode", "BlockRedCart(false)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("plr_blu_crossover1_branch"), "OnTrue", "!self", "RunScriptCode", "BlockBluCart(true)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("plr_blu_crossover1_relay"), "OnTrigger", "!self", "RunScriptCode", "BlockBluCart(false)", 0, -1);

    // Cart onboarding for elevator
    EntityOutputs.AddOutput(MM_GetEntByName("clamp_red_positioncart_relay_begin"), "OnTrigger", "!self", "RunScriptCode", "BlockRedCart(true)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("clamp_blu_positioncart_relay_begin"), "OnTrigger", "!self", "RunScriptCode", "BlockBluCart(true)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("clamp_red_positioncart_relay_end"), "OnTrigger", "!self", "RunScriptCode", "SwitchToElevatorRed()", 0.95, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("clamp_blu_positioncart_relay_end"), "OnTrigger", "!self", "RunScriptCode", "SwitchToElevatorBlu()", 0.95, -1);

    // Clear out elevator logic
    MM_GetEntByName("clamp_logic_case_red").Kill();
    MM_GetEntByName("clamp_logic_case").Kill();

    local plrTimer = MM_GetEntByName("plr_timer");
    EntityOutputs.RemoveOutput(plrTimer, "OnSetupFinished", "plr_timer", "Disable", "");
    EntityOutputs.AddOutput(plrTimer, "OnSetupFinished", "plr_timer", "SetTime", "600", 0, -1);
    EntityOutputs.AddOutput(plrTimer, "OnFinished", "!self", "RunScriptCode", "OvertimeHightower()", 0, -1);
}

function AddCaptureOutputsToEntity(entity, team) {
    EntityOutputs.AddOutput(entity, "OnCase01", "!self", "RunScriptCode", "Update" + team + "Cart(-1)", 0, -1); // Blocked
    EntityOutputs.AddOutput(entity, "OnCase02", "!self", "RunScriptCode", "Update" + team + "Cart(0)", 0, -1); // 0 cap
    EntityOutputs.AddOutput(entity, "OnCase03", "!self", "RunScriptCode", "Update" + team + "Cart(1)", 0, -1); // 1 cap
    EntityOutputs.AddOutput(entity, "OnCase04", "!self", "RunScriptCode", "Update" + team + "Cart(2)", 0, -1); // 2 cap
    EntityOutputs.AddOutput(entity, "OnDefault", "!self", "RunScriptCode", "Update" + team + "Cart(3)", 0, -1); // 3+ cap
}

function OvertimeHightower() {

    local redRollbackRelay = MM_GetEntByName("plr_red_rollback_relay");
    local bluRollbackRelay = MM_GetEntByName("plr_blu_rollback_relay");

    // Prevent other calls to overtime logic
    EntFireByHandle(redRollbackRelay, "Disable", "", 0, null, null);
    EntFireByHandle(bluRollbackRelay, "Disable", "", 0, null, null);

    ::OVERTIME_ACTIVE <- true;
    if(ROLLBACK_DISABLED) {
        AnnounceRollbackDisabled();
    } else {
        local plrTimer = MM_GetEntByName("plr_timer");
        plrTimer.Kill();
        plrTimer = SpawnEntityFromTable("team_round_timer", {
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

        EntFireByHandle(plrTimer, "ShowInHud", "1", 0, null, null);
        EntFireByHandle(plrTimer, "Resume", "1", 0, null, null);
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
            AdvanceRed();
            AdvanceBlu();
        } else if (!ROLLBACK_DISABLED) {
            EntFireByHandle(RED_ROLLBACK, "Test", "", 0, null, null)
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
            AdvanceBlu();
            AdvanceRed();
        } else if (!ROLLBACK_DISABLED) {
            EntFireByHandle(BLU_ROLLBACK, "Test", "", 0, null, null)
        } else {
            StopBlu();
        }
    } else if (CASE_RED == 0) {
        UpdateRedCart(0);
    }
}

function AdvanceRed() {
    EntFireByHandle(RED_CARTSPARKS, "StartSpark", "", 0.1, null, null);
    EntFireByHandle(RED_FLASHINGLIGHT, "Start", "", 0.1, null, null);
    EntFireByHandle(RED_TRAIN, "SetSpeedDirAccel", "0.22", 0.1, null, null);
    if(RED_ELV) {
        EntFireByHandle(RED_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
        EntFireByHandle(RED_ELV, "SetSpeedDirAccel", "0.22", 0.1, null, null);
    }
}

function StopRed() {
    EntFireByHandle(RED_CARTSPARKS, "StopSpark", "", 0.1, null, null);
    EntFireByHandle(RED_FLASHINGLIGHT, "Stop", "", 0.1, null, null);
    EntFireByHandle(RED_TRAIN, "SetSpeedDirAccel", "0.0", 0.1, null, null);
    if(RED_ELV) {
        EntFireByHandle(RED_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
        EntFireByHandle(RED_ELV, "SetSpeedDirAccel", "0.0", 0.1, null, null);
    }
}

function AdvanceBlu() {
    EntFireByHandle(BLU_CARTSPARKS, "StartSpark", "", 0.1, null, null);
    EntFireByHandle(BLU_FLASHINGLIGHT, "Start", "", 0.1, null, null);
    EntFireByHandle(BLU_TRAIN, "SetSpeedDirAccel", "0.22", 0.1, null, null);
    if(BLU_ELV) {
        EntFireByHandle(BLU_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
        EntFireByHandle(BLU_ELV, "SetSpeedDirAccel", "0.22", 0.1, null, null);
    }
}

function StopBlu() {
    EntFireByHandle(BLU_CARTSPARKS, "StopSpark", "", 0.1, null, null);
    EntFireByHandle(BLU_FLASHINGLIGHT, "Stop", "", 0.1, null, null);
    EntFireByHandle(BLU_TRAIN, "SetSpeedDirAccel", "0.0", 0.1, null, null);
    if(BLU_ELV) {
        EntFireByHandle(BLU_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
        EntFireByHandle(BLU_ELV, "SetSpeedDirAccel", "0.0", 0.1, null, null);
    }
}

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

// After a time, we disable rollback zones to prevent theoretically infinite rounds.
// Also disable when a cart reaches the elevator, otherwise it becomes impossible to maintain sync
// between the two func_tracktrains.
function DisableRollback() {
    if(ROLLBACK_DISABLED) return;
    ::ROLLBACK_DISABLED <- true;
    if(!OVERTIME_ACTIVE) return;
    AnnounceRollbackDisabled();
    local plrTimer = MM_GetEntByName("plr_timer");
    if(plrTimer) plrTimer.Kill();
}

// When the cart goes on the elevator, trigger necessary logic.
function SwitchToElevatorRed() {
    ::RED_ELV <- MM_GetEntByName("clamp_red");
    ::RED_PUSHZONE <- MM_GetEntByName("plr_red_pushzone_elv");
    DisableRollback();

    local redPushingCaseElv = MM_GetEntByName("plr_red_pushingcase_elv");
    AddCaptureOutputsToEntity(redPushingCaseElv, "Red");
    EntityOutputs.AddOutput(redPushingCaseElv, "OnCase01", "clamp_red", "SetSpeedDirAccel", "0.0", 0, -1);
    EntityOutputs.AddOutput(redPushingCaseElv, "OnDefault", "clamp_red", "SetSpeedDirAccel", "0.77", 0, -1);

    EntityOutputs.AddOutput(RED_ROLLBACK, "OnTrue", "clamp_red", "SetSpeedDirAccel", "-1.0", 0, -1);
    EntityOutputs.AddOutput(RED_ROLLBACK, "OnFalse", "clamp_red", "SetSpeedDirAccel", "0.0", 0, -1);

    EntFireByHandle(RED_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
    EntFireByHandle(RED_TRAIN, "TeleportToPathTrack", "plr_red_pathC_hillA3", 0, null, null);

    BlockRedCart(false);
}

function SwitchToElevatorBlu() {
    ::BLU_ELV <- MM_GetEntByName("clamp_blue");
    ::BLU_PUSHZONE <- MM_GetEntByName("plr_blu_pushzone_elv");
    DisableRollback();

    local bluPushingCaseElv = MM_GetEntByName("plr_blu_pushingcase_elv");
    AddCaptureOutputsToEntity(bluPushingCaseElv, "Blu");
    EntityOutputs.AddOutput(bluPushingCaseElv, "OnCase01", "clamp_blue", "SetSpeedDirAccel", "0.0", 0, -1);
    EntityOutputs.AddOutput(bluPushingCaseElv, "OnDefault", "clamp_blue", "SetSpeedDirAccel", "0.77", 0, -1);

    EntityOutputs.AddOutput(BLU_ROLLBACK, "OnTrue", "clamp_blue", "SetSpeedDirAccel", "-1.0", 0, -1);
    EntityOutputs.AddOutput(BLU_ROLLBACK, "OnFalse", "clamp_blue", "SetSpeedDirAccel", "0.0", 0, -1);

    EntFireByHandle(BLU_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
    EntFireByHandle(BLU_TRAIN, "TeleportToPathTrack", "plr_blu_pathC_hillA3", 0, null, null);

    BlockBluCart(false);
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

__CollectGameEventCallbacks(this)