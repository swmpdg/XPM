#include <amxmodx>
#include <engine>
#include <debug_helper>

// for testing with team power only 1 person in server
//#define TEST_TP

#define USING_CS

#define DIST_TASK 1475

// for get_players
new iNum, iPlayers[32];
// Max distance range
new pcvar_maxdistance, g_iMaxDist, pcvar_bots, g_iBots;
new pcvar_checktime, Float:g_fCheckTime;
new pcvar_checkteams, g_iCheckTeams;
new g_iMaxRange[33];
/// true if players are close, false if not
new bool:g_bTeamNear[33][33];
new bool:g_bEnemyNear[33][33];

public plugin_init()
{
	// team power distance range - 60*10+80+15+10*10 = max
	register_plugin("Test Distance API", "1.0.0a", "swampdog@modriot.com");
	pcvar_maxdistance = register_cvar("xpm_distance_range","815");
	pcvar_bots = register_cvar("xpm_distance_bots","1");// allow bots to be counted in array of players - 1 = yes, 0 = no
	pcvar_checktime = register_cvar("xpm_distance_time","5.0");// how often to check if players are near team mates
	pcvar_checkteams = register_cvar("xpm_distance_teams","1");// 1 if checking player teams, 0 if disabled
//	pcvar_checkdm = register_cvar("xpm_distance_dm","0");// deathmatch
	g_iMaxDist = get_pcvar_num(pcvar_maxdistance);
	g_iBots = get_pcvar_num(pcvar_bots);
	g_fCheckTime = get_pcvar_float(pcvar_checktime);
	g_iCheckTeams = get_pcvar_num(pcvar_checkteams);
}

public plugin_cfg()
{
	set_task(g_fCheckTime,"DistanceTask",DIST_TASK,_,_,"b");
}

public plugin_natives()
{
	register_library("xpm_distance");

	register_native("set_player_range","_set_player_range");//player reach
	register_native("is_team_near","_is_team_near");//check if 2 players are near each other
	register_native("is_enemy_near","_is_enemy_near");//check if 2 players are near each other
}

public _set_player_range(plugin,params)
{
	if(params!=3)
	{
		log_bad_params();
		return PLUGIN_CONTINUE;
	}

	new id = get_param(1);
	if(!id)
		return PLUGIN_CONTINUE;

	new value = get_param(2);

	new addToRange = get_param(3);

	if(!addToRange)
	{
		if(value < 0)
			value = 0;

		if(value > g_iMaxDist)
			value = g_iMaxDist;
	}
	else
	{
		new newRange = g_iMaxRange[id] + value;
		if(newRange > g_iMaxDist)
			newRange = g_iMaxDist;
		if(newRange < 0)
			newRange = 0;

		value = newRange;
	}

	g_iMaxRange[id] = value;

	return value;
}

public _is_team_near(plugin,params)
{
	if(params!=2)
	{
		log_bad_params();
		return PLUGIN_CONTINUE;
	}

	new id = get_param(1);
	new id2 = get_param(2);

	if(!id || !id2)
		return PLUGIN_CONTINUE;

	new isNear = g_bTeamNear[id][id2] == true ? 1 : 0;

	return isNear;
}

public _is_enemy_near(plugin,params)
{
	if(params!=2)
	{
		log_bad_params();
		return PLUGIN_CONTINUE;
	}

	new id = get_param(1);
	new id2 = get_param(2);

	if(!id || !id2)
		return PLUGIN_CONTINUE;

	new isNear = g_bEnemyNear[id][id2] == true ? 1 : 0;

	return isNear;
}

public DistanceTask()
{
	// only alive and no hltv
	if(g_iBots)
		get_players(iPlayers, iNum, "ah");
	else
		get_players(iPlayers, iNum, "ach");

	// no players - for testing use < 1, otherwise use <= 1
#if defined TEST_TP
	if(iNum<1)
#else
	if(iNum<=1)
#endif
		return;

	for(new i = 0; i < iNum+1; i++)
	{
		new j = iPlayers[i];

		if(g_iMaxRange[j] < 1)
			continue;

		if(is_user_alive(j))
		{
			for(new k = 0; k < iNum+1; k++)
			{
				new l = iPlayers[k];
#if !defined TEST_TP
				if(j == l)
					continue;// skip same player unless testing
#endif
//				if(!player_is_close(j,l,g_iMaxDist))
				if(!player_is_close(j,l,g_iMaxRange[j]))
				{
					g_bEnemyNear[j][l]=false;
					g_bTeamNear[j][l]=false;
					continue;
				}
				if(!g_iCheckTeams)
				{
					g_bEnemyNear[j][l]=true;
					g_bTeamNear[j][l]=false;
					continue;
				}
				else if(!same_team(j,l))
				{
					g_bEnemyNear[j][l]=true;
					g_bTeamNear[j][l]=false;
					continue;
				}
				else
				{
					g_bEnemyNear[j][l]=false;
					g_bTeamNear[j][l]=true;
					continue;
				}
			}
		}
	}
}

// for teamplay games to check if players are on the same team - returns true if both players are on same team, false if otherwise
stock same_team(i, id)
{
#if defined USING_CS
	new teama[32], teamb[32];
	get_user_team(id,teama,31);
	get_user_team(i,teamb,31);
	if(equali(teama,teamb))
		return 1;
	return 0;
#else
	return (get_user_team(i) == get_user_team(id)) ? 1 : 0;
#endif
}

// add distance
// stock team_is_close(i, id)
stock player_is_close(i, id, distance)
{
	if(is_user_alive(id))
	{
		if(entity_range(i, id)<=distance)
			return 1;
	}
	return 0;
}

public debug_set(bool:debug_enabled)
{
	if(!pcvar_debug)
		register_debug_cvar("xpm_distance_debug", "0");// add cvar to debug_helper.cfg to have it loaded with the cfg
	set_debug_logging(debug_enabled);
	return;
}

#if AMXX_VERSION_NUM >= 183
public client_disconnected(id)
#else
public client_disconnect(id)
#endif
{
	g_iMaxRange[id] = 0;
}

public client_connected(id)
{
	g_iMaxRange[id] = 0;
}

// likely best if team power skill is combined in this, although it may be desirable to have separated


