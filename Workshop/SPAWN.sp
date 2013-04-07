#include "MWorkShop.inc"

//For easy generation of Main Menu and manipulation of SPAWN_SetSpawns
const SPAWN_size = 3;
new SPAWN_currentspawn = 0;

/*--------------------------------------------------------------------------------
* Custom Spawns
*  0: All RED
* 10: ALL BLU   
* 1-9/11-19: RED/BLU Scout, Sniper, Soldier, DemoMan, Medic, Heavy, Pyro, Spy, Engineer
/-------------------------------------------------------------------------------*/
const SPAWN_hook_size = 20;
new bool:SPAWN_hook_enabled[SPAWN_hook_size];
new Float:SPAWN_CustomSpawn[SPAWN_hook_size][3];

SPAWN_SetSpawns(const client, const spawn)
{
	switch(spawn)
	{
		case 0://Default
		{
			if(SPAWN_currentspawn != 0){
				UnhookEvent("player_spawn", Event_PlayerSpawn_Spawn1, EventHookMode_Post);
				SPAWN_currentspawn = 0;
				for(new i = 0; i < SPAWN_hook_size; i++){
					SPAWN_hook_enabled[i] = false;
				}
			}
		}
		case 1://Custom
		{	
			LoadSetCustomSpawnMenu(client);
		}
		case 2://Load
		{	
			LoadLoadCustomSpawnMenu(client);
		}
	}
}

/*--------------------------------------------------------------------------------
/ Hooks
/-------------------------------------------------------------------------------*/
public Action:Event_PlayerSpawn_Spawn1(Handle:event, const String:name[], const bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFClassType:class = TF2_GetPlayerClass(client);
	new team = (GetClientTeam(client) - 2)*10;
	new group = team + class;		//Tag Mismatch
	
	if(SPAWN_hook_enabled[group])
		TeleportEntity(client, SPAWN_CustomSpawn[group], NULL_VECTOR, NULL_VECTOR);
	else if(SPAWN_hook_enabled[team])
		TeleportEntity(client, SPAWN_CustomSpawn[team], NULL_VECTOR, NULL_VECTOR);

	return Plugin_Continue;
}

