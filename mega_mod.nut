// Comment out any maps that you don't want to apply the mods to.

local mods = [
    "arena_perks"
];

local mapName = GetMapName();
local index = mods.find(mapName);

if(index != null) {
    printl("Found mod for " + mapName + ". Attempting to load...");
    IncludeScript("mega_mod/mapmods/" + mapName + ".nut")
} else {
    printl("No mod found for " + mapName + ".");
}