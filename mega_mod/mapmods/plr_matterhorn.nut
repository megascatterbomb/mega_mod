ClearGameEventCallbacks();
IncludeScript("mega_mod/common/plr_overtime.nut");

::ELEVATOR_OVERTIME_SPEED <- 0.1;
::LIFT_BOTTOM_THRESHOLD <- 0.676;
::LIFT_BOTTOM_HYSTERESIS <- 0.001;

function OnGameEvent_teamplay_round_start(params) {

    InitGlobalVars();

    ::PLR_TIMER_NAME <- "ssplr_timer";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    PLR_TEAMS[2].cartsparks = MM_GetEntArrayByName("ssplr_red_cartsparks");
    PLR_TEAMS[3].cartsparks = MM_GetEntArrayByName("ssplr_blu_cartsparks");

    PLR_TEAMS[2].flashinglight = MM_GetEntByName("ssplr_red_flashinglight");
    PLR_TEAMS[3].flashinglight = MM_GetEntByName("ssplr_blu_flashinglight");

    PLR_TEAMS[2].pushzone = MM_GetEntByName("ssplr_red_pushzone");
    PLR_TEAMS[3].pushzone = MM_GetEntByName("ssplr_blu_pushzone");

    PLR_TEAMS[2].train = MM_GetEntByName("ssplr_red_train");
    PLR_TEAMS[3].train = MM_GetEntByName("ssplr_blu_train");

    PLR_TEAMS[2].custom.elv <- null;
    PLR_TEAMS[3].custom.elv <- null;
    PLR_TEAMS[2].custom.atBottom <- false;
    PLR_TEAMS[3].custom.atBottom <- false;

    PLR_TEAMS[2].watcher = MM_GetEntByName("ssplr_red_watcherA");
    PLR_TEAMS[3].watcher = MM_GetEntByName("ssplr_blu_watcherA");

    PLR_TEAMS[2].logiccase = PLR_CreateLogicCase(2, "mm_plr_logiccase_red");
    PLR_TEAMS[3].logiccase = PLR_CreateLogicCase(3, "mm_plr_logiccase_blu");

    PLR_TEAMS[2].custom.liftLights <- MM_GetEntArrayByName("ssplr_red_lift_finale1_lights");
    PLR_TEAMS[3].custom.liftLights <- MM_GetEntArrayByName("ssplr_blu_lift_finale1_lights");

    PLR_TEAMS[2].custom.wheel <- MM_GetEntByName("wheel_red");
    PLR_TEAMS[3].custom.wheel <- MM_GetEntByName("wheel_blu");

    // Elevator speed configs (used when on lift)
    PLR_TEAMS[2].custom.liftSpeeds <- {"s1" : 0.33, "s2" : 0.5, "s3" : 0.66, "ot" : 0.05, "rb" : -0.5};
    PLR_TEAMS[3].custom.liftSpeeds <- {"s1" : 0.33, "s2" : 0.5, "s3" : 0.66, "ot" : 0.05, "rb" : -0.5};

    // Rollback zones
    PLR_AddRollbackZone(2, "ssplr_red_path_lift_finale1_4", null, "ssplr_red_path_lift_finale1_1");
    PLR_AddRollbackZone(3, "ssplr_blu_path_lift_finale1_4", null, "ssplr_blu_path_lift_finale1_1");

    // Crossover logic replacement
    foreach(entName in [
        "ssplr_red_crossover1_branch"
        "ssplr_red_crossover1_relay"
        "ssplr_blu_crossover1_branch"
        "ssplr_blu_crossover1_relay"
    ]) {
        MM_GetEntByName(entName).Kill();
    }

    PLR_AddCrossing([
        ["ssplr_red_pathA_12", "ssplr_red_pathA_17", 2],
        ["ssplr_blu_pathA_12", "ssplr_blu_pathA_17", 3]
    ]);

    // Timer logic replacement
    EntityOutputs.RemoveOutput(PLR_TIMER, "OnSetupFinished", PLR_TIMER_NAME, "Disable", "");
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", "!self", "SetTime", PLR_GetRoundTimeString(), 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "PLR_StartOvertime()", 0, -1);

    // team_train_watcher is no longer in charge.
    NetProps.SetPropBool(PLR_TEAMS[2].watcher, "m_bHandleTrainMovement", false);
    NetProps.SetPropBool(PLR_TEAMS[3].watcher, "m_bHandleTrainMovement", false);

    // Hook pre-lift pushzones.
    EntityOutputs.AddOutput(PLR_TEAMS[2].pushzone, "OnNumCappersChanged2", "mm_plr_logiccase_red", "InValue", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[3].pushzone, "OnNumCappersChanged2", "mm_plr_logiccase_blu", "InValue", "", 0, -1);

    EntityOutputs.AddOutput(PLR_TEAMS[2].pushzone, "OnNumCappersChanged2", "ssplr_red_watcherA", "SetNumTrainCappers", "", 0, -1);
    EntityOutputs.AddOutput(PLR_TEAMS[3].pushzone, "OnNumCappersChanged2", "ssplr_blu_watcherA", "SetNumTrainCappers", "", 0, -1);

    // Elevator logic replacement
    foreach (entName in [
        // HUD logic
        // We have to kill these then recreate the status relays as is because we need to enable fast retriggers.
        // Also there's two copies of each of these entities for some reason.
        "status_red"
        "status_red"
        "status_blu"
        "status_blu"
        "status_yellow"
        "status_yellow"
        "status_white"
        "status_white"
        "status_off"
        "status_off"
        "branch_bottomOut"
        "branch_bottomOut"
        "gate1_overload_relay"
        "gate1_alarm_relay"

        // Listeners
        "listener_bothPushing"
        "listener_bothLoaded"

        // Branches
        "branch_areBothBeingPushed"
        "branch_isOneAtBottom"
        "branch_areBothNotBeingPushed"
        "branch_isRedBeingPushed"

        // RED - movement decision logic
        "ssplr_red_lift_finale1_pushingcase"
        "ssplr_red_lift_finale1_rollcase"
        "ssplr_red_lift_finale1_staycase"
        "ssplr_red_lift_rollback_relay_rb1"
        "ssplr_red_lift_finale1_rollback"
        "ssplr_red_lift_finale1_relay_embark"

        // BLU - movement decision logic
        "ssplr_blu_lift_finale1_pushingcase"
        "ssplr_blu_lift_finale1_rollcase"
        "ssplr_blu_lift_finale1_staycase"
        "ssplr_blu_lift_rollback_relay_rb1"
        "ssplr_blu_lift_finale1_rollback"
        "ssplr_blu_lift_finale1_relay_embark"

        // RED - listener logic
        "count_redPushers1"
        "count_redPushers2"
        "case_setRedPushing"
        "branch_isRedPushing"
        "relay_redIsOnLift"
        "relay_redBottom"
        "relay_isRedLiftAtBottom"
        "branch_isRedLiftAtBottom"
        "branch_isRedLoaded"

        // BLU - listener logic
        "count_bluPushers1"
        "count_bluPushers2"
        "case_setBluPushing"
        "branch_isBluPushing"
        "relay_bluIsOnLift"
        "relay_bluBottom"
        "relay_isBluLiftAtBottom"
        "branch_isBluLiftAtBottom"
        "branch_isBluLoaded"
    ]) {
        MM_GetEntByName(entName).Kill();
    }

    local ssplr_red_lift_finale1_relay_embark = SpawnEntityFromTable("logic_relay", {
        targetname = "ssplr_red_lift_finale1_relay_embark"
    });
    local ssplr_blu_lift_finale1_relay_embark = SpawnEntityFromTable("logic_relay", {
        targetname = "ssplr_blu_lift_finale1_relay_embark"
    });

    EntityOutputs.AddOutput(ssplr_red_lift_finale1_relay_embark, "OnTrigger", "ssplr_red_train", "AddOutput", "manualaccelspeed 999", 0.3, -1);
    EntityOutputs.AddOutput(ssplr_red_lift_finale1_relay_embark, "OnTrigger", "ssplr_red_train", "AddOutput", "manualdecelspeed 999", 0.3, -1);
    EntityOutputs.AddOutput(ssplr_red_lift_finale1_relay_embark, "OnTrigger", "!self", "RunScriptCode", "SwitchToElevator(2)", 0, 1);

    EntityOutputs.AddOutput(ssplr_blu_lift_finale1_relay_embark, "OnTrigger", "ssplr_blu_train", "AddOutput", "manualaccelspeed 999", 0.3, -1);
    EntityOutputs.AddOutput(ssplr_blu_lift_finale1_relay_embark, "OnTrigger", "ssplr_blu_train", "AddOutput", "manualdecelspeed 999", 0.3, -1);
    EntityOutputs.AddOutput(ssplr_blu_lift_finale1_relay_embark, "OnTrigger", "!self", "RunScriptCode", "SwitchToElevator(3)", 0, 1);

    SpawnEntityFromTable("logic_relay", {
        targetname = "status_off"
        spawnflags = "2"
        "OnTrigger#1": "gate1_alarm_yellow_flash,Stop,,0,-1"
        "OnTrigger#2": "gate1_emergency_light,SetAnimation,idle,0,-1"
        "OnTrigger#3": "gate1_emergency_light,Skin,1,0,-1"
        "OnTrigger#4": "status_sign_blu,Skin,4,0,-1"
        "OnTrigger#5": "status_sign_hold,Skin,0,0,-1"
        "OnTrigger#6": "status_sign_red,Skin,2,0,-1"
        "OnTrigger#7": "player,RunScriptCode,self.SetScriptOverlayMaterial(\"hud/plr_gray\")"
    });

    SpawnEntityFromTable("logic_relay", {
        targetname = "status_red"
        spawnflags = "2"
        "OnTrigger#1": "gate1_alarm_yellow_flash,Stop,,0,-1"
        "OnTrigger#2": "gate1_emergency_light,SetAnimation,spin,0,-1"
        "OnTrigger#3": "gate1_emergency_light,Skin,4,0,-1"
        "OnTrigger#4": "status_sign_blu,Skin,4,0,-1"
        "OnTrigger#5": "status_sign_hold,Skin,0,0,-1"
        "OnTrigger#6": "status_sign_red,Skin,3,0,-1"
        "OnTrigger#7": "player,RunScriptCode,self.SetScriptOverlayMaterial(\"hud/plr_red\")"
        "OnTrigger#8": "gate1_alarm_relay,Trigger,,0,-1"
        "OnTrigger#9": "gate1_overload_relay,Trigger,,0,-1"
    });

    SpawnEntityFromTable("logic_relay", {
        targetname = "status_blu"
        spawnflags = "2"
        "OnTrigger#1": "gate1_alarm_yellow_flash,Stop,,0,-1"
        "OnTrigger#2": "gate1_emergency_light,SetAnimation,spin,0,-1"
        "OnTrigger#3": "gate1_emergency_light,Skin,3,0,-1"
        "OnTrigger#4": "status_sign_blu,Skin,5,0,-1"
        "OnTrigger#5": "status_sign_hold,Skin,0,0,-1"
        "OnTrigger#6": "status_sign_red,Skin,2,0,-1"
        "OnTrigger#7": "player,RunScriptCode,self.SetScriptOverlayMaterial(\"hud/plr_blue\")"
        "OnTrigger#8": "gate1_alarm_relay,Trigger,,0,-1"
        "OnTrigger#9": "gate1_overload_relay,Trigger,,0,-1"
    });

    SpawnEntityFromTable("logic_relay", {
        targetname = "status_yellow"
        spawnflags = "2"
        "OnTrigger#1": "gate1_alarm_yellow_flash,Start,,0,-1"
        "OnTrigger#2": "gate1_emergency_light,SetAnimation,spin,0,-1"
        "OnTrigger#3": "gate1_emergency_light,Skin,2,0,-1"
        "OnTrigger#4": "status_sign_blu,Skin,4,0,-1"
        "OnTrigger#5": "status_sign_hold,Skin,1,0,-1"
        "OnTrigger#6": "status_sign_red,Skin,2,0,-1"
        "OnTrigger#7": "player,RunScriptCode,self.SetScriptOverlayMaterial(\"hud/plr_yellow\")"
    });

    // track elevator bottom out
    AddThinkToEnt(PLR_TEAMS[2].watcher, "CheckBottomThink_2");
    AddThinkToEnt(PLR_TEAMS[3].watcher, "CheckBottomThink_3");

    // Add thinks to carts
    PLR_CreateCartAutoUpdater(2, PLR_TEAMS[2].train);
    PLR_CreateCartAutoUpdater(3, PLR_TEAMS[3].train);
}

