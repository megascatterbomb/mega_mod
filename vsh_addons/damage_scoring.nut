// Broadcast player's damage in chat when they die.
function BroadcastDamageOnDeath(attacker, victim, deadRinger = false) {
    if(IsBoss(victim) || IsRoundOver() || IsRoundSetup() || bootedPlayers.find(victim) != null)
    {
        return;
    }
    local name = GetPropString(victim, "m_szNetname");
    local damage = GetRoundDamage(victim);

    local target = deadRinger ? GetBossPlayers()[0] : null;
    ClientPrint(target, 3, COLOR_MERCS + name +" \x01dealt "
        + COLOR_MERCS + damage + " \x01damage to Hale before dying."
        + (damage ? "" : " \x01How embarrassing!"));
}

// Broadcast top players at end of round.
function BroadcastBestPlayers()
{
    local topN = 3;
    local damageBoard = GetDamageBoardSorted();

    // Filter self-damage out of here.
    for(local i = 0; i < damageBoard.len(); i++) {
        if(IsBoss(damageBoard[i][0])) {
            damageBoard.remove(i);
            i--;
        }
    }

    if(IsRoundSetup()) {
        return;
    }

    if(damageBoard.len() == 0 && IsAnyBossAlive())
    {
        ClientPrint(null, 3, "None of you managed to scratch Hale this round. Pathetic!");
        return;
    }
    local playerDamage = 0;

    ClientPrint(null, 3, COLOR_BOSS + "Saxton \x01killed "
        + COLOR_BOSS + (startMercCount - GetAliveMercCount()) + "/"
        + startMercCount + "\x01 mercs. Top players this round:");

    for(local i = 0; i < damageBoard.len(); i++) {
        if (damageBoard[i][0].IsValid() == false) {
            continue;
        }
        local name = GetPropString(damageBoard[i][0], "m_szNetname");
        if (name == "") {
            continue;
        }
        local playerTeam = damageBoard[i][0].GetTeam()
        local damage = damageBoard[i][1];
        local percent = floor(100 * damage / maxHealth);
        playerDamage += damage;
        if(i < topN && damage > 0) {
            local isRPSWinner = damageBoard[i][0] == VSH_RPS_WINNER;
            local color = isRPSWinner ? COLOR_SPECIAL : COLOR_MERCS;
            local out = "\x01#"+(i+1)+": "
            + COLOR_MERCS + name + "\x01 dealt "
            + color + damage + "\x01 damage ("
            + color + percent + "%\x01)";
            local out = isRPSWinner ? COLOR_SPECIAL + "(RPS) " + out : out;
            ClientPrint(null, 3, out);
        }
    }
    local netDamage = maxHealth - currentHealth;
    local totalDamage = netDamage + healthHealed;

    local playerPercent = floor(100 * playerDamage / maxHealth);
    if(!IsAnyBossAlive())
    {
        totalDamage = maxHealth + healthHealed;
    }
    local otherDamage = totalDamage - playerDamage;
    local otherPercent = floor(100 * otherDamage / maxHealth);
    local healedPercent = floor(100 * healthHealed / maxHealth);
    local totalPercent = floor(100 * totalDamage / maxHealth);
    local netPercent = floor(100 * netDamage / maxHealth);

    if(otherDamage > 0) ClientPrint(null, 3, "Player Damage: "+playerDamage+" ("+playerPercent+"%)");
    if(otherDamage > 0) ClientPrint(null, 3, "Other Damage: "+otherDamage+" ("+otherPercent+"%)");

    ClientPrint(null, 3, "Total Damage: "+totalDamage+"/"+maxHealth+" ("+totalPercent+"%)");

    if(healthHealed > 0) ClientPrint(null, 3, "Health Regenerated: "+healthHealed+" ("+healedPercent+"%)");
    if(healthHealed > 0) ClientPrint(null, 3, "Net Damage: "+netDamage+" ("+netPercent+"%)");
}

AddListener("death", 0, function(attacker, victim, params)
{
    BroadcastDamageOnDeath(attacker, victim);
});

AddListener("dead_ringer", 0, function(attacker, victim, params)
{
    BroadcastDamageOnDeath(attacker, victim, true);
});

AddListener("round_end", 5, function (winnerTeam)
{
    // Slight delay as the game can take an extra tick to account for all damage stuff sometimes.
    RunWithDelay("BroadcastBestPlayers()", null, 0);
});

// OVERRIDE: __lizardlib\game_events.nut::OnGameEvent_player_death
function OnGameEvent_player_death(params)
{
    if (IsNotValidRound())
        return;
    local player = GetPlayerFromParams(params);
    if (!IsValidPlayer(player))
        return;
    local attacker = GetPlayerFromParams(params, "attacker");
    // Ensure death message gets printed to Hale when dead ringer is used.
    if(params.death_flags & TF_DEATHFLAG.DEAD_RINGER) {
        FireListeners("dead_ringer", attacker, player, params);
        return;
    }

    FireListeners("death", attacker, player, params);
}