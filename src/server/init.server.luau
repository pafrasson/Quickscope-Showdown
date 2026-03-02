local weaponEvent = game.ReplicatedStorage.Events.WeaponEvent
local shootEvent = game.ReplicatedStorage.Events.ShootEvent
local debris = game:GetService("Debris")

-- 1. EVENTO DE UTILIDADES (Sons genéricos)
weaponEvent.OnServerEvent:Connect(function(player, action, arg1, arg2)
	local char = player.Character
	if not char then return end
	local torso = char:FindFirstChild("UpperTorso")
	if not torso then return end

	-- AÇÃO 1: EQUIPAR (Configura os sons no boneco)
	if action == "Equip" then
		local fireID = arg1
		local reloadID = arg2

		-- Limpa sons antigos
		local oldFire = torso:FindFirstChild("FireSound")
		local oldReload = torso:FindFirstChild("ReloadSound")

		if oldFire then oldFire:Destroy() end
		if oldReload then oldReload:Destroy() end

		-- Cria o Som de TIRO 
		local fSound = Instance.new("Sound", torso)
		fSound.Name = "FireSound"
		fSound.SoundId = fireID
		fSound.Volume = 1
		fSound.RollOffMaxDistance = 100

		-- Cria o Som de RELOAD (Se foi enviado um ID)
		if reloadID then
			local rSound = Instance.new("Sound", torso)
			rSound.Name = "ReloadSound"
			rSound.SoundId = reloadID
			rSound.Volume = 1
			rSound.RollOffMaxDistance = 50
		end

		-- AÇÃO 2: RELOAD (Avisa os outros clientes)
	elseif action == "Reload" then
		weaponEvent:FireAllClients("ReplicateReload", char)
	end
end)

-- 2. EVENTO DE TIRO
shootEvent.OnServerEvent:Connect(function(player, muzzlePos, mousePos, damage, headshot)

	local char = player.Character
	if not char then return end
    
	weaponEvent:FireAllClients("ReplicateSound", char)

	if typeof(muzzlePos) == "Vector3" then
		local bullet = Instance.new("Part")
		bullet.Name = "Bullet"
		bullet.Parent = workspace
		bullet.Anchored = false
		bullet.CanCollide = false
		bullet.Size = Vector3.new(0.1, 0.1, 0.5)
		bullet.Color = Color3.new(1, 0.8, 0)
		bullet.Material = Enum.Material.Neon
		bullet.CFrame = CFrame.new(muzzlePos, mousePos)

		bullet:SetNetworkOwner(player)

		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = (bullet.CFrame.LookVector * 500)
		bodyVelocity.MaxForce = Vector3.new(1, 1, 1) * math.huge
		bodyVelocity.Parent = bullet
		
		debris:AddItem(bullet, 3)

		bullet.Touched:Connect(function(hit)
			bullet:Destroy()

			-- 1. Verifica se acertou uma parte do corpo direta (Braço, Perna, Cabeça)
			if hit.Parent:FindFirstChild("Humanoid") and hit.Parent ~= char then

				if hit.Name == "Head" then
					-- Acertou a Cabeça
					hit.Parent.Humanoid:TakeDamage(headshot)

				elseif hit.Name == "UpperTorso" or hit.Name == "Torso" then
					-- Acertou o Peito (R15 ou R6)
					hit.Parent.Humanoid:TakeDamage(damage)

				else
					-- Acertou Membros (Braços/Pernas) - Dano Reduzido (60%)
					hit.Parent.Humanoid:TakeDamage(damage * 0.6)
				end

				-- 2. Verifica se acertou um Acessório (Chapéu, Cabelo, Mochila)
			elseif hit.Parent:IsA("Accessory") and hit.Parent.Parent:FindFirstChild("Humanoid") and hit.Parent.Parent ~= char then

				hit.Parent.Parent.Humanoid:TakeDamage(damage) 

			end
		end)

	else
		warn(player.Name .. " tentou atirar com posição inválida!")
	end
end)


game.Players.PlayerAdded:Connect(function(player)

	player.CharacterAdded:Connect(function(character)

		game.ReplicatedStorage.Events.PlayerAdded:FireClient(player, character)

	end)
end)
