::MM_ZI_ROUND_FINISHED <- false;
::MM_ZI_LAST_SURVIVOR_DEATH <- 0;
::MM_ZI_OVERTIME_ENABLED <- true;
::MM_ZI_OVERTIME <- false;
::MM_ZI_OVERTIME_DAMAGE <- 0;
::MM_ZI_OVERTIME_DAMAGE_LAST_INCREASE <- 0;
::MM_ZI_MAX_TIME <- 180;
::MM_ZI_ADD_TIME_BASE <- 5;
::MM_ZI_ADD_TIME_MIN <- 2;

::MM_ZI_EXPLOITERS <- []; // user ids of players who change teams to try and respawn during overtime

::MM_ZI_PLAYER_MANAGER <- Entities.FindByClassname(null, "tf_player_manager");

// max survivors before we start reducing time added.
::MM_ZI_ADD_TIME_REDUCE_THRESHOLD <- 29; 

// additional survivors required before dropping another second off time added.
::MM_ZI_ADD_TIME_REDUCE_STEP <- 5; 

// zi2026 leaves respawn wave times to map configuration; remember the map's
// default so we can restore it after overtime.
::MM_ZI_BLUE_RESPAWN_WAVE_DEFAULT <- -1.0;

::MM_ZI_LOGIC_SCRIPT <- null;
::MM_ZI_LOGIC_SCRIPT_SCOPE <- null;

function MM_Zombie_Infection() {
    ::MM_ZI_ROUND_FINISHED <- false;
    ::MM_ZI_OVERTIME <- false;
    ::MM_ZI_OVERTIME_DAMAGE <- 0;
    ::MM_ZI_OVERTIME_DAMAGE_LAST_INCREASE <- 0;
    ::MM_ZI_EXPLOITERS <- [];
    ::MM_ZI_LOGIC_SCRIPT <- Entities.FindByClassname(null, "logic_script")
    ::MM_ZI_LOGIC_SCRIPT_SCOPE <- ::MM_ZI_LOGIC_SCRIPT.GetScriptScope();
    ::MM_ZI_PLAYER_MANAGER <- Entities.FindByClassname(null, "tf_player_manager");


    // zi2026 exposes the gamerules entity as the global ::GameRules.
    local gamerules = ( "GameRules" in getroottable() && getroottable().GameRules != null )
        ? getroottable().GameRules
        : Entities.FindByClassname( null, "tf_gamerules" );

    if (gamerules != null) {
        // Capture the map's default BLU respawn wave time before we override it in overtime.
        local blue_wave = GetPropFloat(gamerules, "m_flBlueTeamRespawnWaveTime");
        if (blue_wave > 0.0 && blue_wave < 99999.0) {
            ::MM_ZI_BLUE_RESPAWN_WAVE_DEFAULT <- blue_wave;
        }
    }

    // Clear glow state from last round if needed.
    foreach( _hNextPlayer in GetAllPlayers() ) {
        SetPropBool( _hNextPlayer, "m_bGlowEnabled", false );
    }

    // MEGAMOD: make healthkits/ammopacks RED-pickup at round start.
    // Prevents zombies from removing their debuffs on healthkits.
    local pickupClasses = [
        "item_healthkit_small", "item_healthkit_medium", "item_healthkit_full",
        "item_ammopack_small", "item_ammopack_medium", "item_ammopack_large"
    ];
    foreach( _cls in pickupClasses ) {
        for (local ent = null; ent = Entities.FindByClassname(ent, _cls);) {
            SetPropInt(ent, "m_iTeamNum", 2);
        }
    }

    MM_ZI_OverrideSetupFinished();
    MM_ZI_OverrideDeath();
    MM_ZI_OverrideRoundEnd();
    MM_ZI_OverrideShouldZombiesWin();
    MM_ZI_OverrideSpawnPickerRefund();
    MM_ZI_OverrideSpyRecloak();
    MM_ZI_OverrideEnterSpawnPicker();

    MM_ZI_PrepareForOvertime();
    MM_ZI_MapSpecific_RoundStart();
}

function MM_ZI_OnPlayerTeam(params) {
    if (!::MM_ZI_OVERTIME || !::bGameStarted || ::MM_ZI_ROUND_FINISHED) return;

    // We're in overtime.
    if ( params.team == 2 ) {
        local player = GetPlayerFromUserID(params.userid);
        if (player == null) return;
        ::MM_ZI_EXPLOITERS.append(params.userid);
        SetPropBool( player, "m_bGlowEnabled", false );
        EntFireByHandle(player, "RunScriptCode", "ChangeTeamSafe(self, 3, true); self.ForceRespawn(); SetPropBool( self, \"m_takedamage\", true ); self.TakeDamage(1000000, 0, null)", 0, null, player)
    }
}

function MM_ZI_OverrideEnterSpawnPicker() {
    local root = getroottable();

    // Only wrap once
    if (!("MM_ZI_OriginalEnterSpawnPicker" in root) || ::MM_ZI_OriginalEnterSpawnPicker == null) {
        ::MM_ZI_OriginalEnterSpawnPicker <- CTFPlayer.EnterSpawnPicker;
    }

    CTFPlayer.EnterSpawnPicker <- function() {
        local userid = NetProps.GetPropIntArray(::MM_ZI_PLAYER_MANAGER, "m_iUserID", this.entindex());
        if (::MM_ZI_OVERTIME && ::MM_ZI_EXPLOITERS.find(userid) != null) return;
        ::MM_ZI_OriginalEnterSpawnPicker.call( this );
    };
    CTFBot.EnterSpawnPicker <- CTFPlayer.EnterSpawnPicker;
}

