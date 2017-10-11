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
#include <smlib>
#include <multicolors>
#include <cstrike>

#define PLUGIN_AUTHOR "Elitcky"
#define PLUGIN_VERSION "1.00"

#define Prefix "SHOP"
#pragma newdecls required

//Define Invis stuff
#define INVIS					{255,255,255,20}    //Change the last number in this case "20". For set alpha of invisibility. 0 = Full invisible  255 = Not Invisible
#define NORMAL					{255,255,255,255}

//Define Speed&Gravity
#define SPEED_VELOCITY 			"1.2"
#define GRAVITY_L 				"0.60"


#define TIME_SPEED 				"10.0"
#define TIME_GRAVITY			"12.0"
#define TIME_INVISIBILITY 		"15.0"

char g_sEliShop[PLATFORM_MAX_PATH];

int userhegrenade[MAXPLAYERS + 1];
int userfreezegrenade[MAXPLAYERS + 1];
int userspeed[MAXPLAYERS + 1];
int userhp[MAXPLAYERS + 1];
int userdeagle[MAXPLAYERS + 1];
int userinvisible[MAXPLAYERS + 1];
int usergravity[MAXPLAYERS + 1];

Handle h_gtimer = INVALID_HANDLE;

int g_wearableOffset;
int g_shieldOffset;

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
	HookEvent("player_death", Event_PlayerDeath);
	
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
	g_fSpeed = hConVar.FloatValue; else
	if (StrEqual("eli_gravity", sConVarName))
	g_fGravity = hConVar.FloatValue; else
	if (StrEqual("eli_time_speed", sConVarName))
	g_fTimeSpeed = hConVar.FloatValue; else
	if (StrEqual("eli_time_gravity", sConVarName))
	g_fTimeGravity = hConVar.FloatValue; else
	if (StrEqual("eli_time_invisibility", sConVarName))
	g_fTimeInvisibility = hConVar.FloatValue;
}

public void OnClientConnected(int client)
{
	userhp[client] = 0;
	userhegrenade[client] = 0;
	userfreezegrenade[client] = 0;
	userdeagle[client] = 0;
	userspeed[client] = 0;
	userinvisible[client] = 0;
	usergravity[client] = 0;
}

public void OnClientDisconnect(int client)
{
	userhp[client] = 0;
	userhegrenade[client] = 0;
	userfreezegrenade[client] = 0;
	userdeagle[client] = 0;
	userspeed[client] = 0;
	userinvisible[client] = 0;
	usergravity[client] = 0;
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
*/    //IF YOU WANT TO DISABLE THE BUYZONE UN-MARK THIS LINE

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	//Check for valid client
	if (!client)
		return;
	
	//code
	userhp[client] = 0;
	userhegrenade[client] = 0;
	userfreezegrenade[client] = 0;
	userdeagle[client] = 0;
	userspeed[client] = 0;
	userinvisible[client] = 0;
	usergravity[client] = 0;
	
	Colorize(client, NORMAL);
	
	SetClientSpeed(client,1.0)
	SetEntityGravity(client,1.0)
}

public void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//Check for valid client
	if (!client)
		return;
	
	userhp[client] = 0;
	userhegrenade[client] = 0;
	userfreezegrenade[client] = 0;
	userdeagle[client] = 0;
	userspeed[client] = 0;
	userinvisible[client] = 0;
	usergravity[client] = 0;
	
	Colorize(client, NORMAL);
	
	SetClientSpeed(client,1.0)
	SetEntityGravity(client,1.0)
}

public void Colorize(int client, int color[4])
{
	int maxents = GetMaxEntities();
	// Colorize player and weapons
	int m_hMyWeapons = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
	//int m_hMyWeapons = HasEntProp("CBasePlayer", "m_hMyWeapons");	
	
	for (int i = 0, weapon; i < 47; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
		
		if (weapon > -1)
		{
			char strClassname[250];
			GetEdictClassname(weapon, strClassname, sizeof(strClassname));
			//PrintToChatAll("strClassname is: %s", strClassname);
			
			SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(weapon, color[0], color[1], color[2], color[3]);
		}
	}
	
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
	
	// Colorize any wearable items
	for (int i = MaxClients + 1; i <= maxents; i++)
	{
		if (!IsValidEntity(i))continue;
		
		char netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));
		
		if (strcmp(netclass, "CTFWearableItem") == 0)
		{
			if (GetEntDataEnt2(i, g_wearableOffset) == client)
			{
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, color[0], color[1], color[2], color[3]);
			}
		} else if (strcmp(netclass, "CTFWearableItemDemoShield") == 0)
		{
			if (GetEntDataEnt2(i, g_shieldOffset) == client)
			{
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, color[0], color[1], color[2], color[3]);
			}
		}
	}
	return;
}

public Action Timer_Invis(Handle timer, any client)
{
	Colorize(client, NORMAL);
	
	CPrintToChat(client, "{green}[%s] {default} You are no longer invisible", Prefix);
	CloseHandle(h_gtimer);
}

public Action Timer_Gravity(Handle timer, any client)
{
	SetEntityGravity(client,1.0)
	
	CPrintToChat(client, "{green}[%s] {default} You have returned to your Normal Gravity.", Prefix);
	CloseHandle(h_gtimer);
}

public Action Timer_Speed(Handle timer, any client)
{
	SetClientSpeed(client,1.0)
	
	CPrintToChat(client, "{green}[%s] {default} You have returned to your Normal Speed.", Prefix);
	CloseHandle(h_gtimer);
}

