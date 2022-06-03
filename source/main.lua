import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/animation"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/math"
import "utils"

local gfx<const> = playdate.graphics

local gameStep = 1
local gameplaySpritesInited = false

local playerSprite = nil
local gunSprite = nil
local projectileSprite = nil
local backgroundSprite = nil
local enemySprite = nil
local shotImageTable = nil
local shotAnimator = nil
local recoilAnimator = nil
local shotAnimSprite = nil

local menuSprite = nil
local startButtonSprite = nil
local startButtonAnimator = nil
local startButtonImageTable = nil

local resources = nil

local speed = 200
local bestScore = nil
local worldMap = {{0, 169}, {21, 164}, {46, 185}, {76, 185}, {98, 217}, {206, 123}, {271, 202}, {289, 191}, {318, 207},
                  {331, 200}, {367, 207}, {400, 178}}
local interpolatedMap = getInterpolatedMap(worldMap)
local crankToAngleRatio = 28
local hitAccuracy = 10
local hitScore = 25
local missScore = 10
local degreeSoundFrequency = 5
local startShotX = 15
local startShotY = 152
local gravity = 100 -- pxls/sec^2

local gameState = {}

function initializeMenu()
    local mainMenuImage = gfx.image.new("Images/mainMenu")
    startButtonImageTable = gfx.imagetable.new("./Images/start")
    startAnimator = gfx.animation.loop.new(400, startButtonImageTable, true)

    menuSprite = gfx.sprite.new(mainMenuImage)
    menuSprite:setCenter(0, 0)
    menuSprite:add()

    startButtonSprite = gfx.sprite.new()
    startButtonSprite:moveTo(155, 180)
    startButtonSprite:add()

    bestScore = readFromPersistent()
end

function initializeFinish()
    startButtonSprite:add()
    startButtonSprite:moveTo(145, 100)
end

function clearMenu()
    menuSprite:remove()
    startButtonSprite:remove()
end

function clearFinish()
    startButtonSprite:remove()
end

function initializeGameplay()
    gameState.startTime = 0
    gameState.lastTime = 0
    gameState.angle = 15
    gameState.moving = false
    gameState.score = 0
    gameState.shots = 0
    gameState.enemies = {}
    gameState.trajectoryDrawDistance = 1
    gameState.cheats = false
    gameState.enemyPositions = {math.random(200, 245), math.random(255, 295), math.random(305, 345), math.random(355, 400)}

    resources = initGameplayResources()

    -- INITIALIZE WORLD
    if not gameplaySpritesInited then
        shotAnimSprite = gfx.sprite.new()
        backgroundSprite = gfx.sprite.new(resources.images.backgroundImage)
        playerSprite = gfx.sprite.new(resources.images.playerImage)
        projectileSprite = gfx.sprite.new(resources.images.projectileImage)
        gunSprite = gfx.sprite.new(resources.images.gunImage)

        gameplaySpritesInited = true
    end

    shotAnimSprite:setRotation(30)
    shotAnimSprite:setCenter(0.5, 1.2)
    shotAnimSprite:moveTo(13, 154)
    shotAnimSprite:add()

    backgroundSprite:setCenter(0, 0)
    backgroundSprite:setZIndex(-1)
    backgroundSprite:add()

    playerSprite:moveTo(13, 160)
    playerSprite:add()
    playerSprite:setZIndex(1)

    gunSprite:moveTo(15, 152)
    gunSprite:setCenter(0.5, 1)
    gunSprite:add()
    gunSprite:setZIndex(0)

    for key, val in pairs(gameState.enemyPositions) do
        gameState.enemies[key] = gfx.sprite.new(resources.images.enemyImage)
        gameState.enemies[key]:moveTo(val, interpolatedMap[val])
        gameState.enemies[key]:add()
    end
end

function updateGun()
    if (shotAnimator) then
        shotAnimSprite:setImage(shotAnimator:image())
    end

    local crankChange = playdate.getCrankChange()
    local newAngle = gameState.angle + crankChange / crankToAngleRatio
    if (math.floor(gameState.angle / degreeSoundFrequency) ~= math.floor(newAngle / degreeSoundFrequency)) then
        resources.sounds.degreeSound:play()
    end
    gameState.angle = newAngle

    shotAnimSprite:setRotation(-gameState.angle + 90)
    gunSprite:setRotation(-gameState.angle + 90)
    if (recoilAnimator) then
        gunSprite:setCenter(0.5, recoilAnimator:currentValue())
    end
