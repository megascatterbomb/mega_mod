ClearGameEventCallbacks();
IncludeScript("mega_mod/common/plr_overtime.nut");

function OnGameEvent_teamplay_round_start(params) {

    InitGlobalVars();

	::PLR_TIMER_NAME <- "ssplr_timer";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    ::RED_CARTSPARKS_ARRAY <- MM_GetEntArrayByName("ssplr_red_cartsparks");
    ::BLU_CARTSPARKS_ARRAY <- MM_GetEntArrayByName("ssplr_blu_cartsparks");

    ::RED_FLASHINGLIGHT <- MM_GetEntByName("ssplr_red_flashinglight");
    ::BLU_FLASHINGLIGHT <- MM_GetEntByName("ssplr_blu_flashinglight");

    ::RED_PUSHZONE <- MM_GetEntByName("ssplr_red_pushzone");
    ::BLU_PUSHZONE <- MM_GetEntByName("ssplr_blu_pushzone");

    ::RED_TRAIN <- MM_GetEntByName("ssplr_red_train");
    ::BLU_TRAIN <- MM_GetEntByName("ssplr_blu_train");

    ::RED_ELV <- null;
    ::BLU_ELV <- null;

    ::RED_AT_BOTTOM <- true;
    ::BLU_AT_BOTTOM <- true;

    ::RED_WATCHER <- MM_GetEntByName("ssplr_red_watcherA");
    ::BLU_WATCHER <- MM_GetEntByName("ssplr_blu_watcherA");

    ::RED_LOGICCASE <- CreateLogicCase("mm_plr_logiccase_red", "Red");
    ::BLU_LOGICCASE <- CreateLogicCase("mm_plr_logiccase_blu", "Blu");

    ::ELEVATOR_OVERTIME_SPEED <- 0.1;

    // Rollback zones
    AddRollbackZone("ssplr_red_path_lift_finale1_4", null, "ssplr_red_path_lift_finale1_1", "Red");
    AddRollbackZone("ssplr_blu_path_lift_finale1_4", null, "ssplr_blu_path_lift_finale1_1", "Blu");

	// Crossover logic replacement

	foreach(entName in [
        "ssplr_red_crossover1_branch"
        "ssplr_red_crossover1_relay"
        "ssplr_blu_crossover1_branch"
        "ssplr_blu_crossover1_relay"
    ]) {
        MM_GetEntByName(entName).Kill();
    }

	AddCrossing("ssplr_red_pathA_12", "ssplr_red_pathA_17", "ssplr_blu_pathA_12", "ssplr_blu_pathA_17", 1);

	// Timer logic replacement
    EntityOutputs.RemoveOutput(PLR_TIMER, "OnSetupFinished", PLR_TIMER_NAME, "Disable", "");
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", GetRoundTimeString(), 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "StartOvertime()", 0, -1);

    // team_train_watcher is no longer in charge.
    NetProps.SetPropBool(RED_WATCHER, "m_bHandleTrainMovement", false);
    NetProps.SetPropBool(BLU_WATCHER, "m_bHandleTrainMovement", false);

    // Hook pre-lift pushzones.
    EntityOutputs.AddOutput(RED_PUSHZONE, "OnNumCappersChanged2", "mm_plr_logiccase_red", "InValue", "", 0, -1);
    EntityOutputs.AddOutput(BLU_PUSHZONE, "OnNumCappersChanged2", "mm_plr_logiccase_blu", "InValue", "", 0, -1);

    EntityOutputs.AddOutput(RED_PUSHZONE, "OnNumCappersChanged2", "ssplr_red_watcherA", "SetNumTrainCappers", "", 0, -1);
    EntityOutputs.AddOutput(BLU_PUSHZONE, "OnNumCappersChanged2", "ssplr_blu_watcherA", "SetNumTrainCappers", "", 0, -1);

    // elevator logic replacement

    // There's two copies of each of these entities. Remove the ones on the negative X side.
    // I chose that side because the +x side has more modern logic (e.g. HUD overlay logic)
    foreach(entName in [
        "gate1_overload_relay"
        "gate1_alarm_relay"
        "status_red"
        "status_blu"
        "status_yellow"
        "status_white"
        "status_off"
        "branch_bottomOut"
    ]) {
        local ents = MM_GetEntArrayByName(entName);
        foreach(ent in ents) {
            if (ent.GetOrigin().x < 0) {
                ent.Kill();
                break;
            }
        }
    }

    foreach (entName in [
        // Listeners
        "listener_bothPushing"
        "listener_bothLoaded"

        // Branches
        "branch_areBothBeingPushed"
        "branch_isOneAtBottom"
        "branch_areBothNotBeingPushed"
        "branch_isRedBeingPushed"

        // RED - movement decision logic
        "ssplr_red_lift_finale1_pushingcase"
        "ssplr_red_lift_finale1_rollcase"
        "ssplr_red_lift_finale1_staycase"
        "ssplr_red_lift_rollback_relay_rb1"
        "ssplr_red_lift_finale1_rollback"
        "ssplr_red_lift_finale1_relay_embark"

        // BLU - movement decision logic
        "ssplr_blu_lift_finale1_pushingcase"
        "ssplr_blu_lift_finale1_rollcase"
        "ssplr_blu_lift_finale1_staycase"
        "ssplr_blu_lift_rollback_relay_rb1"
        "ssplr_blu_lift_finale1_rollback"
        "ssplr_blu_lift_finale1_relay_embark"

        // RED - listener logic
        "count_redPushers1"
        "count_redPushers2"
        "case_setRedPushing"
        "branch_isRedPushing"
        "relay_redIsOnLift"
        "relay_redBottom"
        "relay_isRedLiftAtBottom"
        "branch_isRedLiftAtBottom"
        "branch_isRedLoaded"

        // BLU - listener logic
        "count_bluPushers1"
        "count_bluPushers2"
        "case_setBluPushing"
        "branch_isBluPushing"
        "relay_bluIsOnLift"
        "relay_bluBottom"
        "relay_isBluLiftAtBottom"
        "branch_isBluLiftAtBottom"
        "branch_isBluLoaded"
    ]) {
        MM_GetEntByName(entName).Kill();
    }

    local ssplr_red_lift_finale1_relay_embark = SpawnEntityFromTable("logic_relay", {
        targetname = "ssplr_red_lift_finale1_relay_embark"
    });
    local ssplr_blu_lift_finale1_relay_embark = SpawnEntityFromTable("logic_relay", {
        targetname = "ssplr_blu_lift_finale1_relay_embark"
    });

    EntityOutputs.AddOutput(ssplr_red_lift_finale1_relay_embark, "OnTrigger", "ssplr_red_train", "AddOutput", "manualaccelspeed 999", 0.3, -1)
    EntityOutputs.AddOutput(ssplr_red_lift_finale1_relay_embark, "OnTrigger", "ssplr_red_train", "AddOutput", "manualdecelspeed 999", 0.3, -1)
    EntityOutputs.AddOutput(ssplr_red_lift_finale1_relay_embark, "OnTrigger", "!self", "RunScriptCode", "StopRed(); ::BLOCK_RED <- true; SwitchToElevatorRed()", 0, 1)
    EntityOutputs.AddOutput(ssplr_red_lift_finale1_relay_embark, "OnTrigger", "!self", "RunScriptCode", "::BLOCK_RED <- false", 1.05, 1)

    EntityOutputs.AddOutput(ssplr_blu_lift_finale1_relay_embark, "OnTrigger", "ssplr_blu_train", "AddOutput", "manualaccelspeed 999", 0.3, -1)
    EntityOutputs.AddOutput(ssplr_blu_lift_finale1_relay_embark, "OnTrigger", "ssplr_blu_train", "AddOutput", "manualdecelspeed 999", 0.3, -1)
    EntityOutputs.AddOutput(ssplr_blu_lift_finale1_relay_embark, "OnTrigger", "!self", "RunScriptCode", "StopBlu(); ::BLOCK_BLU <- true; SwitchToElevatorBlu()", 0, 1)
    EntityOutputs.AddOutput(ssplr_blu_lift_finale1_relay_embark, "OnTrigger", "!self", "RunScriptCode", "::BLOCK_BLU <- false", 1.05, 1)

    EntityOutputs.AddOutput(MM_GetEntByName("ssplr_red_path_lift_finale1_3reverse"), "OnTrigger", "!self", "RunScriptCode", "if (!BLOCK_RED) ::RED_AT_BOTTOM <- true; UpdateBluCart(CASE_BLU)", 0, -1)
    EntityOutputs.AddOutput(MM_GetEntByName("ssplr_blu_path_lift_finale1_3reverse"), "OnTrigger", "!self", "RunScriptCode", "if (!BLOCK_BLU) ::BLU_AT_BOTTOM <- true; UpdateRedCart(CASE_RED)", 0, -1)

    // Add thinks to carts
    CreateCartAutoUpdater(RED_TRAIN, 2);
    CreateCartAutoUpdater(BLU_TRAIN, 3);

    EntFireByHandle(Gamerules(), "RunScriptCode", "DelayedSetup()", 1.0, null, null);
}

