#if defined _xpm_hp_ap_included
	#endinput
#endif

/**
 * XPM Natives - designed by Swamp Dog @ ModRiot.com, 2016-2017
 * For use across plugins as a library
 */

#define _xpm_hp_ap_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib xpm_hp_ap
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib xpm_hp_ap
	#endif
#else
	#pragma library xpm_hp_ap
#endif

/**
Half-Life Experience Mod (XPM) API native and stock functions
By Swamp Dog @ ModRiot.com
August 26, 2016
Last updated September 20, 2017
*/

native set_start_health(id, start_health, addToHP=0);
native get_start_health(id);
native set_max_health(id, max_hp, addToHP=0);
native get_max_health(id);

native set_start_armor(id, start_armor, addToAP=0);
native get_start_armor(id);
native set_max_armor(id, max_hp, addToAP=0);
native get_max_armor(id);

//native get_sv_start_health();
//native get_sv_start_armor();
native get_sv_max_health();
native get_sv_max_armor();

forward xpm_spawn(id);
forward xpm_die(id);

