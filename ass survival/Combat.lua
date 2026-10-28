local cloneref = cloneref or function(o) return o end

local playersService = cloneref(game:GetService("Players"))
local runService = cloneref(game:GetService("RunService"))
local userInputService = cloneref(game:GetService("UserInputService"))
local workspaceService = cloneref(game:GetService("Workspace"))

local Combat = {}
Combat.__index = Combat

local localPlayer = playersService.LocalPlayer
local mouse = localPlayer:GetMouse()
local currentCamera = workspaceService.CurrentCamera

local aimKeyActive = false
local targetPart = nil
local targetPlayer = nil

-- Сохраняем линк на ремут попадания для ручного инжекта
local bulletHitRemote = nil 
local processedShots = {}

local CombatConfig = {
	Enabled = false,
	AimMode = "Silent Aim",
	Keybind = Enum.UserInputType.MouseButton2,
	KeybindMode = "Hold",
	AimActive = false,
	HitPart = "Head",
	HitChance = 100,
	Smoothness = 2,

	BulletSpeed = 500,
	BulletGravity = 8,
	AutoCompensate = true,

	WallCheck = true,
	
	-- Экспериментальный обход Time Delta
	InstaHit = true,
	InstaMethod = "Velocity Spoof", 

	TargetPlayers = true,
	TargetBots = true,
	TeamCheck = false,
	DeadCheck = true,
	DistCheck = false,
	MaxDistance = 1000,

	FOV = 100,
	ShowFOV = false,
	FOVColor = Color3.fromRGB(255, 255, 255),
	FOVOutline = false,
}

local function checkVisibility(origin, targetPos, ignoreChar)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {localPlayer.Character, ignoreChar, currentCamera}
	params.IgnoreWater = true
	return workspaceService:Raycast(origin, (targetPos - origin), params) == nil 
end

local function getTargetEntities()
	local entities = {}
	local myChar = localPlayer.Character

	for _, obj in ipairs(workspaceService:GetChildren()) do
		if not obj:IsA("Model") or obj == myChar then continue end

		local humanoid = obj:FindFirstChildOfClass("Humanoid")
		local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChild("Torso")
		if not (humanoid and root) then continue end
		if CombatConfig.DeadCheck and humanoid.Health <= 0 then continue end

		local player = playersService:GetPlayerFromCharacter(obj)
		local isBot = (player == nil)

		if isBot and not CombatConfig.TargetBots then continue end
		if not isBot and not CombatConfig.TargetPlayers then continue end
		if not isBot and CombatConfig.TeamCheck and localPlayer.Team and player.Team == localPlayer.Team then continue end

		table.insert(entities, {
			Model = obj,
			Player = player,
			IsBot = isBot,
			Humanoid = humanoid,
			RootPart = root
		})
	end
	return entities
end

local function rollHitChance()
	if CombatConfig.HitChance >= 100 then return true end
	if CombatConfig.HitChance <= 0 then return false end
	return math.random(1, 100) <= CombatConfig.HitChance
end

local function getClosestTarget()
	local closestPart, closestTarget = nil, nil
	local maxFovRadius = (currentCamera.ViewportSize.X * (CombatConfig.FOV / currentCamera.FieldOfView)) / 2
	local mousePos = userInputService:GetMouseLocation()
	local camPos = currentCamera.CFrame.Position

	for _, entity in ipairs(getTargetEntities()) do
		local char = entity.Model
		local part = char:FindFirstChild(CombatConfig.HitPart) or entity.RootPart or char:FindFirstChild("Head")
		if not part or not part:IsA("BasePart") then continue end

		local distToCam = (camPos - part.Position).Magnitude
		if CombatConfig.DistCheck and distToCam > CombatConfig.MaxDistance then continue end

		local screenPos, onScreen = currentCamera:WorldToViewportPoint(part.Position)
		if not onScreen then continue end

		if CombatConfig.WallCheck and not checkVisibility(camPos, part.Position, char) then continue end

		local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
		if dist <= maxFovRadius then
			maxFovRadius = dist
			closestPart = part
			closestTarget = entity.Player or entity.Model
		end
	end
	return closestPart, closestTarget
end

local function calculateTrajectory(origin, targetPos, speed, gravity)
	local diff = targetPos - origin
	local dx = Vector2.new(diff.X, diff.Z).Magnitude
	local dy = diff.Y
	local v2 = speed * speed
	local v4 = v2 * v2
	local root = v4 - gravity * (gravity * dx * dx + 2 * dy * v2)

	if root < 0 then return diff.Unit end

	local angle = math.atan2(v2 - math.sqrt(root), gravity * dx)
	local dir2d = Vector3.new(diff.X, 0, diff.Z).Unit
	return (dir2d * math.cos(angle) + Vector3.new(0, 1, 0) * math.sin(angle)).Unit
end

function Combat:GetConfig() return CombatConfig end
function Combat:SetAimActive(state)
	aimKeyActive = state
	CombatConfig.AimActive = state
end

