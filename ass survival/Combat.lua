-- Services.
local cloneref = cloneref or function(o) return o end

local playersService = cloneref(game:GetService("Players"))
local runService = cloneref(game:GetService("RunService"))
local userInputService = cloneref(game:GetService("UserInputService"))
local workspaceService = cloneref(game:GetService("Workspace"))

-- Constants.
local TRACER_TEXTURES = {
	["1"] = "rbxassetid://119094363918228",
	["2"] = "rbxassetid://18722421816",
	["3"] = "rbxassetid://18654087326",
	["4"] = "rbxassetid://6045867277",
	["5"] = "rbxassetid://135770390535538",
	["6"] = "rbxassetid://97236022367376",
	["7"] = "rbxassetid://6091329339"
}

local FILTER_TYPE = Enum.RaycastFilterType and (Enum.RaycastFilterType.Exclude or Enum.RaycastFilterType.Blacklist)

local Combat = {}
Combat.__index = Combat

-- State.
local localPlayer = playersService.LocalPlayer
local mouse = localPlayer:GetMouse()
local currentCamera = workspaceService.CurrentCamera

local isInternalRaycast = false
local aimKeyActive = false
local targetPart = nil
local targetPlayer = nil
local lastPhysicalShotTick = 0
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

	WallCheck = true,
	ProjectionOverride = true,
	MagicBullet = true,
	BowPrediction = true,

	InstaHit = false,
	InstaMethod = "Trust Client",

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

	Tracers = {
		Enabled = true,
		ReplaceProjectile = true,
		SimulateFallback = true,
		Texture = "1",
		Color = Color3.fromRGB(255, 50, 50),
		Width = 0.5,
		Lifetime = 0.35,
		SimSpeed = 350,
		SimGravity = 25
	},

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
Combat.TracerTextures = TRACER_TEXTURES

local tracerRaycastParams = RaycastParams.new()
tracerRaycastParams.FilterType = FILTER_TYPE
tracerRaycastParams.IgnoreWater = true

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

local function isWeldedToPlayer(part)
	if not part then return false end
	local char = localPlayer.Character
	if char and part:IsDescendantOf(char) then return true end
	if part:IsDescendantOf(currentCamera) then return true end

	for _, joint in ipairs(part:GetJoints()) do
		local connected = (joint.Part0 == part) and joint.Part1 or joint.Part0
		if connected then
			if (char and connected:IsDescendantOf(char)) or connected:IsDescendantOf(currentCamera) then
				return true
			end
		end
	end
	return false
end

local function applyTrailToInstance(targetPart)
	if targetPart:FindFirstChild("CustomTracerTrail") then return end

	local tracerCfg = CombatConfig.Tracers
	local att0 = Instance.new("Attachment")
	att0.Name = "TracerAtt0"
	att0.Position = Vector3.new(0, (tracerCfg.Width or 0.5) * 0.5, 0)
	att0.Parent = targetPart

	local att1 = Instance.new("Attachment")
	att1.Name = "TracerAtt1"
	att1.Position = Vector3.new(0, -(tracerCfg.Width or 0.5) * 0.5, 0)
	att1.Parent = targetPart

	local trail = Instance.new("Trail")
	trail.Name = "CustomTracerTrail"
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Texture = TRACER_TEXTURES[tostring(tracerCfg.Texture)] or TRACER_TEXTURES["1"]
	trail.Color = ColorSequence.new(tracerCfg.Color or Color3.fromRGB(255, 50, 50))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.Lifetime = tracerCfg.Lifetime or 0.35
	trail.FaceCamera = true
	trail.LightEmission = 1
	trail.LightInfluence = 0
	trail.Parent = targetPart
end

