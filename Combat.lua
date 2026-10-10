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

local targetPart = nil
local currentTargetData = nil
local currentWeaponTable = nil

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
	FOV = 120,
	ShowFOV = false,
	FOVColor = Color3.fromRGB(170, 85, 255),
	FOVOutline = true,

	-- New Combat Features.
	Prediction = true,
	InstantHit = false,
	Hitscan = false,
	HitscanDistance = 7,
	HitscanIndicator = true,
	HitscanColor = Color3.fromRGB(255, 196, 0),
	Snapline = false,
	SnaplineColor = Color3.fromRGB(255, 255, 255),

	-- Weapon Mods.
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
snapline.ZIndex = 10
snapline.Visible = false

local hitscanIndicator = Drawing.new("Text")
hitscanIndicator.Text = "hitscanning"
hitscanIndicator.Font = 2
hitscanIndicator.Size = 13
hitscanIndicator.Center = true
hitscanIndicator.Outline = true
hitscanIndicator.ZIndex = 30
hitscanIndicator.Visible = false

---Raycast line of sight check.
---@return boolean, RaycastResult?
local function checkLineOfSight(origin, targetPos, ignoreModel)
	local params = RaycastParams.new()
	params.RespectCanCollide = true
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {currentCamera, localPlayer.Character, ignoreModel}
	local result = workspaceService:Raycast(origin, targetPos - origin, params)
	return not result, result
end

---Get current equipped weapon projectile stats.
---@return number?, number?
local function getProjectileStats()
	if not currentWeaponTable then return nil, nil end
	local stats = rawget(currentWeaponTable, "Stats")
	if typeof(stats) ~= "table" then return nil, nil end
	local projStats = rawget(stats, "ProjectileStats")
	if typeof(projStats) ~= "table" then return nil, nil end
	local vel = rawget(projStats, "Velocity")
	local drop = rawget(projStats, "Drop")
	if typeof(vel) == "number" and typeof(drop) == "number" then
		return vel, drop
	end
	return nil, nil
end

---Calculate ballistic drop and lead position.
---@return Vector3
local function calculatePrediction(origin, targetPos, part)
	local vel, drop = getProjectileStats()
	if not vel then return targetPos end

	local dist = (origin - targetPos).Magnitude
	local flightTime = dist / (vel * 2)
	local dropOffset = (drop / 2) * (flightTime ^ 2)
	local lead = Vector3.zero

	local root = part and (part.Parent:FindFirstChild("HumanoidRootPart") or part)
	if root and root:IsA("BasePart") and root.AssemblyLinearVelocity.Magnitude < 50 then
		lead = root.AssemblyLinearVelocity * Vector3.new(1, 0, 1) * flightTime
	end

	return targetPos + Vector3.new(0, dropOffset, 0) + lead
end

---Scan surrounding angles for hitscan wall penetration.
---@return Vector3?
local function getHitscanPoint(origin, targetPos, char)
	local dist = math.min(CombatConfig.HitscanDistance, 7.5)
	local angles = {
		Vector3.new(1, 0, 0).Unit * CombatConfig.HitscanDistance,
		Vector3.new(-1, 0, 0).Unit * CombatConfig.HitscanDistance,
		Vector3.new(0, 0, 1).Unit * CombatConfig.HitscanDistance,
		Vector3.new(0, 0, -1).Unit * CombatConfig.HitscanDistance,
		Vector3.new(1, 0, 1).Unit * CombatConfig.HitscanDistance,
		Vector3.new(-1, 0, 1).Unit * CombatConfig.HitscanDistance,
		Vector3.new(1, 0, -1).Unit * CombatConfig.HitscanDistance,
		Vector3.new(-1, 0, -1).Unit * CombatConfig.HitscanDistance,
		Vector3.new(0, 1, 0).Unit * dist
	}

	for _, offset in ipairs(angles) do
		local samplePos = targetPos + offset
		local clear, hitResult = checkLineOfSight(targetPos, samplePos, char)
		if not clear and hitResult then
			samplePos = targetPos + ((samplePos - targetPos).Unit * (hitResult.Distance - 0.2))
		end
		if checkLineOfSight(origin, samplePos, char) then
			return samplePos
		end
	end
	return nil
end

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
---@return table?
local function getClosestTarget()
	local closestTarget, closestDist = nil, math.huge
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
			closestTarget = {
				Part = part,
				Model = char,
				ScreenPos = Vector2.new(screenPos.X, screenPos.Y),
				Distance = dist
			}
		end
	end

	return closestTarget
end

