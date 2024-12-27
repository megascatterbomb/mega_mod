// Comment out any maps that you don't want to apply the mods to.

local mods = [
    "arena_perks"
    "cp_freaky_fair"
    "cp_standin_final"
    "koth_lakeside_event"
    "koth_viaduct_event"
    "pl_bloodwater"
    "pl_emerge"
    "plr_bananabay"
    "plr_cutter"
    "plr_hacksaw"
    "plr_hacksaw_event"
    "plr_hightower"
    "plr_hightower_event"
    "plr_nightfall_final"
    "plr_pipeline"

    // Support for updated versions of workshop maps is not guaranteed
    "workshop/pl_cactuscanyon_redux_final2.ugc2579644293"
    "workshop/plr_highertower.ugc899335714"
];

local mapName = GetMapName();
local mapModIndex = mods.find(mapName);
local hasMapMod = mapModIndex != null;

// These are loaded unless there's a map specific mod.
// To create a global mod: create a file in mega_mod/global/ with the name of the mod.
// Implement these functions:
// function ShouldApply() // Return true if the mod should be applied, false if not.
// function IsGlobal() // Return true if the mod should be applied even if there's a map specific mod.
// function ApplyMod() // Apply the mod.
// Remember to bind the functions to their scopes, otherwise things might not work as expected!
local globalMods = [
    "5cp_anti_stalemate"
    "respawn_mod"
    "zi_mod"
    "jakemod"
];

// You should not have to touch anything below this point.

printl("MEGAMOD: Loading mega_mod/util.nut...");
IncludeScript("mega_mod/util.nut")
printl("MEGAMOD: util.nut started");

if(hasMapMod) {
    printl("MEGAMOD: Found mod for " + mapName + ". Attempting to load...");
    IncludeScript("mega_mod/mapmods/" + mapName + ".nut")
    printl("MEGAMOD: " + mapName + ".nut started")
} else {
    printl("MEGAMOD: " + mapName + " is not listed within mega_mod.nut.");
}

printl("MEGAMOD: Loading global mods...");

local root = getroottable();

foreach(mod in globalMods) {
    local prefix = DoUniqueString(mod);
    local modTable = root[prefix] <- {};
    try {
        IncludeScript("mega_mod/global/" + mod + ".nut", modTable);
    } catch (e) {
        printl("MEGAMOD ERROR: Global mod '" + mod + "' does not exist!");
        continue;
    }
    try {
        if(modTable.ShouldApply() && (!hasMapMod || modTable.IsGlobal())) {
            printl("MEGAMOD: Loading global mod '" + mod + "'...");
            modTable.ApplyMod();
            printl("MEGAMOD: Loaded global mod '" + mod + "'");
        } else {
            // printl("MEGAMOD: Skipping global mod '" + mod + "'...");
        }
    } catch (e) {
        printl("MEGAMOD ERROR: Global mod '" + mod + "' has not implemented the required functions!");
    }
}
