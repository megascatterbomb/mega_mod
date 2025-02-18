ClearGameEventCallbacks();
IncludeScript("mega_mod/common/plr_overtime.nut");

function OnGameEvent_teamplay_round_start(params) {
    InitGlobalVars();

    ::PLR_TIMER_NAME <- "plr_timer";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    // For opening sequence where carts roll out.
    ::BLOCK_RED <- true;
    ::BLOCK_BLU <- true;

    // Timer logic replacement
    EntityOutputs.RemoveOutput(PLR_TIMER, "OnSetupFinished", PLR_TIMER_NAME, "Disable", "");
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", GetRoundTimeString(), 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "StartOvertime()", 0, -1);

    EntityOutputs.AddOutput(MM_GetEntByName("plr_blu_pathC_start3"), "OnPass", "!self", "RunScriptCode", "MM_HighTowerEvent_DelayedStart()", 0, -1);
}

function MM_HighTowerEvent_DelayedStart() {

    ::RED_CARTSPARKS_ARRAY <- MM_GetEntArrayByName("plr_red_cartsparks");
    ::BLU_CARTSPARKS_ARRAY <- MM_GetEntArrayByName("plr_blu_cartsparks");

    ::RED_FLASHINGLIGHT <- MM_GetEntByName("plr_red_flashinglight");
    ::BLU_FLASHINGLIGHT <- MM_GetEntByName("plr_blu_flashinglight");

    ::RED_PUSHZONE <- MM_GetEntByName("plr_red_pushzone");
    ::BLU_PUSHZONE <- MM_GetEntByName("plr_blu_pushzone");

    ::RED_TRAIN <- MM_GetEntByName("plr_red_train");
    ::BLU_TRAIN <- MM_GetEntByName("plr_blu_train");

    ::RED_ELV <- null;
    ::BLU_ELV <- null;

    ::BLOCK_RED <- false;
    ::BLOCK_BLU <- false;

    // Cart control logic replacement
    MM_GetEntByName("template_elv_case_red").Kill();
    MM_GetEntByName("template_elv_case_blu").Kill();
    MM_GetEntByName("plr_red_pushingcase").Kill();
    MM_GetEntByName("plr_blu_pushingcase").Kill();

    ::RED_LOGICCASE <- CreateLogicCase("mm_plr_logiccase_red", "Red");
    ::BLU_LOGICCASE <- CreateLogicCase("mm_plr_logiccase_blu", "Blu");

    EntityOutputs.AddOutput(RED_PUSHZONE, "OnNumCappersChanged2", "mm_plr_logiccase_red", "InValue", "", 0, -1);
    EntityOutputs.AddOutput(BLU_PUSHZONE, "OnNumCappersChanged2", "mm_plr_logiccase_blu", "InValue", "", 0, -1);

    // Elevators
    AddRollbackZone("plr_red_pathC_hillA3", "plr_red_pathC_hillA17", "plr_red_pathC_hillA2", "Red");
    AddRollbackZone("plr_blu_pathC_hillA3", "plr_blu_pathC_hillA67", "plr_blu_pathC_hillA2", "Blu");

    // Crossover logic replacement
    MM_GetEntByName("plr_red_crossover1_branch").Kill();
    MM_GetEntByName("plr_red_crossover1_relay").Kill();
    MM_GetEntByName("plr_blu_crossover1_branch").Kill();
    MM_GetEntByName("plr_blu_crossover1_relay").Kill();

    AddCrossing(
        "plr_red_crossover1_start",
        "plr_red_crossover1_end",
        "plr_blu_crossover1_start",
        "plr_blu_crossover1_end",
        1
    );

    // Elevator logic replacement
    MM_GetEntByName("clamp_logic_case_red").Kill();
    MM_GetEntByName("clamp_logic_case").Kill();

    EntityOutputs.AddOutput(MM_GetEntByName("clamp_red_positioncart_relay_begin"), "OnTrigger", "!self", "RunScriptCode", "BlockRedCart(true)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("clamp_blu_positioncart_relay_begin"), "OnTrigger", "!self", "RunScriptCode", "BlockBluCart(true)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("clamp_red_positioncart_relay_end"), "OnTrigger", "!self", "RunScriptCode", "SwitchToElevatorRed()", 0.95, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("clamp_blu_positioncart_relay_end"), "OnTrigger", "!self", "RunScriptCode", "SwitchToElevatorBlu()", 0.95, -1);

    EntityOutputs.AddOutput(MM_GetEntByName("relay_red_capture_cart"), "OnTrigger", "!self", "RunScriptCode", "Endgame()", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("relay_blu_capture_cart"), "OnTrigger", "!self", "RunScriptCode", "Endgame()", 0, -1);
}

// Destroy timer during the underworld phase.
function Endgame() {
    if (PLR_TIMER) PLR_TIMER.Kill();
}

::StartOvertimeBase <- StartOvertime;

function StartOvertime() {
    local redRollbackRelay = MM_GetEntByName("plr_red_rollback_relay");
    local bluRollbackRelay = MM_GetEntByName("plr_blu_rollback_relay");

    // Prevent other calls to overtime logic
    EntFireByHandle(redRollbackRelay, "Disable", "", 0, null, null);
    EntFireByHandle(bluRollbackRelay, "Disable", "", 0, null, null);

    // The only rollback zones are on the elevator, which force disable rollback anyway.
    // Might as well disable rollback right now.
    DisableRollback();

    StartOvertimeBase();
}

