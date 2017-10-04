#include <amxmodx>
#include <fun>
#include <xpm>
//#include <xpm_hp_ap>
#include <xpm_skill_factors>
#include <debug_helper>

#define USING_CS
//#define USING_SVEN

#if defined USING_CS
//#include <cstrike>
#endif

#if defined USING_SVEN
#include <svencoop_const>
#endif

#define TOTAL_LEVELS 1

#define MAX_SKILL_LEVEL 30

#define AMMO_TASKID 1922

/*
/// limit for health, used as a cap for player regeneration rate with the health regeneration skill. Once this limit is reached with a counter, it resets.
	hrate=register_cvar("scxpm_hprlimit","380.0");
/// Same as scxpm_hprlimit, except for nano armor. may want to raise limit for armor and make it much harder for regular skill by itself
	nrate=register_cvar("scxpm_arlimit","380.0");
/// Same as scxpm_hprlimit, except ammo reincarnation
	arate=register_cvar("scxpm_amrate","1000.0");
*/

new bool:g_bHasSkill[33];
new g_iSkillLevel[33];

new gSkillID[TOTAL_LEVELS];

new const gSkillName[TOTAL_LEVELS][] =
{
	"+5 Ammo Reincarnation"
};

new const gSkillCvar[TOTAL_LEVELS][] =
{
	"ammoregen"
};

new const gSkillCost[TOTAL_LEVELS] =
{
	5,
};

new gRequiredLevel[TOTAL_LEVELS];// make required level for each skill cost (i.e. level 5-24 only can use +5 strength at a time, 25-99 can use +25, etc)

// for get_players
new iNum, iPlayers[32];
// regen rates
new regenRate[33], regenCount[33];
new pcvar_regen_limit, g_iRegenLimit;

public plugin_init()
{
	register_plugin("Test Ammo Regeneration", "1.0.0a", "swampdog@modriot.com");

	// is it more efficient just to use forwards, or just use a hook with hamsandwich?

	for (new i = 0; i < TOTAL_LEVELS; i++)
	{
		gRequiredLevel[i] = gSkillCost[i];
		gSkillID[i] = register_skill(gSkillName[i],gSkillCvar[i],gSkillCost[i],_,_,"AmmoRegenCallback",0,0);
		set_skill_info(gSkillID[i], gRequiredLevel[i], MAX_SKILL_LEVEL, "Regeneration of ammo", "Ammo Reincarnation");
	}
	pcvar_regen_limit = register_cvar("xpm_ammoregen_limit","1000");
}

public plugin_cfg()
{
	set_task(1.0,"ammoRegenTask",AMMO_TASKID,_,_,"b");
	g_iRegenLimit = get_pcvar_num(pcvar_regen_limit);
}

public ammoRegenTask()
{
	// only alive and no hltv
	get_players(iPlayers, iNum, "ah");

	for(new i = 0; i < iNum+1; i++)
	{
		new j = iPlayers[i];

		if(!g_bHasSkill[j])
			continue;

		if(is_user_alive(j))
		{
			if(regenCount[j] < g_iRegenLimit)
			{
				regenCount[j] += regenRate[j];
				continue;
			}
			else
			{
				// add different mod weapon and ammo here
#if defined USING_CS
				cs_only_weapon(j);
#endif
#if defined USING_SVEN
				sc_only_weapon(j);
#endif
				regenCount[j] = regenRate[j];
				continue;
			}
		}
	}
}

public skill_factor_init(id, factorLevel, factorIndex)
{
	set_skill_factor(id, factorLevel, factorIndex);

	if(g_bHasSkill[id])
		set_ammo_regen_rate(id);
}