// Override PLR_Advance/PLR_Stop/PLR_TriggerRollback to also control elevator + wheel
::PLR_Advance_Base <- PLR_Advance;
::PLR_Stop_Base <- PLR_Stop;
::PLR_TriggerRollback_Base <- PLR_TriggerRollback;

function PLR_Advance(team, baseSpeed, dynamic = true) {
    local t = PLR_TEAMS[team];
    if (t.custom.elv) {
        dynamic = false;
        t.custom.atBottom = false;
    }
    PLR_Advance_Base(team, baseSpeed, dynamic);
    if(t.custom.elv) {
        EntFireByHandle(t.custom.elv, "SetSpeedDirAccel", "" + baseSpeed, 0, null, null);
        EntFireByHandle(t.custom.wheel, "SetSpeed", "" + baseSpeed, 0, null, null);
        foreach(light in t.custom.liftLights) {
            EntFireByHandle(light, "Start", "", 0, null, null);
        }
    }
}

function PLR_Stop(team) {
    local t = PLR_TEAMS[team];
    PLR_Stop_Base(team);
    if(t.custom.elv) {
        EntFireByHandle(t.custom.elv, "SetSpeedDirAccel", "0.0", 0, null, null);
        local currentSpeed = NetProps.GetPropFloat(t.custom.elv, "m_flSpeed");
        if (currentSpeed == 0) EntFireByHandle(t.custom.elv, "Stop", "", 0, null, null);
        EntFireByHandle(t.custom.wheel, "Stop", "", 0, null, null);
        foreach(light in t.custom.liftLights) {
            EntFireByHandle(light, "Stop", "", 0, null, null);
        }
    }
}

