return function(VisualsPage, Esp, EspCfg, World, WorldCfg, White, Gray, ColorOr)
    local VisualsSub = VisualsPage:SubPage({
        Name = "Visuals",
    })

    local EspSection = VisualsSub:Section({
        Name = "ESP",
        Side = 1,
    })

    local EspToggle = EspSection:Toggle({
        Name = "ESP",
        Flag = "ESPEnabled",
        Default = false,
        Meta = true,
        Callback = function(State)
            EspCfg.Enabled = State

            if State then
                Esp:Load()
            else
                Esp:Unload()
            end
        end,
    })

    EspToggle:Keybind({
        Flag = "ESPKey",
        Default = Enum.KeyCode.J,
        Mode = "Toggle",
    })

    local EspChild = EspToggle:Child({
        Name = "ESP options",
    })

    EspChild:Toggle({
        Name = "Team check",
        Flag = "ESPTeamCheck",
        Default = true,
        Callback = function(State)
            EspCfg.TeamCheck = State
        end,
    })

    EspChild:Slider({
        Name = "Max distance",
        Flag = "ESPDistance",
        Min = 50,
        Max = 5000,
        Default = 1000,
        Decimals = 1,
        Suffix = "st",
        Callback = function(Value)
            EspCfg.MaxDistance = Value
        end,
    })

    EspChild:Slider({
        Name = "FPS limit",
        Flag = "ESPLimitFPS",
        Min = 0,
        Max = 240,
        Default = 0,
        Decimals = 1,
        Callback = function(Value)
            EspCfg.LimitFPS = Value
        end,
    })

    local Boxes = EspCfg.Boxes

    local BoxToggle = EspChild:Toggle({
        Name = "Boxes",
        Flag = "BoxESP",
        Default = true,
        Callback = function(State)
            Boxes.Enabled = State
        end,
    })

    BoxToggle:Colorpicker({
        Flag = "ESPBoxTop",
        Default = ColorOr(Boxes.Gradients.Top, White),
        Callback = function(Color)
            Boxes.Gradients.Top = Color
        end,
    })

    BoxToggle:Colorpicker({
        Flag = "ESPBoxBot",
        Default = ColorOr(Boxes.Gradients.Bot, White),
        Callback = function(Color)
            Boxes.Gradients.Bot = Color
        end,
    })

    local Bounding = Boxes["Bounding Box"]

    EspChild:Toggle({
        Name = "Bounding box",
        Flag = "ESPBoundingBox",
        Default = false,
        Callback = function(State)
            Bounding.Enabled = State
        end,
    })

    EspChild:Slider({
        Name = "Box width padding",
        Flag = "ESPBoxX",
        Min = 0,
        Max = 30,
        Default = 0,
        Decimals = 1,
        Suffix = "px",
        Callback = function(Value)
            Bounding.BoxX = Value
        end,
    })

    EspChild:Slider({
        Name = "Box height padding",
        Flag = "ESPBoxY",
        Min = 0,
        Max = 30,
        Default = 2,
        Decimals = 1,
        Suffix = "px",
        Callback = function(Value)
            Bounding.BoxY = Value
        end,
    })

    local Glow = Boxes["Box Glow"]

    local GlowToggle = EspChild:Toggle({
        Name = "Box glow",
        Flag = "ESPGlow",
        Default = true,
        Callback = function(State)
            Glow.Enabled = State
        end,
    })

    GlowToggle:Colorpicker({
        Flag = "ESPGlowTop",
        Default = ColorOr(Glow.Top, White),
        Callback = function(Color)
            Glow.Top = Color
        end,
    })

    GlowToggle:Colorpicker({
        Flag = "ESPGlowBot",
        Default = ColorOr(Glow.Bot, White),
        Callback = function(Color)
            Glow.Bot = Color
        end,
    })

    EspChild:Slider({
        Name = "Glow transparency top",
        Flag = "ESPGlowT1",
        Min = 0,
        Max = 100,
        Default = 85,
        Decimals = 1,
        Suffix = "%",
        Callback = function(Value)
            Glow.Transparency[1] = Value / 100
        end,
    })

    EspChild:Slider({
        Name = "Glow transparency bottom",
        Flag = "ESPGlowT2",
        Min = 0,
        Max = 100,
        Default = 85,
        Decimals = 1,
        Suffix = "%",
        Callback = function(Value)
            Glow.Transparency[2] = Value / 100
        end,
    })

    local Filled = Boxes.Filled

    local FillToggle = EspChild:Toggle({
        Name = "Box fill",
        Flag = "ESPFill",
        Default = false,
        Callback = function(State)
            Filled.Enabled = State
        end,
    })

    FillToggle:Colorpicker({
        Flag = "ESPFillTop",
        Default = ColorOr(Filled.Top, White),
        Callback = function(Color)
            Filled.Top = Color
        end,
    })

    FillToggle:Colorpicker({
        Flag = "ESPFillBot",
        Default = ColorOr(Filled.Bot, White),
        Callback = function(Color)
            Filled.Bot = Color
        end,
    })

    EspChild:Slider({
        Name = "Fill transparency top",
        Flag = "ESPFillT1",
        Min = 0,
        Max = 100,
        Default = 85,
        Decimals = 1,
        Suffix = "%",
        Callback = function(Value)
            Filled.Transparency[1] = Value / 100
        end,
    })

    EspChild:Slider({
        Name = "Fill transparency bottom",
        Flag = "ESPFillT2",
        Min = 0,
        Max = 100,
        Default = 85,
        Decimals = 1,
        Suffix = "%",
        Callback = function(Value)
            Filled.Transparency[2] = Value / 100
        end,
    })

    local Texts = EspCfg.Texts

    local NameToggle = EspChild:Toggle({
        Name = "Names",
        Flag = "ESPNames",
        Default = true,
        Callback = function(State)
            Texts.Name.Enabled = State
        end,
    })

    NameToggle:Colorpicker({
        Flag = "ESPNameColor",
        Default = ColorOr(Texts.Name.Color, White),
        Callback = function(Color)
            Texts.Name.Color = Color
        end,
    })

    local DistToggle = EspChild:Toggle({
        Name = "Distance",
        Flag = "ESPDistanceText",
        Default = true,
        Callback = function(State)
            Texts.Distance.Enabled = State
        end,
    })

    DistToggle:Colorpicker({
        Flag = "ESPDistColor",
        Default = ColorOr(Texts.Distance.Color, Gray),
        Callback = function(Color)
            Texts.Distance.Color = Color
        end,
    })

    local HealthBar = EspCfg.Bars["Health Bar"]

    local HealthToggle = EspChild:Toggle({
        Name = "Health bar",
        Flag = "ESPHealth",
        Default = true,
        Callback = function(State)
            HealthBar.Enabled = State
        end,
    })

    HealthToggle:Colorpicker({
        Flag = "ESPHealthColor",
        Default = ColorOr(HealthBar.Color, Color3.fromRGB(0, 255, 0)),
        Callback = function(Color)
            HealthBar.Color = Color
        end,
    })

    local WeaponToggle = EspChild:Toggle({
        Name = "Weapon",
        Flag = "ESPWeapon",
        Default = true,
        Callback = function(State)
            Texts.Weapon.Enabled = State
        end,
    })

    WeaponToggle:Colorpicker({
        Flag = "ESPWeaponColor",
        Default = ColorOr(Texts.Weapon.Color, White),
        Callback = function(Color)
            Texts.Weapon.Color = Color
        end,
    })

    EspChild:Toggle({
        Name = "Weapon icon",
        Flag = "ESPWeaponIcon",
        Default = false,
        Callback = function(State)
            Texts.WeaponIcon.Enabled = State
        end,
    })

    EspChild:Slider({
        Name = "Icon size",
        Flag = "ESPIconSize",
        Min = 14,
        Max = 48,
        Default = 26,
        Decimals = 1,
        Suffix = "px",
        Callback = function(Value)
            Texts.WeaponIcon.Size = math.floor(Value + 0.5)
        end,
    })

    local StateToggle = EspChild:Toggle({
        Name = "State",
        Flag = "ESPState",
        Default = false,
        Callback = function(State)
            Texts.State.Enabled = State
        end,
    })

    StateToggle:Colorpicker({
        Flag = "ESPStateColor",
        Default = ColorOr(Texts.State.Color, White),
        Callback = function(Color)
            Texts.State.Color = Color
        end,
    })

    local WorldSub = VisualsPage:SubPage({
        Name = "World",
    })

    local WorldMainSection = WorldSub:Section({
        Name = "World",
        Side = 1,
    })

    local LightingSection = WorldSub:Section({
        Name = "Lighting",
        Side = 2,
    })

    WorldMainSection:Toggle({
        Name = "World visuals",
        Flag = "WorldEnabled",
        Default = false,
        Callback = function(State)
            WorldCfg.Enabled = State
        end,
    })

    WorldMainSection:Toggle({
        Name = "Remove game effects",
        Flag = "WorldRemoveEffects",
        Default = WorldCfg.RemoveGameEffects and true or false,
        Callback = function(State)
            WorldCfg.RemoveGameEffects = State
        end,
    })

    local TechnologyToggle = WorldMainSection:Toggle({
        Name = "Technology",
        Flag = "WorldTechnology",
        Default = WorldCfg.Technology and true or false,
        Callback = function(State)
            WorldCfg.Technology = State
        end,
    })

    local TechnologyChild = TechnologyToggle:Child({
        Name = "Technology options",
    })

    local TechnologyList = World:GetTechnologyList()

    TechnologyChild:Dropdown({
        Name = "Technology mode",
        Flag = "WorldTechnologyMode",
        Items = TechnologyList,
        Default = table.find(TechnologyList, WorldCfg.TechnologyValue)
            and WorldCfg.TechnologyValue
            or "ShadowMap",
        Callback = function(Value)
            WorldCfg.TechnologyValue = Value
        end,
    })

    local TimeToggle = WorldMainSection:Toggle({
        Name = "Time changer",
        Flag = "WorldTime",
        Default = WorldCfg.TimeChanger and true or false,
        Callback = function(State)
            WorldCfg.TimeChanger = State
        end,
    })

    local TimeChild = TimeToggle:Child({
        Name = "Time options",
    })

    WorldCfg.ClockTime = math.clamp(WorldCfg.ClockTime, 0, 24)

    TimeChild:Slider({
        Name = "Clock time",
        Flag = "WorldClockTime",
        Min = 0,
        Max = 24,
        Default = WorldCfg.ClockTime,
        Decimals = 0.1,
        Suffix = "h",
        Callback = function(Value)
            WorldCfg.ClockTime = Value
        end,
    })

    local SkyToggle = WorldMainSection:Toggle({
        Name = "Sky changer",
        Flag = "WorldSky",
        Default = WorldCfg.SkyChanger and true or false,
        Callback = function(State)
            WorldCfg.SkyChanger = State
        end,
    })

    local SkyChild = SkyToggle:Child({
        Name = "Sky options",
    })

    SkyChild:Dropdown({
        Name = "Skybox",
        Flag = "WorldSkybox",
        Items = World:GetSkyboxList(),
        Default = WorldCfg.SelectedSky,
        Callback = function(Value)
            WorldCfg.SelectedSky = Value
        end,
    })

    local CustomSkyToggle = WorldMainSection:Toggle({
        Name = "Custom skybox",
        Flag = "WorldCustomSky",
        Default = WorldCfg.UseCustomSkybox and true or false,
        Callback = function(State)
            WorldCfg.UseCustomSkybox = State
        end,
    })

    local CustomSkyChild = CustomSkyToggle:Child({
        Name = "Custom skybox IDs",
    })

    local SkyFaces = {
        {Key = "Bk", Name = "Back"},
        {Key = "Dn", Name = "Down"},
        {Key = "Ft", Name = "Front"},
        {Key = "Lf", Name = "Left"},
        {Key = "Rt", Name = "Right"},
        {Key = "Up", Name = "Up"},
    }

    if type(CustomSkyChild.Textbox) == "function" then
        for _, Face in ipairs(SkyFaces) do
            CustomSkyChild:Textbox({
                Name = Face.Name .. " face",
                Flag = "WorldCustomSky" .. Face.Key,
                Default = "",
                Placeholder = "Asset ID",
                Callback = function(Value)
                    World:SetCustomSkybox(Value, Face.Key)
                end,
            })
        end
    end

    local SkyParamsToggle = WorldMainSection:Toggle({
        Name = "Sky parameters",
        Flag = "WorldSkyParams",
        Default = WorldCfg.SkyParameters and true or false,
        Callback = function(State)
            WorldCfg.SkyParameters = State
        end,
    })

    local SkyParamsChild = SkyParamsToggle:Child({
        Name = "Sky parameter options",
    })

    WorldCfg.SkyStarCount = math.clamp(WorldCfg.SkyStarCount, 0, 5000)

    SkyParamsChild:Slider({
        Name = "Star count",
        Flag = "WorldStarCount",
        Min = 0,
        Max = 5000,
        Default = WorldCfg.SkyStarCount,
        Decimals = 1,
        Callback = function(Value)
            WorldCfg.SkyStarCount = Value
        end,
    })

    WorldCfg.SkySunSize = math.clamp(WorldCfg.SkySunSize, 0, 100)

    SkyParamsChild:Slider({
        Name = "Sun size",
        Flag = "WorldSunSize",
        Min = 0,
        Max = 100,
        Default = WorldCfg.SkySunSize,
        Decimals = 1,
        Callback = function(Value)
            WorldCfg.SkySunSize = Value
        end,
    })

    WorldCfg.SkyMoonSize = math.clamp(WorldCfg.SkyMoonSize, 0, 100)

    SkyParamsChild:Slider({
        Name = "Moon size",
        Flag = "WorldMoonSize",
        Min = 0,
        Max = 100,
        Default = WorldCfg.SkyMoonSize,
        Decimals = 1,
        Callback = function(Value)
            WorldCfg.SkyMoonSize = Value
        end,
    })

    SkyParamsChild:Toggle({
        Name = "Celestial bodies",
        Flag = "WorldCelestial",
        Default = WorldCfg.SkyCelestialBodies and true or false,
        Callback = function(State)
            WorldCfg.SkyCelestialBodies = State
        end,
    })

    local OrientationValues = {
        X = 0,
        Y = 0,
        Z = 0,
    }

    for _, Axis in ipairs({"X", "Y", "Z"}) do
        SkyParamsChild:Slider({
            Name = "Orientation " .. Axis,
            Flag = "WorldOrientation" .. Axis,
            Min = -180,
            Max = 180,
            Default = 0,
            Decimals = 1,
            Suffix = "°",
            Callback = function(Value)
                OrientationValues[Axis] = Value

                WorldCfg.SkyOrientation = Vector3.new(
                    OrientationValues.X,
                    OrientationValues.Y,
                    OrientationValues.Z
                )
            end,
        })
    end

    local AtmosphereToggle = WorldMainSection:Toggle({
        Name = "Atmosphere",
        Flag = "WorldAtmosphere",
        Default = WorldCfg.Atmosphere and true or false,
        Callback = function(State)
            WorldCfg.Atmosphere = State
        end,
    })

    AtmosphereToggle:Colorpicker({
        Flag = "WorldAtmosphereColor",
        Default = ColorOr(WorldCfg.AtmosphereColor, White),
        Callback = function(Color)
            WorldCfg.AtmosphereColor = Color
        end,
    })

    AtmosphereToggle:Colorpicker({
        Flag = "WorldAtmosphereDecay",
        Default = ColorOr(WorldCfg.AtmosphereDecay, White),
        Callback = function(Color)
            WorldCfg.AtmosphereDecay = Color
        end,
    })

    local AtmosphereChild = AtmosphereToggle:Child({
        Name = "Atmosphere options",
    })

    WorldCfg.AtmosphereDensity = math.clamp(WorldCfg.AtmosphereDensity, 0, 1)

    AtmosphereChild:Slider({
        Name = "Density",
        Flag = "WorldAtmosphereDensity",
        Min = 0,
        Max = 1,
        Default = WorldCfg.AtmosphereDensity,
        Decimals = 0.01,
        Callback = function(Value)
            WorldCfg.AtmosphereDensity = Value
        end,
    })

    WorldCfg.AtmosphereOffset = math.clamp(WorldCfg.AtmosphereOffset, 0, 1)

    AtmosphereChild:Slider({
        Name = "Offset",
        Flag = "WorldAtmosphereOffset",
        Min = 0,
        Max = 1,
        Default = WorldCfg.AtmosphereOffset,
        Decimals = 0.01,
        Callback = function(Value)
            WorldCfg.AtmosphereOffset = Value
        end,
    })

    WorldCfg.AtmosphereHaze = math.clamp(WorldCfg.AtmosphereHaze, 0, 10)

    AtmosphereChild:Slider({
        Name = "Haze",
        Flag = "WorldAtmosphereHaze",
        Min = 0,
        Max = 10,
        Default = WorldCfg.AtmosphereHaze,
        Decimals = 0.1,
        Callback = function(Value)
            WorldCfg.AtmosphereHaze = Value
        end,
    })

    WorldCfg.AtmosphereGlare = math.clamp(WorldCfg.AtmosphereGlare, 0, 10)

    AtmosphereChild:Slider({
        Name = "Glare",
        Flag = "WorldAtmosphereGlare",
        Min = 0,
        Max = 10,
        Default = WorldCfg.AtmosphereGlare,
        Decimals = 0.1,
        Callback = function(Value)
            WorldCfg.AtmosphereGlare = Value
        end,
    })

    local CloudsToggle = WorldMainSection:Toggle({
        Name = "Clouds",
        Flag = "WorldClouds",
        Default = WorldCfg.Clouds and true or false,
        Callback = function(State)
            WorldCfg.Clouds = State
        end,
    })

    CloudsToggle:Colorpicker({
        Flag = "WorldCloudsColor",
        Default = ColorOr(WorldCfg.CloudsColor, White),
        Callback = function(Color)
            WorldCfg.CloudsColor = Color
        end,
    })

    local CloudsChild = CloudsToggle:Child({
        Name = "Cloud options",
    })

    WorldCfg.CloudsCover = math.clamp(WorldCfg.CloudsCover, 0, 1)

    CloudsChild:Slider({
        Name = "Cover",
        Flag = "WorldCloudsCover",
        Min = 0,
        Max = 1,
        Default = WorldCfg.CloudsCover,
        Decimals = 0.01,
        Callback = function(Value)
            WorldCfg.CloudsCover = Value
        end,
    })

    WorldCfg.CloudsDensity = math.clamp(WorldCfg.CloudsDensity, 0, 1)

    CloudsChild:Slider({
        Name = "Density",
        Flag = "WorldCloudsDensity",
        Min = 0,
        Max = 1,
        Default = WorldCfg.CloudsDensity,
        Decimals = 0.01,
        Callback = function(Value)
            WorldCfg.CloudsDensity = Value
        end,
    })

    local AmbientToggle = LightingSection:Toggle({
        Name = "Ambient lighting",
        Flag = "WorldAmbient",
        Default = WorldCfg.Ambient and true or false,
        Callback = function(State)
            WorldCfg.Ambient = State
        end,
    })

    AmbientToggle:Colorpicker({
        Flag = "WorldAmbientColor",
        Default = ColorOr(WorldCfg.AmbientColor, White),
        Callback = function(Color)
            WorldCfg.AmbientColor = Color
        end,
    })

    local OutdoorToggle = LightingSection:Toggle({
        Name = "Outdoor ambient",
        Flag = "WorldOutdoor",
        Default = WorldCfg.OutdoorAmbient and true or false,
        Callback = function(State)
            WorldCfg.OutdoorAmbient = State
        end,
    })

    OutdoorToggle:Colorpicker({
        Flag = "WorldOutdoorColor",
        Default = ColorOr(WorldCfg.OutdoorAmbientColor, White),
        Callback = function(Color)
            WorldCfg.OutdoorAmbientColor = Color
        end,
    })

    local ShiftToggle = LightingSection:Toggle({
        Name = "Color shift",
        Flag = "WorldColorShift",
        Default = WorldCfg.ColorShift and true or false,
        Callback = function(State)
            WorldCfg.ColorShift = State
        end,
    })

    ShiftToggle:Colorpicker({
        Flag = "WorldShiftTop",
        Default = ColorOr(WorldCfg.ColorShiftTop, White),
        Callback = function(Color)
            WorldCfg.ColorShiftTop = Color
        end,
    })

    ShiftToggle:Colorpicker({
        Flag = "WorldShiftBottom",
        Default = ColorOr(WorldCfg.ColorShiftBottom, White),
        Callback = function(Color)
            WorldCfg.ColorShiftBottom = Color
        end,
    })

    local BrightnessToggle = LightingSection:Toggle({
        Name = "Brightness",
        Flag = "WorldBrightness",
        Default = WorldCfg.Brightness and true or false,
        Callback = function(State)
            WorldCfg.Brightness = State
        end,
    })

    local BrightnessChild = BrightnessToggle:Child({
        Name = "Brightness options",
    })

    WorldCfg.BrightnessValue = math.clamp(WorldCfg.BrightnessValue, 0, 10)

    BrightnessChild:Slider({
        Name = "Brightness value",
        Flag = "WorldBrightnessValue",
        Min = 0,
        Max = 10,
        Default = WorldCfg.BrightnessValue,
        Decimals = 0.1,
        Callback = function(Value)
            WorldCfg.BrightnessValue = Value
        end,
    })

    local ExposureToggle = LightingSection:Toggle({
        Name = "Exposure",
        Flag = "WorldExposure",
        Default = WorldCfg.Exposure and true or false,
        Callback = function(State)
            WorldCfg.Exposure = State
        end,
    })

    local ExposureChild = ExposureToggle:Child({
        Name = "Exposure options",
    })

    WorldCfg.ExposureValue = math.clamp(WorldCfg.ExposureValue, -5, 5)

    ExposureChild:Slider({
        Name = "Exposure value",
        Flag = "WorldExposureValue",
        Min = -5,
        Max = 5,
        Default = WorldCfg.ExposureValue,
        Decimals = 0.1,
        Callback = function(Value)
            WorldCfg.ExposureValue = Value
        end,
    })

    local ShadowsToggle = LightingSection:Toggle({
        Name = "Global shadows",
        Flag = "WorldGlobalShadows",
        Default = WorldCfg.GlobalShadows and true or false,
        Callback = function(State)
            WorldCfg.GlobalShadows = State
        end,
    })

    local ShadowsChild = ShadowsToggle:Child({
        Name = "Global shadow options",
    })

    ShadowsChild:Toggle({
        Name = "Shadows enabled",
        Flag = "WorldGlobalShadowsValue",
        Default = WorldCfg.GlobalShadowsValue and true or false,
        Callback = function(State)
            WorldCfg.GlobalShadowsValue = State
        end,
    })

    local SoftnessToggle = LightingSection:Toggle({
        Name = "Shadow softness",
        Flag = "WorldShadowSoftness",
        Default = WorldCfg.ShadowSoftness and true or false,
        Callback = function(State)
            WorldCfg.ShadowSoftness = State
        end,
    })

    local SoftnessChild = SoftnessToggle:Child({
        Name = "Shadow softness options",
    })

    WorldCfg.ShadowSoftnessValue = math.clamp(WorldCfg.ShadowSoftnessValue, 0, 1)

    SoftnessChild:Slider({
        Name = "Softness value",
        Flag = "WorldShadowSoftnessValue",
        Min = 0,
        Max = 1,
        Default = WorldCfg.ShadowSoftnessValue,
        Decimals = 0.01,
        Callback = function(Value)
            WorldCfg.ShadowSoftnessValue = Value
        end,
    })

    local DiffuseToggle = LightingSection:Toggle({
        Name = "Environment diffuse",
        Flag = "WorldEnvDiffuse",
        Default = WorldCfg.EnvironmentDiffuse and true or false,
        Callback = function(State)
            WorldCfg.EnvironmentDiffuse = State
        end,
    })

    local DiffuseChild = DiffuseToggle:Child({
        Name = "Environment diffuse options",
    })

    WorldCfg.EnvironmentDiffuseValue = math.clamp(WorldCfg.EnvironmentDiffuseValue, 0, 1)

    DiffuseChild:Slider({
        Name = "Diffuse scale",
        Flag = "WorldEnvDiffuseValue",
        Min = 0,
        Max = 1,
        Default = WorldCfg.EnvironmentDiffuseValue,
        Decimals = 0.01,
        Callback = function(Value)
            WorldCfg.EnvironmentDiffuseValue = Value
        end,
    })

    local SpecularToggle = LightingSection:Toggle({
        Name = "Environment specular",
        Flag = "WorldEnvSpecular",
        Default = WorldCfg.EnvironmentSpecular and true or false,
        Callback = function(State)
            WorldCfg.EnvironmentSpecular = State
        end,
    })

    local SpecularChild = SpecularToggle:Child({
        Name = "Environment specular options",
    })

    WorldCfg.EnvironmentSpecularValue = math.clamp(WorldCfg.EnvironmentSpecularValue, 0, 1)

    SpecularChild:Slider({
        Name = "Specular scale",
        Flag = "WorldEnvSpecularValue",
        Min = 0,
        Max = 1,
        Default = WorldCfg.EnvironmentSpecularValue,
        Decimals = 0.01,
        Callback = function(Value)
            WorldCfg.EnvironmentSpecularValue = Value
        end,
    })

    local FogToggle = LightingSection:Toggle({
        Name = "Fog",
        Flag = "WorldFog",
        Default = WorldCfg.Fog and true or false,
        Callback = function(State)
            WorldCfg.Fog = State
        end,
    })

    FogToggle:Colorpicker({
        Flag = "WorldFogColor",
        Default = ColorOr(WorldCfg.FogColor, White),
        Callback = function(Color)
            WorldCfg.FogColor = Color
        end,
    })

    local FogChild = FogToggle:Child({
        Name = "Fog options",
    })

    WorldCfg.FogStart = math.clamp(WorldCfg.FogStart, 0, 5000)

    FogChild:Slider({
        Name = "Fog start",
        Flag = "WorldFogStart",
        Min = 0,
        Max = 5000,
        Default = WorldCfg.FogStart,
        Decimals = 1,
        Suffix = "st",
        Callback = function(Value)
            WorldCfg.FogStart = Value
        end,
    })

    WorldCfg.FogEnd = math.clamp(WorldCfg.FogEnd, 0, 100000)

    FogChild:Slider({
        Name = "Fog end",
        Flag = "WorldFogEnd",
        Min = 0,
        Max = 100000,
        Default = WorldCfg.FogEnd,
        Decimals = 10,
        Suffix = "st",
        Callback = function(Value)
            WorldCfg.FogEnd = Value
        end,
    })

    local CorrectionToggle = LightingSection:Toggle({
        Name = "Color correction",
        Flag = "WorldColorCorrection",
        Default = WorldCfg.ColorCorrection and true or false,
        Callback = function(State)
            WorldCfg.ColorCorrection = State
        end,
    })

    CorrectionToggle:Colorpicker({
        Flag = "WorldTint",
        Default = ColorOr(WorldCfg.Tint, White),
        Callback = function(Color)
            WorldCfg.Tint = Color
        end,
    })

    local CorrectionChild = CorrectionToggle:Child({
        Name = "Color correction options",
    })

    WorldCfg.Saturation = math.clamp(WorldCfg.Saturation, -1, 3)

    CorrectionChild:Slider({
        Name = "Saturation",
        Flag = "WorldSaturation",
        Min = -1,
        Max = 3,
        Default = WorldCfg.Saturation,
        Decimals = 0.01,
        Callback = function(Value)
            WorldCfg.Saturation = Value
        end,
    })

    WorldCfg.Contrast = math.clamp(WorldCfg.Contrast, -1, 3)

    CorrectionChild:Slider({
        Name = "Contrast",
        Flag = "WorldContrast",
        Min = -1,
        Max = 3,
        Default = WorldCfg.Contrast,
        Decimals = 0.01,
        Callback = function(Value)
            WorldCfg.Contrast = Value
        end,
    })

    local BloomToggle = LightingSection:Toggle({
        Name = "Bloom",
        Flag = "WorldBloom",
        Default = WorldCfg.Bloom and true or false,
        Callback = function(State)
            WorldCfg.Bloom = State
        end,
    })

    local BloomChild = BloomToggle:Child({
        Name = "Bloom options",
    })

    WorldCfg.BloomIntensity = math.clamp(WorldCfg.BloomIntensity, 0, 3)

    BloomChild:Slider({
        Name = "Intensity",
        Flag = "WorldBloomIntensity",
        Min = 0,
        Max = 3,
        Default = WorldCfg.BloomIntensity,
        Decimals = 0.01,
        Callback = function(Value)
            WorldCfg.BloomIntensity = Value
        end,
    })

    WorldCfg.BloomSize = math.clamp(WorldCfg.BloomSize, 0, 56)

    BloomChild:Slider({
        Name = "Size",
        Flag = "WorldBloomSize",
        Min = 0,
        Max = 56,
        Default = WorldCfg.BloomSize,
        Decimals = 1,
        Callback = function(Value)
            WorldCfg.BloomSize = Value
        end,
    })

    WorldCfg.BloomThreshold = math.clamp(WorldCfg.BloomThreshold, 0, 3)

    BloomChild:Slider({
        Name = "Threshold",
        Flag = "WorldBloomThreshold",
        Min = 0,
        Max = 3,
        Default = WorldCfg.BloomThreshold,
        Decimals = 0.01,
        Callback = function(Value)
            WorldCfg.BloomThreshold = Value
        end,
    })

    local SunRaysToggle = LightingSection:Toggle({
        Name = "Sun rays",
        Flag = "WorldSunRays",
        Default = WorldCfg.SunRays and true or false,
        Callback = function(State)
            WorldCfg.SunRays = State
        end,
    })

    local SunRaysChild = SunRaysToggle:Child({
        Name = "Sun rays options",
    })

    WorldCfg.SunRaysIntensity = math.clamp(WorldCfg.SunRaysIntensity, 0, 1)

    SunRaysChild:Slider({
        Name = "Intensity",
        Flag = "WorldSunRaysIntensity",
        Min = 0,
        Max = 1,
        Default = WorldCfg.SunRaysIntensity,
        Decimals = 0.01,
        Callback = function(Value)
            WorldCfg.SunRaysIntensity = Value
        end,
    })

    WorldCfg.SunRaysSpread = math.clamp(WorldCfg.SunRaysSpread, 0, 1)

    SunRaysChild:Slider({
        Name = "Spread",
        Flag = "WorldSunRaysSpread",
        Min = 0,
        Max = 1,
        Default = WorldCfg.SunRaysSpread,
        Decimals = 0.01,
        Callback = function(Value)
            WorldCfg.SunRaysSpread = Value
        end,
    })

    local BlurToggle = LightingSection:Toggle({
        Name = "Blur",
        Flag = "WorldBlur",
        Default = WorldCfg.Blur and true or false,
        Callback = function(State)
            WorldCfg.Blur = State
        end,
    })

    local BlurChild = BlurToggle:Child({
        Name = "Blur options",
    })

    WorldCfg.BlurSize = math.clamp(WorldCfg.BlurSize, 0, 56)

    BlurChild:Slider({
        Name = "Blur size",
        Flag = "WorldBlurSize",
        Min = 0,
        Max = 56,
        Default = WorldCfg.BlurSize,
        Decimals = 1,
        Callback = function(Value)
            WorldCfg.BlurSize = Value
        end,
    })

    local DofToggle = LightingSection:Toggle({
        Name = "Depth of field",
        Flag = "WorldDof",
        Default = WorldCfg.DepthOfField and true or false,
        Callback = function(State)
            WorldCfg.DepthOfField = State
        end,
    })

    local DofChild = DofToggle:Child({
        Name = "Depth of field options",
    })

    WorldCfg.DofFarIntensity = math.clamp(WorldCfg.DofFarIntensity, 0, 1)

    DofChild:Slider({
        Name = "Far intensity",
        Flag = "WorldDofFar",
        Min = 0,
        Max = 1,
        Default = WorldCfg.DofFarIntensity,
        Decimals = 0.01,
        Callback = function(Value)
            WorldCfg.DofFarIntensity = Value
        end,
    })

    WorldCfg.DofNearIntensity = math.clamp(WorldCfg.DofNearIntensity, 0, 1)

    DofChild:Slider({
        Name = "Near intensity",
        Flag = "WorldDofNear",
        Min = 0,
        Max = 1,
        Default = WorldCfg.DofNearIntensity,
        Decimals = 0.01,
        Callback = function(Value)
            WorldCfg.DofNearIntensity = Value
        end,
    })

    WorldCfg.DofFocusDistance = math.clamp(WorldCfg.DofFocusDistance, 0, 500)

    DofChild:Slider({
        Name = "Focus distance",
        Flag = "WorldDofFocus",
        Min = 0,
        Max = 500,
        Default = WorldCfg.DofFocusDistance,
        Decimals = 1,
        Suffix = "st",
        Callback = function(Value)
            WorldCfg.DofFocusDistance = Value
        end,
    })

    WorldCfg.DofInFocusRadius = math.clamp(WorldCfg.DofInFocusRadius, 0, 500)

    DofChild:Slider({
        Name = "In-focus radius",
        Flag = "WorldDofRadius",
        Min = 0,
        Max = 500,
        Default = WorldCfg.DofInFocusRadius,
        Decimals = 1,
        Suffix = "st",
        Callback = function(Value)
            WorldCfg.DofInFocusRadius = Value
        end,
    })
end
