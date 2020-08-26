--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id gate.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/19 15:26
 - @uses The world server gate service.
--]]
local skynet = require 'skynet'
local gateserver = require 'snax.gateserver'

-- Data.
-------------------------------------------------------------------------------

local watchdog
local connection = {}	-- fd -> connection : { fd , client, agent , ip, mode }
local forwarding = {}	-- agent -> connection
local recvspeed       -- Recv message speed.

local handler = {}
local CMD = {}

-- Local functions.
-------------------------------------------------------------------------------

local function unforward(c)
	if c.agent then
		forwarding[c.agent] = nil
		c.agent = nil
		c.client = nil
	end
end

local function close_fd(fd)
	local c = connection[fd]
	if c then
		unforward(c)
		connection[fd] = nil
	end
end

-- Check recv message on handle message.
local function check_recvspeed(c)
  local last_t = c.last_t or 0
  local now = skynet.now()
  if now - last_t >= 100 then
    local speed = c.recvspeed or 0
    if speed > recvspeed then
      local over = c.recvspeed_over or 0
      if over >= 3 then
        CMD.kick(0, c.fd)
        skynet.error('kick ', fd, 'so much message')
        return
      else
        c.recvspeed_over = over + 1
      end
    else
      c.recvspeed_over = 0
    end
    c.recvspeed = 0
  else
    c.recvspeed = speed + 1
  end
end

skynet.register_protocol {
	name = 'client',
	id = skynet.PTYPE_CLIENT,
}

-- API.
-------------------------------------------------------------------------------

function handler.open(source, conf)
	watchdog = conf.watchdog or source
  recvspeed = conf.recvspeed
end

function handler.message(fd, msg, sz)
	-- recv a package, forward it
	local c = connection[fd]
  local _ = recvspeed and check_recvspeed(c)
	local agent = c.agent
	if agent then
		-- It's safe to redirect msg directly , gateserver framework will not free msg.
		skynet.redirect(agent, c.client, 'client', fd, msg, sz)
	else
		skynet.send(watchdog, 'lua', 'socket', 'data', fd, skynet.tostring(msg, sz))
		-- skynet.tostring will copy msg to a string, so we must free msg here.
		skynet.trash(msg,sz)
	end
end

function handler.connect(fd, addr)
	local c = {
		fd = fd,
		ip = addr,
	}
	connection[fd] = c
	skynet.send(watchdog, 'lua', 'socket', 'open', fd, addr)
end

function handler.disconnect(fd)
	close_fd(fd)
	skynet.send(watchdog, 'lua', 'socket', 'close', fd)
end

function handler.error(fd, msg)
	close_fd(fd)
	skynet.send(watchdog, 'lua', 'socket', 'error', fd, msg)
end

function handler.warning(fd, size)
	skynet.send(watchdog, 'lua', 'socket', 'warning', fd, size)
end

function CMD.forward(source, fd, client, address)
	local c = assert(connection[fd])
	unforward(c)
	c.client = client or 0
	c.agent = address or source
	forwarding[c.agent] = c
	gateserver.openclient(fd)
end

function CMD.accept(source, fd)
	local c = assert(connection[fd])
	unforward(c)
	gateserver.openclient(fd)
end

function CMD.kick(source, fd)
	gateserver.closeclient(fd)
end

function handler.command(cmd, source, ...)
	local f = assert(CMD[cmd])
	return f(source, ...)
end

gateserver.start(handler)
