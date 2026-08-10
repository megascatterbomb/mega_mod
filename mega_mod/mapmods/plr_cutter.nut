ClearGameEventCallbacks();
IncludeScript("mega_mod/common/plr_overtime.nut");

function OnGameEvent_teamplay_round_start(params) {

    InitGlobalVars();

    ::PLR_TIMER_NAME <- "plr_timer";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    PLR_TEAMS[2].cartsparks = MM_GetEntArrayByName("plr_red_cartsparks");
    PLR_TEAMS[3].cartsparks = MM_GetEntArrayByName("plr_blu_cartsparks");

    PLR_TEAMS[2].pushzone = MM_GetEntByName("plr_red_pushzone");
    PLR_TEAMS[3].pushzone = MM_GetEntByName("plr_blu_pushzone");

    PLR_TEAMS[2].train = MM_GetEntByName("plr_red_train");
    PLR_TEAMS[3].train = MM_GetEntByName("plr_blu_train");

    PLR_TEAMS[2].logiccase = PLR_CreateLogicCase(2, "mm_plr_logiccase_red");
    PLR_TEAMS[3].logiccase = PLR_CreateLogicCase(3, "mm_plr_logiccase_blu");

    PLR_TEAMS[2].watcher = MM_GetEntByName("plr_red_watcherA");
    PLR_TEAMS[3].watcher = MM_GetEntByName("plr_blu_watcherA");

    EntityOutputs.AddOutput(PLR_TEAMS[2].pushzone, "OnNumCappersChanged2", "mm_plr_logiccase_red", "InValue", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[3].pushzone, "OnNumCappersChanged2", "mm_plr_logiccase_blu", "InValue", "", 0, -1);

    // Rollzones
    PLR_AddRollbackZone(2, "path_red_rollback2_1", "path_red_rollback2_5", "path_red_256CCW_2_9");
    PLR_AddRollbackZone(2, "path_red_rollback3_1", "path_red_rollback3_5", "path_red_45bCCW_2_4");
    PLR_AddRollbackZone(2, "path_red_finalhill1", "plr_red_pathA_end", "path_red_128CCW_3_5");
    PLR_AddRollbackZone(3, "path_blu_rollback2_1", "path_blu_rollback2_5", "path_blu_256CCW_2_9");
    PLR_AddRollbackZone(3, "path_blu_rollback3_1", "path_blu_rollback3_5", "path_blu_45bCCW_2_4");
    PLR_AddRollbackZone(3, "path_blu_finalhill1", "plr_blu_pathA_end", "path_blu_finalhill1");

    // Crossing logic replacement
    foreach(entName in [
        "plr_red_crossover1_branch"
        "plr_red_crossover1_relay"
        "plr_blu_crossover1_branch"
        "plr_blu_crossover1_relay"
    ]) {
        MM_GetEntByName(entName).Kill();
    }

    PLR_AddCrossing([
        ["plr_red_crossover1_start", "plr_red_crossover1_end", 2],
        ["plr_blu_crossover1_start", "plr_blu_crossover1_end", 3]
    ]);

    // team_train_watcher is no longer in charge.
    NetProps.SetPropBool(PLR_TEAMS[2].watcher, "m_bHandleTrainMovement", false);
    NetProps.SetPropBool(PLR_TEAMS[3].watcher, "m_bHandleTrainMovement", false);

    EntityOutputs.AddOutput(PLR_TEAMS[2].pushzone, "OnNumCappersChanged2", "plr_red_watcherA", "SetNumTrainCappers", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[3].pushzone, "OnNumCappersChanged2", "plr_blu_watcherA", "SetNumTrainCappers", "", 0, -1);

    // Timer logic replacement
    EntityOutputs.RemoveOutput(PLR_TIMER, "OnSetupFinished", PLR_TIMER_NAME, "Disable", "");
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", PLR_GetRoundTimeString(), 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "PLR_StartOvertime()", 0, -1);

    // Add thinks to carts
    PLR_CreateCartAutoUpdater(2, PLR_TEAMS[2].train);
    PLR_CreateCartAutoUpdater(3, PLR_TEAMS[3].train);
}

__CollectGameEventCallbacks(this);
