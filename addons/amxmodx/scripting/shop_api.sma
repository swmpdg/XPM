#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <hamsandwich>
#include <shop>

enum _:ItemData {
	Item_Id,
	Item_Name[32],
	Item_ShortName[32],
	Item_CvarEnabled,
	Item_CvarCost,
	Item_CvarTeam,
	Item_CvarDelay,
	Item_CvarResetOption,
	Item_CvarResetTime,
	Item_Plugin,
	Item_Callback_Allowed,
	Item_CvarData
};

enum _:CvarData {
	Cvar_Name[64],
	Cvar_Pointer
};

enum _:LastUseData {
	LastUse_Time,
	LastUse_Round
};

enum _:ResetData {
	Reset_Option,
	Reset_Time
};

new Array:gItemData;
new gItemCount;

new gCvarMenuTitle;
new gCvarChatTag;
new gCvarSpawnMenu;

new gForwardSelected;
new gForwardReset;
new gReturnFromForward;

new const gMenuRegisteredTitle[] = "shop_api_menu";

#define MAX_PLAYERS 32

new Array:gMenuItems[MAX_PLAYERS + 1];
new gMenuPage[MAX_PLAYERS + 1];

new Array:gLastUseData[MAX_PLAYERS + 1];
new Array:gResetData[MAX_PLAYERS + 1];

new gRoundNumber;
new gMaxPlayers;

new gMoneyPlugin;
new gMoneyFunctionGet = -1;
new gMoneyFunctionSet = -1;
new gMoneyFormatSingle[32] = "$%d";
new gMoneyFormatPlural[32] = "$%d";

#define TASK_ID(%1,%2) (%1 * MAX_PLAYERS + %2)

public plugin_init() {
	register_plugin("Shop API", "0.0.8", "Exolent");
	
	register_event("HLTV", "EventNewRound", "a", "1=0", "2=0");
	
	RegisterHam(Ham_Spawn, "player", "FwdPlayerSpawnPost", 1);
	RegisterHam(Ham_Killed, "player", "FwdPlayerKilledPost", 1);
	
	register_menu(gMenuRegisteredTitle, 1023, "MenuShop");
/*
	register_menucmd(register_menuid("select_skill"),MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0,"SCXPMSkillChoice");
	register_menucmd(register_menuid("select_increment"),MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6,"SCXPMIncrementChoice");
*/
	
	register_clcmd("say /shop", "CmdShop");
	
	gCvarMenuTitle = register_cvar("shop_menu_title", "Shop Menu^n\wYou have \y{$money}");
	gCvarChatTag = register_cvar("shop_chat_tag", "[SHOP]");
	gCvarSpawnMenu = register_cvar("shop_spawn_menu", "0");
	
	new data[ItemData];
	gItemData = ArrayCreate(ItemData);
	ArrayPushArray(gItemData, data); // empty holder so id's start at 1
	gItemCount++;
	
	gForwardSelected = CreateMultiForward("shop_item_selected", ET_STOP2 , FP_CELL, FP_CELL);
	gForwardReset    = CreateMultiForward("shop_item_reset"   , ET_IGNORE, FP_CELL, FP_CELL);
	
	gMaxPlayers = get_maxplayers();
	
	new lastUseData[LastUseData], resetData[ResetData];
	for(new i = 1; i <= gMaxPlayers; i++) {
		gMenuItems[i] = ArrayCreate(1);
		
		gLastUseData[i] = ArrayCreate(LastUseData);
		ArrayPushArray(gLastUseData[i], lastUseData); // empty holder so id's start at 1
		
		gResetData[i] = ArrayCreate(ResetData);
		ArrayPushArray(gResetData[i], resetData); // empty holder so id's start at 1
	}
	
	set_task(1.0, "TaskLoadConfigs");
}

