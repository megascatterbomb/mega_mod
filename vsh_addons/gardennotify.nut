characterTraitsClasses[5].OnDamageDealt <-  function(victim, params) {
    if (params.damage_custom == TF_DMG_CUSTOM_BACKSTAB)
    {
        local attackerName = GetPropString(player, "m_szNetname");
        params.damage = vsh_vscript.CalcStabDamage(victim) / 2.5; //Crit compensation

        SetPropFloat(params.weapon, "m_flNextPrimaryAttack", Time() + 2.0);
        SetPropFloat(player, "m_flNextAttack", Time() + 2.0);
        SetPropFloat(player, "m_flStealthNextTraitTime", Time() + 2.0);
        EmitSoundOn("Player.Spy_Shield_Break", victim);
        EmitSoundOn("Player.Spy_Shield_Break", victim);
        if (victim.GetHealth() > params.damage * 2.5)
            PlayAnnouncerVO(victim, "stabbed");

        if (WeaponIs(params.weapon, "kunai"))
        {
            player.SetHealth(clampCeiling(270, player.GetHealth() + 180));
        }
        else if (WeaponIs(params.weapon, "big_earner"))
        {
            player.AddCondEx(TF_COND_SPEED_BOOST, 3, player);
            player.SetSpyCloakMeter(clampFloor(100, player.GetSpyCloakMeter() + 30));
        }
        else if (WeaponIs(params.weapon, "your_eternal_reward") || WeaponIs(params.weapon, "wanga_prick"))
        {
            RunWithDelay("YERDisguise(activator)", player, 0.1);
        }
        if (WeaponIs(player.GetWeaponBySlot(TF_WEAPONSLOTS.PRIMARY), "diamondback"))
            AddPropInt(player, "m_Shared.m_iRevengeCrits", 2);
        ClientPrint(null, 3, COLOR_MERCS + attackerName + " " + COLOR_SPECIAL + "backstabbed \x01Hale!")
    }
}

characterTraitsClasses[20].OnDamageDealt <-  function(victim, params) {
    if (player.InCond(TF_COND_BLASTJUMPING) && WeaponIs(params.weapon, "market_gardener"))
        {
            params.damage = vsh_vscript.CalcStabDamage(victim) / 2.5;
            local attackerName = GetPropString(player, "m_szNetname");
            EmitSoundOn("vsh_sfx.gardened", player);
            EmitPlayerVODelayed(player, "gardened", 0.3);
            ClientPrint(null, 3, COLOR_MERCS + attackerName + " " + COLOR_SPECIAL + "gardened \x01Hale!")
        }
}
characterTraitsClasses[25].OnDamageDealt <-  function(victim, params) {
    if (params.damage_custom == TF_DMG_CUSTOM_TELEFRAG)
        {
            local attackerName = GetPropString(player, "m_szNetname");
            params.damage = vsh_vscript.CalcStabDamage(victim) * 2;
            ClientPrint(null, 3, COLOR_MERCS + attackerName + " " + COLOR_SPECIAL + "telefragged \x01Hale!")
        }
}

if (IsDedicatedServer() == true){
    local host = GetListenServerHost()}
