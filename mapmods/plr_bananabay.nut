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

    // team_train_watcher is no longer in charge.
    NetProps.SetPropBool(MM_GetEntByName("minecart_red_watcherA"), "m_bHandleTrainMovement", false);
    NetProps.SetPropBool(MM_GetEntByName("minecart_blu_watcherA"), "m_bHandleTrainMovement", false);

    // Timer logic replacement
    EntityOutputs.RemoveOutput(PLR_TIMER, "OnSetupFinished", PLR_TIMER_NAME, "Disable", "");
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", PLR_TIMER_NAME, "SetTime", "600", 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "StartOvertime()", 0, -1);
}

__CollectGameEventCallbacks(this);