// OVERRIDE: replacement for infection.nut::OnGameEvent_teamplay_setup_finished
function MM_ZI_OverrideSetupFinished() {

    ::MM_ZI_LOGIC_SCRIPT_SCOPE.OnGameEvent_teamplay_setup_finished <- function ( params )
    {
        ::bGameStarted <- true;

        // MEGAMOD: Set the timer early at round_start, before the map's OnSetupFinished output
        // can overwrite it with the map's default values.
        local timer = Entities.FindByClassname(null, "team_round_timer");
        if (timer != null) {
            EntFireByHandle(timer, "SetTime", "" + ::MM_ZI_MAX_TIME, 0, null, null);
            EntFireByHandle(timer, "SetMaxTime", "" + ::MM_ZI_MAX_TIME, 0, null, null);
        }

        BuildZombieSpawnPointArray();

        local _iPlayerCountRed    = PlayerCount( TF_TEAM_RED );
        local _numStartingZombies = -1;

        // -------------------------------------------------- //
        // select players to become zombies                   //
        // -------------------------------------------------- //

        if ( !bNewFirstWaveBehaviour )
        {
            if ( ( _iPlayerCountRed <= 1 ) && ( DEBUG_MODE < 1 ) )
            {
                // not enough players, force game over
                local _hGameWin = SpawnEntityFromTable( "game_round_win",
                {
                    win_reason      = "0",
                    force_map_reset = "1",
                    TeamNum         = "2", // TF_TEAM_RED
                    switch_teams    = "0"
                });

                EntFireByHandle( _hGameWin, "RoundWin", "", 0, null, null );
                ::bGameStarted <- false;
                return;
            }
            else if ( _numStartingZombies == -1 )
            {
                _numStartingZombies = GetZombieQuota( _iPlayerCountRed );
            }

            local _szZombieNetNames  =  "";

            local _arrDeadSurvivors = [];

            foreach ( _hDeadSurvivor in GetAllPlayers() )
            {
                if ( _hDeadSurvivor != null &&
                     _hDeadSurvivor.GetTeam() == TF_TEAM_RED &&
                     GetPropInt( _hDeadSurvivor, "m_lifeState" ) != ALIVE )
                {
                    _arrDeadSurvivors.append( _hDeadSurvivor );
                };
            };

            local _iLivePicks = ( _numStartingZombies - _arrDeadSurvivors.len() );

            if ( _iLivePicks < 0 )
                _iLivePicks = 0;

            local _zombieArr = _arrDeadSurvivors;

            _zombieArr.extend( GetRandomPlayers( _iLivePicks, ::tblLastRoundZombies ) );

            if ( _zombieArr.len() == 0 )
                return;

            ::tblLastRoundZombies <- {};

            foreach ( _hInfected in _zombieArr )
            {
                if ( _hInfected != null )
                    ::tblLastRoundZombies[ GetPlayerUserID( _hInfected ) ] <- true;
            };

            // ------------------------------------------ //
            // convert the picked players to zombies      //
            // ------------------------------------------ //

            for ( local i = 0; i < _zombieArr.len(); i++ )
            {
                local _id          =  GetPlayerUserID     ( _zombieArr[ i ] );
                local _nextPlayer  =  GetPlayerFromUserID ( _id );

                if ( _nextPlayer == null )
                    continue;

                local _sc = _nextPlayer.GetScriptScope();

                // a corpse only needs the team change - the respawn takes the normal
                // zombie route from OnGameEvent_player_spawn
                if ( GetPropInt( _nextPlayer, "m_lifeState" ) != ALIVE )
                {
                    _nextPlayer.ResetInfectionVars();
                    ChangeTeamSafe( _nextPlayer, TF_TEAM_BLUE, false );
                }
                else
                {
                    // ------------------------------------------------------- //
                    // make sure heavy/pyro don't get stuck in a t-pose/a-pose  //
                    // ------------------------------------------------------- //
                    local _hActiveWep = _nextPlayer.GetActiveWeapon();

                    if ( _hActiveWep != null &&
                         ( _hActiveWep.GetClassname() == "tf_weapon_minigun" ||
                           _hActiveWep.GetClassname() == "tf_weapon_flamethrower" ) )
                    {
                        SetPropInt( _hActiveWep, "m_iWeaponState", 0 );
                    };

                    // remove player conditions that will cause problems
                    // when switching to zombie
                    _nextPlayer.ClearProblematicConds();

                    // reset all gamemode specific variables
                    _nextPlayer.ResetInfectionVars();

                    ChangeTeamSafe( _nextPlayer, TF_TEAM_BLUE, false );

                    // remove all of the player's existing items
                    _nextPlayer.RemovePlayerWearables();

                    // add the zombie cosmetics/skin modifications
                    _nextPlayer.GiveZombieCosmetics();
                    _nextPlayer.GiveZombieFXWearable();

                    SendGlobalGameEvent( "post_inventory_application", { userid = GetPlayerUserID(_nextPlayer) });

                    // add the pending zombie flag
                    // the actual zombie conversion is handled in the player's think script
                    // the initial infection bit keeps the lightning fx for this wave only
                    _sc.m_iFlags <- ( ( _sc.m_iFlags | ZBIT_PENDING_ZOMBIE | ZBIT_INITIAL_INFECTION ) );

                    // don't delay zombie conversion when the player is alive.
                    _nextPlayer.SetNextActTime ( ZOMBIE_BECOME_ZOMBIE, INSTANT );
                    _nextPlayer.SetNextActTime ( ZOMBIE_ABILITY_CAST, 0.1 );
                };

                // ------------------------------------------- //
                // build string for chat notification          //
                // ------------------------------------------- //

                if ( i == 0 ) // first player in the message
                {
                    _szZombieNetNames = "\x07FF3F3F" + NetName( _nextPlayer ) + "\x07FBECCB";
                }
                else if ( i ==  ( _zombieArr.len() - 1 ) ) // last player in the message
                {
                    if ( _zombieArr.len() > 1 )
                    {
                        _szZombieNetNames += ( "\x07FBECCB " + STRING_UI_AND + " \x07FF3F3F" );
                    }
                    else
                    {
                        _szZombieNetNames += ( "\x07FBECCB, \x07FF3F3F" );
                    };

                    _szZombieNetNames += ( NetName( _nextPlayer ) + "\x07FBECCB" );
                }
                else // players in the middle get commas
                {
                    _szZombieNetNames += ( "\x07FBECCB, \x07FF3F3F" + NetName( _nextPlayer ) + "\x07FBECCB" );
                };
            };

            local _szFirstInfectedAnnounceMSG = "";

            if ( _zombieArr.len() > 1 ) // set the first infected announce message
            {
                _szFirstInfectedAnnounceMSG = format( _szZombieNetNames +
                                                    STRING_UI_CHAT_FIRST_WAVE_MSG_PLURAL );
            }
            else
            {
                _szFirstInfectedAnnounceMSG = format( _szZombieNetNames +
                                                    STRING_UI_CHAT_FIRST_WAVE_MSG );
            };

            local _hNextRespawnRoom = null;
            while ( _hNextRespawnRoom = Entities.FindByClassname( _hNextRespawnRoom, "func_respawnroom" ) )
            {
                if ( _hNextRespawnRoom && _hNextRespawnRoom.GetTeam() == TF_TEAM_RED )
                {
                    EntFireByHandle( _hNextRespawnRoom, "SetInactive", "", 0.0, null, null );
                };
            };

            // MEGAMOD: Force round time to 2 minutes.
            local _hRoundTimer = Entities.FindByClassname( null, "team_round_timer" );
            EntFireByHandle(_hRoundTimer, "SetTime", "" + ::MM_ZI_MAX_TIME, 0, null, null);
            EntFireByHandle(_hRoundTimer, "SetMaxTime", "" + ::MM_ZI_MAX_TIME, 0, null, null);

            PlayGlobalBell( false );

            // show the first infected announce message to all players
            PrintToChat( _szFirstInfectedAnnounceMSG );
        }
    };
}

