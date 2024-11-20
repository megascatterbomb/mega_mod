::mercBuff <- false
::haleBuff <- false

::healthHealed <- 0 // Track health regened by Hale.

local increment = 1;
local idleMultiplier = 1;

local haleLastDamage = Time();
local mercsLastDamage = Time();
local idleTime = 30;

// OVERRIDE: Replace stalemate function to account for a captured control point.
function PrepareStalemate()
{
    local delay = clampFloor(60, API_GetFloat("stalemate_time"));

    RunWithDelay("DisplayStalemateAlert()", null, delay - 60);

    // Don't need to gate, entity is disabled when point captured.
    RunWithDelay("EntFireByHandle(team_round_timer, `SetTime`, `60`, 0, null, null)", null, delay - 60);

    RunWithDelay("PlayAnnouncerVODelayedGated(5)", null, delay - 6);
    RunWithDelay("PlayAnnouncerVODelayedGated(4)", null, delay - 5);
    RunWithDelay("PlayAnnouncerVODelayedGated(3)", null, delay - 4);
    RunWithDelay("PlayAnnouncerVODelayedGated(2)", null, delay - 3);
    RunWithDelay("PlayAnnouncerVODelayedGated(1)", null, delay - 2);

    RunWithDelay("EndRoundTime()", null, delay);
}

// OVERRIDE: Prevent screenshake from the bleed damage dealt if RED caps
function ScreenShakeTrait::OnDamageDealt(victim, params)
{
    if (victim != null && victim.IsValid() && !IsBoss(victim))
        ScreenShake(victim.GetCenter(), 140, 1, 1, 10, 0, true);
}

// Helper functions to gate against mercBuff and haleBuff

// Message displays for 5 seconds rather than 1
function DisplayStalemateAlert() {
    if(mercBuff || haleBuff) return;
    local text_tf = SpawnEntityFromTable("game_text_tf", {
        message = "#vsh_end_this",
        icon = "ico_notify_flag_moving_alt",
        background = 0,
        display_to_team = 0
    });
    EntFireByHandle(text_tf, "Display", "", 0, null, null);
    EntFireByHandle(text_tf, "Kill", "", 5, null, null);
}

// Play stalemate countdown.
function PlayAnnouncerVODelayedGated(number) {
    if(mercBuff || haleBuff) return;
    local boss = GetRandomBossPlayer();
    PlayAnnouncerVODelayed(boss, "count"+number, 0);
}

// Stalemates if point isn't owned.
function EndRoundTime() {
    if(mercBuff || haleBuff) return;
    EndRound(TF_TEAM_UNASSIGNED);
}

// Remove outputs intended to end the round on point capture and add our own.
AddListener("setup_end", 0, function()
{
    // Out with the old...
    local controlPoint = Entities.FindByClassname(null, "team_control_point");
    EntityOutputs.RemoveOutput(controlPoint,
        "OnCapTeam"+(TF_TEAM_MERCS-1),
        vsh_vscript_name,
        "RunScriptCode",
        "EndRound("+TF_TEAM_MERCS+")"
    );
    EntityOutputs.RemoveOutput(controlPoint,
        "OnCapTeam"+(TF_TEAM_BOSS-1),
        vsh_vscript_name,
        "RunScriptCode",
        "EndRound("+TF_TEAM_BOSS+")"
    );

    // ...and in with the new.
    EntityOutputs.AddOutput(controlPoint,
        "OnCapTeam"+(TF_TEAM_MERCS-1),
        vsh_vscript_name,
        "RunScriptCode",
        "BuffMercs()",
        0, -1);
    EntityOutputs.AddOutput(controlPoint,
        "OnCapTeam"+(TF_TEAM_BOSS-1),
        vsh_vscript_name,
        "RunScriptCode",
        "BuffHale()",
        0, -1);
});

