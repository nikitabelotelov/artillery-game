-- Playdate CoreLibs: Sprites
-- Copyright (C) 2014 Panic, Inc.

import "CoreLibs/animator"
import "CoreLibs/object"


local Rect = playdate.geometry.rect
local Point = playdate.geometry.point
local gfx = playdate.graphics
local spritelib = gfx.sprite


local newfunc = spritelib.new


-- make sprite inherit from Object
spritelib.__index = spritelib
spritelib.super = Object
setmetatable(spritelib, Object)
spritelib.className = "Sprite"


-- Object's "extends" function uses the result of this function to allow inheritance from non-Object types
spritelib.baseObject = newfunc


-- init function for Object subclass
function spritelib.init(self, imageOrTilemap)

	if ( type(imageOrTilemap) == 'string' ) then
		print("init('" .. imageOrTilemap .. "'): sprite.init() no longer accepts a file name as an argument")
	end

	if imageOrTilemap ~= nil then
		if getmetatable(imageOrTilemap) == gfx.image then
			self:setImage(imageOrTilemap)
		elseif getmetatable(imageOrTilemap) == gfx.tilemap then
			self:setTilemap(imageOrTilemap)
		end
	end

	self:moveTo(0,0)

end


-- allow sprites to work without using object.lua
function spritelib.new(arg1, arg2)
	local o = newfunc()
	o:init(arg2 or arg1) -- allow for both spritelib.new() and spritelib:new()

	return o
end


function spritelib.performOnAllSprites(func)
	local allSprites = spritelib:getAllSprites()
	for i = 1, #allSprites do
		func(allSprites[i])
	end
end

local _moveWithCollisions = spritelib.moveWithCollisions
function spritelib:moveWithCollisions(x, y)

	if y == nil then	-- assume playdate.geometry.point was passed
		x, y = x.x, x.y
	end

	local actualX, actualY, cols, l = _moveWithCollisions(self, x, y)

	return self.x, self.y, cols, l
end

local _checkCollisions = spritelib.checkCollisions
function spritelib:checkCollisions(x, y)

	if y == nil then
		x, y = x.x, x.y
	end

	local actualX, actualY, cols, l = _checkCollisions(self, x, y)
	return actualX, actualY, cols, l
end


local _copy = spritelib.copy
function spritelib:copy()
	local copy = _copy(self)
	setmetatable(copy, getmetatable(self))	
	return copy
end


function spritelib.addEmptyCollisionSprite(x, ...)

	local y, w, h, radius
	if (type(x) == "userdata") then		-- check if x is a playdate.geometry.rect object
		x, y, w, h = x.x, x.y, x.width, x.height
		radius = select(1, ...)
	else
		y, w, h, radius = select(1, ...)
	end
	
	local sprite = spritelib.new()
	sprite:setBounds(x, y, w, h)
	sprite:setCollideRect(0, 0, w, h)
	sprite:setUpdatesEnabled(false)
	sprite:setVisible(false)
	sprite:add()
	return sprite
end


function spritelib.addWallSprites(tilemap, emptyIDs, xOffset, yOffset)

	xOffset = xOffset or 0
	yOffset = yOffset or 0

	local tileWidth, tileHeight = tilemap:getSize()
	local pixelsWide, pixelsHigh = tilemap:getPixelSize()
	local tileWidthInPixels = pixelsWide / tileWidth
	local tileHeightInPixels = pixelsHigh / tileHeight

	local collisionRects = tilemap:getCollisionRects((emptyIDs or {}))
	local wallSprites = {}

	for i = 1, #collisionRects do
		
		local r = collisionRects[i]
		
		-- Create an invisible sprite (no image or update()) to be used by the collision system
	
		local x = r.x * tileWidthInPixels
		local y = r.y * tileHeightInPixels		
		local w = r.width * tileWidthInPixels
		local h = r.height * tileHeightInPixels
	
		local sprite = spritelib.new()
		sprite:setBounds(x+xOffset, y+yOffset, w, h)
		sprite:setCollideRect(0, 0, w, h)
		sprite:setUpdatesEnabled(false)
		sprite:setVisible(false)
		sprite:add()
	
		wallSprites[i] = sprite
	end

	return wallSprites
end

local bgsprite

function spritelib.setBackgroundDrawingCallback(drawCallback)
	bgsprite = gfx.sprite.new()
	bgsprite:setSize(playdate.display.getSize())
	bgsprite:setCenter(0, 0)
	bgsprite:moveTo(0, 0)
	bgsprite:setZIndex(-32768)
	bgsprite:setIgnoresDrawOffset(true)
	bgsprite:setUpdatesEnabled(false)
	bgsprite.draw = function(s, x, y, w, h)
			drawCallback(x, y, w, h)
		end
	bgsprite:add()
	return bgsprite
end

function spritelib.redrawBackground()
	if bgsprite ~= nil then bgsprite:markDirty() end
end

function spritelib:setAnimator(animator, moveWithCollisions, removeOnCollision)
	
	assert(getmetatable(animator) == playdate.graphics.animator, "`animator` must be of type CoreLibs/animator")
	if animator.startValue ~= nil then
		assert(type(animator.startValue ~= "number", "`animator` must not be a number-based animator."))
	end
	if moveWithCollisions then
		assert(self:getCollideRect() ~= nil, "Sprite must have a collideRect set to move with collisions.")
	end
	
	if self._animator ~= nil then
		self:removeAnimator()
	end
		
	self._update = self.update
	self._animator = animator

	self.update = function()

		if self._animator ~= nil then
			local p = self._animator:currentValue()
			
			if moveWithCollisions == nil or moveWithCollisions ~= true then
				self:moveTo(p)
			else
				local _, _, _, length = self:moveWithCollisions(p)
				if removeOnCollision == true and length > 0 then
					self:removeAnimator()
				end
			end
			
			if self._animator ~= nil and self._animator:ended() then
				self:removeAnimator()
			end
		end
		
		if self._update ~= nil then self:_update() end
	end
	
end


function spritelib:removeAnimator()
	self._animator = nil
	self.update = self._update
end