// OVERRIDE: replacement for infection.nut::OnGameEvent_player_death
function MM_ZI_OverrideDeath() {

    ::MM_ZI_LOGIC_SCRIPT_SCOPE.OnGameEvent_player_death <- function ( params )
    {
        local _hPlayer      =  GetPlayerFromUserID ( params.userid );
        local _hKiller      =  GetPlayerFromUserID ( params.attacker );
        local _iDamageType  =  params.damagebits;
        local _iWeaponIDX   =  params.weapon_def_index;

        if ( _hPlayer == null )
            return;

        local _sc                  =  _hPlayer.GetScriptScope();
        local _iClassNum           =  _hPlayer.GetPlayerClass();
        local _hPlayerTeam         =  _hPlayer.GetTeam();

        SetPropIntArray( _hPlayer, "m_nModelIndexOverrides", 0, 3 );

        if ( _sc != null && ( "m_iFlags" in _sc ) && ( _sc.m_iFlags & ZBIT_SPEWED ) )
            _hPlayer.RemoveSpewDebuff();

        if ( _sc != null )
            _hPlayer.SpoofZombieBuffFX( false );

        // a death mid-picker/emerge leaks locked state - the exit path is otherwise
        // only reachable from FinishSpawnEmerge, which a corpse never gets to
        if ( _sc != null && ( "m_iFlags" in _sc ) )
        {
            if ( _sc.m_iFlags & ( ZBIT_IN_SPAWN_PICKER | ZBIT_EMERGING_FROM_GROUND ) )
            {
                _sc.m_iFlags <- ( _sc.m_iFlags & ~ZBIT_EMERGING_FROM_GROUND );
                _hPlayer.SetNextActTime( ZOMBIE_FINISH_EMERGE, ACT_LOCKED );
                _hPlayer.ExitSpawnPicker();
            }
            else if ( _sc.m_iFlags & ZBIT_HEAVY_ROCK_WINDUP )
            {
                _sc.m_iFlags <- ( _sc.m_iFlags & ~ZBIT_HEAVY_ROCK_WINDUP );
                _hPlayer.DestroySpawnBody   ();
                _hPlayer.SetSpawnBodyHidden ( false );
                _hPlayer.SetForcedTauntCam  ( 0 );
                _hPlayer.LockInPlace        ( false );
            };
        };

        // crumpkin catch - on a halloween-flagged map the engine rolls 30% to turn the
        // death ammo pack into a crit pumpkin. its AP_HALLOWEEN state isn't a netprop
        // and can't be reverted, so swap the pack for the medium ammo it was going to be
        if ( !( ::bGameStarted && _hPlayerTeam == TF_TEAM_BLUE ) )
        {
            local _iPumpkinModel = GetModelIndex( "models/props_halloween/pumpkin_loot.mdl" );
            local _hDroppedAmmo  = null;

            while ( _hDroppedAmmo = Entities.FindByClassname( _hDroppedAmmo, "tf_ammo_pack" ) )
            {
                if ( _hDroppedAmmo.GetOwner() != _hPlayer ||
                     GetPropInt( _hDroppedAmmo, "m_nModelIndex" ) != _iPumpkinModel )
                    continue;

                CreateMediumAmmoPack( _hDroppedAmmo.GetOrigin() );
                _hDroppedAmmo.Destroy();
            };
        };

        // deaths during setup don't cost you the round start
        if ( !::bGameStarted &&
             GetPropInt( GameRules, "m_iRoundState" ) != GR_STATE_TEAM_WIN &&
             !( params.death_flags & TF_DEATH_FEIGN_DEATH ) )
            EntFireByHandle( _hPlayer, "RunScriptCode",
                             "self.ForceRegenerateAndRespawn()", 0.1, null, null );

        if ( ::bGameStarted && _hPlayerTeam == TF_TEAM_BLUE ) // zombie has died
        {

            // any class - the class may have changed since the dispenser was made
            _hPlayer.DestroyMedicDispenser();

            // valve's dropped-weapon pack is always culled - we drop our own below
            local _hDroppedAmmo = null;
            while ( _hDroppedAmmo = Entities.FindByClassname( _hDroppedAmmo, "tf_ammo_pack" ) )
            {
                if ( _hDroppedAmmo.GetOwner() == _hPlayer )
                {
                    _hDroppedAmmo.Destroy();
                };
            };

            // every zombie leaves a small health pack and a small ammo pack
            CreateZombieDeathDrop( _hPlayer.GetOrigin() );

            // ability is null if death lands before conversion (e.g. a killbind in the picker)
            if ( _hPlayer.GetPlayerClass() == TF_CLASS_SNIPER && _sc.m_hZombieAbility != null )
            {
                _sc.m_hZombieAbility.CreateSpitball( true );
            };

            // the heavy is made of the same stuff he throws - burst him into rock gibs
            // MEGAMOD: we add an additional guard to stop a VScript error that occasionally occurs (why does this happen?)
            if ( _hPlayer.GetPlayerClass() == TF_CLASS_HEAVYWEAPONS && "SpawnHeavyRockGibs" in getroottable() )
            {
                SpawnHeavyRockGibs( ( _hPlayer.GetOrigin() + Vector( 0, 0, ZHEAVY_DEATH_GIB_Z_OFF ) ) );
            };

             if ( _hPlayer.GetPlayerClass() == TF_CLASS_PYRO )
             {
                local _hNextPlayer = null;
                local _hKillicon = KilliconInflictor( KILLICON_PYRO_BREATH );

                if ( !::bNoPyroExplosionMod )
                {
                    while ( _hNextPlayer = Entities.FindByClassnameWithin( _hNextPlayer, "player", _hPlayer.GetOrigin(), 125 ) )
                    {
                        if ( _hNextPlayer != null && _hNextPlayer.GetTeam() == TF_TEAM_RED && _hNextPlayer != _hPlayer )
                        {
                            KnockbackPlayer           ( _hPlayer, _hNextPlayer, 210, 0.85, true );
                            _hNextPlayer.TakeDamageEx ( _hKillicon, _hPlayer, _hPlayer.GetActiveWeapon(), Vector(0, 0, 0), _hPlayer.GetOrigin(), 10, ( DMG_CLUB | DMG_PREVENT_PHYSICS_FORCE ) );
                        };
                    };

                    _hKillicon.Destroy();

                    EmitSoundOn            ( SFX_PYRO_FIREBOMB, _hPlayer );
                    DispatchParticleEffect ( "fireSmokeExplosion_track", _hPlayer.GetLocalOrigin(), Vector( 0, 0, 0 ) );
                }

            };

            // ------------------------------------- //
            // remove zombie "vgui"                  //
            // ------------------------------------- //
            // we use the script overlay material for zombie ability hud
            // so let's make sure it's cleared whenever a player has respawned
            _hPlayer.SetScriptOverlayMaterial ( "" );

            // same thing for the HUD text channels. these are only created on the first think
            // tick after the emerge, so a death in the picker/emerge window finds them null
            if ( _sc.m_hHUDText != null && _sc.m_hHUDText.IsValid() )
            {
                _sc.m_hHUDText.KeyValueFromString ( "message", "" );
                EntFireByHandle( _sc.m_hHUDText,  "Display", "", 0.0, _hPlayer, _hPlayer );
            };

            if ( _sc.m_hHUDTextAbilityName != null && _sc.m_hHUDTextAbilityName.IsValid() )
            {
                _sc.m_hHUDTextAbilityName.KeyValueFromString ( "message", "" );
                EntFireByHandle( _sc.m_hHUDTextAbilityName,  "Display", "", 0.0, _hPlayer, _hPlayer );
            };

            // ------------------------------------- //
            // Zombie Gib Hack                       //
            // ------------------------------------- //
            // when a player has the zombie skin override, they are hard coded to never gib
            // if we remove this skin here it creates gibs for the player
            if ( ::bZombieGibsOn )
            {
                SetPropInt ( _hPlayer, "m_iPlayerSkinOverride", 0 );

                // we set custom model on the player afterwards because otherwise the gibs come out red
                _hPlayer.SetCustomModelWithClassAnimations( arrTFClassPlayerModels[ _iClassNum ] );
            };

            // ------------------------------------- //
            // Check if Need Demoman Explosion       //
            // ------------------------------------- //

            if ( ( _sc.m_iFlags & ZBIT_MUST_EXPLODE ) )
            {
                _sc.m_iFlags <- ( _sc.m_iFlags & ~ZBIT_MUST_EXPLODE );
                _sc.m_tblEventQueue <- { };

                // ---------------------------------------- //
                // check for buildings and find the nearest //
                // to become the explosion origin           //
                // ---------------------------------------- //

                DemomanExplosionPreCheck( _hPlayer.GetOrigin(),
                                          DEMOMAN_CHARGE_DAMAGE,
                                          DEMOMAN_CHARGE_RADIUS,
                                          _hPlayer );
            };

            // hide our fx wearable to stop the particles from generating. the handle is null
            // whenever GiveZombieFXWearable is stubbed out, so guard it
            if ( _sc.m_hZombieFXWearable != null && _sc.m_hZombieFXWearable.IsValid() )
            {
                SetPropInt( _sc.m_hZombieFXWearable, "m_nRenderMode", kRenderNone );

                _sc.m_hZombieFXWearable.Destroy();
            };

            // MEGAMOD: Instantly respawn the zombie.
            // zi2026 leaves zombie respawns to map config; this override keeps instant respawns.
            if (!MM_ZI_ROUND_FINISHED && !MM_ZI_OVERTIME) {
                DoEntFire("!self", "RunScriptCode", "MM_ZI_ForceRespawn(self)", 2, null, _hPlayer);
            } else if (!MM_ZI_ROUND_FINISHED && MM_ZI_OVERTIME) {
                EntFireByHandle(self, "RunScriptCode", "MM_ZI_ShouldSurvivorsWin()", 0, null, null);
            }

            return; // zombie death event ends here
        }

        if ( ::bGameStarted ) // if the game is started, a dying survivor becomes a zombie
        {
            if (MM_ZI_ROUND_FINISHED) return;

            // player was survivor, killed by a zombie and wasn't suicide
            if ( _hKiller && _hKiller.GetClassname() == "player" && _hKiller.GetTeam() == TF_TEAM_BLUE && _hPlayerTeam == TF_TEAM_RED )
            {
                if ( _hKiller == null || _hPlayer == _hKiller )
                    return;

                // show a notifcation to all players in chat.
                local _szDeathMsg = format( STRING_UI_CHAT_INFECT_MSG,
                                            NetName( _hPlayer ),
                                            NetName( _hKiller ) );

                ClientPrint( null, HUD_PRINTTALK, _szDeathMsg );
            }
            else // player died to enviro/other, announce they were infected with no killer name
            {
                local _szDeathMsg = format ( STRING_UI_CHAT_INFECT_SOLO_MSG,
                                             NetName( _hPlayer ) );

                ClientPrint( null, HUD_PRINTTALK, _szDeathMsg );
            };

            // dead ringer deaths exit here
            if ( ( params.death_flags & TF_DEATH_FEIGN_DEATH ) )
            {
                PlayGlobalBell( true );
                return;
            };

            // evaluate win condition when a player dies
            // MEGAMOD: our override returns the number of remaining survivors
            local remainingSurvivors = ShouldZombiesWin(_hPlayer);

            // make sure players can only add time once per round
            if ( ( !_sc.m_bCanAddTime ) )
            {
                return;
            }
            else
            {
                _sc.m_bCanAddTime <- false;
            };

            PlayGlobalBell( false );

            local _hRoundTimer = Entities.FindByClassname( null, "team_round_timer" );

            // no round timer on the level, let's make one
            if ( _hRoundTimer == null )
            {
                // MEGAMOD: Don't do this. Every map has its own timer.
                // // create an infection specific timer
                // _hRoundTimer = SpawnEntityFromTable( "team_round_timer",
                // {
                //     auto_countdown       = "0",
                //     max_length           = "120",
                //     reset_time           = "1",
                //     setup_length         = "30",
                //     show_in_hud          = "1",
                //     show_time_remaining  = "1",
                //     start_paused         = "0",
                //     timer_length         = "120",
                //     StartDisabled        = "0",
                // } );
            }
            else
            {
                EntFireByHandle( _hRoundTimer, "auto_countdown", "0", 0, null, null );
            }

            // MEGAMOD: Reduce the time added once there are more survivors than the
            // threshold, taking away a second for every REDUCE_STEP survivors above it.
            local timeToAdd = ::MM_ZI_ADD_TIME_BASE;
            if (remainingSurvivors > ::MM_ZI_ADD_TIME_REDUCE_THRESHOLD) {
                timeToAdd -= 1 + floor((remainingSurvivors - ::MM_ZI_ADD_TIME_REDUCE_THRESHOLD - 1) / ::MM_ZI_ADD_TIME_REDUCE_STEP);
            }
            if (timeToAdd < ::MM_ZI_ADD_TIME_MIN)
                timeToAdd = ::MM_ZI_ADD_TIME_MIN;

            EntFireByHandle(_hRoundTimer, "AddTime", ceil(timeToAdd).tostring(), 0, null, null);

            MM_ZI_LAST_SURVIVOR_DEATH <- Time();

            // MEGAMOD: Halve damage on survivor death to reward Zombie activity.
            ::MM_ZI_OVERTIME_DAMAGE <- MM_ZI_OVERTIME_DAMAGE / 2.0;
            ::MM_ZI_OVERTIME_DAMAGE_LAST_INCREASE <- 0;
        } else {
            // MEGAMOD: If game hasn't started, instantly respawn.
            if (!MM_ZI_ROUND_FINISHED) DoEntFire("!self", "RunScriptCode", "MM_ZI_ForceRespawn(self)", 0.1, null, _hPlayer);
        }
    };
}

