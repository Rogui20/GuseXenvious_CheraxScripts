require("natives/natives")
json = require "json"
require "nav_utils"

Print = Logger.LogInfo
Wait = Script.Yield
joaat = Utils.Joaat

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

local menuNames = {}
local menus = {}
local menu = {}
menu.list = function() end
menu.my_root = function() end
menu.toggle = function(Menu, Desc, Command, HelpTextDesc, Callback, DefaultOn)
	local DescSub = string.gsub(Desc, " ", "")
	menuNames[DescSub] = menuNames and menuNames[DescSub] or {}
	menuNames[DescSub][#menuNames[DescSub] + 1] = true
	local Hash = Utils.Joaat(DescSub .. #menuNames[DescSub])
	local Feature = FeatureMgr.AddFeature(Hash, Desc .. " " .. #menuNames[DescSub], eFeatureType.Toggle, "",
		function(f)
			Script.QueueJob(
				function()
					Callback(f:IsToggled())
				end)
		end)
	if DefaultOn then
		Feature:Toggle()
	end
	menus[#menus + 1] = Hash
end

menu.action = function(Menu, Desc, Command, HelpTextDesc, Callback)
	local DescSub = string.gsub(Desc, " ", "")
	menuNames[DescSub] = menuNames and menuNames[DescSub] or {}
	menuNames[DescSub][#menuNames[DescSub] + 1] = true
	local Hash = Utils.Joaat(DescSub .. #menuNames[DescSub])
	FeatureMgr.AddFeature(Hash, Desc .. " " .. #menuNames[DescSub], eFeatureType.Button, "",
		function(f) Script.QueueJob(function() Callback(f) end, f) end)
	menus[#menus + 1] = Hash
end


menu.slider = function(Menu, Desc, Command, HelpTextDesc, Min, Max, Default, StepSize, CallBack)
	local DescSub = string.gsub(Desc, " ", "")
	menuNames[DescSub] = menuNames and menuNames[DescSub] or {}
	menuNames[DescSub][#menuNames[DescSub] + 1] = true
	local Hash = Utils.Joaat(DescSub .. #menuNames[DescSub])
	local Feature = FeatureMgr.AddFeature(Hash, Desc .. " " .. #menuNames[DescSub], eFeatureType.SliderInt, "",
		function(f) Callback(f:GetIntValue()) end)
	Feature:SetMinValue(Min)
	Feature:SetMaxValue(Max)
	Feature:SetIntValue(Default)
	Feature:SetStepSize(StepSize)
	menus[#menus + 1] = Hash
end

menu.slider_float = function(Menu, Desc, Command, HelpTextDesc, Min, Max, Default, StepSize, Callback)
	local DescSub = string.gsub(Desc, " ", "")
	menuNames[DescSub] = menuNames and menuNames[DescSub] or {}
	menuNames[DescSub][#menuNames[DescSub] + 1] = true
	local Hash = Utils.Joaat(DescSub .. #menuNames[DescSub])
	local Feature = FeatureMgr.AddFeature(Hash, Desc .. " " .. #menuNames[DescSub], eFeatureType.SliderFloat, "",
		function(f) Callback(f:GetFloatValue()) end)
	Feature:SetMinValue(Min)
	Feature:SetMaxValue(Max)
	Feature:SetFloatValue(Default)
	Feature:SetStepSize(StepSize)
	menus[#menus + 1] = Hash
end

menu.list_select = function(Menu, Desc, Command, HelpTextDesc, List, Index, Callback)
	local DescSub = string.gsub(Desc, " ", "")
	menuNames[DescSub] = menuNames and menuNames[DescSub] or {}
	menuNames[DescSub][#menuNames[DescSub] + 1] = true
	local Hash = Utils.Joaat(DescSub .. #menuNames[DescSub])
	local Feature = FeatureMgr.AddFeature(Hash, Desc .. " " .. #menuNames[DescSub], eFeatureType.List, "",
		function(f) Callback(f) end)
	Feature:SetList(List)
	Feature:SetListIndex(Index)
	menus[#menus + 1] = Hash
end

menu.list_action = function(Menu, Desc, Command, HelpTextDesc, List, Index, Callback)
	local DescSub = string.gsub(Desc, " ", "")
	menuNames[DescSub] = menuNames and menuNames[DescSub] or {}
	menuNames[DescSub][#menuNames[DescSub] + 1] = true
	local Hash = Utils.Joaat(DescSub .. #menuNames[DescSub])
	local Feature = FeatureMgr.AddFeature(Hash, Desc .. " " .. #menuNames[DescSub], eFeatureType.List, "",
		function(f) Callback(f) end)
	Feature:SetList(List)
	Feature:SetListIndex(Index)
	menus[#menus + 1] = Hash
end

menu.toggle_loop = function(DevMenu, Desc, Command, HelpTextDesc, Callback)
	local DescSub = string.gsub(Desc, " ", "")
	menuNames[DescSub] = menuNames and menuNames[DescSub] or {}
	menuNames[DescSub][#menuNames[DescSub] + 1] = true
	local Hash = Utils.Joaat(DescSub .. #menuNames[DescSub])
	local Feature = FeatureMgr.AddFeature(Hash, Desc .. " " .. #menuNames[DescSub], eFeatureType.Toggle, "",
		function(f) if f:IsToggled() then Script.QueueJob(Callback(f), f) end end)
	Feature:RegisterCallbackTrigger(eCallbackTrigger.OnTick)
	menus[#menus + 1] = Hash
end

menu.text_input = function(Menu, Desc, Command, HelpTextDesc, Callback)
	local DescSub = string.gsub(Desc, " ", "")
	menuNames[DescSub] = menuNames and menuNames[DescSub] or {}
	menuNames[DescSub][#menuNames[DescSub] + 1] = true
	local Hash = Utils.Joaat(DescSub .. #menuNames[DescSub])
	FeatureMgr.AddFeature(Hash, Desc .. " " .. #menuNames[DescSub], eFeatureType.InputText, "",
		function(f) Callback(f:GetStringValue()) end)
	menus[#menus + 1] = Hash
end

local filesystem = {}
filesystem.mkdirs = function(Path)
	FileMgr.CreateDir(Path)
end
filesystem.scripts_dir = function()
	return FileMgr.GetMenuRootPath() .. "\\Lua\\"
end
filesystem.list_files = function(path, extension, recursive)
	return FileMgr.FindFiles(path, ".txt", false)
end
filesystem.is_dir = function(path)
	return false
end

local FileNameForSave = "StoredPath"
local PathDirSaveds = filesystem.scripts_dir() .. "Paths\\"
local AttachmentsDir = PathDirSaveds .. "Attachments\\"
local LoadedFileName = FileNameForSave


filesystem.mkdirs(filesystem.scripts_dir() .. "Paths")
filesystem.mkdirs(PathDirSaveds .. "EditedRecords")
filesystem.mkdirs(PathDirSaveds .. "ContinuedRecords")
filesystem.mkdirs(PathDirSaveds .. "Attachments")

local memory = {}
memory.write_int = function(addr, value)
	Memory.WriteInt(addr, value)
end
memory.read_int = function(addr)
	return Memory.ReadInt(addr)
end
memory.write_float = function(addr, value)
	Memory.WriteFloat(addr, value)
end
memory.read_float = function(addr)
	return Memory.ReadFloat(addr)
end
memory.read_byte = function(addr)
	return Memory.ReadByte(addr)
end
memory.script_global = function(global)
	return ScriptGlobal.GetPtr(global)
end
memory.script_local = function(scriptName, localNum)
	return ScriptLocal.GetPtr(joaat(scriptName), localNum)
end
memory.alloc = function(Num)
	return Memory.Alloc(Num)
end
memory.alloc_int = function()
	return Memory.AllocInt()
end

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
	local Addr = memory.alloc(8)
	memory.write_int(Addr, blip)
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
local GlobalSpd = 15.65
local SpeedMultiplier = 1.0545

local InterpolationFactor = 10.0

local FileListPTRs = {}

local FileListNoFolder = {}
local FileListOptions = {}
local FileList = {}
local FPS = 30

local function SetFilesList(directory, query, results)
	if results == nil then results = {} end
	for _, filepath in ipairs(filesystem.list_files(directory)) do
		if filesystem.is_dir(filepath) then
			local _2, filename, ext = string.match(filepath, "(.-)([^\\/]-%.?)[.]([^%.\\/]*)$")
			local PathsFile = {
				Is_Directory = true,
				FilePath = filepath .. "\\",
				FileName = filename,
				Name = "",
				Ext = "",
				Directory = _2
			}
			table.insert(results, PathsFile)
			SetFilesList(filepath, query, results)
		else
			if string.match(filepath:lower(), query:lower()) then
				local _2, filename, ext = string.match(filepath, "(.-)([^\\/]-%.?)[.]([^%.\\/]*)$")
				if ext == "txt" then
					local PathsFile = {
						Is_Directory = false,
						FilePath = filepath,
						FileName = filename,
						Name = filename,
						Ext = ext,
						Directory = _2
					}
					table.insert(results, PathsFile)
				end
			end
		end
	end
	return results
end

local ReplaysToLoad = {}
local MultiplayerRecordingPTR = nil
local Advanced_StartRecordingPTR = nil

local SoloRecordingMenu = menu.list(menu.my_root(), "Solo Recording", {}, "Record solo tools.")

local ResetPTRs = true
local FileSelectMenu = menu.list(SoloRecordingMenu, "Load Replay File", { "loadreplayfilemenu" },
	"Now you can select multiple replays to load at once.",
	function() if ResetPTRs then CreateMenuItemsForFileList() end end
	, function()
		if ResetPTRs then CreateMenuItemsForFileList() end
	end)

function CreateMenuItemsForFileList()
	FileList = SetFilesList(PathDirSaveds, "")
	FileListOptions = {}
	FileListNoFolder = {}
	for k = 1, #FileListPTRs do
		menu.delete(FileListPTRs[#FileListPTRs].PTR)
		table.remove(FileListPTRs, #FileListPTRs)
	end
	FileListPTRs = {}
	for k = 1, #FileList do
		if FileList[k].Is_Directory then
			local CanCreate = true
			for i = 1, #FileListOptions do
				if FileListOptions[i].DirectoryName == FileList[k].FilePath then
					CanCreate = false
				end
			end
			if CanCreate then
				FileListOptions[#FileListOptions + 1] = {
					Contents = {},
					DirectoryName = FileList[k].FilePath,
					DirectoryPath =
						FileList[k].FilePath
				}
			end
		end
	end
	for k = 1, #FileList do
		if not FileList[k].Is_Directory then
			local Dir = FileList[k].Directory
			local Inserted = false
			for i = 1, #FileListOptions do
				if FileListOptions[i].DirectoryPath == Dir then
					Inserted = true

					FileListOptions[i].Contents[#FileListOptions[i].Contents + 1] = {
						FilePath = FileList[k].FilePath,
						FileName =
							FileList[k].FileName
					}
				end
			end
			if not Inserted then
				FileListNoFolder[#FileListNoFolder + 1] = {
					FilePath = FileList[k].FilePath,
					FileName = FileList[k]
						.FileName
				}
			end
		end
	end
	for k = 1, #FileListOptions do
		local PTR = menu.list(FileSelectMenu, FileListOptions[k].DirectoryName, {}, "")
		FileListPTRs[#FileListPTRs + 1] = { PTR = PTR }
		for i = 1, #FileListOptions[k].Contents do
			FileListPTRs[#FileListPTRs + 1] = {
				PTR = menu.toggle(PTR, FileListOptions[k].Contents[i].FileName, {}, "", function(toggle)
					local _FileName = FileListOptions[k].Contents[i].FilePath
					if toggle then
						ReplaysToLoad[_FileName] = {}
					else
						ReplaysToLoad[_FileName] = nil
					end
				end, ReplaysToLoad[FileListOptions[k].Contents[i].FilePath] ~= nil)
			}
		end
	end
	for k = 1, #FileListNoFolder do
		FileListPTRs[#FileListPTRs + 1] = {
			PTR = menu.toggle(FileSelectMenu, FileListNoFolder[k].FileName, {}, "", function(toggle)
				_FileName = FileListNoFolder[k].FilePath
				if toggle then
					ReplaysToLoad[_FileName] = {}
				else
					ReplaysToLoad[_FileName] = nil
				end
			end, ReplaysToLoad[FileListNoFolder[k].FilePath] ~= nil)
		}
	end
	Print("FileListOptions " .. #FileListOptions .. " FileListNoFolder " .. #FileListNoFolder)
end

menu.text_input(SoloRecordingMenu, "Set File Name", { "setfilename" }, "Set file name for saving.", function(OnChange)
	FileNameForSave = OnChange
end, FileNameForSave)

CreateMenuItemsForFileList()

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

local EmptyRecord = false
local EmptyRecordPTR = menu.toggle(SoloRecordingMenu, "First Clear Recording File", {}, "", function(toggle)
	EmptyRecord = toggle
end, EmptyRecord)

local RecordT = {}
local GlobalReplayTime = 0 -- tempo virtual de reprodução, em ms
local ReplaySpeed = 1.0    -- 1.0 = velocidade normal, negativo seria rebobinar
local IsRewinding = false
local StartRecord = false
local StartRecordingPTR = menu.toggle(SoloRecordingMenu, "Start Recording", {}, "", function(toggle)
	StartRecord = toggle
	if StartRecord then
		--GlobalReplayTime = 0
		if EmptyRecord then
			ClearFile(PathDirSaveds .. FileNameForSave .. ".txt")
		end
		local StartedTime = MISC.GET_GAME_TIMER()
		local LastTime = 0
		local PausedTimeStart = 0
		local IsPaused = false
		local LastValidTime = 0

		while StartRecord do
			local PlayerPed = PLAYER.PLAYER_PED_ID()
			local Veh = PED.GET_VEHICLE_PED_IS_IN(PlayerPed, true)
			local GameTimer = MISC.GET_GAME_TIMER()

			PAD.DISABLE_CONTROL_ACTION(0, 75)
			PAD.DISABLE_CONTROL_ACTION(0, 99)
			local ExitPressed = PAD.IS_DISABLED_CONTROL_PRESSED(0, 75) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 99)

			if Veh ~= 0 then
				if ExitPressed then
					if not IsPaused then
						IsPaused = true
						PausedTimeStart = GameTimer
					end

					-- Rebobinar: remover último frame
					if #RecordT > 0 then
						table.remove(RecordT, #RecordT)

						-- Atualiza o LastValidTime
						if #RecordT > 0 then
							local LastFrame = GetVectorsFromIndex(RecordT[#RecordT])
							LastValidTime = LastFrame.CurGameTime
							ENTITY.SET_ENTITY_COORDS(Veh, LastFrame.x, LastFrame.y, LastFrame.z, false, false, true)
							ENTITY.SET_ENTITY_ROTATION(Veh, LastFrame.RotX, LastFrame.RotY, LastFrame.RotZ, 5)
							ENTITY.SET_ENTITY_VELOCITY(Veh, LastFrame.VelX, LastFrame.VelY, LastFrame.VelZ)
							ENTITY.SET_ENTITY_ANGULAR_VELOCITY(Veh, LastFrame.AngVelX, LastFrame.AngVelY,
								LastFrame.AngVelZ)
							VEHICLE.SET_VEHICLE_FORWARD_SPEED(Veh,
								math.sqrt(LastFrame.VelX ^ 2 + LastFrame.VelY ^ 2 + LastFrame.VelZ ^ 2))
						else
							LastValidTime = 0
						end
					end
				else
					if IsPaused then
						-- Terminou rebobinamento
						local GameTimerNow = MISC.GET_GAME_TIMER()

						-- ⚡ Aqui a correção real:
						StartedTime = GameTimerNow - LastValidTime

						IsPaused = false
					end

					-- Gravar normalmente
					local Elapsed = GameTimer - StartedTime
					LastTime = Elapsed
					--Global_StartedTime = StartedTime

					local Pos = ENTITY.GET_ENTITY_COORDS(Veh)
					local Rot = ENTITY.GET_ENTITY_ROTATION(Veh, 5)
					local Vel = ENTITY.GET_ENTITY_VELOCITY(Veh)
					local AngVel = ENTITY.GET_ENTITY_ROTATION_VELOCITY(Veh)
					local VehModel = ENTITY.GET_ENTITY_MODEL(Veh)
					local BoneID = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(Veh, "steeringwheel")
					local Steering = 0.0
					if BoneID ~= 0 then
						local SteeringRot = ENTITY.GET_ENTITY_BONE_OBJECT_ROTATION(Veh, BoneID)
						SteeringRot = v3.new(SteeringRot)
						SteeringRot:normalise()
						Steering = -SteeringRot.y
					end

					RecordT[#RecordT + 1] = ToTxt(Pos, Rot, Vel, AngVel, Elapsed, VehModel, Steering)
				end
			end
			IsRewinding = IsPaused
			-- Debug Visual
			--directx.draw_text(0.5, 0.55, "GameTimer "..GameTimer, ALIGN_CENTRE, 1.0, {r = 0.0, g = 1.0 , b = 1.0, a = 1.0}, false)
			--directx.draw_text(0.5, 0.6, "StartedTime "..StartedTime, ALIGN_CENTRE, 1.0, {r = 0.0, g = 1.0 , b = 1.0, a = 1.0}, false)
			--directx.draw_text(0.5, 0.65, "LastTime "..LastTime, ALIGN_CENTRE, 1.0, {r = 0.0, g = 1.0 , b = 1.0, a = 1.0}, false)

			Wait()
		end

		-- Salvar no final
		local BigText = table.concat(RecordT)
		WriteFile(PathDirSaveds .. FileNameForSave .. ".txt", BigText)
		RecordT = {}
	end
end)

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

local function switch_to_next_registered()
	if #RegisteredV2 == 0 then return end
	if CurrentVehicleV2 == 0 then
		CurrentVehicleV2 = RegisteredV2[1]
		ensure_setup_for_vehicle(CurrentVehicleV2)
		return
	end
	local idx = idx_of_handle(RegisteredV2, CurrentVehicleV2)
	if idx == 0 then
		CurrentVehicleV2 = RegisteredV2[1]
	else
		local nxt = idx + 1
		if nxt > #RegisteredV2 then nxt = 1 end
		CurrentVehicleV2 = RegisteredV2[nxt]
	end
	ensure_setup_for_vehicle(CurrentVehicleV2)
end

local function switch_to_previous_registered()
	if #RegisteredV2 == 0 then return end
	if CurrentVehicleV2 == 0 then
		CurrentVehicleV2 = RegisteredV2[1]
		ensure_setup_for_vehicle(CurrentVehicleV2)
		return
	end
	local idx = idx_of_handle(RegisteredV2, CurrentVehicleV2)
	if idx == 0 then
		CurrentVehicleV2 = 1
	else
		local nxt = idx - 1
		if nxt < 1 then nxt = #RegisteredV2 end
		CurrentVehicleV2 = RegisteredV2[nxt]
	end
	ensure_setup_for_vehicle(CurrentVehicleV2)
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
--
---- ===== UI V2 =====
menu.action(SoloRecordingMenu, "V2 - Registrar Veículo Atual", {}, "Adiciona o veículo atual na lista de switch do V2.",
	function()
		local veh = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
		if handle_exists(veh) then
			if idx_of_handle(RegisteredV2, veh) == 0 then
				RegisteredV2[#RegisteredV2 + 1] = veh
				ensure_setup_for_vehicle(veh)
				Print("V2: Registrado veículo " .. tostring(veh))
			else
				Print("V2: Veículo já registrado.")
			end
		else
			Print("V2: Nenhum veículo para registrar.")
		end
	end)

menu.action(SoloRecordingMenu, "V2 - Limpar Veículos Registrados", {}, "", function()
	RegisteredV2 = {}
	CurrentVehicleV2 = 0
	Print("V2: Lista de veículos registrada limpa.")
end)

menu.toggle(SoloRecordingMenu, "Start Recording V3", {}, "Grava vários veículos com rewind local por delta.",
	function(toggle)
		RecordingV2 = toggle
		if RecordingV2 then
			local Records = {}
			CurrentVehicleV2 = 0
			local LastGameTimer = MISC.GET_GAME_TIMER()
			local IsRewinding2 = false
			local FocusedIndex = 1
			local LastIndex = 1
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
							--Records[k].LastIndex = FindFrameIndex(F, Records[k].LastIndex, Records[k].ReplayTime)
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
							if Records[k].SetSpeed then
								Records[k].SetSpeed = false
								if Records[k].LastData then
									ApplyFrame(Veh, Records[k].LastData)
								end
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
									RotateEntityToTargetRotation(Veh, F.Rot, 5.0)
								else
									Records[k].ReplayTP = false
									if Records[k].LastIndex >= #Records[k].FramesData[#Records[k].FramesData] then
										ENTITY.FREEZE_ENTITY_POSITION(Veh, true)
									else
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
								end
							end
						end
					end
				end
				Wait()
			end
			if Records[FocusedIndex] ~= nil then
				local Frames = CopyTable(Records[FocusedIndex].Frames)
				Records[FocusedIndex].FramesData[#Records[FocusedIndex].FramesData+1] = Frames
				Records[FocusedIndex].Frames = {}
			end
			local ID = 1
			for k = 1, #RegisteredV2 do
				if Records[k] ~= nil and #Records[k].FramesData > 0 then
					local Path = filesystem.scripts_dir() .. "Paths\\" .. FileNameForSave .. "_" .. ID .. ".txt"
					local Out = {}
					for i = 1, #Records[k].FramesData do
						for j = 1, #Records[k].FramesData[i] do
							local F = Records[k].FramesData[i][j]
							Out[#Out + 1] = ToTxt(F.Pos, F.Rot, F.Vel, F.Ang, F.Time, F.Model)
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

--menu.toggle(SoloRecordingMenu, "Start Recording V3", {}, "Grava vários veículos com rewind local por delta.",
--	function(toggle)
--		RecordingV2 = toggle
--		if RecordingV2 then
--			Print("🎥 Gravador V3 iniciado.")
--			local VehicleRecordsV2 = {}
--			local VehicleStateV2 = {}
--			CurrentVehicleV2 = 0
--			local LastGameTimerV3 = MISC.GET_GAME_TIMER()
--			local IsRewindingV2 = false
--			local SwitchRequestedV2 = false
--			local FirstVeh = 0
--			local FirstVehRecordTime = 0
--			local SwitchFromRewind = false
--			local PreviousVehicle = 0
--			local StateHistory = {}
--			while RecordingV2 do
--				local now = MISC.GET_GAME_TIMER()
--				local delta = now - LastGameTimerV3
--				if delta < 0 then delta = 0 end
--				LastGameTimerV3 = now       -- 🎮 Controles
--				PAD.DISABLE_CONTROL_ACTION(0, 99, true) -- R
--				IsRewindingV2 = PAD.IS_DISABLED_CONTROL_PRESSED(0, 99)
--				PAD.DISABLE_CONTROL_ACTION(0, 75, true) -- F
--				PAD.DISABLE_CONTROL_ACTION(0, 51, true) -- E
--				if FirstVeh ~= 0 and CurrentVehicleV2 ~= 0 and CurrentVehicleV2 == FirstVeh then
--					if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 75) then
--						switch_to_next_registered()
--						SwitchRequestedV2 = true
--					end
--				else
--					if CurrentVehicleV2 ~= 0 and VehicleStateV2[CurrentVehicleV2] then
--						if VehicleStateV2[CurrentVehicleV2].last_recording_time >= FirstVehRecordTime and not IsRewindingV2 then
--							switch_to_next_registered()
--							SwitchRequestedV2 = true
--						end
--					end
--				end
--				if CurrentVehicleV2 ~= 0 and VehicleStateV2[CurrentVehicleV2] then
--					if IsRewindingV2 and VehicleStateV2[CurrentVehicleV2].last_recording_time <= 0 then
--						if #StateHistory > 0 then
--							VehicleStateV2[CurrentVehicleV2].last_recording_time = 0
--							switch_to_previous_registered()
--							local T = table.remove(StateHistory)
--							VehicleStateV2 = T.States
--							SwitchFromRewind = true
--							SwitchRequestedV2 = true
--						end
--					end
--				end
--				if CurrentVehicleV2 == 0 then
--					CurrentVehicleV2 = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
--					if CurrentVehicleV2 == 0 and #RegisteredV2 > 0 then
--						CurrentVehicleV2 = RegisteredV2[1]
--					end
--				else
--					ENTITY.FREEZE_ENTITY_POSITION(CurrentVehicleV2, false)
--					if not PED.IS_PED_IN_VEHICLE(PLAYER.PLAYER_PED_ID(), CurrentVehicleV2, true) then
--						PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), CurrentVehicleV2, -1)
--					end
--				end
--				if FirstVeh == 0 and CurrentVehicleV2 ~= 0 then
--					FirstVeh = CurrentVehicleV2
--				end -- 🚗 Inicializa veículo atual
--				if CurrentVehicleV2 ~= 0 and not VehicleStateV2[CurrentVehicleV2] then
--					VehicleStateV2[CurrentVehicleV2] = {
--						frames = {},
--						record_time = 0,
--						last_recording_time = 0,
--						replay_time = 0,
--						last_index = 1,
--						frozen = false,
--						recording = false,
--						playing = false,
--					}
--					VehicleRecordsV2[CurrentVehicleV2] = VehicleStateV2[CurrentVehicleV2].frames
--				end
--				if SwitchRequestedV2 then
--					if CurrentVehicleV2 ~= 0 and VehicleStateV2[CurrentVehicleV2] then
--						if not SwitchFromRewind then
--							local T = CopyTable(VehicleStateV2)
--							StateHistory[#StateHistory + 1] = { States = T, Veh = CurrentVehicleV2 }
--							VehicleStateV2[CurrentVehicleV2].last_recording_time = 0
--							if CurrentVehicleV2 == FirstVeh then
--								FirstVehRecordTime = 0
--							end
--						else
--							SwitchRequestedV2 = false
--						end
--						local frames = VehicleStateV2[CurrentVehicleV2].frames
--						if #frames > 0 then
--							local f = frames[#frames]
--							ENTITY.FREEZE_ENTITY_POSITION(CurrentVehicleV2, false)
--							TASK.CLEAR_VEHICLE_CRASH_TASK(CurrentVehicleV2)
--							VEHICLE.SET_DISABLE_AUTOMATIC_CRASH_TASK(CurrentVehicleV2, false)
--							VEHICLE.SET_DIP_STRAIGHT_DOWN_WHEN_CRASHING_PLANE(CurrentVehicleV2, false)
--							VEHICLE.SET_VEHICLE_ENGINE_ON(CurrentVehicleV2, true, true, false)
--							VEHICLE.SET_VEHICLE_KEEP_ENGINE_ON_WHEN_ABANDONED(CurrentVehicleV2, true)
--							ENTITY.SET_ENTITY_COORDS_NO_OFFSET(CurrentVehicleV2, f.pos.x, f.pos.y, f.pos.z)
--							ENTITY.SET_ENTITY_ROTATION(CurrentVehicleV2, f.rot.x, f.rot.y, f.rot.z, 5)
--							VEHICLE.SET_VEHICLE_FORWARD_SPEED(CurrentVehicleV2,
--								math.sqrt(f.vel.x ^ 2 + f.vel.y ^ 2 + f.vel.z ^ 2))
--							ENTITY.SET_ENTITY_VELOCITY(CurrentVehicleV2, f.vel.x, f.vel.y, f.vel.z)
--							ENTITY.SET_ENTITY_ANGULAR_VELOCITY(CurrentVehicleV2, f.ang.x, f.ang.y, f.ang.z)
--						end
--					end
--				end -- 🔁 Atualiza todos os veículos
--				for veh, state in pairs(VehicleStateV2) do
--					if not handle_exists(veh) then
--						goto continue
--					end
--					local frames = state.frames
--					local isFocused = (veh == CurrentVehicleV2)
--					------------------------------------------------------- -- 🧾 GRAVAÇÃO (veículo focado) -------------------------------------------------------
--					if isFocused and not IsRewindingV2 then
--						state.recording = true
--						state.playing = false
--						state.record_time = state.record_time + delta
--						state.last_recording_time = state.last_recording_time + delta
--						if veh == FirstVeh then
--							FirstVehRecordTime = FirstVehRecordTime + delta
--						end
--						local pos = ENTITY.GET_ENTITY_COORDS(veh)
--						local rot = ENTITY.GET_ENTITY_ROTATION(veh, 5)
--						local vel = ENTITY.GET_ENTITY_VELOCITY(veh)
--						local ang = ENTITY.GET_ENTITY_ROTATION_VELOCITY(veh)
--						local model = ENTITY.GET_ENTITY_MODEL(veh)
--						frames[#frames + 1] = {
--							pos = pos,
--							rot = rot,
--							vel = vel,
--							ang = ang,
--							model = model,
--							time = state
--								.record_time
--						}
--						------------------------------------------------------- -- ⏪ REWIND (veículo focado) -------------------------------------------------------
--					elseif isFocused and IsRewindingV2 then
--						state.record_time = math.max(0, state.record_time - delta)
--						state.last_recording_time = math.max(0, state.last_recording_time - delta)
--						if veh == FirstVeh then
--							FirstVehRecordTime = math.max(0, FirstVehRecordTime - delta)
--						end
--						--if state.last_recording_time > 0 then
--						-- remove frames que ficaram "à frente" do tempo atual
--						local i = #frames
--						while i > 0 and frames[i].time > state.record_time do
--							table.remove(frames, i)
--							i = i - 1
--						end
--						--end -- aplica o último frame restante
--						if #frames > 0 then
--							local f = frames[#frames]
--							ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, f.pos.x, f.pos.y, f.pos.z)
--							ENTITY.SET_ENTITY_ROTATION(veh, f.rot.x, f.rot.y, f.rot.z, 5)
--							VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, math.sqrt(f.vel.x ^ 2 + f.vel.y ^ 2 + f.vel.z ^ 2))
--							ENTITY.SET_ENTITY_VELOCITY(veh, f.vel.x, f.vel.y, f.vel.z)
--							ENTITY.SET_ENTITY_ANGULAR_VELOCITY(veh, f.ang.x, f.ang.y, f.ang.z)
--						end ------------------------------------------------------- -- 🎞️ REPLAY (veículos não focados) -------------------------------------------------------
--					elseif not isFocused and #frames > 0 then
--						if state.replay_time == nil then
--							state.replay_time = 0
--						end
--						if SwitchRequestedV2 then
--							state.replay_time = math.max(0, state.record_time - state.last_recording_time)
--						end
--						if not IsRewindingV2 then
--							state.replay_time = state.replay_time + delta
--						else
--							state.replay_time = math.max(0, state.replay_time - delta)
--							--if VehicleStateV2[CurrentVehicleV2] and VehicleStateV2[CurrentVehicleV2].last_recording_time <= 0 then
--							-- state.replay_time = math.max(0, state.record_time - state.last_recording_time)
--							--end
--						end -- busca frames próximos
--						local f1, f2, interp = FindFrameForVehicleAtTime({
--							frames = frames,
--							record_time = state
--								.replay_time,
--							last_index = state.last_index
--						})
--						state.last_index = (f1 and f1) or state.last_index -- aplica
--						if f2 and frames[f2] then
--							local f = frames[f2]
--							if not IsRewindingV2 then
--								if SwitchRequestedV2 then
--									ENTITY.FREEZE_ENTITY_POSITION(veh, false)
--									ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, f.pos.x, f.pos.y, f.pos.z)
--									ENTITY.SET_ENTITY_ROTATION(veh, f.rot.x, f.rot.y, f.rot.z, 5)
--									VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, math.sqrt(f.vel.x ^ 2 + f.vel.y ^ 2 +
--										f.vel.z ^ 2))
--									ENTITY.SET_ENTITY_VELOCITY(veh, f.vel.x, f.vel.y, f.vel.z)
--									ENTITY.SET_ENTITY_ANGULAR_VELOCITY(veh, f.ang.x, f.ang.y, f.ang.z)
--								end
--								if f2 >= #frames then
--									ENTITY.FREEZE_ENTITY_POSITION(veh, true)
--								else
--									ENTITY.FREEZE_ENTITY_POSITION(veh, false) -- modo normal (suave)
--									SetEntitySpeedToCoord(veh, f.pos, 1.0, false, false, false, f.vel.x, f.vel.y, f.vel
--										.z, false, false, nil)
--									RotateEntityToTargetRotation(veh, f.rot, 5.0)
--								end
--							else
--								ENTITY.FREEZE_ENTITY_POSITION(veh, false) -- modo rewind (instantâneo)
--								ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh, f.pos.x, f.pos.y, f.pos.z)
--								ENTITY.SET_ENTITY_ROTATION(veh, f.rot.x, f.rot.y, f.rot.z, 5)
--								VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, math.sqrt(f.vel.x ^ 2 + f.vel.y ^ 2 + f.vel.z ^ 2))
--								ENTITY.SET_ENTITY_VELOCITY(veh, f.vel.x, f.vel.y, f.vel.z)
--								ENTITY.SET_ENTITY_ANGULAR_VELOCITY(veh, f.ang.x, f.ang.y, f.ang.z)
--							end
--						end
--					end
--					::continue::
--				end
--				SwitchRequestedV2 = false
--				SwitchFromRewind = false
--				Wait(0)
--			end ------------------------------------------------------- -- 💾 Salvamento ao sair -------------------------------------------------------
--			local id = 1
--			for veh, state in pairs(VehicleStateV2) do
--				if #state.frames > 0 then
--					local path = filesystem.scripts_dir() .. "Paths\\" .. FileNameForSave .. "_" .. id .. ".txt"
--					if EmptyRecord then
--						ClearFile(path)
--					end
--					local out = {}
--					for i, f in ipairs(state.frames) do
--						out[#out + 1] = ToTxt(f.pos, f.rot, f.vel, f.ang, f.time, f.model)
--					end
--					WriteFile(path, table.concat(out))
--					Print(("💾 V3: Saved PathV3_%d (%d frames)"):format(id, #state.frames))
--					id = id + 1
--				end
--			end
--			Print("🛑 Gravador V3 finalizado.")
--		end
--	end)



local FrameStartIndex = 1
menu.slider(SoloRecordingMenu, "Frame Start Index", { "setstartingframe" },
	"Useful to jump to a specific part of the replay.", 1, 50000000, 1, 1000, function(OnChange)
		FrameStartIndex = OnChange
	end)

local Model = "shinobi"
menu.text_input(SoloRecordingMenu, "Set Veh Model", { "setvehmodel" },
	"Vehicle model will be created to perform the replay.", function(OnChange)
		if STREAMING.IS_MODEL_VALID(joaat(OnChange)) then
			Model = OnChange
		end
	end)

local UseStoredVehicleModel = true
menu.toggle(SoloRecordingMenu, "Use Stored Vehicle Model", {}, "Use vehicle model hash if is stored in the replay file",
	function(toggle)
		UseStoredVehicleModel = toggle
	end, UseStoredVehicleModel)

local PedModel = "mp_m_bogdangoon"
menu.text_input(SoloRecordingMenu, "Set Ped Model", { "setpedmodel" }, "Ped model will be created inside vehicle.",
	function(OnChange)
		if STREAMING.IS_MODEL_VALID(joaat(OnChange)) then
			PedModel = OnChange
		end
	end)

local CreatePedToReplay = true
menu.toggle(SoloRecordingMenu, "Create Ped To Replay Vehicles", {}, "", function(toggle)
	CreatePedToReplay = toggle
end, CreatePedToReplay)

local ReplayTeleportMode = false
menu.toggle(SoloRecordingMenu, "Replay Teleport Mode", {}, "Use teleportation instead of velocity physics.",
	function(toggle)
		ReplayTeleportMode = toggle
	end, ReplayTeleportMode)

local WaitBeforeStartReplay = false
local UseMilisAdjustLoop = true
local Multiplayer_StartedFromScript = false
local StartedFromScript = false
local Advanced_StartedFromScript = false
local ReplayVehsT = {}
local StartReplay = false
local StartSelectedReplaysPTR = menu.toggle(SoloRecordingMenu, "Start Selected Replay", {}, "", function(toggle)
	StartReplay = toggle
	if StartReplay then
		for k, value in pairs(ReplaysToLoad) do
			ReplayVehsT[#ReplayVehsT + 1] = {
				VehHandle = 0,
				ModelHash = 0,
				Paths = GetVectorsTable(k, true, false),
				Index = 0,
				Blip = 0,
				StartTimer = 0,
				PedHandle = 0,
				PedBlip = 0,
				HasSetStartTimer = false,
				SteerMilis = 0,
				IsCargoPlane = false
			}
		end
		for k = 1, #ReplayVehsT do
			if ReplayVehsT[k].Paths ~= nil and ReplayVehsT[k].Paths[1] ~= nil then
				if not UseStoredVehicleModel then
					ReplayVehsT[k].Paths[1].ModelHash = joaat(Model)
				end
				ReplayVehsT[k].ModelHash = ReplayVehsT[k].Paths[1].ModelHash or joaat(Model)
				if ReplayVehsT[k].VehHandle == 0 then
					if not STREAMING.IS_MODEL_VALID(ReplayVehsT[k].ModelHash) then
						ReplayVehsT[k].ModelHash = joaat(Model)
					end
					ReplayVehsT[k].IsCargoPlane = ReplayVehsT[k].ModelHash == joaat("cargoplane") or
						ReplayVehsT[k].ModelHash == joaat("cargoplane2")
					STREAMING.REQUEST_MODEL(ReplayVehsT[k].ModelHash)
					while not STREAMING.HAS_MODEL_LOADED(ReplayVehsT[k].ModelHash) do
						Wait()
					end
					ReplayVehsT[k].VehHandle = GTA.SpawnVehicle(ReplayVehsT[k].ModelHash, ReplayVehsT[k].Paths[1].x,
						ReplayVehsT[k].Paths[1].y, ReplayVehsT[k].Paths[1].z, ReplayVehsT[k].Paths[1].RotZ, true, false)
					--VEHICLE.CREATE_VEHICLE(ReplayVehsT[k].ModelHash, ReplayVehsT[k].Paths[1]
					--.x, ReplayVehsT[k].Paths[1].y, ReplayVehsT[k].Paths[1].z, ReplayVehsT[k].Paths[1].RotZ, true, true,
					--	false)
					if ReplayVehsT[k].VehHandle ~= 0 then
						STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ReplayVehsT[k].ModelHash)
						ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ReplayVehsT[k].VehHandle, false, true)
						entities.set_can_migrate(ReplayVehsT[k].VehHandle, false)
						ENTITY.SET_ENTITY_INVINCIBLE(ReplayVehsT[k].VehHandle, true)
						NETWORK.NETWORK_SET_ENTITY_CAN_BLEND(ReplayVehsT[k].VehHandle, true)
						ReplayVehsT[k].Blip = HUD.ADD_BLIP_FOR_ENTITY(ReplayVehsT[k].VehHandle)
						HUD.SET_BLIP_COLOUR(ReplayVehsT[k].Blip, 3)
						UpgradeVehicle(ReplayVehsT[k].VehHandle, true, true, true)
						if CreatePedToReplay then
							if VEHICLE.IS_VEHICLE_DRIVEABLE(ReplayVehsT[k].VehHandle, false) then
								STREAMING.REQUEST_MODEL(joaat(PedModel))
								while not STREAMING.HAS_MODEL_LOADED(joaat(PedModel)) do
									Wait()
								end
								ReplayVehsT[k].PedHandle = GTA.CreatePed(joaat(PedModel), 28, ReplayVehsT[k].Paths[1].x,
									ReplayVehsT[k].Paths[1].y, ReplayVehsT[k].Paths[1].z, ReplayVehsT[k].Paths[1].RotZ,
									true, false)
								--PED.CREATE_PED_INSIDE_VEHICLE(ReplayVehsT[k].VehHandle, 28,
								--	joaat(PedModel), -1, true, true)
								if ReplayVehsT[k].PedHandle ~= 0 then
									PED.SET_PED_INTO_VEHICLE(ReplayVehsT[k].PedHandle, ReplayVehsT[k].VehHandle, -1)
									STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(joaat(PedModel))
									ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ReplayVehsT[k].PedHandle, false, true)
									entities.set_can_migrate(ReplayVehsT[k].PedHandle, false)
									ENTITY.SET_ENTITY_INVINCIBLE(ReplayVehsT[k].PedHandle, true)
									NETWORK.NETWORK_SET_ENTITY_CAN_BLEND(ReplayVehsT[k].PedHandle, true)
									ReplayVehsT[k].PedBlip = HUD.ADD_BLIP_FOR_ENTITY(ReplayVehsT[k].PedHandle)
									HUD.SET_BLIP_COLOUR(ReplayVehsT[k].PedBlip, 1)
									HUD.SHOW_HEADING_INDICATOR_ON_BLIP(ReplayVehsT[k].PedBlip, true)
									PED.SET_PED_COMBAT_ATTRIBUTES(ReplayVehsT[k].PedHandle, 3, false)
									PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(ReplayVehsT[k].PedHandle, 1)
								else
									STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(joaat(PedModel))
								end
							end
						end
						ENTITY.FREEZE_ENTITY_POSITION(ReplayVehsT[k].VehHandle, true)
						ENTITY.SET_ENTITY_COORDS(ReplayVehsT[k].VehHandle, ReplayVehsT[k].Paths[1].x,
							ReplayVehsT[k].Paths[1].y, ReplayVehsT[k].Paths[1].z)
						ENTITY.SET_ENTITY_ROTATION(ReplayVehsT[k].VehHandle, ReplayVehsT[k].Paths[1].RotX,
							ReplayVehsT[k].Paths[1].RotY, ReplayVehsT[k].Paths[1].RotZ, 5)
					else
						STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ReplayVehsT[k].ModelHash)
					end
				end
			end
		end
		local LastEnt = 0
		local WaitWasEnabled = false
		while WaitBeforeStartReplay do
			WaitWasEnabled = true
			--if LastEnt == 0 then
			local PVeh = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
			if PVeh ~= 0 then
				local NewLastEnt = ENTITY._GET_LAST_ENTITY_HIT_BY_ENTITY(PVeh)
				if NewLastEnt ~= 0 then
					LastEnt = NewLastEnt
				end
			end
			--end
			Wait()
		end
		GlobalReplayTime = 0
		local StartTimer = MISC.GET_GAME_TIMER()
		while StartReplay do
			--VEHICLE.SET_VEHICLE_DOOR_CONTROL(Veh, 2, 360, 360.0)
			local GameTimer = MISC.GET_GAME_TIMER()
			if StartedFromScript then
				StartedFromScript = false
				menu.set_value(StartRecordingPTR, true)
			end
			if Multiplayer_StartedFromScript then
				Multiplayer_StartedFromScript = false
				menu.set_value(MultiplayerRecordingPTR, true)
			end
			if Advanced_StartedFromScript then
				Advanced_StartedFromScript = false
				menu.set_value(Advanced_StartRecordingPTR, true)
			end
			local DeltaTime = MISC.GET_FRAME_TIME() * 1000.0 -- DeltaTime em milissegundos

			if not IsRewinding then
				-- Avançar normalmente
				GlobalReplayTime = GlobalReplayTime + (DeltaTime * ReplaySpeed)
			else
				-- Rebobinar
				GlobalReplayTime = GlobalReplayTime - (DeltaTime * ReplaySpeed)
				if GlobalReplayTime < 0 then
					GlobalReplayTime = 0 -- não pode ir antes do início
				end
			end
			for k = 1, #ReplayVehsT do
				local Veh = ReplayVehsT[k].VehHandle
				if Veh ~= 0 and ENTITY.DOES_ENTITY_EXIST(Veh) then
					ENTITY.FREEZE_ENTITY_POSITION(ReplayVehsT[k].VehHandle, false)
					if ReplayVehsT[k].Index == 0 then
						ReplayVehsT[k].Index = FrameStartIndex
						local PathsData = ReplayVehsT[k].Paths[FrameStartIndex] or ReplayVehsT[k].Paths[1]
						ENTITY.SET_ENTITY_COORDS(Veh, PathsData.x, PathsData.y, PathsData.z)
						ENTITY.SET_ENTITY_ROTATION(Veh, PathsData.RotX, PathsData.RotY, PathsData.RotZ, 5)
						if not ReplayVehsT[k].HasSetStartTimer then
							ReplayVehsT[k].HasSetStartTimer = true
							ReplayVehsT[k].StartTimer = StartTimer
						else
							ReplayVehsT[k].StartTimer = GameTimer
						end
						if FrameStartIndex > 1 then
							if ReplayVehsT[k].Index > 0 and ReplayVehsT[k].Index < #ReplayVehsT[k].Paths then
								local Frame1, Frame2 = ReplayVehsT[k].Paths[ReplayVehsT[k].Index],
									ReplayVehsT[k].Paths[ReplayVehsT[k].Index + 1]
								ReplayVehsT[k].StartTimer = StartTimer -
									(Frame2.CurGameTime - ReplayVehsT[k].Paths[1].CurGameTime)
								--Print("ReplayVehsT[k].StartTimer "..ReplayVehsT[k].StartTimer.." StartTimer "..StartTimer)
							end
						end
					end
					if ReplayVehsT[k].Index > 0 and ReplayVehsT[k].Index < #ReplayVehsT[k].Paths then
						UpdateReplayIndexByTime(ReplayVehsT[k])

						--directx.draw_text(0.5, 0.5, "CurrentTime "..CurrentTime, ALIGN_CENTRE, 1.0, {r = 0.0, g = 1.0 , b = 1.0, a = 1.0}, false)
						--directx.draw_text(0.5, 0.6, "Frame2.CurGameTime - ReplayVehsT[k].Paths[1].CurGameTime "..Frame2.CurGameTime - ReplayVehsT[k].Paths[1].CurGameTime, ALIGN_CENTRE, 1.0, {r = 0.0, g = 1.0 , b = 1.0, a = 1.0}, false)
						local Coord = {
							x = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].x,
							y = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].y,
							z = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].z
						}
						local Rot = {
							x = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].RotX,
							y = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].RotY,
							z = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].RotZ
						}
						local Vel = {
							x = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].VelX,
							y = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].VelY,
							z = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].VelZ
						}
						local AngVel = {
							x = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].AngVelX,
							y = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].AngVelY,
							z = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].AngVelZ
						}
						if ReplayVehsT[k].IsCargoPlane then
							VEHICLE.SET_DOOR_ALLOWED_TO_BE_BROKEN_OFF(Veh, 2, false)
							VEHICLE.SET_VEHICLE_DOOR_CONTROL(Veh, 2, 180.0, 180.0)
							if not VEHICLE.IS_VEHICLE_DOOR_DAMAGED(Veh, 4) then
								VEHICLE.SET_VEHICLE_DOOR_BROKEN(Veh, 4, false)
							end
						end
						--VEHICLE.SET_VEHICLE_IS_RACING(Veh, true)
						local Steering = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].Steering
						--VEHICLE.SET_VEHICLE_STEER_BIAS(Veh, Steering)
						if ReplayVehsT[k].PedHandle ~= 0 and ENTITY.DOES_ENTITY_EXIST(ReplayVehsT[k].PedHandle) then
							PED.SET_DRIVER_RACING_MODIFIER(ReplayVehsT[k].PedHandle, 1.0)
							if GameTimer > ReplayVehsT[k].SteerMilis + 1000 then
								ReplayVehsT[k].SteerMilis = GameTimer
								local Offset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(Veh, -Steering * 3.0, 0.0,
									0.0)
								TASK.TASK_VEHICLE_DRIVE_TO_COORD(ReplayVehsT[k].PedHandle, Veh, Offset.x, Offset.y,
									Offset.z, 180.0, 1, ENTITY.GET_ENTITY_MODEL(Veh), 1, 0.01, 40000.0)
							else
								ReplayVehsT[k].SteerMilis = 0
							end
						end
						if not IsRewinding then
							local CurCoord = ENTITY.GET_ENTITY_COORDS(Veh)
							if not ReplayTeleportMode or DistanceBetween(CurCoord.x, CurCoord.y, CurCoord.z, Coord.x, Coord.y, Coord.z) > 50.0 then
								SetEntitySpeedToCoord(Veh, Coord, 1.0,
									false, false, false, Vel.x, Vel.y, Vel.z, false, false, nil)
								RotateEntityToTargetRotation(Veh, Rot, 10.0)
							else
								ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Veh, Coord.x, Coord.y, Coord.z)
								ENTITY.SET_ENTITY_ROTATION(Veh, Rot.x, Rot.y, Rot.z, 5)
								VEHICLE.SET_VEHICLE_FORWARD_SPEED(Veh,
									math.sqrt(Vel.x ^ 2 + Vel.y ^ 2 + Vel.z ^ 2))
								ENTITY.SET_ENTITY_VELOCITY(Veh, Vel.x, Vel.y, Vel.z)
								ENTITY.SET_ENTITY_ANGULAR_VELOCITY(Veh, AngVel.x, AngVel.y, AngVel.z)
							end
						else
							ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Veh, Coord.x, Coord.y, Coord.z)
							ENTITY.SET_ENTITY_ROTATION(Veh, Rot.x, Rot.y, Rot.z, 5)
							VEHICLE.SET_VEHICLE_FORWARD_SPEED(Veh,
								math.sqrt(Vel.x ^ 2 + Vel.y ^ 2 + Vel.z ^ 2))
							ENTITY.SET_ENTITY_VELOCITY(Veh, Vel.x, Vel.y, Vel.z)
							ENTITY.SET_ENTITY_ANGULAR_VELOCITY(Veh, AngVel.x, AngVel.y, AngVel.z)
						end
					else
						ReplayVehsT[k].Index = 0
						--ReplayVehsT[k].StartTimer = GameTimer
						--StartTimer = GameTimer
					end
				end
			end
			if WaitWasEnabled then
				local PVeh = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
				if PVeh ~= 0 then
					if LastEnt == 0 then
						LastEnt = ENTITY._GET_LAST_ENTITY_HIT_BY_ENTITY(PVeh)
					end
					if LastEnt ~= 0 then
						local CurVel = ENTITY.GET_ENTITY_VELOCITY(LastEnt)
						ENTITY.SET_ENTITY_VELOCITY(PVeh, CurVel.x, CurVel.y, CurVel.z)
						WaitWasEnabled = false
					end
				end
			end
			Wait()
		end
	else
		for k = 1, #ReplayVehsT do
			if ReplayVehsT[k].VehHandle ~= 0 and ENTITY.DOES_ENTITY_EXIST(ReplayVehsT[k].VehHandle) then
				if ReplayVehsT[k].Blip ~= 0 then
					util.remove_blip(ReplayVehsT[k].Blip)
				end
				entities.delete_by_handle(ReplayVehsT[k].VehHandle)
			end
			if ReplayVehsT[k].PedHandle ~= 0 and ENTITY.DOES_ENTITY_EXIST(ReplayVehsT[k].PedHandle) then
				if ReplayVehsT[k].PedBlip ~= 0 then
					util.remove_blip(ReplayVehsT[k].PedBlip)
				end
				entities.delete_by_handle(ReplayVehsT[k].PedHandle)
			end
		end
		ReplayVehsT = {}
	end
end)

local RecordAndReplays = false
local StartRecordingAndReplays = menu.toggle(SoloRecordingMenu, "Start Recording + Replays", {}, "", function(toggle)
	RecordAndReplays = toggle
	if RecordAndReplays then
		for k, value in pairs(ReplaysToLoad) do
			ReplayVehsT[#ReplayVehsT + 1] = {
				VehHandle = 0,
				ModelHash = 0,
				Paths = GetVectorsTable(k, true, false),
				Index = 0,
				Blip = 0,
				StartTimer = 0,
				PedHandle = 0,
				PedBlip = 0,
				HasSetStartTimer = false,
				SteerMilis = 0,
				IsCargoPlane = false
			}
		end
		for k = 1, #ReplayVehsT do
			if ReplayVehsT[k].Paths ~= nil and ReplayVehsT[k].Paths[1] ~= nil then
				if not UseStoredVehicleModel then
					ReplayVehsT[k].Paths[1].ModelHash = joaat(Model)
				end
				ReplayVehsT[k].ModelHash = ReplayVehsT[k].Paths[1].ModelHash or joaat(Model)
				if ReplayVehsT[k].VehHandle == 0 then
					if not STREAMING.IS_MODEL_VALID(ReplayVehsT[k].ModelHash) then
						ReplayVehsT[k].ModelHash = joaat(Model)
					end
					ReplayVehsT[k].IsCargoPlane = ReplayVehsT[k].ModelHash == joaat("cargoplane") or
						ReplayVehsT[k].ModelHash == joaat("cargoplane2")
					STREAMING.REQUEST_MODEL(ReplayVehsT[k].ModelHash)
					while not STREAMING.HAS_MODEL_LOADED(ReplayVehsT[k].ModelHash) do
						Wait()
					end
					ReplayVehsT[k].VehHandle = VEHICLE.CREATE_VEHICLE(ReplayVehsT[k].ModelHash, ReplayVehsT[k].Paths[1]
						.x, ReplayVehsT[k].Paths[1].y, ReplayVehsT[k].Paths[1].z, ReplayVehsT[k].Paths[1].RotZ, true,
						true,
						false)
					if ReplayVehsT[k].VehHandle ~= 0 then
						STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ReplayVehsT[k].ModelHash)
						ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ReplayVehsT[k].VehHandle, false, true)
						entities.set_can_migrate(ReplayVehsT[k].VehHandle, false)
						ENTITY.SET_ENTITY_INVINCIBLE(ReplayVehsT[k].VehHandle, true)
						NETWORK.NETWORK_SET_ENTITY_CAN_BLEND(ReplayVehsT[k].VehHandle, true)
						ReplayVehsT[k].Blip = HUD.ADD_BLIP_FOR_ENTITY(ReplayVehsT[k].VehHandle)
						HUD.SET_BLIP_COLOUR(ReplayVehsT[k].Blip, 3)
						UpgradeVehicle(ReplayVehsT[k].VehHandle, true, true, true)
						if CreatePedToReplay then
							if VEHICLE.IS_VEHICLE_DRIVEABLE(ReplayVehsT[k].VehHandle, false) then
								STREAMING.REQUEST_MODEL(joaat(PedModel))
								while not STREAMING.HAS_MODEL_LOADED(joaat(PedModel)) do
									Wait()
								end
								ReplayVehsT[k].PedHandle = PED.CREATE_PED_INSIDE_VEHICLE(ReplayVehsT[k].VehHandle, 28,
									joaat(PedModel), -1, true, true)
								if ReplayVehsT[k].PedHandle ~= 0 then
									STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(joaat(PedModel))
									ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ReplayVehsT[k].PedHandle, false, true)
									entities.set_can_migrate(ReplayVehsT[k].PedHandle, false)
									ENTITY.SET_ENTITY_INVINCIBLE(ReplayVehsT[k].PedHandle, true)
									NETWORK.NETWORK_SET_ENTITY_CAN_BLEND(ReplayVehsT[k].PedHandle, true)
									ReplayVehsT[k].PedBlip = HUD.ADD_BLIP_FOR_ENTITY(ReplayVehsT[k].PedHandle)
									HUD.SET_BLIP_COLOUR(ReplayVehsT[k].PedBlip, 1)
									HUD.SHOW_HEADING_INDICATOR_ON_BLIP(ReplayVehsT[k].PedBlip, true)
									PED.SET_PED_COMBAT_ATTRIBUTES(ReplayVehsT[k].PedHandle, 3, false)
									PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(ReplayVehsT[k].PedHandle, 1)
								else
									STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(joaat(PedModel))
								end
							end
						end
						ENTITY.FREEZE_ENTITY_POSITION(ReplayVehsT[k].VehHandle, true)
						ENTITY.SET_ENTITY_COORDS(ReplayVehsT[k].VehHandle, ReplayVehsT[k].Paths[1].x,
							ReplayVehsT[k].Paths[1].y, ReplayVehsT[k].Paths[1].z)
						ENTITY.SET_ENTITY_ROTATION(ReplayVehsT[k].VehHandle, ReplayVehsT[k].Paths[1].RotX,
							ReplayVehsT[k].Paths[1].RotY, ReplayVehsT[k].Paths[1].RotZ, 5)
					else
						STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(ReplayVehsT[k].ModelHash)
					end
				end
			end
		end
		local LastEnt = 0
		local WaitWasEnabled = false
		while WaitBeforeStartReplay do
			WaitWasEnabled = true
			--if LastEnt == 0 then
			local PVeh = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
			if PVeh ~= 0 then
				local NewLastEnt = ENTITY._GET_LAST_ENTITY_HIT_BY_ENTITY(PVeh)
				if NewLastEnt ~= 0 then
					LastEnt = NewLastEnt
				end
			end
			--end
			Wait()
		end
		GlobalReplayTime = 0

		if EmptyRecord then
			ClearFile(PathDirSaveds .. FileNameForSave .. ".txt")
		end
		local StartedTime = MISC.GET_GAME_TIMER()
		local LastTime = 0
		local PausedTimeStart = 0
		local IsPaused = false
		local LastValidTime = 0

		local StartTimer = StartedTime
		while RecordAndReplays do
			local PlayerPed = PLAYER.PLAYER_PED_ID()
			local Veh = PED.GET_VEHICLE_PED_IS_IN(PlayerPed, true)
			local GameTimer = MISC.GET_GAME_TIMER()

			PAD.DISABLE_CONTROL_ACTION(0, 75)
			PAD.DISABLE_CONTROL_ACTION(0, 99)
			local ExitPressed = PAD.IS_DISABLED_CONTROL_PRESSED(0, 75) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 99)

			if Veh ~= 0 then
				if ExitPressed then
					if not IsPaused then
						IsPaused = true
						PausedTimeStart = GameTimer
					end

					-- Rebobinar: remover último frame
					if #RecordT > 0 then
						table.remove(RecordT, #RecordT)

						-- Atualiza o LastValidTime
						if #RecordT > 0 then
							local LastFrame = GetVectorsFromIndex(RecordT[#RecordT])
							LastValidTime = LastFrame.CurGameTime
							ENTITY.SET_ENTITY_COORDS(Veh, LastFrame.x, LastFrame.y, LastFrame.z, false, false, true)
							ENTITY.SET_ENTITY_ROTATION(Veh, LastFrame.RotX, LastFrame.RotY, LastFrame.RotZ, 5)
							ENTITY.SET_ENTITY_VELOCITY(Veh, LastFrame.VelX, LastFrame.VelY, LastFrame.VelZ)
							ENTITY.SET_ENTITY_ANGULAR_VELOCITY(Veh, LastFrame.AngVelX, LastFrame.AngVelY,
								LastFrame.AngVelZ)
							VEHICLE.SET_VEHICLE_FORWARD_SPEED(Veh,
								math.sqrt(LastFrame.VelX ^ 2 + LastFrame.VelY ^ 2 + LastFrame.VelZ ^ 2))
						else
							LastValidTime = 0
						end
					end
				else
					if IsPaused then
						-- Terminou rebobinamento
						local GameTimerNow = MISC.GET_GAME_TIMER()

						-- ⚡ Aqui a correção real:
						StartedTime = GameTimerNow - LastValidTime

						IsPaused = false
					end

					-- Gravar normalmente
					local Elapsed
					if IsRewinding then
						Elapsed = GlobalReplayTime
					else
						Elapsed = GlobalReplayTime
					end

					LastTime = Elapsed
					--Global_StartedTime = StartedTime

					local Pos = ENTITY.GET_ENTITY_COORDS(Veh)
					local Rot = ENTITY.GET_ENTITY_ROTATION(Veh, 5)
					local Vel = ENTITY.GET_ENTITY_VELOCITY(Veh)
					local AngVel = ENTITY.GET_ENTITY_ROTATION_VELOCITY(Veh)
					local VehModel = ENTITY.GET_ENTITY_MODEL(Veh)
					local BoneID = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(Veh, "steeringwheel")
					local Steering = 0.0
					if BoneID ~= 0 then
						local SteeringRot = ENTITY.GET_ENTITY_BONE_OBJECT_ROTATION(Veh, BoneID)
						SteeringRot:normalise()
						Steering = -SteeringRot.y
					end

					RecordT[#RecordT + 1] = ToTxt(Pos, Rot, Vel, AngVel, Elapsed, VehModel, Steering)
				end
			end
			IsRewinding = IsPaused
			-- Debug Visual
			--directx.draw_text(0.5, 0.55, "GameTimer "..GameTimer, ALIGN_CENTRE, 1.0, {r = 0.0, g = 1.0 , b = 1.0, a = 1.0}, false)
			--directx.draw_text(0.5, 0.6, "StartedTime "..StartedTime, ALIGN_CENTRE, 1.0, {r = 0.0, g = 1.0 , b = 1.0, a = 1.0}, false)
			--directx.draw_text(0.5, 0.65, "LastTime "..LastTime, ALIGN_CENTRE, 1.0, {r = 0.0, g = 1.0 , b = 1.0, a = 1.0}, false)
			--VEHICLE.SET_VEHICLE_DOOR_CONTROL(Veh, 2, 360, 360.0)
			if StartedFromScript then
				StartedFromScript = false
				menu.set_value(StartRecordingPTR, true)
			end
			if Multiplayer_StartedFromScript then
				Multiplayer_StartedFromScript = false
				menu.set_value(MultiplayerRecordingPTR, true)
			end
			if Advanced_StartedFromScript then
				Advanced_StartedFromScript = false
				menu.set_value(Advanced_StartRecordingPTR, true)
			end
			local DeltaTime = MISC.GET_FRAME_TIME() * 1000.0 -- DeltaTime em milissegundos

			if not IsRewinding then
				-- Avançar normalmente
				GlobalReplayTime = GlobalReplayTime + (DeltaTime * ReplaySpeed)
			else
				-- Rebobinar
				GlobalReplayTime = GlobalReplayTime - (DeltaTime * ReplaySpeed)
				if GlobalReplayTime < 0 then
					GlobalReplayTime = 0 -- não pode ir antes do início
				end
			end
			for k = 1, #ReplayVehsT do
				local Veh = ReplayVehsT[k].VehHandle
				if Veh ~= 0 and ENTITY.DOES_ENTITY_EXIST(Veh) then
					ENTITY.FREEZE_ENTITY_POSITION(ReplayVehsT[k].VehHandle, false)
					if ReplayVehsT[k].Index == 0 then
						ReplayVehsT[k].Index = FrameStartIndex
						local PathsData = ReplayVehsT[k].Paths[FrameStartIndex] or ReplayVehsT[k].Paths[1]
						ENTITY.SET_ENTITY_COORDS(Veh, PathsData.x, PathsData.y, PathsData.z)
						ENTITY.SET_ENTITY_ROTATION(Veh, PathsData.RotX, PathsData.RotY, PathsData.RotZ, 5)
						if not ReplayVehsT[k].HasSetStartTimer then
							ReplayVehsT[k].HasSetStartTimer = true
							ReplayVehsT[k].StartTimer = StartTimer
						else
							ReplayVehsT[k].StartTimer = GameTimer
						end
						if FrameStartIndex > 1 then
							if ReplayVehsT[k].Index > 0 and ReplayVehsT[k].Index < #ReplayVehsT[k].Paths then
								local Frame1, Frame2 = ReplayVehsT[k].Paths[ReplayVehsT[k].Index],
									ReplayVehsT[k].Paths[ReplayVehsT[k].Index + 1]
								ReplayVehsT[k].StartTimer = StartTimer -
									(Frame2.CurGameTime - ReplayVehsT[k].Paths[1].CurGameTime)
								--Print("ReplayVehsT[k].StartTimer "..ReplayVehsT[k].StartTimer.." StartTimer "..StartTimer)
							end
						end
					end
					if ReplayVehsT[k].Index > 0 and ReplayVehsT[k].Index < #ReplayVehsT[k].Paths then
						UpdateReplayIndexByTime(ReplayVehsT[k])

						--directx.draw_text(0.5, 0.5, "CurrentTime "..CurrentTime, ALIGN_CENTRE, 1.0, {r = 0.0, g = 1.0 , b = 1.0, a = 1.0}, false)
						--directx.draw_text(0.5, 0.6, "Frame2.CurGameTime - ReplayVehsT[k].Paths[1].CurGameTime "..Frame2.CurGameTime - ReplayVehsT[k].Paths[1].CurGameTime, ALIGN_CENTRE, 1.0, {r = 0.0, g = 1.0 , b = 1.0, a = 1.0}, false)
						local Coord = {
							x = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].x,
							y = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].y,
							z = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].z
						}
						local Rot = {
							x = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].RotX,
							y = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].RotY,
							z = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].RotZ
						}
						local Vel = {
							x = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].VelX,
							y = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].VelY,
							z = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].VelZ
						}
						local AngVel = {
							x = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].AngVelX,
							y = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].AngVelY,
							z = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].AngVelZ
						}
						if ReplayVehsT[k].IsCargoPlane then
							VEHICLE.SET_DOOR_ALLOWED_TO_BE_BROKEN_OFF(Veh, 2, false)
							VEHICLE.SET_VEHICLE_DOOR_CONTROL(Veh, 2, 180.0, 180.0)
							if not VEHICLE.IS_VEHICLE_DOOR_DAMAGED(Veh, 4) then
								VEHICLE.SET_VEHICLE_DOOR_BROKEN(Veh, 4, false)
							end
						end
						--VEHICLE.SET_VEHICLE_IS_RACING(Veh, true)
						local Steering = ReplayVehsT[k].Paths[ReplayVehsT[k].Index].Steering
						--VEHICLE.SET_VEHICLE_STEER_BIAS(Veh, Steering)
						if ReplayVehsT[k].PedHandle ~= 0 and ENTITY.DOES_ENTITY_EXIST(ReplayVehsT[k].PedHandle) then
							PED.SET_DRIVER_RACING_MODIFIER(ReplayVehsT[k].PedHandle, 1.0)
							if GameTimer > ReplayVehsT[k].SteerMilis + 1000 then
								ReplayVehsT[k].SteerMilis = GameTimer
								local Offset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(Veh, -Steering * 3.0, 0.0,
									0.0)
								TASK.TASK_VEHICLE_DRIVE_TO_COORD(ReplayVehsT[k].PedHandle, Veh, Offset.x, Offset.y,
									Offset.z, 180.0, 1, ENTITY.GET_ENTITY_MODEL(Veh), 1, 0.01, 40000.0)
							else
								ReplayVehsT[k].SteerMilis = 0
							end
						end
						if not IsRewinding then
							if not ReplayTeleportMode then
								SetEntitySpeedToCoord(Veh, Coord, 1.0,
									false, false, false, Vel.x, Vel.y, Vel.z, false, false, nil)
								RotateEntityToTargetRotation(Veh, Rot, 10.0)
							else
								ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Veh, Coord.x, Coord.y, Coord.z)
								ENTITY.SET_ENTITY_ROTATION(Veh, Rot.x, Rot.y, Rot.z, 5)
								ENTITY.SET_ENTITY_VELOCITY(Veh, Vel.x, Vel.y, Vel.z)
								ENTITY.SET_ENTITY_ANGULAR_VELOCITY(Veh, AngVel.x, AngVel.y, AngVel.z)
							end
						else
							ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Veh, Coord.x, Coord.y, Coord.z)
							ENTITY.SET_ENTITY_ROTATION(Veh, Rot.x, Rot.y, Rot.z, 5)
							ENTITY.SET_ENTITY_VELOCITY(Veh, Vel.x, Vel.y, Vel.z)
							ENTITY.SET_ENTITY_ANGULAR_VELOCITY(Veh, AngVel.x, AngVel.y, AngVel.z)
						end
					else
						ReplayVehsT[k].Index = 0
						--ReplayVehsT[k].StartTimer = GameTimer
						--StartTimer = GameTimer
					end
				end
			end
			if WaitWasEnabled then
				local PVeh = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), true)
				if PVeh ~= 0 then
					if LastEnt == 0 then
						LastEnt = ENTITY._GET_LAST_ENTITY_HIT_BY_ENTITY(PVeh)
					end
					if LastEnt ~= 0 then
						local CurVel = ENTITY.GET_ENTITY_VELOCITY(LastEnt)
						ENTITY.SET_ENTITY_VELOCITY(PVeh, CurVel.x, CurVel.y, CurVel.z)
						WaitWasEnabled = false
					end
				end
			end
			Wait()
		end

		-- Salvar no final
		local BigText = table.concat(RecordT)
		WriteFile(PathDirSaveds .. FileNameForSave .. ".txt", BigText)
		RecordT = {}
	else
		for k = 1, #ReplayVehsT do
			if ReplayVehsT[k].VehHandle ~= 0 and ENTITY.DOES_ENTITY_EXIST(ReplayVehsT[k].VehHandle) then
				if ReplayVehsT[k].Blip ~= 0 then
					util.remove_blip(ReplayVehsT[k].Blip)
				end
				entities.delete_by_handle(ReplayVehsT[k].VehHandle)
			end
			if ReplayVehsT[k].PedHandle ~= 0 and ENTITY.DOES_ENTITY_EXIST(ReplayVehsT[k].PedHandle) then
				if ReplayVehsT[k].PedBlip ~= 0 then
					util.remove_blip(ReplayVehsT[k].PedBlip)
				end
				entities.delete_by_handle(ReplayVehsT[k].PedHandle)
			end
		end
		ReplayVehsT = {}
	end
