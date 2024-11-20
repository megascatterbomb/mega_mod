function MightySlamTrait::Perform()
{
    DispatchParticleEffect("hammer_impact_button", boss.GetOrigin() + Vector(0,0,20), Vector(0,0,0));
    EmitSoundOn("vsh_sfx.boss_slam_impact", boss);
    lastFrameDownVelocity = 0;
    meter = -15;

    local bossLocal = boss;
    BossPlayViewModelAnim(boss, "vsh_slam_land");
    local weapon = boss.GetActiveWeapon();
    SetItemId(weapon, 444); //Mantreads
    CreateAoE(boss.GetCenter(), 500,
        function (target, deltaVector, distance) {
            local damage = target.GetMaxHealth() * (1 - distance / 500);
            if (!target.IsPlayer())
                damage *= 2;
            if (damage <= 30 && target.GetHealth() <= 30)
                return; // We don't want to have people on low health die because Hale just Slammed a mile away.
            target.TakeDamageEx(
                bossLocal,
                bossLocal,
                weapon,
                deltaVector * 1250,
                bossLocal.GetOrigin(),
                damage,
                DMG_BLAST);
        }
        function (target, deltaVector, distance) {
            local pushForce = distance < 100 ? 1 : 100 / distance;
            deltaVector.x = deltaVector.x * 1250 * pushForce;
            deltaVector.y = deltaVector.y * 1250 * pushForce;
            deltaVector.z = 950 * pushForce;
            target.Yeet(deltaVector);
        });

    SetItemId(weapon, 5);
    ScreenShake(boss.GetCenter(), 10, 2.5, 1, 1000, 0, true);
}