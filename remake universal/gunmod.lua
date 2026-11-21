local env = getgenv()

if env.CombinedGunMovement then
    pcall(function()
        env.CombinedGunMovement:Unload()
    end)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Mod = {
    Running = true,

    Config = {
        NoSpread = false,
        NoBloom = false,
        NoRecoil = false,
        NoViewmodelKick = false,
        FastReload = false,
        ReloadScale = 0.1,
        NoSway = false,

        ShootWhileSprinting = false,
        SprintWhileAiming = false,
        NoAimSlowdown = false,
        AutoSprint = false,
    },

    Movement = nil,
    Viewmodel = nil,
    MovementSaved = nil,
    AutoSprintApplied = false,

    Tools = setmetatable({}, { __mode = "k" }),
    Specs = setmetatable({}, { __mode = "k" }),
    Settings = setmetatable({}, { __mode = "k" }),
    Hooked = setmetatable({}, { __mode = "k" }),

    Connections = {},
    CharacterConnection = nil,
    Scanning = false,
    ScanAgain = false,
    QueueToken = 0,

    Found = {
        Movement = false,
        Viewmodel = false,
        Recoil = false,
        Spread = 0,
        Sway = false,
    },
}

env.CombinedGunMovement = Mod

local function Hook(fn, name, callback)
    if type(fn) ~= "function" or Mod.Hooked[fn] then
        return
    end

    local original

    local ok = pcall(function()
        original = hookfunction(fn, function(...)
            if not Mod.Running then
                return original(...)
            end

            return callback(original, ...)
        end)
    end)

    if ok then
        Mod.Hooked[fn] = name
    end
end

local function RegisterTool(tool)
    if typeof(tool) ~= "Instance" or not tool:IsA("Tool") then
        return
    end

    local saved = Mod.Tools[tool]

    if not saved then
        saved = {
            original = nil,
            applied = false,
        }

        Mod.Tools[tool] = saved
    end

    pcall(function()
        if Mod.Config.FastReload then
            if not saved.applied then
                saved.original = tool:GetAttribute("ReloadScale")
                saved.applied = true
            end

            local scale = math.max(
                tonumber(Mod.Config.ReloadScale) or 0.1,
                0.01
            )

            if tool:GetAttribute("ReloadScale") ~= scale then
                tool:SetAttribute("ReloadScale", scale)
            end
        elseif saved.applied then
            tool:SetAttribute("ReloadScale", saved.original)
            saved.applied = false
        end
    end)
end

local function RegisterSpec(spec)
    if type(spec) ~= "table" then
        return
    end

    if not Mod.Specs[spec] then
        Mod.Specs[spec] = {
            aimMove = nil,
            aimApplied = false,

            hipKick = nil,
            hipKickRot = nil,
            aimKick = nil,
            aimKickRot = nil,
            punch = nil,
            kickApplied = false,
        }
    end
end

local function ApplySpec(spec, saved)
    if Mod.Config.NoAimSlowdown and type(spec.aimMove) == "number" then
        if not saved.aimApplied then
            saved.aimMove = spec.aimMove
            saved.aimApplied = true
        end

        if spec.aimMove ~= 1 then
            spec.aimMove = 1
        end
    elseif saved.aimApplied then
        spec.aimMove = saved.aimMove
        saved.aimApplied = false
    end

    if Mod.Config.NoViewmodelKick then
        if not saved.kickApplied then
            saved.hipKick = spec.hipKick
            saved.hipKickRot = spec.hipKickRot
            saved.aimKick = spec.aimKick
            saved.aimKickRot = spec.aimKickRot
            saved.punch = spec.punch
            saved.kickApplied = true
        end

        if typeof(spec.hipKick) == "Vector3" then
            spec.hipKick = Vector3.zero
        end

        if typeof(spec.hipKickRot) == "Vector3" then
            spec.hipKickRot = Vector3.zero
        end

        if typeof(spec.aimKick) == "Vector3" then
            spec.aimKick = Vector3.zero
        end

        if typeof(spec.aimKickRot) == "Vector3" then
            spec.aimKickRot = Vector3.zero
        end

        if type(spec.punch) == "number" then
            spec.punch = 0
        end
    elseif saved.kickApplied then
        spec.hipKick = saved.hipKick
        spec.hipKickRot = saved.hipKickRot
        spec.aimKick = saved.aimKick
        spec.aimKickRot = saved.aimKickRot
        spec.punch = saved.punch
        saved.kickApplied = false
    end
