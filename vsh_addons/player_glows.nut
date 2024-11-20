// Last player gets glow, if hale caps they all get glow
characterTraitsClasses.push(class extends CharacterTrait
{
    function OnTickAlive(timeDelta)
    {
        local currentGlow = GetPropBool(player, "m_bGlowEnabled");
        local mercsAlive = GetAliveMercCount();
        if(!currentGlow && (mercsAlive == 1 || haleBuff)){
            SetPropBool( player, "m_bGlowEnabled", true );
        } else if (currentGlow && !haleBuff && (mercsAlive > 1 || GetPropInt(player, "m_iTeamNum") == 3)) {
            SetPropBool( player, "m_bGlowEnabled", false );
        }
    }
});

class BossGlowOnMercBuffTrait extends BossTrait {
    function OnTickAlive(timeDelta)
    {
        local currentGlow = GetPropBool(player, "m_bGlowEnabled");
        local mercsAlive = GetAliveMercCount();
        if(!currentGlow && (mercsAlive == 1 || mercBuff)){
            SetPropBool( player, "m_bGlowEnabled", true );
        } else if (!IsAnyBossAlive() || (currentGlow && !mercBuff && mercsAlive > 1 )) {
            SetPropBool( player, "m_bGlowEnabled", false );
        }
    }
}

AddBossTrait("saxton_hale", BossGlowOnMercBuffTrait);