local newMightySlamCooldown = 5;
local newSaxtonPunchCooldown = 5;
local newSweepingChargeCooldown = 5;

// Contains replacement functions for each of saxton's abilities.
// Needed to modify the ability cooldown at runtime.

function MightySlamTrait::Perform() {
    DispatchParticleEffect("hammer_impact_button", boss.GetOrigin() + Vector(0,0,20), Vector(0,0,0));
    EmitSoundOn("vsh_sfx.boss_slam_impact", boss);
    lastFrameDownVelocity = 0;
    meter = -newMightySlamCooldown;

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

function SaxtonPunchTrait::Perform(victim)
{
    if (meter != 0)
        return false;
    meter -= newSaxtonPunchCooldown;

    vsh_vscript.Hale_SetRedArm(boss, false);

    local haleEyeVector = boss.EyeAngles().Forward();
    haleEyeVector.Norm();

    boss.RemoveCond(TF_COND_CRITBOOSTED);
    EmitSoundOn("TFPlayer.CritHit", boss);
    EmitSoundOn("vsh_sfx.saxton_punch", boss);
    if (GetAliveMercCount() > 1)
        EmitPlayerVO(boss, "saxton_punch");
    DispatchParticleEffect("vsh_megapunch_shockwave", victim.EyePosition(), QAngle(0,boss.EyeAngles().Yaw(),0).Forward());
    ScreenShake(boss.GetCenter(), 10, 2.5, 1, 1000, 0, true);

    CreateAoE(boss.GetCenter(), 600,
        function (target, deltaVector, distance) {
            local dot = haleEyeVector.Dot(deltaVector);
            if (dot < 0.6)
                return;
            local damage = target.GetMaxHealth() * (0.7 - distance / 2000);
            if (!target.IsPlayer())
                damage *= 2;
            target.TakeDamageEx(
                boss,
                boss,
                boss.GetActiveWeapon(),
                deltaVector * 1250,
                boss.GetOrigin(),
                damage,
                DMG_BLAST);
        }
        function (target, deltaVector, distance) {
            local dot = haleEyeVector.Dot(deltaVector);
            if (dot < 0.6)
                return;
            local pushForce = distance < 100 ? 10 : 10 / sqrt(distance);
            deltaVector.x = deltaVector.x * 1250 * pushForce;
            deltaVector.y = deltaVector.y * 1250 * pushForce;
            deltaVector.z = 750 * pushForce;
            target.Yeet(deltaVector);
        });
    return true;
}

function SweepingChargeTrait::Finish()
{
    vsh_vscript.Hale_SetBlueArm(boss, false);
    BossPlayViewModelAnim(boss, "vsh_dash_end");
    boss.AddCondEx(TF_COND_GRAPPLINGHOOK_LATCHED, 0.1, boss);
    meter = -newSweepingChargeCooldown;
    isCurrentlyDashing = false;
    boss.SetGravity(1);
    EntFireByHandle(triggerCatapult, "Disable", "", 0, boss, boss)
    boss.AddCustomAttribute("no_attack", 1, 0.5);
}

// Update the meters to show the correct cooldowns

function MightySlamTrait::MeterAsPercentage()
{
    if (meter < 0)
        return (newMightySlamCooldown + meter) * 90 / newMightySlamCooldown;
    return inUse ? 200 : 100
}

function SaxtonPunchTrait::MeterAsPercentage()
{
    if (meter < 0)
        return (newSaxtonPunchCooldown + meter) * 90 / newSaxtonPunchCooldown;
    return 200;
}

function SweepingChargeTrait::MeterAsPercentage()
{
    if (meter < 0)
        return (newSweepingChargeCooldown + meter) * 90 / newSweepingChargeCooldown;
    return isCurrentlyDashing ? 200 : 100
}