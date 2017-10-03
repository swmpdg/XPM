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

#define MAX_SKILL_LEVEL 450

new bool:g_bHasSkill[33];
new g_iSkillLevel[33];

new gSkillID[TOTAL_LEVELS];

new const gSkillName[TOTAL_LEVELS][] =
{
	"+5 Superior Armor",
};

new const gSkillCvar[TOTAL_LEVELS][] =
{
	"armor5",
};

new const gSkillCost[TOTAL_LEVELS] =
{
	5,
};

new gRequiredLevel[TOTAL_LEVELS];// make required level for each skill cost (i.e. level 5-24 only can use +5 strength at a time, 25-99 can use +25, etc)

public plugin_init()
{
	register_plugin("Test Superior Armor", "1.0.0a", "swampdog@modriot.com");

	// is it more efficient just to use forwards, or just use a hook with hamsandwich?

	for (new i = 0; i < TOTAL_LEVELS; i++)
	{
		gRequiredLevel[i] = gSkillCost[i];
		gSkillID[i] = register_skill(gSkillName[i],gSkillCvar[i],gSkillCost[i],_,_,"SuperiorArmorCallback",0,0);
		set_skill_info(gSkillID[i], gRequiredLevel[i], MAX_SKILL_LEVEL, "Adds to max armor limit and adds to current armor", "Superior Armor");
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
				g_bHasSkill[id] = true;
			else
			{
				g_bHasSkill[id] = false;
//				xpm_set_points(id, g_iSkillLevel[id], true);// refund skill points after drop?
				g_iSkillLevel[id] = 0;
			}
			break;
		}
	}
}

public SuperiorArmorCallback(id, item)
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

			set_max_armor(id, skillCost, true);// add on to max ap=true - set for awareness skill?

			if(is_user_alive(id))
			{
				new totalArmor = get_user_armor(id) + skillCost;
#if defined USING_CS
				cs_set_user_armor(id,totalArmor,CS_ARMOR_VESTHELM);
#else
				set_user_armor(id, totalArmor);
#endif
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
		if(g_bHasSkill[id])
		{
// need to reset maxarmor here for some mods? ??
			new curMaxAP = get_max_armor(id);
			new curArmor = get_user_armor(id);

			new factors = get_all_factors(id);
			new totalArmor = curArmor + g_iSkillLevel[id] + factors;

			if(totalArmor > curMaxAP)
				set_max_armor(id, totalArmor, false);// add on to max hp=true - set for awareness skill?

#if defined USING_CS
			cs_set_user_armor(id,totalArmor,CS_ARMOR_VESTHELM);
#else
			set_user_armor(id, totalArmor);
#endif
			client_print(id, print_chat, "You spawned with %i total AP", totalArmor);
		}
	}
	debug_log(g_debug, "xpm_spawn(id) xpm_skill_superiorarmor.amxx called");
}

public xpm_die(id)
{
	debug_log(g_debug, "xpm_die(id) xpm_skill_superiorarmor.amxx called");
}

public debug_set(bool:debug_enabled)
{
	if(!pcvar_debug)
		register_debug_cvar("xpm_superiorarmor_debug", "0");// add cvar to debug_helper.cfg to have it loaded with the cfg
	set_debug_logging(debug_enabled);
	return;
}