::AdvanceRedBase <- AdvanceRed;
::StopRedBase <- StopRed;
::TriggerRollbackRedBase <- TriggerRollbackRed;
::AdvanceBluBase <- AdvanceBlu;
::StopBluBase <- StopBlu;
::TriggerRollbackBluBase <- TriggerRollbackBlu;

function AdvanceRed(speed) {
    AdvanceRedBase(speed);
    if(RED_ELV) {
        EntFireByHandle(RED_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
        EntFireByHandle(RED_ELV, "SetSpeedDirAccel", "" + speed, 0, null, null);
    }
}

function StopRed() {
    StopRedBase();
    if(RED_ELV) {
        EntFireByHandle(RED_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
        EntFireByHandle(RED_ELV, "SetSpeedDirAccel", "0.0", 0, null, null);
    }
}

function TriggerRollbackRed() {
    TriggerRollbackRedBase();
    if(RED_ELV) {
        EntFireByHandle(RED_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
        EntFireByHandle(RED_ELV, "SetSpeedDirAccel", "-1", 0, null, null);
    }
}

function AdvanceBlu(speed) {
    AdvanceBluBase(speed);
    if(BLU_ELV) {
        EntFireByHandle(BLU_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
        EntFireByHandle(BLU_ELV, "SetSpeedDirAccel", "" + speed, 0, null, null);
    }
}

function StopBlu() {
    StopBluBase();
    if(BLU_ELV) {
        EntFireByHandle(BLU_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
        EntFireByHandle(BLU_ELV, "SetSpeedDirAccel", "0.0", 0, null, null);
    }
}

function TriggerRollbackBlu() {
    TriggerRollbackBluBase();
    if(BLU_ELV) {
        EntFireByHandle(BLU_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
        EntFireByHandle(BLU_ELV, "SetSpeedDirAccel", "-1", 0, null, null);
    }
}


// When the cart goes on the elevator, trigger necessary logic.
// Also disables rollback, otherwise it becomes impossible to maintain sync
// between the two func_tracktrains.
function SwitchToElevatorRed() {
    ::RED_ELV <- MM_GetEntByName("clamp_red");
    ::RED_PUSHZONE <- MM_GetEntByName("plr_red_pushzone_elv");
    ::RED_CARTSPARKS_ARRAY <- MM_GetEntArrayByName("plr_red_elevatorsparks");

    DisableRollback();

    EntFireByHandle(RED_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
    EntFireByHandle(RED_TRAIN, "TeleportToPathTrack", "plr_red_pathC_hillA3", 0, null, null);
    EntityOutputs.AddOutput(RED_PUSHZONE, "OnNumCappersChanged2", "mm_plr_logiccase_red", "InValue", "", 0, -1);

    ::UpdateRedCart <- UpdateRedElevator;

    BlockRedCart(false);
}

function SwitchToElevatorBlu() {
    ::BLU_ELV <- MM_GetEntByName("clamp_blue");
    ::BLU_PUSHZONE <- MM_GetEntByName("plr_blu_pushzone_elv");
    ::BLU_CARTSPARKS_ARRAY <- MM_GetEntArrayByName("plr_blu_elevatorsparks");

    DisableRollback();

    EntFireByHandle(BLU_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
    EntFireByHandle(BLU_TRAIN, "TeleportToPathTrack", "plr_blu_pathC_hillA3", 0, null, null);
    EntityOutputs.AddOutput(BLU_PUSHZONE, "OnNumCappersChanged2", "mm_plr_logiccase_blu", "InValue", "", 0, -1);

    ::UpdateBluCart <- UpdateBluElevator;

    BlockBluCart(false);
}

function UpdateRedElevator(caseNumber) {
    ::CASE_RED = caseNumber;

    if(BLOCK_RED) return;

    if(CASE_RED >= 1) {
        AdvanceRed(TIMES_2_SPEED_RED);
    } else if (CASE_RED == -1) {
        StopRed();
    }

    if(CASE_RED == 0) {
        if(CASE_BLU == 0 && OVERTIME_ACTIVE) {
            AdvanceRed(OVERTIME_SPEED_RED);
            if(!BLOCK_BLU) AdvanceBlu(OVERTIME_SPEED_BLU);
        } else if (!OVERTIME_ACTIVE && RED_ROLLSTATE == -1) {
            TriggerRollbackRed();
        } else {
            StopRed();
        }
    } else if (OVERTIME_ACTIVE && CASE_BLU == 0) {
        UpdateBluCart(0);
    }
}

function UpdateBluElevator(caseNumber) {
    ::CASE_BLU = caseNumber;

    if(BLOCK_BLU) return;

    if(CASE_BLU >= 1) {
        AdvanceBlu(TIMES_2_SPEED_BLU);
    } else if (CASE_BLU == -1) {
        StopBlu();
    }

    if(CASE_BLU == 0) {
        if(CASE_RED == 0 && OVERTIME_ACTIVE) {
            AdvanceBlu(OVERTIME_SPEED_BLU);
            if(!BLOCK_RED) AdvanceRed(OVERTIME_SPEED_RED);
        } else if (!OVERTIME_ACTIVE && BLU_ROLLSTATE == -1) {
            TriggerRollbackBlu();
        } else {
            StopBlu();
        }
    } else if (OVERTIME_ACTIVE && CASE_RED == 0) {
        UpdateRedCart(0);
    }
}

__CollectGameEventCallbacks(this);