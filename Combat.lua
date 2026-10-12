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

-- Constants.
local LONE_MAX_LEASH = 3.4

local targetEntity = nil
local targetPart = nil
local hitscanOverridePos = nil
local manipulatorOriginPos = nil

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
	Manipulator = false,
	ManipulatorDistance = 3.2,
	ManipulatorVisualColor = Color3.fromRGB(0, 255, 170),
	InstantHit = false,
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

local manipulatorPoint = Drawing.new("Circle")
manipulatorPoint.Radius = 4
manipulatorPoint.Filled = true
manipulatorPoint.Thickness = 1
manipulatorPoint.ZIndex = 6
manipulatorPoint.Visible = false

local manipulatorTracer = Drawing.new("Line")
manipulatorTracer.Thickness = 1.5
manipulatorTracer.Transparency = 1
manipulatorTracer.ZIndex = 5
manipulatorTracer.Visible = false

---Perform raycast visibility check between two points.
local function checkVisibility(origin, destination, targetChar)
	local params = RaycastParams.new()
	params.RespectCanCollide = true

	local myChar = localPlayer.Character
	local ignoredFolder = workspaceService:FindFirstChild("Ignored")
	local filterList = { currentCamera, ignoredFolder }

	if targetChar then
		table.insert(filterList, targetChar)
	end
	if myChar then
		table.insert(filterList, myChar)
	end

	params.FilterDescendantsInstances = filterList

	local hit = workspaceService:Raycast(origin, destination - origin, params)
	return not hit, hit
end

---Generate angles for Target Hitscan.
local function getHitscanAngles()
	local dist = CombatConfig.HitscanDistance
	local baseAngles = {
		Vector3.new(1, 0, 0).Unit,
		Vector3.new(-1, 0, 0).Unit,
		Vector3.new(0, 0, 1).Unit,
		Vector3.new(0, 0, -1).Unit,
		Vector3.new(1, 0, 1).Unit,
		Vector3.new(-1, 0, 1).Unit,
		Vector3.new(1, 0, -1).Unit,
		Vector3.new(-1, 0, -1).Unit,
		Vector3.new(0, 1, 0).Unit,
	}

	local angles = {}
	for idx = 1, #baseAngles do
		local vec = baseAngles[idx]
		if vec.Y ~= 0 then
			angles[idx] = vec * math.min(dist, 7.5)
		else
			angles[idx] = vec * dist
		end
	end
	return angles
end

---Target-Side Hitscan solver.
local function findHitscanPosition(camPos, targetBonePos, targetChar)
	local angles = getHitscanAngles()
	for idx = 1, #angles do
		local samplePos = targetBonePos + angles[idx]
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

---Origin-Side Manipulator solver strictly respecting server Hitreg leash and LOS.
local function findManipulatorOrigin(targetPos, targetChar)
	local myChar = localPlayer.Character
	local head = myChar and myChar:FindFirstChild("Head")
	if not head then return nil end

	local headPos = head.Position
	local camCF = currentCamera.CFrame
	local maxDist = math.clamp(CombatConfig.ManipulatorDistance or 3.2, 0.5, LONE_MAX_LEASH)

	local camLook = camCF.LookVector
	local flatLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
	local flatRight = Vector3.new(-flatLook.Z, 0, flatLook.X).Unit
	local worldUp = Vector3.yAxis

	local testDirections = {
		worldUp,
		flatRight,
		-flatRight,
		(worldUp + flatRight).Unit,
		(worldUp - flatRight).Unit,
		(worldUp + flatLook).Unit,
		(flatRight + flatLook).Unit,
		(-flatRight + flatLook).Unit,
	}

	local steps = { 0.5, 0.75, 1.0 }

	for _, mult in ipairs(steps) do
		local dist = maxDist * mult
		for _, dir in ipairs(testDirections) do
			local sampleOrigin = headPos + (dir * dist)

			-- Проверка 1: Серверный луч от головы до точки выстрела должен быть чистым.
			local clearFromHead = checkVisibility(headPos, sampleOrigin, myChar)
			if clearFromHead then
				-- Проверка 2: Траектория от точки выстрела до врага должна быть чистой.
				local clearToEnemy = checkVisibility(sampleOrigin, targetPos, targetChar)
				if clearToEnemy then
					return sampleOrigin
				end
			end
		end
	end

	return nil
