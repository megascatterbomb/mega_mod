special_round <- Ware_SpecialRoundData
({
	name = "What have you done!?"
	author = ["megascatterbomb", "ficool2"]
	description = "Your server admin has gone crazy!"
	category = "meta"
})

scopes <- []

function OnPick()
{
	local categories = clone(Ware_SpecialRoundCategories)
	// don't include ourself...
	if ("meta" in categories)
		delete categories.meta

	local special_rounds = []
	if (Ware_DebugNextSpecialRound2.len() == 0)
	{
		foreach (category, file_names in categories)
		{
			foreach (file_name in file_names)
				special_rounds.append({category = category, file_name = file_name})
		}
	}
	else
	{
        Ware_ChatPrint(null, "There are {str} in Ware_DebugNextSpecialRound2!", Ware_DebugNextSpecialRound2.len());
        foreach (file_name in Ware_DebugNextSpecialRound2) {
            special_rounds.append({category = "none", file_name = file_name})
        }
		Ware_DebugNextSpecialRound2.clear()
	}

    Ware_ChatPrint(null, "There are {str} in special_rounds!", special_rounds.len());

	local picks = [];

	local player_count = Ware_GetValidPlayers().len()

    local special_rounds_count = special_rounds.len();

    for (local round = 1; round <= Min(5, special_rounds_count); round++) {
        local player_count = Ware_GetValidPlayers().len()
        local max_count = Min(16 * round, special_rounds_count)
        for (local i = 0; i <  max_count; i++)
        {
            local pick = RemoveRandomElement(special_rounds)
            local skip = false;
            foreach (p in picks) {
                if (pick.category != "none" && pick.category == p.category) {
                    skip = true;
                }
            }
            if(skip) continue;

            local scope = Ware_LoadSpecialRound(pick.file_name, player_count, false)
            if (scope)
            {
                picks.append(pick);
                scopes.append(scope)
                break
            }
        }
    }

    Ware_ChatPrint(null, "There are {str} in scopes!", scopes.len());

	foreach (callback_name, func in delegated_callbacks)
	{
        foreach (scope in scopes)
        {
            if (callback_name in scope) {
                this[callback_name] <- func.bindenv(this)
                break;
            }
        }
	}
	delete delegated_callbacks

	local data = special_round
    local scope_data = []

    foreach (scope in scopes)
    {
       scope_data.append(scope.special_round)
    }

    foreach (d in scope_data)
    {
        foreach (name, value in d.convars) data.convars[name] <- value
    }

    local default_boss_count = data.boss_count;
    local default_boss_threshold = data.boss_threshold;
    local default_speedup_threshold = data.speedup_threshold;
    local default_pitch_override = data.pitch_override;

	foreach (d in scope_data) {
        // Logical OR assignments
        if (d.reverse_text) data.reverse_text = d.reverse_text;
        if (d.allow_damage) data.allow_damage = true;
        if (d.force_collisions) data.force_collisions = true;
        if (d.opposite_win) data.opposite_win = true;
        if (d.force_pvp_damage) data.force_pvp_damage = true;
        if (d.bonus_points) data.bonus_points = d.bonus_points;

        // Logical AND assignments
        data.friendly_fire = data.friendly_fire && d.friendly_fire;
        data.allow_respawnroom = data.allow_respawnroom && d.allow_respawnroom;

        // Choosing the non-default value
        if (d.boss_count != null && d.boss_count != default_boss_count) data.boss_count = d.boss_count;
        if (d.boss_threshold != null && d.boss_threshold != default_boss_threshold) data.boss_threshold = d.boss_threshold;
        if (d.speedup_threshold != null && d.speedup_threshold != default_speedup_threshold) data.speedup_threshold = d.speedup_threshold;
        if (d.pitch_override != null && d.pitch_override != default_pitch_override) data.pitch_override = d.pitch_override;
    }

	return true
}

function GetName()
{
    local out = format("%s\n", special_round.name)
    foreach (scope in scopes)
    {
        out = format("%s-> %s\n", out, scope.special_round.name)
    }
	return out;
}

// called externally
function IsSet(file_name)
{
    foreach (scope in scopes)
    {
        if (scope.special_round.file_name == file_name)
        {
            return true;
        }
    }
	return false;
}

function OnStartInternal()
{
    foreach(scope in scopes)
    {
        Ware_ChatPrint(null, "{color}{color}{str}{color}! {str}", TF_COLOR_DEFAULT, COLOR_GREEN, scope.special_round.name,
		    TF_COLOR_DEFAULT,  scope.special_round.description)
    }
}

OnStart <- OnStartInternal // might get overriden below

// call the function only if it exists in that scope
local call_failed
function DelegatedCall(scope, name, ...)
{
	call_failed = false
	if (name in scope)
	{
		vargv.insert(0, scope)
		return scope[name].acall(vargv)
	}
	call_failed = true
}

