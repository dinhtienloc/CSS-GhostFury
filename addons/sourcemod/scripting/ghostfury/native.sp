#include <ghostfury>

PlayerClass gPlayerClass[MAXPLAYERS + 1];


bool gameStarted = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("GF_IsPlayerGhost", Native_IsPlayerGhost);
	CreateNative("GF_IsPlayerHuman", Native_IsPlayerHuman);
	CreateNative("GF_SetPlayerClass", Native_SetPlayerClass);
	
	// Register mod library
	RegPluginLibrary("ghostfury");
	return APLRes_Success;
}

/**
 * Declare native
 */
public int Native_IsPlayerGhost(Handle plugin, int numParams) {
	int clientId = GetNativeCell(1);
	return gPlayerClass[clientId] == TEAM_GHOST ? true : false;
}

public int Native_IsPlayerHuman(Handle plugin, int numParams) {
	int clientId = GetNativeCell(1);
	return gPlayerClass[clientId] == TEAM_HUMAN ? true : false;
}

public int Native_SetPlayerClass(Handle plugin, int numParams) {
	int clientId = GetNativeCell(1);
	PlayerClass class = GetNativeCell(2);
	
	gPlayerClass[clientId] = class;
}

bool IsGameStarted() {
	return gameStarted;
}

void SetGameStarted(bool value) {
	gameStarted = value;
}