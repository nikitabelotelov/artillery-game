import 'CoreLibs/timer'
import 'CoreLibs/easing'

playdate.ui = playdate.ui or {}

playdate.ui.gridview = {}
playdate.ui.gridview.__index = playdate.ui.gridview

local gfx = playdate.graphics
local easingFunctions = playdate.easingFunctions



playdate.ui.gridview.__index = function(table, key)
	if key == "isScrolling" then
		return table._isScrolling
	elseif key == "scrollEasingFunction" then
		if table.timerX ~= nil then
			return table.timerX.originalValues.easingFunction
		else
			return easingFunctions.outCubic
		end
	elseif key == "easingAmplitude" then
		if table.timerX ~= nil then
			return table.timerX.easingAmplitude
		end
	elseif key == "easingPeriod" then
		if table.timerX ~= nil then
			return table.timerX.easingPeriod
		end
	else
		return rawget(playdate.ui.gridview, key)
	end
end


playdate.ui.gridview.__newindex = function(table, key, value)
	if key == "isScrolling" then	-- read-only variables
		print("ERROR: playdate.gridview."..key.." is read-only.")
	elseif key == "scrollEasingFunction" then
		-- update the values that will be set on the timer when it is reset before our animations
		if table.timerX ~= nil and table.timerY ~= nil then
			table.timerX.originalValues.easingFunction = value
			table.timerY.originalValues.easingFunction = value
		end
	elseif key == "easingAmplitude" then
		if table.timerX ~= nil and table.timerY ~= nil then
			table.timerX.easingAmplitude = value
			table.timerY.easingAmplitude = value
		end
	elseif key == "easingPeriod" then
		if table.timerX ~= nil and table.timerY ~= nil then
			table.timerX.easingPeriod = value
			table.timerY.easingPeriod = value
		end
	else
		rawset(table, key, value)
	end
end



function playdate.ui.gridview.new(cellWidth, cellHeight)
	
	local o = {}
	setmetatable(o, playdate.ui.gridview)
	
	o.cellWidth = cellWidth or 0		-- cellWidth = 0 means it takes up the entire table width
	o.cellHeight = cellHeight or 0

	o.numSections = 1
	o.numRows = {}
	o.numRows[1] = 0
	o.numColumns = 1
	
	o.selectedSection = 1
	o.selectedRow = 1
	o.selectedColumn = 1
	
	o.contentInsetTop = 0
	o.contentInsetBottom = 0
	o.contentInsetLeft = 0
	o.contentInsetRight = 0
	
	o.cellPaddingTop = 0
	o.cellPaddingBottom = 0
	o.cellPaddingLeft = 0
	o.cellPaddingRight = 0
	
	o.sectionHeaderPaddingTop = 0
	o.sectionHeaderPaddingBottom = 0
	o.sectionHeaderPaddingLeft = 0
	o.sectionHeaderPaddingRight = 0
	
	o.horizontalDividers = {}
	o.horizontalDividerHeight = cellHeight or 0
	o.horizontalDividerHeight = o.horizontalDividerHeight / 2
	
	o.backgroundImage = nil		-- can be either a regular image that gets tiled or a nineslice
	
	o.sectionHeaderHeight = 0
	
	o._isScrolling = false
	o.scrollPositionX = 0
	o.scrollPositionY = 0
	
	o.changeRowOnColumnWrap = true
	o.scrollCellsToCenter = true
	
	o.needsDisplay = true -- will be true for things like scrolling changes
	
	-- private
	
	-- set up timers
	local timerX = playdate.timer.new(250)
	timerX.discardOnCompletion = false
	timerX.easingFunction = easingFunctions.outCubic
	timerX:pause()
	timerX.updateCallback = function(timer)
			o.scrollPositionX = timer.value
			o.needsDisplay = true
		end
	timerX.timerEndedCallback = function(timer)
			o.scrollPositionX = timer.endValue
			o._isScrolling = false
			o.needsDisplay = true
		end
		
	local timerY = playdate.timer.new(250)
	timerY.discardOnCompletion = false
	timerY.easingFunction = easingFunctions.outCubic
	timerY:pause()
	timerY.updateCallback = function(timer)
			o.scrollPositionY = timer.value
			o.needsDisplay = true
		end
	timerY.timerEndedCallback = function(timer)
			o.scrollPositionY = timer.endValue
			o._isScrolling = false
			o.needsDisplay = true
		end
		
	o.timerX = timerX
	o.timerY = timerY
	
	o.contentWidth = 0
	o.contentHeight = 0
	o.drawingWidth = 0
	o.drawingHeight = 0
	o.drawingX = 0
	o.drawingY = 0

	return o
