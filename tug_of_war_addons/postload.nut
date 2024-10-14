IncludeScript("mega_mod/util.nut");

mm_cart_trucktrain <- null;

local RED_PATH_BASE = null;
local BLU_PATH_BASE = null;

function MM_OvertimeInit() {
    local trainName = GetPropString(team_train_watcher, "m_iszTrain");
    mm_cart_trucktrain = MM_GetEntByName(trainName);

    RED_PATH_BASE = NetProps.GetPropString(team_train_watcher, "m_iszGoalNode");
    BLU_PATH_BASE = NetProps.GetPropString(team_train_watcher, "m_iszStartNode");
    // EntityOutputs.AddOutput(MM_GetEntByName(RED_PATH_BASE), "OnPass", mm_cart_trucktrain.GetName(), "TeleportToPathTrack", RED_PATH_BASE, 0, -1);
    // EntityOutputs.AddOutput(MM_GetEntByName(BLU_PATH_BASE), "OnPass", mm_cart_trucktrain.GetName(), "TeleportToPathTrack", BLU_PATH_BASE, 0, -1);

    EntFireByHandle(self, "RunScriptCode", "MM_OvertimeStart()", 300.0, null, null);
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

    NetProps.SetPropFloat(mm_cart_trucktrain, "m_maxSpeed", floor(oldSpeed * 1.1));
    NetProps.SetPropFloat(mm_cart_trucktrain, "m_flAccelSpeed", min(oldAccel + 5, 280));
    NetProps.SetPropFloat(mm_cart_trucktrain, "m_flDecelSpeed", min(oldDecel + 10, 600));

    EntFireByHandle(self, "RunScriptCode", "MM_OvertimeLoop()", 30.0, null, null);
}

function MM_TeleportToPoint(team) {
    local dest;
    if (team == TF_TEAM_RED) {
        dest = RED_PATH_BASE;
    } else if (team == TF_TEAM_BLUE) {
        dest = BLU_PATH_BASE;
    } else {
        return;
    }

    mm_cart_trucktrain.AcceptInput("TeleportToPathTrack", dest, null, null);
}

// OVERRIDE: Needed to fix the rollback hud for short delays
function UpdatePayloadHUD()
{
    local cartOwnerTeam = cart_moving_point.GetTeam();

    //Cart Position on the HUD
    local cartPos = GetPropFloat(team_train_watcher, "m_flTotalProgress");
    cartPos = ceil(cartPos * 255);
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
    // Move rollback HUD code to else block so it doesn't override any situation where players are pushing the cart.
    } else {
        local countdown = floor(Time() - nextRollbackTS + 10);
        if (countdown >= 0)
        {
            if (countdown < 7)
                texCoords = countdown * 125 + 0.5;
            else
                texCoords = (countdown - 6) * 125 + 0.75;
        }
        // Icon used depends solely on the choice of rollback direction
        if (CART_ROLLBACK_SPEED[rollBackTeam] > 0)
            texCoords = 620.75;
        else if (CART_ROLLBACK_SPEED[rollBackTeam] < 0)
            texCoords = 502.75;
    }
    prevCapSpeed = capSpeed;

    SetPropFloat(water_lod_control, "m_flCheapWaterEndDistance", texCoords);
}

MM_OvertimeInit();