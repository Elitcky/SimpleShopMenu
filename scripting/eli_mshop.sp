/* Simple Shop Menu
 *    by Elitcky
 * 
 *  Credits:
 *    Franc1sco - I took some tutorials and copy/paste some functions of his plugins.
 *    Celofan - Because he made the HNS MODE for csgo and that made me think to make this plugin
 *    Boomix - Took ideas & stuff from his Basebuilder Menu and Addapted it to General CSGO game.
 *   
 *												 Made by Elitcky
 *						 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *						 *   Im NEW ON SOURCEMOD PAWN   - IM TRYING TO LEARN NEW THINGS        *
 *						 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 */
#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <cstrike>
#include <sdkhooks>

#define PLUGIN_AUTHOR "Elitcky"
#define PLUGIN_VERSION "1.10"

#define Prefix "SHOP"
#pragma newdecls required
#pragma semicolon 1


//Define Speed&Gravity
#define SPEED_VELOCITY 			"1.2"
#define GRAVITY_L 				"0.60"


#define TIME_SPEED 				"10.0"
#define TIME_GRAVITY			"12.0"
#define TIME_INVISIBILITY 		"15.0"

char g_sEliShop[PLATFORM_MAX_PATH];

bool g_bUserhegrenade[MAXPLAYERS + 1];
bool g_bUserfreezegrenade[MAXPLAYERS + 1];
bool g_bUserspeed[MAXPLAYERS + 1];
bool g_bUserhp[MAXPLAYERS + 1];
bool g_bUserdeagle[MAXPLAYERS + 1];
bool g_bUserinvisible[MAXPLAYERS + 1];
bool g_bUsergravity[MAXPLAYERS + 1];

int iCashOffs;

Handle h_gtimer = INVALID_HANDLE;

ConVar g_hSpeedVelocity;
ConVar g_hGravity;

ConVar g_hTimeSpeed;
ConVar g_hTimeGravity;
ConVar g_hTimeInvisibility;

float g_fSpeed;
float g_fGravity;

float g_fTimeSpeed;
float g_fTimeGravity;
float g_fTimeInvisibility;

KeyValues kvtShop;

public Plugin myinfo = 
{
	name = "Simple Shop Menu v1.0", 
	author = PLUGIN_AUTHOR, 
	description = "It's just a normal SHOP. I wanted one of this for my HidenSeek.", 
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_shop", CMD_Shop, "Open shop!");
	
	BuildPath(Path_SM, g_sEliShop, sizeof(g_sEliShop), "configs/mshop/shop_items.cfg");
	
	//HookEvent("round_start", RoundStart_Event);  //This un-marked enable the Block BUYZONE  Check RoundStart_Event too.
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	g_hSpeedVelocity = CreateConVar("eli_speed", SPEED_VELOCITY, "Amount of Speed a Player gets (0.1 = reduce speed // 2.0 = give more speed)", _, true, 0.1);
	g_hGravity = CreateConVar("eli_gravity", GRAVITY_L, "Amount of Gravity a player Gets (0.1 = More Gravity // 2.0 = give less Gravity)", _, true, 0.1);
	
	g_hTimeSpeed = CreateConVar("eli_time_speed", TIME_SPEED, "How long the speed effect lasts", _, true, 0.0);
	g_hTimeGravity = CreateConVar("eli_time_gravity", TIME_GRAVITY, "How long the gravity effect lasts", _, true, 0.0);
	g_hTimeInvisibility = CreateConVar("eli_time_invisibility", TIME_INVISIBILITY, "How long the invisibility effect lasts", _, true, 0.0);
	
	
	AutoExecConfig(true, "shop_cvars");
	
	g_hSpeedVelocity.AddChangeHook(OnCvarChange);
	g_hGravity.AddChangeHook(OnCvarChange);
	
	g_hTimeSpeed.AddChangeHook(OnCvarChange);
	g_hTimeGravity.AddChangeHook(OnCvarChange);
	g_hTimeInvisibility.AddChangeHook(OnCvarChange);
	
	//Get Cash offset
	iCashOffs = FindSendPropInfo("CCSPlayer", "m_iAccount");
}

public void OnConfigsExecuted()
{
	//Load up configs
	kvtShop = new KeyValues("shop_items");
	kvtShop.ImportFromFile(g_sEliShop);
	
	g_fSpeed = g_hSpeedVelocity.FloatValue;
	g_fGravity = g_hGravity.FloatValue;
	
	g_fTimeSpeed = g_hTimeSpeed.FloatValue;
	g_fTimeGravity = g_hTimeGravity.FloatValue;
	g_fTimeInvisibility = g_hTimeInvisibility.FloatValue;
}

public void OnCvarChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	char sConVarName[64];
	hConVar.GetName(sConVarName, sizeof(sConVarName));
	
	if (StrEqual("eli_speed", sConVarName))
		g_fSpeed = hConVar.FloatValue;
	else if (StrEqual("eli_gravity", sConVarName))
		g_fGravity = hConVar.FloatValue;
	else if (StrEqual("eli_time_speed", sConVarName))
		g_fTimeSpeed = hConVar.FloatValue;
	else if (StrEqual("eli_time_gravity", sConVarName))
		g_fTimeGravity = hConVar.FloatValue;
	else if (StrEqual("eli_time_invisibility", sConVarName))
		g_fTimeInvisibility = hConVar.FloatValue;
}

