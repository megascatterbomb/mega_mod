function ShouldApply() {
    return MM_GetGamemode() == MM_Gamemodes.MVM;
}

function LoadAlongsideMapMods() {
    return true;
}

::MM_MVM_PLAYERS_ON_RED <- 0;

::MM_MVM_UpdatePlayersOnRed <- function () {
    local oldValue = ::MM_MVM_PLAYERS_ON_RED;
    local newValue = 0;

    local maxPlayers = MaxClients().tointeger();

    for (local i = 1; i <= maxPlayers ; i++)
    {
        local player = PlayerInstanceFromIndex(i)
        if (player == null) continue;
        if (player.GetTeam() == 2) newValue++;
    }

    if (oldValue == newValue || (oldValue <= 6 && newValue <= 6)) return;

    ::MM_MVM_PLAYERS_ON_RED = newValue;
    local healthRatio = newValue / 6.0;

    if(healthRatio < 1.0) healthRatio = 1.0;

    Convars.SetValue("tf_populator_health_multiplier", healthRatio);
    // OBSOLETE: tf_populator_health_multiplier accounts for this.
    // if (Convars.GetFloat("sig_mvm_robot_multiplier_tank_hp") != null) {
    //     Convars.SetValue("sig_mvm_robot_multiplier_tank_hp", healthRatio);
    // }

    local healthRatioInt = floor(healthRatio * 100);
    ClientPrint(null, 3, "\x0799CCFFRobots and Tanks spawn with " + healthRatioInt + "% HP as there are " + newValue + " players on RED.");
}


ApplyMod <- function () {
    local root = getroottable();

    this.OnGameEvent_teamplay_round_start <- function (event) {
        EntFire("tf_gamerules", "RunScriptCode", "::MM_MVM_UpdatePlayersOnRed()", 0, null);
    }.bindenv(this);

    this.OnGameEvent_player_spawn <- function (event) {
        EntFire("tf_gamerules", "RunScriptCode", "::MM_MVM_UpdatePlayersOnRed()", 0, null);
    }.bindenv(this);

    this.OnGameEvent_player_team <- function (event) {
        EntFire("tf_gamerules", "RunScriptCode", "::MM_MVM_UpdatePlayersOnRed()", 0, null);
    }.bindenv(this);

    this.OnGameEvent_player_disconnect <- function (event) {
        EntFire("tf_gamerules", "RunScriptCode", "::MM_MVM_UpdatePlayersOnRed()", 0, null);
    }.bindenv(this);

    local scope = this;
    scope.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
    ::ClearGameEventCallbacks <- function () {
        scope.ClearGameEventCallbacks()
        ::__CollectGameEventCallbacks(scope)
    };

    ::__CollectGameEventCallbacks(this);
}.bindenv(this);