end

---Scan workspace containers for targets.
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
				RootPart = root,
			})
		end
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
	local closestPart, closestDist, bestEntity = nil, math.huge, nil
	local resolvedHitscan, resolvedManipulator = nil, nil
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
			local isVisible = checkVisibility(camPos, part.Position, char)
			local hitscanPos = nil
			local manipPos = nil

			if not isVisible then
				if CombatConfig.Manipulator then
					manipPos = findManipulatorOrigin(part.Position, char)
					if manipPos then
						isVisible = true
					end
				end

				if not isVisible and CombatConfig.Hitscan then
					hitscanPos = findHitscanPosition(camPos, part.Position, char)
					if hitscanPos then
						isVisible = true
					end
				end
			end

			if CombatConfig.VisibleCheck and not isVisible then
				continue
			end

			closestDist = dist
			closestPart = part
			bestEntity = entity
			resolvedHitscan = hitscanPos
			resolvedManipulator = manipPos
		end
	end

	return closestPart, bestEntity, resolvedHitscan, resolvedManipulator
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
										if (key == "Origin" or key == "Position" or key == "StartPos") and CombatConfig.Enabled and CombatConfig.Manipulator and manipulatorOriginPos then
											return manipulatorOriginPos
										end
										if (key == "CFrame" or key == "OriginCFrame") and CombatConfig.Enabled and CombatConfig.Manipulator and manipulatorOriginPos then
											local targetPos = hitscanOverridePos or (targetPart and targetPart.Position) or (manipulatorOriginPos + currentCamera.CFrame.LookVector * 100)
											return CFrame.new(manipulatorOriginPos, targetPos)
										end
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
									__metatable = "",
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
												__newindex = val,
											})
										end
										return val
									end,
									__newindex = rawParams,
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
							end,
						}, { __index = origEnv.math or math })
						setfenv(tryFire, setmetatable({ math = fakeMath }, { __index = origEnv }))
					end
				end)
			end
		end

		local physicsFolder = client:FindFirstChild("Physics")
		local projFolder = physicsFolder and physicsFolder:FindFirstChild("Projectile")

		if projFolder then
			for _, mod in ipairs(projFolder:GetChildren()) do
				if not mod:IsA("ModuleScript") then continue end

				pcall(function()
					local projFn = require(mod)
					if typeof(projFn) ~= "function" then return end

					-- Redirect spawn origin inside projectile instance.
					local oldProj
					oldProj = hookfunction(projFn, newcclosure(function(...)
						local args = { ... }
						if CombatConfig.Enabled and CombatConfig.Manipulator and manipulatorOriginPos then
							local char = localPlayer.Character
							local head = char and char:FindFirstChild("Head")
							local originBase = head and head.Position or currentCamera.CFrame.Position

							for i = 1, math.min(#args, 4) do
								if typeof(args[i]) == "Vector3" then
									if (args[i] - originBase).Magnitude <= 10 then
										args[i] = manipulatorOriginPos
										break
									end
								end
							end
						end
						return oldProj(unpack(args))
					end))

					if debug.getupvalues and debug.setupvalue then
						for idx, upv in pairs(debug.getupvalues(projFn)) do
							if typeof(upv) == "function" and debug.info(upv, "n") == "GetSpreadDirection" then
								local origSpread = upv
								local spreadEnv = getfenv(origSpread)

								local fakeRandom = newcclosure(function(...)
									return math.random(...) * (CombatConfig.Spread / 100)
								end)

								setfenv(origSpread, setmetatable({
									math = setmetatable({ random = fakeRandom }, { __index = spreadEnv.math or math }),
								}, { __index = spreadEnv }))

								local function redirectedSpread(...)
									if not (CombatConfig.Enabled and targetPart and rollHitChance()) then
										return origSpread(...)
									end

									local targetPos = hitscanOverridePos or targetPart.Position
									local startPos = (CombatConfig.Manipulator and manipulatorOriginPos) or currentCamera.CFrame.Position
									return (targetPos - startPos).Unit
								end

								debug.setupvalue(projFn, idx, redirectedSpread)
								break
							end
						end
					end

					-- Workspace wrapper for Instant Hit.
					local fakeWorkspace = setmetatable({}, {
						__index = function(_, key)
							if key == "Raycast" then
								return function(self, origin, direction, params)
									if CombatConfig.Enabled and CombatConfig.InstantHit and targetPart and rollHitChance() then
										local myChar = localPlayer.Character
										if params and params.IgnoreWater and myChar and table.find(params.FilterDescendantsInstances, myChar) then
											local finalPos = hitscanOverridePos or targetPart.Position
											local startOrigin = (CombatConfig.Manipulator and manipulatorOriginPos) or origin
											local isVisible = checkVisibility(startOrigin, finalPos, targetPart.Parent)

											if isVisible then
												task.wait()
												return {
													Instance = targetPart,
													Position = finalPos,
													Normal = Vector3.new(1, 1, 1).Unit,
													Material = targetPart.Material,
													Distance = (startOrigin - finalPos).Magnitude,
												}
											end
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
						end,
					})

					local projEnv = getfenv(projFn)
					setfenv(projFn, setmetatable({
						workspace = fakeWorkspace,
						Workspace = fakeWorkspace,
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
	circleInline:Remove()
	circleOutline:Remove()
	hitscanIndicator:Remove()
	hitscanPoint:Remove()
	manipIndicator:Remove()
	manipulatorPoint:Remove()
	manipulatorTracer:Remove()
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
			targetPart, targetEntity, hitscanOverridePos, manipulatorOriginPos = getClosestTarget()
		else
			targetPart = nil
			targetEntity = nil
			hitscanOverridePos = nil
			manipulatorOriginPos = nil
		end

		local isHitscanning = CombatConfig.Enabled and CombatConfig.Hitscan and hitscanOverridePos ~= nil
		local isManipulating = CombatConfig.Enabled and CombatConfig.Manipulator and manipulatorOriginPos ~= nil
		local viewportSize = currentCamera.ViewportSize

		-- Hitscan Visuals.
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

		-- Manipulator Visuals.
		if isManipulating then
			local yOffset = isHitscanning and 54 or 38
			manipIndicator.Position = Vector2.new(viewportSize.X / 2, (viewportSize.Y / 2) + yOffset)
			manipIndicator.Color = CombatConfig.ManipulatorVisualColor
			manipIndicator.Visible = true

			local screenPos, onScreen = currentCamera:WorldToViewportPoint(manipulatorOriginPos)
			if onScreen then
				manipulatorPoint.Position = Vector2.new(screenPos.X, screenPos.Y)
				manipulatorPoint.Color = CombatConfig.ManipulatorVisualColor
				manipulatorPoint.Visible = true

				manipulatorTracer.From = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
				manipulatorTracer.To = Vector2.new(screenPos.X, screenPos.Y)
				manipulatorTracer.Color = CombatConfig.ManipulatorVisualColor
				manipulatorTracer.Visible = true
			else
				manipulatorPoint.Visible = false
				manipulatorTracer.Visible = false
			end
		else
			manipIndicator.Visible = false
			manipulatorPoint.Visible = false
			manipulatorTracer.Visible = false
		end
	end)

	local oldIndex
	oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
		if self ~= mouse or checkcaller() or not CombatConfig.Enabled then
			return oldIndex(self, key)
		end

		if userInputService.MouseBehavior == Enum.MouseBehavior.Default or userInputService:GetFocusedTextBox() then
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
