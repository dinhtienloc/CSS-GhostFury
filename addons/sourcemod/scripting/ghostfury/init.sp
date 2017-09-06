/* ConVar Handler */
Handle pCvar_dia;
Handle pCvar_noclipSpeed;

void InitServerConVar() {
	
}

void InitHook() {
	HookConVarChange(pCvar_dia, ConVarChanged);
}

public void ConVarChanged(Handle cvar,char[] oldVal, char[] newVal) {
	SetConVarInt(pCvar_dia, 1);
}