public TaskLoadConfigs() {
	new configsDir[32];
	get_configsdir(configsDir, charsmax(configsDir));
	
	new fileShopGen[32], fileShop[32];
	formatex(fileShopGen, charsmax(fileShopGen), "%s/shop_gen.cfg", configsDir);
	formatex(fileShop, charsmax(fileShop), "%s/shop.cfg", configsDir);
	
	new f = fopen(fileShopGen, "wt");
	
	if(f) {
		fputs(f, "// This file is generated to list all cvars from shop items^n");
		fputs(f, "// If you try to edit this file, your changes will not be saved as this is generated every map^n");
		fputs(f, "// If you want to edit these cvars, then edit the shop.cfg file^n^n");
		
		new data[ItemData];
		new Array:cvars;
		new numCvars;
		new cvarData[CvarData];
		new value[128];
		
		for(new item = 1, i; item < gItemCount; item++) {
			ArrayGetArray(gItemData, item, data);
			
			fprintf(f, "// %s cvars^n// ==============================================================================================^n^n", data[Item_Name]);
			
			cvars = Array:data[Item_CvarData];
			numCvars = ArraySize(cvars);
			
			for(i = 0; i < numCvars; i++) {
				ArrayGetArray(cvars, i, cvarData);
				
				get_pcvar_string(cvarData[Cvar_Pointer], value, charsmax(value));
				
				fprintf(f, "%s ^"%s^"^n", cvarData[Cvar_Name], value);
			}
			
			fputs(f, numCvars ? "^n^n" : "^n");
		}
		
		fprintf(f, "exec %s^n", fileShop);
		
		fclose(f);
	}
	
	if(!file_exists(fileShop)) {
		new f = fopen(fileShop, "wt");
		
		if(f) {
			fputs(f, "// This file is generated only if it doesn't already exist^n");
			fputs(f, "// That means that there could be new cvars from plugins that you added that don't exist in here^n");
			fputs(f, "// In case you added any plugins or want to make sure, go to shop_gen.cfg and copy over any new cvars^n^n");
			
			new data[ItemData];
			new Array:cvars;
			new numCvars;
			new cvarData[CvarData];
			new value[128];
			
			for(new item = 1, i; item < gItemCount; item++) {
				ArrayGetArray(gItemData, item, data);
				
				fprintf(f, "// %s cvars^n// ==============================================================================================^n^n", data[Item_Name]);
				
				cvars = Array:data[Item_CvarData];
				numCvars = ArraySize(cvars);
				
				for(i = 0; i < numCvars; i++) {
					ArrayGetArray(cvars, i, cvarData);
					
					get_pcvar_string(cvarData[Cvar_Pointer], value, charsmax(value));
					
					fprintf(f, "%s ^"%s^"^n", cvarData[Cvar_Name], value);
				}
				
				fputs(f, numCvars ? "^n^n" : "^n");
			}
			
			fclose(f);
		}
	}
	
	server_cmd("exec %s", fileShopGen);
}

public plugin_natives() {
	register_library("shop");
	
	register_native("shop_add_item", "_shop_add_item");
	register_native("shop_show_menu", "_shop_show_menu");
	register_native("shop_override_money", "_shop_override_money");
	register_native("shop_print", "_shop_print");
	register_native("shop_item_register_cvar", "_shop_item_register_cvar");
}

public _shop_add_item(plugin, params) {
	if(!ValidParams(params, 8)) {
		return 0;
	}
	
	new data[ItemData];
	get_string(1, data[Item_Name], charsmax(data[Item_Name]));
	get_string(2, data[Item_ShortName], charsmax(data[Item_ShortName]));
	
	new cost = get_param(3);
	new team = get_param(4);
	
	data[Item_CvarData] = _:ArrayCreate(CvarData);
	
	data[Item_CvarEnabled] = item_register_cvar(data, "enabled", "1");
	
	new valueString[12];
	num_to_str(cost, valueString, charsmax(valueString));
	data[Item_CvarCost] = item_register_cvar(data, "cost", valueString);
	
	if(team && team != (SHOP_TEAM_T | SHOP_TEAM_CT | SHOP_TEAM_SPEC)) {
		new len;
		
		for(new i = 1; i <= 3; i++) {
			if(team & (1 << i)) {
				len += formatex(valueString[len], charsmax(valueString) - len, "%s%d", len ? "," : "", i);
			}
		}
		
		valueString[len] = EOS;
	} else {
		copy(valueString, charsmax(valueString), "0");
	}
	
	data[Item_CvarTeam] = item_register_cvar(data, "team", valueString);
	
	num_to_str(get_param(5), valueString, charsmax(valueString));
	data[Item_CvarDelay] = item_register_cvar(data, "delay", valueString);
	
	new callback[32];
	get_string(6, callback, charsmax(callback));
	
	if(callback[0]) {
		data[Item_Callback_Allowed] = get_func_id(callback, plugin);
		
		if(data[Item_Callback_Allowed] == -1) {
			log_error(AMX_ERR_GENERAL, "Invalid callback specified for allowed!");
			return 0;
		}
		
		data[Item_Plugin] = plugin;
	} else {
		data[Item_Callback_Allowed] = -1;
	}
	
	num_to_str(get_param(7), valueString, charsmax(valueString));
	data[Item_CvarResetOption] = item_register_cvar(data, "reset_option", valueString);
	
	num_to_str(get_param(8), valueString, charsmax(valueString));
	data[Item_CvarResetTime] = item_register_cvar(data, "reset_time", valueString);
	
	new lastUseData[LastUseData], resetData[ResetData];
	for(new i = 1; i <= gMaxPlayers; i++) {
		ArrayPushArray(gLastUseData[i], lastUseData);
		ArrayPushArray(gResetData[i], resetData);
	}
	
	new id = data[Item_Id] = gItemCount++;
	
	ArrayPushArray(gItemData, data);
	
	return id;
}

