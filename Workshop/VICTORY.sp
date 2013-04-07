#include "MWorkShop.inc"

const VICTORY_hook_size = 3;
new bool:VICTORY_hook_enabled[VICTORY_hook_size];

VICTORY_SetVictory(const victory)
{
	switch(victory)
	{
		case 0://Kill the Medic
		{
			if(VICTORY_hook_enabled[0])
				UnhookEvent("player_death", Event_PlayerDeath_Victory0, EventHookMode_Post);
			else{
				if(!HookEventEx("player_death", Event_PlayerDeath_Victory0, EventHookMode_Post))
					SetFailState("Could not hook an event.");
			}	
		}
		case 1://Last one Standing
		{	
			return;  //DISABLED
			
			new Handle:convar_mp_respawnwavetime = FindConVar("mp_respawnwavetime");
			if(convar_mp_respawnwavetime == INVALID_HANDLE){
				SetFailState("Handle Invalid: mp_respawnwavetime");
			}
			
			if(VICTORY_hook_enabled[1]){
				UnhookEvent("player_death", Event_PlayerDeath_Victory1, EventHookMode_Post);
				SetConVarInt(convar_mp_respawnwavetime, 10);
			}
			else{
				if(!HookEventEx("player_death", Event_PlayerDeath_Victory1, EventHookMode_Post))
					SetFailState("Could not hook an event.");
				SetConVarInt(convar_mp_respawnwavetime, 9001);
			}

		}
		case 2://Cap the Point
		{
			if(VICTORY_hook_enabled[2])
				UnhookEvent("teamplay_point_captured", Event_Teamplay_Point_Captured_Victory2, EventHookMode_Post);
			else{
				if(!HookEventEx("teamplay_point_captured", Event_Teamplay_Point_Captured_Victory2, EventHookMode_Post))
					SetFailState("Could not hook an event.");
			}	
		}
	}

	if(VICTORY_hook_enabled[victory])
		VICTORY_hook_enabled[victory] = false;
	else{
		VICTORY_hook_enabled[victory] = true;
		MWSSetState(true);
	}
}

/*--------------------------------------------------------------------------------
/ Hooks
/-------------------------------------------------------------------------------*/
public Action:Event_PlayerDeath_Victory0(Handle:event, const String:name[], const bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new client_attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new deathflags = GetEventInt(event, "death_flags");
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	//If a Medic and not dead ringing
	if (class == TFClass_Medic && !(deathflags & 32)){
		if(client_attacker != client)
			SetWinner(GetClientTeam(client_attacker), 0);
	}
	return Plugin_Continue;
}

public Action:Event_PlayerDeath_Victory1(Handle:event, const String:name[], const bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFClassType:class = TF2_GetPlayerClass(client);
	

	PrintToChatAll("Class:%i",class);

	
	return Plugin_Continue;
}

public Action:Event_Teamplay_Point_Captured_Victory2(Handle:event, const String:name[], const bool:dontBroadcast)
{
	new team = GetEventInt(event, "team");
	SetWinner(team, 2);
	return Plugin_Continue;
}

/*--------------------------------------------------------------------------------
/ Menus
/-------------------------------------------------------------------------------*/
public Menu_Victory(Handle:menu, const MenuAction:action, const client, const param)
{
	if (action == MenuAction_Select)
	{
		new String:info[INFO_MAXLEN];
		GetMenuItem(menu, param, info, INFO_MAXLEN);
		VICTORY_SetVictory(param);
		LoadVictoryMenu(client);
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


/*--------------------------------------------------------------------------------
/ Load Menu Functions
/-------------------------------------------------------------------------------*/
LoadVictoryMenu(const client)
{
	new Handle:menu = CreateMenu(Menu_Victory);
	new String:menuitems[VICTORY_hook_size][MENUITEM_NAME_MAXLEN];

	GetVictories(menuitems);
	
	for(new i = 0; i < VICTORY_hook_size; i++){
		new String:menu_i[MENUITEM_NAME_MAXLEN];
		if(VICTORY_hook_enabled[i])
			menu_i = "[X]";
		else
			menu_i = "[  ]";
		StrCat(menu_i, MENUITEM_NAME_MAXLEN, menuitems[i]);
		AddMenuItem(menu, "", menu_i);
	}

	SetMenuTitle(menu, "Rules of Victory");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}

/*--------------------------------------------------------------------------------
/ Helper Functions
/-------------------------------------------------------------------------------*/
//You can't set arrays equal to each other in sourcemod, so I made this helper function
GetVictories(String:victory_out[VICTORY_hook_size][MENUITEM_NAME_MAXLEN])
{
	static String:VICTORIES[VICTORY_hook_size][MENUITEM_NAME_MAXLEN] = {"Kill the Medic", "Last one Standing - DISABLED", "Cap the Point"};
	
	for(new i = 0; i < VICTORY_hook_size; i++){
		victory_out[i] = VICTORIES[i];
	}
}
/*--------------------------------------------------------------------------------
* TODO
* -Finish "Last one Standing"
* --Add Hook and player alive counter
/-------------------------------------------------------------------------------*/