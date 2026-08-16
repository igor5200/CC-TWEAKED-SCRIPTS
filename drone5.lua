-- =========================================================
-- GPS DRONE 3D
-- GPS -> VECTOR -> HEADING -> GYROSCOPIC PROPELLERS
-- =========================================================


-- =========================================================
-- CEL
-- =========================================================

local TARGET_X = -232
local TARGET_Y = 70
local TARGET_Z = -59


-- =========================================================
-- PROFIL WYSOKOŚCI
-- =========================================================

local CRUISE_HEIGHT = 100
local DESCENT_DISTANCE = 50


-- =========================================================
-- GYROSCOPIC PROPELLER BEARINGS
-- =========================================================

local front = peripheral.wrap("gyroscopic_propeller_bearing_0")
local right = peripheral.wrap("gyroscopic_propeller_bearing_1")
local back = peripheral.wrap("gyroscopic_propeller_bearing_2")
local left = peripheral.wrap("gyroscopic_propeller_bearing_3")


-- =========================================================
-- ROTATION SPEED CONTROLLERS
-- =========================================================

local frontRSC = peripheral.wrap("front")
local rightRSC = peripheral.wrap("right")
local backRSC = peripheral.wrap("back")
local leftRSC = peripheral.wrap("left")

local vertical =
    peripheral.wrap("Create_RotationSpeedController_0")


-- =========================================================
-- RUCH POZIOMY
-- =========================================================

local MAX_HORIZONTAL_SPEED = 40

local POSITION_GAIN = 1.5

local MIN_HORIZONTAL_POWER = 5


-- =========================================================
-- RUCH PIONOWY
-- =========================================================

local MAX_VERTICAL_POWER = 30

local VERTICAL_GAIN = 2.0

local MIN_VERTICAL_POWER = 5


-- =========================================================
-- TOLERANCJA
-- =========================================================

local TARGET_RADIUS = 2

local TARGET_HEIGHT = 1


-- =========================================================
-- CLAMP
-- =========================================================

local function clamp(value, min, max)

    if value < min then
        return min
    end

    if value > max then
        return max
    end

    return value
end


-- =========================================================
-- STOP POZIOMY
-- =========================================================

local function stopHorizontal()

    frontRSC.setTargetSpeed(0)
    backRSC.setTargetSpeed(0)
    leftRSC.setTargetSpeed(0)
    rightRSC.setTargetSpeed(0)

end


-- =========================================================
-- STOP PIONOWY
-- =========================================================

local function stopVertical()

    vertical.setTargetSpeed(0)

end


-- =========================================================
-- STOP
-- =========================================================

local function stop()

    stopHorizontal()
    stopVertical()

end


-- =========================================================
-- START
-- =========================================================

print("GPS DRONE 3D")
print()

print("TARGET")
print("X =", TARGET_X)
print("Y =", TARGET_Y)
print("Z =", TARGET_Z)

sleep(2)


-- =========================================================
-- GŁÓWNA PĘTLA
-- =========================================================

