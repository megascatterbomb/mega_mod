function ShouldApply() {
    return MM_GetGamemode() == MM_Gamemodes.MVM;
}

function LoadAlongsideMapMods() {
    return true;
}

local configPath = "mega_mod_mvm_max_defenders.txt"

::MM_MVM_CurrentPopfile <- null;
::MM_MVM_DefendersConfig <- {};

::MM_MVM_LoadDefendersConfig <- function() {
    local configString = FileToString(configPath)
	if (!configString) configString = "";

    local defendersConfig = {};

	local lines = split(configString, "\n")
	foreach (line in lines) {
		switch (line) {
			case null:
				continue;
			case "":
				continue;
		}
        try {
            local splitLine = split(line, "=");
            local mission = splitLine[0];
            local maxDefenders = splitLine[1].tointeger();

            defendersConfig[mission] <- maxDefenders;
        } catch (err) {
            printl("MEGAMOD: MVM Max Defenders: Skipping malformed config line \"" + line + "\"");
        }
	}

    ::MM_MVM_DefendersConfig = defendersConfig;
}

::MM_MVM_CheckMaxDefenders <- function() {
    local objectiveResource = Entities.FindByClassname(null, "tf_objective_resource");
    local currentPopfile = NetProps.GetPropString(objectiveResource, "m_iszMvMPopfileName");

    // converts "scripts/population/mvm_decoy_advanced3.pop" to "mvm_decoy_advanced3"
    if (startswith(currentPopfile, "scripts/population/")) currentPopfile = currentPopfile.slice(19);
    if (endswith(currentPopfile, ".pop")) currentPopfile = currentPopfile.slice(0, currentPopfile.len() - 4);

    local maxDefenders = 6;

    if(::MM_MVM_DefendersConfig.rawin(currentPopfile)) {
        maxDefenders = MM_MVM_DefendersConfig[currentPopfile];
    }

    printl("MEGAMOD: Max defenders for " + currentPopfile + " is " + maxDefenders)

    Convars.SetValue("tf_mvm_defenders_team_size", maxDefenders);
}

ApplyMod <- function () {
    local root = getroottable();

    MM_MVM_LoadDefendersConfig();

    this.OnGameEvent_teamplay_round_start <- function (event) {
        EntFire("tf_gamerules", "RunScriptCode", "::MM_MVM_CheckMaxDefenders()", 0, null);
    }.bindenv(this);

    ::MM_MVM_CheckMaxDefenders();

    local scope = this;
    scope.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
    ::ClearGameEventCallbacks <- function () {
        scope.ClearGameEventCallbacks()
        ::__CollectGameEventCallbacks(scope)
    };

    ::__CollectGameEventCallbacks(this);
}.bindenv(this);