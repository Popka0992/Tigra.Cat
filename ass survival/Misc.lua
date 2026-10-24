local cloneref = cloneref or function(o) return o end

-- Services.
local playersService = cloneref(game:GetService("Players"))
local runService = cloneref(game:GetService("RunService"))
local userInputService = cloneref(game:GetService("UserInputService"))
local workspaceService = cloneref(game:GetService("Workspace"))
local proximityPromptService = cloneref(game:GetService("ProximityPromptService"))

local Misc = {}
Misc.__index = Misc

local localPlayer = playersService.LocalPlayer
local currentCamera = workspaceService.CurrentCamera

local MiscConfig = {
	Speed = false,
	SpeedMode = "CFrame",
	SpeedValue = 40,

	Fly = false,
	FlyMode = "CFrame",
	FlySpeed = 50,

	InfiniteJump = false,
	NoClip = false,
	InstantPrompts = false,

	SpinBot = false,
	SpinMode = "Spin",
	SpinSpeed = 15,
	JitterAngle = 90,

	CustomFOV = false,
	FOVValue = 70,
	ThirdPerson = false,
	ThirdPersonDist = 12,
	MouseLock = true,

	Freecam = false,
	FreecamSpeed = 60
}

local flyBodyVelocity = nil
local flyBodyGyro = nil

local freecamPos = nil
local freecamRotX = 0
local freecamRotY = 0

local function getMovementVector()
	local moveDir = Vector3.zero
	if userInputService:IsKeyDown(Enum.KeyCode.W) then
		moveDir = moveDir + currentCamera.CFrame.LookVector
	end
	if userInputService:IsKeyDown(Enum.KeyCode.S) then
		moveDir = moveDir - currentCamera.CFrame.LookVector
	end
	if userInputService:IsKeyDown(Enum.KeyCode.A) then
		moveDir = moveDir - currentCamera.CFrame.RightVector
	end
	if userInputService:IsKeyDown(Enum.KeyCode.D) then
		moveDir = moveDir + currentCamera.CFrame.RightVector
	end
	if userInputService:IsKeyDown(Enum.KeyCode.Space) then
		moveDir = moveDir + Vector3.new(0, 1, 0)
	end
	if userInputService:IsKeyDown(Enum.KeyCode.LeftShift) or userInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		moveDir = moveDir - Vector3.new(0, 1, 0)
	end
	return moveDir.Magnitude > 0 and moveDir.Unit or Vector3.zero
end

function Misc:GetConfig()
	return MiscConfig
end

