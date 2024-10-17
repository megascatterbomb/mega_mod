// Credit to Mr. Burguers for figuring this out and sharing how to do it in the TF2Maps discord.

local root = getroottable();
local prefix = DoUniqueString("mega");
local mega = root[prefix] <- {};

::MM_CREDITS_RED <- 0;
::MM_CREDITS_BLU <- 0;

::MM_TRIGGERED <- false;

mega.OnGameEvent_teamplay_round_start <- function (event) {
    printl("MEGAMOD: ROUND START");

    ::MegaModRoundStart <- function () {
        if(IsInWaitingForPlayers()) return;

        // For reasons beyond my comprehension, the freaky_fair vscript is attached to an info_target.
        // This means the script only runs *once* when the map loads, meaning that if the line of code
        // below runs more than once, we end up assigning our AwardCreditsToTeam to the base handle as well,
        // creating an infinite loop. https://developer.valvesoftware.com/wiki/Info_target
        if (MM_TRIGGERED == false)
            AwardCreditsToTeamBase <- AwardCreditsToTeam;

        ::MM_TRIGGERED <- true;

        AwardCreditsToTeam <- function (team, amount)
        {
            if (team == Constants.ETFTeam.TF_TEAM_RED) {
                ::MM_CREDITS_RED <- MM_CREDITS_RED + amount;
            } else if (team == Constants.ETFTeam.TF_TEAM_BLUE) {
                ::MM_CREDITS_BLU <- MM_CREDITS_BLU + amount;
            }
            printl("Added " + amount + " credits to team " + team);
            AwardCreditsToTeamBase(team, amount);
        }.bindenv(MM_GetEntByName("scripto").GetScriptScope());

        AwardCreditsToTeamBase(Constants.ETFTeam.TF_TEAM_RED, MM_CREDITS_RED);
        AwardCreditsToTeamBase(Constants.ETFTeam.TF_TEAM_BLUE, MM_CREDITS_BLU);

        // Misc changes

        local captureArea = Entities.FindByClassname(null, "trigger_capture_area");

        while (captureArea != null) {
            if (NetProps.GetPropString(captureArea, "m_iszCapPointName") !=  "cap_middle") {
                // Grant credits for final point capture.
                EntityOutputs.AddOutput(captureArea, "OnCapTeam1", "scripto", "RunScriptCode", "AwardCreditsToTeam(2,400)", 0, -1);
                EntityOutputs.AddOutput(captureArea, "OnCapTeam2", "scripto", "RunScriptCode", "AwardCreditsToTeam(3,400)", 0, -1);
            }
            captureArea = Entities.FindByClassname(captureArea, "trigger_capture_area");
        }

    }.bindenv(MM_GetEntByName("scripto").GetScriptScope())

    EntFireByHandle(MM_GetEntByName("scripto"), "RunScriptCode", "MegaModRoundStart()", 0, null, null);
}

mega.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
::ClearGameEventCallbacks <- function () {
    mega.ClearGameEventCallbacks()
    ::__CollectGameEventCallbacks(mega)
}
::__CollectGameEventCallbacks(mega);