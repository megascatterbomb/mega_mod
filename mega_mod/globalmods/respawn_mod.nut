function ShouldApply() {
    local gamemodes = [
        MM_Gamemodes.AD,
        MM_Gamemodes.AD_MS,
        MM_Gamemodes.PL,
        MM_Gamemodes.PL_MS
    ];
    return gamemodes.find(MM_GetGamemode()) != null;
}

function LoadAlongsideMapMods() {
    return false;
}

ApplyMod <- function () {
    local root = getroottable();
    IncludeScript("mega_mod/common/respawn_mod.nut", root);

    this.OnGameEvent_teamplay_round_start <- function (event) {
        if(IsInWaitingForPlayers()) return;
        printl("MEGAMOD: Loading respawn mod...");
        MM_Respawn_Mod(event.full_reset == 1);
    }.bindenv(this);

    local scope = this;
    scope.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
    ::ClearGameEventCallbacks <- function () {
        scope.ClearGameEventCallbacks()
        ::__CollectGameEventCallbacks(scope)
    };

    ::__CollectGameEventCallbacks(this);
}.bindenv(this);


