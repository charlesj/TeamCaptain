#pragma semicolon 1

/*--------------------------------------------------------------------------------
/ Includes
/-------------------------------------------------------------------------------*/
#include "MWorkShop.inc"
#include "SPAWN.sp"
#include "LAB.sp"
#include "VICTORY.sp"

/*--------------------------------------------------------------------------------
/ Globals
/-------------------------------------------------------------------------------*/
static bool:ENABLED = false;
static bool:isDamageDisabled = false;

/*--------------------------------------------------------------------------------
/ Commands
/-------------------------------------------------------------------------------*/
public Action:Command_mws_menu(const client, const args)
{
	if(client == 0)
	{
		return Plugin_Handled;
	}
	
	LoadMainMenu(client);
	
	return Plugin_Handled;
}

public Action:Command_mws_spawn_save(const client, const args)
{
	if(GetCmdArgs() != 1){
		PrintToConsole(client,"[MWS] mws_spawn_save <name>");
	}
	else if(SPAWN_currentspawn == 0){
		PrintToConsole(client,"[MWS] Custom Spawns must be on, in order to Save");
	}
	else{
		new spawn_name_maxlenplusone = SPAWN_NAME_MAXLEN+1;	//Add 1, so spawn_name_length can see if the user typed a name greater than the max count
		new String:spawn_name[spawn_name_maxlenplusone];
		new spawn_name_length = GetCmdArg(1, spawn_name, spawn_name_maxlenplusone);
		
		if(spawn_name_length != 0 && spawn_name_length < SPAWN_NAME_MAXLEN)
			SPAWN_SaveCustomSpawn(client, spawn_name);
		else
			PrintToConsole(client,"[MWS] Spawn Name can be at most %i characters or atleast 1 character", SPAWN_NAME_MAXLEN);
	}
	
	return Plugin_Handled;
}
/*--------------------------------------------------------------------------------
/ Hooks
/-------------------------------------------------------------------------------*/
//public Action:Event_Player_Hurt_Pre(Handle:event, const String:name[], const bool:dontBroadcast)
//{
//	PrintToChatAll("HURT");
//	return Plugin_Stop;
//}

/*--------------------------------------------------------------------------------
/ Menus
/-------------------------------------------------------------------------------*/
public Menu_Main(Handle:menu, const MenuAction:action, const client, const param)
{
	if (action == MenuAction_Select)
	{
		new String:info[INFO_MAXLEN];
		GetMenuItem(menu, param, info, INFO_MAXLEN);
		switch(param)
		{
			case 0://Choose Spawn Locations
			{
				LoadSpawnMenu(client);
			}
			case 1://Rules of Victory
			{
				LoadVictoryMenu(client);
			}
			case 2://Labs
			{
				LoadLabMenu(client);
			}
			case 3://Disable Damage
			{
				if(isDamageDisabled){
					//UnhookEvent("player_hurt", Event_Player_Hurt_Pre, EventHookMode_Pre);
					isDamageDisabled = false;
				}
				else{
					//if(!HookEventEx("player_hurt", Event_Player_Hurt_Pre, EventHookMode_Pre))
					//	SetFailState("Could not hook an event.");
					isDamageDisabled = true;
				}
			}
			case 4://Disable MWS
			{
				SPAWN_SetSpawns(0,0);
				
				for(new i = 0; i < VICTORY_hook_size; i++){
					if(VICTORY_hook_enabled[i]){
						VICTORY_SetVictory(i);
					}
				}
				
				for(new i = 0; i < LAB_hook_size; i++){
					if(LAB_hook_enabled[i]){
						LAB_SetLab(i);
					}
				}
				
				MWSSetState(false);
				LoadMainMenu(client);
			}
			case 5://Start
			{
				PrintCenterTextAll("WorkShop is Starting");
				RestartRound();
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}


/*--------------------------------------------------------------------------------
/ Load Menu Functions
/-------------------------------------------------------------------------------*/
LoadMainMenu(const client)
{
	new Handle:menu = CreateMenu(Menu_Main);
	SetMenuTitle(menu, "MWS Labs");
	AddMenuItem(menu, "", "Choose Spawn Locations");
	AddMenuItem(menu, "", "Rules of Victory");
	AddMenuItem(menu, "", "Labs");
	
	if(isDamageDisabled)
		AddMenuItem(menu, "", "Enable Damage");
	else
		AddMenuItem(menu, "", "Disable Damage");
	
	if(ENABLED){
		AddMenuItem(menu, "", "Disable MWS");
		AddMenuItem(menu, "", "Start");
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

/*--------------------------------------------------------------------------------
/ Helper Functions
/-------------------------------------------------------------------------------*/
SetWinner(winningteam, victory)
{
	new String:winningteamString[2][4] = {"RED", "BLU"};
	new String:victoryString[VICTORY_hook_size][MENUITEM_NAME_MAXLEN] = {"Killed the Medic", "Survived Last one Standing", "Capped the Point"};
	
	PrintCenterTextAll("%s %s", winningteamString[winningteam-2], victoryString[victory]);
	
	RestartRound();
}

static RestartRound()
{
	const victoriesString_MaxLen = VICTORY_hook_size * MENUITEM_NAME_MAXLEN;
	const labsString_MaxLen = LAB_hook_size * MENUITEM_NAME_MAXLEN;
	
	new activeVictories_i = 0;
	new activeLabs_i = 0;
	
	new String:Victories[VICTORY_hook_size][MENUITEM_NAME_MAXLEN];
	new String:Labs[LAB_hook_size][MENUITEM_NAME_MAXLEN];
	
	new String:activeVictories[VICTORY_hook_size][MENUITEM_NAME_MAXLEN];
	new String:activeLabs[LAB_hook_size][MENUITEM_NAME_MAXLEN];
	
	new String:victoriesString[victoriesString_MaxLen];
	new String:labsString[labsString_MaxLen];
	
	GetVictories(Victories);
	GetLabs(Labs);
	
	for(new i = 0; i < VICTORY_hook_size; i++){
		if(VICTORY_hook_enabled[i]){
			activeVictories[activeVictories_i++] = Victories[i];
		}
	}
		
	for(new i = 0; i < LAB_hook_size; i++){
		if(LAB_hook_enabled[i]){
			activeLabs[activeLabs_i++] = Labs[i];
		}
	}
	
	if(activeVictories_i != 0){
		ImplodeStrings(activeVictories, activeVictories_i, ", ", victoriesString, victoriesString_MaxLen);
		PrintToChatAll("[MWS] Objectives: %s", victoriesString);
	}
	
	if(activeLabs_i != 0){
		ImplodeStrings(activeLabs, activeLabs_i, ", ", labsString, labsString_MaxLen);
		PrintToChatAll("[MWS] Labs: %s", labsString);
	}
	
	ServerCommand("mp_restartgame 3");
}


//Should only be called in MWWorkShop
MWSSetState(const bool:new_state)
{
	if(!ENABLED && new_state){
		ENABLED = true;
		PrintToChatAll("[MWS] MWS Enabled");
	}
	if(ENABLED && !new_state){
		ENABLED = false;
		PrintToChatAll("[MWS] MWS Disabled");
	}
}

/*--------------------------------------------------------------------------------
* TODO:
* -Add ability to run highlander mode and other Comp configurations
* -When disabling MWS, stop damage
* -Create a data sctructure for holding all the hooks
* -Add scorring Screen in restart round with result of win and who won
* -Disable Restart Round untill a few seconds after the round starts
* -All menus should re-display their menu when a selection happens and not exit
/-------------------------------------------------------------------------------*/