// OVERRIDE: functions.nut::ShouldZombiesWin
// MEGAMOD: now returns number of remaining survivors
function MM_ZI_OverrideShouldZombiesWin() {
    ::ShouldZombiesWin <- function( _hPlayer )
    {
        local _iValidSurvivors = 0;
        local _iValidPlayers   = 0;

        // count all valid survivors to see if the game should end
        for ( local i = 1; i <= MaxPlayers; i++ )
        {
            local _player = PlayerInstanceFromIndex( i );

            if ( _player != null )
            {
                _iValidPlayers++;

                // if the player is valid, on survivor (red) team, alive, and not the player who just died
                if ( ( _player != null ) &&
                     ( _player.GetTeam() == TF_TEAM_RED ) &&
                     ( GetPropInt( _player, "m_lifeState" ) == ALIVE ) && _player != _hPlayer )
                {
                     _iValidSurvivors++;
                };
            };
        };

        if ( _iValidPlayers == 0 ) // GetAllPlayers didn't find any players, should never happen
        {
            return -1;
        };

        if ( _iValidSurvivors == 3 )
        {
            ClientPrint( null, HUD_PRINTTALK, format( STRING_UI_CHAT_LAST_SURV_YELLOW, _iValidSurvivors, STRING_UI_MINI_CRITS ) );
        };

        // check if zombies have killed enough survivors to win
        if ( _iValidSurvivors <= MAX_SURVIVORS_FOR_ZOMBIE_WIN )
        {
            local _hGameWin = SpawnEntityFromTable( "game_round_win",
            {
                win_reason      = "0",
                force_map_reset = "1",
                TeamNum         = "3", // TF_TEAM_BLUE
                switch_teams    = "0"
            } );

            // the zombies have won the round.
            ::bGameStarted <- false;
            EntFireByHandle ( _hGameWin, "RoundWin", "", 0, null, null );
        }
        else
        {
            if ( _iValidSurvivors == 1 ) // last guy
            {
                foreach( _hNextPlayer in GetAllPlayers() )
                {
                    if ( _hNextPlayer.GetTeam() == TF_TEAM_RED && GetPropInt( _hNextPlayer, "m_lifeState" ) == ALIVE )
                    {
                        if ( _hNextPlayer == null || _hNextPlayer == _hPlayer )
                            continue;

                        ClientPrint( null, HUD_PRINTTALK, format( STRING_UI_CHAT_LAST_SURV_GREEN, NetName( _hNextPlayer ), STRING_UI_CRITS ) );

                        _hNextPlayer.GetScriptScope().m_bLastManStanding <- true;
                        // MEGAMOD: Apply Last three buffs as well as last man standing buff
                        _hNextPlayer.GetScriptScope().m_bLastThree       <- true;

                        _hNextPlayer.AddCond( TF_COND_CRITBOOSTED );
                    };
                };
            }
            else if ( ( _iValidSurvivors < 4 ) && ( _iValidSurvivors > 1 ) ) // last 3 get minicrits
            {
                foreach( _hNextPlayer in GetAllPlayers() )
                {
                    if ( _hNextPlayer.GetTeam() == TF_TEAM_RED && GetPropInt( _hNextPlayer, "m_lifeState" ) == ALIVE )
                    {
                        if ( _hNextPlayer == null )
                            continue;

                        _hNextPlayer.GetScriptScope().m_bLastThree <- true;
                        _hNextPlayer.AddCond( TF_COND_OFFENSEBUFF );
                        continue;
                    };
                };
            };
        };

        return _iValidSurvivors;
    };
}

