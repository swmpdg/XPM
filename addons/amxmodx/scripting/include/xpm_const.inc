#if defined _xpm_const_included
	#endinput
#endif

/**
 * XPM Natives - designed by Swamp Dog @ ModRiot.com, 2016-2017
 * For use across plugins as a library
 */

#define _xpm_const_included

/**
Half-Life Experience Mod (XPM) API native and stock functions
By Swamp Dog @ ModRiot.com
August 26, 2016
*/

// max skills possible to load hardcoded to 64 for now.
#define MAX_SKILLS 64

// skill_init(id, skillIndex, mode) modes
//Skill is dropped
#define SKILL_DROP 0
//Skill is added
#define SKILL_ADD 1

#if !defined _shop_included

enum {
	SHOP_ITEM_ENABLED, // allows item to be used
	SHOP_ITEM_DISABLED, // shows item but cannot be used
	SHOP_ITEM_HIDDEN // hides item completely
};

#define SHOP_COST_NONE 0

enum {
	SHOP_TEAM_ALL = 0,
	SHOP_TEAM_T = 1,
	SHOP_TEAM_CT = 2,
	SHOP_TEAM_SPEC = 4
};

#define SHOP_DELAY_NONE 0
#define SHOP_DELAY_ROUND -1

enum {
	SHOP_RESET_TIMEONLY = 0,
	SHOP_RESET_ROUND = 1 << 0, // 1
	SHOP_RESET_DEATH = 1 << 1, // 2
	SHOP_RESET_SPAWN = 1 << 2 // 4
};

#define SHOP_RESET_ALL (SHOP_RESET_ROUND | SHOP_RESET_DEATH | SHOP_RESET_SPAWN)

#define SHOP_TIME_INFINITE 0

#endif
