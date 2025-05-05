local mercsIdleTracker = {};

local idleThreshold = 60;

::bootedPlayers <- [];

function PrintIdleMessage(player, timeToKick)
{
    ClientPrint(player, 3, "You have "+timeToKick+" seconds to stop being AFK before you're fired!");
}

function PrintIdleMessageNearDeath(player, timeToKick)
{
    ClientPrint(player, 3, timeToKick+"...");
}

function CheckIfStillIdle(player)
{
    local buttons = GetPropInt(player, "m_nButtons");

    if(buttons == 0) // No input
    {
        return true;
    }
    mercsIdleTracker[player] <- Time();
    return false;
}

function IdleTick()
{
    foreach(player in GetAliveMercs())
    {
        if(!(player in mercsIdleTracker))
        {
            continue;
        }
        CheckIfStillIdle(player);
    }
}

local adjustedMercCount = -1;

// Reduce hale's health to compensate for the loss in players.
function AdjustHaleHealth(booted)
{
    local bootCount = booted.len();
    if(adjustedMercCount < 0) adjustedMercCount = startMercCount;
    local oldMercCount = adjustedMercCount;

    if(bootCount <= 0 || adjustedMercCount - bootCount <= 0) return;

    local boss = GetBossPlayers()[0];
    local currHealth = boss.GetHealth();
    local oldMaxHealth = GetStartingHealth(oldMercCount);
    local adjustedMaxHealth = oldMaxHealth;

    local damageToDeal = 0;

    // Calculate the shift in hale's max health that would result from this number of players disconnecting.
    // Calculate the amount of damage we should deal such that the ratio between current health and damage dealt geometrically matches the shift in max health we'd expect.
    // Subtract any damage already dealt by the players that are now AFK.
    foreach(player in booted)
    {
        local damageByPlayer = GetRoundDamage(player);
        adjustedMercCount--;
        local damageToAdd = clampFloor(0, adjustedMaxHealth - GetStartingHealth(adjustedMercCount) - damageByPlayer);
        damageToDeal += damageToAdd;
        adjustedMaxHealth = GetStartingHealth(adjustedMercCount);
    }

    // This is the formula used in received_damage_scaling
    local mercMultiplier = clampFloor(1, 1.85 - (GetAliveMercCount() * 1.0 / adjustedMercCount));

    // Divide by 1.25 to counter the damage vulnerability hale has to fire damage.
    local healthPenalty = floor(clampCeiling((currHealth - 100) / mercMultiplier, damageToDeal * (currHealth / oldMaxHealth) / mercMultiplier ) / 1.25);

    if(healthPenalty < 1) return;

    boss.TakeDamageCustom(null, boss, null, Vector(0.0000001, 0.0000001, 0.0000001), Vector(0.0000001, 0.0000001, 0.0000001), healthPenalty, DMG_BURN + DMG_PREVENT_PHYSICS_FORCE, TF_DMG_CUSTOM_BLEEDING);

    // Need this because all the damage modifiers in the VScript fuck with the calculations.
    local actualNewHealth = boss.GetHealth();
    local actualHealthPenalty = currHealth - actualNewHealth;
    RunWithDelay("ClampRoundTime()", null, 0.05);
    ClientPrint(null, 3, "Removed " + actualHealthPenalty + " health from Hale to compensate for idling players.");
}

// Enable the AFK checker.
function IdleStart()
{
    local now = Time();
    foreach(player in GetAliveMercs())
    {
        mercsIdleTracker[player] <- now;
    }
    IdleSecondLoop();
    AddListener("tick_only_valid", 11, function (timeDelta)
    {
        IdleTick();
    });
}

// Every second, look for idle players.
// Send warning messages; kill if idleThreshold is reached.
function IdleSecondLoop()
{
    local booted = [];
    foreach(player in GetAliveMercs())
    {
        if (player == null || !IsPlayerAlive(player) || !(player in mercsIdleTracker)) continue;

        local timeIdle = floor(Time() - mercsIdleTracker[player]);

        if(timeIdle >= idleThreshold)
        {
            booted.push(player);
            bootedPlayers.push(player);
            player.TakeDamage(999999, 0, null);

            local name = GetPropString(player, "m_szNetname");

            ClientPrint(null, 3, COLOR_MERCS + name + "\x01 was fired for being AFK.");

            continue;
        }
        switch (timeIdle) {
            case (idleThreshold - 30):
                PrintIdleMessage(player, 30);
                break;
            case (idleThreshold - 20):
                PrintIdleMessage(player, 20);
                break;
            case (idleThreshold - 15):
                PrintIdleMessage(player, 15);
                break;
            case (idleThreshold - 10):
                PrintIdleMessage(player, 10);
                break;
            case (idleThreshold - 5):
                PrintIdleMessage(player, 5);
                break;
            case (idleThreshold - 4):
                PrintIdleMessageNearDeath(player, 4);
                break;
            case (idleThreshold - 3):
                PrintIdleMessageNearDeath(player, 3);
                break;
            case (idleThreshold - 2):
                PrintIdleMessageNearDeath(player, 2);
                break;
            case (idleThreshold - 1):
                PrintIdleMessageNearDeath(player, 1);
                break;
        }
    }
    AdjustHaleHealth(booted);

    RunWithDelay("IdleSecondLoop()", null, 1);
}

AddListener("setup_end", 10, function()
{
    // Give the game plenty of time to sort its shit out before we start reading vars.
    RunWithDelay("IdleStart()", null, 1);
});


