minigame <- Ware_MinigameData
({
	name           = "Dodgeball"
	author         = ["megascatterbomb"]
	description    = "Reflect the homing rockets!"
	duration       = 168.0
	end_delay      = 2.0
	location       = "boxarena"
	music          = "dodgeball" // TODO
	min_players    = 2
	start_freeze   = 2.0
	allow_damage   = true
	custom_overlay = "airblast_rockets"
	convars =
	{
		tf_flamethrower_burstammo = 1
	}
})

db_scope <- this

rockets <- []

rocket_speed_initial <- 250.0 // hu/s
rocket_speed_ratio <- 1.1
rocket_stall_threshold <- 10.0 // seconds
rocket_stall_speed_increase <- 50.0 // hu/s per second
rocket_turn_speed_base <- 0 // degrees per second
rocket_turn_speed_deg <- @(s) rocket_turn_speed_base + (0.004 * s * s) // degrees per second, s is the speed of the rocket
rocket_turn_speed_rad <- @(s) rocket_turn_speed_deg(s) * PI / 180.0

GetMinRocketCount <- @(num_players) ceil(num_players / 25.0)
GetMaxRocketCount <- @(num_players) floor(sqrt(num_players)) + target_rocket_count_extra

target_rocket_count <- 1
target_rocket_count_extra <- 0 // make things spicier over time for smaller player counts.
rocket_end <- false

launcher_origin <- Ware_Location.boxarena.center + Vector(0, 0, 200)
launcher_effect <- null
launcher_effect_offset <- launcher_origin + Vector(0, 0, 0)
launcher <- null

rocket_target_offset <- Vector(0, 0, 48.0)

class Rocket {
	handle = null
	rocketTeam = null // team of the rocket (targets other team)
	target = null
	reflect_time = 0.0
	reflect_count = 0
	db_scope = db_scope
	think = null

	RocketThink = null
	OnReflect = null

	constructor(targetTeam, target = null)
	{
		this.target = target ? target : db_scope.SelectRocketTargetFromTeam(targetTeam)
		this.rocketTeam = this.target.GetTeam() == TF_TEAM_RED ? TF_TEAM_BLUE : TF_TEAM_RED
		this.reflect_time = Time()

		//db_scope.launcher.SetTeam(TEAM_SPECTATOR)
		db_scope.launcher.AcceptInput("FireOnce", "", null, null)

		local rocket = FindByClassname(null, "tf_projectile_rocket")
		if (rocket != null)
		{
			MarkForPurge(rocket)
			rocket.SetOwner(this.target)
			rocket.SetTeam(TEAM_SPECTATOR)
			rocket.KeyValueFromString("classname", "ware_projectile")
			this.handle = rocket
		} else {
			printl("Failed to find rocket after firing launcher!")
			return
		}

		this.RocketThink = function ()
		{
			if(!db_scope)
				return 10.0 // stop thinking, we're gonna be purged soon anyway)

			local rocketPos = this.handle.GetOrigin()
			local rocketVelocity = this.handle.GetAbsVelocity()

			local targetVector = null

			if (!this.target || !this.target.IsValid() || !this.target.IsAlive())
			{
				// No target, reassign to same team if possible
				if (!db_scope.rocket_end)
				{
					local targetTeam = this.rocketTeam == TF_TEAM_RED ? TF_TEAM_BLUE : TF_TEAM_RED
					this.target = db_scope.SelectRocketTargetFromTeam(targetTeam)
				}
			}

			if (!db_scope.rocket_end && this.target && this.target.IsValid() && this.target.IsAlive())
			{
				local targetPos = this.target.GetOrigin()
				// if the rocket is a spectator rocket, it won't explode on its target because we set its owner to the initial target,
				// check if the rocket is close enough to contact initial target then remove owner tag.
				if (this.handle.GetTeam() == TEAM_SPECTATOR && ((targetPos + db_scope.rocket_target_offset) - rocketPos).Length() < 24.0)
				{
					this.handle.SetOwner(null)
					// deal non-crit damage to all players in range
					local explosion = SpawnEntityFromTable("env_explosion",
					{
						origin = rocketPos
						iRadiusOverride = 64.0
						iMagnitude = 20 + 2 * (Ware_GetAlivePlayers().len())
						damagetype = DMG_BLAST
						flags = 0x254 // no sound, no fireball. no particles, no sounds
					})
					explosion.AcceptInput("Explode", "", null, null)
					this.handle.Kill()
					return
				} 
				targetVector = (targetPos - rocketPos) + db_scope.rocket_target_offset
			} else {
				// No target, go straight up
				targetVector = Vector(0, 0, 1)
			}

			local actualSpeed = db_scope.rocket_speed_initial * pow(db_scope.rocket_speed_ratio, this.reflect_count)
			if (Time() - this.reflect_time > db_scope.rocket_stall_threshold)
				actualSpeed += (Time() - this.reflect_time - db_scope.rocket_stall_threshold) * db_scope.rocket_stall_speed_increase

			local actualVector = rocketVelocity
			targetVector.Norm()
			actualVector.Norm()
			
			local dot = Min(Max(actualVector.Dot( targetVector ), -1.0), 1.0);
    		local angle = acos(dot);
			local maxTurnAngleRad = db_scope.rocket_turn_speed_rad(actualSpeed) * FrameTime()
			
			if (angle < maxTurnAngleRad) // directly face target
			{
				actualVector = targetVector
			}
			else // rotate towards target by max turn angle
			{
				local axis = actualVector.Cross( targetVector )
				axis.Norm()
				local cosA = cos( maxTurnAngleRad );
    			local sinA = sin( maxTurnAngleRad );

				actualVector = actualVector * cosA +
					axis.Cross( actualVector ) * sinA +
					axis * axis.Dot( actualVector ) * ( 1 - cosA );
			}

			this.handle.SetAbsVelocity(actualVector * actualSpeed)
			this.handle.SetForwardVector(actualVector)

			return -1
		}.bindenv(this)

		this.OnReflect = function (reflector)
		{
			this.reflect_time = Time()
			this.reflect_count++
			printl("Reflect count: " + reflect_count)
			this.rocketTeam = reflector.GetTeam() == TF_TEAM_RED ? TF_TEAM_RED : TF_TEAM_BLUE
			this.target = db_scope.SelectRocketTargetByReflector(reflector)
		}

		this.handle.ValidateScriptScope()
		this.handle.GetScriptScope().ClassScope <- this
		this.handle.GetScriptScope().Think <- this.RocketThink
		AddThinkToEnt(this.handle, "Think")
	}
}