end

local function RegisterView(view)
    if type(view) ~= "table" then
        return
    end

    local tool = rawget(view, "tool")
    local spec = rawget(view, "spec")

    if typeof(tool) ~= "Instance" or type(spec) ~= "table" then
        return
    end

    RegisterTool(tool)
    RegisterSpec(spec)

    local saved = Mod.Specs[spec]

    if saved then
        pcall(ApplySpec, spec, saved)
    end
end

local function InstallViewmodel(module)
    if type(module) ~= "table" then
        return
    end

    local ready = rawget(module, "ready")

    if type(ready) ~= "function"
        or type(rawget(module, "start")) ~= "function"
        or type(rawget(module, "hipSpread")) ~= "function" then
        return
    end

    Mod.Viewmodel = module
    Mod.Found.Viewmodel = true

    Hook(ready, "Viewmodel.ready", function(original, self, ...)
        if not Mod.Config.ShootWhileSprinting or type(self) ~= "table" then
            return original(self, ...)
        end

        local sprintAlpha = rawget(self, "sprintAlpha")

        if type(sprintAlpha) ~= "number" then
            return original(self, ...)
        end

        self.sprintAlpha = 0

        local result = table.pack(pcall(original, self, ...))

        self.sprintAlpha = sprintAlpha

        if not result[1] then
            error(result[2], 0)
        end

        return table.unpack(result, 2, result.n)
    end)

    local current = rawget(module, "current")

    if type(current) == "table" then
        RegisterView(current)
    end
end

local function InstallRecoil(methods)
    if type(methods) ~= "table" then
        return
    end

    local shot = rawget(methods, "shot")
    local step = rawget(methods, "step")
    local cool = rawget(methods, "cool")

    if type(shot) ~= "function"
        or type(step) ~= "function"
        or type(cool) ~= "function" then
        return
    end

    Mod.Found.Recoil = true

    Hook(shot, "GunRecoil.shot", function(
        original,
        self,
        aimAlpha,
        pitchScale,
        yawScale,
        ...
    )
        if Mod.Config.NoRecoil then
            return original(self, aimAlpha, 0, 0, ...)
        end

        return original(self, aimAlpha, pitchScale, yawScale, ...)
    end)

    Hook(cool, "GunRecoil.cool", function(original, ...)
        if Mod.Config.NoBloom then
            return 0
        end

        return original(...)
    end)

    local coolExact = rawget(methods, "coolExact")

    if type(coolExact) == "function" then
        Hook(coolExact, "GunRecoil.coolExact", function(original, ...)
            if Mod.Config.NoBloom then
                return 0
            end

            return original(...)
        end)
    end
end

local function RegisterSettings(settings)
    if not Mod.Settings[settings] then
        Mod.Settings[settings] = {
            original = nil,
            applied = false,
        }
    end

    local saved = Mod.Settings[settings]

    if Mod.Config.NoSway then
        if not saved.applied then
            saved.original = settings.sway
            saved.applied = true
        end

        settings.sway = 0
    end

    Mod.Found.Sway = true
end

local function IsRifleSpreadFunction(fn)
    local okName, name = pcall(debug.info, fn, "n")

    if not okName or name ~= "spreadDir" then
        return false
    end

    local okEnv, fnEnv = pcall(getfenv, fn)

    if not okEnv or type(fnEnv) ~= "table" then
        return false
    end

    local scriptObject = rawget(fnEnv, "script")

    if typeof(scriptObject) ~= "Instance" then
        return false
    end

    return scriptObject.Name == "RifleClient"
        and scriptObject:IsA("LocalScript")
        and scriptObject.Parent ~= nil
        and scriptObject.Parent:IsA("Tool")
end

local function InstallSpread(fn)
    if Mod.Hooked[fn] then
        return
    end

    Hook(fn, "RifleClient.spreadDir", function(original, direction, cone, ...)
        if Mod.Config.NoSpread and typeof(direction) == "Vector3" then
            return direction
        end

        return original(direction, cone, ...)
    end)

    if Mod.Hooked[fn] then
        Mod.Found.Spread += 1
    end
end

