import 'CoreLibs/timer'
import 'CoreLibs/assets/crank-notice-bubble.png'
import 'CoreLibs/assets/crank-notice-text.png'
import 'CoreLibs/assets/crank-frames-table-52-38.png'

local gfx = playdate.graphics
playdate.ui = playdate.ui or {}

local crankIndicatorY = 210 

playdate.ui.crankIndicator = {
	clockwise = true,
	currentFrame = 0,
	textImage = gfx.image.new('CoreLibs/assets/crank-notice-text'),
	bubble = gfx.image.new('CoreLibs/assets/crank-notice-bubble'),
	frames = gfx.imagetable.new('CoreLibs/assets/crank-frames'),
	textTimer = nil
}

if playdate.getFlipped() then
	local flippedImage = gfx.image.new( playdate.ui.crankIndicator.bubble.width, playdate.ui.crankIndicator.bubble.height )
	gfx.pushContext( flippedImage )
	playdate.ui.crankIndicator.bubble:draw( 0, 0, gfx.kImageFlippedXY )
	gfx.popContext()
	playdate.ui.crankIndicator.bubble = flippedImage
end

-- makes the api a little clearer to have a :start() method.
function playdate.ui.crankIndicator:start()
	self.currentFrame = 0

	self.bubbleWidth, self.bubbleHeight = self.bubble:getSize()
	self.bubbleX = playdate.display.getWidth() - self.bubbleWidth
	self.bubbleY = crankIndicatorY - self.bubbleHeight / 2
	
	-- left-handed mode
	if playdate.getFlipped() then
		self.bubbleX = 0
		self.bubbleY = 240 - crankIndicatorY - self.bubbleHeight / 2
	end
	
	self.textTimer = playdate.timer.new(700, function()
		playdate.ui.crankIndicator.currentFrame = 1
		playdate.ui.crankIndicator.textTimer = nil
	end)
end

function playdate.ui.crankIndicator:update(xOffset)

	assert( self.bubbleX, "Please call playdate.ui.crankIndicator:start() before calling :update()" )
		
	xOffset = xOffset or 0
	
	gfx.pushContext()
	
	gfx.setImageDrawMode( gfx.kDrawModeCopy )
	
	self.bubble:draw(self.bubbleX + xOffset, self.bubbleY)
	
	local limitFrames = #self.frames * 3
	if self.currentFrame == limitFrames then
		self:start()		
	end
	
	if self.currentFrame > 0 and self.currentFrame <= limitFrames then
		local frame = nil
		if self.clockwise then
			frame = self.frames[self.currentFrame % #self.frames + 1]
		else
			frame = self.frames[(#self.frames - self.currentFrame + 1) % #self.frames + 1]
		end
		local frameWidth, frameHeight = frame:getSize()
		frame:draw(self.bubbleX + (76 - frameWidth) / 2 + xOffset, self.bubbleY + (self.bubbleHeight - frameHeight) / 2)
		self.currentFrame += 1
	else
		local textWidth, textHeight = self.textImage:getSize()
		local textOffset = 76
		if playdate.getFlipped() then 
			textOffset = 100
		end
		self.textImage:draw(self.bubbleX + (textOffset - textWidth) / 2 + xOffset, self.bubbleY + (self.bubbleHeight - textHeight) / 2)
	end
	
	gfx.popContext()
	
end