/*--------------------------------------------------------------------------------
/ Menus
/-------------------------------------------------------------------------------*/
public Menu_Spawn(Handle:menu, const MenuAction:action, const client, const param)
{
	if (action == MenuAction_Select)
	{
		new String:info[INFO_MAXLEN];
		GetMenuItem(menu, param, info, INFO_MAXLEN);
		SPAWN_SetSpawns(client, param);
	}
	else if (action == MenuAction_Cancel)
	{
		LoadMainMenu(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_setcustomspawn(Handle:menu, const MenuAction:action, const client, const param)
{
	if (action == MenuAction_Select)
	{
		new String:info[INFO_MAXLEN];
		GetMenuItem(menu, param, info, INFO_MAXLEN);
		
		SPAWN_hook_enabled[param] = SPAWN_SetCustomSpawn(client, param);
		LoadSetCustomSpawnMenu(client);
	}
	else if (action == MenuAction_Cancel)
	{
		LoadSpawnMenu(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_Loadcustomspawn(Handle:menu, const MenuAction:action, const client, const param)
{
	if (action == MenuAction_Select)
	{
		new String:spawn_name[SPAWN_NAME_MAXLEN];
		new String:path[PATH_MAXLEN];
		new Handle:kv = CreateKeyValues("ROOT");
		
		GetMenuItem(menu, param, spawn_name, SPAWN_NAME_MAXLEN);
		
		if(StrEqual(spawn_name, "")){
			LoadSpawnMenu(client);
			return;
		}
		
		SPAWN_GetPath(path, PATH_MAXLEN);

		FileToKeyValues(kv, path);
		
		if(!KvJumpToKey(kv, spawn_name, false) || !KvGotoFirstSubKey(kv, false))
			PrintToChat(client, "[MWS] Custom Spawn is Empty");
		else{
			new i = 0;
			new String:istring[ISTRING_MAXLEN];
			
			do{
				KvGetSectionName(kv, istring, ISTRING_MAXLEN);
				i = StringToInt(istring);
				
				KvGoBack(kv);
				KvGetVector(kv,istring,SPAWN_CustomSpawn[i]);
				SPAWN_hook_enabled[i] = true;
				
				KvJumpToKey(kv, istring, false);
			}while(KvGotoNextKey(kv, false));
			
			if(SPAWN_currentspawn == 0){
				if(!HookEventEx("player_spawn", Event_PlayerSpawn_Spawn1, EventHookMode_Post))
					SetFailState("Could not hook an event.");
				MWSSetState(true);
			}
			
			SPAWN_currentspawn = 2;
		}
		
		CloseHandle(kv);
		LoadSpawnMenu(client);
	}
	else if (action == MenuAction_Cancel)
	{
		LoadSpawnMenu(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

/*--------------------------------------------------------------------------------
/ Load Menu Functions
/-------------------------------------------------------------------------------*/
LoadSpawnMenu(const client)
{
	new Handle:menu = CreateMenu(Menu_Spawn);
	new String:menuitems[SPAWN_size][MENUITEM_NAME_MAXLEN] = {"[  ]Default", "[  ]Custom Spawns", "[  ]Load Custom Spawns"};
				
	ReplaceStringEx(menuitems[SPAWN_currentspawn], MENUITEM_NAME_MAXLEN, "[  ]", "[X]");
	
	for(new i = 0; i < SPAWN_size; i++){
		AddMenuItem(menu, "", menuitems[i]);
	}

	SetMenuTitle(menu, "Choose Spawn Locations");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}

static LoadSetCustomSpawnMenu(const client)
{		
	new Handle:menu = CreateMenu(Menu_setcustomspawn);
	new String:menuitems[SPAWN_hook_size][MENUITEM_NAME_MAXLEN] = {"[  ]RED Team", "[  ]RED Scout", "[  ]RED Sniper", "[  ]RED Soldier", "[  ]RED DemoMan", "[  ]RED Medic", "[  ]RED Heavy", "[  ]RED Pyro", "[  ]RED Spy", "[  ]RED Engineer","[  ]BLU Team", "[  ]BLU Scout", "[  ]BLU Sniper", "[  ]BLU Soldier", "[  ]BLU DemoMan", "[  ]BLU Medic", "[  ]BLU Heavy", "[  ]BLU Pyro", "[  ]BLU Spy", "[  ]BLU Engineer"};

	for(new i = 0; i < SPAWN_hook_size; i++){
		if(SPAWN_hook_enabled[i])
			ReplaceStringEx(menuitems[i], MENUITEM_NAME_MAXLEN, "[  ]", "[X]");
		AddMenuItem(menu, "", menuitems[i]);
	}

	SetMenuTitle(menu, "Choose Custom Spawns");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}


static LoadLoadCustomSpawnMenu(const client)
{	
	new Handle:menu = CreateMenu(Menu_Loadcustomspawn);
	new map_maxLen = 50;
	new path_maxLen = 100;
	new String:map[map_maxLen];
	new String:path[path_maxLen];
	new Handle:kv = CreateKeyValues("ROOT");
	

	GetCurrentMap(map, map_maxLen);
	BuildPath(Path_SM,path, path_maxLen, "data/mws/%s.txt", map);
	
	if(!FileExists(path) || !FileToKeyValues(kv, path) || !KvGotoFirstSubKey(kv)){
		AddMenuItem(menu, "", "No Custom Spawns for this Map");
	}
	else{
		new String:spawn_name[SPAWN_NAME_MAXLEN];
		do
		{
			KvGetSectionName(kv, spawn_name, SPAWN_NAME_MAXLEN);
			AddMenuItem(menu, spawn_name, spawn_name);
			
		} while (KvGotoNextKey(kv));
	}

	CloseHandle(kv);
	
	SetMenuTitle(menu, "Load Custom Spawns");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}

/*--------------------------------------------------------------------------------
/ Helper Functions
/-------------------------------------------------------------------------------*/
static bool:SPAWN_SetCustomSpawn(const client, const group){
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "[SM] You must be alive to set a spawn location.");
		return false;
	}
	
	decl Float:newCustomSpawn[3];
	GetClientAbsOrigin(client, newCustomSpawn);
	
	SPAWN_CustomSpawn[group][0] = newCustomSpawn[0];
	SPAWN_CustomSpawn[group][1] = newCustomSpawn[1];
	SPAWN_CustomSpawn[group][2] = newCustomSpawn[2];
	
	if(SPAWN_currentspawn == 0){
		if(!HookEventEx("player_spawn", Event_PlayerSpawn_Spawn1, EventHookMode_Post))
			SetFailState("Could not hook an event.");
		MWSSetState(true);
	}
	SPAWN_currentspawn = 1;
	
	return true;
}

SPAWN_SaveCustomSpawn(const client, const String:spawn_name[])
{
	new String:path[PATH_MAXLEN];
	new Handle:kv = CreateKeyValues("ROOT");

	SPAWN_GetPath(path, PATH_MAXLEN);
	
	{
		new String:pathdir[PATH_MAXLEN];
		BuildPath(Path_SM,pathdir, PATH_MAXLEN, "data/mws");
		
		if(!DirExists(pathdir)){
			//TODO: Add check and create file on SPAWN_GetPath with FileExist
			PrintToConsole(client,"[MWS] Directory doesn't exist and I'm too lazy to create one");
			PrintToConsole(client,"[MWS] See: 'Manual of Manos'");
			return;
		}
	}
	
	if(!FileExists(path)){
		//Creates the file
		CloseHandle(OpenFile(path,"w"));
	}

	FileToKeyValues(kv, path);
	
	if(KvJumpToKey(kv, spawn_name, false)){
		PrintToConsole(client,"[MWS] Save Cancelled: Name already being used");
		return;
	}

	KvJumpToKey(kv, spawn_name, true);
	for(new i = 0; i < SPAWN_hook_size; i++){
		if(SPAWN_hook_enabled[i]){
			new String:istring[ISTRING_MAXLEN];
			
			IntToString(i, istring, ISTRING_MAXLEN);
			KvSetVector(kv, istring, SPAWN_CustomSpawn[i]);
		}
	}
	
	KvRewind(kv);
	
	if(!KeyValuesToFile(kv, path))
		PrintToConsole(client,"[MWS] Unable to Save File");
	else
		PrintToConsole(client,"[MWS] Save Successful");
		
	CloseHandle(kv);
}

static SPAWN_GetPath(String:path[], const path_maxLen)
{
	new String:map[MAP_MAXLEN ];
	
	GetCurrentMap(map, MAP_MAXLEN );
	BuildPath(Path_SM,path, path_maxLen, "data/mws/%s.txt", map);
}
/*--------------------------------------------------------------------------------
* TODO
* -Create a Helper for disabling, enabling and clearing spawns
* -Save the name of current loaded spawn, to mark on the Load Custom Spawn Menu
/-------------------------------------------------------------------------------*/