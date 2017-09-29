// Half-Life Experience Mod (HLXPM) by Swamp Dog @ ModRiot.com 
// Concept based on Sven Co-op Experience Mod (SCXPM) by Silencer and others
#include < amxmodx >
#include < amxmisc >
#include < debug_helper >
#include < shop >
#include < xpm_const >

#pragma semicolon 1

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
new fwdSkillInit;
new fwdReturn;

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
/// max level for skill
new gItemMaxLevel[MAX_SKILLS+1];
/// required player level for skill
new gItemRequiredLevel[MAX_SKILLS+1];
/// current player skill level loaded?
new gSkillLevel[33][MAX_SKILLS+1];// set skill status with player's current level of skill
/// current player level loaded for checking requirements
new gPlayerLevel[33];

enum _:SkillzData
{
	_CVAR_NAME[16],// short name to append with shop
	_CVAR_COST,
	_DESC[32],// name of the skill - not long enough?
	_CALLBACK[32],
	_PLUGIN_ID,
	_FUNC_ID,
};

new Array:g_aCvars;
new g_iTotalCvars;
enum _:CvarzData
{
	_SKILL_INDEX,
	_SKILL_MAX,
	_SKILL_LEVEL,//required player level for skill
	_SKILL_DESC[64],
	_SKILL_SHORT[16]
};

enum
{
	FWD_SKILL_INIT,
}

// forwards in an array using the Enum above
stock const fwdID[FWD_SKILL_INIT+1][] =
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

	new eSklCvar[CvarzData];
	g_aCvars = ArrayCreate(CvarzData);
	ArrayPushArray(g_aCvars, eSklCvar);
	g_iTotalCvars++;

#if defined USING_CS
	register_event("DeathMsg", "EventDeathMsg", "a");
#endif

	register_clcmd("say /skillpoints", "CmdPoints");

	// command to test max level from max_xp
	register_clcmd("say /resetskills", "clearAllSkills");

	fwdSkillInit = CreateMultiForward(fwdID[FWD_SKILL_INIT], ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);// param 1 = player id, param 2 = skill id, param 3 = mode

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
	register_native("set_skill_info","_set_skill_info");// set_skill_info with longer description maybe

	register_native("xpm_set_points","_xpm_set_points");// for skillpoints
	register_native("xpm_get_points","_xpm_get_points");// for skill points

//	register_native("get_skill_status","_get_skill_status");
//	register_native("set_skill_status","_set_skill_status");// for handling max level skills..

	// native set_player_level(id, player_level, bool:addToLevel=false); // returns player level
	// native get_player_level(id); // returns player level
	register_native("set_player_level","_set_player_level");
	register_native("get_player_level","_get_player_level");

	//native get_skill_level(id, skillIndex);// returns level of skill loaded for player
	//native set_skill_level(id, skillIndex, level, bool:addToLevel);// sets level of skill loaded for player
	register_native("get_skill_level","_get_skill_level");// player skill level of current item
	register_native("set_skill_level","_set_skill_level");// set specific levels for skills on players, call through forward?
/*
	// ammo-related natives
	
	
	// speed-related natives
	
	
	// gravity-related natives
	
	
	// distance-related natives (like team power) i.e "is_team_close(i, id) except in a native with a bool statement" "distance API"
	
	
	// afk-related natives (like afk manager) i.e. "is_player_afk(id)" with a mative and bool statement to return quickly "AFK API"
*/
}

public _get_skill_level(plugin,params)
{
	if(params!=2)
	{
		log_bad_params();
		return 0;
	}

	new id = get_param(1);
	new skillId = get_param(2);

	if(!id || !skillId)
		return PLUGIN_CONTINUE;

	return gSkillLevel[id][skillId];
}

