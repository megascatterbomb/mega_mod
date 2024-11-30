# Megascatterbomb's server mods

A collection of VScript mods for various maps that I think improve the overall gameplay experience. If you would like to play on a server with these mods, connect to `tf2.megascatterbomb.com`.

Installation:
- Copy the contents of the repo to `tf/scripts/vscripts`
- Add `script_execute mega_mod/main.nut` to the end of your server.cfg
- You can comment out any maps you don't want to use the mod for within `main.nut`

Project structure:
- /common
  - Script files that may be included by any map-specific mod or global mod when needed. Typically contains templates that may require map-specific setup.
- /global
  - Script files that are included on maps without a map-specific mod. Can be used for gamemode specific stuff by using conditions evaluated on map launch (See mega_mod/global/5cp_anti_stalemate.nut as an example).
- /mapmods
  - Script files that are included on a specific map, determined by the filename.
- /tug_of_war_addons
  - Addons that utilize the official addon support in the Tug-of-war VScript gamemode.
- /vsh_addons
  - Addons that utilize the official addon support in the Versus Saxton Hale VScript gamemode.

# General Improvements

## Force Team Respawn when appropriate

In certain scenarios, it is beneficial to respawn the dead players on one or both teams to improve the gameplay experience.

- In Attack/Defend and Payload maps:
  - Both teams are respawned at the end of setup time.
  - RED team is respawned whenever a control point is captured. This helps prevent steamrolls.

# Gamemode Improvements

## 5CP Anti-stalemate

Due to a lack of effective time limit, control point maps tend to be stalematey as hell. This mod makes the following changes:
- A pair of KOTH-style timers replaces the usual round timer. These timers activate depending on which team owns the middle point.
- The team timers are initialized to the same starting time as the vanilla round timer (10 minutes on most maps, sometimes less, never more).
- No time is ever added to either team's timer during the course of the round.
- If `mp_timelimit` is set, the team timers will start at a lower value to prevent rounds dragging on long past the intended finish time.
- If a team gets their timer to 0, they win.
- The middle point is initially locked for the first 35 seconds of the round.
- All control points have their capture times increased to match the maximum cap time present within the map.
  - There are a couple exceptions (e.g `cp_well`) as they set `team_numcap_2`/`team_numcap_3` to a value other than 1, meaning some point's capture times are raised more than others.

With these changes, the team defending last will have an easier time defending, but if they want to win, they have to push at least past mid.

### Map specific quirks:

On `cp_standin_final`, the same anti-stalemate functionality is present, with these changes:
- The team with the active KOTH timer is determined by which team owns more points. If tied, both timers pause.
- To win by point captures, all three points must be uncontested.

## Payload Race

### Added Overtime

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

## Tug of War

Tug of war can last forever, but not with this mod! After 5 minutes, the cart will move on its own towards the objective in favour of the cart owner's team. Every 30 seconds from then on, the cart's maximum speed will increase. Eventually, it'll be moving so fast that it can't help but be at either end of the track!

The KOTH timer was increased to 3 minutes so that the round is unlikely to end before the anti-stalemate phase without sidelining the vanilla experience, as the anti-stalemate mechanics are really fun to play with.

## Versus Saxton Hale

### New Features:
- Damage logging:
  - Market gardens, backstabs, and telefrags are logged in chat.
  - On death: the damage dealt by the player is broadcast in chat.
    - If the dead ringer is used, a fake message is displayed to Hale only.
    - Insults the player if they do 0 damage.
  - At round end:
    - The top 3 players' damage is listed.
    - The total damage by all players is displayed.
    - Damage by other sources (e.g. Distillery grinder) is listed separately.
    - Winners of RPS are displayed in gold.
    - Shows a percentage of how much health the Mercs managed to chip away.
- Anti-AFK measures:
  - If a player fails to send a keyboard input for 60 seconds, they are killed.
  - When this happens, Hale's health is reduced to compensate, as though the idle player was never there in the first place.
  - Chat messages are sent to the idle player to give them an opportunity to come back before the idle-death.
- Killstreaks:
  - Killstreaks now increment as the mercenaries deal damage to Hale.
  - The streak increments by 1 for every 200 damage dealt to Hale.
  - This does NOT produce any killstreak notifications, but it does enable the visual effects of Professional Killstreak items.
- Player Glows:
  - The last mercenary and Hale can see each other through walls.
  - Prevents that one guy from hiding in a corner for the whole round.

### Changes:
- Legend:
  - $n$ is the number of Mercs still alive.
  - $N$ is the number of Mercs at the start of the round.
  - $H$ is the max health of Hale.