local function InspectMethods(methods)
    if type(methods) ~= "table" then
        return
    end

    if type(rawget(methods, "ready")) == "function"
        and type(rawget(methods, "hipSpread")) == "function" then
        InstallViewmodel(methods)
    end

    if type(rawget(methods, "shot")) == "function"
        and type(rawget(methods, "cool")) == "function" then
        InstallRecoil(methods)
    end
end

local function Inspect(object)
    if type(object) == "function" then
        if IsRifleSpreadFunction(object) then
            InstallSpread(object)
        end

        return
    end

    if type(object) ~= "table" then
        return
    end

    local state = rawget(object, "state")

    if type(state) == "table"
        and type(rawget(state, "sprinting")) == "boolean"
        and type(rawget(state, "sliding")) == "boolean"
        and type(rawget(object, "autoSprint")) == "boolean"
        and type(rawget(object, "weaponScale")) == "number"
        and type(rawget(object, "blockSprint")) == "boolean" then

        if Mod.Movement ~= object then
            if Mod.Movement and Mod.AutoSprintApplied then
                pcall(function()
                    Mod.Movement.autoSprint = Mod.MovementSaved
                end)
            end

            Mod.Movement = object
            Mod.MovementSaved = nil
            Mod.AutoSprintApplied = false
        end

        Mod.Found.Movement = true

        if Mod.Config.AutoSprint and not Mod.AutoSprintApplied then
            Mod.MovementSaved = object.autoSprint
            Mod.AutoSprintApplied = true
            object.autoSprint = true
        end
    end

    InspectMethods(object)

    if type(rawget(object, "spec")) == "table"
        and typeof(rawget(object, "tool")) == "Instance"
        and type(rawget(object, "aimAlpha")) == "number"
        and type(rawget(object, "sprintAlpha")) == "number" then

        RegisterView(object)

        local mt = getmetatable(object)

        if type(mt) == "table" then
            InspectMethods(mt)

            local index = rawget(mt, "__index")

            if type(index) == "table" and index ~= mt then
                InspectMethods(index)
            end
        end
    end

    if type(rawget(object, "profile")) == "table"
        and type(rawget(object, "pitch")) == "number"
        and type(rawget(object, "rawPitch")) == "number" then

        local mt = getmetatable(object)

        if type(mt) == "table" then
            InspectMethods(mt)

            local index = rawget(mt, "__index")

            if type(index) == "table" and index ~= mt then
                InspectMethods(index)
            end
        end
    end

    if type(rawget(object, "sway")) == "number"
        and type(rawget(object, "aimScale")) == "function"
        and type(rawget(object, "zoomScale")) == "function" then
        RegisterSettings(object)
    end
end

function Mod:Rescan()
    if not self.Running then
        return
    end

    if self.Scanning then
        self.ScanAgain = true
        return
    end

    self.Scanning = true

    task.spawn(function()
        local ok, objects = pcall(getgc, true)

        if not ok or type(objects) ~= "table" then
            self.Scanning = false
            return
        end

        for i, object in ipairs(objects) do
            if not self.Running then
                break
            end

            pcall(Inspect, object)

            if i % 2000 == 0 then
                task.wait()
            end
        end

        self.Scanning = false

        if self.Running and self.ScanAgain then
            self.ScanAgain = false
            self:Rescan()
        end
    end)
end

function Mod:QueueScan(delayTime)
    self.QueueToken += 1
    local token = self.QueueToken

    task.delay(delayTime or 0.4, function()
        if self.Running and token == self.QueueToken then
            self:Rescan()
        end
    end)
end

local function WatchCharacter(character)
    if Mod.CharacterConnection then
        Mod.CharacterConnection:Disconnect()
        Mod.CharacterConnection = nil
    end

    Mod.CharacterConnection = character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            Mod:QueueScan(0.4)
        end
    end)
end

table.insert(
    Mod.Connections,
    LocalPlayer.CharacterAdded:Connect(function(character)
        WatchCharacter(character)
        Mod:QueueScan(0.5)
    end)
)

if LocalPlayer.Character then
    WatchCharacter(LocalPlayer.Character)
end

