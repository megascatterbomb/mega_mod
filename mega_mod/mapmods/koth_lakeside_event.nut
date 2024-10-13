ClearGameEventCallbacks();

IncludeScript("mega_mod/common/no_truce.nut")

function OnGameEvent_teamplay_round_start(params)
{
    local red_timer = MM_GetEntByName("zz_red_koth_timer");
    local blu_timer = MM_GetEntByName("zz_blue_koth_timer");

    EntFireByHandle(red_timer, "SetTime", "180", 0, null, null);
    EntFireByHandle(blu_timer, "SetTime", "180", 0, null, null);
}

__CollectGameEventCallbacks(this);