// TODO: rocket movement https://discord.com/channels/217585440457228290/217585440457228290/1038507132368199852

function OnPrecache()
{
	// TODO: precache launcher effect?
}

function OnTeleport(players)
{
	players.sort(function(a, b) { return a.GetTeam() <=> b.GetTeam() })
	Ware_TeleportPlayersCircle(players, Ware_MinigameLocation.center, 800.0)
}

function OnUpdate()
{
	// disable primary fire
	foreach (player in Ware_MinigamePlayers)
	{
		local weapon = player.GetActiveWeapon()
		if (weapon && weapon.GetSlot() == TF_SLOT_PRIMARY)
			SetPropFloat(weapon, "m_flNextPrimaryAttack", 1e30)
	}
}

function OnStart()
{
	launcher = Ware_SpawnEntity("tf_point_weapon_mimic",
	{
		origin 	= launcher_origin
		WeaponType = 0
		SpeedMin   = rocket_speed_initial
		SpeedMax   = rocket_speed_initial
		Damage     = 20 + 2 * (Ware_GetAlivePlayers().len())
		Crits      = true
		angles     = QAngle(90, 0, 0)
	})
	launcher.SetTeam(TEAM_SPECTATOR)

	Ware_SetGlobalLoadout(TF_CLASS_PYRO, "Flame Thrower")

	target_rocket_count <- GetMinRocketCount(Ware_GetAlivePlayers().len())
	Ware_CreateTimer(CheckSpawnRocket, 2.0)
	Ware_CreateTimer(IncreaseRocketCount, 10.0)
	Ware_CreateTimer(@() target_rocket_count_extra++, 45.0)
	Ware_CreateTimer(@() target_rocket_count_extra++, 95.0)
	Ware_CreateTimer(@() rocket_end <- true, 165.0)
}

function OnTakeDamage(params)
{
	if (params.const_entity.IsPlayer())
	{
		params.weapon = null
		params.attacker = World

		local inflictor = params.inflictor
		if (inflictor != null && inflictor.GetClassname() == "ware_projectile")
		{
			// prevents server crash because of attacker not being a player
			SetPropEntity(inflictor, "m_hLauncher", null)
		}
	}
}

function GetRocketCountTarget() {
	local num_players = Ware_GetAlivePlayers().len()
	local min = GetMinRocketCount(num_players)
	if (target_rocket_count < min)
		return min
	local max = GetMaxRocketCount(num_players)
	if (target_rocket_count > max)
		return max
	return target_rocket_count
}

function IncreaseRocketCount()
{
	target_rocket_count++
	Ware_CreateTimer(IncreaseRocketCount, 10.0)
}

function CheckSpawnRocket()
{
	if (rocket_end || (Ware_GetAlivePlayers(TF_TEAM_RED).len() == 0 || Ware_GetAlivePlayers(TF_TEAM_BLUE).len() == 0))
		return
	
	if (rockets.len() < GetRocketCountTarget())
		SpawnRocket()
	rockets = rockets.filter(@(i, r) r.handle != null && r.handle.IsValid())
	Ware_CreateTimer(CheckSpawnRocket, 1.0)
}

function SpawnRocket(team = null)
{
	local rocket = Rocket(team)
	rockets.append(rocket)
}

function GetRockets(team = null)
{
	return rockets.filter(@(i, r) r.handle != null && r.handle.IsValid() && (r.rocketTeam == team || team == null || team == 0))
}

