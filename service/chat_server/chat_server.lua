local skynet = require("skynet")
local service = require("skynet.service")
local skyhelper = require("helper")
local utils = require("utils")
require("skynet.manager")
require("service_type")

local chat_logic_servers = {}  -- 服务ID

local function dispatch_send_message(head, content)
    local index = (head.center_agent % #chat_logic_servers)+1
    -- skynet.error("chat_logic_servers index:", index)
    local chat_logic_server = chat_logic_servers[index]
    skyhelper.send(chat_logic_server, "dispatch_send_message", head, content)
end

local CMD = {
    servicetype = SERVICE_TYPE.CHAT.ID, 	-- 服务类型
	servername = SERVICE_TYPE.CHAT.NAME,  	-- 服务名
    debug = false,
}

function CMD.start(content)
    math.randomseed(os.time())

    CMD.debug = content.debug

    for i=1, 10 do
        local chat_logic_server = skynet.newservice("service/chat_logic_server")
        chat_logic_servers[i] = chat_logic_server
        skynet.call(chat_logic_server, "lua", "start", {
            debug = CMD.debug,
            chat_server_id = skynet.self(),
        })
    end
    -- utils.dump(chat_logic_servers, "chat_logic_servers")

    return 0
end

function CMD.stop() 
    return 0
end

-- 登录服·消息处理接口
function CMD.dispatch_send_message(head, content)
    return dispatch_send_message(head, content)
end

local function dispatch()
    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
            local f = CMD[cmd]
            assert(f)
            if session == 0 then
                f(...)
            else
                skynet.ret(skynet.pack(f(...)))
            end
        end
    )
    skynet.register(CMD.servername)
end

skynet.start(dispatch)
