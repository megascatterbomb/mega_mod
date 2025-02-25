function ShouldApply() {
    return MM_GetGamemode() == MM_Gamemodes.CP;
}

function IsGlobal() {
    return false;
}


ApplyMod <- function () {
    local root = getroottable();
    IncludeScript("mega_mod/common/5cp_anti_stalemate.nut", root);

    this.OnGameEvent_teamplay_round_start <- function (event) {
        if(IsInWaitingForPlayers()) return;
        printl("MEGAMOD: Loading 5cp mod...");
        MM_5CP_Activate();
    }.bindenv(this);

    local scope = this;
    scope.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
    ::ClearGameEventCallbacks <- function () {
        scope.ClearGameEventCallbacks();
        ::__CollectGameEventCallbacks(scope)
    };

    ::__CollectGameEventCallbacks(this);
}.bindenv(this);