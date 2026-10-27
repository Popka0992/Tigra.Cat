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
	BowPrediction = true, 

	InstaHit = false,
	InstaMethod = "Trust Client", -- "Trust Client", "Origin Spoof", "Speed Abuse", "Skip Raycast"

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
	}
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

local function checkVisibility(origin, targetPos, ignoreChar)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {localPlayer.Character, ignoreChar, currentCamera}
	params.IgnoreWater = true

	local result = workspaceService:Raycast(origin, (targetPos - origin), params)
	return result == nil 
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
		if checkcaller() or not CombatConfig.Enabled then
			return oldNamecall(self, ...)
		end

		local method = getnamecallmethod()
		local args = {...}

		if method == "FireServer" and CombatConfig.Methods.Network and CombatConfig.AimMode == "Silent Aim" and targetPart and rollHitChance() then
			local pIndex = (type(args[1]) == "string" and type(args[2]) == "table") and 2 or 1
			local payload = args[pIndex]
			
			if type(payload) == "table" then
				local newPayload = {}
				for k, v in pairs(payload) do newPayload[k] = v end
				
				local modified = false
				local tPos = targetPart.Position
				
				if newPayload.charge ~= nil then
					if CombatConfig.InstaHit then
						newPayload.origin = tPos + Vector3.new(0, 2, 0)
						newPayload.dir = Vector3.new(0, -1, 0)
						newPayload.charge = 999999
						modified = true
					else
						local charge = math.clamp(newPayload.charge, 0.15, 1)
						local speed = 125 * charge + 95
						local gravity = 50
						local origin = newPayload.origin or currentCamera.CFrame.Position
						
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
						else
							newPayload.dir = (tPos - origin).Unit
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
							modified = true
						end
					else
						if newPayload.aiming ~= nil and newPayload.dir ~= nil and newPayload.origin ~= nil then
							newPayload.dir = (tPos - newPayload.origin).Unit
							modified = true
						elseif newPayload.pellet ~= nil and newPayload.part ~= nil and newPayload.pos ~= nil then
							newPayload.part = targetPart
							newPayload.pos = tPos
							newPayload.normal = Vector3.new(0, 1, 0)
							modified = true
						end
					end
				end
				
				if modified then
					args[pIndex] = newPayload
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

		local hitpos = targetPart.Position

		-- Легитная длина луча (Без Projection Override)
		if method == "Raycast" and CombatConfig.Methods.Raycast then
			local origin, direction, params = args[1], args[2], args[3]
			if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
				local newDir = (hitpos - origin).Unit * direction.Magnitude
				return oldNamecall(self, origin, newDir, params)
			end
		end

		if method == "Spherecast" and CombatConfig.Methods.Spherecast then
			local origin, radius, direction, params = args[1], args[2], args[3], args[4]
			if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
				local newDir = (hitpos - origin).Unit * direction.Magnitude
				return oldNamecall(self, origin, radius, newDir, params)
			end
		end

		if (method == "ScreenPointToRay" and CombatConfig.Methods.ScreenPointToRay) or (method == "ViewportPointToRay" and CombatConfig.Methods.ViewportPointToRay) then
			local ray = oldNamecall(self, ...)
			local origin = ray.Origin
			local direction = ray.Direction
			local newDir = (hitpos - origin).Unit * direction.Magnitude

			return Ray.new(origin, newDir)
		end

		if method:find("FindPartOnRay") and (CombatConfig.Methods[method] or CombatConfig.Methods.FindPartOnRay) then
			local ray, ignoreList, terrainCellsAreCubes, ignoreWater = args[1], args[2], args[3], args[4]
			if typeof(ray) == "Ray" then
				local origin = ray.Origin
				local direction = ray.Direction
				local newDir = (hitpos - origin).Unit * direction.Magnitude
				return oldNamecall(self, Ray.new(origin, newDir), ignoreList, terrainCellsAreCubes, ignoreWater)
			end
		end

		return oldNamecall(self, ...)
	end))
end

print("im 100000 detected insta ban")
return Combat
