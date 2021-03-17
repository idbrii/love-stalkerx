-- Demonstration of STALKER-X
-- Creates a world with a player who can walk around the world.

local Camera = require('Camera')

local camera,style_names
local world_dimensions = {1600,1200}
local is_faded = false
local has_gravity = false

local player = {
    x = world_dimensions[1] * 0.5,
    y = world_dimensions[2] * 0.5,
    velocity = {
        y = 0,
    },
    jump_height = -300,
    gravity = -500,
    width = 10,
}

local chaser = {
    x = 0,
    y = 0,
}

local function clamp(x, min, max)
    return math.min(math.max(x, min), max)
end
local function lerp(a,b,t)
    return a * (1-t) + b * t
end
local function loop(i, n)
    local z = i - 1
    return (z % n) + 1
end

local function translate(x,y)
    local half_width = player.width / 2
    player.x = clamp(player.x + x, half_width, world_dimensions[1] - half_width)
    player.y = clamp(player.y + y, half_width, world_dimensions[2] - half_width)
end

local function style_to_name(follow_style)
    return style_names[follow_style]
end

local function increment_style(delta)
    local follow_style = loop(camera.follow_style + delta, #style_names)
    camera:setFollowStyle(follow_style)
    print("Set follow style to:", style_to_name(follow_style))
end



function love.load()
    camera = Camera()

    style_names = {}
    for k, v in pairs(camera.style) do style_names[v] = k end

    -- If you don't omit this step, uses NO_DEADZONE by default.
    camera:setFollowStyle(camera.style.TOPDOWN)
end

function love.keyreleased(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'z' then
        camera.draw_deadzone = not camera.draw_deadzone 
    elseif key == 'p' then
        has_gravity = not has_gravity
        if has_gravity then
            player.velocity.y = 1
        else
            player.velocity.y = 0
        end
    elseif key == 'q' then
        increment_style(-1)
    elseif key == 'e' then
        increment_style(1)
    elseif key == 'f' then
        local fade
        if is_faded then
            -- Change fade to transparent
            fade = {0, 0, 0, 0}
        else
            -- Draw black over screen.
            fade = {0, 0, 0, 1}
        end
        is_faded = not is_faded
        print("Set fade to:", is_faded, unpack(fade))
        camera:fade(1, fade)
    elseif key == 'g' then
        print("Flashing camera")
        camera:flash(0.05, {1, 1, 1, 0.5})
    elseif key == 'h' then
        if camera.follow_style == camera.style.NO_DEADZONE then
            print("Shaking doesn't work with NO_DEADZONE. Not enough slack to move around.")
        end
        print("Shaking camera")
        camera:shake(8, 1, 60)
    elseif key == 'n' then
        camera.scale = loop(camera.scale + 1, 4)
    elseif key == 'm' then
        camera.scale = camera.scale * 0.5
    end
end

function love.update(dt)
    local moveSpeed = 300
    local tau = math.pi * 2
    local rotateSpeed = tau * 0.05
    
    if love.keyboard.isDown('a') then translate(-moveSpeed * dt, 0) end
    if love.keyboard.isDown('d') then translate(moveSpeed * dt, 0) end

    if love.keyboard.isDown('x') then camera.rotation = camera.rotation - rotateSpeed * dt end
    if love.keyboard.isDown('c') then camera.rotation = camera.rotation + rotateSpeed * dt end

    if has_gravity then
        -- See https://love2d.org/wiki/Tutorial:Baseline_2D_Platformer
        if love.keyboard.isDown('w') or love.keyboard.isDown('space') then
            -- infinite jumps
            player.velocity.y = player.jump_height
        end
        if player.velocity.y ~= 0 then
            player.y = player.y + player.velocity.y * dt
            player.velocity.y = player.velocity.y - player.gravity * dt
        end

        local half_width = player.width * 0.5
        local bottom = world_dimensions[2] - half_width
        if player.y > bottom then
            player.velocity.y = 0
            player.y = bottom
        end
    else
        if love.keyboard.isDown('w') then translate(0, -moveSpeed * dt) end
        if love.keyboard.isDown('s') then translate(0, moveSpeed * dt) end
    end

    -- Chase the mouse to demonstrate converting mouse to world
    -- coordinates.
    local x,y = camera:getMousePosition()
    chaser.x = lerp(chaser.x, x, 0.025)
    chaser.y = lerp(chaser.y, y, 0.025)

    -- ## Update the camera and the target position. ##
    camera:follow(player.x, player.y)
    camera:update(dt)
end

local function draw_game()
    -- Draw world bounds.
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('line', 0, 0, world_dimensions[1], world_dimensions[2])
    -- Draw the player (position is their centre)
    love.graphics.setColor(0, 1, 1, 1)
    local half_width = player.width * 0.5
    love.graphics.rectangle('fill', player.x - half_width, player.y - half_width, player.width, player.width)
    -- Populate the world with something.
    love.graphics.setColor(1, 0, 1, 1)
    for y=0,world_dimensions[2]-1,10 do
        for x=0,world_dimensions[1]-1,10 do
            if love.math.noise(x,y) > 0.98 then
                love.graphics.rectangle('fill', x, y, 10, 10)
            end
        end
    end
    -- Draw mouse position
    love.graphics.setColor(1, 1, 0, 1)
    local x,y = camera:getMousePosition()
    love.graphics.circle('fill', x,y, 7,7)
    love.graphics.setColor(0.5, 1, 0, 1)
    love.graphics.circle('fill', chaser.x,chaser.y, 7,7)
end

function love.draw()
    love.graphics.clear()
    camera:attach() do
        -- ## Draw the game here ##
        draw_game()
    end camera:detach()
    camera:draw() -- Must call this to use camera:fade!
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(style_to_name(camera.follow_style), 0,0, 1000)
    love.graphics.printf("Physics: " .. (has_gravity and "Platformer" or "TopDown"), 0,20, 1000)
    if is_faded then
        love.graphics.printf("Press f to unfade", 0,40, 1000)
    end

    local x,y = camera:toCameraCoords(world_dimensions[1]/2,world_dimensions[2]/2)
    love.graphics.circle("line", x,y, 5,5)
    love.graphics.printf("World Center", x,y, 100, 'center')
end

