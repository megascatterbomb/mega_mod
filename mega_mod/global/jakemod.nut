::MM_NoLoudWaterThink <- function ()
{
	if (self.IsTaunting())
	{
		for (local scene; scene = Entities.FindByClassname(scene, "instanced_scripted_scene");)
		{
			local owner = NetProps.GetPropEntity(scene, "m_hOwner")
			if (owner == self)
			{
				local name = NetProps.GetPropString(scene, "m_szInstanceFilename")
				local medictaunt_name = "taunt09"
				if (name.find(medictaunt_name) != null && self.GetWaterLevel() != 0)
				{
					printl("MEGAMOD: Detected 'Meet the medic taunt' in water, applying punishment...")
					scene.Kill()
					self.RemoveCond(7)
					self.StunPlayer(3, 1, 2, null)
                    self.SetHealth(1)
				}
			}
		}
	}

	return -1
}

function ShouldApply() {
	return true;
}

function IsGlobal() {
	return true;
}

ApplyMod <- function () {
	this.OnGameEvent_player_spawn <- function (event) {
		local player = GetPlayerFromUserID(event.userid)
		AddThinkToEnt(player, "MM_NoLoudWaterThink")
	}.bindenv(this);
	
	this.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
	::ClearGameEventCallbacks <- function () {
		this.ClearGameEventCallbacks()
		::__CollectGameEventCallbacks(this)
	}.bindenv(this);
	
	::__CollectGameEventCallbacks(this);
}.bindenv(this);