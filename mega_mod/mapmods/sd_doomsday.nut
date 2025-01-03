IncludeScript("mega_mod/common/special_delivery.nut");

function OnGameEvent_teamplay_round_start(params) {
    MM_Special_Delivery();
}

__CollectGameEventCallbacks(this);