ClearGameEventCallbacks();

IncludeScript("mega_mod/common/no_truce.nut")

function OnGameEvent_teamplay_round_start(params)
{
	StripBossRelays("control_point_1")
}

__CollectGameEventCallbacks(this);