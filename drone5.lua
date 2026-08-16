local front = peripheral.wrap("gyroscopic_propeller_bearing_0")
local back  = peripheral.wrap("gyroscopic_propeller_bearing_1")
local left  = peripheral.wrap("gyroscopic_propeller_bearing_2")
local right = peripheral.wrap("gyroscopic_propeller_bearing_3")

local selected = front
local angle = 0

while true do
    term.clear()
    term.setCursorPos(1, 1)

    print("GYROSCOPIC BEARING TESTER")
    print("-------------------------")
    print("1 - FRONT")
    print("2 - BACK")
    print("3 - LEFT")
    print("4 - RIGHT")
    print("")
    print("A - X -10")
    print("D - X +10")
    print("W - Y +10")
    print("S - Y -10")
    print("Q - CENTER")
    print("E - EXIT")
    print("")
    print("Angle: " .. angle)

    local _, key = os.pullEvent("key")

    if key == keys.one then
        selected = front

    elseif key == keys.two then
        selected = back

    elseif key == keys.three then
        selected = left

    elseif key == keys.four then
        selected = right

    elseif key == keys.a then
        angle = angle - 10
        selected.setManualTarget({
            x = angle,
            y = 0,
            z = 0
        })

    elseif key == keys.d then
        angle = angle + 10
        selected.setManualTarget({
            x = angle,
            y = 0,
            z = 0
        })

    elseif key == keys.w then
        selected.setManualTarget({
            x = 0,
            y = 10,
            z = 0
        })

    elseif key == keys.s then
        selected.setManualTarget({
            x = 0,
            y = -10,
            z = 0
        })

    elseif key == keys.q then
        selected.setManualTarget({
            x = 0,
            y = 0,
            z = 0
        })
        angle = 0

    elseif key == keys.e then
        front.setManualTarget({x = 0, y = 0, z = 0})
        back.setManualTarget({x = 0, y = 0, z = 0})
        left.setManualTarget({x = 0, y = 0, z = 0})
        right.setManualTarget({x = 0, y = 0, z = 0})
        break
    end
end
