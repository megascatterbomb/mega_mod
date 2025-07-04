const MM_CONFIG_PATH = "mega_mod_config.txt";
::MM_GLOBAL_MODS <- {};
::MM_MAP_MODS <- {};

function MM_SaveConfig() {
	local configString = "globalmods:\n";
	foreach (mod, enabled in MM_GLOBAL_MODS) {
		configString += mod + "=" + enabled + "\n";
	}
	configString += "mapmods:\n";
	foreach (mod, enabled in MM_MAP_MODS) {
		configString += mod + "=" + enabled + "\n";
	}
}

// Loads the config. Initializes any missing settings to enabled.
function MM_LoadConfig() {
	local globalMods = {};
	MM_ALL_GLOBAL_MODS.apply(function(mod) {
		globalMods.append({
			"mod": mod,
			"enabled": true
		});
	});
	local mapMods = {};
	MM_ALL_MAP_MODS.apply(function(mod) {
		mapMods.append({
			"mod": mod,
			"enabled": true
		});
	});
	local configString = FileToString(MM_CONFIG_PATH)

	// Load existing config
	if (!configString) {
		return;
	}
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
				if (settings.rawin(mode)) {
					settings[mode] = enabled;
				} else {
					printl("MEGAMOD: Skipping unknown mod \"" + mod + "\" in config file.");
				}
			} catch (err) {
				printl("MEGAMOD: Skipping malformed config line \"" + line + "\"");
			}
		}
	}

	MM_GLOBAL_MODS <- globalMods;
	MM_MAP_MODS <- mapMods;
}

MM_LoadConfig();
MM_SaveConfig();