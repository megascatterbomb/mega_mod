// OVERRIDE: tf2ware_ultimate/specialrounds/double_trouble.nut
// This entire file is based on the original double_trouble special round.
// Modifications are tagged with MEGAMOD

// MEGAMOD: Update metadata and credits.
special_round <- Ware_SpecialRoundData
({
	name = "What have you done!?"
	author = ["megascatterbomb", "ficool2"]
	description = "Multiple special rounds will be stacked together!"
	category = "meta"
})

// MEGAMOD: Table of incompatible special rounds.
// Special rounds that share a category cannot be loaded together.
// Special rounds with "unique" cannot be loaded via double_trouble at all
// Special rounds with "first" must be the first loaded special round.
special_round_categories <- {
    "adrenaline_shot": ["timescale"],
    "all_in": ["scores"],
    "bonk": ["weapon"],
    "boss_rush": ["unique"], // incompatible with double_trouble
    "cocanium": ["overlay"],
    "collisions": ["collisions"],
    "cramped_quarters": ["collisions"],
    "double_trouble": ["unique"], // would be more catastrophic than average valve update
    "extended_round": ["boss_threshold"]
    "hale": ["weapon"],
    "math_only": ["text"], // this one sucks enough as-is
    "merasmus": ["winners"],
    "mirrored_world": ["overlay"],
    "no_text": ["text"],
    "non_stop": ["unique"], // incompatible with double_trouble
    "nostalgia": ["overlay"],
    "opposite_day": ["scores"],
    "random_score": ["scores", "first"],
    "reversed_text": ["text"],
    "slow_mo": ["timescale", "boss_threshold"],
    "speedrun": ["timescale"],
    "sudden_death": ["scores"],
    "swap_madness": ["teleport"],
    "team_battles": ["scores", "winners"],
    "time_attack": ["timescale"],
    "two_bosses": ["bosses"],
    "up_down": ["timescale", "first"],
    "wipeout": ["unique"] // incompatible with double_trouble
}

// MEGAMOD: Table of special round requirement checks.
special_round_requirements <- {
    "collisions": function (player_count)
    {
        return player_count >= 2 && player_count <= 40;
    },
    "cramped_quarters": function (player_count)
    {
        return player_count >= 2;
    },
    "singleplayer": function (player_count)
    {
        return player_count >= 2;
    },
    "speedrun": function (player_count)
    {
        return player_count <= 40;
    },
    "squid_game": function (player_count)
    {
        return player_count >= 2;
    },
    "sudden_death": function (player_count)
    {
        return player_count >= 3;
    },
    "swap_madness": function (player_count)
    {
        return player_count >= 2;
    },
    "team_battles": function (player_count)
    {
        return player_count >= 4;
    },
    "wipeout": function (player_count)
    {
        return player_count >= 3;
    },
}

scopes <- []

