ClearGameEventCallbacks();
IncludeScript("mega_mod/common/plr_overtime.nut");

function OnGameEvent_teamplay_round_start(params) {

    InitGlobalVars();

    ::PLR_TIMER_NAME <- "ssplr_timer";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    ::RED_CARTSPARKS_ARRAY <- MM_GetEntArrayByName("ssplr_red_cartsparks");
    ::BLU_CARTSPARKS_ARRAY <- MM_GetEntArrayByName("ssplr_blu_cartsparks");

    ::RED_PUSHZONE <- MM_GetEntByName("plr_red_pushzone");
    ::BLU_PUSHZONE <- MM_GetEntByName("plr_blu_pushzone");

    ::RED_TRAIN <- MM_GetEntByName("plr_red_train");
    ::BLU_TRAIN <- MM_GetEntByName("plr_blu_train");

    ::RED_LOGICCASE <- CreateLogicCase("mm_plr_logiccase_red", "Red");
    ::BLU_LOGICCASE <- CreateLogicCase("mm_plr_logiccase_blu", "Blu");

    EntityOutputs.AddOutput(RED_PUSHZONE, "OnNumCappersChanged2", "mm_plr_logiccase_red", "InValue", "", 0, -1);
    EntityOutputs.AddOutput(BLU_PUSHZONE, "OnNumCappersChanged2", "mm_plr_logiccase_blu", "InValue", "", 0, -1);

    // Some rollback zones are improperly marked. This removes the uphill spawnflag from the offending path_track entities
    foreach(entName in [
        "ssplr_red_pathA_start83",
        "ssplr_red_pathA_start73",
        "ssplr_red_pathA_start79",
        "ssplr_blu_pathA_start87",
        "ssplr_blu_pathA_start77",
        "ssplr_blu_pathA_start89"
    ]) {
        EntFireByHandle(MM_GetEntByName(entName), "AddOutput", "spawnflags 0", 0, null, null);
    }

    // Prevent SetSpeedForwardModifier for final ramp from triggering more than once
    // This fixes a weird bug where the cart humps the second-to-last path_track during rollback.

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

    // Clean up unnecessary entities
    for (local ent = null; ent = Entities.FindByClassname(ent, "func_rotating");) {
        ent.Kill();
    }

    // Rollzones RED
    AddRollbackZone("ssplr_red_pathA_start64", "ssplr_red_pathA_start65", "ssplr_red_pathA_start83", "Red");
    AddRollbackZone("ssplr_red_pathA_start74", "ssplr_red_pathA_start75", "ssplr_red_pathA_start73", "Red");
    AddRollbackZone("ssplr_red_pathA_start82", "red_path_15", "ssplr_red_pathA_start81", "Red");

    // Rollzones BLU
    AddRollbackZone("ssplr_blu_pathA_start68", "ssplr_blu_pathA_start69", "ssplr_blu_pathA_start87", "Blu");
    AddRollbackZone("ssplr_blu_pathA_start78", "ssplr_blu_pathA_start79", "ssplr_blu_pathA_start77", "Blu");
    AddRollbackZone("ssplr_blu_pathA_start85", "blu_path_15", "ssplr_blu_pathA_start84", "Blu");

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

    AddCrossing("ssplr_red_crossover1_start", "ssplr_red_crossover1_end", "ssplr_blu_crossover1_start", "ssplr_blu_crossover1_end", 1);
    AddCrossing("ssplr_red_pathA_start55", "ssplr_red_pathA_start56", "ssplr_blu_pathA_start59", "ssplr_blu_pathA_start60", 2);
    AddCrossing("ssplr_red_pathA_start80", "ssplr_red_pathA_start81", "ssplr_blu_pathA_start83", "ssplr_blu_pathA_start84", 3);

    // team_train_watcher is no longer in charge.
    NetProps.SetPropBool(MM_GetEntByName("plr_red_watcher"), "m_bHandleTrainMovement", false);
    NetProps.SetPropBool(MM_GetEntByName("plr_blu_watcher"), "m_bHandleTrainMovement", false);

    EntityOutputs.AddOutput(RED_PUSHZONE, "OnNumCappersChanged2", "plr_red_watcher", "SetNumTrainCappers", "", 0, -1);
    EntityOutputs.AddOutput(BLU_PUSHZONE, "OnNumCappersChanged2", "plr_blu_watcher", "SetNumTrainCappers", "", 0, -1);

    // Timer logic replacement
    EntityOutputs.RemoveOutput(PLR_TIMER, "OnSetupFinished", PLR_TIMER_NAME, "Disable", "");
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", "600", 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "StartOvertime()", 0, -1);
}

__CollectGameEventCallbacks(this);