function Misc:Load()
	userInputService.JumpRequest:Connect(function()
		if MiscConfig.InfiniteJump and localPlayer.Character then
			local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
	end)

	proximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
		if MiscConfig.InstantPrompts and fireproximityprompt then
			fireproximityprompt(prompt)
		end
	end)

	proximityPromptService.PromptShown:Connect(function(prompt)
		if MiscConfig.InstantPrompts then
			prompt.HoldDuration = 0
		end
	end)

	runService.RenderStepped:Connect(function(dt)
		currentCamera = workspaceService.CurrentCamera or currentCamera

		if MiscConfig.CustomFOV then
			currentCamera.FieldOfView = MiscConfig.FOVValue
		end

		if MiscConfig.ThirdPerson then
			localPlayer.CameraMode = Enum.CameraMode.Classic
			localPlayer.CameraMinZoomDistance = MiscConfig.ThirdPersonDist
			localPlayer.CameraMaxZoomDistance = MiscConfig.ThirdPersonDist

			if MiscConfig.MouseLock and not MiscConfig.Freecam then
				userInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			end
		else
			localPlayer.CameraMinZoomDistance = 0.5
			localPlayer.CameraMaxZoomDistance = 400
		end

		if MiscConfig.Freecam then
			if currentCamera.CameraType ~= Enum.CameraType.Scriptable then
				currentCamera.CameraType = Enum.CameraType.Scriptable
				freecamPos = currentCamera.CFrame.Position
				local rx, ry, _ = currentCamera.CFrame:ToOrientation()
				freecamRotX = rx
				freecamRotY = ry
			end

			if userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
				local delta = userInputService:GetMouseDelta()
				freecamRotY = freecamRotY - delta.X * 0.004
				freecamRotX = math.clamp(freecamRotX - delta.Y * 0.004, -math.rad(89), math.rad(89))
			end

			local rotCF = CFrame.Angles(0, freecamRotY, 0) * CFrame.Angles(freecamRotX, 0, 0)
			local moveDir = Vector3.zero

			if userInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + rotCF.LookVector end
			if userInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - rotCF.LookVector end
			if userInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - rotCF.RightVector end
			if userInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + rotCF.RightVector end
			if userInputService:IsKeyDown(Enum.KeyCode.E) or userInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.yAxis end
			if userInputService:IsKeyDown(Enum.KeyCode.Q) or userInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.yAxis end

			if moveDir.Magnitude > 0 then
				freecamPos = freecamPos + (moveDir.Unit * (MiscConfig.FreecamSpeed * dt))
			end

			currentCamera.CFrame = CFrame.new(freecamPos) * rotCF
		else
			if freecamPos then
				currentCamera.CameraType = Enum.CameraType.Custom
				freecamPos = nil
			end
		end

		if MiscConfig.Fly and MiscConfig.FlyMode == "CFrame" and localPlayer.Character then
			local hrp = localPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local moveVec = getMovementVector()
				hrp.CFrame = hrp.CFrame + (moveVec * (MiscConfig.FlySpeed * dt))
				hrp.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)

	runService.Stepped:Connect(function()
		local char = localPlayer.Character
		if not char then return end

		if MiscConfig.NoClip then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
				end
			end

			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.MoveDirection.Magnitude > 0 then
				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				rayParams.FilterDescendantsInstances = {char, currentCamera}
				rayParams.IgnoreWater = true

				local checkRay = workspaceService:Raycast(hrp.Position, hum.MoveDirection * 2, rayParams)
				if checkRay and checkRay.Instance and checkRay.Instance.CanCollide then
					hrp.CFrame = hrp.CFrame + (hum.MoveDirection * 0.8)
				end
			end
		end
	end)

	runService.Heartbeat:Connect(function(dt)
		local char = localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")

		if MiscConfig.Speed and hrp and hum then
			if MiscConfig.SpeedMode == "CFrame" and hum.MoveDirection.Magnitude > 0 then
				hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (MiscConfig.SpeedValue * dt))
			elseif MiscConfig.SpeedMode == "Velocity" and hum.MoveDirection.Magnitude > 0 then
				hrp.AssemblyLinearVelocity = Vector3.new(
					hum.MoveDirection.X * MiscConfig.SpeedValue,
					hrp.AssemblyLinearVelocity.Y,
					hum.MoveDirection.Z * MiscConfig.SpeedValue
				)
			elseif MiscConfig.SpeedMode == "WalkSpeed Spoof" then
				hum.WalkSpeed = MiscConfig.SpeedValue
			end
		elseif hum and MiscConfig.SpeedMode == "WalkSpeed Spoof" and hum.WalkSpeed ~= 16 and not MiscConfig.Speed then
			hum.WalkSpeed = 16
		end

		if MiscConfig.Fly and hrp then
			local moveVec = getMovementVector()

			if MiscConfig.FlyMode == "Velocity" then
				hrp.AssemblyLinearVelocity = moveVec * MiscConfig.FlySpeed
			elseif MiscConfig.FlyMode == "BodyVelocity" then
				if not flyBodyVelocity or flyBodyVelocity.Parent ~= hrp then
					if flyBodyVelocity then flyBodyVelocity:Destroy() end
					flyBodyVelocity = Instance.new("BodyVelocity")
					flyBodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
					flyBodyVelocity.Parent = hrp
				end
				if not flyBodyGyro or flyBodyGyro.Parent ~= hrp then
					if flyBodyGyro then flyBodyGyro:Destroy() end
					flyBodyGyro = Instance.new("BodyGyro")
					flyBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
					flyBodyGyro.P = 10000
					flyBodyGyro.Parent = hrp
				end

				flyBodyVelocity.Velocity = moveVec * MiscConfig.FlySpeed
				flyBodyGyro.CFrame = currentCamera.CFrame
			end
		else
			if flyBodyVelocity then
				flyBodyVelocity:Destroy()
				flyBodyVelocity = nil
			end
			if flyBodyGyro then
				flyBodyGyro:Destroy()
				flyBodyGyro = nil
			end
		end

		if MiscConfig.SpinBot and hrp then
			if MiscConfig.SpinMode == "Spin" then
				hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(MiscConfig.SpinSpeed), 0)
			elseif MiscConfig.SpinMode == "Yaw Jitter" then
				local sign = (math.random(0, 1) == 0) and 1 or -1
				hrp.CFrame = hrp.CFrame * CFrame.Angles(0, sign * math.rad(MiscConfig.JitterAngle), 0)
			end
		end
	end)

	local oldIndex
	oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
		if not checkcaller() then
			if MiscConfig.NoClip and typeof(self) == "Instance" and self:IsA("BasePart") and key == "CanCollide" then
				local char = localPlayer.Character
				if char and self:IsDescendantOf(char) then
					return true
				end
			end

			if MiscConfig.Speed and MiscConfig.SpeedMode == "WalkSpeed Spoof" and typeof(self) == "Instance" and self:IsA("Humanoid") and key == "WalkSpeed" then
				return 16
			end
		end

		return oldIndex(self, key)
	end))
end

return Misc