public _shop_show_menu(plugin, params) {
	if(!ValidParams(params, 1)) {
		return 0;
	}
	
	new id = get_param(1);
	
	if(id) {
		if(!is_user_connected(id)) {
			log_error(AMX_ERR_GENERAL, "Player id %d is not connected!", id);
			return 0;
		}
		
		ShowShopMenu(id);
	} else {
		new players[32], pnum;
		get_players(players, pnum, "ch");
		
		for(new i = 0; i < pnum; i++) {
			ShowShopMenu(players[i]);
		}
	}
	
	return 1;
}

public _shop_override_money(plugin, params) {
	if(!ValidParams(params, 4)) {
		return 0;
	}
	
	new callback[32];
	get_string(1, callback, charsmax(callback));
	
	if(callback[0]) {
		gMoneyFunctionGet = get_func_id(callback, plugin);
		
		if(gMoneyFunctionGet == -1) {
			log_error(AMX_ERR_GENERAL, "Invalid callback for ^"money get^" provided!");
			return 0;
		}
		
		get_string(2, callback, charsmax(callback));
		
		if(!callback[0] || (gMoneyFunctionSet = get_func_id(callback, plugin)) == -1) {
			log_error(AMX_ERR_GENERAL, "Invalid callback for ^"money set^" provided!");
			return 0;
		}
		
		gMoneyPlugin = plugin;
	}
	
	get_string(3, gMoneyFormatSingle, charsmax(gMoneyFormatSingle));
	get_string(4, gMoneyFormatPlural, charsmax(gMoneyFormatPlural));
	
	return 1;
}

public _shop_print(plugin, params) {
	if(!ValidParams(params, 2, false)) {
		return 0;
	}
	
	new id = get_param(1);
	
	if(id) {
		if(!is_user_connected(id)) {
			log_error(AMX_ERR_GENERAL, "Player %d is not connected", id);
			return 0;
		}
		
		new message[192];
		if(params > 2) {
			vdformat(message, charsmax(message), 2, 3);
		} else {
			get_string(2, message, charsmax(message));
		}
		
		client_print(id, print_chat, "%s %s", GetChatTag(), message);
	} else {
		new Array:langArgs;
		new numLangArgs, lang[64];
		
		if(params > 3) {
			for(new i = 3; i < params; i++) {
				if(get_param_byref(i) == LANG_PLAYER) {
					get_string(i + 1, lang, charsmax(lang));
					
					if(GetLangTransKey(lang) != TransKey_Bad) {
						if(!numLangArgs) {
							langArgs = ArrayCreate(1);
						}
						
						ArrayPushCell(langArgs, i++);
						numLangArgs++;
					}
				}
			}
		}
		
		if(numLangArgs) {
			new players[32], pnum, id;
			get_players(players, pnum, "ch");
			
			new message[192], len;
			len = formatex(message, charsmax(message), "%s ", GetChatTag());
			
			for(new i = 0, j; i < pnum; i++) {
				id = players[i];
				
				for(j = 0; j < numLangArgs; j++) {
					set_param_byref(ArrayGetCell(langArgs, j), id);
				}
				
				vdformat(message[len], charsmax(message) - len, 2, 3);
				
				client_print(id, print_chat, "%s", message);
			}
			
			ArrayDestroy(langArgs);
		} else {
			new message[192];
			if(params > 2) {
				vdformat(message, charsmax(message), 2, 3);
			} else {
				get_string(2, message, charsmax(message));
			}
			
			client_print(0, print_chat, "%s %s", GetChatTag(), message);
		}
	}
	
	return 1;
}