// executes after logic_auto does its thing
function DelayedSetup()
{

}

::StartOvertimeBase <- StartOvertime;

function StartOvertime() {


    StartOvertimeBase();
}

::AdvanceRedBase <- AdvanceRed;
::StopRedBase <- StopRed;
::TriggerRollbackRedBase <- TriggerRollbackRed;
::AdvanceBluBase <- AdvanceBlu;
::StopBluBase <- StopBlu;
::TriggerRollbackBluBase <- TriggerRollbackBlu;

// ::UpdateRedCartBase <- UpdateRedCart;
// ::UpdateBluCartBase <- UpdateBluCart;

function AdvanceRed(speed, dynamic = true) {
    if (RED_ELV) dynamic = false;
    AdvanceRedBase(speed, dynamic);
    if (RED_ELV) {
        ::RED_AT_BOTTOM = false;
        EntFireByHandle(RED_ELV, "SetSpeedDirAccel", "" + speed, 0, null, null);
    }
}

function StopRed() {
    StopRedBase();
    if (RED_ELV) {
        local currentSpeed = NetProps.GetPropFloat(RED_ELV, "m_flSpeed");
        if (currentSpeed == 0) EntFireByHandle(RED_ELV, "Stop", "", 0, null, null);
    }
}

function TriggerRollbackRed() {
    TriggerRollbackRedBase();
    if(RED_ELV) {
        EntFireByHandle(RED_ELV, "SetSpeedDirAccel", "" + ROLLBACK_SPEED_RED, 0, null, null);
    }
}