public _set_skill_level(plugin,params)
{
	if(params!=4)
	{
		log_bad_params();
		return 0;
	}

	new id = get_param(1);
	new skillId = get_param(2);

	if(!id || !skillId)
		return PLUGIN_CONTINUE;

	new skillLevel = get_param(3);

	new addToLevel = get_param(4);
	new maxSkill = gItemMaxLevel[skillId];

	if(!addToLevel)
	{
		if((maxSkill) && (skillLevel > maxSkill))
		{
			skillLevel = gItemMaxLevel[skillId];
		}
		else
		{
			if(skillLevel < 0)
			{
				skillLevel = 0;
			}
		}
	}
	else
	{
		new oldSkillLvl = gSkillLevel[id][skillId];
		new skillLevel = oldSkillLvl + skillLevel;

		if((maxSkill) && (skillLevel > maxSkill))
		{
			skillLevel = maxSkill;
		}
		else
		{
			if (skillLevel < 0)
			{
				skillLevel = 0;
			}
		}
	}

//	gSkillLevel[id][skillId] = skillLevel;
	set_skill_lvl(id, skillId, skillLevel, false);

	return skillLevel;// return new skill level
}

public _get_player_level(plugin,params)
{
	if(params!=1)
	{
		log_bad_params();
		return -1;
	}

	new id = get_param(1);

	if(!id)
		return PLUGIN_CONTINUE;

	return gPlayerLevel[id];
}

// bool add to level
public _set_player_level(plugin,params)
{
	if(params!=3)
	{
		log_bad_params();
		return -1;
	}

	new id = get_param(1);

	if(!id)
		return PLUGIN_CONTINUE;
	
	new level = get_param(2);

	new addToLevel = get_param(3);

	if(!addToLevel)
	{
		if(level < 0)
			level = 0;
		gPlayerLevel[id] = level;
	}
	else
	{
		new newLevel = level+gPlayerLevel[id];
		if(newLevel < 0)
			newLevel = 0;
		gPlayerLevel[id] = newLevel;
	}

	return gPlayerLevel[id];
}

//native set_skill_info(skillIndex, requiredPlayerLevel=0, maxSkillLevel, const description[], const shortName[]);
public _set_skill_info(plugin,params)
{
	if(params!=5)
	{
		log_bad_params();
		return -1;
	}

	new eSklCvar[SkillzData];
	new sklId = get_param(1);

	if(!sklId)
	{
		log_error(AMX_ERR_PARAMS, "Invalid Skill Index");
		return -1;
	}

	eSklCvar[_SKILL_INDEX] = get_param(1);

	new sklReqLvl = get_param(2);
	eSklCvar[_SKILL_LEVEL] = sklReqLvl;
	gItemRequiredLevel[sklId] = sklReqLvl;

	new sklMaxLvl = get_param(3);
	eSklCvar[_SKILL_MAX] = sklMaxLvl;
	gItemMaxLevel[sklId] = sklMaxLvl;

	get_string( 4, eSklCvar[_SKILL_DESC], charsmax(eSklCvar[_SKILL_DESC]));
	get_string( 5, eSklCvar[_SKILL_SHORT], charsmax(eSklCvar[_SKILL_SHORT]));

	ArrayPushArray( g_aCvars, eSklCvar );

	g_iTotalCvars++;

	return (g_iTotalCvars - 1);
}

// xpm_is_on(); // check if program is enabled
public _xpm_is_on(plugin,params)
{
	if(params!=0)
	{
		log_bad_params();
		return PLUGIN_CONTINUE;
	}

	return g_iXPMEnabled ? 1 : 0;
}

// set_skill_info()

