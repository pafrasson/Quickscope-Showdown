local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local debris = game:GetService("Debris")

local camera = game.Workspace.CurrentCamera

local aimCF = CFrame.new()

local mouse = player:GetMouse()

-- bools
local isAiming = false
local isShooting = false
local isReloading = false
local isEquipping = false
local canShoot = true

local debounce = false

local currentSwayAMT = 0
local swayAMT = -.2
local aimSwayAMT = .15
local swayCF = CFrame.new()
local lastCameraCF = CFrame.new()

local reloadAnim = nil
local fireAnim = nil
local equipAnim = nil

local fireSound = nil
local reloadSound = nil
local equipSound = nil

local framework = {
    inventory = {
        "Ballista",
        "Knife"
    },

    module = nil,
    viewmodel = nil,
    currentSlot = 1,
}

function loadSlot(Item)
    -- can't change while reloading
    if isReloading == false then
        local viewmodelFolder = game.ReplicatedStorage.ViewModels
        local moduleFolder = game.ReplicatedStorage.Modules

        -- Limpa o viewmodel antigo
        if framework.viewmodel then
            framework.viewmodel:Destroy()
            framework.viewmodel = nil
        end

        -- Limpa referências antigas
        fireSound = nil
        fireAnim = nil

        reloadAnim = nil
        equipAnim = nil

        if moduleFolder:FindFirstChild(Item) then
            framework.module = require(moduleFolder:FindFirstChild(Item))

            if viewmodelFolder:FindFirstChild(Item) then
                framework.viewmodel = viewmodelFolder:FindFirstChild(Item):Clone()

                for _, part in pairs(framework.viewmodel:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if part.Transparency < 1 then
                            part.Transparency = 1
                        end
                    end
                end

                framework.viewmodel.Parent = camera

                if framework.viewmodel and framework.module and character then
                    -- Busca o Animator
                    local controller = framework.viewmodel:WaitForChild("AnimationController", 5)
                    local animator = controller and controller:WaitForChild("Animator", 5)

                    if animator then
                        -- 1. CARREGAR TIRO (FIRE)
                        local tempFire = Instance.new("Animation")
                        tempFire.AnimationId = framework.module.fireAnim
                        fireAnim = animator:LoadAnimation(tempFire)

                        if framework.module.reloadAnim then
                            local tempReload = Instance.new("Animation")
                            tempReload.AnimationId = framework.module.reloadAnim

                            reloadAnim = animator:LoadAnimation(tempReload)

                            reloadAnim.Looped = false
                            reloadAnim.Priority = Enum.AnimationPriority.Action -- Garante que sobreponha o 'Andar'
                        end

                        if framework.module.equipAnim then
                            local tempEquip = Instance.new("Animation")
                            tempEquip.AnimationId = framework.module.equipAnim

                            equipAnim = animator:LoadAnimation(tempEquip)

                            equipAnim.Looped = false
                            equipAnim.Priority = Enum.AnimationPriority.Action

                            equipAnim:Play()

                            isEquipping = true -- Bloqueia o tiro

                            -- Pega o tempo da animação (se for 0 por lag, usa 1 segundo como garantia)
                            local equipTime = equipAnim.Length > 0 and equipAnim.Length or 1

                            -- Cria uma thread separada para liberar a arma depois do tempo
                            task.spawn(function()
                                task.wait(equipTime)
                                -- Só libera se a arma ainda for a mesma (caso ele troque rápido demais)
                                if framework.viewmodel and framework.module.equipAnim then
                                    isEquipping = false
                                end
                            end)
                        else
                            -- Se não tiver animação de equipar, garante que não fica travado
                            isEquipping = false
                        end

                        task.delay(0.05, function()
                            if framework.viewmodel then
                                for _, part in pairs(framework.viewmodel:GetDescendants()) do
                                    -- Só mexemos em BaseParts (MeshPart, Part, Union)
                                    if part:IsA("BasePart") then
                                        -- Adicione aqui os nomes de partes que DEVEM continuar invisíveis
                                        if part.Name ~= "HumanoidRootPart" and part.Name ~= "AimPart" and part.Name ~= "CamPart" and part.Name ~= "Muzzle" and part.Name ~= "Main" then
                                            part.Transparency = 0
                                        end
                                    end
                                end
                            end
                        end)
                    end

                    -- SOM LOCAL
                    local head = character:WaitForChild("Head")

                    -- 1. Helper Function para pegar ID (alguns modules usam string, outros objeto)
                    local function getSoundId(modSound)
                        if type(modSound) == "table" or typeof(modSound) == "Instance" then
                            return modSound.SoundId
                        end
                        return modSound
                    end

                    -- 2. Setup Fire Sound
                    fireSound = Instance.new("Sound", head)
                    fireSound.Name = "LocalFireSound"
                    fireSound.SoundId = getSoundId(framework.module.fireSound)
                    fireSound.Volume = 1

                    -- 3. Setup Reload Sound
                    if framework.module.reloadSound then
                        reloadSound = Instance.new("Sound", head)
                        reloadSound.Name = "LocalReloadSound"
                        reloadSound.SoundId = getSoundId(framework.module.reloadSound)
                        reloadSound.Volume = 1
                    end

                    -- 4. Setup e Play Equip Sound
                    if framework.module.equipSound then
                        equipSound = Instance.new("Sound", head)
                        equipSound.Name = "LocalEquipSound"
                        equipSound.SoundId = getSoundId(framework.module.equipSound)
                        equipSound.Volume = 1
                        equipSound:Play()
                    end

                    local rId = reloadSound and reloadSound.SoundId or nil
                    game.ReplicatedStorage.Events.WeaponEvent:FireServer("Equip", fireSound.SoundId, rId)
                end
            end
        end
    end
end

function Shoot()
    if not framework.viewmodel or not framework.module then return end

    equipAnim:Stop()

    if fireAnim then fireAnim:Play() end

    if fireSound then fireSound:Play() end

    framework.module.ammo -= 1
    game.ReplicatedStorage.Events.ShootEvent:FireServer(framework.viewmodel.Muzzle.Position, mouse.Hit.Position,
        framework.module.damage, framework.module.headshot)

    debounce = true
    wait(framework.module.debounce)
    debounce = false
end

function Reload()
    if character and framework.module and framework.viewmodel and framework.module.ammo < framework.module.maxAmmo and not isReloading then
        if framework.module.canReload then
            canShoot = false
            isReloading = true

            if reloadAnim then reloadAnim:Play() end
            if reloadSound then reloadSound:Play() end
            game.ReplicatedStorage.Events.WeaponEvent:FireServer("Reload")

            wait(framework.module.reloadTime)

            canShoot = true
            isReloading = false

            framework.module.ammo = framework.module.maxAmmo
        end
    end
end

local hud = player.PlayerGui:WaitForChild("HUD")

-- Garante que se o personagem morrer e nascer de novo, atualizamos a variável
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
end)

