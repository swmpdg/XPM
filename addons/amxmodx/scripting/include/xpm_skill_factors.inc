#if defined _xpm_skill_factors_included
	#endinput
#endif

/**
 * XPM Natives - designed by Swamp Dog @ ModRiot.com, 2016-2017
 * For use across plugins as a library
 */

#define _xpm_skill_factors_included

/**
Half-Life Experience Mod (XPM) API native and stock functions
By Swamp Dog @ ModRiot.com
August 26, 2016
*/

// factors such as items which could increase other abilities (awareness, medals, characters, "hats", models, etc...)
#define TOTAL_FACTORS 3

// index vaues for skills factors, with indexing beginning at 1 (return 0,-1, or greater than SKILL_PRESTIGE would be invalid)
enum
{
	SKILL_AWARE,
	SKILL_MEDAL,
	SKILL_PRESTIGE
};

stock bool:g_bHasFactor[33][TOTAL_FACTORS];
stock g_iFactorLevel[33][TOTAL_FACTORS];
// g_iFactors for being lazy and storing them all in 1 variable added together
stock g_iFactors[33];

stock const gFactorName[TOTAL_FACTORS][] =
{
	"Awareness",
	"Medal",
	"Prestige"
};

stock const gFactorCvar[TOTAL_FACTORS][] =
{
	"aware",
	"medal",
	"prestige"
};

// forwards

// param 1 = player id, param 2 = skill level, param 3 = mode (set SKILL_AWARE, SKILL_MEDAL, or SKILL_PRESTIGE for mode?)
// factorIndex is SKILL_AWARE, SKILL_MEDAL, or SKILL_PRESTIGE for now (xpm_skill_factor.inc)
forward skill_factor_init(id, factorLevel, factorIndex);

// check index of skill in stock function through forward
stock set_skill_factor(id, factorLevel, factorIndex)
{
	switch(factorIndex)
	{
		case SKILL_AWARE:
		{
			g_iFactorLevel[id][SKILL_AWARE] = factorLevel;
		}
		case SKILL_MEDAL:
		{
			g_iFactorLevel[id][SKILL_MEDAL] = factorLevel;
		}
		case SKILL_PRESTIGE:
		{
			g_iFactorLevel[id][SKILL_PRESTIGE] = factorLevel;
		}
	}
}

stock get_all_factors(id)
{
	new totalLevels;
	for(new i = 0; i < TOTAL_FACTORS; i++)
	{
		totalLevels+=g_iFactorLevel[id][i];
	}
	g_iFactors[id] = totalLevels;
	return totalLevels;
}

stock get_factor_level(id, factorIndex)
{
	return g_iFactorLevel[id][factorIndex];
}

// to check if needed whether or not a value will go over a limit, return difference?
stock check_value_limit(id, value, limit)
{
	return value < limit ? 0 : (value - limit);
}