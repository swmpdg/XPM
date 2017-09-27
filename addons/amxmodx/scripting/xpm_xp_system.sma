// comment the #define USING_CS if you don't use cs
#define USING_CS

#include <amxmodx>
#include <amxmisc>
// based on zp_ap_store_nvault system
#include <nvault>
#include <debug_helper>
#include <xpm>

#if defined USING_CS
#include <fakemeta>
const PEV_SPEC_TARGET = pev_iuser2;
#endif

const Float:HUD_SPECT_X = 0.6
const Float:HUD_SPECT_Y = 0.8
const Float:HUD_STATS_X = 0.02
//const Float:HUD_STATS_Y = 0.9
const Float:HUD_STATS_Y = 0.87

// Used for calculation in XP
const Float:mysteryNumber = 5.0;

new g_MsgSync;

#define TASK_SHOWHUD 100
#define ID_SHOWHUD (taskid - TASK_SHOWHUD)

#if !defined USING_CS
new pcvar_maxlevelup_enabled, pcvar_maxlevelup, pcvar_maxlevelup_limit;
new g_iMaxLvlUpOn, g_iMaxLvlUp, g_iMaxLvlUpLimit;
new firstLvl[33], lastfrags[33];
#endif

//new pcvar_hud_channel;
new pcvar_xpgain, pcvar_maxlevel, g_maxlevel, Float:g_fXPGain;
new pcvar_save_style, pcvar_save_method, pcvar_save_bots, g_save_style, g_savemethod, g_save_bots;

// name of vault file
#define VAULT_NAME "xpm_levels"

//Max player's xp that can be save in nvault? 2 less than max data type range for signed int
#define MAX_XP 2147483646

//Max day player's ammopack can be stay in vault, set 0 = permanent.
#define DAY_PRUNE 60
new hVaultHandle, bool:bIsLoaded[33], szName[33][35];

new xp[33],
	neededxp[33],
	playerlevel[33];

public debug_set(bool:debug_enabled)
{
	if(!pcvar_debug)
		register_debug_cvar("scxpm_debug","0");// add cvar to debug_helper.cfg to have it loaded with the cfg
	set_debug_logging(debug_enabled);
	return;
}

public plugin_init()
{
	register_plugin("XPM XP System","1.0.0a","Various");

	debug_log(g_debug, "[XPM] Loading XP Mod version 1.0.0a");

	g_MsgSync = CreateHudSyncObj();

#if !defined USING_CS
	/* If enabled, it will try to prevent players using bugs to boost their XP in maps like of4a4
	** 0 = Disabled
	** 1 = Enabled
	*/
	pcvar_maxlevelup_enabled = register_cvar("scxpm_maxlevelup_enabled", "0");
	
	// Maximum level can be gained per map (Default:20)
	pcvar_maxlevelup = register_cvar("scxpm_maxlevelup", "20");
	
	// Players will be able to level up without limitations if they're under the specified level (Default:100)
	pcvar_maxlevelup_limit = register_cvar("scxpm_maxlevelup_limit", "100");
#endif

	// xp gain factor - multiplies - 10.0 is highest recommended, although it can go higher.
	pcvar_xpgain = register_cvar( "scxpm_xpgain", "10.0" );
	
	// possibility to cap the max level - 1800 is default max level and is recommended as a highest level, but it can go higher.
	pcvar_maxlevel = register_cvar( "scxpm_maxlevel", "1800" );

	// saving method cvars - could be handled with some API also
	pcvar_save_style = register_cvar("xpm_level_save", "2")// 0 = off, 1 = Name, 2 = steam id, 3 = IP?

	// saving with vault or sql?
	pcvar_save_method = register_cvar("xpm_save_method","0");// 0 for nvault, 1 for mysql (if "xpm_level_save" is greater than 0)

	// allow bots to have data saved
	pcvar_save_bots = register_cvar("xpm_save_bots","0");

#if defined USING_CS
	// for mods which use DeathMsg
	register_event("DeathMsg","death","a");
#endif

	// command to test max level from max_xp
	register_clcmd("say /maxlevel", "CmdMaxLvl");
}

public CmdMaxLvl(id)
{
	new XPmaxLvl = scxpm_calc_lvl(MAX_XP);
	client_print(id,print_chat,"[XPM] Max Level is: %i.^n[XPM] Max XP is: %i.",XPmaxLvl,MAX_XP);
}

