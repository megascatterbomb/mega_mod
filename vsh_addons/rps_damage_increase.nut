::VSH_RPS_WINNER <- null;

// OVERRIDE: bosses\generic\misc\taunt_handler.nut::TauntHandlerTrait::OnRPS
// Increase RPS damage to 1 Million to account for very high hale health
function TauntHandlerTrait::OnRPS(winner, loser, params)
{
    local voiceLine = null;
    if (IsBoss(winner))
        voiceLine = "rps_win_"+["rock","paper","scissors"][params.winner_rps];
    else if (IsBoss(loser))
    {
        lostByRPS = true;
        voiceLine = RandomInt(1, 2) == 1 ? "rps_lose" : "rps_lose_"+["rock","paper","scissors"][params.loser_rps];
        ::VSH_RPS_WINNER <- winner; // MEGAMOD: Track winner for damage summary purposes.
        RunWithDelay2(this, 3, function(winner, loser) {
            if (!IsValidPlayer(loser))
                return;
            local attacker = IsValidPlayer(winner) ? winner : loser
            local deltaVector = loser.GetCenter() - attacker.GetCenter();
            deltaVector.Norm();
            deltaVector *= 1000000000;
            deltaVector.z = 1000000000;
            loser.TakeDamageEx(
                attacker,
                attacker,
                attacker.GetActiveWeapon(),
                deltaVector,
                attacker.GetOrigin(),
                999999, // MEGAMOD: Up the damage.
                0);
        }, winner, loser);
    }

    if (voiceLine != null)
        PlayAnnouncerVODelayed(IsBoss(winner) ? winner : loser, voiceLine, 1);
}