function AdvanceBlu(speed, dynamic = true) {
    if (BLU_ELV) dynamic = false;
    AdvanceBluBase(speed, dynamic);
    if (BLU_ELV) {
        ::BLU_AT_BOTTOM = false;
        EntFireByHandle(BLU_ELV, "SetSpeedDirAccel", "" + speed, 0, null, null);
    }
}

function StopBlu() {
    StopBluBase();
    if (BLU_ELV) {
        local currentSpeed = NetProps.GetPropFloat(BLU_ELV, "m_flSpeed");
        if (currentSpeed == 0) EntFireByHandle(BLU_ELV, "Stop", "", 0, null, null);
    }
}

function TriggerRollbackBlu() {
    TriggerRollbackBluBase();
    if(BLU_ELV) {
        EntFireByHandle(BLU_ELV, "SetSpeedDirAccel", "" + ROLLBACK_SPEED_BLU, 0, null, null);
    }
}

// The RED/BLU specific hud only appears when the respective counter-boost is active.
function UpdateHUD() {
    local toTrigger = null;
    if (!RED_ELV || !BLU_ELV) {
        return;
    } else if (CASE_RED > 0 && CASE_BLU > 0) { // Both carts being pushed
        toTrigger = "status_off"
    } else if (CASE_RED > 0 && CASE_BLU == 0 && !BLU_AT_BOTTOM) { // RED counter-boost
        toTrigger = "status_red"
    } else if (CASE_RED == 0 && !RED_AT_BOTTOM && CASE_BLU > 0) { // BLU counter-boost
        toTrigger = "status_blu"
    } else if (CASE_RED == 0 && CASE_BLU == 0) { // Hold
        toTrigger = "status_yellow"
    } else {
        toTrigger = "status_off"
    }

    MM_GetEntByName(toTrigger).AcceptInput("Trigger", "", null, null);
}

