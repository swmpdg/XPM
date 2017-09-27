#if defined _xpm_core_included
	#endinput
#endif

/**
 * XPM Natives - designed by Swamp Dog @ ModRiot.com, 2016-2017
 * For use across plugins as a library
 */

#define _xpm_core_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib xpm_core
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib xpm_core
	#endif
#else
	#pragma library xpm_core
#endif

/**
Half-Life Experience Mod (XPM) API native and stock functions
By Swamp Dog @ ModRiot.com
August 26, 2016
Last updated September 20, 2017
*/

#include <xpm_const>

/**
 * xpm_is_on() Checks if SCXPM is loaded or not. Sub-plugins will want to have loading checks and other checks to see if xpmod is enabled.
 *
 * @return		Returns value of pcvar - 1 if enabld, 0 if disabled.
 * 
 * @note		This native function may eventually be replaced with a stock function.
 */
native xpm_is_on();

/**
 * Turns XP Mod on or off using switch_xpmod() after calling to check if XP Mod is on with xpmod_is_on(). 
 * 
 * @return		True if XP Mod on/off switch was performed, false if otherwise.
 * 
 * @note		This will turn XP Mod on or off. Use switch_xpmod() to turn it on if it is off, or off it is on.
 *
 */
native switch_xpmod();

/**
 * Checks and returns the value of the loop that is currently loaded for XP Mod.
 *
 * @return			"loopcheck" loop id loaded on success/true, PLUGIN_CONTINUE on failure/false.
 */
native get_loop_id();

/**
 * Retrieves configured max level (default 1800).
 *
 * @return			The max level value success, false on failure.
 */
native xpm_max_lvl();

/**
 * Retrieves configured max health (default 0, disabled - maxhealth is 645).
 *
 * @return			The max health value on success, false on failure.
 */
native xpm_max_hp();

/**
 * Retrieves server configured max armor (default 0, disabled - maxarmor is 645).
 *
 * @return			The max armor value on success, false on failure.
 */
native xpm_max_ap();

/**
 * Gets the client's player level.
 *
 * @param id		The index of the client.
 * @return			The current level of the player.
 */
native get_level(id);

/**
 * Sets the client's player level.
 * @param id		The index of the client.
 * @param lvlnum	The level number to set on the client. 
 */
native set_level(id);

/**
 * Retrieves the client's current XP.
 *
 * @param id		The index of the client.
 * @return			The current XP of the client.
 */
native get_xp(id);

/**
 * Add to client's current XP.
 *
 * @param id		The index of the client.
 * @param addxp		The xp to add to the client.
 * @return			PLUGIN_HANDLED on success, PLUGIN_CONTINUE on failure.
 */
native add_xp(id, addxp);

/**
 * Sets the client's current XP to this value.
 *
 * @param id		The index of the client.
 * @param setxp		The xp to add to the client.
 * @return			PLUGIN_HANDLED on success, PLUGIN_CONTINUE on failure.
 */
native set_xp(id, setxp);

/**
 * Checks if the client's stats are loaded yet.
 *
 * @param id		The index of the client.
 * @return			PLUGIN_HANDLED on success/true, PLUGIN_CONTINUE on failure/false
 */
native is_loaded(id);


//xpm_set_points(player_id,amount,bool:addToPoints=false)
/**
 * Sets the client's current skillpoints.
 *
 * @param id			The index of the client.
 * @param amount		The amount of skillpoints to set for the client.
 * @param addToPoints	True to add amount to current skill points, false to set to amount.
 * @return				gPoints[id] on success, -1 on error.
 * @note				If points are calculated to go below zero, gPoints[id] will be set to 0 and not go below.
 */
native xpm_set_points(id, amount, bool:addToPoints);

/**
 * Retrieves the client's current skillpoints.
 *
 * @param id		The index of the client.
 * @return			The current skillpoints of the client.
 */
native xpm_get_points(id);