::MM_ZI_ForceRespawn <-  function(player, allowInOvertime = false) {
    if ((!allowInOvertime && MM_ZI_OVERTIME) || MM_ZI_ROUND_FINISHED) return;
    player.ForceRespawn();
}

// OVERRIDE: functions.nut::CTFPlayer_RefundSpawnPickerTime
// MEGAMOD: Prevent players from stalling indefinitely in Overtime.
// We remove the 1 second given when switching cameras.
function MM_ZI_OverrideSpawnPickerRefund() {
    local root = getroottable();

    // Only wrap once
    if (!("MM_ZI_OriginalRefundSpawnPickerTime" in root) || ::MM_ZI_OriginalRefundSpawnPickerTime == null) {
        ::MM_ZI_OriginalRefundSpawnPickerTime <- CTFPlayer.RefundSpawnPickerTime;
    }

    CTFPlayer.RefundSpawnPickerTime <- function() {
        if (::MM_ZI_OVERTIME) return;
        ::MM_ZI_OriginalRefundSpawnPickerTime.call( this );
    };
    CTFBot.RefundSpawnPickerTime <- CTFPlayer.RefundSpawnPickerTime;
}

// OVERRIDE: functions.nut::CTFPlayer_AddEventToQueue
// MEGAMOD: Gate zombie spy cloak events in Overtime.
function MM_ZI_OverrideSpyRecloak() {
    local root = getroottable();

    // Only wrap once
    if (!("MM_ZI_OriginalAddEventToQueue" in root) || ::MM_ZI_OriginalAddEventToQueue == null) {
        ::MM_ZI_OriginalAddEventToQueue <- CTFPlayer.AddEventToQueue;
    }

    CTFPlayer.AddEventToQueue <- function( _event, _delay ) {
        if (::MM_ZI_OVERTIME && ( _event == EVENT_SPY_RECLOAK || _event == EVENT_SPY_SWAP_CLOAK ))
            return;
        ::MM_ZI_OriginalAddEventToQueue.call( this, _event, _delay );
    };
    CTFBot.AddEventToQueue <- CTFPlayer.AddEventToQueue;
}

