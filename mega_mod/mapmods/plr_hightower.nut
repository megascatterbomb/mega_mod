ClearGameEventCallbacks();
IncludeScript("mega_mod/common/plr_overtime.nut");

function OnGameEvent_teamplay_round_start(params) {

    InitGlobalVars();

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

    PLR_TEAMS[2].custom.elv = null;
    PLR_TEAMS[3].custom.elv = null;

    PLR_TEAMS[2].watcher = MM_GetEntByName("plr_red_watcherC");
    PLR_TEAMS[3].watcher = MM_GetEntByName("plr_blu_watcherC");

    // Cart control logic replacement
    MM_GetEntByName("template_elv_case_red").Kill();
    MM_GetEntByName("template_elv_case_blu").Kill();
    MM_GetEntByName("plr_red_pushingcase").Kill();
    MM_GetEntByName("plr_blu_pushingcase").Kill();

    PLR_TEAMS[2].logiccase = PLR_CreateLogicCase(2, "mm_plr_logiccase_red");
    PLR_TEAMS[3].logiccase = PLR_CreateLogicCase(3, "mm_plr_logiccase_blu");

    EntityOutputs.AddOutput(PLR_TEAMS[2].pushzone, "OnNumCappersChanged2", "mm_plr_logiccase_red", "InValue", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[3].pushzone, "OnNumCappersChanged2", "mm_plr_logiccase_blu", "InValue", "", 0, -1);

    // First hills
    PLR_AddRollbackZone(2, "plr_red_pathC_mid_35", "plr_red_pathC_mid_38", "plr_red_pathC_mid_34");
    PLR_AddRollbackZone(3, "plr_blu_pathC_hillA38", "plr_blu_pathC_hillA22", "plr_blu_pathC_hillA19");
    // Elevators
    PLR_AddRollbackZone(2, "plr_red_pathC_hillA3", "plr_red_pathC_end_dummy", "plr_red_pathC_hillA2");
    PLR_AddRollbackZone(3, "plr_blu_pathC_hillA3", "plr_blu_pathC_end_dummy", "plr_blu_pathC_hillA2");

    // Crossover logic replacement
    MM_GetEntByName("plr_red_crossover1_branch").Kill();
    MM_GetEntByName("plr_red_crossover1_relay").Kill();
    MM_GetEntByName("plr_blu_crossover1_branch").Kill();
    MM_GetEntByName("plr_blu_crossover1_relay").Kill();

    PLR_AddCrossing([
        ["plr_red_crossover1_start", "plr_red_crossover1_end", 2],
        ["plr_blu_crossover1_start", "plr_blu_crossover1_end", 3]
    ]);

    // Elevator logic replacement
    MM_GetEntByName("clamp_logic_case_red").Kill();
    MM_GetEntByName("clamp_logic_case").Kill();

    EntityOutputs.AddOutput(MM_GetEntByName("clamp_red_positioncart_relay_begin"), "OnTrigger", "!self", "RunScriptCode", "PLR_BlockCart(2, true)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("clamp_blu_positioncart_relay_begin"), "OnTrigger", "!self", "RunScriptCode", "PLR_BlockCart(3, true)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("clamp_red_positioncart_relay_end"), "OnTrigger", "!self", "RunScriptCode", "SwitchToElevator(2)", 0.95, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("clamp_blu_positioncart_relay_end"), "OnTrigger", "!self", "RunScriptCode", "SwitchToElevator(3)", 0.95, -1);

    // Timer logic replacement
    EntityOutputs.RemoveOutput(PLR_TIMER, "OnSetupFinished", PLR_TIMER_NAME, "Disable", "");
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", PLR_GetRoundTimeString(), 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "PLR_StartOvertime()", 0, -1);

    // Add thinks to carts
    PLR_CreateCartAutoUpdater(2, PLR_TEAMS[2].train);
    PLR_CreateCartAutoUpdater(3, PLR_TEAMS[3].train);
}

::PLR_StartOvertimeBase <- PLR_StartOvertime;

