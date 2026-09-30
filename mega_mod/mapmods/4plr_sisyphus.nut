ClearGameEventCallbacks();
IncludeScript("mega_mod/common/plr_overtime.nut");

function OnGameEvent_teamplay_round_start(params) {

    InitGlobalVars();

    // 4-team map: register GREEN and YELLOW in addition to RED/BLU.
    PLR_RegisterTeam(4, {});
    PLR_RegisterTeam(5, {});

    ::PLR_TIMER_NAME <- "ssplr_timer";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    // Cart sparks (used for the pusher count display).
    PLR_TEAMS[2].cartsparks = MM_GetEntArrayByName("ssplr_red_cartsparks");
    PLR_TEAMS[3].cartsparks = MM_GetEntArrayByName("ssplr_blu_cartsparks");
    PLR_TEAMS[4].cartsparks = MM_GetEntArrayByName("ssplr_grn_cartsparks");
    PLR_TEAMS[5].cartsparks = MM_GetEntArrayByName("ssplr_ylw_cartsparks");

    PLR_TEAMS[2].pushzone = MM_GetEntByName("ssplr_red_pushzone");
    PLR_TEAMS[3].pushzone = MM_GetEntByName("ssplr_blu_pushzone");
    PLR_TEAMS[4].pushzone = MM_GetEntByName("ssplr_grn_pushzone");
    PLR_TEAMS[5].pushzone = MM_GetEntByName("ssplr_ylw_pushzone");

    PLR_TEAMS[2].train = MM_GetEntByName("ssplr_red_train");
    PLR_TEAMS[3].train = MM_GetEntByName("ssplr_blu_train");
    PLR_TEAMS[4].train = MM_GetEntByName("ssplr_grn_train");
    PLR_TEAMS[5].train = MM_GetEntByName("ssplr_ylw_train");

    PLR_TEAMS[2].flashinglight = MM_GetEntByName("ssplr_red_flashinglight");
    PLR_TEAMS[3].flashinglight = MM_GetEntByName("ssplr_blu_flashinglight");
    PLR_TEAMS[4].flashinglight = MM_GetEntByName("ssplr_grn_flashinglight");
    PLR_TEAMS[5].flashinglight = MM_GetEntByName("ssplr_ylw_flashinglight");

    PLR_TEAMS[2].watcher = MM_GetEntByName("ssplr_red_watcherA");
    PLR_TEAMS[3].watcher = MM_GetEntByName("ssplr_blu_watcherA");
    PLR_TEAMS[4].watcher = MM_GetEntByName("ssplr_grn_watcherA");
    PLR_TEAMS[5].watcher = MM_GetEntByName("ssplr_ylw_watcherA");

    // Cart control logic replacement.
    foreach (entName in [
        "plr_red_pushingcase"
        "plr_blu_pushingcase"
        "plr_grn_pushingcase"
        "plr_ylw_pushingcase"
        "red_overtimepush"
        "blu_overtimepush"
        "grn_overtimepush"
        "ylw_overtimepush"
        "overtime_timer"
    ]) {
        MM_GetEntByName(entName).Kill();
    }

    PLR_TEAMS[2].logiccase = PLR_CreateLogicCase(2, "mm_plr_logiccase_red");
    PLR_TEAMS[3].logiccase = PLR_CreateLogicCase(3, "mm_plr_logiccase_blu");
    PLR_TEAMS[4].logiccase = PLR_CreateLogicCase(4, "mm_plr_logiccase_grn");
    PLR_TEAMS[5].logiccase = PLR_CreateLogicCase(5, "mm_plr_logiccase_ylw");

    // Hook pushzones into the new logic cases.
    EntityOutputs.AddOutput(PLR_TEAMS[2].pushzone, "OnNumCappersChanged2", "mm_plr_logiccase_red", "InValue", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[3].pushzone, "OnNumCappersChanged2", "mm_plr_logiccase_blu", "InValue", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[4].pushzone, "OnNumCappersChanged2", "mm_plr_logiccase_grn", "InValue", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[5].pushzone, "OnNumCappersChanged2", "mm_plr_logiccase_ylw", "InValue", "", 0, -1);

    // Rollback zones - first hill (track_2 to track_3)
    PLR_AddRollbackZone(2, "path_red_2", "path_red_3", "path_red_28");
    PLR_AddRollbackZone(3, "path_blu_2", "path_blu_3", "path_blu_29");
    PLR_AddRollbackZone(4, "path_grn_2", "path_grn_3", "path_grn_28");
    PLR_AddRollbackZone(5, "path_ylw_2", "path_ylw_3", "path_ylw_28");

    // Rollback zones - final hill (track_6 to end of track; blu starts at track_7)
    PLR_AddRollbackZone(2, "path_red_6", null, "path_red_24");
    PLR_AddRollbackZone(3, "path_blu_7", null, "path_blu_25");
    PLR_AddRollbackZone(4, "path_grn_6", null, "path_grn_24");
    PLR_AddRollbackZone(5, "path_ylw_6", null, "path_ylw_24");

    // Timer logic replacement - kill and recreate.
    local oldTimer = MM_GetEntByName("ssplr_timer");
    if (oldTimer) oldTimer.Kill();

    ::PLR_TIMER_NAME <- "ssplr_timer";
    ::PLR_TIMER = SpawnEntityFromTable("team_round_timer", {
        targetname = "ssplr_timer"
        setup_length = 10
        timer_length = 600
        show_in_hud = 1
        start_paused = 1
        StartDisabled = 0
    });
    EntFireByHandle(PLR_TIMER, "Resume", "", 0, null, null);

    // Enable pushzones when setup ends.
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "ssplr_red_pushzone", "Enable", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "ssplr_blu_pushzone", "Enable", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "ssplr_grn_pushzone", "Enable", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "ssplr_ylw_pushzone", "Enable", "", 0, -1);

    // Set round time when setup ends.
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", PLR_GetRoundTimeString(), 0, -1);

    // Overtime.
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "PLR_StartOvertime()", 0, -1);

    // team_train_watcher is no longer in charge of train movement.
    EntFireByHandle(PLR_TEAMS[2].watcher, "SetTrainCanRecede", "0", 0, null, null);
    EntFireByHandle(PLR_TEAMS[3].watcher, "SetTrainCanRecede", "0", 0, null, null);
    EntFireByHandle(PLR_TEAMS[4].watcher, "SetTrainCanRecede", "0", 0, null, null);
    EntFireByHandle(PLR_TEAMS[5].watcher, "SetTrainCanRecede", "0", 0, null, null);
    
    NetProps.SetPropBool(PLR_TEAMS[2].watcher, "m_bHandleTrainMovement", false);
    NetProps.SetPropBool(PLR_TEAMS[3].watcher, "m_bHandleTrainMovement", false);
    NetProps.SetPropBool(PLR_TEAMS[4].watcher, "m_bHandleTrainMovement", false);
    NetProps.SetPropBool(PLR_TEAMS[5].watcher, "m_bHandleTrainMovement", false);

    // Add thinks to carts so their movement state stays in sync.
    PLR_CreateCartAutoUpdater(2, PLR_TEAMS[2].train);
    PLR_CreateCartAutoUpdater(3, PLR_TEAMS[3].train);
    PLR_CreateCartAutoUpdater(4, PLR_TEAMS[4].train);
    PLR_CreateCartAutoUpdater(5, PLR_TEAMS[5].train);
}

__CollectGameEventCallbacks(this);
