#include < amxmodx >
#include < amxmisc >
#include < debug_helper >

#pragma semicolon 1

// debug log messages
new fwdDebugSet, fwdReturn;
new configsDir[64];

public plugin_init()
{
	set_task(5.0,"loop_check_debug",18015,_,_,"b");
}

public plugin_precache()
{
	register_plugin( "Debug Helper", "1.0", "dude" );
	fwdDebugSet = CreateMultiForward("debug_set", ET_IGNORE, FP_CELL);// will forward 1 character lightstyle to plugins

//	pcvar_debug = register_cvar("debug_helper", "0");// 0 = off, 1 = on (implement levels?)
	register_debug_cvar("debug_helper", "0");

	get_configsdir(configsDir,63);

	server_cmd("exec %s/debug_helper.cfg", configsDir);
	new mapName[32];
	get_mapname(mapName, charsmax(mapName));
	new mapCfg[128];
	format(mapCfg, charsmax(mapCfg), "%s/maps/%_debug.cfg", configsDir, mapName);
	if(file_exists(mapCfg))
	{
		log_amx("Map debug log configuration file found for %s, executing config", mapName);
		server_cmd("exec %s",mapCfg);
	}

	g_debug = get_pcvar_num(pcvar_debug);
	if(g_debug)
	{
		dbg_log = true;
		// make sure all cfgs get executed here?
		debug_log(g_debug, "plugin_precache executing forward debug_set()");
		ExecuteForward(fwdDebugSet, fwdReturn, dbg_log);
	}
}

public loop_check_debug()
{
	new oldDebug = g_debug;
	g_debug = get_pcvar_num(pcvar_debug);
	if(oldDebug != g_debug)
	{
		switch(g_debug)
		{
			case 1:
			{
				dbg_log = true;
				// make sure all cfgs get executed here?
				debug_log(g_debug, "Debug Helper logging enabled");
				ExecuteForward(fwdDebugSet, fwdReturn, dbg_log);
			}
			case 0:
			{
				dbg_log = false;
				// make sure all cfgs get executed here?
				debug_log(1, "Debug Logger helping disabled");
				ExecuteForward(fwdDebugSet, fwdReturn, dbg_log);
			}
		}
	}
}
