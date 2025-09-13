::MM_ZI_ROUND_FINISHED <- false;
::MM_ZI_LAST_SURVIVOR_DEATH <- 0;
::MM_ZI_STARTING_PLAYERS <- 1;
::MM_ZI_STARTING_SURVIVORS <- 1;
::MM_ZI_OVERTIME <- false;
::MM_ZI_OVERTIME_DAMAGE <- 0;

function MM_Zombie_Infection() {
    local gamerules = Gamerules();
    if (gamerules != null)  {
        // Delay so our settings overwrite those set by logic_auto ents.
        EntFireByHandle(gamerules, "SetRedTeamRespawnWaveTime", "5", 5, null, null);
        EntFireByHandle(gamerules, "SetBlueTeamRespawnWaveTime", "999999", 5, null, null);

        gamerules.ValidateScriptScope();
        local gamerules_scope = gamerules.GetScriptScope();
        if (!("zi_chosen_zombies" in gamerules_scope)) {
            gamerules_scope["zi_chosen_zombies"] <- [];
        }
    }

    ::MM_ZI_ROUND_FINISHED <- false;
    ::MM_ZI_OVERTIME <- false;
    ::MM_ZI_OVERTIME_DAMAGE <- 0;

    MM_ZI_OverrideSetupFinished();
    MM_ZI_OverrideDeath();
    MM_ZI_OverrideZombieSelection();
    MM_ZI_OverrideRoundEnd();
    MM_ZI_OverrideWeaponMods();
    MM_ZI_OverrideShouldZombiesWin();

    MM_ZI_PrepareForOvertime();
}

function MM_ZI_OnPlayerTeam(params) {
    if (!::MM_ZI_OVERTIME || !::bGameStarted || ::MM_ZI_ROUND_FINISHED) return;
    if ( params.team == 2 ) {
        local player = GetPlayerFromUserID(params.userid);
        EntFireByHandle(player, "RunScriptCode", "ChangeTeamSafe(self, 3, true); self.ForceRespawn(); self.TakeDamage(1000000, 0, null)", 0, null, player)
    }
}

// OVERRIDE: replacement for functions.nut::GetRandomPlayers
function MM_ZI_OverrideZombieSelection() {
    // MEGAMOD: Zombie selection will always ignore zombies from last round if possible.
    ::GetRandomPlayers <- function( _howMany = 1 )
    {
        local _playerArr = [];
        local _lowPriorityPlayerArr = [];

        local gamerules = Gamerules();
        local gamerules_scope = gamerules.GetScriptScope();

        // gamerules_scope["zi_chosen_zombies"].map(function(p) {
        //     printl(p);
        //     return true;
        // });

        printl("# of low prio players " + gamerules_scope["zi_chosen_zombies"].len())

        foreach ( _hPlayer in GetAllPlayers() )
        {
            if ( _hPlayer != null /* &&  ( _hPlayer.GetFlags() & FL_FAKECLIENT ) == 0 */  ) {
                if (gamerules_scope["zi_chosen_zombies"].find(_hPlayer.entindex()) != null) {
                    // printl("Deprioritizing " + NetName(_hPlayer));
                    _lowPriorityPlayerArr.append(_hPlayer);
                } else {
                    _playerArr.append( _hPlayer )
                };
            }
        };

        local availablePlayers = _playerArr.len() + _lowPriorityPlayerArr.len();
        _howMany = ( _howMany <= availablePlayers ) ? _howMany : availablePlayers;

        local _selectedPlayers = [];

        for ( local i = 0; i < _howMany; i++ )
        {
            if (_playerArr.len() == 0) break;
            local _randomID = RandomInt ( 0, _playerArr.len() - 1 );
            _selectedPlayers.append     ( _playerArr[ _randomID ] );
            _playerArr.remove           ( _randomID );
        };

        for (local i = _selectedPlayers.len(); i < _howMany; i++ ) {
            if (_lowPriorityPlayerArr.len() == 0) break;
            local _randomID = RandomInt ( 0, _lowPriorityPlayerArr.len() - 1 );
            _selectedPlayers.append     ( _lowPriorityPlayerArr[ _randomID ] );
            _playerArr.remove           ( _randomID );
        }

        gamerules_scope["zi_chosen_zombies"] <- _selectedPlayers.map(function(p) {
            // printl(p.entindex());
            return p.entindex();
        });

        ::MM_ZI_STARTING_PLAYERS = availablePlayers;
        ::MM_ZI_STARTING_SURVIVORS = availablePlayers - _selectedPlayers.len();

        return _selectedPlayers;
    };
}

