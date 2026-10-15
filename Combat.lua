-- Services.
local cloneref = cloneref or function(instance) return instance end
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
local manipPosition = nil

local manipTimer = 0
local isSpoofed = false
local realCFrame = nil
local realVelocity = nil

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
	VisibleCheck = true,
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
	Hitscan = false,
	HitscanDistance = 7,
	HitscanIndicator = true,
	HitscanPoint = true,
	HitscanVisualColor = Color3.fromRGB(255, 196, 0),
	InstantHit = false,
	Manipulator = true,
	ManipulatorDistance = 9,
	ManipulatorIndicator = true,
	ManipulatorPoint = true,
	ManipulatorLine = true,
	ManipulatorColor = Color3.fromRGB(0, 255, 170)
}

-- Reusable static RaycastParams to prevent GC allocations.
local sharedRayParams = RaycastParams.new()
sharedRayParams.FilterType = Enum.RaycastFilterType.Exclude
sharedRayParams.RespectCanCollide = true

local staticHitscanDirs = {
	Vector3.new(1, 0, 0),
	Vector3.new(-1, 0, 0),
	Vector3.new(0, 0, 1),
	Vector3.new(0, 0, -1),
	Vector3.new(1, 0, 1).Unit,
	Vector3.new(-1, 0, 1).Unit,
	Vector3.new(1, 0, -1).Unit,
	Vector3.new(-1, 0, -1).Unit,
	Vector3.new(0, 1, 0)
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

local hitscanIndicator = Drawing.new("Text")
hitscanIndicator.Text = "hitscanning"
hitscanIndicator.Size = 13
hitscanIndicator.Center = true
hitscanIndicator.Outline = true
hitscanIndicator.OutlineColor = Color3.new(0, 0, 0)
hitscanIndicator.ZIndex = 5
hitscanIndicator.Visible = false

local hitscanPoint = Drawing.new("Circle")
hitscanPoint.Radius = 3.5
hitscanPoint.Filled = true
hitscanPoint.Thickness = 1
hitscanPoint.ZIndex = 6
hitscanPoint.Visible = false

local manipIndicator = Drawing.new("Text")
manipIndicator.Text = "manipulated"
manipIndicator.Size = 13
manipIndicator.Center = true
manipIndicator.Outline = true
manipIndicator.OutlineColor = Color3.new(0, 0, 0)
manipIndicator.ZIndex = 5
manipIndicator.Visible = false

local manipPoint = Drawing.new("Circle")
manipPoint.Radius = 4
manipPoint.Filled = true
manipPoint.Thickness = 1
manipPoint.ZIndex = 6
manipPoint.Visible = false

local manipLine = Drawing.new("Line")
manipLine.Thickness = 1.5
manipLine.ZIndex = 5
manipLine.Visible = false

---Perform raycast visibility check using pooled parameters.
local function checkVisibility(origin, destination, targetChar)
	local myChar = localPlayer.Character
	local ignoredFolder = workspaceService:FindFirstChild("Ignored")

	local filterList = { currentCamera }
	if targetChar then table.insert(filterList, targetChar) end
	if myChar then table.insert(filterList, myChar) end
	if ignoredFolder then table.insert(filterList, ignoredFolder) end

	sharedRayParams.FilterDescendantsInstances = filterList

	local hit = workspaceService:Raycast(origin, destination - origin, sharedRayParams)
	return not hit, hit
end

---Solver for Hitscan angles without dynamic allocations.
local function findHitscanPosition(camPos, targetBonePos, targetChar)
	local dist = CombatConfig.HitscanDistance
	for idx = 1, #staticHitscanDirs do
		local dir = staticHitscanDirs[idx]
		local offset = dir * (dir.Y ~= 0 and math.min(dist, 7.5) or dist)
		local samplePos = targetBonePos + offset

		local clearToTarget, wallHit = checkVisibility(targetBonePos, samplePos, targetChar)
		if not clearToTarget and wallHit then
			if wallHit.Distance > 0.25 then
				samplePos = targetBonePos + ((samplePos - targetBonePos).Unit * (wallHit.Distance - 0.2))
			else
				continue
			end
		end

		if checkVisibility(camPos, samplePos, targetChar) then
			return samplePos
		end
	end
	return nil
end

---Optimized manipulator solver.
local function findManipulatorPosition(myRoot, targetPos, targetChar)
	local rootPos = myRoot.Position
	local dist = CombatConfig.ManipulatorDistance
	local toTarget = targetPos - rootPos
	local flatDir = Vector3.new(toTarget.X, 0, toTarget.Z)

	if flatDir.Magnitude > 0.1 then
		flatDir = flatDir.Unit
	else
		flatDir = myRoot.CFrame.LookVector
	end

	local rightDir = Vector3.new(-flatDir.Z, 0, flatDir.X).Unit
	local upDir = Vector3.new(0, 1, 0)

	local candidates = {
		upDir * dist,
		upDir * (dist * 0.7),
		-rightDir * dist,
		rightDir * dist,
		(upDir * 0.8 - rightDir * 0.6).Unit * dist,
		(upDir * 0.8 + rightDir * 0.6).Unit * dist
	}

	for idx = 1, #candidates do
		local samplePos = rootPos + candidates[idx]

		local clearToSample, wallHit = checkVisibility(rootPos, samplePos, localPlayer.Character)
		if not clearToSample and wallHit then
			if wallHit.Distance > 1.2 then
				samplePos = rootPos + (candidates[idx].Unit * (wallHit.Distance - 0.4))
			else
				continue
			end
		end

		if checkVisibility(samplePos, targetPos, targetChar) then
			return samplePos
		end
	end

	return nil
end

---Scan workspace containers for targets.
local function getTargetEntities()
	local entities = {}
	local myChar = localPlayer.Character

	local playersFolder = workspaceService:FindFirstChild("Players")
	local aiFolder = workspaceService:FindFirstChild("AICharacters") or workspaceService:FindFirstChild("AI")

	local function processFolder(folder, isBot)
		if not folder then return end
		local children = folder:GetChildren()
		for i = 1, #children do
			local obj = children[i]
			if obj == myChar or not obj:IsA("Model") then continue end

			local humanoid = obj:FindFirstChildOfClass("Humanoid")
			local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChild("Torso")
			if not (humanoid and root) then continue end
			if CombatConfig.DeadCheck and humanoid.Health <= 0 then continue end

			local player = playersService:GetPlayerFromCharacter(obj) or playersService:FindFirstChild(obj.Name)
			local botStatus = isBot or (player == nil)

			if botStatus and not CombatConfig.TargetBots then continue end
			if not botStatus and not CombatConfig.TargetPlayers then continue end
			if not botStatus and CombatConfig.TeamCheck and player and localPlayer.Team and player.Team == localPlayer.Team then continue end

			table.insert(entities, {
				Model = obj,
				Player = player,
				IsBot = botStatus,
				Humanoid = humanoid,
				RootPart = root
			})
		end
	end

	if playersFolder or aiFolder then
		processFolder(playersFolder, false)
		processFolder(aiFolder, true)
	else
		processFolder(workspaceService, false)
	end

	return entities
end

---Roll hit chance.
local function rollHitChance()
	if CombatConfig.HitChance >= 100 then return true end
	if CombatConfig.HitChance <= 0 then return false end
	return math.random(1, 100) <= CombatConfig.HitChance
end

---Get nearest target bone to cursor.
local function getClosestTarget()
	local closestPart, closestDist, bestEntity, resolvedHitscan, resolvedManip = nil, math.huge, nil, nil, nil
	local mousePos = userInputService:GetMouseLocation()
	local camPos = currentCamera.CFrame.Position
	local maxFovRadius = CombatConfig.FOV

	local myChar = localPlayer.Character
	local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)
	local entities = getTargetEntities()

	for i = 1, #entities do
		local entity = entities[i]
		local char = entity.Model
		local part = char:FindFirstChild(CombatConfig.HitPart) or entity.RootPart

		if not part or not part:IsA("BasePart") then continue end

		local distToCam = (camPos - part.Position).Magnitude
		if CombatConfig.DistCheck and distToCam > CombatConfig.MaxDistance then continue end

		local screenPos, onScreen = currentCamera:WorldToViewportPoint(part.Position)
		if not onScreen then continue end

		local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
		if dist <= maxFovRadius and dist < closestDist then
			local camCanSee = checkVisibility(camPos, part.Position, char)
			local isVisible = camCanSee
			local hitscanPos = nil
			local manipPos = nil

			if not isVisible and CombatConfig.Hitscan then
				hitscanPos = findHitscanPosition(camPos, part.Position, char)
				if hitscanPos then
					isVisible = true
				end
			end

			if CombatConfig.Manipulator and myRoot and not camCanSee then
				manipPos = findManipulatorPosition(myRoot, part.Position, char)
				if manipPos then
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
			resolvedManip = manipPos
		end
	end

	return closestPart, bestEntity, resolvedHitscan, resolvedManip