public _shop_item_register_cvar(plugin, params) {
	if(!ValidParams(params, 3, false)) {
		return 0;
	}
	
	new item = get_param(1);
	
	if(!(1 <= item < gItemCount)) {
		return 0;
	}
	
	new data[ItemData];
	ArrayGetArray(gItemData, item, data);
	
	new description[32];
	get_string(2, description, charsmax(description));
	
	new default_value[128];
	get_string(3, default_value, charsmax(default_value));
	
	new flags, Float:fvalue;
	
	if(params > 3) {
		flags = get_param(4);
		
		if(params > 4) {
			fvalue = get_param_f(5);
		}
	}
	
	return item_register_cvar(data, description, default_value, flags, fvalue);
}

item_register_cvar(data[ItemData], const description[], const default_value[], flags=0, Float:fvalue=0.0) {
	new cvarData[CvarData];
	formatex(cvarData[Cvar_Name], charsmax(cvarData[Cvar_Name]), "shop_item_%s_%s", data[Item_ShortName], description);
	
	cvarData[Cvar_Pointer] = register_cvar(cvarData[Cvar_Name], default_value, flags, fvalue)
	
	ArrayPushArray(Array:data[Item_CvarData], cvarData);
	
	return cvarData[Cvar_Pointer];
}

public client_disconnect(id) {
	CheckResets(id, SHOP_RESET_ALL);
}

public EventNewRound() {
	gRoundNumber++;
	
	for(new id = 1; id <= gMaxPlayers; id++) {
		CheckResets(id, SHOP_RESET_ROUND);
	}
}

CheckResets(id, option) {
	new resetData[ResetData];
	
	for(new i = 1; i < gItemCount; i++) {
		ArrayGetArray(gResetData[id], i, resetData);
		
		if(resetData[Reset_Option] & option) {
			ResetItem(id, i);
		}
	}
}

ResetItem(id, item) {
	ExecuteForward(gForwardReset, gReturnFromForward, item, id);
	
	new resetData[ResetData];
	ArraySetArray(gResetData[id], item, resetData);
	
	remove_task(TASK_ID(id, item));
}

public FwdPlayerSpawnPost(id) {
	if(is_user_alive(id)) {
		if(get_pcvar_num(gCvarSpawnMenu)) {
			ShowShopMenu(id);
		}
		
		CheckResets(id, SHOP_RESET_SPAWN);
	}
}

public FwdPlayerKilledPost(id, killer, shouldGib) {
	if(!is_user_alive(id)) {
		CheckResets(id, SHOP_RESET_DEATH);
	}
}

public CmdShop(id) {
	ShowShopMenu(id);
}

#define PERPAGE 7

