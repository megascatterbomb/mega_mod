IncludeScript("mega_mod/common/special_delivery.nut");

function OnGameEvent_teamplay_round_start(params) {
    MM_Special_Delivery();
    EntityOutputs.AddOutput(MM_GetEntByName("capturezone_volume"), "OnCapture", "!self", "RunScriptCode", "MM_SDCapture()", 0, -1)
}

__CollectGameEventCallbacks(this);