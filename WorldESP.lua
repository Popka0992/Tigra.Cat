-- Services.
local cloneref = cloneref or function(o) return o end
local workspaceService = cloneref(game:GetService("Workspace"))
local runService = cloneref(game:GetService("RunService"))

---@module Features.Visuals.WorldESP
local WorldESP = {
	Config = {
		Enabled = false,
		Boxes = false,
		Names = true,
		Distance = true,
		MaxDistance = 1000,
		Targets = {
			["ClothPlant"] = { Enabled = false, Name = "Hemp", Color = Color3.fromRGB(184, 184, 184) },
			["Backpack"] = { Enabled = false, Name = "Body Bag", Color = Color3.fromRGB(255, 101, 40) },
			["Brimstone Ore"] = { Enabled = false, Name = "Brimstone", Color = Color3.fromRGB(116, 103, 45) },
			["Iron Ore"] = { Enabled = false, Name = "Iron", Color = Color3.fromRGB(168, 105, 21) },
			["Stone Ore"] = { Enabled = false, Name = "Stone", Color = Color3.fromRGB(104, 104, 104) },
		}
	},
	Entities = {},
	Connections = {}
}

local function createEntityEsp(instance, definition)
	local box = Drawing.new("Square")
	box.Visible = false
	box.Thickness = 1
	box.Filled = false

	local nameText = Drawing.new("Text")
	nameText.Visible = false
	nameText.Size = 13
	nameText.Center = true
	nameText.Outline = true
	nameText.Font = 2

	local distText = Drawing.new("Text")
	distText.Visible = false
	distText.Size = 12
	distText.Center = true
	distText.Outline = true
	distText.Font = 2

	local entry = {
		Instance = instance,
		Definition = definition,
		Box = box,
		Name = nameText,
		Distance = distText
	}

	instance.AncestryChanged:Connect(function(_, parent)
		if not parent then
			box:Remove()
			nameText:Remove()
			distText:Remove()
			WorldESP.Entities[instance] = nil
		end
	end)

	WorldESP.Entities[instance] = entry
end

local function checkAndRegisterEntity(child)
	local def = WorldESP.Config.Targets[child.Name]
	if def and not WorldESP.Entities[child] then
		createEntityEsp(child, def)
	end
end

local function monitorContainer(container)
	for _, child in ipairs(container:GetChildren()) do
		checkAndRegisterEntity(child)
	end
	table.insert(WorldESP.Connections, container.ChildAdded:Connect(checkAndRegisterEntity))
end

---Initialize and start render cycle.
---@param config table?
---@return table
function WorldESP:Load(config)
	self:Unload()
	if config then
		for k, v in pairs(config) do self.Config[k] = v end
	end

	local containers = { "Resources", "DroppedPacks", "ClothPlants" }
	for _, name in ipairs(containers) do
		local folder = workspaceService:FindFirstChild(name)
		if folder then monitorContainer(folder) end
	end

	table.insert(self.Connections, workspaceService.ChildAdded:Connect(function(child)
		if table.find(containers, child.Name) then
			monitorContainer(child)
		else
			checkAndRegisterEntity(child)
		end
	end))

	table.insert(self.Connections, runService.PreRender:Connect(function()
		local camera = workspaceService.CurrentCamera
		if not camera then return end

		local camPos = camera.CFrame.Position
		local cfg = self.Config
		local isMasterEnabled = cfg.Enabled

		for inst, entry in pairs(self.Entities) do
			if not (inst and inst.Parent) then
				entry.Box.Visible = false
				entry.Name.Visible = false
				entry.Distance.Visible = false
				continue
			end

			local def = entry.Definition
			if not (isMasterEnabled and def.Enabled) then
				entry.Box.Visible = false
				entry.Name.Visible = false
				entry.Distance.Visible = false
				continue
			end

			local pivot = inst:GetPivot()
			local pos = pivot.Position
			local dist = (pos - camPos).Magnitude

			if dist > cfg.MaxDistance then
				entry.Box.Visible = false
				entry.Name.Visible = false
				entry.Distance.Visible = false
				continue
			end

			local screenPos, onScreen = camera:WorldToViewportPoint(pos)
			if not onScreen then
				entry.Box.Visible = false
				entry.Name.Visible = false
				entry.Distance.Visible = false
				continue
			end

			local color = def.Color
			local topY, bottomY, centerX = screenPos.Y, screenPos.Y, screenPos.X

			if cfg.Boxes then
				local cf, sz
				if inst:IsA("Model") then
					cf, sz = inst:GetBoundingBox()
				elseif inst:IsA("BasePart") then
					cf, sz = inst.CFrame, inst.Size
				else
					cf, sz = pivot, Vector3.new(2, 2, 2)
				end

				local half = sz / 2
				local corners = {
					cf * Vector3.new(-half.X, -half.Y, -half.Z),
					cf * Vector3.new(-half.X, -half.Y,  half.Z),
					cf * Vector3.new(-half.X,  half.Y, -half.Z),
					cf * Vector3.new(-half.X,  half.Y,  half.Z),
					cf * Vector3.new( half.X, -half.Y, -half.Z),
					cf * Vector3.new( half.X, -half.Y,  half.Z),
					cf * Vector3.new( half.X,  half.Y, -half.Z),
					cf * Vector3.new( half.X,  half.Y,  half.Z),
				}

				local minX, maxX = math.huge, -math.huge
				local minY, maxY = math.huge, -math.huge
				local valid = true

				for i = 1, 8 do
					local p = camera:WorldToViewportPoint(corners[i])
					if p.Z <= 0 then valid = false break end
					if p.X < minX then minX = p.X end
					if p.X > maxX then maxX = p.X end
					if p.Y < minY then minY = p.Y end
					if p.Y > maxY then maxY = p.Y end
				end

				if valid and maxX > minX and maxY > minY then
					entry.Box.Visible = true
					entry.Box.Position = Vector2.new(minX, minY)
					entry.Box.Size = Vector2.new(maxX - minX, maxY - minY)
					entry.Box.Color = color
					topY = minY
					bottomY = maxY
					centerX = (minX + maxX) / 2
				else
					entry.Box.Visible = false
				end
			else
				entry.Box.Visible = false
			end

			if cfg.Names then
				entry.Name.Visible = true
				entry.Name.Text = def.Name
				entry.Name.Color = color
				entry.Name.Position = Vector2.new(centerX, topY - 14)
			else
				entry.Name.Visible = false
			end

			if cfg.Distance then
				entry.Distance.Visible = true
				entry.Distance.Text = string.format("[%d st]", math.floor(dist))
				entry.Distance.Color = color
				entry.Distance.Position = Vector2.new(centerX, bottomY + (cfg.Boxes and 2 or 4))
			else
				entry.Distance.Visible = false
			end
		end
	end))

	return self
end

---Get current config table.
---@return table
function WorldESP:GetConfig()
	return self.Config
end

---Clean up all drawings and connections.
function WorldESP:Unload()
	for _, conn in ipairs(self.Connections) do conn:Disconnect() end
	table.clear(self.Connections)
	for _, entry in pairs(self.Entities) do
		if entry.Box then entry.Box:Remove() end
		if entry.Name then entry.Name:Remove() end
		if entry.Distance then entry.Distance:Remove() end
	end
	table.clear(self.Entities)
end

return WorldESP
