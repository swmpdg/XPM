// Half-Life Experience Mod (HLXPM) by Swamp Dog @ ModRiot.com 
// Concept based on Sven Co-op Experience Mod (SCXPM) by Silencer and others
#include < amxmodx >
#include < amxmisc >
#include < debug_helper >
#include < shop >

#pragma semicolon 1

// max skills possible to load hardcoded to 64 for now.
#define MAX_SKILLS 64

// define for using CS or not (use with Sven Coop, other mods)
#define USING_CS

// to contain the registered skills - 0 in array = "cvar_name", 1 = "max_level", 2 = "Description"(limited to 16 characters for now)

enum
{
	_NAME,
	_VERSION,
	_AUTHOR,
	_LIBNAME,
}

new const xpmLib[_LIBNAME+1][] = 
{
	"XPM Core",
	"0.0.1a",
	"swampdog@modriot.com",
	"xpm_core"
};

// forwards
// new fwdSkillInit;
//new fwdReturn;

// cvars
new g_iCvarXPMEnabled, g_iXPMEnabled;

new Array:g_aItems;
new g_iTotalItems;

/// list of skills with indexes from Shop API
new gItems[MAX_SKILLS+1];
/// cost of skill
new gItemCostValues[MAX_SKILLS+1];
/// player points
new gPoints[33];

enum _:SkillzData
{
	_CVAR_NAME[16],// short name to append with shop
	_CVAR_COST,
	_DESC[32],// name of the skill - not long enough?
	_CALLBACK[32],
	_PLUGIN_ID,
	_FUNC_ID,
};

enum
{
	FWD_SKILL_INIT = 1
}

// forwards in an array using the Enum above
stock const fwdID[FWD_SKILL_INIT][] =
{
	"skill_init"
};

public debug_set(bool:debug_enabled)
{
	if(!pcvar_debug)
		register_debug_cvar("xpm_debug", "0");// add cvar to debug_helper.cfg to have it loaded with the cfg
	set_debug_logging(debug_enabled);
	return;
}

public plugin_init()
{
	register_plugin(xpmLib[_NAME], xpmLib[_VERSION], xpmLib[_AUTHOR]);
//	register_dictionary("xpm_core.txt");

	shop_override_money("CallbackGetPoints", "CallbackSetPoints", "%d point", "%d points");

	new eSklData[SkillzData];
	g_aItems = ArrayCreate(SkillzData);
	ArrayPushArray(g_aItems, eSklData);// empty holder so id's start at 1
	g_iTotalItems++;

#if defined USING_CS
	register_event("DeathMsg", "EventDeathMsg", "a");
#endif

	register_clcmd("say /skillpoints", "CmdPoints");

/*
	fwdSkillInit = CreateMultiForward(fwdID[FWD_SKILL_INIT], ET_IGNORE, FP_CELL, FP_CELL);// parameter 1 = skill index, parameter 2 = player index??
*/
	cache_pcvars();// perhaps try to use cvars amxx 1.8.3 functionality once again, to avail
}

cache_pcvars()
{
	g_iXPMEnabled = get_pcvar_num(g_iCvarXPMEnabled);
}

public plugin_precache()
{
	g_iCvarXPMEnabled = register_cvar("xpm_enabled", "1");
}

public plugin_natives()
{
	// xpm_core library - to be loaded before the sub-plugins
	register_library(xpmLib[_LIBNAME]);

	register_native("xpm_is_on","_xpm_is_on");

	register_native("register_skill","_register_skill");

	register_native("xpm_set_points","_xpm_set_points");// for skillpoints
	register_native("xpm_get_points","_xpm_get_points");// for skill points
/*
	// ammo-related natives
	
	
	// speed-related natives
	
	
	// gravity-related natives
	
	
	// distance-related natives (like team power) i.e "is_team_close(i, id) except in a native with a bool statement" "distance API"
	
	
	// afk-related natives (like afk manager) i.e. "is_player_afk(id)" with a mative and bool statement to return quickly "AFK API"
*/
}

// xpm_is_on(); // check if program is enabled
public _xpm_is_on(plugin,params)
{
	if(params!=0)
		return PLUGIN_CONTINUE;

	return g_iXPMEnabled ? 1 : 0;
}

// register_skill("skill_name","max_level_cvar","Description");// returns skill index for sub-plugin - requires "skill_init" with skill index - similar to superhero mod and runemod ? must return value greater than 1? g_iSkillRegistry[MAX_SKILLS][2][16] - include callback?
public _register_skill(plugin,params)
{
//	if(params!=5)

	if(params<6)
	{
		log_error(AMX_ERR_PARAMS, "Missing or incorrect parameters");
		return -1;
	}

	if(g_iTotalItems >= MAX_SKILLS+1)
		return PLUGIN_CONTINUE;

	new eSklData[SkillzData];

	get_string( 1, eSklData[_DESC], charsmax(eSklData[_DESC]));
	get_string( 2, eSklData[_CVAR_NAME], charsmax(eSklData[_CVAR_NAME]));

	new cvar_cost = get_param(3);
	eSklData[_CVAR_COST] = cvar_cost;

	gItemCostValues[g_iTotalItems] = cvar_cost;

	new shop_team = get_param(4);
	new shop_delay = get_param(5);

	//might be unnecessary if using something like a skill_init forward - could use eSklData array for arrays below instead
	get_string( 6, eSklData[_CALLBACK], charsmax(eSklData[_CALLBACK]));

	new reset_option = get_param(7);
	new reset_time = get_param(8);

	debug_log(g_debug,"%i %s skill successfuly loaded, now adding to menu. Cost: %i", g_iTotalItems, eSklData[_NAME], cvar_cost);
	debug_log(g_debug,"team: %i, delay: %i, reset_option: %i, reset_time: %i", shop_team, shop_delay, reset_option, reset_time);

	// from shop api
	// these arrays seems to handle the need for "const" data type with the Shop API native parameters - swmpdg
	new shopteamid[1], shopdelay[1], resetoption[1], resettime[1];

	shopteamid[0] = shop_team;
	shopdelay[0] = shop_delay;
	resetoption[0] = reset_option;
	resettime[0] = reset_time;

	gItems[g_iTotalItems] = shop_add_item(eSklData[_DESC], eSklData[_CVAR_NAME], cvar_cost, shopteamid[0], shopdelay[0], "CallbackItemAllowed",resetoption[0],resettime[0]);

	eSklData[_PLUGIN_ID] = plugin;
	eSklData[_FUNC_ID] = get_func_id(  eSklData[_CALLBACK], plugin );

	ArrayPushArray( g_aItems, eSklData );

	g_iTotalItems++;

	return (g_iTotalItems - 1);
}