// OVERRIDE: replacement for infection.nut::OnGameEvent_teamplay_setup_finished
function MM_ZI_OverrideSetupFinished() {
    local logic_script = Entities.FindByClassname(null, "logic_script");
    local scope = logic_script.GetScriptScope();

    // Some maps might set gamerules at the end of setup time. This is just a safety check.
    local gamerules = Gamerules();
    if (gamerules != null)  {
        EntFireByHandle(gamerules, "SetRedTeamRespawnWaveTime", "6", 1, null, null);
        EntFireByHandle(gamerules, "SetBlueTeamRespawnWaveTime", "999999", 1, null, null);
    }

    scope.OnGameEvent_teamplay_setup_finished <- function ( params )
    {
        ::bGameStarted <- true;

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
                if ( _iPlayerCountRed <= 4 )
                {
                    _numStartingZombies = 1;
                }
                else if ( _iPlayerCountRed <= 8 )
                {
                    _numStartingZombies = 2;
                }
                else if ( _iPlayerCountRed <= 12 )
                {
                    _numStartingZombies = 3;
                }
                else if (_iPlayerCountRed <= 16)
                {
                    _numStartingZombies = 4;
                }
                else // 17 or more players
                {
                    _numStartingZombies = floor(sqrt(_iPlayerCountRed - 1));
                }
            }

            local _szZombieNetNames  =  "";
            local _zombieArr         =  GetRandomPlayers( _numStartingZombies );

            if ( _zombieArr.len() == 0 )
                return;

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

                // ------------------------------------------- //
                // make sure heavy doesn't get stuck in t-pose //
                // ------------------------------------------- //

                if ( _nextPlayer.GetPlayerClass() == TF_CLASS_HEAVYWEAPONS )
                {
                    if ( _nextPlayer.GetActiveWeapon().GetClassname() == "tf_weapon_minigun" )
                    {
                        SetPropInt( _nextPlayer.GetActiveWeapon(), "m_iWeaponState", 0 );
                    };
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
                _sc.m_iFlags <- ( ( _sc.m_iFlags | ZBIT_PENDING_ZOMBIE ) );

                // don't delay zombie conversion when the player is alive.
                _nextPlayer.SetNextActTime ( ZOMBIE_BECOME_ZOMBIE, INSTANT );
                _nextPlayer.SetNextActTime ( ZOMBIE_ABILITY_CAST, 0.1 );

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
            EntFireByHandle(_hRoundTimer, "SetTime", "120", 0, null, null);
            EntFireByHandle(_hRoundTimer, "SetMaxTime", "120", 0, null, null);

            PlayGlobalBell( false );

            // show the first infected announce message to all players
            PrintToChat( _szFirstInfectedAnnounceMSG );
        }
    };
}

