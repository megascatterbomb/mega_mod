::maxHealth <- 100000; // Don't initialize to zero or else you get random divide by zeroes.
::currentHealth <- 100000;
::haleName <- "\x07FCD303kiwi is a bald retard"; // If kiwi's code doesn't run correctly, this will let us know :)

// Track current health for damage calculations.
AddListener("tick_always", 5, function(timeDelta)
{
    if(!IsRoundOver() && IsAnyBossAlive())
    {
        local boss = GetBossPlayers()[0];
        currentHealth = boss.GetHealth();
    }
});

::COLOR_MERCS <- TF_TEAM_MERCS == 2 ? "\x07FF3F3F" : "\x0799CCFF"
::COLOR_BOSS <- TF_TEAM_BOSS == 2 ? "\x07FF3F3F" : "\x0799CCFF"
::COLOR_SPECIAL <- "\x07FCD303"

// Credit to valve wiki: https://developer.valvesoftware.com/wiki/Team_Fortress_2/Scripting/VScript_Examples#Getting_the_userid_from_a_player_handle
::PlayerManager <- FindByClassname(null, "tf_player_manager")
::GetPlayerUserID <- function(player)
{
    return GetPropIntArray(PlayerManager, "m_iUserID", player.entindex())
}

// Helper to erase listeners we want to replace.
function EraseListener(event, order, indexToRemove)
{
    local listenerToRemove = null;
    if(listeners[event] == null) {
        return;
    }
    local count = 0;
    for(local i = 0; i < listeners[event].len(); i++)
    {
        if(listeners[event][i][0] == order && count == indexToRemove) {
            listenerToRemove = i;
            break;
        } else if (listeners[event][i][0] == order) {
            count++;
        }
    }
    if(listenerToRemove != null)
    {

        local sizeBefore = listeners[event].len();
        listeners[event].remove(listenerToRemove);
        local sizeAfter = listeners[event].len();

        if(sizeAfter - sizeBefore == 1)
        {
            printl("Removed listener "+event+" "+order);
        } else {
            printl("ERROR in removing listener "+event+" "+order);
        }
    }
}

PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "vsh_megapunch_shockwave" })
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "vsh_mighty_slam" });
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "stomp_text" });

IncludeScript("vsh_addons/health.nut");
IncludeScript("vsh_addons/damage_scoring.nut");
IncludeScript("vsh_addons/round_time.nut");
IncludeScript("vsh_addons/control_point.nut");
IncludeScript("vsh_addons/brave_jump_dampening.nut");
IncludeScript("vsh_addons/rps_damage_increase.nut");
IncludeScript("vsh_addons/anti_afk.nut");
IncludeScript("vsh_addons/killstreaks.nut");
IncludeScript("vsh_addons/mighty_slam_fix.nut");
IncludeScript("vsh_addons/player_glows.nut");
IncludeScript("vsh_addons/gardennotify.nut");
