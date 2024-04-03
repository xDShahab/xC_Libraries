ManageArray = {}
RegisteredResource = {}
XArray = {}
YArray = {}
Area = {}

function unpackCoord(coord, index)
    local insertX = false
    for i=1, #XArray do
        if XArray[i].point > coord.x then
            table.insert(XArray, i, {
                index = index,
                point = coord.x
            })
            insertX = true
            break
        end
    end
    if not insertX then
        table.insert(XArray, {
            index = index,
            point = coord.x
        })
    end

    local insertY = false
    for i=1, #YArray do
        if YArray[i].point > coord.y then
            table.insert(YArray, i, {
                index = index,
                point = coord.y
            })
            insertY = true
            break
        end
    end
    if not insertY then
        table.insert(YArray, {
            index = index,
            point = coord.y
        })
    end
end

setmetatable(ManageArray, {
    __newindex = function(self, k, v)
        unpackCoord(v.coord, k)
        rawset(self, k, v)
    end
})

function InsertResourcePoint(res, id)
    if not RegisteredResource[res] then
        RegisteredResource[res] = {}
    end

    RegisteredResource[res][id] = true
end

function AddPoint(coord, distance, useZ, res)
    local id = #ManageArray + 1
    InsertResourcePoint(res, id)
    table.insert(Area, id)
    ManageArray[id] = {
        res         = res,
        coord       = coord,
        distance    = distance + 0.0,
        useZ        = useZ,
        Callbacks   = {
            id = id,
            InArea,
            OutArea,
            InAreaOnce,
            OutAreaOnce,
            OnRemove,
            remove = function()
                if not ManageArray[id] then return nil end
                local PedCoord = GetEntityCoords(PlayerPedId())
                local Point = ManageArray[id]
                local CB = Point.Callbacks
                if Point then
                    if CB.OnRemove then
                        CB.OnRemove()
                    end
                    
                    if Point.useZ then
                        if #(Point.coord - PedCoord) < Point.distance then
                            if CB.InArea then
                                CB.InArea()
                            end
                            if not Point.InPoint then
                                ManageArray[id].InPoint = true
                                if CB.InAreaOnce then
                                    CB.InAreaOnce()
                                end
                            end
                        else
                            if Point.InPoint then
                                ManageArray[id].InPoint = false
                                if CB.OutAreaOnce then
                                    CB.OutAreaOnce()
                                end
                            end
                        end
                    else
                        if #(vector2(Point.coord.x, Point.coord.y) - vector2(PedCoord.x, PedCoord.y)) < Point.distance then
                            if CB.InArea then
                                CB.InArea()
                            end
                            if not Point.InPoint then
                                ManageArray[id].InPoint = true
                                if CB.InAreaOnce then
                                    CB.InAreaOnce()
                                end
                            end
                        else
                            if Point.InPoint then
                                ManageArray[id].InPoint = false
                                if CB.OutAreaOnce then
                                    CB.OutAreaOnce()
                                end
                            end
                        end
                    end
                end
                RemovePoint(id)
                return nil
            end,
            set = function(ref, val, lav)
                local In = ref:find('InArea')
                local Out = ref:find('OutArea')
                local Once = ref:find('Once')

                if Once then
                    if In then
                        ManageArray[id].InPoint = false
                    else
                        ManageArray[id].InPoint = true
                    end
                end

                ManageArray[id].Callbacks[ref] = val

                if lav then
                    local fer
                    if In then
                        fer = ref:gsub('In', 'Out')
                    elseif Out then
                        fer = ref:gsub('Out', 'In')
                    end
                    ManageArray[id].Callbacks[fer] = lav
                end
            end,
        }
    }

    return ManageArray[id].Callbacks
end

exports('AddPoint', AddPoint)

function RemovePoint(id)
    RegisteredResource[ManageArray[id].res][id] = nil
    ManageArray[id] = nil
    for k,v in pairs(XArray) do
        if v.index == id then
            table.remove(XArray, k)
        end
    end
    for k,v in pairs(YArray) do
        if v.index == id then
            table.remove(YArray, k)
        end
    end
    for k,v in pairs(Area) do
        if v == id then
            table.remove(Area, k)
        end
    end
