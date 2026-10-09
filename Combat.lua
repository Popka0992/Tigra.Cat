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
	FOV = 120,
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

---Scan workspace containers for targets.
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

			local player = playersService:GetPlayerFromCharacter(obj) or playersService:FindFirstChild(obj.Name)
			local isBot = container.isBot or (player == nil)

			if isBot and not CombatConfig.TargetBots then continue end
			if not isBot and not CombatConfig.TargetPlayers then continue end
			if not isBot and CombatConfig.TeamCheck and player and localPlayer.Team and player.Team == localPlayer.Team then continue end

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

---Calculate hit chance probability.
---@return boolean
local function rollHitChance()
	if CombatConfig.HitChance >= 100 then return true end
	if CombatConfig.HitChance <= 0 then return false end
	return math.random(1, 100) <= CombatConfig.HitChance
end

---Get nearest target bone to screen cursor.
---@return Instance?
local function getClosestTarget()
	local closestPart, closestDist = nil, math.huge
	local mousePos = userInputService:GetMouseLocation()
	local camPos = currentCamera.CFrame.Position
	local maxFovRadius = CombatConfig.FOV

	for _, entity in ipairs(getTargetEntities()) do
		local char = entity.Model
		local part = nil

		if CombatConfig.HitPart == "Random" then
			local limbs = {"Head", "HumanoidRootPart", "Torso", "UpperTorso"}
			part = char:FindFirstChild(limbs[math.random(1, #limbs)]) or entity.RootPart
		else
			part = char:FindFirstChild(CombatConfig.HitPart) or entity.RootPart or char:FindFirstChild("Head")
		end

		if not part or not part:IsA("BasePart") then continue end

		local distToCam = (camPos - part.Position).Magnitude
		if CombatConfig.DistCheck and distToCam > CombatConfig.MaxDistance then continue end

		local screenPos, onScreen = currentCamera:WorldToViewportPoint(part.Position)
		if not onScreen then continue end

		local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
		if dist <= maxFovRadius and dist < closestDist then
			closestDist = dist
			closestPart = part
		end
	end

	return closestPart
end

---Patch weapon recoil, spread, firerate, reload and viewmodels.
local function applyWeaponMods()
	task.spawn(function()
		local modules = replicatedStorage:WaitForChild("Modules", 10)
		if not modules then return end

		local client = modules:WaitForChild("Client", 10)
		if not client then return end

		local recoilScript = client:FindFirstChild("Character")
			and client.Character:FindFirstChild("Camera")
			and client.Character.Camera:FindFirstChild("Recoil")
		local recoilModule = recoilScript and require(recoilScript)

		local toolsFolder = client:FindFirstChild("Tools")
		local viewmodelFolder = toolsFolder and toolsFolder:FindFirstChild("Tool") and toolsFolder.Tool:FindFirstChild("Viewmodel")

		if viewmodelFolder and recoilModule then
			for _, mod in ipairs(viewmodelFolder:GetChildren()) do
				if not mod:IsA("ModuleScript") then continue end

				pcall(function()
					local data = require(mod)
					if typeof(data) ~= "table" then return end

					-- 1. No Pullout Delay (Instant Equip)
					local setup = rawget(data, "Setup")
					if typeof(setup) == "function" and debug.info(setup, "s") ~= "[C]" then
						local origSetupEnv = getfenv(setup)
						local fakeTask = setmetatable({
							delay = newcclosure(function(dTime, fn, ...)
								if CombatConfig.InstantEquip then
									return fn(...)
								end
								return task.delay(dTime, fn, ...)
							end)
						}, {__index = origSetupEnv.task or task})
						setfenv(setup, setmetatable({task = fakeTask}, {__index = origSetupEnv}))
					end

					-- 2. Recoil Hook & Fire Hook
					local fire = rawget(data, "Fire")
					if typeof(fire) == "function" then
						if debug.getupvalues and debug.setupvalue then
							for idx, upv in pairs(debug.getupvalues(fire)) do
								local upvType = typeof(upv)
								local isRecoil = (upvType == "function" and debug.info(upv, "s"):find("Recoil"))
									or (upvType == "Instance" and upv.Name == "Recoil")

								if isRecoil then
									debug.setupvalue(fire, idx, function(arg1, arg2, arg3, factor)
										local origFactor = factor
										if typeof(factor) == "number" then
											factor = factor * (CombatConfig.Recoil / 100)
										end
										local r1, r2 = recoilModule()(arg1, arg2, arg3, factor)
										return r1, r2, origFactor
									end)
								end
							end
						end

						local origFire = fire
						local function modifiedFire(...)
							local rawParams = ...
							if typeof(rawParams) == "table" then
								local proxyParams = setmetatable({}, {
									__index = function(_, key)
										local val = rawParams[key]
										if key == "RPM" and typeof(val) == "number" then
											if CombatConfig.Firerate > 1 then
												return val / CombatConfig.Firerate
											end
											return val
										end
										if key == "Ready" and CombatConfig.FastBow then
											return true
										end
										if key == "Viewmodel" and CombatConfig.ShootSprinting and typeof(val) == "table" then
											return setmetatable({Sprinting = false}, {__index = val, __newindex = val})
										end
										return val
									end,
									__newindex = rawParams,
									__metatable = ""
								})

								if CombatConfig.AutoReload and typeof(data.Reload) == "function" then
									task.delay(0, data.Reload, rawParams)
								end

								return origFire(proxyParams)
							end
							return origFire(...)
						end

						if setfenv and getfenv then
							setfenv(modifiedFire, getfenv(origFire))
						end
						rawset(data, "Fire", modifiedFire)
					end

					-- 3. Reload Hook (Clean Instant Reload & Reload While Sprinting)
					local reload = rawget(data, "Reload")
					if typeof(reload) == "function" then
						local origReload = reload
						local function modifiedReload(...)
							local rawParams = ...
							if typeof(rawParams) == "table" then
								local proxyParams = setmetatable({}, {
									__index = function(_, key)
										local val = rawParams[key]
										if key ~= "Viewmodel" or typeof(val) ~= "table" then
											return val
										end

										local proxyVm = {}
										if CombatConfig.ReloadSprinting then
											proxyVm.Sprinting = false
										end

										if CombatConfig.InstantReload then
											proxyVm.Play = function(_, animKey, ...)
												local success, marker = pcall(function()
													local anim = rawParams.Viewmodel.Animator.LoadedAnimations[animKey]
													local s1 = anim:GetMarkerReachedSignal("FinishReload")
													local s2 = anim:GetMarkerReachedSignal("InsertBullet")
													return (#getconnections(s1) > 0 and s1)
														or (#getconnections(s2) > 0 and s2)
														or anim:GetMarkerReachedSignal("Insert")
												end)

												if success and marker then
													firesignal(marker)
													rawset(rawParams, "Reloading", false)
													task.defer(function()
														rawset(rawParams, "Reloading", false)
													end)
													return
												end

												local animName = tostring(animKey):lower()
												if animName:find("reload") or animName:find("insert") then
													rawset(rawParams, "Reloading", false)
													return
												end

												return val:Play(animKey, ...)
											end
										end

										return setmetatable(proxyVm, {__index = val, __newindex = val})
									end,
									__newindex = rawParams,
									__metatable = ""
								})
								return origReload(proxyParams)
							end
							return origReload(...)
						end

						if setfenv and getfenv then
							setfenv(modifiedReload, getfenv(origReload))
						end
						rawset(data, "Reload", modifiedReload)
					end

					-- 4. Instant Eoka
					local tryFire = rawget(data, "TryFire")
					if typeof(tryFire) == "function" and debug.info(tryFire, "s") ~= "[C]" then
						local origEnv = getfenv(tryFire)
						local fakeMath = setmetatable({
							random = function(...)
								if CombatConfig.InstantEoka then
									local a, b = ...
									return b or a or 1
								end
								return math.random(...)
							end
						}, {__index = origEnv.math or math})
						setfenv(tryFire, setmetatable({math = fakeMath}, {__index = origEnv}))
					end
				end)
			end
		end

		-- 5. No Spread Hook (native amongus-hook implementation)
		local physicsFolder = client:FindFirstChild("Physics")
		local projFolder = physicsFolder and physicsFolder:FindFirstChild("Projectile")

		if projFolder then
			for _, mod in ipairs(projFolder:GetChildren()) do
				if not mod:IsA("ModuleScript") then continue end

				pcall(function()
					local projFn = require(mod)
					if typeof(projFn) ~= "function" then return end

					if debug.getupvalues then
						for idx, upv in pairs(debug.getupvalues(projFn)) do
							if typeof(upv) == "function" and debug.info(upv, "n") == "GetSpreadDirection" then
								local spreadEnv = getfenv(upv)
								local fakeRandom = newcclosure(function(...)
									return math.random(...) * (CombatConfig.Spread / 100)
								end)

								local fakeEnv = setmetatable({
									math = setmetatable({random = fakeRandom}, {__index = spreadEnv.math or math})
								}, {__index = spreadEnv})

								setfenv(upv, fakeEnv)
								break
							end
						end
					end
				end)
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
end

function Combat:Load()
	applyWeaponMods()

	runService.RenderStepped:Connect(function()
		currentCamera = workspaceService.CurrentCamera or currentCamera

		local mpos = userInputService:GetMouseLocation()
		local radius = CombatConfig.FOV

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
			if key == "Target" then
				return targetPart
			elseif key == "Hit" then
				return targetPart.CFrame
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
		local hitsize = hitpart.Size
		local orgpos = hitpart.Position

		local hitpos = orgpos + Vector3.new(
			(math.random() - math.random()) * (hitsize.X / 10),
			(math.random() - math.random()) * (hitsize.Y / 10),
			(math.random() - math.random()) * (hitsize.Z / 10)
		)

		if method == "Raycast" then
			local origin, direction, params = ...
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

				if CombatConfig.Wallbang then
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