function MM_ZI_PrepareForOvertime() {
    // As there is no situation where the ZI codebase calls a game_round_win entity
    // in the map, we can safely nuke all game_round_wins from the map.
    // This prevents the vanilla win behaviour for survivors.
    for (local win = null; win = Entities.FindByClassname(win, "game_round_win");) {
        win.Kill();
    }
    local timer = Entities.FindByClassname(null, "team_round_timer");
    EntityOutputs.AddOutput(timer, "OnFinished", "!self", "RunScriptCode", "MM_ZI_EnableOvertime()", 0, -1);
    PrecacheScriptSound ( "Game.Overtime" );
}

function MM_ZI_EnableOvertime() {
    printl("MEGAMOD: Entering overtime...");

    if (::MM_ZI_OVERTIME_ENABLED == false) {
        // survivors just win
        local _hGameWin = SpawnEntityFromTable( "game_round_win",
        {
            win_reason      = "0",
            force_map_reset = "1",
            TeamNum         = "2", // TF_TEAM_RED
            switch_teams    = "0"
        } );
        ::bGameStarted <- false;
        ::MM_ZI_ROUND_FINISHED <- true;
        EntFireByHandle ( _hGameWin, "RoundWin", "", 0, null, null );
        return;
    }

    ::MM_ZI_OVERTIME <- true;

    // No natural zombie respawns during overtime - the map's BLU wave time is suspended.
    local gamerules = ( "GameRules" in getroottable() && getroottable().GameRules != null )
        ? getroottable().GameRules
        : Entities.FindByClassname( null, "tf_gamerules" );
    if (gamerules != null) {
        EntFireByHandle(gamerules, "SetBlueTeamRespawnWaveTime", "999999", 0, null, null);
    }

    local timer = Entities.FindByClassname(null, "team_round_timer");
    timer.Kill();

    // Respawn all dead survivors so they can participate in overtime.
    // No longer needed as we respawn all dead survivors in ::MM_ZI_ShouldSurvivorsWin
    // foreach( _hNextPlayer in GetAllPlayers() ) {
    //     if (_hNextPlayer.GetTeam() == 2 && GetPropInt(_hNextPlayer, "m_lifeState") != 0) {
    //         DoEntFire("!self", "RunScriptCode", "self.ForceRespawn()", 0.1, null, _hNextPlayer);
    //     }
    // }

    foreach( _hNextPlayer in GetAllPlayers() ) {
        if (_hNextPlayer.GetTeam() == 3 || GetPropInt(_hNextPlayer, "m_lifeState") != 0) {
            SetPropBool( _hNextPlayer, "m_bGlowEnabled", true );
            ClientPrint(_hNextPlayer, 3, "\x0738F3ABNo more respawns for you. Kill all the remaining Survivors to win!\x01");
            ClientPrint(_hNextPlayer, 3, "\x0738F3ABBeware: Survivors can visit your spawn and see you through walls!\x01");
        } else {
            ClientPrint(_hNextPlayer, 3, "\x07FCD303No more respawns for Zombies. Kill all the remaining Zombies to win!\x01");
            ClientPrint(_hNextPlayer, 3, "\x07FCD303You can enter Zombie spawns to hunt down the last few Zombies!\x01");
        }
    }

    // Clear event queue for spy cloaks to ensure consistent state.
    foreach( _hNextPlayer in GetAllPlayers() ) {
        if (_hNextPlayer.GetTeam() == 3 && _hNextPlayer.GetPlayerClass() == TF_CLASS_SPY) {
            local _sc = _hNextPlayer.GetScriptScope();
            if (_sc != null && "m_tblEventQueue" in _sc) {
                if (_sc.m_tblEventQueue.rawin(EVENT_SPY_RECLOAK)) {
                    _sc.m_tblEventQueue.rawdelete(EVENT_SPY_RECLOAK);
                }
                if (_sc.m_tblEventQueue.rawin(EVENT_SPY_SWAP_CLOAK)) {
                    _sc.m_tblEventQueue.rawdelete(EVENT_SPY_SWAP_CLOAK);
                }
            }
            _hNextPlayer.RemoveCond(TF_COND_STEALTHED);
            _hNextPlayer.RemoveCond(TF_COND_STEALTHED_USER_BUFF);
        }
    }

    MM_ZI_MapSpecific_OvertimeStart();

    local overtime_sound = {
        team  = 255,
        sound = "Game.Overtime"
    };
    SendGlobalGameEvent ( "teamplay_broadcast_audio", overtime_sound );

    // Kill all respawn visualizers to stop zombies stalling in spawn.
    for (local vis = null; vis = Entities.FindByClassname(vis, "func_respawnroomvisualizer");) {
        vis.Kill()
    }
    // Kill all respawn rooms to stop zombies from class-changing during overtime.
    for (local respawn = null; respawn = Entities.FindByClassname(respawn, "func_respawnroom");) {
        respawn.Kill()
    }

    EntFireByHandle(::MM_ZI_LOGIC_SCRIPT, "RunScriptCode", "MM_ZI_OvertimeSecondTick()", 1, null, null);
}

// MEGAMOD: Apply zombie glow when overtime starts
function MM_ZI_OnPlayerSpawn(params) {
    if (!::MM_ZI_OVERTIME || ::MM_ZI_ROUND_FINISHED) return;

    local player = GetPlayerFromUserID(params.userid);
    if (player == null) return;

    if (player.GetTeam() == 3) {
        SetPropBool( player, "m_bGlowEnabled", true );
    }
}

