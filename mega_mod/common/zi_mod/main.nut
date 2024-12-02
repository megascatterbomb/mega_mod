function MM_Zombie_Infection() {
    MM_OverrideSetupFinished();
    MM_OverrideDeath();

    local gamerules = Entities.FindByClassname(null, "tf_gamerules");
    if (gamerules != null)  {
        EntFireByHandle(gamerules, "SetRedTeamRespawnWaveTime", "6", 0, null, null);
        EntFireByHandle(gamerules, "SetBlueTeamRespawnWaveTime", "999999", 0, null, null);
    }
    // TODO: Fixed value for round timer
    // TODO: Remove BASE Jumper nerf
    // TODO: Reduce effect of jumper weapon nerf.
    // TODO: Endgame/Overtime before survivor victory.
    // TODO: Prevent players from becoming zombies twice in a row
}

// OVERRIDE: replacement for infection.nut::OnGameEvent_teamplay_setup_finished
function MM_OverrideSetupFinished() {
    local logic_script = Entities.FindByClassname(null, "logic_script");
    local scope = logic_script.GetScriptScope();

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
                else if ( _iPlayerCountRed < 18 )
                {
                    _numStartingZombies = 4;
                }
                else // 18 or more players
                {
                    _numStartingZombies = RoundUp( _iPlayerCountRed / STARTING_ZOMBIE_FAC );
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
function MM_OverrideDeath() {

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
            DoEntFire("!self", "RunScriptCode", "self.ForceRespawn()", 0.1, null, _hPlayer);

            return; // zombie death event ends here
        }

        if ( ::bGameStarted ) // if the game is started, a dying survivor becomes a zombie
        {
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
            ShouldZombiesWin ( _hPlayer );

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
                // create an infection specific timer
                _hRoundTimer = SpawnEntityFromTable( "team_round_timer",
                {
                    auto_countdown       = "0",
                    max_length           = "120",
                    reset_time           = "1",
                    setup_length         = "30",
                    show_in_hud          = "1",
                    show_time_remaining  = "1",
                    start_paused         = "0",
                    timer_length         = "120",
                    StartDisabled        = "0",
                } );
            }
            else
            {
                EntFireByHandle( _hRoundTimer, "auto_countdown", "0", 0, null, null );
            }

            if ( bIsPayload )
                return; // don't add time to the round timer if it's a payload map

            EntFireByHandle( _hRoundTimer, "AddTime", ADDITIONAL_SEC_PER_PLAYER.tostring(), 0, null, null );
        } else {
            // MEGAMOD: If game hasn't started, instantly respawn.
            DoEntFire("!self", "RunScriptCode", "self.ForceRespawn()", 0.1, null, _hPlayer);
        }
    };
}