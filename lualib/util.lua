--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id util.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/07/13 17:22
 - @uses The util functions tool for lua.
--]]
local _M = {}

local function _table2str(lua_table, raw_table, table_map, n, fold, indent)        
  indent = indent or 1                                                             
  for k, v in pairs(lua_table) do                                                  
    if type(k) == 'string' then                                                    
      k = string.format('%q', k)                                                   
    else                                                                           
      k = tostring(k)                                                              
    end                                                                            
    n = n + 1; raw_table[n] = string.rep('  ', indent)                             
    n = n + 1; raw_table[n] = '['                                                  
    n = n + 1; raw_table[n] = k                                                    
    n = n + 1; raw_table[n] = ']'                                                  
    n = n + 1; raw_table[n] = ' = '                                                
    if type(v) == 'table' then                                                     
      if fold and table_map[tostring(v)] then                                      
        n = n + 1; raw_table[n] = tostring(v)                                      
        n = n + 1; raw_table[n] = ',\n'                                            
      else                                                                         
        table_map[tostring(v)] = true                                              
        n = n + 1; raw_table[n] = '{\n'                                            
        n = _table2str(v, raw_table, table_map, n, fold, indent + 1)               
        n = n + 1; raw_table[n] = string.rep('  ', indent)                         
        n = n + 1; raw_table[n] = '},\n'                                           
      end                                                                          
    else                                                                           
      if type(v) == 'string' then                                                  
        v = string.format('%q', v)                                                 
      else                                                                         
        v = tostring(v)                                                            
      end                                                                          
      n = n + 1; raw_table[n] = v                                                  
      n = n + 1; raw_table[n] = ',\n'                                              
    end                                                                            
  end                                                                              
  return n                                                                         
end

-- Dump a table to string.
-- @param table lua_table The source table.
-- @param mixed fold
-- @return mixed
function _M.dump(lua_table, fold)
  if type(lua_table) == 'table' then                                               
    local raw_table = {}                                                           
    local table_map = {}                                                        
    table_map[tostring(lua_table)] = true                                       
    local n = 0                                                                 
    n = n + 1; raw_table[n] = '{\n'                                             
    n = _table2str(lua_table, raw_table, table_map, n, fold)                    
    n = n + 1; raw_table[n] = '}'                                               
    return table.concat(raw_table, '')                                          
  else                                                                          
    return lua_table                                                            
  end   
end
