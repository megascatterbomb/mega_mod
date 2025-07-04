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

::MM_Gamemodes <- {
    UNKNOWN = null,
    ARENA = "arena",
    AD = "cp_ad" ,
    AD_MS = "cp_ad_ms",
    CTF =  "ctf",
    CP = "5cp",
    KOTH = "koth",
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
    TOW = "tow",
    VSH = "vsh",
    ZI = "zi"
    VIP = "vip"
}

function MM_GetGamemode() {
    local mapName = GetMapName();
    local overrides = {
        "ctf_haarp": MM_Gamemodes.AD_MS
    };

    if(mapName in overrides) {
        return overrides[mapName];
    }

    if (startswith(mapName, "workshop/")) {
        mapName = mapName.slice(9);
    }

    local mapPrefix = mapName.slice(0, mapName.find("_"));

    switch (mapPrefix) {
        case "arena":
            return MM_Gamemodes.ARENA;
        case "cp":
            return MM_Gamemode_CheckCPGamemode();
        case "ctf":
            return MM_Gamemode_CheckForMannpower();
        case "koth":
            return MM_Gamemodes.KOTH;
        case "pl":
            return MM_Gamemode_CheckIfMultiStage() ? MM_Gamemodes.PL_MS : MM_Gamemodes.PL;
        case "plr":
            return MM_Gamemode_CheckIfMultiStage() ? MM_Gamemodes.PLR_MS : MM_Gamemodes.PLR;
        case "pass":
            return MM_Gamemodes.PASS;
        case "sd":
            return MM_Gamemodes.SD;
        case "rd":
            return MM_Gamemodes.RD;
        case "pd":
            return MM_Gamemodes.PD;
        case "tc":
            return MM_Gamemodes.TC;
        case "mvm":
            return MM_Gamemodes.MVM;
        case "tow":
            return MM_Gamemodes.TOW;
        case "vsh":
            return MM_Gamemodes.VSH;
        case "zi":
            return MM_Gamemodes.ZI;
        case "vip":
            return MM_Gamemodes.VIP;
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
        printl("MEGAMOD ERROR: Global mod '" + mod + "' errored when loading! Have you implemented the required functions?");
    }
}
