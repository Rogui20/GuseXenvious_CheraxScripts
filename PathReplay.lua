require("natives/natives")
json = require "json"

Print = Logger.LogInfo

function SplitGlobals(GlobalString)
    local colcheteCount = select(2, GlobalString:gsub("%[.-%]", ""))
    local cleaned = GlobalString:gsub("%[.-%]", "")
    cleaned = cleaned:gsub("[^%d%.]", "")
    local total = 0
    for num in cleaned:gmatch("(%d+)") do
        total = total + tonumber(num)
    end
    total = total + colcheteCount
    return total
end

function ToFloat(V)
	return V * 1.0
end

--[[  Stand API Compatible v3 Implementation (for Cherax)
      Author: Adapted by ChatGPT
      Fully supports: v3.func(a,b) and a:func(b)
      Excludes: toRot, lookAt
--]]

local v3 = {}
v3.__index = v3

-- ===== Constructor =====
function v3.new(x, y, z)
	if type(x) == "table" or type(x) == "userdata" then
		return setmetatable({
			x = x.x or 0.0,
			y = x.y or 0.0,
			z = x.z or 0.0
		}, v3)
	elseif type(x) == "number" and type(y) == "number" and type(z) == "number" then
		return setmetatable({ x = x, y = y, z = z }, v3)
	else
		return setmetatable({ x = 0.0, y = 0.0, z = 0.0 }, v3)
	end
end

setmetatable(v3, {
	__call = function(_, ...)
		return v3.new(...)
	end
})

-- ===== Internal helper to unify method/static calls =====
local function selfArg(a, b)
	if getmetatable(a) == v3 then return a, b end
	if getmetatable(b) == v3 then return b, a end
	return a, b
end

-- ===== Getters =====
function v3.get(a)
	local self = a; return self.x, self.y, self.z
end

function v3.getX(a) return a.x end

function v3.getY(a) return a.y end

function v3.getZ(a) return a.z end

function v3.getHeading(a)
	return math.deg(math.atan2(a.y, a.x))
end

-- ===== Setters =====
function v3.set(a, x, y, z)
	a.x, a.y, a.z = x or 0, y or 0, z or 0
	return a
end

function v3.setX(a, x)
	a.x = x
	return a
end

function v3.setY(a, y)
	a.y = y
	return a
end

function v3.setZ(a, z)
	a.z = z
	return a
end

function v3.reset(a)
	a.x, a.y, a.z = 0, 0, 0
	return a
end

-- ===== Arithmetic (in-place) =====
function v3.add(a, b)
	a.x = a.x + b.x
	a.y = a.y + b.y
	a.z = a.z + b.z
	return a
end

function v3.sub(a, b)
	a.x = a.x - b.x
	a.y = a.y - b.y
	a.z = a.z - b.z
	return a
end

function v3.mul(a, f)
	a.x = a.x * f
	a.y = a.y * f
	a.z = a.z * f
	return a
end

function v3.div(a, f)
	a.x = a.x / f
	a.y = a.y / f
	a.z = a.z / f
	return a
end

-- ===== Arithmetic (new instance) =====
function v3.addNew(a, b) return v3(a.x + b.x, a.y + b.y, a.z + b.z) end

function v3.subNew(a, b) return v3(a.x - b.x, a.y - b.y, a.z - b.z) end

function v3.mulNew(a, f) return v3(a.x * f, a.y * f, a.z * f) end

function v3.divNew(a, f) return v3(a.x / f, a.y / f, a.z / f) end

-- ===== Comparison =====
function v3.eq(a, b) return a.x == b.x and a.y == b.y and a.z == b.z end

-- ===== Magnitude / Distance =====
function v3.magnitude(a)
	return math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
end

v3.__len = function(self) return self:magnitude() end

function v3.distance(a, b)
	local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- ===== Vector operations =====
function v3.abs(a)
	a.x, a.y, a.z = math.abs(a.x), math.abs(a.y), math.abs(a.z)
	return a
end

function v3.sum(a)
	return a.x + a.y + a.z
end

function v3.min(a)
	return math.min(a.x, a.y, a.z)
end

function v3.max(a)
	return math.max(a.x, a.y, a.z)
end

function v3.dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z
end

function v3.normalise(a)
	local mag = a:magnitude()
	if mag > 0 then
		a.x, a.y, a.z = a.x / mag, a.y / mag, a.z / mag
	end
	return a
end

function v3.crossProduct(a, b)
	return v3(
		a.y * b.z - a.z * b.y,
		a.z * b.x - a.x * b.z,
		a.x * b.y - a.y * b.x
	)
end

function v3.toDir(a)
	local mag = math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
	if mag == 0 then
		return v3(0, 0, 0)
	end
	return v3(a.x / mag, a.y / mag, a.z / mag)
end

-- ===== Operator Overloads =====
v3.__add = function(a, b) return v3.addNew(a, b) end
v3.__sub = function(a, b) return v3.subNew(a, b) end
v3.__mul = function(a, b)
	if type(a) == "number" then
		return v3.mulNew(b, a)
	elseif type(b) == "number" then
		return v3.mulNew(a, b)
	else
		error("v3 multiplication only supports scalar * vector or vector * scalar")
	end
end
v3.__div = function(a, b)
	if type(b) == "number" then
		return v3.divNew(a, b)
	else
		error("v3 division only supports vector / scalar")
	end
end
v3.__eq = function(a, b) return v3.eq(a, b) end
v3.__tostring = function(a) return string.format("v3(%.3f, %.3f, %.3f)", a.x, a.y, a.z) end

-- ===== Make every function dual-callable (obj:func() or v3.func(obj)) =====
for k, fn in pairs(v3) do
	if type(fn) == "function" and k ~= "new" then
		v3[k] = function(...)
			local a, b = ...
			if type(a) == "table" and getmetatable(a) == v3 then
				return fn(...)
			else
				return fn(v3, ...)
			end
		end
	end
end

local ScriptsDir = FileMgr.GetMenuRootPath() .. "\\Lua\\"

local FileNameForSave = "StoredPath"
local PathDirSaveds = ScriptsDir .. "PathReplay\\"
local GameModesDir = ScriptsDir .. "PathReplay\\GameModesDir\\"

FileMgr.CreateDir(PathDirSaveds)
FileMgr.CreateDir(GameModesDir)

local entities = {}
entities.set_can_migrate = function(entity, canMigrate)
	local Pointer = GTA.HandleToPointer(entity):GetAddress()
	if Pointer ~= 0 then
		Pointer = Memory.ReadLong(Pointer+0xD0)
		if Pointer ~= 0 then
			local Bits = Memory.ReadByte(Pointer+0x4E)
			if not canMigrate then
				if not is_bit_set(Bits, 1) then
					Bits = set_bit(Bits, 1)
					Memory.WriteByte(Pointer+0x4E, Bits)
				end
			else
				if is_bit_set(Bits, 1) then
					Bits = clear_bit(Bits, 1)
					Memory.WriteByte(Pointer+0x4E, Bits)
				end
			end
		end
	end
end

entities.delete_by_handle = function(entity)
	local mem = Memory.AllocInt()
	Memory.WriteInt(mem, entity)
	ENTITY.DELETE_ENTITY(mem)
	Memory.Free(mem)
end

local util = {}
util.remove_blip = function(blip)
	local Addr = Memory.Alloc(8)
	Memory.WriteInt(Addr, blip)
	HUD.REMOVE_BLIP(Addr)
	Memory.Free(Addr)
end

function LoadJSON(path)
    local myTable = {}
    local file = io.open( path, "r" )

    if file then
        -- read all contents of file into a string
        local contents = file:read( "*a" )
        myTable = json.decode(contents);
        io.close( file )
        return myTable
    end
    return {}
end


function SaveJSONFile(FileName, JSONContents)
    local File = io.open(FileName, "w+")
    if File then
        local Contents = json.encode(JSONContents)
        File:write(Contents)
        io.close(File)
    end
end

function set_entity_as_no_longer_needed(entity)
	local pHandle = Memory.AllocInt()
	Memory.WriteInt(pHandle, entity)
	ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(pHandle)
	Memory.Free(pHandle)
end

local ReplayListFeatures = {}
local ReplayFeatures = {}
local RecordFeatures = {}

local ReplaysToLoad = {}

local GameModeMakerData = {
	MissionVehicles = {},
	Vehicles = {},
	PreviewVehicles = {},
	MaxVehicles = 32,
	ListVehicles = {},
	ListVehicleTypes = {
		"Normal",
		"Replay"
	},
	ListReplayFiles = {},
	VehicleTypesEnum = {
		Normal = 1,
		Replay = 2
	},
	GMVehIndex = 1,
	GameModeName = "MyGameMode",
	GameModesList = {},
	GameModes = {}
}

local GMFeatures = {
	GMVehIndexFeature = nil,
	GMVehTypeFeature = nil,
	GMVehReplayFileFeature = nil,
	GMVehInvincibleFeature = nil,
	GMVehAttachedToFeature = nil,
	GMVehAttachOffsetXFeature = nil,
	GMVehAttachOffsetYFeature = nil,
	GMVehAttachOffsetZFeature = nil,
	GMVehAttachRotXFeature = nil,
	GMVehAttachRotYFeature = nil,
	GMVehAttachRotZFeature = nil,
	GMVehRespawnForTeamFeature = nil,
	GMVehUseBoolFeature = nil,

	GMLoadGameModeFeature = nil
}

