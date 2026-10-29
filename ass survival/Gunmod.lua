-- Check for table that is shared between executions.
if not shared then
	return warn("No shared, no script.")
end

-- Initialize Luraph globals if they do not exist.
loadstring("getfenv().LPH_NO_VIRTUALIZE = function(...) return ... end")()
getfenv().PP_SCRAMBLE_NUM = function(...) return ... end
getfenv().PP_SCRAMBLE_STR = function(...) return ... end
getfenv().PP_SCRAMBLE_RE_NUM = function(...) return ... end

if shared.GunMods and shared.GunMods.Unload then
	pcall(shared.GunMods.Unload, shared.GunMods)
end

---@module Features.Combat.GunMods
local GunMods = {
	Loaded = false,
	Table = {
		RecoilReduction = 0,
		SpreadReduction = 0,
		NoBulletDrop = false,
		InstaADS = false,
		InstaEquip = false,
		NoKick = false,
		NoSway = false
	}
}

GunMods.__index = GunMods

-- Constants.
local SPREAD_PROPERTY_NAMES = {
	"spread",
	"cone",
	"inaccuracy",
	"bloom",
	"dispersion",
	"pelletspread",
	"basespread",
	"hipspread",
	"aimcone",
	"hipcone"
}

-- Services.
local cloneref = cloneref or function(instance) return instance end
local replicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local playersService = cloneref(game:GetService("Players"))

-- State.
local targetConfig = nil
local targetKick = nil
local originalConfig = {}
local originalKick = {}
local originalGuns = {}
local originalSpreadEntries = {}
local cachedSpreadTables = {}
local characterConn = nil

---Check whether a field name corresponds to spread or accuracy cone.
---@param fieldName string
---@return boolean
local function isSpreadField(fieldName)
	local lowerName = string.lower(fieldName)
	for _, prop in ipairs(SPREAD_PROPERTY_NAMES) do
		if string.find(lowerName, prop) then
			return true
		end
	end
	return false
end

---Cache all spread fields recursively.
---@param tbl table
---@param visited table?
local function indexSpreadTable(tbl, visited)
	visited = visited or {}
	if visited[tbl] then return end
	visited[tbl] = true

	local hasSpread = false
	for key, value in pairs(tbl) do
		if typeof(value) == "table" then
			indexSpreadTable(value, visited)
		elseif typeof(value) == "number" and typeof(key) == "string" and isSpreadField(key) then
			if not originalSpreadEntries[tbl] then
				originalSpreadEntries[tbl] = {}
			end
			if originalSpreadEntries[tbl][key] == nil then
				originalSpreadEntries[tbl][key] = value
			end
			hasSpread = true
		end
	end

	if hasSpread and not table.find(cachedSpreadTables, tbl) then
		table.insert(cachedSpreadTables, tbl)
	end
end

