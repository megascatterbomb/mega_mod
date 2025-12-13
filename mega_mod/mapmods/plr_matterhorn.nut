ClearGameEventCallbacks();
IncludeScript("mega_mod/common/plr_overtime.nut");

function OnGameEvent_teamplay_round_start(params) {
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

    // Add thinks to carts
    CreateCartAutoUpdater(RED_TRAIN, 2);
    CreateCartAutoUpdater(BLU_TRAIN, 3);
}

::StartOvertimeBase <- StartOvertime;

function StartOvertime() {

    // elevator movement logic replacement

    local elevator_overtime_speed = 0.1;

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
    EntityOutputs.AddOutput(red_staycase, "OnCase02", "ssplr_red_lift_finale1_train", "SetSpeedDirAccel", "" + elevator_overtime_speed, 0, -1);
    EntityOutputs.AddOutput(red_staycase, "OnCase02", "ssplr_red_train", "SetSpeedDirAccel", "" + elevator_overtime_speed, 0, -1);
    EntityOutputs.AddOutput(red_staycase, "OnCase02", "wheel_red", "SetSpeed", "" + elevator_overtime_speed, 0, -1);

    //EntityOutputs.RemoveOutput(blu_staycase, "OnCase02", "ssplr_blu_lift_finale1_crush", "Disable", "");
    EntityOutputs.AddOutput(blu_staycase, "OnCase02", "ssplr_blu_lift_finale1_lights", "Start", "", 0, -1);
    //EntityOutputs.RemoveOutput(blu_staycase, "OnCase02", "ssplr_blu_lift_finale1_sparks", "StopSpark", "");
    EntityOutputs.AddOutput(blu_staycase, "OnCase02", "ssplr_blu_lift_finale1_train", "SetSpeedDirAccel", "" + elevator_overtime_speed, 0, -1);
    EntityOutputs.AddOutput(blu_staycase, "OnCase02", "ssplr_blu_train", "SetSpeedDirAccel", "" + elevator_overtime_speed, 0, -1);
    EntityOutputs.AddOutput(blu_staycase, "OnCase02", "wheel_blu", "SetSpeed", "" + elevator_overtime_speed, 0, -1);

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