function GetReplaysList()
	for k = 1, #ReplayListFeatures do
		FeatureMgr.RemoveFeature(ReplayListFeatures[k].Hash)
	end
	ReplayListFeatures = {}
	ReplaysToLoad = {}
	GameModeMakerData.ListReplayFiles = {}
	local Files = FileMgr.FindFiles(PathDirSaveds, ".txt", false)
	for k = 1, #Files do
		local _, FileName, Ext = string.match(Files[k], "(.-)([^\\/]-%.?)[.]([^%.\\/]*)$")
		if Ext == "txt" then
			local Hash = Utils.Joaat(string.gsub(FileName, " ", ""))
			ReplayListFeatures[#ReplayListFeatures+1] = {
				Hash = Hash,
				Feature = FeatureMgr.AddFeature(Hash, FileName, eFeatureType.Toggle, "", function(f)
					if f:IsToggled() then
						ReplaysToLoad[Files[k]] = true
					else
						ReplaysToLoad[Files[k]] = nil
					end
				end),
				FileName = FileName,
				FilePath = Files[k]
			}
			GameModeMakerData.ListReplayFiles[#GameModeMakerData.ListReplayFiles+1] = FileName
		end
	end
	Script.QueueJob(function()
		Script.Yield(1000)
		GMFeatures.GMVehReplayFileFeature:SetList(GameModeMakerData.ListReplayFiles)
	end)
end

function GetGameModesList()
	GameModeMakerData.GameModesList = {}
	GameModeMakerData.GameModes = {}
	local Files = FileMgr.FindFiles(GameModesDir, ".json", false)
	for k = 1, #Files do
		local _, FileName, Ext = string.match(Files[k], "(.-)([^\\/]-%.?)[.]([^%.\\/]*)$")
		if Ext == "json" then
			GameModeMakerData.GameModesList[#GameModeMakerData.GameModesList+1] = FileName
			GameModeMakerData.GameModes[#GameModeMakerData.GameModes+1] = Files[k]
		end
	end
	Script.QueueJob(function()
		Script.Yield(1000)
		GMFeatures.GMLoadGameModeFeature:SetList(GameModeMakerData.GameModesList)
	end)
end

FeatureMgr.AddFeature(Utils.Joaat("Replay_RefreshReplays"), "Refresh Replays", eFeatureType.Button, "Updates the replay list.", function(f)
	GetReplaysList()
end)

RecordFeatures[#RecordFeatures+1] = {Hash = Utils.Joaat("Replay_SetFileName"), Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_SetFileName"), "Set File Name", eFeatureType.InputText, "",
		function(f)
			FileNameForSave = f:GetStringValue()
		end)
	}

GetReplaysList()
GetGameModesList()

function ClearFile(FileName)
	local File = io.open(FileName, "w") -- Abrir em modo de escrita ("w") para limpar
	if File then
		File:close()                 -- Fechar o arquivo para garantir que foi zerado
	end
end

local AiHateRel = "rgFM_AiHate"
local AiLikeRel = "rgFM_AiLike"
local AiLikeHateAiHateRel = "rgFM_AiLike_HateAiHate"
local AiHateAiHateRel = "rgFM_HateAiHate"
local AiHateEveryone = "rgFM_HateEveryOne"

local EmptyRecord = true
RecordFeatures[#RecordFeatures+1] = {Hash = Utils.Joaat("Replay_EmptyRecord"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_EmptyRecord"), "Empty Record Before Saving", eFeatureType.Toggle, "",
	function(f)
		EmptyRecord = f:IsToggled()
	end):SetValue(EmptyRecord)
}

local RegisteredV2 = {}
local CurrentVehicleV2 = 0

function CopyTable(orig)
	if type(orig) ~= "table" then
		return orig
	end

	local copy = {}
	for key, value in pairs(orig) do
		copy[CopyTable(key)] = CopyTable(value)
	end

	return copy
end

local function handle_exists(ent)
	return ent ~= 0 and ENTITY.DOES_ENTITY_EXIST(ent)
end

local function idx_of_handle(t, h)
	for i = 1, #t do if t[i] == h then return i end end
	return 0
end

local function ensure_setup_for_vehicle(veh)
	if not handle_exists(veh) then return end
	if not ENTITY.IS_ENTITY_A_MISSION_ENTITY(veh) then
		ENTITY.SET_ENTITY_AS_MISSION_ENTITY(veh, false, true)
	end
	ENTITY.SET_ENTITY_INVINCIBLE(veh, true)
	entities.set_can_migrate(veh, false)
end

function FindFrameForVehicleAtTime(state)
	local frames = state.frames
	if not frames or #frames == 0 then return nil, nil, 0 end

	-- Usa o tempo correto (replay ou gravação)
	local t = state.replay_time or state.record_time or 0

	-- Limita tempo dentro do intervalo
	if t <= frames[1].time then
		return 1, 1, 0
	elseif t >= frames[#frames].time then
		return #frames, #frames, 0
	end

	-- Mantém índice local (melhor performance que reiniciar do 1)
	state.last_index = state.last_index or 1
	local idx = state.last_index

	-- Busca incremental pra frente
	while idx < #frames and frames[idx + 1].time <= t do
		idx = idx + 1
	end
	-- Busca incremental pra trás (caso rewind)
	while idx > 1 and frames[idx].time > t do
		idx = idx - 1
	end

	state.last_index = idx

	-- Calcula interpolação entre frames
	local f1 = frames[idx]
	local f2 = frames[idx + 1] or f1
	local interp = 0
	if f2.time > f1.time then
		interp = (t - f1.time) / (f2.time - f1.time)
	end

	return idx, idx + 1, interp
end

function FindFrameIndex(Table, Idx, Time)
	if Time <= Table[1].Time then
		return 1
	elseif Time >= Table[#Table].Time then
		return #Table
	end
	if #Table == 1 then
		return 1
	end
	local Index = Idx
	if Index > #Table then
		Index = #Table
	end
	while Index < #Table and Table[Index + 1].Time <= Time do
		Index = Index + 1
	end
	while Index > 1 and Table[Index].Time > Time do
		Index = Index - 1
	end
	return Index
end

function GetEntityPlayerIsAimingAt(Player)
    local EntAddr = Memory.AllocInt()
    local Found = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(Player, EntAddr)
    local Ent = 0
    if Found then
        Ent = Memory.ReadInt(EntAddr)
    end
    Memory.Free(EntAddr)
    return Ent
end

RecordFeatures[#RecordFeatures+1] = {Hash = Utils.Joaat("Replay_RegVehicle"), 
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_RegVehicle"), "Register Current Vehicle", eFeatureType.Button, "To record.",
		function(f)
		local veh = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
		if handle_exists(veh) then
			if idx_of_handle(RegisteredV2, veh) == 0 then
				RegisteredV2[#RegisteredV2 + 1] = veh
				ensure_setup_for_vehicle(veh)
				Print("Registered vehicle handle " .. tostring(veh))
				GUI.AddToast("Path Replay", "Registered vehicle handle " .. tostring(veh), 3000, eToastPos.TOP_RIGHT )
			else
				Print("Vehicle already in the list.")
				GUI.AddToast("Path Replay", "Vehicle already in the list.", 3000, eToastPos.TOP_RIGHT )
			end
		else
			Print("No vehicle to register.")
			GUI.AddToast("Path Replay", "No vehicle to register.", 3000, eToastPos.TOP_RIGHT )
		end
	end)
}
RecordFeatures[#RecordFeatures+1] = {Hash = Utils.Joaat("Replay_UnregVehicle"), 
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_UnregVehicle"), "Unregister Current Vehicle", eFeatureType.Button, "Remove from record list.",
	function()
		local veh = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
		if handle_exists(veh) then
			local Idx = idx_of_handle(RegisteredV2, veh)
			if Idx ~= 0 then
				table.remove(RegisteredV2, Idx)
				Print("Unregistered vehicle handle " .. tostring(veh).. " index "..Idx)
				GUI.AddToast("Path Replay", "Unregistered vehicle handle " .. tostring(veh).. " index "..Idx, 3000, eToastPos.TOP_RIGHT )
			else
				Print("Vehicle is not registered, nothing removed.")
				GUI.AddToast("Path Replay", "Vehicle is not registered, nothing removed.", 3000, eToastPos.TOP_RIGHT )
			end
		else
			Print("No vehicle to unregister.")
			GUI.AddToast("Path Replay", "No vehicle to unregister.", 3000, eToastPos.TOP_RIGHT )
		end
	end)
}

function ROTATION_TO_DIRECTION(rotation)
	local adjusted_rotation = { 
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}
	local direction = {
		x = - math.sin(adjusted_rotation.z) * math.abs(math.cos(adjusted_rotation.x)),
		y =   math.cos(adjusted_rotation.z) * math.abs(math.cos(adjusted_rotation.x)),
		z =   math.sin(adjusted_rotation.x)
	}
	return direction
end

function ReadVector3(Addr)
	local x, y, z = Memory.ReadFloat(Addr), Memory.ReadFloat(Addr+8), Memory.ReadFloat(Addr+16)
	return v3.new(x, y, z)
end

function RaycastFromCamera(Entity, Distance, Flags, Flags2)
	local HitCoords = v3.new()
	local Normal = v3.new()
	local CamRot = CAM.GET_GAMEPLAY_CAM_ROT(2)
	local FVect = ROTATION_TO_DIRECTION(CamRot)
	local PPos = CAM.GET_GAMEPLAY_CAM_COORD()
	local AdjustedX = PPos.x + FVect.x * Distance
	local AdjustedY = PPos.y + FVect.y * Distance
	local AdjustedZ = PPos.z + FVect.z * Distance
	local DidHitAddr = Memory.Alloc(1)
	local EndCoordsAddr = Memory.Alloc(8*3)
	local NormalAddr = Memory.Alloc(8*3)
	local HitEntityAddr = Memory.AllocInt()
	
	local Handle = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
		PPos.x, PPos.y, PPos.z,
		AdjustedX, AdjustedY, AdjustedZ,
		Flags or -1,
		Entity, Flags2 or 0
	)
	SHAPETEST.GET_SHAPE_TEST_RESULT(Handle, DidHitAddr, EndCoordsAddr, NormalAddr, HitEntityAddr)
	if Memory.ReadByte(DidHitAddr) ~= 0 then
		HitCoords = ReadVector3(EndCoordsAddr)
		Normal = ReadVector3(NormalAddr)
	else
		HitCoords = v3.new(AdjustedX, AdjustedY, AdjustedZ)
	end
	local DidHitBool = Memory.ReadByte(DidHitAddr)
	local HitEntityInt = Memory.ReadInt(HitEntityAddr)
	Memory.Free(DidHitAddr)
	Memory.Free(EndCoordsAddr)
	Memory.Free(HitEntityAddr)
	Memory.Free(NormalAddr)
	return DidHitBool ~= 0, HitCoords, Normal, HitEntityInt
end

local AimedRegister = false
RecordFeatures[#RecordFeatures+1] = {
	Hash = Utils.Joaat("Replay_VehRegisterManager"), 
	Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_VehRegisterManager"), "Vehicle Register Manager", eFeatureType.Toggle, "To record.",
	function(f)
		AimedRegister = f:IsToggled()
		Script.QueueJob(function()
			if AimedRegister then
				local Ents = {}
				while AimedRegister do
					local PlayerPed = PLAYER.PLAYER_PED_ID()
					local Pos = ENTITY.GET_ENTITY_COORDS(PlayerPed)
					local CamRot = CAM.GET_GAMEPLAY_CAM_ROT(2)
					local Dir = v3.new(ROTATION_TO_DIRECTION(CamRot))
					local NewPos = v3.add(v3.new(Pos), v3.mul(Dir, 100.0))
					local Hit, EndCoords, Normal, Ent = RaycastFromCamera(PlayerPed, 100.0, 2, 0)
					if Hit then
						GRAPHICS.DRAW_LINE(Pos.x, Pos.y, Pos.z, EndCoords.x, EndCoords.y, EndCoords.z, 255, 255, 255, 255)
					else
						GRAPHICS.DRAW_LINE(Pos.x, Pos.y, Pos.z, NewPos.x, NewPos.y, NewPos.z, 255, 255, 255, 255)
					end
					if PAD.IS_CONTROL_JUST_PRESSED(0, 24) then
						if Hit and Ent ~= 0 and not Ents[Ent] then
							if ENTITY.IS_ENTITY_A_VEHICLE(Ent) then
								if idx_of_handle(RegisteredV2, Ent) == 0 then
									RegisteredV2[#RegisteredV2 + 1] = Ent
									ensure_setup_for_vehicle(Ent)
									Print("Registered vehicle handle " .. tostring(Ent))
									GUI.AddToast("Path Replay", "Registered vehicle handle " .. tostring(Ent), 3000, eToastPos.TOP_RIGHT )
								else
									Print("Vehicle already in the list.")
									GUI.AddToast("Path Replay", "Vehicle already in the list.", 3000, eToastPos.TOP_RIGHT )
								end
								Ents[Ent] = true
							else
								Print("Entity is not a vehicle.")
								GUI.AddToast("Path Replay", "Entity is not a vehicle.", 3000, eToastPos.TOP_RIGHT )
							end
						end
					end
					if PAD.IS_CONTROL_JUST_PRESSED(0, 25) then
						if Hit and Ent ~= 0 then
							local Idx = idx_of_handle(RegisteredV2, Ent)
							if Idx ~= 0 then
								entities.set_can_migrate(Ent, true)
								table.remove(RegisteredV2, Idx)
								Print("Unregistered vehicle handle " .. tostring(Ent).. " index "..Idx)
								GUI.AddToast("Path Replay", "Unregistered vehicle handle " .. tostring(Ent).. " index "..Idx, 3000, eToastPos.TOP_RIGHT )
							else
								Print("Vehicle is not registered, nothing removed.")
								GUI.AddToast("Path Replay", "Vehicle is not registered, nothing removed.", 3000, eToastPos.TOP_RIGHT )
							end
							Ents[Ent] = nil
						end
					end
					Script.Yield(0)
				end
			end
		end)
	end)
}

RecordFeatures[#RecordFeatures+1] = {
	Hash = Utils.Joaat("Replay_ClearRegVehs"),
	Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_ClearRegVehs"), "Clear Registered Vehicles", eFeatureType.Button, "Clear all vehicles from record list.",
	function()
		RegisteredV2 = {}
		CurrentVehicleV2 = 0
		Print("Vehicle list to record cleared.")
	end)
}
local DrawPathLines = false
RecordFeatures[#RecordFeatures+1] = {
	Hash = Utils.Joaat("Replay_DrawPathLines"),
	Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_DrawPathLines"), "Draw Path Lines", eFeatureType.Toggle, "Clear all vehicles from record list.",
	function(f)
		DrawPathLines = f:IsToggled()
	end)
}

