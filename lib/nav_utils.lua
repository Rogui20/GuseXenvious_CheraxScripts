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

vect = {}
vect.new = function(x,y,z)
    return {['x'] = x, ['y'] = y, ['z'] = z or 0}
end

vect.subtract = function(a,b)
	return vect.new(a.x - b.x, a.y - b.y, a.z - b.z)
end

vect.add = function(a,b)
	return vect.new(a.x + b.x, a.y + b.y, a.z + b.z)
end

vect.mag = function(a)
	return math.sqrt(a.x^2 + a.y^2 + a.z^2)
end

vect.norm = function(a)
    local mag = vect.mag(a)
    return vect.mult(a, 1/mag)
end

vect.mult = function(a,b)
	return vect.new(a.x*b, a.y*b, a.z*b)
end

-- returns the dot product of two vectors
vect.dot = function (a,b)
	return (a.x * b.x + a.y * b.y + a.z * b.z)
end

--returns the angle between two vectors
vect.angle = function (a,b)
	return math.acos(vect.dot(a,b) / ( vect.mag(a) * vect.mag(b) ))
end

-- returns the distance between two coords
vect.dist = function(a,b)
    return vect.mag(vect.subtract(a, b))
end

vect.tostring = function(a)
    return "{" .. a.x .. ", " .. a.y .. ", " .. a.z .. "}"
end

function atan2(y, x)
	if x > 0 then
		return ( math.atan(y / x) )
	end
	if x < 0 and y >= 0 then
		return ( math.atan(y / x) + math.pi )
	end
	if x < 0 and y < 0 then
		return ( math.atan(y / x) - math.pi )
	end
	if x == 0 and y > 0 then
		return ( math.pi / 2 )
	end
	if x == 0 and y < 0 then
		return ( - math.pi / 2 )
	end
	if x == 0 and y == 0 then
		return 0 -- actually 'tan' is not defined in this case
	end
end

function GET_ROTATION_FROM_DIRECTION(v)
	local mag = vect.mag(v)
	local rotation = {
		x = math.asin(v.z / mag) * (180 / math.pi),
		y =   0.0,
		z = - atan2(v.x, v.y) * (180 / math.pi)
	}
	return rotation
end

function V3_LookAt(Start, Target)
	local ab = vect.subtract(Target, Start)
	local rot = GET_ROTATION_FROM_DIRECTION(ab)
    return rot
end

function deg2rad(deg)
    return deg * math.pi / 180.0
end

-- Função para converter radianos para graus
function rad2deg(rad)
    return rad * 180.0 / math.pi
end

-- Função para limitar o ângulo no intervalo de -180 a 180 graus
function wrap180(deg)
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
        {cosY * cosZ, -cosY * sinZ, sinY},
        {sinX * sinY * cosZ + cosX * sinZ, -sinX * sinY * sinZ + cosX * cosZ, -sinX * cosY},
        {-cosX * sinY * cosZ + sinX * sinZ, cosX * sinY * sinZ + sinX * cosZ, cosX * cosY}
    }

    -- Extrair ângulos ZYX da matriz de rotação
    local rotZ2 = atan2(Rxyz[2][1], Rxyz[1][1])
    local rotY2 = math.asin(-Rxyz[3][1])
    local rotX2 = atan2(Rxyz[3][2], Rxyz[3][3])

    -- Converter de volta para graus
    rotX2 = rad2deg(rotX2)
    rotY2 = rad2deg(rotY2)
    rotZ2 = rad2deg(rotZ2)

    -- Ajustar ângulos para o intervalo de -180 a 180 graus
    rotX2 = wrap180(rotX2)
    rotY2 = wrap180(rotY2)
    rotZ2 = wrap180(rotZ2)

    return {x = rotX2, y = -rotY2, z = rotZ2}
end

function DistanceBetween(x1, y1, z1, x2, y2, z2)
	local dx = x1 - x2
	local dy = y1 - y2
	local dz = z1 - z2
	return math.sqrt ( dx * dx + dy * dy + dz * dz)
end

function SetNavmeshPropCount(Curl, mapID, count)
    local Data = {
        action = "setPropCount",
        mapID = mapID,
        args = {
            count = count
        }
    }
    Curl:Setopt(eCurlOption.CURLOPT_POSTFIELDS, json.encode(Data))
    Curl:Perform()
