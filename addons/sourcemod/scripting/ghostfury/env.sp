Handle pCvar_fog;

void InitEnvCvar() {
	pCvar_fog = CreateConVar("gf_light", "a");
}

void PrepareEnv() {
	char lightValue[PLATFORM_MAX_PATH];
	GetConVarString(pCvar_fog, lightValue, sizeof(lightValue));
	SetLightStyle(0, lightValue);
	
}
