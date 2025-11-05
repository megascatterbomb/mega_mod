# Megascatterbomb's server mods

A collection of VScript mods for various maps that I think improve the overall gameplay experience. If you would like to play on a server with these mods, connect to the [bomb shelter](https://megascatterbomb.com).

### Installation:
- Copy the contents of the repo to `tf/scripts/vscripts`
- Add `script_execute mega_mod/main.nut` to the end of your server.cfg

### Configuration:
You can disable any mods you don't want to use by modifying `scriptdata/mega_mod_config.txt` after loading the mod once.
- The internal name for each global mod is listed under each heading in this readme.
- Map specific mods are named after the filename of their map.
- All mods default to `true` in the cfg (enabled).

Some mods depend on certain cvars being in vscript_convar_allowlist:
- `sv_allow_point_servercommand` if you want to use gamemode-specific cfgs.
- `sig_mvm_robot_multiplier_tank_hp` if you want MvM health scaling to apply to tanks. Also depends on [rafmod](https://github.com/rafradek/sigsegv-mvm).

### Project structure:
- `/arena_addons`
  - Addons that utilize the official addon support in the [VScript Arena](https://steamcommunity.com/workshop/filedetails/?id=3360196477) community fix by Lizard of Oz.
- `/common`
  - Script files that may be included by any map-specific mod or global mod when needed. Typically contains templates that require map-specific setup (PLR is a good example of this).
- `/globalmods`
  - Script files that are included on many/all maps. Can be used for gamemode specific stuff by using conditions evaluated on map launch (See mega_mod/globalmods/5cp_anti_stalemate.nut as an example).
  - Global mods must include these functions:
    - `ShouldApply()`: Should this mod be loaded?
    - `LoadAlongsideMapMods()`: Should this mod be loaded even if there's a map-specific mod?
    - `ApplyMod()`: Applies the modification.
- `/mapmods`
  - Script files that are automatically included when the map with the same filename loads.
- `/tug_of_war_addons`
  - Addons that utilize the official addon support in the Tug-of-war VScript gamemode.
- `/vsh_addons`
  - Addons that utilize the official addon support in the Versus Saxton Hale VScript gamemode.

# General Improvements

## Gamemode-specific .cfg support
Internal name: `gamemode_cfg`

By default, TF2 offers `server.cfg` for general configuration, plus map specific configs. But if you want to configure entire gamemodes with a single cfg, you're SOL.

This mod offers gamemode-specific config execution. Unfortunately, this requires `sv_allow_point_servercommand` to be added to your `vscript_convar_allowlist.txt`. This mod will only enable server commands when it needs to, reducing the risk of any potentially malicious maps. However, there is still a vulnerability to malicious VScript, so be warned!

## Force Team Respawn when appropriate
Internal name: `respawn_mod`

In certain scenarios, it is beneficial to respawn the dead players on one or both teams to improve the gameplay experience.

- In Attack/Defend and Payload maps:
  - BLU team is respawned at the end of setup time.
  - RED team is respawned whenever a control point is captured. This helps prevent steamrolls.

## Better mp_timelimit enforcement on KOTH and 5CP.
Internal name: `neutral_point_stalemate`

Normally, mp_match_end_at_timelimit enforces a stalemate on these gamemodes when the map timer ends, regardless of the game state.

This mod only forces a stalemate if no-one has capped a point (i.e. there is a neutral point on the map). This guarantees a map change after a certain point in time without interrupting actual gameplay (loitering on harvest without capping is not actual gameplay).

This mod will force `mp_match_end_at_timelimit 0`.

## Reliable Bunnyhopping for market gardening at high ping

Does some serverside shenanigans to re-apply the rocket jumping state as you bhop. Now you can reliably hit gardens at 350 ping!

Inspired by the MGA Rewrite Project https://mgatf.org/ and ported from https://github.com/kiwitf2/kiwimands by @kiwitf2
 
# Gamemode Improvements

## 5CP Anti-stalemate
Internal name: `5cp_anti_stalemate`

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

## Arena (VScript)

Gamemode has official addon support. See `arena_addons/` folder.

These improvements apply only to the [VScript Arena](https://steamcommunity.com/workshop/filedetails/?id=3360196477) community fix by Lizard of Oz.

- Added a 3 minute round timer. When elapsed, the round is won by whichever team has more players alive, stalemating if a tie.

## Mann Vs Machine

### Health scaling above 6 players.

Internal name: `mvm_scaling`

Robots gain a multipler on their health based on how many players are on RED. For example, if there are 12 players on RED, robots spawn with 200% HP. Health is multiplied by modifying `tf_populator_health_multiplier`.

Also supports multiplying Tank health if [rafmod](https://github.com/rafradek/sigsegv-mvm) is installed. Requires `sig_mvm_robot_multiplier` to be non-zero and `sig_mvm_robot_multiplier_tank_hp` to be in `cfg/vscript_convar_allowlist.txt`.

### Tank Announcements

Internal name: `mvm_tank_messages`

When a tank spawns, its health will be announced in chat. When a tank is destroyed, whoever dealt the most damage will be credited in chat.

## Payload Race

No global mod used; mod has separate implementations for each supported map.

Currently supported maps: `plr_bananabay`, `plr_cutter`, `plr_hacksaw`, `plr_hacksaw_event`, `plr_hightower`, `plr_hightower_event`, `plr_nightfall_final`, `plr_pipeline`, [`plr_highertower`](https://steamcommunity.com/sharedfiles/filedetails/?id=899335714).

### Added Overtime

Stage 1 and 2 of Nightfall feature an overtime. This mod copies that logic into other maps using nothing but VScript, with some additional QoL features.

After 10 minutes (or less if mp_timelimit has nearly elapsed), the map enters overtime. If neither cart is being pushed, they will both slowly inch forward. Pushing either cart will result in the other cart stopping (potentially rolling backwards). The mod basically replaces all vanilla PLR logic, as trying to utiize existing rollback/rollforward zones, hightower elevators, crossings, map logic, etc is a pain. Multistage maps will also always play to the final stage, even if mp_timelimit has expired.

### Dynamic cart speed

To reduce the likelihood of steamrolls, the leading cart's speed is reduced based on how much of a lead that team has over the losing team. The leading cart's speed starts reducing when it's 25% (of the track length) ahead of the other cart, and reaches its minimum at a 65% lead. The following table shows the relative speeds in various situations:

| Cart State    | <=25% lead | 45% lead | >=65% lead |
|:--------------|:-----------|:---------|:-----------|
| x0 (overtime) | 0.22       | 0.149    | 0.077      |
| x1            | 0.55       | 0.371    | 0.193      |
| x2            | 0.77       | 0.520    | 0.270      |
| x3            | 1.00       | 0.675    | 0.350      |

### Map specific quirks:
- On Hacksaw and Hacksaw Event, the game_text entities that display "hacking" progress now operate on separate channels, so both teams' progress can display simultaneously.
- On Hightower and Hightower Event, the elevators' rollback zones do not operate in overtime and are not affected by the dynamic speed system.
- Nightfall:
  - There's two improperly sized clip brushes on stage 3 next to the crossing. This mod spawns a couple of signs that take up the extra space covered by the clip brush, which also provide direction to players.
  - The path_track nodes at the top of the final ramp also use the wrong output; this mod corrects the outputs. Carts will roll slower down the final ramp as a result.
  - The round timer overhaul fixes a bug where setup time is stuck on during Stage 3, affecting Engineer building upgrades.

## Special Delivery

No global mod used; mod has separate implementations for each supported map.

Added a 15 minute round timelimit. When elapsed, the round stalemates immediately (or goes to bumper cars on sd_doomsday_event).

The time limit automatically reduces based on mp_timelimit.

## Tug of War

Gamemode has official addon support. See `tug_of_war_addons/` folder.

Tug of war can last forever, but not with this mod! After 10 minutes, the cart will move on its own towards the objective in favour of the cart owner's team. Every 30 seconds from then on, the cart's maximum speed will increase. Eventually, it'll be moving so fast that it can't help but be at either end of the track!

The KOTH timer was increased to 3 minutes so that the round is unlikely to end before the anti-stalemate phase without sidelining the vanilla experience, as the anti-stalemate mechanics are really fun to play with.

## Versus Saxton Hale

Gamemode has official addon support. See `vsh_addons/` folder.

### New Features:
- **Damage logging**:
  - Market gardens, backstabs, and telefrags are logged in chat.
  - On death: the damage dealt by the player is broadcast in chat.
    - If the dead ringer is used, a fake message is displayed to Hale only.
    - Insults the player if they do 0 damage.
  - At round end, the following are displayed:
    - The round duration.
    - The amount of Mercs killed by hale.
    - The top 3 players' damage (RPS winners displayed in gold).
    - The total damage by all players.
    - Damage by other sources (e.g. Distillery grinder).
    - Total damage.
- **Anti-AFK measures**:
  - If a player fails to send a keyboard input for 60 seconds, they are "fired" (killed).
  - When this happens, Hale's health is reduced to compensate, as though the idle player was never there in the first place.
    - Damage dealt by players before going AFK is factored into the damage caluclation to prevent metagaming. 
  - Chat messages are sent to the idle player to give them an opportunity to come back before they're "fired".
- **Killstreaks**:
  - Killstreaks now increment as the mercenaries deal damage to Hale.
  - The streak increments by 1 for every 200 damage dealt to Hale.
  - This does NOT produce any killstreak notifications, but it does enable the visual effects of Professional Killstreak items.
- **Player Glows**:
  - The last mercenary and Hale can see each other through walls.
  - Prevents that one guy from hiding in a corner for the whole round.

### Changes:
- **Legend**: 
  - $n$: Mercs alive
  - $N$: Mercs at round start
  - $H$: Hale's max health

- **Hale's Health**:
  - Updated formula based on [vsh_facility](https://steamcommunity.com/sharedfiles/filedetails/?id=3225055613).
  - A version of this formula with slight tweaks to the numbers made it into the [official game](https://www.teamfortress.com/post.php?id=234882)!
  - Decided to stick with the original numbers as this mod is likely going to be used in higher-skilled communities.

    | Mercs ($N$) | Vanilla Formula (2024)       | Resulting Health ($H(N)$)  |
    |:----------|:-------------------------------|:---------------------------|
    | 1         | $H = 1000$                     | H(1) = 1000                |
    | 2 - 6     | $H = 45N^2 + 2350(0.3 + N/10)$ | H(2) = 1500; H(6) = 4100   |
    | 7 - 23    | $H = 45N^2 + 2350$             | H(7) = 5000; H(12) = 9200;<br>H(18) = 17300; H(23) = 26600 |
    | 24+       | $H = 2000(N-23) + 26600$       | H(24) = 28600; H(31) = 42600;<br>H(63) = 106600; H(99) = 178600 |

    | Mercs ($N$) | Custom Formula               | Resulting Health ($H(N)$)  |
    |:----------|:-------------------------------|:---------------------------|
    | 1         | $H = 1000$                     | H(1) = 1000                |
    | 2 - 6     | $H = 41N^2 + 2350(0.3 + N/10)$ | H(2) = 1300; H(6) = 3500   |
    | 7 - 23    | $H = 41N^2 + 2350$             | H(7) = 4300; H(12) = 8200;<br>H(18) = 15600; H(23) = 24000 |
    | 24+       | $H = 2000(N-23) + 24000$       | H(24) = 26000; H(31) = 40000;<br>H(63) = 104000; H(99) = 176000 |

- **Gameplay Tweaks**:
  - **Brave Jump**: 3 second cooldown, center HUD notification alongside repurposed brave jump icon.
  - **Round Timer**:
    - Setup time: Adjusts to player count, 16-32s.
    - Point Unlock time: 10 seconds per player up to 30 players. Additional players add 5 seconds each. Final result clamped between 30 seconds and 10 minutes.
      - During the round: if $time > 15n$, then the timer is clamped to $15n$ 
  - **Rock-Paper-Scissors**: 1M damage to Hale (vanilla 100k isn't enough), high ragdoll knockback.
  - **Mighty Slam**: Do not prevent weighdown when on jump cooldown.
  - **Telefrags**: Deal 10x the damage they'd normally do, as they are so rare.

- **Control Point**:
  - Captures don't end rounds immediately; instead granting bonuses to the capping team.
  - **Mercs Cap**: 
    - Guaranteed crits and a brief health regen.
    - Hale's health is drained until he either dies or wins.
  - **Hale Caps**:
    - Ability cooldowns reduced to 5s.
    - The Merc with the lowest damage dealt is marked for death and drained of health.
  - Point capture guarantees the round will end given sufficient time.
  - Rate of health drain increases over time.
  - Point capture now leads to an engaging endgame, avoiding abrupt and unfair victories.

- **Particle Precaching**: Fixes missing particles (red X) when playing workshop maps.

## Zombie Infection

Internal name: `zi_mod`

Zombie Infection is a promising gamemode, however the implementation leaves a lot to be desired in my opinion. Notably, the long respawn times for the Zombies result in long periods of time without any fighting. Rounds tend to drag on and on, and the variablity of round and respawn times results in an inconsistent experience.

- Adjusted various timings to improve the gamemode's pacing.
  - Round time always starts at, and can never exceed, 2 minutes.
  - Time added upon survivor death is reduced by 1 second for every 5 remaining survivors (to a minimum of 2 seconds).
  - Respawn wave time is set to 5 seconds for Survivors.
  - Zombies have near-instant respawn (2 seconds, interrupts killcam).
  - Death during setup triggers instant respawn.
- Initial Zombie selection:
  - Zombie count formula modified (see table).  
  - Players cannot start as Zombies in two consecutive rounds.
- Weapon rebalances:
  - The B.A.S.E. Jumper disables during overtime instead of disabling for the last survivor.
  - Increased reserve ammo for the Rocket Jumper (0 -> 5) and Sticky Jumper's reserve ammo (0 -> 5).
- Added Overtime:
  - When the timer expires, the game enters Overtime. Overtime lasts until round end and cannot be interrupted.
  - Zombies cannot respawn in Overtime, however Survivors killed in Overtime still become Zombies.
    - Dead survivors will respawn as Zombies instantly if there are no other Zombies alive.
  - Win conditions:
    - Survivors can only win by killing all the remaining Zombies.
    - Zombies win by killing all the remaining Survivors (as usual).
  - Zombies experience bleed with increasing damage over time to guarantee a round end.
    - The damage halves on every survivor death.
  - Survivors can enter Zombie spawnrooms during Overtime.

Player count to Zombie count table:

| # Players ($P$) | # Zombies (Vanilla) | # Zombies (Modified) |
|:----------------|:--------------------|:---------------------|
| 2 - 4           | 1                   | 1                    |
| 5 - 8           | 2                   | 2                    |
| 9 - 12          | 3                   | 3                    |
| 13 - 16         | 4                   | 4                    |
| 17+ | $\lceil\frac{P}{5}\rceil$ | $\lfloor\sqrt{P-1}\rfloor$ |

# Map Specific/Miscellanious Fixes

All of these mods are map-specific unless specified.

## arena_perks:

### Added a 2:50 time limit for each mini-round.
Time limit chosen so the 2:00 mark coincides with the unlocking of the point. If the time limit is reached, then whichever team has more players alive wins. If both teams have the same amount of living players, then it's a tie.

### Made ties less arbitrary.
When both teams die at exactly the same time (or the time limit introduced by this mod is reached), both teams get a point. This is necessary as the game can't last more than 5 rounds. However, if the score is 2-2 and there's a tie, the winning team is chosen arbitrarily. If this rare situation occurs, this mod makes the win slightly less arbitrary by awarding the win to whichever team most recently lost a player to death (implying their team lasted longer).

## cp_freaky_fair:

### Cash accumulates between rounds.
Too often do people complain about capping on cp_freaky_fair, lest they lose their ability to ~~pay off the japanese mafia~~ purchase some insane combination of upgrades. To prevent this, the cash is preserved between rounds. Both teams start with the same amount of cash that the richer team had at the end of the previous round.

### Nerfed canteens.
Reduced durations for the kritz canteen (10s -> 8s) and the Uber canteen (10s -> 5s).

### Damage resistances provide Melee resistance.
Each tick of Fire, Bullet, or Blast resistance gives 5% resistance to Melee damage; up to a total of 45% resistance.

## Boss fights on koth_lakeside_event & koth_viaduct_event

Truces are removed, and the point retains its owner during the boss fight. The clock pauses when the boss spawns in and resumes once the boss leaves or is defeated.

The point model hides during the boss fight (the point is *technically* netural during the boss fight and this was the easiest way to make it not look stupid).

## Edict optimizations

Kills several entities to save on edicts. View individual mod files for specifics.

Approximate savings:

- `cp_cowerhouse`: 365 edicts
- `pl_bloodwater`: 300 edicts
- `plr_hacksaw`: 6 edicts

## Prevent players going the wrong way on pl_breadspace

Spawns a door at the top of that ramp using the door model featured throughout the map. Door opens once B is captured.

## Fix captures not being counted correctly in scoreboard.

In Payload, the team scores are supposed to reflect how many control points that team has captured.
- In pl_emerge, that setting simply isn't enabled; this mod turns it on.
- In [pl_cactuscanyon_redux_final2](https://steamcommunity.com/sharedfiles/filedetails/?id=2579644293), some of the outputs that trigger point captures trigger twice; adding a slight delay fixes this.

## Prevent 'Meet the Medic" taunt from being used in water.

Internal name: `jakemod`

For the uninitiated, this taunt creates a VERY loud noise if the doves happen to spawn in water. This mod applies a countermeasure.
Interally referred to as the "jakemod" after the person who "inspired" this mod's existence.

## TF2Ware Ultimate mod support.

Framework for injecting mods into the official workshop version of TF2Ware Ultimate. You can add new minigames, bossgames, and special rounds or modify/replace existing ones.

If you need to modify the map itself, you're far better off forking the [TF2Ware Ultimate](https://github.com/ficool2/TF2Ware_Ultimate) repo which has everything you need.

Within `mapmods\workshop\tf2ware` there are several folders of interest:

- `bossgames`: Files placed here function as if they were in `scripts\vscripts\tf2ware_ultimate\bossgames` in the TF2Ware project.
- `minigames`: Files placed here function as if they were in `scripts\vscripts\tf2ware_ultimate\minigames` in the TF2Ware project.
- `specialrounds`: Files placed here function as if they were in `scripts\vscripts\tf2ware_ultimate\specialrounds` in the TF2Ware project.

### Change round counter to account for my nativevotes fork.

If you happen to be using my [fork](https://github.com/megascatterbomb/sourcemod-nativevotes-updated) of nativevotes, then the round counter will account for the use of `sm_mapvote_instant_change 1`.

Requires `sm_mapvote_instant_change` and `sm_mapvote_startround` to be whitelisted in `vscript_convar_allowlist.txt`.

## VScript Error Cleanup on pass_jerma

I was gonna do some more stuff with this but I decided it wasn't necessary, so I just kept the function overrides that prevent VScript errors from being spammed in console.