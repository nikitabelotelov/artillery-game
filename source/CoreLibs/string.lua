playdate.string = {}

function playdate.string.UUID(length)
  str = ""
  for i=1, length do str = str..string.char(math.random(65, 90)) end
  return str
end

string.getTextSize = playdate.graphics.getTextSize

-- trim7() from http://lua-users.org/wiki/StringTrim
local match = string.match
function playdate.string.trimWhitespace(str)
   return match(str,'^()%s*$') and '' or match(str,'^%s*(.*%S)')
end

function playdate.string.trimLeadingWhitespace(str)
   return match(str,'^%s*(.+)')
end

function playdate.string.trimTrailingWhitespace(str)
   return match(str,'(.-)%s*$')
end