ShowShopMenu(id, page = 0) {
	new menu[1024], len;
	new keys = MENU_KEY_0;
	
	new money = GetMoney(id);
	
	len = copy(menu, charsmax(menu), "\y");
	
	// grab custom title
	new titleLen = get_pcvar_string(gCvarMenuTitle, menu[len], charsmax(menu) - len);
	// fix new lines
	replace_all(menu, charsmax(menu), "^^n", "^n");
	// show money if in title
	replace_all(menu, charsmax(menu), "{$money}", FormatMoney(money));
	
	// 
	len = add(menu, charsmax(menu), "^n{$pageInfo}^n^n");
	
	new added = 0;
	
	new data[ItemData];
	new allowed;
	new cost;
	
	ArrayClear(gMenuItems[id]);
	
	new start = page * PERPAGE;
	gMenuPage[id] = page;
	
	new Array:itemsAllowed = ArrayCreate(1);
	
	for(new i = 1; i < gItemCount; i++) {
		ArrayGetArray(gItemData, i, data);
		
		allowed = GetAllowed(id, data);
		
		if(allowed == SHOP_ITEM_HIDDEN) continue;
		
		ArrayPushCell(gMenuItems[id], i);
		ArrayPushCell(itemsAllowed, allowed);
		
		added++;
	}
	
	if(!added) {
		client_print(id, print_chat, "* You cannot buy anything!");
		return;
	}
	
	// in case we're at a higher page than exists
	// go back to the last available page
	if(added <= start) {
		page = gMenuPage[id] = (added - 1) / PERPAGE;
		start = page * PERPAGE;
	}
	
	new stop = min(added, start + PERPAGE);
	
	for(new i = start; i < stop; i++) {
		ArrayGetArray(gItemData, ArrayGetCell(gMenuItems[id], i), data);
		
		allowed = ArrayGetCell(itemsAllowed, i);
		
		cost = GetCost(data);
		
		if(allowed == SHOP_ITEM_ENABLED && cost > money) {
			allowed = SHOP_ITEM_DISABLED;
		}
		
		if(allowed == SHOP_ITEM_ENABLED) {
			keys |= (1 << (i - start));
			len += formatex(menu[len], charsmax(menu) - len, cost ? "\r%d. \w%s \y%s^n" : "\r%d. \w%s^n", (i - start + 1), data[Item_Name], FormatMoney(cost));
		} else {
			len += formatex(menu[len], charsmax(menu) - len, cost ? "\d%d. %s \r%s^n" : "\d%d. %s^n", (i - start + 1), data[Item_Name], FormatMoney(cost));
		}
	}
	
	ArrayDestroy(itemsAllowed);
	
	len += copy(menu[len], charsmax(menu) - len, "^n");
	
	new pageInfo[32];
	
	if(start > 0 || stop < added) {
		if(start > 0) {
			keys |= MENU_KEY_8;
			len += copy(menu[len], charsmax(menu) - len, "\r8. \wBack^n");
		}
		if(stop < added) {
			keys |= MENU_KEY_9;
			len += copy(menu[len], charsmax(menu) - len, "\r9. \wNext^n");
		}
		
		len += copy(menu[len], charsmax(menu) - len, "^n\r0. \wExit");
		
		new pages = (added - 1) / PERPAGE + 1;
		formatex(pageInfo, charsmax(pageInfo), "(Page %d/%d)", gMenuPage[id], pages);
	}
	
	copy(menu[len], charsmax(menu) - len, "\r0. \wExit");
	replace(menu[titleLen], charsmax(menu) - titleLen, "{$pageInfo}", pageInfo);
	
	show_menu(id, keys, menu, .title = gMenuRegisteredTitle);
}

public MenuShop(id, key) {
	switch(++key % 10) {
		case 8: gMenuPage[id] = max(0, --gMenuPage[id]);
		case 9: gMenuPage[id] = min(ArraySize(gMenuItems[id]) / PERPAGE, ++gMenuPage[id]);
		case 0: return PLUGIN_HANDLED;
		default: {
			new item = gMenuPage[id] * PERPAGE + key - 1;
			new i = ArrayGetCell(gMenuItems[id], item);
			
			new data[ItemData];
			ArrayGetArray(gItemData, i, data);
			
			if(GetAllowed(id, data) == SHOP_ITEM_ENABLED) {
				new cost = GetCost(data);
				
				new money = GetMoney(id);
				if(0 <= cost <= money) {
					ExecuteForward(gForwardSelected, gReturnFromForward, i, id);
					
					if(gReturnFromForward != PLUGIN_CONTINUE) {
						new lastUseData[LastUseData];
						lastUseData[LastUse_Time ] = _:get_gametime();
						lastUseData[LastUse_Round] = gRoundNumber;
						
						ArraySetArray(gLastUseData[id], i, lastUseData);
						
						new resetData[ResetData];
						resetData[Reset_Option] = GetResetOption(data[Item_CvarResetOption]);
						resetData[Reset_Time  ] = get_pcvar_num(data[Item_CvarResetTime]);
						
						ArraySetArray(gResetData[id], i, resetData);
						
						if(resetData[Reset_Time] > 0) {
							new params[1];
							params[0] = i;
							set_task(float(resetData[Reset_Time]), "TaskResetItem", TASK_ID(id, i), params, sizeof(params));
						}
						
						if(cost != SHOP_COST_NONE) {
							SetMoney(id, money - cost);
							
							client_print(id, print_chat, "%s You bought %s for %s!", GetChatTag(), data[Item_Name], FormatMoney(cost));
						} else {
							client_print(id, print_chat, "%s You chose %s!", GetChatTag(), data[Item_Name]);
						}
					}
				}
			}
		}
	}
	
	ShowShopMenu(id, gMenuPage[id]);
	
	return PLUGIN_HANDLED;
}

