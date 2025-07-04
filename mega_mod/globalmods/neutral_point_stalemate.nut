function ShouldApply() {
    return MM_GetGamemode() == MM_Gamemodes.KOTH ||
           MM_GetGamemode() == MM_Gamemodes.CP;
}

function LoadAlongsideMapMods() {
    return true;
}

ApplyMod <- function () {
    this.OnGameEvent_teamplay_round_start <- function (event) {
        if(IsInWaitingForPlayers()) return;
        printl("MEGAMOD: Loading neutral stalemate mod...");
        IncludeScript("mega_mod/common/neutral_point_stalemate.nut");
    }.bindenv(this);

    local scope = this;
    scope.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
    ::ClearGameEventCallbacks <- function () {
        scope.ClearGameEventCallbacks();
        ::__CollectGameEventCallbacks(scope)
    };

    ::__CollectGameEventCallbacks(this);
}.bindenv(this);