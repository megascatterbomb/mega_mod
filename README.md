# Megascatterbomb's server mods

A collection of VScript mods for various maps that I think improve the overall gameplay experience.

Installation:
- Copy the contents of the repo to `tf/scripts/vscripts/mega_mod`
- Add `script_execute mega_mod/main.nut` to the end of your server.cfg
- You can comment out any maps you don't want to use the mod for within `main.nut`

# arena_perks

## Added a 3:50 time limit for each mini-round.
Time limit chosen so the 3:00 mark coincides with the unlocking of the point. If the time limit is reached, then whichever team has more players alive wins. If both teams have the same amount of living players, then it's a tie.

## Made ties less arbitrary.
When both teams die at exactly the same time (or lose to the time limit), both teams get a point. This is necessary as the game can't last more than 5 rounds. However, if the score is 2-2 and there's a tie, the winning team is chosen arbitrarily. If this exact situation happens, this mod makes the win slightly less arbitrary by awarding the win to whichever team most recently lost a player to death (implying their team lasted longer).

# Payload Race

## Added Overtime

Currently supported maps: `plr_bananabay`, `plr_hightower`.

Stage 1 and 2 of Nightfall feature an overtime. This mod copies that logic into other maps using nothing but VScript, with some additional QoL features.

After 10 minutes, the map enters overtime. If neither cart is being pushed, they will both slowly inch forward. Pushing either cart will result in the other cart stopping (potentially rolling backwards). After a further 5 minutes, all rollback zones are disabled to guarantee a winner in a reasonable timeframe. The mod basically replaces all vanilla PLR logic, as trying to utiize existing rollback/rollforward zones, hightower elevators, crossings, map logic, etc is a pain.

### Map specific quirks:
- On Hightower, rollback zones will be disabled if either cart is at the elevator and the round is in overtime. Unfortunately, Hightower's elevators are too jank for me to work around at this time.