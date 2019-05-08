script_name('Pretty Flooder')
script_author('r4nx')
script_version('1.0.0-alpha')

local inicfg = require 'inicfg'

local flooding = false
local antiFloodStreak = 0
local cfgPath = 'prettyflooder.ini'

-- Default config
local cfg = {
    general = {
        floodingMessage = 'Hello, World!',
        antiFloodMessage = '',
        interval = 400
    }
}

function loadConfig()
    cfg = inicfg.load(cfg, cfgPath)
end

function saveConfig()
    inicfg.save(cfg, cfgPath)
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    
    sampRegisterChatCommand('pfreload', cmdPFReload)
    sampRegisterChatCommand('pfmsg', cmdPFMsg)
    sampRegisterChatCommand('pfantiflood', cmdPFAntiFlood)
    sampRegisterChatCommand('pfinterval', cmdPFInterval)
    
    loadConfig()
    
    wait(-1)
end

function onWindowMessage(msg, wParam, lParam)
    if msg == 0x100 and wParam == 0x78 then  -- keydown message, F9 key
        flooding = not flooding
        printStringNow(('~w~Flooder %s'):format(flooding and '~g~activated' or '~r~deactivated'), 1200)
        if flooding then
            lua_thread.create(function()
                while flooding do
                    sampSendChat(cfg.general.floodingMessage)
                    wait(cfg.general.interval)
                end
            end)
        end
        consumeWindowMessage(true, false)
    end
end

function onReceiveRpc(rpcId, bs)
    if string.len(cfg.general.antiFloodMessage) > 0 and rpcId == 93 then  -- RPC_ClientMessage
        raknetBitStreamResetReadPointer(bs)
        local color = raknetBitStreamReadInt32(bs)
        local textLen = raknetBitStreamReadInt32(bs)
        if textLen > 0 then
            local text = raknetBitStreamReadString(bs, textLen)
            if text:find(cfg.general.antiFloodMessage) then
                if antiFloodStreak >= 5 then
                    sampAddChatMessage('Interval increment did not help, turned off the flooder.', 0xAAAAAA)
                    flooding = false
                    antiFloodStreak = 0
                else
                    cfg.general.interval = cfg.general.interval + 100
                    saveConfig()
                    antiFloodStreak = antiFloodStreak + 1
                    sampAddChatMessage(('Anti flood message received, interval increased (now {4E79AA}%d{AAAAAA}).'):format(cfg.general.interval), 0xAAAAAA)
                end
            end
        end
        raknetBitStreamResetReadPointer(bs)
    end
end

function cmdPFReload()
    loadConfig()
    printStringNow('~w~Config reloaded', 1200)
end

function cmdPFMsg(params)
    if params:len() <= 0 then
        sampAddChatMessage('* /pfmsg <your message goes here>', 0xAAAAAA)
        return
    end
    cfg.general.floodingMessage = params
    saveConfig()
    printStringNow('~g~Done', 1200)
end

function cmdPFAntiFlood(params)
    if params:len() <= 0 then
        sampAddChatMessage('Anti flood message check {E53935}disabled{AAAAAA}.', 0xAAAAAA)
        cfg.general.antiFloodMessage = ''
        return
    end
    cfg.general.antiFloodMessage = params
    saveConfig()
    printStringNow('~g~Done', 1200)
end

function cmdPFInterval(params)
    local parsedInterval = tonumber(params)
    if parsedInterval == nil or parsedInterval <= 0 then
        sampAddChatMessage('* /pfinterval <time in milliseconds>', 0xAAAAAA)
        return
    end
    cfg.general.interval = parsedInterval
    saveConfig()
    printStringNow('~g~Done', 1200)
end
