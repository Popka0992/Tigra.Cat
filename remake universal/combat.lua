if shared.Combat and shared.Combat.Unload then
    pcall(shared.Combat.Unload, shared.Combat)
end

local cloneref = cloneref or function(object)
    return object
end

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Workspace = cloneref(game:GetService("Workspace"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = Workspace.CurrentCamera

local Voxel = ReplicatedStorage:WaitForChild("Voxel")
local Remotes = Voxel:WaitForChild("Remotes")
local Ballistics = require(Voxel:WaitForChild("Ballistics"))

local Combat = {}

local Config = {
    AimMode = "Silent Aim",
    Enabled = false,

    Keybind = Enum.UserInputType.MouseButton2,
    KeybindMode = "Hold",
    AimActive = false,

    HitPart = "Head",
    HitChance = 100,
    Smoothness = 2,

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

    HitboxEnabled = false,
    HitboxSize = 6,
    HitboxTrans = 0.6,
    HitboxPart = "All Parts",
    HitboxCustom = true,
}

local FIRE_NAMES = {
    FireRifle = true,
    FireSMG = true,
    FireLMG = true,
    FirePistol = true,
    FireDMR = true,
    FireSniper = true,
    FireShotgun = true,
}

local BIND_NAME = "LigraCombat"
local ENTITY_REFRESH = 0.5
local HITBOX_INTERVAL = 0.1

local loaded = false
local aimKeyActive = false
local targetPart = nil

local connections = {}
local entities = {}
local entityByModel = {}

local entityTimer = 0
local hitboxTimer = 0

local originalPartSizes = setmetatable({}, {
    __mode = "k",
})

local touched = {}

local partsList = {
    "All Parts",
    "Head",
    "HumanoidRootPart",
    "Torso",
    "UpperTorso",
    "LowerTorso",
}

local partsSet = {}

for _, name in ipairs(partsList) do
    partsSet[name] = true
end

local partsDirty = false

Combat.PartsList = partsList

local circleInline = nil
local circleOutline = nil

local lastRadius = nil
local lastColor = nil
local lastPosition = nil

local inlineShown = false
local outlineShown = false

local env = getgenv()
local bridge = env.LigraCombatBridge

if not bridge then
    bridge = {
        Active = false,
        Namecall = nil,
    }

    env.LigraCombatBridge = bridge

    local oldNamecall

    oldNamecall = hookmetamethod(
        game,
        "__namecall",
        newcclosure(function(self, ...)
            if not bridge.Active
                or checkcaller()
                or not bridge.Namecall then
                return oldNamecall(self, ...)
            end

            return bridge.Namecall(
                self,
                oldNamecall,
                getnamecallmethod(),
                ...
            )
        end)
    )
end

local function isDefaultLimb(name)
    return name == "Head"
        or name:find("Torso") ~= nil
        or name:find("Arm") ~= nil
        or name:find("Leg") ~= nil
end

local function addPartRecord(entity, part)
    if entity.PartSet[part] then
        return
    end

    entity.PartSet[part] = true

    local name = part.Name

    entity.Parts[#entity.Parts + 1] = {
        Part = part,
        Name = name,
        Default = isDefaultLimb(name),
    }

    if not partsSet[name] then
        partsSet[name] = true
        partsList[#partsList + 1] = name
        partsDirty = true
    end
end

local function findRoot(model)
    return model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
        or model:FindFirstChild("Torso")
        or model:FindFirstChild("UpperTorso")
end

local function addEntity(model, player)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = findRoot(model)

    if not humanoid or not root then
        return
    end

    local entity = {
        Model = model,
        Player = player,
        IsBot = player == nil,

        Humanoid = humanoid,
        RootPart = root,

        Parts = {},
        PartSet = {},
    }

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            addPartRecord(entity, descendant)
        end
    end

    entity.Connection = model.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            addPartRecord(entity, descendant)
        end
    end)

    entityByModel[model] = entity
    entities[#entities + 1] = entity
end

local function removeEntityAt(index)
    local entity = entities[index]

    if entity.Connection then
        entity.Connection:Disconnect()
    end

    entityByModel[entity.Model] = nil
    table.remove(entities, index)
end

local function refreshEntities()
    local live = {}
    local myCharacter = LocalPlayer.Character

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character

        if player ~= LocalPlayer
            and character
            and character.Parent then
            live[character] = player
        end
    end

    for _, object in ipairs(Workspace:GetChildren()) do
        if live[object] == nil
            and object ~= myCharacter
            and object:IsA("Model")
            and (
                entityByModel[object]
                or object:FindFirstChildOfClass("Humanoid")
            ) then
            live[object] = false
        end
    end

    for index = #entities, 1, -1 do
        local entity = entities[index]

        if live[entity.Model] == nil
            or not entity.Model.Parent
            or not entity.Humanoid.Parent
            or not entity.RootPart.Parent then
            removeEntityAt(index)
        end
    end

    for model, player in pairs(live) do
        if not entityByModel[model] then
            addEntity(model, player or nil)
        end
    end
end

local function isTargetable(entity)
    if not entity.Model.Parent then
        return false
    end

    if entity.IsBot then
        if not Config.TargetBots then
            return false
        end
    else
        if not Config.TargetPlayers then
            return false
        end

        if Config.TeamCheck
            and LocalPlayer.Team
            and entity.Player.Team == LocalPlayer.Team then
            return false
        end
    end

    if Config.DeadCheck and entity.Humanoid.Health <= 0 then
        return false
    end

    return true
end

local function rollHitChance()
    local chance = tonumber(Config.HitChance) or 100

    if chance >= 100 then
        return true
    end

    if chance <= 0 then
        return false
    end

    return math.random(1, 100) <= chance
end

local function fovRadius()
    local camera = CurrentCamera

    if not camera then
        return 0
    end

    local cameraFov = math.clamp(camera.FieldOfView, 1, 179)
    local aimFov = math.clamp(tonumber(Config.FOV) or 100, 0, 179)

    local cameraHalf = math.rad(cameraFov / 2)
    local aimHalf = math.rad(aimFov / 2)

    return (camera.ViewportSize.Y / 2)
        * math.tan(aimHalf)
        / math.tan(cameraHalf)
end

local function getClosestPart(mousePosition, maxRadius)
    local camera = CurrentCamera

    if not camera then
        return nil
    end

    local cameraPosition = camera.CFrame.Position
    local hitName = Config.HitPart

    local best = nil
    local bestDistance = maxRadius

    for index = 1, #entities do
        local entity = entities[index]

        if isTargetable(entity) then
            local model = entity.Model

            local part =
                model:FindFirstChild(hitName)
                or entity.RootPart
                or model:FindFirstChild("Head")

            if part and part:IsA("BasePart") then
                local position = part.Position

                if not Config.DistCheck
                    or (cameraPosition - position).Magnitude
                        <= Config.MaxDistance then

                    local screenPosition, onScreen =
                        camera:WorldToViewportPoint(position)

                    if onScreen then
                        local distance = (
                            Vector2.new(screenPosition.X, screenPosition.Y)
                            - mousePosition
                        ).Magnitude

                        if distance <= bestDistance then
                            best = part
                            bestDistance = distance
                        end
                    end
                end
            end
        end
    end

    return best
end

local function rewriteShot(name, args)
    if not Config.Enabled or Config.AimMode ~= "Silent Aim" then
        return false
    end

    local part = targetPart

    if not part or not part.Parent or not rollHitChance() then
        return false
    end

    local muzzle = args[1]

    if typeof(muzzle) ~= "Vector3"
        or typeof(args[2]) ~= "Vector3" then
        return false
    end

    local point = part.Position

    local model = part:FindFirstAncestorOfClass("Model")
    local root = model and model:FindFirstChild("HumanoidRootPart")

    local speed = Ballistics.SPEED or 1700
    local arc = nil

    if name == "FireSniper" then
        local character = LocalPlayer.Character
        local tool = character and character:FindFirstChildOfClass("Tool")

        local velocityScale =
            (tool and tonumber(tool:GetAttribute("GsVelocity"))) or 1

        speed = (Ballistics.RIFLE_SPEED or speed) * velocityScale
        arc = Ballistics.RIFLE_ARC
    end

    if type(speed) ~= "number" or speed <= 0 then
        return false
    end

    if root and root.AssemblyLinearVelocity.Magnitude > 0.5 then
        local distance = (point - muzzle).Magnitude

        local ok, flightTime = pcall(
            Ballistics.flightTime,
            distance,
            speed,
            arc
        )

        if not ok
            or type(flightTime) ~= "number"
            or flightTime ~= flightTime
            or flightTime < 0 then
            flightTime = distance / speed
        end

        point += root.AssemblyLinearVelocity * flightTime
    end

    local delta = point - muzzle

    if delta.Magnitude < 0.001 then
        return false
    end

    local plain = delta.Unit
    local aim = plain

    if name == "FireSniper" then
        local ok, launch = pcall(
            Ballistics.launch,
            muzzle,
            point,
            speed,
            arc
        )

        if ok
            and typeof(launch) == "Vector3"
            and launch.Magnitude > 0.5 then
            aim = launch.Unit
        end
    end

    if name == "FireShotgun" then
        for index = 3, args.n do
            if typeof(args[index]) == "Vector3" then
                args[index] = plain
            end
        end
    else
        args[2] = aim

        if typeof(args[4]) == "Vector3" then
            args[4] = plain
        end

        if type(args[5]) == "number" then
            args[5] = 0
        end
    end

    return true
end

local function namecallHandler(self, old, method, ...)
    if method ~= "FireServer"
        or typeof(self) ~= "Instance"
        or self.Parent ~= Remotes
        or not FIRE_NAMES[self.Name] then
        return old(self, ...)
    end

    local args = table.pack(...)
    local ok, changed = pcall(rewriteShot, self.Name, args)

    if not ok or not changed then
        return old(self, ...)
    end

    setnamecallmethod(method)

    return old(self, table.unpack(args, 1, args.n))
end

local function createCircles()
    local ok = pcall(function()
        circleOutline = Drawing.new("Circle")
        circleOutline.Thickness = 3
        circleOutline.Color = Color3.new(0, 0, 0)
        circleOutline.Filled = false
        circleOutline.ZIndex = 1
        circleOutline.Visible = false

        circleInline = Drawing.new("Circle")
        circleInline.Thickness = 1
        circleInline.Filled = false
        circleInline.ZIndex = 2
        circleInline.Visible = false
    end)

    if not ok then
        if circleOutline then
            pcall(function()
                circleOutline:Remove()
            end)
        end

        if circleInline then
            pcall(function()
                circleInline:Remove()
            end)
        end

        circleInline = nil
        circleOutline = nil
    end
end

local function updateCircles(show, radius, mousePosition)
    if not circleInline or not circleOutline then
        return
    end

    if show then
        if mousePosition ~= lastPosition then
            circleInline.Position = mousePosition
            circleOutline.Position = mousePosition
            lastPosition = mousePosition
        end

        if radius ~= lastRadius then
            circleInline.Radius = radius
            circleOutline.Radius = radius
            lastRadius = radius
        end

        if Config.FOVColor ~= lastColor then
            circleInline.Color = Config.FOVColor
            lastColor = Config.FOVColor
        end
    end

    if show ~= inlineShown then
        circleInline.Visible = show
        inlineShown = show
    end

    local outline = show and Config.FOVOutline or false

    if outline ~= outlineShown then
        circleOutline.Visible = outline
        outlineShown = outline
    end
end

local function restorePart(part, data)
    if not part.Parent then
        return
    end

    part.Size = data.Size
    part.Transparency = data.Transparency
    part.CanCollide = data.CanCollide
    part.Massless = data.Massless
end

local function restoreAll()
    for part, data in pairs(originalPartSizes) do
        restorePart(part, data)
        originalPartSizes[part] = nil
    end
end

local function hitboxPass()
    if not Config.HitboxEnabled then
        if next(originalPartSizes) ~= nil then
            restoreAll()
        end

        return
    end

    local size = Config.HitboxSize
    local targetSize = Vector3.new(size, size, size)
    local transparency = Config.HitboxTrans
    local mode = Config.HitboxPart
    local custom = Config.HitboxCustom

    table.clear(touched)

    for index = 1, #entities do
        local entity = entities[index]

        if isTargetable(entity) then
            local parts = entity.Parts

            for partIndex = #parts, 1, -1 do
                local record = parts[partIndex]
                local part = record.Part

                if not part.Parent then
                    entity.PartSet[part] = nil
                    table.remove(parts, partIndex)
                elseif record.Name ~= "HumanoidRootPart" then
                    if mode == "All Parts"
                        or mode == record.Name
                        or (custom and not record.Default) then

                        touched[part] = true

                        if not originalPartSizes[part] then
                            originalPartSizes[part] = {
                                Size = part.Size,
                                Transparency = part.Transparency,
                                CanCollide = part.CanCollide,
                                Massless = part.Massless,
                            }
                        end

                        if part.Size ~= targetSize then
                            part.Size = targetSize
                        end

                        if part.Transparency ~= transparency then
                            part.Transparency = transparency
                        end

                        if part.CanCollide then
                            part.CanCollide = false
                        end

                        if not part.Massless then
                            part.Massless = true
                        end
                    end
                end
            end
        end
    end

    for part, data in pairs(originalPartSizes) do
        if not touched[part] then
            restorePart(part, data)
            originalPartSizes[part] = nil
        end
    end
end

local function onRender()
    CurrentCamera = Workspace.CurrentCamera or CurrentCamera

    local camera = CurrentCamera

    if not camera then
        targetPart = nil
        bridge.Active = false
        return
    end

    local mousePosition = UserInputService:GetMouseLocation()
    local radius = fovRadius()

    local aiming = aimKeyActive or Config.AimActive
    local silent = Config.AimMode == "Silent Aim"

    updateCircles(
        Config.Enabled and Config.ShowFOV,
        radius,
        mousePosition
    )

    if Config.Enabled and (silent or aiming) then
        targetPart = getClosestPart(mousePosition, radius)
    else
        targetPart = nil
    end

    bridge.Active =
        Config.Enabled
        and silent
        and targetPart ~= nil

    if Config.Enabled
        and not silent
        and aiming
        and targetPart
        and targetPart.Parent then

        local look = CFrame.lookAt(
            camera.CFrame.Position,
            targetPart.Position
        )

        local smoothness = math.clamp(
            tonumber(Config.Smoothness) or 1,
            1,
            30
        )

        if smoothness <= 1 then
            camera.CFrame = look
        else
            camera.CFrame = camera.CFrame:Lerp(
                look,
                1 / smoothness
            )
        end
    end
end

local function onHeartbeat(dt)
    entityTimer += dt

    if entityTimer >= ENTITY_REFRESH then
        entityTimer = 0
        refreshEntities()
    end

    hitboxTimer += dt

    if hitboxTimer >= HITBOX_INTERVAL then
        hitboxTimer = 0
        hitboxPass()
    end
end

function Combat:GetConfig()
    return Config
end

function Combat:RefreshParts()
    refreshEntities()

    local dirty = partsDirty
    partsDirty = false

    return dirty
end

function Combat:SetAimActive(state)
    aimKeyActive = state and true or false
    Config.AimActive = aimKeyActive
end

function Combat:Load()
    if loaded then
        return self
    end

    loaded = true

    CurrentCamera = Workspace.CurrentCamera or CurrentCamera

    createCircles()
    refreshEntities()

    bridge.Index = nil
    bridge.Mouse = nil
    bridge.Namecall = namecallHandler
    bridge.Active = false

    pcall(
        RunService.UnbindFromRenderStep,
        RunService,
        BIND_NAME
    )

    RunService:BindToRenderStep(
        BIND_NAME,
        Enum.RenderPriority.Camera.Value + 1,
        onRender
    )

    connections[#connections + 1] =
        RunService.Heartbeat:Connect(onHeartbeat)

    shared.Combat = self

    return self
end

function Combat:Unload()
    loaded = false

    bridge.Active = false
    bridge.Namecall = nil
    bridge.Index = nil
    bridge.Mouse = nil

    pcall(
        RunService.UnbindFromRenderStep,
        RunService,
        BIND_NAME
    )

    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end

    table.clear(connections)

    restoreAll()

    for index = #entities, 1, -1 do
        removeEntityAt(index)
    end

    table.clear(touched)

    if circleInline then
        pcall(function()
            circleInline:Remove()
        end)
    end

    if circleOutline then
        pcall(function()
            circleOutline:Remove()
        end)
    end

    circleInline = nil
    circleOutline = nil

    lastRadius = nil
    lastColor = nil
    lastPosition = nil

    inlineShown = false
    outlineShown = false

    targetPart = nil
    aimKeyActive = false
    Config.AimActive = false

    entityTimer = 0
    hitboxTimer = 0

    if shared.Combat == self then
        shared.Combat = nil
    end
end

return Combat
