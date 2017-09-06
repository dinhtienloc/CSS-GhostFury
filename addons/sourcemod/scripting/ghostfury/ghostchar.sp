Handle pCvar_ghostHp;
Handle pCvar_ghostGravity;
Handle pCvar_ghostSpeed;

int gAlpha[MAXPLAYERS + 1];
float gVisibleInterval = 0.5;

void InitGhostCvar() {
	pCvar_ghostHp = CreateConVar("gf_ghosthp", "200");
	pCvar_ghostSpeed = CreateConVar("gf_ghostspeed", "1.0");
	pCvar_ghostGravity = CreateConVar("gf_ghostGravity", "1.0");
}

void createHookForGhost(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	if (attacker == 0) {
		if (IsClientValid(victim) && GetClientTeam(victim) == CS_TEAM_T)
			return Plugin_Handled;
		else if (IsClientValid(victim) && GetClientTeam(victim) == CS_TEAM_CT)
			return Plugin_Continue;
	}
	else {
		if (IsClientValid(victim)) {
			int victimTeam = GetClientTeam(victim);
			int attackerTeam = GetClientTeam(attacker);
			if (victimTeam == CS_TEAM_T && attackerTeam == CS_TEAM_CT) {
				int health = GetEntProp(victim, Prop_Send, "m_iHealth");
				health -= RoundFloat(damage);
				
				if (health <= 0) {
					SetEntityMoveType(victim, MOVETYPE_NONE);
					return Plugin_Continue;
				}
				else {
					SetEntProp(victim, Prop_Data, "m_iHealth", health);
					HandleGhostTakeDamage(victim);
					return Plugin_Handled;
				}
			}			
			else if (victimTeam == CS_TEAM_CT && attackerTeam == CS_TEAM_T) {
				int health = GetEntProp(victim, Prop_Send, "m_iHealth");
				health -= RoundFloat(damage);
				
				if (health <= 0) {
					if (FuncCountCTAlive() <= 1)
						return Plugin_Continue;
					else {
						CreateDeathEvent(attacker, victim);
						SetPlayerToGhost(victim);
						return Plugin_Handled;
					}
				}
				else
					return Plugin_Continue;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action OnWeaponCanUse(int client, int weapon) {
    if (GetClientTeam(client) == CS_TEAM_T && IsGameStarted()) {
    	if (IsValidEntity(weapon)) {
			char weapon_name[PLATFORM_MAX_PATH];
			GetEntityClassname(weapon, weapon_name, charsmax(weapon_name));
			
			if (StrEqual(weapon_name, "weapon_knife"))
				return Plugin_Continue;
		}
        return Plugin_Handled; 
	}
    
    return Plugin_Continue; 
}

public Action OnWeaponDrop(int client, int weapon) {
    if(GetClientTeam(client) == CS_TEAM_T)
        return Plugin_Handled; 
    
    return Plugin_Continue; 
}  

void makeNoclip(int clientId) {
	PrintToChatAll("Client %d enabled noclip", clientId);
	SetEntityMoveType(clientId, MOVETYPE_NOCLIP);
}

void removeNoclip(int clientId) {
	PrintToChatAll("Client %d disabled noclip", clientId);
	SetEntityMoveType(clientId, MOVETYPE_WALK);
}

public Action TimerSetVisible(Handle timer, any clientId) {
	int subtractionValue = 255 / 2 + 1;
	
	if (gAlpha[clientId] <= 0) {
		return Plugin_Stop;
	}
	else {
		gAlpha[clientId] -= subtractionValue;
		SetEntityRenderColor(clientId, 255, 255, 255, gAlpha[clientId] <= 0 ? 0 : gAlpha[clientId]);
		PrintToChatAll("Set Alpha Render: %d", gAlpha[clientId]);
	}
	
	return Plugin_Continue;
}

void HandleGhostTakeDamage(int clientId) {
	PrintToChatAll("Attacked player: %d", clientId);
	
	// Set timer again
	SetEntityRenderColor(clientId, 255, 255, 255, 255);
	gAlpha[clientId] = 255;
	CreateTimer(gVisibleInterval, TimerSetVisible, clientId, TIMER_REPEAT);
}

Action CheckTransmit(int entity, int client) {
	if (entity != client && gAlpha[client] <= 0) {
		SetEntityRenderMode(client, RENDER_NORMAL);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

void SetPlayerToGhost(int clientId) {
	FuncChangePlayerTeam(clientId, CS_TEAM_T);
	SetEntityHealth(clientId, GetConVarInt(pCvar_ghostHp));
	
	float speedMul = GetConVarFloat(pCvar_ghostSpeed);
	SetEntPropFloat(clientId, Prop_Send, "m_flLaggedMovementValue", speedMul);
	
	float gravityMul = GetConVarFloat(pCvar_ghostGravity);
	SetEntityGravity(clientId, gravityMul);
	
	//SDKHook(clientId, SDKHook_SetTransmit, Hook_SetTransmit);
	SetEntityRenderMode(clientId, RENDER_TRANSCOLOR);
	SetEntityRenderColor(clientId, 255, 255, 255, 0);
	
	Client_RemoveAllWeapons(clientId, "weapon_knife", true);
	MakeGhostWeaponInvisible(clientId);
}

void MakeGhostWeaponInvisible(int id) {
	int weapon_index = GetEntPropEnt(id, Prop_Data, "m_hActiveWeapon");
	PrintToChat(id, "m_hActiveWeapon: %d", weapon_index);
	SetEntityRenderMode(weapon_index , RENDER_TRANSCOLOR);
	SetEntityRenderColor(weapon_index, 255, 255, 255, 0);
}

void CreateDeathEvent(int attacker, int victim) {
	Event event = CreateEvent("player_death");
	if (event == null)
	{
		return;
	}
 
	event.SetInt("userid", GetClientUserId(victim));
	event.SetInt("attacker", GetClientUserId(attacker));
	event.SetString("weapon", "weapon_knife");
	event.Fire();
}