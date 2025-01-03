IncludeScript("mega_mod/common/special_delivery.nut");

::MM_SDRoundEnd <- function () {
    if (::MM_SDCaptured) {
        return;
    }
    local bell_ringer_relay = MM_GetEntByName("bell_ringer_relay");
    MM_GetEntByName("capturezone_volume").Kill();
    MM_GetEntByName("australium").Kill();
    EntFireByHandle(bell_ringer_relay, "Enable", "", 0, null, null);
    EntFireByHandle(bell_ringer_relay, "Trigger", "", 0, null, null);
    Entities.FindByClassname(null, "team_round_timer").Kill();
}

::MM_SDCapture <- function () {
    ::MM_SDCaptured <- true;
    Entities.FindByClassname(null, "team_round_timer").Kill();
}

function OnGameEvent_teamplay_round_start(params) {
    MM_Special_Delivery();

    ::MM_SDCaptured <- false;
    EntityOutputs.AddOutput(MM_GetEntByName("capturezone_volume"), "OnCapture", "!self", "RunScriptCode", "MM_SDCapture()", 0, -1)
}

__CollectGameEventCallbacks(this);