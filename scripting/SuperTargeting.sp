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
	ConfigArray = CreateArray(26);
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
	if(StrContains(value, ":")!=-1)
	{
		ExplodeString(value, ":", sBuffer, 3, 32);
		FilterArray[Team]  = (StrEqual(sBuffer[0], "", false)) ? 0 : StringToInt(sBuffer[0]);
		FilterArray[Class] = (StrEqual(sBuffer[1], "", false)) ? 0 : StringToInt(sBuffer[1]);
	}
	strcopy(FilterArray[Filter], 24, key);
	PushArrayArray(ConfigArray, FilterArray[0]);
	AddMultiTargetFilter(FilterArray[Filter], FilterClasses, sBuffer[2], false);
}