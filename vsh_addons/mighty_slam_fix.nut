// OVERRIDE: bosses\saxton_hale\abilities\mighty_slam.nut::MightySlamTrait::OnTickAlive
function MightySlamTrait::OnTickAlive(timeDelta)
{
    if (meter < 0)
    {
        meter += timeDelta;
        if (meter > 0)
        {
            EmitSoundOnClient("vsh_sfx.slam_ready", boss);
            EmitSoundOnClient("TFPlayer.ReCharged", boss);
            meter = 0;
        }
    }
    // MEGAMOD: Do not prevent the boss from using the slam when on cooldown.
    if (!boss.IsOnGround() && (boss.GetFlags() & FL_DUCKING))
        Weightdown();
    else if (inUse && !(boss.GetFlags() & FL_DUCKING))
    {
        inUse = false;
        SetItemId(boss.GetActiveWeapon(), 5);
        boss.SetGravity(1);
        BossPlayViewModelAnim(boss, "f_idle");
    }
    else if (inUse && boss.IsOnGround())
    {
        inUse = false;
        SetItemId(boss.GetActiveWeapon(), 5);
        boss.SetGravity(1);
        if (meter >= 0 && lastFrameDownVelocity < -300)
            Perform();
        else
            BossPlayViewModelAnim(boss, "f_idle");
    }
}