#pragma semicolon 1
#define charsmax(%1) sizeof(%1)-1

#define DEBUG

#define PLUGIN_AUTHOR "locdt"
#define PLUGIN_VERSION "1.01"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#include "ghostfury/stocks.sp"
#include "ghostfury/native.sp"
#include "ghostfury/env.sp"
#include "ghostfury/ghostchar.sp"

#pragma newdecls required

EngineVersion g_Game;

/* ConVar Handler */
Handle pCvar_noclipSpeed;
Handle pCvar_teamLimit;
Handle pCvar_autoBalance;
Handle pCvar_limitTeam;
Handle pCvar_timeCountdown;
Handle pCvar_ratio;

bool gIsNocliping[MAXPLAYERS + 1];

int gRoundStartTime;
int gFreezeTime;
int gTimer;

public Plugin myinfo = 
{
	name = "SM: GhostMode",
	author = PLUGIN_AUTHOR,
	description = "Ghost mode based on CSO2 Ghost mode",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	RegConsoleCmd("fly", HandleNoclipCommand);
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_team", OnPlayerTeam, EventHookMode_Pre); 
	
	pCvar_timeCountdown = CreateConVar("gf_countdowntime", "5");
	pCvar_ratio = CreateConVar("gf_ratio", "4");
	InitEnvCvar();
	InitGhostCvar();
	
	pCvar_noclipSpeed = FindConVar("sv_noclipspeed");
	pCvar_teamLimit = FindConVar("mp_teams_unbalance_limit");
	pCvar_autoBalance = FindConVar("mp_autoteambalance");
	pCvar_limitTeam = FindConVar("mp_limitteams");
	
	if (pCvar_noclipSpeed == INVALID_HANDLE) return;
	
	SetConVarInt(pCvar_noclipSpeed, 1);
	SetConVarInt(pCvar_teamLimit, 0);
	SetConVarInt(pCvar_autoBalance, 0);
	SetConVarInt(pCvar_limitTeam, 0);
	
	HookConVarChange(pCvar_noclipSpeed, ConVarChanged);
	HookConVarChange(pCvar_teamLimit, ConVarChanged);
	HookConVarChange(pCvar_autoBalance, ConVarChanged);
	HookConVarChange(pCvar_limitTeam, ConVarChanged);
	
	ServerCommand("sv_skyname 2cliff");
}

public void ConVarChanged(Handle cvar,char[] oldVal, char[] newVal) {
	SetConVarInt(pCvar_noclipSpeed, 1);
	SetConVarInt(pCvar_teamLimit, 0);
	SetConVarInt(pCvar_autoBalance, 0);
	SetConVarInt(pCvar_limitTeam, 0);
}

public void OnMapStart() {
	PrepareEnv();
}

public void OnClientPutInServer(int client) {
	createHookForGhost(client);
}

public Action HandleNoclipCommand(int clientId, int args) {
	if (IsClientValid(clientId) && IsPlayerAlive(clientId) && GetClientTeam(clientId) == CS_TEAM_T) {
		if (!gIsNocliping[clientId]) {
			gFreezeTime = GetConVarInt(FindConVar("mp_freezetime"));
			if (GetTime() - gRoundStartTime > gFreezeTime) {
				makeNoclip(clientId);
				gIsNocliping[clientId] = true;
			}
		}
		else {
			removeNoclip(clientId);
			gIsNocliping[clientId] = false;
		}
	}
	
	return Plugin_Handled;
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast) {
	SetGameStarted(false);
	gRoundStartTime = GetTime();
	
	// reset noclip data
	for (int i = 0; i <= MAXPLAYERS; i++) {
		gIsNocliping[i] = false;
		
		if (IsClientValid(i) && IsClientConnected(i))
			FuncChangePlayerTeam(i, CS_TEAM_CT);
	}
	
	// Reset timer
	gTimer = GetConVarInt(pCvar_timeCountdown);
	PrintToChatAll("%d", gTimer);
	CreateTimer(1.0, TimerCountdown, _, TIMER_REPEAT);
}

public Action OnRoundEnd(Handle event, const char[] name, bool dontBroadcast) {	
	for (int id = 1; id <= MaxClients; id++) {
		if (!IsClientValid(id) && GetClientTeam(id) == CS_TEAM_T) {
			SetEntityRenderColor(id, 255, 255, 255, 255);
		}
	}
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast) {
	int clientId = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetClientTeam(clientId) == CS_TEAM_T) {
		gIsNocliping[clientId] = false;
		int num = FuncCountTAlive();
		if (num == 0)
			PrintToChatAll("CT win");
	}
}

public Action OnPlayerTeam(Event event, const char[] name, bool dontBroadcast) { 
    if(!dontBroadcast && !GetEventBool(event, "silent")) { 
        SetEventBroadcast(event,true); 
    } 
     
    return Plugin_Continue; 
}  

public Action Hook_SetTransmit(int entity, int client)
{
	return CheckTransmit(entity, client);
}

/** 
 * Timer function 
 */
public Action TimerCountdown(Handle timer) {
	if (gTimer <= 0) {
		StartMode();
		return Plugin_Stop;
	}
	
	if (gTimer == 1) {
		//EmitSoundToAll(gSound_Countdown[0]);
		PrintCenterTextAll("Ghost will appear after 1 second");
	}
	else {
		PrintCenterTextAll("Ghost will appear after %d seconds", gTimer);
		//if (gTimer <= 10)EmitSoundToAll(gSound_Countdown[gTimer - 1]);
	}
	
	gTimer--;
	
	return Plugin_Continue;
}

void StartMode() {
	SetGameStarted(true);
	PrintCenterTextAll("Ghost appear!!!");
	ChangeRandomPlayerToGhost();
}

void ChangeRandomPlayerToGhost() {
	int totalPlayers = FuncCountPlayerAlive();
	int numOfGhost = totalPlayers / GetConVarInt(pCvar_ratio);
	TranferCTsToGhosts(numOfGhost);
}

void TranferCTsToGhosts(int num) {
	for (int i = 0; i < num; i++) {
		int id;
		do {
			int maxPlayer = FuncCountCTAlive();
			id = FuncGetRandomCTAlive(GetRandomInt(1, maxPlayer));
			if (id != -1)
				SetPlayerToGhost(id);
		} while (id == -1);
	}
}