---Scan memory once on initialization.
local function locateAndBackupTables()
	table.clear(cachedSpreadTables)
	table.clear(originalSpreadEntries)

	local fustFolder = replicatedStorage:FindFirstChild("Fust")
	if fustFolder and fustFolder:FindFirstChild("Items") then
		setthreadidentity(2)
		local success, itemsData = pcall(require, fustFolder.Items)
		setthreadidentity(8)
		if success and typeof(itemsData) == "table" then
			indexSpreadTable(itemsData)
		end
	end

	for _, item in ipairs(getgc(true)) do
		if typeof(item) == "table" and not isreadonly(item) then
			if not targetConfig and rawget(item, "RECOIL") and rawget(item, "RECOIL_CLIMB") and rawget(item, "ADS_SPREAD") then
				targetConfig = item
				originalConfig.RECOIL_CLIMB = rawget(item, "RECOIL_CLIMB")
				originalConfig.RECOIL_MAX = rawget(item, "RECOIL_MAX")
				originalConfig.ADS_RECOIL = rawget(item, "ADS_RECOIL")
				originalConfig.CROUCH_RECOIL = rawget(item, "CROUCH_RECOIL")
				originalConfig.MOVE_SPREAD = rawget(item, "MOVE_SPREAD")
				originalConfig.AIR_SPREAD = rawget(item, "AIR_SPREAD")
				originalConfig.ADS_SPREAD = rawget(item, "ADS_SPREAD")
				originalConfig.VISUAL_BLOOM = rawget(item, "VISUAL_BLOOM")
				originalConfig.ADS_TIME = rawget(item, "ADS_TIME")
				originalConfig.ADS_OUT_TIME = rawget(item, "ADS_OUT_TIME")
				originalConfig.DRAW_BLOCK = rawget(item, "DRAW_BLOCK")
				originalConfig.HOLSTER_TIME = rawget(item, "HOLSTER_TIME")

				originalConfig.recoilList = {}
				local recoilList = rawget(item, "RECOIL")
				if typeof(recoilList) == "table" then
					for name, data in pairs(recoilList) do
						if typeof(data) == "table" then
							originalConfig.recoilList[name] = {
								pitch = rawget(data, "pitch"),
								yaw = rawget(data, "yaw")
							}
						end
					end
				end

				originalConfig.proj = {}
				local projData = rawget(item, "PROJ")
				if typeof(projData) == "table" then
					if typeof(projData.bullet) == "table" then
						originalConfig.proj.bullet = {
							gravity = rawget(projData.bullet, "gravity"),
							life = rawget(projData.bullet, "life")
						}
					end
					if typeof(projData.pellet) == "table" then
						originalConfig.proj.pellet = {
							gravity = rawget(projData.pellet, "gravity"),
							life = rawget(projData.pellet, "life")
						}
					end
				end
			end

			if not targetKick and rawget(item, "GUNS") and rawget(item, "KICK_BACK") and rawget(item, "SWAY") then
				targetKick = item
				originalKick.KICK_BACK = rawget(item, "KICK_BACK")
				originalKick.KICK_PITCH = rawget(item, "KICK_PITCH")
				originalKick.ADS_KICK = rawget(item, "ADS_KICK")
				originalKick.SWAY = rawget(item, "SWAY")
				originalKick.SWAY_MAX = rawget(item, "SWAY_MAX")
				originalKick.SWAY_ROT = rawget(item, "SWAY_ROT")
				originalKick.BOB_WALK = rawget(item, "BOB_WALK")
				originalKick.BOB_IDLE = rawget(item, "BOB_IDLE")
				originalKick.EQUIP_TIME = rawget(item, "EQUIP_TIME")

				local gunsList = rawget(item, "GUNS")
				if typeof(gunsList) == "table" then
					for name, gunData in pairs(gunsList) do
						if typeof(gunData) == "table" then
							originalGuns[name] = {
								kickBack = rawget(gunData, "kickBack"),
								kickPitch = rawget(gunData, "kickPitch"),
								kickRoll = rawget(gunData, "kickRoll"),
								adsKick = rawget(gunData, "adsKick"),
								adsTime = rawget(gunData, "adsTime"),
								adsOutTime = rawget(gunData, "adsOutTime")
							}
						end
					end
				end
			end

			for k, _ in pairs(item) do
				if typeof(k) == "string" and isSpreadField(k) then
					indexSpreadTable(item)
					break
				end
			end
		end
	end
end

