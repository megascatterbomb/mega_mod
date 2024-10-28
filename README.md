# Megascatterbomb's server mods

A collection of VScript mods for various maps that I think improve the overall gameplay experience. If you would like to play on a server with these mods, connect to `tf2.megascatterbomb.com`.

Installation:
- Copy the contents of the repo to `tf/scripts/vscripts`
- Add `script_execute mega_mod/main.nut` to the end of your server.cfg
- You can comment out any maps you don't want to use the mod for within `main.nut`

Project structure:
- /common
  - Script files that may be included by any map-specific mod or global mod when needed.
- /global
  - Script files that are included on maps without a map-specific mod. Can be used for gamemode specific stuff by using conditions evaluated on map launch (See mega_mod/global/5cp_anti_stalemate.nut as an example).
- /mapmods
  - Script files that are included on a specific map, determined by the filename.
- /tug_of_war_addons
  - Addons that utilize the official addon support in the Tug-of-war VScript gamemode.

# 5CP Anti-stalemate

Due to a lack of effective time limit, control point maps tend to be stalematey as hell. This mod makes the following changes:
- A pair of KOTH-style timers replaces the usual round timer. These timers activate depending on which team owns the middle point.
- The team timers are initialized to the same starting time as the vanilla round timer (10 minutes on most maps, sometimes less, never more).
- No time is ever added to either team's timer during the course of the round.
- If `mp_timelimit` is set, the team timers will start at a lower value to prevent rounds dragging on long past the intended finish time.
- If a team gets their timer to 0, they win.
- All control points have their capture times increased to match the maximum cap time present within the map.

# arena_perks

## Added a 2:50 time limit for each mini-round.
Time limit chosen so the 2:00 mark coincides with the unlocking of the point. If the time limit is reached, then whichever team has more players alive wins. If both teams have the same amount of living players, then it's a tie.

## Made ties less arbitrary.
When both teams die at exactly the same time (or the time limit introduced by this mod is reached), both teams get a point. This is necessary as the game can't last more than 5 rounds. However, if the score is 2-2 and there's a tie, the winning team is chosen arbitrarily. If this rare situation occurs, this mod makes the win slightly less arbitrary by awarding the win to whichever team most recently lost a player to death (implying their team lasted longer).

# Payload Race

## Added Overtime

Currently supported maps: `plr_bananabay`, `plr_hacksaw`, `plr_hacksaw_event`, `plr_hightower`, `plr_hightower_event`, `plr_nightfall_final`, `plr_pipeline`, [`plr_highertower`](https://steamcommunity.com/sharedfiles/filedetails/?id=899335714).

Stage 1 and 2 of Nightfall feature an overtime. This mod copies that logic into other maps using nothing but VScript, with some additional QoL features.

After 10 minutes, the map enters overtime. If neither cart is being pushed, they will both slowly inch forward. Pushing either cart will result in the other cart stopping (potentially rolling backwards). After a further 5 minutes, all rollback zones are disabled to guarantee a winner in a reasonable timeframe. The mod basically replaces all vanilla PLR logic, as trying to utiize existing rollback/rollforward zones, hightower elevators, crossings, map logic, etc is a pain.

In multi-stage maps, each win on a previous stage will provide winning teams with an advantage on the next stage. In vanilla TF2, this takes the form of the winning team's cart starting ahead of the enemy's cart. This mod adds another advantage: the winning team's cart will move slightly faster when automatically advancing in overtime compared to the enemy's cart.

### Map specific quirks:
- On Hacksaw and Hacksaw Event, the game_text entities that display "hacking" progress now operate on separate channels, so both teams' progress can display simultaneously.
- On Hightower and Hightower Event, rollback zones will be disabled if either cart is at the elevator and the round is in overtime. Unfortunately, Hightower's elevators are too jank for me to work around at this time.
  - Hightower Event disables the rollback zones immediately upon entering overtime as there are no rollback zones other than the elevators in this version of the map. 
- Nightfall:
  - There's two improperly sized clip brushes on stage 3 next to the crossing. This mod spawns a couple of signs that take up the extra space covered by the clip brush, which also provide direction to players.
  - The path_track nodes at the top of the final ramp also use the wrong output; this mod corrects the outputs. Carts will roll slower down the final ramp as a result.

# Tug of War (WIP)

Tug of war can last forever, but not with this mod! After 5 minutes, the cart will move on its own towards the objective in favour of the cart owner's team. Every 30 seconds from then on, the cart's maximum speed will increase. Eventually, it'll be moving so fast that it can't help but be at either end of the track!

The KOTH timer was increased to 3 minutes so that the round is unlikely to end before the anti-stalemate phase without sidelining the vanilla experience, as the anti-stalemate mechanics are really fun to play with.

# Miscellanious Fixes

## Cumulative cash on cp_freaky_fair

Too often do people complain about capping on cp_freaky_fair, lest they lose their ability to ~~pay off the japanese mafia~~ purchase some insane combination of upgrades. To prevent this, the cash is preserved between rounds. Similar to midpoint, the final points now award $400 on capture.

## No truces on koth_lakeside_event & koth_viaduct_event

Self-explanatory. Ghost Fort's timer was also reduced to 3:00 (from 7:00).

## Edict optimization on pl_bloodwater

Saved over 300 edicts by removing gameplay-irrelevant elements.