function PLR_StartOvertime() {
    local redRollbackRelay = MM_GetEntByName("plr_red_rollback_relay");
    local bluRollbackRelay = MM_GetEntByName("plr_blu_rollback_relay");

    // Prevent other calls to overtime logic
    EntFireByHandle(redRollbackRelay, "Disable", "", 0, null, null);
    EntFireByHandle(bluRollbackRelay, "Disable", "", 0, null, null);

    PLR_StartOvertimeBase();
}

// Override PLR_Advance/PLR_Stop/PLR_TriggerRollback to also control elevator
::PLR_Advance_Base <- PLR_Advance;
::PLR_Stop_Base <- PLR_Stop;
::PLR_TriggerRollback_Base <- PLR_TriggerRollback;

function PLR_Advance(team, baseSpeed, dynamic = true) {
    local t = PLR_TEAMS[team];
    if (t.custom.elv) dynamic = false;
    PLR_Advance_Base(team, baseSpeed, dynamic);
    if(t.custom.elv) {
        EntFireByHandle(t.custom.elv, "SetSpeedForwardModifier", "0.25", 0, null, null);
        EntFireByHandle(t.custom.elv, "SetSpeedDirAccel", "" + baseSpeed, 0, null, null);
    }
}

function PLR_Stop(team) {
    local t = PLR_TEAMS[team];
    PLR_Stop_Base(team);
    if(t.custom.elv) {
        EntFireByHandle(t.custom.elv, "SetSpeedForwardModifier", "0.25", 0, null, null);
        EntFireByHandle(t.custom.elv, "SetSpeedDirAccel", "0.0", 0, null, null);

        // Stop sound if elevator is completely stopped.
        local currentSpeed = NetProps.GetPropFloat(t.custom.elv, "m_flSpeed");
        if (currentSpeed == 0) EntFireByHandle(t.custom.elv, "Stop", "", 0, null, null);
    }
}

function PLR_TriggerRollback(team, multiplier = 1.0) {
    local t = PLR_TEAMS[team];
    PLR_TriggerRollback_Base(team, multiplier);
    if(t.custom.elv) {
        EntFireByHandle(t.custom.elv, "SetSpeedForwardModifier", "0.25", 0, null, null);
        EntFireByHandle(t.custom.elv, "SetSpeedDirAccel", "" + (t.rollbackSpeed * multiplier), 0, null, null);
    }
}

// When the cart goes on the elevator, trigger necessary logic.
// Also disables rollback, otherwise it becomes impossible to maintain sync
// between the two func_tracktrains.
function SwitchToElevator(team) {
    local t = PLR_TEAMS[team];
    local otherTeam = team == 2 ? 3 : 2;
    local otherT = PLR_TEAMS[otherTeam];

    if(team == 2) {
        t.custom.elv = MM_GetEntByName("clamp_red");
        t.pushzone = MM_GetEntByName("plr_red_pushzone_elv");
        t.cartsparks = MM_GetEntArrayByName("plr_red_elevatorsparks");
        EntFireByHandle(t.train, "TeleportToPathTrack", "plr_red_pathC_hillA3", 0, null, null);
        EntityOutputs.AddOutput(t.pushzone, "OnNumCappersChanged2", "mm_plr_logiccase_red", "InValue", "", 0, -1);
    } else {
        t.custom.elv = MM_GetEntByName("clamp_blue");
        t.pushzone = MM_GetEntByName("plr_blu_pushzone_elv");
        t.cartsparks = MM_GetEntArrayByName("plr_blu_elevatorsparks");
        EntFireByHandle(t.train, "TeleportToPathTrack", "plr_blu_pathC_hillA3", 0, null, null);
        EntityOutputs.AddOutput(t.pushzone, "OnNumCappersChanged2", "mm_plr_logiccase_blu", "InValue", "", 0, -1);
    }

    PLR_DisableOvertimeRollback();

    EntFireByHandle(t.custom.elv, "SetSpeedForwardModifier", "0.25", 0, null, null);

    PLR_BlockCart(team, false);
}

__CollectGameEventCallbacks(this);
