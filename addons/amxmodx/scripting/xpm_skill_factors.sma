#include <amxmodx>
#include <xpm>
#include <xpm_skill_factors>
#include <debug_helper>

new gSkillID[TOTAL_FACTORS];

new const gSkillCost[TOTAL_FACTORS] =
{
	5,
	1,
	100
};

new const gRequiredLevel[TOTAL_FACTORS] =
{
	5,
	1,
	100
};

new const gFactorMaxLvl[TOTAL_FACTORS] =
{
	80,
	15,
	10
};

enum
{
	FWD_SKILL_FACTOR,
};

// forwards in an array using the Enum above
stock const fwdID[FWD_SKILL_FACTOR+1][] =
{
	"skill_factor_init"
};

new fwdFactorInit, fwdReturn;

public plugin_init()
{
	register_plugin("Test Skill Factors", "1.0.0a", "swampdog@modriot.com");

	for (new i = 0; i < TOTAL_FACTORS; i++)
	{
		gSkillID[i] = register_skill(gFactorName[i],gFactorCvar[i],gSkillCost[i],_,_,"FactorCallback",0,0);
		// data type conflict going on? items not getting added to the list
		set_skill_info(gSkillID[i], gRequiredLevel[i], gFactorMaxLvl[i], "Adds to max health limit and adds current health", gFactorName[i]);
	}
	fwdFactorInit = CreateMultiForward(fwdID[FWD_SKILL_FACTOR], ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);// param 1 = player id, param 2 = skill level, param 3 = mode (set SKILL_AWARE, SKILL_MEDAL, or SKILL_PRESTIGE for mode?)

}

public skill_init(id, skillIndex, mode)
{
	for(new i = 0; i < TOTAL_FACTORS; i++)
	{
		if(gSkillID[i] == skillIndex)
		{
			if(mode)
				g_bHasFactor[id][i] = true;
			else
			{
				g_bHasFactor[id][i] = false;
//				xpm_set_points(id, g_iSkillLevel[id], true);// refund skill points after drop?
				g_iFactorLevel[id][i] = 0;
			}
			break;
		}
	}
}

public FactorCallback(id, item)
{
	for(new i = 0; i < TOTAL_FACTORS; i++)
	{
		if(gSkillID[i] == item)
		{
			g_bHasFactor[id][i] = true;

			new skillCost = gSkillCost[i];
			g_iFactorLevel[id][i]+=skillCost;

			set_skill_level(id,gSkillID[i],g_iFactorLevel[id][i],false);

			// call forward for skill_factor_init
			// forward skill_factor_init(id, factorLevel, factorIndex); // factorIndex is SKILL_AWARE, SKILL_MEDAL, or SKILL_PRESTIGE for now (xpm_skill_factor.inc)
			ExecuteForward(fwdFactorInit, fwdReturn, id, g_iFactorLevel[id][i], i);

			break;
		}
	}
}

public debug_set(bool:debug_enabled)
{
	if(!pcvar_debug)
		register_debug_cvar("xpm_factors_debug", "0");// add cvar to debug_helper.cfg to have it loaded with the cfg
	set_debug_logging(debug_enabled);
	return;
}