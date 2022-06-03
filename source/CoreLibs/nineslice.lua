import 'CoreLibs/graphics'

local floor = math.floor
local newRect = playdate.geometry.rect.new
local loadImage = playdate.graphics.image.new
local newImage = playdate.graphics.image.new
local kColorClear = playdate.graphics.kColorClear
local pushContext = playdate.graphics.pushContext
local popContext = playdate.graphics.popContext
local insert = table.insert

playdate.graphics.nineSlice = { }
playdate.graphics.nineSlice.__index = playdate.graphics.nineSlice

function playdate.graphics.nineSlice.new(imagePath, innerX, innerY, innerWidth, innerHeight)

	assert(imagePath~=playdate.graphics.nineSlice, 'Please use playdate.graphics.nineSlice.new() instead of playdate.graphics.nineSlice:new()')

	local ns = {
		innerRect = nil, -- playdate.geometry.rect
		slices = nil, -- table of playdate.graphics.images
		cache = nil, -- playdate.graphics.image
		cacheWidth = 0,
		cacheHeight = 0,
		minWidth = 0,
		minHeight = 0,
	}

	local image = loadImage(imagePath)
	local w,h = image:getSize()

	local leftWidth = innerX
	local topHeight = innerY
	local rightWidth = w - (innerX + innerWidth)
	local bottomHeight = h - (innerY + innerHeight)

	ns.minWidth = leftWidth + rightWidth
	ns.minHeight = topHeight + bottomHeight
	ns.innerRect = newRect(innerX, innerY, innerWidth, innerHeight)

	-- cache slices
	local rects = {
		0,0,leftWidth,topHeight, -- top left
		innerX,0,innerWidth,topHeight, -- top center
		innerX+innerWidth,0,rightWidth,topHeight, -- top right

		0,topHeight,leftWidth,innerHeight, -- middle left
		innerX,topHeight,innerWidth,innerHeight, -- middle center
		innerX+innerWidth,topHeight,rightWidth,innerHeight, -- middle right

		0,topHeight+innerHeight,leftWidth,bottomHeight, -- bottom left
		innerX,topHeight+innerHeight,innerWidth,bottomHeight, -- bottom center
		innerX+innerWidth,topHeight+innerHeight,rightWidth,bottomHeight, -- bottom right
	}

	local t = #rects
	local slices = {}
	local slice

	for i=1,t,4 do
		slice = newImage(rects[i+2],rects[i+3],kColorClear)
		pushContext(slice)
		image:draw(-rects[i],-rects[i+1])
		popContext()
		insert(slices, slice)
	end

	ns.slices = slices

	setmetatable(ns, playdate.graphics.nineSlice)
	return ns
end


function playdate.graphics.nineSlice:getSize()
	return self.cacheWidth,self.cacheHeight
end


function playdate.graphics.nineSlice:getMinSize()
	return self.minWidth,self.minHeight
end


local function prerender(ns, width, height)

	ns.cacheWidth = width
	ns.cacheHeight = height

	local ix,iy,iw,ih = ns.innerRect:unpack()
	local mw,mh = ns.minWidth,ns.minHeight

	iw = width - mw
	ih = height - mh

	local slices = ns.slices
	local cache = newImage(width,height,kColorClear)
	pushContext(cache)

	slices[1]:draw(0,0)
	if iw>0 then
		slices[2]:drawTiled(ix,0,iw,iy)
	end
	slices[3]:draw(ix+iw,0)

	if ih>0 then
		slices[4]:drawTiled(0,iy,ix,ih)
		if iw>0 then
			slices[5]:drawTiled(ix,iy,iw,ih)
		end
		slices[6]:drawTiled(ix+iw,iy,width-(ix+iw),ih)
	end

	slices[7]:draw(0,iy+ih)
	if iw>0 then
		slices[8]:drawTiled(ix,iy+ih,iw,height-(iy+ih))
	end
	slices[9]:draw(ix+iw,iy+ih)

	popContext()
	ns.cache = cache
end


function playdate.graphics.nineSlice:drawInRect(x, ...)

	local y, w, h
	if (type(x) == "userdata") then		-- check if x is a playdate.geometry.rect object
		x, y, w, h = x.x, x.y, x.width, x.height
	else
		y, w, h = select(1, ...)
	end

	local w = floor(w)
	local h = floor(h)

	if w < self.minWidth then w = self.minWidth end
	if h < self.minHeight then h = self.minHeight end

	if w ~= self.cacheWidth or h ~= self.cacheHeight then
		prerender(self, w, h)
	end
	if self.cache then
		self.cache:draw(x,y)
	end
end