public CallbackItemAllowed(item, id)
{
	for(new i = 1; i <= g_iTotalItems; i++)
	{
		if(gItems[i] == item)
		{
			if(gPoints[id] < gItemCostValues[i])
				return SHOP_ITEM_HIDDEN;
		}
	}

	return is_user_alive(id) ? SHOP_ITEM_ENABLED : SHOP_ITEM_DISABLED;
}

public shop_item_selected(item, id)
{
	for(new i = 1; i <= g_iTotalItems; i++)
	{
		if(gItems[i] == item)
		{
			// let plugins know that the skill has been initialized if it hasn't already
			// we can return the leftover skillpoints here with fwdReturn, and avoid using callfunc here which won't return a value
//			ExecuteForward(fwdSkillInit, fwdReturn, id, item);

			new eSklData[SkillzData];
			ArrayGetArray( g_aItems, item, eSklData);

			callfunc_begin_i( eSklData[_FUNC_ID], eSklData[_PLUGIN_ID]);
			callfunc_push_int(id);
			callfunc_push_int(item);
			callfunc_end();

			break;
		}
	}
	return PLUGIN_HANDLED;// return to over-ride handling of shop menu (doesn't work properly without value or with PLUGIN_CONTINUE)
}

/*
public shop_item_reset(item, id)
{
	for(new i = 1; i <= g_iTotalItems; i++)
	{
		if(gItems[i] == item)
		{
//			set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
//			break;
		}
	}
}
*/

// skillpoints natives - xpm_set_points(player_id,amount,bool:addToSkillpoints=false)
// returns -1 on missing parameters, 0 on none or less than 0 skill points or missing player id, or returns current skillpoints after being set
public _xpm_set_points(plugin, params)
{
	if(params!=3)
	{
		log_error(AMX_ERR_PARAMS, "Missing or incorrect parameters");
		return -1;
	}

	new id = get_param(1);

	if(!id)
		return PLUGIN_CONTINUE;

	new amt = get_param(2);

	new addOn = get_param(3);

	if(addOn)
	{
		new oldPts = gPoints[id];
		new newPts = oldPts + amt;

		if(newPts < 0)
			newPts = 0;

		gPoints[id] = newPts;
	}
	else
	{
		// we can go negative, but not yet
		if(amt < 0)
			amt = 0;

		gPoints[id] = amt;
	}

	return gPoints[id];
}

// skillpoints natives - xpm_get_points(player_id)
// returns current skill points
public _xpm_get_points(plugin,params)
{
	if(params!=1)
	{
		log_error(AMX_ERR_PARAMS, "Missing or incorrect parameters");
		return -1;
	}

	new id = get_param(1);

	return gPoints[id];
}

public client_connect(id)
{
	gPoints[id] = 5;
}

#if AMXX_VERSION_NUM >= 183
public client_disconnected(id)
#else
public client_disconnect(id)
#endif
{
	// player left, so reset points
	gPoints[id] = 0;
}

#if defined USING_CS

public EventDeathMsg()
{
	// read message data
	new killer = read_data(1);
	new victim = read_data(2);

	// check if valid kill
//	if(is_user_connected(victim) && killer != victim && cs_get_user_team(killer) != cs_get_user_team(victim)) {
	if(is_user_connected(victim) && killer != victim && get_user_team(killer) != get_user_team(victim))
	{
		// give killer points for killing
		new points = 5;

		// check if headshot
		if(read_data(3))
		{
			// give killer extra points for headshot
			points += 10;
		}

		// give killer the total points
		gPoints[killer] += points;

		// notify killer
		new name[32];
		get_user_name(victim, name, charsmax(name));
		client_print(killer, print_chat, "* You earned %d point%s for killing %s!", points, (points == 1) ? "" : "s", name);
	}
}

#endif

public CmdPoints(id)
{
	client_print(id, print_chat, "* You have %d point%s", gPoints[id], (gPoints[id] == 1) ? "" : "s");
}

// callback function for shop to get points
public CallbackGetPoints(id)
{
	// tell shop plugin the player's points
	return gPoints[id];
}

// callback function for shop to set points
public CallbackSetPoints(id, value)
{
	// set the player's points to the value from the shop
	// this is called after a player buys something
	gPoints[id] = value;
	client_print(id,print_chat,"You currently have %i points", value);
}
