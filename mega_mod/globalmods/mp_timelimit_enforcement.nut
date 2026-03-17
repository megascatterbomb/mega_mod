function ShouldApply() {
    local gamemodes = [
		MM_Gamemodes.CP,
		MM_Gamemodes.TD,
		MM_Gamemodes.VIPR
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
        printl("MEGAMOD: Loading mp_timelimit enforcement mod...");

        MM_CallOnTimelimitExpired(function() {
            ClientPrint(null, 3, "HELLO WORLD :)");
        })
    }.bindenv(this);

    local scope = this;
    scope.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
    ::ClearGameEventCallbacks <- function () {
        scope.ClearGameEventCallbacks()
        ::__CollectGameEventCallbacks(scope)
    };

    ::__CollectGameEventCallbacks(this);
}.bindenv(this);


