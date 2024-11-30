ClearGameEventCallbacks();

IncludeScript("mega_mod/global/respawn_mod.nut");

function OnGameEvent_teamplay_round_start(params)
{
    local master = Entities.FindByClassname(null, "team_control_point_master");
    master.AcceptInput("AddOutput", "score_style 1", null, null);
}

__CollectGameEventCallbacks(this);