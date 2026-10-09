local cloneref = cloneref or function(o) return o end

-- Services.
local playersService = cloneref(game:GetService("Players"))
local runService = cloneref(game:GetService("RunService"))
local userInputService = cloneref(game:GetService("UserInputService"))
local workspaceService = cloneref(game:GetService("Workspace"))
local replicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

local localPlayer = playersService.LocalPlayer
local mouse = localPlayer:GetMouse()
local currentCamera = workspaceService.CurrentCamera

local Combat = {}
Combat.__index = Combat

local isInternalRaycast = false
local targetPart = nil
local currentWeapon = nil
local hitscanTargetPos = nil
local hitscanAngles = {}
local dynamicFovConnection = nil

local CombatConfig = {
	Enabled = false,
	HitPart = "Head",
	HitChance = 100,
	Wallbang = false,
	ProjectionOverride = false,
	TargetPlayers = true,
	TargetBots = true,
	TeamCheck = false,
	DeadCheck = true,
	DistCheck = false,
	MaxDistance = 1000,
	VisibleCheck = false,
	Prediction = false,
	InstantHit = false,
	Hitscan = false,
	HitscanDistance = 7,
	HitscanIndicator = false,
	HitscanIndicatorColor = Color3.fromRGB(255, 196, 0),
	Snapline = false,
	SnaplineColor = Color3.fromRGB(255, 255, 255),
	FOV = 120,
	DynamicFOV = false,
	ShowFOV = false,
	FOVColor = Color3.fromRGB(170, 85, 255),
	FOVOutline = true,
	Recoil = 100,
	Spread = 100,
	Firerate = 1,
	InstantEquip = false,
	ShootSprinting = false,
	ReloadSprinting = false,
	InstantReload = false,
	AutoReload = false,
	FastBow = false,
	InstantEoka = false
}

-- Drawings.
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

local snapline = Drawing.new("Line")
snapline.Thickness = 1
snapline.Color = Color3.new(1, 1, 1)
snapline.ZIndex = 3
snapline.Visible = false

local hitscanIndicator = Drawing.new("Text")
hitscanIndicator.Text = "hitscanning"
hitscanIndicator.Font = 2
hitscanIndicator.Center = true
hitscanIndicator.Outline = true
hitscanIndicator.OutlineColor = Color3.new(0, 0, 0)
hitscanIndicator.Size = 13
hitscanIndicator.ZIndex = 3
hitscanIndicator.Color = Color3.fromRGB(255, 196, 0)
hitscanIndicator.Visible = false

local BONE_PRIORITY = {
	"Head",
	"UpperTorso",
	"RightHand",
	"RightUpperArm",
	"LeftHand",
	"LeftUpperArm",
	"RightUpperLeg",
	"LeftUpperLeg"
}

---Update hitscan ray directions based on offset distance.
---@param dist number
local function updateHitscanAngles(dist)
	local axes = {
		Vector3.new(1, 0, 0).Unit,
		Vector3.new(-1, 0, 0).Unit,
		Vector3.new(0, 0, 1).Unit,
		Vector3.new(0, 0, -1).Unit,
		Vector3.new(1, 0, 1).Unit,
		Vector3.new(-1, 0, 1).Unit,
		Vector3.new(1, 0, -1).Unit,
		Vector3.new(-1, 0, -1).Unit,
		Vector3.new(0, 1, 0).Unit
	}
	for i = 1, #axes do
		if axes[i].Y ~= 0 then
			axes[i] = axes[i] * math.min(dist, 7.5)
		else
			axes[i] = axes[i] * dist
		end
	end
	hitscanAngles = axes
end

updateHitscanAngles(CombatConfig.HitscanDistance)