local function ApplyMovement()
    local movement = Mod.Movement
    local module = Mod.Viewmodel
    local view = module and rawget(module, "current")

    if not movement then
        return
    end

    if Mod.Config.AutoSprint then
        if not Mod.AutoSprintApplied then
            Mod.MovementSaved = movement.autoSprint
            Mod.AutoSprintApplied = true
        end

        if not movement.autoSprint then
            movement.autoSprint = true
        end
    elseif Mod.AutoSprintApplied then
        movement.autoSprint = Mod.MovementSaved
        Mod.AutoSprintApplied = false
    end

    if type(view) ~= "table" or not view.active then
        return
    end

    RegisterView(view)

    local aimingAllowed = Mod.Config.SprintWhileAiming and view.aiming
    local firingAllowed = Mod.Config.ShootWhileSprinting and view.firing
    local aimBlocks = view.aiming and not Mod.Config.SprintWhileAiming
    local fireBlocks = view.firing and not Mod.Config.ShootWhileSprinting
    local holdBlocks = (view.sprintHoldUntil or 0) > os.clock()
    local handsBusy = rawget(module, "hands") ~= nil

    if (aimingAllowed or firingAllowed)
        and not aimBlocks
        and not fireBlocks
        and not holdBlocks
        and not handsBusy then
        movement.blockSprint = false
    end
end

Mod.StepName = "CombinedGunMovement_" .. tostring(math.random(100000, 999999))

RunService:BindToRenderStep(
    Mod.StepName,
    Enum.RenderPriority.Input.Value,
    function()
        if Mod.Running then
            pcall(ApplyMovement)
        end
    end
)

local elapsed = 0

table.insert(
    Mod.Connections,
    RunService.Heartbeat:Connect(function(dt)
        if not Mod.Running then
            return
        end

        elapsed += dt

        if elapsed < 0.15 then
            return
        end

        elapsed = 0

        local current = Mod.Viewmodel and rawget(Mod.Viewmodel, "current")

        if type(current) == "table" then
            RegisterView(current)
        end

        for tool, saved in pairs(Mod.Tools) do
            pcall(function()
                if Mod.Config.FastReload then
                    if not saved.applied then
                        saved.original = tool:GetAttribute("ReloadScale")
                        saved.applied = true
                    end

                    local scale = math.max(
                        tonumber(Mod.Config.ReloadScale) or 0.1,
                        0.01
                    )

                    if tool:GetAttribute("ReloadScale") ~= scale then
                        tool:SetAttribute("ReloadScale", scale)
                    end
                elseif saved.applied then
                    tool:SetAttribute("ReloadScale", saved.original)
                    saved.applied = false
                end
            end)
        end

        for spec, saved in pairs(Mod.Specs) do
            pcall(ApplySpec, spec, saved)
        end

        for settings, saved in pairs(Mod.Settings) do
            pcall(function()
                if Mod.Config.NoSway then
                    if not saved.applied then
                        saved.original = settings.sway
                        saved.applied = true
                    end

                    if settings.sway ~= 0 then
                        settings.sway = 0
                    end
                elseif saved.applied then
                    settings.sway = saved.original
                    saved.applied = false
                end
            end)
        end
    end)
)

function Mod:Unload()
    if not self.Running then
        return
    end

    self.Running = false
    self.QueueToken += 1

    RunService:UnbindFromRenderStep(self.StepName)

    if self.CharacterConnection then
        self.CharacterConnection:Disconnect()
        self.CharacterConnection = nil
    end

    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end

    if self.Movement and self.AutoSprintApplied then
        pcall(function()
            self.Movement.autoSprint = self.MovementSaved
        end)
    end

    for tool, saved in pairs(self.Tools) do
        if saved.applied then
            pcall(function()
                tool:SetAttribute("ReloadScale", saved.original)
            end)
        end
    end

    for spec, saved in pairs(self.Specs) do
        pcall(function()
            if saved.aimApplied then
                spec.aimMove = saved.aimMove
            end

            if saved.kickApplied then
                spec.hipKick = saved.hipKick
                spec.hipKickRot = saved.hipKickRot
                spec.aimKick = saved.aimKick
                spec.aimKickRot = saved.aimKickRot
                spec.punch = saved.punch
            end
        end)
    end

    for settings, saved in pairs(self.Settings) do
        if saved.applied then
            pcall(function()
                settings.sway = saved.original
            end)
        end
    end

    if env.CombinedGunMovement == self then
        env.CombinedGunMovement = nil
    end
end

Mod:Rescan()

return Mod