end

---Hook weapon modules.
local function patchWeaponModule(mod, recoilModule)
	if not mod:IsA("ModuleScript") then return end

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
			if debug.getupvalues and debug.setupvalue and recoilModule then
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
				local myChar = localPlayer.Character
				local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)
				local savedCF = nil

				if CombatConfig.Enabled and CombatConfig.Manipulator and manipPosition and myRoot then
					manipTimer = os.clock() + 0.35
					savedCF = myRoot.CFrame
					myRoot.CFrame = CFrame.new(manipPosition, manipPosition + savedCF.LookVector)
				end

				local result
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

					result = origFire(proxyParams)
				else
					result = origFire(...)
				end

				if savedCF and myRoot and myRoot.Parent then
					myRoot.CFrame = savedCF
				end

				return result
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

---Patch weapon mods & hook Projectile modules.
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

		if viewmodelFolder then
			for _, mod in ipairs(viewmodelFolder:GetChildren()) do
				patchWeaponModule(mod, recoilModule)
			end
			viewmodelFolder.ChildAdded:Connect(function(mod)
				task.wait(0.1)
				patchWeaponModule(mod, recoilModule)
			end)
		end

		local physicsFolder = client:FindFirstChild("Physics")
		local projFolder = physicsFolder and physicsFolder:FindFirstChild("Projectile")

		if projFolder then
			for _, mod in ipairs(projFolder:GetChildren()) do
				if not mod:IsA("ModuleScript") then continue end

				pcall(function()
					local projFn = require(mod)
					if typeof(projFn) ~= "function" then return end

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
									local originPos = (CombatConfig.Manipulator and manipPosition) or currentCamera.CFrame.Position
									return (targetPos - originPos).Unit
								end

								debug.setupvalue(projFn, idx, redirectedSpread)
								break
							end
						end
					end

					local fakeWorkspace = setmetatable({}, {
						__index = function(_, key)
							if key == "Raycast" then
								return function(self, origin, direction, params)
									local myChar = localPlayer.Character
									local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)

									if CombatConfig.Enabled and CombatConfig.Manipulator and manipPosition and myRoot and (os.clock() < manipTimer) then
										local distFromPlayer = (origin - myRoot.Position).Magnitude
										if distFromPlayer < (CombatConfig.ManipulatorDistance + 15) then
											local targetPos = hitscanOverridePos or (targetPart and targetPart.Position)
											origin = manipPosition
											if targetPos then
												direction = (targetPos - manipPosition).Unit * direction.Magnitude
											end
										end
									end

									if CombatConfig.Enabled and CombatConfig.InstantHit and targetPart and rollHitChance() then
										local finalPos = hitscanOverridePos or targetPart.Position
										local vantageOrigin = (CombatConfig.Manipulator and manipPosition) or origin
										local isVisible = checkVisibility(vantageOrigin, finalPos, targetPart.Parent)

										if isVisible then
											task.wait()
											return {
												Instance = targetPart,
												Position = finalPos,
												Normal = Vector3.new(0, 1, 0),
												Material = targetPart.Material,
												Distance = (vantageOrigin - finalPos).Magnitude
											}
										end
									end

									return workspaceService:Raycast(origin, direction, params)
								end
							end

							local val = workspaceService[key]
							if typeof(val) == "function" then
								return function(self, ...)
									return val(workspaceService, ...)
								end
							end
							return val
						end,
						__newindex = function(_, key, val)
							workspaceService[key] = val
						end
					})

					local projEnv = getfenv(projFn)
					setfenv(projFn, setmetatable({
						workspace = fakeWorkspace,
						Workspace = fakeWorkspace
					}, { __index = projEnv }))
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
	pcall(function()
		runService:UnbindFromRenderStep("CombatManipRestore")
	end)
	circleInline:Remove()
	circleOutline:Remove()
	hitscanIndicator:Remove()
	hitscanPoint:Remove()
	manipIndicator:Remove()
	manipPoint:Remove()
	manipLine:Remove()