public TaskResetItem(params[], taskID) {
	// taskID = (id * MAX_PLAYERS + item)
	// id = (taskID - item) / MAX_PLAYERS
	
	new item = params[0];
	new id = (taskID - item) / MAX_PLAYERS;
	
	ResetItem(id, item);
}

bool:ValidParams(params, expected, bool:exact = true) {
	if(exact ? (params != expected) : (params < expected)) {
		log_error(AMX_ERR_PARAMS, "Invalid params given (%d). Expected %d.", params, expected);
		return false;
	}
	return true;
}

GetAllowed(id, data[ItemData]) {
	if(!get_pcvar_num(data[Item_CvarEnabled])) {
		return SHOP_ITEM_HIDDEN;
	}
	
	new teams = GetTeams(data[Item_CvarTeam]);
	
	if(teams && !(teams & (1 << (_:cs_get_user_team(id))))) {
		return SHOP_ITEM_HIDDEN;
	}
	
	new allowed = SHOP_ITEM_ENABLED;
	
	new callback = data[Item_Callback_Allowed];
	if(callback != -1) {
		callfunc_begin_i(callback, data[Item_Plugin]);
		callfunc_push_int(data[Item_Id]);
		callfunc_push_int(id);
		allowed = callfunc_end();
	}
	
	if(allowed == SHOP_ITEM_ENABLED) {
		new delay = get_pcvar_num(data[Item_CvarDelay]);
		
		if(delay != SHOP_DELAY_NONE) {
			new lastUseData[LastUseData];
			ArrayGetArray(gLastUseData[id], data[Item_Id], lastUseData);
			
			if(delay == SHOP_DELAY_ROUND) {
				if(lastUseData[LastUse_Round] >= gRoundNumber) {
					return SHOP_ITEM_DISABLED;
				}
			} else {
				if((Float:lastUseData[LastUse_Time] + delay) > get_gametime()) {
					return SHOP_ITEM_DISABLED;
				}
			}
		}
	}
	
	return allowed;
}

GetTeams(pcvar) {
	new teamString[6];
	get_pcvar_string(pcvar, teamString, charsmax(teamString));
	
	new team = SHOP_TEAM_ALL;
	
	if(contain(teamString, "1") >= 0) {
		team |= SHOP_TEAM_T;
	}
	if(contain(teamString, "2") >= 0) {
		team |= SHOP_TEAM_CT;
	}
	if(contain(teamString, "3") >= 0) {
		team |= SHOP_TEAM_SPEC;
	}
	
	if(team == (SHOP_TEAM_T | SHOP_TEAM_CT | SHOP_TEAM_SPEC)) {
		team = SHOP_TEAM_ALL;
		
		set_pcvar_string(pcvar, "0");
	}
	
	return team;
}

GetCost(data[ItemData]) {
	return get_pcvar_num(data[Item_CvarCost]);
}

GetChatTag() {
	static tag[16];
	get_pcvar_string(gCvarChatTag, tag, charsmax(tag));
	
	return tag;
}

GetMoney(id) {
	if(gMoneyFunctionGet == -1) {
		return cs_get_user_money(id);
	}
	
	callfunc_begin_i(gMoneyFunctionGet, gMoneyPlugin);
	callfunc_push_int(id);
	return callfunc_end();
}

SetMoney(id, value) {
	if(gMoneyFunctionSet == -1) {
		cs_set_user_money(id, value);
	} else {
		callfunc_begin_i(gMoneyFunctionSet, gMoneyPlugin);
		callfunc_push_int(id);
		callfunc_push_int(value);
		callfunc_end();
	}
}

FormatMoney(value) {
	new output[32];
	copy(output, charsmax(output), (value == 1) ? gMoneyFormatSingle : gMoneyFormatPlural);
	
	new valueString[12];
	num_to_str(value, valueString, charsmax(valueString));
	
	replace_all(output, charsmax(output), "%d", valueString);
	
	return output;
}

GetResetOption(cvar) {
	new value[12];
	get_pcvar_string(cvar, value, charsmax(value));
	
	new options = SHOP_RESET_TIMEONLY;
	
	if(containi(value, "death") >= 0) {
		options |= SHOP_RESET_DEATH;
	}
	if(containi(value, "round") >= 0) {
		options |= SHOP_RESET_ROUND;
	}
	if(containi(value, "spawn") >= 0) {
		options |= SHOP_RESET_SPAWN;
	}
	
	return options;
}
