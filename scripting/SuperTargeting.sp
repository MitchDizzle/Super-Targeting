#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <tf2_stocks>

// ====[ DEFINES ]=============================================================
#define PLUGIN_NAME "Super Target Filters"
#define PLUGIN_VERSION "1.0.0"

// ====[ CONFIG ]==============================================================
new Handle:ConfigArray = INVALID_HANDLE;
enum FilterData
{
	String:Filter[24],
	Team,
	Class
	//Alive - 0 any, 1 alive, 2 dead
	//Condition - If a player is in these certain condition
};

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Super Target Filters",
	author = "ReFlexPoison, Mitch",
	description = "Addition to the classes server owners can now define new target filters based on classes, teams, etc.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public APLRes:AskPluginLoad2(Handle:hMyself, bool:bLate, String:strError[], iErrMax)
{
	decl String:strGame[32];
	GetGameFolderName(strGame, sizeof(strGame));
	if(!StrEqual(strGame, "tf"))
	{
		Format(strError, iErrMax, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

// ====[ EVENTS ]==============================================================
public OnPluginStart()
{
	CreateConVar("sm_supertargeting_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	LoadFilterConfig();
}

public OnPluginEnd()
{
	new FilterArray[FilterData];
	for(new i = 0; i < GetArraySize(ConfigArray); i++)
	{
		GetArrayArray(ConfigArray, i, FilterArray[0]);
		RemoveMultiTargetFilter(FilterArray[Filter], FilterClasses);
	}
	ClearArray(ConfigArray);
}

// ====[ Filter Event ]========================================================
public bool:FilterClasses(const String:strPattern[], Handle:hClients)
{
	new FilterArray[FilterData];
	for(new i = 0; i < GetArraySize(ConfigArray); i++)
	{
		GetArrayArray(ConfigArray, i, FilterArray[0]);
		if(StrEqual(FilterArray[Filter], strPattern))
			break;
	}
	new bool:bOpposite = (StrContains(strPattern, "!") != -1) ? true : false;
	new bool:PlayerMatchesCriteria;
	for(new i = 1; i <= MaxClients; i ++) if(IsClientInGame(i))
	{
		if(!IsPlayerAlive(i))
			continue;
		PlayerMatchesCriteria = true;
		if(FilterArray[Class] != 0 && TF2_GetPlayerClass(i) != TFClassType:FilterArray[Class])
			PlayerMatchesCriteria = false;
		if(FilterArray[Team] != 0 && GetClientTeam(i) != FilterArray[Team])
			PlayerMatchesCriteria = false;
		if(bOpposite) PlayerMatchesCriteria = !PlayerMatchesCriteria;
		if(PlayerMatchesCriteria) PushArrayCell(hClients, i);
	}
	return true;
}


// ====[ Config Functions ]====================================================
public LoadFilterConfig()
{
	ConfigArray = CreateArray(ByteCountToCells(24)+2);
	new Handle:SMC = SMC_CreateParser(); 
	SMC_SetReaders(SMC, NewSection, KeyValue, EndSection); 
	decl String:sPaths[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPaths, sizeof(sPaths),"configs/SuperTargeting.cfg");
	SMC_ParseFile(SMC, sPaths);
	CloseHandle(SMC);
}
public SMCResult:NewSection(Handle:smc, const String:name[], bool:opt_quotes) { }
public SMCResult:EndSection(Handle:smc) { }  
public SMCResult:KeyValue(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes) 
{
	new FilterArray[FilterData];
	new String:sBuffer[3][32];
	if(StrContains(value, ":")>=0)
	{
		ExplodeString(value, ":", sBuffer, 3, 32);
		FilterArray[Team]  = (StrEqual(sBuffer[0], "", false)) ? 0 : StringToInt(sBuffer[0]);
		FilterArray[Class] = (StrEqual(sBuffer[1], "", false)) ? 0 : StringToInt(sBuffer[1]);
	}
	strcopy(FilterArray[Filter], 24, key);
	PushArrayArray(ConfigArray, FilterArray[0]);
	AddMultiTargetFilter(FilterArray[Filter], FilterClasses, sBuffer[2], false);
}

/*
	AddMultiTargetFilter("@scout", FilterClasses, "all scouts", false);
	AddMultiTargetFilter("@scouts", FilterClasses, "all scouts", false);
	AddMultiTargetFilter("@!scout", FilterClasses, "all but scouts", false);
	AddMultiTargetFilter("@!scouts", FilterClasses, "all but scouts", false);
	AddMultiTargetFilter("@redscout", FilterClasses, "all scouts", false);
	AddMultiTargetFilter("@scouts", FilterClasses, "all scouts", false);
	AddMultiTargetFilter("@!redscout", FilterClasses, "all but scouts", false);
	AddMultiTargetFilter("@!redscouts", FilterClasses, "all but scouts", false);
	AddMultiTargetFilter("@bluscout", FilterClasses, "all scouts", false);
	AddMultiTargetFilter("@bluscouts", FilterClasses, "all scouts", false);
	AddMultiTargetFilter("@!bluscout", FilterClasses, "all but scouts", false);
	AddMultiTargetFilter("@!bluscouts", FilterClasses, "all but scouts", false);
	AddMultiTargetFilter("@bluescout", FilterClasses, "all scouts", false);
	AddMultiTargetFilter("@bluescouts", FilterClasses, "all scouts", false);
	AddMultiTargetFilter("@!bluescout", FilterClasses, "all but scouts", false);
	AddMultiTargetFilter("@!bluescouts", FilterClasses, "all but scouts", false);

	AddMultiTargetFilter("@soldier", FilterClasses, "all soldiers", false);
	AddMultiTargetFilter("@soldiers", FilterClasses, "all soldiers", false);
	AddMultiTargetFilter("@!soldier", FilterClasses, "all but soldiers", false);
	AddMultiTargetFilter("@!soldiers", FilterClasses, "all but soldiers", false);
	AddMultiTargetFilter("@redsoldier", FilterClasses, "all soldiers", false);
	AddMultiTargetFilter("@redsoldiers", FilterClasses, "all soldiers", false);
	AddMultiTargetFilter("@!redsoldier", FilterClasses, "all but soldiers", false);
	AddMultiTargetFilter("@!redsoldiers", FilterClasses, "all but soldiers", false);
	AddMultiTargetFilter("@blusoldier", FilterClasses, "all soldiers", false);
	AddMultiTargetFilter("@blusoldiers", FilterClasses, "all soldiers", false);
	AddMultiTargetFilter("@!blusoldier", FilterClasses, "all but soldiers", false);
	AddMultiTargetFilter("@!blusoldiers", FilterClasses, "all but soldiers", false);
	AddMultiTargetFilter("@bluesoldier", FilterClasses, "all soldiers", false);
	AddMultiTargetFilter("@bluesoldiers", FilterClasses, "all soldiers", false);
	AddMultiTargetFilter("@!bluesoldier", FilterClasses, "all but soldiers", false);
	AddMultiTargetFilter("@!bluesoldiers", FilterClasses, "all but soldiers", false);

	AddMultiTargetFilter("@pyro", FilterClasses, "all pyros", false);
	AddMultiTargetFilter("@pyros", FilterClasses, "all pyros", false);
	AddMultiTargetFilter("@!pyro", FilterClasses, "all but pyros", false);
	AddMultiTargetFilter("@!pyros", FilterClasses, "all but pyros", false);
	AddMultiTargetFilter("@redpyro", FilterClasses, "all pyros", false);
	AddMultiTargetFilter("@redpyros", FilterClasses, "all pyros", false);
	AddMultiTargetFilter("@!redpyro", FilterClasses, "all but pyros", false);
	AddMultiTargetFilter("@!redpyros", FilterClasses, "all but pyros", false);
	AddMultiTargetFilter("@blupyro", FilterClasses, "all pyros", false);
	AddMultiTargetFilter("@blupyros", FilterClasses, "all pyros", false);
	AddMultiTargetFilter("@!blupyro", FilterClasses, "all but pyros", false);
	AddMultiTargetFilter("@!blupyros", FilterClasses, "all but pyros", false);
	AddMultiTargetFilter("@bluepyro", FilterClasses, "all pyros", false);
	AddMultiTargetFilter("@bluepyros", FilterClasses, "all pyros", false);
	AddMultiTargetFilter("@!bluepyro", FilterClasses, "all but pyros", false);
	AddMultiTargetFilter("@!bluepyros", FilterClasses, "all but pyros", false);

	AddMultiTargetFilter("@demo", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@demos", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@demoman", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@demomans", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@demomen", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@!demo", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!demos", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!demoman", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!demomans", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!demomen", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@reddemo", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@reddemos", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@reddemoman", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@reddemomans", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@reddemomen", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@!reddemo", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!reddemos", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!reddemoman", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!reddemomans", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!reddemomen", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@bludemo", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@bludemos", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@bludemoman", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@bludemomans", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@bludemomen", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@!bludemo", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!bludemos", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!bludemoman", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!bludemomans", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!bludemomen", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@bluedemo", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@bluedemos", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@bluedemoman", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@bluedemomans", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@bluedemomen", FilterClasses, "all demomen", false);
	AddMultiTargetFilter("@!bluedemo", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!bluedemos", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!bluedemoman", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!bluedemomans", FilterClasses, "all but demomen", false);
	AddMultiTargetFilter("@!bluedemomen", FilterClasses, "all but demomen", false);

	AddMultiTargetFilter("@heavy", FilterClasses, "all heavies", false);
	AddMultiTargetFilter("@heavies", FilterClasses, "all heavies", false);
	AddMultiTargetFilter("@!heavy", FilterClasses, "all but heavies", false);
	AddMultiTargetFilter("@!heavies", FilterClasses, "all but heavies", false);
	AddMultiTargetFilter("@redheavy", FilterClasses, "all heavies", false);
	AddMultiTargetFilter("@redheavies", FilterClasses, "all heavies", false);
	AddMultiTargetFilter("@!redheavy", FilterClasses, "all but heavies", false);
	AddMultiTargetFilter("@!redheavies", FilterClasses, "all but heavies", false);
	AddMultiTargetFilter("@bluheavy", FilterClasses, "all heavies", false);
	AddMultiTargetFilter("@bluheavies", FilterClasses, "all heavies", false);
	AddMultiTargetFilter("@!bluheavy", FilterClasses, "all but heavies", false);
	AddMultiTargetFilter("@!bluheavies", FilterClasses, "all but heavies", false);
	AddMultiTargetFilter("@blueheavy", FilterClasses, "all heavies", false);
	AddMultiTargetFilter("@blueheavies", FilterClasses, "all heavies", false);
	AddMultiTargetFilter("@!blueheavy", FilterClasses, "all but heavies", false);
	AddMultiTargetFilter("@!blueheavies", FilterClasses, "all but heavies", false);

	AddMultiTargetFilter("@engy", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@engys", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@engineer", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@engineers", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@!engy", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!engys", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!engineer", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!engineers", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@redengy", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@redengys", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@redengineer", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@redengineers", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@!redengy", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!redengys", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!redengineer", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!redengineers", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@bluengy", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@bluengys", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@bluengineer", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@bluengineers", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@!bluengy", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!bluengys", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!bluengineer", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!bluengineers", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@blueengy", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@blueengys", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@blueengineer", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@blueengineers", FilterClasses, "all engineers", false);
	AddMultiTargetFilter("@!blueengy", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!blueengys", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!blueengineer", FilterClasses, "all but engineers", false);
	AddMultiTargetFilter("@!blueengineers", FilterClasses, "all but engineers", false);

	AddMultiTargetFilter("@medic", FilterClasses, "all medics", false);
	AddMultiTargetFilter("@medics", FilterClasses, "all medics", false);
	AddMultiTargetFilter("@!medic", FilterClasses, "all but medics", false);
	AddMultiTargetFilter("@!medics", FilterClasses, "all but medics", false);
	AddMultiTargetFilter("@redmedic", FilterClasses, "all medics", false);
	AddMultiTargetFilter("@redmedics", FilterClasses, "all medics", false);
	AddMultiTargetFilter("@!redmedic", FilterClasses, "all but medics", false);
	AddMultiTargetFilter("@!redmedics", FilterClasses, "all but medics", false);
	AddMultiTargetFilter("@blumedic", FilterClasses, "all medics", false);
	AddMultiTargetFilter("@blumedics", FilterClasses, "all medics", false);
	AddMultiTargetFilter("@!blumedic", FilterClasses, "all but medics", false);
	AddMultiTargetFilter("@!blumedics", FilterClasses, "all but medics", false);
	AddMultiTargetFilter("@bluemedic", FilterClasses, "all medics", false);
	AddMultiTargetFilter("@bluemedics", FilterClasses, "all medics", false);
	AddMultiTargetFilter("@!bluemedic", FilterClasses, "all but medics", false);
	AddMultiTargetFilter("@!bluemedics", FilterClasses, "all but medics", false);

	AddMultiTargetFilter("@sniper", FilterClasses, "all snipers", false);
	AddMultiTargetFilter("@snipers", FilterClasses, "all snipers", false);
	AddMultiTargetFilter("@!sniper", FilterClasses, "all but snipers", false);
	AddMultiTargetFilter("@!snipers", FilterClasses, "all but snipers", false);
	AddMultiTargetFilter("@redsniper", FilterClasses, "all snipers", false);
	AddMultiTargetFilter("@redsnipers", FilterClasses, "all snipers", false);
	AddMultiTargetFilter("@!redsniper", FilterClasses, "all but snipers", false);
	AddMultiTargetFilter("@!redsnipers", FilterClasses, "all but snipers", false);
	AddMultiTargetFilter("@blusniper", FilterClasses, "all snipers", false);
	AddMultiTargetFilter("@blusnipers", FilterClasses, "all snipers", false);
	AddMultiTargetFilter("@!blusniper", FilterClasses, "all but snipers", false);
	AddMultiTargetFilter("@!blusnipers", FilterClasses, "all but snipers", false);
	AddMultiTargetFilter("@bluesniper", FilterClasses, "all snipers", false);
	AddMultiTargetFilter("@bluesnipers", FilterClasses, "all snipers", false);
	AddMultiTargetFilter("@!bluesniper", FilterClasses, "all but snipers", false);
	AddMultiTargetFilter("@!bluesnipers", FilterClasses, "all but snipers", false);

	AddMultiTargetFilter("@spy", FilterClasses, "all spies", false);
	AddMultiTargetFilter("@spies", FilterClasses, "all spies", false);
	AddMultiTargetFilter("@!spy", FilterClasses, "all but spies", false);
	AddMultiTargetFilter("@!spies", FilterClasses, "all but spies", false);
	AddMultiTargetFilter("@redspy", FilterClasses, "all spies", false);
	AddMultiTargetFilter("@redspies", FilterClasses, "all spies", false);
	AddMultiTargetFilter("@!redspy", FilterClasses, "all but spies", false);
	AddMultiTargetFilter("@!redspies", FilterClasses, "all but spies", false);
	AddMultiTargetFilter("@bluspy", FilterClasses, "all spies", false);
	AddMultiTargetFilter("@bluspies", FilterClasses, "all spies", false);
	AddMultiTargetFilter("@!bluspy", FilterClasses, "all but spies", false);
	AddMultiTargetFilter("@!bluspies", FilterClasses, "all but spies", false);
	AddMultiTargetFilter("@bluespy", FilterClasses, "all spies", false);
	AddMultiTargetFilter("@bluespies", FilterClasses, "all spies", false);
	AddMultiTargetFilter("@!bluespy", FilterClasses, "all but spies", false);
	AddMultiTargetFilter("@!bluespies", FilterClasses, "all but spies", false);
*/