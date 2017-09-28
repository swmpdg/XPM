// Half-Life Experience Mod (HLXPM) by Swamp Dog @ ModRiot.com 
// Concept based on Sven Co-op Experience Mod (SCXPM) by Silencer and others

#include < amxmodx >
#include < amxmisc >
#include < engine >
#include < debug_helper >

#pragma semicolon 1

// max skills possible to load hardcoded to 64 for now.
#define MAX_SKILLS 64

// define for using CS or not (use with Sven Coop, other mods)
#define USING_CS

// to control spawning and death forwards - use fakemeta or ham sandwich, but not both
#define USE_HAMSANDWICH
//#define USE_FAKEMETA

#if defined USE_HAMSANDWICH
#include < hamsandwich >
#endif

#if defined USE_FAKEMETA
#include < fakemeta >
new deadFlag[33];
#endif

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
	"XPM Max HP & AP",
	"0.0.1a",
	"swampdog@modriot.com",
	"xpm_hp_ap"
};

// forwards
// new fwdStartHealth, fwdMaxHealth, fwdStartArmor, fwdMaxArmor, fwdReturn;
new fwdXPMSpawn, fwdXPMDie;
new fwdReturn;

// array to contain points, level, and ??
//new gPlayer[33][2];
//new gLevel[33];

// global starting values

/// global starthealth
new g_start_hp, pcvar_start_hp;
/// global startarmor
new g_start_ap, pcvar_start_ap;
/// player starthealth
new g_iStart_HP[33];
/// player startarmor
new g_iStart_AP[33];

// global max variables

/// global max health variable
new g_max_health, pcvar_max_hp;
/// global max armor variable
new g_armortype, pcvar_max_ap;
/// player max health
new Float:g_fMax_HP[33];
/// player max armor
new Float:g_fMax_AP[33];

enum
{
	FWD_XPM_SPAWN,
	FWD_XPM_DIE,
	FWD_START_HEALTH,
	FWD_MAX_HEALTH,
	FWD_START_ARMOR,
	FWD_MAX_ARMOR,
}

// forwards in an array using the Enum above
stock const fwdID[FWD_MAX_ARMOR+1][] =
{
	"xpm_spawn",
	"xpm_die",
	"start_health",
	"max_health",
	"start_armor",
	"max_armor"
};

public debug_set(bool:debug_enabled)
{
	if(!pcvar_debug)
		register_debug_cvar("xpm_hp_ap_debug", "0");// add cvar to debug_helper.cfg to have it loaded with the cfg
	set_debug_logging(debug_enabled);
	return;
}

public plugin_init()
{
	register_plugin(xpmLib[_NAME], xpmLib[_VERSION], xpmLib[_AUTHOR]);
//	register_dictionary("xpm_core.txt");

#if defined USE_HAMSANDWICH
	RegisterHam(Ham_Spawn, "player", "XPMPlayerSpawnPost", 1);
	RegisterHam(Ham_Killed, "player", "XPMPlayerKilledPost", 1);
#endif

#if defined USE_FAKEMETA
	register_forward(FM_PlayerPreThink,"xpm_prethink");
#endif

	fwdXPMSpawn = CreateMultiForward("xpm_spawn", ET_IGNORE, FP_CELL);// parameter 1 = player index
	fwdXPMDie = CreateMultiForward("xpm_die", ET_IGNORE, FP_CELL);// parameter 1 = player index
/*
	fwdStartHealth = CreateMultiForward(fwdID[FWD_START_HEALTH], ET_IGNORE, FP_CELL, FP_CELL);// parameter 1 = player index, parameter 2 = value
	fwdMaxHealth = CreateMultiForward(fwdID[FWD_MAX_HEALTH], ET_IGNORE, FP_CELL, FP_FLOAT);// parameter 1 = player index, parameter 2 = value rounded, must be greater than 0.9

	fwdStartArmor = CreateMultiForward(fwdID[FWD_START_ARMOR], ET_IGNORE, FP_CELL, FP_CELL);// parameter 1 = player index, parameter 2 = value
	fwdMaxArmor = CreateMultiForward(fwdID[FWD_MAX_ARMOR], ET_IGNORE, FP_CELL, FP_FLOAT);// parameter 1 = player index, parameter 2 = value rounded, must be greater than 0.9
*/
	// register cvars
	pcvar_start_hp = register_cvar("xpm_start_hp","0");// use 0 for default map settings? any value greater than 0 for setting
	pcvar_start_ap = register_cvar("xpm_start_ap","0");// use 0 for default map settings? any value greater than 0 for setting
	pcvar_max_hp = register_cvar("xpm_max_hp","0");// 0.0 to disable? set to absolute value with decimal, such as 300.0 (not 300.2), rounded down.
	pcvar_max_ap = register_cvar("xpm_max_ap","0");// 0.0 to disable? set to absolute value with decimal, such as 300.0 (not 300.2), rounded down.
//	pcvar_min_gravity = register_cvar("xpm_min_gravity","0.5");

	cache_pcvars();// perhaps try to use cvars amxx 1.8.3 functionality once again, to avail
}