//  @param SklMax		Skill max level (i.e. 645) - temporarily removed rom register skill

/**
 * Registers skill for use with XPM skill menu
 *
 * @param SklName		Skill cvar Name. (i.e. "strength") (max 16 characters)
 * @param SklCost		Skill point cost for this skill (i.e. 1 for 1 skillpoint cost, 5 for 5 skillpoints)
 * @param SklDesc		Skill Description (max 16 characters).(i.e. "Strength")
 * @param SklCallback	Skill callback for shop menu function
 */
 
/**
 * Adds a "Skill" item to the shop through XPM library as a base core plugin to handle leveling and XP ( see xpm_xp_system.sma, based on SCXPM by Silencer & others )
 * 
 * @param		name - The name of the item in the menu
 * @param		name_short - A shortened version of the name (use only lowercase letters and no other characters)
 * @param		default_cost - The default cost of the item (if cost = SHOP_COST_NONE, cost is hidden from menu)
 * @param		team - The default set of teams allowed to use the item (combine specific teams with SHOP_TEAM_* constants and the bitwise | operator)
 * @param		usage_delay - The delay in seconds between using this item (use SHOP_DELAY_NONE for no delay or SHOP_DELAY_ROUND for once per round)
 * @param		callback_allowed - The name of the function to handle who can use the item, leave empty string for everyone to use
 * @param		reset_option - The setting for when the item resets and is no longer in use
 * 				SHOP_RESET_TIMEONLY for the time to expire
 * 				SHOP_RESET_ROUND for next round
 * 				SHOP_RESET_DEATH for when player dies
 * 				SHOP_RESET_SPAWN for when player spawns)
 * 				These are bitwise flags, so use | operator to combine them, or use SHOP_RESET_ALL for all of them
 * @param		reset_time - The time in seconds that the item lasts. If set to SHOP_TIME_INFINITE, then there is no timer and will wait for the reset_option setting to stop it.
 * 
 * @return		A unique item id on success, 0 on failure.
 * 
 * @note		Callbacks should be structured as: public <function name>(item, id)
 * @note		In callback for allowed, the return value should be a SHOP_ITEM_* constant
 * @note		The "allowed" callback is called twice: (1) when menu is displayed (2) when player selects the item
 * @note		If reset_option is SHOP_RESET_TIMEONLY and reset_time is SHOP_TIME_INFINITE, then the shop will never force the item to reset
 */
native register_skill(const name[], const name_short[], default_cost=SHOP_COST_NONE, team=SHOP_TEAM_ALL, usage_delay=SHOP_DELAY_NONE, const callback_allowed[]="", reset_option=SHOP_RESET_ALL, reset_time=SHOP_TIME_INFINITE);
// likely number conflict with const, just use 0 for usage_delay - need to make register_skill different

// native shop_add_item(const name[], const name_short[], const default_cost=SHOP_COST_NONE, const team=SHOP_TEAM_ALL, const usage_delay=SHOP_DELAY_ROUND, const callback_allowed[]="", const reset_option=SHOP_RESET_ALL, const reset_time=SHOP_TIME_INFINITE);


// register to another array the values ? or register_skill ?? can use pcvars
native set_skill_info(skillIndex, requiredPlayerLevel=0, maxSkillLevel, const description[], const shortName[]);

native get_player_level(id);//returns player level
native set_player_level(id, level, bool:addToLevel=false);

native get_skill_level(id, skillIndex);// returns current level of skill
native set_skill_level(id, skillIndex, level, bool:addToLevel=false);//set level of player skill


/**************************
 *        FORWARDS        *
 **************************/

/**
 * Called when a skill is added or dropped.
 * See xpm_const.inc for mode types.
 *
 * @param id			The index of the client.
 * @param skillIndex	The index of the skill.
 * @param mode			The skillIndex is being added or dropped.
 * @noreturn
 */
forward skill_init(id, skillIndex, mode);

//forward skill_init(player_id,skill_index);
