import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/animation"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/math"

local datastoreFile = 'artillery-data'
local gfx<const> = playdate.graphics

function getInterpolatedMap(worldMap)
    local res = {}
    for j = 1, #worldMap - 1 do
        local a = worldMap[j]
        local b = worldMap[j + 1]
        local y0 = a[2]
        local x0 = a[1]
        local x1 = b[1]
        local y1 = b[2]
        for i = a[1], b[1], 1 do
            res[i] = math.floor((y0 * (x1 - i) + y1 * (i - x0)) / (x1 - x0))
        end
    end
    return res
end

function updateScore(score)
    gfx.drawText(math.floor(score), 340, 5)
end

function saveToPersistent(score)
    local data = {bestScore = score}
    playdate.datastore.write(data, datastoreFile)
end

function readFromPersistent()
    local savedData = playdate.datastore.read(datastoreFile)
    if savedData then
        return savedData['bestScore']
    else
        return nil
    end
end

function initGameplayResources()
    local result = {images = {}, sounds = {}, soundPlayers = {}}

    result.images.playerImage = gfx.image.new("Images/playerImage")
    result.images.gunImage = gfx.image.new("Images/gun")
    result.images.projectileImage = gfx.image.new("Images/projectile")
    result.images.enemyImage = gfx.image.new("Images/enemy")
    result.images.backgroundImage = gfx.image.new("Images/background")
    result.images.shotImageTable = gfx.imagetable.new("./Images/shots")

    result.sounds.degreeSound = playdate.sound.sample.new("./Sounds/degree.wav")
    result.sounds.shotSound = playdate.sound.sample.new("./Sounds/shot.wav")

    result.soundPlayers.whistlePlayer = playdate.sound.sampleplayer.new('./Sounds/whistle.wav')
    result.soundPlayers.explosionPlayer = playdate.sound.sampleplayer.new('./Sounds/explosion.wav')
    result.soundPlayers.degreePlayer = playdate.sound.sampleplayer.new('./Sounds/degree.wav')

    return result
end

local konamiCodeCount = 1
local konamiButtonStates = {
    playdate.kButtonUp,
    playdate.kButtonUp,
    playdate.kButtonDown,
    playdate.kButtonDown,
    playdate.kButtonLeft,
    playdate.kButtonRight,
    playdate.kButtonLeft,
    playdate.kButtonRight,
    playdate.kButtonB,
    playdate.kButtonA
}

function checkKonamiCode()
    local current, pressed, released = playdate.getButtonState()
    if pressed == 0 then
        return
    end

    if konamiCodeCount == 10 and pressed == konamiButtonStates[konamiCodeCount] then
        konamiCodeCount = 1
        return true
    elseif pressed == konamiButtonStates[konamiCodeCount] then
        konamiCodeCount = konamiCodeCount + 1
    else
        konamiCodeCount = 1
        return false
    end
end