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

local targetEntity = nil
local targetPart = nil
local hitscanOverridePos = nil

local CombatConfig = {
	Enabled = false,
	HitPart = "Head",
	HitChance = 100,
	TargetPlayers = true,
	TargetBots = true,
	TeamCheck = false,
	DeadCheck = true,
	DistCheck = false,
	MaxDistance = 1000,
	VisibleCheck = false,
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
	InstantEoka = false,
	-- Hitscan & Instant Hit
	Hitscan = false,
	HitscanDistance = 7,
	InstantHit = false
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

---Perform raycast visibility check between two points.
---@param origin Vector3
---@param destination Vector3
---@param targetChar Model?
---@return boolean, RaycastResult?
local function checkLineOfSight(origin, destination, targetChar)
	local params = RaycastParams.new()
	params.RespectCanCollide = true

	local myChar = localPlayer.Character
	local ignoredFolder = workspaceService:FindFirstChild("Ignored")
	params.FilterDescendantsInstances = { targetChar, currentCamera, myChar, ignoredFolder }

	local direction = destination - origin
	if direction.Magnitude < 0.001 then
		return true, nil
	end

	local result = workspaceService:Raycast(origin, direction, params)
	return result == nil, result
end

---Scan workspace containers for valid targets.
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

---Calculate exposed hitscan vector around target.
---@param cameraPos Vector3
---@param partPos Vector3
---@param targetModel Model
---@return Vector3?
local function calculateHitscan(cameraPos, partPos, targetModel)
	local dist = CombatConfig.HitscanDistance
	local offsets = {
		Vector3.new(1, 0, 0).Unit * dist,
		Vector3.new(-1, 0, 0).Unit * dist,
		Vector3.new(0, 0, 1).Unit * dist,
		Vector3.new(0, 0, -1).Unit * dist,
		Vector3.new(1, 0, 1).Unit * dist,
		Vector3.new(-1, 0, 1).Unit * dist,
		Vector3.new(1, 0, -1).Unit * dist,
		Vector3.new(-1, 0, -1).Unit * dist,
		Vector3.new(0, 1, 0).Unit * math.min(dist, 7.5)
	}

	for _, offset in ipairs(offsets) do
		local samplePoint = partPos + offset
		local clearToTarget, targetRay = checkLineOfSight(partPos, samplePoint, targetModel)

		if not clearToTarget and targetRay then
			local safeDistance = math.max(0.05, targetRay.Distance - 0.2)
			samplePoint = partPos + (offset.Unit * safeDistance)
		end

		local clearToCam = checkLineOfSight(cameraPos, samplePoint, targetModel)
		if clearToCam then
			return samplePoint
		end
	end

	return nil
end

---Get nearest target bone to screen cursor.
---@return Instance?, table?, Vector3?
local function getClosestTarget()
	local closestPart, closestDist, bestEntity, resolvedHitscan = nil, math.huge, nil, nil
	local mousePos = userInputService:GetMouseLocation()
	local camPos = currentCamera.CFrame.Position
	local maxFovRadius = CombatConfig.FOV

	for _, entity in ipairs(getTargetEntities()) do
		local char = entity.Model
		local part = nil

		if CombatConfig.HitPart == "Random" then
			local limbs = { "Head", "HumanoidRootPart", "Torso", "UpperTorso" }
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
			local isVisible = checkLineOfSight(camPos, part.Position, char)
			local hitscanPos = nil

			if not isVisible and CombatConfig.Hitscan then
				hitscanPos = calculateHitscan(camPos, part.Position, char)
				if hitscanPos then
					isVisible = true
				end
			end

			if CombatConfig.VisibleCheck and not isVisible then
				continue
			end

			closestDist = dist
			closestPart = part
			bestEntity = entity
			resolvedHitscan = hitscanPos
		end
	end

	return closestPart, bestEntity, resolvedHitscan
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
						}, { __index = origSetupEnv.task or task })
						setfenv(setup, setmetatable({ task = fakeTask }, { __index = origSetupEnv }))
					end

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
											return setmetatable({ Sprinting = false }, { __index = val, __newindex = val })
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

					local reload = rawget(data, "Reload")
					if typeof(reload) == "function" then
						local origReload = reload
						rawset(data, "Reload", function(...)
							local rawParams = ...
							if typeof(rawParams) == "table" then
								local firedOnce = false
								local proxyParams = setmetatable({}, {
									__index = function(_, key)
										local val = rawParams[key]
										if key == "Viewmodel" and typeof(val) == "table" then
											return setmetatable({}, {
												__index = function(_, vmKey)
													if vmKey == "Sprinting" and CombatConfig.ReloadSprinting then
														return false
													end
													if vmKey == "Play" and CombatConfig.InstantReload then
														return function(vmSelf, animKey, ...)
															local track = val:Play(animKey, ...)
															task.defer(function()
																pcall(function()
																	local animator = val.Animator
																	local loaded = animator and animator.LoadedAnimations
																	local resolvedTrack = track or (loaded and loaded[animKey])
																	if resolvedTrack and not firedOnce then
																		local s1 = resolvedTrack:GetMarkerReachedSignal("FinishReload")
																		local s2 = resolvedTrack:GetMarkerReachedSignal("InsertBullet")
																		local s3 = resolvedTrack:GetMarkerReachedSignal("Insert")

																		local chosen = (#getconnections(s1) > 0 and s1)
																			or (#getconnections(s2) > 0 and s2)
																			or (#getconnections(s3) > 0 and s3)

																		if chosen then
																			firedOnce = true
																			firesignal(chosen)
																			rawset(rawParams, "Reloading", false)
																			pcall(function()
																				resolvedTrack:Stop(0)
																			end)
																		end
																	end
																end)
															end)
															return track
														end
													end
													return val[vmKey]
												end,
												__newindex = val
											})
										end
										return val
									end,
									__newindex = rawParams
								})
								return origReload(proxyParams)
							end
							return origReload(...)
						end)
					end

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
						}, { __index = origEnv.math or math })
						setfenv(tryFire, setmetatable({ math = fakeMath }, { __index = origEnv }))
					end
				end)
			end
		end

		-- Projectile Module Hooks: GetSpreadDirection redirection + Instant Hit sandbox
		local physicsFolder = client:FindFirstChild("Physics")
		local projFolder = physicsFolder and physicsFolder:FindFirstChild("Projectile")

		if projFolder then
			for _, mod in ipairs(projFolder:GetChildren()) do
				if not mod:IsA("ModuleScript") then continue end

				pcall(function()
					local projFn = require(mod)
					if typeof(projFn) ~= "function" then return end

					-- 1. Hook GetSpreadDirection to redirect bullet toward target / hitscan position
					if debug.getupvalues and debug.setupvalue then
						for idx, upv in pairs(debug.getupvalues(projFn)) do
							if typeof(upv) == "function" and debug.info(upv, "n") == "GetSpreadDirection" then
								local origSpread = upv
								local spreadEnv = getfenv(origSpread)

								local fakeRandom = newcclosure(function(...)
									return math.random(...) * (CombatConfig.Spread / 100)
								end)

								setfenv(origSpread, setmetatable({
									math = setmetatable({ random = fakeRandom }, { __index = spreadEnv.math or math })
								}, { __index = spreadEnv }))

								local function redirectedSpread(...)
									if not (CombatConfig.Enabled and targetPart and rollHitChance()) then
										return origSpread(...)
									end

									local targetPos = hitscanOverridePos or targetPart.Position
									local camPos = currentCamera.CFrame.Position

									if targetEntity and targetEntity.RootPart then
										local vel = targetEntity.RootPart.Velocity
										if vel.Magnitude > 0.5 and vel.Magnitude < 50 then
											local dist = (camPos - targetPos).Magnitude
											targetPos = targetPos + (vel * Vector3.new(1, 0, 1) * (dist / 600))
										end
									end

									return (targetPos - camPos).Unit
								end

								debug.setupvalue(projFn, idx, redirectedSpread)
								break
							end
						end
					end

					-- 2. Sandbox workspace inside projFn environment for Instant Hit
					local fakeWorkspace = Instance.new("Part")
					local meta = getrawmetatable(fakeWorkspace)
					setreadonly(meta, false)

					meta.__index = newcclosure(function(self, key)
						return workspaceService[key]
					end)

					meta.__namecall = newcclosure(function(self, ...)
						local method = getnamecallmethod()
						if method == "Raycast" and CombatConfig.Enabled and CombatConfig.InstantHit and targetPart and rollHitChance() then
							local origin, direction, params = ...
							local myChar = localPlayer.Character

							if params and params.IgnoreWater and myChar and table.find(params.FilterDescendantsInstances, myChar) then
								task.wait()
								local finalPos = hitscanOverridePos or targetPart.Position
								return {
									Instance = targetPart,
									Position = finalPos,
									Normal = Vector3.new(1, 1, 1).Unit,
									Material = targetPart.Material or Enum.Material.Plastic,
									Distance = (origin - finalPos).Magnitude
								}
							end
						end

						return workspaceService[method](workspaceService, ...)
					end)

					setreadonly(meta, true)

					local origEnv = getfenv(projFn)
					setfenv(projFn, setmetatable({ workspace = fakeWorkspace }, { __index = origEnv }))
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
			targetPart, targetEntity, hitscanOverridePos = getClosestTarget()
		else
			targetPart = nil
			targetEntity = nil
			hitscanOverridePos = nil
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
			local finalPos = hitscanOverridePos or targetPart.Position
			if key == "Target" then
				return targetPart
			elseif key == "Hit" then
				return CFrame.new(finalPos)
			end
		end

		return oldIndex(self, key)
	end))

	return self
end

return Combat