end

function AddNavmeshObject(Curl, mapID, index, modelHash, pos, rot)
    local Data = {
        action = "addPropByHash",
        mapID = mapID,
        args = {
            index = index,
            modelHash = modelHash,
            pos = {x = pos.x, y = pos.z, z = -pos.y},
            rot = {x = rot.x, y = -rot.y, z = rot.z}
        }
    }
    Curl:Setopt(eCurlOption.CURLOPT_POSTFIELDS, json.encode(Data))
    Curl:Perform()
end

-- Solicita construção da navmesh (será feita automaticamente 100ms após alteração na fila)
function BuildNavmesh(Curl, mapID)
    local Data = {
        action = "buildNavMesh",
        mapID = mapID
    }
    Curl:Setopt(eCurlOption.CURLOPT_POSTFIELDS, json.encode(Data))
    Curl:Perform()
end

function RequestPath(Curl, MapID, RequestID, StartPos, GoalPos, Options)
    local Data = {
        action = "findPath",
        mapID = MapID,
        args = {
            requestID = RequestID,
            start = { x = StartPos.x, y = StartPos.z, z = -StartPos.y },
            target = { x = GoalPos.x, y = GoalPos.z, z = -GoalPos.y },
            options = Options or 2
        }
    }
    --Logger.LogInfo("Called Request")
    Curl:Setopt(eCurlOption.CURLOPT_POSTFIELDS, json.encode(Data))
    Curl:Perform()
end

function AddOffMeshLink(Curl, MapID, StartPos, EndPos, Radius, BiDir, Area, Flags)
    local Data = {
        action = "addOffMeshLink",
        mapID = MapID,
        args = {
            start = { x = StartPos.x, y = StartPos.z, z = -StartPos.y },
            target = { x = EndPos.x, y = EndPos.z, z = -EndPos.y },
            radius = Radius,
            bidirectional = BiDir,
            area = Area,
            flags = Flags
        }
    }
    Curl:Setopt(eCurlOption.CURLOPT_POSTFIELDS, json.encode(Data))
    Curl:Perform()
end

function RequestEdges(Curl, MapID)
    local Data = {
        action = "getNavmeshEdges",
        mapID = MapID
    }
    Curl:Setopt(eCurlOption.CURLOPT_POSTFIELDS, json.encode(Data))
    Curl:Perform()
end

function GetEdges(Curl)
    if Curl:GetFinished() then
        local code, response = Curl:GetResponse()
        if code == eCurlCode.CURLE_OK then
            local data = json.decode(response)
            if data.edges ~= nil and #data.edges > 0 then
                return data.edges
            end
        end
    end
    return nil
end

function ApplyOffMeshLinks(Curl, MapID)
    local Data = {
        action = "applyOffMeshLinks",
        mapID = MapID
    }
    Curl:Setopt(eCurlOption.CURLOPT_POSTFIELDS, json.encode(Data))
    Curl:Perform()
end

function tofloat(v)
    return v * 1.0
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
        {cy * cz, -cy * sz, sy},
        {sx * sy * cz + cx * sz, -sx * sy * sz + cx * cz, -sx * cy},
        {-cx * sy * cz + sx * sz, cx * sy * sz + sx * cz, cx * cy}
    }
end

-- Função para multiplicar duas matrizes 3x3
local function MatrixMultiply(m1, m2)
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
local function MatrixInverse(m)
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
local function GetEntityRotationMatrix(entity)
    local rot = ENTITY.GET_ENTITY_ROTATION(entity, 5)
    return EulerToRotationMatrix(math.rad(rot.x), math.rad(rot.y), math.rad(rot.z))
end

-- Função para converter uma matriz de rotação para quaternion
function RotationMatrixToQuaternion(m)
    local w = math.sqrt(1 + m[1][1] + m[2][2] + m[3][3]) / 2
    local x = (m[3][2] - m[2][3]) / (4 * w)
    local y = (m[1][3] - m[3][1]) / (4 * w)
    local z = (m[2][1] - m[1][2]) / (4 * w)
    return {w = w, x = x, y = y, z = z}
end

