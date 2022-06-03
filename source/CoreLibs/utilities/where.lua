-- where() returns a single-line stack trace
local getinfo = debug.getinfo
local insert = table.insert
local concat = table.concat

function where()
	
	local ret = {}

	local o = 2 -- the function/file that called this one
	local _ = getinfo(o)
	while _ do
		if #ret > 0 then
			insert(ret, ' < ')
		end
		insert(ret, _.short_src)
		insert(ret, ':')
		insert(ret, _.currentline)
		local name = _.name or _.what
		if name ~= 'main' then
			local isFunc = false
			if name == 'Lua' then 
				if _.istailcall then
					name = '(tail call)'
				else
					name = '(from C)'
				end
			else
				isFunc = true
			end
			insert(ret, ' ')
			insert(ret, name)
			if isFunc then
				insert(ret, '()')
			end
		end
		
		o += 1
		_ = getinfo(o)
	end
	return concat(ret, '')
end