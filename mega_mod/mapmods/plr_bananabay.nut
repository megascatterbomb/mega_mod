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

    ::RED_WATCHER <- MM_GetEntByName("minecart_red_watcherA");
    ::BLU_WATCHER <- MM_GetEntByName("minecart_blu_watcherA");

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

    // Track if the cart is at the cutoff between the track and the capture zone
    // where the cart stops during the train event.
    ::RED_AT_CUTOFF <- false;
    ::BLU_AT_CUTOFF <- false;

    EntityOutputs.AddOutput(MM_GetEntByName("minecart_path_81"), "OnPass", "!self", "RunScriptCode", "::RED_AT_CUTOFF <- false", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("minecart_path_82"), "OnPass", "!self", "RunScriptCode", "::RED_AT_CUTOFF <- true", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("minecart_path_84"), "OnPass", "!self", "RunScriptCode", "::RED_AT_CUTOFF <- true", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("minecart_path_86"), "OnPass", "!self", "RunScriptCode", "::RED_AT_CUTOFF <- false", 0, -1);

    EntityOutputs.AddOutput(MM_GetEntByName("minecart_bpath_82"), "OnPass", "!self", "RunScriptCode", "::BLU_AT_CUTOFF <- false", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("minecart_bpath_89"), "OnPass", "!self", "RunScriptCode", "::BLU_AT_CUTOFF <- true", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("minecart_bpath_83"), "OnPass", "!self", "RunScriptCode", "::BLU_AT_CUTOFF <- true", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("minecart_bpath_86"), "OnPass", "!self", "RunScriptCode", "::BLU_AT_CUTOFF <- false", 0, -1);

    // Track if the cart is at the very end of the track.
    ::RED_AT_END <- false;
    ::BLU_AT_END <- false;

    EntityOutputs.AddOutput(MM_GetEntByName("minecart_path_85"), "OnPass", "!self", "RunScriptCode", "::RED_AT_END <- false", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("minecart_red_pathA_end"), "OnPass", "!self", "RunScriptCode", "::RED_AT_END <- true", 0, -1);

    EntityOutputs.AddOutput(MM_GetEntByName("minecart_bpath_85"), "OnPass", "!self", "RunScriptCode", "::BLU_AT_END <- false", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("minecart_blu_pathA_end"), "OnPass", "!self", "RunScriptCode", "::BLU_AT_END <- true", 0, -1);

    // Check if the cart needs updating.
    EntityOutputs.AddOutput(MM_GetEntByName("path_mid_a7"), "OnPass", "!self", "RunScriptCode", "CheckCartRed()", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("path_mid_a10"), "OnPass", "!self", "RunScriptCode", "CheckCartRed()", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("relay_enable_red_cap"), "OnTrigger", "!self", "RunScriptCode", "CheckCartRed()", 0, -1);

    EntityOutputs.AddOutput(MM_GetEntByName("path_mid_a7"), "OnPass", "!self", "RunScriptCode", "CheckCartBlu()", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("path_mid_a10"), "OnPass", "!self", "RunScriptCode", "CheckCartBlu()", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("relay_enable_blu_cap"), "OnTrigger", "!self", "RunScriptCode", "CheckCartBlu()", 0, -1);

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
    NetProps.SetPropBool(RED_WATCHER, "m_bHandleTrainMovement", false);
    NetProps.SetPropBool(BLU_WATCHER, "m_bHandleTrainMovement", false);

    EntityOutputs.AddOutput(RED_PUSHZONE, "OnNumCappersChanged2", "minecart_red_watcherA", "SetNumTrainCappers", "", 0, -1);
    EntityOutputs.AddOutput(BLU_PUSHZONE, "OnNumCappersChanged2", "minecart_blu_watcherA", "SetNumTrainCappers", "", 0, -1);

    // Timer logic replacement
    EntityOutputs.RemoveOutput(PLR_TIMER, "OnSetupFinished", PLR_TIMER_NAME, "Disable", "");
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", GetRoundTimeString(), 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "StartOvertime()", 0, -1);

    // Add thinks to carts
    CreateCartAutoUpdater(RED_TRAIN, 2);
    CreateCartAutoUpdater(BLU_TRAIN, 3);
}

// Update carts at the cutoff when train event finishes (carts at cutoff don't autoresume)
function CheckCartRed() {
    // Don't need to autoresume if the cart should be stationary.
    if (CASE_RED == 0 && !OVERTIME_ACTIVE) return;
    if (!RED_AT_CUTOFF) return;

    printl("CHECK CART RED");
    UpdateRedCart(CASE_RED);
}

function CheckCartBlu() {
    // Don't need to autoresume if the cart should be stationary.
    if (CASE_BLU == 0 && !OVERTIME_ACTIVE) return;
    if (!BLU_AT_CUTOFF) return;

    printl("CHECK CART BLU");
    UpdateBluCart(CASE_BLU);
}

// Do not move cart forward if it's already at the end of the track.
::AdvanceRedBase <- AdvanceRed;
::AdvanceBluBase <- AdvanceBlu;

function AdvanceRed(speed, dynamic = true) {
    if (RED_AT_END && speed > 0) return;
    AdvanceRedBase(speed, dynamic);
}

function AdvanceBlu(speed, dynamic = true) {
    if (BLU_AT_END && speed > 0) return;
    AdvanceBluBase(speed, dynamic);
}

// Stop thinks from needlessly checking cart (causes cart sounds to play when they shouldn't)
::CartThinkBase <- CartThink;
function CartThink(team) {
    if (team == 2 && (RED_AT_END || RED_AT_CUTOFF)) return;
    if (team == 3 && (BLU_AT_END || BLU_AT_CUTOFF)) return;
    printl("THINK CART" + (team == 3 ? " BLU" : " RED"));
    return CartThinkBase(team);
}

__CollectGameEventCallbacks(this);