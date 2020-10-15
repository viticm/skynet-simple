#!/bin/sh

# Current lua check use: https://github.com/mpeterv/luacheck
# On linux: luarocks install luacheck
# Use vim plugin ale with luacheck.

checker=3rd/lua-checker/lua_checker
checker_s=3rd/lua-checker/lua_simplifier
temp_dir=./lua-checker-t

function die() {
  local message=${@}
  echo ${message} && exit 1
}


[[ ! -x $checker || ! -x $checker_s ]] && die "can't find the lua checker"

rm -rf ${temp_dir}
mkdir -p ${temp_dir}

files=`find lualib -name "*.lua"`

for file in $files
do
  dname=`dirname $file`
  mkdir -p ${temp_dir}/$dname
  ${checker_s} -emit_lines $file > ${temp_dir}/$file
done

echo "success"
