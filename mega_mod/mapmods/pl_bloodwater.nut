ClearGameEventCallbacks();

// Kill a lot of gameplay-irrelevant entities to save edicts.
// Total estimated savings: ~300
function OnGameEvent_teamplay_round_start(params)
{
    local killed = 0;

    // kill all info_target in underworld (-51)
    killed += MM_KillAllByName("spawn_purgatory");
    killed += MM_KillAllByName("spawn_loot");
    killed += MM_KillAllByName("spawn_warcrimes");

    killed -= 3;

    ::SPAWN_PURGATORY_ORIGIN <- Vector(-12319, -11965, -11786);
    ::SPAWN_LOOT_ORIGIN <- Vector(-12319, -10965, -11786);
    ::SPAWN_WARCRIMES_ORIGIN <- Vector(-12319, -9965, -11786);

    // replace with single info_target
    SpawnEntityFromTable("info_target", {
        targetname = "spawn_purgatory",
        origin = "-12319 -11965 -11786",
        angles = "0 0 0",
    });
    SpawnEntityFromTable("info_target", {
        targetname = "spawn_loot",
        origin = "-12319 -10965 -11786",
        angles = "0 0 0",
    })
    SpawnEntityFromTable("info_target", {
        targetname = "spawn_warcrimes",
        origin = "-12319 -9965 -11786",
        angles = "0 0 0",
    })

    // check target OnTick for players who have teleported there,
    // then teleport them to the appropriate location (hardcode coords)

    ::SPAWN_PURGATORY_RED <- [
        [Vector(-1314, -2975, -11840), QAngle(0, 108, 0)],
        [Vector(-1442, -2975, -11840), QAngle(0, 108, 0)],
        [Vector(-1570, -2975, -11840), QAngle(0, 108, 0)],
        [Vector(-737, -3067, -11761), QAngle(0, 45, 0)],
        [Vector(-812, -2962, -11761), QAngle(0, 45, 0)]
    ];
    ::SPAWN_PURGATORY_BLU <- [
        [Vector(-1378, -2975, -11840), QAngle(0, 108, 0)],
        [Vector(-1506, -2975, -11840), QAngle(0, 108, 0)],
        [Vector(-1634, -2975, -11840), QAngle(0, 108, 0)],
        [Vector(-774, -3015, -11761), QAngle(0, 45, 0)],
        [Vector(-849, -2910, -11761), QAngle(0, 45, 0)]
    ];
    ::SPAWN_LOOT_RED <- [[Vector(634, 2096, -11960), QAngle(0, 180, 0)]];
    ::SPAWN_LOOT_BLU <- [[Vector(634, 2224, -11960), QAngle(0, 180, 0)]];
    ::SPAWN_WARCRIMES_RED <- [
        [Vector(-1055, -40, -12047), QAngle(0, 0, 0)],
        [Vector(-928, -155, -12053), QAngle(0, 0, 0)],
        [Vector(-1074, -249, -12069), QAngle(0, 0, 0)],
        [Vector(-1201, -135, -12050), QAngle(0, 0, 0)],
        [Vector(-1378, -16, -12053), QAngle(0, 0, 0)],
        [Vector(-1403, 207, -12050), QAngle(0, 0, 0)],
        [Vector(-1187, 337, -12047), QAngle(0, 0, 0)],
        [Vector(-997, 333, -12047), QAngle(0, 0, 0)],
        [Vector(-810, 224, -12059), QAngle(0, 0, 0)],
        [Vector(-802, 72, -12063), QAngle(0, 0, 0)],
        [Vector(-808, -235, -12069), QAngle(0, 0, 0)],
        [Vector(-939, -353, -12093), QAngle(0, 0, 0)],
        [Vector(-764, -464, -12130), QAngle(0, 0, 0)],
        [Vector(-502, -1117, -12090), QAngle(0, 0, 0)],
        [Vector(-362, -1234, -12079), QAngle(0, 0, 0)],
        [Vector(-190, -1362, -12089), QAngle(0, 0, 0)],
        [Vector(-94, -2222, -12191), QAngle(0, 0, 0)]
    ];
    ::SPAWN_WARCRIMES_BLU <- [
        [Vector(-143, -2713, -12165), QAngle(0, 0, 0)],
        [Vector(-286, -2481, -12165), QAngle(0, 0, 0)],
        [Vector(-371, -2768, -12157), QAngle(0, 0, 0)],
        [Vector(-538, -2636, -12166), QAngle(0, 0, 0)],
        [Vector(-1299, -2675, -12027), QAngle(0, 0, 0)],
        [Vector(-1414, -2535, -12023), QAngle(0, 0, 0)],
        [Vector(-1641, -2641, -12003), QAngle(0, 0, 0)],
        [Vector(-1822, -2828, -12012), QAngle(0, 0, 0)],
        [Vector(-1953, -2654, -12025), QAngle(0, 0, 0)],
        [Vector(-1604, -2452, -12035), QAngle(0, 0, 0)],
        [Vector(-1830, -2450, -12038), QAngle(0, 0, 0)],
        [Vector(-1972, -2191, -12082), QAngle(0, 0, 0)],
        [Vector(-1902, -1425, -12093), QAngle(0, 0, 0)],
        [Vector(-1706, -1274, -12080), QAngle(0, 0, 0)],
        [Vector(-1560, -1116, -12103), QAngle(0, 0, 0)]
    ];

    AddThinkToEnt(MM_GetEntByName("gamerules"), "ThinkTeleport");

    // SOUND EFFECTS
    // remove duplicates at underworld skull  (-19)
    killed += MM_KillAllButOneByName("island_explode_warning_1");
    killed += MM_KillAllButOneByName("island_explode_warning_2");
    killed += MM_KillAllButOneByName("island_explode_warning_3");
    killed += MM_KillAllButOneByName("island_explode_sound_laugh");

    // The sound we leave behind triggers 4.0 seconds after relay_kill_all_treasure_island_effects is triggered.
    killed += MM_KillAllByName("island_explode_sound_1");
    killed += MM_KillAllByName("island_explode_sound_2");
    killed += MM_KillAllButOneByName("island_explode_sound_3");
    killed += MM_KillAllByName("island_explode_sound_4");

    // remove funny cart lines (-16)
    foreach (ent in [
        "keepmoving1"
        "keepmoving2"
        "auch1"
        "auch2"
        "auch3"
        "auch4"
        "auch5"
        "auch6"
        "auch7"
        "random1"
        "random2"
        "random3"
        "random4"
        "random5"
        "random6"
        "random7"
    ]) {
        MM_GetEntByName(ent).Kill();
        killed++;
    }
    // do the logic separately as they're not edicts but still consume CPU cycles needlessly.
    foreach (ent in [
        "random_case_timer"
        "keepmoving_case"
        "auch_case"
        "random_case"
    ]) {
        MM_GetEntByName(ent).Kill();
    }

    // Remove duplicates next to clock
    killed += MM_KillAllButOneByName("clock_open_sound");
    // Multiple sounds among the ambient_generics with this name
    // We kill duplicates within that group e.g. (A A B B C) -> Kill 1 A and 1 B.
    local clock_closed_sounds = MM_GetEntArrayByName("clock_closed_sound");
    foreach (ent in clock_closed_sounds) {
        local origin = ent.GetOrigin();
        if (origin.z < 8220.0 || origin.y < -640.0) {
            ent.Kill();
            killed++;
        }
    }

    local zombie_event_stingers = MM_GetEntArrayByName("zombie_event_stinger");
    foreach (ent in zombie_event_stingers) {
        local origin = ent.GetOrigin();
        if (origin.z < 8100.0 || origin.z > 8150.0) {
            ent.Kill();
            killed++;
        }
    }

    MM_GetEntByName("zombie_event_thunder1").Kill();
    MM_GetEntByName("zombie_event_thunder3").Kill();
    killed += 2;
    MM_GetEntByName("zombie_event_thunder_case").Kill(); // not an edict
    EntityOutputs.RemoveOutput(MM_GetEntByName("zombie_event_thunder_timer"), "OnTimer", "zombie_event_thunder_case", "PickRandom", "");
    EntityOutputs.AddOutput(MM_GetEntByName("zombie_event_thunder_timer"), "OnTimer", "zombie_event_thunder2", "PlaySound", "", 0, -1);

    // very long pit sounds and matching triggers (-37)
    foreach (ent in [
        "tele_tunnel_boss_laugh_1"
        "tele_tunnel_boss_laugh_1" // there's two with this name
        "tele_tunnel_boss_laugh_2"
        "tele_tunnel_boss_laugh_3"
        "tele_tunnel_boss_laugh_4"
        "tele_tunnel_boss_laugh_5"
        "tele_tunnel_boss_laugh_6"
        "tele_tunnel_boss_laugh_7"
        "tele_tunnel_boss_laugh_8"
        "tele_tunnel_boss_laugh_9"
        "tele_tunnel_boss_laugh_10"
        "tele_tunnel_ghostmoan_1"
        "tele_tunnel_ghostmoan_2"
        "tele_tunnel_ghostmoan_3"
        "tele_tunnel_ghostmoan_4"
        "tele_tunnel_ghostmoan_5"
        "tele_tunnel_ghostmoan_6"
        "tele_tunnel_ghostmoan_7"
        "tele_tunnel_ghostmoan_8"
    ]) {
        MM_GetEntByName(ent).Kill();
        killed++;
    }

    local tunnel_triggers = [];
    local tunnel_trigger = Entities.FindByClassname(null, "trigger_multiple");
    while(tunnel_trigger != null) {
        if (tunnel_trigger.GetName() == "") {
            local origin = tunnel_trigger.GetOrigin();
            if (origin.x > 110 && origin.y > 2345 && origin.z > -8382 &&
                origin.x < 530 && origin.y < 2783 && origin.z < 5793) {
                tunnel_triggers.push(tunnel_trigger);
            }
        }
        tunnel_trigger = Entities.FindByClassname(tunnel_trigger, "trigger_multiple");
    }
    foreach (ent in tunnel_triggers) {
        ent.Kill();
        killed++;
    }

    // VISUAL EFFECTS
    // excess island_explode_particle# (-7)
    foreach (ent in [
        "island_explode_particle1"
        "island_explode_particle2"
        "island_explode_particle3"
        "island_explode_particle4"
        "island_explode_particle5"
        "island_explode_particle6"
        "island_explode_particle8"
    ]) {
        MM_GetEntByName(ent).Kill();
        killed++;
    }
    // Sync last remaining particle to last remaining sound.
    EntityOutputs.RemoveOutput(MM_GetEntByName("relay_kill_all_treasure_island_effects"), "OnTrigger", "island_explode_particle7", "Start", "");
    EntityOutputs.AddOutput(MM_GetEntByName("relay_kill_all_treasure_island_effects"), "OnTrigger", "island_explode_particle7", "Start", "", 4.0, -1);

    // minecart_kill_decorations_particle (-6)
    foreach(ent in MM_GetEntArrayByName("minecart_kill_decorations_particle")) {
        ent.Kill();
        killed++;
    }

    // burning_torch (-24)
    local torches = [];
    local torch = Entities.FindByClassname(null, "info_particle_system");
    while(torch != null) {
        if (NetProps.GetPropString(torch, "m_iszEffectName") == "burning_torch") {
            torches.push(torch);
        }
        torch = Entities.FindByClassname(torch, "info_particle_system");
    }
    foreach (ent in torches) {
        ent.Kill();
        killed++;
    }

    // all unnamed env_sprite (-74)
    local sprites = [];
    local sprite = Entities.FindByClassname(null, "env_sprite");
    while(sprite != null) {
        if (sprite.GetName() == "") {
            sprites.push(sprite);
        }
        sprite = Entities.FindByClassname(sprite, "env_sprite");
    }
    foreach (ent in sprites) {
        ent.Kill();
        killed++;
    }
    // excess candles in red spawn (-22)
    local candles = MM_GetEntArrayByName("particle_fire");
    foreach (ent in candles) {
        local origin = ent.GetOrigin();
        if(origin.z < 6458.0 || origin.x < 1200.0) {
            ent.Kill()
            killed++;
        }
    }

    // point_spotlight (-40)
    local spotlights = [];
    local spotlight = Entities.FindByClassname(null, "point_spotlight");
    while(spotlight != null) {
        spotlights.push(spotlight);
        spotlight = Entities.FindByClassname(spotlight, "point_spotlight");
    }
    foreach (ent in spotlights) {
        ent.Kill();
        killed++;
    }

    printl("MEGAMOD: Killed " + killed + " entities.");
}


