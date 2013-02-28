#if defined _CAP_INC
  #endinput
#endif

#define _CAP_INC
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

/*--------------------------------------------------------------------------------
/ Globals
/-------------------------------------------------------------------------------*/
#define PLUGIN_VERSION "0.0.1"
const PLAYER_NAME_MAXLEN = 33;
const CHATALL_MSG_MAX = 100;
const MENUITEM_NAME_MAXLEN = 40;
const ISTRING_MAXLEN = 5;	//0-9999
/*--------------------------------------------------------------------------------
/ Handles
/-------------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------------
/ Plugin
/-------------------------------------------------------------------------------*/
public Plugin:myinfo =
{
	name = "Mano's Captain Pick",
	author = "Manos",
	description = "Generate a team though captain pick",
	version = PLUGIN_VERSION,
	url = ""
}
public OnPluginStart()
{	
	CreateConVar("mcp_version", PLUGIN_VERSION, "Captain", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegConsoleCmd("mcp_menu", Command_mcp_menu);
	RegAdminCmd("mcp_start", Command_mcp_start, ADMFLAG_GENERIC);
}

/*--------------------------------------------------------------------------------
/ Load Menu Functions
/-------------------------------------------------------------------------------*/
stock LoadCaptainPickMenu(client);
stock LoadCaptainPickClassMenu(client, class);
stock LoadChooseClassMenu(client);
/*--------------------------------------------------------------------------------
/ Helper Functions
/-------------------------------------------------------------------------------*/
stock CaptainMode();
stock PickTeams();
stock StopPlugin(String:msg[CHATALL_MSG_MAX]);