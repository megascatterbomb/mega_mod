// Rocket Jump & Bhop fixes inspired by The MGA Rewrite Project https://mgatf.org/ and ported from https://github.com/kiwitf2/kiwimands

::FakeBlastJump <- function(player) { // deals damage to the player with the dmgtype that rockets use to simulate a rocket jump, allowing the user to get mg crits
	local punch = NetProps.GetPropVector(player, "m_Local.m_vecPunchAngle")
	// jesus take the wheel
	player.TakeDamageEx(player, player, null, Vector(), player.GetOrigin(), -0.1, Constants.FDmgType.DMG_BLAST | Constants.FDmgType.DMG_PREVENT_PHYSICS_FORCE)
	NetProps.SetPropVector(self, "m_Local.m_vecPunchAngle", punch)
}

::MM_SoldierMovementThink <- function () {
	local maxP = MaxClients().tointeger();
	for (local i = 1; i <= maxP ; i++) {
		local player = PlayerInstanceFromIndex(i)
		if (player == null
		|| !player.IsAlive()
		|| player.GetPlayerClass() != 3 // TF_CLASS_SOLDIER
		) {
			continue;
		}

		local scope = player.GetScriptScope()
		if (!(player.GetFlags() & Constants.FPlayer.FL_ONGROUND) && Tick() <= scope.rocket_land_tick)
		{
			if (!scope.jumped)
			{
				// printl(Tick().tostring() + " " + (scope.rocket_land_tick).tostring())
				// if(NetProps.GetPropBool(player, "m_Shared.m_bJumping")){
				// 	// bhop_combo += 1
				// 	ClientPrint(player, 3, "Perfomed \"fake\" bhop!")
				// }
				// ClientPrint(player, 3, "Fixing blast jump status!")
				FakeBlastJump(player)
				scope.jumped = true
			}
		}
	}
	return -1
}

function ShouldApply() {
	return true;
}

function LoadAlongsideMapMods() {
	return true;
}

ApplyMod <- function () {
	this.OnGameEvent_teamplay_round_start <- function (event) {
		MM_CreateDummyThink("MM_SoldierMovementThink");
    }.bindenv(this);

	this.OnGameEvent_player_spawn <- function(params) {
		local player = GetPlayerFromUserID(params.userid)
		player.ValidateScriptScope()
		player.GetScriptScope().rocket_land_tick <- 0
		player.GetScriptScope().jumped <- false
	}.bindenv(this);

	this.OnGameEvent_rocket_jump_landed <- function(params) {
		local player = GetPlayerFromUserID(params.userid)
		player.GetScriptScope().rocket_land_tick = Tick()
		player.GetScriptScope().jumped =  false
		// printl("OnGameEvent_rocket_jump_landed @ " + Tick())
		// printl(player.GetVelocity())
	}.bindenv(this);

	local scope = this;
	scope.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
	::ClearGameEventCallbacks <- function () {
		scope.ClearGameEventCallbacks()
		::__CollectGameEventCallbacks(scope)
	};

	::__CollectGameEventCallbacks(this);
}.bindenv(this);