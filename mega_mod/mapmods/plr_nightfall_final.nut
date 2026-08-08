ClearGameEventCallbacks();
IncludeScript("mega_mod/common/plr_overtime.nut");

function OnGameEvent_teamplay_round_start(params) {

    if(params.full_reset != 1) return;

    InitGlobalVars();

    ::ROUND_WIN_COUNTER <- 0;

    ::PLR_TIMER_NAME <- "plr_timer";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    PLR_TEAMS[2].cartsparks = MM_GetEntArrayByName("plr_red_cartsparks");
    PLR_TEAMS[3].cartsparks = MM_GetEntArrayByName("plr_blu_cartsparks");

    PLR_TEAMS[2].flashinglight = MM_GetEntByName("plr_red_flashinglight");
    PLR_TEAMS[3].flashinglight = MM_GetEntByName("plr_blu_flashinglight");

    PLR_TEAMS[2].pushzone = MM_GetEntByName("plr_red_pushzone");
    PLR_TEAMS[3].pushzone = MM_GetEntByName("plr_blu_pushzone");

    PLR_TEAMS[2].train = MM_GetEntByName("plr_red_train");
    PLR_TEAMS[3].train = MM_GetEntByName("plr_blu_train");

    PLR_TEAMS[2].watcher = MM_GetEntByName("plr_red_watcherA");
    PLR_TEAMS[3].watcher = MM_GetEntByName("plr_blu_watcherA");

    MM_GetEntByName("plr_red_overtime").Kill();
    MM_GetEntByName("plr_blu_overtime").Kill();
    MM_GetEntByName("plr_overtime_template").Kill();

    PLR_TEAMS[2].logiccase = PLR_CreateLogicCase(2, "red_train_case");
    PLR_TEAMS[3].logiccase = PLR_CreateLogicCase(3, "blue_train_case");

    EntityOutputs.AddOutput(PLR_TEAMS[2].pushzone, "OnNumCappersChanged2", "red_train_case", "InValue", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[3].pushzone, "OnNumCappersChanged2", "blue_train_case", "InValue", "", 0, -1);

    // Rollback logic replacement

    PLR_AddRollbackZone(2, "plr_red_pathA_hillA2", "plr_red_pathA_hillA4", "plr_red_pathA_hillA1");
    PLR_AddRollbackZone(3, "plr_blu_pathA_hillA2", "plr_blu_pathA_hillA4", "plr_blu_pathA_hillA1");

    PLR_AddRollbackZone(2, "plr_red_pathB_hillA2", "plr_red_pathB_hillA5", "plr_red_pathB_hillA1");
    PLR_AddRollbackZone(2, "plr_red_pathB_hillB2", "plr_red_pathB_hillB4", "plr_red_pathB_hillB1");
    PLR_AddRollbackZone(3, "plr_blu_pathB_hillA2", "plr_blu_pathB_hillA5", "plr_blu_pathB_hillA1");
    PLR_AddRollbackZone(3, "plr_blu_pathB_hillB2", "plr_blu_pathB_hillB4", "plr_blu_pathB_hillB1");

    PLR_AddRollbackZone(2, "plr_red_pathC_hillA2", "plr_red_pathC_hillA6", "plr_red_pathC_hillA1");
    PLR_AddRollbackZone(2, "plr_red_pathC_hillB2", "plr_red_pathC_hillB6", "plr_red_pathC_hillB1");
    PLR_AddRollbackZone(3, "plr_blu_pathC_hillA2", "plr_blu_pathC_hillA6", "plr_blu_pathC_hillA1");
    PLR_AddRollbackZone(3, "plr_blu_pathC_hillB2", "plr_blu_pathC_hillB6", "plr_blu_pathC_hillB1");

    // Crossing logic replacement (yes they used "crossover2" twice)
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

    AddCrossing([
        ["plr_red_pathA15", "plr_red_pathA16", 2],
        ["plr_blu_pathA15", "plr_blu_pathA16", 3]
    ]);
    AddCrossing([
        ["plr_red_pathB_crossover2_start", "plr_red_pathB_crossover2_end", 2],
        ["plr_blu_pathB_crossover2_start", "plr_blu_pathB_crossover2_end", 3]
    ]);
    AddCrossing([
        ["plr_red_crossover3_start", "plr_red_pathC_29", 2],
        ["plr_blu_crossover3_start", "plr_blu_pathC_29", 3]
    ]);

    // Fix invisible walls on stage 3 by putting a prop there
    // Flag removal needed to stop sentries trying to shoot through the thin prop (thanks ficool2!)

    SpawnEntityFromTable("prop_dynamic",
    {
        targetname = "mm_fixprop_1",
        solid = "6",
        disableshadows = "1",
        origin = "-254 11517 272",
        angles= "0 180 0",
        model = "models/props_trainyard/train_billboard001.mdl"
    }).RemoveEFlags(Constants.FEntityEFlags.EFL_DONTBLOCKLOS);

    SpawnEntityFromTable("prop_dynamic",
    {
        targetname = "mm_fixprop_2",
        solid = "6",
        disableshadows = "1",
        origin = "254 11516 272",
        angles = "0 180 -180",
        model = "models/props_trainyard/train_billboard001.mdl"
    }).RemoveEFlags(Constants.FEntityEFlags.EFL_DONTBLOCKLOS);

    // Fix path_tracks using SetSpeedDirAccel instead of SetSpeedForwardModifier

    EntityOutputs.RemoveOutput(MM_GetEntByName("plr_red_pathC_slopeA2"), "OnPass", "plr_red_train", "SetSpeedDirAccel", "0.5");
    EntityOutputs.RemoveOutput(MM_GetEntByName("plr_blu_pathC_slopeA2"), "OnPass", "plr_blu_train", "SetSpeedDirAccel", "0.5");

    EntityOutputs.AddOutput(MM_GetEntByName("plr_red_pathC_slopeA2"), "OnPass", "plr_red_train", "SetSpeedForwardModifier", "0.5", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("plr_blu_pathC_slopeA2"), "OnPass", "plr_blu_train", "SetSpeedForwardModifier", "0.5", 0, -1);

    // Timer logic
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "StartOvertime()", 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", GetRoundTimeString(45), 0, -1);

    SpawnEntityFromTable("team_round_timer", {
        setup_length = 45,
        start_paused = 1,
        targetname = "plr_timer_b",
        timer_length = 600,
        StartDisabled = 1,
        show_in_hud = 0,
        "OnFinished#1" : "!self,RunScriptCode,StartOvertime(),0,1",
        "OnSetupFinished#1" : "plr_red_pushzone,Enable,,0,1",
        "OnSetupFinished#2" : "plr_blu_pushzone,Enable,,0,1",
        "OnSetupFinished#3" : "plr_siren,PlaySound,,0,1",
        "OnSetupFinished#4" : "plr_setupgate_relay*,Trigger,,0,1",
    });

    SpawnEntityFromTable("team_round_timer", {
        setup_length = 6,
        start_paused = 1,
        targetname = "plr_timer_c",
        timer_length = 600,
        StartDisabled = 1,
        show_in_hud = 0,
        "OnFinished#1" : "!self,RunScriptCode,StartOvertime(),0,1"
    });

    // team_train_watcher is no longer in charge.
    NetProps.SetPropBool(MM_GetEntByName("plr_red_watcherA"), "m_bHandleTrainMovement", false);
    NetProps.SetPropBool(MM_GetEntByName("plr_blu_watcherA"), "m_bHandleTrainMovement", false);
    NetProps.SetPropBool(MM_GetEntByName("plr_red_watcherB"), "m_bHandleTrainMovement", false);
    NetProps.SetPropBool(MM_GetEntByName("plr_blu_watcherB"), "m_bHandleTrainMovement", false);
    NetProps.SetPropBool(MM_GetEntByName("plr_red_watcherC"), "m_bHandleTrainMovement", false);
    NetProps.SetPropBool(MM_GetEntByName("plr_blu_watcherC"), "m_bHandleTrainMovement", false);

    EntityOutputs.AddOutput(PLR_TEAMS[2].pushzone, "OnNumCappersChanged2", "plr_red_watcherA", "SetNumTrainCappers", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[3].pushzone, "OnNumCappersChanged2", "plr_blu_watcherA", "SetNumTrainCappers", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[2].pushzone, "OnNumCappersChanged2", "plr_red_watcherB", "SetNumTrainCappers", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[3].pushzone, "OnNumCappersChanged2", "plr_blu_watcherB", "SetNumTrainCappers", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[2].pushzone, "OnNumCappersChanged2", "plr_red_watcherC", "SetNumTrainCappers", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[3].pushzone, "OnNumCappersChanged2", "plr_blu_watcherC", "SetNumTrainCappers", "", 0, -1);

    // Prevent both win outputs being fired for cart warps.

    EntityOutputs.RemoveOutput(MM_GetEntByName("plr_red_pathA_end"), "OnPass", "plr_round_B", "AddOutput", "OnStart plr_red_train:TeleportToPathTrack:plr_red_pathB_start1:0:1");
    EntityOutputs.RemoveOutput(MM_GetEntByName("plr_red_pathA_end"), "OnPass", "plr_round_B", "AddOutput", "OnStart plr_blu_train:TeleportToPathTrack:plr_blu_pathB_start0:0:1");
    EntityOutputs.RemoveOutput(MM_GetEntByName("plr_blu_pathA_end"), "OnPass", "plr_round_B", "AddOutput", "OnStart plr_red_train:TeleportToPathTrack:plr_red_pathB_start0:0:1");
    EntityOutputs.RemoveOutput(MM_GetEntByName("plr_blu_pathA_end"), "OnPass", "plr_round_B", "AddOutput", "OnStart plr_blu_train:TeleportToPathTrack:plr_blu_pathB_start1:0:1");

    EntityOutputs.RemoveOutput(MM_GetEntByName("plr_red_pathA_end"), "OnPass", "plr_stageC_start_counter", "Add", "2");
    EntityOutputs.RemoveOutput(MM_GetEntByName("plr_red_pathB_end"), "OnPass", "plr_stageC_start_counter", "Add", "2");
    EntityOutputs.RemoveOutput(MM_GetEntByName("plr_blu_pathA_end"), "OnPass", "plr_stageC_start_counter", "Add", "3");
    EntityOutputs.RemoveOutput(MM_GetEntByName("plr_blu_pathB_end"), "OnPass", "plr_stageC_start_counter", "Add", "3");

    // Multi-stage logic
    EntityOutputs.AddOutput(MM_GetEntByName("plr_round_B"), "OnStart", "!self", "RunScriptCode", "OnRound2Start()", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("plr_round_C"), "OnStart", "!self", "RunScriptCode", "OnRound3Start()", 0, -1);

    // Add thinks to carts
    PLR_CreateCartAutoUpdater(2, PLR_TEAMS[2].train);
    PLR_CreateCartAutoUpdater(3, PLR_TEAMS[3].train);
}

