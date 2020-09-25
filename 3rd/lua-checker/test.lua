
-- Test lexxing of numeric formats.
a = 0x123abc
a = 123
a = 123e99
a = 123e+99
a = 123e-99
a = .123
a = .123e99
a = .123e+99
a = .123e-99
a = 123.
a = 123.e99
a = 123.e+99
a = 123.e-99
a = 123.456
a = 123.456e99
a = 123.456e+99
a = 123.456e-99

dofile "tmp/abc.lua"

-- Test syntactic sugar expansions.
function fn() end			-- Dummy function used below
tab = {}				-- Dummy table used below
a = a.name
fn{1, 2}
fn'string'
function tab.a.b.c.f() end
local function fn2() end
function tab.a.b.c:f(params) end
a1 = { foo=1 }
local a2
local a3,b3,c3
local a4 = 1
local a5,b5,c5 = 1,2,3

-- Test that these are not expanded.
tab:name(1,2,3)
tab.a.b.c:name(1,2,3)

-- Test arithmetic precedence is preserved.
a = 1 + 2*3
a = 1 + (2*3)
a = (1 + 2)*3
a = 1*2 + 3
a = (1*2) + 3
a = 1*(2 + 3)

-- Test numbers are preserved.
a = 1.23
a = 1.2345678901234567890123456789012345678901234567890
a = -1.234e-56
a = - -1.234e-56

-- Test string and long strings.
a = 'abc'
a = 'abc\ndef\123\ghi'
a = "abc"
a = "abc\ndef\123\ghi"
a = [[hello [=[blah]=]
world]]
a = [==[hello [[blah]] [=[blah]=]
world]==]

-- Test array tables
a = {'a', 'b', {true, false}, 'c', 'd', {11, 22, {33, {44}}}, 'blah'}

-- Test warnings about reused variables.
function foo()
  local a = 1
  a = 2
  local a = 3
  function bar1() end
  local function bar2()
    local a = 1
    a = 2
    local a = 3
  end
  local function bar2() end
end

-- Test warnings about constant variables.
X = 1 --@ const
X = 2
X2 = 1
X2 = 2 --@ const
function foo()
  X = 3
  local X = 4   --@ const
  local X = 5   --@ const
  local Y = 'a' --@ const
  Y = 'b'
  local function bar()
    Y = 'c'
    local Y = 'd'
    Y = 'e'
    local Y
  end
  bar = nil
end
function print() end
