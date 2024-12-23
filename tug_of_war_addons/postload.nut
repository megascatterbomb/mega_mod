IncludeScript("mega_mod/util.nut");

mm_cart_trucktrain <- null;

local initSpeed = 110;
local initAccel = 70;
local initDecel = 150;

local RED_PATH_BASE = null;
local BLU_PATH_BASE = null;

// Max speed cart will arrive at the end of the track
local CART_MAX_ARRIVAL_SPEED = 110;
// Min distance from the end of the track that the cart will travel at full speed
// as a proprtion of the track length.
local CART_MAX_ARRIVAL_DISTANCE = 0.125;

function MM_OvertimeInit() {
    local trainName = GetPropString(team_train_watcher, "m_iszTrain");
    mm_cart_trucktrain = MM_GetEntByName(trainName);

    CART_MAX_ARRIVAL_SPEED = NetProps.GetPropFloat(mm_cart_trucktrain, "m_maxSpeed");

    RED_PATH_BASE = NetProps.GetPropString(team_train_watcher, "m_iszGoalNode");
    BLU_PATH_BASE = NetProps.GetPropString(team_train_watcher, "m_iszStartNode");

    initSpeed = NetProps.GetPropFloat(mm_cart_trucktrain, "m_maxSpeed");
    initAccel = NetProps.GetPropFloat(mm_cart_trucktrain, "m_flAccelSpeed");
    initDecel = NetProps.GetPropFloat(mm_cart_trucktrain, "m_flDecelSpeed");
    // EntityOutputs.AddOutput(MM_GetEntByName(RED_PATH_BASE), "OnPass", mm_cart_trucktrain.GetName(), "TeleportToPathTrack", RED_PATH_BASE, 0, -1);
    // EntityOutputs.AddOutput(MM_GetEntByName(BLU_PATH_BASE), "OnPass", mm_cart_trucktrain.GetName(), "TeleportToPathTrack", BLU_PATH_BASE, 0, -1);

    EntFireByHandle(self, "RunScriptCode", "MM_OvertimeStart()", 600.0, null, null);
}

function MM_OvertimeStart() {
    CART_ROLLBACK_DELAY <- Epsilon * 2;
    CART_ROLLBACK_SPEED <- [
        0,    //UNASSIGNED
        0,    //SPECTATOR
        -0.2,  //RED
        0.2, //BLU
        0,    //TEAM4
        0     //BOSS
    ];
    MM_OvertimeLoop();
}

function MM_OvertimeLoop() {
    local oldSpeed = NetProps.GetPropFloat(mm_cart_trucktrain, "m_maxSpeed");
    local oldAccel = NetProps.GetPropFloat(mm_cart_trucktrain, "m_flAccelSpeed");
    local oldDecel = NetProps.GetPropFloat(mm_cart_trucktrain, "m_flDecelSpeed");

    local newSpeed = min(floor(oldSpeed * 1.1), 10000);
    local newAccel = min(newSpeed * initAccel / initSpeed, 2000);
    local newDecel = newAccel * initDecel / initAccel;

    NetProps.SetPropFloat(mm_cart_trucktrain, "m_maxSpeed", newSpeed);
    NetProps.SetPropFloat(mm_cart_trucktrain, "m_flAccelSpeed", newAccel);
    NetProps.SetPropFloat(mm_cart_trucktrain, "m_flDecelSpeed", newDecel);

    // Force cart speed update
    prevSpeed = 2147483647;
    nextRollbackTS = Time() + Epsilon * 2;

    EntFireByHandle(self, "RunScriptCode", "MM_OvertimeLoop()", 30.0, null, null);
}

// OVERRIDE: tug_of_war.nut::ProcessSpeedAndRollback
function ProcessSpeedAndRollback()
{
    local cartOwnerTeam = cart_moving_point.GetTeam();
    if (cartOwnerTeam == 0)
        return;

    local time = Time();

    local capSpeedBlue = GetPropIntArray(tf_objective_resource, "m_iNumTeamMembers", 24 + cartPointIndex);
    local capSpeedRed = GetPropIntArray(tf_objective_resource, "m_iNumTeamMembers", 16 + cartPointIndex);
    local capSpeed = clampCeiling(3, max(capSpeedRed, capSpeedBlue));

    if (CART_ROLLBACK_DELAY > Epsilon && (capSpeed > 0.1 || GetPropBoolArray(tf_objective_resource, "m_bBlocked", cartPointIndex)))
    {
        nextRollbackTS = time + CART_ROLLBACK_DELAY;
        rollBackTeam = 0;
    }
    local speed;
    if (nextRollbackTS < time)
    {
        rollBackTeam = cartOwnerTeam;
        speed = CART_ROLLBACK_SPEED[rollBackTeam];
    }
    else
    {
        local pushingTeam = capSpeedRed > capSpeedBlue ? TF_TEAM_RED : TF_TEAM_BLUE;
        speed = pushingTeam == cartOwnerTeam
            ? CART_SPEED[cartOwnerTeam][clampCeiling(3, capSpeed)]
            : 0;
    }
    // MEGAMOD: Limit cart speed when approaching the end of the track.
    local cartPos = GetPropFloat(team_train_watcher, "m_flTotalProgress");
    local unclampedMaxSpeed = NetProps.GetPropFloat(mm_cart_trucktrain, "m_maxSpeed");

    if (speed < 0) {
        local maxPermissibleSpeed = (CART_MAX_ARRIVAL_SPEED + (cartPos / CART_MAX_ARRIVAL_DISTANCE) * CART_MAX_ARRIVAL_SPEED) / unclampedMaxSpeed;
        // Speed is negative, approaching BLU base (start of track)
        speed = max(speed, -maxPermissibleSpeed);
    } else if (speed > 0) {
        local maxPermissibleSpeed = (CART_MAX_ARRIVAL_SPEED + ((1 - cartPos) / CART_MAX_ARRIVAL_DISTANCE) * CART_MAX_ARRIVAL_SPEED) / unclampedMaxSpeed;
        // Speed is positive, approaching RED base (cartPos approaches 1)
        speed = min(speed, maxPermissibleSpeed);
    }

    if (prevSpeed != speed)
    {
        printl("Cart pos: " + cartPos + ", speed: " + speed);
        EntFireByHandle(cart_trucktrain, "SetSpeedDirAccel", speed.tostring(), 0, null, null);
        prevSpeed = speed;
    }
}

