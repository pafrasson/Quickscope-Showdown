local Settings = {
	-- [[ Informações Básicas ]]
	name = "Ballista";
	isMelee = false;

	-- [[ Sistema de Disparo ]]
	canFire = true;
	fireMode = "Semi";
	fireRate = 0.3;
	debounce = 1.2;
	damage = 100;
	headshot = 100;

	-- [[ Sistema de Munição ]]
	ammo = 5;
	maxAmmo = 5;
	canReload = true;
	reloadTime = 2.5;

	-- [[ Sistema de Mira ]]
	canAim = true;
	aimSmooth = 0.15;

	-- Ativos (Sons e Animações)
	fireSound = game.ReplicatedStorage.Sounds.Ballista.Fire;
	fireAnim = "rbxassetid://129743193615093";
	
	reloadSound = game.ReplicatedStorage.Sounds.Ballista.Reload;
	reloadAnim = "rbxassetid://85073803499728";
	
	equipSound = game.ReplicatedStorage.Sounds.Ballista.Equip;
	equipAnim = "rbxassetid://106315787742180";
}

return Settings
