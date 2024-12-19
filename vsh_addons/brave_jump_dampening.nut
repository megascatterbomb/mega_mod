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
        charges = 4;
        braveJumpCharges = 4;
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
    newVelocity *= 300 * jumpSpamForwardVel[4];
    newVelocity.z = jumpForce * jumpSpamUpwardVel[4];

    boss.SetGravity(jumpSpamGrav[4]);

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

// OVERRIDE: bosses\generic\misc\ability_hud.nut::AbilityHudTrait::OnTickAlive
function AbilityHudTrait::OnTickAlive(timeDelta)
{
    if (!(player in hudAbilityInstances))
    return;

    local progressBarTexts = [];
    local overlay = "";
    foreach(ability in hudAbilityInstances[player])
    {
        local percentage = ability.MeterAsPercentage();
        local progressBarText = BigToSmallNumbers(ability.MeterAsNumber())+" ";
        local i = 13;
        for(; i < clampCeiling(100, percentage); i+=13)
            progressBarText += "▰";
        for(; i <= 100; i+=13)
            progressBarText += "▱";
        progressBarTexts.push(progressBarText);
        // MEGAMOD: Don't gray out Mighty Slam as it's always available because of our Brave Jump changes.
        if (percentage >= 100)
            overlay += "1";
        else
            overlay += "0";
    }
    if (braveJumpCharges >= 2)
        overlay += "0";
    else
        overlay += cos(Time() * 12) < 0 ? "1" : "2";

    EntFireByHandle(game_text_charge, "AddOutput", "message "+progressBarTexts[0], 0, boss, boss);
    EntFireByHandle(game_text_charge, "Display", "", 0, boss, boss);

    EntFireByHandle(game_text_punch, "AddOutput", "message "+progressBarTexts[1], 0, boss, boss);
    EntFireByHandle(game_text_punch, "Display", "", 0, boss, boss);

    EntFireByHandle(game_text_slam, "AddOutput", "message "+progressBarTexts[2], 0, boss, boss);
    EntFireByHandle(game_text_slam, "Display", "", 0, boss, boss);

    player.SetScriptOverlayMaterial(API_GetString("ability_hud_folder") + "/" + overlay);
}