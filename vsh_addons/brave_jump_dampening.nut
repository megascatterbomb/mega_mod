local jumped = false;
local jumpCooldown = 3;
local lastDisplayTime = Time()

function BraveJumpTrait::OnFrameTickAlive()
{
    local buttons = GetPropInt(boss, "m_nButtons");

    if (!boss.IsOnGround())
    {
        if (jumpStatus == BOSS_JUMP_STATUS.WALKING)
            jumpStatus = BOSS_JUMP_STATUS.JUMP_STARTED;
        else if (jumpStatus == BOSS_JUMP_STATUS.JUMP_STARTED && !(buttons & IN_JUMP))
            jumpStatus = BOSS_JUMP_STATUS.CAN_DOUBLE_JUMP;
    }
    else
        jumpStatus = BOSS_JUMP_STATUS.WALKING;

    if (buttons & IN_JUMP && jumpStatus == BOSS_JUMP_STATUS.CAN_DOUBLE_JUMP)
    {
        if(Time() < lastTimeJumped + jumpCooldown)
        {
            // if (lastDisplayTime + 0.7 <= Time())
            // {
            //     // shows brave jump timer in chat upon trying to doublejump (to counteract some players not being able to see game_text_tf)
            //     // hello hi kiwi here probablyt a better way to do this but im stupid :steamhappy:
            //     local jumpTimeCeil = ceil(3 - (Time() - lastTimeJumped))
            //     ClientPrint(boss, 4, "\x03Brave Jump ready in " + jumpTimeCeil + " seconds.")
            //     lastDisplayTime = Time()
            // }
            return
        }

        lastTimeJumped = Time();
        jumped = true;
        if (!IsRoundSetup() && Time() - voiceLinePlayed > 1.5)
        {
            voiceLinePlayed = Time();
            EmitPlayerVO(boss, "jump");
        }

        jumpStatus = BOSS_JUMP_STATUS.DOUBLE_JUMPED;
        Perform();
    }

    if (!jumped && Time() > lastTimeJumped + 30)
    {
        NotifyJump();
    }
}

local cooldown_text_tf;

function BraveJumpTrait::Perform()
{
    local buttons = GetPropInt(boss, "m_nButtons");
    local eyeAngles = boss.EyeAngles();
    local forward = eyeAngles.Forward();
    forward.z = 0;
    forward.Norm();
    local left = eyeAngles.Left();
    left.z = 0;
    left.Norm();

    local forwardmove = 0
    if (buttons & IN_FORWARD)
        forwardmove = 1;
    else if (buttons & IN_BACK)
        forwardmove = -1;
    local sidemove = 0
    if (buttons & IN_MOVELEFT)
        sidemove = -1;
    else if (buttons & IN_MOVERIGHT)
        sidemove = 1;

    local newVelocity = Vector(0,0,0);
    newVelocity.x = forward.x * forwardmove + left.x * sidemove;
    newVelocity.y = forward.y * forwardmove + left.y * sidemove;
    newVelocity.Norm();
    newVelocity *= 300;
    newVelocity.z = jumpForce

    local currentVelocity = boss.GetAbsVelocity();
    if (currentVelocity.z < 300)
        currentVelocity.z = 0;

    SetPropEntity(boss, "m_hGroundEntity", null);
    boss.SetAbsVelocity(currentVelocity + newVelocity);

    for(local i = 0; i < jumpCooldown; i++)
    {
        RunWithDelay("BraveJumpNotifyJump(" + (jumpCooldown - i) + ")", null, i);
    }
    RunWithDelay("BraveJumpNotifyJump(0)", null, jumpCooldown);
    RunWithDelay("BraveJumpNotifyJump(-1)", null, jumpCooldown + 2);
}

function BraveJumpNotifyJump(secondsLeft) {
    local boss = GetBossPlayers()[0];
    if(secondsLeft < 0) {
        // TODO: find a way to blank the csay.
    } else if (secondsLeft == 0) {
        ClientPrint(boss, 4, "Brave Jump Ready!")
    } else {
        ClientPrint(boss, 4, "Brave Jump ready in " + secondsLeft + " seconds.")
    }
}