// OVERRIDE: replacement for infection.nut::OnGameEvent_player_death
function MM_ZI_OverrideDeath() {

    local logic_script = Entities.FindByClassname(null, "logic_script");
    local scope = logic_script.GetScriptScope();

    scope.OnGameEvent_player_death <- function ( params )
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
        local _bIsEngineerWithEMP  =  ( _hPlayer.GetPlayerClass() == TF_CLASS_ENGINEER && _hPlayer.CanDoAct( ZOMBIE_ABILITY_CAST ) );

        SetPropIntArray( _hPlayer, "m_nModelIndexOverrides", 0, 3 );

        if ( ::bGameStarted && _hPlayerTeam == TF_TEAM_BLUE ) // zombie has died
        {

            if ( _iClassNum ==  TF_CLASS_MEDIC )
            {
                if ( _sc.m_hMedicDispenser )
                    _sc.m_hMedicDispenser.Destroy();
            }

            // zombie engie with unused emp grenade drops a small ammo kit
            // so just use the one valve spawned for us
            if ( !_bIsEngineerWithEMP )
            {
                // if the player isn't an engineer, we want to cull the kit instead
                local _hDroppedAmmo = null;
                while ( _hDroppedAmmo = Entities.FindByClassname( _hDroppedAmmo, "tf_ammo_pack" ) )
                {
                    if ( _hDroppedAmmo.GetOwner() == _hPlayer )
                    {
                        _hDroppedAmmo.Destroy();
                    };
                };
            };

            if ( _hPlayer.GetPlayerClass() == TF_CLASS_SNIPER )
            {
                _sc.m_hZombieAbility.CreateSpitball( true );
            };

             if ( _hPlayer.GetPlayerClass() == TF_CLASS_PYRO )
             {
                local _hNextPlayer = null;
                local _hKillicon = KilliconInflictor( KILLICON_PYRO_BREATH );

                CreateMediumHealthKit( _hPlayer.GetOrigin() );

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

            }
            else
            {
                if ( _hPlayer.GetPlayerClass() == TF_CLASS_HEAVYWEAPONS )
                {
                    CreateMediumHealthKit( _hPlayer.GetOrigin() );
                }
                else
                {
                    CreateSmallHealthKit( _hPlayer.GetOrigin() );
                }

            };

            // ------------------------------------- //
            // remove zombie "vgui"                  //
            // ------------------------------------- //
            // we use the script overlay material for zombie ability hud
            // so let's make sure it's cleared whenever a player has respawned
            _hPlayer.SetScriptOverlayMaterial ( "" );

            // same thing for the HUD text channels
            _sc.m_hHUDText.KeyValueFromString ( "message", "" );
            _sc.m_hHUDTextAbilityName.KeyValueFromString ( "message", "" );

            EntFireByHandle( _sc.m_hHUDText,  "Display", "", 0.0, _hPlayer, _hPlayer );
            EntFireByHandle( _sc.m_hHUDTextAbilityName,  "Display", "", 0.0, _hPlayer, _hPlayer );

            // ------------------------------------- //
            // Zombie Gib Hack                       //
            // ------------------------------------- //
            // when a player has the zombie skin override, they are hard coded to never gib
            // if we remove this skin here it creates gibs for the player
            SetPropInt ( _hPlayer, "m_iPlayerSkinOverride", 0 );

            // we set custom model on the player afterwards because otherwise the gibs come out red
            _hPlayer.SetCustomModelWithClassAnimations( arrTFClassPlayerModels[ _iClassNum ] );

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

            // hide our fx wearable to stop the particles from generating
            SetPropInt( _sc.m_hZombieFXWearable, "m_nRenderMode", kRenderNone );

            // _sc.m_hZombieWearable.Kill();
            // SendGlobalGameEvent( "post_inventory_application", { userid = GetPlayerUserID(_hPlayer) });

            try { _sc.m_hZombieFXWearable.Destroy() } catch ( e ) {}

            // MEGAMOD: Instantly respawn the zombie.
            // BLU's respawnwavetime is set to 999999 to facilitate overtime. To make respawns not instant, change this delay.
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

            if ( bIsPayload )
                return; // don't add time to the round timer if it's a payload map

            // MEGAMOD: Reduce the time added when there's a large number of survivors
            local minTimeToAdd = 2;
            local adjustedTimeToAdd = ADDITIONAL_SEC_PER_PLAYER - floor(remainingSurvivors / 5)
            if (adjustedTimeToAdd < minTimeToAdd)
                adjustedTimeToAdd = minTimeToAdd;

            EntFireByHandle(_hRoundTimer, "AddTime", ceil(adjustedTimeToAdd).tostring(), 0, null, null);

            MM_ZI_LAST_SURVIVOR_DEATH <- Time();
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

                        // MEGAMOD: Do not disable BASE Jumper. We'll do that in overtime instead.
                        // if (_hNextPlayer.GetPlayerClass() == TF_CLASS_SOLDIER || _hNextPlayer.GetPlayerClass() == TF_CLASS_DEMOMAN)
                        // {
                        //     local _bDestroyedParachuteResult = _hNextPlayer.HasThisWeapon( 1101, true );
                        // }

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
    ::MM_ZI_OVERTIME <- true;
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
            ClientPrint(_hNextPlayer, 3, "\x0738F3ABNo more respawns for you. Kill the remaining Survivors to win!\x01");
        } else {
            // Disable B.A.S.E. Jumper in overtime instead of the last player.
            ClientPrint(_hNextPlayer, 3, "\x07FCD303No more respawns for Zombies. Kill the remaining Zombies to win!\x01");
            if (_hNextPlayer.GetPlayerClass() == TF_CLASS_SOLDIER || _hNextPlayer.GetPlayerClass() == TF_CLASS_DEMOMAN)
            {
                local _bDestroyedParachuteResult = _hNextPlayer.HasThisWeapon( 1101, true );
                if (_bDestroyedParachuteResult)
                {
                    ClientPrint(_hNextPlayer, 3, "\x07FCD303Your B.A.S.E. Jumper has been disabled.\x01");
                }
            }
        }
    }

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

    local logic_script = Entities.FindByClassname(null, "logic_script");
    EntFireByHandle(logic_script, "RunScriptCode", "MM_ZI_OvertimeSecondTick()", 1, null, null);
}