local function createFlyingTracer(startPos, endPos)
	local tracerCfg = CombatConfig.Tracers
	if not tracerCfg or not tracerCfg.Enabled then return end

	local char = localPlayer.Character
	if char then
		tracerRaycastParams.FilterDescendantsInstances = {char, currentCamera}
	end

	local direction = (endPos - startPos).Unit
	local speed = tracerCfg.SimSpeed or 350
	local currentVelocity = direction * speed
	local currentPosition = startPos
	local gravVector = Vector3.new(0, tracerCfg.SimGravity or 25, 0)

	local projectilePart = Instance.new("Part")
	projectilePart.Size = Vector3.new(0.1, 0.1, 0.1)
	projectilePart.Transparency = 1
	projectilePart.CanCollide = false
	projectilePart.CanQuery = false
	projectilePart.CanTouch = false
	projectilePart.Anchored = true
	projectilePart.CFrame = CFrame.lookAt(startPos, endPos)
	projectilePart.Parent = workspaceService.Terrain

	applyTrailToInstance(projectilePart)

	local connection
	local startTime = os.clock()

	connection = runService.RenderStepped:Connect(function(dt)
		if os.clock() - startTime > 4 then
			connection:Disconnect()
			projectilePart:Destroy()
			return
		end

		local nextPosition = currentPosition + (currentVelocity * dt)
		currentVelocity = currentVelocity - (gravVector * dt)

		local travelVector = nextPosition - currentPosition
		local rayResult = workspaceService:Raycast(currentPosition, travelVector, tracerRaycastParams)

		if rayResult then
			connection:Disconnect()
			projectilePart.CFrame = CFrame.lookAt(rayResult.Position, rayResult.Position + currentVelocity)
			task.delay(tracerCfg.Lifetime or 0.35, function()
				projectilePart:Destroy()
			end)
			return
		end

		currentPosition = nextPosition
		projectilePart.CFrame = CFrame.lookAt(currentPosition, currentPosition + currentVelocity)
	end)
end

local function hookProjectile(instance)
	local tracerCfg = CombatConfig.Tracers
	if not tracerCfg or not tracerCfg.Enabled then return end

	task.defer(function()
		if not instance or not instance.Parent then return end

		local part = instance:IsA("BasePart") and instance or instance:FindFirstChildWhichIsA("BasePart")
		if not part then return end

		local char = localPlayer.Character
		if isWeldedToPlayer(part) then return end

		local camPos = currentCamera.CFrame.Position
		local headPos = char and char:FindFirstChild("Head") and char.Head.Position or camPos
		local originDist = math.min((part.Position - camPos).Magnitude, (part.Position - headPos).Magnitude)
		if originDist > 30 then return end

		local name = instance.Name:lower()
		local isProjName = name:find("arrow") or name:find("bolt") or name:find("bullet") or name:find("proj") or name:find("ammo")

		local startPos = part.Position
		task.wait(0.02)

		if not part or not part.Parent or isWeldedToPlayer(part) then return end

		local vel = part.AssemblyLinearVelocity or part.Velocity
		local speed = vel and vel.Magnitude or 0
		local distMoved = (part.Position - startPos).Magnitude

		if isProjName then
			if speed < 40 and distMoved < 1.0 then
				return
			end
		else
			if speed < 70 or distMoved < 2.0 then
				return
			end
		end

		lastPhysicalShotTick = os.clock()

		if tracerCfg.ReplaceProjectile then
			if instance:IsA("BasePart") then
				instance.Transparency = 1
			end
			for _, descendant in ipairs(instance:GetDescendants()) do
				if descendant:IsA("BasePart") or descendant:IsA("Decal") or descendant:IsA("Texture") then
					descendant.Transparency = 1
				elseif descendant:IsA("Trail") or descendant:IsA("Beam") or descendant:IsA("ParticleEmitter") then
					descendant.Enabled = false
				end
			end
		end

		applyTrailToInstance(part)
	end)
end

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

local function isTargetVisible(target, targetModel)
	if not CombatConfig.WallCheck then return true end

	local origin = currentCamera.CFrame.Position
	local direction = target.Position - origin

	local params = RaycastParams.new()
	params.FilterType = FILTER_TYPE
	params.FilterDescendantsInstances = {localPlayer.Character, currentCamera}
	params.IgnoreWater = true

	local result = workspaceService:Raycast(origin, direction, params)

	if result and result.Instance then
		if result.Instance:IsDescendantOf(targetModel) then
			return true
		end
		return false
	end

	return true