// OVERRIDE: tf2ware_ultimate/specialrounds/double_trouble.nut::OnPick
function OnPick()
{
	printl("MEGAMOD: Loading custom double_trouble logic...");

    // MEGAMOD: Completely rewrote the logic for picking special rounds.
	local random = true;
	local special_rounds = [];

    local special_rounds_to_pick = RandomInt(2, 5);

	if (Ware_DebugNextSpecialRound2.len() == 0)
	{
		foreach (file_name in Ware_SpecialRounds)
		{
			special_rounds.append(file_name)
		}
	}
	else
	{
		foreach (file_name in Ware_DebugNextSpecialRound2) {
			special_rounds.append(file_name)
		}
        special_rounds_to_pick = Min(5, Ware_DebugNextSpecialRound2.len());
		Ware_DebugNextSpecialRound2.clear()
		random = false;
	}

	local picks = [];
	local selected_rounds = [];
	local selected_categories = [];

	local player_count = Ware_GetValidPlayers().len()

	for (local round = 1; round <= special_rounds_to_pick; round++) {
		while (special_rounds.len() > 0)
		{
			local pick;
			if(random) {
				pick = RemoveRandomElement(special_rounds)
			} else {
				pick = special_rounds.remove(0)
			}
			local skip = false;

            // Duplicate check.
            foreach (p in selected_rounds) {
                if (p == pick) {
                    skip = true;
                    break;
                }
            }

            // Category check
			if (special_round_categories.rawin(pick)) {
                if (special_round_categories[pick].find("unique") != null) {
                    skip = true; // we can't load "unique" special rounds with double_trouble
                }
                foreach (category in special_round_categories[pick]) {
                    if (selected_categories.find(category) != null) {
                        skip = true;
                        break;
                    }
                }
			}

            if(skip) {
                if (!random) { // manually selected round is incompatible.
                    Ware_Error("Not loading '%s' as it is incompatible with other selected special rounds.", pick);
                }
                continue;
            }

            // Requirements check. We don't want Ware_LoadSpecialRound to handle requirements because we
            // need the ability to re-arrange load order after selecting the special rounds.
            if (special_round_requirements.rawin(pick) && !special_round_requirements[pick](player_count)) {
                continue;
            }

            selected_rounds.append(pick)

            // Track categories we've selected
            if (special_round_categories.rawin(pick)) {
                foreach (category in special_round_categories[pick]) {
                    selected_categories.append(category);
                }
            }

            break;
        }
        if (random) { // repopulate special_rounds so we don't run out.
            special_rounds.clear()
            foreach (file_name in Ware_SpecialRounds)
            {
                special_rounds.append(file_name)
            }
        }
    }

    // Check for a special round that needs to be first.
    // There can only be one because "first" protects against dupes like any other category.
    for (local i = 0; i < selected_rounds.len(); i++) {
        local pick = selected_rounds[i];
        if (i > 0 && special_round_categories.rawin(pick) && special_round_categories[pick].find("first") != null) {
            special_rounds.remove(i);
            selected_rounds.insert(0, pick);
            break;
        }
    }

    // Theoretically none of these should fail because we already checked requirements.
    foreach (pick in selected_rounds) {
        local scope = Ware_LoadSpecialRound(pick, player_count, false)
        if (scope)
        {
            picks.append({file_name = pick, category = "none"});
            scopes.append(scope);
        }
    }

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

    // Update special round name and description based on the number of specials we're loading.
    switch (scopes.len()) {
    case 0: // In case ALL special rounds fail to load for some reason.
        special_round.name = "404 Not Found";
        special_round.description = "We tried to load a special round but failed spectacularly!";
        return false;
    case 1: // In case other special rounds fail to load for some reason.
        special_round.name = scopes[0].special_round.name;
        special_round.description = scopes[0].special_round.description;
        break;
    case 2:
        special_round.name = "Double Trouble";
        special_round.description = "Two special rounds will be stacked together!"
        break;
    case 3:
        special_round.name = "Oh Baby a Triple!";
        special_round.description = "Three special rounds will be stacked together!"
        break;
    case 4:
        special_round.name = "QUAAAAAAAAAAAAAAD!!!!!!!";
        special_round.description = "Four special rounds will be stacked together!"
        break;
    case 5:
        special_round.name = "What have you done!?";
        special_round.description = "Five special rounds will be stacked together!"
        break;
    }

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

// MEGAMOD: Rewrote to support 3 or more special rounds.
function GetName()
{
	if (scopes.len() == 0) {
        return "404 Not Found";
    } else if (scopes.len() == 1) {
        return scopes[0].special_round.name;
    }
    local out = format("%s\n", special_round.name)
    foreach (scope in scopes)
    {
        out = format("%s-> %s\n", out, scope.special_round.name)
    }
	return out;
}

// MEGAMOD: Rewrote to support 3 or more special rounds.
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

// MEGAMOD: Rewrote to support 3 or more special rounds.
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

// MEGAMOD: Rewrote to support 3 or more special rounds.
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
        if (call_failed) ret = false;
		return ret
	}

	function OnCalculateTopScorers(top_players)
	{
        local ret = null;
        foreach (scope in scopes)
        {
            ret = DelegatedCall(scope, "OnCalculateTopScorers", top_players)
            if (call_failed || ret == false) continue;
            return ret
        }
        if (call_failed) ret = false;
        return ret;
	}

	function OnDeclareWinners(top_players, top_score, winner_count)
	{
        local ret = null;
        foreach (scope in scopes)
        {
            ret = DelegatedCall(scope, "OnDeclareWinners", top_players, top_score, winner_count)
            if (call_failed || ret == false) continue;
            return ret
        }
        if (call_failed) ret = false;
        return ret;
	}

    function OnShowChatText(player, fmt)
	{
        local fmt;
        foreach (scope in scopes) {
            local ret = DelegatedCall(scope, "OnShowChatText", player, fmt)
            if (!call_failed) {
                fmt = ret
            }
        }
		return fmt
	}

	function OnShowGameText(players, channel, text)
	{
        local text;
        foreach (scope in scopes) {
            local ret = DelegatedCall(scope, "OnShowGameText", players, channel, text)
            if (!call_failed) {
                text = ret
            }
        }
		return text
	}

	function OnShowOverlay(players, overlay_name)
	{
        local overlay_name;
        foreach (scope in scopes) {
            local ret = DelegatedCall(scope, "OnShowOverlay", players, overlay_name)
            if (!call_failed) {
                overlay_name = ret
            }
        }
		return overlay_name
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