/// team power formula for distance range: (team_power_level * 10) + awareness + medals + (prestige * prestige_multiplier)
set_ammo_regen_rate(id)
{
	regenRate[id] = g_iSkillLevel[id] + g_iFactorLevel[id][SKILL_AWARE] + g_iFactorLevel[id][SKILL_MEDAL] + (g_iFactorLevel[id][SKILL_PRESTIGE] * 10);
	if(regenCount[id] < regenRate[id])
		regenCount[id] = regenRate[id];
}

public skill_init(id, skillIndex, mode)
{
	for(new i = 0; i < TOTAL_LEVELS; i++)
	{
		if(gSkillID[i] == skillIndex)
		{
			if(mode)
				g_bHasSkill[id] = true;
			else
			{
				g_bHasSkill[id] = false;
				g_iSkillLevel[id] = 0;
				regenRate[id] = 0;
				regenCount[id] = 0;
			}
			break;
		}
	}
}

public AmmoRegenCallback(id, item)
{
	for(new i = 0; i < TOTAL_LEVELS; i++)
	{
		if(gSkillID[i] == item)
		{
			g_bHasSkill[id] = true;
			new skillCost = gSkillCost[i];
			g_iSkillLevel[id]+=skillCost;

			set_ammo_regen_rate(id);

			for(new j = 0; j < TOTAL_LEVELS; j++)
			{
				set_skill_level(id,gSkillID[j],g_iSkillLevel[id],false);// sync all the separate skills loaded with this value, so they all match
			}
			break;
		}
	}
}

public debug_set(bool:debug_enabled)
{
	if(!pcvar_debug)
		register_debug_cvar("xpm_ammoregen_debug", "0");// add cvar to debug_helper.cfg to have it loaded with the cfg
	set_debug_logging(debug_enabled);
	return;
}

// id is player index, amount = amount of times for give_item to run in a while loop, type[] = ammo type
stock giveThisMany(id, amount, const type[])
{
	if(amount < 1)
		return;
	new i = 0;
	while(i < amount)
	{
		give_item(id,type);
		i++;
	}
//	return PLUGIN_HANDLED;
}

// svencoop
stock get_ammotype(wpn_index)
{
	new ammotype;
	switch(wpn_index)
	{
		case WEAPON_SHOTGUN: ammotype = SHOTSHELLS;
		case WEAPON_MINIGUN, WEAPON_M249, WEAPON_M16: ammotype = CLIP556;
		case WEAPON_RPG: ammotype = ROCKET;
		case WEAPON_9MMHANDGUN, WEAPON_9MMAR, WEAPON_UZIAKIMBO, WEAPON_UZI: ammotype = CLIP9MM;
		case WEAPON_357, WEAPON_EAGLE: ammotype = MAG357;
		case WEAPON_CROSSBOW: ammotype = CLIPCB;
		case WEAPON_SNIPERRIFLE: ammotype = CLIP762;
		case WEAPON_SPORELAUNCHER: ammotype = SPORES;
		case WEAPON_GAUSS, WEAPON_EGON, WEAPON_DISPLACER: ammotype = CLIPGAUSS;
		case WEAPON_SHOCKRIFLE, WEAPON_CROWBAR_ELECTRIC: ammotype = BATTERY;
		case WEAPON_MEDKIT: ammotype = HEALTHKIT;
		case WEAPON_HORNETGUN: ammotype = HORNETS;
		case WEAPON_TRIPMINE: ammotype = TRIPMINE;
		case WEAPON_HANDGRENADE: ammotype = HANDGREN;
		case WEAPON_SATCHEL: ammotype = SATCHEL;
		case WEAPON_SNARK: ammotype = SNARKS;
		default: ammotype = 0;// for weapons which don't need ammo? - might need something else set here
	}
	return ammotype;
}

#if defined USING_CS

stock const ammotype[7][] =
{
	"ammo_9mm",
	"ammo_50ae",
	"ammo_buckshot",
	"ammo_57mm",
	"ammo_45acp",
	"ammo_556nato",
	"ammo_9mm"
};