function PLR_TriggerRollback(team, multiplier = 1.0) {
    local t = PLR_TEAMS[team];
    local rbSpeed = t.rollbackSpeed * multiplier;
    PLR_TriggerRollback_Base(team, multiplier);
    if(t.custom.elv) {
        EntFireByHandle(t.custom.elv, "SetSpeedDirAccel", "" + rbSpeed, 0, null, null);
        EntFireByHandle(t.custom.wheel, "SetSpeed", "" + rbSpeed, 0, null, null);
        foreach(light in t.custom.liftLights) {
            EntFireByHandle(light, "Stop", "", 0, null, null);
        }
    }
}

// Override PLR_UpdateCart for counter-boost logic
::PLR_UpdateCart_Base <- PLR_UpdateCart;

function PLR_UpdateCart(team, pushstate) {
    local t = PLR_TEAMS[team];
    local other = team == 2 ? 3 : 2;
    local otherT = PLR_TEAMS[other];

    if (++PLR_UPDATE_DEPTH > PLR_MAX_UPDATE_DEPTH) {
        --PLR_UPDATE_DEPTH;
        return;
    }

    t.pushstate = pushstate;

    if(t.blocked) {
        --PLR_UPDATE_DEPTH;
        return;
    }

    local liftsBothOn = t.custom.elv && otherT.custom.elv;

    // Counter-boost: if opponent is NOT pushing and NOT at bottom, speed is halved
    local isCounterBoost = !t.custom.elv || (!otherT.custom.atBottom && otherT.pushstate == 0);
    local speedFactor = isCounterBoost ? 1.0 : 0.5;

    if(pushstate == -1) {
        PLR_Stop(team);
        --PLR_UPDATE_DEPTH;
        return;
    }

    if(pushstate == 1) {
        PLR_Advance(team, t.speed1 * speedFactor);
    } else if(pushstate == 2) {
        PLR_Advance(team, t.speed2 * speedFactor);
    } else if(pushstate >= 3) {
        PLR_Advance(team, t.speed3 * speedFactor);
    }

    if(pushstate == 0) {
        if(otherT.pushstate == 0 && OVERTIME_ACTIVE) {
            PLR_Advance(team, t.overtimeSpeed);
            if(!otherT.blocked) PLR_Advance(other, otherT.overtimeSpeed);
        } else if(!(OVERTIME_ACTIVE && ROLLBACK_DISABLED) && t.rollstate == -1
            && !t.custom.atBottom
            && !(t.custom.elv && otherT.custom.elv && otherT.pushstate == 0)) {
            PLR_TriggerRollback(team);
        } else {
            PLR_Stop(team);
        }
    } else if((otherT.custom.elv || OVERTIME_ACTIVE) && otherT.pushstate == 0) {
        PLR_UpdateCart(other, 0);
    }

    // Force update other cart for elevator coordination
    if(liftsBothOn && !OVERTIME_ACTIVE) {
        if(pushstate == 0 && otherT.pushstate == 0) {
            PLR_Stop(other);
        } else if(pushstate != 0 && otherT.pushstate == 0) {
            PLR_TriggerRollback(other);
        }
    }

    UpdateHUD();
    --PLR_UPDATE_DEPTH;
}

