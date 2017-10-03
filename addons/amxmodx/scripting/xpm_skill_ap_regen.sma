#include <amxmodx>
#include <fun>
#include <xpm>
#include <xpm_hp_ap>
#include <xpm_skill_factors>
#include <debug_helper>

#define USING_CS

#if defined USING_CS
#include <cstrike>
#endif

#define TOTAL_LEVELS 1

#define MAX_SKILL_LEVEL 350

#define AP_TASKID 1472

/*
/// limit for health, used as a cap for player regeneration rate with the health regeneration skill. Once this limit is reached with a counter, it resets.
	hrate=register_cvar("scxpm_hprlimit","380.0");
/// Same as scxpm_hprlimit, except for nano armor. may want to raise limit for armor and make it much harder for regular skill by itself
	nrate=register_cvar("scxpm_arlimit","380.0");
/// Same as scxpm_hprlimit, except ammo reincarnation
	arate=register_cvar("scxpm_amrate","1000.0");
*/

new bool:g_bHasSkill[33];
new g_iSkillLevel[33];

new gSkillID[TOTAL_LEVELS];

new const gSkillName[TOTAL_LEVELS][] =
{
	"+5 Armor Regeneration"
};

new const gSkillCvar[TOTAL_LEVELS][] =
{
	"apregen"
};

new const gSkillCost[TOTAL_LEVELS] =
{
	5,
};

new gRequiredLevel[TOTAL_LEVELS];// make required level for each skill cost (i.e. level 5-24 only can use +5 strength at a time, 25-99 can use +25, etc)

// for get_players
new iNum, iPlayers[32];
// regen rates
new regenRate[33], regenCount[33];
new pcvar_regen_limit, g_iRegenLimit;

public max_armor(id,armorNum)
{
	g_iMaxArmor[id] = armorNum
}

public plugin_init()
{
	register_plugin("Test Armor Regeneration", "1.0.0a", "swampdog@modriot.com");

	// is it more efficient just to use forwards, or just use a hook with hamsandwich?

	for (new i = 0; i < TOTAL_LEVELS; i++)
	{
		gRequiredLevel[i] = gSkillCost[i];
		gSkillID[i] = register_skill(gSkillName[i],gSkillCvar[i],gSkillCost[i],_,_,"ArmorRegenCallback",0,0);
		set_skill_info(gSkillID[i], gRequiredLevel[i], MAX_SKILL_LEVEL, "Regeneration of armor points", "Armor Regeneration");
	}
	pcvar_regen_limit = register_cvar("xpm_apregen_limit","380");
}

public plugin_cfg()
{
	set_task(1.0,"armorRegenTask",AP_TASKID,_,_,"b");
	g_iRegenLimit = get_pcvar_num(pcvar_regen_limit);
}

public armorRegenTask()
{
	// only alive and no hltv
	get_players(iPlayers, iNum, "ah");

	for(new i = 0; i < iNum+1; i++)
	{
		new j = iPlayers[i];

		if(!g_bHasSkill[j])
			continue;

		if(is_user_alive(j))
		{
			if(regenCount[j] < g_iRegenLimit)
			{
				regenCount[j] += regenRate[j];
				continue;
			}
			else
			{
				new curAp = get_user_armor(j);

				if(curAp < g_iMaxArmor[j])
				{
#if defined USING_CS
					cs_set_user_armor(j,curAp+1,CS_ARMOR_VESTHELM)
#else
					set_user_armor(j,curAp+1);
#endif
					regenCount[j] = regenRate[j];
				}
				continue;
			}
		}
	}
}

public skill_factor_init(id, factorLevel, factorIndex)
{
	set_skill_factor(id, factorLevel, factorIndex);

	if(g_bHasSkill[id])
		set_ap_regen_rate(id);
}

/// team power formula for distance range: (team_power_level * 10) + awareness + medals + (prestige * prestige_multiplier)
set_ap_regen_rate(id)
{
	regenRate[id] = g_iSkillLevel[id] + g_iFactorLevel[id][SKILL_AWARE] + g_iFactorLevel[id][SKILL_MEDAL] + (g_iFactorLevel[id][SKILL_PRESTIGE] * 10);
	if(regenCount[id] < regenRate[id])
		regenCount[id] = regenRate[id];
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
				regenRate[id] = 0;
				regenCount[id] = 0;
			}
			break;
		}
	}
}

public HealthRegenCallback(id, item)
{
	for(new i = 0; i < TOTAL_LEVELS; i++)
	{
		if(gSkillID[i] == item)
		{
			g_bHasSkill[id] = true;
			new skillCost = gSkillCost[i];
			g_iSkillLevel[id]+=skillCost;

			set_ap_regen_rate(id);

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
		register_debug_cvar("xpm_apregen_debug", "0");// add cvar to debug_helper.cfg to have it loaded with the cfg
	set_debug_logging(debug_enabled);
	return;
}