function OnRound2Start() {

    if(PLR_TIMER && PLR_TIMER.IsValid()) PLR_TIMER.Kill();

    ::PLR_TIMER_NAME <- "plr_timer_b";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    PLR_TEAMS[2].watcher = MM_GetEntByName("plr_red_watcherB");
    PLR_TEAMS[3].watcher = MM_GetEntByName("plr_blu_watcherB");

    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", GetRoundTimeString(45), 0, -1);
    EntFireByHandle(PLR_TIMER, "ShowInHud", "1", 0, null, null);
    EntFireByHandle(PLR_TIMER, "Enable", "", 0.1, null, null);

    // Handle cart warp
    if(ROUND_WIN_COUNTER == 2) {
        PLR_TEAMS[2].train.AcceptInput("TeleportToPathTrack", "plr_red_pathB_start1", null, null);
        PLR_TEAMS[3].train.AcceptInput("TeleportToPathTrack", "plr_blu_pathB_start0", null, null);
    } else if (ROUND_WIN_COUNTER == 3) {
        PLR_TEAMS[2].train.AcceptInput("TeleportToPathTrack", "plr_red_pathB_start0", null, null);
        PLR_TEAMS[3].train.AcceptInput("TeleportToPathTrack", "plr_blu_pathB_start1", null, null);
    }

    ResetCartStates();
}

function OnRound3Start() {

    if(PLR_TIMER && PLR_TIMER.IsValid()) PLR_TIMER.Kill();

    ::PLR_TIMER_NAME <- "plr_timer_c";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    PLR_TEAMS[2].watcher = MM_GetEntByName("plr_red_watcherC");
    PLR_TEAMS[3].watcher = MM_GetEntByName("plr_blu_watcherC");

    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", GetRoundTimeString(), 0, -1);
    EntFireByHandle(PLR_TIMER, "ShowInHud", "1", 0, null, null);
    EntFireByHandle(PLR_TIMER, "Enable", "", 0.1, null, null);

    // Handle cart warp
    MM_GetEntByName("plr_stageC_start_case").AcceptInput("InValue", "" + ROUND_WIN_COUNTER, null, null);

    ResetCartStates();
}

::WinRed_Base <- WinRed;
::WinBlu_Base <- WinBlu;

function WinRed() {
    WinRed_Base();
    ::ROUND_WIN_COUNTER <- ROUND_WIN_COUNTER + 2;
}

function WinBlu() {
    WinBlu_Base();
    ::ROUND_WIN_COUNTER <- ROUND_WIN_COUNTER + 3;
}

__CollectGameEventCallbacks(this);