/*  IF YOU WANT TO DISABLE THE BUYZONE UN-MARK THIS LINE
public void RoundStart_Event(Event event, const char[] name, bool dontBroadcast)
{
	int ent = MaxClients + 1;
	bool DisableBuyZone = false;
	
	while ((ent = FindEntityByClassname(ent, "func_buyzone")) != -1)
	{
		DisableBuyZone ? AcceptEntityInput(ent, "Disable"):AcceptEntityInput(ent, "Enable");
	}
}
*/ //IF YOU WANT TO DISABLE THE BUYZONE UN-MARK THIS LINE

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	//Check for valid client
	if (!client)
		return;
	
	//codea
	g_bUserhp[client] = false;
	g_bUserhegrenade[client] = false;
	g_bUserfreezegrenade[client] = false;
	g_bUserdeagle[client] = false;
	g_bUserspeed[client] = false;
	g_bUserinvisible[client] = false;
	g_bUsergravity[client] = false;
	
	SetClientSpeed(client, 1.0);
	SetEntityGravity(client, 1.0);
}

public void SetClientSpeed(int client, float speed)
{
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed);
}

public Action CMD_Shop(int client, int args)
{
	//cHECK
	if (IsClientInGame(client) && (!IsFakeClient(client)) && IsPlayerAlive(client))
	{
		Menu shopmenu = new Menu(MenuHandler_Shop);
		SetMenuTitle(shopmenu, "SHOP MENU V1.0");
		
		kvtShop.Rewind();
		if (!kvtShop.GotoFirstSubKey())
			return Plugin_Handled;
		
		char ItemID[10], name[150], price[20];
		do
		{
			kvtShop.GetSectionName(ItemID, sizeof(ItemID));
			kvtShop.GetString("name", name, sizeof(name));
			kvtShop.GetString("price", price, sizeof(price));
			Format(name, sizeof(price), "%s| $%s", name, price);
			shopmenu.AddItem(ItemID, name);
		} while (kvtShop.GotoNextKey());
		
		shopmenu.Display(client, 0);
	}
	else if (!IsPlayerAlive(client))
	{
		CPrintToChat(client, "{green}[%s] {default} You are not alive to open the shopping menu.", Prefix);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public int MenuHandler_Shop(Menu menu, MenuAction action, int client, int item)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, item, info, sizeof(info));
			
			char configfile[PLATFORM_MAX_PATH];
			configfile = g_sEliShop;
			
			kvtShop.Rewind();
			if (!kvtShop.JumpToKey(info))
				return;
			
			char price[10];
			kvtShop.GetString("price", price, sizeof(price));
			
			int money = GetClientMoney(client);
			int cost = StringToInt(price);
			
			//Main functions
			char sItem[50], value[50];
			kvtShop.GetString("item", sItem, sizeof(sItem));
			kvtShop.GetString("value", value, sizeof(value));
			
			if (StrEqual(sItem, "health"))
			{
				if (!g_bUserhp[client])
				{
					CPrintToChat(client, "{green}[%s] {default} You already own this item!", Prefix);
					return;
				}
				else if (money > cost || money == cost)
				{
					//Take off money
					int Cash = money - cost;
					SetClientMoney(client, Cash);
					
					//Print message in chat
					CPrintToChat(client, "{green}[%s] {default} You purchased HP!", Prefix);
					
					int ivalue = StringToInt(value);
					int ihealth = GetClientHealth(client);
					SetEntityHealth(client, ihealth + ivalue);
					g_bUserhp[client] = true;
				}
				else
				{
					CPrintToChat(client, "{green}[%s] {default} You need more money to buy this!", Prefix);
				}
			}
			
			else if (StrEqual(sItem, "weapon_hegrenade"))
			{
				if (!g_bUserhegrenade[client])
				{
					CPrintToChat(client, "{green}[%s] {default} You already own this item!", Prefix);
					return;
				}
				else if (money > cost || money == cost) {
					//Take off money
					int Cash = money - cost;
					SetClientMoney(client, Cash);
					
					//Print message in chat
					CPrintToChat(client, "{green}[%s] {default} You purchased a HE Grenade!", Prefix);
					GivePlayerItem(client, "weapon_hegrenade");
					g_bUserhegrenade[client] = true;
				}
				else
				{
					CPrintToChat(client, "{green}[%s] {default} You need more money to buy this!", Prefix);
				}
			}
			
			else if (StrEqual(sItem, "weapon_decoy"))
			{
				if (!g_bUserfreezegrenade[client])
				{
					CPrintToChat(client, "{green}[%s] {default} You already own this item!", Prefix);
					return;
				}
				else if (money > cost || money == cost)
				{
					//Take off money
					int Cash = money - cost;
					SetClientMoney(client, Cash);
					
					//Print message in chat
					CPrintToChat(client, "{green}[%s] {default} You purchased a Decoy Grenade!", Prefix);
					GivePlayerItem(client, "weapon_decoy");
					g_bUserfreezegrenade[client] = true;
				}
				else
				{
					CPrintToChat(client, "{green}[%s] {default} You need more money to buy this!", Prefix);
				}
			}
			
			else if (StrEqual(sItem, "weapon_deagle"))
			{
				if (!g_bUserdeagle[client])
				{
					CPrintToChat(client, "{green}[%s] {default} You already own this item!", Prefix);
					return;
				}
				else if (money > cost || money == cost)
				{
					//Take off money
					int Cash = money - cost;
					SetClientMoney(client, Cash);
					
					//Print message in chat
					CPrintToChat(client, "{green}[%s] {default} You purchased a Deagle Weapon with 1 bullet!", Prefix);
					GivePlayerItemAmmo(client, "weapon_deagle");
					g_bUserdeagle[client] = true;
				}
				else
				{
					CPrintToChat(client, "{green}[%s] {default} You need more money to buy this!", Prefix);
				}
			}
			
			else if (StrEqual(sItem, "Invisibility"))
			{
				if (!g_bUserinvisible[client])
				{
					CPrintToChat(client, "{green}[%s] {default} You already own this item!", Prefix);
					return;
				}
				else if (money > cost || money == cost)
				{
					//Take off money
					int Cash = money - cost;
					SetClientMoney(client, Cash);
					
					//int target;
					
					//Print message in chat
					CPrintToChat(client, "{green}[%s] {default} You purchased Invisibility!", Prefix);
					SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
					h_gtimer = CreateTimer(g_fTimeInvisibility, Timer_Invis, client); // Timer Invisibility
					g_bUserinvisible[client] = true;
				}
				else
				{
					CPrintToChat(client, "{green}[%s] {default} You need more money to buy this!", Prefix);
				}
			}
			
			else if (StrEqual(sItem, "Gravity"))
			{
				if (!g_bUsergravity[client])
				{
					CPrintToChat(client, "{green}[%s] {default} You already own this item!", Prefix);
					return;
				}
				else if (money > cost || money == cost)
				{
					//Take off money
					int Cash = money - cost;
					SetClientMoney(client, Cash);
					
					//int target;
					
					//Print message in chat
					CPrintToChat(client, "{green}[%s] {default} You purchased Gravity!", Prefix);
					SetEntityGravity(client, g_fGravity);
					h_gtimer = CreateTimer(g_fTimeGravity, Timer_Gravity, client); // Timer Gravity
					g_bUsergravity[client] = true;
				}
				else
				{
					CPrintToChat(client, "{green}[%s] {default} You need more money to buy this!", Prefix);
				}
			}
			
			else if (StrEqual(sItem, "Speed"))
			{
				if (!g_bUserspeed[client])
				{
					CPrintToChat(client, "{green}[%s] {default} You already own this item!", Prefix);
					return;
				}
				else if (money > cost || money == cost)
				{
					//Take off money
					int Cash = money - cost;
					SetClientMoney(client, Cash);
					
					//int target;
					
					//Print message in chat
					CPrintToChat(client, "{green}[%s] {default} You purchased Speed!", Prefix);
					SetClientSpeed(client, g_fSpeed);
					h_gtimer = CreateTimer(g_fTimeSpeed, Timer_Speed, client); // Timer Speed
					g_bUserspeed[client] = true;
				}
				else
				{
					CPrintToChat(client, "{green}[%s] {default} You need more money to buy this!", Prefix);
				}
			}
			
		}
	}
}