cache_pcvars()
{
	g_start_hp = get_pcvar_num(pcvar_start_hp);
	g_start_ap = get_pcvar_num(pcvar_start_ap);
	g_max_health = get_pcvar_num(pcvar_max_hp);
	g_armortype = get_pcvar_num(pcvar_max_ap);
}


#if defined USE_FAKEMETA

public XPMPlayerSpawnPost(id)
{
	if(is_user_alive(id))
	{
		set_max_hp(id, g_fMax_HP[id], false);
		set_max_ap(id, g_fMax_AP[id], false);
		ExecuteForward(fwdXPMSpawn, fwdReturn, id);
	}
}

public XPMPlayerKilledPost(id)
{
	if(!is_user_alive(id))
	{
		ExecuteForward(fwdXPMDie, fwdReturn, id);
	}
}

public xpm_prethink(id)
{
	new deadflag=pev(id,pev_deadflag);

	if(!deadflag&&deadFlag[id])
	{
		XPMPlayerSpawnPost(id);
	}
	else if(deadflag&&!deadFlag[id])
	{
		XPMPlayerKilledPost(id);
	}

	deadFlag[id]=deadflag;

	return FMRES_IGNORED;
}

#endif // USE_FAKEMETA

#if defined USE_HAMSANDWICH

public XPMPlayerSpawnPost(id)
{
	if(is_user_alive(id))
	{
		set_max_hp(id, g_fMax_HP[id], false);
		set_max_ap(id, g_fMax_AP[id], false);
		ExecuteForward(fwdXPMSpawn, fwdReturn, id);
	}

	return HAM_IGNORED;
}

public XPMPlayerKilledPost(id, killer, shouldGib)
{
	if(!is_user_alive(id))
	{
		ExecuteForward(fwdXPMDie, fwdReturn, id);
	}

	return HAM_IGNORED;
}

#endif // USE_HAMSANDWICH

public plugin_natives()
{
	// xpm_core library - to be loaded before the sub-plugins
	register_library("xpm_hp_ap");

	// health-related natives - move to separate plugin library?
	register_native("set_start_health","_set_start_health");
	register_native("get_start_health","_get_start_health");
	register_native("set_start_armor","_set_start_armor");
	register_native("get_start_armor","_get_start_armor");
//	register_native("get_sv_start_health","_get_sv_start_health");
//	register_native("get_sv_start_armor","_get_sv_start_health");

	// armor-related natives - move to separate plugin library?
	register_native("set_max_health","_set_max_health");
	register_native("get_max_health","_get_max_health");
	register_native("set_max_armor","_set_max_armor");
	register_native("get_max_armor","_get_max_armor");
	register_native("get_sv_max_health","_get_sv_max_health");
	register_native("get_sv_max_armor","_get_sv_max_armor");// may be better to forward max_armor values to plugins

	// ammo-related natives
	
	
	// speed-related natives
	
	
	// gravity-related natives
	
	
	// distance-related natives (like team power) i.e "is_team_close(i, id) except in a native with a bool statement" "distance API"
	
	
	// afk-related natives (like afk manager) i.e. "is_player_afk(id)" with a mative and bool statement to return quickly "AFK API"
}

