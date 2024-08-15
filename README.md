# Megascatterbomb's server mods

A collection of VScript mods for various maps that I think improve the overall gameplay experience.

Installation:
- Copy the contents of the repo to `tf/scripts/vscripts/mega_mod`
- Add `script_execute mega_mod/main.nut` to the end of your server.cfg
- You can comment out any maps you don't want to use the mod for within `main.nut`

## arena_perks

### Added a 3:50 time limit for each mini-round.
Time limit chosen so the 3:00 mark coincides with the unlocking of the point. If the time limit is reached, then whichever team has more players alive wins. If both teams have the same amount of living players, then it's a tie.

### Made ties less arbitrary.
When both teams die at exactly the same time (or lose to the time limit), both teams get a point. This is necessary as the game can't last more than 5 rounds. However, if the score is 2-2 and there's a tie, the winning team is chosen arbitrarily. If this exact situation happens, this mod makes the win slightly less arbitrary by awarding the win to whichever team most recently lost a player to death (implying their team lasted longer).