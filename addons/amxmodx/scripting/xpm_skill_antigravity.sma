#include <amxmodx>
#include <fun>
#include <xpm>
#include <xpm_skill_factors>
#include <debug_helper>

#define TOTAL_LEVELS 1

#define MAX_SKILL_LEVEL 30

new bool:g_bHasSkill[33];
new g_iSkillLevel[33];

new gSkillID[TOTAL_LEVELS];

new const gSkillName[TOTAL_LEVELS][] =
{
	"+5 Anti-Gravity",
};

new const gSkillCvar[TOTAL_LEVELS][] =
{
	"gravity5",
};

new const gSkillCost[TOTAL_LEVELS] =
{
	5,
};

new gRequiredLevel[TOTAL_LEVELS];// make required level for each skill cost (i.e. level 5-24 only can use +5 strength at a time, 25-99 can use +25, etc)
new Float:g_fMinGravity[33];


public plugin_init()
{
	register_plugin("Test Anti-Gravity Device", "1.0.0a", "swampdog@modriot.com");

	// is it more efficient just to use forwards, or just use a hook with hamsandwich?

	for (new i = 0; i < TOTAL_LEVELS; i++)
	{
		gRequiredLevel[i] = gSkillCost[i];
		gSkillID[i] = register_skill(gSkillName[i],gSkillCvar[i],gSkillCost[i],_,_,"AntiGravityCallback",0,0);
		set_skill_info(gSkillID[i], gRequiredLevel[i], MAX_SKILL_LEVEL, "Reduces gravity when jumping", "Anti-Gravity Device");
	}
}

public skill_factor_init(id, factorLevel, factorIndex)
{
	set_skill_factor(id, factorLevel, factorIndex);
	set_min_gravity(id);
}

stock set_min_gravity(id)
{
	if(g_bHasSkill[id])
	{
		if(g_iFactorLevel[id][SKILL_MEDAL] > 0)
			g_fMinGravity[id] = 1.0-(0.015*g_iSkillLevel[id])-(0.001*g_iFactorLevel[id][SKILL_MEDAL]);
		else
			g_fMinGravity[id] = 1.0-(0.015*g_iSkillLevel[id])
	}
	else
	{
		g_fMinGravity[id] = 1.0;
	}
	gravity_enable(id);
}

stock gravity_enable(id)
{
	if(is_user_alive(id))
	{
		new Float:oldGravity = get_user_gravity(id);
		if(oldGravity != g_fMinGravity[id])
			set_user_gravity(id, g_fMinGravity[id]);
	}
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
//				xpm_set_points(id, g_iSkillLevel[id], true);// refund skill points after drop?
				g_iSkillLevel[id] = 0;
				g_fMinGravity[id] = 1.0;
				set_min_gravity(id);
			}
			break;
		}
	}
}

public AntiGravityCallback(id, item)
{
	for(new i = 0; i < TOTAL_LEVELS; i++)
	{
		if(gSkillID[i] == item)
		{
			g_bHasSkill[id] = true;
			new skillCost = gSkillCost[i];
			g_iSkillLevel[id]+=skillCost;

			for(new j = 0; j < TOTAL_LEVELS; j++)
			{
				set_skill_level(id,gSkillID[j],g_iSkillLevel[id],false);// sync all the separate skills loaded with this value, so they all match
			}

			set_min_gravity(id);

			break;
		}
	}
}

//public FwdPlayerSpawnPost(id)
public xpm_spawn(id)
{
	if(is_user_alive(id))
	{
		set_min_gravity(id);
	}
	debug_log(g_debug, "xpm_spawn(id) xpm_skill_antigravity.amxx called");
}

public xpm_die(id)
{
	debug_log(g_debug, "xpm_die(id) xpm_skill_antigravity.amxx called");
}

public debug_set(bool:debug_enabled)
{
	if(!pcvar_debug)
		register_debug_cvar("xpm_antigravity_debug", "0");// add cvar to debug_helper.cfg to have it loaded with the cfg
	set_debug_logging(debug_enabled);
	return;
}