while true do

    -- =====================================================
    -- GPS
    -- =====================================================

    local pose = sublevel.getLogicalPose()

    local droneX =
        pose.position.x

    local droneY =
        pose.position.y

    local droneZ =
        pose.position.z


    if not droneX then

        stop()

        sleep(0.2)

    else

        -- =================================================
        -- WEKTOR DO CELU
        -- =================================================

        local vx =
            TARGET_X - droneX

        local vz =
            TARGET_Z - droneZ


        -- =================================================
        -- ODLEGŁOŚĆ
        -- =================================================

        local horizontalDistance =
            math.sqrt(
                vx * vx +
                vz * vz
            )


        -- =================================================
        -- WYSOKOŚĆ
        -- =================================================

        local desiredY

        if horizontalDistance >= DESCENT_DISTANCE then

            desiredY =
                CRUISE_HEIGHT

        else

            local t =
                horizontalDistance /
                DESCENT_DISTANCE

            desiredY =
                TARGET_Y +
                (CRUISE_HEIGHT - TARGET_Y) * t

        end


        local vy =
            desiredY - droneY


        local verticalDistance =
            math.abs(vy)


        -- =================================================
        -- CEL OSIĄGNIĘTY
        -- =================================================

        if horizontalDistance <= TARGET_RADIUS
            and math.abs(TARGET_Y - droneY) <= TARGET_HEIGHT then

            stop()

            print("TARGET REACHED")

            break

        end


        -- =================================================
        -- RUCH POZIOMY
        -- =================================================

        if horizontalDistance > TARGET_RADIUS then

            -- ---------------------------------------------
            -- NORMALNY WEKTOR WORLD
            -- ---------------------------------------------

            local worldX =
                vx / horizontalDistance

            local worldZ =
                vz / horizontalDistance


            -- ---------------------------------------------
            -- HEADING
            -- ---------------------------------------------

            local heading =
                nav.getHeadingRad()


            -- ---------------------------------------------
            -- WORLD -> LOCAL
            -- ---------------------------------------------

            local forward =
                -worldX * math.cos(heading) +
                 worldZ * math.sin(heading)


            local rightDirection =
                worldX * math.sin(heading) +
                worldZ * math.cos(heading)


            -- ---------------------------------------------
            -- SIŁA
            -- ---------------------------------------------

            local horizontalPower =
                MIN_HORIZONTAL_POWER +
                horizontalDistance *
                POSITION_GAIN


            horizontalPower =
                clamp(
                    horizontalPower,
                    MIN_HORIZONTAL_POWER,
                    MAX_HORIZONTAL_SPEED
                )


            -- ---------------------------------------------
            -- WEKTOR RUCHU
            -- ---------------------------------------------

            local targetX =
                rightDirection

            local targetZ =
                forward


            -- ---------------------------------------------
            -- NORMALIZACJA
            -- ---------------------------------------------

            local length =
                math.sqrt(
                    targetX * targetX +
                    targetZ * targetZ
                )


            if length > 0 then

                targetX =
                    targetX / length

                targetZ =
                    targetZ / length

            end


            -- ---------------------------------------------
            -- GYROSCOPIC BEARINGS
            -- ---------------------------------------------

            front.setManualTarget({
                x = targetX,
                y = 0,
                z = targetZ
            })

            back.setManualTarget({
                x = targetX,
                y = 0,
                z = targetZ
            })

            left.setManualTarget({
                x = targetX,
                y = 0,
                z = targetZ
            })

            right.setManualTarget({
                x = targetX,
                y = 0,
                z = targetZ
            })


            -- ---------------------------------------------
            -- RSC
            -- ---------------------------------------------

            frontRSC.setTargetSpeed(horizontalPower)
            backRSC.setTargetSpeed(horizontalPower)
            leftRSC.setTargetSpeed(horizontalPower)
            rightRSC.setTargetSpeed(horizontalPower)

        else

            stopHorizontal()

        end


        -- =================================================
        -- PION
        -- =================================================

        if verticalDistance > TARGET_HEIGHT then

            local verticalPower =
                MIN_VERTICAL_POWER +
                verticalDistance *
                VERTICAL_GAIN


            verticalPower =
                clamp(
                    verticalPower,
                    MIN_VERTICAL_POWER,
                    MAX_VERTICAL_POWER
                )


            if vy > 0 then

                vertical.setTargetSpeed(
                    verticalPower
                )

            else

                vertical.setTargetSpeed(
                    -verticalPower
                )

            end

        else

            stopVertical()

        end


        -- =================================================
        -- DEBUG
        -- =================================================

        term.clear()
        term.setCursorPos(1, 1)

        print("=== GPS DRONE 3D ===")
        print()

        print(string.format(
            "POS: %.2f %.2f %.2f",
            droneX,
            droneY,
            droneZ
        ))

        print(string.format(
            "TARGET: %.2f %.2f %.2f",
            TARGET_X,
            TARGET_Y,
            TARGET_Z
        ))

        print()

        print(string.format(
            "DISTANCE: %.2f",
            horizontalDistance
        ))

        print(string.format(
            "DESIRED Y: %.2f",
            desiredY
        ))

        print(string.format(
            "Y ERROR: %.2f",
            vy
        ))

        print()

        print(string.format(
            "HEADING: %.2f",
            math.deg(nav.getHeadingRad())
        ))

        print()

        sleep(0.1)

    end

end
