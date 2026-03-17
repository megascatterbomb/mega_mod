// Functions in this file are always loaded into the root scope.

function MM_GetEntByName(name) {
    return Entities.FindByName(null, name);
}

function MM_GetEntArrayByName(name) {
    local ents = [];
    local ent = Entities.FindByName(null, name);
    while(ent != null) {
        ents.push(ent);
        ent = Entities.FindByName(ent, name);
    }
    return ents;
}

// Entity optimization
function MM_KillAllByName(name) {
    local killed = 0;
    local ents = MM_GetEntArrayByName(name);
    foreach (ent in ents) {
        ent.Kill();
        killed++;
    }
    return killed;
}

function MM_KillAllButOneByName(name) {
    local killed = 0;
    local ents = MM_GetEntArrayByName(name);
    local skip = true;
    foreach (ent in ents) {
        if(!skip && ent) {
            ent.Kill();
            killed++;
        }
        skip = false;
    }
    return killed;
}

// Create thinks that aren't attached to any particular entity
function MM_CreateDummyThink(funcName) {
    local relay = Entities.CreateByClassname("logic_relay");
    AddThinkToEnt(relay, funcName);
}

function MM_GetTickCount() { // ticks since server start
	// netprop exists on tf_player_manager and tf_player_manager always exists
	return NetProps.GetPropInt(Entities.FindByClassname(null, "tf_player_manager"), "m_nSimulationTick")
}

function MM_GetCapAreaByPoint(cp) {
	for (local area = null; area = Entities.FindByClassname(area, "trigger_capture_area");) {
		if (NetProps.GetPropString(area, "m_iszCapPointName") == cp.GetName()) {
			return area;
		}
	}
	return null;
}

// TODO: how to account for TF2C's bullshit?
function MM_GetTimelimitRemaining() { // Seconds
    local gamerules = Gamerules();
    local mp_timelimit = Convars.GetInt("mp_timelimit");

    if (mp_timelimit != null && mp_timelimit > 0) {
        local remainingTime = (mp_timelimit * 60) - (Time() - NetProps.GetPropFloat(gamerules, "m_flMapResetTime"));
        return remainingTime;
    }
    return null;
}

function MM_IsTimelimitExpired() {
    local remainingTime = MM_GetTimelimitRemaining();
    return remainingTime == null ? false : remainingTime <= 0;
}

function MM_CallOnTimelimitExpired(func) {
    local f = UniqueString("MP_TIMELIMIT_EXPIREFUNC");
    local g = UniqueString("MP_TIMELIMIT_EXPIREGATE");
    local root = getroottable();
    root[f] <- function() {
        ClientPrint(null, 3, "THINKING " + root[g]);
        if (root[g]) return 2147483647; // INT_MAX
        if (!MM_IsTimelimitExpired()) return 1;
        root[g] <- true;
        func();
    };
    root[g] <- false;
    MM_CreateDummyThink(f);
}

function Gamerules() {
    return Entities.FindByClassname(null, "tf_gamerules");
}


::MM_Gamemodes <- {
    UNKNOWN = null,
    ARENA = "arena",
    AD = "cp_ad" ,
    AD_MS = "cp_ad_ms",
    CTF =  "ctf",
    CP = "5cp",
    CPPL = "cppl",
    KOTH = "koth",
    TWOKOTH = "2koth",
    PL = "pl",
    PL_MS = "pl_ms",
    PLR = "plr",
    PLR_MS = "plr_ms",
    PASS = "pass",
    SD = "sd",
    RD =  "rd",
    PD = "pd",
    TC = "tc",
    MVM = "mvm",
    MP = "mannpower",
    HTF = "htf"
    TOW = "tow",
    VSH = "vsh",
    ZI = "zi",

    // TF2 Classified
    TD = "td",
    DOM = "dom",
    VIP = "vip",
    VIPR = "vipr",
    ARENA_4TEAM = "4arena",
    CTF_4TEAM = "4ctf"
    DOM_4TEAM = "4dom",
    KOTH_4TEAM = "4koth",
    PLR_4TEAM = "4plr"
}

