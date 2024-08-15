// Comment out any maps that you don't want to apply the mods to.

local mods = [
    "arena_perks",
    "plr_bananabay",
    "plr_hightower"
];

local mapName = GetMapName();
local index = mods.find(mapName);

if(index != null) {
    printl("MEGAMOD: Loading mega_mod/util.nut...");
    IncludeScript("mega_mod/util.nut")
    printl("MEGAMOD: util.nut started");
    printl("MEGAMOD: Found mod for " + mapName + ". Attempting to load...");
    IncludeScript("mega_mod/mapmods/" + mapName + ".nut")
    printl("MEGAMOD: " + mapName + ".nut started")
} else {
    printl("" + mapName + " is not listed within mega_mod.nut");
}