const GAMEMODE_PREFIX = "gamemode_";

function ShouldApply() {
    return true;
}

function LoadAlongsideMapMods() {
    return true;
}

::ExecGamemodeConfig <- function (gamemode) {
    local gamemodeConfig = GAMEMODE_PREFIX + gamemode.tostring() + ".cfg";
    printl("MEGAMOD: Executing gamemode config: " + gamemodeConfig);
    SendToServerConsole("exec " + gamemodeConfig);

    local mapName = GetMapName();
    local mapConfig = mapName + ".cfg";

    printl("MEGAMOD: Executing map specific config: " + mapConfig);
    SendToServerConsole("exec " + mapConfig);
}

::FullGamemodeExec <- function () {
    local gamemode = MM_GetGamemode();

    if (gamemode == null) {
        printl("MEGAMOD ERROR: Could not identify gamemode. Skipping gamemode config execution.");
        return;
    }

    local gamemodeConfig = GAMEMODE_PREFIX + gamemode.tostring() + ".cfg";
    printl("MEGAMOD: Gamemode identified: " + gamemode);

    // For this to work, allow sv_allow_point_servercommand in your cfg/vscript_convar_allowlist.txt
    // This plugin will set it to always for a single tick so it can execute the config, which will protect
    // against *some* malicious maps, but not against malicious vscript!

    if (Convars.GetStr("sv_allow_point_servercommand") != "always" && !Convars.IsConVarOnAllowList("sv_allow_point_servercommand")) {
        // bail out
        printl("MEGAMOD ERROR: sv_allow_point_servercommand is not set to 'always' and is not in the allow list. Skipping gamemode config execution.");
    } else if (Convars.GetStr("sv_allow_point_servercommand") != "always") {
        local oldValue = Convars.GetStr("sv_allow_point_servercommand");
        Convars.SetValue("sv_allow_point_servercommand", "always");
        ExecGamemodeConfig(gamemode);
        Convars.SetValue("sv_allow_point_servercommand", oldValue);
    } else {
        ExecGamemodeConfig(gamemode);
    }
}

ApplyMod <- function () {
    EntFire("tf_gamerules", "CallScriptFunction", "FullGamemodeExec", 0)
}.bindenv(this);