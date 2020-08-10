--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id mysqlauto.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/05 16:22
 - @uses A simple tool for mysql database operate.
         !ref: https://github.com/hongling0/mysqlauto
--]]
local _M = {}

_M.db = require "mysql.mysql_auto.db"
_M.file = require "mysql.mysql_auto.file"

function _M.newctx(opt)
    assert(opt.name)
    assert(opt.query)
    assert(opt.dir)
    local ret = {}
    _M.db.newctx(ret, opt)
    _M.file.newctx(ret, opt)
    return ret
end

function _M.db2file(ctx)
    _M.db.load(ctx)
    _M.file.save(ctx)
end

function _M.file2db(ctx)
    _M.file.load(ctx)
    _M.db.save(ctx)
end

return _M
