local root = getroottable();
local prefix = DoUniqueString("jake_mod");
local jake_mod = root[prefix] <- {};

function NoLoudWaterThink()
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
					scene.Kill()
					self.RemoveCond(7)
					self.StunPlayer(3, 1, 2, null)
                    self.SetHealth(1)
                    self.AddCustomAttribute("max health additive penalty", -149, 10)
				}
			}
		}
	}

	return -1
}


jake_mod.OnGameEvent_player_spawn <- function (event) {
    local player = GetPlayerFromUserID(event.userid)
    AddThinkToEnt(player, "NoLoudWaterThink")
}

jake_mod.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
::ClearGameEventCallbacks <- function () {
    jake_mod.ClearGameEventCallbacks()
    ::__CollectGameEventCallbacks(jake_mod)
}

::__CollectGameEventCallbacks(jake_mod);