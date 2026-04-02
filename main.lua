require "love"
require "fsm"

function love.load()

    local states = {
        top = {enter = function() print("Top") end, update = function() end},
        left = {enter = function() print("Left") end, update = function() end},
        center = {enter = function() print("Center") end, update = function() end},
        right = {enter = function() print("Right") end, update = function() end},
        bottom = {enter = function() print("Bottom") end, update = function() end},
    }

    local modalities = {
        a = {from = "top", to = "left"},
        s = {from = {{"left", "center", "right"}, "top", "bottom"}, to = {"bottom", "center", "top"}},
        d = {from = "top", to = "right"}
    }

    test_fsm = machines.new(states, modalities, "top")

end

function love.keypressed(key, _, _)

    if key == "w" or key == "a" or key == "s" or key == "d" then

        test_fsm:update(key)

    end
end

function love.update(dt)

    if love.keyboard.isDown("escape") then love.event.push("quit") end
    
end

function love.draw()

end