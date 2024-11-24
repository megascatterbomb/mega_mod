// Comment out any maps that you don't want to apply the mods to.

local mods = [
    "arena_perks"
    "cp_freaky_fair"
    "cp_standin_final"
    "koth_lakeside_event"
    "koth_viaduct_event"
    "pl_bloodwater"
    "plr_bananabay"
    "plr_hacksaw"
    "plr_hacksaw_event"
    "plr_hightower"
    "plr_hightower_event"
    "plr_nightfall_final"
    "plr_pipeline"

    // Support for updated versions of workshop maps is not guaranteed
    "workshop/plr_highertower.ugc899335714"
];

local mapName = GetMapName();
local index = mods.find(mapName);

// These are ALWAYS loaded (unless there's a map specific mod)
// if you only want to apply mods on some maps, do your own checks!
local globalMods = [
    "5cp_anti_stalemate"
    "respawn_mod"
];

printl("MEGAMOD: Loading mega_mod/util.nut...");
IncludeScript("mega_mod/util.nut")
printl("MEGAMOD: util.nut started");

if(index != null) {
    printl("MEGAMOD: Found mod for " + mapName + ". Attempting to load...");
    IncludeScript("mega_mod/mapmods/" + mapName + ".nut")
    printl("MEGAMOD: " + mapName + ".nut started")
} else {
    printl("" + mapName + " is not listed within mega_mod.nut. Checking global mods...");
    foreach(mod in globalMods) {
        IncludeScript("mega_mod/global/" + mod + ".nut");
    }
}