function UpdateRedCart(caseNumber) {
    ::CASE_RED = caseNumber;

    if(BLOCK_RED) return;

    local isCounterBoost = !RED_ELV || (BLU_ELV && !BLU_AT_BOTTOM && CASE_BLU) == 0;
    local speedFactor = isCounterBoost ? 1.0 : 0.5;

    if(CASE_RED == 1) {
        AdvanceRed(TIMES_1_SPEED_RED * speedFactor);
    } else if(CASE_RED == 2) {
        AdvanceRed(TIMES_2_SPEED_RED * speedFactor);
    } else if(CASE_RED >= 3) {
        AdvanceRed(TIMES_3_SPEED_RED * speedFactor);
    } else if (CASE_RED == -1) {
        StopRed();
    }

    if(CASE_RED == 0) {
        if(CASE_BLU == 0 && OVERTIME_ACTIVE) {
            AdvanceRed(OVERTIME_SPEED_RED);
            if(!BLOCK_BLU) AdvanceBlu(OVERTIME_SPEED_BLU);
        } else if (!(OVERTIME_ACTIVE && ROLLBACK_DISABLED) && RED_ROLLSTATE == -1
            && !(RED_ELV && BLU_ELV && CASE_BLU == 0)) { // If BLU cart is on the lift and not being pushed, activate HOLD state.
            TriggerRollbackRed();
        } else {
            StopRed();
        }
    } else if ((BLU_ELV || OVERTIME_ACTIVE) && CASE_BLU == 0) {
        UpdateBluCart(0);
    }

    UpdateHUD();
}

function UpdateBluCart(caseNumber) {
    ::CASE_BLU = caseNumber;

    if(BLOCK_BLU) return;

    local isCounterBoost = !BLU_ELV || (RED_ELV && !RED_AT_BOTTOM && CASE_RED) == 0;
    local speedFactor = isCounterBoost ? 1.0 : 0.5;

    if(CASE_BLU == 1) {
        AdvanceBlu(TIMES_1_SPEED_BLU * speedFactor);
    } else if(CASE_BLU == 2) {
        AdvanceBlu(TIMES_2_SPEED_BLU * speedFactor);
    } else if(CASE_BLU >= 3) {
        AdvanceBlu(TIMES_3_SPEED_BLU * speedFactor);
    } else if (CASE_BLU == -1) {
        StopBlu();
    }

    if(CASE_BLU == 0) {
        if(CASE_RED == 0 && OVERTIME_ACTIVE) {
            AdvanceBlu(OVERTIME_SPEED_BLU);
            if(!BLOCK_RED) AdvanceRed(OVERTIME_SPEED_RED);
        } else if (!(OVERTIME_ACTIVE && ROLLBACK_DISABLED) && BLU_ROLLSTATE == -1
            && !(BLU_ELV && RED_ELV && CASE_RED == 0)) { // If both carts are on the lift and not being pushed, activate HOLD state.
            TriggerRollbackBlu();
        } else {
            StopBlu();
        }
    } else if ((RED_ELV || OVERTIME_ACTIVE) && CASE_RED == 0) {
        UpdateRedCart(0);
    }

    UpdateHUD();
}

// New speeds assume counter-boost is in effect (if not, use 50% of given value)
function SwitchToElevatorRed() {
    ::RED_ELV <- MM_GetEntByName("ssplr_red_lift_finale1_train");
    ::RED_PUSHZONE <- MM_GetEntByName("ssplr_red_lift_finale1_pushzone");
    EntityOutputs.AddOutput(RED_PUSHZONE, "OnNumCappersChanged2", "mm_plr_logiccase_red", "InValue", "", 0, -1);
    ROLLBACK_SPEED_RED = -0.5;
    OVERTIME_SPEED_RED = 0.1;
    TIMES_1_SPEED_RED = 0.33;
    TIMES_2_SPEED_RED = 0.5;
    TIMES_3_SPEED_RED = 0.66;

    UpdateHUD();
}

function SwitchToElevatorBlu() {
    ::BLU_ELV <- MM_GetEntByName("ssplr_blu_lift_finale1_train");
    ::BLU_PUSHZONE <- MM_GetEntByName("ssplr_blu_lift_finale1_pushzone");
    EntityOutputs.AddOutput(BLU_PUSHZONE, "OnNumCappersChanged2", "mm_plr_logiccase_blu", "InValue", "", 0, -1);
    ROLLBACK_SPEED_BLU = -0.5;
    OVERTIME_SPEED_BLU = 0.1;
    TIMES_1_SPEED_BLU = 0.33;
    TIMES_2_SPEED_BLU = 0.5;
    TIMES_3_SPEED_BLU = 0.66;

    UpdateHUD();
}

__CollectGameEventCallbacks(this);