function SelectRocketTargetFromTeam(targetTeam = null)
{
	if (rocket_end)
		return null // go straight up

	local redRockets = GetRockets(TF_TEAM_RED)
	local blueRockets = GetRockets(TF_TEAM_BLUE)

	local redPlayers = Ware_GetAlivePlayers(TF_TEAM_RED)
	local bluePlayers = Ware_GetAlivePlayers(TF_TEAM_BLUE)

	// calculate per team "alive player count - rockets targeting team" and choose team with highest value (combine both if tied)
	if (targetTeam != TF_TEAM_RED && targetTeam != TF_TEAM_BLUE)
	{
		// remember rockets target the opposite team of their own
		local redCount = redPlayers.len() - blueRockets.len()
		local blueCount = bluePlayers.len() - redRockets.len()

		if (redCount > blueCount)
			targetTeam = TF_TEAM_RED
		else if (blueCount > redCount)
			targetTeam = TF_TEAM_BLUE
		else
			targetTeam = null
	}


	local candidates = []

	if (targetTeam != TF_TEAM_RED)
		candidates.extend(bluePlayers)
	if (targetTeam != TF_TEAM_BLUE)
		candidates.extend(redPlayers)

	local rocketCounts = {}
	local minRockets = null
	local leastTargetedPlayers = []

	// choose the least targeted candidate (randomly choose if multiple options)
	foreach (player in candidates)
		rocketCounts[player.GetEntityIndex()] <- 0

	foreach (rocket in rockets)
	{
		if (rocket.target != null && rocket.target.IsValid())
		{
			local targetIndex = rocket.target.GetEntityIndex()
			if (targetIndex in rocketCounts)
			{
				rocketCounts[targetIndex] += 1
			}
		}
	}

	foreach (player in candidates)
	{
		local count = rocketCounts[player.GetEntityIndex()]
		if (minRockets == null || count < minRockets)
		{
			minRockets = count
		}
	}

	foreach (player in candidates)
	{
		local count = rocketCounts[player.GetEntityIndex()]
		if (count == minRockets)
		{
			leastTargetedPlayers.append(player)
		}
	}

	if (leastTargetedPlayers.len() == 0)
		if (candidates.len() == 0)
			return null
		else
			return candidates[RandomInt(0, candidates.len() - 1)]

	return leastTargetedPlayers[RandomInt(0, leastTargetedPlayers.len() - 1)]
}

function SelectRocketTargetByReflector(reflector = null)
{
	
	if (!reflector) // no reflector provided, fail-safe. Should never happen
	{
		return null
	}
	// calculate per enemy player "(shortest distance of enemy to reflector's line of sight) minus (distance to enemy along reflector's LOS axis)" and take highest value
	local rocketTeam = reflector.GetTeam() == TF_TEAM_RED ? TF_TEAM_RED : TF_TEAM_BLUE
	local targetTeam = rocketTeam == TF_TEAM_RED ? TF_TEAM_BLUE : TF_TEAM_RED

	local origin = reflector.GetOrigin()
	local lookVector = reflector.EyeAngles().Forward()

	lookVector.z = 0 // don't factor in vertical angles.
	lookVector.Norm()

	// TODO: fix the target selection being wrong.
	local distanceToLOS = @(p) (p.GetOrigin() - origin).Cross(lookVector).Length() / lookVector.Length()
	local distanceAlongLOS = @(p)(p.GetOrigin() - origin).Dot(lookVector) / lookVector.Length()

	local candidates = Ware_GetAlivePlayers(targetTeam)
	local scores = {}

	foreach (player in candidates)
	{
		scores[player.GetEntityIndex()] <- distanceToLOS(player) - distanceAlongLOS(player)
	}

	local bestScore = null
	local bestTarget = null
	foreach (player in candidates)
	{
		local score = scores[player.GetEntityIndex()]
		if (bestScore == null || score > bestScore)
		{
			bestScore = score
			bestTarget = player
		}
	}

	return bestTarget
}

function OnGameEvent_object_deflected(params)
{
	printl("REFLECTION EVENT")
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	local object = EntIndexToHScript(params.object_entindex)
	if (object != null && object.GetClassname() == "ware_projectile")
	{
		foreach (rocket in rockets)
		{
			if (rocket.handle == object && rocket.handle.entindex() == params.object_entindex)
			{
				rocket.OnReflect(player)
				break
			}
		}
	}
}

function OnCheckEnd()
{
	// either when everyone dies, or one team dies and that team has no active rockets
	return Ware_GetAlivePlayers().len() == 0 ||
		(
			Ware_GetAlivePlayers(TF_TEAM_RED).len() == 0 &&
			GetRockets(TF_TEAM_RED).len() == 0
		) ||
		(
			Ware_GetAlivePlayers(TF_TEAM_BLUE).len() == 0 &&
			GetRockets(TF_TEAM_BLUE).len() == 0
		)
}

function OnEnd()
{
	foreach (player in Ware_GetAlivePlayers())
	{
		Ware_PassPlayer(player, true)
	}
}

function OnCleanup() {
	for (local rocket = null; rocket = FindByClassname(rocket, "ware_projectile"); )
	{
		rocket.Kill()
	}
}