#include <amxmodx>
#include <fun>
#include <xpm>
#include <xpm_hp_ap>
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


public plugin_init()
{
	register_plugin("Test Skill Plugin", "1.0.0a", "swampdog@modriot.com");

//	RegisterHam(Ham_Spawn, "player", "FwdPlayerSpawnPost", 1);

	for (new i = 0; i < TOTAL_LEVELS; i++)
	{
		gSkillID[i] = register_skill(gSkillName[i],gSkillCvar[i],gSkillCost[i],_,_,"StrengthCallback",0,0);
	}
}

public skill_init(id, item)
{
	for(new i = 0; i < TOTAL_LEVELS; i++)
	{
		if(gSkillID[i] == item)
		{
			g_iHasSkill[id] = true;
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
/*
			if(g_iSkillLevel[id] > MAX_SKILL_LEVEL)
			{
				new leftover_points;
				leftover_points = g_iSkillLevel[id] - MAX_SKILL_LEVEL;
				new newCost;
				newCost = skillCost - leftover_points;
				skillCost = newCost;
				xpm_set_points(id, leftover_points, true);// add back to the xp points system
				g_iSkillLevel[id] = MAX_SKILL_LEVEL;
			}
*/
			new totalHealth = get_user_health(id) + skillCost;
/*
			new curmaxhealth = get_sv_max_health();// should be server max health, not player max health check

			// really I want to increase max health, but maybe that could be for another skill..
			// can turn this into a stock function to handle leftover skillpoints
			// maybe like: stock xpm_check_skillpoints(new_value, server_max_value, skillCost) return leftover_points?
*/
			set_max_health(id, skillCost, true);// add on to max hp=true - set for awareness skill?
			set_user_health(id, totalHealth);
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
// need to reset maxhealth here for some mods?
			new totalHealth = get_user_health(id) + g_iSkillLevel[id];
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