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
	custom_overlay = "airblast_rockets"
})

db_scope <- this

rockets <- []

rocket_speed_initial <- 250.0
rocket_speed_increment <- 25.0
rocket_stall_threshold <- 10.0

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
	speed = rocket_speed_initial
	last_reflect_time = 0.0
	db_scope = db_scope
	think = null

	RocketThink = null
	OnReflect = null

	constructor(targetTeam, target = null)
	{
		this.target = target ? target : db_scope.SelectRocketTarget()
		this.rocketTeam = this.target.GetTeam() == TF_TEAM_RED ? TF_TEAM_BLUE : TF_TEAM_RED
		this.last_reflect_time = Time()

		//db_scope.launcher.SetTeam(TEAM_SPECTATOR)
		db_scope.launcher.AcceptInput("FireOnce", "", null, null)

		local rocket = FindByClassname(null, "tf_projectile_rocket")
		if (rocket != null)
		{
			MarkForPurge(rocket)
			rocket.SetTeam(TEAM_SPECTATOR)
			rocket.KeyValueFromString("classname", "ware_projectile")
			this.handle = rocket
		} else {
			printl("Failed to find rocket after firing launcher!")
			return
		}

		this.RocketThink = function ()
		{
			local rocketPos = this.handle.GetOrigin()
			local rocketVelocity = this.handle.GetAbsVelocity()

			local targetVector = null

			if (!this.target || !this.target.IsValid() || !this.target.IsAlive())
			{
				// No target, reassign if possible
				this.target = db_scope.SelectRocketTarget()
			}

			if (this.target && this.target.IsValid() && this.target.IsAlive())
			{
				targetVector = (this.target.GetOrigin() - rocketPos) + db_scope.rocket_target_offset
			} else {
				// No target, go straight up
				targetVector = Vector(0, 0, 1)
			}

			// TODO: learn how to rotate the vector (max of speed / 200 degrees per tick)
			targetVector.Norm()
			this.handle.SetAbsVelocity(targetVector * this.speed)

			return -1
		}.bindenv(this)

		this.OnReflect = function (reflector)
		{
			this.last_reflect_time = Time()
			this.speed += db_scope.rocket_speed_increment
			this.team = reflector.GetTeam() == TF_TEAM_RED ? TF_TEAM_RED : TF_TEAM_BLUE
			this.target = db_scope.SelectRocketTarget(reflector)
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

function OnStart()
{
	launcher = Ware_SpawnEntity("tf_point_weapon_mimic",
	{
		origin 	= launcher_origin
		WeaponType = 0
		SpeedMin   = rocket_speed_initial
		SpeedMax   = rocket_speed_initial
		Damage     = 20 + (Ware_GetAlivePlayers().len())
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
	target_rocket_count = Min(target_rocket_count + 1, GetMaxRocketCount(Ware_GetAlivePlayers().len()))
	Ware_CreateTimer(IncreaseRocketCount, 10.0)
}

function CheckSpawnRocket()
{
	if (rockets.len() < target_rocket_count)
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

function SelectRocketTarget(reflector = null)
{
	if (rocket_end)
		return null // go straight up
	if (!reflector)
	{
		// calculate per team "alive player count - rockets targeting team" and choose team with highest value (combine both if tied)
		// of the selected group, choose the least targeted player (randomly choose if tied)

		local redRockets = GetRockets(TF_TEAM_RED)
		local blueRockets = GetRockets(TF_TEAM_BLUE)

		local redPlayers = Ware_GetAlivePlayers(TF_TEAM_RED)
		local bluePlayers = Ware_GetAlivePlayers(TF_TEAM_BLUE)

		local redCount = redPlayers.len() - redRockets.len()
		local blueCount = bluePlayers.len() - blueRockets.len()

		local candidates = []

		if (redCount >= blueCount)
			candidates.extend(redPlayers)
		if (blueCount >= redCount)
			candidates.extend(bluePlayers)

		local rocketCounts = {}
		local minRockets = null
		local leastTargetedPlayers = []

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
	else
	{
		printl("Selecting target for reflector " + reflector)
		// calculate per enemy player "(shortest distance of enemy to reflector's line of sight) minus (distance to enemy along reflector's LOS axis)" and take highest value
		local team = reflector.GetTeam() == TF_TEAM_RED ? TF_TEAM_BLUE : TF_TEAM_RED

		local origin = reflector.GetOrigin()
		local lookVector = reflector.EyeAngles().Forward()

		lookVector.z = 0 // don't factor in vertical angles.
		lookVector.Norm()

		local distanceToLOS = @(p) (p.GetOrigin() - origin).Cross(lookVector).Length() / lookVector.Length()
		local distanceAlongLOS = @(p)(p.GetOrigin() - origin).Dot(lookVector) / lookVector.Length()

		local candidates = Ware_GetAlivePlayers(team)
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
	// TODO: award points to surviving players
	foreach (player in Ware_GetAlivePlayers())
	{
		Ware_PassPlayer(player, true)
	}
}