end

exports('RemovePoint', RemovePoint)

function RemoveByTag(tag)
    for k,v in pairs(ManageArray) do
        if v.Callbacks.Tag == tag then
            v.Callbacks.remove()
        end
    end
end

exports('RemoveByTag', RemoveByTag)

function QadreMotlaq(number)
    return math.sqrt(number^2)
end

Citizen.CreateThread(function ()
    while true do
        Citizen.Wait(3)
        local PedCoord = GetEntityCoords(PlayerPedId())
        local Sleep = true
        for _, id in pairs(Area) do
            if id then
                local Point = ManageArray[id]
                if Point then
                    if Point.useZ then
                        local CB = Point.Callbacks
                        if #(Point.coord - PedCoord) < Point.distance then
                            if CB.InArea then
                                Sleep = false
                                CB.InArea()
                            end
                            if not Point.InPoint then
                                Sleep = false
                                ManageArray[id].InPoint = true
                                if CB.InAreaOnce then
                                    CB.InAreaOnce()
                                end
                            end
                        else
                            if CB.OutArea then
                                Sleep = false
                                CB.OutArea()
                            end
                            if Point.InPoint then
                                Sleep = false
                                ManageArray[id].InPoint = false
                                if CB.OutAreaOnce then
                                    CB.OutAreaOnce()
                                end
                            end
                        end
                    else
                        local CB = Point.Callbacks
                        if #(vector2(Point.coord.x, Point.coord.y) - vector2(PedCoord.x, PedCoord.y)) < Point.distance then
                            if CB.InArea then
                                Sleep = false
                                CB.InArea()
                            end
                            if not Point.InPoint then
                                Sleep = false
                                ManageArray[id].InPoint = true
                                if CB.InAreaOnce then
                                    CB.InAreaOnce()
                                end
                            end
                        else
                            if CB.OutArea then
                                Sleep = false
                                CB.OutArea()
                            end
                            if Point.InPoint then
                                Sleep = false
                                ManageArray[id].InPoint = false
                                if CB.OutAreaOnce then
                                    CB.OutAreaOnce()
                                end
                            end
                        end
                    end
                end
            end
        end
        if Sleep then Citizen.Wait(710) end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if RegisteredResource[res] then
        for id in pairs(RegisteredResource[res]) do
            RemovePoint(id)
        end
        RegisteredResource[res] = nil
    end
end)

-- Keys

_G.RegisteredKeys = {}

local KeyType = {
	['MOUSE_RIGHT'] 		= 'MOUSE_BUTTON',
	['MOUSE_LEFT']	        = 'MOUSE_BUTTON',
	['IOM_WHEEL_DOWN'] 		= 'MOUSE_WHEEL'
}

setmetatable(KeyType, {
	__index = function ()
		return 'KEYBOARD'
	end
})

AddEventHandler('key:register', function(keyname)
	if RegisteredKeys[keyname] == nil then
		RegisteredKeys[keyname] = true
		RegisterKeyMapping(('+kp keyboard %s'):format(keyname), 'Bind '..keyname, KeyType[keyname:upper()], keyname:upper())
	end
end)

RegisterCommand('+kp', function(s, args)
	local keyname = args[2]
	if keyname then
		keyname = keyname:lower()
		if RegisteredKeys[keyname] ~= nil then
			TriggerEvent(('key:press:%s'):format(keyname))
		end
	end
end, false)

RegisterCommand('-kp', function(s, args)
	local keyname = args[2]
	if keyname then
		keyname = keyname:lower()
		if RegisteredKeys[keyname] ~= nil then
			TriggerEvent(('key:release:%s'):format(keyname))
		end
	end
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    TriggerServerEvent('xC_Managermanager:giveNotificationD', resourceName)
end)

AddEventHandler('onResourceStarting', function(resourceName)
    TriggerServerEvent('xC_Managermanager:giveNotificationU', resourceName)
end)

AddEventHandler('onResourceStart', function(resourceName)
    TriggerServerEvent('xC_Managermanager:giveNotificationU', resourceName)
end)