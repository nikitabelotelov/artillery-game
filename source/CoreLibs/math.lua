if playdate.math == nil then
	playdate.math = {}
end


function playdate.math.lerp(min, max, t)
	return min + (max - min) * t
end
