ClearGameEventCallbacks();

IncludeScript("mega_mod/common/no_truce.nut")

HookBossRelaysManual("control_point_1", "eyeball_boss");

function OnGameEvent_teamplay_round_start(params)
{
	StripBossRelays("control_point_1")
}

__CollectGameEventCallbacks(this);