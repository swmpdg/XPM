#include <amxmodx>
#include <fun>
#include <xpm>
#include <xpm_hp_ap>
#include <xpm_skill_factors>
#include <debug_helper>

#define TOTAL_LEVELS 3

#define MAX_SKILL_LEVEL 450

new bool:g_iHasSkill[33]=false;
new g_iSkillLevel[33];

new gSkillID[TOTAL_LEVELS];

new const gSkillName[TOTAL_LEVELS][] =
{
	"+5 HP & +5 Max HP",
	"+25 HP & +25 Max HP",
	"+100 HP & +100 Max HP"
};

new const gSkillCvar[TOTAL_LEVELS][] =
{
	"health5",
	"health25",
	"health100"
};

new const gSkillCost[TOTAL_LEVELS] =
{
	5,
	25,
	100
};

new gRequiredLevel[TOTAL_LEVELS];// make required level for each skill cost (i.e. level 5-24 only can use +5 strength at a time, 25-99 can use +25, etc)

//new pcvar_skill_max, pcvar_required_level, g_skillmax, g_required_level;

public plugin_init()
{
	register_plugin("Test Skill Plugin", "1.0.0a", "swampdog@modriot.com");

	// is it more efficient just to use forwards, or just use a hook with hamsandwich?
//	RegisterHam(Ham_Spawn, "player", "FwdPlayerSpawnPost", 1);

//	pcvar_skill_max = register_cvar("skill_strength_max", "50");
//	pcvar_required_level = register_cvar("skill_strength_req_level","10");

//	g_skillmax = get_pcvar_num(pcvar_skill_max);
//	g_required_level = get_pcvar_num(pcvar_required_level);

	for (new i = 0; i < TOTAL_LEVELS; i++)
	{
		gRequiredLevel[i] = gSkillCost[i];
		gSkillID[i] = register_skill(gSkillName[i],gSkillCvar[i],gSkillCost[i],_,_,"StrengthCallback",0,0);
//		set_skill_info(gSkillID[i], g_required_level, g_skillmax, "Adds to max health limit and adds current health", "Strength");
		set_skill_info(gSkillID[i], gRequiredLevel[i], MAX_SKILL_LEVEL, "Adds to max health limit and adds current health", "Strength");
	}
}

public skill_factor_init(id, factorLevel, factorIndex)
{
	set_skill_factor(id, factorLevel, factorIndex);
}

public skill_init(id, skillIndex, mode)
{
	for(new i = 0; i < TOTAL_LEVELS; i++)
	{
		if(gSkillID[i] == skillIndex)
		{
			if(mode)
				g_iHasSkill[id] = true;
			else
			{
				g_iHasSkill[id] = false;
//				xpm_set_points(id, g_iSkillLevel[id], true);// refund skill points after drop?
				g_iSkillLevel[id] = 0;
			}
			break;
		}
	}
}

public StrengthCallback(id, item)
{
	for(new i = 0; i < TOTAL_LEVELS; i++)
	{
		if(gSkillID[i] == item)
		{
			g_iHasSkill[id] = true;
			new skillCost = gSkillCost[i];
			g_iSkillLevel[id]+=skillCost;

			for(new j = 0; j < TOTAL_LEVELS; j++)
			{
				set_skill_level(id,gSkillID[j],g_iSkillLevel[id],false);// sync all the separate skills loaded with this value, so they all match
			}

			set_max_health(id, skillCost, true);// add on to max hp=true - set for awareness skill?

			if(is_user_alive(id))
			{
				new totalHealth = get_user_health(id) + skillCost;
				set_user_health(id, totalHealth);
			}
			break;
		}
	}
}

//public FwdPlayerSpawnPost(id)
public xpm_spawn(id)
{
	if(is_user_alive(id))
	{
		if(g_iHasSkill[id])
		{
// need to reset maxhealth here for some mods? ??
			new curMaxHP = get_max_health(id);
			new curHealth = get_user_health(id);
//			new totalHealth = curHealth + g_iSkillLevel[id];
			new factors = get_all_factors(id);
			new totalHealth = curHealth + g_iSkillLevel[id] + factors;

			if(totalHealth > curMaxHP)
				set_max_health(id, totalHealth, false);// add on to max hp=true - set for awareness skill?

			set_user_health(id, totalHealth);

			client_print(id, print_chat, "You spawned with %i total HP", totalHealth);
		}
	}
	debug_log(g_debug, "xpm_spawn(id) xpm_skill_strength.amxx called");
}

public xpm_die(id)
{
	debug_log(g_debug, "xpm_die(id) xpm_skill_strength.amxx called");
}

public debug_set(bool:debug_enabled)
{
	if(!pcvar_debug)
		register_debug_cvar("xpm_strength_debug", "0");// add cvar to debug_helper.cfg to have it loaded with the cfg
	set_debug_logging(debug_enabled);
	return;
}