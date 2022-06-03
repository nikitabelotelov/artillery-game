-- Playdate CoreLibs: Animation addons
-- Copyright (C) 2014 Panic, Inc.


playdate.graphics.animation = playdate.graphics.animation or {}

--! **** Animation Loops ****
playdate.graphics.animation.loop = {}

local loopAnimation = playdate.graphics.animation.loop
loopAnimation.__index = loopAnimation


local floor = math.floor

local function updateLoopAnimation(loop, force)

	if loop.paused == true and force ~= true then
		return
	end

	local startTime = loop.t
	local elapsedTime = playdate.getCurrentTimeMilliseconds() - startTime
	local frame = loop.startFrame + floor(elapsedTime / loop.delay) * loop.step

	if loop.loop or frame <= loop.endFrame then
		local startFrame = loop.startFrame
		local numFrames = loop.endFrame + 1 - startFrame
		loop.currentFrame = ((frame-startFrame) % numFrames) + startFrame
	else
		loop.currentFrame = loop.endFrame
		loop.valid = false
	end
end


local nag1 = true
local nag2 = true
local nag3 = true

loopAnimation.__index = function(table, key)

	if key == "frame" then
		updateLoopAnimation(table)
		return table.currentFrame

	elseif key == "paused" then
		return table._paused

	elseif key == "start" then
		if nag1 == true then
			print("playdate.graphics.animation.loop.start has been renamed to playdate.graphics.animation.loop.startFrame. `start` will still work now but is depricated and will be removed in the future.")
			nag1 = false
		end
		return table.startFrame

	elseif key == "end" then
		if nag2 == true then
			print("playdate.graphics.animation.loop.stop has been renamed to playdate.graphics.animation.loop.endFrame. `stop` will still work now but is depricated and will be removed in the future.")
			nag2 = false
		end
		return table.endFrame

	else
		return rawget(loopAnimation, key)
	end
end


loopAnimation.__newindex = function(table, key, value)

	if key == "frame" then
		local newFrame = math.floor(tonumber(value))
		assert(newFrame ~= nil, "playdate.graphics.animation.loop.frame must be an number")
		local newFrame = math.min(table.endFrame, math.max(table.startFrame, value))
		local frameOffset = newFrame - table.startFrame
		table.t = playdate.getCurrentTimeMilliseconds() - (frameOffset * table.delay)
		table.valid = true
		updateLoopAnimation(table, true)

	elseif key == "paused" then

		assert(value == true or value == false, "playdate.graphics.animation.loop.paused can only be set to true or false")

		if value == true and table._paused == false then
			table.pauseTime = playdate.getCurrentTimeMilliseconds()
		elseif value == false and table._paused == true then
			local elapsedPauseTime = table.pauseTime - playdate.getCurrentTimeMilliseconds()
			table.pauseTime = nil
			table.t -= elapsedPauseTime -- offset the original pause time so unpausing carries on at the same frame as when the loop was paused
		end

		table._paused = value
	
	elseif key == "shouldLoop" then

		assert(value == true or value == false, "playdate.graphics.animation.loop.loop can only be set to true or false")

		if table.valid == false and value == true then
			-- restart the loop if necessary
			table.valid = true
			table.t = playdate.getCurrentTimeMilliseconds()
		end
		
		if value == false then
			-- adjust the start time of the loop so that it's what it would have been if the loop started at the beginning of this cycle
			local currentTime = playdate.getCurrentTimeMilliseconds()
			local oneLoopDuration = table.delay * (table.endFrame - table.startFrame + 1)
			table.t += (floor((currentTime - table.t) / oneLoopDuration) * oneLoopDuration)			
		end
		
		table.loop = value

	elseif key == "start" then
		table.startFrame = value
		if nag1 == true then
			print("playdate.graphics.animation.loop.start has been renamed to playdate.graphics.animation.loop.startFrame. `start` will still work now but is depricated and will be removed in the future.")
			nag1 = false
		end

	elseif key == "stop" then
		table.endFrame = value
		if nag2 == true then
			print("playdate.graphics.animation.loop.stop has been renamed to playdate.graphics.animation.loop.endFrame. `stop` will still work now but is depricated and will be removed in the future.")
			nag2 = false
		end
	elseif key == "remove" then
		if nag3 == true then
		print("playdate.graphics.animation.loop.stop has been removed. Instead, simply don't call playdate.graphics.animation.loop:draw(x, y).")
			nag3 = false
		end
	else
		rawset(table, key, value)
	end