// OVERRIDE: tug_of_war.nut::UpdatePayloadHUD
// Needed to fix the rollback hud for short delays
function UpdatePayloadHUD()
{
    local cartOwnerTeam = cart_moving_point.GetTeam();

    //Cart Position on the HUD
    local cartPos = GetPropFloat(team_train_watcher, "m_flTotalProgress");
    cartPos = ceil(cartPos * 254);
    SetPropInt(pd_logic, "m_nBlueTargetPoints", cartPos);

    //Set Cart's Team Color
    SetPropFloat(water_lod_control, "m_flCheapWaterStartDistance", [0, 0, 1, 2, 0, 0][cartOwnerTeam]);

    //Capture Progress Bars
    local capturingTeam = GetPropIntArray(tf_objective_resource, "m_iCappingTeam", cartPointIndex);
    local capProgressRaw = capturingTeam == 0 ? 0 : 1 - GetPropFloatArray(tf_objective_resource, "m_flCapPercentages", cartPointIndex);
    if (capProgressRaw > 0.1 && cartOwnerTeam > 1)
        capProgressRaw = capProgressRaw * capProgressRaw - 0.1 * capProgressRaw + 0.1;
    local capProgressRemapped = (capProgressRaw >= 1 || capProgressRaw <= 0.01) ? 0 : (capProgressRaw * 0.72 + 0.15);
    capProgressRemapped = ceil(capProgressRemapped * 255);

    if (capturingTeam == TF_TEAM_BLUE)
    {
        SetPropInt(escrow_blue, "m_nPointValue", capProgressRemapped - cartPos);
        SetPropInt(pd_logic, "m_nRedTargetPoints", 0);
    }
    else if (capturingTeam == TF_TEAM_RED)
    {
        SetPropInt(escrow_blue, "m_nPointValue", -cartPos);
        SetPropInt(pd_logic, "m_nRedTargetPoints", capProgressRemapped);
    }
    else
    {
        SetPropInt(escrow_blue, "m_nPointValue", -cartPos);
        SetPropInt(pd_logic, "m_nRedTargetPoints", 0);
    }

    //Capture Number Display
    //frac portion is U range from 0 to 1
    //int portion is V range from 0 to 1000
    //local texCoords = y.x
    //wait, why did I make it flipped?
    local texCoords = 1000.25;

    local capSpeedRed = GetPropIntArray(tf_objective_resource, "m_iNumTeamMembers", 16 + cartPointIndex);
    local capSpeedBlue = GetPropIntArray(tf_objective_resource, "m_iNumTeamMembers", 24 + cartPointIndex);
    local capSpeed = max(capSpeedRed, capSpeedBlue);

    if (GetPropBoolArray(tf_objective_resource, "m_bBlocked", cartPointIndex))
    {
        SetPropFloat(water_lod_control, "m_flCheapWaterEndDistance", 752.75);
        return;
    }

    if (capSpeed > 0.1)
    {
        local flag = (cartOwnerTeam == TF_TEAM_RED && capSpeedRed > 0.1) || (cartOwnerTeam == TF_TEAM_BLUE && capSpeedBlue > 0.1);
        if (flag || capturingTeam == GetPropIntArray(tf_objective_resource, "m_iTeamInZone", cartPointIndex))
        {
            texCoords = clampCeiling(8, capSpeed) - 1;
            texCoords *= 125.0;
            texCoords += capturingTeam && !flag ? 0.0 : 0.25;
        }
        if (prevCapSpeed < 0.1)
            SetPropFloat(water_lod_control, "m_flCheapWaterStartDistance", GetPropFloat(water_lod_control, "m_flCheapWaterStartDistance") + 0.1);
    // MEGAMOD: Move rollback HUD code to else block so it doesn't override any situation where players are pushing the cart.
    } else {
        local countdown = floor(Time() - nextRollbackTS + 10);
        if (countdown >= 0)
        {
            if (countdown < 7)
                texCoords = countdown * 125 + 0.5;
            else
                texCoords = (countdown - 6) * 125 + 0.75;
        }
        // MEGAMOD: Icon used depends solely on the choice of rollback direction
        if (CART_ROLLBACK_SPEED[rollBackTeam] > 0)
            texCoords = 620.75;
        else if (CART_ROLLBACK_SPEED[rollBackTeam] < 0)
            texCoords = 502.75;
    }
    prevCapSpeed = capSpeed;

    SetPropFloat(water_lod_control, "m_flCheapWaterEndDistance", texCoords);
}

MM_OvertimeInit();