end

local function getClosestTarget()
	local closestPart, closestTarget = nil, nil
	local maxFovRadius = CombatConfig.FOV
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
			if isTargetVisible(part, char) then
				maxFovRadius = dist
				closestPart = part
				closestTarget = entity.Player or entity.Model
			end
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

	workspaceService.DescendantAdded:Connect(hookProjectile)

	runService.RenderStepped:Connect(function()
		currentCamera = workspaceService.CurrentCamera or currentCamera

		local mpos = userInputService:GetMouseLocation()
		local fovRadius = CombatConfig.FOV

		circleInline.Position = mpos
		circleInline.Radius = fovRadius
		circleInline.Color = CombatConfig.FOVColor
		circleInline.Visible = CombatConfig.Enabled and CombatConfig.ShowFOV

		circleOutline.Position = mpos
		circleOutline.Radius = fovRadius
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
		if isInternalRaycast or checkcaller() then
			return oldNamecall(self, ...)
		end

		local method = getnamecallmethod()
		local args = {...}

		if method == "FireServer" and CombatConfig.Methods.Network then
			local pIndex = (type(args[1]) == "string" and type(args[2]) == "table") and 2 or 1
			local payload = args[pIndex]

			if type(payload) == "table" and (payload.charge ~= nil or payload.pellet ~= nil or payload.dir ~= nil or payload.aiming ~= nil) then
				local origin = payload.origin or currentCamera.CFrame.Position
				local tracerTarget = nil

				if CombatConfig.Enabled and CombatConfig.AimMode == "Silent Aim" and targetPart and rollHitChance() then
					local newPayload = {}
					for k, v in pairs(payload) do newPayload[k] = v end

					local modified = false
					local tPos = targetPart.Position

					if newPayload.charge ~= nil then
						if CombatConfig.InstaHit then
							newPayload.origin = tPos + Vector3.new(0, 2, 0)
							newPayload.dir = Vector3.new(0, -1, 0)
							newPayload.charge = 999999
							origin = newPayload.origin
							tracerTarget = tPos
							modified = true
						else
							local charge = math.clamp(newPayload.charge, 0.15, 1)
							local speed = 125 * charge + 95
							local gravity = 50

							if CombatConfig.BowPrediction then
								local dist = (tPos - origin).Magnitude
								local t = dist / speed

								for i = 1, 2 do
									local drop = 0.5 * gravity * (t * t)
									local predictedPos = tPos + (targetPart.AssemblyLinearVelocity * t) + Vector3.new(0, drop, 0)
									t = (predictedPos - origin).Magnitude / speed
								end

								local finalDrop = 0.5 * gravity * (t * t)
								local finalTarget = tPos + (targetPart.AssemblyLinearVelocity * t) + Vector3.new(0, finalDrop, 0)
								newPayload.dir = (finalTarget - origin).Unit
								tracerTarget = finalTarget
							else
								newPayload.dir = (tPos - origin).Unit
								tracerTarget = tPos
							end
							modified = true
						end
					else
						if CombatConfig.InstaHit then
							if CombatConfig.InstaMethod == "Trust Client" then
								if newPayload.pellet ~= nil or newPayload.part ~= nil then
									newPayload.part = targetPart
									newPayload.pos = tPos
									newPayload.normal = Vector3.new(0, 1, 0)
									modified = true
								end
								if newPayload.dir ~= nil and newPayload.origin ~= nil then
									newPayload.dir = (tPos - newPayload.origin).Unit
									modified = true
								end
								tracerTarget = tPos
							elseif CombatConfig.InstaMethod == "Origin Spoof" then
								if newPayload.dir ~= nil and newPayload.origin ~= nil then
									newPayload.origin = tPos
									newPayload.dir = Vector3.new(0, -1, 0)
									modified = true
								end
								if newPayload.pellet ~= nil or newPayload.part ~= nil then
									newPayload.part = targetPart
									newPayload.pos = tPos
									newPayload.normal = Vector3.new(0, 1, 0)
									modified = true
								end
								origin = tPos
								tracerTarget = tPos + Vector3.new(0, -5, 0)
							elseif CombatConfig.InstaMethod == "Speed Abuse" then
								if newPayload.pellet ~= nil or newPayload.part ~= nil then
									newPayload.part = targetPart
									newPayload.pos = tPos
									newPayload.normal = Vector3.new(0, 1, 0)
									modified = true
								end
								if newPayload.dir ~= nil and newPayload.origin ~= nil then
									newPayload.dir = (tPos - newPayload.origin).Unit
									modified = true
								end
								tracerTarget = tPos
							elseif CombatConfig.InstaMethod == "Skip Raycast" then
								newPayload.t = 0
								newPayload.time = 0
								if newPayload.pellet ~= nil or newPayload.part ~= nil then
									newPayload.part = targetPart
									newPayload.pos = tPos
									newPayload.normal = Vector3.new(0, 1, 0)
								end
								if newPayload.dir ~= nil and newPayload.origin ~= nil then
									newPayload.dir = (tPos - newPayload.origin).Unit
								end
								tracerTarget = tPos
								modified = true
							end
						else
							if newPayload.aiming ~= nil and newPayload.dir ~= nil and newPayload.origin ~= nil then
								newPayload.dir = (tPos - newPayload.origin).Unit
								tracerTarget = tPos
								modified = true
							elseif newPayload.pellet ~= nil and newPayload.part ~= nil and newPayload.pos ~= nil then
								newPayload.part = targetPart
								newPayload.pos = tPos
								newPayload.normal = Vector3.new(0, 1, 0)
								tracerTarget = tPos
								modified = true
							end
						end
					end

					if modified then
						args[pIndex] = newPayload
						task.delay(0.06, function()
							if os.clock() - lastPhysicalShotTick >= 0.055 and CombatConfig.Tracers.SimulateFallback then
								createFlyingTracer(origin, tracerTarget or tPos)
							end
						end)
						return oldNamecall(self, unpack(args))
					end
				end

				local shotDir = payload.dir or (payload.pos and (payload.pos - origin).Unit) or currentCamera.CFrame.LookVector
				local targetEnd = payload.pos or (origin + shotDir * 500)
				task.delay(0.06, function()
					if os.clock() - lastPhysicalShotTick >= 0.055 and CombatConfig.Tracers.SimulateFallback then
						createFlyingTracer(origin, targetEnd)
					end
				end)
			end

			return oldNamecall(self, ...)
		end

		if not CombatConfig.Enabled then
			return oldNamecall(self, ...)
		end

		if not (method == "Raycast" or method == "Spherecast" or method == "ScreenPointToRay" or method == "ViewportPointToRay" or method:find("FindPartOnRay")) then
			return oldNamecall(self, ...)
		end

		if CombatConfig.AimMode ~= "Silent Aim" or not targetPart or not rollHitChance() then
			return oldNamecall(self, ...)
		end

		local hitpart = targetPart
		local hitpos = hitpart.Position

		if method == "Raycast" and CombatConfig.Methods.Raycast then
			local origin, direction, params = args[1], args[2], args[3]
			if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
				local newDir = CombatConfig.ProjectionOverride and (hitpos - origin) or (hitpos - origin).Unit * direction.Magnitude
				return oldNamecall(self, origin, newDir, params)
			end
		end

		if method == "Spherecast" and CombatConfig.Methods.Spherecast then
			local origin, radius, direction, params = args[1], args[2], args[3], args[4]
			if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
				local newDir = CombatConfig.ProjectionOverride and (hitpos - origin) or (hitpos - origin).Unit * direction.Magnitude
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
				return oldNamecall(self, Ray.new(origin, newDir), ignoreList, terrainCellsAreCubes, ignoreWater)
			end
		end

		return oldNamecall(self, ...)
	end))
end

return Combat
