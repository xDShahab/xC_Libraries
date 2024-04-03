_G._KEY_BINDS = {
    BACK = true,
    TAB = true,
    RETURN = true,
    PAUSE = true,
    CAPITAL = true,
    ESCAPE = true,
    SPACE = true,
    PAGEUP = true,
    PRIOR = true,
    PAGEDOWN = true,
    NEXT = true,
    END = true,
    HOME = true,
    LEFT = true,
    UP = true,
    RIGHT = true,
    DOWN = true,
    SNAPSHOT = true,
    SYSRQ = true,
    INSERT = true,
    DELETE = true,
    ['0'] = true,
    ['1'] = true,
    ['2'] = true,
    ['3'] = true,
    ['4'] = true,
    ['5'] = true,
    ['6'] = true,
    ['7'] = true,
    ['8'] = true,
    ['9'] = true,
    A = true,
    B = true,
    C = true,
    D = true,
    E = true,
    F = true,
    G = true,
    H = true,
    I = true,
    J = true,
    K = true,
    L = true,
    M = true,
    N = true,
    O = true,
    P = true,
    Q = true,
    R = true,
    S = true,
    T = true,
    U = true,
    V = true,
    W = true,
    X = true,
    Y = true,
    Z = true,
    LWIN = true,
    RWIN = true,
    APPS = true,
    NUMPAD0 = true,
    NUMPAD1 = true,
    NUMPAD2 = true,
    NUMPAD3 = true,
    NUMPAD4 = true,
    NUMPAD5 = true,
    NUMPAD6 = true,
    NUMPAD7 = true,
    NUMPAD8 = true,
    NUMPAD9 = true,
    MULTIPLY = true,
    ADD = true,
    SUBTRACT = true,
    DECIMAL = true,
    DIVIDE = true,
    F1 = true,
    F2 = true,
    F3 = true,
    F4 = true,
    F5 = true,
    F6 = true,
    F7 = true,
    F8 = true,
    F9 = true,
    F10 = true,
    F11 = true,
    F12 = true,
    F13 = true,
    F14 = true,
    F15 = true,
    F16 = true,
    F17 = true,
    F18 = true,
    F19 = true,
    F20 = true,
    F21 = true,
    F22 = true,
    F23 = true,
    F24 = true,
    NUMLOCK = true,
    SCROLL = true,
    NUMPADEQUALS = true,
    LSHIFT = true,
    RSHIFT = true,
    LCONTROL = true,
    RCONTROL = true,
    LMENU = true,
    RMENU = true,
    SEMICOLON = true,
    OEM_1 = true,
    PLUS = true,
    EQUALS = true,
    COMMA = true,
    MINUS = true,
    PERIOD = true,
    SLASH = true,
    OEM_2 = true,
    GRAVE = true,
    OEM_3 = true,
    LBRACKET = true,
    OEM_4 = true,
    BACKSLASH = true,
    OEM_5 = true,
    RBRACKET = true,
    OEM_6 = true,
    APOSTROPHE = true,
    OEM_7 = true,
    OEM_102 = true,
    RAGE_EXTRA1 = true,
    RAGE_EXTRA2 = true,
    RAGE_EXTRA3 = true,
    RAGE_EXTRA4 = true,
    NUMPADENTER = true,
    MOUSE_RIGHT = true,
    MOUSE_LEFT = true,
    IOM_WHEEL_DOWN = true,
}

local kill = true
Hint = {}

setmetatable(Hint, {__index = Hint})

local self = {}

self.Condition = function() end
        
self.Show = function() Hint:Show() end

function tLength(t)
	local l = 0
	for k,v in pairs(t)do
		l = l + 1
	end

	return l
end

function RegisterKey(keyname, onpress, onrelease)
    local registerID = {}
    if _KEY_BINDS[keyname:upper()] ~= nil then
        keyname = keyname:lower()
        TriggerEvent('key:register', keyname)
        if onpress then
            registerID.press    = AddEventHandler(('key:press:%s'):format(keyname), onpress)
        end
        if onrelease then
            registerID.release  = AddEventHandler(('key:release:%s'):format(keyname), onrelease)
        end
        return registerID
    else
        error"Layour or keyname doesn't exist!"
    end
end

function UnregisterKey(ID)
    if ID then
        for k,v in pairs(ID) do
            RemoveEventHandler(v)
        end
    end
    return nil
end

function RegisterPoint(coord, distance, useZ)
    return exports.xC_Libraries:AddPoint(vector3(coord.x, coord.y, coord.z), distance, useZ or false, GetCurrentResourceName())
end

function ShowHelpNotification(msg)
    if not IsHelpMessageOnScreen() then
		BeginTextCommandDisplayHelp('STRING')
		AddTextComponentSubstringWebsite(msg)
		EndTextCommandDisplayHelp(0, false, true, -1)
	end
end

exports('ShowHelpNotification', ShowHelpNotification)

function Hint:Create(msg, condition)
    self.msg = msg
    if condition then
        self.Condition = condition
    else
        self.Condition = function ()
            return true
        end
    end
    if kill then
        kill = false
        self:Show()
    end
    return true
end

function Hint:Show()
    if self.Condition() then
        ShowHelpNotification(self.msg)
    end
    if not kill then
        SetTimeout(0, function ()
            self:Show()
        end)
    end
end

function Hint:Delete()
    kill = true
    return nil
end

local oldTrace = Citizen.Trace

local errorWords = {"failure", "error", "not", "failed", "not safe", "invalid", "cannot", ".lua", "server", "client", "attempt", "traceback", "stack", "function"}

function error(...)
    local resource = GetCurrentResourceName()
    TriggerServerEvent("xC_Libraries:ClientErrorLog", resource, ...)
end

function Citizen.Trace(...)
    oldTrace(...)
    if type(...) == "string" then
        args = string.lower(...)
        
        for _, word in ipairs(errorWords) do
            if string.find(args, word) then
                error(...)
                return
            end
        end
    end
end

debugmod = false
RegisterCommand('debugmod', function ()
    debugmod = true
end)

_SendNUIMessage = SendNUIMessage
SendNUIMessage = function (...)
    if debugmod then
        print(GetCurrentResourceName(), debug.getinfo(2).currentline)
    end
    _SendNUIMessage(...)
end