end


function loopAnimation.new(delay, imageTable, shouldLoop)

	assert(delay~=loopAnimation, 'Please use loop.new() instead of loop:new()')

	local o = {}

	o.delay = delay or 100
	o.startFrame = 1
	o.currentFrame = 1
	o.endFrame = 1
	o.step = 1
	o.loop = shouldLoop ~= false
	o._paused = false
	o.valid = true
	o.t = playdate.getCurrentTimeMilliseconds()

	if imageTable ~= nil then
		o.imageTable = imageTable
		o.endFrame = #imageTable
	else
		imageTable = nil
	end

	setmetatable(o, loopAnimation)
	return o
end


function loopAnimation:setImageTable(it)
	self.imageTable = it
	if it ~= nil then
		self.endFrame = #it
	end
end


function loopAnimation:isValid()
	return self.valid
end


function loopAnimation:image()
	if self.imageTable ~= nil then
		return self.imageTable[self.frame]
	end
	return nil
end


function loopAnimation:draw(x, y, flipped)
	local img = self:image()
	if img ~= nil then
		img:draw(x, y, flipped)
		return true
	end
	return false
end


--! **** Blinkers ****
playdate.graphics.animation.blinker = {}

local blinker = playdate.graphics.animation.blinker
blinker.__index = blinker

blinker.allBlinkers = {}
blinker.needsRemoval = false

function blinker.new(o)
  assert(o~=blinker, 'Please use blinker.new() instead of blinker:new()')

  o = o or {}
  setmetatable(o, blinker)

  o.t = 0

  o.counter = 0
  if o.cycles == nil then o.cycles = 6 end

  if o.onDuration == nil then o.onDuration = 200 end
  if o.offDuration == nil then o.offDuration = 200 end

  if o.default == nil then o.default = true end
  o.on = o.default

  if o.loop == nil then o.loop = false end

  o.running = false

  o.valid = true

  table.insert(blinker.allBlinkers, o)

  return o
end

local function removeInvalidBlinkers()
  -- find blinkers to remove

  for l = #blinker.allBlinkers, 1, -1 do

    local blinkerToCheck = blinker.allBlinkers[l]

    if not blinkerToCheck.valid then
      table.remove(blinker.allBlinkers, l)
    end

  end

  blinker.needsRemoval = false

end

function blinker:updateAll()
  for i=1, #blinker.allBlinkers do
    blinker.allBlinkers[i]:update()
	end

  if blinker.needsRemoval then removeInvalidBlinkers() end
end

function blinker:update()

  if not self.running then return end
  local elapsedTime = playdate.getCurrentTimeMilliseconds()

  if elapsedTime - self.t >= self.onDuration and self.counter > 0 and self.on then

    self.t = elapsedTime
    self.on = not self.on
    self.counter = self.counter - 1

  elseif elapsedTime - self.t >= self.offDuration and self.counter > 0 and not self.on then
    self.t = elapsedTime
    self.on = not self.on
    self.counter = self.counter - 1

  elseif self.counter == 0 then
    self.on = self.default
    self.t = 0
    self.running = false

    if self.loop then self:start() end

  end

end

function blinker:startLoop()
  self.loop = true
  self:start()
end

function blinker:start()
  self.counter = self.cycles
  self.t = playdate.getCurrentTimeMilliseconds()
  self.running = true
end

function blinker:stop()
  self.counter = 0
  self.on = self.default
  self.loop = false
  self.running = false
end

function blinker.stopAll()
  for i=1, #blinker.allBlinkers do
    blinker.allBlinkers[i]:stop()
	end

end

function blinker:remove()
  self.valid = false
  blinker.needsRemoval = true
end
