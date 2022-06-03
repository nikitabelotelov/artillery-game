--[[
USAGE:

Suspect some code is running hot? Wrap it in
an anonymous function and pass it to sample()
like so:

sample('name of this sample', function()
	-- nested for loops, lots of table creation, member access...
end)

By moving around where you start and end the 
anonymous function in your code you can get
a better idea of where the problem lies.

And you can sample multiple code paths at once
by using a different name for each sample.

]]

local concat = table.concat
local function repeatString(s,t)
	local chars = {}
	for i=1,t do chars[i] = s end
	return concat(chars)
end

local tasks = {}
local maxSamples = 20
local ms = playdate.getCurrentTimeMilliseconds
local ceil = math.ceil
local maxinteger = math.maxinteger
local depth = 0
local depths = {}
local maxDepth = 32
local defaultSampleName = 'sample'
for i=0,maxDepth+1 do
	depths[i] = repeatString('\t', i)
end
function sample(name,func,max)
	sampleStart(name,max)
	local result = func()
	sampleEnd(name)
	
	return result
end
function sampleStart(name,max)
	name = name or defaultSampleName
	max = max or maxSamples

	local task = tasks[name]
	if not task then
		task = {elapsed=0,start=0,samples=0,maxSamples=max,low=maxinteger,high=0}
		tasks[name] = task
	end
	task.start = ms()
end
function sampleEnd(name)
	local endTime = ms()
	
	name = name or defaultSampleName
	local task = tasks[name]
	if not task then return end

	local startTime = task.start
	
	local samples = task.samples
	local maxSamples = task.maxSamples
	local elapsed = endTime - startTime
	local low = task.low
	local high = task.high
	if elapsed > high then high = elapsed end
	if elapsed < low then low = elapsed end
	elapsed += task.elapsed
	samples += 1
	if samples >= maxSamples then
		local avg
		if maxSamples > 1 then
			-- ignore the outlier (in The Ratcheteer's case, usually caused by infrequent state changes)
			avg = (elapsed-high) / (samples-1)
		else
			avg = elapsed / samples
		end
		print(name, 'avg: '..ceil(avg)..'ms', 'low: '..low, 'high: '..high)
		elapsed = 0
		samples -= maxSamples
		low = maxinteger
		high = 0
	end
	task.elapsed = elapsed
	task.samples = samples
	task.low = low
	task.high = high
	return result
end

local prints = {}
function printS(name,max,...)
	name = name or defaultSampleName
	max = max or maxSamples
	
	local ref = prints[name]
	if not ref then
		ref = {frames=0,maxFrames=max}
		prints[name] = ref
	end

	local frames = ref.frames
	local maxFrames = ref.maxFrames
	frames += 1
	if frames >= maxFrames then
		printT(...)
		frames -= maxFrames
	end
	ref.frames = frames
end