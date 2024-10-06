ClearGameEventCallbacks();

// Kill a lot of gameplay-irrelevant entities to save edicts.
// Total estimated savings: ~300
function OnGameEvent_teamplay_round_start(params)
{
    local killed = 0;
    // info_target in underworld
    // replace with single info_target (-51)
    // check target OnTick for players who have teleported there, then teleport them to the appropriate location (hardcode coords)
    // remove pushtriggers at entrances (-3)

    // TODO
    // SPAWN_PURGATORY_RED <- Vector(0, 0, 0);
    // SPAWN_PURGATORY_BLU <- Vector(0, 0, 0);
    // SPAWN_LOOT_RED <- [Vector(634, 2096, -11960), QAngle(0, 180, 0)];
    // SPAWN_LOOT_BLU <- [Vector(634, 2224, -11960), QAngle(0, 180, 0)];
    // SPAWN_WARCRIMES_RED <- Vector(0, 0, 0);
    // SPAWN_WARCRIMES_BLU <- Vector(0, 0, 0);

    // killed += MM_KillAllByName("spawn_purgatory");
    // killed += MM_KillAllByName("spawn_loot");
    // killed += MM_KillAllByName("spawn_warcrimes");

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
        ent.Kill();
        killed++;
    }
    // do the logic separately as they're not edicts but still consume CPU cycles needlessly.
    foreach (ent in [
        "random_case_timer"
        "keepmoving_case"
        "auch_case"
        "random_case"
    ]) {
        ent.Kill();
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

    // TODO
    // very long pit sounds and matching triggers (-36)

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
        ent.Kill();
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
        if (NetProps.GetPropString(torch, "m_iszEffectName") == "burning_torch"); {
            torches.push(torch);
        }
        torch = Entities.FindByClassname(null, "env_sprite");
    }
    foreach (ent in torches) {
        ent.Kill();
        killed++;
    }

    // all unnamed env_sprite (-74)
    local sprites = [];
    local sprite = Entities.FindByClassname(null, "env_sprite");
    while(sprite != null) {
        if (sprite.GetName == "") {
            sprites.push(sprite);
        }
        sprite = Entities.FindByClassname(null, "env_sprite");
    }
    foreach (ent in sprites) {
        ent.Kill();
        killed++;
    }
    // excess candles in red spawn (-20)
    local candles = MM_GetEntArrayByName("particle_fire");
    foreach (ent in candles) {
        local origin = ent.GetOrigin();
        if(origin.z < 6458.0) {
            ent.Kill()
            killed++;
        }
    }

    // point_spotlight (-40)
    local spotlights = [];
    local spotlight = Entities.FindByClassname(null, "point_spotlight");
    while(spotlight != null) {
        spotlights.push(spotlight);
        spotlight = Entities.FindByClassname(null, "env_sprite");
    }
    foreach (ent in spotlights) {
        ent.Kill();
        killed++;
    }

    printl("MEGAMOD: Killed " + killed + " entities.")
}

__CollectGameEventCallbacks(this);