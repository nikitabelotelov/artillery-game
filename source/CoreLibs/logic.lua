-- Playdate CoreLibs: Logic
-- Copyright (C) 2015 Panic, Inc.

import "CoreLibs/object"

if not playdate.math then 
  playdate.math = {}
end

playdate.math.logic = {}
local logic = playdate.math.logic

function logic.nor(bool1, bool2)
  if not bool1 and not bool2 then return true end
  
  return false
end

function logic.xor(bool1, bool2)
  if bool1 and bool2 then return false end
  if not bool1 and not bool2 then return false end
  
  return true  
end

function logic.nand(bool1, bool2)
  if bool1 and bool2 then return false end
  
  return true
end

function logic.nxor(bool1, bool2)
  return not logic.xor (bool1, bool2)
end