---Patch weapon recoil, spread, firerate, reload and viewmodels.
local function applyWeaponMods()
	task.spawn(function()
		local modules = replicatedStorage:WaitForChild("Modules", 10)
		if not modules then return end

		local client = modules:WaitForChild("Client", 10)
		if not client then return end

		local toolsFolder = client:FindFirstChild("Tools")
		if toolsFolder then
			local toolsModule = toolsFolder:FindFirstChild("Tools")
			if toolsModule then
				pcall(function()
					local tMod = require(toolsModule)
					local rawCurrent = rawget(tMod, "CurrentTool")
					if typeof(rawCurrent) == "table" then
						currentWeaponTable = rawCurrent
					end
					local oldRefresh = tMod.RefreshHotbar
					tMod.RefreshHotbar = function(...)
						currentWeaponTable = rawget(tMod, "CurrentTool")
						return oldRefresh(...)
					end
				end)
			end
		end

		local recoilScript = client:FindFirstChild("Character")
			and client.Character:FindFirstChild("Camera")
			and client.Character.Camera:FindFirstChild("Recoil")
		local recoilModule = recoilScript and require(recoilScript)

		local viewmodelFolder = toolsFolder and toolsFolder:FindFirstChild("Tool") and toolsFolder.Tool:FindFirstChild("Viewmodel")

		if viewmodelFolder and recoilModule then
			for _, mod in ipairs(viewmodelFolder:GetChildren()) do
				if not mod:IsA("ModuleScript") then continue end

				pcall(function()
					local data = require(mod)
					if typeof(data) ~= "table" then return end

					-- 1. Instant Equip
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

					-- 2. Recoil & Fire
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

					-- 3. Instant Reload
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

		-- 5. Spread Modification
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
	snapline:Remove()
	hitscanIndicator:Remove()
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
			currentTargetData = getClosestTarget()
			targetPart = currentTargetData and currentTargetData.Part or nil
		else
			currentTargetData = nil
			targetPart = nil
		end

		-- Visuals: Snapline & Indicator
		if CombatConfig.Enabled and currentTargetData and targetPart then
			if CombatConfig.Snapline then
				snapline.Visible = true
				snapline.From = mpos
				snapline.To = currentTargetData.ScreenPos
				snapline.Color = CombatConfig.SnaplineColor
			else
				snapline.Visible = false
			end

			if CombatConfig.Hitscan and CombatConfig.HitscanIndicator then
				local camPos = currentCamera.CFrame.Position
				local scanPoint = getHitscanPoint(camPos, targetPart.Position, currentTargetData.Model)
				hitscanIndicator.Visible = scanPoint ~= nil
				hitscanIndicator.Color = CombatConfig.HitscanColor
				hitscanIndicator.Position = currentCamera.ViewportSize / 2 + Vector2.new(0, 45)
			else
				hitscanIndicator.Visible = false
			end
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
			local origin = currentCamera.CFrame.Position
			local hitpos = targetPart.Position

			if CombatConfig.Hitscan and currentTargetData then
				local scanPoint = getHitscanPoint(origin, hitpos, currentTargetData.Model)
				if scanPoint then hitpos = scanPoint end
			end

			if CombatConfig.Prediction then
				hitpos = calculatePrediction(origin, hitpos, targetPart)
			end

			if key == "Target" then
				return targetPart
			elseif key == "Hit" then
				return CFrame.new(hitpos)
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
		if not (method == "Raycast" or method == "ScreenPointToRay" or method == "ViewportPointToRay" or method:find("FindPartOnRay")) then
			return oldNamecall(self, ...)
		end

		if not targetPart or not rollHitChance() then
			return oldNamecall(self, ...)
		end

		local origin = currentCamera.CFrame.Position
		local hitpos = targetPart.Position

		if CombatConfig.Hitscan and currentTargetData then
			local scanPoint = getHitscanPoint(origin, hitpos, currentTargetData.Model)
			if scanPoint then hitpos = scanPoint end
		end

		if CombatConfig.Prediction then
			hitpos = calculatePrediction(origin, hitpos, targetPart)
		end

		-- Instant Hit / Force Hit hook
		if method == "Raycast" and CombatConfig.InstantHit then
			task.wait()
			return {
				Instance = targetPart,
				Position = hitpos,
				Normal = Vector3.new(0, 1, 0),
				Material = targetPart.Material
			}
		end

		if method == "Raycast" then
			local rayOrigin, rayDirection, rayParams = ...
			if typeof(rayOrigin) == "Vector3" and typeof(rayDirection) == "Vector3" then
				local newDir = (hitpos - rayOrigin).Unit * rayDirection.Magnitude
				return oldNamecall(self, rayOrigin, newDir, rayParams)
			end
		end

		if method == "ScreenPointToRay" or method == "ViewportPointToRay" then
			local ray = oldNamecall(self, ...)
			local rayOrigin = ray.Origin
			local rayDirection = ray.Direction
			local newDir = (hitpos - rayOrigin).Unit * rayDirection.Magnitude
			return Ray.new(rayOrigin, newDir)
		end

		if method:find("FindPartOnRay") then
			local ray, ignoreList, terrainCellsAreCubes, ignoreWater = ...
			if typeof(ray) == "Ray" then
				local rayOrigin = ray.Origin
				local rayDirection = ray.Direction
				local newDir = (hitpos - rayOrigin).Unit * rayDirection.Magnitude
				return oldNamecall(self, Ray.new(rayOrigin, newDir), ignoreList, terrainCellsAreCubes, ignoreWater)
			end
		end

		return oldNamecall(self, ...)
	end))

	return self
end

return Combat