end


local function animateScroll(self, newX, newY)

	if self.timerX.duration > 0 or self.timerY.duration > 0 then
		self._isScrolling = true
	end

	if self.timerX.duration > 0 then
		self.timerX:reset()
		self.timerX.startValue = self.scrollPositionX
		self.timerX.endValue = newX
		self.timerX:start()
	else
		self.scrollPositionX = newX
	end
	
	if self.timerY.duration > 0 then
		self.timerY:reset()
		self.timerY.startValue = self.scrollPositionY
		self.timerY.endValue = newY
		self.timerY:start()
	else
		self.scrollPositionY = newY
	end
end


-- override to draw the contents of the cells
function playdate.ui.gridview:drawCell(section, row, column, selected, x, y, width, height)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRect(x, y, width, height)
	if selected then
		gfx.fillRect(x + 2, y + 2, width - 4, height - 4)
	end
end

-- override to draw the contents of the section headers
function playdate.ui.gridview:drawSectionHeader(section, x, y, width, height)
	gfx.setColor(gfx.kColorBlack)
	gfx.fillRect(x, y, width, height)
end

-- override to draw the contents of horizontal dividers
function playdate.ui.gridview:drawHorizontalDivider(x, y, width, height)
	gfx.setColor(gfx.kColorBlack)
	local lineHeight = 2
	gfx.fillRect(x + 2, y + ((height-lineHeight)/2), width - 4, lineHeight)
end


function playdate.ui.gridview:setHorizontalDividerHeight(newHeight)
	assert(newHeight ~= nil, "nil value passed to playdate.ui.gridview.setHorizontalDividerHeight()")
	assert(newHeight >= 0, "negative value passed to playdate.ui.gridview.setHorizontalDividerHeight()")
	self.horizontalDividerHeight = newHeight
	self.needsDisplay = true
end

function playdate.ui.gridview:getHorizontalDividerHeight()
	return self.horizontalDividerHeight
end


function playdate.ui.gridview:removeHorizontalDividers()
	self.horizontalDividers = {}
	self.needsDisplay = true
end


function playdate.ui.gridview:addHorizontalDividerAbove(section, row)

	if self.horizontalDividers[section] == nil then
		self.horizontalDividers[section] = {}
		self.horizontalDividers[section].count = 0
	end

	self.horizontalDividers[section][row] = true
	self.horizontalDividers[section].count += 1
	
	self.needsDisplay = true
end


local function horizontalDividerSpaceForSection(self, section)
	if self.horizontalDividers[section] == nil then
		return 0
	end
	
	return self.horizontalDividers[section].count * self.horizontalDividerHeight
end


function horizontalDividerSpaceAboveRow(self, section, row, includePreviousSections)
	local space = 0
	
	if includePreviousSections == true then
		for aboveSection = 1, section-1 do
			if self.horizontalDividers[aboveSection] ~= nil then
				space += (self.horizontalDividers[aboveSection].count * self.horizontalDividerHeight)
			end
		end
	end
	
	if self.horizontalDividers[section] ~= nil then
		for k, _ in pairs(self.horizontalDividers[section]) do
			if type(k) == "number" and k <= row then	-- type check is to filter out the "count" entry
				space += self.horizontalDividerHeight
			end
		end
	end

	return space
end


