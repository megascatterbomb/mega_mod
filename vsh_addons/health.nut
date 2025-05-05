// Separate function so we can get maxhealth without setting the maxHealth variable.
::GetStartingHealth <- function(enemyCount)
{
    local linearCutoff = 23;
    if (enemyCount < 2)
        return 1000;
    local unrounded;
    if (enemyCount <= linearCutoff)
    {
        local constant = 2350 * clampCeiling(1.0, 0.3 + (enemyCount/10.0));
        unrounded = enemyCount * enemyCount * 41 + constant;
    }
    else {
        local baseHealth = 24000;
        local increment = 2000;
        unrounded = baseHealth + (increment * (enemyCount - linearCutoff));
    }
    return floor(unrounded / 100) * 100;
}

// OVERRIDE: bosses\generic\misc\setup_stat_refresh.nut::CalcBossMaxHealth
::CalcBossMaxHealth <- function(mercCount)
{
    local health = GetStartingHealth(mercCount);
    maxHealth = health;
    return health;
}