-- Função para calcular a velocidade angular a partir da diferença de quaternions
function QuaternionToAngularVelocity(q)
    local theta = 2 * math.acos(q.w)
    local sinTheta = math.sqrt(1 - q.w * q.w)
    if sinTheta < 0.001 then
        return {x = q.x * theta, y = q.y * theta, z = q.z * theta}
    else
        return {x = q.x / sinTheta * theta, y = q.y / sinTheta * theta, z = q.z / sinTheta * theta}
    end
end

-- Função principal para girar a entidade até a rotação desejada usando matrizes de rotação
function RotateEntityToTargetRotation(entity, targetRotation, interpolationFactor, normalise)
    interpolationFactor = interpolationFactor or 0.1 -- Fator de interpolação para suavizar a rotação

    -- Obtenha a matriz de rotação atual da entidade
    local currentRotationMatrix = GetEntityRotationMatrix(entity)

    -- Calcule a matriz de rotação alvo a partir dos ângulos de Euler desejados
    local targetRotationMatrix = EulerToRotationMatrix(math.rad(targetRotation.x), math.rad(targetRotation.y), math.rad(targetRotation.z))

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

	if normalise then
		if angularVelocity.x < -interpolationFactor then
			angularVelocity.x = -interpolationFactor
		end
		if angularVelocity.x > interpolationFactor then
			angularVelocity.x = interpolationFactor
		end
		if angularVelocity.y < -interpolationFactor then
			angularVelocity.y = -interpolationFactor
		end
		if angularVelocity.y > interpolationFactor then
			angularVelocity.y = interpolationFactor
		end
		if angularVelocity.z < -interpolationFactor then
			angularVelocity.z = -interpolationFactor
		end
		if angularVelocity.z > interpolationFactor then
			angularVelocity.z = interpolationFactor
		end
	end
    -- Aplique a velocidade angular à entidade
   	ENTITY.SET_ENTITY_ANGULAR_VELOCITY(entity, angularVelocity.x, angularVelocity.y, angularVelocity.z)
    return angularVelocity
end

function ShapeTestNav(Entity, PPos, AdjustedVect, Flags)
	local FlagBits = -1
	if Flags ~= nil then
		FlagBits = Flags
	end
	local DidHit = Memory.Alloc(1)
    local DidHitBool = false
	local EndCoords = Memory.Alloc(24)
	local Normal = Memory.Alloc(24)
	local HitEntity = Memory.AllocInt()
	local HitEntityHandle = 0

	local Handle = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
		PPos.x, PPos.y, PPos.z,
		AdjustedVect.x, AdjustedVect.y, AdjustedVect.z,
		FlagBits,
		Entity, 7
	)
	local Status = SHAPETEST.GET_SHAPE_TEST_RESULT(Handle, DidHit, EndCoords, Normal, HitEntity)
    local HitCoordsV3 = {x = 0.0, y = 0.0, z = 0.0}
    local NormalV3 = {x = 0.0, y = 0.0, z = 0.0}
	if Memory.ReadByte(DidHit) ~= 0 then
		--HitCoordsV3 = Memory.ReadV3(EndCoords)
        --NormalV3 = Memory.ReadV3(Normal)
		HitCoordsV3 = {x = Memory.ReadFloat(EndCoords + 8 * 0), y = Memory.ReadFloat(EndCoords + 8 * 1), z = Memory.ReadFloat(EndCoords + 8 * 2)}
        NormalV3 =  {x = Memory.ReadFloat(Normal + 8 * 0), y = Memory.ReadFloat(Normal + 8 * 1), z = Memory.ReadFloat(Normal + 8 * 2)}
        DidHitBool = true
	else
		HitCoordsV3.x = AdjustedVect.x
		HitCoordsV3.y = AdjustedVect.y
		HitCoordsV3.z = AdjustedVect.z
	end
	if DidHitBool then
		if Memory.ReadInt(HitEntity) ~= 0 then
			HitEntityHandle = Memory.ReadInt(HitEntity)
		end
        --Logger.LogInfo(string.format("HitCoordsV3 %0.1f %0.1f %0.1f DidHit %d", HitCoordsV3.x, HitCoordsV3.y, HitCoordsV3.z, Memory.ReadByte(DidHit)))
	end
    Memory.Free(DidHit)
    Memory.Free(EndCoords)
    Memory.Free(Normal)
    Memory.Free(HitEntity)
    --Logger.LogInfo("Status "..Status.." Byte "..Memory.ReadByte(DidHit))
	return DidHitBool, HitCoordsV3, HitEntityHandle, NormalV3