-- returns left, top, right, bottom for the cell in question. Includes padding
local function paddedEdgesForCell(self, section, row, column)
	
	if section < 1 or row < 1 or column < 1 or section > self.numSections or column > self.numColumns then
		return 0, 0, 0, 0
	end
	
	local numRows = 0
	local numSections = 0
	
	for s = 1, section-1 do
		numRows = numRows + self.numRows[s]
	end
	numRows = numRows + row
	
	local cellAndPaddingWidth = (self.cellPaddingLeft + self.cellWidth + self.cellPaddingRight)
	local cellAndPaddingHeight = (self.cellPaddingTop + self.cellHeight + self.cellPaddingBottom)
	
	local dividersSpace = horizontalDividerSpaceAboveRow(self, section, row, true)
	
	local right = self.contentInsetLeft + (column * cellAndPaddingWidth)
	local bottom = self.contentInsetTop + (section * (self.sectionHeaderPaddingTop + self.sectionHeaderHeight + self.sectionHeaderPaddingBottom)) + (numRows * cellAndPaddingHeight) + dividersSpace
	
	return right - cellAndPaddingWidth, bottom - cellAndPaddingHeight, right, bottom
end


-- returns the tuple (x, y, width, height) representing the frame of the cell, not including padding, relative to the top-right corner of the grid view
function playdate.ui.gridview:getCellBounds(section, row, column, gridWidth)

	assert(self.cellWidth ~= 0 or gridWidth ~= nil, "playdate.ui.gridview:getCellBounds() requires `gridWidth` argument when cell width is zero")

	local l, t, r, b = paddedEdgesForCell(self, section, row, column)
	local width = r-l
	if width == 0 and gridWidth ~= nil then
		width = gridWidth - self.cellPaddingLeft + self.cellPaddingRight - self.contentInsetLeft - self.contentInsetRight
	end

	return l - self.scrollPositionX + self.cellPaddingLeft, t - self.scrollPositionY + self.cellPaddingTop, width - self.cellPaddingLeft - self.cellPaddingRight, b - t - self.cellPaddingTop - self.cellPaddingBottom

end


-- when a scroll method is called before the grid view has been drawn we don't know the size yet, so scrolling must be deferred

local function doDeferredScrollIfNecessary(self)
	if self.deferredScrollFunction ~= nil then
		self.deferredScrollFunction(self, self.deferredArg1, self.deferredArg2, self.deferredArg3, self.deferredArg4)
		self.deferredScrollFunction = nil
		self.deferredArg1 = nil
		self.deferredArg2 = nil
		self.deferredArg3 = nil
		self.deferredArg4 = nil
	end
end


local function deferScroll(self, funcArg, arg1, arg2, arg3, arg4)
	
	if self.drawingHeight <= 0 then	-- view has not drawn yet, defer the scroll
		self.deferredScrollFunction = funcArg
		self.deferredArg1 = arg1
		self.deferredArg2 = arg2
		self.deferredArg3 = arg3
		self.deferredArg4 = arg4
		return true
	end
	return false
end



-- utility function used by drawInRect()
local function calculateContentSizeAndClampScrollPosition(self, drawingWidth, drawingHeight)

	if self.needsDisplay == false then
		return
	end

	local contentWidth, contentHeight

	-- width
	if self.cellWidth > 0 then
		self.contentWidth = self.contentInsetLeft + self.contentInsetRight + (self.numColumns * (self.cellPaddingLeft + self.cellWidth + self.cellPaddingRight))
	else
		self.contentWidth = drawingWidth
	end
	
	-- height
	if self.numSections > 0 and self.numRows[1] > 0 and self.numColumns > 0 then
		local totalRows = 0
		local dividerSpace = 0
		for section = 1, self.numSections do
			totalRows = totalRows + self.numRows[section]
			dividerSpace += horizontalDividerSpaceForSection(self, section)
		end
		
		self.contentHeight = self.contentInsetTop + self.contentInsetBottom + (self.numSections * (self.sectionHeaderHeight + self.sectionHeaderPaddingTop + self.sectionHeaderPaddingBottom)) + (totalRows * (self.cellHeight + self.cellPaddingTop + self.cellPaddingBottom)) + dividerSpace

	else
		self.contentWidth = self.contentInsetTop + self.contentInsetBottom
	end
	
	-- make sure we're not scrolled beyond what we're allowed to be scrolled to
	-- since gridview doesn't have an intrisic size, this is really the only place this can be done
	if self.scrollPositionX < 0 then
		self.scrollPositionX = 0
	elseif self.scrollPositionX  > self.contentWidth - drawingWidth then
		self.scrollPositionX = math.max(0, self.contentWidth - drawingWidth)
	end
	
	if self.scrollPositionY < 0 then
		self.scrollPositionY = 0
	elseif self.scrollPositionY  > self.contentHeight - drawingHeight then
		self.scrollPositionY = math.max(0, self.contentHeight - drawingHeight)
	end
