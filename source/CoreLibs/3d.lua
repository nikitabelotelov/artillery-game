
patterns =
{
	{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
	{ 0x80, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00 },
	{ 0x88, 0x00, 0x00, 0x00, 0x88, 0x00, 0x00, 0x00 },
	{ 0x88, 0x00, 0x20, 0x00, 0x88, 0x00, 0x02, 0x00 },
	{ 0x88, 0x00, 0x22, 0x00, 0x88, 0x00, 0x22, 0x00 },
	{ 0xa8, 0x00, 0x22, 0x00, 0x8a, 0x00, 0x22, 0x00 },
	{ 0xaa, 0x00, 0x22, 0x00, 0xaa, 0x00, 0x22, 0x00 },
	{ 0xaa, 0x00, 0xa2, 0x00, 0xaa, 0x00, 0x2a, 0x00 },
	{ 0xaa, 0x00, 0xaa, 0x00, 0xaa, 0x00, 0xaa, 0x00 },
	{ 0xaa, 0x40, 0xaa, 0x00, 0xaa, 0x04, 0xaa, 0x00 },
	{ 0xaa, 0x44, 0xaa, 0x00, 0xaa, 0x44, 0xaa, 0x00 },
	{ 0xaa, 0x44, 0xaa, 0x10, 0xaa, 0x44, 0xaa, 0x01 },
	{ 0xaa, 0x44, 0xaa, 0x11, 0xaa, 0x44, 0xaa, 0x11 },
	{ 0xaa, 0x54, 0xaa, 0x11, 0xaa, 0x45, 0xaa, 0x11 },
	{ 0xaa, 0x55, 0xaa, 0x11, 0xaa, 0x55, 0xaa, 0x11 },
	{ 0xaa, 0x55, 0xaa, 0x51, 0xaa, 0x55, 0xaa, 0x15 },
	{ 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55 },
	{ 0xba, 0x55, 0xaa, 0x55, 0xab, 0x55, 0xaa, 0x55 },
	{ 0xbb, 0x55, 0xaa, 0x55, 0xbb, 0x55, 0xaa, 0x55 },
	{ 0xbb, 0x55, 0xea, 0x55, 0xbb, 0x55, 0xae, 0x55 },
	{ 0xbb, 0x55, 0xee, 0x55, 0xbb, 0x55, 0xee, 0x55 },
	{ 0xfb, 0x55, 0xee, 0x55, 0xbf, 0x55, 0xee, 0x55 },
	{ 0xff, 0x55, 0xee, 0x55, 0xff, 0x55, 0xee, 0x55 },
	{ 0xff, 0x55, 0xfe, 0x55, 0xff, 0x55, 0xef, 0x55 },
	{ 0xff, 0x55, 0xff, 0x55, 0xff, 0x55, 0xff, 0x55 },
	{ 0xff, 0x55, 0xff, 0xd5, 0xff, 0x55, 0xff, 0x5d },
	{ 0xff, 0x55, 0xff, 0xdd, 0xff, 0x55, 0xff, 0xdd },
	{ 0xff, 0x75, 0xff, 0xdd, 0xff, 0x57, 0xff, 0xdd },
	{ 0xff, 0x77, 0xff, 0xdd, 0xff, 0x77, 0xff, 0xdd },
	{ 0xff, 0x77, 0xff, 0xfd, 0xff, 0x77, 0xff, 0xdf },
	{ 0xff, 0x77, 0xff, 0xff, 0xff, 0x77, 0xff, 0xff },
	{ 0xff, 0xf7, 0xff, 0xff, 0xff, 0x7f, 0xff, 0xff },
	{ 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff }
}


-- vector3d

vector3d = { x = 0, y = 0, z = 0 }
vector3d.__index = vector3d

function vector3d.new(x, y, z)
	return setmetatable({x = x, y = y, z = z}, vector3d)
end

function vector3d:__add(v)
	return vector3d.new(self.x + v.x, self.y + v.y, self.z + v.z)
end

function vector3d:__sub(v)
	return vector3d.new(self.x - v.x, self.y - v.y, self.z - v.z)
end

function vector3d:dot(v)
	return self.x * v.x + self.y * v.y + self.z * v.z
end

function vector3d:cross(v)
	return vector3d.new(self.y * v.z - self.z * v.y, self.z * v.x - self.x * v.z, self.x * v.y - self.y * v.x);
end

function vector3d:length()
	return math.sqrt(self.x*self.x + self.y*self.y + self.z*self.z)
end

function vector3d:__mul(s)
	return vector3d.new(self.x * s, self.y * s, self.z * s)
end

function vector3d:__div(s)
	return self:__mul(1/s)
end

function vector3d:__tostring()
	return "vector3d ("..self.x..", "..self.y..", "..self.z..")"
end

function vector3d:rotateAroundY(angle)
	local z = self.z * math.cos(angle) - self.x * math.sin(angle)
	local x = self.z * math.sin(angle) + self.x * math.cos(angle)
	
	self.x = x
	self.z = z
end

function vector3d:rotateAroundX(angle)
	local y = self.y * math.cos(angle) - self.z * math.sin(angle)
	local z = self.y * math.sin(angle) + self.z * math.cos(angle)
	
	self.y = y
	self.z = z
end

function vector3d:copy()
	return vector3d.new(self.x, self.y, self.z)
end


-- face3d

face3d = {}
face3d.__index = face3d

function face3d.new(v1, v2, v3)
	return setmetatable({v1 = v1:copy(), v2 = v2:copy(), v3 = v3:copy()}, face3d)
end

function face3d:normal()
	local c = (self.v2 - self.v1):cross(self.v3 - self.v1)
	return c / c:length()
end

function face3d:isFacingForward()
	-- XXX - assuming fixed camera
	-- compute z component only of cross product
	local dx1 = self.v2.x - self.v1.x
	local dy1 = self.v2.y - self.v1.y
	local dx2 = self.v3.x - self.v1.x
	local dy2 = self.v3.y - self.v1.y
	
	return (dx1 * dy2 - dx2 * dy1) > 0
end

function face3d:__tostring()
	return "{ "..tostring(self.v1)..", "..tostring(self.v2)..", "..tostring(self.v3).." }"
end


-- shape3d

shape3d = { }
shape3d.__index = shape3d

function shape3d.new()
	return setmetatable({ faces = {} }, shape3d)
end

function shape3d:addFace(v1, v2, v3)
	self.faces[#self.faces+1] = face3d.new(v1, v2, v3)
end

function shape3d:rotateAroundY(angle)
	for index, face in pairs(self.faces)
	do
		face.v1:rotateAroundY(angle)
		face.v2:rotateAroundY(angle)
		face.v3:rotateAroundY(angle)
	end
end

function shape3d:rotateAroundX(angle)
	for index, face in pairs(self.faces)
	do
		face.v1:rotateAroundX(angle)
		face.v2:rotateAroundX(angle)
		face.v3:rotateAroundX(angle)
	end
end

function shape3d:drawInScene(scene)
	
	local light = scene.light
	local gfx = playdate.graphics
	
	for index, face in pairs(self.faces)
	do
		if face:isFacingForward()
		then
			local color = scene:lightmap(face:normal():dot(light))
			
			gfx.setPattern(patterns[1 + math.floor(#patterns * color)])

			gfx.fillTriangle(200 + 120 * face.v1.x, 120 - 120 * face.v1.y,
							 200 + 120 * face.v2.x, 120 - 120 * face.v2.y,
							 200 + 120 * face.v3.x, 120 - 120 * face.v3.y)
		end
	end
end

function shape3d:drawWireframeInScene(scene)
	
	local gfx = playdate.graphics
	
	for index, face in pairs(self.faces)
	do
		local x1, y1 = 200 + 120 * face.v1.x, 120 - 120 * face.v1.y
		local x2, y2 = 200 + 120 * face.v2.x, 120 - 120 * face.v2.y
		local x3, y3 = 200 + 120 * face.v3.x, 120 - 120 * face.v3.y
		
		gfx.drawLine(x1, y1, x2, y2)
		gfx.drawLine(x2, y2, x3, y3)
		gfx.drawLine(x3, y3, x1, y1)
	end
end

function shape3d:scaleBy(scale)
	for index, face in pairs(self.faces)
	do
		face.v1 = face.v1 * scale
		face.v2 = face.v2 * scale
		face.v3 = face.v3 * scale
	end
end


-- scene3d

scene3d = { light = vector3d.new(0, 0, 1) }
scene3d.__index = scene3d

function scene3d.new()
	return setmetatable({ shapes = {} }, scene3d)
end

function scene3d:addShape(s)
	self.shapes[#self.shapes+1] = s
end

function scene3d:setLight(v)
	self.light = v
end

function scene3d:draw()
	-- no perspective, camera is looking at origin
	-- y=1 maps to top of screen, y=-1 to bottom
	
	for index, shape in pairs(self.shapes)
	do
		shape:drawInScene(self)
	end
end

function scene3d:drawWireframe()
	for index, shape in pairs(self.shapes)
	do
		shape:drawWireframeInScene(self)
	end
end

function scene3d:lightmap(dot)
	-- input is face:normal():dot(light), output is brightness, 0-1
	local c = (1 + dot) / 2
	return c * c
end

