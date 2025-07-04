ClearGameEventCallbacks();
if (MM_ModIsEnabled("respawn_mod")) MM_IncludeGlobalMod("respawn_mod");

// Adds a door that prevents players from accidentally going the wrong way.

function OnGameEvent_teamplay_round_start(params)
{
    // Spawn door entities
    local door_left = SpawnEntityFromTable("func_door",
    {
        targetname = "c_door_left",
        speed = "400"
        lip = "-190"
        wait = "-1"
        spawnflags = "0"
        movedir = "0 180 0"
        origin = "1872 2518 -408"
    })
    door_left.SetSize(Vector(1792, 2510, -512), Vector(1952, 2526, -304))
    door_left.SetSolid(2) // SOLID_BBOX

    local door_right = SpawnEntityFromTable("func_door",
    {
        targetname = "c_door_right"
        speed = "400"
        lip = "-190"
        wait = "-1"
        spawnflags = "0"
        movedir = "0 0 0"
        origin = "2032 2518 -408"
    })
    door_right.SetSize(Vector(1952, 2510, -512), Vector(2112, 2526, -304))
    door_right.SetSolid(2) // SOLID_BBOX

    // Spawn props
    local prop_left = SpawnEntityFromTable("prop_dynamic",
    {
        targetname = "c_prop_left"
        model = "models/props_breadspace/blastdoor_2.mdl"
        origin = "1952 2508 -416"
        solid = "6",
        disableshadows = "1",
        angles = "0 270 0"
    })

    local prop_right = SpawnEntityFromTable("prop_dynamic",
    {
        targetname = "c_prop_right"
        model = "models/props_breadspace/blastdoor_1.mdl"
        origin = "1952 2508 -416"
        solid = "6",
        disableshadows = "1",
        angles = "0 270 0"
    })

    prop_left.RemoveEFlags(Constants.FEntityEFlags.EFL_DONTBLOCKLOS);
    prop_right.RemoveEFlags(Constants.FEntityEFlags.EFL_DONTBLOCKLOS);

    // Set doors to open after B is captured.
    local cp_b = MM_GetEntByName("Cp_2");
    EntityOutputs.AddOutput(cp_b, "OnCapTeam2", "c_door_*", "Open", "", 1, -1);

    EntFireByHandle(prop_left, "SetParent", "c_door_left", 0, null, null);
    EntFireByHandle(prop_right, "SetParent", "c_door_right", 0, null, null);
}

__CollectGameEventCallbacks(this);