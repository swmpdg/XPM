#if defined _debug_helper_included
	#endinput
#endif
#define _debug_helper_included

#include < amxmodx >
#include < amxmisc >

/**
 * This file can be used across multiple plugins to load constant data.
 * Some of these implementations of constants will be moved to a dictionary file. 
 */

///
stock bool:dbg_log = false;

stock pcvar_debug;
stock g_debug;

stock debug_log(debug_level, const fmt[], ...)
{
	if(dbg_log && debug_level)
	{
		static szFormattedText[512];
		vformat( szFormattedText, 511, fmt, 3 );

		log_amx( szFormattedText );
	}
}

stock client_debug_msg(debug_level, id, const fmt[], ...)
{
	if(dbg_log && debug_level)
	{
		if(!is_user_connected(id) || is_user_bot(id))
			return;
		static szFormattedText[512];
		vformat( szFormattedText, 511, fmt, 3 );

		client_print(id, print_chat, "%s", szFormattedText );
	}
}

stock register_debug_cvar(const cvarName[], const cvarValue[])
{
	pcvar_debug = register_cvar(cvarName, cvarValue);
	g_debug = get_pcvar_num(pcvar_debug);
}

// logging with AMXX Error Codes
stock debug_log_error(debug_level, ERR_CODE, const fmt[], ...)
{
	if(dbg_log && debug_level)
	{
		switch(ERR_CODE)
		{
			case 0, 3, 4, 5, 7, 8, 10, 11, 19, 25, 27:
			{
				static szFormattedText[512];
				vformat( szFormattedText, 511, fmt, 3 );
				log_error(ERR_CODE, szFormattedText );
				return;
			}
			default:
			{
				log_error(AMX_ERR_PARAMS,"Undefined AMXX Error Code %i", ERR_CODE);
			}
		}
	}
}

stock set_debug_logging(bool:isEnabled)
{
	if(isEnabled)
	{
		dbg_log = true;
		g_debug = get_pcvar_num(pcvar_debug);
		debug_log(g_debug, "Debug Helper logging enabled");
	}
	else
	{
		dbg_log = false;
		debug_log(g_debug, "Debug Helper logging disabled");
	}
}

stock log_bad_params()
{
	log_error(AMX_ERR_PARAMS, "Missing or incorrect parameters");
}

forward debug_set(bool:debug_enabled);