// set_start_health(player_id,value,bool:add_to_starthealth);// returns current starthealth. add_to_starthealth true to add on, false to set (checks max_health so it won't go over)
public _set_start_health(plugin,params)
{
	
}

// get_start_health(player_id);// returns current starthealth
public _get_start_health(plugin,params)
{
	
}

// set_start_armor(player_id,value,bool:add_to_startarmor);// returns current startarmor. add_to_startarmor true to add on, false to set (checks max_armor so it won't go over)
public _set_start_armor(plugin,params)
{
	
}

// get_start_armor(player_id);// returns current startarmor
public _get_start_armor(plugin,params)
{
	
}

// set_max_health(player_id,value,bool:add_to_max_health);// returns current max_health. add_to_max_health true to add on, false to set (checks starthealth so it won't go under)
public _set_max_health(plugin,params)
{
	if(params!=3)
	{
		log_error(AMX_ERR_PARAMS, "Missing or incorrect parameters");
		return -1;
	}

	new id = get_param(1);

	if(!id)
		return PLUGIN_CONTINUE;

	new Float:fValue = float(get_param(2));

	new addOn = get_param(3);

	set_max_hp(id, fValue, addOn);

	return PLUGIN_HANDLED;
}


// get_max_health(player_id);// returns current max_health
public _get_max_health(plugin,params)
{
	if(params!=1)
	{
		log_error(AMX_ERR_PARAMS, "Missing or incorrect parameters");
		return -1;
	}

	new id = get_param(1);

	if(!id)
		return PLUGIN_CONTINUE;

	new Float:g_PlayerMaxHP = g_fMax_HP[id];
	new i_MaxHP = floatround(g_PlayerMaxHP,floatround_floor);

	return i_MaxHP;
}

// set_max_armor(player_id,value,bool:add_to_max_armor);// returns current max_armor. add_to_max_health true to add on, false to set (checks startarmor so it won't go under)
public _set_max_armor(plugin,params)
{
	if(params!=3)
	{
		log_error(AMX_ERR_PARAMS, "Missing or incorrect parameters");
		return -1;
	}

	new id = get_param(1);

	if(!id)
		return PLUGIN_CONTINUE;

	new Float:fValue = float(get_param(2));

	new addOn = get_param(3);

	set_max_ap(id, fValue, addOn);

	return PLUGIN_HANDLED;
}


// get_max_armor(player_id);// returns current max_armor
public _get_max_armor(plugin,params)
{
	if(params!=1)
	{
		log_error(AMX_ERR_PARAMS, "Missing or incorrect parameters");
		return -1;
	}

	new id = get_param(1);

	if(!id)
		return PLUGIN_CONTINUE;

	new i_MaxAP = floatround(g_fMax_AP[id],floatround_floor);

	return i_MaxAP;
}

public _get_sv_max_health(plugin,params)
{
	if(params!=0)
	{
		log_error(AMX_ERR_PARAMS, "Missing or incorrect parameters");
		return -1;
	}

	new i_MaxHP = get_sv_max_hp();

	return i_MaxHP;
}

public _get_sv_max_armor(plugin,params)
{
	if(params!=0)
	{
		log_error(AMX_ERR_PARAMS, "Missing or incorrect parameters");
		return -1;
	}

	new i_MaxAP = get_sv_max_ap();

	return i_MaxAP;
}

