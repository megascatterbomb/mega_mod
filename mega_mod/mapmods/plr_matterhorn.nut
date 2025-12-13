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

    ::RED_ON_ELV <- false;
    ::BLU_ON_ELV <- false;

    ::RED_WATCHER <- MM_GetEntByName("ssplr_red_watcherA");
    ::BLU_WATCHER <- MM_GetEntByName("ssplr_blu_watcherA");

    ::RED_LOGICCASE <- CreateLogicCase("mm_plr_logiccase_red", "Red");
    ::BLU_LOGICCASE <- CreateLogicCase("mm_plr_logiccase_blu", "Blu");

    ::ELEVATOR_OVERTIME_SPEED <- 0.1;

    EntityOutputs.AddOutput(RED_PUSHZONE, "OnNumCappersChanged2", "mm_plr_logiccase_red", "InValue", "", 0, -1);
    EntityOutputs.AddOutput(BLU_PUSHZONE, "OnNumCappersChanged2", "mm_plr_logiccase_blu", "InValue", "", 0, -1);

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

    // this pushzone is ONLY for the pre-lift section.
    EntityOutputs.AddOutput(RED_PUSHZONE, "OnNumCappersChanged2", "ssplr_red_watcherA", "SetNumTrainCappers", "", 0, -1);
    EntityOutputs.AddOutput(BLU_PUSHZONE, "OnNumCappersChanged2", "ssplr_blu_watcherA", "SetNumTrainCappers", "", 0, -1);

    // elevator transition logic replacement

    local red_disembark = MM_GetEntByName("ssplr_red_lift_finale1_relay_disembark");
    local blu_disembark = MM_GetEntByName("ssplr_blu_lift_finale1_relay_disembark");

    local red_embark = MM_GetEntByName("ssplr_red_lift_finale1_relay_embark");
    local blu_embark = MM_GetEntByName("ssplr_blu_lift_finale1_relay_embark");

    EntityOutputs.RemoveOutput(red_disembark, "OnTrigger", "ssplr_red_watcherA", "AddOutput", "handle_train_movement 1");
    EntityOutputs.RemoveOutput(red_disembark, "OnTrigger", "ssplr_red_watcherA", "SetNumTrainCappers", "1");

    EntityOutputs.RemoveOutput(blu_disembark, "OnTrigger", "ssplr_blu_watcherA", "AddOutput", "handle_train_movement 1");
    EntityOutputs.RemoveOutput(blu_disembark, "OnTrigger", "ssplr_blu_watcherA", "SetNumTrainCappers", "1");

    EntityOutputs.AddOutput(red_disembark, "OnTrigger", "!self", "RunScriptCode", "::RED_ON_ELV <- false", 0, -1);
    EntityOutputs.AddOutput(red_disembark, "OnTrigger", "!self", "RunScriptCode", "AdvanceRedBase(0.55, false)", 0.3, -1);
    EntityOutputs.AddOutput(red_disembark, "OnTrigger", "!self", "RunScriptCode", "StopRedBase()", 0.4, -1);

    EntityOutputs.AddOutput(blu_disembark, "OnTrigger", "!self", "RunScriptCode", "::BLU_ON_ELV <- false", 0, -1);
    EntityOutputs.AddOutput(blu_disembark, "OnTrigger", "!self", "RunScriptCode", "AdvanceBluBase(0.55, false)", 0.3, -1);
    EntityOutputs.AddOutput(blu_disembark, "OnTrigger", "!self", "RunScriptCode", "StopBluBase()", 0.4, -1);

    EntityOutputs.AddOutput(red_embark, "OnTrigger", "!self", "RunScriptCode", "::RED_ON_ELV <- true", 0, -1);
    EntityOutputs.AddOutput(blu_embark, "OnTrigger", "!self", "RunScriptCode", "::BLU_ON_ELV <- true", 0, -1);

    // rollback logic replacement

    // these sit between ssplr_red_lift_finale1_rollback and ssplr_red_lift_rollback_relay_rb1
    // once overtime hits, we detour through this branch, which is set to true if the opposite cart (NOT LIFT) is being pushed.
    // if true, we pass to the vanilla rollback relay. if false, we pass to our own relay which advances the cart.

    local red_rollback_postcheck = SpawnEntityFromTable("logic_branch", {
        targetname = "mm_ssplr_red_rollback_postcheck"
        InitialValue = "0"
        "OnTrue#1" : "ssplr_red_lift_rollback_relay_rb1,Trigger,,0,-1"
        "OnFalse#1" : "ssplr_red_lift_rollback_relay_overtime,Trigger,,0,-1"
    });
    local blu_rollback_postcheck = SpawnEntityFromTable("logic_branch", {
        targetname = "mm_ssplr_blu_rollback_postcheck"
        InitialValue = "0"
        "OnTrue#1" : "ssplr_blu_lift_rollback_relay_rb1,Trigger,,0,-1"
        "OnFalse#1" : "ssplr_blu_lift_rollback_relay_overtime,Trigger,,0,-1"
    });

    local red_rollback_overtime_relay = SpawnEntityFromTable("logic_relay", {
        targetname = "ssplr_red_lift_rollback_relay_overtime"
        "OnTrigger#1" : "ssplr_red_train,SetSpeedDirAccel," + ELEVATOR_OVERTIME_SPEED + ",0,-1"
        "OnTrigger#2" : "ssplr_red_lift_finale1_train,SetSpeedDirAccel," + ELEVATOR_OVERTIME_SPEED + ",0,-1"
        "OnTrigger#3" : "ssplr_red_lift_finale1_lights,Start,,0,-1"
        "OnTrigger#4" : "wheel_red,SetSpeed," + ELEVATOR_OVERTIME_SPEED + ",0,-1"
        "OnTrigger#5" : "ssplr_red_lift_finale1_sparks,StopSpark,,0,-1"
        "OnTrigger#6": "ssplr_red_lift_finale1_crush,Disable,,0,-1"
    });
    local blu_rollback_overtime_relay = SpawnEntityFromTable("logic_relay", {
        targetname = "ssplr_blu_lift_rollback_relay_overtime"
        "OnTrigger#1" : "ssplr_blu_train,SetSpeedDirAccel," + ELEVATOR_OVERTIME_SPEED + ",0,-1"
        "OnTrigger#2" : "ssplr_blu_lift_finale1_train,SetSpeedDirAccel," + ELEVATOR_OVERTIME_SPEED + ",0,-1"
        "OnTrigger#3" : "ssplr_blu_lift_finale1_lights,Start,,0,-1"
        "OnTrigger#4" : "wheel_blu,SetSpeed," + ELEVATOR_OVERTIME_SPEED + ",0,-1"
        "OnTrigger#5" : "ssplr_blu_lift_finale1_sparks,StopSpark,,0,-1"
        "OnTrigger#6": "ssplr_blu_lift_finale1_crush,Disable,,0,-1"
    });

    // TODO:
    // send output from cart pushzone to set the opposite cart's postcheck branch
    // send output when cart reaches elevator to set this branch to true again.
    // rewire ssplr_red_lift_finale1_rollback to this logic when overtime starts.
    // repeat this for blu.

    // Add thinks to carts
    CreateCartAutoUpdater(RED_TRAIN, 2);
    CreateCartAutoUpdater(BLU_TRAIN, 3);
}

