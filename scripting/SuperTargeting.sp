#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>
#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME "Super Target Filters"
#define PLUGIN_VERSION "1.5"

#define MAXFILTERS 500
StringMap filterMap;
int maxFilters;
char fltKey[MAXFILTERS][24];
int fltTeam[MAXFILTERS];
int fltClass[MAXFILTERS];
int fltAlive[MAXFILTERS];
int fltBots[MAXFILTERS];
int fltCond[MAXFILTERS];
int fltFlag[MAXFILTERS];
bool fltOnlyFlag[MAXFILTERS];
int fltRnd[MAXFILTERS];
int fltNeg[MAXFILTERS];
int fltSelf[MAXFILTERS];

int clientLastUsed = -1;
float timeLastUsed = -1.0;

public Plugin myinfo = {
	name = "Super Target Filters",
	author = "Mitch",
	description = "Addition to the classes server owners can now define new target filters based on classes, teams, etc.",
	version = PLUGIN_VERSION,
	url = "mtch.tech"
}

public void OnPluginStart() {
	CreateConVar("sm_supertargeting_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	LoadFilterConfig();
	AddCommandListener(ST_CommandListener);
}

public void OnPluginEnd() {
	for(int k = 0; k < maxFilters; k++) {
		RemoveMultiTargetFilter(fltKey[k], FilterClasses);
	}
	delete filterMap;
}

public Action ST_CommandListener(int client, const char[] command, int argc) {
	clientLastUsed = client;
	timeLastUsed = GetGameTime();
}

/* Target filter callback */
public bool FilterClasses(const char[] pattern, Handle clients) {
	ArrayList alClients = getClientsFromPattern(pattern);
	for(int i = 0; i < alClients.Length; i++) {
		PushArrayCell(clients, alClients.Get(i));
	}
	return alClients.Length > 0;
}

/* Method to gather all the clients that match the filter. */
public ArrayList getClientsFromPattern(const char[] pattern) {
	ArrayList alClients = new ArrayList();
	
	/* Get filter key from pattern */
	int k = -1;
	if(!filterMap.GetValue(pattern, k) || k == -1) {
		/* Pattern is not found within the trie */
		return alClients;
	}
	
	bool reverse = (StrContains(pattern,"!") == 1 || fltNeg[k]);

	int client = -1;
	if(fltSelf[k] > 0) {
		client = (GetGameTime() < timeLastUsed + 1.0) ? clientLastUsed : -1;
		if(client > 0 && fltSelf[k] == 2) {
			client = GetClientAimTarget(client);
		}
	}

	if(client > 0 && !reverse) {
		/* we have a single client being targeted */
		if(filterCheck(client, k) ^ reverse) {
			alClients.Push(client);
		}
	} else {
		/* We have more than one client that can be targeted */
		for(int i = 1; i <= MaxClients; i ++) {
			if(!IsClientInGame(i)) continue;
			
			/* ignore the client that issued the command, or is being targeted */
			if(client > 0 && reverse && i == client) {
				continue;
			}

			if(filterCheck(i, k) ^ reverse) {
				alClients.Push(i);
			}
		}
	}

	if(fltRnd[k] > 0) {
		/* Remove a random player until the alClients matches the fltRnd value */
		while(alClients.Length > fltRnd[k]) {
			alClients.Erase(GetRandomInt(0, alClients.Length-1));
		}
	}
	return alClients;
}

/* Filter checks for the client */
public bool filterCheck(int client, int filter) {
	//Bots
	if(fltBots[filter] > -1 && IsFakeClient(client) != (fltBots[filter] != 0)) {
		return false;
	}
	//Alive
	if(fltAlive[filter] > -1 && IsPlayerAlive(client) != (fltAlive[filter] != 0)) {
		return false;
	}
	//Class
	if(fltClass[filter] > 0 && GetPlayerClass(client) != fltClass[filter]) {
		return false;
	}
	//Team
	if(fltTeam[filter] > 0 && GetClientTeam(client) != fltTeam[filter]) {
		return false;
	}
	//TF2: Conditions
	if(fltCond[filter] > -1 && !TF2_IsPlayerInCondition(client, view_as<TFCond>(fltCond[filter]))) {
		return false;
	}
	//Admin Flags
	if(fltFlag[filter] > 0) {
		if((!fltOnlyFlag[filter] && !(GetUserFlagBits(client) &  fltFlag[filter])) || 
			(fltOnlyFlag[filter] && !(GetUserFlagBits(client) == fltFlag[filter]))) {
			return false;
		}
	}
	return true;
}

/* Gets the player's current class, since the netprop can change between engines we should try and find it */
public int GetPlayerClass(int client) {
	static char propertyClass[32];
	if(StrEqual(propertyClass, "")) {
        if(HasEntProp(client, Prop_Send, "m_iPlayerClass")) {
            propertyClass = "m_iPlayerClass";
        } else if(HasEntProp(client, Prop_Send, "m_iClass")) {
            propertyClass = "m_iClass";
        } else {
            ThrowError("Unable to find Player Class netprop, Engine does not support the class filter.");
        }
	}
	return GetEntProp(client, Prop_Send, propertyClass);
}

/* Load filters from SuperTargeting config */
public void LoadFilterConfig() {
	filterMap = new StringMap();
	char sPaths[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPaths, sizeof(sPaths),"configs/SuperTargeting.cfg");
	KeyValues kv = new KeyValues("SuperTargeting");
	kv.ImportFromFile(sPaths);
	if(kv.GotoFirstSubKey()) {
		char sText[64];
		int k; // Represents the current id for simplicity
		do {
			k = maxFilters;
			kv.GetSectionName(fltKey[k], 24);
			if(StrEqual(fltKey[k], "")) { //Continue to the next filter if this is invalid.
				continue;
			}
			//Add to filter map.
			filterMap.SetValue(fltKey[k], maxFilters);

			kv.GetString("text", sText, 32, "TOOL TIP MISSING");
			AddMultiTargetFilter(fltKey[k], FilterClasses, sText, false);

			fltTeam[k] = kv.GetNum("team", -1);
			fltClass[k] = kv.GetNum("class", -1);
			fltAlive[k] = kv.GetNum("alive", -1);
			fltBots[k] = kv.GetNum("bots", -1);
			fltCond[k] = kv.GetNum("cond", -1);
			fltRnd[k] = kv.GetNum("random", 0);
			fltNeg[k] = kv.GetNum("invert", 0);
			fltSelf[k] = kv.GetNum("self", 0); // 0 - Disable, 1 - Self, 2 - Aim
			//Get Flags
			kv.GetString("flag", sText, 8, "");
			if(!StrEqual(sText, "", false)) {
				fltOnlyFlag[k] = (StrContains(sText, "#") != -1) ? true : false;
				ReplaceString(sText, sizeof(sText), "#", "");
				fltFlag[k] = ReadFlagString(sText);
			}		
			maxFilters++; //Increase the amount of filters
		} while(kv.GotoNextKey());
	}
	delete kv;
}
