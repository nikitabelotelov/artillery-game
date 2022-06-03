import 'CoreLibs/assets/keyboard/Roobert-24-Keyboard-Medium-table-36-36.png'
import 'CoreLibs/assets/keyboard/menu-del.png'
import 'CoreLibs/assets/keyboard/menu-cancel.png'
import 'CoreLibs/assets/keyboard/menu-ok.png'
import 'CoreLibs/assets/keyboard/menu-space.png'
import 'CoreLibs/assets/sfx/click.wav'
import 'CoreLibs/assets/sfx/denial.wav'
import 'CoreLibs/assets/sfx/key.wav'
import 'CoreLibs/assets/sfx/selection.wav'
import 'CoreLibs/assets/sfx/selection-reverse.wav'

local gfx <const> = playdate.graphics
local Point <const> = playdate.geometry.point
local Rect <const> = playdate.geometry.rect

local displayWidth <const>, displayHeight <const> = playdate.display.getSize()

local abs <const> = math.abs
local floor <const> = math.floor

local originalText = nil
local okButtonPressed = false

-- Keyboard Input Handler --

local KeyboardInput = {}

KeyboardInput.clickCWFunction = nil
KeyboardInput.clickCCWFunction = nil

local clickDegrees <const> = 360 / 15
local degreesSinceClick = 0

function KeyboardInput.cranked(change, acceleratedChange)
	
	degreesSinceClick += acceleratedChange

	local clickCount = 0

	if degreesSinceClick > clickDegrees then
		while degreesSinceClick > clickDegrees do
			clickCount += 1
			degreesSinceClick -= clickDegrees
		end
		degreesSinceClick = 0
	elseif degreesSinceClick < -clickDegrees then
		while degreesSinceClick < -clickDegrees do
			clickCount -= 1
			degreesSinceClick += clickDegrees
		end
		degreesSinceClick = 0
	end

	if clickCount > 0 then
		KeyboardInput.clickCWFunction(clickCount)
	elseif clickCount < 0 then
		KeyboardInput.clickCCWFunction(-clickCount)
	end
	
end


--! Easing Functions

local function linearEase(t, b, c, d)
  return c * t / d + b
end

local function outBackEase(t, b, c, d, s)
  if not s then s = 1.70158 end
  t = t / d - 1
  return floor(c * (t * t * ((s + 1) * t + s) + 1) + b)
end


--! Constants

playdate.keyboard = {}
local kb <const> = playdate.keyboard

kb.kCapitalizationNormal = 1
kb.kCapitalizationWords = 2
kb.kCapitalizationSentences = 3

local keyboardFont <const> = gfx.font.new('CoreLibs/assets/keyboard/Roobert-24-Keyboard-Medium')
local menuImageSpace <const> = gfx.image.new("CoreLibs/assets/keyboard/menu-space")
local menuImageOK <const> = gfx.image.new("CoreLibs/assets/keyboard/menu-ok")
local menuImageDelete <const> = gfx.image.new("CoreLibs/assets/keyboard/menu-del")
local menuImageCancel <const> = gfx.image.new("CoreLibs/assets/keyboard/menu-cancel")

local lowerColumn <const> = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"}
local upperColumn <const> = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}
local numbersColumn <const> = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0", ".", ",", ":", ";", "<", "=", ">", "?", "!", "'", '"', "#", "$", "%", "&", "(", ")", "*", "+", "-", "/", "|", "\\", "[", "]", "^", "_", "`", "{", "}", "~", "@"}
local menuColumn <const> = {menuImageSpace, menuImageOK, menuImageDelete, menuImageCancel}