end)

function UpdateReplayIndexByTime(vehicleReplay)
	local Paths = vehicleReplay.Paths
	local StartFrameTime = Paths[1].CurGameTime

	-- Atualiza o índice com base no GlobalReplayTime
	while vehicleReplay.Index < (#Paths - 1) and
		GlobalReplayTime > (Paths[vehicleReplay.Index + 1].CurGameTime - StartFrameTime) do
		vehicleReplay.Index = vehicleReplay.Index + 1
	end

	while vehicleReplay.Index > 1 and
		GlobalReplayTime < (Paths[vehicleReplay.Index].CurGameTime - StartFrameTime) do
		vehicleReplay.Index = vehicleReplay.Index - 1
	end
end

function UpdateReplayIndexByTime2(vehicleReplay, CurTime)
	local Paths = vehicleReplay.Paths
	local StartFrameTime = Paths[1].CurGameTime

	-- Atualiza o índice com base no GlobalReplayTime
	while vehicleReplay.Index < (#Paths - 1) and
		CurTime > (Paths[vehicleReplay.Index + 1].CurGameTime - StartFrameTime) do
		vehicleReplay.Index = vehicleReplay.Index + 1
	end

	while vehicleReplay.Index > 1 and
		CurTime < (Paths[vehicleReplay.Index].CurGameTime - StartFrameTime) do
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

--function GetVectorsTable(FileName, DelayLoad, GetOnlyFirstData)
--	local MaxIt = 10000
--	local VectorTable = {}
--	local Vectors = file_lines(FileName)
--	local It = 0
--	for i = 1, #Vectors do
--		local Number = split_number(Vectors[i])
--		VectorTable[#VectorTable + 1] = {
--			x = Number[1],
--			y = Number[2],
--			z = Number[3],
--			RotX = Number[4],
--			RotY = Number[5],
--			RotZ = Number[6],
--			VelX = Number[7],
--			VelY = Number[8],
--			VelZ = Number[9],
--			AngVelX = Number[10],
--			AngVelY = Number[11],
--			AngVelZ = Number[12],
--			CurGameTime = Number[13],
--			ModelHash = Number[14]
--		}
--		if DelayLoad then
--			It = It + 1
--			if It > MaxIt then
--				It = 0
--				Wait()
--			end
--		end
--		if GetOnlyFirstData then
--			break
--		end
--	end
--	return VectorTable
--end

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
		" " .. CurGameTimer .. " " .. VehModel .. " " .. (Steering or 0.0) .. "\n"
end

function RequestModel(ModelHash)
	if not STREAMING.HAS_MODEL_LOADED(ModelHash) then
		STREAMING.REQUEST_MODEL(ModelHash)
		while not STREAMING.HAS_MODEL_LOADED(ModelHash) do
			Wait()
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

function SplitGlobals(GlobalString)
	local String = GlobalString
	local Value = String:gsub("%[(.-)]", "+1")
	local NewValue = Value:gsub("%a", "")
	local NewValue2 = NewValue:gsub("._", "+")
	local NewValue3 = NewValue2:gsub("_", "")
	local _Text, SymbolCount = NewValue3:gsub("+", "")
	local PatternCount = "(%d+)"
	for i = 1, SymbolCount do
		PatternCount = PatternCount .. "+(%d+)"
	end
	local Global, Global2, Global3, Global4, Global5, Global6, Global7 = NewValue3:match(PatternCount)
	local GlobalNumber = 0
	if Global ~= nil then
		GlobalNumber = GlobalNumber + tonumber(Global)
	end
	if Global2 ~= nil then
		GlobalNumber = GlobalNumber + tonumber(Global2)
	end
	if Global3 ~= nil then
		GlobalNumber = GlobalNumber + tonumber(Global3)
	end
	if Global4 ~= nil then
		GlobalNumber = GlobalNumber + tonumber(Global4)
	end
	if Global5 ~= nil then
		GlobalNumber = GlobalNumber + tonumber(Global5)
	end
	if Global6 ~= nil then
		GlobalNumber = GlobalNumber + tonumber(Global6)
	end
	if Global7 ~= nil then
		GlobalNumber = GlobalNumber + tonumber(Global7)
	end
	return GlobalNumber
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

--local ScriptedToolsMenu = menu.list(menu.my_root(), "Scripted Tools", {}, "")

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

local GameModesMenu = menu.list(menu.my_root(), "Game Modes", {}, "")

local CargoPlaneTest = false
menu.toggle(GameModesMenu, "Cargo Plane Test", {}, "", function(toggle)
	CargoPlaneTest = toggle
	if CargoPlaneTest then
		local Vehs = {}
		local Objs = {}
		local Props = {}
		local VehsLocal = SplitGlobals("uLocal_23609.f_834.f_81")
		local ObjsLocal = SplitGlobals("uLocal_23609.f_834.f_147[i]")
		local PropsLocal = SplitGlobals("uLocal_7710[i]")
		local PropsNum = SplitGlobals("Global_5242880")
		local PropsNumPtr = ScriptGlobal.GetPtr(PropsNum)
		local HostMilis = 0
		local OffsetsNum = 0
		local SavedAttach = false
		local SaveMS = MISC.GET_GAME_TIMER() + 3000
		while CargoPlaneTest do
			if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("fm_mission_controller")) > 0 then
				local IsHost = false
				Script.ExecuteAsScript("fm_mission_controller", function()
					IsHost = NETWORK.NETWORK_IS_HOST_OF_THIS_SCRIPT()
				end)
				local GameTimer = MISC.GET_GAME_TIMER()
				if not IsHost then
					if GameTimer > HostMilis then
						HostMilis = GameTimer + 1000
						GTA.ForceScriptHost(Utils.Joaat("fm_mission_controller"))
					end
				end
				for k = 1, 1 do
					if Vehs[k] == nil then
						local Handle, Address = GetEntityFromScript("fm_mission_controller", VehsLocal + k)
						if Handle ~= 0 then
							Vehs[k] = { Handle = Handle, Address = Address }
						end
					else
						if not ENTITY.DOES_ENTITY_EXIST(Vehs[k].Handle) or ENTITY.IS_ENTITY_DEAD(Vehs[k].Handle) then
							Vehs[k] = nil
						end
					end
				end
				local PropsNumValue = 1--Memory.ReadInt(PropsNumPtr)
				for k = 1, PropsNumValue do
					if Props[k] == nil then
						local Handle = ScriptLocal.GetInt(joaat("fm_mission_controller"), PropsLocal + (k - 1))
						--local Handle = GetEntityFromScript("fm_mission_controller", PropsLocal + (k - 1))
						if Handle ~= 0 then
							Props[k] = { Handle = Handle, Attached = false, Offset = nil, Rot = nil, AttachMS = 0, MoreOffset =
							v3.new(), FinalOffset = v3.new() }
						end
					else
						if Vehs[1] ~= nil then
							--ENTITY.FREEZE_ENTITY_POSITION(Vehs[1].Handle, true)
							--ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(Vehs[1].Handle, false, true)
							if Props[k].Offset == nil then
								local Pos = ENTITY.GET_ENTITY_COORDS(Props[k].Handle)
								local VehRot = ENTITY.GET_ENTITY_ROTATION(Vehs[1].Handle, 2)
								--local Offset = ENTITY.GET_OFFSET_FROM_ENTITY_GIVEN_WORLD_COORDS(Vehs[1].Handle, Pos.x,
								--	Pos.y, Pos.z)
								local VehPos = ENTITY.GET_ENTITY_COORDS(Vehs[1].Handle)

								local PropRot = ENTITY.GET_ENTITY_ROTATION(Props[k].Handle, 2)

								-- diferença de rotação (mantendo o mesmo eixo YXZ da flag 2)
								local RotDif = v3.new(
									PropRot.x - VehRot.x,
									PropRot.y - VehRot.y,
									PropRot.z - VehRot.z
								)

								-- normaliza os ângulos para -180..180 (opcional, evita wrap)
								RotDif.x = (RotDif.x + 180.0) % 360.0 - 180.0
								RotDif.y = (RotDif.y + 180.0) % 360.0 - 180.0
								RotDif.z = (RotDif.z + 180.0) % 360.0 - 180.0

								-- converte rotação para radianos
								local radZ = math.rad(-VehRot.z)
								local sinZ = math.sin(radZ)
								local cosZ = math.cos(radZ)

								-- offset bruto (em mundo)
								local dx = Pos.x - VehPos.x
								local dy = Pos.y - VehPos.y
								local dz = Pos.z - VehPos.z

								-- aplica inversa da rotação do veículo (corrigindo para espaço local)
								local localX = dx * cosZ - dy * sinZ
								local localY = dx * sinZ + dy * cosZ
								local localZ = dz

								Props[k].Rot = v3.new(RotDif)
								Props[k].Offset = v3.new(localX, localY, localZ)
								OffsetsNum = OffsetsNum + 1

							end
							if OffsetsNum >= PropsNumValue then
								ENTITY.FREEZE_ENTITY_POSITION(Props[k].Handle, false)
								ENTITY.SET_ENTITY_DYNAMIC(Props[k].Handle, true)
								if not Props[k].Attached then
									-- alvo desejado no frame local do veículo (já calculado antes)
									-- Props[k].Offset : vector3 (LOCAL DO VEÍCULO)

									-- posição atual do prop (mundo)
						

									ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(Props[k].Handle, false, true)
									local MoreOffset = Props[k].MoreOffset
									if Props[k].AttachMS == 0 then
										Props[k].AttachMS = GameTimer + 1000
										ENTITY.ATTACH_ENTITY_TO_ENTITY_PHYSICALLY(Props[k].Handle, Vehs[1].Handle, -1, -1,
											Props[k].Offset.x + MoreOffset.x, Props[k].Offset.y + MoreOffset.y,
											Props[k].Offset.z + MoreOffset.z, 0.0, 0.0, 0.0, Props[k].Rot.x,
											Props[k].Rot.y, Props[k].Rot.z, -1.0, true, true, false, false, 2)
									end
									if GameTimer > Props[k].AttachMS then
										Props[k].AttachMS = GameTimer + 1000
										Props[k].FinalOffset = v3.new(
											Props[k].Offset.x + MoreOffset.x,
											Props[k].Offset.y + MoreOffset.y,
											Props[k].Offset.z + MoreOffset.z
										)
										ENTITY.ATTACH_ENTITY_TO_ENTITY_PHYSICALLY(Props[k].Handle, Vehs[1].Handle, -1, -1,
											Props[k].Offset.x + MoreOffset.x, Props[k].Offset.y + MoreOffset.y,
											Props[k].Offset.z + MoreOffset.z, 0.0, 0.0, 0.0, Props[k].Rot.x,
											Props[k].Rot.y, Props[k].Rot.z, -1.0, true, true, false, false, 2)
										--ENTITY.ATTACH_ENTITY_TO_ENTITY(Props[k].Handle, Vehs[1].Handle, 0, Props[k].Offset.x, Props[k].Offset.y, Props[k].Offset.z, Props[k].Rot.x, Props[k].Rot.y, Props[k].Rot.z, false, false, true, false, 2, true, false)

										Props[k].Attached = true
									end
									local Pos = ENTITY.GET_ENTITY_COORDS(Props[k].Handle)

									-- converte a posição atual do prop para o frame LOCAL do veículo
									local curLocal = ENTITY.GET_OFFSET_FROM_ENTITY_GIVEN_WORLD_COORDS(
										Vehs[1].Handle, Pos.x, Pos.y, Pos.z
									)

									-- delta que falta em ESPAÇO LOCAL (ordem de subtração importa!)
									MoreOffset = v3.new(
										Props[k].Offset.x - curLocal.x,
										Props[k].Offset.y - curLocal.y,
										Props[k].Offset.z - curLocal.z
									)
									Props[k].MoreOffset = MoreOffset
									SaveMS = GameTimer + 3000
									--local Pos = ENTITY.GET_ENTITY_COORDS(Props[k].Handle)
									--local OffsetPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(Vehs[1].Handle,
									--	Props[k].Offset.x, Props[k].Offset.y, Props[k].Offset.z)
									--Pos = v3.new(Pos)
									--OffsetPos = v3.new(OffsetPos)
									--OffsetPos:sub(Pos)
									--Props[k].MoreOffset = OffsetPos
								else
									ENTITY.SET_ENTITY_COLLISION(Props[k].Handle, true, true)
								end
							end
						end
					end
				end
				if not SavedAttach and GameTimer > SaveMS then
					local Data = {}
					for k = 1, PropsNumValue do
						if Props[k] ~= nil then
							Data[#Data+1] = {
								Model = ENTITY.GET_ENTITY_MODEL(Props[k].Handle),
								Rot = {x = Props[k].Rot.x, y = Props[k].Rot.y, z = Props[k].Rot.z},
								Offset = {
									x = Props[k].FinalOffset.x,
									y = Props[k].FinalOffset.y,
									z = Props[k].FinalOffset.z
								}
							}
						end
					end
					SaveJSONFile(AttachmentsDir.."LastAttach.json", Data)
					SavedAttach = true
				end
			else
				Vehs = {}
				Objs = {}
				Props = {}
				HostMilis = 0
				OffsetsNum = 0
			end
			Wait()
		end
	end
end)

local TeamCurPriority = SplitGlobals("uLocal_29016[j]")
local TeamCurScore = SplitGlobals("iLocal_20395.f_1232[i]")
local TeamCurScore2 = SplitGlobals("iLocal_20395.f_1237[i]")
local Tsc = SplitGlobals("Global_4718592.f_3605[i /*26968*/].f_6219[j]")
function NextObjective()
    for k = 0, 3 do
        local CurPriority = ScriptLocal.GetInt(Utils.Joaat("fm_mission_controller"), TeamCurPriority + k)
        if CurPriority >= 0 and CurPriority <= 16 then
            ScriptGlobal.SetInt(Tsc + (26968 * k) + CurPriority, 1)
            ScriptLocal.SetInt(Utils.Joaat("fm_mission_controller"), TeamCurScore + k, 1)
            ScriptLocal.SetInt(Utils.Joaat("fm_mission_controller"), TeamCurScore2 + k, 1)
        end
    end
end

local AnnihilatorRide = false
menu.toggle(GameModesMenu, "Annihilator Ride", {}, "", function(toggle)
	AnnihilatorRide = toggle
	if AnnihilatorRide then
		local Paths = GetVectorsTable(PathDirSaveds.."AnnihilatorRide_1.txt", true, false)
		local Vehs = {}
		local Peds = {}
		local Objs = {}
		local Props = {}
		local VehsLocal = SplitGlobals("uLocal_23609.f_834.f_81")
		local ObjsLocal = SplitGlobals("uLocal_23609.f_834.f_147")
		local PedsLocal = SplitGlobals("uLocal_23609.f_834")
		local PropsLocal = SplitGlobals("uLocal_7710[i]")
		local PropsNum = SplitGlobals("Global_5242880")
		local PropsNumPtr = ScriptGlobal.GetPtr(PropsNum)
		local HostMilis = 0
		local OffsetsNum = 0
		local VehHash = Utils.Joaat("bati")
		local CurPed = 1
		local MaxPeds = 50
		local TotalTime = 0
		local LastTimer = 0
		local Started = false

		local ModelsData = {
			[427753832] = function()
				local Dist = 15.0
				return {
					Positions = {
						v3.new(-Dist, 0.0, 5.0),
						v3.new(Dist, 0.0, 5.0),
						v3.new(0.0, -Dist, 5.0),
						v3.new(0.0, Dist, 5.0)
					},
					Type = "Normal"
				}
			end,
			[287515096] = function()
				return {
					Positions = {
						v3.new(0.0, -7.0, 0.0),
						v3.new(0.0, 0.0, 0.0),
						v3.new(0.0, 7.0, 0.0)
					},
					Type = "RequireColor"
				}
			end
		}
		local ModelsFunctions = {
			[1] = function(Ped, Pos, Heading)
				ENTITY.SET_ENTITY_COORDS(Ped, Pos.x, Pos.y, Pos.z)
				ENTITY.SET_ENTITY_HEADING(Ped, Heading)
			end,
			[7] = function(Ped, Pos, Heading)
				local Vehicle = GTA.SpawnVehicle(VehHash, Pos.x,
					Pos.y, Pos.z, Heading, true, true)
				PED.SET_PED_INTO_VEHICLE(Ped, Vehicle, -1)
				WEAPON.GIVE_WEAPON_TO_PED(Ped, Utils.Joaat("weapon_microsmg"), 99999, false, true)
				PED.SET_PED_COMBAT_ATTRIBUTES(Ped, 3, false)
			end
		}
		local AttachData = LoadJSON(AttachmentsDir.."AnnihilatorAttach.json")
		local AttachModels = {}
		local AttachKeys = {}
		for k = 1, #AttachData do
			if AttachKeys[AttachData[k].Model] == nil then
				AttachKeys[AttachData[k].Model] = true
				AttachModels[#AttachModels+1] = AttachData[k].Model
			end
		end
		local AttachPropModel = AttachData[1].Model
		local Attachs = {}
		while AnnihilatorRide do
			if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("fm_mission_controller")) > 0 then
				local PlayerID = PLAYER.PLAYER_ID()
				if not STREAMING.HAS_MODEL_LOADED(VehHash) then
					STREAMING.REQUEST_MODEL(VehHash)
				end
				for k = 1, #AttachModels do
					if not STREAMING.HAS_MODEL_LOADED(AttachModels[k]) then
						STREAMING.REQUEST_MODEL(AttachModels[k])
					end
				end
				local IsHost = false
				Script.ExecuteAsScript("fm_mission_controller", function()
					IsHost = NETWORK.NETWORK_IS_HOST_OF_THIS_SCRIPT()
				end)
				local GameTimer = MISC.GET_GAME_TIMER()
				if not IsHost then
					if GameTimer > HostMilis then
						HostMilis = GameTimer + 1000
						GTA.ForceScriptHost(Utils.Joaat("fm_mission_controller"))
					end
				end
				local Delta = GameTimer - LastTimer
				if Delta < 0 then Delta = 0 end
				LastTimer = GameTimer
				if not Started then
					if PLAYER.IS_PLAYER_CONTROL_ON(PlayerID) then
						Started = true
					end
				else
					TotalTime = TotalTime + Delta
				end
				for k = 1, 1 do
					if Vehs[k] == nil then
						local Handle, Address, NetID = GetEntityFromScript("fm_mission_controller", VehsLocal + k)
						if Handle ~= 0 then
							Vehs[k] = { Handle = Handle, NetID = NetID, NetOBJ = NetworkObjectMgr.GetNetworkObject(NetID, false), Address = Address, Index = 1, Paths = Paths }
							local VPos = ENTITY.GET_ENTITY_COORDS(Handle)
							local AttachProps = {}
							for i = 1, #AttachData do
								local PropHandle = GTA.CreateObject(AttachData[i].Model, VPos.x, VPos.y, VPos.z + 50.0, true, true)
								Attachs[#Attachs+1] = PropHandle
								AttachProps[i] = PropHandle
								entities.set_can_migrate(PropHandle, false)
								ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(PropHandle, false, true)
							end
							for i = 1, #AttachData do
								local PropHandle = AttachProps[i]
								ENTITY.ATTACH_ENTITY_TO_ENTITY_PHYSICALLY(PropHandle, Handle, -1, -1,
									AttachData[i].Offset.x, AttachData[i].Offset.y,
									AttachData[i].Offset.z, 0.0, 0.0, 0.0, AttachData[i].Rot.x,
									AttachData[i].Rot.y, AttachData[i].Rot.z, -1.0, true, true, false, false, 2)
							end
							for i = 1, #AttachData do
								local PropHandle = AttachProps[i]
								ENTITY.SET_ENTITY_COLLISION(PropHandle, true, true)
							end
						end
					else
						if not ENTITY.DOES_ENTITY_EXIST(Vehs[k].Handle) or ENTITY.IS_ENTITY_DEAD(Vehs[k].Handle) then
							Vehs[k] = nil
						else
							if RequestControlOfEntity(Vehs[k].Handle) then
								entities.set_can_migrate(Vehs[k].Handle, false)
							else
								--NetworkObjectMgr.ChangeOwner(Vehs[k].NetOBJ, NetGamePlayer, 2)
							end
							--ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(Vehs[k].Handle, false, true)
							ENTITY.SET_ENTITY_COLLISION(Vehs[k].Handle, false, true)
							UpdateReplayIndexByTime2(Vehs[k], TotalTime)
							if Vehs[k].Index >= #Paths then
								NextObjective()
							end
							local Coord = {
								x = Vehs[k].Paths[Vehs[k].Index].x,
								y = Vehs[k].Paths[Vehs[k].Index].y,
								z = Vehs[k].Paths[Vehs[k].Index].z
							}
							local Rot = {
								x = 0.0,
								y = 0.0,
								z = Vehs[k].Paths[Vehs[k].Index].RotZ
							}
							local Vel = {
								x = Vehs[k].Paths[Vehs[k].Index].VelX,
								y = Vehs[k].Paths[Vehs[k].Index].VelY,
								z = Vehs[k].Paths[Vehs[k].Index].VelZ
							}
							SetEntitySpeedToCoord(Vehs[k].Handle, Coord, 1.0,
								false, false, false, Vel.x, Vel.y, Vel.z, false, false, nil)
							RotateEntityToTargetRotation(Vehs[k].Handle, Rot, 1.0)
						end
					end
				end
				for k = 1, #Attachs do
					if RequestControlOfEntity(Attachs[k]) then
						local Ent = ENTITY. _GET_LAST_ENTITY_HIT_BY_ENTITY(Attachs[k])
						if Ent ~= 0 and ENTITY.IS_ENTITY_AN_OBJECT(Ent) then
							ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(Attachs[k], Ent, false)
						end
					end
				end
				for k = 1, MaxPeds do
					if Peds[k] == nil then
						local Handle, Address, NetID = GetEntityFromScript("fm_mission_controller", PedsLocal + k)
						if Handle ~= 0 then
							Peds[k] = {Handle = Handle, NetID = NetID, NetOBJ = NetworkObjectMgr.GetNetworkObject(NetID, false)}
						end
					else
						if not ENTITY.DOES_ENTITY_EXIST(Peds[k].Handle) or ENTITY.IS_ENTITY_DEAD(Peds[k].Handle) then
							Peds[k] = nil
						end
					end
				end
				local PlayerPos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID())
				local PropsNumValue = Memory.ReadInt(PropsNumPtr)
				for k = 1, PropsNumValue do
					if Props[k] == nil then
						local Handle = ScriptLocal.GetInt(joaat("fm_mission_controller"), PropsLocal + (k))
						--local Handle = GetEntityFromScript("fm_mission_controller", PropsLocal + (k - 1))
						if Handle ~= 0 then
							local Data = nil
							local PropModel = ENTITY.GET_ENTITY_MODEL(Handle)
							if ModelsData[PropModel] then
								Data = ModelsData[PropModel]()
							end
							Props[k] = { Handle = Handle, Data = Data }
						end
					else
						if Props[k].Data ~= nil then
							local PropPos = ENTITY.GET_ENTITY_COORDS(Props[k].Handle)
							if DistanceBetween(PlayerPos.x, PlayerPos.y, PlayerPos.z, PropPos.x, PropPos.y, PropPos.z) < 100.0 then
								if #Props[k].Data.Positions > 0 then
									local Pos = Props[k].Data.Positions[1]
									local FinalPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(Props[k].Handle, Pos.x, Pos.y, Pos.z)
									local Heading = ENTITY.GET_ENTITY_HEADING(Props[k].Handle)
									if Peds[CurPed] ~= nil then
										local Ped = Peds[CurPed].Handle
										if RequestControlOfEntity(Ped) then
											--NetworkObjectMgr.ChangeOwner(Peds[CurPed].NetOBJ, NetGamePlayer, 2)
											if Props[k].Data.Type == "Normal" then
												ENTITY.SET_ENTITY_COORDS(Ped, FinalPos.x, FinalPos.y, FinalPos.z)
												ENTITY.SET_ENTITY_HEADING(Ped, Heading)
											elseif Props[k].Data.Type == "RequireColor" then
												local Tint = OBJECT.GET_OBJECT_TINT_INDEX(Props[k].Handle)
												if ModelsFunctions[Tint] then
													ModelsFunctions[Tint](Ped, FinalPos, Heading)
												end
											end
										end
									end
									CurPed = CurPed + 1
									if CurPed > MaxPeds then
										CurPed = 1
									end
									table.remove(Props[k].Data.Positions, 1)
								else
									Props[k].Data = nil
								end
							end
						end
					end
				end
			else
				Vehs = {}
				Peds = {}
				Objs = {}
				Props = {}
				HostMilis = 0
				OffsetsNum = 0
				CurPed = 1
				TotalTime = 0
				LastTimer = 0
				Started = false
				for k = 1, #Attachs do
					entities.delete_by_handle(Attachs[k])
				end
				Attachs = {}
			end
			Wait()
		end
		for k = 1, #Attachs do
			entities.delete_by_handle(Attachs[k])
		end
	end
end)

local AnnihilatorRideWars = false
menu.toggle(GameModesMenu, "Annihilator Ride Wars", {}, "", function(toggle)
	AnnihilatorRideWars = toggle
	if AnnihilatorRideWars then
		local Paths = {
			GetVectorsTable(PathDirSaveds.."RideWars1_1.txt", true, false),
			GetVectorsTable(PathDirSaveds.."RideWars1_2.txt", true, false)
		}
		local Vehs = {}
		local Peds = {}
		local Objs = {}
		local Props = {}
		local VehsLocal = SplitGlobals("uLocal_23609.f_834.f_81")
		local ObjsLocal = SplitGlobals("uLocal_23609.f_834.f_147")
		local PedsLocal = SplitGlobals("uLocal_23609.f_834")
		local PropsLocal = SplitGlobals("uLocal_7710[i]")
		local PropsNum = SplitGlobals("Global_5242880")
		local PropsNumPtr = ScriptGlobal.GetPtr(PropsNum)
		local HostMilis = 0
		local OffsetsNum = 0
		local VehHash = Utils.Joaat("bati")
		local CurPed = 1
		local MaxPeds = 50
		local TotalTime = 0
		local LastTimer = 0
		local Started = false

		local AttachData = LoadJSON(AttachmentsDir.."AnnihilatorAttach.json")
		local AttachModels = {}
		local AttachKeys = {}
		for k = 1, #AttachData do
			if AttachKeys[AttachData[k].Model] == nil then
				AttachKeys[AttachData[k].Model] = true
				AttachModels[#AttachModels+1] = AttachData[k].Model
			end
		end
		local IDsToAttach = {
			[3] = 1,
			[4] = 2
		}
		local Attachs = {}
		while AnnihilatorRideWars do
			if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("fm_mission_controller")) > 0 then
				local PlayerID = PLAYER.PLAYER_ID()
				for k = 1, #AttachModels do
					if not STREAMING.HAS_MODEL_LOADED(AttachModels[k]) then
						STREAMING.REQUEST_MODEL(AttachModels[k])
					end
				end
				local IsHost = false
				Script.ExecuteAsScript("fm_mission_controller", function()
					IsHost = NETWORK.NETWORK_IS_HOST_OF_THIS_SCRIPT()
				end)
				local GameTimer = MISC.GET_GAME_TIMER()
				if not IsHost then
					if GameTimer > HostMilis then
						HostMilis = GameTimer + 1000
						GTA.ForceScriptHost(Utils.Joaat("fm_mission_controller"))
					end
				end
				local Delta = GameTimer - LastTimer
				if Delta < 0 then Delta = 0 end
				LastTimer = GameTimer
				if not Started then
					if PLAYER.IS_PLAYER_CONTROL_ON(PlayerID) then
						Started = true
					end
				else
					TotalTime = TotalTime + Delta
				end
				for k = 1, 4 do
					if Vehs[k] == nil then
						local Handle, Address, NetID = GetEntityFromScript("fm_mission_controller", VehsLocal + k)
						if Handle ~= 0 then
							Vehs[k] = { Handle = Handle, NetID = NetID, NetOBJ = NetworkObjectMgr.GetNetworkObject(NetID, false), Address = Address, Index = 1, Paths = Paths[k] }
							if k <= 2 then
								local VPos = ENTITY.GET_ENTITY_COORDS(Handle)
								local AttachProps = {}
								for i = 1, #AttachData do
									local PropHandle = GTA.CreateObject(AttachData[i].Model, VPos.x, VPos.y, VPos.z + 50.0, true, true)
									Attachs[#Attachs+1] = PropHandle
									AttachProps[i] = PropHandle
									entities.set_can_migrate(PropHandle, false)
									ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(PropHandle, false, true)
								end
								for i = 1, #AttachData do
									local PropHandle = AttachProps[i]
									ENTITY.ATTACH_ENTITY_TO_ENTITY_PHYSICALLY(PropHandle, Handle, -1, -1,
										AttachData[i].Offset.x, AttachData[i].Offset.y,
										AttachData[i].Offset.z, 0.0, 0.0, 0.0, AttachData[i].Rot.x,
										AttachData[i].Rot.y, AttachData[i].Rot.z, -1.0, true, true, false, false, 2)
								end
								for i = 1, #AttachData do
									local PropHandle = AttachProps[i]
									ENTITY.SET_ENTITY_COLLISION(PropHandle, true, true)
									ENTITY.SET_ENTITY_VISIBLE(PropHandle, false, false)
								end
							end
						end
					else
						if not ENTITY.DOES_ENTITY_EXIST(Vehs[k].Handle) or ENTITY.IS_ENTITY_DEAD(Vehs[k].Handle) then
							Vehs[k] = nil
						else
							if RequestControlOfEntity(Vehs[k].Handle) then
								entities.set_can_migrate(Vehs[k].Handle, false)
								ENTITY.SET_ENTITY_INVINCIBLE(Vehs[k].Handle, true, false)
							else
								--NetworkObjectMgr.ChangeOwner(Vehs[k].NetOBJ, NetGamePlayer, 2)
							end
							--ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(Vehs[k].Handle, false, true)
							if k <= 2 then
								ENTITY.SET_ENTITY_COLLISION(Vehs[k].Handle, false, true)
								UpdateReplayIndexByTime2(Vehs[k], TotalTime)
								if Vehs[k].Index >= #Paths[k] then
									NextObjective()
								end
								local Coord = {
									x = Vehs[k].Paths[Vehs[k].Index].x,
									y = Vehs[k].Paths[Vehs[k].Index].y,
									z = Vehs[k].Paths[Vehs[k].Index].z
								}
								local Rot = {
									x = 0.0,
									y = 0.0,
									z = Vehs[k].Paths[Vehs[k].Index].RotZ
								}
								local Vel = {
									x = Vehs[k].Paths[Vehs[k].Index].VelX,
									y = Vehs[k].Paths[Vehs[k].Index].VelY,
									z = Vehs[k].Paths[Vehs[k].Index].VelZ
								}
								SetEntitySpeedToCoord(Vehs[k].Handle, Coord, 1.0,
									false, false, false, Vel.x, Vel.y, Vel.z, false, false, nil)
								RotateEntityToTargetRotation(Vehs[k].Handle, Rot, 1.0)
							else
								if not ENTITY.IS_ENTITY_ATTACHED(Vehs[k].Handle) then
									ENTITY.ATTACH_ENTITY_TO_ENTITY(Vehs[k].Handle, Vehs[IDsToAttach[k]].Handle, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true, false)
								end
							end
						end
					end
				end
				for k = 1, #Attachs do
					if RequestControlOfEntity(Attachs[k]) then
						if ENTITY.IS_ENTITY_VISIBLE(Attachs[k]) then
							ENTITY.SET_ENTITY_VISIBLE(Attachs[k], false, true)
						end
						local Ent = ENTITY. _GET_LAST_ENTITY_HIT_BY_ENTITY(Attachs[k])
						if Ent ~= 0 and ENTITY.IS_ENTITY_AN_OBJECT(Ent) then
							ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(Attachs[k], Ent, false)
						end
					end
				end
			else
				Vehs = {}
				Peds = {}
				Objs = {}
				Props = {}
				HostMilis = 0
				CurPed = 1
				TotalTime = 0
				LastTimer = 0
				Started = false
				for k = 1, #Attachs do
					entities.delete_by_handle(Attachs[k])
				end
				Attachs = {}
			end
			Wait()
		end
		for k = 1, #Attachs do
			entities.delete_by_handle(Attachs[k])
		end
	end
end)

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

local WastelanderRideWars = false
menu.toggle(GameModesMenu, "Wastelander Ride Wars", {}, "", function(toggle)
	WastelanderRideWars = toggle
	if WastelanderRideWars then
		local Paths = {
			GetVectorsTable(PathDirSaveds.."Wastelander_2.txt", true, false),
			GetVectorsTable(PathDirSaveds.."Wastelander_1.txt", true, false)
		}
		local Vehs = {}
		local Peds = {}
		local Objs = {}
		local Props = {}
		local VehsLocal = SplitGlobals("uLocal_23609.f_834.f_81")
		local ObjsLocal = SplitGlobals("uLocal_23609.f_834.f_147")
		local PedsLocal = SplitGlobals("uLocal_23609.f_834")
		local PropsLocal = SplitGlobals("uLocal_7710[i]")
		local PropsNum = SplitGlobals("Global_5242880")
		local PropsNumPtr = ScriptGlobal.GetPtr(PropsNum)
		local HostMilis = 0
		local OffsetsNum = 0
		local VehHash = Utils.Joaat("bati")
		local CurPed = 1
		local MaxPeds = 50
		local TotalTime = 0
		local LastTimer = 0
		local Started = false
		local IDsToAttach = {
			[3] = 2,
			[4] = 1
		}
		while WastelanderRideWars do
			if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("fm_mission_controller")) > 0 then
				local PlayerID = PLAYER.PLAYER_ID()
				local IsHost = false
				Script.ExecuteAsScript("fm_mission_controller", function()
					IsHost = NETWORK.NETWORK_IS_HOST_OF_THIS_SCRIPT()
				end)
				local GameTimer = MISC.GET_GAME_TIMER()
				if not IsHost then
					if GameTimer > HostMilis then
						HostMilis = GameTimer + 1000
						GTA.ForceScriptHost(Utils.Joaat("fm_mission_controller"))
					end
				end
				local Delta = GameTimer - LastTimer
				if Delta < 0 then Delta = 0 end
				LastTimer = GameTimer
				if not Started then
					if PLAYER.IS_PLAYER_CONTROL_ON(PlayerID) then
						Started = true
					end
				else
					TotalTime = TotalTime + Delta
				end
				for k = 1, 4 do
					if Vehs[k] == nil then
						local Handle, Address, NetID = GetEntityFromScript("fm_mission_controller", VehsLocal + k)
						if Handle ~= 0 then
							Vehs[k] = { Handle = Handle, NetID = NetID, NetOBJ = NetworkObjectMgr.GetNetworkObject(NetID, false), Address = Address, Index = 1, Paths = Paths[k] }
						end
					else
						if not ENTITY.DOES_ENTITY_EXIST(Vehs[k].Handle) or ENTITY.IS_ENTITY_DEAD(Vehs[k].Handle) then
							Vehs[k] = nil
						else
							if RequestControlOfEntity(Vehs[k].Handle) then
								entities.set_can_migrate(Vehs[k].Handle, false)
								ENTITY.SET_ENTITY_INVINCIBLE(Vehs[k].Handle, true, false)
							end
							if k <= 2 then
								UpdateReplayIndexByTime2(Vehs[k], TotalTime)
								if Vehs[k].Index >= #Paths[k] then
									NextObjective()
								end
								local Coord = {
									x = Vehs[k].Paths[Vehs[k].Index].x,
									y = Vehs[k].Paths[Vehs[k].Index].y,
									z = Vehs[k].Paths[Vehs[k].Index].z
								}
								local Rot = {
									x = Vehs[k].Paths[Vehs[k].Index].RotX,
									y = Vehs[k].Paths[Vehs[k].Index].RotY,
									z = Vehs[k].Paths[Vehs[k].Index].RotZ
								}
								local Vel = {
									x = Vehs[k].Paths[Vehs[k].Index].VelX,
									y = Vehs[k].Paths[Vehs[k].Index].VelY,
									z = Vehs[k].Paths[Vehs[k].Index].VelZ
								}
								local VPos = ENTITY.GET_ENTITY_COORDS(Vehs[k].Handle)
								if DistanceBetween(VPos.x, VPos.y, VPos.z, Coord.x, Coord.y, Coord.z) > 20.0 then
									ENTITY.SET_ENTITY_COORDS(Vehs[k].Handle, Coord.x, Coord.y, Coord.z)
									ENTITY.SET_ENTITY_ROTATION(Vehs[k].Handle, Rot.x, Rot.y, Rot.z, 5)
								end
								SetEntitySpeedToCoord(Vehs[k].Handle, Coord, 1.0,
									false, false, false, Vel.x, Vel.y, Vel.z, false, false, nil)
								RotateEntityToTargetRotation(Vehs[k].Handle, Rot, 5.0)
								--RotateEntityToTargetRotationFixedSpeed(Vehs[k].Handle, Rot, 10.0, 2.0)
							else
								if not ENTITY.IS_ENTITY_ATTACHED(Vehs[k].Handle) then
									if Vehs[IDsToAttach[k]] ~= nil then
										ENTITY.ATTACH_ENTITY_TO_ENTITY(Vehs[k].Handle, Vehs[IDsToAttach[k]].Handle, 0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true, false)
									end
								end
							end
						end
					end
				end
			else
				Vehs = {}
				Peds = {}
				Objs = {}
				Props = {}
				HostMilis = 0
				CurPed = 1
				TotalTime = 0
				LastTimer = 0
				Started = false
			end
			Wait()
		end
	end
end)

local AnniBaseFM = false
menu.toggle(GameModesMenu, "Annihilator Base FM", {}, "", function(toggle)
	AnniBaseFM = toggle
	if AnniBaseFM then
		local Veh = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
		if Veh ~= 0 then
			local AttachData = LoadJSON(AttachmentsDir.."AnnihilatorAttach.json")
			local AttachModels = {}
			local AttachKeys = {}
			for k = 1, #AttachData do
				if AttachKeys[AttachData[k].Model] == nil then
					AttachKeys[AttachData[k].Model] = true
					AttachModels[#AttachModels+1] = AttachData[k].Model
				end
			end
			local Attachs = {}
			for k = 1, #AttachModels do
				while not STREAMING.HAS_MODEL_LOADED(AttachModels[k]) do
					STREAMING.REQUEST_MODEL(AttachModels[k])
					Wait(0)
				end
			end
			
			ENTITY.SET_ENTITY_COLLISION(Veh, false, true)
			--ENTITY.SET_ENTITY_HAS_GRAVITY(Veh, false)
			local VPos = ENTITY.GET_ENTITY_COORDS(Veh)
			local AttachProps = {}
			for i = 1, #AttachData do
				local PropHandle = GTA.CreateObject(AttachData[i].Model, VPos.x, VPos.y, VPos.z + 50.0, true, true)
				Attachs[#Attachs+1] = PropHandle
				AttachProps[i] = PropHandle
				entities.set_can_migrate(PropHandle, false)
				ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(PropHandle, false, true)
			end
			for i = 1, #AttachData do
				local PropHandle = AttachProps[i]
				ENTITY.ATTACH_ENTITY_TO_ENTITY_PHYSICALLY(PropHandle, Veh, -1, -1,
					AttachData[i].Offset.x, AttachData[i].Offset.y,
					AttachData[i].Offset.z, 0.0, 0.0, 0.0, AttachData[i].Rot.x,
					AttachData[i].Rot.y, AttachData[i].Rot.z, -1.0, true, true, false, false, 2)
			end
			for i = 1, #AttachData do
				local PropHandle = AttachProps[i]
				ENTITY.SET_ENTITY_COLLISION(PropHandle, true, true)
				ENTITY.SET_ENTITY_HAS_GRAVITY(PropHandle, false)
				ENTITY.SET_ENTITY_VISIBLE(PropHandle, false, false)
			end
			while AnniBaseFM do
				Wait(0)
			end
			for k = 1, #Attachs do
				entities.delete_by_handle(Attachs[k])
			end
			if ENTITY.DOES_ENTITY_EXIST(Veh) then
				ENTITY.SET_ENTITY_COLLISION(Veh, true, true)
				ENTITY.SET_ENTITY_HAS_GRAVITY(Veh, true)
			end
		end
	end
end)

menu.action(SoloRecordingMenu, "Disable Veh Col", {}, "", function()
	local Veh = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
	if Veh ~= 0 then
		ENTITY.SET_ENTITY_COLLISION(Veh, false, true)
	end
end)

menu.action(SoloRecordingMenu, "Enable Veh Col", {}, "", function()
	local Veh = PED.GET_VEHICLE_PED_IS_IN(PLAYER.PLAYER_PED_ID(), false)
	if Veh ~= 0 then
		ENTITY.SET_ENTITY_COLLISION(Veh, true, true)
	end
end)

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

function QuatInverse(q)
	return { x = -q.x, y = -q.y, z = -q.z, w = q.w }
end

function QuatMultiply(q1, q2)
	return {
		x = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y,
		y = q1.w * q2.y - q1.x * q2.z + q1.y * q2.w + q1.z * q2.x,
		z = q1.w * q2.z + q1.x * q2.y - q1.y * q2.x + q1.z * q2.w,
		w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z
	}
end

function QuatToEuler(q)
	local ysqr = q.y * q.y

	-- Roll (X)
	local t0 = 2.0 * (q.w * q.x + q.y * q.z)
	local t1 = 1.0 - 2.0 * (q.x * q.x + ysqr)
	local roll = math.atan(t0, t1)

	-- Pitch (Y)
	local t2 = 2.0 * (q.w * q.y - q.z * q.x)
	t2 = math.max(-1.0, math.min(1.0, t2))
	local pitch = math.asin(t2)

	-- Yaw (Z)
	local t3 = 2.0 * (q.w * q.z + q.x * q.y)
	local t4 = 1.0 - 2.0 * (ysqr + q.z * q.z)
	local yaw = math.atan(t3, t4)

	return { x = math.deg(roll), y = math.deg(pitch), z = math.deg(yaw) }
end

function GetEntityQuaternion(ent)
	local q_pointer = memory.alloc(8 * 4)
	ENTITY.GET_ENTITY_QUATERNION(ent, q_pointer, q_pointer + 8, q_pointer + 16, q_pointer + 24)
	return {
		x = memory.read_float(q_pointer),
		y = memory.read_float(q_pointer + 8),
		z = memory.read_float(q_pointer + 16),
		w = memory.read_float(q_pointer + 24)
	}
end

-------------------------------------------------------------------------------
-- Produto vetorial: cross(u, v) = (u.y*v.z - u.z*v.y, u.z*v.x - u.x*v.z, u.x*v.y - u.y*v.x)
-------------------------------------------------------------------------------
function CrossProduct(a, b)
	return {
		x = a.y * b.z - a.z * b.y,
		y = a.z * b.x - a.x * b.z,
		z = a.x * b.y - a.y * b.x
	}
end

-------------------------------------------------------------------------------
-- Soma vetorial simples: a + b
-------------------------------------------------------------------------------
function VecAdd(a, b)
	return {
		x = a.x + b.x,
		y = a.y + b.y,
		z = a.z + b.z
	}
end

-------------------------------------------------------------------------------
-- Escala um vetor: a * escalar
-------------------------------------------------------------------------------
function VecScale(a, s)
	return {
		x = a.x * s,
		y = a.y * s,
		z = a.z * s
	}
end

-------------------------------------------------------------------------------
-- Magnitude de um vetor
-------------------------------------------------------------------------------
function VecMag(a)
	return math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
end

-------------------------------------------------------------------------------
-- Normaliza um vetor
-------------------------------------------------------------------------------
function VecNormalize(a)
	local mag = VecMag(a)
	if mag > 0.000001 then
		return { x = a.x / mag, y = a.y / mag, z = a.z / mag }
	else
		return { x = 0, y = 0, z = 0 }
	end
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

	for line in content:gmatch("[^\r\n]+") do -- Divide manualmente por linhas
		local numbers = {}
		for n in line:gmatch("%S+") do     -- Divide por espaços
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
				Wait() -- Dá um respiro no loop
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
	for line in Txts:gmatch("[^\r\n]+") do -- Divide manualmente por linhas
		local numbers = {}
		for n in line:gmatch("%S+") do  -- Divide por espaços
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

ClickGUI.AddTab("Path Replay", function()
	if ClickGUI.BeginCustomChildWindow("Path Replay") then
		for _, hash in ipairs(menus) do
			ClickGUI.RenderFeature(hash)
		end
		ClickGUI.EndCustomChildWindow()
	end
end)
