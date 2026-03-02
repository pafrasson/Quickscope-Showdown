local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

local camera = game.Workspace.CurrentCamera

-- Config
local WALK_SPEED = 18
local SPRINT_SPEED = 25
local FOV_NORMAL = 70
local FOV_SPRINTING = 80

-- Controle de Estado
local isShiftHeld = false -- O jogador está segurando a tecla?
local isSprinting = false -- O personagem está REALMENTE correndo?

local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

-- Detectar se a tecla está pressionada
userInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isShiftHeld = true
	end
end)

userInputService.InputEnded:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isShiftHeld = false
	end
end)

-- Loop Principal (Roda todo frame)
runService.RenderStepped:Connect(function()
	if not humanoid then return end

	-- 1. LÓGICA DE DETECÇÃO "PRA FRENTE" --------------------------
	local moveDir = humanoid.MoveDirection
	local lookDir = camera.CFrame.LookVector

	-- Ignoramos a altura (Y) para calcular apenas a direção no chão
	local moveFlat = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
	local lookFlat = Vector3.new(lookDir.X, 0, lookDir.Z).Unit

	-- O Dot Product retorna: 1 (Frente), 0 (Lado), -1 (Trás)
	-- Usamos 0.1 para permitir correr levemente na diagonal (W+A ou W+D)
	local isMovingForward = false

	-- Verifica se está se movendo (Magnitude > 0) E se a direção é compativel com a câmera
	if moveDir.Magnitude > 0 and moveFlat:Dot(lookFlat) > 0.1 then
		isMovingForward = true
	end

	-- 2. DECISÃO DE CORRER ----------------------------------------
	-- Só corre se: Apertou Shift + Está indo pra frente + Não está exausto (futuro)
	local shouldSprint = isShiftHeld and isMovingForward

	-- Só aplica as mudanças se o estado MUDOU (pra não ficar travando o script)
	if shouldSprint ~= isSprinting then
		isSprinting = shouldSprint

		character:SetAttribute("IsSprinting", isSprinting)

		if isSprinting then
			-- Começou a correr
			character:SetAttribute("IsSprinting", true)
			humanoid.WalkSpeed = SPRINT_SPEED
			tweenService:Create(camera, tweenInfo, {FieldOfView = FOV_SPRINTING}):Play()
		else
			-- Parou de correr (Soltou shift OU começou a andar pra trás)
			character:SetAttribute("IsSprinting", false)
			humanoid.WalkSpeed = WALK_SPEED
			tweenService:Create(camera, tweenInfo, {FieldOfView = FOV_NORMAL}):Play()
		end
	end

	if humanoid.MoveDirection.Magnitude > 0 then
		local t = tick()
		local bobY = math.sin(t * 14) * 0.4
		local bobX = math.cos(t * 7) * 0.2 

		-- Se NÃO estiver correndo (WalkSpeed baixo), suaviza o balanço
		if humanoid.WalkSpeed == WALK_SPEED then
			bobY = math.sin(t * 7) * 0.2
			bobX = math.cos(t * 3.5) * 0.1
		end

		local bob = Vector3.new(bobX, bobY, 0)
		humanoid.CameraOffset = humanoid.CameraOffset:Lerp(bob, .1)
	else
		humanoid.CameraOffset = humanoid.CameraOffset:Lerp(Vector3.new(), .1)
	end
end)
