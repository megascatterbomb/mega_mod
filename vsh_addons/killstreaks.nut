function GetKillstreak(damage) {
    return floor(damage / 200);
}

// OVERRIDE: Add killstreaks
EraseListener("player_hurt", 5, 0);
AddListener("player_hurt", 5, function (attacker, victim, params)
{
    local oldDamage = GetRoundDamage(attacker);
    local damage = params.damageamount;
    if (victim.GetHealth() < 0)
        damage -= params.health - victim.GetHealth();
    if (!IsValidBoss(victim))
        return;
    SetRoundDamage(attacker, oldDamage + damage);
    local oldKillstreak = GetKillstreak(oldDamage);
    local newKillstreak = GetKillstreak(oldDamage + damage);
    if(newKillstreak > oldKillstreak && IsPlayerAlive(attacker)) {
        SetPropInt(attacker, "m_Shared.m_nStreaks", newKillstreak);
    }
});