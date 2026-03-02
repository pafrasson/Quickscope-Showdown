local Settings = {
	-- [[ Informações Básicas ]]
	name = "Knife";
	isMelee = true;

	-- [[ Sistema de Ataque ]]
	canFire = true;
	fireMode = "Semi";
	fireRate = 0.5;
	debounce = .03;
	damage = 50;
	headshot = 100;

	-- [[ Sistema de Munição (Ignorado pelo isMelee, mas mantido por segurança) ]]
	ammo = 0;
	maxAmmo = 0;
	canReload = false;
	reloadTime = 1.5;

	-- [[ Sistema de Mira ]]
	canAim = false;
	aimSmooth = 0.1;

	-- [[ Ativos (Sons e Animações) ]]
	fireSound = game.ReplicatedStorage.Sounds.Knife.KnifeSwing2;
	fireAnim = "rbxassetid://112069182182377";
	
	equipSound = game.ReplicatedStorage.Sounds.Knife.KnifeSwing;
	equipAnim = "rbxassetid://106315787742180";

    inspectAnim = "rbxassetid://85073803499728";
}

return Settings