::StartOvertimeBase <- StartOvertime;

function StartOvertime() {

    // elevator movement logic replacement - staycase


    local red_staycase = MM_GetEntByName("ssplr_red_lift_finale1_staycase");
    local blu_staycase = MM_GetEntByName("ssplr_blu_lift_finale1_staycase");

    //EntityOutputs.RemoveOutput(red_staycase, "OnCase02", "ssplr_red_lift_finale1_crush", "Disable", "");
    EntityOutputs.RemoveOutput(red_staycase, "OnCase02", "ssplr_red_lift_finale1_lights", "Stop", "");
    //EntityOutputs.RemoveOutput(red_staycase, "OnCase02", "ssplr_red_lift_finale1_sparks", "StopSpark", "");
    EntityOutputs.RemoveOutput(red_staycase, "OnCase02", "ssplr_red_lift_finale1_train", "SetSpeedDirAccel", "0");
    EntityOutputs.RemoveOutput(red_staycase, "OnCase02", "ssplr_red_train", "SetSpeedDirAccel", "0");
    EntityOutputs.RemoveOutput(red_staycase, "OnCase02", "wheel_red", "SetSpeed", "0");

    //EntityOutputs.RemoveOutput(blu_staycase, "OnCase02", "ssplr_blu_lift_finale1_crush", "Disable", "");
    EntityOutputs.RemoveOutput(blu_staycase, "OnCase02", "ssplr_blu_lift_finale1_lights", "Stop", "");
    //EntityOutputs.RemoveOutput(blu_staycase, "OnCase02", "ssplr_blu_lift_finale1_sparks", "StopSpark", "");
    EntityOutputs.RemoveOutput(blu_staycase, "OnCase02", "ssplr_blu_lift_finale1_train", "SetSpeedDirAccel", "0");
    EntityOutputs.RemoveOutput(blu_staycase, "OnCase02", "ssplr_blu_train", "SetSpeedDirAccel", "0");
    EntityOutputs.RemoveOutput(blu_staycase, "OnCase02", "wheel_blu", "SetSpeed", "0");

    //EntityOutputs.RemoveOutput(red_staycase, "OnCase02", "ssplr_red_lift_finale1_crush", "Disable", "");
    EntityOutputs.AddOutput(red_staycase, "OnCase02", "ssplr_red_lift_finale1_lights", "Start", "", 0, -1);
    //EntityOutputs.RemoveOutput(red_staycase, "OnCase02", "ssplr_red_lift_finale1_sparks", "StopSpark", "");
    EntityOutputs.AddOutput(red_staycase, "OnCase02", "ssplr_red_lift_finale1_train", "SetSpeedDirAccel", "" + ELEVATOR_OVERTIME_SPEED, 0, -1);
    EntityOutputs.AddOutput(red_staycase, "OnCase02", "ssplr_red_train", "SetSpeedDirAccel", "" + ELEVATOR_OVERTIME_SPEED, 0, -1);
    EntityOutputs.AddOutput(red_staycase, "OnCase02", "wheel_red", "SetSpeed", "" + ELEVATOR_OVERTIME_SPEED, 0, -1);

    //EntityOutputs.RemoveOutput(blu_staycase, "OnCase02", "ssplr_blu_lift_finale1_crush", "Disable", "");
    EntityOutputs.AddOutput(blu_staycase, "OnCase02", "ssplr_blu_lift_finale1_lights", "Start", "", 0, -1);
    //EntityOutputs.RemoveOutput(blu_staycase, "OnCase02", "ssplr_blu_lift_finale1_sparks", "StopSpark", "");
    EntityOutputs.AddOutput(blu_staycase, "OnCase02", "ssplr_blu_lift_finale1_train", "SetSpeedDirAccel", "" + ELEVATOR_OVERTIME_SPEED, 0, -1);
    EntityOutputs.AddOutput(blu_staycase, "OnCase02", "ssplr_blu_train", "SetSpeedDirAccel", "" + ELEVATOR_OVERTIME_SPEED, 0, -1);
    EntityOutputs.AddOutput(blu_staycase, "OnCase02", "wheel_blu", "SetSpeed", "" + ELEVATOR_OVERTIME_SPEED, 0, -1);

    // elevator movement logic replacement - rollback branch

    local red_rollback = MM_GetEntByName("ssplr_red_lift_finale1_rollback");
    local blu_rollback = MM_GetEntByName("ssplr_blu_lift_finale1_rollback");

    EntityOutputs.RemoveOutput(red_rollback, "OnTrigger", "ssplr_red_lift_finale1_lights", "Stop", "0");
    EntityOutputs.RemoveOutput(red_rollback, "OnTrigger", "ssplr_red_lift_finale1_train", "SetSpeedDirAccel", "0");
    EntityOutputs.RemoveOutput(red_rollback, "OnTrigger", "ssplr_red_train", "SetSpeedDirAccel", "0");
    EntityOutputs.RemoveOutput(red_rollback, "OnTrigger", "wheel_red", "Stop", "0");

    EntityOutputs.RemoveOutput(blu_rollback, "OnTrigger", "ssplr_blu_lift_finale1_lights", "Stop", "0");
    EntityOutputs.RemoveOutput(blu_rollback, "OnTrigger", "ssplr_blu_lift_finale1_train", "SetSpeedDirAccel", "0");
    EntityOutputs.RemoveOutput(blu_rollback, "OnTrigger", "ssplr_blu_train", "SetSpeedDirAccel", "0");
    EntityOutputs.RemoveOutput(blu_rollback, "OnTrigger", "wheel_blu", "Stop", "0");

    EntityOutputs.AddOutput(red_rollback, "OnTrigger", "ssplr_red_lift_finale1_lights", "Start", "", 0, -1);
    EntityOutputs.AddOutput(red_rollback, "OnTrigger", "ssplr_red_lift_finale1_train", "SetSpeedDirAccel", "" + ELEVATOR_OVERTIME_SPEED, 0, -1);
    EntityOutputs.AddOutput(red_rollback, "OnTrigger", "ssplr_red_train", "SetSpeedDirAccel", "" + ELEVATOR_OVERTIME_SPEED, 0, -1);
    EntityOutputs.AddOutput(red_rollback, "OnTrigger", "wheel_red", "SetSpeed", "" + ELEVATOR_OVERTIME_SPEED, 0, -1);

    EntityOutputs.AddOutput(blu_rollback, "OnTrigger", "ssplr_blu_lift_finale1_lights", "Start", "", 0, -1);
    EntityOutputs.AddOutput(blu_rollback, "OnTrigger", "ssplr_blu_lift_finale1_train", "SetSpeedDirAccel", "" + ELEVATOR_OVERTIME_SPEED, 0, -1);
    EntityOutputs.AddOutput(blu_rollback, "OnTrigger", "ssplr_blu_train", "SetSpeedDirAccel", "" + ELEVATOR_OVERTIME_SPEED, 0, -1);
    EntityOutputs.AddOutput(blu_rollback, "OnTrigger", "wheel_blu", "SetSpeed", "" + ELEVATOR_OVERTIME_SPEED, 0, -1);

    StartOvertimeBase();
}

