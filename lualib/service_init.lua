-- Auto start model.

local args = table.pack(...)

assert(#args >= 1)

local service_provider = require 'service_provider'
local mod = require(args[1])

service_provider.init(mod, select(2, ...))
