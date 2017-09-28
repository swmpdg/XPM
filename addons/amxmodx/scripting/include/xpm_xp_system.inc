#if defined _xpm_xp_system_included
	#endinput
#endif

/**
 * XPM Natives - designed by Swamp Dog @ ModRiot.com, 2016-2017
 * For use across plugins as a library
 */

#define _xpm_xp_system_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib xpm_xp_system
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib xpm_xp_system
	#endif
#else
	#pragma library xpm_xp_system
#endif

/**
Half-Life Experience Mod (XPM) API native and stock functions
By Swamp Dog @ ModRiot.com
August 26, 2016
*/

//  returns new xp after set?
native xpm_set_xp(id, amount, bool:addToXP=false);

//  returns current xp
native xpm_get_xp(id);