::MM_ZI_OvertimeSecondTick <- function() {
    MM_ZI_ShouldSurvivorsWin();

    if (!bGameStarted || MM_ZI_ROUND_FINISHED) return;

    foreach( _hNextPlayer in GetAllPlayers() ) {
        if (_hNextPlayer.GetTeam() == 3 && GetPropInt(_hNextPlayer, "m_lifeState") == 0 && floor(MM_ZI_OVERTIME_DAMAGE) >= 1) {
            local vecPunch = GetPropVector(_hNextPlayer, "m_Local.m_vecPunchAngle");
            _hNextPlayer.TakeDamageCustom(null, _hNextPlayer, null,
                Vector(Epsilon, Epsilon, Epsilon), _hNextPlayer.GetOrigin(),
                floor(MM_ZI_OVERTIME_DAMAGE), DMG_BURN + DMG_PREVENT_PHYSICS_FORCE, TF_DMG_CUSTOM_BLEEDING);
            SetPropVector(_hNextPlayer, "m_Local.m_vecPunchAngle", vecPunch);
        }
    }

    ::MM_ZI_OVERTIME_DAMAGE <- MM_ZI_OVERTIME_DAMAGE + 0.1;

    local logic_script = Entities.FindByClassname(null, "logic_script");
    EntFireByHandle(logic_script, "RunScriptCode", "MM_ZI_OvertimeSecondTick()", 1, null, null);
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

    // the zombies have won the round.
    ::bGameStarted <- false;
    ::MM_ZI_ROUND_FINISHED <- true;
    EntFireByHandle ( _hGameWin, "RoundWin", "", 0, null, null );
}

function MM_ZI_OverrideRoundEnd() {
    local logic_script = Entities.FindByClassname(null, "logic_script");
    local scope = logic_script.GetScriptScope();

    scope.OnGameEvent_teamplay_round_win <- function ( params ) {
        ::MM_ZI_ROUND_FINISHED <- true;
    }
}

// OVERRIDE: functions.nut::CTFPlayer_ModifyJumperWeapons
function MM_ZI_OverrideWeaponMods() {
    // printl("Loading modified jumper script.");
    CTFPlayer["ModifyJumperWeapons"] <-  function () {
        // printl("Running modified jumper script.");
        if ( this.GetPlayerClass() == TF_CLASS_SOLDIER )
        {
            if ( this.HasThisWeapon( 237 ) ) // rocket jumper
            {
                /*local _hWeapon = GetPropEntityArray( this, "m_hMyWeapons", 1 );

                _hWeapon.AddAttribute ( "maxammo primary reduced", 0.0, -1 );
                SetPropIntArray       ( this, "m_iAmmo", 0, 1 );

                _hWeapon.ReapplyProvision();
                return;*/
                for ( local i = 0; i < TF_WEAPON_COUNT; i++ )
                {
                    local _hWeapon = GetPropEntityArray( this, "m_hMyWeapons", i )

                    if ( _hWeapon == null )
                        return;

                    if ( GetPropInt( _hWeapon, STRING_NETPROP_ITEMDEF ) != 237 )
                        continue;

                    // MEGAMOD: reserve ammo of 5
                    local newMaxAmmo = 5;
                    _hWeapon.AddAttribute ( "maxammo primary reduced", newMaxAmmo / 60.0, -1 );
                    SetPropIntArray       ( this, "m_iAmmo", 5, 1 );

                    _hWeapon.ReapplyProvision();
                    return;
                }
            };
        };

        if ( this.GetPlayerClass() == TF_CLASS_DEMOMAN )
        {
            if ( this.HasThisWeapon( 265 ) ) // sticky jumper
            {
                /*local _hWeapon = GetPropEntityArray( this, "m_hMyWeapons", 2 );

                _hWeapon.AddAttribute ( "hidden secondary max ammo penalty", 0.02, -1 );
                SetPropIntArray       ( this, "m_iAmmo", 0, 2 );

                _hWeapon.ReapplyProvision();
                return;*/
                for ( local i = 0; i < TF_WEAPON_COUNT; i++ )
                {
                    local _hWeapon = GetPropEntityArray( this, "m_hMyWeapons", i )

                    if ( _hWeapon == null )
                        return;

                    if ( GetPropInt( _hWeapon, STRING_NETPROP_ITEMDEF ) != 265 )
                        continue;

                    // MEGAMOD: reserve ammo of 5
                    local newMaxAmmo = 5;
                    _hWeapon.AddAttribute ( "hidden secondary max ammo penalty", newMaxAmmo / 72.0, -1 );
                    SetPropIntArray       ( this, "m_iAmmo", 5, 2 );

                    _hWeapon.ReapplyProvision();
                    return;
                }
            };
        };
    };
}

// We can't beat the vanilla function's execution, so we load the modified function ahead of time.
MM_ZI_OverrideWeaponMods();