public void SetClientSpeed(int client, float speed) 
{ 
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue",speed)
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
			
			int money = Client_GetMoney(client);
			int cost = StringToInt(price);
			
			//Main functions
			char sItem[50], value[50];
			kvtShop.GetString("item", sItem, sizeof(sItem));
			kvtShop.GetString("value", value, sizeof(value));
			
			if (StrEqual(sItem, "health"))
			{
				if (userhp[client] > 0)
				{
					CPrintToChat(client, "{green}[%s] {default} You already own this item!", Prefix);
					return;
				}
				else if (money > cost || money == cost)
				{
					//Take off money
					int Cash = money - cost;
					Client_SetMoney(client, Cash);
					
					//Print message in chat
					CPrintToChat(client, "{green}[%s] {default} You purchased HP!", Prefix);
					
					int ivalue = StringToInt(value);
					int ihealth = GetClientHealth(client);
					SetEntityHealth(client, ihealth + ivalue);
					userhp[client]++;
				}
				else
				{
					CPrintToChat(client, "{green}[%s] {default} You need more money to buy this!", Prefix);
				}
			}
			
			else if (StrEqual(sItem, "weapon_hegrenade"))
			{
				if (userhegrenade[client] > 0)
				{
					CPrintToChat(client, "{green}[%s] {default} You already own this item!", Prefix);
					return;
				}
				else if (money > cost || money == cost) {
					//Take off money
					int Cash = money - cost;
					Client_SetMoney(client, Cash);
					
					//Print message in chat
					CPrintToChat(client, "{green}[%s] {default} You purchased a HE Grenade!", Prefix);
					GivePlayerItem(client, "weapon_hegrenade");
					userhegrenade[client]++;
				}
				else
				{
					CPrintToChat(client, "{green}[%s] {default} You need more money to buy this!", Prefix);
				}
			}
			
			else if (StrEqual(sItem, "weapon_decoy"))
			{
				if (userfreezegrenade[client] > 0)
				{
					CPrintToChat(client, "{green}[%s] {default} You already own this item!", Prefix);
					return;
				}
				else if (money > cost || money == cost)
				{
					//Take off money
					int Cash = money - cost;
					Client_SetMoney(client, Cash);
					
					//Print message in chat
					CPrintToChat(client, "{green}[%s] {default} You purchased a Decoy Grenade!", Prefix);
					GivePlayerItem(client, "weapon_decoy");
					userfreezegrenade[client]++;
				}
				else
				{
					CPrintToChat(client, "{green}[%s] {default} You need more money to buy this!", Prefix);
				}
			}
			
			else if (StrEqual(sItem, "weapon_deagle"))
			{
				if (userdeagle[client] > 0)
				{
					CPrintToChat(client, "{green}[%s] {default} You already own this item!", Prefix);
					return;
				}
				else if (money > cost || money == cost)
				{
					//Take off money
					int Cash = money - cost;
					Client_SetMoney(client, Cash);
					
					//Print message in chat
					CPrintToChat(client, "{green}[%s] {default} You purchased a Deagle Weapon with 1 bullet!", Prefix);
					Client_GiveWeaponAndAmmo(client, "weapon_deagle", _, 0, _, 1);
					userdeagle[client]++;
				}
				else
				{
					CPrintToChat(client, "{green}[%s] {default} You need more money to buy this!", Prefix);
				}
			}
			
			else if (StrEqual(sItem, "Invisibility"))
			{
				if (userinvisible[client] > 0)
				{
					CPrintToChat(client, "{green}[%s] {default} You already own this item!", Prefix);
					return;
				}
				else if (money > cost || money == cost)
				{
					//Take off money
					int Cash = money - cost;
					Client_SetMoney(client, Cash);
					
					//int target;
					
					//Print message in chat
					CPrintToChat(client, "{green}[%s] {default} You purchased Invisibility!", Prefix);
					Colorize(client, INVIS);
					h_gtimer = CreateTimer(g_fTimeInvisibility, Timer_Invis, client); // Timer Invisibility
					userinvisible[client]++;
				}
				else
				{
					CPrintToChat(client, "{green}[%s] {default} You need more money to buy this!", Prefix);
				}
			}
			
			else if (StrEqual(sItem, "Gravity"))
			{
				if (usergravity[client] > 0)
				{
					CPrintToChat(client, "{green}[%s] {default} You already own this item!", Prefix);
					return;
				}
				else if (money > cost || money == cost)
				{
					//Take off money
					int Cash = money - cost;
					Client_SetMoney(client, Cash);
					
					//int target;
					
					//Print message in chat
					CPrintToChat(client, "{green}[%s] {default} You purchased Gravity!", Prefix);
					SetEntityGravity(client,g_fGravity)
					h_gtimer = CreateTimer(g_fTimeGravity, Timer_Gravity, client); // Timer Gravity
					usergravity[client]++;
				}
				else
				{
					CPrintToChat(client, "{green}[%s] {default} You need more money to buy this!", Prefix);
				}
			}
			
			else if (StrEqual(sItem, "Speed"))
			{
				if (userspeed[client] > 0)
				{
					CPrintToChat(client, "{green}[%s] {default} You already own this item!", Prefix);
					return;
				}
				else if (money > cost || money == cost)
				{
					//Take off money
					int Cash = money - cost;
					Client_SetMoney(client, Cash);
					
					//int target;
					
					//Print message in chat
					CPrintToChat(client, "{green}[%s] {default} You purchased Speed!", Prefix);
					SetClientSpeed(client,g_fSpeed)
					h_gtimer = CreateTimer(g_fTimeSpeed, Timer_Speed, client); // Timer Speed
					userspeed[client]++;
				}
				else
				{
					CPrintToChat(client, "{green}[%s] {default} You need more money to buy this!", Prefix);
				}
			}
			
		}
	}
} 