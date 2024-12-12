ClearGameEventCallbacks();
IncludeScript("mega_mod/common/plr_overtime.nut");

function OnGameEvent_teamplay_round_start(params) {

    InitGlobalVars();

    ::PLR_TIMER_NAME <- "plr_timer";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    ::RED_CARTSPARKS_ARRAY <- MM_GetEntArrayByName("plr_red_cartsparks");
    ::BLU_CARTSPARKS_ARRAY <- MM_GetEntArrayByName("plr_blu_cartsparks");

    ::RED_PUSHZONE <- MM_GetEntByName("plr_red_pushzone");
    ::BLU_PUSHZONE <- MM_GetEntByName("plr_blu_pushzone");

    ::RED_TRAIN <- MM_GetEntByName("plr_red_train");
    ::BLU_TRAIN <- MM_GetEntByName("plr_blu_train");

    ::RED_LOGICCASE <- CreateLogicCase("mm_plr_logiccase_red", "Red");
    ::BLU_LOGICCASE <- CreateLogicCase("mm_plr_logiccase_blu", "Blu");

    EntityOutputs.AddOutput(RED_PUSHZONE, "OnNumCappersChanged2", "mm_plr_logiccase_red", "InValue", "", 0, -1);
    EntityOutputs.AddOutput(BLU_PUSHZONE, "OnNumCappersChanged2", "mm_plr_logiccase_blu", "InValue", "", 0, -1);

    // Rollzones RED
    AddRollbackZone("path_red_rollback2_1", "path_red_rollback2_5", "path_red_256CCW_2_9", "Red");
    AddRollbackZone("path_red_rollback3_1", "path_red_rollback3_5", "path_red_45bCCW_2_4", "Red");
    AddRollbackZone("path_red_finalhill1", "plr_red_pathA_end", "path_red_128CCW_3_5", "Red");

    // Rollzones BLU
    AddRollbackZone("path_blu_rollback2_1", "path_blu_rollback2_5", "path_blu_256CCW_2_9", "Blu");
    AddRollbackZone("path_blu_rollback3_1", "path_blu_rollback3_5", "path_blu_45bCCW_2_4", "Blu");
    AddRollbackZone("path_blu_finalhill1", "plr_blu_pathA_end", "path_blu_finalhill1", "Blu");

    // Crossing logic replacement

    foreach(entName in [
        "plr_red_crossover1_branch"
        "plr_red_crossover1_relay"
        "plr_blu_crossover1_branch"
        "plr_blu_crossover1_relay"
    ]) {
        MM_GetEntByName(entName).Kill();
    }

    AddCrossing("plr_red_crossover1_start", "plr_red_crossover1_end", "plr_blu_crossover1_start", "plr_blu_crossover1_end", 1);

    // team_train_watcher is no longer in charge.
    NetProps.SetPropBool(MM_GetEntByName("plr_red_watcherA"), "m_bHandleTrainMovement", false);
    NetProps.SetPropBool(MM_GetEntByName("plr_blu_watcherA"), "m_bHandleTrainMovement", false);

    EntityOutputs.AddOutput(RED_PUSHZONE, "OnNumCappersChanged2", "plr_red_watcherA", "SetNumTrainCappers", "", 0, -1);
    EntityOutputs.AddOutput(BLU_PUSHZONE, "OnNumCappersChanged2", "plr_blu_watcherA", "SetNumTrainCappers", "", 0, -1);

    // Timer logic replacement
    EntityOutputs.RemoveOutput(PLR_TIMER, "OnSetupFinished", PLR_TIMER_NAME, "Disable", "");
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", "600", 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "StartOvertime()", 0, -1);
}

__CollectGameEventCallbacks(this);