local PauseReplay = false
local PauseReplayFeature = nil
local ReplayData = {
	StartTimer = 0,
	LastGameTimer = MISC.GET_GAME_TIMER(),
	IsRewinding = false,
	UpdateMS = 0,
	ForceUpdate = false
}
local InterpolationFactor = 10.0
RecordFeatures[#RecordFeatures+1] = {
	Hash = Utils.Joaat("Replay_StartRecording"),
	Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_StartRecording"), "Start Recording", eFeatureType.Toggle, "Supports recording more than one vehicle at the same time alone.",
	function(f)
		RecordingV2 = f:IsToggled()
		Script.QueueJob(function()
			if RecordingV2 then
				local Records = {}
				CurrentVehicleV2 = 0
				local LastGameTimer = MISC.GET_GAME_TIMER()
				local IsRewinding2 = false
				local FocusedIndex = 1
				local FirstVeh = 0
				local FirstVehIndex = 1
				local function ApplyFrame(Veh, F)
					ENTITY.FREEZE_ENTITY_POSITION(Veh, false)
					TASK.CLEAR_VEHICLE_CRASH_TASK(Veh)
					VEHICLE.SET_DISABLE_AUTOMATIC_CRASH_TASK(Veh, false)
					VEHICLE.SET_DIP_STRAIGHT_DOWN_WHEN_CRASHING_PLANE(Veh, false)
					VEHICLE.SET_VEHICLE_ENGINE_ON(Veh, true, true, false)
					VEHICLE.SET_VEHICLE_KEEP_ENGINE_ON_WHEN_ABANDONED(Veh, true)
					ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Veh, F.Pos.x, F.Pos.y, F.Pos.z)
					ENTITY.SET_ENTITY_ROTATION(Veh, F.Rot.x, F.Rot.y, F.Rot.z, 5)
					VEHICLE.SET_VEHICLE_FORWARD_SPEED(Veh,
						math.sqrt(F.Vel.x ^ 2 + F.Vel.y ^ 2 + F.Vel.z ^ 2) * 1.5)
					ENTITY.SET_ENTITY_VELOCITY(Veh, F.Vel.x, F.Vel.y, F.Vel.z)
					ENTITY.SET_ENTITY_ANGULAR_VELOCITY(Veh, F.Ang.x, F.Ang.y, F.Ang.z)
				end
				local function ResetReplays(IgnoreIndex, LastFrame, Time)
					for k = 1, #RegisteredV2 do
						if IgnoreIndex ~= k then
							if Records[k] ~= nil and #Records[k].FramesData > 0 and #Records[k].FramesData[#Records[k].FramesData] > 0 then
								local Veh = RegisteredV2[k]
								local F = nil
								if LastFrame then
									F = Records[k].FramesData[#Records[k].FramesData][#Records[k].FramesData[#Records[k].FramesData]]
								else
									F = Records[k].FramesData[#Records[k].FramesData][1]
								end
								Records[k].ReplayTime = Time or F.Time
								ApplyFrame(Veh, F)
								Records[k].ReplayTP = true
							end
						end
					end
				end
				local function ApplyPositions(SetSpeed)
					for k = 1, #RegisteredV2 do
						if Records[k] ~= nil then
							local Veh = RegisteredV2[k]
							local Pos = ENTITY.GET_ENTITY_COORDS(Veh)
							local Rot = ENTITY.GET_ENTITY_ROTATION(Veh, 5)
							local Vel = ENTITY.GET_ENTITY_VELOCITY(Veh)
							local Ang = ENTITY.GET_ENTITY_ROTATION_VELOCITY(Veh)
							Records[k].LastData = {
								Pos = Pos,
								Rot = Rot,
								Vel = Vel,
								Ang = Ang
							}
							if SetSpeed then
								Records[k].SetSpeed = true
							end
						end
					end
				end
				if PauseReplay then
					if PauseReplayFeature then
						PauseReplayFeature:Toggle()
					end
				end
				local TimerOffset = ReplayData.StartTimer or 0
				while RecordingV2 do
					local now = MISC.GET_GAME_TIMER()
					local delta = now - LastGameTimer
					if delta < 0 then delta = 0 end
					LastGameTimer = now
					PAD.DISABLE_CONTROL_ACTION(0, 99, true) -- R
					IsRewinding2 = PAD.IS_DISABLED_CONTROL_PRESSED(0, 99)
					PAD.DISABLE_CONTROL_ACTION(0, 75, true) -- F
					local SwitchRequested = PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 75)
					PAD.DISABLE_CONTROL_ACTION(0, 51, true) -- E
					ReplayData.IsRewinding = IsRewinding2
					if CurrentVehicleV2 == 0 then
						CurrentVehicleV2 = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
						if CurrentVehicleV2 == 0 and #RegisteredV2 > 0 then
							CurrentVehicleV2 = RegisteredV2[1]
						else
							if #RegisteredV2 == 0 and CurrentVehicleV2 ~= 0 then
								RegisteredV2[#RegisteredV2+1] = CurrentVehicleV2
							end
						end
					else
						if not PED.IS_PED_IN_VEHICLE(PLAYER.PLAYER_PED_ID(), CurrentVehicleV2, true) then
							PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), CurrentVehicleV2, -1)
						end
					end
					if FirstVeh == 0 and CurrentVehicleV2 ~= 0 then
						FirstVeh = CurrentVehicleV2
						FocusedIndex = idx_of_handle(RegisteredV2, FirstVeh)
						FirstVehIndex = FocusedIndex
					end
					if CurrentVehicleV2 ~= 0 then
						CurrentVehicleV2 = RegisteredV2[FocusedIndex]
					end
					for k = 1, #RegisteredV2 do
						local Veh = RegisteredV2[k]
						local IsFirstVeh = Veh == FirstVeh
						local IsFocused = FocusedIndex == k
						if Records[k] == nil then
							Records[k] = {
								Veh = Veh,
								FramesData = {},
								Frames = {},
								Time = 0,
								ReplayTime = 0,
								LastIndex = 1,
								SetSpeed = false,
								GetData = false,
								LastData = nil,
								ReplayTP = false
							}
						end
						if IsFocused then
							if not IsRewinding2 then
								Records[k].Time = Records[k].Time + delta
								ENTITY.FREEZE_ENTITY_POSITION(Veh, false)
								if Records[k].SetSpeed then
									Records[k].SetSpeed = false
									if Records[k].LastData then
										ApplyFrame(Veh, Records[k].LastData)
									end
								end
								local Pos = ENTITY.GET_ENTITY_COORDS(Veh)
								local Rot = ENTITY.GET_ENTITY_ROTATION(Veh, 5)
								local Vel = ENTITY.GET_ENTITY_VELOCITY(Veh)
								local Ang = ENTITY.GET_ENTITY_ROTATION_VELOCITY(Veh)
								local Model = ENTITY.GET_ENTITY_MODEL(Veh)
								Records[k].Frames[#Records[k].Frames+1] = {
									Pos = Pos,
									Rot = Rot,
									Vel = Vel,
									Ang = Ang,
									Model = Model,
									Time = Records[k].Time
								}
								if not Records[k].GetData then
									Records[k].GetData = true
									Records[k].LastData = {
										Pos = Pos,
										Rot = Rot,
										Vel = Vel,
										Ang = Ang
									}
								end
								if #RegisteredV2 >= 2 then
									if IsFirstVeh then
										if SwitchRequested then
											local Frames = CopyTable(Records[k].Frames)
											Records[k].FramesData[#Records[k].FramesData+1] = Frames
											Records[k].Frames = {}
											FocusedIndex = FocusedIndex + 1
											if FocusedIndex > #RegisteredV2 then
												FocusedIndex = 1
											end
											SwitchRequested = false
											Records[k].SetSpeed = true
											ResetReplays(FocusedIndex, false)
											Records[k].LastData = {
												Pos = Pos,
												Rot = Rot,
												Vel = Vel,
												Ang = Ang
											}
										end
									else
										if Records[k].Time >= Records[FirstVehIndex].Time then
											local Frames = CopyTable(Records[k].Frames)
											Records[k].FramesData[#Records[k].FramesData+1] = Frames
											Records[k].Frames = {}
											FocusedIndex = FocusedIndex + 1
											if FocusedIndex > #RegisteredV2 then
												FocusedIndex = 1
											end
											--Records[k].GetData = false
											Records[k].SetSpeed = true
											ResetReplays(FocusedIndex, false)
											Records[k].LastData = {
												Pos = Pos,
												Rot = Rot,
												Vel = Vel,
												Ang = Ang
											}
										end
									end
								end
							else
								Records[k].SetSpeed = false
								if #Records[k].Frames > 0 then
									Records[k].Time = math.max(0, Records[k].Time - delta)
									-- remove frames que ficaram "à frente" do tempo atual
									local i = #Records[k].Frames
									while i > 0 and Records[k].Frames[i].Time > Records[k].Time do
										table.remove(Records[k].Frames, i)
										i = i - 1
									end
									if #Records[k].Frames > 0 then
										local F = Records[k].Frames[#Records[k].Frames]
										ApplyFrame(Veh, F)
									end
								else
									if #Records[k].FramesData > 0 then
										local F = Records[k].FramesData[#Records[k].FramesData][#Records[k].FramesData[#Records[k].FramesData]]
										ApplyFrame(Veh, F)
										ENTITY.FREEZE_ENTITY_POSITION(Veh, true)
									end
								end
								if #RegisteredV2 >= 2 then
									if #Records[k].Frames == 0 then
										if #Records[k].FramesData > 0 then
											Records[k].Frames = {}
											FocusedIndex = FocusedIndex - 1
											if FocusedIndex < 1 then
												FocusedIndex = #RegisteredV2
											end
											if #Records[FocusedIndex].FramesData > 0 then
												local Frames = table.remove(Records[FocusedIndex].FramesData, #Records[FocusedIndex].FramesData)
												local F = Frames
												Records[FocusedIndex].Frames = F
												ResetReplays(0, true, Records[FocusedIndex].Time)
												ApplyFrame(RegisteredV2[FocusedIndex], F[#F])
											else
												ResetReplays(0, true, Records[FocusedIndex].Time)
											end
											ApplyPositions(true)
										end
									end
								end
							end
							ReplayData.StartTimer = (Records[k].Time or 0) + TimerOffset
						else
							if #Records[k].FramesData > 0 then
								if not IsRewinding2 then
									Records[k].ReplayTime = math.max(0, Records[k].ReplayTime + delta)
								else
									Records[k].ReplayTime = math.max(0, Records[k].ReplayTime - delta)
								end
								if #Records[k].FramesData[#Records[k].FramesData] > 0 then
									Records[k].LastIndex = FindFrameIndex(Records[k].FramesData[#Records[k].FramesData], Records[k].LastIndex, Records[k].ReplayTime)
									local F = Records[k].FramesData[#Records[k].FramesData][Records[k].LastIndex]
									if not IsRewinding2 and not Records[k].ReplayTP then
										ENTITY.FREEZE_ENTITY_POSITION(Veh, false) -- modo normal (suave)
										SetEntitySpeedToCoord(Veh, F.Pos, 1.0, false, false, false, F.Vel.x, F.Vel.y, F.Vel
														.z, false, false, nil)
										RotateEntityToTargetRotation(Veh, F.Rot, InterpolationFactor)
									else
										Records[k].ReplayTP = false
										if Records[k].LastIndex >= #Records[k].FramesData[#Records[k].FramesData] then
											ENTITY.FREEZE_ENTITY_POSITION(Veh, true)
										else
											ApplyFrame(Veh, F)
										end
									end
									local Frames = Records[k].FramesData[#Records[k].FramesData]
									if DrawPathLines then
										for i = Records[k].LastIndex, #Frames-1 do
											local F1 = Frames[i]
											local F2 = Frames[i+1]
											GRAPHICS.DRAW_LINE(F1.Pos.x, F1.Pos.y, F1.Pos.z, F2.Pos.x, F2.Pos.y, F2.Pos.z, 255, 255, 255, 255)
										end
									end
								end
							end
						end
					end
					Script.Yield(0)
				end
				if Records[FocusedIndex] ~= nil then
					local Frames = CopyTable(Records[FocusedIndex].Frames)
					Records[FocusedIndex].FramesData[#Records[FocusedIndex].FramesData+1] = Frames
					Records[FocusedIndex].Frames = {}
				end
				local ID = 1
				for k = 1, #RegisteredV2 do
					if Records[k] ~= nil and #Records[k].FramesData > 0 then
						local Path = PathDirSaveds .. FileNameForSave .. "_" .. ID .. ".txt"
						local Out = {}
						for i = 1, #Records[k].FramesData do
							for j = 1, #Records[k].FramesData[i] do
								local F = Records[k].FramesData[i][j]
								Out[#Out + 1] = ToTxt(F.Pos, F.Rot, F.Vel, F.Ang, F.Time + TimerOffset, F.Model)
							end
						end
						if EmptyRecord then
							ClearFile(Path)
						end
						WriteFile(Path, table.concat(Out))
						Print(("💾 V3: Saved PathV3_%d (%d frames)"):format(ID, #Out))
						ID = ID + 1
					end
				end
			end
		end)
	end)
}

RecordFeatures[#RecordFeatures+1] = {
	Hash = Utils.Joaat("Replay_StartMultiplayerRecording"),
	Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_StartMultiplayerRecording"), "Start Multiplayer Recording", eFeatureType.Toggle, "Supports recording more than one vehicle at the same time with players or npcs in other registered vehicles.",
	function(f)
		RecordingV2 = f:IsToggled()
		Script.QueueJob(function()
			if RecordingV2 then
				local Records = {}
				CurrentVehicleV2 = 0
				local LastGameTimer = MISC.GET_GAME_TIMER()
				local IsRewinding = false
				local FocusedIndex = 1
				local FirstVeh = 0
				local FirstVehIndex = 1
				local function ApplyFrame(Veh, F)
					--ENTITY.FREEZE_ENTITY_POSITION(Veh, false)
					TASK.CLEAR_VEHICLE_CRASH_TASK(Veh)
					VEHICLE.SET_DISABLE_AUTOMATIC_CRASH_TASK(Veh, false)
					VEHICLE.SET_DIP_STRAIGHT_DOWN_WHEN_CRASHING_PLANE(Veh, false)
					VEHICLE.SET_VEHICLE_ENGINE_ON(Veh, true, true, false)
					VEHICLE.SET_VEHICLE_KEEP_ENGINE_ON_WHEN_ABANDONED(Veh, true)
					ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Veh, F.Pos.x, F.Pos.y, F.Pos.z)
					ENTITY.SET_ENTITY_ROTATION(Veh, F.Rot.x, F.Rot.y, F.Rot.z, 5)
					VEHICLE.SET_VEHICLE_FORWARD_SPEED(Veh,
						math.sqrt(F.Vel.x ^ 2 + F.Vel.y ^ 2 + F.Vel.z ^ 2) * 1.5)
					ENTITY.SET_ENTITY_VELOCITY(Veh, F.Vel.x, F.Vel.y, F.Vel.z)
					ENTITY.SET_ENTITY_ANGULAR_VELOCITY(Veh, F.Ang.x, F.Ang.y, F.Ang.z)
				end
				local function ResetReplays(IgnoreIndex, LastFrame, Time)
					for k = 1, #RegisteredV2 do
						if IgnoreIndex ~= k then
							if Records[k] ~= nil and #Records[k].FramesData > 0 and #Records[k].FramesData[#Records[k].FramesData] > 0 then
								local Veh = RegisteredV2[k]
								local F = nil
								if LastFrame then
									F = Records[k].FramesData[#Records[k].FramesData][#Records[k].FramesData[#Records[k].FramesData]]
								else
									F = Records[k].FramesData[#Records[k].FramesData][1]
								end
								Records[k].ReplayTime = Time or F.Time
								ApplyFrame(Veh, F)
								Records[k].ReplayTP = true
							end
						end
					end
				end
				local function ApplyPositions(SetSpeed)
					for k = 1, #RegisteredV2 do
						if Records[k] ~= nil then
							local Veh = RegisteredV2[k]
							local Pos = ENTITY.GET_ENTITY_COORDS(Veh)
							local Rot = ENTITY.GET_ENTITY_ROTATION(Veh, 5)
							local Vel = ENTITY.GET_ENTITY_VELOCITY(Veh)
							local Ang = ENTITY.GET_ENTITY_ROTATION_VELOCITY(Veh)
							Records[k].LastData = {
								Pos = Pos,
								Rot = Rot,
								Vel = Vel,
								Ang = Ang
							}
							if SetSpeed then
								Records[k].SetSpeed = true
							end
						end
					end
				end
				local function EnsureVehicleControls(CanMigrate)
					local Count = 1
					for k = 1, #RegisteredV2 do
						if k ~= FirstVehIndex then
							local Veh = RegisteredV2[k]
							if not CanMigrate then
								if RequestControlOfEntity(Veh) then
									entities.set_can_migrate(Veh, false)
									Count = Count + 1
								end
							else
								if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(Veh) then
									entities.set_can_migrate(Veh, true)
								else
									Count = Count + 1
								end
							end
						end
					end
					return Count == #RegisteredV2
				end
				if PauseReplay then
					if PauseReplayFeature then
						PauseReplayFeature:Toggle()
					end
				end
				local TimerOffset = ReplayData.StartTimer or 0
				local RewindRequested = false
				local DoRewind = false
				local BusyState = false
				local Ensured = false
				local EnsuredMS = 0
				while RecordingV2 do
					local now = MISC.GET_GAME_TIMER()
					local delta = now - LastGameTimer
					if delta < 0 then delta = 0 end
					LastGameTimer = now
					PAD.DISABLE_CONTROL_ACTION(0, 99, true) -- R
					RewindRequested = PAD.IS_DISABLED_CONTROL_PRESSED(0, 99)
					if RewindRequested then
						BusyState = true
						Ensured = false
						if EnsureVehicleControls(false) then
							if now > EnsuredMS then
								BusyState = false
								DoRewind = true
							end
						else
							EnsuredMS = now + 100
						end
					else
						DoRewind = false
						if not Ensured then
							if EnsureVehicleControls(true) then
								BusyState = false
								Ensured = true
							end
						end
					end
					PAD.DISABLE_CONTROL_ACTION(0, 75, true) -- F
					local SwitchRequested = false
					PAD.DISABLE_CONTROL_ACTION(0, 51, true) -- E
					ReplayData.IsRewinding = DoRewind
					if CurrentVehicleV2 == 0 then
						CurrentVehicleV2 = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
						if CurrentVehicleV2 == 0 and #RegisteredV2 > 0 then
							CurrentVehicleV2 = RegisteredV2[1]
						else
							if #RegisteredV2 == 0 and CurrentVehicleV2 ~= 0 then
								RegisteredV2[#RegisteredV2+1] = CurrentVehicleV2
							end
						end
					else
						if not PED.IS_PED_IN_VEHICLE(PLAYER.PLAYER_PED_ID(), CurrentVehicleV2, true) then
							PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), CurrentVehicleV2, -1)
						end
					end
					if FirstVeh == 0 and CurrentVehicleV2 ~= 0 then
						FirstVeh = CurrentVehicleV2
						FocusedIndex = idx_of_handle(RegisteredV2, FirstVeh)
						FirstVehIndex = FocusedIndex
					end
					if CurrentVehicleV2 ~= 0 then
						CurrentVehicleV2 = RegisteredV2[FocusedIndex]
					end
					for k = 1, #RegisteredV2 do
						local Veh = RegisteredV2[k]
						local IsFirstVeh = Veh == FirstVeh
						local IsFocused = true
						if Records[k] == nil then
							Records[k] = {
								Veh = Veh,
								FramesData = {},
								Frames = {},
								Time = 0,
								ReplayTime = 0,
								LastIndex = 1,
								SetSpeed = false,
								GetData = false,
								LastData = nil,
								ReplayTP = false
							}
						end
						if IsFocused then
							if not DoRewind then
								ENTITY.FREEZE_ENTITY_POSITION(Veh, false)
								if Records[k].SetSpeed then
									Records[k].SetSpeed = false
									if Records[k].LastData then
										ApplyFrame(Veh, Records[k].LastData)
									end
								end
								local Pos = ENTITY.GET_ENTITY_COORDS(Veh)
								local Rot = ENTITY.GET_ENTITY_ROTATION(Veh, 5)
								local Vel = ENTITY.GET_ENTITY_VELOCITY(Veh)
								local Ang = ENTITY.GET_ENTITY_ROTATION_VELOCITY(Veh)
								local Model = ENTITY.GET_ENTITY_MODEL(Veh)
								if not BusyState then
									Records[k].Time = Records[k].Time + delta
									Records[k].Frames[#Records[k].Frames+1] = {
										Pos = Pos,
										Rot = Rot,
										Vel = Vel,
										Ang = Ang,
										Model = Model,
										Time = Records[k].Time
									}
								else
									--ENTITY.FREEZE_ENTITY_POSITION(Veh, true)
									ApplyFrame(Veh, Records[k].Frames[#Records[k].Frames])
									--Pos = ENTITY.GET_ENTITY_COORDS(Veh)
									--Rot = ENTITY.GET_ENTITY_ROTATION(Veh, 5)
									--Vel = ENTITY.GET_ENTITY_VELOCITY(Veh)
									--Ang = ENTITY.GET_ENTITY_ROTATION_VELOCITY(Veh)
									--Records[k].LastData = {
									--	Pos = Pos,
									--	Rot = Rot,
									--	Vel = Vel,
									--	Ang = Ang
									--}
									--Records[k].SetSpeed = true
									local F = Records[k].Frames[#Records[k].Frames]
									Records[k].LastData = {
										Pos = F.Pos,
										Rot = F.Rot,
										Vel = F.Vel,
										Ang = F.Ang
									}
								end
								if not Records[k].GetData then
									Records[k].GetData = true
									Records[k].LastData = {
										Pos = Pos,
										Rot = Rot,
										Vel = Vel,
										Ang = Ang
									}
								end
							else
								if not BusyState then
									--Records[k].SetSpeed = true
									if #Records[k].Frames > 0 then
										Records[k].Time = math.max(0, Records[k].Time - delta)
										-- remove frames que ficaram "à frente" do tempo atual
										local i = #Records[k].Frames
										while i > 0 and Records[k].Frames[i].Time > Records[k].Time do
											table.remove(Records[k].Frames, i)
											i = i - 1
										end
										if #Records[k].Frames > 0 then
											local F = Records[k].Frames[#Records[k].Frames]
											ApplyFrame(Veh, F)
											--local Pos = ENTITY.GET_ENTITY_COORDS(Veh)
											--local Rot = ENTITY.GET_ENTITY_ROTATION(Veh, 5)
											--local Vel = ENTITY.GET_ENTITY_VELOCITY(Veh)
											--local Ang = ENTITY.GET_ENTITY_ROTATION_VELOCITY(Veh)
											Records[k].LastData = {
												Pos = F.Pos,
												Rot = F.Rot,
												Vel = F.Vel,
												Ang = F.Ang
											}
											Records[k].SetSpeed = true
										end
									else
										if #Records[k].FramesData > 0 then
											local F = Records[k].FramesData[#Records[k].FramesData][#Records[k].FramesData[#Records[k].FramesData]]
											ApplyFrame(Veh, F)
											ENTITY.FREEZE_ENTITY_POSITION(Veh, true)
										end
									end
								end
							end
							ReplayData.StartTimer = (Records[k].Time or 0) + TimerOffset
						end
					end
					Script.Yield(0)
				end
				for k = 1, #RegisteredV2 do
					if Records[k] ~= nil then
						local Frames = CopyTable(Records[k].Frames)
						Records[k].FramesData[#Records[k].FramesData+1] = Frames
						Records[k].Frames = {}
					end
				end
				local ID = 1
				for k = 1, #RegisteredV2 do
					if Records[k] ~= nil and #Records[k].FramesData > 0 then
						local Path = PathDirSaveds .. FileNameForSave .. "_" .. ID .. ".txt"
						local Out = {}
						for i = 1, #Records[k].FramesData do
							for j = 1, #Records[k].FramesData[i] do
								local F = Records[k].FramesData[i][j]
								Out[#Out + 1] = ToTxt(F.Pos, F.Rot, F.Vel, F.Ang, F.Time + TimerOffset, F.Model)
							end
						end
						if EmptyRecord then
							ClearFile(Path)
						end
						WriteFile(Path, table.concat(Out))
						Print(("💾 V3: Saved PathV3_%d (%d frames)"):format(ID, #Out))
						ID = ID + 1
					end
				end
			end
		end)
	end)
}

local Model = "shinobi"
ReplayFeatures[#ReplayFeatures+1] = {Hash = Utils.Joaat("Replay_SetVehModel"), Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_SetVehModel"), "Set Veh Model", eFeatureType.InputText, "",
	function(f)
		if STREAMING.IS_MODEL_VALID(Utils.Joaat(f:GetStringValue())) and STREAMING.IS_MODEL_A_VEHICLE(Utils.Joaat(f:GetStringValue())) then
			Model = f:GetStringValue()
		end
	end)
}

local UseStoredVehicleModel = true
ReplayFeatures[#ReplayFeatures+1] = {
	Hash = Utils.Joaat("Replay_UseStoredVehModel"),
	Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_UseStoredVehModel"), "Use Stored Vehicle Model", eFeatureType.Toggle, "Use vehicle model hash if is stored in the replay file",
	function(f)
		UseStoredVehicleModel = f:IsToggled()
	end):Toggle()
}

local PedModel = "mp_m_bogdangoon"
ReplayFeatures[#ReplayFeatures+1] = {Hash = Utils.Joaat("Replay_SetPedModel"),
	Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_SetPedModel"), "Set Ped Model", eFeatureType.InputText,
	"Ped model will be created inside vehicle.",
	function(f)
		if STREAMING.IS_MODEL_VALID(Utils.Joaat(f:GetStringValue())) and STREAMING.IS_MODEL_A_PED(f:GetStringValue()) then
			PedModel = f:GetStringValue()
		end
	end)
}

local CreatePedToReplay = true
ReplayFeatures[#ReplayFeatures+1] = {Hash = Utils.Joaat("Replay_CreatePedToVehs"),
 	Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_CreatePedToVehs"), "Create Ped To Replay Vehicles", eFeatureType.Toggle,
	"Ped model will be created inside vehicle.",
	function(f)
		CreatePedToReplay = f:IsToggled()
	end):Toggle()
}

local ReplayTeleportMode = false
ReplayFeatures[#ReplayFeatures+1] = {Hash = Utils.Joaat("Replay_TeleportMode"),
	Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_TeleportMode"), "Replay Teleport Mode", eFeatureType.Toggle,
	"Use teleportation instead of velocity physics.",
	function(f)
		ReplayTeleportMode = f:IsToggled()
	end)
}

local StartTimerVar = 0
ReplayFeatures[#ReplayFeatures+1] = {Hash = Utils.Joaat("Replay_PlaybackTime"),
	Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_PlaybackTime"), "Playback Current Time", eFeatureType.SliderInt,
	"Set the time of the current replays.",
	function(f)
		if RecordingV2 then return end
		ReplayData.StartTimer = f:GetIntValue()
		ReplayData.UpdateMS = MISC.GET_GAME_TIMER() + 100
		ReplayData.ForceUpdate = true
		StartTimerVar = f:GetIntValue()
	end)
}

local ReplayPlaybackTimeFeature = ReplayFeatures[#ReplayFeatures].Feature
ReplayFeatures[#ReplayFeatures+1] = {Hash = Utils.Joaat("Replay_Pause"),
	Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_Pause"), "Pause Replay Playback", eFeatureType.Toggle,
	"Set the time of the current replays.",
	function(f)
		PauseReplay = f:IsToggled()
		if RecordingV2 then return end
		Script.QueueJob(function()
			if PauseReplay then
				StartTimerVar = ReplayData.StartTimer or 0
				while PauseReplay do
					ReplayData.StartTimer = StartTimerVar
					ReplayData.ForceUpdate = true
					Script.Yield(0)
				end
			end
		end)
	end)
}
PauseReplayFeature = ReplayFeatures[#ReplayFeatures].Feature

local ReplayVehsT = {}
local StartReplay = false
local ReplayID = 0

function GetBiggestReplayTime()
	local BiggestReplayTime = 0
	for k = 1, #ReplayVehsT do
		if #ReplayVehsT[k].Paths > 0 then
			if ReplayVehsT[k].Paths[#ReplayVehsT[k].Paths].CurGameTime > BiggestReplayTime then
				BiggestReplayTime = ReplayVehsT[k].Paths[#ReplayVehsT[k].Paths].CurGameTime
			end
		end
	end
	return BiggestReplayTime
end

local ReplayPlayback = {
	[0] = function(T)
		for k, value in pairs(ReplaysToLoad) do
			T[#T + 1] = {
				VehHandle = 0,
				ModelHash = 0,
				Paths = GetVectorsTable(k, true, false),
				Index = 0,
				Blip = 0,
				StartTimer = 0,
				PedHandle = 0,
				PedBlip = 0,
				HasSetStartTimer = false,
				TaskMS = 0,
				IsCargoPlane = false
			}
		end
		ReplayPlaybackTimeFeature:SetMaxValue(GetBiggestReplayTime())
		ReplayID = 1
		return false
	end,
	[1] = function(T)
		for k = 1, #T do
			if T[k].Paths ~= nil and T[k].Paths[1] ~= nil then
				if not UseStoredVehicleModel then
					T[k].Paths[1].ModelHash = Utils.Joaat(Model)
				end
				T[k].ModelHash = T[k].Paths[1].ModelHash or Utils.Joaat(Model)
				if T[k].VehHandle == 0 then
					if not STREAMING.IS_MODEL_VALID(T[k].ModelHash) then
						T[k].ModelHash = Utils.Joaat(Model)
					end
					T[k].IsCargoPlane = T[k].ModelHash == Utils.Joaat("cargoplane") or
						T[k].ModelHash == Utils.Joaat("cargoplane2")
					RequestModel(T[k].ModelHash)
					T[k].VehHandle = GTA.SpawnVehicle(T[k].ModelHash, T[k].Paths[1].x,
						T[k].Paths[1].y, T[k].Paths[1].z, T[k].Paths[1].RotZ, true, false)
					if T[k].VehHandle ~= 0 then
						STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(T[k].ModelHash)
						ENTITY.SET_ENTITY_AS_MISSION_ENTITY(T[k].VehHandle, false, true)
						entities.set_can_migrate(T[k].VehHandle, false)
						ENTITY.SET_ENTITY_INVINCIBLE(T[k].VehHandle, true)
						NETWORK.NETWORK_SET_ENTITY_CAN_BLEND(T[k].VehHandle, true)
						T[k].Blip = HUD.ADD_BLIP_FOR_ENTITY(T[k].VehHandle)
						HUD.SET_BLIP_COLOUR(T[k].Blip, 3)
						UpgradeVehicle(T[k].VehHandle, true, true, true)
						if CreatePedToReplay then
							if VEHICLE.IS_VEHICLE_DRIVEABLE(T[k].VehHandle, false) then
								RequestModel(Utils.Joaat(PedModel))
								T[k].PedHandle = GTA.CreatePed(Utils.Joaat(PedModel), 28, T[k].Paths[1].x,
									T[k].Paths[1].y, T[k].Paths[1].z, T[k].Paths[1].RotZ,
									true, false)
								if T[k].PedHandle ~= 0 then
									PED.SET_PED_INTO_VEHICLE(T[k].PedHandle, T[k].VehHandle, -1)
									STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(Utils.Joaat(PedModel))
									ENTITY.SET_ENTITY_AS_MISSION_ENTITY(T[k].PedHandle, false, true)
									entities.set_can_migrate(T[k].PedHandle, false)
									ENTITY.SET_ENTITY_INVINCIBLE(T[k].PedHandle, true)
									NETWORK.NETWORK_SET_ENTITY_CAN_BLEND(T[k].PedHandle, true)
									T[k].PedBlip = HUD.ADD_BLIP_FOR_ENTITY(T[k].PedHandle)
									HUD.SET_BLIP_COLOUR(T[k].PedBlip, 1)
									HUD.SHOW_HEADING_INDICATOR_ON_BLIP(T[k].PedBlip, true)
									PED.SET_PED_COMBAT_ATTRIBUTES(T[k].PedHandle, 3, false)
									PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(T[k].PedHandle, 1)
									PED.SET_PED_RELATIONSHIP_GROUP_HASH(T[k].PedHandle, Utils.Joaat(AiLikeRel))
								else
									STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(Utils.Joaat(PedModel))
								end
							end
						end
						ENTITY.FREEZE_ENTITY_POSITION(T[k].VehHandle, true)
						ENTITY.SET_ENTITY_COORDS(T[k].VehHandle, T[k].Paths[1].x,
							T[k].Paths[1].y, T[k].Paths[1].z)
						ENTITY.SET_ENTITY_ROTATION(T[k].VehHandle, T[k].Paths[1].RotX,
							T[k].Paths[1].RotY, T[k].Paths[1].RotZ, 5)
					else
						STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(T[k].ModelHash)
					end
				end
			end
		end
		ReplayData = {
			StartTimer = 0,
			LastGameTimer = MISC.GET_GAME_TIMER(),
			IsRewinding = false,
			UpdateMS = 0,
			ForceUpdate = false
		}
		ReplayID = 2
		return false
	end,
	[2] = function(T, Run, CanClearTable)
		local GameTimer = MISC.GET_GAME_TIMER()
		local DeltaTime = GameTimer - ReplayData.LastGameTimer
		if DeltaTime < 0 then DeltaTime = 0 end
		ReplayData.LastGameTimer = GameTimer
		ReplayData.StartTimer = ReplayData.StartTimer + DeltaTime
		if GameTimer > ReplayData.UpdateMS then
			ReplayPlaybackTimeFeature:SetValue(ReplayData.StartTimer)
		end
		for k = #T, 1, -1 do
			local Veh = T[k].VehHandle
			if Veh ~= 0 and ENTITY.DOES_ENTITY_EXIST(Veh) then
				if not ENTITY.IS_ENTITY_DEAD(Veh) then
					ENTITY.FREEZE_ENTITY_POSITION(T[k].VehHandle, false)
					if T[k].Index == 0 then
						T[k].Index = 1
						local PathsData = T[k].Paths[1]
						ENTITY.SET_ENTITY_COORDS(Veh, PathsData.x, PathsData.y, PathsData.z)
						ENTITY.SET_ENTITY_ROTATION(Veh, PathsData.RotX, PathsData.RotY, PathsData.RotZ, 5)
						if not T[k].HasSetStartTimer then
							T[k].HasSetStartTimer = true
							T[k].StartTimer = ReplayData.StartTimer
						else
							T[k].StartTimer = 0
						end
					end
					if T[k].Index > 0 and T[k].Index < #T[k].Paths then
						UpdateReplayIndexByTime2(T[k], ReplayData.StartTimer)
						local Coord = {
							x = T[k].Paths[T[k].Index].x,
							y = T[k].Paths[T[k].Index].y,
							z = T[k].Paths[T[k].Index].z
						}
						local Rot = {
							x = T[k].Paths[T[k].Index].RotX,
							y = T[k].Paths[T[k].Index].RotY,
							z = T[k].Paths[T[k].Index].RotZ
						}
						local Vel = {
							x = T[k].Paths[T[k].Index].VelX,
							y = T[k].Paths[T[k].Index].VelY,
							z = T[k].Paths[T[k].Index].VelZ
						}
						local AngVel = {
							x = T[k].Paths[T[k].Index].AngVelX,
							y = T[k].Paths[T[k].Index].AngVelY,
							z = T[k].Paths[T[k].Index].AngVelZ
						}
						if T[k].IsCargoPlane then
							VEHICLE.SET_DOOR_ALLOWED_TO_BE_BROKEN_OFF(Veh, 2, false)
							VEHICLE.SET_VEHICLE_DOOR_CONTROL(Veh, 2, 180.0, 180.0)
							if not VEHICLE.IS_VEHICLE_DOOR_DAMAGED(Veh, 4) then
								VEHICLE.SET_VEHICLE_DOOR_BROKEN(Veh, 4, false)
							end
						end
						if T[k].PedHandle ~= 0 and ENTITY.DOES_ENTITY_EXIST(T[k].PedHandle) then
							if GameTimer > T[k].TaskMS then
								T[k].TaskMS = GameTimer + 1000
								TASK.TASK_VEHICLE_TEMP_ACTION(T[k].PedHandle, Veh, 32, 2000)
							end
						end
						local CurCoord = ENTITY.GET_ENTITY_COORDS(Veh)
						if not ReplayTeleportMode and DistanceBetween(CurCoord.x, CurCoord.y, CurCoord.z, Coord.x, Coord.y, Coord.z) < 50.0 and not ReplayData.IsRewinding and not ReplayData.ForceUpdate then
							SetEntitySpeedToCoord(Veh, Coord, 1.0,
								false, false, false, Vel.x, Vel.y, Vel.z, false, false, nil)
							RotateEntityToTargetRotation(Veh, Rot, InterpolationFactor)
						else
							ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Veh, Coord.x, Coord.y, Coord.z)
							ENTITY.SET_ENTITY_ROTATION(Veh, Rot.x, Rot.y, Rot.z, 5)
							if not PauseReplay or RecordingV2 then
								VEHICLE.SET_VEHICLE_FORWARD_SPEED(Veh,
									math.sqrt(Vel.x ^ 2 + Vel.y ^ 2 + Vel.z ^ 2))
								ENTITY.SET_ENTITY_VELOCITY(Veh, Vel.x, Vel.y, Vel.z)
								ENTITY.SET_ENTITY_ANGULAR_VELOCITY(Veh, AngVel.x, AngVel.y, AngVel.z)
							else
								if PauseReplay then
									ENTITY.FREEZE_ENTITY_POSITION(T[k].VehHandle, true)
								end
							end
						end
					else
						T[k].Index = 0
					end
				end
			else
				if CanClearTable then
					table.remove(T, k)
				end
			end
		end
		ReplayData.ForceUpdate = false
		if not Run then
			for k = 1, #T do
				if T[k].VehHandle ~= 0 and ENTITY.DOES_ENTITY_EXIST(T[k].VehHandle) then
					if T[k].Blip ~= 0 then
						util.remove_blip(T[k].Blip)
					end
					entities.delete_by_handle(T[k].VehHandle)
				end
				if T[k].PedHandle ~= 0 and ENTITY.DOES_ENTITY_EXIST(T[k].PedHandle) then
					if T[k].PedBlip ~= 0 then
						util.remove_blip(T[k].PedBlip)
					end
					entities.delete_by_handle(T[k].PedHandle)
				end
			end
			T = {}
			ReplayID = 0
			ReplayData.StartTimer = 0
			return true
		end
		return false
	end
}

function StartReplaysPlayback(Run)
	return ReplayPlayback[ReplayID](ReplayVehsT, Run, true)
end

ReplayFeatures[#ReplayFeatures+1] = {Hash = Utils.Joaat("Replay_InterpolationFactor"),
	Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_InterpolationFactor"), "Interpolation Factor", eFeatureType.InputFloat,
	"",
	function(f)
		InterpolationFactor = f:GetFloatValue()
	end):SetMaxValue(10.0):SetMinValue(1.0):SetValue(InterpolationFactor)
}

ReplayFeatures[#ReplayFeatures+1] = {Hash = Utils.Joaat("Replay_StartSelectedReplays"),
	Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_StartSelectedReplays"), "Start Selected Replays", eFeatureType.Toggle,
	"",
	function(f)
		StartReplay = f:IsToggled()
		if StartReplay then
			Script.QueueJob(function()
				while StartReplay do
					StartReplaysPlayback(true)
					Script.Yield(0)
				end
			end)
		else
			StartReplaysPlayback(false)
		end
	end)
}

function UpdateReplayIndexByTime(vehicleReplay, CurTime)
	local Paths = vehicleReplay.Paths
	local StartFrameTime = Paths[1].CurGameTime

	while vehicleReplay.Index < (#Paths - 1) and
		CurTime > (Paths[vehicleReplay.Index + 1].CurGameTime - StartFrameTime) do
		vehicleReplay.Index = vehicleReplay.Index + 1
	end

	while vehicleReplay.Index > 1 and
		CurTime < (Paths[vehicleReplay.Index].CurGameTime - StartFrameTime) do
		vehicleReplay.Index = vehicleReplay.Index - 1
	end
end

function UpdateReplayIndexByTime2(vehicleReplay, CurTime)
	local Paths = vehicleReplay.Paths

	while vehicleReplay.Index < (#Paths - 1) and
		CurTime > (Paths[vehicleReplay.Index + 1].CurGameTime) do
		vehicleReplay.Index = vehicleReplay.Index + 1
	end

	while vehicleReplay.Index > 1 and
		CurTime < (Paths[vehicleReplay.Index].CurGameTime) do
		vehicleReplay.Index = vehicleReplay.Index - 1
	end
end

function WriteFile(FileName, Contents)
	local File = io.open(FileName, "a")
	if File then
		File:write(Contents)
		io.close(File)
	end
end

function file_exists(file)
	local f = io.open(file, "rb")
	if f then f:close() end
	return f ~= nil
end

function file_lines(file)
	if not file_exists(file) then return {} end
	local lines = {}
	for line in io.lines(file) do
		lines[#lines + 1] = line
	end
	return lines
end

function split_number(str)
	local t = {}
	for n in str:gmatch("%S+") do
		table.insert(t, tonumber(n))
	end
	return t
end

function ToTxt(Pos, Rot, Vel, AngVel, CurGameTimer, VehModel, Steering)
	return string.format("%0.3f", Pos.x) .. " " .. string.format("%0.3f", Pos.y) .. " " ..
		string.format("%0.3f", Pos.z) ..
		" " .. string.format("%0.3f", Rot.x) .. " " ..
		string.format("%0.3f", Rot.y) .. " " .. string.format("%0.3f", Rot.z) ..
		" " .. string.format("%0.3f", Vel.x) .. " " ..
		string.format("%0.3f", Vel.y) .. " " .. string.format("%0.3f", Vel.z) ..
		" " ..
		string.format("%0.3f", AngVel.x) ..
		" " .. string.format("%0.3f", AngVel.y) .. " " .. string.format("%0.3f", AngVel.z) ..
		" " .. CurGameTimer .. " " .. (VehModel or 0) .. " " .. (Steering or 0.0) .. "\n"
end

function RequestModel(ModelHash)
	if not STREAMING.HAS_MODEL_LOADED(ModelHash) then
		STREAMING.REQUEST_MODEL(ModelHash)
		while not STREAMING.HAS_MODEL_LOADED(ModelHash) do
			Script.Yield(0)
		end
	end
end

function RequestModelFunc(ModelHash)
	STREAMING.REQUEST_MODEL(ModelHash)
	return STREAMING.HAS_MODEL_LOADED(ModelHash)
end

function RequestControlOfEntity(Entity)
	if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(Entity) then
		return true
	else
		return NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(Entity)
	end
end

-- Função para converter ângulos de Euler para matriz de rotação (ordem XYZ)
function EulerToRotationMatrix(pitch, yaw, roll)
	local cx = math.cos(pitch)
	local sx = math.sin(pitch)
	local cy = math.cos(yaw)
	local sy = math.sin(yaw)
	local cz = math.cos(roll)
	local sz = math.sin(roll)

	return {
		{ cy * cz,                 -cy * sz,                sy },
		{ sx * sy * cz + cx * sz,  -sx * sy * sz + cx * cz, -sx * cy },
		{ -cx * sy * cz + sx * sz, cx * sy * sz + sx * cz,  cx * cy }
	}
end

-- Função para multiplicar duas matrizes 3x3
function MatrixMultiply(m1, m2)
	local result = {}
	for i = 1, 3 do
		result[i] = {}
		for j = 1, 3 do
			result[i][j] = m1[i][1] * m2[1][j] + m1[i][2] * m2[2][j] + m1[i][3] * m2[3][j]
		end
	end
	return result
end

-- Função para calcular a matriz de rotação inversa
function MatrixInverse(m)
	local determinant = m[1][1] * (m[2][2] * m[3][3] - m[2][3] * m[3][2]) -
		m[1][2] * (m[2][1] * m[3][3] - m[2][3] * m[3][1]) +
		m[1][3] * (m[2][1] * m[3][2] - m[2][2] * m[3][1])
	local invDet = 1 / determinant

	return {
		{
			invDet * (m[2][2] * m[3][3] - m[2][3] * m[3][2]),
			invDet * (m[1][3] * m[3][2] - m[1][2] * m[3][3]),
			invDet * (m[1][2] * m[2][3] - m[1][3] * m[2][2])
		},
		{
			invDet * (m[2][3] * m[3][1] - m[2][1] * m[3][3]),
			invDet * (m[1][1] * m[3][3] - m[1][3] * m[3][1]),
			invDet * (m[1][3] * m[2][1] - m[1][1] * m[2][3])
		},
		{
			invDet * (m[2][1] * m[3][2] - m[2][2] * m[3][1]),
			invDet * (m[1][2] * m[3][1] - m[1][1] * m[3][2]),
			invDet * (m[1][1] * m[2][2] - m[1][2] * m[2][1])
		}
	}
end

-- Função para obter a matriz de rotação da entidade
function GetEntityRotationMatrix(entity)
	local rot = ENTITY.GET_ENTITY_ROTATION(entity, 5)
	return EulerToRotationMatrix(math.rad(rot.x), math.rad(rot.y), math.rad(rot.z))
end

-- Função para converter uma matriz de rotação para quaternion
function RotationMatrixToQuaternion(m)
	local w = math.sqrt(1 + m[1][1] + m[2][2] + m[3][3]) / 2
	local x = (m[3][2] - m[2][3]) / (4 * w)
	local y = (m[1][3] - m[3][1]) / (4 * w)
	local z = (m[2][1] - m[1][2]) / (4 * w)
	return { w = w, x = x, y = y, z = z }
end

-- Função para calcular a velocidade angular a partir da diferença de quaternions
function QuaternionToAngularVelocity(q)
	local theta = 2 * math.acos(q.w)
	local sinTheta = math.sqrt(1 - q.w * q.w)
	if sinTheta < 0.001 then
		return { x = q.x * theta, y = q.y * theta, z = q.z * theta }
	else
		return { x = q.x / sinTheta * theta, y = q.y / sinTheta * theta, z = q.z / sinTheta * theta }
	end
end

-- Função principal para girar a entidade até a rotação desejada usando matrizes de rotação
function RotateEntityToTargetRotation(entity, targetRotation, interpolationFactor)
	interpolationFactor = interpolationFactor or 0.1 -- Fator de interpolação para suavizar a rotação

	-- Obtenha a matriz de rotação atual da entidade
	local currentRotationMatrix = GetEntityRotationMatrix(entity)

	-- Calcule a matriz de rotação alvo a partir dos ângulos de Euler desejados
	local targetRotationMatrix = EulerToRotationMatrix(math.rad(targetRotation.x), math.rad(targetRotation.y),
		math.rad(targetRotation.z))

	-- Calcule a matriz de rotação delta
	local deltaRotationMatrix = MatrixMultiply(targetRotationMatrix, MatrixInverse(currentRotationMatrix))

	-- Converta a matriz de rotação delta para quaternion
	local deltaQuaternion = RotationMatrixToQuaternion(deltaRotationMatrix)

	-- Converta a diferença de quaternion em velocidade angular
	local angularVelocity = QuaternionToAngularVelocity(deltaQuaternion)

	-- Interpole a velocidade angular para suavizar a rotação
	angularVelocity.x = angularVelocity.x * interpolationFactor
	angularVelocity.y = angularVelocity.y * interpolationFactor
	angularVelocity.z = angularVelocity.z * interpolationFactor

	-- Aplique a velocidade angular à entidade
	ENTITY.SET_ENTITY_ANGULAR_VELOCITY(entity, angularVelocity.x, angularVelocity.y, angularVelocity.z)
end

function is_bit_set(value, bit)
	bit = bit - 1
	return (value & (1 << bit)) ~= 0
end

function clear_bit(value, bit)
	bit = bit - 1;
	return value & ~(1 << bit)
end

function set_bit(value, bit)
	bit = bit - 1;
	return value | 1 << bit
end

function angleDifference(target, current)
	local diff = target - current
	if diff > 180 then
		diff = diff - 360
	elseif diff < -180 then
		diff = diff + 360
	end
	return diff
end

-- Função para converter graus para radianos
local function deg2rad(deg)
	return deg * math.pi / 180.0
end

-- Função para converter radianos para graus
local function rad2deg(rad)
	return rad * 180.0 / math.pi
end

-- Função para limitar o ângulo no intervalo de -180 a 180 graus
local function wrap180(deg)
	while deg <= -180.0 do deg = deg + 360.0 end
	while deg > 180.0 do deg = deg - 360.0 end
	return deg
end

-- Função para converter rotação XYZ para ZYX
function convertRotationXYZtoZYX(rotX, rotY, rotZ)
	-- Converter para radianos
	local x = deg2rad(rotX)
	local y = deg2rad(rotY)
	local z = deg2rad(rotZ)

	-- Matriz de rotação para XYZ
	local cosX = math.cos(x)
	local sinX = math.sin(x)
	local cosY = math.cos(y)
	local sinY = math.sin(y)
	local cosZ = math.cos(z)
	local sinZ = math.sin(z)

	local Rxyz = {
		{ cosY * cosZ,                       -cosY * sinZ,                      sinY },
		{ sinX * sinY * cosZ + cosX * sinZ,  -sinX * sinY * sinZ + cosX * cosZ, -sinX * cosY },
		{ -cosX * sinY * cosZ + sinX * sinZ, cosX * sinY * sinZ + sinX * cosZ,  cosX * cosY }
	}

	-- Extrair ângulos ZYX da matriz de rotação
	local rotZ2 = math.atan2(Rxyz[2][1], Rxyz[1][1])
	local rotY2 = math.asin(-Rxyz[3][1])
	local rotX2 = math.atan2(Rxyz[3][2], Rxyz[3][3])

	-- Converter de volta para graus
	rotX2 = rad2deg(rotX2)
	rotY2 = rad2deg(rotY2)
	rotZ2 = rad2deg(rotZ2)

	-- Ajustar ângulos para o intervalo de -180 a 180 graus
	rotX2 = wrap180(rotX2)
	rotY2 = wrap180(rotY2)
	rotZ2 = wrap180(rotZ2)

	return { x = rotX2, y = -rotY2, z = rotZ2 }
end

-- Função para adicionar duas rotações e retornar a rotação normalizada
function addRotation(rot1, rot2)
	local result = rot1 + rot2
	return wrap180(result)
end

-- Função para subtrair duas rotações e retornar a rotação normalizada
function subtractRotation(rot1, rot2)
	local result = rot1 - rot2
	return wrap180(result)
end

function DistanceBetween(x1, y1, z1, x2, y2, z2)
	local dx = x1 - x2
	local dy = y1 - y2
	local dz = z1 - z2
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function CalculateOffsetZYX(basePos, rotation, forwardOffset, sideOffset, verticalOffset)
	-- Converte ângulos de graus para radianos
	local radZ = math.rad(rotation.z)
	local radY = math.rad(rotation.y)
	local radX = math.rad(rotation.x)

	-- Calcula os vetores de direção usando ZYX
	local cosZ, sinZ = math.cos(radZ), math.sin(radZ)
	local cosY, sinY = math.cos(radY), math.sin(radY)
	local cosX, sinX = math.cos(radX), math.sin(radX)

	-- Forward vector (Z depois Y depois X)
	local forward = {
		x = cosY * cosZ,
		y = cosY * sinZ,
		z = -sinY
	}

	-- Right vector
	local right = {
		x = cosZ * sinY * sinX - sinZ * cosX,
		y = sinZ * sinY * sinX + cosZ * cosX,
		z = cosY * sinX
	}

	-- Up vector
	local up = {
		x = cosZ * sinY * cosX + sinZ * sinX,
		y = sinZ * sinY * cosX - cosZ * sinX,
		z = cosY * cosX
	}

	-- Calcula a posição final com offset
	local finalPos = {
		x = basePos.x + forward.x * forwardOffset + right.x * sideOffset + up.x * verticalOffset,
		y = basePos.y + forward.y * forwardOffset + right.y * sideOffset + up.y * verticalOffset,
		z = basePos.z + forward.z * forwardOffset + right.z * sideOffset + up.z * verticalOffset
	}

	return finalPos
end

function SetEntitySpeedToCoord(Entity, CoordTarget, Mul, IgnoreX, IgnoreY, IgnoreZ, AddX, AddY, AddZ, Normalise, Relative,
							   OverridePos)
	local OPos = nil
	if OverridePos ~= nil then
		OPos = OverridePos
	else
		OPos = ENTITY.GET_ENTITY_COORDS(Entity)
	end
	local NewV3 = {
		x = (CoordTarget.x - OPos.x) * Mul,
		y = (CoordTarget.y - OPos.y) * Mul,
		z = (CoordTarget.z - OPos.z) * Mul
	}
	if IgnoreX then
		NewV3.x = 0.0
	end
	if IgnoreY then
		NewV3.y = 0.0
	end
	if IgnoreZ then
		NewV3.z = 0.0
	end
	if Normalise then
		NewV3 = v3.new(NewV3.x, NewV3.y, NewV3.z)
		if DistanceBetween(OPos.x, OPos.y, OPos.z, CoordTarget.x, CoordTarget.y, CoordTarget.z) * 0.5 > 1.0 then
			NewV3:normalise()
			NewV3:mul(Mul)
		end
	end
	local MoreX, MoreY, MoreZ = AddX, AddY, AddZ
	if Relative then
		local FVect, RVect, UpVect, Vect = v3.new(), v3.new(), v3.new(), v3.new()
		ENTITY.GET_ENTITY_MATRIX(Entity, FVect, RVect, UpVect, Vect)
		MoreX = (FVect.x * AddY) + (RVect.x * AddX) + (UpVect.x + AddZ)
		MoreY = (FVect.y * AddY) + (RVect.y * AddX) + (UpVect.y + AddZ)
		MoreZ = (FVect.z * AddY) + (RVect.z * AddX) + (UpVect.z + AddZ)
	end
	ENTITY.SET_ENTITY_VELOCITY(Entity, (NewV3.x) + MoreX, (NewV3.y) + MoreY, (NewV3.z) + MoreZ)
end

function UpgradeVehicle(Vehicle, RandomUpgrade, SetRandomColors, SetRandomCustomColors)
	VEHICLE.SET_VEHICLE_MOD_KIT(Vehicle, 0)
	if RandomUpgrade then
		for k = 0, 48 do
			local Max = VEHICLE.GET_NUM_VEHICLE_MODS(Vehicle, k)
			VEHICLE.SET_VEHICLE_MOD(Vehicle, k, math.random(0, math.max(0, Max - 1)), false)
		end
	else
		for k = 0, 48 do
			local Max = VEHICLE.GET_NUM_VEHICLE_MODS(Vehicle, k)
			VEHICLE.SET_VEHICLE_MOD(Vehicle, k, Max - 1, false)
		end
	end
	if SetRandomColors then
		VEHICLE.SET_VEHICLE_COLOURS(Vehicle, math.random(0, 222), math.random(0, 222))
	end
	if SetRandomCustomColors then
		VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(Vehicle, math.random(0, 255), math.random(0, 255), math.random(0, 255))
		VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(Vehicle, math.random(0, 255), math.random(0, 255),
			math.random(0, 255))
	end
end

function GetEntityFromScript(ScriptName, Local)
	local ScriptHash = Utils.Joaat(ScriptName)
	local Handle = 0
	local Address = ScriptLocal.GetPtr(ScriptHash, Local)
	local NetID = 0
	if Address ~= 0 then
		NetID = Memory.ReadInt(Address)
		if NetID ~= 0 then
			Script.ExecuteAsScript(ScriptName, function()
				Handle = NETWORK.NETWORK_GET_ENTITY_FROM_NETWORK_ID(NetID)
			end)
		end
	end
	return Handle, Address, NetID
end

function RotateEntityToTargetRotationFixedSpeed(entity, targetRotation, interpolationFactor, fixedSpeed)
    interpolationFactor = interpolationFactor or 0.1 -- Para suavizar a aproximação
    fixedSpeed = fixedSpeed or 1.0
    -- Obtenha a matriz de rotação atual da entidade
    local currentRotationMatrix = GetEntityRotationMatrix(entity)

    -- Calcule a matriz de rotação alvo
    local targetRotationMatrix = EulerToRotationMatrix(math.rad(targetRotation.x), math.rad(targetRotation.y), math.rad(targetRotation.z))

    -- Delta Rotation Matrix
    local deltaRotationMatrix = MatrixMultiply(targetRotationMatrix, MatrixInverse(currentRotationMatrix))

    -- Delta Quaternion
    local deltaQuaternion = RotationMatrixToQuaternion(deltaRotationMatrix)

    -- Converte delta quaternion para angular velocity
    local angularVelocity = QuaternionToAngularVelocity(deltaQuaternion)

    -- Calcula magnitude da angular velocity
    local mag = math.sqrt(angularVelocity.x^2 + angularVelocity.y^2 + angularVelocity.z^2)
    -- Normalização e aplicação do fixedSpeed
    if mag >= 0.05 then
        angularVelocity.x = (angularVelocity.x / mag) * fixedSpeed
        angularVelocity.y = (angularVelocity.y / mag) * fixedSpeed
        angularVelocity.z = (angularVelocity.z / mag) * fixedSpeed
    else
        -- Se não usar fixedSpeed → usa interpolação padrão (como a versão anterior)
        angularVelocity.x = angularVelocity.x * interpolationFactor
        angularVelocity.y = angularVelocity.y * interpolationFactor
        angularVelocity.z = angularVelocity.z * interpolationFactor
    end

    -- Aplica
    ENTITY.SET_ENTITY_ANGULAR_VELOCITY(entity, angularVelocity.x, angularVelocity.y, angularVelocity.z)
end

function GetRotationDifference(CurRot, TargetRot)
	local RotDifference = {
		x = TargetRot.x - CurRot.x,
		y = TargetRot.y - CurRot.y,
		z = TargetRot.z - CurRot.z,
	}
	RotDifference.x = (RotDifference.x + 180) % 360 - 180
	RotDifference.y = (RotDifference.y + 180) % 360 - 180
	RotDifference.z = (RotDifference.z + 180) % 360 - 180
	return RotDifference
end

function Rotation180To360(Angle)
	if Angle < 0.0 then
		return 360.0 + Angle
	else
		return Angle
	end
end

function GetCoordsCenter(CoordsT)
	local cx, cy, cz = 0, 0, 0
	local NumCoords = #CoordsT

	for i = 1, NumCoords do
		cx = cx + CoordsT[i].x
		cy = cy + CoordsT[i].y
		cz = cz + CoordsT[i].z
	end
	cx = cx / NumCoords
	cy = cy / NumCoords
	cz = cz / NumCoords

	return { x = cx, y = cy, z = cz }
end

function GetTheBiggerDistance(CoordsT, Center)
	local Distance = 0.0
	for i = 1, #CoordsT do
		local Dist = DistanceBetween(CoordsT[i].x, CoordsT[i].y, CoordsT[i].z, Center.x, Center.y, Center.z) -- * 0.5
		if Dist > Distance then
			Distance = Dist
		end
	end
	return Distance
end

function GetVector3_Distances(CoordsT, Center, Adjust)
	local d_x, d_y, d_z = 0, 0, 0
	for _, heli in ipairs(CoordsT) do
		d_x = math.max(d_x, math.abs(heli.x - Center.x))
		d_y = math.max(d_y, math.abs(heli.y - Center.y))
		d_z = math.max(d_z, math.abs(heli.z - Center.z))
	end
	local L_x = d_x + Adjust
	local L_y = d_y + Adjust
	local L_z = d_z + Adjust

	return { x = L_x, y = L_y, z = L_z }
end

function file_read(file)
	local f = io.open(file, "rb")
	if not f then return nil end
	local content = f:read("*a") -- Lê tudo de uma vez (muito mais rápido)
	f:close()
	return content
end

function GetVectorsTable(fileName, delayLoad, getOnlyFirstData)
	local content = file_read(fileName)
	if not content then return {} end

	local vectorTable = {}
	local maxIt = 1000
	local it = 0

	for line in content:gmatch("[^\r\n]+") do
		local numbers = {}
		for n in line:gmatch("%S+") do
			numbers[#numbers + 1] = tonumber(n)
		end

		vectorTable[#vectorTable + 1] = {
			x = numbers[1],
			y = numbers[2],
			z = numbers[3],
			RotX = numbers[4],
			RotY = numbers[5],
			RotZ = numbers[6],
			VelX = numbers[7],
			VelY = numbers[8],
			VelZ = numbers[9],
			AngVelX = numbers[10],
			AngVelY = numbers[11],
			AngVelZ = numbers[12],
			CurGameTime = numbers[13],
			ModelHash = numbers[14],
			Steering = numbers[15] or 0.0
		}

		if delayLoad then
			it = it + 1
			if it >= maxIt then
				it = 0
				Script.Yield(0)
			end
		end

		if getOnlyFirstData then
			break
		end
	end

	return vectorTable
end

function GetVectorsFromIndex(Txts)
	local Vectors = nil
	for line in Txts:gmatch("[^\r\n]+") do
		local numbers = {}
		for n in line:gmatch("%S+") do
			numbers[#numbers + 1] = tonumber(n)
		end
		Vectors = {
			x = numbers[1],
			y = numbers[2],
			z = numbers[3],
			RotX = numbers[4],
			RotY = numbers[5],
			RotZ = numbers[6],
			VelX = numbers[7],
			VelY = numbers[8],
			VelZ = numbers[9],
			AngVelX = numbers[10],
			AngVelY = numbers[11],
			AngVelZ = numbers[12],
			CurGameTime = numbers[13],
			ModelHash = numbers[14],
			Steering = numbers[15] or 0.0
		}
	end
	return Vectors
end


for k = 1, GameModeMakerData.MaxVehicles do
	GameModeMakerData.ListVehicles[k] = tostring(k-1)
	local Data = {
		VehicleType = 1,
		VehicleID = k-1,
		PathToPathsIndex = 1,
		PathToPaths = nil,
		Invincible = false,
		AttachedTo = -1,
		AttachOffset = {x = 0.0, y = 0.0, z = 0.0},
		AttachRot = {x = 0.0, y = 0.0, z = 0.0},
		RespawnVehForTeam = -1,
		Team = -1,
		TeamPlayerIndex = -1,
		Use = false
	}
	GameModeMakerData.MissionVehicles[k] = Data
end

local GameModeMakerFeatures = {}

--[[
local GameModePreview = false
GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GameModePreview"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GameModePreview"), "Game Mode Preview", eFeatureType.Toggle, "Preview positions.",
	function(f)
		GameModePreview = f:IsToggled()
	end)
}
]]
local RunGameMode = false
GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_RunGameMode"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_RunGameMode"), "Run Game Mode", eFeatureType.Toggle, "Needs to be in a mission.",
	function(f)
		RunGameMode = f:IsToggled()
		Script.QueueJob(function()
			if RunGameMode then
				local S = "fm_mission_controller"
				local SHash = Utils.Joaat(S)
				local Vehs = {}
				local ReplayVehicles = {}
				for k = 1, GameModeMakerData.MaxVehicles do
					local Data = GameModeMakerData.MissionVehicles[k]
					if Data.Use then
						if Data.VehicleType == GameModeMakerData.VehicleTypesEnum.Replay and Data.PathToPaths then
							ReplayVehicles[#ReplayVehicles + 1] = {
								VehHandle = 0,
								ModelHash = 0,
								Paths = GetVectorsTable(PathDirSaveds..Data.PathToPaths..".txt", true, false),
								Index = 0,
								Blip = 0,
								StartTimer = 0,
								PedHandle = 0,
								PedBlip = 0,
								HasSetStartTimer = false,
								TaskMS = 0,
								IsCargoPlane = false
							}
							Vehs[#Vehs+1] = {Data = Data, Replay = ReplayVehicles[#ReplayVehicles], Handle = 0}
						else
							Vehs[#Vehs+1] = {Data = Data, Handle = 0}
						end
					end
				end
				local HostMilis = 0
				local VehsLocal = SplitGlobals("uLocal_23609.f_834.f_81")
				local VehIDs = {}
				local Started = false
				while RunGameMode do
					if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(SHash) > 0 then
						local PlayerID = PLAYER.PLAYER_ID()
						local IsHost = false
						Script.ExecuteAsScript("fm_mission_controller", function()
							IsHost = NETWORK.NETWORK_IS_HOST_OF_THIS_SCRIPT()
						end)
						local GameTimer = MISC.GET_GAME_TIMER()
						if not IsHost then
							if GameTimer > HostMilis then
								HostMilis = GameTimer + 1000
								GTA.ForceScriptHost(SHash)
							end
						end
						if not Started then
							ReplayData.StartTimer = 0
							ReplayData.LastGameTimer = GameTimer
							if PLAYER.IS_PLAYER_CONTROL_ON(PlayerID) then
								Started = true
							end
						end
						for k = 1, #Vehs do
							local Data = Vehs[k].Data
							local Replay = Vehs[k].Replay
							local ID = Data.VehicleID
							if Replay ~= nil then
								if Replay.VehHandle == 0 then
									Replay.VehHandle = GetEntityFromScript(S, VehsLocal + (ID+1))
									Vehs[k].Handle = Replay.VehHandle
								else
									VehIDs[ID] = Vehs[k].Handle
									if not ENTITY.DOES_ENTITY_EXIST(Vehs[k].Handle) or ENTITY.IS_ENTITY_DEAD(Vehs[k].Handle) then
										Replay.VehHandle = 0
									end
								end
							end
							if Vehs[k].Handle == 0 then
								Vehs[k].Handle = GetEntityFromScript(S, VehsLocal + (ID+1))
							else
								local Handle = Vehs[k].Handle
								if ENTITY.DOES_ENTITY_EXIST(Handle) and not ENTITY.IS_ENTITY_DEAD(Handle) then
									VehIDs[ID] = Handle
									if RequestControlOfEntity(Handle) then
										entities.set_can_migrate(Handle, false)
										if Data.AttachedTo > -1 then
											local AID = Data.AttachedTo
											if VehIDs[AID] and ENTITY.DOES_ENTITY_EXIST(VehIDs[AID]) then
												local O1 = Data.AttachOffset
												local O2 = Data.AttachRot
												ENTITY.ATTACH_ENTITY_TO_ENTITY(Handle, VehIDs[AID], 0, O1.x, O1.y, O1.z, O2.x, O2.y, O2.z, false, false, false, false, 2, true, false)
											end
										end
										if Data.Invincible then
											ENTITY.SET_ENTITY_INVINCIBLE(Handle, true)
										end
									end
								else
									Vehs[k].Handle = 0
								end
							end
						end
						ReplayPlayback[2](ReplayVehicles, true, false)
					else
						Started = false
					end
					Script.Yield(0)
				end
			end
		end)
	end)
}

GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GMResetSettings"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GMResetSettings"), "Reset Settings", eFeatureType.Button, "",
	function()
		local Total = #GameModeMakerData.MaxVehicles
		GameModeMakerData.MissionVehicles = {}
		for k = 1, Total do
			local Data = {
				VehicleType = 1,
				VehicleID = k-1,
				PathToPathsIndex = 1,
				PathToPaths = nil,
				Invincible = false,
				AttachedTo = -1,
				AttachOffset = {x = 0.0, y = 0.0, z = 0.0},
				AttachRot = {x = 0.0, y = 0.0, z = 0.0},
				RespawnVehForTeam = -1,
				Team = -1,
				TeamPlayerIndex = -1,
				Use = false
			}
			GameModeMakerData.MissionVehicles[k] = Data
		end
	end)
}


GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GMSetFileName"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GMSetFileName"), "Game Mode Name", eFeatureType.InputText, "",
	function(f)
		GameModeMakerData.GameModeName = f:GetStringValue()
	end)
}

GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GMSaveGameMode"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GMSaveGameMode"), "Save Game Mode", eFeatureType.Button, "",
	function()
		local T = {
			MissionVehicles = GameModeMakerData.MissionVehicles
		}
		SaveJSONFile(GameModesDir..GameModeMakerData.GameModeName..".json", T)
		GetGameModesList()
	end)
}

GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GMRefreshGameModes"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GMRefreshGameModes"), "Refresh Game Modes", eFeatureType.Button, "",
	function()
		GetGameModesList()
	end)
}

GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GMLoadGameMode"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GMLoadGameMode"), "Load Game Mode", eFeatureType.Combo, "",
	function(f)
		local Index = f:GetListIndex() + 1
		if GameModeMakerData.GameModes[Index] then
			local T = LoadJSON(GameModeMakerData.GameModes[Index])
			GameModeMakerData.MissionVehicles = T.MissionVehicles
			local Data = GameModeMakerData.MissionVehicles[Index]
			GMFeatures.GMVehTypeFeature:SetListIndex(Data.VehicleType - 1)
			if Data.PathToPaths then
				local RIndex = FindReplayIndex(Data.PathToPaths) - 1
				GMFeatures.GMVehReplayFileFeature:SetListIndex(RIndex)
			end
			GMFeatures.GMVehInvincibleFeature:SetValue(Data.Invincible)
			GMFeatures.GMVehAttachedToFeature:SetValue(Data.AttachedTo)
			GMFeatures.GMVehAttachOffsetXFeature:SetValue(ToFloat(Data.AttachOffset.x))
			GMFeatures.GMVehAttachOffsetYFeature:SetValue(ToFloat(Data.AttachOffset.y))
			GMFeatures.GMVehAttachOffsetZFeature:SetValue(ToFloat(Data.AttachOffset.z))
			GMFeatures.GMVehAttachRotXFeature:SetValue(ToFloat(Data.AttachRot.x))
			GMFeatures.GMVehAttachRotYFeature:SetValue(ToFloat(Data.AttachRot.y))
			GMFeatures.GMVehAttachRotZFeature:SetValue(ToFloat(Data.AttachRot.z))
			GMFeatures.GMVehRespawnForTeamFeature:SetValue(Data.RespawnVehForTeam)
			GMFeatures.GMVehUseBoolFeature:SetValue(Data.Use)
		end
	end)
}
GMFeatures.GMLoadGameModeFeature = GameModeMakerFeatures[#GameModeMakerFeatures].Feature
function FindReplayIndex(ReplayFile)
	local Index = 1
	for k = 1, #ReplayListFeatures do
		if ReplayFile == ReplayListFeatures[k].FileName then
			return k
		end
	end
	return Index
end

GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GMSelectVehIndex"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GMSelectVehIndex"), "Select Vehicle Index To Edit", eFeatureType.Combo, "",
	function(f)
		local Index = f:GetListIndex() + 1
		GameModeMakerData.GMVehIndex = Index
		local Data = GameModeMakerData.MissionVehicles[Index]
		GMFeatures.GMVehTypeFeature:SetListIndex(Data.VehicleType - 1)
		if Data.PathToPaths then
			local RIndex = FindReplayIndex(Data.PathToPaths) - 1
			GMFeatures.GMVehReplayFileFeature:SetListIndex(RIndex)
		end
		GMFeatures.GMVehInvincibleFeature:SetValue(Data.Invincible)
		GMFeatures.GMVehAttachedToFeature:SetValue(Data.AttachedTo)
		GMFeatures.GMVehAttachOffsetXFeature:SetValue(ToFloat(Data.AttachOffset.x))
		GMFeatures.GMVehAttachOffsetYFeature:SetValue(ToFloat(Data.AttachOffset.y))
		GMFeatures.GMVehAttachOffsetZFeature:SetValue(ToFloat(Data.AttachOffset.z))
		GMFeatures.GMVehAttachRotXFeature:SetValue(ToFloat(Data.AttachRot.x))
		GMFeatures.GMVehAttachRotYFeature:SetValue(ToFloat(Data.AttachRot.y))
		GMFeatures.GMVehAttachRotZFeature:SetValue(ToFloat(Data.AttachRot.z))
		GMFeatures.GMVehRespawnForTeamFeature:SetValue(Data.RespawnVehForTeam)
		GMFeatures.GMVehUseBoolFeature:SetValue(Data.Use)
	end):SetList(GameModeMakerData.ListVehicles)
}
GMFeatures.GMVehIndexFeature = GameModeMakerFeatures[#GameModeMakerFeatures].Feature

GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GMSetVehicleType"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GMSetVehicleType"), "Vehicle Type", eFeatureType.Combo, "",
	function(f)
		GameModeMakerData.MissionVehicles[GameModeMakerData.GMVehIndex].VehicleType = f:GetListIndex() + 1
	end):SetList(GameModeMakerData.ListVehicleTypes)
}
GMFeatures.GMVehTypeFeature = GameModeMakerFeatures[#GameModeMakerFeatures].Feature

GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GMSetVehicleReplayFile"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GMSetVehicleReplayFile"), "Replay File", eFeatureType.Combo, "",
	function(f)
		GameModeMakerData.MissionVehicles[GameModeMakerData.GMVehIndex].PathToPaths = ReplayListFeatures[f:GetListIndex() + 1].FileName
	end):SetList(GameModeMakerData.ListReplayFiles)
}
GMFeatures.GMVehReplayFileFeature = GameModeMakerFeatures[#GameModeMakerFeatures].Feature
GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GMSetVehicleInvincible"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GMSetVehicleInvincible"), "Set Vehicle Invincible", eFeatureType.Toggle, "",
	function(f)
		GameModeMakerData.MissionVehicles[GameModeMakerData.GMVehIndex].Invincible = f:IsToggled()
	end)
}
GMFeatures.GMVehInvincibleFeature = GameModeMakerFeatures[#GameModeMakerFeatures].Feature
GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GMSetVehicleAttachedTo"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GMSetVehicleAttachedTo"), "Set Vehicle Attached To", eFeatureType.InputInt, "",
	function(f)
		GameModeMakerData.MissionVehicles[GameModeMakerData.GMVehIndex].AttachedTo = f:GetIntValue()
	end):SetMaxValue(31):SetMinValue(-1):SetValue(-1)
}
GMFeatures.GMVehAttachedToFeature = GameModeMakerFeatures[#GameModeMakerFeatures].Feature
GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GMVehAttachOffsetX"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GMVehAttachOffsetX"), "Attach Offset X", eFeatureType.InputFloat, "",
	function(f)
		GameModeMakerData.MissionVehicles[GameModeMakerData.GMVehIndex].AttachOffset.x = f:GetFloatValue()
	end):SetMaxValue(1000.0):SetMinValue(-1000.0):SetValue(0.0)
}
GMFeatures.GMVehAttachOffsetXFeature = GameModeMakerFeatures[#GameModeMakerFeatures].Feature
GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GMVehAttachOffsetY"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GMVehAttachOffsetY"), "Attach Offset Y", eFeatureType.InputFloat, "",
	function(f)
		GameModeMakerData.MissionVehicles[GameModeMakerData.GMVehIndex].AttachOffset.y = f:GetFloatValue()
	end):SetMaxValue(1000.0):SetMinValue(-1000.0):SetValue(0.0)
}
GMFeatures.GMVehAttachOffsetYFeature = GameModeMakerFeatures[#GameModeMakerFeatures].Feature
GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GMVehAttachOffsetZ"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GMVehAttachOffsetZ"), "Attach Offset Z", eFeatureType.InputFloat, "",
	function(f)
		GameModeMakerData.MissionVehicles[GameModeMakerData.GMVehIndex].AttachOffset.z = f:GetFloatValue()
	end):SetMaxValue(1000.0):SetMinValue(-1000.0):SetValue(0.0)
}
GMFeatures.GMVehAttachOffsetZFeature = GameModeMakerFeatures[#GameModeMakerFeatures].Feature
GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GMVehAttachRotX"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GMVehAttachRotX"), "Attach Rot X", eFeatureType.InputFloat, "",
	function(f)
		GameModeMakerData.MissionVehicles[GameModeMakerData.GMVehIndex].AttachRot.x = f:GetFloatValue()
	end):SetMaxValue(180.0):SetMinValue(-180.0):SetValue(0.0)
}
GMFeatures.GMVehAttachRotXFeature = GameModeMakerFeatures[#GameModeMakerFeatures].Feature
GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GMVehAttachRotY"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GMVehAttachRotY"), "Attach Rot Y", eFeatureType.InputFloat, "",
	function(f)
		GameModeMakerData.MissionVehicles[GameModeMakerData.GMVehIndex].AttachRot.y = f:GetFloatValue()
	end):SetMaxValue(180.0):SetMinValue(-180.0):SetValue(0.0)
}
GMFeatures.GMVehAttachRotYFeature = GameModeMakerFeatures[#GameModeMakerFeatures].Feature
GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GMVehAttachRotZ"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GMVehAttachRotZ"), "Attach Rot Z", eFeatureType.InputFloat, "",
	function(f)
		GameModeMakerData.MissionVehicles[GameModeMakerData.GMVehIndex].AttachRot.z = f:GetFloatValue()
	end):SetMaxValue(180.0):SetMinValue(-180.0):SetValue(0.0)
}
GMFeatures.GMVehAttachRotZFeature = GameModeMakerFeatures[#GameModeMakerFeatures].Feature
GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GMRespawnVehForTeam"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GMRespawnVehForTeam"), "Respawn Vehicle For Team", eFeatureType.InputInt, "",
	function(f)
		GameModeMakerData.MissionVehicles[GameModeMakerData.GMVehIndex].RespawnVehForTeam = f:GetIntValue()
	end):SetMaxValue(3):SetMinValue(-1):SetValue(-1)
}
GMFeatures.GMVehRespawnForTeamFeature = GameModeMakerFeatures[#GameModeMakerFeatures].Feature
GameModeMakerFeatures[#GameModeMakerFeatures+1] = {Hash = Utils.Joaat("Replay_GMUseVehicle"),
Feature = FeatureMgr.AddFeature(Utils.Joaat("Replay_GMUseVehicle"), "Use Vehicle", eFeatureType.Toggle, "",
	function(f)
		GameModeMakerData.MissionVehicles[GameModeMakerData.GMVehIndex].Use = f:IsToggled()
	end)
}
GMFeatures.GMVehUseBoolFeature = GameModeMakerFeatures[#GameModeMakerFeatures].Feature
ClickGUI.AddTab("Path Replay", function()
	if ImGui.BeginTabBar("Path Replay", 0) then
		if ImGui.BeginTabItem("Recording") then
			if ClickGUI.BeginCustomChildWindow("Recording") then
				for k = 1, #RecordFeatures do
					ClickGUI.RenderFeature(RecordFeatures[k].Hash)
				end
				ClickGUI.EndCustomChildWindow()
			end
			ImGui.EndTabItem()
		end
		if ImGui.BeginTabItem("Replay Features") then
			if ClickGUI.BeginCustomChildWindow("Replay Features") then
				for k = 1, #ReplayFeatures do
					ClickGUI.RenderFeature(ReplayFeatures[k].Hash)
				end
				ClickGUI.EndCustomChildWindow()
			end
			ImGui.EndTabItem()
		end
		if ImGui.BeginTabItem("Replay List") then
			if ClickGUI.BeginCustomChildWindow("Replay List") then
				ClickGUI.RenderFeature(Utils.Joaat("Replay_RefreshReplays"))
				ImGui.Columns()
				for k = 1, #ReplayListFeatures do
					ClickGUI.RenderFeature(ReplayListFeatures[k].Hash)
				end
				ClickGUI.EndCustomChildWindow()
			end
			ImGui.EndTabItem()
		end
		if ImGui.BeginTabItem("Game Mode Maker") then
			if ClickGUI.BeginCustomChildWindow("Game Mode Maker") then
				for k = 1, #GameModeMakerFeatures do
					ClickGUI.RenderFeature(GameModeMakerFeatures[k].Hash)
				end
				ClickGUI.EndCustomChildWindow()
			end
			ImGui.EndTabItem()
		end
		ImGui.EndTabBar()
	end
end)
