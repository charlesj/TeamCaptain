#pragma semicolon 1

/*--------------------------------------------------------------------------------
/ Includes
/-------------------------------------------------------------------------------*/
#include "CAP.inc"
#include "PLAYERS.sp"

/*--------------------------------------------------------------------------------
/ Globals
/-------------------------------------------------------------------------------*/
const INFO_NOTUSED_MAXLEN = 2;		//For places where info isn't used
const ISTRING_MAXLEN = 5;			//0-9999
static CapMode_Stage = 0;

/*--------------------------------------------------------------------------------
/ Commands
/-------------------------------------------------------------------------------*/
public Action:Command_mcp_menu(client, args)
{
	if(client == 0)
		return Plugin_Handled;
	
	if(PLAYERS_isHumanNotCap(client))
		LoadChooseClassMenu(client);
	else if(client == PLAYERS_GetCaptainClient(0) || client == PLAYERS_GetCaptainClient(1))
		LoadCaptainPickMenu(client);
	else
		PrintToConsole(client, "[MCP] You've already been picked");
	
	return Plugin_Handled;
}


public Action:Command_mcp_start(client, args)
{
	if(client == 0)
		return Plugin_Handled;
	
	if(CapMode_Stage == 0){
		LoadStartMenu(client);
	}
	else
		PrintToConsole(client, "[MCP] Captain Pick has already started");
		
		
	return Plugin_Handled;
}

/*--------------------------------------------------------------------------------
/ Hooks
/-------------------------------------------------------------------------------*/
public Action:Event_Command_jointeam(client, const String:command[], argc)
{
	return Plugin_Handled;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(CapMode_Stage != 2)
		return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new deathflags = GetEventInt(event, "death_flags");
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	//If a Medic, not dead ringing, and didn't suicide
	if (class == TFClass_Medic && !(deathflags & 32) && attacker != client){
		CapMode_Stage = 3;
		
		PLAYERS_SetCaptainClient(0, attacker);
		PLAYERS_SetCaptainClient(1, client);
			
		PickTeams();
	}
	else
		PrintToChatAll("[CAP] PlayerDeath Test Fail");//TODO, see if a suicide with damage will win
	return Plugin_Continue;
}


//TODO: Move player to team, when ready, otherwise it moves a player to team 2/3, not BLU/RED
//Change to OnClientPostAdminCheck
public Action:Event_PlayerActivate(Handle:event, const String:name[], bool:dontBroadcast)
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:steamid[STEAMID_MAX] = "";
	new bool:isAuth = IsClientAuthorized(client);
	
	if(!PLAYERS_isHumanNotCap(client))
		return Plugin_Continue;
	
	if(isAuth){
		GetClientAuthString(client, steamid, STEAMID_MAX);
		for(new i = 0; i < 2; i++){
			if(strcmp(steamid,PLAYERS_GetCaptainSteamID(i)) == 0){
				PLAYERS_SetCaptainClient(i, client);
					
				PLAYERS_SetCaptainSteamID(i, "");
				
				return Plugin_Continue;
			}
		}
		
		ChangeClientTeam(client, 1);
		PLAYERS_GetClass(client);
	}
	else
		PrintToChatAll("[CAP] Shit just got REAL ERROR");
		
	return Plugin_Continue;
}



public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:steamid[STEAMID_MAX] = "";
	new bool:isAuth = IsClientAuthorized(client);
	
	for(new i = 0; i < 2; i++){
		if(client == PLAYERS_GetCaptainClient(i)){
			if(isAuth){
				GetClientAuthString(client, steamid, STEAMID_MAX);
				PLAYERS_SetCaptainSteamID(i, steamid);
				PrintToChatAll("Medic disconnected.  Waiting 30 seconds for re-connect before getting a new medic");
				//TODO: Create time for new medic
			}
			else{
				new newmedic_client = GetRandomInt(1, CLIENT_LAST);
				new othermedic_client;
				
				if(i == 0)
					othermedic_client = PLAYERS_GetCaptainClient(1);
				else 
					othermedic_client = PLAYERS_GetCaptainClient(0);
				
				
				while(!PLAYERS_isHumanNotCap(newmedic_client) && newmedic_client == othermedic_client)
				{
					newmedic_client = GetRandomInt(1, CLIENT_LAST);
				}
				
				PrintToChatAll("Un-Auth medic disconnected.  New medic selected");
				PLAYERS_SetCaptainClient(i , newmedic_client);
			}
		}
	}
	
	PLAYERS_ClearPlayer(client);

	return Plugin_Continue;
}


