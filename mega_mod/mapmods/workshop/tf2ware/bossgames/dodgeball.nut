minigame <- Ware_MinigameData
({
	name           = "Dodgeball"
	author         = ["megascatterbomb"]
	description    = "Reflect the homing rockets!"
	duration       = 145.0
	end_delay      = 2.0
	location       = "boxarena"
	music          = "dodgeball" // TODO
	min_players    = 2
	start_pass     = true
	start_freeze   = 0.5
	custom_overlay = "airblast_rockets"
})

rockets <- []

rocket_speed_initial <- 250.0
rocket_speed_increment <- 25.0
rocket_stall_threshold <- 10.0

GetMinRocketCount <- @(num_players) ceil(num_players / 25.0)
GetMaxRocketCount <- @(num_players) floor(sqrt(num_players)) + 2

target_rocket_count <- 1
rocket_end <- false

launcher_origin <- Vector(0, 0, 0)
launcher_effect <- null
launcher_effect_offset <- launcher_origin + Vector(0, 0, 0)

class Rocket {
	handle = null
	team = null
	target = null
	speed = rocket_speed_initial
	last_reflect_time = 0.0

	constructor(team, target = null)
	{
		this.target = target ? target : SelectRocketTarget(team)
		this.team = this.target.GetTeam() == TF_TEAM_RED ? TF_TEAM_BLUE : TF_TEAM_RED
		this.last_reflect_time = Time()

		this.handle = SpawnEntityFromTableSafe("tf_projectile_rocket",
		{
			basevelocity = Vector(0, 0, rocket_speed_initial)
			teamnumber = this.team
			origin = launcher_origin
		})
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
	Ware_CreateTimer(10.0 + (10.0 * target_rocket_count), IncreaseRocketCount)
	Ware_CreateTimer(180.0, @() rocket_end <- true)
	Ware_CreateTimer(3.0, CheckSpawnRocket)
}

function IncreaseRocketCount()
{
	target_rocket_count = Min(target_rocket_count + 1, GetMaxRocketCount(Ware_GetAlivePlayers().len()))
	Ware_CreateTimer(10.0, IncreaseRocketCount)
}

function CheckSpawnRocket()
{
	Ware_CreateTimer(1.0, CheckSpawnRocket)
}

function SpawnRocket(team = null)
{
	local rocket = Rocket(team)
	rockets.append(rocket)
}

function GetRockets(team = null)
{

}

function SelectRocketTarget(reflector = null)
{
	if (rocket_end)
		return null // go straight up
	if (!reflector)
	{
		// TODO: select random alive player:
		// - if team is not specified: calculate per team "alive player count minus rockets targeting team" and choose team with highest value
		// - randomly choose player on team, always prefer players without target if possible
	} else
	{
		local team = reflector.GetTeam() == TF_TEAM_RED ? TF_TEAM_BLUE : TF_TEAM_RED
		// calculate per enemy player "(shortest distance of enemy to reflector's line of sight ) minus (distance to enemy along reflector's LOS axis)" and take highest value
	}
}

function OnCheckEnd()
{
	// TODO: either when everyone dies, or one team dies and that team has no active rockets
	return Ware_GetAlivePlayers().len() == 0
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