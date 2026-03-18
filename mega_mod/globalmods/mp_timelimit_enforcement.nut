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

        // Cut off all inputs to team_round_timer from these entities.
        MM_CallOnTimelimitExpired(function() {
            local outputsToRemove = {
                "OnCapTeam1": "team_control_point"
                "OnCapTeam2": "team_control_point"
                "OnCapTeam1": "trigger_capture_area"
                "OnCapTeam2": "trigger_capture_area"
                "OnTrigger": "logic_relay"
            };
            foreach (outputName, className in outputsToRemove) {
            	for (local ent = null; ent = Entities.FindByClassname(ent, className);) {
            		local outputs = [];
            		local outputCount = EntityOutputs.GetNumElements(ent, outputName);
            		for (local i = outputCount - 1; i >= 0; i--) {
            			local table = {}
            			EntityOutputs.GetOutputTable(ent, outputName, table, i);
            			outputs.append(table)
            		}
                    foreach (output in outputs) {
                        if (output.target == "team_round_timer" || output.target == "timer_round") {
                            EntityOutputs.RemoveOutput(ent, outputName, output.target, output.input, output.parameter);
                        }
                    }
                }
            }
            ClientPrint(null, 3, "\x07FCD303Map timelimit has expired, no more time will be added!");
        }
    )}.bindenv(this);

    local scope = this;
    scope.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
    ::ClearGameEventCallbacks <- function () {
        scope.ClearGameEventCallbacks()
        ::__CollectGameEventCallbacks(scope)
    };

    ::__CollectGameEventCallbacks(this);
}.bindenv(this);


