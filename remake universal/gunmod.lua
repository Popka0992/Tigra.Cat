local env = getgenv()

if env.CombinedGunMovement then
    pcall(function()
        env.CombinedGunMovement:Unload()
    end)
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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
    GunRecoil = nil,
    LookSettings = nil,

    Tools = setmetatable({}, { __mode = "k" }),
    Specs = setmetatable({}, { __mode = "k" }),
    Settings = setmetatable({}, { __mode = "k" }),
    Hooked = setmetatable({}, { __mode = "k" }),

    Connections = {},

    AutoSprintApplied = false,
    MovementSaved = nil,

    Found = {
        Movement = false,
        Viewmodel = false,
        Recoil = false,
        Spread = false,
        Sway = false,
    },

    Errors = {},
}

env.CombinedGunMovement = Mod

local function RecordError(name, err)
    Mod.Errors[name] = tostring(err)
end

local function Hook(fn, name, callback)
    if type(fn) ~= "function" then
        RecordError(name, "function not found")
        return false
    end

    if Mod.Hooked[fn] then
        return true
    end

    if type(hookfunction) ~= "function" then
        RecordError(name, "hookfunction is unavailable")
        return false
    end

    local original

    local ok, err = pcall(function()
        original = hookfunction(fn, function(...)
            if not Mod.Running then
                return original(...)
            end

            return callback(original, ...)
        end)
    end)

    if not ok then
        RecordError(name, err)
        return false
    end

    if type(original) ~= "function" then
        RecordError(name, "hookfunction did not return original function")
        return false
    end

    Mod.Hooked[fn] = name
    return true
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

    local ok, err = pcall(function()
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

    if not ok then
        Mod.Errors.Tool = tostring(err)
    end
end

local kickFields = {
    "hipKick",
    "hipKickRot",
    "aimKick",
    "aimKickRot",
    "scopeKick",
    "punch",
}

local function RegisterSpec(spec)
    if type(spec) ~= "table" then
        return
    end

    if not Mod.Specs[spec] then
        Mod.Specs[spec] = {
            aimMove = nil,
            aimApplied = false,

            kickValues = {},
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

        spec.aimMove = 1
    elseif saved.aimApplied then
        spec.aimMove = saved.aimMove
        saved.aimApplied = false
    end

    if Mod.Config.NoViewmodelKick then
        if not saved.kickApplied then
            for _, field in ipairs(kickFields) do
                saved.kickValues[field] = spec[field]
            end

            saved.kickApplied = true
        end

        for _, field in ipairs(kickFields) do
            local value = spec[field]

            if typeof(value) == "Vector3" then
                spec[field] = Vector3.zero
            elseif type(value) == "number" then
                spec[field] = 0
            end
        end
    elseif saved.kickApplied then
        for _, field in ipairs(kickFields) do
            spec[field] = saved.kickValues[field]
        end

        saved.kickValues = {}
        saved.kickApplied = false
    end
end

local function RegisterView(view)
    if type(view) ~= "table" then
        return
    end

    local tool = rawget(view, "tool")
    local spec = rawget(view, "spec")

    if typeof(tool) == "Instance" and tool:IsA("Tool") then
        RegisterTool(tool)
    end

    if type(spec) == "table" then
        RegisterSpec(spec)

        local saved = Mod.Specs[spec]

        if saved then
            local ok, err = pcall(ApplySpec, spec, saved)

            if not ok then
                Mod.Errors.Spec = tostring(err)
            end
        end
    end
end

local function InstallViewmodel(module)
    if type(module) ~= "table" then
        RecordError("Viewmodel", "module did not return a table")
        return
    end

    Mod.Viewmodel = module
    Mod.Found.Viewmodel = true

    local ready = rawget(module, "ready")
    local hipSpread = rawget(module, "hipSpread")

    if type(ready) == "function" then
        Hook(ready, "Viewmodel.ready", function(original, self, ...)
            if not Mod.Config.ShootWhileSprinting
                or type(self) ~= "table" then
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
    else
        RecordError("Viewmodel.ready", "function not found")
    end

    if type(hipSpread) == "function" then
        Mod.Found.Spread = Hook(
            hipSpread,
            "Viewmodel.hipSpread",
            function(original, ...)
                if Mod.Config.NoSpread then
                    return 0
                end

                return original(...)
            end
        )
    else
        RecordError("Viewmodel.hipSpread", "function not found")
    end

    local current = rawget(module, "current")

    if type(current) == "table" then
        RegisterView(current)
    end
end

local function InstallRecoil(module)
    if type(module) ~= "table" then
        RecordError("GunRecoil", "module did not return a table")
        return
    end

    Mod.GunRecoil = module
    Mod.Found.Recoil = true

    local shot = rawget(module, "shot")
    local cool = rawget(module, "cool")
    local coolExact = rawget(module, "coolExact")

    if type(shot) == "function" then
        Hook(shot, "GunRecoil.shot", function(
            original,
            self,
            aimAlpha,
            pitchScale,
            yawScale,
            ...
        )
            if not Mod.Config.NoRecoil then
                return original(
                    self,
                    aimAlpha,
                    pitchScale,
                    yawScale,
                    ...
                )
            end

            local result = table.pack(
                original(self, aimAlpha, 0, 0, ...)
            )

            if type(self) == "table" and type(self.roll) == "number" then
                self.roll = 0
            end

            return table.unpack(result, 1, result.n)
        end)
    else
        RecordError("GunRecoil.shot", "function not found")
    end

    if type(cool) == "function" then
        Hook(cool, "GunRecoil.cool", function(original, ...)
            if Mod.Config.NoBloom then
                return 0
            end

            return original(...)
        end)
    else
        RecordError("GunRecoil.cool", "function not found")
    end

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
    if type(settings) ~= "table" then
        RecordError("LookSettings", "module did not return a table")
        return
    end

    Mod.LookSettings = settings
    Mod.Found.Sway = true

    if not Mod.Settings[settings] then
        Mod.Settings[settings] = {
            original = nil,
            applied = false,
        }
    end
end

local function ApplySettings(settings, saved)
    if Mod.Config.NoSway then
        if not saved.applied then
            saved.original = settings.sway
            saved.applied = true
        end

        settings.sway = 0
    elseif saved.applied then
        settings.sway = saved.original
        saved.applied = false
    end
end

local function LoadModule(folder, name)
    local object = folder:FindFirstChild(name)

    if not object then
        RecordError(
            name,
            "ModuleScript not found in ReplicatedStorage.Voxel"
        )
        return nil
    end

    local ok, result = pcall(require, object)

    if not ok then
        RecordError(name, result)
        return nil
    end

    Mod.Errors[name] = nil
    return result
end

function Mod:Rescan()
    if not self.Running then
        return false
    end

    local voxel = ReplicatedStorage:FindFirstChild("Voxel")

    if not voxel then
        RecordError("Voxel", "ReplicatedStorage.Voxel not found")
        return false
    end

    self.Errors.Voxel = nil

    if not self.Movement then
        local movement = LoadModule(voxel, "Movement")

        if type(movement) == "table" then
            self.Movement = movement
            self.Found.Movement = true
        end
    end

    if not self.Viewmodel then
        local viewmodel = LoadModule(voxel, "Viewmodel")

        if viewmodel then
            InstallViewmodel(viewmodel)
        end
    end

    if not self.GunRecoil then
        local recoil = LoadModule(voxel, "GunRecoil")

        if recoil then
            InstallRecoil(recoil)
        end
    end

    if not self.LookSettings then
        local settings = LoadModule(voxel, "LookSettings")

        if settings then
            RegisterSettings(settings)
        end
    end

    local current = self.Viewmodel
        and rawget(self.Viewmodel, "current")

    if type(current) == "table" then
        RegisterView(current)
    end

    return true
end

local function ApplyMovement()
    local movement = Mod.Movement

    if type(movement) ~= "table" then
        return
    end

    if Mod.Config.AutoSprint then
        if not Mod.AutoSprintApplied then
            Mod.MovementSaved = movement.autoSprint
            Mod.AutoSprintApplied = true
        end

        movement.autoSprint = true
    elseif Mod.AutoSprintApplied then
        movement.autoSprint = Mod.MovementSaved
        Mod.AutoSprintApplied = false
    end

    local module = Mod.Viewmodel
    local view = module and rawget(module, "current")

    if type(view) ~= "table" or not view.active then
        return
    end

    RegisterView(view)

    local aimingAllowed =
        Mod.Config.SprintWhileAiming and view.aiming

    local firingAllowed =
        Mod.Config.ShootWhileSprinting and view.firing

    local aimBlocks =
        view.aiming and not Mod.Config.SprintWhileAiming

    local fireBlocks =
        view.firing and not Mod.Config.ShootWhileSprinting

    local holdBlocks =
        (view.sprintHoldUntil or 0) > os.clock()

    local handsBusy = rawget(module, "hands") ~= nil

    if (aimingAllowed or firingAllowed)
        and not aimBlocks
        and not fireBlocks
        and not holdBlocks
        and not handsBusy then
        movement.blockSprint = false
    end
end

Mod.StepName =
    "CombinedGunMovement_" .. tostring(math.random(100000, 999999))

RunService:BindToRenderStep(
    Mod.StepName,
    Enum.RenderPriority.Input.Value,
    function()
        if not Mod.Running then
            return
        end

        local ok, err = pcall(ApplyMovement)

        if not ok then
            Mod.Errors.MovementStep = tostring(err)
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

        local current = Mod.Viewmodel
            and rawget(Mod.Viewmodel, "current")

        if type(current) == "table" then
            RegisterView(current)
        end

        for tool in pairs(Mod.Tools) do
            RegisterTool(tool)
        end

        for spec, saved in pairs(Mod.Specs) do
            local ok, err = pcall(ApplySpec, spec, saved)

            if not ok then
                Mod.Errors.Spec = tostring(err)
            end
        end

        for settings, saved in pairs(Mod.Settings) do
            local ok, err = pcall(ApplySettings, settings, saved)

            if not ok then
                Mod.Errors.Settings = tostring(err)
            end
        end
    end)
)

function Mod:Unload()
    if not self.Running then
        return
    end

    self.Running = false

    RunService:UnbindFromRenderStep(self.StepName)

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
                for _, field in ipairs(kickFields) do
                    spec[field] = saved.kickValues[field]
                end
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
