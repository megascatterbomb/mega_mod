local mapFunctions = {
	["ctf_turbine_winter"] = function() {
		local skin = "" + RandomInt(2, 10);
		local replacement = SpawnEntityFromTable("prop_dynamic",
		{
			model = "models/props_office/officedoor02.mdl"
			origin = "1404 1591.88 -159.75"
			solid = "6",
			disableshadows = "1",
			angles = "0 270 0"
			skin = skin
		})
		replacement.RemoveEFlags(Constants.FEntityEFlags.EFL_DONTBLOCKLOS);
	},
	["plr_hacksaw"] = function() {
		for (local ent = null; ent = Entities.FindByClassname(ent, "func_rotating");) {
			ent.Kill();
		}
	}
}

function ShouldApply() {
	return GetMapName() in mapFunctions;
}

function LoadAlongsideMapMods() {
    return true;
}

ApplyMod <- function () {
    local root = getroottable();

	local execute = mapFunctions[GetMapName()];

    this.OnGameEvent_teamplay_round_start <- function (event) {
        if(event.full_reset == 1) execute();
    }.bindenv(this);

	execute();

    local scope = this;
    scope.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
    ::ClearGameEventCallbacks <- function () {
        scope.ClearGameEventCallbacks()
        ::__CollectGameEventCallbacks(scope)
    };

    ::__CollectGameEventCallbacks(this);
}.bindenv(this);