public plugin_natives()
{
	register_library("xpm_xp_system")

	register_native("xpm_set_xp","_xpm_set_xp");// xpm_set_xp(id, amount, bool:addToXP=false); //  returns new xp after set?
	register_native("xpm_get_xp","_xpm_get_xp");// xpm_get_xp(id); //  returns current xp
}

public _xpm_set_xp(plugin,params)
{
	if(params!=3)
	{
		log_error(AMX_ERR_PARAMS, "Missing or incorrect parameters");
		return -1;
	}
	new id = get_param(1);

	if(!id)
		return PLUGIN_CONTINUE;// ???

	new xpAmt = get_param(2);

	new bAddTo = get_param(3);

	if(!bAddTo)
	{
		if(xpAmt < 0)
			xpAmt = 0;
		else if(xpAmt >= MAX_XP)
			xpAmt = MAX_XP;// might be bad ot check this..
	}
	else
	{
		new newXP = xp[id]+xpAmt;
//		new maxXP = scxpm_calc_xp(get_pcvar_num(pcvar_maxlevel);
		if(newXP >= MAX_XP)
			newXP = MAX_XP;
		else if(newXP < 0)
				newXP = 0;
		xpAmt = newXP;
	}

	xp[id] = xpAmt;
	playerlevel[id] = scxpm_calc_lvl(xpAmt);
	scxpm_calcneedxp(id);

	return xp[id];
}

public _xpm_get_xp(plugin,params)
{
	if(params!=1)
	{
		log_error(AMX_ERR_PARAMS, "Missing or incorrect parameters");
		return -1;
	}

	new id = get_param(1);

	if(!id)
		return PLUGIN_CONTINUE;// ???

	return xp[id];
}

public plugin_cfg()
{
#if !defined USING_CS
	set_task( 1.0, "scxpm_reexp", 2147, _, _, "b" );
#endif

	if(get_cvar_num("sv_lan") > 0 && get_pcvar_num(pcvar_save_style))
		set_pcvar_num(pcvar_save_style, 1); // save by name on lan if saving is enabled

	// execute config file here? create XPM cfg forward to cache pcvars
	
	
	g_save_style = get_pcvar_num(pcvar_save_style);
	if(g_save_style)
	{
		g_save_bots = get_pcvar_num(pcvar_save_bots);
		g_savemethod = get_pcvar_num(pcvar_save_method);
		// load nvault
		if(!g_savemethod)
		{
			hVaultHandle = nvault_open(VAULT_NAME)
			if(hVaultHandle == INVALID_HANDLE)
			{
				new szText[128]
				formatex(szText, 127, "Error opening '%s' nVault.", VAULT_NAME)
				set_fail_state(szText)
			}
			
			new day = DAY_PRUNE
			if(day > 0)
				nvault_prune(hVaultHandle, 0, get_systime() - (DAY_PRUNE * 86400));
		}
		// else load sql
	}
	cache_pcvars();
}

cache_pcvars()
{
#if !defined USING_CS
	g_iMaxLvlUpOn = get_pcvar_num(pcvar_maxlevelup_enabled);
	g_iMaxLvlUpLimit = get_pcvar_num(pcvar_maxlevelup_limit);
	g_iMaxLvlUp = get_pcvar_num(pcvar_maxlevelup);
#endif
	g_maxlevel = get_pcvar_num(pcvar_maxlevel);
	g_fXPGain = get_pcvar_float(pcvar_xpgain);
}

public client_putinserver(id)
{
	if(is_user_hltv(id)) return;// do bot check later

	xp[id] = 0;

	if(g_save_style)
	{
		switch(g_save_style)
		{
			case 1:
			{
				get_user_name(id, szName[id], 34);
			}
			case 2:
			{
				get_user_authid(id, szName[id], 34);
			}
			case 3:
			{
				get_user_ip(id, szName[id], 34, 1);
			}
		}
		LoadData(id);
	}
	else
	{
		bIsLoaded[id] = true;
	}

	if (!is_user_bot(id))
	{
		// Set the custom HUD display task
		set_task(1.0, "ShowHUD", id+TASK_SHOWHUD, _, _, "b");// maybe setting this many tasks is bad? but seems possibly better than for loop because of HUD
	}

	new iLevel =  scxpm_calc_lvl(xp[id]);
	playerlevel[id] = iLevel;
	scxpm_calcneedxp(id);
	xpm_set_points(id, iLevel, true);
	set_player_level(id, iLevel, false);
}

