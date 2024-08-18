ClearGameEventCallbacks();
IncludeScript("mega_mod/common/plr_overtime.nut");

function OnGameEvent_teamplay_round_start(params) {

    if(params.full_reset != 1) return;

    InitGlobalVars();

    ::PLR_TIMER_NAME <- "setup_timer_a";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    ::RED_CARTSPARKS_ARRAY <- [MM_GetEntByName("red_cart_spark_left"), MM_GetEntByName("red_cart_spark_right")];
    ::BLU_CARTSPARKS_ARRAY <- [MM_GetEntByName("blue_cart_spark_left"), MM_GetEntByName("blue_cart_spark_right")];

    ::RED_FLASHINGLIGHT <- MM_GetEntByName("red_cart_particles");
    ::BLU_FLASHINGLIGHT <- MM_GetEntByName("blue_cart_particles");

    ::RED_PUSHZONE <- MM_GetEntByName("red_cap_area");
    ::BLU_PUSHZONE <- MM_GetEntByName("blue_cap_area");

    ::RED_TRAIN <- MM_GetEntByName("red_cart_tracktrain");
    ::BLU_TRAIN <- MM_GetEntByName("blue_cart_tracktrain");

    MM_GetEntByName("red_train_case").Kill();
    MM_GetEntByName("blue_train_case").Kill();
    MM_GetEntByName("red_train_remap").Kill();
    MM_GetEntByName("blue_train_remap").Kill();

    ::RED_LOGICCASE <- CreateLogicCase("red_train_case", "Red");
    ::BLU_LOGICCASE <- CreateLogicCase("blue_train_case", "Blu");

    EntityOutputs.AddOutput(RED_PUSHZONE, "OnNumCappersChanged2", "red_train_case", "InValue", "", 0, -1);
    EntityOutputs.AddOutput(BLU_PUSHZONE, "OnNumCappersChanged2", "blue_train_case", "InValue", "", 0, -1);

    // Rollback logic replacement
    MM_GetEntByName("red_train_hill_branch").Kill();
    MM_GetEntByName("red_train_hillclimb_backstop_relay").Kill();
    MM_GetEntByName("blue_train_hill_branch").Kill();
    MM_GetEntByName("blue_train_hillclimb_backstop_relay").Kill();

    AddRollbackZone("red_path_26", "red_path_27", "red_path_25", "Red");
    AddRollbackZone("blue_path_26", "blue_path_27", "blue_path_25", "Blu");

    AddRollbackZone("red_path_b_22", "red_path_b_23", "red_path_b_21", "Red");
    AddRollbackZone("blue_path_b_22", "blue_path_b_23", "blue_path_b_21", "Blu");

    AddRollbackZone("red_path_c_3", "red_path_c_6", "red_path_c_2", "Red");
    AddRollbackZone("red_path_c_8", "red_path_c_11", "red_path_c_7", "Red");
    AddRollbackZone("blue_path_c_3", "blue_path_c_6", "blue_path_c_2", "Blu");
    AddRollbackZone("blue_path_c_8", "blue_path_c_11", "blue_path_c_7", "Blu");

    // Crossing logic replacement
    foreach(entName in [
        "blue_crossover_b_relay",
        "blue_crossover_b_relay2",
        "blue_crossover_b_stop_relay",
        "blue_crossover_relay",
        "blue_crossover_relay2",
        "blue_crossover_stop_relay",
        "red_crossover_b_relay",
        "red_crossover_b_relay2",
        "red_crossover_b_stop_relay",
        "red_crossover_relay",
        "red_crossover_relay2",
        "red_crossover_stop_relay"
    ]) {
        MM_GetEntByName(entName).Kill();
    }

    AddCrossing("red_path_9", "red_path_12", "blue_path_9", "blue_path_12", 1);
    AddCrossing("red_path_b_8", "red_path_b_11", "blue_path_b_8", "blue_path_b_11", 2);

    // Timer logic replacement
    EntityOutputs.RemoveOutput(PLR_TIMER, "OnSetupFinished", "setup_timer_a", "Disable", "");
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", "600", 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "StartOvertime()", 0, -1);

    SpawnEntityFromTable("team_round_timer", {
        setup_length = 10,
        start_paused = 1,
        targetname = "setup_timer_c",
        timer_length = 600,
        StartDisabled = 1
        show_in_hud=  0
        "OnFinished#1" : "!self,RunScriptCode,StartOvertime(),0,1",
        "OnSetupFinished#1" : "redbase3_door,Unlock,,0,1",
        "OnSetupFinished#2" : "bluebase3_door,Unlock,,0,1",
        "OnSetupFinished#3" : "redbase3_door,Open,,0.1,1",
        "OnSetupFinished#4" : "bluebase3_door,Open,,0.1,1"
    });

    // Multi-stage logic
    EntityOutputs.AddOutput(MM_GetEntByName("round2"), "OnStart", "!self", "RunScriptCode", "OnRound2Start()", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("round3"), "OnStart", "!self", "RunScriptCode", "OnRound3Start()", 0, -1);
}

function OnRound2Start() {

    if(PLR_TIMER) PLR_TIMER.Kill();

    ::PLR_TIMER_NAME <- "setup_timer_b";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    EntityOutputs.RemoveOutput(PLR_TIMER, "OnSetupFinished", "setup_timer_b", "Disable", "");
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", "600", 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "StartOvertime()", 0, -1);

    ::OVERTIME_ACTIVE <- false;
    ::ROLLBACK_DISABLED <- false;
    ::RED_ROLLSTATE <- 0;
    ::BLU_ROLLSTATE <- 0;

    UpdateRedCart(0);
    UpdateBluCart(0);
}

function OnRound3Start() {

    // if(PLR_TIMER) PLR_TIMER.Kill();

    MM_GetEntByName("redbase3_door").AcceptInput("Lock", "", null, null);
    MM_GetEntByName("bluebase3_door").AcceptInput("Lock", "", null, null);

    ::PLR_TIMER_NAME <- "setup_timer_c";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    EntFireByHandle(PLR_TIMER, "ShowInHud", "1", 0, null, null);
    EntFireByHandle(PLR_TIMER, "Enable", "", 0.1, null, null);


    ::OVERTIME_ACTIVE <- false;
    ::ROLLBACK_DISABLED <- false;
    ::RED_ROLLSTATE <- 0;
    ::BLU_ROLLSTATE <- 0;

    UpdateRedCart(0);
    UpdateBluCart(0);
}

__CollectGameEventCallbacks(this);