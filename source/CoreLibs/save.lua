
store = playdate.datastore.read("save") or {}

playdate.save = playdate.save or {}

function playdate.save.write(key, value)
	local t = store
	local p = string.find(key, "%.")
	
	while p ~= nil do

		local k = key:sub(0,p-1)
		local subt = t[k]
		
		if sub ~= nil then
			t = subt
		else
			subt = {}
			t[k] = subt
			t = subt
		end
		
		key = key:sub(p+1)
		p = string.find(key, "%.")
	end

	t[key] = value
end

function playdate.save.read(key)
	local t = store
	
	for i in string.gmatch(key, "[^%.]+") do
		t = t[i]
		
		if t == nil then return nil end
	end

	return t
end

function playdate.save.synchronize()
	playdate.datastore.write(store, "save")
end