end


local floor = math.floor

function playdate.ui.gridview:drawInRect(x, y, width, height)

	if width == 0 or height == 0 then
		return
	end
	
	self.drawingX = x
	self.drawingY = y
	self.drawingWidth = width
	self.drawingHeight = height

	local insetX = x + self.contentInsetLeft
	local insetY = y + self.contentInsetTop
	local insetWidth = width - self.contentInsetLeft - self.contentInsetRight
	local insetHeight = height - self.contentInsetTop - self.contentInsetBottom

	local currentImageDrawMode = gfx.getImageDrawMode()
	gfx.setImageDrawMode(gfx.kDrawModeCopy)

	-- draw background image
	if self.backgroundImage ~= nil then
		if self.backgroundImage.slices ~= nil then -- it's a nineslice
			self.backgroundImage:drawInRect(x, y, width, height)
		else -- it's a regular image
			self.backgroundImage:drawTiled(x, y, width, height)
		end
	end

	-- calculate drawing positions
	doDeferredScrollIfNecessary(self)
	calculateContentSizeAndClampScrollPosition(self, width, height)
	
	-- draw cell content and section headers
	
	local clipX, clipY, clipW, clipH = gfx.getClipRect()	-- save the current clipRect
	local tempX, tempY, tempW, tempH = playdate.geometry.rect.fast_intersection(clipX, clipY, clipW, clipH, insetX, insetY, insetWidth, insetHeight)
	gfx.setClipRect(tempX, tempY, tempW, tempH) -- set temporary clip rect
	
	local headerWidth = width - (self.contentInsetLeft + self.contentInsetRight) -- always draw headers full-width
	local cellHeight = self.cellHeight
	local cellWidth = self.cellWidth
	if cellWidth == 0 then
		-- if cellWidth is set to 0, we want to stretch the cells horizontally to fit the table, and section headers always do this
		cellWidth = headerWidth - self.cellPaddingLeft - self.cellPaddingRight
	end

	local drawX = -self.scrollPositionX + self.contentInsetLeft
	local drawY = -self.scrollPositionY + self.contentInsetTop

	-- SECTIONS --
	if self.numSections > 0 and self.numRows[1] > 0 and self.numColumns > 0 then
		
		for section = 1, self.numSections do
			
			-- draw section header
			
			drawY = drawY + self.sectionHeaderPaddingTop	-- add section header top padding
			
			
			if self.sectionHeaderHeight > 0 and drawY + self.sectionHeaderHeight > 0 and drawY < height then
				-- draw the section header, inset by left and right paddings, and by the x passed in by the caller
				self:drawSectionHeader(section, floor(x + drawX + self.sectionHeaderPaddingLeft + self.scrollPositionX), floor(y + drawY), headerWidth - self.sectionHeaderPaddingLeft - self.sectionHeaderPaddingRight, self.sectionHeaderHeight)
			end
			
			drawY = drawY + self.sectionHeaderHeight + self.sectionHeaderPaddingBottom -- add section header height and bottom padding
			
			
			-- ROWS --
			for row = 1, self.numRows[section] do
				
				drawY += self.cellPaddingTop	-- add top cell padding
				
				if self.horizontalDividers[section] ~= nil and self.horizontalDividers[section][row] == true and self.horizontalDividerHeight > 0 then
					self:drawHorizontalDivider(floor(x + drawX), floor(y + drawY), self.contentWidth - (self.contentInsetRight + self.contentInsetLeft), self.horizontalDividerHeight)
					drawY += self.horizontalDividerHeight
				end
				
				-- COLUMNS --
				for col = 1, self.numColumns do
					
					drawX = drawX + self.cellPaddingLeft	-- add left cell padding
					
					if drawY + self.cellHeight > 0 and drawY < height and drawX + cellWidth > 0 and drawX < width then
						-- cell is visible, draw it, offset by caller's x, y
						local selected = (section == self.selectedSection) and (row == self.selectedRow) and (col == self.selectedColumn)
						self:drawCell(section, row, col, selected, floor(x + drawX), floor(y + drawY), cellWidth, self.cellHeight)
					end
					
					drawX = drawX + cellWidth + self.cellPaddingRight	-- add cell width and right padding
					
					if drawY > height then
						break -- don't need to draw anymore
					end
					
				end -- columns
				
				drawX = -self.scrollPositionX + self.contentInsetLeft	--reset for next row
				drawY = drawY + self.cellHeight + self.cellPaddingBottom -- add cell height and bottom padding
				
				if drawY > height then
					break  -- don't need to draw anymore
				end
				
			end -- rows
			
		end -- sections
		
	end
	
	gfx.setClipRect(clipX, clipY, clipW, clipH) -- reset to the original clipRect
	gfx.setImageDrawMode(currentImageDrawMode)
	
	self.needsDisplay = false
