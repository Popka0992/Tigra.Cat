-- combat module optimized for FustGuns & FustCombat (Bow Ballistics)
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

local isInternalRaycast = false
local aimKeyActive = false
local targetPart = nil
local targetPlayer = nil
local originalPartSizes = {}

local CombatConfig = {
	AimMode = "Silent Aim",
	Enabled = false,
	Keybind = Enum.UserInputType.MouseButton2,
	KeybindMode = "Hold",
	AimActive = false,
	HitPart = "Head",
	HitChance = 100,
	Smoothness = 2,

	Wallbang = false,
	ProjectionOverride = true,
	MagicBullet = true,
	BowPrediction = true, 

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

	Methods = {
		Raycast = true,
		Spherecast = true,
		FindPartOnRay = true,
		FindPartOnRayWithWhitelist = true,
		FindPartOnRayWithIgnoreList = true,
		ScreenPointToRay = true,
		ViewportPointToRay = true,
		Mouse = true,
		Network = true
	},

	HitboxEnabled = false,
	HitboxSize = 6,
	HitboxTrans = 0.6,
	HitboxPart = "All Parts",
	HitboxCustom = true
}

local scannedPartsList = {"All Parts", "Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}
local scannedPartsSet = {}
for _, name in ipairs(scannedPartsList) do
	scannedPartsSet[name] = true
end

Combat.PartsList = scannedPartsList

local circleOutline = Drawing.new("Circle")
circleOutline.Thickness = 3
circleOutline.Color = Color3.new(0, 0, 0)
circleOutline.Filled = false
circleOutline.ZIndex = 1
circleOutline.Visible = false

local circleInline = Drawing.new("Circle")
circleInline.Thickness = 1
circleInline.Filled = false
circleInline.ZIndex = 2
circleInline.Visible = false

local function getTargetEntities()
	local entities = {}
	local myChar = localPlayer.Character

	for _, obj in ipairs(workspaceService:GetChildren()) do
		if not obj:IsA("Model") or obj == myChar then continue end

		local humanoid = obj:FindFirstChildOfClass("Humanoid")
		local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso")
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

local function scanCharacterParts()
	local updated = false
	for _, entity in ipairs(getTargetEntities()) do
		for _, child in ipairs(entity.Model:GetDescendants()) do
			if child:IsA("BasePart") and not scannedPartsSet[child.Name] then
				scannedPartsSet[child.Name] = true
				table.insert(scannedPartsList, child.Name)
				updated = true
			end
		end
	end
	return updated
end

local function rollHitChance()
	if CombatConfig.HitChance >= 100 then return true end
	if CombatConfig.HitChance <= 0 then return false end
	return math.random(1, 100) <= CombatConfig.HitChance
end

local function getClosestTarget()
	local closestPart, closestTarget = nil, nil
	local viewportSize = currentCamera.ViewportSize
	local maxFovRadius = (viewportSize.X * (CombatConfig.FOV / currentCamera.FieldOfView)) / 2
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

		local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
		if dist <= maxFovRadius then
			maxFovRadius = dist
			closestPart = part
			closestTarget = entity.Player or entity.Model
		end
	end

	return closestPart, closestTarget
end

function Combat:GetConfig()
	return CombatConfig
end

function Combat:RefreshParts()
	return scanCharacterParts()
end

function Combat:SetAimActive(state)
	aimKeyActive = state
	CombatConfig.AimActive = state
end

function Combat:Load()
	scanCharacterParts()

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
		if CombatConfig.Enabled and CombatConfig.AimMode == "Aimbot" and isAiming and targetPart and targetPart.Parent then
			local camPos = currentCamera.CFrame.Position
			local targetLook = CFrame.lookAt(camPos, targetPart.Position)
			local smoothFactor = math.clamp(CombatConfig.Smoothness, 1, 30)

			if smoothFactor <= 1 then
				currentCamera.CFrame = targetLook
			else
				currentCamera.CFrame = currentCamera.CFrame:Lerp(targetLook, 1 / smoothFactor)
			end
		end
	end)

	runService.Heartbeat:Connect(function()
		if not CombatConfig.HitboxEnabled then
			if next(originalPartSizes) ~= nil then
				for part, data in pairs(originalPartSizes) do
					if part and part.Parent and part:IsA("BasePart") then
						part.Size = data.Size
						part.Transparency = data.Transparency
						part.CanCollide = data.CanCollide
						part.Massless = data.Massless
					end
				end
				table.clear(originalPartSizes)
			end
			return
		end

		local targetSize = Vector3.new(CombatConfig.HitboxSize, CombatConfig.HitboxSize, CombatConfig.HitboxSize)

		for _, entity in ipairs(getTargetEntities()) do
			local pChar = entity.Model
			for _, part in ipairs(pChar:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					local isDefaultLimb = (part.Name == "Head" or part.Name:find("Torso") or part.Name:find("Arm") or part.Name:find("Leg"))

					local shouldExpand = false
					if CombatConfig.HitboxPart == "All Parts" or CombatConfig.HitboxPart == part.Name then
						shouldExpand = true
					end

					if not isDefaultLimb and CombatConfig.HitboxCustom then
						shouldExpand = true
					end

					if shouldExpand then
						if not originalPartSizes[part] then
							originalPartSizes[part] = {
								Size = part.Size,
								Transparency = part.Transparency,
								CanCollide = part.CanCollide,
								Massless = part.Massless
							}
						end

						part.Size = targetSize
						part.Transparency = CombatConfig.HitboxTrans
						part.CanCollide = false
						part.Massless = true
					end
				end
			end
		end
	end)

	local oldIndex
	oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
		if self ~= mouse or checkcaller() or not CombatConfig.Enabled then
			return oldIndex(self, key)
		end

		if key ~= "Hit" and key ~= "Target" then
			return oldIndex(self, key)
		end

		if CombatConfig.AimMode == "Silent Aim" and targetPart and CombatConfig.Methods.Mouse then
			if rollHitChance() then
				if key == "Target" then
					return targetPart
				elseif key == "Hit" then
					return targetPart.CFrame
				end
			end
		end

		return oldIndex(self, key)
	end))

	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		if isInternalRaycast or checkcaller() or not CombatConfig.Enabled then
			return oldNamecall(self, ...)
		end

		local method = getnamecallmethod()
		local args = {...}

		-- Перехват сетевых событий (Server-Authoritative для Bow, Client-Authoritative для Guns)
		if method == "FireServer" and CombatConfig.Methods.Network and CombatConfig.AimMode == "Silent Aim" and targetPart and rollHitChance() then
			local payload = args[1]
			if type(payload) == "table" and payload.shotId ~= nil then
				
				-- 1. Логика лука (FustCombat) - сервер сам симулирует полёт, меняем только dir
				if payload.charge ~= nil and payload.dir ~= nil and payload.origin ~= nil then
					local hitpos = targetPart.Position
					
					if CombatConfig.BowPrediction then
						local charge = math.clamp(payload.charge, 0.15, 1)
						local speed = 125 * charge + 95
						local gravity = 50
						
						-- Предсказание движения цели
						if targetPart.AssemblyLinearVelocity.Magnitude > 0 then
							local dist = (hitpos - payload.origin).Magnitude
							local t = dist / speed
							hitpos = hitpos + targetPart.AssemblyLinearVelocity * t
						end
						
						-- Точная баллистическая дуга
						local delta = hitpos - payload.origin
						local hDelta = Vector3.new(delta.X, 0, delta.Z)
						local x = hDelta.Magnitude
						local y = delta.Y

						local v2 = speed * speed
						local v4 = v2 * v2
						local root = v4 - gravity * (gravity * x * x + 2 * y * v2)

						if root > 0 then
							local angle = math.atan2(v2 - math.sqrt(root), gravity * x)
							payload.dir = (hDelta.Unit * math.cos(angle) + Vector3.new(0, 1, 0) * math.sin(angle)).Unit
						else
							-- Фолбэк для дальних (out-of-range)
							local timeToHit = delta.Magnitude / speed
							local drop = 0.5 * gravity * (timeToHit * timeToHit)
							payload.dir = (hitpos + Vector3.new(0, drop, 0) - payload.origin).Unit
						end
					else
						payload.dir = (hitpos - payload.origin).Unit
					end
					
					args[1] = payload
					return oldNamecall(self, unpack(args))
				end

				-- 2. Логика отправки выстрела (FustGuns)
				if payload.aiming ~= nil and payload.dir ~= nil and payload.origin ~= nil then
					payload.dir = (targetPart.Position - payload.origin).Unit
					args[1] = payload
					return oldNamecall(self, unpack(args))
				end
				
				-- 3. Логика регистрации попадания (FustGuns)
				if payload.pellet ~= nil and payload.part ~= nil and payload.pos ~= nil then
					payload.part = targetPart
					payload.pos = targetPart.Position
					args[1] = payload
					return oldNamecall(self, unpack(args))
				end
			end
			return oldNamecall(self, ...)
		end

		if not (method == "Raycast" or method == "Spherecast" or method == "ScreenPointToRay" or method == "ViewportPointToRay" or method:find("FindPartOnRay")) then
			return oldNamecall(self, ...)
		end

		if CombatConfig.AimMode ~= "Silent Aim" or not targetPart or not rollHitChance() then
			return oldNamecall(self, ...)
		end

		local hitpart = targetPart
		local hitsize = hitpart.Size
		local orgpos = hitpart.Position

		local hitpos = orgpos + Vector3.new(
			(math.random() - math.random()) * (hitsize.X / 10),
			(math.random() - math.random()) * (hitsize.Y / 10),
			(math.random() - math.random()) * (hitsize.Z / 10)
		)

		if method == "Raycast" and CombatConfig.Methods.Raycast then
			local origin, direction, params = args[1], args[2], args[3]
			if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
				local newDir = CombatConfig.ProjectionOverride and (hitpos - origin) or (hitpos - origin).Unit * direction.Magnitude

				if CombatConfig.Wallbang then
					local fakeParams = RaycastParams.new()
					fakeParams.FilterType = Enum.RaycastFilterType.Include
					fakeParams.FilterDescendantsInstances = {hitpart}
					fakeParams.IgnoreWater = true

					isInternalRaycast = true
					local forcedResult = workspaceService:Raycast(hitpos + Vector3.new(0, 2, 0), Vector3.new(0, -5, 0), fakeParams)
					isInternalRaycast = false

					if forcedResult then
						return forcedResult
					end
				end

				return oldNamecall(self, origin, newDir, params)
			end
		end

		if method == "Spherecast" and CombatConfig.Methods.Spherecast then
			local origin, radius, direction, params = args[1], args[2], args[3], args[4]
			if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
				local newDir = CombatConfig.ProjectionOverride and (hitpos - origin) or (hitpos - origin).Unit * direction.Magnitude
				
				if CombatConfig.Wallbang then
					local fakeParams = RaycastParams.new()
					fakeParams.FilterType = Enum.RaycastFilterType.Include
					fakeParams.FilterDescendantsInstances = {hitpart}
					fakeParams.IgnoreWater = true

					isInternalRaycast = true
					local forcedResult = workspaceService:Raycast(hitpos + Vector3.new(0, 2, 0), Vector3.new(0, -5, 0), fakeParams)
					isInternalRaycast = false

					if forcedResult then
						return forcedResult
					end
				end

				return oldNamecall(self, origin, radius, newDir, params)
			end
		end

		if (method == "ScreenPointToRay" and CombatConfig.Methods.ScreenPointToRay) or (method == "ViewportPointToRay" and CombatConfig.Methods.ViewportPointToRay) then
			local ray = oldNamecall(self, ...)
			local origin = ray.Origin
			local direction = ray.Direction
			local newDir = CombatConfig.ProjectionOverride and (hitpos - origin) or (hitpos - origin).Unit * direction.Magnitude

			return Ray.new(origin, newDir)
		end

		if method:find("FindPartOnRay") and (CombatConfig.Methods[method] or CombatConfig.Methods.FindPartOnRay) then
			local ray, ignoreList, terrainCellsAreCubes, ignoreWater = args[1], args[2], args[3], args[4]
			if typeof(ray) == "Ray" then
				local origin = ray.Origin
				local direction = ray.Direction
				local newDir = CombatConfig.ProjectionOverride and (hitpos - origin) or (hitpos - origin).Unit * direction.Magnitude

				if CombatConfig.Wallbang then
					return hitpart, CombatConfig.MagicBullet and Vector3.new(0/0, 0/0, 0/0) or hitpos, (origin - hitpos).Unit, hitpart.Material
				end

				return oldNamecall(self, Ray.new(origin, newDir), ignoreList, terrainCellsAreCubes, ignoreWater)
			end
		end

		return oldNamecall(self, ...)
	end))
end

return Combat