---Check line of sight visibility between two points.
---@param from Vector3
---@param to Vector3
---@param char Instance
---@return boolean, RaycastResult?
local function checkLineOfSight(from, to, char)
	local params = RaycastParams.new()
	params.RespectCanCollide = true
	params.FilterType = Enum.RaycastFilterType.Exclude

	local myChar = localPlayer.Character
	local ignored = workspaceService:FindFirstChild("Ignored")
	local filter = {currentCamera, myChar}
	if char then
		table.insert(filter, char)
	end
	if ignored then
		table.insert(filter, ignored)
	end
	params.FilterDescendantsInstances = filter

	isInternalRaycast = true
	local result = workspaceService:Raycast(from, to - from, params)
	isInternalRaycast = false

	return not result, result
end

---Perform Hitscan angle traversal around cover.
---@param from Vector3
---@param targetPos Vector3
---@param char Instance
---@return Vector3?
local function scanAngles(from, targetPos, char)
	for i = 1, #hitscanAngles do
		local offsetPos = targetPos + hitscanAngles[i]
		local clearTarget, hitTarget = checkLineOfSight(targetPos, offsetPos, char)
		if not clearTarget and hitTarget then
			offsetPos = targetPos + ((offsetPos - targetPos).Unit * (hitTarget.Distance - 0.2))
		end
		if checkLineOfSight(from, offsetPos, char) then
			return offsetPos
		end
	end
	return nil
end

---Extract velocity and drop rates from current weapon stats.
---@return number?, number?
local function getWeaponStats()
	if not currentWeapon or typeof(currentWeapon) ~= "table" then
		return nil, nil
	end
	local stats = rawget(currentWeapon, "Stats")
	if typeof(stats) ~= "table" then
		return nil, nil
	end
	local projStats = rawget(stats, "ProjectileStats")
	if typeof(projStats) ~= "table" then
		return nil, nil
	end
	local vel = rawget(projStats, "Velocity")
	local drop = rawget(projStats, "Drop")
	if typeof(vel) == "number" and typeof(drop) == "number" then
		return vel, drop
	end
	return nil, nil
end

---Apply ballistic prediction to target vector.
---@param origin Vector3
---@param targetPos Vector3
---@param rootPart BasePart?
---@return Vector3
local function predictTrajectory(origin, targetPos, rootPart)
	local vel, drop = getWeaponStats()
	if not vel then
		if rootPart and rootPart.Velocity.Magnitude < 100 then
			local distance = (origin - targetPos).Magnitude
			local timeToHit = distance / 500
			return targetPos + (rootPart.Velocity * timeToHit)
		end
		return targetPos
	end

	local dist = (origin - targetPos).Magnitude
	local timeToHit = dist / (vel * 2)
	local dropOffset = (drop / 2) * (timeToHit ^ 2)
	local leadOffset = Vector3.zero

	if rootPart and rootPart.Velocity.Magnitude < 100 then
		leadOffset = rootPart.Velocity * Vector3.new(1, 0, 1) * timeToHit
	end

	return targetPos + Vector3.new(0, dropOffset, 0) + leadOffset
end

---Scan workspace containers for valid target entities.
---@return table
local function getTargetEntities()
	local entities = {}
	local myChar = localPlayer.Character
	local containers = {}

	local playersFolder = workspaceService:FindFirstChild("Players")
	local aiFolder = workspaceService:FindFirstChild("AICharacters") or workspaceService:FindFirstChild("AI")

	if playersFolder then
		table.insert(containers, { folder = playersFolder, isBot = false })
	end

	if aiFolder then
		table.insert(containers, { folder = aiFolder, isBot = true })
	end

	if #containers == 0 then
		table.insert(containers, { folder = workspaceService, isBot = false })
	end

	for _, container in ipairs(containers) do
		for _, obj in ipairs(container.folder:GetChildren()) do
			if not obj:IsA("Model") or obj == myChar then continue end

			local humanoid = obj:FindFirstChildOfClass("Humanoid")
			local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso")
			if not (humanoid and root) then continue end
			if CombatConfig.DeadCheck and humanoid.Health <= 0 then continue end
			if obj:GetAttribute("Downed") then continue end

			local player = playersService:GetPlayerFromCharacter(obj) or playersService:FindFirstChild(obj.Name)
			local isBot = container.isBot or (player == nil)

			if isBot and not CombatConfig.TargetBots then continue end
			if not isBot and not CombatConfig.TargetPlayers then continue end

			if not isBot and CombatConfig.TeamCheck then
				local teamDot = obj:FindFirstChild("TeamDot")
				if (teamDot and teamDot.Enabled) or (player and localPlayer.Team and player.Team == localPlayer.Team) then
					continue
				end
			end

			table.insert(entities, {
				Model = obj,
				Player = player,
				IsBot = isBot,
				Humanoid = humanoid,
				RootPart = root
			})
		end
	end

	return entities