end

-- Verifica se dois pontos 3D são iguais dentro de uma tolerância
local function pointsEqual(p1, p2, tolerance)
    tolerance = tolerance or 0.001
    return math.abs(p1.x - p2.x) < tolerance and
           math.abs(p1.y - p2.y) < tolerance and
           math.abs(p1.z - p2.z) < tolerance
end

-- Verifica se dois edges se conectam
local function edgesConnect(e1, e2)
    return pointsEqual(e1.start, e2.start) or
           pointsEqual(e1.start, e2["end"]) or
           pointsEqual(e1["end"], e2.start) or
           pointsEqual(e1["end"], e2["end"])
end

-- Agrupa todos os edges conectados
function GroupConnectedEdges(edges)
    local groups = {}
    local visited = {}

    -- Marca todos como não visitados no início
    for i = 1, #edges do
        visited[i] = false
    end

    -- Função recursiva para agrupar conexões
    local function addConnectedEdges(index, currentGroup)
        visited[index] = true
        table.insert(currentGroup, edges[index])

        for i = 1, #edges do
            if not visited[i] and edgesConnect(edges[index], edges[i]) then
                addConnectedEdges(i, currentGroup)
            end
        end
    end

    -- Itera sobre todos os edges
    for i = 1, #edges do
        if not visited[i] then
            local group = {}
            addConnectedEdges(i, group)
            table.insert(groups, group)
        end
    end

    return groups
end

local function dotProduct(v1, v2)
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
end

local function vectorLength(v)
    return math.sqrt(v.x^2 + v.y^2 + v.z^2)
end

local function angleBetween(v1, v2)
    local dot = dotProduct(v1, v2)
    local len1 = vectorLength(v1)
    local len2 = vectorLength(v2)
    if len1 == 0 or len2 == 0 then return 0 end -- evita divisão por zero
    local cosTheta = dot / (len1 * len2)
    -- Clamp para evitar imprecisão (cosTheta pode passar ligeiramente de -1/+1)
    cosTheta = math.max(-1, math.min(1, cosTheta))
    return math.deg(math.acos(cosTheta)) -- retorna em graus
end

-- Checa se dois normals "se olham" com tolerância (ex: 30°)
function NormalsFaceEachOther(n1, n2, tolerance)
    tolerance = tolerance or 30 -- padrão 30 graus
    local angle = angleBetween(n1, n2)
    return math.abs(180 - angle) <= tolerance
end

function GetAllPeds()
    local Peds = {}
    for i = 0, PoolMgr.GetMaxPedCount() - 1 do
        local pedIndex = PoolMgr.GetPed(i)
        if pedIndex and pedIndex ~= -1 then
            Peds[#Peds+1] = pedIndex
        end
    end
    return Peds
end

function GetClosestTarget(Ped, CheckForLos)
    local Target = 0
    local Dist = 10000.0
    local AllPeds = GetAllPeds()
    local Pos = ENTITY.GET_ENTITY_COORDS(Ped)
    for k = 1, #AllPeds do
        if AllPeds[k] ~= Ped then
            if PED.GET_RELATIONSHIP_BETWEEN_PEDS(Ped, AllPeds[k]) == 5 then
                if not ENTITY.IS_ENTITY_DEAD(AllPeds[k]) then
                    if CheckForLos then
                        if ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(Ped, AllPeds[k], 17) then
                            local TPos = ENTITY.GET_ENTITY_COORDS(AllPeds[k])
                            local Distance = DistanceBetween(TPos.x, TPos.y, TPos.z, Pos.x, Pos.y, Pos.z)
                            if Distance < Dist then
                                Target = AllPeds[k]
                                Dist = Distance
                            end
                        end
                    else
                        local TPos = ENTITY.GET_ENTITY_COORDS(AllPeds[k])
                        local Distance = DistanceBetween(TPos.x, TPos.y, TPos.z, Pos.x, Pos.y, Pos.z)
                        if Distance < Dist then
                            Target = AllPeds[k]
                            Dist = Distance
                        end
                    end
                end
            end
        end
    end
    return Target
end