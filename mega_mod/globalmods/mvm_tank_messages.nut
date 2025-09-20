function ShouldApply() {
    return MM_GetGamemode() == MM_Gamemodes.MVM;
}

function LoadAlongsideMapMods() {
    return true;
}

::MM_MVM_Tanks <- [];

::MM_MVM_HookTankMessages <- function () {
    ::MM_MVM_Tanks <- [];
    local path = Entities.FindByClassname(null, "path_track");
    while (path) {
        EntityOutputs.AddOutput(path, "OnPass", "tf_gamerules", "RunScriptCode", "::MM_MVM_HandleTank(activator)", 0, -1)
        path = Entities.FindByClassname(path, "path_track")
    }
}

::MM_MVM_HandleTank <- function(tank) {
    if (tank.GetClassname() != "tank_boss" || tank.GetScriptScope() != null) {
        return;
    }
    tank.ValidateScriptScope();

    ::MM_MVM_Tanks.append({
        entID = tank.entindex()
        startHealth = tank.GetMaxHealth()
        playerDamages = {}
        handle = tank
    });

    ClientPrint(null, 3, "\x0799CCFFTank spawned with " + tank.GetMaxHealth().tostring() + " health!");
}

::MM_MVM_HandleTankDamage <- function(params) {
    local tankInfo = null;

    foreach(t in ::MM_MVM_Tanks) {
        if (!t.handle || !t.handle.IsValid()) continue;
        if (t.entID == params.entindex) {
            tankInfo = t;
            break;
        }
    }

    if (tankInfo == null) return;

    if(!tankInfo.playerDamages.rawin(params.attacker_player)) {
        tankInfo.playerDamages[params.attacker_player] <- 0;
    }

    // Prevent over-crediting of killing hit to tank.
    local damage = params.damageamount > params.health ? params.health : params.damageamount;

    tankInfo.playerDamages[params.attacker_player] <- tankInfo.playerDamages[params.attacker_player] + damage;

    EntFire("tf_gamerules", "RunScriptCode", "::MM_MVM_HandleTankDeath()", 0, null);
}

::MM_MVM_HandleTankDeath <- function () {

    for (local i = ::MM_MVM_Tanks.len() - 1; i >= 0; i--) {
        local tankInfo = ::MM_MVM_Tanks[i];
        if(tankInfo.handle != null && tankInfo.handle.IsValid()) continue;

        ::MM_MVM_Tanks.remove(i);

        local playerDamages = [];
        foreach (userID, damage in tankInfo.playerDamages) {
            playerDamages.append([userID, damage]);
        }

        local mvp = playerDamages.sort(function(a, b) { return b[1] - a[1]; })[0];

        local userID = mvp != null ? mvp[0] : null;
        local player = userID != null ? GetPlayerFromUserID(userID) : null;
        local name = NetProps.GetPropString(player, "m_szNetname");
        local damage = mvp != null ? mvp[1] : 0;
        local damagePercent = floor((damage.tofloat() / tankInfo.startHealth) * 100);

        ClientPrint(null, 3, "\x07FF3F3FTank MVP: "
            + (player != null ? (name + " (" + damage + " damage, " + damagePercent +  "%)") : "<unknown>"));
    }
}

ApplyMod <- function () {
    local root = getroottable();

    this.OnGameEvent_teamplay_round_start <- function (event) {
        EntFire("tf_gamerules", "RunScriptCode", "::MM_MVM_HookTankMessages()", 0, null);
    }.bindenv(this);

    this.OnGameEvent_npc_hurt <- MM_MVM_HandleTankDamage;

    ::MM_MVM_HookTankMessages();

    local scope = this;
    scope.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
    ::ClearGameEventCallbacks <- function () {
        scope.ClearGameEventCallbacks()
        ::__CollectGameEventCallbacks(scope)
    };

    ::__CollectGameEventCallbacks(this);
}.bindenv(this);