end


function playdate.ui.gridview:setNumberOfColumns(num)
	if num > 0 then
		self.numColumns = num	
	else
		print("ERROR: playdate.ui.gridview must be at least one column wide.")
	end
	
	self.needsDisplay = true
end


function playdate.ui.gridview:getNumberOfColumns()
	return self.numColumns
end


function playdate.ui.gridview:setNumberOfSections(num)

	if num > 0 then
		
		if num < self.numSections then
			-- remove unused row counts
			for i = num+1, self.numSections do
				self.numRows[i] = nil
			end
		elseif num > self.numSections then
			-- seed the numRows array to prevent errors
			for i=self.numSections, num do
				if self.numRows[i] == nil then
					self.numRows[i] = 1
				end
			end
		end
		
		self.numSections = num
	else
		print("ERROR: playdate.ui.gridview must contain at least one section.")
	end
	
	self.needsDisplay = true
end

function playdate.ui.gridview:getNumberOfSections()
	return self.numSections
end


function playdate.ui.gridview:setNumberOfRowsInSection(section, num)
	if num > 0 then
		self.numRows[section] = num
		if self.numSections < section then self:setNumberOfSections(section) end
	else
		print("ERROR: playdate.ui.gridview sections must contain at least one row.")
	end
	
	self.needsDisplay = true
end

function playdate.ui.gridview:setNumberOfRows(...)
	
	local lastSection = select("#",...)
	
	if lastSection > self.numSections then
		self:setNumberOfSections(lastSection)
	end
	
	for section=1, lastSection do
		local num = select(section, ...)
		self:setNumberOfRowsInSection(section, num)
	end
	
	self.needsDisplay = true
end

function playdate.ui.gridview:getNumberOfRowsInSection(section)
	return self.numRows[section]
end


function playdate.ui.gridview:setCellSize(width, height)
	if cellWidth == 0 then
		self.numColumns = 1
	end
	self.cellWidth = width
	self.cellHeight = height
	
	self.needsDisplay = true
end

function playdate.ui.gridview:setSectionHeaderHeight(height)
	if height and height > 0 then
		self.sectionHeaderHeight = height
	else
		self.sectionHeaderHeight = 0
	end
	
	self.needsDisplay = true
end

function playdate.ui.gridview:getSectionHeaderHeight()
	return self.sectionHeaderHeight
end

function playdate.ui.gridview:setContentInset(left, right, top, bottom)
	assert(left ~= nil and right ~= nil and top ~= nil and bottom ~=nil, "nil value passed to playdate.ui.gridview:setContentInset()")
	self.contentInsetTop = top
	self.contentInsetBottom = bottom
	self.contentInsetLeft = left
	self.contentInsetRight = right
	
	self.needsDisplay = true
end


function playdate.ui.gridview:setCellPadding(left, right, top, bottom)
assert(left ~= nil and right ~= nil and top ~= nil and bottom ~=nil, "nil value passed to playdate.ui.gridview:setCellPadding()")
	self.cellPaddingTop = top
	self.cellPaddingBottom = bottom
	self.cellPaddingLeft = left
	self.cellPaddingRight = right
	
	self.needsDisplay = true