function UpdateHUD() {
    local t2 = PLR_TEAMS[2];
    local t3 = PLR_TEAMS[3];

    local toTrigger = null;
    if(!t2.custom.elv || !t3.custom.elv) {
        return;
    } else if(t2.pushstate > 0 && t3.pushstate > 0) {
        toTrigger = "status_off";
    } else if(t2.pushstate > 0 && t3.pushstate == 0 && !t3.custom.atBottom) {
        toTrigger = "status_red";
    } else if(t2.pushstate == 0 && !t2.custom.atBottom && t3.pushstate > 0) {
        toTrigger = "status_blu";
    } else if(!OVERTIME_ACTIVE && t2.pushstate == 0 && t3.pushstate == 0) {
        toTrigger = "status_yellow";
    } else {
        toTrigger = "status_off";
    }

    MM_GetEntByName(toTrigger).AcceptInput("Trigger", "", null, null);
}

function SwitchToElevator(team) {
    local t = PLR_TEAMS[team];
    local lifts = t.custom.liftSpeeds;

    t.blocked = true;
    t.custom.atBottom = true;
    PLR_Advance(team, 1.0);

    if(t.flashinglight) t.flashinglight.AcceptInput("Stop", "", null, null);
    foreach(spark in t.cartsparks) spark.AcceptInput("Stop", "", null, null);

    if(team == 2) {
        t.custom.elv = MM_GetEntByName("ssplr_red_lift_finale1_train");
        t.pushzone = MM_GetEntByName("ssplr_red_lift_finale1_pushzone");
        t.cartsparks = MM_GetEntArrayByName("ssplr_red_lift_finale1_sparks");
        t.flashinglight = null;

        EntityOutputs.AddOutput(MM_GetEntByName("ssplr_red_path_lift_finale1_4"), "OnPass", t.train.GetName(), "Stop", "", 0, 1);
        EntityOutputs.AddOutput(MM_GetEntByName("ssplr_red_path_lift_finale1_4"), "OnPass", t.custom.elv.GetName(), "Stop", "", 0, 1);
        EntityOutputs.AddOutput(MM_GetEntByName("ssplr_red_path_lift_finale1_4"), "OnPass", "!self",
            "RunScriptCode", "PLR_UpdateCart(2, PLR_TEAMS[2].pushstate)", 0.05, 1);

        EntFireByHandle(MM_GetEntByName("ssplr_red_flashinglight"), "Stop", "", 1.0, null, null);
        foreach(spark in MM_GetEntArrayByName("ssplr_red_cartsparks")) EntFireByHandle(spark, "Stop", "", 0.1, null, null);
    } else {
        t.custom.elv = MM_GetEntByName("ssplr_blu_lift_finale1_train");
        t.pushzone = MM_GetEntByName("ssplr_blu_lift_finale1_pushzone");
        t.cartsparks = MM_GetEntArrayByName("ssplr_blu_lift_finale1_sparks");
        t.flashinglight = null;

        EntityOutputs.AddOutput(MM_GetEntByName("ssplr_blu_path_lift_finale1_4"), "OnPass", t.train.GetName(), "Stop", "", 0, 1);
        EntityOutputs.AddOutput(MM_GetEntByName("ssplr_blu_path_lift_finale1_4"), "OnPass", t.custom.elv.GetName(), "Stop", "", 0, 1);
        EntityOutputs.AddOutput(MM_GetEntByName("ssplr_blu_path_lift_finale1_4"), "OnPass", "!self",
            "RunScriptCode", "PLR_UpdateCart(3, PLR_TEAMS[3].pushstate)", 0.05, 1);

        EntFireByHandle(MM_GetEntByName("ssplr_blu_flashinglight"), "Stop", "", 1.0, null, null);
        foreach(spark in MM_GetEntArrayByName("ssplr_blu_cartsparks")) EntFireByHandle(spark, "Stop", "", 0.1, null, null);
    }

    EntityOutputs.AddOutput(t.pushzone, "OnNumCappersChanged2",
        team == 2 ? "mm_plr_logiccase_red" : "mm_plr_logiccase_blu", "InValue", "", 0, -1);

    // Update speed configs for elevator mode
    t.rollbackSpeed = lifts.rb;
    t.overtimeSpeed = lifts.ot;
    t.speed1 = lifts.s1;
    t.speed2 = lifts.s2;
    t.speed3 = lifts.s3;

    EntFireByHandle(Gamerules(), "RunScriptCode", "PLR_Stop(" + team + "); PLR_TEAMS[" + team + "].blocked = false", 1.0, null, null);
    EntFireByHandle(Gamerules(), "RunScriptCode", "PLR_UpdateCart(" + team + ", PLR_TEAMS[" + team + "].pushstate)", 1.05, null, null);

    UpdateHUD();
}

