#include "MWorkShop.inc"

const LAB_hook_size = 1;
new bool:LAB_hook_enabled[LAB_hook_size];

LAB_SetLab(const lab)
{
	switch(lab)
	{
		case 0:
		{
			if(LAB_hook_enabled[0]){
				UnhookEvent("player_changeclass", Event_PlayerClass_Lab0, EventHookMode_Post);
				UnhookEvent("player_spawn", Event_PlayerSpawn_Lab0, EventHookMode_Post);
			}
			else{
				if (!HookEventEx("player_changeclass", Event_PlayerClass_Lab0, EventHookMode_Post)
				  ||!HookEventEx("player_spawn", Event_PlayerSpawn_Lab0, EventHookMode_Post))
					SetFailState("Could not hook an event.");
			}
		}
	}
	if(LAB_hook_enabled[lab])
		LAB_hook_enabled[lab] = false;
	else{
		LAB_hook_enabled[lab] = true;
		MWSSetState(true);
	}
}

/*--------------------------------------------------------------------------------
/ Hooks
/-------------------------------------------------------------------------------*/
public Action:Event_PlayerClass_Lab0(Handle:event, const String:name[], const bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new any:class = GetEventInt(event, "class");
	if (class == TFClass_Medic)
		CreateTimer(0.25, Timer_L1_PlayerUberDelay, client);
	return Plugin_Continue;
}
public Action:Event_PlayerSpawn_Lab0(Handle:event, const String:name[], const bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFClassType:class = TF2_GetPlayerClass(client);
	if (class == TFClass_Medic)
		CreateTimer(0.25, Timer_L1_PlayerUberDelay, client);
	return Plugin_Continue;
}

/*--------------------------------------------------------------------------------
/ Timers
/-------------------------------------------------------------------------------*/
public Action:Timer_L1_PlayerUberDelay(Handle:timer, const any:client)
{
	if (IsClientInGame(client)) {
		new TFClassType:class = TF2_GetPlayerClass(client);
		if (class == TFClass_Medic) {
			new Float:uberlevel = GetConVarFloat(mws_l1_startuberlevel);
			new index = GetPlayerWeaponSlot(client, 1);
			if (index > 0)
				SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel);
		}
	}
}
/*--------------------------------------------------------------------------------
/ Menus
/-------------------------------------------------------------------------------*/
public Menu_Lab(Handle:menu, const MenuAction:action, const client, const param)
{
	if (action == MenuAction_Select)
	{
		new String:info[INFO_MAXLEN];
		GetMenuItem(menu, param, info, INFO_MAXLEN);
		LAB_SetLab(param);
		LoadLabMenu(client);
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
LoadLabMenu(const client)
{
	new Handle:menu = CreateMenu(Menu_Lab);
	new String:menuitems[LAB_hook_size][MENUITEM_NAME_MAXLEN];
	
	GetLabs(menuitems);

	for(new i = 0; i < LAB_hook_size; i++){
		new String:menu_i[MENUITEM_NAME_MAXLEN];
		if(LAB_hook_enabled[i])
			menu_i = "[X]";
		else
			menu_i = "[  ]";
		StrCat(menu_i, MENUITEM_NAME_MAXLEN, menuitems[i]);
		AddMenuItem(menu, "", menu_i);
	}

	SetMenuTitle(menu, "Labs");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}

/*--------------------------------------------------------------------------------
/ Helper Functions
/-------------------------------------------------------------------------------*/
GetLabs(String:lab_out[LAB_hook_size][MENUITEM_NAME_MAXLEN])
{
	static String:LABS[LAB_hook_size][MENUITEM_NAME_MAXLEN] = {"Start with Full Uber"};
	
	for(new i = 0; i < LAB_hook_size; i++){
		lab_out[i] = LABS[i];
	}
}