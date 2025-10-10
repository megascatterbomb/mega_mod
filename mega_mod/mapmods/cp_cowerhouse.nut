// Credit to Mr. Burguers for figuring out how to inject code into existing VScript scopes.

local root = getroottable()
local prefix = DoUniqueString("mega")
local mega = root[prefix] <- {}

mega.OnGameEvent_teamplay_round_start <- function (event) {
    EntFireByHandle(Entities.FindByClassname(null, "logic_script"), "RunScriptCode", "MegaModRoundStart()", 0, null, null);
}

// Kill a lot of gameplay-irrelevant entities to save edicts.
// Total estimated savings: ~365

::MegaModRoundStart <- function () {
    local killed = 0;

	// VISUAL EFFECTS
	// fire_small_02 (-135)
    local fires = [];
    local fire = Entities.FindByClassname(null, "info_particle_system");
    while(fire != null) {
        if (NetProps.GetPropString(fire, "m_iszEffectName") == "fire_small_02") {
            fires.push(fire);
        }
        fire = Entities.FindByClassname(fire, "info_particle_system");
    }
    foreach (ent in fires) {
        ent.Kill();
        killed++;
    }

	// candle_light1 (-230)
    local candles = [];
    local candle = Entities.FindByClassname(null, "info_particle_system");
    while(candle != null) {
        if (NetProps.GetPropString(candle, "m_iszEffectName") == "candle_light1") {
            candles.push(candle);
        }
        candle = Entities.FindByClassname(candle, "info_particle_system");
    }
    foreach (ent in candles) {
        ent.Kill();
        killed++;
    }

    printl("MEGAMOD: Killed " + killed + " entities.");
}

MegaModRoundStart();

mega.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
::ClearGameEventCallbacks <- function () {
    mega.ClearGameEventCallbacks()
    ::__CollectGameEventCallbacks(mega)
}
::__CollectGameEventCallbacks(mega);