public Action Hook_SetTransmit(int entity, int client)
{
	if (entity != client)
		return Plugin_Handled;
	
	return Plugin_Continue;
}


//Timers
public Action Timer_Invis(Handle timer, any client)
{
	SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	
	CPrintToChat(client, "{green}[%s] {default} You are no longer invisible", Prefix);
	CloseHandle(h_gtimer);
}

public Action Timer_Gravity(Handle timer, any client)
{
	SetEntityGravity(client, 1.0);
	
	CPrintToChat(client, "{green}[%s] {default} You have returned to your Normal Gravity.", Prefix);
	CloseHandle(h_gtimer);
}

public Action Timer_Speed(Handle timer, any client)
{
	SetClientSpeed(client, 1.0);
	
	CPrintToChat(client, "{green}[%s] {default} You have returned to your Normal Speed.", Prefix);
	CloseHandle(h_gtimer);
}


//Stocks
stock void SetClientMoney(int client, int money)
{
	SetEntData(client, iCashOffs, money);
}


stock int GetClientMoney(int client)
{
	return GetEntData(client, iCashOffs);
}

stock void GivePlayerItemAmmo(int client, const char[] item)
{
	int weaponEnt = GivePlayerItem(client, item);
	
	SetEntProp(weaponEnt, Prop_Data, "m_iClip1", 1);
	
	SetEntProp(weaponEnt, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
	SetEntProp(weaponEnt, Prop_Send, "m_iSecondaryReserveAmmoCount", 0);
} 