local nav = peripheral.wrap("navigation_table_0")

local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")

if not nav then
    error("Brak navigation_table_0")
end

if not front or not back or not left or not right then
    error("Brak front/back/left/right")
end

local BASE_RPM = 100
local POWER = 100

local function clamp(x)
    return math.max(-256, math.min(256, x))
end

local function setRPM(controller, rpm)
    controller.setTargetSpeed(clamp(rpm))
end

while true do
    local bearing = nav.getBearingRad()

    -- Rozklad kierunku celu na osie drona
    local forward = math.cos(bearing)
    local rightDir = math.sin(bearing)

    -- Sterowanie
    local frontRPM = BASE_RPM + forward * POWER
    local backRPM  = BASE_RPM - forward * POWER

    local rightRPM = BASE_RPM + rightDir * POWER
    local leftRPM  = BASE_RPM - rightDir * POWER

    frontRPM = clamp(frontRPM)
    backRPM  = clamp(backRPM)
    leftRPM  = clamp(leftRPM)
    rightRPM = clamp(rightRPM)

    setRPM(front, frontRPM)
    setRPM(back, backRPM)
    setRPM(left, leftRPM)
    setRPM(right, rightRPM)

    term.clear()
    term.setCursorPos(1, 1)

    print("=== DRONE DIRECTION TEST ===")
    print()

    print(string.format(
        "Bearing: %.1f deg",
        math.deg(bearing)
    ))

    print(string.format(
        "Forward: %.2f",
        forward
    ))

    print(string.format(
        "Right:   %.2f",
        rightDir
    ))

    print()

    print("FRONT: " .. math.floor(frontRPM))
    print("BACK:  " .. math.floor(backRPM))
    print("LEFT:  " .. math.floor(leftRPM))
    print("RIGHT: " .. math.floor(rightRPM))

    sleep(0.1)
end
