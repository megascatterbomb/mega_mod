::MM_LAST_CAPTURE_BY <- 0;

// Lock point, ensure retains owner and timers pause
::MM_ON_BOSS_ENTER <- function(cpName) {
    printl("MEGAMOD: no_truce mod firing ON_BOSS_ENTER for " + cpName);
    local cp = MM_GetEntByName(cpName);
    local capArea = Entities.FindByClassname(null, "trigger_capture_area");
    local objectiveRes = Entities.FindByClassname(null, "tf_objective_resource");
    NetProps.SetPropIntArray(objectiveRes, "m_iOwner", ::MM_LAST_CAPTURE_BY, 0);

    capArea.SetTeam(::MM_LAST_CAPTURE_BY);
    cp.AcceptInput("SetOwner", "" + ::MM_LAST_CAPTURE_BY, null, null);
    cp.AcceptInput("SetLocked", "1", null, null);
}.bindenv(this);

// Unlock point and resume timer
::MM_ON_BOSS_EXIT <- function(cpName) {
    printl("MEGAMOD: no_truce mod firing ON_BOSS_EXIT for " + cpName);
    local cp = MM_GetEntByName(cpName);
    local owner = cp.GetTeam();
    cp.AcceptInput("SetLocked", "0", null, null);

    local kothTimer = MM_GetEntByName(owner == 2 ? "zz_red_koth_timer" : "zz_blue_koth_timer");
    kothTimer.AcceptInput("ResumeTimer", "", null, null);
}.bindenv(this);

// Unlock point and resume timer
::MM_ON_BOSS_DEAD <- function(cpName) {
    printl("MEGAMOD: no_truce mod firing ON_BOSS_DEAD for " + cpName);
    local cp = MM_GetEntByName(cpName);
    local owner = cp.GetTeam();
    cp.AcceptInput("SetLocked", "0", null, null);

    local kothTimer = MM_GetEntByName(owner == 2 ? "zz_red_koth_timer" : "zz_blue_koth_timer");
    kothTimer.AcceptInput("ResumeTimer", "", null, null);
}.bindenv(this);

function StripBossRelays(cpName) {
    local bossEnterRelay = MM_GetEntByName("boss_enter_relay");
	local bossExitRelay = MM_GetEntByName("boss_exit_relay");
	local bossDeadRelay = MM_GetEntByName("boss_dead_relay");

    EntityOutputs.RemoveOutput(bossEnterRelay, "OnTrigger", cpName, "Disable", "");
    EntityOutputs.RemoveOutput(bossExitRelay, "OnTrigger", cpName, "Enable", "");
    EntityOutputs.RemoveOutput(bossDeadRelay, "OnTrigger", cpName, "Enable", "");

    EntityOutputs.AddOutput(bossEnterRelay, "OnTrigger", "!self", "RunScriptCode", "::MM_ON_BOSS_ENTER(\"" + cpName + "\")", 0, -1);
    EntityOutputs.AddOutput(bossExitRelay, "OnTrigger", "!self", "RunScriptCode", "::MM_ON_BOSS_EXIT(\"" + cpName + "\")", 0, -1);
    EntityOutputs.AddOutput(bossDeadRelay, "OnTrigger", "!self", "RunScriptCode", "::MM_ON_BOSS_DEAD(\"" + cpName + "\")", 0, -1);

    local cp = MM_GetEntByName(cpName);

    EntityOutputs.AddOutput(cp, "OnCapTeam1", "!self", "RunScriptCode", "::MM_LAST_CAPTURE_BY = 2", 0, -1);
    EntityOutputs.AddOutput(cp, "OnCapTeam2", "!self", "RunScriptCode", "::MM_LAST_CAPTURE_BY = 3", 0, -1);
}

// no_truce function by LizardOfOz
::no_truce <- {
    gamerules = Gamerules(),
    OnGameEvent_recalculate_truce = function(params)
    {
        local isTruce = NetProps.GetPropBool(gamerules, "m_bTruceActive");
        NetProps.SetPropBool(gamerules, "m_bTruceActive", false);

        if(!isTruce) {
            return;
        }

        local text_tf = SpawnEntityFromTable("game_text_tf", {
            message = "No Truce! Keep on Killing!",
            icon = "ico_notify_flag_moving_alt",
            background = 0,
            display_to_team = 0
        });
        NetProps.SetPropBool(text_tf, "m_bForcePurgeFixedupStrings", true);
        EntFireByHandle(text_tf, "Display", "", 0, null, null);
        EntFireByHandle(text_tf, "Kill", "", 3, null, null);
    }
};

EntFireByHandle(Gamerules(), "RunScriptCode", "::__CollectGameEventCallbacks(no_truce)", 1, null, null);