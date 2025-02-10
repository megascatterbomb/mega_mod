::mercBuff <- false
::haleBuff <- false
::pointUnlocked <- false;

::healthHealed <- 0 // Track health regened by Hale.

local increment = 1;
local idleMultiplier = 1;

local haleLastDamage = Time();
local mercsLastDamage = Time();
local idleTime = 30;
local mercDamageTarget = null;

// OVERRIDE: _gamemode\gamerules.nut::PrepareStalemate
// Replace stalemate function to account for a captured control point.
function PrepareStalemate()
{
    local delay = clampFloor(60, API_GetFloat("stalemate_time"));

    RunWithDelay("DisplayStalemateAlert()", null, delay - 60);

    // Don't need to gate, entity is disabled when point captured.
    RunWithDelay("EntFireByHandle(team_round_timer, `SetMaxTime`, `60`, 0, null, null)", null, delay - 60);
    RunWithDelay("EntFireByHandle(team_round_timer, `SetTime`, `60`, 0, null, null)", null, delay - 60);

    RunWithDelay("PlayAnnouncerVODelayedGated(5)", null, delay - 6);
    RunWithDelay("PlayAnnouncerVODelayedGated(4)", null, delay - 5);
    RunWithDelay("PlayAnnouncerVODelayedGated(3)", null, delay - 4);
    RunWithDelay("PlayAnnouncerVODelayedGated(2)", null, delay - 3);
    RunWithDelay("PlayAnnouncerVODelayedGated(1)", null, delay - 2);

    RunWithDelay("EndRoundTime()", null, delay);
}

// OVERRIDE: bosses\generic\misc\screen_shake.nut::ScreenShakeTrait::OnDamageDealt
// Prevent screenshake from the bleed damage dealt if RED caps
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

// Continuously damages hale.
function EndgameIntervalMercsCap()
{
    if(IsRoundOver()) {
        return;
    }

    local boss = GetBossPlayers()[0];
    local oldHealth = boss.GetHealth();
    local damage = ceil(increment * idleMultiplier);
    local newHealth = ceil(oldHealth - damage);

    local vecPunch = GetPropVector(boss, "m_Local.m_vecPunchAngle");
    // Adjust for merc damage scaling and fire resistance.
    local actualDamage = damage / (clampFloor(1, 1.85 - (GetAliveMercCount() * 1.0 / startMercCount)) * 1.25 );
    boss.TakeDamageCustom(boss, boss, null, Vector(0.0000001, 0.0000001, 0.0000001), boss.GetOrigin(), actualDamage, DMG_BURN + DMG_PREVENT_PHYSICS_FORCE, TF_DMG_CUSTOM_BLEEDING);
    SetPropVector(boss, "m_Local.m_vecPunchAngle", vecPunch);

    increment++;
    // Speed things up if the losing team hasn't dealt damage in the past 30 seconds.
    if (Time() > haleLastDamage + idleTime) {
        idleMultiplier = idleMultiplier * 1.05;
    } else {
        idleMultiplier = 1;
    }

    // Loop continuously at 1 second intervals.
    RunWithDelay("EndgameIntervalMercsCap()", null, 1);
}

// Continuously damages the merc who has dealt the least damage.
function EndgameIntervalHaleCaps()
{
    if(IsRoundOver()) {
        return;
    }

    local damageBoard = GetDamageBoardSorted();
    for (local i = damageBoard.len() - 1; i >= 0; i--) {
        local merc = damageBoard[i][0];
        if(IsMercValidAndAlive(merc)) {
            if(!IsMercValidAndAlive(mercDamageTarget) || merc.entindex() != mercDamageTarget.entindex()) {
                SetMarkedForDeath(mercDamageTarget, false);
            }
            SetMarkedForDeath(merc, true);
            break;
        }
    }

    local damage = 1 + (idleMultiplier * increment / 10);

    if (mercDamageTarget == null) {
        RunWithDelay("EndgameIntervalHaleCaps()", null, 1);
        return;
    }

    local vecPunch = GetPropVector(mercDamageTarget, "m_Local.m_vecPunchAngle");
    mercDamageTarget.TakeDamageCustom(mercDamageTarget, mercDamageTarget, null, Vector(0.0000001, 0.0000001, 0.0000001),
        mercDamageTarget.GetOrigin(), damage, DMG_BURN + DMG_PREVENT_PHYSICS_FORCE, TF_DMG_CUSTOM_BLEEDING);
    SetPropVector(mercDamageTarget, "m_Local.m_vecPunchAngle", vecPunch);

    increment++;
    // Speed things up if the losing team hasn't dealt damage in the past 30 seconds.
    if (Time() > mercsLastDamage + idleTime) {
        idleMultiplier = idleMultiplier * 1.05;
    } else {
        idleMultiplier = 1;
    }

    // Loop continuously at 1 second intervals.
    RunWithDelay("EndgameIntervalHaleCaps()", null, 1);
}

// Apply Marked for Death to targeted player
function SetMarkedForDeath(merc, mark) {
    if (!IsMercValidAndAlive(merc)) {
        mercDamageTarget = null;
    } else if (!mark) {
        merc.RemoveCond(TF_COND_MARKEDFORDEATH);
    } else {
        merc.AddCondEx(TF_COND_MARKEDFORDEATH, 1.1, merc);
        if (mercDamageTarget == null || merc.entindex() != mercDamageTarget) {
            // notify new target.
        }
        mercDamageTarget = merc;
    }
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
function BeginEndgame() {

    EntFireByHandle(team_round_timer, "Pause", "", 0, null, null);
    EntFireByHandle(team_round_timer, "Disable", "", 0, null, null);

    local controlPoint = Entities.FindByClassname(null, "team_control_point");
    EntFireByHandle(controlPoint, "SetLocked", "1", 0, null, null);

    haleLastDamage = Time();
    mercsLastDamage = Time();

    increment = 1;
}

::BuffHale <- function() {
    haleBuff = true;
    ClientPrint(null, 3, COLOR_BOSS + "[HALE CAPTURED POINT]");
    ClientPrint(null, 3, "Hale's abilities have reduced cooldown, and the merc with the lowest damage will bleed to death!");
    // Buff ability cooldown
    IncludeScript("vsh_addons/ability_cooldown_override.nut");

    // Init damage board for mercs who haven't dealt damage.
    local mercs = GetAliveMercs();
    for(local i = 0; i < mercs.len(); i++) {
        if (GetRoundDamage(mercs[i]) == 0) SetRoundDamage(mercs[i], 0);
    }

    BeginEndgame();
    EndgameIntervalHaleCaps();
}

::BuffMercs <- function() {
    mercBuff = true;
    ClientPrint(null, 3, COLOR_MERCS + "[MERCS CAPTURED POINT]");
    ClientPrint(null, 3, "Hale is bleeding to death, and the Mercs now have permanent crits!");
    // Give huge health buff
    local mercs = GetAliveMercs();
    for(local i = 0; i < mercs.len(); i++) {
        mercs[i].AddCondEx(TF_COND_HALLOWEEN_QUICK_HEAL, 5, mercs[i]);
    }

    BeginEndgame();
    EndgameIntervalMercsCap();
}

// Give full crits for rest of round if mercs cap.
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