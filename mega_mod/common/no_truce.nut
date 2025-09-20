::MM_LAST_CAPTURE_BY <- 0;

// Lock point, ensure retains owner and timers pause
::MM_ON_BOSS_ENTER <- function(cpName) {
    printl("MEGAMOD: no_truce mod firing ON_BOSS_ENTER for " + cpName);
    local cp = MM_GetEntByName(cpName);
    local objectiveRes = Entities.FindByClassname(null, "tf_objective_resource");

    NetProps.SetPropIntArray(objectiveRes, "m_iOwner", ::MM_LAST_CAPTURE_BY, 0);
    cp.AcceptInput("SetLocked", "1", null, null);
    cp.AcceptInput("HideModel", "", null, null);
}.bindenv(this);

// Unlock point and resume timer
// Caller cannot be null otherwise SetOwner does nothing.
::MM_ON_BOSS_EXIT <- function(cpName) {
    printl("MEGAMOD: no_truce mod firing ON_BOSS_EXIT for " + cpName);
    local cp = MM_GetEntByName(cpName);
    cp.AcceptInput("SetOwner", "" + ::MM_LAST_CAPTURE_BY, null, Gamerules());
    cp.AcceptInput("SetLocked", "0", null, null);
    cp.AcceptInput("ShowModel", "", null, null);

    local kothTimer;
    if (::MM_LAST_CAPTURE_BY == 2) {
        kothTimer = MM_GetEntByName("zz_red_koth_timer");
    } else if (::MM_LAST_CAPTURE_BY == 3) {
        kothTimer = MM_GetEntByName("zz_blue_koth_timer");
    } else {
        return;
    }

    kothTimer.AcceptInput("Resume", "", null, null);
}.bindenv(this);

// Unlock point and resume timer
// Caller cannot be null otherwise SetOwner does nothing.
::MM_ON_BOSS_DEAD <- function(cpName) {
    printl("MEGAMOD: no_truce mod firing ON_BOSS_DEAD for " + cpName);
    local cp = MM_GetEntByName(cpName);
    cp.AcceptInput("SetOwner", "" + ::MM_LAST_CAPTURE_BY, null, Gamerules());
    cp.AcceptInput("SetLocked", "0", null, null);
    cp.AcceptInput("ShowModel", "", null, null);

    local kothTimer;
    if (::MM_LAST_CAPTURE_BY == 2) {
        kothTimer = MM_GetEntByName("zz_red_koth_timer");
    } else if (::MM_LAST_CAPTURE_BY == 3) {
        kothTimer = MM_GetEntByName("zz_blue_koth_timer");
    } else {
        return;
    }

    kothTimer.AcceptInput("Resume", "", null, null);
}.bindenv(this);

function StripBossRelays(cpName) {
    ::MM_LAST_CAPTURE_BY <- 0;

    local bossEnterRelay = MM_GetEntByName("boss_enter_relay");
	local bossExitRelay = MM_GetEntByName("boss_exit_relay");
	local bossDeadRelay = MM_GetEntByName("boss_dead_relay");

    if (!bossEnterRelay) {
        bossEnterRelay = SpawnEntityFromTable("logic_relay", {
            targetname = "boss_enter_relay"
        });
    }

    if (!bossExitRelay) {
        bossExitRelay = SpawnEntityFromTable("logic_relay", {
            targetname = "boss_exit_relay"
        });
    }

    if (!bossDeadRelay) {
        bossDeadRelay = SpawnEntityFromTable("logic_relay", {
            targetname = "boss_dead_relay"
        });
    }

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

// Don't need this for merasmus.
// Call after include, NOT in teamplay_round_start
function HookBossRelaysManual(cpName, bossType) {
    this["OnGameEvent_" + bossType + "_summoned"] <- function(params) {
        MM_ON_BOSS_ENTER(cpName);
    };
    this["OnGameEvent_" + bossType + "_killed"] <- function(params) {
        MM_ON_BOSS_DEAD(cpName);
    };
    this["OnGameEvent_" + bossType + "_escaped"] <- function(params) {
        MM_ON_BOSS_EXIT(cpName);
    };
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