// calculate needed xp for next level
public scxpm_calcneedxp ( id )
{
	new Float:m70 = float( playerlevel[id] ) * 70.0;
	new Float:mselfm3dot2 = float( playerlevel[id] ) * float( playerlevel[id] ) * 3.5;
	neededxp[id] = floatround( m70 + mselfm3dot2 + 30.0 );
}

// calculate level from xp
public scxpm_calc_lvl ( xp )
{
	return floatround( -10 + floatsqroot( 100 - ( 60 / 7 - ( ( xp - 1 ) / 3.5 ) ) ), floatround_ceil );
}

public scxpm_calc_xp ( level)
{
	level--;
	return floatround( (float( level ) * 70.0) + (float( level ) * float(level) * 3.5) + 30);
}

public check_player_level(id)
{
	new iNeedXp = neededxp[id];
	if( iNeedXp > 0 )
	{
		new iXP = xp[id];
		if(iXP >= iNeedXp)
		{
			new playerlevelOld = playerlevel[id];
			playerlevel[id] = scxpm_calc_lvl(iXP);

			new points = playerlevel[id] - playerlevelOld;
			xpm_set_points(id,points,true);// add to xp each time a player levels? - returns  xpm skillpoints
			set_player_level(id, playerlevel[id], false);// hmmm false? forward level change could be helpful or skill change..
			scxpm_calcneedxp(id);

			new name[64];
			get_user_name( id, name, 63 );

			if ( playerlevel[id] == g_maxlevel )
			{
				client_print(0,print_chat,"[SCXPM] Everyone say ^"Congratulations!!!^" to %s, who has reached Level %i!",name, g_maxlevel);
				log_amx("[SCXPM] Player %s reached level %i!", name, g_maxlevel );
			}
			else
			{
				client_print(id,print_chat,"[SCXPM] Congratulations, %s, you are now Level %i - Next Level: %i XP - Needed: %i XP",name,playerlevel[id],neededxp[id],neededxp[id]-xp[id])
				log_amx("[SCXPM] Player %s reached level %i!", name, playerlevel[id] );
			}
		}
	}
}


#if !defined USING_CS

// periodic calculations
/*public scxpm_sdac()
{
	scxpm_reexp();
//	scxpm_showdata();
}*/

public scxpm_reexp()
{
	new iPlayers[32], iNum;
	get_players( iPlayers, iNum );
	for( new g = 0; g < iNum; g++ )
	{
		new i=iPlayers[g];
		if ( is_user_connected(i) )
		{
//			new maxlvl = get_pcvar_num(pcvar_maxlevel);
//			g_maxlevel = get_pcvar_num(pcvar_maxlevel);
//			new maxlvlupon = get_pcvar_num(pcvar_maxlevelup_enabled);
//			new maxlvluplimit = get_pcvar_num(pcvar_maxlevelup_limit);
//			new maxlvlup = get_pcvar_num(pcvar_maxlevelup);
//			new Float:f_xpGain = get_pcvar_float(pcvar_xpgain);

			new plrlvl = playerlevel[i];

			if ( plrlvl >= g_maxlevel )
			{
//				xp[i] = 11500000;
				xp[i] = scxpm_calc_xp(g_maxlevel);
			}
			else
			{
				if(firstLvl[i] == 0)
				{
					firstLvl[i] = plrlvl;
				}

				if (g_iMaxLvlUpOn == 0 || playerlevel[i] <= g_iMaxLvlUpLimit || (playerlevel[i] - firstLvl[i]) < g_iMaxLvlUp)
				{
//					new Float:helpvar = float(xp[i])/5.0/f_xpGain+float(get_user_frags(i))-float(lastfrags[i]);
//					xp[i]=floatround(helpvar*5.0*f_xpGain);
					new Float:f_XP = float(xp[i]), Float:f_Frags = float(get_user_frags(i)), Float:f_LastFrags = float(lastfrags[i]), Float:f_NewXP;
					new Float:helpvar = f_XP/mysteryNumber/g_fXPGain+f_Frags-f_LastFrags;
					f_NewXP = helpvar*mysteryNumber*g_fXPGain;
					xp[i]=floatround(f_NewXP);
				}
				lastfrags[i] = get_user_frags(i);
				check_player_level(i);
			}
			// add HUD update here?
			
		}
	}
}

#else