/*--------------------------------------------------------------------------------
/ Menus
/-------------------------------------------------------------------------------*/
public Menu_Start(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		new String:info[INFO_NOTUSED_MAXLEN];
		GetMenuItem(menu, param, info, INFO_NOTUSED_MAXLEN);

		switch(param)
		{
			//Team Size
			case 0:
			{
				//Create Load Menu Function in PLAYERS
			}
			//Pick Method
			case 1:
			{
				//Create Load Menu Function in PLAYERS
			}
			//Labs
			case 2:
			{
				//Create Load Menu Function in PLAYERS
			}
			//Start
			case 3:
			{
				CapMode_Stage = 1;
				PrintToChatAll("[CAP] Captain Mode Started...(0 Seconds)");
				CreateTimer(0.0, Timer_BeginCapMode);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_CaptainPick(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		new String:info[INFO_NOTUSED_MAXLEN];
		GetMenuItem(menu, param, info, INFO_NOTUSED_MAXLEN);

		LoadCaptainPickClassMenu(client, param);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_CaptainPickClass(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		new String:idString[ISTRING_MAXLEN];
		GetMenuItem(menu, param, idString, ISTRING_MAXLEN);
		new player_client = StringToInt(idString);
		new captain_id;

		if(client == PLAYERS_GetCaptainClient(0))
			captain_id = 0;
		else if(client == PLAYERS_GetCaptainClient(1))
			captain_id = 1;
		else{
			PrintToChat(client, "[CAP] You're not a captain");
			return;
		}
		
		if(!PLAYERS_CaptainPicksPlayer(captain_id,player_client))
			PrintToChat(client, "[CAP] It's not your turn to choose a player");
	}
	else if (action == MenuAction_Cancel)
	{
		LoadCaptainPickMenu(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_ChooseClass(Handle:menu, MenuAction:action, client, param)
{
	
	if (action == MenuAction_Select)
	{
		new String:info[INFO_NOTUSED_MAXLEN];
		GetMenuItem(menu, param, info, INFO_NOTUSED_MAXLEN);
		new class = param;
		
		if(class == PLAYER_CLASS_MAX)
			PLAYERS_ClassPicked(client);
		else
		{
			PLAYERS_ToggleClass(client,class);
			LoadChooseClassMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
/*--------------------------------------------------------------------------------
/ Timers
/-------------------------------------------------------------------------------*/
public Action:Timer_BeginCapMode(Handle:timer)
{	
	PLAYERS_Reset();
	
	PLAYERS_GetClientEnd();
	
	for(new i = 1; i <= CLIENT_LAST ;i++){
		if(PLAYERS_isHumanNotCap(i))
			PLAYERS_GetClass(i);
	}
}


/*--------------------------------------------------------------------------------
/ Load Menu Functions
/-------------------------------------------------------------------------------*/
LoadStartMenu(client)
{
	new Handle:menu = CreateMenu(Menu_Start);

	AddMenuItem(menu, "", "Team Size");
	AddMenuItem(menu, "", "Pick Method");
	AddMenuItem(menu, "", "Labs");
	AddMenuItem(menu, "", "Start");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}


LoadCaptainPickMenu(client)
{
	new String:iString[ISTRING_MAXLEN];
	new String:menu_i[MENUITEM_NAME_MAXLEN];
	new String:menuitems[PLAYER_CLASS_MAX][MENUITEM_NAME_MAXLEN];
	new String:classcountString[ISTRING_MAXLEN];
	new class_count = 0;
	new Handle:menu = CreateMenu(Menu_CaptainPick);
	
	PLAYERS_GetClassStrings(menuitems);
	
	for(new iClass = 0; iClass < PLAYER_CLASS_MAX; iClass++){
		if(PLAYER_isClassEnabled(iClass)){
			for(new iClient = 0; iClient <= CLIENT_LAST; iClient++){
				if(PLAYERS_isHumanNotCap(iClient) && PLAYERS_isClass(iClient, iClass))
					class_count++;
			}
			
			menu_i = "[";
			IntToString(class_count, classcountString, ISTRING_MAXLEN);
			StrCat(menu_i, MENUITEM_NAME_MAXLEN, classcountString);
			StrCat(menu_i, 2, "]");

			StrCat(menu_i, MENUITEM_NAME_MAXLEN, menuitems[iClass]);
			IntToString(iClass, iString, ISTRING_MAXLEN);
			AddMenuItem(menu, iString, menu_i);
		}
	}
	
	IntToString(PLAYER_CLASS_MAX, iString, ISTRING_MAXLEN);
	AddMenuItem(menu, iString, "All");
	
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}

LoadCaptainPickClassMenu(client, class)
{
	new String:name[PLAYER_NAME_MAXLEN];
	new String:istring[ISTRING_MAXLEN];
	new Handle:menu = CreateMenu(Menu_CaptainPickClass);
	
	if(class == PLAYER_CLASS_MAX){
		for(new i = 1; i <= CLIENT_LAST ;i++){
			if(PLAYERS_isHumanNotCap(i)){
				GetClientName(i, name, PLAYER_NAME_MAXLEN);
				IntToString(i,istring,ISTRING_MAXLEN);
				AddMenuItem(menu, istring, name);
			}
		}
	}
	else{
		for(new i = 1; i <= CLIENT_LAST ;i++){
			if(PLAYERS_isHumanNotCap(i)){
				if(PLAYERS_isClass(i, class)){
					GetClientName(i, name, PLAYER_NAME_MAXLEN);
					IntToString(i,istring,ISTRING_MAXLEN);
					AddMenuItem(menu, istring, name);
				}
			}
		}
	}
	
	SetMenuTitle(menu, "Pick a Player");
	SetMenuExitButton(menu, false);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 0);
}

LoadChooseClassMenu(client)
{
	new String:iString[ISTRING_MAXLEN];
	new String:menu_i[MENUITEM_NAME_MAXLEN];
	new String:menuitems[PLAYER_CLASS_MAX][MENUITEM_NAME_MAXLEN];
	new Handle:menu = CreateMenu(Menu_ChooseClass);
			
	PLAYERS_GetClassStrings(menuitems);
	
	//TODO: FIX
	for(new i = 0; i < PLAYER_CLASS_MAX; i++){
		if(PLAYER_isClassEnabled(i)){
			if(PLAYERS_isClass(client,i))
				menu_i = "[X]";
			else
				menu_i = "[  ]";
			StrCat(menu_i, MENUITEM_NAME_MAXLEN, menuitems[i]);
			IntToString(i, iString, ISTRING_MAXLEN);
			AddMenuItem(menu, iString, menu_i);
		}
	}
	
	IntToString(PLAYER_CLASS_MAX, iString, ISTRING_MAXLEN);
	AddMenuItem(menu, iString, "Done");
	
	SetMenuTitle(menu, "What class do you want to play?");
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}
/*--------------------------------------------------------------------------------
/ Helper Functions
/-------------------------------------------------------------------------------*/

CaptainMode()
{
	{
		new player_count = 0;
		for(new i = 1; i <= CLIENT_LAST ;i++){
				if(PLAYERS_isHumanNotCap(i))
					player_count++;
		}
		
		if(player_count < 2){
			StopPlugin("Not enough players to play, need atleast 2");
			return;
		}
	}
	
	if(CapMode_Stage != 1)
		return;
	CapMode_Stage = 2;
	
	//Add Hooks
	//-prevent a players moving out of their designated team
	//-move joined players to designated team
	//-save captions steamid that leave the server
	if(!AddCommandListener(Event_Command_jointeam, "jointeam"))
		SetFailState("Could not hook an event.");
	if(!HookEventEx("player_activate", Event_PlayerActivate, EventHookMode_Post))
		SetFailState("Could not hook an event.");
	if(!HookEventEx("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre))
		SetFailState("Could not hook an event.");

	{
		//Randomly pick 2 medics, 1 for each team
		new medic_client[2];
		
		medic_client[0] = GetRandomInt(1, CLIENT_LAST);
		while(!PLAYERS_isHumanNotCap(medic_client[0])){
			medic_client[0] = GetRandomInt(1, CLIENT_LAST);
		}
		
		medic_client[1] = GetRandomInt(1, CLIENT_LAST);
		while(!PLAYERS_isHumanNotCap(medic_client[1]) || medic_client[0] == medic_client[1])
		{
			medic_client[1] = GetRandomInt(1, CLIENT_LAST);
		}
		
		//Distribute the medics for a fight to see who picks first
		for(new i = 0; i < 2; i++){
			PLAYERS_SetCaptainClient(i, medic_client[i]);
			TF2_SetPlayerClass(medic_client[i], TFClass_Medic);
		}
	}
	
	//All players that were'nt selected to be medic get moved to spectate
	for(new i = 1; i <= CLIENT_LAST ;i++){
		if(PLAYERS_isHumanNotCap(i))
			ChangeClientTeam(i, 1);
	}
	
	//Restart Round
	PrintToChatAll("[CAP] Medic Fight Begins");
	ServerCommand("mp_restartgame 1");
	
	//Add Hook to look for Medic death
	if(!HookEventEx("player_death", Event_PlayerDeath, EventHookMode_Post))
		SetFailState("Could not hook an event.");

}

PickTeams()
{	
	UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);

	//Winning Medic goes to BLU team
	ChangeClientTeam(PLAYERS_GetCaptainClient(0), 3);
	ChangeClientTeam(PLAYERS_GetCaptainClient(1), 2);
	
	LoadCaptainPickMenu(PLAYERS_GetCaptainClient(0));
}

//TODO: Ability to stop or abort plugin
StopPlugin(String:msg[CHATALL_MSG_MAX])
{
	new String:mcp_msg[7] = "[MCP] ";
	StrCat(mcp_msg, CHATALL_MSG_MAX + 7, msg);
	PrintToChatAll(mcp_msg);
	PrintToChatAll("[MCP] Plugin Stopped");
	
	//TODO: Find a better test to see if hooks are enabled
	if(CapMode_Stage > 1){
		RemoveCommandListener(Event_Command_jointeam, "jointeam");
		UnhookEvent("player_activate", Event_PlayerActivate, EventHookMode_Post);
		UnhookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	}
	
	if(CapMode_Stage == 2){
		UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	}
	
	PLAYERS_Reset();
	CapMode_Stage = 0;
}


/*--------------------------------------------------------------------------------
* TODO:
* -Add Hooks to players that leave and join game
* -Add ability to abort plugin
* -Add command to re-pick class
* -Add a timer, so waiting players don't have to wait too long
* --Need to make fix for classpicked in-case someone joins later or enters class late
* -On map end, stop plugin
/-------------------------------------------------------------------------------*/