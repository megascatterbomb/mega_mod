// Last player gets glow
characterTraitsClasses.push(class extends CharacterTrait
{
    function OnTickAlive(timeDelta)
    {
        local currentGlow = GetPropBool(player, "m_bGlowEnabled");
        local mercsAlive = GetAliveMercCount();
        if(!currentGlow && (mercsAlive == 1)){
            SetPropBool( player, "m_bGlowEnabled", true );
        } else if (currentGlow && (mercsAlive > 1 || GetPropInt(player, "m_iTeamNum") == 3)) {
            SetPropBool( player, "m_bGlowEnabled", false );
        }
    }
});

class BossGlowOnMercBuffTrait extends BossTrait {
    function OnTickAlive(timeDelta)
    {
        local currentGlow = GetPropBool(player, "m_bGlowEnabled");
        local mercsAlive = GetAliveMercCount();
        if(!currentGlow && (mercsAlive == 1)){
            SetPropBool( player, "m_bGlowEnabled", true );
        } else if (!IsAnyBossAlive() || (currentGlow && mercsAlive > 1 )) {
            SetPropBool( player, "m_bGlowEnabled", false );
        }
    }
}

AddBossTrait("saxton_hale", BossGlowOnMercBuffTrait);