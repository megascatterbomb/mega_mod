// https://steamcommunity.com/sharedfiles/filedetails/?id=2579644293

ClearGameEventCallbacks();

MM_IncludeGlobalMod("respawn_mod");

function OnGameEvent_teamplay_round_start(params)
{
    local caps = [
        MM_GetEntByName("minecart_path_66")
        MM_GetEntByName("minecart_path_s3_122")
        MM_GetEntByName("minecart_path_s3_97")
        MM_GetEntByName("minecart_path_s3_27")
    ];
    for (local i = 0; i < 4; i++) {
        local cap_name = "cap_" + (i + 1);
        local path_track = caps[i];
        EntityOutputs.RemoveOutput(path_track, "OnPass", cap_name, "SetOwner", "3");
        EntityOutputs.AddOutput(path_track, "OnPass", cap_name, "SetOwner", "3", 0.1, 1);
    }
}

__CollectGameEventCallbacks(this);