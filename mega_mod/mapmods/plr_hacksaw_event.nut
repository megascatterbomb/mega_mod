ClearGameEventCallbacks();
IncludeScript("mega_mod/common/plr_overtime.nut");

function OnGameEvent_teamplay_round_start(params) {

    InitGlobalVars();

    ::PLR_TIMER_NAME <- "ssplr_timer";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    PLR_TEAMS[2].cartsparks = MM_GetEntArrayByName("ssplr_red_cartsparks");
    PLR_TEAMS[3].cartsparks = MM_GetEntArrayByName("ssplr_blu_cartsparks");

    PLR_TEAMS[2].pushzone = MM_GetEntByName("plr_red_pushzone");
    PLR_TEAMS[3].pushzone = MM_GetEntByName("plr_blu_pushzone");

    PLR_TEAMS[2].train = MM_GetEntByName("plr_red_train");
    PLR_TEAMS[3].train = MM_GetEntByName("plr_blu_train");

    PLR_TEAMS[2].logiccase = PLR_CreateLogicCase(2, "mm_plr_logiccase_red");
    PLR_TEAMS[3].logiccase = PLR_CreateLogicCase(3, "mm_plr_logiccase_blu");

    PLR_TEAMS[2].watcher = MM_GetEntByName("plr_red_watcher");
    PLR_TEAMS[3].watcher = MM_GetEntByName("plr_blu_watcher");

    EntityOutputs.AddOutput(PLR_TEAMS[2].pushzone, "OnNumCappersChanged2", "mm_plr_logiccase_red", "InValue", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[3].pushzone, "OnNumCappersChanged2", "mm_plr_logiccase_blu", "InValue", "", 0, -1);

    // Prevent SetSpeedForwardModifier for final ramp from triggering more than once
    EntityOutputs.RemoveOutput(MM_GetEntByName("ssplr_red_pathA_start84"), "OnPass", "plr_red_train", "SetSpeedForwardModifier", "0.04");
    EntityOutputs.RemoveOutput(MM_GetEntByName("ssplr_red_pathA_start82"), "OnPass", "plr_red_train", "SetSpeedForwardModifier", "0.04");
    EntityOutputs.RemoveOutput(MM_GetEntByName("ssplr_blu_pathA_start86"), "OnPass", "plr_blu_train", "SetSpeedForwardModifier", "0.04");
    EntityOutputs.RemoveOutput(MM_GetEntByName("ssplr_blu_pathA_start85"), "OnPass", "plr_blu_train", "SetSpeedForwardModifier", "0.04");

    EntityOutputs.AddOutput(MM_GetEntByName("ssplr_red_pathA_start84"), "OnPass", "plr_red_train", "SetSpeedForwardModifier", "0.04", 0, 1);
    EntityOutputs.AddOutput(MM_GetEntByName("ssplr_blu_pathA_start86"), "OnPass", "plr_blu_train", "SetSpeedForwardModifier", "0.04", 0, 1);

    // The game_text entities don't last long enough if the cart is moving at overtime speed.
    EntFire("game_text*", "AddOutput", "holdtime 4", 0, null);

    // Move the BLU team game_texts to different channel so RED and BLU can both be on screen
    EntFire("text_hack_blu*", "AddOutput", "channel 4", 0, null);

    // Rollzones
    PLR_AddRollbackZone(2, "ssplr_red_pathA_start64", "ssplr_red_pathA_start65", "ssplr_red_pathA_start83");
    PLR_AddRollbackZone(2, "ssplr_red_pathA_start74", "ssplr_red_pathA_start75", "ssplr_red_pathA_start73");
    PLR_AddRollbackZone(2, "ssplr_red_pathA_start82", "red_path_15", "ssplr_red_pathA_start81");
    PLR_AddRollbackZone(3, "ssplr_blu_pathA_start68", "ssplr_blu_pathA_start69", "ssplr_blu_pathA_start87");
    PLR_AddRollbackZone(3, "ssplr_blu_pathA_start78", "ssplr_blu_pathA_start79", "ssplr_blu_pathA_start77");
    PLR_AddRollbackZone(3, "ssplr_blu_pathA_start85", "blu_path_15", "ssplr_blu_pathA_start84");

    // Crossing logic replacement
    foreach(entName in [
        "ssplr_red_crossover1_branch"
        "ssplr_red_crossover1_relay"
        "ssplr_blu_crossover1_branch"
        "ssplr_blu_crossover1_relay"
        "ssplr_red_crossover2_branch"
        "ssplr_red_crossover2_relay"
        "ssplr_blu_crossover2_branch"
        "ssplr_blu_crossover2_relay"
        "ssplr_red_crossover3_branch"
        "ssplr_red_crossover3_relay"
        "ssplr_blu_crossover3_branch"
        "ssplr_blu_crossover3_relay"
    ]) {
        MM_GetEntByName(entName).Kill();
    }

    PLR_AddCrossing([
        ["ssplr_red_crossover1_start", "ssplr_red_crossover1_end", 2],
        ["ssplr_blu_crossover1_start", "ssplr_blu_crossover1_end", 3]
    ]);
    PLR_AddCrossing([
        ["ssplr_red_pathA_start55", "ssplr_red_pathA_start56", 2],
        ["ssplr_blu_pathA_start59", "ssplr_blu_pathA_start60", 3]
    ]);
    PLR_AddCrossing([
        ["ssplr_red_pathA_start80", "ssplr_red_pathA_start81", 2],
        ["ssplr_blu_pathA_start83", "ssplr_blu_pathA_start84", 3]
    ]);

    // team_train_watcher is no longer in charge.
    NetProps.SetPropBool(PLR_TEAMS[2].watcher, "m_bHandleTrainMovement", false);
    NetProps.SetPropBool(PLR_TEAMS[3].watcher, "m_bHandleTrainMovement", false);

    EntityOutputs.AddOutput(PLR_TEAMS[2].pushzone, "OnNumCappersChanged2", "plr_red_watcher", "SetNumTrainCappers", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[3].pushzone, "OnNumCappersChanged2", "plr_blu_watcher", "SetNumTrainCappers", "", 0, -1);

    // Timer logic replacement
    EntityOutputs.RemoveOutput(PLR_TIMER, "OnSetupFinished", PLR_TIMER_NAME, "Disable", "");
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", PLR_GetRoundTimeString(), 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "PLR_StartOvertime()", 0, -1);

    EntityOutputs.AddOutput(MM_GetEntByName("relay_red_capture_cart"), "OnTrigger", "!self", "RunScriptCode", "PLR_ForceStopCarts()", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("relay_blu_capture_cart"), "OnTrigger", "!self", "RunScriptCode", "PLR_ForceStopCarts()", 0, -1);

    // Add thinks to carts
    PLR_CreateCartAutoUpdater(2, PLR_TEAMS[2].train);
    PLR_CreateCartAutoUpdater(3, PLR_TEAMS[3].train);
}

__CollectGameEventCallbacks(this);
