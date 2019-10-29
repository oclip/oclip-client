local oclip_cmd = require 'oclip.oclip_cmd'
if oclip_cmd then
  return
end

package.path = '../share/lua/5.3/?.lua;?.lua;;'
package.cpath = '../lib/lua/5.3/?.so;?.dll;'

local cfg = require 'oclip.config'
local log_path = cfg.get_logs_file_path()
local log_file = io.open(log_path, 'w+')

local origin_print = print
function _G.print(...)
  origin_print(...)
  if log_file then
    log_file:write(os.date('%Y-%m-%d %H:%M:%S\t'))
    local n = select('#', ...)
    for i = 1, n do
      local a = select(i, ...)
      log_file:write(tostring(a), '\t')
    end
    log_file:write('\n')
    log_file:flush()
  end
end

local socket = require 'socket'
local copas = require 'copas'
local ws = require 'websocket'
local ws_client = ws.client.copas({timeout = 5})
local rpc = require 'oclip.rpc'
local cafile = require 'oclip.cafile'
local icon = require 'oclip.icon'
local tools = require 'oclip.tools'

local handler

local function traceback(msg)
  print(debug.traceback(msg))
end

local _send_text

local function on_cliboard_change(text, from)
  print('on_cliboard_change', from, #text)

  -- do not send text in here. need in main thread
  if not from and handler then
    _send_text = text
  end
end
local function clipboard_init()
  tools.clipboard_init(on_cliboard_change)
end

local function connect()
  while true do
    copas.sleep(0)
    if ws_client.state ~= 'OPEN' then
      local params = {
        mode = 'client',
        cafile = cafile.get(), --<-- added cafile parameters
        verify = 'peer', --<-- changed "none" to "peer"
        options = 'all'
      }
      local domain = cfg.get('domain')
      local url
      if domain:sub(1,2) == "ws" then
        url = domain
      else
        url = string.format('wss://%s/server', domain)
      end
      print('try connect: ', url)
      local ok, err = ws_client:connect(url, '', params)
      if not ok then
        print('could not connect', err)
        print('will try again 5s later...')
        tools.set_status_disconnect()
        copas.sleep(5)
      end
      tools.set_status_connected()
      handler = rpc:new_handler(ws_client)
    end
  end
end

local function send_ping()
  while true do
    if ws_client.state == 'OPEN' then
      ws_client:send('ping', ws.TEXT)
    end
    copas.sleep(5)
  end
end

local function send_copy()
  while true do
    copas.sleep(0)
    if ws_client.state == 'OPEN' then
      if _send_text then
        handler:send_copy(_send_text)
        _send_text = nil
      end
    end
  end
end

local function handler_receive()
  while true do
    copas.sleep(0)
    if ws_client.state == 'OPEN' then
      local data, opcode = ws_client:receive()
      if data and opcode == ws.BINARY then
        handler:process(data)
      end
    end
  end
end

local function net_init()
  copas.addthread(
    function()
      xpcall(connect, traceback)
    end
  )

  copas.addthread(
    function()
      xpcall(handler_receive, traceback)
    end
  )

  copas.addthread(
    function()
      xpcall(send_copy, traceback)
    end
  )

  copas.addthread(
    function()
      xpcall(send_ping, traceback)
    end
  )
end

local function main()
  tools.tray_init()
  clipboard_init()
  net_init()

  while true do
    copas.step(0)
    socket.sleep(0.05)
    if tools.loop() == -1 then
      print('exit.')
      break
    end
  end
  cafile.exit()
  icon.exit()
end

xpcall(main, traceback)

log_file:close()
