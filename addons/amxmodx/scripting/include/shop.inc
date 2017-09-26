#if defined _shop_included
	#endinput
#endif
#define _shop_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib shop
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib shop
	#endif
#else
	#pragma library shop
#endif

#include <amxmodx>

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

/**
 * Adds an item to the shop
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
native shop_add_item(const name[], const name_short[], const default_cost=SHOP_COST_NONE, const team=SHOP_TEAM_ALL, const usage_delay=SHOP_DELAY_ROUND, const callback_allowed[]="", const reset_option=SHOP_RESET_ALL, const reset_time=SHOP_TIME_INFINITE);

/**
 * Displays the shop menu to a (or all) player(s)
 * 
 * @param		id - The unique player id (use 0 to show to all players)
 * 
 * @return		Returns 1 on success, 0 on failure
 */
native shop_show_menu(id);

/**
 * Overrides the shop's money system but using your own
 * 
 * @param		function_get - The callback function that returns the player's money
 * @param		function_set - The callback function that sets the player's money
 * @param		money_single - The format used to display player's money when they have only 1 unit
 * @param		money_plural - The format used to display player's money when they have 0 or more than 1 units
 * 
 * @return		Returns 1 on success, 0 on failure
 * 
 * @note		To only change the functions for get/set, do not pass format parameters.
 * @note		To only change the format, set the functions to "" and it will still use the CS money system.
 * 
 * @note		Callbacks should be structed as:
 * 			public CallbackMoneyGet(id)
 * 			public CallbackMoneySet(id, value)
 * 
 * @note		In the money formats, use "%d" for where the actual money value should go.
 * 
 * @note		Example of money formats using points:
 * 			shop_override_money("CallbackGetPoints", "CallbackSetPoints", "%d point", "%d points");
 * 			// ...
 * 			public CallbackGetPoints(id) { return gPoints[id]; }
 * 			public CallbackSetPoints(id, value) { gPoints[id] = value; }
 */
native shop_override_money(const function_get[], const function_set[], const money_single[] = "$%d", const money_plural[] = "$%d");

/**
 * Shows a message in the chat using the Shop's format
 * 
 * @param		id - The player to send the message to (0 is all players)
 * @param		fmt - The formatting message to send
 * @param		... - Any formatting parameters for the message
 * 
 * @return		Returns 1 on success, 0 on failure.
 * 
 * @note		This does not support colored chat and forces the tag in front of the message.
 */
native shop_print(id, const fmt[], any:...);

/**
 * Called when an item was selected
 * 
 * @param		item - The unique item id
 * @param		player - The unique player id
 * 
 * @return		PLUGIN_CONTINUE allows selection
 * 			PLUGIN_HANDLED blocks selection and does not send forward to any plugins after this one
 * 			PLUGIN_HANDLED_MAIN blocks selection but the forward continues to other plugins
 */
forward shop_item_selected(item, player);

/**
 * Called when an item is reset
 * 
 * @param		item - The unique item id
 * @param		player - The unique player id
 * 
 * @return		Return values are ignored
 */
forward shop_item_reset(item, player);

/**
 * Registers a specific cvar for an item
 * 
 * @param		name_short - The short name for the item that has only lowercase letters for characters
 * @param		description - A short description of the cvar's contents using only lowercase letters (eg. 'time', 'value')
 * @param		default_value - The default value for the cvar
 * @param		flags - Same flags usage from register_cvar()
 * @param		fvalue - Same fvalue usage from register_cvar()
 * 
 * @return		Returns the pointer to the registered cvar, or 0 on failure
 */
native shop_item_register_cvar(item, const description[], const default_value[], flags=0, Float:fvalue=0.0);
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