stock scxpm_randomammo(id)
{
	new number=random_num(0,6);
	give_item(id,ammotype[number]);
}

#endif

#if defined USING_SVEN



// add weapon index
stock scxpm_randomammo(id)
{
	new number=random_num(0,6);
	new clip,ammo;
	if(number==0)
	{
		get_user_ammo(id,WEAPON_9MMHANDGUN,clip,ammo);
		if(ammo<SC_9MM_MAX)
			giveThisMany(id, 2, scammotype[CLIP9MM]);
		else
			number=1;
	}
	if(number==1)
	{
		get_user_ammo(id,WEAPON_357,clip,ammo);
		if(ammo<SC_357_MAX)
			giveThisMany(id, 3, scammotype[MAG357]);
		else
			number=2;
	}
	if(number==2)
	{
		get_user_ammo(id,WEAPON_SHOTGUN,clip,ammo);
		if(ammo<SC_BS_MAX)
			giveThisMany(id, 3, scammotype[SHOTSHELLS]);
		else
			number=3;
	}
	if(number==3)
	{
		get_user_ammo(id,WEAPON_GAUSS,clip,ammo);
		if(ammo<SC_GC_MAX)
			giveThisMany(id, 2, scammotype[CLIPGAUSS]);
		else
			number=4;
	}
	if(number==4)
	{
		get_user_ammo(id,WEAPON_CROSSBOW,clip,ammo);
		if(ammo<SC_CB_MAX)
			giveThisMany(id, 2, scammotype[CLIPCB]);
		else
			number=5;
	}
	if(number==5)
	{
		get_user_ammo(id,WEAPON_RPG,clip,ammo);
		if(ammo<SC_RPG_MAX)
			giveThisMany(id, 1, scammotype[ROCKET]);
		else
			number=6;
	}
	if(number==6)
	{
		get_user_ammo(id,WEAPON_SNIPERRIFLE,clip,ammo);
		if(ammo<SC_762_MAX)
		{
			giveThisMany(id, 2, scammotype[CLIP762]);
			giveThisMany(id, 2, scammotype[CLIP556]);
			giveThisMany(id, 5, scammotype[SPORES]);
		}
	}
}
#endif

stock sc_only_weapon(id)
{
	new clip,ammo;
	new weaponIndex = get_user_weapon(id,clip,ammo);// this will need to be changed for weapons which do not have ammo?
	GenericAmmo(id,weaponIndex,clip,ammo);
}


