IncludeScript("mega_mod/common/special_delivery.nut");

::MM_SDSetupEndBase <- ::MM_SDSetupEnd;
::MM_SDSetupEnd <- function () {
    ::MM_SDSetupEndBase();

    EntFireByHandle(Entities.FindByClassname(null, "tf_gamerules"), "RunScriptCode", "::MM_SDSetupDisableSpellOutput()", 1, null, null);
}

::MM_SDSetupDisableSpellOutput <- function () {
    // Disable merasmus spells near the round end.
    local team_round_timer = Entities.FindByClassname(null, "team_round_timer");
    EntityOutputs.AddOutput(team_round_timer, "On2MinRemain", "!self", "RunScriptCode", "::MM_SDDisableSpells()", 0, -1);
}

::MM_SDDisableSpells <- function () {
    printl("MEGAMOD: Disabling Merasmus spells...");
    EntityOutputs.RemoveOutput(MM_GetEntByName("elevator_australium_zone"), "OnEndTouchFlag", "merasmus_fortune_booth", "EnableFortuneTelling", "");
    MM_GetEntByName("merasmus_fortune_booth").AcceptInput("DisableFortuneTelling", "", null, null);
}

::MM_SDRoundEnd <- function () {
    if (::MM_SDCaptured) {
        printl("MEGAMOD: Round end by timeout BLOCKED (already captured)...");
        return;
    }
    printl("MEGAMOD: Round end by timeout...");
    local bell_ringer_relay = MM_GetEntByName("bell_ringer_relay");
    MM_GetEntByName("capturezone_volume").Kill();
    MM_GetEntByName("australium").Kill();
    MM_GetEntByName("hammer_smash_trigger_relay").Kill();
    MM_GetEntByName("elevator_australium_zone").Kill();
    MM_GetEntByName("elevator_alarm").Kill();

    EntFireByHandle(bell_ringer_relay, "Enable", "", 0, null, null);
    EntFireByHandle(bell_ringer_relay, "Trigger", "", 0, null, null);

    Entities.FindByClassname(null, "team_round_timer").Kill();
}


function OnGameEvent_teamplay_round_start(params) {
    MM_Special_Delivery();
    EntityOutputs.AddOutput(Entities.FindByClassname(null, "tf_gamerules"), "OnCapture", "!self", "RunScriptCode", "MM_SDCapture()", 0, -1)
}

__CollectGameEventCallbacks(this);