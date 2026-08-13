-- ==========================================
-- SIMPLE DRONE PD CONTROLLER
-- CC:Tweaked + Create Aeronautics
-- ==========================================

-- ==========================================
-- MOTORS
-- ==========================================

local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")

if not front or not back or not left or not right then
    print("Brakuje Rotation Speed Controller!")
    return
end


-- ==========================================
-- TARGET
-- ==========================================

-- USTAW TUTAJ CEL

local TARGET_X = 100
local TARGET_Y = 80
local TARGET_Z = 200


-- ==========================================
-- SETTINGS
-- ==========================================

-- RPM potrzebne do utrzymania zawisu
local HOVER_RPM = 50

-- Maksymalna zmiana RPM
local MAX_CONTROL = 30

-- PD dla X
local KP_X = 2.0
local KD_X = 1.0

-- PD dla Y
local KP_Y = 2.0
local KD_Y = 1.0

-- PD dla Z
local KP_Z = 2.0
local KD_Z = 1.0

-- Jak często działa kontroler
local DT = 0.05

-- Tolerancja dotarcia
local POSITION_TOLERANCE = 1.0


-- ==========================================
-- MOTOR FUNCTION
-- ==========================================

local function setMotors(frontRPM, backRPM, leftRPM, rightRPM)

    front.setTargetSpeed(frontRPM)
    back.setTargetSpeed(backRPM)
    left.setTargetSpeed(leftRPM)
    right.setTargetSpeed(rightRPM)

end


local function stopMotors()

    setMotors(0, 0, 0, 0)

end


-- ==========================================
-- CLAMP
-- ==========================================

local function clamp(value, min, max)

    if value < min then
        return min
    end

    if value > max then
        return max
    end

    return value

end


-- ==========================================
-- GPS
-- ==========================================

local function getPosition()

    local x, y, z = gps.locate(2)

    if not x then
        return nil
    end

    return x, y, z

end


-- ==========================================
-- START
-- ==========================================

term.clear()
term.setCursorPos(1, 1)

print("================================")
print("       DRONE PD CONTROLLER")
print("================================")
print("")

print(string.format(
    "TARGET: %.1f %.1f %.1f",
    TARGET_X,
    TARGET_Y,
    TARGET_Z
))

print("")

local x, y, z = getPosition()

if not x then

    print("Brak GPS!")
    return

end

print(string.format(
    "START: %.1f %.1f %.1f",
    x,
    y,
    z
))

print("")
print("ENTER aby wystartowac")

read()


-- ==========================================
-- PREVIOUS POSITION
-- ==========================================

local lastX = x
local lastY = y
local lastZ = z


-- ==========================================
-- MAIN LOOP
-- ==========================================

while true do

    -- ======================================
    -- GPS
    -- ======================================

    local currentX, currentY, currentZ = getPosition()

    if not currentX then

        print("BRAK GPS!")

        stopMotors()

        sleep(0.5)

    else

        -- ==================================
        -- POSITION ERROR
        -- ==================================

        local errorX = TARGET_X - currentX
        local errorY = TARGET_Y - currentY
        local errorZ = TARGET_Z - currentZ


        -- ==================================
        -- VELOCITY
        -- ==================================

        local velocityX =
            (currentX - lastX) / DT

        local velocityY =
            (currentY - lastY) / DT

        local velocityZ =
            (currentZ - lastZ) / DT


        -- ==================================
        -- PD CONTROLLER
        -- ==================================

        local controlX =
            KP_X * errorX
            - KD_X * velocityX

        local controlY =
            KP_Y * errorY
            - KD_Y * velocityY

        local controlZ =
            KP_Z * errorZ
            - KD_Z * velocityZ


        -- ==================================
        -- LIMIT CONTROL
        -- ==================================

        controlX =
            clamp(
                controlX,
                -MAX_CONTROL,
                MAX_CONTROL
            )

        controlY =
            clamp(
                controlY,
                -MAX_CONTROL,
                MAX_CONTROL
            )

        controlZ =
            clamp(
                controlZ,
                -MAX_CONTROL,
                MAX_CONTROL
            )


        -- ==================================
        -- MOTOR MIXER
        -- ==================================

        local frontRPM =
            HOVER_RPM
            + controlY
            + controlZ

        local backRPM =
            HOVER_RPM
            + controlY
            - controlZ

        local leftRPM =
            HOVER_RPM
            + controlY
            + controlX

        local rightRPM =
            HOVER_RPM
            + controlY
            - controlX


        -- ==================================
        -- LIMIT RPM
        -- ==================================

        frontRPM = math.max(0, frontRPM)
        backRPM  = math.max(0, backRPM)
        leftRPM  = math.max(0, leftRPM)
        rightRPM = math.max(0, rightRPM)


        -- ==================================
        -- SEND TO MOTORS
        -- ==================================

        setMotors(
            frontRPM,
            backRPM,
            leftRPM,
            rightRPM
        )


        -- ==================================
        -- DISTANCE
        -- ==================================

        local distance =
            math.sqrt(
                errorX * errorX +
                errorY * errorY +
                errorZ * errorZ
            )


        -- ==================================
        -- DISPLAY
        -- ==================================

        term.clear()
        term.setCursorPos(1, 1)

        print("DRONE PD CONTROLLER")
        print("-------------------")

        print(string.format(
            "POS %.2f %.2f %.2f",
            currentX,
            currentY,
            currentZ
        ))

        print(string.format(
            "TARGET %.2f %.2f %.2f",
            TARGET_X,
            TARGET_Y,
            TARGET_Z
        ))

        print("")

        print(string.format(
            "ERROR %.2f %.2f %.2f",
            errorX,
            errorY,
            errorZ
        ))

        print("")

        print(string.format(
            "VEL %.2f %.2f %.2f",
            velocityX,
            velocityY,
            velocityZ
        ))

        print("")

        print(string.format(
            "CTRL %.2f %.2f %.2f",
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

        print("")

        print(string.format(
            "DISTANCE %.2f",
            distance
        ))


        -- ==================================
        -- TARGET REACHED
        -- ==================================

        if distance < POSITION_TOLERANCE then

            print("")
            print("TARGET REACHED!")

            stopMotors()

            break

        end


        -- ==================================
        -- SAVE POSITION
        -- ==================================

        lastX = currentX
        lastY = currentY
        lastZ = currentZ


        sleep(DT)

    end

end
