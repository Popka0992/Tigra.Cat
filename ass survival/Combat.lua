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

	BowPrediction = true, 
	PredictionDot = false,
	PredictionDotColor = Color3.fromRGB(255, 0, 0),
	PredictionDotSize = 4,

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
		Mouse = true,
		FindPartOnRay = true,
		FindPartOnRayWithWhitelist = true,
		FindPartOnRayWithIgnoreList = true,
		ScreenPointToRay = true,
		ViewportPointToRay = true,
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

-- FOV Circle
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

-- Prediction Dot
local predDotOutline = Drawing.new("Circle")
predDotOutline.Thickness = 2
predDotOutline.Color = Color3.new(0, 0, 0)
predDotOutline.Filled = false
predDotOutline.ZIndex = 3
predDotOutline.Visible = false

local predDot = Drawing.new("Circle")
predDot.Thickness = 1
predDot.Filled = true
predDot.ZIndex = 4
predDot.Visible = false

-- Fust Constants
local FUST_BASE_SPEED = 95
local FUST_CHARGE_SPEED = 125
local FUST_GRAVITY = 50

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

-- Итеративный расчет предикшена (позиция + скорость цели + гравитация)
local function getPredictedPosition(tPos, tVel, origin, speed, gravity)
	local t = (tPos - origin).Magnitude / speed
	for i = 1, 4 do
		local drop = 0.5 * gravity * (t * t)
		local aimPoint = tPos + (tVel * t) + Vector3.new(0, drop, 0)
		t = (aimPoint - origin).Magnitude / speed
	end
	local finalDrop = 0.5 * gravity * (t * t)
	return tPos + (tVel * t) + Vector3.new(0, finalDrop, 0)
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

		-- Prediction Dot Render
		if CombatConfig.Enabled and CombatConfig.PredictionDot and targetPart then
			local origin = currentCamera.CFrame.Position
			-- Для дота считаем макс натяжение (220 стадов/сек)
			local maxSpeed = FUST_BASE_SPEED + FUST_CHARGE_SPEED 
			local predPos = getPredictedPosition(targetPart.Position, targetPart.AssemblyLinearVelocity, origin, maxSpeed, FUST_GRAVITY)

			local screenPos, onScreen = currentCamera:WorldToViewportPoint(predPos)
			if onScreen then
				predDot.Position = Vector2.new(screenPos.X, screenPos.Y)
				predDot.Radius = CombatConfig.PredictionDotSize
				predDot.Color = CombatConfig.PredictionDotColor
				predDot.Visible = true

				predDotOutline.Position = predDot.Position
				predDotOutline.Radius = CombatConfig.PredictionDotSize + 1
				predDotOutline.Visible = true
			else
				predDot.Visible = false
				predDotOutline.Visible = false
			end
		else
			predDot.Visible = false
			predDotOutline.Visible = false
		end
	end)

	runService:BindToRenderStep("CombatAimbot", Enum.RenderPriority.Camera.Value + 1, function()
		local isAiming = aimKeyActive or CombatConfig.AimActive
		if CombatConfig.Enabled and CombatConfig.AimMode == "Aimbot" and isAiming and targetPart and targetPart.Parent then
			local origin = currentCamera.CFrame.Position
			local aimPos = targetPart.Position

			if CombatConfig.BowPrediction then
				local maxSpeed = FUST_BASE_SPEED + FUST_CHARGE_SPEED
				aimPos = getPredictedPosition(targetPart.Position, targetPart.AssemblyLinearVelocity, origin, maxSpeed, FUST_GRAVITY)
			end

			local targetLook = CFrame.lookAt(origin, aimPos)
			local smoothFactor = math.clamp(CombatConfig.Smoothness, 1, 30)

			if smoothFactor <= 1 then
				currentCamera.CFrame = targetLook
			else
				currentCamera.CFrame = currentCamera.CFrame:Lerp(targetLook, 1 / smoothFactor)
			end
		end
	end)

	runService.Heartbeat:Connect(function()
		-- Хитбокс экспандер Fust (игнорим HRP, меняем коллизию на false чтобы не багать)
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

	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		if checkcaller() or not CombatConfig.Enabled then
			return oldNamecall(self, ...)
		end

		local method = getnamecallmethod()
		local args = {...}

		-- Перехват пакетов Fust
		if method == "FireServer" and CombatConfig.Methods.Network and CombatConfig.AimMode == "Silent Aim" and targetPart and rollHitChance() then
			local pIndex = (type(args[1]) == "string" and type(args[2]) == "table") and 2 or 1
			local payload = args[pIndex]
			
			if type(payload) == "table" and payload.charge ~= nil and payload.dir ~= nil then
				local newPayload = {}
				for k, v in pairs(payload) do newPayload[k] = v end
				
				local charge = math.clamp(newPayload.charge, 0.15, 1)
				local speed = FUST_CHARGE_SPEED * charge + FUST_BASE_SPEED
				local origin = newPayload.origin or currentCamera.CFrame.Position
				
				if CombatConfig.BowPrediction then
					local aimPos = getPredictedPosition(targetPart.Position, targetPart.AssemblyLinearVelocity, origin, speed, FUST_GRAVITY)
					newPayload.dir = (aimPos - origin).Unit
				else
					newPayload.dir = (targetPart.Position - origin).Unit
				end
				
				args[pIndex] = newPayload
				return oldNamecall(self, unpack(args))
			end
		end

		return oldNamecall(self, ...)
	end))
end

return Combat
