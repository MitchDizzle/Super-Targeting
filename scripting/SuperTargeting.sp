#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#tryinclude <updater>

// ====[ DEFINES ]=============================================================
#define PLUGIN_NAME "Super Target Filters"
#define PLUGIN_VERSION "1.1.0"

// ====[ CONFIG ]==============================================================
new Handle:ConfigArray = INVALID_HANDLE;
enum FilterData
{
	String:Filter[24],
	String:Text[32],
	Team,
	Class,
	Alive,
	Cond
};

// ====[ PLUGIN ]==============================================================
new Handle:hCUpdater = INVALID_HANDLE;
public Plugin:myinfo =
{
	name = "Super Target Filters",
	author = "Mitch",
	description = "Addition to the classes server owners can now define new target filters based on classes, teams, etc.",
	version = PLUGIN_VERSION,
	url = "https://bitbucket.org/MitchDizzle/super-targeting/"
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
	hCUpdater = CreateConVar("sm_supertargeting_update", "1", "(0/1) Enable automatic updating?", FCVAR_PLUGIN);
	AutoExecConfig();
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
		PlayerMatchesCriteria = true;
		if( ( FilterArray[Alive] == 0 && IsPlayerAlive(i) ) || ( FilterArray[Alive] == 1 && !IsPlayerAlive(i) ) )
			PlayerMatchesCriteria = false;
		if( FilterArray[Class] != 0 && TF2_GetPlayerClass(i) != TFClassType:FilterArray[Class] )
			PlayerMatchesCriteria = false;
		if( FilterArray[Team] != 0 && GetClientTeam(i) != FilterArray[Team] )
			PlayerMatchesCriteria = false;
		if( FilterArray[Cond] != -1 && !TF2_IsPlayerInCondition(i, TFCond:FilterArray[Cond]) )
			PlayerMatchesCriteria = false;
		
		if( bOpposite ) PlayerMatchesCriteria = !PlayerMatchesCriteria;
		if( PlayerMatchesCriteria ) PushArrayCell(hClients, i);
	}
	return true;
}


// ====[ Config Functions ]====================================================
public LoadFilterConfig()
{
	ConfigArray = CreateArray(60);
	decl String:sPaths[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPaths, sizeof(sPaths),"configs/SuperTargeting.cfg");
	new Handle:kv = CreateKeyValues("SuperTargeting");
	FileToKeyValues(kv, sPaths);
	if (!KvGotoFirstSubKey(kv))
		return;
	
	new FilterArray[FilterData];
	do
	{
		KvGetSectionName(kv, FilterArray[Filter], 24);
		KvGetString(kv, "text", FilterArray[Text], 32, "TOOLTIP MISSING");
		FilterArray[Team] = 	KvGetNum(kv, "team", 0);
		FilterArray[Class] = 	KvGetNum(kv, "class", 0);
		FilterArray[Alive] = 	KvGetNum(kv, "alive", -1);
		FilterArray[Cond] = 	KvGetNum(kv, "cond", -1);
		//PrintToChatAll("%s : %i,%i,%i,%i : %s", FilterArray[Filter], FilterArray[Team], FilterArray[Class], FilterArray[Alive], FilterArray[Cond], FilterArray[Text]);
		PushArrayArray(ConfigArray, FilterArray[0]);
		AddMultiTargetFilter(FilterArray[Filter], FilterClasses, FilterArray[Text], false);
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