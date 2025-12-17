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
	start_pass     = true
	start_freeze   = 2.0
	custom_overlay = "airblast_rockets"
})

rockets <- []

rocket_speed_initial <- 250.0
rocket_speed_increment <- 25.0
rocket_stall_threshold <- 10.0

GetMinRocketCount <- @(num_players) ceil(num_players / 25.0)
GetMaxRocketCount <- @(num_players) floor(sqrt(num_players)) + target_rocket_count_extra

target_rocket_count <- 1
target_rocket_count_extra <- 0 // make things spicier over time for smaller player counts.
rocket_end <- false

launcher_origin <- Vector(0, 0, 0)
launcher_effect <- null
launcher_effect_offset <- launcher_origin + Vector(0, 0, 0)

rocket_offset <- Vector(0, 0, 48.0)

class Rocket {
	handle = null
	team = null // team of the rocket (targets other team)
	target = null
	speed = rocket_speed_initial
	last_reflect_time = 0.0

	constructor(targetTeam, target = null)
	{
		this.target = target ? target : SelectRocketTarget(targetTeam)
		this.team = this.target.GetTeam() == TF_TEAM_RED ? TF_TEAM_BLUE : TF_TEAM_RED
		this.last_reflect_time = Time()

		this.handle = SpawnEntityFromTableSafe("tf_projectile_rocket",
		{
			basevelocity = Vector(0, 0, rocket_speed_initial)
			teamnumber = this.team
			origin = launcher_origin
		})

		this.handle.ValidateScriptScope()
		this.handle.think <- this.RocketThink

		AddThinkToEnt(this.handle, "RocketThink")
	}

	function RocketThink()
	{
		local rocketPos = this.handle.GetOrigin()
		local rocketVelocity = this.handle.GetVelocity()

		local targetVector = null

		if (!this.target || !this.target.IsValid() || !this.target.IsAlive())
		{
			// No target, reassign if possible
			this.target = SelectRocketTarget(this.handle.GetTeam() == TF_TEAM_RED ? TF_TEAM_BLUE : TF_TEAM_RED)
		}

		if (this.target && this.target.IsValid() && this.target.IsAlive())
		{
			targetVector = this.target.GetOrigin().Subtract(rocketPos + rocket_offset)
			targetVector.z += 48.0 // aim a bit higher
		} else {
			// No target, go straight up
			targetVector = Vector(0, 0, 1)
		}

		// TODO: learn how to rotate the vector (max of speed / 200 degrees per tick)

		return -1
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
	Ware_SetGlobalLoadout(TF_CLASS_PYRO, "Flame Thrower")

	target_rocket_count <- GetMinRocketCount(Ware_GetAlivePlayers().len())
	Ware_CreateTimer(2.0, CheckSpawnRocket)
	Ware_CreateTimer(10.0, IncreaseRocketCount)
	Ware_CreateTimer(45.0, @() target_rocket_count_extra++)
	Ware_CreateTimer(95.0, @() target_rocket_count_extra++)
	Ware_CreateTimer(180.0, @() rocket_end <- true)
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
	Ware_CreateTimer(10.0, IncreaseRocketCount)
}

function CheckSpawnRocket()
{
	if (rockets.len() < target_rocket_count)
		SpawnRocket()
	Ware_CreateTimer(1.0, CheckSpawnRocket)
}

function SpawnRocket(team = null)
{
	local rocket = Rocket(team)
	rockets.append(rocket)
}

function GetRockets(team = null)
{
	return rockets.filter(@(r) r.handle != null && r.handle.IsValid() && (r.team == team || team == null || team == TF_TEAM_ANY))
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

		local redCount = redPlayers - redRockets.len()
		local blueCount = bluePlayers - blueRockets.len()

		local candidates = []

		if (redCount > blueCount)
			candidates = redPlayers
		else if (blueCount > redCount)
			candidates = bluePlayers
		else
			candidates = redPlayers + bluePlayers

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
				return candidates[Maths.RandomInt(0, candidates.len() - 1)]

		return leastTargetedPlayers[Maths.RandomInt(0, leastTargetedPlayers.len() - 1)]
	}
	else
	{
		// calculate per enemy player "(shortest distance of enemy to reflector's line of sight) minus (distance to enemy along reflector's LOS axis)" and take highest value
		local team = reflector.GetTeam() == TF_TEAM_RED ? TF_TEAM_BLUE : TF_TEAM_RED

		local origin = reflector.GetOrigin()
		local lookVector = reflector.EyeAngles().Forward()

		lookVector.z = 0 // don't factor in vertical angles.
		lookVector.Norm()

		local distanceToLOS = @(p) p.GetOrigin().Subtract(origin).Cross(lookVector).Length() / lookVector.Length()
		local distanceAlongLOS = @(p) p.GetOrigin().Subtract(origin).Dot(lookVector) / lookVector.Length()

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
	// is this needed with start_pass = true?
}

function OnCleanup()
{
	// delete rockets, launchers, and effects
}