runService.RenderStepped:Connect(function()
    mouse.TargetFilter = framework.viewmodel

    if humanoid then
        local rot = camera.CFrame:ToObjectSpace(lastCameraCF)
        local X, Y, Z = rot:ToOrientation()
        swayCF = swayCF:Lerp(CFrame.Angles(math.sin(X) * currentSwayAMT, math.sin(Y) * currentSwayAMT, 0), .1)
        lastCameraCF = camera.CFrame

        if hud and humanoid and character then
            -- Atualiza o HUD com os dados da arma atual
            if framework.viewmodel and framework.module then
                -- O Nome da arma sempre aparece, independente do tipo
                hud.GunName.Text = framework.inventory[framework.currentSlot]

                if framework.module.isMelee then
                    -- Se for corpo-a-corpo, esconde tudo sobre munição
                    hud.Ammo.Visible = false
                    hud.NoAmmo.Visible = false
                else
                    -- Se for arma de fogo, mostra e atualiza os números
                    hud.Ammo.Visible = true
                    hud.Ammo.Text = framework.module.ammo
                    hud.Ammo.MaxAmmo.Text = framework.module.maxAmmo

                    hud.NoAmmo.Visible = (framework.module.ammo <= 0)
                end
            end
        end

        if framework.viewmodel and framework.module then
            local aimSmooth = framework.module.aimSmooth or 0.1

            if isAiming and framework.module.canAim and not character:GetAttribute("IsSprinting") and not isReloading then
                if framework.viewmodel:FindFirstChild("AimPart") then
                    local offset = framework.viewmodel.AimPart.CFrame:ToObjectSpace(framework.viewmodel.PrimaryPart
                    .CFrame)
                    aimCF = aimCF:Lerp(offset, aimSmooth)
                    currentSwayAMT = aimSwayAMT
                end
            else
                local offset = CFrame.new()
                aimCF = aimCF:Lerp(offset, aimSmooth)
                currentSwayAMT = swayAMT
            end

            local bobOffset = CFrame.new()

            if humanoid then
                bobOffset = CFrame.new(-humanoid.CameraOffset.X / 4, -humanoid.CameraOffset.Y / 4,
                    -humanoid.CameraOffset.Z / 4)
                framework.viewmodel:PivotTo(camera.CFrame * swayCF * aimCF * bobOffset)
            end
        end
    end
end)