end

function Combat:Load()
	applyWeaponMods()

	runService.Heartbeat:Connect(function()
		if not (CombatConfig.Enabled and CombatConfig.Manipulator and manipPosition and (os.clock() < manipTimer)) then
			isSpoofed = false
			return
		end

		local char = localPlayer.Character
		local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
		local hum = char and char:FindFirstChildOfClass("Humanoid")

		if hrp and hum and hum.Health > 0 then
			realCFrame = hrp.CFrame
			realVelocity = hrp.AssemblyLinearVelocity

			hrp.CFrame = CFrame.new(manipPosition, manipPosition + realCFrame.LookVector)
			hrp.AssemblyLinearVelocity = Vector3.zero
			isSpoofed = true
		end
	end)

	runService:BindToRenderStep("CombatManipRestore", 199, function()
		if isSpoofed and realCFrame and localPlayer.Character then
			local hrp = localPlayer.Character:FindFirstChild("HumanoidRootPart") or localPlayer.Character.PrimaryPart
			if hrp then
				hrp.CFrame = realCFrame
				hrp.AssemblyLinearVelocity = realVelocity or Vector3.zero
				isSpoofed = false
			end
		end
	end)

	-- Update targets at fixed rate to reduce RenderStepped strain.
	task.spawn(function()
		while true do
			if CombatConfig.Enabled then
				targetPart, targetEntity, hitscanOverridePos, manipPosition = getClosestTarget()
			else
				targetPart = nil
				targetEntity = nil
				hitscanOverridePos = nil
				manipPosition = nil
			end
			task.wait(0.03)
		end
	end)

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

		local myChar = localPlayer.Character
		local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)
		local viewportSize = currentCamera.ViewportSize

		local isHitscanning = CombatConfig.Enabled and CombatConfig.Hitscan and hitscanOverridePos ~= nil
		if isHitscanning and CombatConfig.HitscanIndicator then
			hitscanIndicator.Position = Vector2.new(viewportSize.X / 2, (viewportSize.Y / 2) + 38)
			hitscanIndicator.Color = CombatConfig.HitscanVisualColor
			hitscanIndicator.Visible = true
		else
			hitscanIndicator.Visible = false
		end

		if isHitscanning and CombatConfig.HitscanPoint then
			local screenPos, onScreen = currentCamera:WorldToViewportPoint(hitscanOverridePos)
			if onScreen then
				hitscanPoint.Position = Vector2.new(screenPos.X, screenPos.Y)
				hitscanPoint.Color = CombatConfig.HitscanVisualColor
				hitscanPoint.Visible = true
			else
				hitscanPoint.Visible = false
			end
		else
			hitscanPoint.Visible = false
		end

		local isVisualizingManip = CombatConfig.Enabled and CombatConfig.Manipulator and manipPosition ~= nil
		if isVisualizingManip and CombatConfig.ManipulatorIndicator then
			local yOffset = (isHitscanning and CombatConfig.HitscanIndicator) and 54 or 38
			manipIndicator.Position = Vector2.new(viewportSize.X / 2, (viewportSize.Y / 2) + yOffset)
			manipIndicator.Color = CombatConfig.ManipulatorColor
			manipIndicator.Visible = true
		else
			manipIndicator.Visible = false
		end

		if isVisualizingManip and CombatConfig.ManipulatorPoint then
			local screenPos, onScreen = currentCamera:WorldToViewportPoint(manipPosition)
			if onScreen then
				manipPoint.Position = Vector2.new(screenPos.X, screenPos.Y)
				manipPoint.Color = CombatConfig.ManipulatorColor
				manipPoint.Visible = true

				if CombatConfig.ManipulatorLine and myRoot then
					local rootPos = realCFrame and realCFrame.Position or myRoot.Position
					local rootScreen, rootOnScreen = currentCamera:WorldToViewportPoint(rootPos)
					if rootOnScreen then
						manipLine.From = Vector2.new(rootScreen.X, rootScreen.Y)
						manipLine.To = Vector2.new(screenPos.X, screenPos.Y)
						manipLine.Color = CombatConfig.ManipulatorColor
						manipLine.Visible = true
					else
						manipLine.Visible = false
					end
				else
					manipLine.Visible = false
				end
			else
				manipPoint.Visible = false
				manipLine.Visible = false
			end
		else
			manipPoint.Visible = false
			manipLine.Visible = false
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

		if userInputService.MouseBehavior == Enum.MouseBehavior.Default or userInputService:GetFocusedTextBox() then
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
