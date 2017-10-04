#include <amxmodx>
#include <fun>
#include <xpm>
#include <xpm_hp_ap>
#include <xpm_skill_factors>
#include <debug_helper>

#define TOTAL_LEVELS 1

#define MAX_SKILL_LEVEL 90

#define BLOCK_TASKID 1867

new bool:g_bHasSkill[33];
new g_iSkillLevel[33];

new gSkillID[TOTAL_LEVELS];

new const gSkillName[TOTAL_LEVELS][] =
{
	"+5 Block Attack"
};

new const gSkillCvar[TOTAL_LEVELS][] =
{
	"block5"
};

new const gSkillCost[TOTAL_LEVELS] =
{
	5,
};

new gRequiredLevel[TOTAL_LEVELS];// make required level for each skill cost (i.e. level 5-24 only can use +5 strength at a time, 25-99 can use +25, etc)

// for get_players
new iNum, iPlayers[32];
// regen rates
new blockRate[33], letBlock[33], evade[33];
new pcvar_let_block, g_iLetBlock, pcvar_block_limit, g_iBlockLimit;

public max_health(id,healthNum)
{
	g_iMaxHealth[id] = healthNum;
}

public plugin_init()
{
	register_plugin("Test Block Attack", "1.0.0a", "swampdog@modriot.com");

	for (new i = 0; i < TOTAL_LEVELS; i++)
	{
		gRequiredLevel[i] = gSkillCost[i];
		gSkillID[i] = register_skill(gSkillName[i],gSkillCvar[i],gSkillCost[i],_,_,"BlockAttackCallback",0,0);
		set_skill_info(gSkillID[i], gRequiredLevel[i], MAX_SKILL_LEVEL, "Random chance to block attacks, based on luck", "Block Attack");
	}
/// adding block limit cvar, for random_num(0,blocklimit+maxdodge[id]); if (random_num(0,blocklimit+maxdodge[id]) > blocklimit, give block attack
	pcvar_block_limit = register_cvar("xpm_blocklimit","250");
/// could possibly use the blocklimit above as a countdown...use medals and awareness?..or just medals?
	pcvar_let_block = register_cvar("xpm_letblock","90");

	g_iBlockLimit = get_pcvar_num(pcvar_block_limit);
	g_iLetBlock = get_pcvar_num(pcvar_let_block);
}

public plugin_cfg()
{
	set_task(1.0,"blockAttackTask",BLOCK_TASKID,_,_,"b");
	g_iLetBlock=get_pcvar_num(pcvar_let_block);
}

public blockAttackTask()
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
			BlockAttack(j);
			if(g_debug)
				client_print(j, print_chat, "Random chance to block attack");
		}
	}
}

public skill_factor_init(id, factorLevel, factorIndex)
{
	set_skill_factor(id, factorLevel, factorIndex);

	if(g_bHasSkill[id])
		set_evade(id);
}

set_evade(id)
{
	blockRate[id] = g_iSkillLevel[id] + g_iFactorLevel[id][SKILL_AWARE] + g_iFactorLevel[id][SKILL_MEDAL] + (g_iFactorLevel[id][SKILL_PRESTIGE] * 10);
	if(letBlock[id] < g_iLetBlock)
		letBlock[id] = g_iLetBlock;
	evade[id] = blockRate[id]+g_iLetBlock;
}

stock handle_evade(id,iSkill,iLimit)
{
	client_print(id, print_chat, "handle_evade");
	new swift = random_num(0,iSkill+iLimit);
	if(g_debug)
		client_print(id, print_chat, "swift: %i, iLimit: %i, iSkill: %i", swift, iLimit, iSkill);
	if(swift>iLimit)
	{
		godmode_on(id);
		letBlock[id]=g_iLetBlock;
		if(g_debug)
			client_print(id, print_chat, "evade successful");
	}
}

BlockAttack(id)
{
	if(!get_user_godmode(id)&&get_user_health(id)<g_iMaxHealth[id])
	{
		if(letBlock[id] > 0)
		{
			letBlock[id]-=g_iSkillLevel[id];
			if(g_debug)
				client_print(id, print_chat, "letBlock[id] = %i",letBlock[id]);
		}
		else
			handle_evade(id,evade[id],g_iBlockLimit);
	}
	else if(g_debug)
	{
		client_print(id, print_chat, "Block Attack: player has godmode or max health");
	}
}
godmode_on(id)
{
	if(is_user_connected(id)&&is_user_alive(id))
	{
		set_user_godmode(id,1);
		new gid[1];
		gid[0] = id;
		set_task(0.5,"godmode_off",BLOCK_TASKID+id,gid,1);
	}
}
public godmode_off(gid[])
{
	new oid = gid[0];
	if(is_user_alive(oid))
		set_user_godmode(oid);
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
				letBlock[id] = 0;
				blockRate[id] = 0;
				evade[id] = 0;
			}
			break;
		}
	}
}

public BlockAttackCallback(id, item)
{
	for(new i = 0; i < TOTAL_LEVELS; i++)
	{
		if(gSkillID[i] == item)
		{
			g_bHasSkill[id] = true;
			new skillCost = gSkillCost[i];
			g_iSkillLevel[id]+=skillCost;

			set_evade(id);

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
		register_debug_cvar("xpm_block_debug", "0");// add cvar to debug_helper.cfg to have it loaded with the cfg
	set_debug_logging(debug_enabled);
	return;
}