function Combat:Load()
	runService.RenderStepped:Connect(function()
		currentCamera = workspaceService.CurrentCamera or currentCamera

		local mpos = userInputService:GetMouseLocation()
		local radius = (currentCamera.ViewportSize.X * (CombatConfig.FOV / currentCamera.FieldOfView)) / 2

		circleInline.Position = mpos
		circleInline.Radius = radius
		circleInline.Color = CombatConfig.FOVColor
		circleInline.Visible = CombatConfig.Enabled and CombatConfig.ShowFOV

		circleOutline.Position = mpos
		circleOutline.Radius = radius
		circleOutline.Visible = CombatConfig.Enabled and CombatConfig.ShowFOV and CombatConfig.FOVOutline

		if CombatConfig.Enabled then
			targetPart, targetPlayer = getClosestTarget()
		else
			targetPart, targetPlayer = nil, nil
		end
	end)

	runService:BindToRenderStep("CombatAimbot", Enum.RenderPriority.Camera.Value + 1, function()
		local isAiming = aimKeyActive or CombatConfig.AimActive
		if CombatConfig.Enabled and CombatConfig.AimMode == "Aimbot" and isAiming and targetPart then
			local camPos = currentCamera.CFrame.Position
			local targetLook
			
			if CombatConfig.AutoCompensate then
				local dir = calculateTrajectory(camPos, targetPart.Position, CombatConfig.BulletSpeed, CombatConfig.BulletGravity)
				targetLook = CFrame.lookAt(camPos, camPos + dir)
			else
				targetLook = CFrame.lookAt(camPos, targetPart.Position)
			end

			local smoothFactor = math.clamp(CombatConfig.Smoothness, 1, 30)
			if smoothFactor <= 1 then
				currentCamera.CFrame = targetLook
			else
				currentCamera.CFrame = currentCamera.CFrame:Lerp(targetLook, 1 / smoothFactor)
			end
		end
	end)

	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		if checkcaller() or not CombatConfig.Enabled then return oldNamecall(self, ...) end

		local method = getnamecallmethod()
		local args = {...}

		if method == "FireServer" then
			local pIndex = (type(args[1]) == "string" and type(args[2]) == "table") and 2 or 1
			local payload = args[pIndex]

			if type(payload) == "table" then
				-- КЕШИРУЕМ РЕМУТ ПОПАДАНИЯ ДЛЯ ИНЖЕКТА
				if payload.shotId and payload.part and payload.pos and not payload.origin then
					bulletHitRemote = self
					
					-- Блокируем двойную отправку, если мы уже отправили инста-хит
					if CombatConfig.InstaHit and processedShots[payload.shotId] then
						return nil
					end
					
					-- Если это легитный хит, корректируем парту
					if CombatConfig.AimMode == "Silent Aim" and targetPart and rollHitChance() then
						local newPayload = {}
						for k, v in pairs(payload) do newPayload[k] = v end
						newPayload.part = targetPart
						newPayload.pos = targetPart.Position
						args[pIndex] = newPayload
						return oldNamecall(self, unpack(args))
					end
				end

				-- ПЕРЕХВАТ ВЫСТРЕЛА
				if payload.origin and payload.dir and payload.shotId and CombatConfig.AimMode == "Silent Aim" and targetPart and rollHitChance() then
					local newPayload = {}
					for k, v in pairs(payload) do newPayload[k] = v end
					
					local origin = newPayload.origin
					local tPos = targetPart.Position
					
					if CombatConfig.InstaHit and CombatConfig.InstaMethod == "Velocity Spoof" then
						-- ТЕОРИЯ: Если сервер не делает .Unit, мы умножаем вектор в 9999 раз. 
						-- Скорость пули на сервере становится бесконечной. Time Delta = 0.
						newPayload.dir = (tPos - origin).Unit * 9999 
						args[pIndex] = newPayload
						
						processedShots[newPayload.shotId] = true
						
						-- Отправляем пакет выстрела
						local fireResult = oldNamecall(self, unpack(args))
						
						-- Моментально спавним пакет попадания, т.к. сервер думает, что пуля уже долетела
						task.spawn(function()
							if bulletHitRemote then
								bulletHitRemote:FireServer({
									shotId = newPayload.shotId,
									pellet = 1,
									part = targetPart,
									pos = tPos
								})
							end
						end)
						
						return fireResult
					else
						-- Легитная баллистика
						local dist = (tPos - origin).Magnitude
						local travelTime = dist / CombatConfig.BulletSpeed
						local predictedPos = tPos + (targetPart.AssemblyLinearVelocity * travelTime)

						if CombatConfig.AutoCompensate then
							newPayload.dir = calculateTrajectory(origin, predictedPos, CombatConfig.BulletSpeed, CombatConfig.BulletGravity)
						else
							newPayload.dir = (predictedPos - origin).Unit
						end
						
						args[pIndex] = newPayload
						return oldNamecall(self, unpack(args))
					end
				end
			end
		end

		return oldNamecall(self, unpack(args))
	end))
end

print("hsdhsdhsdhsd")
return Combat
