ClearGameEventCallbacks();
IncludeScript("mega_mod/common/plr_overtime.nut");

function OnGameEvent_teamplay_round_start(params) {

    if(params.full_reset != 1) return;

    InitGlobalVars();

    ::PLR_TIMER_NAME <- "plr_timer";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    ::RED_CARTSPARKS_ARRAY <- MM_GetEntArrayByName("plr_red_cartsparks");
    ::BLU_CARTSPARKS_ARRAY <- MM_GetEntArrayByName("plr_blu_cartsparks");

    ::RED_FLASHINGLIGHT <- MM_GetEntByName("plr_red_flashinglight");
    ::BLU_FLASHINGLIGHT <- MM_GetEntByName("plr_blu_flashinglight");

    ::RED_PUSHZONE <- MM_GetEntByName("plr_red_pushzone");
    ::BLU_PUSHZONE <- MM_GetEntByName("plr_blu_pushzonez");

    ::RED_TRAIN <- MM_GetEntByName("plr_red_train");
    ::BLU_TRAIN <- MM_GetEntByName("plr_blu_train");

    MM_GetEntByName("plr_red_overtime").Kill();
    MM_GetEntByName("plr_blu_overtime").Kill();
    MM_GetEntByName("plr_overtime_template").Kill();

    ::RED_LOGICCASE <- CreateLogicCase("red_train_case", "Red");
    ::BLU_LOGICCASE <- CreateLogicCase("blue_train_case", "Blu");

    EntityOutputs.AddOutput(RED_PUSHZONE, "OnNumCappersChanged2", "red_train_case", "InValue", "", 0, -1);
    EntityOutputs.AddOutput(BLU_PUSHZONE, "OnNumCappersChanged2", "blue_train_case", "InValue", "", 0, -1);

    // Rollback logic replacement

    // MM_GetEntByName("plr_red_rollback").Kill();
    // MM_GetEntByName("plr_blu_rollback").Kill();

    AddRollbackZone("plr_red_pathA_hillA2", "plr_red_pathA_hillA4", "plr_red_pathA_hillA1", "Red");
    AddRollbackZone("plr_blu_pathA_hillA2", "plr_blu_pathA_hillA4", "plr_blu_pathA_hillA1", "Blu");

    AddRollbackZone("plr_red_pathB_hillA2", "plr_red_pathB_hillA5", "plr_red_pathB_hillA1", "Red");
    AddRollbackZone("plr_red_pathB_hillB2", "plr_red_pathB_hillB4", "plr_red_pathB_hillB1", "Red");
    AddRollbackZone("plr_blu_pathB_hillA2", "plr_blu_pathB_hillA5", "plr_blu_pathB_hillA1", "Blu");
    AddRollbackZone("plr_blu_pathB_hillB2", "plr_blu_pathB_hillB4", "plr_blu_pathB_hillB1", "Blu");

    AddRollbackZone("plr_red_pathC_hillA2", "plr_red_pathC_hillA6", "plr_red_pathC_hillA1", "Red");
    AddRollbackZone("plr_red_pathC_hillB2", "plr_red_pathC_hillB6", "plr_red_pathC_hillB1", "Red");
    AddRollbackZone("plr_blu_pathC_hillA2", "plr_blu_pathC_hillA6", "plr_blu_pathC_hillA1", "Blu");
    AddRollbackZone("plr_blu_pathC_hillB2", "plr_blu_pathC_hillB6", "plr_blu_pathC_hillB1", "Blu")

    // Crossing logic replacement (yes they used "crossing2" twice)
    foreach(entName in [
        "plr_red_pathA_crossover1_branch",
        "plr_red_pathA_crossover1_relay",
        "plr_blu_pathA_crossover1_branch",
        "plr_blu_pathA_crossover1_relay",
        "plr_red_pathB_crossover2_branch",
        "plr_red_pathB_crossover2_relay",
        "plr_blu_pathB_crossover2_branch",
        "plr_blu_pathB_crossover2_relay",
        "plr_red_pathC_crossover2_branch",
        "plr_red_pathC_crossover2_relay",
        "plr_blu_pathC_crossover2_branch",
        "plr_blu_pathC_crossover2_relay"
    ]) {
        MM_GetEntByName(entName).Kill();
    }

    AddCrossing("plr_red_pathA15", "plr_red_pathA16", "plr_blu_pathA15", "plr_blu_pathA16", 1);
    AddCrossing("plr_red_pathB_crossover2_start", "plr_red_pathB_crossover2_end", "plr_blu_pathB_crossover2_start", "plr_blu_pathB_crossover2_end", 2);
    AddCrossing("plr_red_crossover3_start", "plr_red_pathC_29", "plr_blu_crossover3_start", "plr_blu_pathC_29", 3);

    // Fix invisible walls on stage 3 by putting a prop there

    SpawnEntityFromTable("prop_dynamic",
    {
        origin = "-254 11518 272",
        angles= "0 180 0",
        model = "models/props_trainyard/train_billboard001.mdl"
    });

    SpawnEntityFromTable("prop_dynamic",
    {
        origin = "254 11518 272",
        angles = "0 180 -180",
        model = "models/props_trainyard/train_billboard001.mdl"
    });

    // Fix path_tracks using SetSpeedDirAccel instead of SetSpeedForwardModifier

    EntityOutputs.RemoveOutput(MM_GetEntByName("plr_red_pathC_slopeA2"), "OnPass", "plr_red_train", "SetSpeedDirAccel", "0.5");
    EntityOutputs.RemoveOutput(MM_GetEntByName("plr_blu_pathC_slopeA2"), "OnPass", "plr_blu_train", "SetSpeedDirAccel", "0.5");

    EntityOutputs.AddOutput(MM_GetEntByName("plr_red_pathC_slopeA2"), "OnPass", "plr_red_train", "SetSpeedForwardModifier", "0.5", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("plr_blu_pathC_slopeA2"), "OnPass", "plr_blu_train", "SetSpeedForwardModifier", "0.5", 0, -1);

    // Timer logic
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "StartOvertime()", 0, -1);

    SpawnEntityFromTable("team_round_timer", {
        setup_length = 6,
        start_paused = 1,
        targetname = "plr_timer_c",
        timer_length = 600,
        StartDisabled = 1,
        show_in_hud=  0,
        "OnFinished#1" : "!self,RunScriptCode,StartOvertime(),0,1"
    });

    // Multi-stage logic
    EntityOutputs.AddOutput(MM_GetEntByName("plr_round_B"), "OnStart", "!self", "RunScriptCode", "OnRound2Start()", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("plr_round_C"), "OnStart", "!self", "RunScriptCode", "OnRound3Start()", 0, -1);
}

function OnRound2Start() {
    ::OVERTIME_ACTIVE <- false;
    ::ROLLBACK_DISABLED <- false;
    ::RED_ROLLSTATE <- 0;
    ::BLU_ROLLSTATE <- 0;

    UpdateRedCart(0);
    UpdateBluCart(0);
}

function OnRound3Start() {

    ::PLR_TIMER_NAME <- "plr_timer_c";
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