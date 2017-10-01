#include <amxmodx>
#include <fun>
#include <engine>
#include <xpm>
//#include <xpm_hp_ap>
#include <xpm_skill_factors>
#include <xpm_distance>
#include <debug_helper>

#define USING_CS

#define TOTAL_LEVELS 1

#define MAX_SKILL_LEVEL 60

#define TP_TASKID 12374

// testing team power with only 1 player and with self
//#define TEST_TP

new bool:g_bHasSkill[33];
new g_iSkillLevel[33];

new gSkillID[TOTAL_LEVELS];

new const gSkillName[TOTAL_LEVELS][] =
{
	"+5 Team Power"
};

new const gSkillCvar[TOTAL_LEVELS][] =
{
	"teampwr"
};

new const gSkillCost[TOTAL_LEVELS] =
{
	5
};

new gRequiredLevel[TOTAL_LEVELS];// make required level for each skill cost (i.e. level 5-24 only can use +5 strength at a time, 25-99 can use +25, etc)

// for get_players
new iNum, iPlayers[32];
// Max distance range
new maxDist[33];

public plugin_init()
{
	register_plugin("Test Team Power", "1.0.0a", "swampdog@modriot.com");

	// is it more efficient just to use forwards, or just use a hook with hamsandwich?

	for (new i = 0; i < TOTAL_LEVELS; i++)
	{
		gRequiredLevel[i] = gSkillCost[i];
		gSkillID[i] = register_skill(gSkillName[i],gSkillCvar[i],gSkillCost[i],_,_,"TeamPowerCallback",0,0);
		set_skill_info(gSkillID[i], gRequiredLevel[i], MAX_SKILL_LEVEL, "Aids team by healing if nearby", "Team Power");
	}
}

public plugin_cfg()
{
	set_task(5.0,"teamPowerTask",TP_TASKID,_,_,"b");
}

public teamPowerTask()
{
	// only alive and no hltv
	get_players(iPlayers, iNum, "ah");

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

		if(g_bHasSkill[j] && is_user_alive(j))
		{
			for(new k = 0; k < iNum+1; k++)
			{
				new l = iPlayers[k];

#if !defined TEST_TP
				if(j == l)
					continue;// skip same player unless testing
#endif

				if(!is_team_near(j,l))
					continue;

				new teamHealth = get_user_health(l)+1;
				set_user_health(l,teamHealth);
			}
		}
	}
}

// for teamplay games to check if players are on the same team - returns true if both players are on same team, false if otherwise
stock same_team(i, id)
{
	new teama[32], teamb[32];
	get_user_team(id,teama,31);
	get_user_team(i,teamb,31);
	if(equali(teama,teamb)) return 1;
	return 0;
}


stock team_is_close(i, id)
{
#if defined USE_FAKEMETA
	new Float:origin_i[3];
	pev(i,pev_origin,origin_i);

	new Float:origin_id[3];
	pev(id,pev_origin,origin_id);

	if(get_distance_f(origin_i,origin_id)<=maxDist[id])
		return 1;
#else
	if(entity_range(i, id)<=maxDist[id])
		return 1;
#endif
	return 0;
}


public skill_factor_init(id, factorLevel, factorIndex)
{
	set_skill_factor(id, factorLevel, factorIndex);

	if(g_bHasSkill[id])
		set_max_distance(id);
}

/// team power formula for distance range: (team_power_level * 10) + awareness + medals + (prestige * prestige_multiplier)
set_max_distance(id)
{
	maxDist[id] = (g_iSkillLevel[id]*10) + g_iFactorLevel[id][SKILL_AWARE] + g_iFactorLevel[id][SKILL_MEDAL] + (g_iFactorLevel[id][SKILL_PRESTIGE]*10);
	set_player_range(id, maxDist[id], false);
}

public skill_init(id, skillIndex, mode)
{
	for(new i = 0; i < TOTAL_LEVELS; i++)
	{
		if(gSkillID[i] == skillIndex)
		{
			if(mode)
				g_bHasSkill[id] = true;
			else
			{
				g_bHasSkill[id] = false;
				g_iSkillLevel[id] = 0;
				maxDist[id] = 0;
			}
			break;
		}
	}
}

public TeamPowerCallback(id, item)
{
	for(new i = 0; i < TOTAL_LEVELS; i++)
	{
		if(gSkillID[i] == item)
		{
			g_bHasSkill[id] = true;
			new skillCost = gSkillCost[i];
			g_iSkillLevel[id]+=skillCost;

			set_max_distance(id);

			for(new j = 0; j < TOTAL_LEVELS; j++)
			{
				set_skill_level(id,gSkillID[j],g_iSkillLevel[id],false);// sync all the separate skills loaded with this value, so they all match
			}
			break;
		}
	}
}

public debug_set(bool:debug_enabled)
{
	if(!pcvar_debug)
		register_debug_cvar("xpm_teampwr_debug", "0");// add cvar to debug_helper.cfg to have it loaded with the cfg
	set_debug_logging(debug_enabled);
	return;
}