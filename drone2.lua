local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")

-- =========================================
-- TARGET
-- =========================================

local TARGET_X = 100
local TARGET_Y = 80
local TARGET_Z = 200

-- =========================================
-- PD CONSTANTS
-- =========================================

local KP_X = 1.0
local KD_X = 0.4

local KP_Y = 1.0
local KD_Y = 0.4

local KP_Z = 1.0
local KD_Z = 0.4

-- Maksymalna zmiana RPM
local MAX_CONTROL = 30

-- Bazowa prędkość wirników
local BASE_RPM = 20

-- =========================================

local function setSpeed(controller, speed)
    speed = math.max(-256, math.min(256, speed))
    controller.setTargetSpeed(speed)
end

local function stop()
    setSpeed(front, 0)
    setSpeed(back, 0)
    setSpeed(left, 0)
    setSpeed(right, 0)
end

local function getGPS()
    local x, y, z = gps.locate(3)

    if not x then
        return nil
    end

    return x, y, z
end

-- =========================================
-- START
-- =========================================

print("DRONE PD CONTROLLER")
print("-------------------")

local x, y, z = getGPS()

if not x then
    print("Brak GPS!")
    return
end

local lastX = x
local lastY = y
local lastZ = z

local lastTime = os.clock()

print(string.format(
    "START %.2f %.2f %.2f",
    x, y, z
))

print(string.format(
    "TARGET %.2f %.2f %.2f",
    TARGET_X,
    TARGET_Y,
    TARGET_Z
))

sleep(1)

-- =========================================
-- MAIN LOOP
-- =========================================

while true do

    local currentX, currentY, currentZ = getGPS()

    if not currentX then
        print("Brak GPS!")
        stop()
        sleep(0.5)
        goto continue
    end

    local now = os.clock()
    local dt = now - lastTime

    if dt <= 0 then
        dt = 0.1
    end

    -- =====================================
    -- POSITION ERROR
    -- =====================================

    local errorX = TARGET_X - currentX
    local errorY = TARGET_Y - currentY
    local errorZ = TARGET_Z - currentZ

    -- =====================================
    -- VELOCITY
    -- =====================================

    local velocityX =
        (currentX - lastX) / dt

    local velocityY =
        (currentY - lastY) / dt

    local velocityZ =
        (currentZ - lastZ) / dt

    -- =====================================
    -- PD
    -- =====================================

    local controlX =
        KP_X * errorX -
        KD_X * velocityX

    local controlY =
        KP_Y * errorY -
        KD_Y * velocityY

    local controlZ =
        KP_Z * errorZ -
        KD_Z * velocityZ

    -- ograniczenie
    controlX =
        math.max(-MAX_CONTROL,
        math.min(MAX_CONTROL, controlX))

    controlY =
        math.max(-MAX_CONTROL,
        math.min(MAX_CONTROL, controlY))

    controlZ =
        math.max(-MAX_CONTROL,
        math.min(MAX_CONTROL, controlZ))

    -- =====================================
    -- MOTOR MIXING
    -- =====================================

    local frontRPM = BASE_RPM
    local backRPM  = BASE_RPM
    local leftRPM  = BASE_RPM
    local rightRPM = BASE_RPM

    -- X
    leftRPM  = leftRPM  + controlX
    rightRPM = rightRPM - controlX

    -- Z
    frontRPM = frontRPM + controlZ
    backRPM  = backRPM  - controlZ

    -- Y
    frontRPM = frontRPM + controlY
    backRPM  = backRPM + controlY
    leftRPM  = leftRPM  + controlY
    rightRPM = rightRPM + controlY

    -- =====================================
    -- SEND RPM
    -- =====================================

    setSpeed(front, frontRPM)
    setSpeed(back, backRPM)
    setSpeed(left, leftRPM)
    setSpeed(right, rightRPM)

    -- =====================================
    -- DISPLAY
    -- =====================================

    term.clear()
    term.setCursorPos(1, 1)

    print("DRONE PD CONTROLLER")
    print("-------------------")

    print(string.format(
        "POS %.1f %.1f %.1f",
        currentX,
        currentY,
        currentZ
    ))

    print(string.format(
        "ERR %.1f %.1f %.1f",
        errorX,
        errorY,
        errorZ
    ))

    print(string.format(
        "VEL %.1f %.1f %.1f",
        velocityX,
        velocityY,
        velocityZ
    ))

    print("")

    print(string.format(
        "PD  %.1f %.1f %.1f",
        controlX,
        controlY,
        controlZ
    ))

    print("")

    print(string.format(
        "RPM F:%d B:%d",
        frontRPM,
        backRPM
    ))

    print(string.format(
        "RPM L:%d R:%d",
        leftRPM,
        rightRPM
    ))

    -- =====================================
    -- TARGET CHECK
    -- =====================================

    local distance =
        math.sqrt(
            errorX^2 +
            errorY^2 +
            errorZ^2
        )

    if distance < 1 then

        print("")
        print("TARGET REACHED!")

        stop()

        break
    end

    -- =====================================

    lastX = currentX
    lastY = currentY
    lastZ = currentZ

    lastTime = now

    ::continue::

    sleep(0.1)
end
