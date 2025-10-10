// Credit to Mr. Burguers for figuring out how to inject code into existing VScript scopes.

local root = getroottable();
local prefix = DoUniqueString("mega");
local mega = root[prefix] <- {};

mega.OnGameEvent_teamplay_round_start <- function (event) {
    printl("MEGAMOD: Loading custom pass_jerma logic...");

	local nullFunc = function(a) {};

	local scriptEntity = null;

	while (scriptEntity == null || !scriptEntity.GetScriptScope().rawin("processWeapon"))
	{
		scriptEntity = Entities.FindByClassname(scriptEntity, "logic_script");
	}

	// get the logic_script with vehicle_events.nut
	local scriptScope = scriptEntity.GetScriptScope();

	scriptScope.Vehicle_OnPlayerSpawn <- nullFunc;
	scriptScope.Vehicle_OnPlayerDeath <- nullFunc;
	scriptScope.Vehicle_OnPlayerDisconnect <- nullFunc;
	scriptScope.Vehicle_OnRoundReset <- nullFunc;
	scriptScope.Vehicle_OnTakeDamage <- nullFunc;
	::PlayerThink <- function() {};
}

mega.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
::ClearGameEventCallbacks <- function () {
    mega.ClearGameEventCallbacks()
    ::__CollectGameEventCallbacks(mega)
}
::__CollectGameEventCallbacks(mega);