public death()
{
	new killerId, victimId;
	killerId = read_data(1);
	victimId = read_data(2);

	if (killerId < 1 || victimId < 1 || !is_user_connected(killerId) || killerId == victimId)
	{
		if ( get_pcvar_num( pcvar_debug ) == 1 )
		{
			log_amx("[SCXPM DEBUG] Suicide or invalid killer/victim, dont award xp for kill");
		}
		return PLUGIN_HANDLED;
	}

	// cache maxlevel cvar here, why not for now? could get hectic
//	g_maxlevel = get_pcvar_num(pcvar_maxlevel);
	if ( playerlevel[killerId] < g_maxlevel )
	{
		scxpm_kill( killerId );
	}

	return PLUGIN_HANDLED;
}

public scxpm_kill( id )
{
//	xp[id] +=  floatround( mysteryNumber * g_fXPGain );
	new Float:f_NewXP = (mysteryNumber*g_fXPGain);
	xp[id] += floatround(f_NewXP);

	scxpm_calcneedxp(id);
	check_player_level(id);
}

#endif

// Show HUD Task
public ShowHUD(taskid)
{
	new player = ID_SHOWHUD

#if defined USING_CS
	// Player dead?
	if (!is_user_alive(player))
	{
		// Get spectating target
		player = pev(player, PEV_SPEC_TARGET)

		// Target not alive
		if (!is_user_alive(player))
			return;
	}

	// Spectating someone else?
	if (player != ID_SHOWHUD)
	{
		// Show name, health, class, and money
		set_hudmessage(255,255,255,HUD_SPECT_X,HUD_SPECT_Y,0,6.0,1.1,0.0,0.0,-1);
		ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync, "Exp.: %i / %i | Level: %i / %i | Health: %i | Armor: %i", xp[player],neededxp[player],playerlevel[player], get_pcvar_num(pcvar_maxlevel), get_user_health(player), get_user_armor(player) );
	}
	else
	{
		set_hudmessage(0,200,255,HUD_STATS_X,HUD_STATS_Y,0,6.0,1.1,0.0,0.0,-1);
		ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync, "Exp.: %i / %i | Level: %i / %i | Health: %i | Armor: %i", xp[ID_SHOWHUD],neededxp[ID_SHOWHUD],playerlevel[ID_SHOWHUD], get_pcvar_num(pcvar_maxlevel), get_user_health(ID_SHOWHUD), get_user_armor(ID_SHOWHUD));
	}
#else
	if (!is_user_alive(player))
	{
		return;
	}
	else
	{
		set_hudmessage(0,200,255,HUD_STATS_X,HUD_STATS_Y,0,6.0,1.1,0.0,0.0,-1);
		ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync, "Exp.: %i / %i | Level: %i / %i | Health: %i | Armor: %i", xp[ID_SHOWHUD],neededxp[ID_SHOWHUD],playerlevel[ID_SHOWHUD], get_pcvar_num(pcvar_maxlevel), get_user_health(ID_SHOWHUD), get_user_armor(ID_SHOWHUD));
	}
#endif
}


// level saving and loading (nvault and mysql)

public plugin_end()
{
	if(g_save_style)
	{
		if(!g_savemethod)
			nvault_close(hVaultHandle);
	}
}


#if AMXX_VERSION_NUM >= 183
public client_disconnected(id)
#else
public client_disconnect(id)
#endif
{
	if(g_save_style)
	{
		SaveData(id);
	}

	bIsLoaded[id] = false;
}

LoadData(id)
{
	if(is_user_hltv(id) || (!g_save_bots && is_user_bot(id))) return;
	new szKey[40]
	formatex(szKey, 39, "%sXPLvl", szName[id])

	new playerxp = nvault_get(hVaultHandle, szKey)
	xp[id] = playerxp;
	bIsLoaded[id] = true;
	log_amx("Loaded data for %s", szName[id]);
}

SaveData(id)
{
	if(is_user_hltv(id) || (!g_save_bots && is_user_bot(id))) return;
	if(!bIsLoaded[id]) return;

	new playerxp = xp[id];

	if(playerxp >= MAX_XP)
		playerxp = MAX_XP;// max data type limitations - save note

	new szXP[12], szKey[40];
	formatex(szKey, 39, "%sXPLvl", szName[id]);
	formatex(szXP, 11, "%d", playerxp);
	nvault_set(hVaultHandle, szKey, szXP);
	log_amx("Saved data for %s", szName[id]);
}