---Apply modifications without scanning memory.
function GunMods:Apply()
	local cfg = self.Table

	-- 1. No Recoil
	local recoilMult = 1 - math.clamp((cfg.RecoilReduction or 0) / 100, 0, 1)
	if targetConfig then
		rawset(targetConfig, "RECOIL_CLIMB", (originalConfig.RECOIL_CLIMB or 0) * recoilMult)
		rawset(targetConfig, "RECOIL_MAX", (originalConfig.RECOIL_MAX or 0) * recoilMult)
		rawset(targetConfig, "ADS_RECOIL", (originalConfig.ADS_RECOIL or 0) * recoilMult)
		rawset(targetConfig, "CROUCH_RECOIL", (originalConfig.CROUCH_RECOIL or 0) * recoilMult)

		local recoilList = rawget(targetConfig, "RECOIL")
		if typeof(recoilList) == "table" and originalConfig.recoilList then
			for name, data in pairs(recoilList) do
				if typeof(data) == "table" and originalConfig.recoilList[name] then
					rawset(data, "pitch", (originalConfig.recoilList[name].pitch or 0) * recoilMult)
					rawset(data, "yaw", (originalConfig.recoilList[name].yaw or 0) * recoilMult)
				end
			end
		end
	end

	-- 2. No Spread
	local spreadMult = 1 - math.clamp((cfg.SpreadReduction or 0) / 100, 0, 1)
	if targetConfig then
		rawset(targetConfig, "MOVE_SPREAD", (originalConfig.MOVE_SPREAD or 0) * spreadMult)
		rawset(targetConfig, "AIR_SPREAD", (originalConfig.AIR_SPREAD or 0) * spreadMult)
		rawset(targetConfig, "ADS_SPREAD", (originalConfig.ADS_SPREAD or 0) * spreadMult)
		rawset(targetConfig, "VISUAL_BLOOM", (originalConfig.VISUAL_BLOOM or 0) * spreadMult)
	end

	for i = 1, #cachedSpreadTables do
		local tbl = cachedSpreadTables[i]
		local props = originalSpreadEntries[tbl]
		if props then
			for key, origValue in pairs(props) do
				rawset(tbl, key, origValue * spreadMult)
			end
		end
	end

	-- 3. No Bullet Drop
	if targetConfig and originalConfig.proj then
		local projData = rawget(targetConfig, "PROJ")
		if typeof(projData) == "table" then
			if typeof(projData.bullet) == "table" and originalConfig.proj.bullet then
				rawset(projData.bullet, "gravity", cfg.NoBulletDrop and 0 or originalConfig.proj.bullet.gravity)
				rawset(projData.bullet, "life", cfg.NoBulletDrop and 5 or originalConfig.proj.bullet.life)
			end
			if typeof(projData.pellet) == "table" and originalConfig.proj.pellet then
				rawset(projData.pellet, "gravity", cfg.NoBulletDrop and 0 or originalConfig.proj.pellet.gravity)
				rawset(projData.pellet, "life", cfg.NoBulletDrop and 5 or originalConfig.proj.pellet.life)
			end
		end
	end

	-- 4. Instant ADS
	if targetConfig then
		rawset(targetConfig, "ADS_TIME", cfg.InstaADS and 0 or originalConfig.ADS_TIME)
		rawset(targetConfig, "ADS_OUT_TIME", cfg.InstaADS and 0 or originalConfig.ADS_OUT_TIME)
	end
	if targetKick and originalGuns then
		local gunsList = rawget(targetKick, "GUNS")
		if typeof(gunsList) == "table" then
			for name, gunData in pairs(gunsList) do
				if typeof(gunData) == "table" and originalGuns[name] then
					rawset(gunData, "adsTime", cfg.InstaADS and 0 or originalGuns[name].adsTime)
					rawset(gunData, "adsOutTime", cfg.InstaADS and 0 or originalGuns[name].adsOutTime)
				end
			end
		end
	end

	-- 5. Instant Equip
	if targetConfig then
		rawset(targetConfig, "DRAW_BLOCK", cfg.InstaEquip and 0 or originalConfig.DRAW_BLOCK)
		rawset(targetConfig, "HOLSTER_TIME", cfg.InstaEquip and 0 or originalConfig.HOLSTER_TIME)
	end
	if targetKick then
		rawset(targetKick, "EQUIP_TIME", cfg.InstaEquip and 0 or originalKick.EQUIP_TIME)
	end

	-- 6. No Kick
	if targetKick then
		rawset(targetKick, "KICK_BACK", cfg.NoKick and 0 or originalKick.KICK_BACK)
		rawset(targetKick, "KICK_PITCH", cfg.NoKick and 0 or originalKick.KICK_PITCH)
		rawset(targetKick, "ADS_KICK", cfg.NoKick and 0 or originalKick.ADS_KICK)

		local gunsList = rawget(targetKick, "GUNS")
		if typeof(gunsList) == "table" and originalGuns then
			for name, gunData in pairs(gunsList) do
				if typeof(gunData) == "table" and originalGuns[name] then
					rawset(gunData, "kickBack", cfg.NoKick and 0 or originalGuns[name].kickBack)
					rawset(gunData, "kickPitch", cfg.NoKick and 0 or originalGuns[name].kickPitch)
					rawset(gunData, "kickRoll", cfg.NoKick and 0 or originalGuns[name].kickRoll)
					rawset(gunData, "adsKick", cfg.NoKick and 0 or originalGuns[name].adsKick)
				end
			end
		end
	end

	-- 7. No Sway
	if targetKick then
		rawset(targetKick, "SWAY", cfg.NoSway and 0 or originalKick.SWAY)
		rawset(targetKick, "SWAY_MAX", cfg.NoSway and 0 or originalKick.SWAY_MAX)
		rawset(targetKick, "SWAY_ROT", cfg.NoSway and 0 or originalKick.SWAY_ROT)
		rawset(targetKick, "BOB_WALK", cfg.NoSway and 0 or originalKick.BOB_WALK)
		rawset(targetKick, "BOB_IDLE", cfg.NoSway and 0 or originalKick.BOB_IDLE)
	end
end

---Initialize the GunMods module.
---@return table
function GunMods:Load()
	if self.Loaded then return self end

	locateAndBackupTables()

	local localPlayer = playersService.LocalPlayer
	if localPlayer then
		characterConn = localPlayer.CharacterAdded:Connect(function()
			task.wait(0.5)
			self:Apply()
		end)
	end

	self.Loaded = true
	shared.GunMods = self
	return self
end

---Retrieve live configuration table.
---@return table
function GunMods:GetConfig()
	return self.Table
end

---Restore original gun configurations.
function GunMods:Unload()
	self.Loaded = false

	if characterConn then
		characterConn:Disconnect()
		characterConn = nil
	end

	self.Table.RecoilReduction = 0
	self.Table.SpreadReduction = 0
	self.Table.NoBulletDrop = false
	self.Table.InstaADS = false
	self.Table.InstaEquip = false
	self.Table.NoKick = false
	self.Table.NoSway = false

	self:Apply()

	table.clear(cachedSpreadTables)
	table.clear(originalSpreadEntries)
	shared.GunMods = nil
end

return GunMods
