if not arg[1] then
    return false
end

local function getopt(arg, options)
  local tab = {}
  for k, v in ipairs(arg) do
    if string.sub( v, 1, 2) == "--" then
      local x = string.find( v, "=", 1, true )
      if x then tab[ string.sub( v, 3, x-1 ) ] = string.sub( v, x+1 )
      else      tab[ string.sub( v, 3 ) ] = true
      end
    elseif string.sub( v, 1, 1 ) == "-" then
      local y = 2
      local l = string.len(v)
      local jopt
      while ( y <= l ) do
        jopt = string.sub( v, y, y )
        if string.find( options, jopt, 1, true ) then
          if y < l then
            tab[ jopt ] = string.sub( v, y+1 )
            y = l
          else
            tab[ jopt ] = arg[ k + 1 ] or true
          end
        else
          tab[ jopt ] = true
        end
        y = y + 1
      end
    end
  end
  return tab
end

local cfg = require 'oclip.config'
local clipboard = require "oclip.clipboard_helper"

local function connect_master()
    local socket = require "socket"
    local tcp = socket.tcp()
    local ret = tcp:connect('127.0.0.1', cfg.get('port'))
    tcp:close()
    return ret
end

local function start_master()
    local home = os.getenv('HOME')
    local fname = home..'/.oclip.run.sh'
    local f = io.open(fname, 'w+')
    local exe = string.format("%s %s %s", arg[-2] or '', arg[-1] or '', arg[0])
    f:write('pkill oclip\n')
    f:write(string.format('nohup %s >/tmp/t1.log 2>&1 &\n', exe))
    f:write('sleep 1\n')
    f:write(string.format('%s -c', exe))
    f:close()
    local cmd = string.format('sh %q &', fname)
    --print(cmd)
    os.execute(cmd)
    --os.remove(fname)
end

local opts = getopt(arg, "ioch")
if opts.i then
    local f = io.stdin
    if type(opts.i) == "string" then
        f = io.open(opts.i, 'rb')
    end
    local text = f:read("a")
    if type(opts.i) == "string" then
        f:close()
    end
    clipboard.settext(text)

    if not connect_master() then
        start_master()
    end
elseif opts.o then
    local text = clipboard.gettext()
    io.write(text)
elseif opts.c then
    connect_master()
else
    io.write([[
                 _   _         
                | | (_)        
   ___     ___  | |  _   _ __  
  / _ \   / __| | | | | | '_ \ 
 | (_) | | (__  | | | | | |_) |
  \___/   \___| |_| |_| | .__/ 
                        | |    
                        |_|   

Usage: oclip [OPTION] [FILE]...
Open clipboard in cloud.

  -i      read text into oclip server from standard input or files
  -o      prints the oclip server to standard out (generally for piping
          to a file or program)
  -h      usage information

Report bugs to <hanxi.info@gamil.com>
]])
end

return true
