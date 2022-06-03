
function playdate.getDeviceOrientation()

	if not playdate.accelerometerIsRunning() then
		playdate.startAccelerometer()
	end
	
	local x,y,z = playdate.readAccelerometer()
	
	local r = math.sqrt(x*x+y*y)
	
	if z > r then return "on back" end
	if z < -r then return "on front" end

	if y > math.abs(x) then return "standing up" end
	if y < -math.abs(x) then return "upside down" end
	if x > math.abs(y) then return "on right" end
	--if x < -math.abs(y) then return "onLeft" end
	return "on left"
end

function playdate.getPitchAndRoll()

	if not playdate.accelerometerIsRunning() then
		playdate.startAccelerometer()
	end
	
	local x,y,z = playdate.readAccelerometer()
	
	local pitch = math.atan2(y, z) * 180.0 / math.pi;
	local roll  = math.atan2(x, math.sqrt(y*y + z*z)) * 180.0 / math.pi;

	return pitch, roll
end
