local WINDOW_WIDTH = 500
local WINDOW_HEIGHT = 180
local SPRITE_PATH = 'assets/sprites/bgsprite.png'
local ENEMY_SCALE = 0.2
local MIN_ENEMY_SPEED = 60
local MAX_ENEMY_SPEED = 100
local SPAWN_INTERVAL = 1
local EXPLOSION_DURATION = 0.5
local MAX_EXPLOSION_RADIUS = 40

local enemies = {}
local bullets = {}
local explosions = {}
local spawnTimer = 0
local sprite
local gameOver = false

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        love.event.quit()
    end

    if key == "r" then
        love.event.quit("restart")
    end
end

local gg = {
    x = 270,
    y = 600,
    xvel = 0,
    speed = 28,
    friction = 3,
    sprite = love.graphics.newImage('assets/sprites/ggsprite.png'),
    bulletSpeed = 400,
    bulletWidth = 8,
    bulletHeight = 18,
    bulletCooldown = 0.2,
    bulletTimer = 0
}

local function spawnEnemy()
    local enemy = {
        x = math.random(0, WINDOW_WIDTH),
        y = -sprite:getHeight() * ENEMY_SCALE,
        speed = math.random(MIN_ENEMY_SPEED, MAX_ENEMY_SPEED),
        width = sprite:getWidth() * ENEMY_SCALE,
        height = sprite:getHeight() * ENEMY_SCALE
    }
    table.insert(enemies, enemy)
end

local function spawnBullet()
    local bullet = {
        x = gg.x + (gg.sprite:getWidth() * 0.2 / 2) - (gg.bulletWidth / 2),
        y = gg.y,
        width = gg.bulletWidth,
        height = gg.bulletHeight,
        speed = gg.bulletSpeed
    }
    table.insert(bullets, bullet)
end

local function checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end

function love.load()
    sprite = love.graphics.newImage(SPRITE_PATH)
    gameOverFont = love.graphics.newFont(48)  -- Set the font size for the Game Over text
end

function love.update(dt)
    if gameOver then
        return  -- Exit early to pause the game updates
    end

    gg.x = gg.x + gg.xvel
    gg.xvel = gg.xvel * (1 - math.min(dt * gg.friction, 1))

    if (love.keyboard.isDown("right") or love.keyboard.isDown("d")) and gg.xvel < 100 then
        gg.xvel = gg.xvel + gg.speed * dt
    end

    if (love.keyboard.isDown("left") or love.keyboard.isDown("a")) and gg.xvel > -100 then
        gg.xvel = gg.xvel - gg.speed * dt
    end


    local ggWidth = gg.sprite:getWidth() * 0.2
    if gg.x < 0 then
        gg.x = 0
        gg.xvel = 0
    elseif gg.x > WINDOW_WIDTH then
        gg.x = WINDOW_WIDTH
        gg.xvel = 0
    end

    gg.bulletTimer = gg.bulletTimer - dt
    if love.keyboard.isDown("space") and gg.bulletTimer <= 0 then
        spawnBullet()
        gg.bulletTimer = gg.bulletCooldown
    end

    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        bullet.y = bullet.y - bullet.speed * dt
        if bullet.y < 0 then
            table.remove(bullets, i)
        end
    end

    spawnTimer = spawnTimer + dt
    if spawnTimer >= SPAWN_INTERVAL then
        spawnEnemy()
        spawnTimer = 0
    end

    for _, enemy in ipairs(enemies) do
        enemy.y = enemy.y + enemy.speed * dt
    end

    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        for j = #enemies, 1, -1 do
            local enemy = enemies[j]
            if checkCollision(bullet, enemy) then
                table.insert(explosions, {x = enemy.x + enemy.width / 2, y = enemy.y + enemy.height / 2, timer = 0})
                table.remove(bullets, i)
                table.remove(enemies, j)
                break
            end
        end
    end

    for i = #explosions, 1, -1 do
        local explosion = explosions[i]
        explosion.timer = explosion.timer + dt
        if explosion.timer >= EXPLOSION_DURATION then
            table.remove(explosions, i)
        end
    end

    for _, enemy in ipairs(enemies) do
        if checkCollision(enemy, {x = gg.x, y = gg.y, width = gg.sprite:getWidth() * 0.2, height = gg.sprite:getHeight() * 0.2}) then
            gameOver = true
            break
        end
    end
end


function love.draw()
    love.graphics.draw(gg.sprite, gg.x, gg.y, nil, 0.2)

    love.graphics.setColor(1, 0, 0)
    for _, bullet in ipairs(bullets) do
        love.graphics.rectangle("fill", bullet.x, bullet.y, bullet.width, bullet.height)
    end
    love.graphics.setColor(1, 1, 1)

    for _, enemy in ipairs(enemies) do
        love.graphics.draw(sprite, enemy.x, enemy.y, nil, ENEMY_SCALE)
    end

    for _, explosion in ipairs(explosions) do
        local progress = explosion.timer / EXPLOSION_DURATION
        local radius = MAX_EXPLOSION_RADIUS * progress
        local alpha = 0.5 - (0.5 * progress)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.circle("fill", explosion.x, explosion.y, radius)
    end
    love.graphics.setColor(1, 1, 1)

    if gameOver then
        local boxWidth, boxHeight = 400, 100
        local boxX = 100
        local boxY = 350

        love.graphics.setColor(1, 1, 1, 0.7)  -- Set the box background color to white with low opacity
        love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight)

        love.graphics.setFont(gameOverFont)  -- Set the font to the larger size
        love.graphics.setColor(0, 0, 0, 1)  -- Set the text color to black for better contrast
        love.graphics.printf("Game Over", boxX, boxY + (boxHeight / 2) - 24, boxWidth, "center")
    end
end
