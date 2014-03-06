#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>

#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>

#undef REQUIRE_PLUGIN
#include <updater>

// ====[ DEFINES ]=============================================================
#define PLUGIN_NAME "Super Target Filters"
#define PLUGIN_VERSION "1.3.0"

// ====[ CONFIG ]==============================================================
new Handle:ConfigArray = INVALID_HANDLE;
enum FilterData
{
	String:Filter[24],
	Team,
	Class,
	Alive,
	Bots,
	Cond
};

// ====[ PLUGIN ]==============================================================
new Handle:hCUpdater = INVALID_HANDLE;
new EngineVersion:EVGame;
#define Is_iClass() (EVGame == Engine_TF2)
#define Is_iPlayerClass() (EVGame == Engine_DODS || EVGame == Engine_Left4Dead || EVGame == Engine_Left4Dead2)
public Plugin:myinfo =
{
	name = "Super Target Filters",
	author = "Mitch",
	description = "Addition to the classes server owners can now define new target filters based on classes, teams, etc.",
	version = PLUGIN_VERSION,
	url = "https://bitbucket.org/MitchDizzle/super-targeting/"
}
// ====[ EVENTS ]==============================================================
public OnPluginStart()
{
	hCUpdater = CreateConVar("sm_supertargeting_update", "1", "(0/1) Enable automatic updating?", FCVAR_PLUGIN);
	AutoExecConfig();
	CreateConVar("sm_supertargeting_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	LoadFilterConfig();
	EVGame = GetEngineVersion();
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
		PlayerMatchesCriteria = true;
		//Filter Checks
		//Bots
		if( FilterArray[Bots] > -1 && bool:FilterArray[Bots] != IsFakeClient(i) )
			PlayerMatchesCriteria = false;
		
		//Alive			
		if( FilterArray[Alive] > -1 && bool:FilterArray[Alive] != IsPlayerAlive(i) )
			PlayerMatchesCriteria = false;
		
		//Class
		if( FilterArray[Class] != 0 )
		{
			if( Is_iPlayerClass() && GetEntProp(i, Prop_Send, "m_iPlayerClass") != FilterArray[Class] )
				PlayerMatchesCriteria = false;
			if( Is_iClass() && GetEntProp(i, Prop_Send, "m_iClass") != FilterArray[Class] )
				PlayerMatchesCriteria = false;
		}
		//Team
		if( FilterArray[Team] != 0 && GetClientTeam(i) != FilterArray[Team] )
			PlayerMatchesCriteria = false;
		//TF2: Conditions
		if( EVGame == Engine_TF2 && FilterArray[Cond] != -1 && !TF2_IsPlayerInCondition(i, TFCond:FilterArray[Cond]) )
			PlayerMatchesCriteria = false;
		//TF2: Premium
		
		//Flags
		
		if( bOpposite ) PlayerMatchesCriteria = !PlayerMatchesCriteria;
		if( PlayerMatchesCriteria ) PushArrayCell(hClients, i);
	}
	return true;
}


// ====[ Config Functions ]====================================================
public LoadFilterConfig()
{
	ConfigArray = CreateArray(29); // 24 + 1 + 1 + 1 + 1
	decl String:sPaths[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPaths, sizeof(sPaths),"configs/SuperTargeting.cfg");
	new Handle:kv = CreateKeyValues("SuperTargeting");
	FileToKeyValues(kv, sPaths);
	if (!KvGotoFirstSubKey(kv))
		return;
	
	new FilterArray[FilterData];
	decl String:sText[32];
	do
	{
		KvGetSectionName(kv, FilterArray[Filter], 24);
		KvGetString(kv, "text", sText, 32, "TOOLTIP MISSING");
		FilterArray[Team] = 	KvGetNum(kv, "team", 0);
		FilterArray[Class] = 	KvGetNum(kv, "class", 0);
		FilterArray[Alive] = 	KvGetNum(kv, "alive", -1);
		FilterArray[Bots] = 	KvGetNum(kv, "bots", -1);
		FilterArray[Cond] = 	KvGetNum(kv, "cond", -1);
		//FilterArray[Prem] = 	KvGetNum(kv, "premium", -1);
		AddMultiTargetFilter(FilterArray[Filter], FilterClasses, sText, false);
		//KvGetString(kv, "flag", sText, 8, "");
		
		/*
		
		"flag"		"a" 	//targets players that have the flag of 'a'.
		"flag"		"ab" 	//targets players that have the flag of both 'a' and 'b'.
		"flag"		"#a"	//Targets players that ONLY have flag 'a'.
		"flag"		"#ab"	//Targets players that ONLY have both flags 'a' and 'b'.
		
		*/
		
		
		PushArrayArray(ConfigArray, FilterArray[0]);
	} while(KvGotoNextKey(kv));
	CloseHandle(kv);
	return;
}

// ====[ Updater ]=============================================================
#define UPDATE_URL "http://bitbucket.snbx.info/super-targeting/raw/master/supertargeting.txt"
public OnAllPluginsLoaded() {
	if (LibraryExists("updater"))
		Updater_AddPlugin(UPDATE_URL);
}
public OnLibraryAdded(const String:name[]) {
	if (StrEqual(name, "updater"))
		Updater_AddPlugin(UPDATE_URL);
}
public Action:Updater_OnPluginDownloading() {
	if (GetConVarBool(hCUpdater))
		return Plugin_Continue;
	return Plugin_Handled;
}
public Updater_OnPluginUpdated() {
	ReloadPlugin();
}

// ====[ Stocks ]=============================================================