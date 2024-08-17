ClearGameEventCallbacks();
IncludeScript("mega_mod/common/plr_overtime.nut");

function OnGameEvent_teamplay_round_start(params) {

    InitGlobalVars();

    ::PLR_TIMER_NAME <- "minecart_timer";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    ::RED_CARTSPARKS_ARRAY <- MM_GetEntArrayByName("minecart_red_cartsparks");
    ::BLU_CARTSPARKS_ARRAY <- MM_GetEntArrayByName("minecart_blu_cartsparks");

    ::RED_FLASHINGLIGHT <- MM_GetEntByName("minecart_red_flashinglight");
    ::BLU_FLASHINGLIGHT <- MM_GetEntByName("minecart_blu_flashinglight");

    ::RED_PUSHZONE <- MM_GetEntByName("minecart_red_pushzone");
    ::BLU_PUSHZONE <- MM_GetEntByName("minecart_blu_pushzone");

    ::RED_TRAIN <- MM_GetEntByName("minecart_red_train");
    ::BLU_TRAIN <- MM_GetEntByName("minecart_blu_train");

    ::RED_LOGICCASE <- CreateLogicCase("mm_plr_logiccase_red", "Red");
    ::BLU_LOGICCASE <- CreateLogicCase("mm_plr_logiccase_blu", "Blu");

    EntityOutputs.AddOutput(RED_PUSHZONE, "OnNumCappersChanged2", "mm_plr_logiccase_red", "InValue", "", 0, -1);
    EntityOutputs.AddOutput(BLU_PUSHZONE, "OnNumCappersChanged2", "mm_plr_logiccase_blu", "InValue", "", 0, -1);

    // Rollzones RED

    AddRollbackZone("minecart_path_36", "minecart_path_38", "minecart_path_35", "Red");
    AddRollforwardZone("minecart_path_48", "minecart_path_52", "minecart_path_51", "Red");
    AddRollbackZone("minecart_path_57", "minecart_path_68", "minecart_path_56", "Red");
    AddRollbackZone("minecart_path_77", "minecart_path_78", "minecart_path_76", "Red");
    AddRollbackZone("minecart_path_88", null, "minecart_path_87", "Red");

    // Rollzones BLU

    AddRollbackZone("minecart_bpath_36", "minecart_bpath_38", "minecart_bpath_35", "Blu");
    AddRollforwardZone("minecart_bpath_48", "minecart_bpath_52", "minecart_bpath_51", "Blu");
    AddRollbackZone("minecart_bpath_57", "minecart_bpath_68", "minecart_bpath_56", "Blu");
    AddRollbackZone("minecart_bpath_77", "minecart_bpath_78", "minecart_bpath_76", "Blu");
    AddRollbackZone("minecart_bpath_80", null, "minecart_bpath_88", "Blu");

    // Update carts whenever trains move out of the way (carts waiting at final ramp don't autoresume)
    EntityOutputs.AddOutput(MM_GetEntByName("path_mid_a7"), "OnPass", "!self", "RunScriptCode", "UpdateRedCart(CASE_RED)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("path_mid_a10"), "OnPass", "!self", "RunScriptCode", "UpdateRedCart(CASE_RED)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("relay_enable_red_cap"), "OnTrigger", "!self", "RunScriptCode", "UpdateRedCart(CASE_RED)", 0, -1);

    EntityOutputs.AddOutput(MM_GetEntByName("path_mid_a7"), "OnPass", "!self", "RunScriptCode", "UpdateBluCart(CASE_BLU)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("path_mid_a10"), "OnPass", "!self", "RunScriptCode", "UpdateBluCart(CASE_BLU)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("relay_enable_blu_cap"), "OnTrigger", "!self", "RunScriptCode", "UpdateBluCart(CASE_BLU)", 0, -1);

    // team_train_watcher is no longer in charge.
    NetProps.SetPropBool(MM_GetEntByName("minecart_red_watcherA"), "m_bHandleTrainMovement", false);
    NetProps.SetPropBool(MM_GetEntByName("minecart_blu_watcherA"), "m_bHandleTrainMovement", false);

    EntityOutputs.AddOutput(RED_PUSHZONE, "OnNumCappersChanged2", "minecart_red_watcherA", "SetNumTrainCappers", "", 0, -1);
    EntityOutputs.AddOutput(BLU_PUSHZONE, "OnNumCappersChanged2", "minecart_blu_watcherA", "SetNumTrainCappers", "", 0, -1);

    // Timer logic replacement
    EntityOutputs.RemoveOutput(PLR_TIMER, "OnSetupFinished", PLR_TIMER_NAME, "Disable", "");
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", PLR_TIMER_NAME, "SetTime", "600", 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "StartOvertime()", 0, -1);
}

__CollectGameEventCallbacks(this);