delegated_callbacks <-
{
	function OnStart()
	{
		OnStartInternal()

        foreach(scope in scopes)
        {
            DelegatedCall(scope, "OnStart")
        }
	}

	function OnUpdate()
	{
        foreach(scope in scopes)
        {
            DelegatedCall(scope, "OnUpdate")
        }
	}

	function OnEnd()
	{
        foreach(scope in scopes)
        {
            DelegatedCall(scope, "OnEnd")
        }
	}

	function GetOverlay2()
	{
		// take first valid result
        foreach(scope in scopes)
        {
            local ret = DelegatedCall(scope, "GetOverlay2")
            if (ret != null)
                return ret
        }
		return null
	}

	function GetMinigameName(is_boss)
	{
        foreach(scope in scopes)
        {
            local ret = DelegatedCall(scope, "GetMinigameName", is_boss)
            if (ret != null)
                return ret
        }
		return null;
	}

	function OnMinigameStart()
	{
        foreach(scope in scopes)
        {
            DelegatedCall(scope, "OnMinigameStart")
        }
	}

	function OnMinigameEnd()
	{
        foreach(scope in scopes)
        {
            DelegatedCall(scope, "OnMinigameEnd")
        }
	}

	function OnMinigameCleanup()
	{
        foreach(scope in scopes)
        {
            DelegatedCall(scope, "OnMinigameCleanup")
        }
	}

	function OnBeginIntermission(is_boss)
	{
		// return true if either one wants to override logic
        local ret = false;
        foreach(scope in scopes)
        {
            local ret = DelegatedCall(scope, "OnBeginIntermission", is_boss)
            if (ret)
                ret = true;
                break;
        }

		// for simon special round
        foreach (scope in scopes)
        {
            if (scope.special_round.opposite_win)
                special_round.opposite_win = true;
        }

		return ret;
	}

	function OnSpeedup()
	{
        local ret = false
        foreach (scope in scopes) {
            ret = ret || DelegatedCall(scope, "OnSpeedup")
        }
		return ret
	}

	function OnBeginBoss()
	{
        local ret = false
        foreach (scope in scopes) {
            ret = ret || DelegatedCall(scope, "OnBeginBoss")
        }
		return ret
	}

	function OnCheckGameOver()
	{
        local ret = false;
        foreach (scope in scopes) {
            ret = ret || DelegatedCall(scope, "OnCheckGameOver")
        }
        return ret
	}

	function GetValidPlayers()
	{
        local ret = null;
        foreach (scope in scopes)
        {
            ret = DelegatedCall(scope, "GetValidPlayers")
            if (call_failed) continue;
            return ret
        }
		return ret
	}

	function OnCalculateScore(data)
	{
        local ret = null;
        foreach (scope in scopes)
        {
            ret = DelegatedCall(scope, "OnCalculateScore", data)
            if (call_failed || ret == false) continue;
            return ret
        }
        ret == false
		return ret
	}

	function OnCalculateTopScorers(top_players)
	{
        local ret = null;
        foreach (scope in scopes)
        {
            ret = DelegatedCall(scope, "OnCalculateTopScorers", top_players)
            if (call_failed) continue;
            return ret
        }
        return ret;
	}

	function OnDeclareWinners(top_players, top_score, winner_count)
	{
        local ret = null;
        foreach (scope in scopes)
        {
            ret = DelegatedCall(scope, "OnDeclareWinners", top_players, top_score, winner_count)
            if (call_failed) continue;
            return ret
        }
        return ret;
	}

	function OnPlayerConnect(player)
	{
        foreach(scope in scopes)
        {
            DelegatedCall(scope, "OnPlayerConnect", player)
        }
	}

	function OnPlayerDisconnect(player)
	{
        foreach(scope in scopes)
        {
            DelegatedCall(scope, "OnPlayerDisconnect", player)
        }
	}

	function OnPlayerSpawn(player)
	{
		foreach(scope in scopes)
        {
            DelegatedCall(scope, "OnPlayerSpawn", player)
        }
	}

	function OnPlayerPostSpawn(player)
	{
		foreach(scope in scopes)
        {
            DelegatedCall(scope, "OnPlayerPostSpawn", player)
        }
	}

	function OnPlayerInventory(player)
	{
		foreach(scope in scopes)
        {
            DelegatedCall(scope, "OnPlayerInventory", player)
        }
	}

	function OnPlayerVoiceline(player, name)
	{
		foreach(scope in scopes)
        {
            DelegatedCall(scope, "OnPlayerVoiceline", player, name)
        }
	}

	function OnPlayerTouch(player, other_player)
	{
		foreach(scope in scopes)
        {
            DelegatedCall(scope, "OnPlayerTouch", player, other_player)
        }
	}

	function GetPlayerRoll(player)
	{
        local ret = null;
        foreach (scope in scopes)
        {
            ret = DelegatedCall(scope, "GetPlayerRoll", player)
            if (call_failed) continue;
            return ret
        }
		return ret
	}

	function CanPlayerRespawn(player)
	{
		// only respawn if all agree
		// if the function doesn't exist then assume it's allowed
        local return_value = true;
        foreach(scope in scopes)
        {
            local ret = DelegatedCall(scope, "CanPlayerRespawn", player)
            if (call_failed) continue;
            if (ret == false)
                return_value = false
        }
		return return_value;
	}

	function OnTakeDamage(params)
	{
		// cancel damage if either one explicitly returns false
        local return_value = true;
        foreach(scope in scopes)
        {
            local ret = DelegatedCall(scope, "OnTakeDamage", params)
            if (ret == false)
                return_value = false
        }
		return return_value;
	}
}