end

function drawTrajectory(angle)
    local angleRadian = angle * math.pi / 180
    local v0y = math.sin(angleRadian) * -speed
    local vx = math.cos(angleRadian) * speed

    for t = 0, gameState.trajectoryDrawDistance, 0.05 do
        gfx.drawPixel(t * vx + startShotX - 1, (v0y * t + gravity * t ^ 2 / 2) + startShotY - 1)
    end
end

function checkHit(x)
    local hit = false
    for key, val in pairs(gameState.enemyPositions) do
        local distance = math.abs(x - val)
        if (distance < hitAccuracy) then
            gameState.enemies[key]:remove()
            gameState.enemyPositions[key] = nil
            gameState.score = gameState.score + hitScore * (math.ceil((hitAccuracy - distance) / 2.5))
            if gameState.cheats == false and (bestScore == nil or bestScore < gameState.score) then
                saveToPersistent(gameState.score)
            end
            hit = true
            break
        end
    end
    if hit == false and gameState.shots > 1 then
        gameState.score = gameState.score - missScore
    end
end

function updateMenu()
    if playdate.buttonJustPressed(playdate.kButtonA) then
        clearMenu()
        initializeGameplay()
        gameStep = 2
    end

    startButtonSprite:setImage(startAnimator:image())

    gfx.sprite.update()
    gfx.drawText('to start', 175, 170)
    if bestScore and bestScore > 0 then
        gfx.drawText('Best score:  ' .. tostring(bestScore), 132, 195)
    end
end

function updateFinish()
    if playdate.buttonJustPressed(playdate.kButtonA) then
        clearFinish()
        initializeGameplay()
        gameStep = 2
    end

    startButtonSprite:setImage(startAnimator:image())
    gfx.sprite.update()
    
    gfx.drawText("Mission completed!", 132, 30)
    gfx.drawText("Your score: " .. tostring(gameState.score), 132, 55)
    gfx.drawText("to play again", 160, 90)
end

function updateProjectile(deltaTime)
    if gameState.moving then
        local angleRadian = gameState.angle * math.pi / 180
        local v0y = math.sin(angleRadian) * -speed
        local vx = math.cos(angleRadian) * speed
        local vy = (v0y + gravity * (gameState.lastTime - gameState.startTime))

        local currentX, currentY = projectileSprite:getPosition()
        if (currentX < 0 or currentX > 400 or currentY > interpolatedMap[math.floor(currentX)]) then
            projectileSprite:remove()
            resources.soundPlayers.whistlePlayer:stop()
            resources.soundPlayers.explosionPlayer:play()
            checkHit(currentX)
            gameState.moving = false
        else
            projectileSprite:moveBy(vx * deltaTime, vy * deltaTime)
            projectileSprite:setRotation(math.atan2(vy, vx) * 180 / math.pi + 90)
        end
        if (gameState.moving and resources.soundPlayers.whistlePlayer:isPlaying() == false and gameState.lastTime - gameState.startTime > 0.7) then
            resources.soundPlayers.whistlePlayer:play()
        end
    end
end

function updateGameplay()
    local deltaTime = playdate.getElapsedTime() - gameState.lastTime
    gameState.lastTime = playdate.getElapsedTime()

    updateGun()
    updateProjectile(deltaTime)
    if(checkKonamiCode()) then
        gameState.trajectoryDrawDistance = 5 
        gameState.cheats = true   
    elseif playdate.buttonJustPressed(playdate.kButtonA) then
        gameState.moving = true
        gameState.shots = gameState.shots + 1
        resources.sounds.shotSound:play()
        shotAnimator = gfx.animation.loop.new(30, resources.images.shotImageTable, false)
        recoilAnimator = gfx.animator.new(300, 0.5, 1, playdate.easingFunctions.inOutCubic)
        gameState.startTime = playdate.getElapsedTime()
        gameState.lastTime = gameState.startTime
        projectileSprite:moveTo(startShotX, startShotY)
        projectileSprite:add()
    end

    gfx.sprite.update()
    playdate.timer.updateTimers()
    updateScore(gameState.score)
    drawTrajectory(gameState.angle)

    if #(gameState.enemyPositions) == 0 then
        initializeFinish()
        gameStep = 3
    end
end

initializeMenu()

function playdate.update()
    if gameStep == 1 then
        updateMenu()
    elseif gameStep == 2 then
        updateGameplay()
    elseif gameStep == 3 then
        updateFinish()
    end
end