function ThinkTeleport() {
    for (local i = 0; i < 3; i++) {
        HandleTeleport(i);
    }

    return -1;
}

// type 0 = "PURGATORY", 1 = "LOOT", 2 = "WARCRIMES"
function HandleTeleport(type) {
    local maxplayers = MaxClients().tointeger()

    for (local i = 1; i <= maxplayers ; i++)
    {
        local player = PlayerInstanceFromIndex(i);
        if (player == null) continue;
        local player_origin = player.GetOrigin();
        local target_origin = [
            SPAWN_PURGATORY_ORIGIN,
            SPAWN_LOOT_ORIGIN,
            SPAWN_WARCRIMES_ORIGIN
        ][type];
        if (abs(player_origin.x - target_origin.x) < 64 &&
            abs(player_origin.y - target_origin.y) < 64 &&
            abs(player_origin.z - target_origin.z) < 64
        ) {
            local team = player.GetTeam();
            local destination = GetDestination(type, team);
            local d_pos = destination[0];
            local d_ang = destination[1];

            player.SetAbsOrigin(d_pos);
            player.SnapEyeAngles(d_ang);
        }
    }
}

function GetDestination(type, team) {
    local red_destinations = [
        SPAWN_PURGATORY_RED,
        SPAWN_LOOT_RED,
        SPAWN_WARCRIMES_RED
    ];
    local blu_destinations = [
        SPAWN_PURGATORY_BLU,
        SPAWN_LOOT_BLU,
        SPAWN_WARCRIMES_BLU
    ];
    if (team == Constants.ETFTeam.TF_TEAM_RED) {
        local n = RandomInt(0, red_destinations[type].len() - 1);
        return red_destinations[type][n];
    } else {
        local n = RandomInt(0, blu_destinations[type].len() - 1);
        return blu_destinations[type][n];
    }
}

__CollectGameEventCallbacks(this);