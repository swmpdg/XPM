#if defined _xpm_distance_included
	#endinput
#endif

/**
 * XPM Natives - designed by Swamp Dog @ ModRiot.com, 2016-2017
 * For use across plugins as a library
 */

#define _xpm_distance_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib xpm_distance
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib xpm_distance
	#endif
#else
	#pragma library xpm_distance
#endif

/**
Half-Life Experience Mod (XPM) API native and stock functions
By Swamp Dog @ ModRiot.com
August 26, 2016
*/

/// Change player's range to see if they are nearby team mates
native set_player_range(id, value, addToRange=0);

/// Checked every "xpm_distance_time" seconds (default 5.0 ?) - returns 1 if players are nearby and 0 if not. Team specific cvar can be disabled or enabled.
native is_team_near(player_id1, player_id2);

native is_enemy_near(player_id1, player_id2);
