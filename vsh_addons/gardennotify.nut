::specialScoreboard <- {}

::SPECIAL_BACKSTAB <- 0
::SPECIAL_MARKET_GARDEN <- 1
::SPECIAL_TELEFRAG <- 2

::IncrementAndGetSpecialScoreboard <-  function(player, specialType) {
    local userid = GetPlayerUserID(player);
    // I don't want to have to deal with tuple keys if a class ends up with two specials in the future.
    // Merge userID and specialType into a single key.
    local scoreboardKey = (specialType << 16) | userid;
    if (scoreboardKey in specialScoreboard){
        ::specialScoreboard[scoreboardKey]++
    } else {
        ::specialScoreboard[scoreboardKey] <- 1
    }
    return ::specialScoreboard[scoreboardKey]
}

// OVERRIDE: mercs\merc_traits\single_class\spy_backstab.nut::OnDamageDealt
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
        local count = IncrementAndGetSpecialScoreboard(player, ::SPECIAL_BACKSTAB);
        ClientPrint(null, 3, COLOR_MERCS + attackerName + " " + COLOR_SPECIAL + "backstabbed \x01Hale! (#" + count + ")")
    }
}

// OVERRIDE: mercs\merc_traits\single_class\soldier_market_gardener.nut::OnDamageDealt
characterTraitsClasses[20].OnDamageDealt <-  function(victim, params) {
    if (player.InCond(TF_COND_BLASTJUMPING) && WeaponIs(params.weapon, "market_gardener"))
        {
            params.damage = vsh_vscript.CalcStabDamage(victim) / 2.5;
            local attackerName = GetPropString(player, "m_szNetname");
            EmitSoundOn("vsh_sfx.gardened", player);
            EmitPlayerVODelayed(player, "gardened", 0.3);
            local count = IncrementAndGetSpecialScoreboard(player, ::SPECIAL_MARKET_GARDEN);
            ClientPrint(null, 3, COLOR_MERCS + attackerName + " " + COLOR_SPECIAL + "gardened \x01Hale! (#" + count + ")")
        }
}
// OVERRIDE: mercs\merc_traits\single_class\engineer_telefrag_scaling.nut::OnDamageDealt
characterTraitsClasses[25].OnDamageDealt <-  function(victim, params) {
    if (params.damage_custom == TF_DMG_CUSTOM_TELEFRAG)
        {
            local attackerName = GetPropString(player, "m_szNetname");
            // MEGAMOD: Telefrags deal 10x the damage they'd normally do
            params.damage = vsh_vscript.CalcStabDamage(victim) * 2 * 10;
            local count = IncrementAndGetSpecialScoreboard(player, ::SPECIAL_TELEFRAG);
            ClientPrint(null, 3, COLOR_MERCS + attackerName + " " + COLOR_SPECIAL + "telefragged \x01Hale! (#" + count + ")")
        }
}