public client_connect(id)
{
	if(g_start_hp)
		g_iStart_HP[id] = g_start_hp;
	if(g_start_ap)
		g_iStart_AP[id] = g_start_ap;

	if(g_max_health)
		g_fMax_HP[id] = float(g_max_health);
	else
		g_fMax_HP[id] = 100.0;

	if(g_armortype)
		g_fMax_AP[id] = float(g_armortype);
	else
		g_fMax_AP[id] = 100.0;
}


#if AMXX_VERSION_NUM >= 183
public client_disconnected(id)
#else
public client_disconnect(id)
#endif
{
	// player left, so reset points
//	gPoints[id] = 0;
	g_fMax_HP[id] = 0.0;
	g_fMax_AP[id] = 0.0;
}


/// Set max armor points - using entvar "max_health" - if using a mod that needs it (like Sven Coop) to prevent constant counting down of points
stock set_max_hp(id, Float:max_hp, addToMax=0)
{
	if(!addToMax)
	{
		if((g_max_health) && (max_hp > g_max_health))
				max_hp = float(g_max_health);
		if(max_hp < 1.0)
			max_hp = 1.0;
	}
	else
	{
		new Float:cur_max_hp, Float:new_max_hp;// Float:player_max_hp;

//		player_max_hp = get_max_hp(id);
		cur_max_hp = entity_get_float(id, EV_FL_max_health);
		new_max_hp = cur_max_hp + max_hp;

		// only check if g_max_health is > 0.0
		if((g_max_health) && (new_max_hp > g_max_health))
		{
			new_max_hp = float(g_max_health);
		}

		if(new_max_hp < 1.0)
			new_max_hp = 1.0;

		max_hp = new_max_hp;
//		log_amx("cur_max_hp: %f,^nnew_max_hp: %f,^ng_max_health: %f,^nmax_hp: %f,^nplayer_max_hp: %f",cur_max_hp,new_max_hp,g_max_health,max_hp,player_max_hp);
	}
	g_fMax_HP[id] = max_hp;
//	set_ev_max_health(id, max_hp);
	if(is_user_alive(id))
	{
		entity_set_float(id, EV_FL_max_health, max_hp);
//		log_amx("g_fMax_HP[id]: %f,^nmax_hp: %f",g_fMax_HP[id],max_hp);
	}
}

/// Set max armor points - using entvar "armortype" - if using a mod that needs it (like Sven Coop) to prevent constant counting down of points
stock set_max_ap(id, Float:max_ap, addToMax=0)
{
	if(!addToMax)
	{
		if((g_armortype) && (max_ap > g_armortype))
				max_ap = float(g_armortype);
		if(max_ap < 1.0)
			max_ap = 1.0;
	}
	else
	{
		new Float:cur_max_ap, Float:new_max_ap;// Float:player_max_ap;

//		player_max_ap = get_max_ap(id);
		cur_max_ap = entity_get_float(id, EV_FL_armortype);
		new_max_ap = cur_max_ap + max_ap;

		// only check if g_armortype is > 0.0
		if((g_armortype) && (new_max_ap > g_armortype))
		{
			new_max_ap = float(g_armortype);
		}

		if(new_max_ap < 1.0)
			new_max_ap = 1.0;

		max_ap = new_max_ap;

//		log_amx("cur_max_hp: %f,^nnew_max_hp: %f,^ng_max_health: %f,^nmax_hp: %f,^nplayer_max_hp: %f",cur_max_ap,new_max_ap,g_armortype,max_ap,player_max_ap);
	}
	g_fMax_AP[id] = max_ap;
//	set_ev_armortype(id, max_ap);
	if(is_user_alive(id))
	{
		entity_set_float(id, EV_FL_armortype, max_ap);
//		log_amx("g_fMax_AP[id]: %f,^nmax_ap: %f",g_fMax_AP[id],max_ap);
	}
}

stock Float:get_max_hp(id)
{
	return g_fMax_HP[id];
}

stock Float:get_max_ap(id)
{
	return g_fMax_AP[id];
}

stock get_sv_max_hp()
{
	return g_max_health;
}

stock get_sv_max_ap()
{
	return g_armortype;
}