// Continuously regens or damages hale until the round ends.
function EndgameInterval(killHale)
{
    if(IsRoundOver()) {
        return;
    }

    local boss = GetBossPlayers()[0];
    local oldHealth = boss.GetHealth();
    local damageOrHealing = ceil(increment * idleMultiplier);
    local newHealth = ceil(killHale ? oldHealth - damageOrHealing : oldHealth + damageOrHealing);

    // ClientPrint(null, 3, "Increment: " + increment);
    // ClientPrint(null, 3, "Idle multiplier: " + idleMultiplier);
    // ClientPrint(null, 3, "Damage: " + damageOrHealing);

    // Do the damage
    if(killHale) {
        local vecPunch = GetPropVector(boss, "m_Local.m_vecPunchAngle");
        boss.TakeDamageCustom(boss, boss, null, Vector(0.000001, 0.000001, 0.000001), Vector(0.000001, 0.000001, 0.000001), damageOrHealing, DMG_BURN + DMG_PREVENT_PHYSICS_FORCE, TF_DMG_CUSTOM_BLEEDING);
        SetPropVector(boss, "m_Local.m_vecPunchAngle", vecPunch);
    } else if(!killHale && newHealth >= maxHealth) {
        healthHealed = healthHealed + maxHealth - oldHealth;
        boss.SetHealth(maxHealth);
        currentHealth = maxHealth;
        EndRound(TF_TEAM_BOSS);
        return;
    } else {
        healthHealed = healthHealed + newHealth - oldHealth;
        boss.SetHealth(newHealth);
    }

    increment++;
    // Speed things up if the losing team hasn't dealt damage in the past 30 seconds.
    if(killHale && Time() > haleLastDamage + idleTime) {
        if(idleMultiplier == 1) {
            ClientPrint(null, 3, "Do some damage Saxton! Otherwise your health will drain even faster!");
        }
        idleMultiplier = idleMultiplier * 1.05;
    } else if (!killHale && Time() > mercsLastDamage + idleTime){
        if(idleMultiplier == 1) {
            ClientPrint(null, 3, "Do some damage Mercenaries! Otherwise Hale will regenerate even faster!");
        }
        idleMultiplier = idleMultiplier * 1.05;
    } else {
        idleMultiplier = 1;
    }

    // Loop continuously at 1 second intervals.
    RunWithDelay("EndgameInterval("+killHale+")", null, 1);
}

// Listen for idlers
AddListener("damage_hook", 0, function (attacker, victim, params)
{
    if (IsBoss(attacker) && !IsBoss(victim)) {
        haleLastDamage = Time();
    } else if (!IsBoss(attacker) && IsBoss(victim)) {
        mercsLastDamage = Time();
    }
});

// Starts the endgame bleed/health regen.
// Calculates the appropriate starting increment to use.
function BeginEndgame(killHale) {

    EntFireByHandle(team_round_timer, "Pause", "", 0, null, null);
    EntFireByHandle(team_round_timer, "Disable", "", 0, null, null);

    local controlPoint = Entities.FindByClassname(null, "team_control_point");
    EntFireByHandle(controlPoint, "SetLocked", "1", 0, null, null);

    haleLastDamage = Time();
    mercsLastDamage = Time();

    // local sum = killHale ? currentHealth : maxHealth - currentHealth;
    // local mercsKilled = startMercCount - GetAliveMercCount();
    // local desiredTimeUnclamped = 5 * (killHale ? mercsKilled : GetAliveMercCount());

    // local desiredTime = clampFloor(60, desiredTimeUnclamped);

    // local startingIncrement = (2*sum/desiredTime - desiredTime + 1)/2.0;

    increment = 1; // clamp(ceil(startingIncrement), 1, maxHealth / 100);

    EndgameInterval(killHale);
}

// Removes Hale's cooldown on abilities.
// Hale's health regenerates an ever-increasing amount until it's max, at which point Hale wins.
::BuffHale <- function() {
    haleBuff = true;
    ClientPrint(null, 3, "Hale's regenerating health, and his abilities have reduced cooldown!");
    ClientPrint(null, 3, "If Hale's health replenishes entirely, he wins!");
    // Buff ability cooldown
    IncludeScript("vsh_addons/ability_cooldown_override.nut");

    // Super regen
    BeginEndgame(false);
}

// Mercs get 5s of massive regen and full crits on all weapons for the rest of the round.
// Hale bleeds an ever-increasing amount until the round ends.
::BuffMercs <- function() {
    mercBuff = true;
    ClientPrint(null, 3, "Hale is bleeding to death, and the Mercs now have permanent crits!");
    // Give huge health buff
    local mercs = GetAliveMercs();
    for(local i = 0; i < mercs.len(); i++) {
        mercs[i].AddCondEx(TF_COND_HALLOWEEN_QUICK_HEAL, 5, mercs[i]);
    }

    // Super bleed
    BeginEndgame(true);
}

// Give full crits for rest of round
characterTraitsClasses.push(class extends CharacterTrait
{
    function OnTickAlive(timeDelta)
    {
        if(mercBuff){
            player.AddCondEx(TF_COND_OFFENSEBUFF, 0.2, player);
            player.AddCondEx(TF_COND_CRITBOOSTED_ON_KILL, 0.2, player);
        }
    }
});