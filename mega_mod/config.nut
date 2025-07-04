const MM_CONFIG_PATH = "mega_mod_config.txt";
::MM_GLOBAL_MODS <- {};
::MM_MAP_MODS <- {};

function MM_ModIsEnabled(mod, isMapMod = false) {

	local mods = MM_GLOBAL_MODS;
	if (isMapMod) {
		mods = MM_MAP_MODS;
	}

	if (mods.rawin(mod)) {
		return mods[mod];
	} else {
		printl("MEGAMOD ERROR: Mod \"" + mod + "\" is not a valid mod.");
		return false;
	}
}

function MM_SaveConfig() {
	local configString = "";
	local globalModLines = [];
	local mapModLines = [];
	foreach (mod, enabled in MM_GLOBAL_MODS) {
		globalModLines.append(mod + "=" + enabled + "\n");
	}
	globalModLines.sort();
	foreach (mod, enabled in MM_MAP_MODS) {
		mapModLines.append(mod + "=" + enabled + "\n");
	}
	mapModLines.sort();

	configString += "globalmods:\n";
	foreach (line in globalModLines) {
		configString += line;
	}
	configString += "mapmods:\n";
	foreach (line in mapModLines) {
		configString += line;
	}

	StringToFile(MM_CONFIG_PATH, configString);
}

// Loads the config. Initializes any missing settings to enabled.
function MM_LoadConfig() {
	local globalMods = {};
	foreach (mod in MM_ALL_GLOBAL_MODS) {
		globalMods.rawset(mod, true);
	};
	local mapMods = {};
	foreach (mod in MM_ALL_MAP_MODS) {
		mapMods.rawset(mod, true);
	};
	local configString = FileToString(MM_CONFIG_PATH)

	// Load existing config
	if (!configString) configString = "";

	local lines = split(configString, "\n")
	local settings = null;
	foreach (line in lines) {
		switch (line) {
				case null:
			continue;
				case "":
			continue;
				case "globalmods:":
			settings = globalMods;
			continue;
				case "mapmods:":
			settings = mapMods;
			continue;
				default:
			if (settings == null) {
				continue;
			}
			try {
				local splitLine = split(line, "=");
				local mod = splitLine[0];
				local enabled = splitLine[1] == "true";

				// All supported mods should be in MM_ALL_GLOBAL_MODS or MM_ALL_MAP_MODS
				// and thus should pass this rawin check.
				if (settings.rawin(mod)) {
					settings[mod] = enabled;
				} else {
					printl("MEGAMOD: Skipping unknown mod \"" + mod + "\" in config file.");
				}
			} catch (err) {
				printl("MEGAMOD: Skipping malformed config line \"" + line + "\"");
			}
		}
	}

	::MM_GLOBAL_MODS <- globalMods;
	::MM_MAP_MODS <- mapMods;
}

MM_LoadConfig();
MM_SaveConfig();