local columns <const> = {numbersColumn, upperColumn, lowerColumn, menuColumn}
local columnCounts <const> = {#numbersColumn, #upperColumn, #lowerColumn, #menuColumn}
local columnShouldLoop <const> = {true, true, true, false}

local kAnimationTypeNone <const> = 1
local kAnimationTypeKeyboardShow <const> = 2
local kAnimationTypeKeyboardHide <const> = 3
local kAnimationTypeSelectionUp <const> = 4
local kAnimationTypeSelectionDown <const> = 5

local kColumnUpper <const> = 2
local kColumnLower <const> = 3
local kColumnSymbols <const> = 1
local kColumnMenu <const> = 4

local kMenuOptionSpace <const> = 1
local kMenuOptionOK <const> = 2
local kMenuOptionDelete <const> = 3
local kMenuOptionCancel <const> = 4

local rightMargin <const> = 8
local standardColumnWidth <const> = 36
local menuColumnWidth <const> = 50
local leftMargin <const> = 12

local keyboardWidth <const> = rightMargin + (standardColumnWidth * 3) + menuColumnWidth + leftMargin

local columnWidths <const> = {standardColumnWidth, standardColumnWidth, standardColumnWidth, menuColumnWidth}

local p1 <const> = leftMargin
local p2 <const> = p1 + columnWidths[1]
local p3 <const> = p2 + columnWidths[2]
local p4 <const> = p3 + columnWidths[3]

local columnPositions <const> = {p1, p2, p3, p4}

local rowHeight <const> = 38

--! Variables

local capitalizationBehavior = kb.capitalizationNormal

local selectColumn = nil -- forward declaration for function selectColumn(column)

local selectedColumn = kColumnUpper
local lastTypedColumn = kColumnUpper
local selectionIndexes = {1, 1, 1, 2}

local keyboardIsVisible = false
local keyboardJustOpened = true

local currentAnimationType = kAnimationTypeNone
local animationDuration = 0
local animationStartTime = 0
local animationTime = 0

local refreshRate = playdate.display.getRefreshRate()
local frameRateAdjustedScrollRepeatDelay = 6

local columnJiggle = 0
local rowJiggle = 0
local rowShift = 0

local selectionY = displayHeight / 2 - rowHeight / 2 - 2
local keyboardRect = Rect.new(displayWidth, 0, 0, displayHeight)
local selectedCharacterRect = Rect.new(columnPositions[selectedColumn], selectionY, columnWidths[selectedColumn], rowHeight)

kb.text = ''
kb.textChangedCallback = nil
kb.keyboardDidShowCallback = nil
kb.keyboardDidHideCallback = nil
kb.keyboardWillHideCallback = nil
kb.keyboardAnimatingCallback = nil

local playdateUpdate = nil
local keyboardUpdate = nil

local scrollRepeatDelay = 0
local scrollingVertically = false

-- Animation Variables
local selectionYOffset = 0
local selectionStartY


--! Sounds

local kSoundColumnMoveNext <const> = 'selection'
local kSoundColumnMovePrevious <const> = 'selection-reverse'
local kSoundRowMove <const> = 'click'
local kSoundBump <const> = 'denial'
local kSoundKeyPress <const> = 'key'

local columnNextSound = nil
local columnPreviousSound = nil
local rowSound = nil
local bumpSound = nil
local keySound = nil

local function playSound(name)
	
	if name == kSoundColumnMoveNext then
		if columnNextSound == nil then columnNextSound = playdate.sound.sampleplayer.new('CoreLibs/assets/sfx/'..name) end
		if columnNextSound ~= nil then columnNextSound:play() end
	elseif name == kSoundColumnMovePrevious then
		if columnPreviousSound == nil then	columnPreviousSound = playdate.sound.sampleplayer.new('CoreLibs/assets/sfx/'..name) end
		if columnPreviousSound ~= nil then columnPreviousSound:play() end
	elseif name == kSoundRowMove then
		if rowSound == nil then	rowSound = playdate.sound.sampleplayer.new('CoreLibs/assets/sfx/'..name) end
		if rowSound ~= nil then rowSound:play() end
	elseif name == kSoundBump then
		if bumpSound == nil then bumpSound = playdate.sound.sampleplayer.new('CoreLibs/assets/sfx/'..name) end
		if bumpSound ~= nil then bumpSound:play() end
	elseif name == kSoundKeyPress then
		if keySound == nil then keySound = playdate.sound.sampleplayer.new('CoreLibs/assets/sfx/'..name) end
		if keySound ~= nil then keySound:play() end
	end
end


--! Graphics

local fillRoundRect <const> = gfx.fillRoundRect


--! Draw

local function drawKeyboard()
	
	gfx.pushContext()
	
	local animating = (currentAnimationType == kAnimationTypeKeyboardShow or currentAnimationType == kAnimationTypeKeyboardHide)
	local columnOffsets = {}
	
	if animating == false then
		for i = 1, 4 do
			columnOffsets[i] = keyboardRect.x + columnPositions[i]
		end
	else
		local progress = keyboardRect.width / keyboardWidth
		for i = 1, 4 do
			columnOffsets[i] = keyboardRect.x + (columnPositions[i] * progress)
		end
	end

	local leftX = keyboardRect.x

	-- background
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
	gfx.setColor(gfx.kColorBlack)
	gfx.fillRect(leftX + 2, 0, displayWidth - leftX, displayHeight)
	gfx.setColor(gfx.kColorWhite)
	gfx.fillRect(leftX, 0, 2, displayHeight)

	-- selection
	local selectedRect = selectedCharacterRect:copy()
	selectedRect.x += leftX
	if currentAnimationType == kAnimationTypeSelectionUp then
		selectedRect.y += 3
	elseif currentAnimationType == kAnimationTypeSelectionDown then
		selectedRect.y -= 3
	end
	
	if rowShift > 0 then
		selectedRect.y += 5
		rowShift -= 1
	elseif rowShift < 0 then
		selectedRect.y -= 5
		rowShift +=1
	end 
	
	if rowJiggle > 0 then
		selectedRect.y -= 3
		selectedRect.height += 2
		rowJiggle -= 1
	elseif rowJiggle < 0 then
		selectedRect.y += 1
		selectedRect.height += 2
		rowJiggle +=1
	end
	
	if columnJiggle > 0 then
		selectedRect.x += 1
		selectedRect.width += 2
		columnJiggle -= 1
	elseif columnJiggle < 0 then
		selectedRect.x -= 3
		selectedRect.width += 2
		columnJiggle += 1
	end

	
	if animating == false then
		fillRoundRect(selectedRect, 2)
	end
	
	
	gfx.setImageDrawMode(gfx.kDrawModeNXOR)
	gfx.setColor(gfx.kColorBlack)
	
	
	-- menu column
	local selectedMenuIndex = selectionIndexes[kColumnMenu]
	local w = columnWidths[kColumnMenu]
	local y = selectionY - (selectedMenuIndex * rowHeight) + rowHeight
	local x = columnOffsets[kColumnMenu]
	local yOffset = 0
	if selectedColumn == kColumnMenu then 
		yOffset = selectionYOffset 
	end
	
	local cx = x + menuColumnWidth / 2
	local cy = y + rowHeight/2 + yOffset

	if animating == true then
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
		gfx.fillRect(x, 0, w, displayHeight)
		gfx.setImageDrawMode(gfx.kDrawModeNXOR)
		
		if selectedColumn == kColumnMenu then
			selectedRect.x = x
			gfx.setColor(gfx.kColorWhite)
			fillRoundRect(selectedRect, 2)
			gfx.setColor(gfx.kColorBlack)
		end
	end

	for i = 1, #menuColumn do
		local glyphImage = menuColumn[i]
		local gw, gh = glyphImage:getSize()
		glyphImage:draw(cx - gw * 0.5, cy - gh * 0.5);
		cy += rowHeight
	end
	
	-- letter/symbol columns
	
	for i = 1, #columns do
		
		if columns[i] ~= menuColumn then
			local w = columnWidths[i]
			local y = selectionY
			local y2 = y
			local x = columnOffsets[i]
			local index = selectionIndexes[i]
			local yOffset = 0

			if i == selectedColumn
				or (selectedColumn == kColumnLower and i == kColumnUpper )
				or (selectedColumn == kColumnUpper and i == kColumnLower ) then
				-- while scrolling vertically, don't offset, instead center letters on selection rect - easier to read and looks better
				if scrollingVertically == false then
					yOffset = selectionYOffset 
				end
			end
			
			if animating == true then
				gfx.setImageDrawMode(gfx.kDrawModeCopy)
				gfx.fillRect(x, 0, w, displayHeight)
				gfx.setImageDrawMode(gfx.kDrawModeNXOR)
				
				if i == selectedColumn then
					selectedRect.x = x
					gfx.setColor(gfx.kColorWhite)
					fillRoundRect(selectedRect, 2)
					gfx.setColor(gfx.kColorBlack)
				end
			end
			
			local glyph = columns[i][selectionIndexes[i]]
			local cx = x
			local cy = y + 4 + yOffset
	
			keyboardFont:drawText(glyph, cx, cy)
	
			-- letters above
			local j = 0
			while y2 + rowHeight + yOffset > 0 do
				j += 1
				y2 -= rowHeight
				local cy = y2 + 4 + yOffset
	
				local glyph = columns[i][(((selectionIndexes[i]-j-1) % (columnCounts[i])) + 1)]
				keyboardFont:drawText(glyph, cx, cy)	
			end
			
			-- letters below
			j = 0
			while y + rowHeight + yOffset < displayHeight do
				j += 1
				y += rowHeight
				local cy = y + 4 + yOffset
				
				local glyph = columns[i][(((selectionIndexes[i]+j-1) % (columnCounts[i])) + 1)]
				keyboardFont:drawText(glyph, cx, cy)
				
			end
		end
	end
	
	gfx.popContext()
end


--! Menu Commands

local function hideKeyboard(okPressed)
	
	okButtonPressed = okPressed
	kb.hide()
		
	-- free up memory
	columnSound = nil
	rowSound = nil
	bumpSound = nil
	keySound = nil
	originalText = nil
end


local function deleteAction()
	kb.text = string.sub(kb.text, 1, -2)		
	if kb.textChangedCallback ~= nil then
		kb.textChangedCallback()
	end
end


local function cancelAction()
	
	kb.text = originalText or ""
	
	if kb.textChangedCallback ~= nil then
		kb.textChangedCallback()
	end
	
	hideKeyboard(false)
end


local function addLetter(newLetter)
	local lastLetter = string.sub(kb.text, -1)
	kb.text = kb.text .. newLetter
	if kb.textChangedCallback ~= nil then
		kb.textChangedCallback()
	end

	if (newLetter == ' ' and capitalizationBehavior == kb.kCapitalizationWords) or
	   (newLetter == ' ' and lastLetter == '.' and capitalizationBehavior == kb.kCapitalizationSentences) then
		selectColumn(kColumnUpper)
	end
	
	lastLetter = newLetter
end


local function handleMenuCommand()
	
	local selectedMenuOption = selectionIndexes[kColumnMenu]
	
	if selectedMenuOption == kMenuOptionDelete then
		deleteAction()
		
	elseif selectedMenuOption == kMenuOptionOK then
		hideKeyboard(true)
	
	elseif selectedMenuOption == kMenuOptionSpace then
		addLetter(' ')
	
	elseif selectedMenuOption == kMenuOptionCancel then
		cancelAction()
		
	end

end


local lastKeyEnteredTime = 0
local minKeyRepeatMilliseconds <const> = 100

local function enterNewLetterIfNecessary()
	
	if keyboardIsVisible == false or currentAnimationType == kAnimationTypeKeyboardShow or currentAnimationType == kAnimationTypeKeyboardHide then 
		return 
	end
	
	local function enterKey()
		if selectedColumn == kColumnMenu then
			handleMenuCommand()
		else
			local newLetter = columns[selectedColumn][selectionIndexes[selectedColumn]]
			addLetter(newLetter)
			lastTypedColumn = selectedColumn
		end
		playSound(kSoundKeyPress)
	end
	
	local currentMillis = playdate.getCurrentTimeMilliseconds()
	
	if playdate.buttonJustPressed(playdate.kButtonA) and currentMillis > lastKeyEnteredTime + minKeyRepeatMilliseconds then
		enterKey()
		lastKeyEnteredTime = currentMillis
	end
end

--! Animations

local function updateAnimation()

	animationTime = playdate.getCurrentTimeMilliseconds() - animationStartTime
	
	if animationTime >= animationDuration then		-- animation ended

		if currentAnimationType == kAnimationTypeKeyboardShow then
			keyboardRect.x = displayWidth - keyboardWidth
			if kb.keyboardDidShowCallback ~= nil then
				kb.keyboardDidShowCallback()
			end
			
		elseif currentAnimationType == kAnimationTypeKeyboardHide then
			keyboardRect.x = displayWidth
			keyboardIsVisible = false
			playdate.update = playdateUpdate	-- reset main update function
			playdate.inputHandlers.pop()
			if kb.keyboardDidHideCallback ~= nil then
				kb.keyboardDidHideCallback()
			end
			kb.text = ''
			
		elseif currentAnimationType == kAnimationTypeSelectionUp or currentAnimationType == kAnimationTypeSelectionDown then
			selectionYOffset = 0
			
		end

		currentAnimationType = kAnimationTypeNone
	else
		-- see what type of animation we are running, and continue it
				
		if currentAnimationType == kAnimationTypeKeyboardShow then
			keyboardRect.x = outBackEase(animationTime, displayWidth, -keyboardWidth, animationDuration, 1)
			keyboardRect.width = displayWidth - keyboardRect.x
			
		elseif currentAnimationType == kAnimationTypeKeyboardHide then
			keyboardRect.x = outBackEase(animationTime, displayWidth - keyboardWidth, keyboardWidth, animationDuration, 1)
			keyboardRect.width = displayWidth - keyboardRect.x
			
		elseif currentAnimationType == kAnimationTypeSelectionUp or currentAnimationType == kAnimationTypeSelectionDown then
			
			selectionYOffset = linearEase(animationTime, selectionStartY, -selectionStartY, animationDuration)
			
		end
	end
end


local function startAnimation(animationType, duration)
	
	-- finish the last animation before starting this one
	if animationType ~= kAnimationTypeNone then
		animationDuration = animationTime
		updateAnimation()
	end
	
	animationDuration = duration
	currentAnimationType = animationType
	animationStartTime = playdate.getCurrentTimeMilliseconds()
	animationTime = 0
end


--! Selection

local scrollAnimationDuration = 150

local function moveSelectionUp(count, shiftRow)

	if currentAnimationType == kAnimationTypeKeyboardShow or currentAnimationType == kAnimationTypeKeyboardHide then
		return
	end
	
	if selectedColumn == kColumnMenu then
		count = 1
	end
	
	if selectedColumn == kColumnMenu and selectionIndexes[kColumnMenu] == 1 then
		if refreshRate > 30 then 
			rowJiggle = 2
		else
			rowJiggle = 1
		end
		playSound(kSoundBump)
		return
	end
	
	-- moving the selection up means moving the letters down. Set an offset that goes from position of the old current letter and animates to zero
	
	selectionIndexes[selectedColumn] = ((selectionIndexes[selectedColumn] - 1 - count) % columnCounts[selectedColumn]) + 1
	
	-- move upper and lower alphabets together
	if selectedColumn == kColumnLower then
		selectionIndexes[kColumnUpper] = selectionIndexes[kColumnLower]
	elseif selectedColumn == kColumnUpper then
		selectionIndexes[kColumnLower] = selectionIndexes[kColumnUpper]
	end
	
	selectionYOffset -= (rowHeight * count)
	selectionStartY = selectionYOffset
	
	startAnimation(kAnimationTypeSelectionUp, scrollAnimationDuration)	
	-- let the animation think it's already been going on for a frame
	animationStartTime = playdate.getCurrentTimeMilliseconds() - (1000 / refreshRate)
	
	if shiftRow then 
		if refreshRate > 30 then 
			rowShift = -2
		else
			rowShift = -1
		end
	end
	
	playSound(kSoundRowMove)
end


local function moveSelectionDown(count, shiftRow)
	
	if currentAnimationType == kAnimationTypeKeyboardShow or currentAnimationType == kAnimationTypeKeyboardHide then
		return
	end

	if selectedColumn == kColumnMenu then
		count = 1
	end
	
	if selectedColumn == kColumnMenu and selectionIndexes[kColumnMenu] == #menuColumn then
		if refreshRate > 30 then 
			rowJiggle = -2
		else
			rowJiggle = -1
		end
		playSound(kSoundBump)
		return
	end
	
	selectionIndexes[selectedColumn] = ((selectionIndexes[selectedColumn] - 1 + count) % columnCounts[selectedColumn]) + 1
	
	-- move upper and lower alphabets together
	if selectedColumn == kColumnLower then
		selectionIndexes[kColumnUpper] = selectionIndexes[kColumnLower]
	elseif selectedColumn == kColumnUpper then
		selectionIndexes[kColumnLower] = selectionIndexes[kColumnUpper]
	end
	
	selectionYOffset += (rowHeight * count)
	selectionStartY = selectionYOffset
	
	startAnimation(kAnimationTypeSelectionDown, scrollAnimationDuration)
	-- let the animation think it's already been going on for a frame
	animationStartTime = playdate.getCurrentTimeMilliseconds() - (1000 / refreshRate)
	
	if shiftRow then 
		if refreshRate > 30 then 
			rowShift = 2
		else
			rowShift = 1
		end
	end
	
	playSound(kSoundRowMove)
end


KeyboardInput.clickCWFunction = moveSelectionDown
KeyboardInput.clickCCWFunction = moveSelectionUp


local function jiggleColumn(jiggleRight)
	local numFrames
	if refreshRate > 30 then
		numFrames = 2
	else
		numFrames = 1
	end
	
	if jiggleRight then
		columnJiggle = numFrames
	else
		columnJiggle = -numFrames		
	end
	
end

selectColumn = function(column)
	
	if currentAnimationType == kAnimationTypeKeyboardShow or currentAnimationType == kAnimationTypeKeyboardHide then
		return
	end
	
	if selectedColumn > column then
		jiggleColumn(false)
	else
		jiggleColumn(true)
	end
	
	if column > selectedColumn then
		playSound(kSoundColumnMoveNext)
	else
		playSound(kSoundColumnMovePrevious)
	end
	
	selectedColumn = column
	
	selectedCharacterRect.x = columnPositions[selectedColumn]
	selectedCharacterRect.width = columnWidths[selectedColumn]
end


local function selectPreviousColumn()
	
	if currentAnimationType == kAnimationTypeKeyboardShow or currentAnimationType == kAnimationTypeKeyboardHide then
		return
	end
	
	if selectedColumn > 1 then selectedColumn -= 1 else selectedColumn = #columns end
	jiggleColumn(false)
	selectedCharacterRect.x = columnPositions[selectedColumn]
	selectedCharacterRect.width = columnWidths[selectedColumn]
	playSound(kSoundColumnMoveNext)

end

local function selectNextColumn()
	
	if currentAnimationType == kAnimationTypeKeyboardShow or currentAnimationType == kAnimationTypeKeyboardHide then
		return
	end
	
	if selectedColumn < #columns then selectedColumn += 1 else selectedColumn = 1 end
	jiggleColumn(true)
	selectedCharacterRect.x = columnPositions[selectedColumn]
	selectedCharacterRect.width = columnWidths[selectedColumn]
	playSound(kSoundColumnMovePrevious)

end


local function checkButtonInputs()

	if playdate.buttonJustPressed(playdate.kButtonUp) then
		
		moveSelectionUp(1, true)
		scrollRepeatDelay = frameRateAdjustedScrollRepeatDelay
	
	elseif playdate.buttonIsPressed(playdate.kButtonUp) then
		
		if scrollRepeatDelay <= 0 then
			moveSelectionUp(1, true)
			scrollingVertically = true
			if refreshRate > 30 then 
				scrollRepeatDelay = 1
			end
		else
			scrollRepeatDelay -= 1
		end
		
	elseif playdate.buttonJustReleased(playdate.kButtonUp) then
		scrollingVertically = false
	
	elseif playdate.buttonJustPressed(playdate.kButtonDown) then
		
		moveSelectionDown(1, true)
		scrollRepeatDelay = frameRateAdjustedScrollRepeatDelay
		
	elseif playdate.buttonIsPressed(playdate.kButtonDown) then
		
		if scrollRepeatDelay <= 0 then
			moveSelectionDown(1, true)
			scrollingVertically = true
			if refreshRate > 30 then 
				scrollRepeatDelay = 1
			end
		else
			scrollRepeatDelay -= 1
		end
		
	elseif playdate.buttonJustReleased(playdate.kButtonDown) then
		scrollingVertically = false

	elseif playdate.buttonJustPressed(playdate.kButtonLeft) then
		selectPreviousColumn()
		
	elseif playdate.buttonJustPressed(playdate.kButtonRight) then
		selectNextColumn()
		
	elseif playdate.buttonJustPressed(playdate.kButtonB) then
		playSound(kSoundKeyPress)
		deleteAction()
	end

end

--! update
-- override on the main playdate.update function so that we can run our animations without requiring timers
local keyboardUpdate = function()

	if keyboardIsVisible == true then
		
		enterNewLetterIfNecessary()
		
		if currentAnimationType ~= kAnimationTypeNone then
			
			updateAnimation()
			
			if currentAnimationType == kAnimationTypeKeyboardShow or currentAnimationType == kAnimationTypeKeyboardHide then
				if kb.keyboardAnimatingCallback ~= nil then
					kb.keyboardAnimatingCallback()
				end
			end
		end
		
		if keyboardJustOpened ~= true then
			checkButtonInputs()		
		else
			keyboardJustOpened = false
		end
		
		playdateUpdate()
		drawKeyboard()
		
	end

end


--! Public functions

function playdate.keyboard.show(newText)

	if playdate.update == nil then
		print("Error: playdate.update() must be defined before calling playdate.keyboard.show()")
		return
	end
	
	if keyboardIsVisible == true then return end
	
	keyboardJustOpened = true

	okButtonPressed = false
	selectionIndexes[kColumnMenu] = 2	-- scroll the menu row to OK
	selectedColumn = lastTypedColumn	-- move the selection back to the last row a character was entered from
	selectedCharacterRect.x = columnPositions[selectedColumn]
	selectedCharacterRect.width = columnWidths[selectedColumn]

	playdate.inputHandlers.push(KeyboardInput, true)
	
	originalText = newText or ''
	kb.text = originalText
	
	playdateUpdate = playdate.update
	playdate.update = keyboardUpdate
	
	if currentAnimationType	~= kAnimationTypeNone then
		-- force the previous animation to finish
		animationStartTime = 0
		updateAnimation()
	end
	
	refreshRate = playdate.display.getRefreshRate()
	local scrollDelaySeconds = 0.18
	frameRateAdjustedScrollRepeatDelay = floor(scrollDelaySeconds * refreshRate)
	
	keyboardIsVisible = true
	startAnimation(kAnimationTypeKeyboardShow, 220)

end


function playdate.keyboard.hide()	
	if keyboardIsVisible == true and currentAnimationType == kAnimationTypeNone then
		
		startAnimation(kAnimationTypeKeyboardHide, 220)
		
		if kb.keyboardWillHideCallback ~= nil then
			kb.keyboardWillHideCallback(okButtonPressed or false)
		end
	end
	
end


function playdate.keyboard.width()
	return keyboardRect.width
end


function playdate.keyboard.left()
	return keyboardRect.x
end


function playdate.keyboard.isVisible()
	return keyboardIsVisible
end


function playdate.keyboard.setCapitalizationBehavior(behavior)	

	assert(behavior ~= nil and behavior >= kb.kCapitalizationNormal and behavior <= kb.kCapitalizationSentences, "Please use one of the following options: playdate.keyboard.kCapitalizationNormal, playdate.keyboard.kCapitalizationWords, playdate.keyboard.kCapitalizationSentences")
	capitalizationBehavior = behavior
end
