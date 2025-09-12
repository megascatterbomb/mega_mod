// This file should only be touched by mod contributors.
// If you're a server owner and you want to disable certain mods,
// go to scriptdata/mega_mod_config.txt and set those mods to false.

if(getroottable().rawin("MEGA_MOD_LOADED") && ::MEGA_MOD_LOADED) {
    printl("MEGAMOD: Already loaded, skipping...");
    return;
}

::MEGA_MOD_LOADED <- false;

// You should not have to touch anything above this point.

::MM_ALL_MAP_MODS <- [
    "arena_perks"
    "cp_freaky_fair"
    "cp_standin_final"
    "koth_lakeside_event"
    "koth_viaduct_event"
    "pl_bloodwater"
    "pl_breadspace"
    "pl_emerge"
    "plr_bananabay"
    "plr_cutter"
    "plr_hacksaw"
    "plr_hacksaw_event"
    "plr_hightower"
    "plr_hightower_event"
    "plr_nightfall_final"
    "plr_pipeline"
    "sd_doomsday"
    "sd_doomsday_event"

    // Support for updated versions of workshop maps is not guaranteed
    "workshop/pl_cactuscanyon_redux_final2.ugc2579644293"
    "workshop/plr_highertower.ugc899335714"
    "workshop/tf2ware_ultimate.ugc3413262999"
];

// To create a global mod: create a file in mega_mod/globalmods/ with the name of the mod.
// Implement these functions:
// function ShouldApply() // Return true if the mod should be applied, false if not.
// function LoadAlongsideMapMods() // Return true if the mod should be applied even if there's a map specific mod.
// function ApplyMod() // Apply the mod.
// Remember to bind the functions to their scopes, otherwise things might not work as expected!

// If you want to manually include a global mod in a map-specific mod, use MM_IncludeGlobalMod("global_mod_name")
// Make sure to gate its inclusion with MM_ModIsEnabled("global_mod_name") unless your mod REQUIRES the global mod to work.

::MM_ALL_GLOBAL_MODS <- [
    "5cp_anti_stalemate"
    "respawn_mod"
    "zi_mod"
    "jakemod"
    "gamemode_cfg"
    "neutral_point_stalemate"
    "mvm_scaling"
    "speedshot_bhop_mod"
];

// You should not have to touch anything below this point.

IncludeScript("mega_mod/config.nut");

local mapName = GetMapName();
local mapModIndex = MM_ALL_MAP_MODS.find(mapName);
local hasMapMod = mapModIndex != null;

printl("MEGAMOD: Loading mega_mod/util.nut...");
IncludeScript("mega_mod/util.nut")
printl("MEGAMOD: util.nut started");

if(hasMapMod) {
    if(MM_ModIsEnabled(mapName, true)) {
        IncludeScript("mega_mod/mapmods/" + mapName + ".nut")
        printl("MEGAMOD: " + mapName + ".nut started")
    } else {
        printl("MEGAMOD: " + mapName + " has a mod, but is disabled, skipping...");
    }
} else {
    printl("MEGAMOD: " + mapName + " is not listed within mega_mod.nut.");
}

printl("MEGAMOD: Loading global mods...");

foreach(mod in MM_ALL_GLOBAL_MODS) {
	if(MM_ModIsEnabled(mod)) MM_IncludeGlobalMod(mod, hasMapMod);
}

printl("MEGAMOD: Global mods loaded.");

::MEGA_MOD_LOADED <- true;
