ClearGameEventCallbacks();
IncludeScript("mega_mod/common/plr_overtime.nut");

function OnGameEvent_teamplay_round_start(params) {

    InitGlobalVars();

    ::PLR_TIMER_NAME <- "minecart_timer";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    PLR_TEAMS[2].cartsparks = MM_GetEntArrayByName("minecart_red_cartsparks");
    PLR_TEAMS[3].cartsparks = MM_GetEntArrayByName("minecart_blu_cartsparks");

    PLR_TEAMS[2].flashinglight = MM_GetEntByName("minecart_red_flashinglight");
    PLR_TEAMS[3].flashinglight = MM_GetEntByName("minecart_blu_flashinglight");

    PLR_TEAMS[2].pushzone = MM_GetEntByName("minecart_red_pushzone");
    PLR_TEAMS[3].pushzone = MM_GetEntByName("minecart_blu_pushzone");

    PLR_TEAMS[2].train = MM_GetEntByName("minecart_red_train");
    PLR_TEAMS[3].train = MM_GetEntByName("minecart_blu_train");

    PLR_TEAMS[2].logiccase = PLR_CreateLogicCase(2, "mm_plr_logiccase_red");
    PLR_TEAMS[3].logiccase = PLR_CreateLogicCase(3, "mm_plr_logiccase_blu");

    PLR_TEAMS[2].watcher = MM_GetEntByName("minecart_red_watcherA");
    PLR_TEAMS[3].watcher = MM_GetEntByName("minecart_blu_watcherA");

    EntityOutputs.AddOutput(PLR_TEAMS[2].pushzone, "OnNumCappersChanged2", "mm_plr_logiccase_red", "InValue", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[3].pushzone, "OnNumCappersChanged2", "mm_plr_logiccase_blu", "InValue", "", 0, -1);

    // Rollzones
    PLR_AddRollbackZone(2, "minecart_path_36", "minecart_path_38", "minecart_path_35");
    PLR_AddRollforwardZone(2, "minecart_path_48", "minecart_path_52", "minecart_path_51");
    PLR_AddRollbackZone(2, "minecart_path_57", "minecart_path_68", "minecart_path_56");
    PLR_AddRollbackZone(2, "minecart_path_77", "minecart_path_78", "minecart_path_76");
    PLR_AddRollbackZone(2, "minecart_path_88", null, "minecart_path_87");

    PLR_AddRollbackZone(3, "minecart_bpath_36", "minecart_bpath_38", "minecart_bpath_35");
    PLR_AddRollforwardZone(3, "minecart_bpath_48", "minecart_bpath_52", "minecart_bpath_51");
    PLR_AddRollbackZone(3, "minecart_bpath_57", "minecart_bpath_68", "minecart_bpath_56");
    PLR_AddRollbackZone(3, "minecart_bpath_77", "minecart_bpath_78", "minecart_bpath_76");
    PLR_AddRollbackZone(3, "minecart_bpath_80", null, "minecart_bpath_88");

    // Track if the cart is at the cutoff between the track and the capture zone
    PLR_TEAMS[2].custom.atCutoff = false;
    PLR_TEAMS[3].custom.atCutoff = false;

    EntityOutputs.AddOutput(MM_GetEntByName("minecart_path_81"), "OnPass", "!self", "RunScriptCode", "PLR_TEAMS[2].custom.atCutoff = false", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("minecart_path_82"), "OnPass", "!self", "RunScriptCode", "PLR_TEAMS[2].custom.atCutoff = true", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("minecart_path_84"), "OnPass", "!self", "RunScriptCode", "PLR_TEAMS[2].custom.atCutoff = true", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("minecart_path_86"), "OnPass", "!self", "RunScriptCode", "PLR_TEAMS[2].custom.atCutoff = false", 0, -1);

    EntityOutputs.AddOutput(MM_GetEntByName("minecart_bpath_82"), "OnPass", "!self", "RunScriptCode", "PLR_TEAMS[3].custom.atCutoff = false", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("minecart_bpath_89"), "OnPass", "!self", "RunScriptCode", "PLR_TEAMS[3].custom.atCutoff = true", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("minecart_bpath_83"), "OnPass", "!self", "RunScriptCode", "PLR_TEAMS[3].custom.atCutoff = true", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("minecart_bpath_86"), "OnPass", "!self", "RunScriptCode", "PLR_TEAMS[3].custom.atCutoff = false", 0, -1);

    // Track if the cart is at the very end of the track.
    PLR_TEAMS[2].custom.atEnd = false;
    PLR_TEAMS[3].custom.atEnd = false;

    EntityOutputs.AddOutput(MM_GetEntByName("minecart_path_85"), "OnPass", "!self", "RunScriptCode", "PLR_TEAMS[2].custom.atEnd = false; PLR_UpdateCart(2, PLR_TEAMS[2].pushstate)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("minecart_red_pathA_end"), "OnPass", "!self", "RunScriptCode", "PLR_TEAMS[2].custom.atEnd = true", 0, -1);

    EntityOutputs.AddOutput(MM_GetEntByName("minecart_bpath_85"), "OnPass", "!self", "RunScriptCode", "PLR_TEAMS[3].custom.atEnd = false; PLR_UpdateCart(3, PLR_TEAMS[3].pushstate)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("minecart_blu_pathA_end"), "OnPass", "!self", "RunScriptCode", "PLR_TEAMS[3].custom.atEnd = true", 0, -1);

    // Check if the cart needs updating.
    EntityOutputs.AddOutput(MM_GetEntByName("path_mid_a7"), "OnPass", "!self", "RunScriptCode", "CheckCart(2)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("path_mid_a10"), "OnPass", "!self", "RunScriptCode", "CheckCart(2)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("relay_enable_red_cap"), "OnTrigger", "!self", "RunScriptCode", "CheckCart(2)", 0, -1);

    EntityOutputs.AddOutput(MM_GetEntByName("path_mid_a7"), "OnPass", "!self", "RunScriptCode", "CheckCart(3)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("path_mid_a10"), "OnPass", "!self", "RunScriptCode", "CheckCart(3)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("relay_enable_blu_cap"), "OnTrigger", "!self", "RunScriptCode", "CheckCart(3)", 0, -1);

    // Remove old cart update logic
    EntityOutputs.RemoveOutput(MM_GetEntByName("path_mid_a7"), "OnPass", "minecart_red_pushzone", "Disable", "");
    EntityOutputs.RemoveOutput(MM_GetEntByName("path_mid_a10"), "OnPass", "minecart_red_pushzone", "Disable", "");
    EntityOutputs.RemoveOutput(MM_GetEntByName("path_mid_a7"), "OnPass", "minecart_blu_pushzone", "Disable", "");
    EntityOutputs.RemoveOutput(MM_GetEntByName("path_mid_a10"), "OnPass", "minecart_blu_pushzone", "Disable", "");

    EntityOutputs.RemoveOutput(MM_GetEntByName("path_mid_a7"), "OnPass", "minecart_red_pushzone", "Enable", "");
    EntityOutputs.RemoveOutput(MM_GetEntByName("path_mid_a10"), "OnPass", "minecart_red_pushzone", "Enable", "");
    EntityOutputs.RemoveOutput(MM_GetEntByName("path_mid_a7"), "OnPass", "minecart_blu_pushzone", "Enable", "");
    EntityOutputs.RemoveOutput(MM_GetEntByName("path_mid_a10"), "OnPass", "minecart_blu_pushzone", "Enable", "");

    EntityOutputs.RemoveOutput(MM_GetEntByName("relay_enable_red_cap"), "OnTrigger", "minecart_red_pushzone", "Disable", "");
    EntityOutputs.RemoveOutput(MM_GetEntByName("relay_enable_red_cap"), "OnTrigger", "minecart_red_pushzone", "Enable", "");
    EntityOutputs.RemoveOutput(MM_GetEntByName("relay_enable_blu_cap"), "OnTrigger", "minecart_blu_pushzone", "Disable", "");
    EntityOutputs.RemoveOutput(MM_GetEntByName("relay_enable_blu_cap"), "OnTrigger", "minecart_blu_pushzone", "Enable", "");

    // team_train_watcher is no longer in charge.
    NetProps.SetPropBool(PLR_TEAMS[2].watcher, "m_bHandleTrainMovement", false);
    NetProps.SetPropBool(PLR_TEAMS[3].watcher, "m_bHandleTrainMovement", false);

    EntityOutputs.AddOutput(PLR_TEAMS[2].pushzone, "OnNumCappersChanged2", "minecart_red_watcherA", "SetNumTrainCappers", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[3].pushzone, "OnNumCappersChanged2", "minecart_blu_watcherA", "SetNumTrainCappers", "", 0, -1);

    // Timer logic replacement
    EntityOutputs.RemoveOutput(PLR_TIMER, "OnSetupFinished", PLR_TIMER_NAME, "Disable", "");
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", GetRoundTimeString(), 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "StartOvertime()", 0, -1);

    // Add thinks to carts
    PLR_CreateCartAutoUpdater(2, PLR_TEAMS[2].train);
    PLR_CreateCartAutoUpdater(3, PLR_TEAMS[3].train);
}

// Update carts at the cutoff when train event finishes (carts at cutoff don't autoresume)
function CheckCart(team) {
    local t = PLR_GetTeam(team);
    // Don't need to autoresume if the cart should be stationary.
    if (t.pushstate == 0 && !OVERTIME_ACTIVE) return;
    if (!t.custom.atCutoff) return;

    PLR_UpdateCart(team, t.pushstate);
}

// Do not move cart forward if it's already at the end of the track.
::PLR_Advance_Base <- PLR_Advance;
function PLR_Advance(team, speed, dynamic) {
    if (dynamic == null) dynamic = true;
    local t = PLR_GetTeam(team);
    if (t.custom.atEnd && speed > 0) return;
    PLR_Advance_Base(team, speed, dynamic);
}

// Stop thinks from needlessly checking cart (causes cart sounds to play when they shouldn't)
::PLR_CartThink_Base <- PLR_CartThink;
function PLR_CartThink(team) {
    local t = PLR_GetTeam(team);
    if (t.custom.atEnd || t.custom.atCutoff) return 0.5;
    return PLR_CartThink_Base(team);
}

__CollectGameEventCallbacks(this);