::AdvanceRedBase <- AdvanceRed;
::StopRedBase <- StopRed;
::TriggerRollbackRedBase <- TriggerRollbackRed;
::AdvanceBluBase <- AdvanceBlu;
::StopBluBase <- StopBlu;
::TriggerRollbackBluBase <- TriggerRollbackBlu;

::UpdateRedCartBase <- UpdateRedCart;
::UpdateBluCartBase <- UpdateBluCart;

// If cart on elevator:
// ignore all cart movement calls and let the elevator logic handle it.

function AdvanceRed(speed, dynamic = true) {
    if (RED_ON_ELV) return;
    AdvanceRedBase(speed, dynamic);
}

function StopRed() {
    if (RED_ON_ELV) return;
    StopRedBase();
}

function TriggerRollbackRed() {
    if (RED_ON_ELV) return;
    TriggerRollbackRedBase();
}

function AdvanceBlu(speed, dynamic = true) {
    if (BLU_ON_ELV) return;
    AdvanceBluBase(speed, dynamic);
}

function StopBlu() {
    if (BLU_ON_ELV) return;
    StopBluBase();
}

function TriggerRollbackBlu() {
    if (BLU_ON_ELV) return;
    TriggerRollbackBluBase();
}

// Allow cart updates even on elevator, so the other cart can respond to it.
// We've blocked movement calls above so these should be safe to run 100% of the time.

function UpdateRedCart(caseNumber) {
    UpdateRedCartBase(caseNumber);
}

function UpdateBluCart(caseNumber) {
    UpdateBluCartBase(caseNumber);
}

__CollectGameEventCallbacks(this);