end


function playdate.ui.gridview:setSectionHeaderPadding(left, right, top, bottom)
assert(left ~= nil and right ~= nil and top ~= nil and bottom ~=nil, "nil value passed to playdate.ui.gridview:setSectionHeaderPadding()")
	self.sectionHeaderPaddingTop = top
	self.sectionHeaderPaddingBottom = bottom
	self.sectionHeaderPaddingLeft = left
	self.sectionHeaderPaddingRight = right
	
	self.needsDisplay = true
end



function playdate.ui.gridview:setScrollPosition(x, y, animated)
	
	if animated == nil then animated = true end
		
	if animated == true then
		animateScroll(self, x, y)
	else
		self.scrollPositionX = x
		self.scrollPositionY = y
	end
	
	self.needsDisplay = true
end


function playdate.ui.gridview:getScrollPosition()
	return self.scrollPositionX, self.scrollPositionY
end


-- attempts to change the scrolling as little as possible, just pushing it to the closest location that will cause the cell (and it's padding) to be visible.
function playdate.ui.gridview:scrollToCell(section, row, column, animated)
	
	if animated == nil then animated = true end
	
	if deferScroll(self, playdate.ui.gridview.scrollToCell, section, row, column, animated) then
		return
	end

	local left, top, right, bottom = paddedEdgesForCell(self, section, row, column)
	
	local scrollX = self.scrollPositionX
	local scrollY = self.scrollPositionY

	-- if the cell is at and edge, scroll all the way to that edge
	if section == 1 and row == 1 then -- top row
		scrollY = 0
	elseif section == self.numSections and row == self.numRows[section] then -- last row
		scrollY = self.contentHeight - self.drawingHeight
	else
		-- not on an edge, need to figure it out for real
		if top < self.scrollPositionY then
			scrollY = top
		elseif bottom > self.scrollPositionY + self.drawingHeight then
			scrollY = bottom - self.drawingHeight
		end
	end
	
	if column == 1 then	-- first column
		scrollX = 0
	elseif column == self.numColumns then -- last column
		scrollX = self.contentWidth - self.drawingWidth
	else -- not an edge, need to figure it out for real
		if left < self.scrollPositionX then
			scrollX = left
		elseif right > self.scrollPositionX + self.drawingWidth then
			scrollX = right - self.drawingWidth
		end
	end

	self:setScrollPosition(scrollX, scrollY, animated)
end


function playdate.ui.gridview:scrollCellToCenter(section, row, column, animated)
	
	if animated == nil then animated = true end

	if deferScroll(self, playdate.ui.gridview.scrollCellToCenter, section, row, column, animated) then
		return
	end

	local left, top, right, bottom = paddedEdgesForCell(self, section, row, column)
	local scrollX = left - (self.drawingWidth + self.contentInsetLeft - self.contentInsetRight)/2 + (right-left)/2
	local scrollY = top - (self.drawingHeight + self.contentInsetTop - self.contentInsetBottom)/2 + (bottom-top)/2
	self:setScrollPosition(scrollX, scrollY, animated)
end


local function scrollToSelectedCell(self, animated)
	if animated == nil then animated = true end
	if self.scrollCellsToCenter then
		self:scrollCellToCenter(self.selectedSection, self.selectedRow, self.selectedColumn, animated)
	else
		self:scrollToCell(self.selectedSection, self.selectedRow, self.selectedColumn, animated)
	end
end


-- tableview convenience function - assumes only one section and one column
function playdate.ui.gridview:scrollToRow(row, animated)
	if animated == nil then animated = true end
	if self.scrollCellsToCenter then
		self:scrollCellToCenter(1, row, 1, animated)
	else
		self:scrollToCell(1, row, 1, animated)
	end
end


function playdate.ui.gridview:scrollToTop(animated)
	if animated == nil then animated = true end
	self:setScrollPosition(0, self.scrollPositionY, animated)
end


function playdate.ui.gridview:setSelection(section, row, column)
	self.selectedSection = section
	self.selectedRow = row
	if column == nil then
		self.selectedColumn = 1
	else
		self.selectedColumn = column
	end
	
	self.needsDisplay = true
end


function playdate.ui.gridview:getSelection()
	return self.selectedSection, self.selectedRow, self.selectedColumn
end

-- tableview convenience function - assumes only one section and one column
function playdate.ui.gridview:setSelectedRow(row)
	self:setSelection(1, row, 1)
end

function playdate.ui.gridview:getSelectedRow()
	return self.selectedRow
end

-- will move the selection to the next row. If wrapSelection is true and the last row in the last section is selected, the first row in the first section will be selected. If it is false the selection will not change. Returns the newly selected section and row
-- scrollToSelection is true by default
function playdate.ui.gridview:selectNextRow(wrapSelection, scrollToSelection, animate)

	local scroll = scrollToSelection or true
	local animate = animate or true

	local lastSection = self.numSections
	local currentSection = self.selectedSection
	local currentRow = self.selectedRow
	
	local nextSelectionSection = currentSection
	local nextSelectionRow = currentRow
	
	if currentSection == lastSection and currentRow == self.numRows[lastSection] then -- wrap from last section/row to first
		if wrapSelection then
			nextSelectionSection = 1
			nextSelectionRow = 1
		end
	elseif currentRow == self.numRows[currentSection]  then -- last row in the section, but not the last section
		nextSelectionSection = currentSection + 1
		nextSelectionRow = 1
	else
		nextSelectionRow = currentRow + 1
	end

	self.selectedSection = nextSelectionSection
	self.selectedRow = nextSelectionRow
	
	if scroll then
		scrollToSelectedCell(self, animate)
	end
	
	self.needsDisplay = true
	
	return nextSelectionSection, nextSelectionRow
end


function playdate.ui.gridview:selectPreviousRow(wrapSelection, scrollToSelection, animate)

	local scroll = scrollToSelection or true
	local animate = animate or true

	local lastSection = self.numSections
	local currentSection = self.selectedSection
	local currentRow = self.selectedRow
	
	local nextSelectionSection = currentSection
	local nextSelectionRow = currentRow

	if currentSection == 1 and currentRow == 1 then -- wrap from first section/row to last
		if wrapSelection then
			nextSelectionSection = self.numSections
			nextSelectionRow = self.numRows[lastSection]
		end
	elseif currentRow == 1 then -- first row in the section, but not in the top section
		nextSelectionSection = currentSection - 1
		nextSelectionRow = self.numRows[nextSelectionSection]
	else
		nextSelectionRow = currentRow - 1
	end
	
	self.selectedSection = nextSelectionSection
	self.selectedRow = nextSelectionRow
	
	if scroll then
		scrollToSelectedCell(self, animate)
	end
	
	self.needsDisplay = true
		
	return nextSelectionSection, nextSelectionRow
end


function playdate.ui.gridview:selectNextColumn(wrapSelection, scrollToSelection, animate)

	local scroll = scrollToSelection or true
	local animate = animate or true
	
	local newColumn = self.selectedColumn + 1
	
	if newColumn > self.numColumns then -- move to the next row
		if wrapSelection then
			newColumn = 1
			if self.changeRowOnColumnWrap then
				self:selectNextRow(wrapSelection)
			end
		else
			newColumn = self.selectedColumn
		end
	end
	
	self.selectedColumn = newColumn
	
	if scroll then
		scrollToSelectedCell(self, animate)
	end
	
	self.needsDisplay = true
	
	return newColumn
end


function playdate.ui.gridview:selectPreviousColumn(wrapSelection, scrollToSelection, animate)

	local scroll = scrollToSelection or true
	local animate = animate or true
	
	local newColumn = self.selectedColumn - 1
	
	if newColumn < 1 then -- move to the next row
		if wrapSelection then
			newColumn = self.numColumns
			if self.changeRowOnColumnWrap then
				self:selectPreviousRow(wrapSelection)
			end
		else
			newColumn = 1
		end
	end
	
	self.selectedColumn = newColumn
	
	if scroll then
		scrollToSelectedCell(self, animate)
	end
	
	self.needsDisplay = true
	
	return newColumn
end


function playdate.ui.gridview:setScrollDuration(ms)
	self.timerX.duration = ms or 0
	self.timerY.duration = ms or 0
end
	
