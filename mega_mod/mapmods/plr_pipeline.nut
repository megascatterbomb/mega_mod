ClearGameEventCallbacks();
IncludeScript("mega_mod/common/plr_overtime.nut");

function OnGameEvent_teamplay_round_start(params) {

    if (params.full_reset != 1) return;

    InitGlobalVars();

    ::PLR_TIMER_NAME <- "setup_timer_a";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    PLR_TEAMS[2].cartsparks = [MM_GetEntByName("red_cart_spark_left"), MM_GetEntByName("red_cart_spark_right")];
    PLR_TEAMS[3].cartsparks = [MM_GetEntByName("blue_cart_spark_left"), MM_GetEntByName("blue_cart_spark_right")];

    PLR_TEAMS[2].flashinglight = MM_GetEntByName("red_cart_particles");
    PLR_TEAMS[3].flashinglight = MM_GetEntByName("blue_cart_particles");

    PLR_TEAMS[2].pushzone = MM_GetEntByName("red_cap_area");
    PLR_TEAMS[3].pushzone = MM_GetEntByName("blue_cap_area");

    PLR_TEAMS[2].train = MM_GetEntByName("red_cart_tracktrain");
    PLR_TEAMS[3].train = MM_GetEntByName("blue_cart_tracktrain");

    PLR_TEAMS[2].watcher = MM_GetEntByName("red_watcher_1");
    PLR_TEAMS[3].watcher = MM_GetEntByName("blue_watcher_1");

    MM_GetEntByName("red_train_case").Kill();
    MM_GetEntByName("blue_train_case").Kill();
    MM_GetEntByName("red_train_remap").Kill();
    MM_GetEntByName("blue_train_remap").Kill();

    PLR_TEAMS[2].logiccase = PLR_CreateLogicCase(2, "red_train_case");
    PLR_TEAMS[3].logiccase = PLR_CreateLogicCase(3, "blue_train_case");

    EntityOutputs.AddOutput(PLR_TEAMS[2].pushzone, "OnNumCappersChanged2", "red_train_case", "InValue", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[3].pushzone, "OnNumCappersChanged2", "blue_train_case", "InValue", "", 0, -1);

    // Rollback logic replacement
    MM_GetEntByName("red_train_hill_branch").Kill();
    MM_GetEntByName("red_train_hillclimb_backstop_relay").Kill();
    MM_GetEntByName("blue_train_hill_branch").Kill();
    MM_GetEntByName("blue_train_hillclimb_backstop_relay").Kill();

    PLR_AddRollbackZone(2, "red_path_26", "red_path_27", "red_path_25");
    PLR_AddRollbackZone(3, "blue_path_26", "blue_path_27", "blue_path_25");

    PLR_AddRollbackZone(2, "red_path_b_22", "red_path_b_23", "red_path_b_21");
    PLR_AddRollbackZone(3, "blue_path_b_22", "blue_path_b_23", "blue_path_b_21");

    PLR_AddRollbackZone(2, "red_path_c_3", "red_path_c_6", "red_path_c_2");
    PLR_AddRollbackZone(2, "red_path_c_8", "red_path_c_11", "red_path_c_7");
    PLR_AddRollbackZone(3, "blue_path_c_3", "blue_path_c_6", "blue_path_c_2");
    PLR_AddRollbackZone(3, "blue_path_c_8", "blue_path_c_11", "blue_path_c_7");

    // Crossing logic replacement
    foreach (entName in [
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

    PLR_AddCrossing([
        ["red_path_9", "red_path_12", 2],
        ["blue_path_9", "blue_path_12", 3]
    ]);
    PLR_AddCrossing([
        ["red_path_b_8", "red_path_b_11", 2],
        ["blue_path_b_8", "blue_path_b_11", 3]
    ]);

    // Timer logic replacement
    EntityOutputs.RemoveOutput(PLR_TIMER, "OnSetupFinished", "setup_timer_a", "Disable", "");
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", PLR_GetRoundTimeString(65), 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "PLR_StartOvertime()", 0, -1);

    SpawnEntityFromTable("team_round_timer", {
        setup_length = 6,
        start_paused = 1,
        targetname = "setup_timer_c",
        timer_length = 600,
        StartDisabled = 1,
        show_in_hud = 0,
        "OnFinished#1": "!self,RunScriptCode,PLR_StartOvertime(),0,1",
    });

    // Multi-stage logic
    EntityOutputs.AddOutput(MM_GetEntByName("round2"), "OnStart", "!self", "RunScriptCode", "OnRound2Start()", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("round3"), "OnStart", "!self", "RunScriptCode", "OnRound3Start()", 0, -1);

    // Add thinks to carts
    PLR_CreateCartAutoUpdater(2, PLR_TEAMS[2].train);
    PLR_CreateCartAutoUpdater(3, PLR_TEAMS[3].train);
}

::WinBase <- OnGameEvent_teamplay_round_win;

// Pipeline has an end-of-round win sequence that requires the winning cart to keep moving forward.
function OnGameEvent_teamplay_round_win(params) {
    if (params.full_round == 1 && params.team != 0) {
        PLR_ForEachTeam(function(team, state) { state.blocked = true; });
        if (params.team == 2) {
            PLR_Stop(3);
            PLR_Advance(2, 3, false);
        } else if (params.team == 3) {
            PLR_Stop(2);
            PLR_Advance(3, 3, false);
        }
        return;
    }
    WinBase(params);
}

function OnRound2Start() {
    if (PLR_TIMER && PLR_TIMER.IsValid()) PLR_TIMER.Kill();

    ::PLR_TIMER_NAME <- "setup_timer_b";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    PLR_TEAMS[2].watcher = MM_GetEntByName("red_watcher_2");
    PLR_TEAMS[3].watcher = MM_GetEntByName("blue_watcher_2");

    EntityOutputs.RemoveOutput(PLR_TIMER, "OnSetupFinished", "setup_timer_b", "Disable", "");
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", PLR_GetRoundTimeString(65), 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "PLR_StartOvertime()", 0, -1);

    PLR_ResetCartStates();
}

function OnRound3Start() {
    if (PLR_TIMER && PLR_TIMER.IsValid()) PLR_TIMER.Kill();

    ::PLR_TIMER_NAME <- "setup_timer_c";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", PLR_GetRoundTimeString(), 0, -1);

    PLR_TEAMS[2].watcher = MM_GetEntByName("red_watcher_3");
    PLR_TEAMS[3].watcher = MM_GetEntByName("blue_watcher_3");

    EntFireByHandle(PLR_TIMER, "ShowInHud", "1", 0, null, null);
    EntFireByHandle(PLR_TIMER, "Enable", "", 0.1, null, null);

    PLR_ResetCartStates();
}

__CollectGameEventCallbacks(this);