function MM_GetGamemode() {
    local mapName = GetMapName();
    local overrides = {
        "ctf_haarp": MM_Gamemodes.AD_MS,
        "ctf_4fort_final": MM_Gamemodes.CTF_4TEAM,
        "ctf_4bine_v2": MM_Gamemodes.CTF_4TEAM
    };

    if(mapName in overrides) {
        return overrides[mapName];
    }

    if (startswith(mapName, "workshop/")) {
        mapName = mapName.slice(9);
    }

    local mapPrefix = mapName.slice(0, mapName.find("_"));

    switch (mapPrefix) {
        case "cp":
            return MM_Gamemode_CheckCPGamemode();
        case "ctf":
            return MM_Gamemode_CheckForMannpower();
        case "pl":
            return MM_Gamemode_CheckIfMultiStage() ? MM_Gamemodes.PL_MS : MM_Gamemodes.PL;
        case "plr":
            return MM_Gamemode_CheckIfMultiStage() ? MM_Gamemodes.PLR_MS : MM_Gamemodes.PLR;
        default:
            foreach (name, value in MM_Gamemodes) {
                if (value == mapPrefix)
                    return value;
            }
        }

    return MM_Gamemodes.UNKNOWN;
}

function MM_Gamemode_CheckCPGamemode() {
    local countNeutral = 0;
    local countRed = 0;
    local countBlu = 0

    for (local cp = null; cp = Entities.FindByClassname(cp, "team_control_point");) {
        local owner = NetProps.GetPropInt(cp, "m_iDefaultOwner");
        switch (owner) {
            case 0:
                countNeutral++;
                break;
            case 2:
                countRed++;
                break;
            case 3:
                countBlu++;
                break;
        }
    }

    // Check for 3CP or 5CP by looking at default owners of control points.
    if (countRed == countBlu && countNeutral >= 1) {
        return MM_Gamemodes.CP;
    }
    return MM_Gamemode_CheckIfMultiStage() ? MM_Gamemodes.AD_MS : MM_Gamemodes.AD;
}

function MM_Gamemode_CheckForMannpower() {
    local powerups = Entities.FindByClassname(null, "tf_logic_mannpower");
    if(powerups != null) {
        return MM_Gamemodes.MP;
    }
    return MM_Gamemodes.CTF;
}

function MM_Gamemode_CheckIfMultiStage() {
    local rounds = 0;
    local round = Entities.FindByClassname(null, "team_control_point_round");
    while(round != null) {
        rounds++;
        round = Entities.FindByClassname(round, "team_control_point_round");
    }
    return rounds > 1;
}

// hasMapMod == true: Mod is loaded if both ShouldApply() and LoadAlongsideMapMods() returns true
// hasMapMod == false: Mod is loaded if ShouldApply() returns true
// hasMapMod == null: Mod is always loaded
function MM_IncludeGlobalMod(mod, hasMapMod = null) {
    local root = getroottable();
    local prefix = DoUniqueString(mod);
    local modTable = root[prefix] <- {};
    try {
        IncludeScript("mega_mod/globalmods/" + mod + ".nut", modTable);
    } catch (e) {
        printl("MEGAMOD ERROR: Global mod '" + mod + "' does not exist!");
        return;
    }
    try {
        if((hasMapMod == null || modTable.ShouldApply()) && (!hasMapMod || modTable.LoadAlongsideMapMods())) {
            printl("MEGAMOD: Loading global mod '" + mod + "'...");
            modTable.ApplyMod();
            printl("MEGAMOD: Loaded global mod '" + mod + "'");
        } else {
            // printl("MEGAMOD: Skipping global mod '" + mod + "'...");
        }
    } catch (e) {
        printl("MEGAMOD ERROR: Global mod '" + mod + "' errored when loading! Error:\n" + e);
    }
}