// register_skill("skill_name","max_level_cvar","Description");// returns skill index for sub-plugin - requires "skill_init" with skill index - similar to superhero mod and runemod ? must return value greater than 1? g_iSkillRegistry[MAX_SKILLS][2][16] - include callback?
public _register_skill(plugin,params)
{
	if(params<6)
	{
		log_bad_params();
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
			new costvalue = gItemCostValues[i];

			// don't show player if they don't have enough points
			if(gPoints[id] < costvalue)
				return SHOP_ITEM_HIDDEN;

//			new reqLvl = gItemRequiredLevel[item];
			new reqLvl = gItemRequiredLevel[i];

			// don't show player if they aren't a high enough level
			if((reqLvl > 0) && (reqLvl > gPlayerLevel[id]))
				return SHOP_ITEM_HIDDEN;

			// somewhere in here is breaking medals from showing up in the list...
			
//			new itemMax = gItemMaxLevel[item];
//			new sklLvl = gSkillLevel[id][item];
			new itemMax = gItemMaxLevel[i];
			new sklLvl = gSkillLevel[id][i];

			new costLvl = sklLvl + costvalue;

			// don't show player if they already have the max level of this skill (cost must be less than max)
			if((itemMax > 0) && (itemMax < costLvl))
			{
				debug_log(g_debug,"Disabled itemMax: %i, costLvl: %i, sklLvl: %i", itemMax, costLvl, sklLvl);
				return SHOP_ITEM_HIDDEN;
			}
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
			// we can return the leftover skillpoints here with fwdReturn, and avoid using callfunc here which won't return a value?
			initSkill(id, item, SKILL_ADD);

			// wasn't counting towards max level when selected - have plugins handle this separately?
//			gSkillLevel[id][item]+=gItemCostValues[item];// have plugins handle with natives when using more than 1 item index per skill...

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

public shop_item_reset(item, id)
{
	for(new i = 1; i <= g_iTotalItems; i++)
	{
		if(gItems[i] == item)
		{
			gSkillLevel[id][item] = 0;// reset?
			debug_log(g_debug,"Skill index %i reset for player index %i", item, id);
			break;
		}
	}
}

// similar to superhero mod
initSkill(id, skillIndex, mode)
{
	ExecuteForward(fwdSkillInit, fwdReturn, id, skillIndex, mode);// could have fwdReturn return value of current level of skill? to let plugin know?
}

// clear all skills // clearAllPowers(id, bool:dispStatusText) // should do bool:addPointsBack or something like that
public clearAllSkills(id)
{
	// OK to fire if mod is off since we want skills to clean themselves up
//	gPlayerPowers[id][0] = 0
//	gPlayerBinds[id][0] = 0

//	new totalPoints;
	new skillIndex;
	new bool:userConnected = is_user_connected(id) ? true : false;

	// Clear the power before sending the drop init
	for ( new x = 1; x <= g_iTotalItems; x++ )
	{

		// Save skillid for init forward
		skillIndex = gItems[x];

		// Clear All skill slots for player
		gSkillLevel[id][x] = 0;

		// Only send drop on skills user has (/)
//		if ( skillIndex != -1 && userConnected )
		if ( skillIndex > 0 && userConnected )
		{
			initSkill(id, skillIndex, SKILL_DROP);  // Disable this skill
		}
	}
	// don't return points? or return points for player level?
//	if(gPlayerLevel[id])
//		localSetPoints(id,gPlayerLevel[id],true);
}

// skillpoints natives - xpm_set_points(player_id,amount,bool:addToSkillpoints=false)
// returns -1 on missing parameters, 0 on none or less than 0 skill points or missing player id, or returns current skillpoints after being set
public _xpm_set_points(plugin, params)
{
	if(params!=3)
	{
		log_bad_params();
		return -1;
	}

	new id = get_param(1);

	if(!id)
		return PLUGIN_CONTINUE;

	new amt = get_param(2);

	new addOn = get_param(3);

	localSetPoints(id, amt, addOn);

	return gPoints[id];
}

// use 1 to add to points, 0 to set points
localSetPoints(id, amount, addToPoints=0)
{
	if(addToPoints)
	{
		new oldPts = gPoints[id];
		new newPts = oldPts + amount;

		if(newPts < 0)
			newPts = 0;

		gPoints[id] = newPts;
	}
	else
	{
		// we can go negative, but not yet
		if(amount < 0)
			amount = 0;

		gPoints[id] = amount;
	}
}

// skillpoints natives - xpm_get_points(player_id)
// returns current skill points
public _xpm_get_points(plugin,params)
{
	if(params!=1)
	{
		log_bad_params();
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


stock set_skill_lvl(id, skillIndex, skill_level, bool:addToLevel=false)
{
	if(!addToLevel)
	{
		gSkillLevel[id][skillIndex] = skill_level;
	}
	else
	{
		gSkillLevel[id][skillIndex]+=skill_level;
	}
}