::MM_ZI_OvertimeSecondTick <- function() {
    MM_ZI_ShouldSurvivorsWin();

    if (!bGameStarted || MM_ZI_ROUND_FINISHED) return;

    foreach( _hNextPlayer in GetAllPlayers() ) {
        if (_hNextPlayer.GetTeam() == 3 && GetPropInt(_hNextPlayer, "m_lifeState") == 0 && floor(MM_ZI_OVERTIME_DAMAGE) >= 1) {
            local multiplier = _hNextPlayer.GetPlayerClass() == TF_CLASS_HEAVYWEAPONS ? (1.0 / 0.65) : 1.0;
            local rawDamage = floor(MM_ZI_OVERTIME_DAMAGE);
            local damage = (rawDamage * multiplier).tointeger();
            local vecPunch = GetPropVector(_hNextPlayer, "m_Local.m_vecPunchAngle");
            SendGlobalGameEvent("player_healonhit", {
                entindex = _hNextPlayer.entindex(),
                amount = -rawDamage
            });
            _hNextPlayer.TakeDamageCustom(null, _hNextPlayer, null,
                Vector(Epsilon, Epsilon, Epsilon), _hNextPlayer.GetOrigin(),
                damage, DMG_BURN + DMG_PREVENT_PHYSICS_FORCE, TF_DMG_CUSTOM_BLEEDING);
            SetPropVector(_hNextPlayer, "m_Local.m_vecPunchAngle", vecPunch);
        }
    }
    local addDamage = false;
    local damageIncrementThreshold = 10;

    if (::MM_ZI_OVERTIME_DAMAGE >= 40) {
        damageIncrementThreshold = 1;
    } else if (::MM_ZI_OVERTIME_DAMAGE >= 30) {
        damageIncrementThreshold = 2;
    } else if (::MM_ZI_OVERTIME_DAMAGE >= 20) {
        damageIncrementThreshold = 3;
    } else if (::MM_ZI_OVERTIME_DAMAGE >= 10) {
        damageIncrementThreshold = 5;
    } else {
        damageIncrementThreshold = 10;
    }

    ::MM_ZI_OVERTIME_DAMAGE_LAST_INCREASE <- ::MM_ZI_OVERTIME_DAMAGE_LAST_INCREASE + 1;

    if (::MM_ZI_OVERTIME_DAMAGE_LAST_INCREASE >= damageIncrementThreshold) {
        addDamage = true;
        ::MM_ZI_OVERTIME_DAMAGE_LAST_INCREASE <- 0;
    }

    ::MM_ZI_OVERTIME_DAMAGE <- floor(MM_ZI_OVERTIME_DAMAGE + (addDamage ? 1 : 0));

    EntFireByHandle(::MM_ZI_LOGIC_SCRIPT, "RunScriptCode", "MM_ZI_OvertimeSecondTick()", 1, null, null);
}

::MM_ZI_ShouldSurvivorsWin <- function () {
    foreach (_hNextPlayer in GetAllPlayers()) {
        if ( _hNextPlayer.GetTeam() == 3 && GetPropInt( _hNextPlayer, "m_lifeState" ) == 0 ) {
            return;
        }
    }
    local exit = false;
    // We only get here if there are no living zombies.
    // Check if there are dead survivors that can become zombies. If so: respawn them.
    foreach (_hNextPlayer in GetAllPlayers()) {
        if ( _hNextPlayer.GetTeam() == 2 && GetPropInt( _hNextPlayer, "m_lifeState" ) != 0 ) {
            DoEntFire("!self", "RunScriptCode", "MM_ZI_ForceRespawn(self, true)", 0, null, _hNextPlayer);
            exit = true;
        }
    }
    if (exit) return;

    local _hGameWin = SpawnEntityFromTable( "game_round_win",
    {
        win_reason      = "0",
        force_map_reset = "1",
        TeamNum         = "2", // TF_TEAM_RED
        switch_teams    = "0"
    } );

    // the survivors have won the round.
    ::bGameStarted <- false;
    ::MM_ZI_ROUND_FINISHED <- true;
    EntFireByHandle ( _hGameWin, "RoundWin", "", 0, null, null );
}

function MM_ZI_OverrideRoundEnd() {
    ::MM_ZI_LOGIC_SCRIPT_SCOPE.OnGameEvent_teamplay_round_win <- function ( params ) {
        ::MM_ZI_ROUND_FINISHED <- true;

        // Restore the map's default BLU respawn wave time after overtime.
        if (::MM_ZI_OVERTIME && ::MM_ZI_BLUE_RESPAWN_WAVE_DEFAULT > 0.0) {
            local gamerules = ( "GameRules" in getroottable() && getroottable().GameRules != null )
                ? getroottable().GameRules
                : Entities.FindByClassname( null, "tf_gamerules" );
            if (gamerules != null) {
                EntFireByHandle(gamerules, "SetBlueTeamRespawnWaveTime", "" + ::MM_ZI_BLUE_RESPAWN_WAVE_DEFAULT, 0, null, null);
            }
        }
    }
}

// Map specific edits

// Jumppad definitions for overtime map edits.
// Each entry describes one jumppad: a visible base prop (drain pipe), optional extra
// props, an info_particle_system and a trigger_catapult that launch players up to
// the elevated zombie spawn. Particles and catapults are disabled until overtime.
::MM_ZI_JUMPPAD_DEFS <- {
    ["zi_blazehattan_v4_0_5"] = [
        {
            name = "jumppad_gate2",
            origin = "-1400 -1592 39.0283",
            angles = "-90 0 0",
            modelscale = "1.2",
            launchPitch = -75,
            launchYaw = 180,
            launchSpeed = 700.0,
            catapultOrigin = "-1400 -1592.01 40.78",
            min = Vector(-1416, -1608, 30.7783),
            max = Vector(-1384, -1576, 50.7783),
            extraProps = []
        }
    ],
    ["zi_woods_v4_0_5"] = [
        {
            name = "jumppad_cliffside",
            origin = "-732 -4572 38.25",
            angles = "-90 0 0",
            modelscale = "1.2",
            launchPitch = -85,
            launchYaw = 225,
            launchSpeed = 850.0,
            catapultOrigin = "-732 -4572 40",
            min = Vector(-748, -4588, 30),
            max = Vector(-716, -4556, 50),
            extraProps = [
                { suffix = "_base_pipe", model = "models/props_farm/concrete_pipe001.mdl", origin = "-766 -4572 -29.75", angles = "90 0 0", modelscale = "1.0" }
            ]
        },
        {
            name = "jumppad_shoreline",
            origin = "792 -4196 38.25",
            angles = "-90 0 0",
            modelscale = "1.2",
            launchPitch = -75,
            launchYaw = 45,
            launchSpeed = 800.0,
            catapultOrigin = "792 -4196 40",
            min = Vector(776, -4212, 30),
            max = Vector(808, -4180, 50),
            extraProps = [
                { suffix = "_base_pipe", model = "models/props_farm/concrete_pipe001.mdl", origin = "758 -4196 -29.75", angles = "90 0 0", modelscale = "1.0" }
            ]
        },
        {
            name = "jumppad_mines",
            origin = "1548.32 582.295 380.14",
            angles = "-90 0 0",
            modelscale = "1.2",
            launchPitch = -75,
            launchYaw = 65,
            launchSpeed = 800.0,
            catapultOrigin = "1548.32 582.29 381.89",
            min = Vector(1532.32, 566.295, 371.89),
            max = Vector(1564.32, 598.295, 391.89),
            extraProps = []
        }
    ]
}