loadSlot(framework.inventory[1])

userInputService.MouseIconEnabled = false

userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    --Choose Slot
    if input.KeyCode == Enum.KeyCode.One then
        if framework.currentSlot ~= 1 and isReloading == false then
            loadSlot(framework.inventory[1])
            framework.currentSlot = 1
        end
    end

    if input.KeyCode == Enum.KeyCode.Two then
        if framework.currentSlot ~= 2 and isReloading == false then
            loadSlot(framework.inventory[2])
            framework.currentSlot = 2
        end
    end

    --Aiming
    if input.UserInputType == Enum.UserInputType.MouseButton2 and isReloading == false then
        isAiming = true
    end

    --Shooting
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if character and framework.module and framework.viewmodel and framework.module.ammo > 0 and debounce == false and canShoot == true and isReloading ~= true and isEquipping ~= true then
            if framework.module.canFire then
                Shoot()
            end
        end
    end

    --Reloading
    if input.KeyCode == Enum.KeyCode.R then
        Reload()
    end
end)

userInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAiming = false
    end
end)

game.ReplicatedStorage.Events.WeaponEvent.OnClientEvent:Connect(function(instruction, sourceChar)
    if not sourceChar or sourceChar == player.Character then return end -- Ignora você mesmo

    local torso = sourceChar:FindFirstChild("UpperTorso")
    if not torso then return end

    -- TIRO INIMIGO
    if instruction == "ReplicateSound" then
        local s = torso:FindFirstChild("FireSound")
        if s then s:Play() end

        -- RELOAD INIMIGO
    elseif instruction == "ReplicateReload" then
        local s = torso:FindFirstChild("ReloadSound")
        if s then s:Play() end
    end
end)

game.ReplicatedStorage.Events.PlayerAdded.OnClientEvent:Connect(function(ply, char)
    player = game.Players.LocalPlayer
    character = player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")

    framework.inventory[1] = "Ballista"
    framework.inventory[2] = "Knife"

    framework.module.ammo = framework.module.maxAmmo
    framework.module = nil
    framework.viewmodel = nil
    framework.currentSlot = 1

    humanoid.Died:Connect(function()
        if framework.viewmodel then
            framework.viewmodel:Destroy()
        end

        player = nil
        character = nil
        humanoid = nil

        local aimCF = CFrame.new()

        local isAiming = false
        local isShooting = false
        local isReloading = false
        local canShoot = true

        local debounce = false

        local currentSwayAMT = 0
        local swayAMT = -.2
        local aimSwayAMT = .15
        local swayCF = CFrame.new()
        local lastCameraCF = CFrame.new()

        local reloadAnim = nil
        local fireAnim = nil
        local fireSound = nil
    end)
end)
loadSlot(framework.inventory[1])