function CheckBottomThink(team) {
    local t = PLR_TEAMS[team];
    local other = team == 2 ? 3 : 2;
    local oldValue = t.custom.atBottom;
    local position = NetProps.GetPropFloat(t.watcher, "m_flTotalProgress");

    local newValue = null;
    if(t.custom.elv && position > LIFT_BOTTOM_THRESHOLD + LIFT_BOTTOM_HYSTERESIS) newValue = false;
    else if(t.custom.elv && position < LIFT_BOTTOM_THRESHOLD) newValue = true;

    if(newValue != null && oldValue != newValue) {
        t.custom.atBottom = newValue;
        EntFireByHandle(Gamerules(), "RunScriptCode", "PLR_UpdateCart(" + team + ", PLR_TEAMS[" + team + "].pushstate)", 0.1, null, null);
        EntFireByHandle(Gamerules(), "RunScriptCode", "PLR_UpdateCart(" + other + ", PLR_TEAMS[" + other + "].pushstate)", 0.1, null, null);
    }
    return -1;
}

// Create captured-think functions for each team
(function() {
    local root = getroottable();
    local teams = [2, 3];
    foreach(team in teams) {
        local thinkName = "CheckBottomThink_" + team;
        local capturedTeam = team;
        root[thinkName] <- function() { return CheckBottomThink(capturedTeam); };
    }
})();

__CollectGameEventCallbacks(this);
