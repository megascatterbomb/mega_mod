function ShouldApply() {
    return MM_GetGamemode() == MM_Gamemodes.MVM;
}

function LoadAlongsideMapMods() {
    return true;
}

::MM_MVM_HookTankMessages <- function () {
    local path = Entities.FindByClassname(null, "path_track");
    while (path) {
        EntityOutputs.AddOutput(path, "OnPass", "tf_gamerules", "RunScriptCode", "::MM_MVM_HandleTank(activator)", 0, -1)
        path = Entities.FindByClassname(path, "path_track")
    }

    ClientPrint(null, 3, "\x0799CCFF[MM] Tank messages hooked.");
}

::MM_MVM_HandleTank <- function(tank) {
    if (tank.GetClassname() != "tank_boss" || tank.GetScriptScope() != null) {
        printl("Not a tank or already has a scope: " + tank)
        return;
    }
    tank.ValidateScriptScope();
    local tankScope = tank.GetScriptScope();

    tankScope.startHealth <- tank.GetMaxHealth();

    ClientPrint(null, 3, "\x0799CCFFTank spawned with " + tankScope.startHealth.tostring() + " health!");
}


ApplyMod <- function () {
    local root = getroottable();

    this.OnGameEvent_teamplay_round_start <- function (event) {
        EntFire("tf_gamerules", "RunScriptCode", "::MM_MVM_HookTankMessages()", 0, null);
    }.bindenv(this);

    ::MM_MVM_HookTankMessages();

    local scope = this;
    scope.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
    ::ClearGameEventCallbacks <- function () {
        scope.ClearGameEventCallbacks()
        ::__CollectGameEventCallbacks(scope)
    };

    ::__CollectGameEventCallbacks(this);
}.bindenv(this);

