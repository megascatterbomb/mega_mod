::MM_NoLoudWaterThink <- function ()
{
	local maxP = MaxClients().tointeger();
	for (local i = 1; i <= maxP ; i++) {
		local player = PlayerInstanceFromIndex(i)
		if (player == null
			|| NetProps.GetPropInt(player, "m_lifeState") != 0
			|| !player.IsTaunting()
			|| player.GetWaterLevel() == 0
			|| player.GetPlayerClass() != 5 // TF_CLASS_MEDIC
		) {
			continue;
		}

		for (local scene; scene = Entities.FindByClassname(scene, "instanced_scripted_scene");) {
			local owner = NetProps.GetPropEntity(scene, "m_hOwner")
			if (owner == player) {
				local name = NetProps.GetPropString(scene, "m_szInstanceFilename")
				local medictaunt_name = "taunt09"
				if (name.find(medictaunt_name) != null) {
					printl("MEGAMOD: Detected 'Meet the medic taunt' in water, applying punishment...")
					scene.Kill()
					player.RemoveCond(7)
					player.StunPlayer(3, 1, 2, null)
                    player.SetHealth(1)
				}
			}
		}
	}

	return 0.1
}

function ShouldApply() {
	return true;
}

function LoadAlongsideMapMods() {
	return true;
}

ApplyMod <- function () {
	this.OnGameEvent_teamplay_round_start <- function (event) {
		if(IsInWaitingForPlayers()) return;
		printl("MEGAMOD: Loading jakemod...");
		MM_CreateDummyThink("MM_NoLoudWaterThink");
    }.bindenv(this);

	local scope = this;
	scope.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
	::ClearGameEventCallbacks <- function () {
		scope.ClearGameEventCallbacks()
		::__CollectGameEventCallbacks(scope)
	};

	::__CollectGameEventCallbacks(this);
}.bindenv(this);