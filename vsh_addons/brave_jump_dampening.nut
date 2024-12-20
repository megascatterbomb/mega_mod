local jumpCooldown = 3;

// OVERRIDE: bosses\generic\abilities\brave_jump.nut::BraveJumpTrait::OnFrameTickAlive
function BraveJumpTrait::OnFrameTickAlive()
{
    local time = Time();
    local buttons = GetPropInt(boss, "m_nButtons");

    if (!boss.IsOnGround())
    {
        if (jumpStatus == BOSS_JUMP_STATUS.WALKING)
            jumpStatus = BOSS_JUMP_STATUS.JUMP_STARTED;
        else if (jumpStatus == BOSS_JUMP_STATUS.JUMP_STARTED && !(buttons & IN_JUMP))
            jumpStatus = BOSS_JUMP_STATUS.CAN_DOUBLE_JUMP;
    }
    else
    {
        if (jumpStatus == BOSS_JUMP_STATUS.DOUBLE_JUMPED)
        {
            boss.SetGravity(1);
        }
        jumpStatus = BOSS_JUMP_STATUS.WALKING;
    }

    if (buttons & IN_JUMP && jumpStatus == BOSS_JUMP_STATUS.CAN_DOUBLE_JUMP && charges > 0)
    {
        if (!IsRoundSetup() && time - voiceLinePlayed > 1.5)
        {
            voiceLinePlayed = time;
            if (charges > 0)
                EmitPlayerVO(boss, "jump");
        }

        jumpStatus = BOSS_JUMP_STATUS.DOUBLE_JUMPED;
        Perform();
        charges = 0;
        braveJumpCharges = 0;
    }

    if (shouldNotifyJump && time > lastTimeJumped + API_GetInt("setup_length") + 30)
        NotifyJump();
    if (time - lastTimeJumped >= jumpCooldown)
    {
        charges = 5;
        braveJumpCharges = 5;
    }
}

local cooldown_text_tf;

// OVERRIDE: bosses\generic\abilities\brave_jump.nut::BraveJumpTrait::Perform
function BraveJumpTrait::Perform()
{
    shouldNotifyJump = false;
    lastTimeJumped = Time();

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
    newVelocity *= 300 * jumpSpamForwardVel[jumpSpamForwardVel.len() - 1];
    newVelocity.z = jumpForce * jumpSpamUpwardVel[jumpSpamUpwardVel.len() - 1];

    boss.SetGravity(jumpSpamGrav[jumpSpamGrav.len() - 1]);

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

// OVERRIDE: bosses\generic\abilities\brave_jump.nut::BraveJumpTrait::NotifyJump
function BraveJumpTrait::NotifyJump()
{
    local boss = GetBossPlayers()[0];
    ClientPrint(boss, 4, "Double jump while in the air!");
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