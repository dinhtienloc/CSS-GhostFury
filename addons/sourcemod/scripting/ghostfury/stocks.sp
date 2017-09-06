/**
 * Check if client is ingame or not
 *
 * @param client			Client index.
 * @return					
 */
stock bool IsClientValid(int client) {
	return (1 <= client && client <= MaxClients && IsClientInGame(client));
}

/**
 * Check if client is in ghost team or not
 *
 * @param client			Client index.
 * @return					
 */
stock bool IsClientGhost(int client) {
	return (IsClientValid(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_T);
}

/**
 * Get number of alive player in game
 *
 * @return					
 */
int FuncCountPlayerAlive() {
	static iAlive, id;
	iAlive = 0;
	
	for (id = 1; id <= MaxClients; id++) {
		if (IsClientConnected(id) && IsPlayerAlive(id)) {
			iAlive++;
		}
	}
	
	return iAlive;
}

/**
 * Get number of alive player in CT team
 *
 * @return					
 */
int FuncCountCTAlive() {
	static iAlive, id;
	iAlive = 0;
	
	for (id = 1; id <= MaxClients; id++) {
		if (IsClientConnected(id) && IsPlayerAlive(id) && GetClientTeam(id) == CS_TEAM_CT) {
			iAlive++;
		}
	}
	
	return iAlive;
}

/**
 * Get number of alive player in T team
 *
 * @return					
 */
int FuncCountTAlive() {
	static iAlive, id;
	iAlive = 0;
	
	for (id = 1; id <= MaxClients; id++) {
		if (IsClientConnected(id) && IsPlayerAlive(id) && GetClientTeam(id) == CS_TEAM_T) {
			iAlive++;
		}
	}
	
	return iAlive;
}

/**
 * Get the n-th alive player in game
 *
 * @return					
 */
int FuncGetRandomCTAlive(int n) {
	static iAlive, id;
	iAlive = 0;
	
	for (id = 1; id <= MaxClients; id++) {
		if (IsPlayerAlive(id) && GetClientTeam(id) == CS_TEAM_CT) iAlive++;
		if (iAlive == n)return id;
	}
	
	return -1;
}

/**
 * Change player to specific team
 *
 * @return					
 */
void FuncChangePlayerTeam(int client, int newTeam) {
	// Stop if input client is invalid;
	if (!IsClientValid(client)) return;
	
	// Stop if change to CS_TEAM_NONE
	if (newTeam == CS_TEAM_NONE) return;
	
	int curTeam = GetClientTeam(client);
	
	// Stop if new team is the current team
	if (curTeam == newTeam) return;
	
	// Change team
	CS_SwitchTeam(client, newTeam);
}

/**
 * Gets the Classname of an entity.
 * This is like GetEdictClassname(), except it works for ALL
 * entities, not just edicts.
 *
 * @param entity			Entity index.
 * @param buffer			Return/Output buffer.
 * @param size				Max size of buffer.
 * @return					
 */
stock bool Entity_GetClassName(int entity, char[] buffer, int size)
{
	GetEntPropString(entity, Prop_Data, "m_iClassname", buffer, size);
	
	if (buffer[0] == '\0') {
		return false;
	}
	
	return true;
}

/**
 * Checks if an entity is a player or not.
 * No checks are done if the entity is actually valid,
 * the player is connected or ingame.
 *
 * @param entity			Entity index.
 * @return 				True if the entity is a player, false otherwise.
 */
stock bool Entity_IsPlayer(int entity)
{
	if (entity < 1 || entity > MaxClients) {
		return false;
	}
	
	return true;
}

/**
 * Checks if an entity matches a specific entity class.
 *
 * @param entity		Entity Index.
 * @param class			Classname String.
 * @return				True if the classname matches, false otherwise.
 */
stock bool Entity_ClassNameMatches(int entity, const char[] className, bool partialMatch = false)
{
	char entity_className[64];
	Entity_GetClassName(entity, entity_className, sizeof(entity_className));
	
	if (partialMatch) {
		return (StrContains(entity_className, className) != -1);
	}
	
	return StrEqual(entity_className, className);
}

/**
 * Kills an entity on the next frame (delayed).
 * It is safe to use with entity loops.
 * If the entity is is player ForcePlayerSuicide() is called.
 *
 * @param kenny			Entity index.
 * @return 				True on success, false otherwise
 */
stock bool Entity_Kill(int entity)
{
	if (Entity_IsPlayer(entity)) {
		ForcePlayerSuicide(entity);
		return true;
	}
	
	return AcceptEntityInput(entity, "kill");
}

/**
 * Gets the offset for a client's weapon list (m_hMyWeapons).
 * The offset will saved globally for optimization.
 *
 * @param client		Client Index.
 * @return				Weapon list offset or -1 on failure.
 */
stock int Client_GetWeaponsOffset(int client)
{
	static offset = -1;
	
	if (offset == -1) {
		offset = FindDataMapInfo(client, "m_hMyWeapons");
	}
	
	return offset;
}

stock Client_RemoveAllWeapons(int client, const char[] exclude = "", bool clearAmmo = false)
{
	int offset = Client_GetWeaponsOffset(client) - 4;
	
	int numWeaponsRemoved = 0;
	for (int i = 0; i < 48; i++) {
		offset += 4;
		
		int weapon = GetEntDataEnt2(client, offset);
		
		if (!IsValidEdict(weapon)) {
			continue;
		}
		
		if (exclude[0] != '\0' && Entity_ClassNameMatches(weapon, exclude)) {
			SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", weapon);
			ChangeEdictState(client, FindDataMapInfo(client, "m_hActiveWeapon"));
			continue;
		}
		
		if (clearAmmo) {
			int offset_ammo = FindDataMapInfo(client, "m_iAmmo");
			
			int priOffset = offset_ammo + (GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType") * 4);
			SetEntData(client, priOffset, 0, 4, true);
			
			int secondOffset = offset_ammo + (GetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoType") * 4);
			SetEntData(client, secondOffset, 0, 4, true);
		}
		
		if (RemovePlayerItem(client, weapon)) {
			Entity_Kill(weapon);
		}
		
		numWeaponsRemoved++;
	}
	
	return numWeaponsRemoved;
}