stock cs_only_weapon(id)
{
	new clip,ammo;
	switch(get_user_weapon(id,clip,ammo))
	{
		case 1: /* P228 */
		{
			get_user_ammo(id,21,clip,ammo);
			if(ammo<g_iSkillLevel[id]+13)
			{
				give_item(id,"ammo_357sig");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 3: /* SCOUT */
		{
			get_user_ammo(id,3,clip,ammo);
			if(ammo<20)
			{
				give_item(id,"ammo_762nato");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 4: /* HEGRENADE */
		{
			scxpm_randomammo(id);
		}
		case 5: /* XM1014 */
		{
			get_user_ammo(id,5,clip,ammo);
			if(ammo<21)
			{
				give_item(id,"ammo_buckshot");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 6: /* C4 */
		{
			scxpm_randomammo(id);
		}
		case 7: /* MAC10 */
		{
			get_user_ammo(id,7,clip,ammo);
			if(ammo<60+g_iSkillLevel[id])
			{
				give_item(id,"ammo_45acp");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 8: /* AUG */
		{
			get_user_ammo(id,8,clip,ammo);
			if(ammo<60+g_iSkillLevel[id])
			{
				give_item(id,"ammo_556nato");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 9: /* SMOKEGRENADE */
		{
			scxpm_randomammo(id);
		}
		case 10: /* ELITES */
		{
			get_user_ammo(id,10,clip,ammo);
			if(ammo<100)
			{
				give_item(id,"ammo_9mm");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 11: /* FIVESEVEN */
		{
			get_user_ammo(id,11,clip,ammo);
			if(ammo<60+g_iSkillLevel[id])
			{
				give_item(id,"ammo_57mm");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 12: /* UMP45 */
		{
			get_user_ammo(id,12,clip,ammo);
			if (ammo<60+g_iSkillLevel[id])
			{
				give_item(id,"ammo_45acp");
				give_item(id,"ammo_45acp");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 13: /* SG550 */
		{
			get_user_ammo(id,13,clip,ammo);
			if (ammo<60+g_iSkillLevel[id])
			{
				give_item(id,"ammo_556nato");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 14: /* GALIL */ 
		{
			get_user_ammo(id,14,clip,ammo);
			if (ammo<60+g_iSkillLevel[id])
			{
				give_item(id,"ammo_556nato");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 15: /* FAMAS */ 
		{
			get_user_ammo(id,15,clip,ammo);
			if (ammo<60+g_iSkillLevel[id])
			{
				give_item(id,"ammo_556nato");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 16: /* USP */
		{
			get_user_ammo(id,16,clip,ammo);
			if(ammo<250)
			{
				give_item(id,"ammo_45acp");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 17: /* GLOCK18 */
		{
			get_user_ammo(id,17,clip,ammo);
			if(ammo<60+g_iSkillLevel[id])
			{
				give_item(id,"ammo_9mm");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 18: /* AWP */
		{
			get_user_ammo(id,18,clip,ammo);
			if(ammo<20)
			{
				give_item(id,"ammo_338magnum");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 19: /* MP5NAVY */
		{
			get_user_ammo(id,19,clip,ammo);
			if(ammo<60+g_iSkillLevel[id])
			{
				give_item(id,"ammo_9mm");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 20: /* M249 */
		{
			get_user_ammo(id,20,clip,ammo);
			if(ammo<100+g_iSkillLevel[id])
			{
				give_item(id,"ammo_556natobox");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 21: /* M3 */
		{
			get_user_ammo(id,21,clip,ammo);
			if(ammo<24)
			{
				give_item(id,"ammo_buckshot");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 22: /* M4A1 */
		{
			get_user_ammo(id,22,clip,ammo);
			if(ammo<60+g_iSkillLevel[id])
			{
				give_item(id,"ammo_556nato");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 23: /* TMP */
		{
			// can go up to 120...
			get_user_ammo(id,23,clip,ammo);
			if(ammo<60+g_iSkillLevel[id])
			{
				give_item(id,"ammo_9mm");
				give_item(id,"ammo_9mm");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 24: /* G3SG1 */
		{
			get_user_ammo(id,24,clip,ammo);
			if(ammo<60+g_iSkillLevel[id])
			{
				give_item(id,"ammo_762nato");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 25: /* FLASHBANG */
		{
			scxpm_randomammo(id);
		}
		case 26: /* DEAGLE */
		{
			get_user_ammo(id,26,clip,ammo);
			if(ammo<21)
			{
				give_item(id,"ammo_50ae");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 27: /* SG552 */
		{
			get_user_ammo(id,27,clip,ammo);
			if(ammo<60+g_iSkillLevel[id])
			{
				give_item(id,"ammo_556nato");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
		case 28: /* AK47 */
		{
			get_user_ammo(id,27,clip,ammo);
			if (ammo<60+g_iSkillLevel[id])
			{
				give_item(id,"ammo_762nato");
			}
			else
			{
				scxpm_randomammo(id);
			}
			
		}
		case 29: /* KNIFE */
		{
			scxpm_randomammo(id);
		}
		case 30: /* P90 */
		{
			get_user_ammo(id,30,clip,ammo);
			if (ammo<60+g_iSkillLevel[id])
			{
				give_item(id,"ammo_57mm");
			}
			else
			{
				scxpm_randomammo(id);
			}
		}
	}	
}

