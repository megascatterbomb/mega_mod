// We did it Grommit! We saved the cheese!
// Renamed to _example after https://github.com/ficool2/TF2Ware_Ultimate/pull/182 was merged, since it isn't needed anymore, but serves
// as a good example for how overriding values in minigames could go.

IncludeScript("tf2ware_ultimate/minigames/taunt_kill.nut")

ITEM_MAP["Taunt: Texan Trickshot"] <-
{
    id = 31520
    classname = "tf_weapon_revolver"
}

// OVERRIDE: tf2ware_ultimate/minigames/taunt_kill.nut::OnStart
function OnStart()
{
	local loadouts =
	[
		[ TF_CLASS_SCOUT,        "Sandman"          	  , @(player) SuicideLine(player, 64.0)    ],
		[ TF_CLASS_SOLDIER,      "Equalizer"        	  , @(player) SuicideSphere(player, 100.0) ],
		[ TF_CLASS_PYRO,         "Flare Gun"        	  , @(player) SuicideLine(player, 64.0)    ],
		[ TF_CLASS_PYRO,         "Rainblower"       	  , @(player) SuicideSphere(player, 100.0) ],
		[ TF_CLASS_PYRO,         "Scorch Shot"      	  , @(player) SuicideLine(player, 128.0)   ],
		[ TF_CLASS_DEMOMAN,      "Eyelander"        	  , @(player) SuicideLine(player, 128.0)   ],
		[ TF_CLASS_HEAVYWEAPONS, "Fists"            	  , @(player) SuicideLine(player, 500.0)   ],
		[ TF_CLASS_ENGINEER,     "Frontier Justice" 	  , @(player) SuicideLine(player, 128.0)   ],
		[ TF_CLASS_ENGINEER,     "Taunt: Texan Trickshot" , @(player) SuicideLine(player, 500.0)   ],
		[ TF_CLASS_ENGINEER,     "Gunslinger"       	  , @(player) SuicideLine(player, 128.0)   ],
		[ TF_CLASS_MEDIC,        "Ubersaw"          	  , @(player) SuicideLine(player, 128.0)   ],
		[ TF_CLASS_SNIPER,       "Huntsman"         	  , @(player) SuicideLine(player, 128.0)   ],
		[ TF_CLASS_SPY,          "Knife"            	  , @(player) SuicideLine(player, 64.0)    ],
	]
	local loadout = RandomElement(loadouts)

	Ware_SetGlobalLoadout(loadout[0], loadout[1])
	Ware_SetGlobalAttribute("no_attack", 1, -1)

	// simple anti-griefing
	suicide_callback = loadout[2]
}