// Spawns a single jumppad base prop and removes the DONTBLOCKLOS flag so it blocks sight like normal props.
function MM_ZI_SpawnJumppadProp(targetname, model, origin, angles, modelscale) {
    local prop = SpawnEntityFromTable("prop_dynamic",
    {
        targetname = targetname,
        model = model,
        origin = origin,
        angles = angles,
        modelscale = modelscale,
        solid = "6"
    });
    prop.RemoveEFlags(Constants.FEntityEFlags.EFL_DONTBLOCKLOS);
    return prop;
}

// VScript-based jumppad launcher.
// Dynamically spawned trigger_catapult entities never activated in-game, so the launch
// behaviour is implemented here instead: while overtime is active, a periodic think checks
// each player's position against every pad's bounds and applies the launch impulse.
::MM_ZI_JUMPPADS_ACTIVE <- []; // runtime pad data: { min, max, dir, speed }
::MM_ZI_JUMPPAD_COOLDOWN <- {}; // entindex -> last launch Time()

// Spawns all jumppads for the given map. The particle system is spawned disabled;
// MM_ZI_ActivateJumppads() enables it when overtime starts.
function MM_ZI_SpawnJumppads(mapName) {
    local defs = ::MM_ZI_JUMPPAD_DEFS[mapName];
    if (defs == null) return;

    ::MM_ZI_JUMPPADS_ACTIVE <- [];
    ::MM_ZI_JUMPPAD_COOLDOWN <- {};

    foreach (def in defs) {
        // Defensive cleanup in case the previous round didn't fully reset the map.
        MM_KillAllByName(def.name + "_base");
        MM_KillAllByName(def.name + "_particle");

        // Visible base prop(s).
        MM_ZI_SpawnJumppadProp(def.name + "_base", "models/props_farm/drain_pipe001.mdl", def.origin, def.angles, def.modelscale);
        foreach (extra in def.extraProps) {
            MM_ZI_SpawnJumppadProp(def.name + extra.suffix, extra.model, extra.origin, extra.angles, extra.modelscale);
        }

        // Particle effect marking the pad. Disabled until overtime.
        SpawnEntityFromTable("info_particle_system",
        {
            targetname = def.name + "_particle",
            effect_name = "green_steam_plume",
            origin = def.origin,
            angles = def.angles,
            start_active = "0"
        });

        // Register the pad's launch volume for the VScript launcher.
        local dir = MM_ZI_AnglesToDirection(def.launchPitch, def.launchYaw);
        ::MM_ZI_JUMPPADS_ACTIVE.append({
            min = def.min,
            max = def.max,
            dir = dir,
            speed = def.launchSpeed
        });
    }
}

// Mirrors Source's VectorFromAngles (Euler pitch/yaw -> forward direction vector).
function MM_ZI_AnglesToDirection(pitch, yaw) {
    local p = pitch * PI / 180;
    local y = yaw * PI / 180;
    return Vector(cos(y) * cos(p), sin(y) * cos(p), -sin(p));
}

// Periodic think: launches any player standing in a jumppad volume while overtime is active.
::MM_ZI_JumppadThink <- function() {
    if (::MM_ZI_OVERTIME) {
        local now = Time();
        foreach (player in GetAllPlayers()) {
            if (GetPropInt(player, "m_lifeState") != 0) continue;

            // Cooldown so a single entry doesn't re-launch every think.
            local last = null;
            if (::MM_ZI_JUMPPAD_COOLDOWN.rawin(player.entindex())) {
                last = ::MM_ZI_JUMPPAD_COOLDOWN[player.entindex()];
            }
            if (last != null && now - last < 0.5) continue;

            local pos = player.GetOrigin();
            foreach (pad in ::MM_ZI_JUMPPADS_ACTIVE) {
                if (pos.x < pad.min.x || pos.x > pad.max.x) continue;
                if (pos.y < pad.min.y || pos.y > pad.max.y) continue;
                if (pos.z < pad.min.z || pos.z > pad.max.z) continue;

                ::MM_ZI_JUMPPAD_COOLDOWN[player.entindex()] <- now;
                player.SetVelocity(pad.dir * pad.speed);
                break;
            }
        }
    }
}

// Enables the jumppads for the given map (called when overtime starts).
function MM_ZI_ActivateJumppads(mapName) {
    local defs = ::MM_ZI_JUMPPAD_DEFS[mapName];
    if (defs == null) return;

    foreach (def in defs) {
        local particle = MM_GetEntByName(def.name + "_particle");
        if (particle != null) EntFireByHandle(particle, "Start", "", 0, null, null);
    }

    // Start the periodic launcher think (idempotent per round).
    MM_CreateDummyThink("MM_ZI_JumppadThink");
}

function MM_ZI_MapSpecific_RoundStart() {
    local mapName = GetMapName();

    switch (mapName) {
        case "zi_blazehattan_v4_0_5":
            // The spawn near gate 2 needs a jumppad to reach.
            MM_ZI_SpawnJumppads(mapName);
        case "zi_woods_v4_0_5":
            // Three spawns require jumppads to reach.
            MM_ZI_SpawnJumppads(mapName);
    }
}

function MM_ZI_MapSpecific_OvertimeStart() {
    local mapName = GetMapName();

    switch (mapName) {
        case "zi_blazehattan_v4_0_5":
            // Activating Jumppads
            MM_ZI_ActivateJumppads(mapName);
        case "zi_devastation_v4_0_5":
            // Kill all trigger_multiple entities (e.g. spawndoors) and force the exit doors open.
            local triggers = [];
            for (local trig = null; trig = Entities.FindByClassname(trig, "trigger_multiple");) {
                triggers.push(trig);
            }
            foreach (trig in triggers) {
                trig.Kill();
            }
            local door1 = MM_GetEntByName("swr_exit_door_1");
            if (door1 != null) EntFireByHandle(door1, "Open", "", 0, null, null);
            local door2 = MM_GetEntByName("swr_exit_door_2");
            if (door2 != null) EntFireByHandle(door2, "Open", "", 0, null, null);
        case "zi_woods_v4_0_5":
            // Activating Jumppads
            MM_ZI_ActivateJumppads(mapName);
    }
}