end

---Roll hit chance percentage.
---@return boolean
local function rollHitChance()
	if CombatConfig.HitChance >= 100 then return true end
	if CombatConfig.HitChance <= 0 then return false end
	return math.random(1, 100) <= CombatConfig.HitChance
end

---Get nearest target bone to screen cursor with prediction and hitscan.
---@return Instance?, Vector3?
local function getClosestTarget()
	local closestPart, closestPos, closestDist = nil, nil, math.huge
	local mousePos = userInputService:GetMouseLocation()
	local camPos = currentCamera.CFrame.Position
	local currentFov = circleInline.Radius
	local scannedTargets = {}

	for _, entity in ipairs(getTargetEntities()) do
		local char = entity.Model
		local part = nil

		if CombatConfig.HitPart == "Random" then
			local limbs = {"Head", "HumanoidRootPart", "Torso", "UpperTorso"}
			part = char:FindFirstChild(limbs[math.random(1, #limbs)]) or entity.RootPart
		elseif CombatConfig.HitPart == "closest" then
			for _, boneName in ipairs(BONE_PRIORITY) do
				local bone = char:FindFirstChild(boneName)
				if not bone or not bone:IsA("BasePart") then continue end
				local screenPos, onScreen = currentCamera:WorldToViewportPoint(bone.Position)
				if not onScreen then continue end
				local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
				if dist <= currentFov then
					table.insert(scannedTargets, {
						part = bone,
						char = char,
						root = entity.RootPart,
						pos = bone.Position,
						dist = dist
					})
				end
			end
			continue
		else
			part = char:FindFirstChild(CombatConfig.HitPart) or entity.RootPart or char:FindFirstChild("Head")
		end

		if not part or not part:IsA("BasePart") then continue end

		local distToCam = (camPos - part.Position).Magnitude
		if CombatConfig.DistCheck and distToCam > CombatConfig.MaxDistance then continue end

		local screenPos, onScreen = currentCamera:WorldToViewportPoint(part.Position)
		if not onScreen then continue end

		local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
		if dist <= currentFov then
			table.insert(scannedTargets, {
				part = part,
				char = char,
				root = entity.RootPart,
				pos = part.Position,
				dist = dist
			})
		end
	end

	table.sort(scannedTargets, function(a, b)
		return a.dist < b.dist
	end)

	for _, target in ipairs(scannedTargets) do
		local evalPos = target.pos

		if CombatConfig.Prediction then
			evalPos = predictTrajectory(camPos, evalPos, target.root)
		end

		if CombatConfig.VisibleCheck then
			local isClear = checkLineOfSight(camPos, evalPos, target.char)
			if isClear then
				hitscanTargetPos = nil
				return target.part, evalPos
			elseif CombatConfig.Hitscan then
				local scannedPos = scanAngles(camPos, evalPos, target.char)
				if scannedPos then
					hitscanTargetPos = scannedPos
					return target.part, scannedPos
				end
			end
		else
			hitscanTargetPos = nil
			return target.part, evalPos
		end
	end

	hitscanTargetPos = nil
	return nil, nil
end

---Apply tool viewmodel and projectile bytecode patches.
local function patchWeaponModules()
	pcall(function()
		local modules = replicatedStorage:WaitForChild("Modules", 5)
		if not modules then return end

		local client = modules:WaitForChild("Client", 5)
		if not client then return end

		local toolsFolder = client:WaitForChild("Tools", 5)
		if toolsFolder and toolsFolder:FindFirstChild("Tools") then
			local toolsModule = require(toolsFolder.Tools)
			local oldRefresh = toolsModule.RefreshHotbar
			toolsModule.RefreshHotbar = function(...)
				local tool = rawget(toolsModule, "CurrentTool")
				if tool and typeof(tool) == "table" then
					currentWeapon = tool
				end
				return oldRefresh(...)
			end
			currentWeapon = rawget(toolsModule, "CurrentTool")
		end

		local viewmodelFolder = toolsFolder and toolsFolder:FindFirstChild("Tool") and toolsFolder.Tool:FindFirstChild("Viewmodel")
		if viewmodelFolder then
			local recoilModule = client:FindFirstChild("Character") and client.Character:FindFirstChild("Camera") and client.Character.Camera:FindFirstChild("Recoil")
			local recoilFunc = recoilModule and require(recoilModule)

			for _, mod in ipairs(viewmodelFolder:GetChildren()) do
				if not mod:IsA("ModuleScript") then continue end
				local data = require(mod)
				if typeof(data) ~= "table" then continue end

				local setup = rawget(data, "Setup")
				if typeof(setup) == "function" and debug.info(setup, "s") ~= "[C]" then
					local env = getfenv(setup)
					local fakeTask = setmetatable({
						delay = newcclosure(function(delayTime, fn, ...)
							if CombatConfig.InstantEquip then
								return fn(...)
							end
							return task.delay(delayTime, fn, ...)
						end)
					}, {__index = env.task})
					setfenv(setup, setmetatable({task = fakeTask}, {__index = env}))
				end

				local fire = rawget(data, "Fire")
				if typeof(fire) == "function" then
					if recoilFunc and debug.getupvalues then
						for idx, upv in pairs(debug.getupvalues(fire)) do
							if typeof(upv) == "function" and debug.info(upv, "s"):find("Recoil") then
								debug.setupvalue(fire, idx, function(arg1, arg2, arg3, factor)
									local orig = factor
									if typeof(factor) == "number" then
										factor = factor * (CombatConfig.Recoil / 100)
									end
									local r1, r2 = recoilFunc()(arg1, arg2, arg3, factor)
									return r1, r2, orig
								end)
							end
						end
					end

					local origFire = fire
					local function wrappedFire(...)
						local rawParams = ...
						local fakeParams = setmetatable({}, {
							__index = function(_, key)
								local val = rawParams[key]
								if key == "RPM" and typeof(val) == "number" then
									return val / math.max(CombatConfig.Firerate, 0.1)
								end
								if key == "Ready" and CombatConfig.FastBow then
									return true
								end
								if key == "Viewmodel" and CombatConfig.ShootSprinting then
									return setmetatable({Sprinting = false}, {__index = val, __newindex = val})
								end
								return val
							end,
							__newindex = rawParams
						})

						if CombatConfig.AutoReload and typeof(data.Reload) == "function" then
							task.delay(0, data.Reload, rawParams)
						end

						return origFire(fakeParams)
					end
					setfenv(wrappedFire, getfenv(fire))
					rawset(data, "Fire", wrappedFire)
				end

				local reload = rawget(data, "Reload")
				if typeof(reload) == "function" then
					local origReload = reload
					local function wrappedReload(...)
						local rawParams = ...
						local fakeParams = setmetatable({}, {
							__index = function(_, key)
								local val = rawParams[key]
								if key ~= "Viewmodel" then return val end
								local proxy = {}
								if CombatConfig.ReloadSprinting then
									proxy.Sprinting = false
								end
								if CombatConfig.InstantReload then
									proxy.Play = function(_, animKey, ...)
										local success, marker = pcall(function()
											local anim = rawParams.Viewmodel.Animator.LoadedAnimations[animKey]
											local sig = anim:GetMarkerReachedSignal("FinishReload")
											local sig2 = anim:GetMarkerReachedSignal("InsertBullet")
											if #getconnections(sig) > 0 then return sig end
											if #getconnections(sig2) > 0 then return sig2 end
											return anim:GetMarkerReachedSignal("Insert")
										end)
										if success and marker then
											firesignal(marker)
											rawset(rawParams, "Reloading", false)
											return
										end
										return rawParams.Viewmodel:Play(animKey, ...)
									end
								end
								return setmetatable(proxy, {__index = val, __newindex = val})
							end,
							__newindex = rawParams
						})
						return origReload(fakeParams)
					end
					setfenv(wrappedReload, getfenv(reload))
					rawset(data, "Reload", wrappedReload)
				end

				local tryFire = rawget(data, "TryFire")
				if typeof(tryFire) == "function" and debug.info(tryFire, "s") ~= "[C]" then
					local env = getfenv(tryFire)
					local fakeMath = setmetatable({
						random = function(...)
							if CombatConfig.InstantEoka then
								local a, b = ...
								return b or a or 1
							end
							return math.random(...)
						end
					}, {__index = env.math})
					setfenv(tryFire, setmetatable({math = fakeMath}, {__index = env}))
				end
			end
		end

		local projFolder = client:FindFirstChild("Physics") and client.Physics:FindFirstChild("Projectile")
		if projFolder then
			for _, mod in ipairs(projFolder:GetChildren()) do
				if not mod:IsA("ModuleScript") then continue end
				local projFn = require(mod)
				if typeof(projFn) ~= "function" then continue end

				for key, upv in pairs(debug.getupvalues(projFn)) do
					if typeof(upv) == "function" and debug.info(upv, "n") == "GetSpreadDirection" then
						local origSpread = upv
						local function customSpread(...)
							if targetPart and CombatConfig.Enabled then
								local destination = hitscanTargetPos or targetPart.Position
								local camP = currentCamera.CFrame.Position
								if CombatConfig.Prediction then
									destination = predictTrajectory(camP, destination, targetPart)
								end
								return (destination - camP).Unit
							end
							return origSpread(...)
						end

						local spreadEnv = getfenv(origSpread)
						local fakeSpreadMath = setmetatable({
							random = newcclosure(function(...)
								return math.random(...) * (CombatConfig.Spread / 100)
							end)
						}, {__index = spreadEnv.math})
						setfenv(origSpread, setmetatable({math = fakeSpreadMath}, {__index = spreadEnv}))
						debug.setupvalue(projFn, key, customSpread)
						break
					end
				end

				local fakePart = Instance.new("Part")
				local meta = getrawmetatable(fakePart)
				local oldPartNamecall = meta.__namecall

				setreadonly(meta, false)
				meta.__namecall = newcclosure(function(self, ...)
					local method = getnamecallmethod()
					local args = {...}
					if method == "Raycast" and CombatConfig.InstantHit and targetPart then
						local hitPos = hitscanTargetPos or targetPart.Position
						return {
							Instance = targetPart,
							Position = hitPos,
							Normal = Vector3.new(0, 1, 0),
							Material = targetPart.Material
						}
					end
					return oldPartNamecall(self, ...)
				end)
				setreadonly(meta, true)

				local fnEnv = getfenv(projFn)
				setfenv(projFn, setmetatable({workspace = fakePart}, {__index = fnEnv}))
			end
		end
	end)
end

function Combat:GetConfig()
	return CombatConfig
end

function Combat:Unload()
	CombatConfig.Enabled = false
	circleInline:Remove()
	circleOutline:Remove()
	snapline:Remove()
	hitscanIndicator:Remove()
	if dynamicFovConnection then
		dynamicFovConnection:Disconnect()
		dynamicFovConnection = nil
	end
end

function Combat:Load()
	patchWeaponModules()

	dynamicFovConnection = currentCamera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
		if CombatConfig.DynamicFOV then
			circleInline.Radius = CombatConfig.FOV / (currentCamera.FieldOfView / 70)
			circleOutline.Radius = circleInline.Radius
		end
	end)

	runService.RenderStepped:Connect(function()
		currentCamera = workspaceService.CurrentCamera or currentCamera

		local mpos = userInputService:GetMouseLocation()
		local radius = CombatConfig.DynamicFOV and (CombatConfig.FOV / (currentCamera.FieldOfView / 70)) or CombatConfig.FOV

		circleInline.Position = mpos
		circleInline.Radius = radius
		circleInline.Color = CombatConfig.FOVColor
		circleInline.Visible = CombatConfig.Enabled and CombatConfig.ShowFOV

		circleOutline.Position = mpos
		circleOutline.Radius = radius
		circleOutline.Visible = CombatConfig.Enabled and CombatConfig.ShowFOV and CombatConfig.FOVOutline

		if CombatConfig.Enabled then
			targetPart = getClosestTarget()
		else
			targetPart = nil
			hitscanTargetPos = nil
		end

		if targetPart and CombatConfig.Enabled then
			local endPos = hitscanTargetPos or targetPart.Position
			local screenEnd, onScreen = currentCamera:WorldToViewportPoint(endPos)

			if onScreen and CombatConfig.Snapline then
				snapline.From = mpos
				snapline.To = Vector2.new(screenEnd.X, screenEnd.Y)
				snapline.Color = CombatConfig.SnaplineColor
				snapline.Visible = true
			else
				snapline.Visible = false
			end

			hitscanIndicator.Visible = CombatConfig.HitscanIndicator and (hitscanTargetPos ~= nil)
			hitscanIndicator.Position = (currentCamera.ViewportSize / 2) + Vector2.new(0, 43)
			hitscanIndicator.Color = CombatConfig.HitscanIndicatorColor
		else
			snapline.Visible = false
			hitscanIndicator.Visible = false
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

		if targetPart and rollHitChance() then
			local hitPos = hitscanTargetPos or targetPart.Position
			if CombatConfig.Prediction then
				hitPos = predictTrajectory(currentCamera.CFrame.Position, hitPos, targetPart)
			end
			if key == "Target" then
				return targetPart
			elseif key == "Hit" then
				return CFrame.new(hitPos)
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
		if not (method == "Raycast" or method == "ScreenPointToRay" or method == "ViewportPointToRay" or method:find("FindPartOnRay")) then
			return oldNamecall(self, ...)
		end

		if not targetPart or not rollHitChance() then
			return oldNamecall(self, ...)
		end

		local hitpart = targetPart
		local orgpos = hitscanTargetPos or hitpart.Position

		if CombatConfig.Prediction then
			orgpos = predictTrajectory(currentCamera.CFrame.Position, orgpos, hitpart)
		end

		local hitpos = orgpos

		if method == "Raycast" then
			local origin, direction, params = ...
			if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
				local newDir = CombatConfig.ProjectionOverride and (hitpos - origin) or (hitpos - origin).Unit * direction.Magnitude

				if CombatConfig.InstantHit or CombatConfig.Wallbang then
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

		if method == "ScreenPointToRay" or method == "ViewportPointToRay" then
			local ray = oldNamecall(self, ...)
			local origin = ray.Origin
			local direction = ray.Direction
			local newDir = CombatConfig.ProjectionOverride and (hitpos - origin) or (hitpos - origin).Unit * direction.Magnitude

			return Ray.new(origin, newDir)
		end

		if method:find("FindPartOnRay") then
			local ray, ignoreList, terrainCellsAreCubes, ignoreWater = ...
			if typeof(ray) == "Ray" then
				local origin = ray.Origin
				local direction = ray.Direction
				local newDir = CombatConfig.ProjectionOverride and (hitpos - origin) or (hitpos - origin).Unit * direction.Magnitude

				if CombatConfig.Wallbang or CombatConfig.InstantHit then
					return hitpart, hitpos, (origin - hitpos).Unit, hitpart.Material
				end

				return oldNamecall(self, Ray.new(origin, newDir), ignoreList, terrainCellsAreCubes, ignoreWater)
			end
		end

		return oldNamecall(self, ...)
	end))

	return self
end

return Combat