- Hale's health:
  - Changed the formula to match that used in [vsh_facility](https://steamcommunity.com/sharedfiles/filedetails/?id=3225055613), but with a cleaner curve.

    | Mercs   (N)| Vanilla Formula     |
    |:-----------|:--------------------|
    | 1          | $H = 1000$          |
    | 2 - 5      | $H = 40N^2 + 1300$  |
    | 6+         | $H = 40N^2 + 2000$  |

    | Mercs   (N)| New Formula                               |
    |:-----------|:------------------------------------------|
    | 1          | $H = 1000$                                |
    | 2 - 6      | $H = 41N^2 + 2350(0.3 + N/10)$            |
    | 7 - 23     | $H = 41N^2 + 2350$                        |
    | 24+        | $H = 2000(N-23) + 24000$                  |

- Brave Jump:
  - Added a 3 second cooldown. Uses HUD_PRINTCENTER to notify the user.
- Round timer:
  - Setup Time:
    - Extended for high player counts so players can spread out and/or recover from large lag spikes.
    - Old value: 16 seconds.
    - New value: $(N/3)$ seconds, clamped between 16 and 32 seconds.
  - Time before point unlocks:
    - Old behaviour: Starts at 4 minutes, drops to 1 minute once only 5 players are alive.
    - New behaviour: Starts at $max(30, 10N)$ seconds, then clamped down to $max(30, 15n)$ seconds during the round (updated on round start and player death).
  - Stalemate 3 minutes after the point unlocks remains in place, unless the point is captured.
- Rock-Paper-Scissors:
  - Deals 1 million damage to Hale.
    - The default value is only 100k; not enough to cover the maximum possible Hale health.
  - Comically high knockback on Hale's ragdoll when he dies.
- Mighty Slam:
  - Fixed check to prevent low damage (<=30) hits killing low health (<=30) players.
- Control Point:
  - Capturing the point no longer instantly ends the round:
    - If the Mercs cap, they get guaranteed crits on all weapons and a powerful 5 second health regen.
    - If Hale caps, the cooldown on all of his special abilities is reduced to 5 seconds.
  - On capture, the stalemate timer is disabled entirely and the point locks itself permanently.
  - The round will eventually end due to Hale's health changing over time:
    - When the Mercs cap, Hale's health will tick down faster and faster. This guarantees his death if he doesn't manage to kill all of the Mercs first.
    - When Hale caps, his health will tick up faster and faster until it reaches max health, at which point Hale wins the round.
  - The health gained/lost each second starts at 1, then increases by 1 every second.
  - If the Mercs have the point and Hale doesn't do any damage to the Mercs for 30 seconds, an additional 1.05 multiplier is added onto the health drain *each second*.
    - For example, after 45 seconds:
      - Hale will take 45 damage per second.
      - Then a $1.05^{15} = 2.08$ multiplier is applied to the health drain as Hale has not dealt damage for 45 seconds.
      - The final damage per tick is ~94 damage per tick.
    - The multiplier resets to 1.0 once Hale deals damage.
    - The reverse is also true; if Hale owns the point and the mercs don't deal damage to Hale for 30 seconds, Hale's health will regenerate faster.
    - This multiplier resets the moment the team that has the point takes damage from the other team.
  - These changes prevent either side from getting an undeserved victory, as the opponent still has a *slim* chance of winning after the capture.
  - Capturing the point produces exciting gameplay to finish a round as opposed to a sudden cutoff.

# Map Specific/Miscellanious Fixes

## arena_perks

### Added a 2:50 time limit for each mini-round.
Time limit chosen so the 2:00 mark coincides with the unlocking of the point. If the time limit is reached, then whichever team has more players alive wins. If both teams have the same amount of living players, then it's a tie.

### Made ties less arbitrary.
When both teams die at exactly the same time (or the time limit introduced by this mod is reached), both teams get a point. This is necessary as the game can't last more than 5 rounds. However, if the score is 2-2 and there's a tie, the winning team is chosen arbitrarily. If this rare situation occurs, this mod makes the win slightly less arbitrary by awarding the win to whichever team most recently lost a player to death (implying their team lasted longer).

## Cumulative cash on cp_freaky_fair

Too often do people complain about capping on cp_freaky_fair, lest they lose their ability to ~~pay off the japanese mafia~~ purchase some insane combination of upgrades. To prevent this, the cash is preserved between rounds.

## No truces on koth_lakeside_event & koth_viaduct_event

Self-explanatory. Ghost Fort's timer was also reduced to 3:00 (from 7:00).

## Edict optimization on pl_bloodwater

Saved over 300 edicts by removing gameplay-irrelevant elements.

## Fix pl_emerge not counting captures in scoreboard.

In Payload, The team scores are supposed to reflect how many control points that team has captured. That setting isn't enabled in Emerge; this mod fixes that.