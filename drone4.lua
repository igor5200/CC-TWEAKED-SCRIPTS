-- =========================================================
-- GPS DRONE 3D
-- GPS -> VECTOR -> HEADING -> PROPELLERS
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

-- Wysokość przelotowa podczas lotu do celu
local CRUISE_HEIGHT = 100

-- Od tej odległości rozpoczynamy opadanie
local DESCENT_DISTANCE = 50


-- =========================================================
-- URZĄDZENIA
-- =========================================================

local nav = peripheral.wrap("navigation_table_0")

local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")
local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")

local vertical =
    peripheral.wrap("Create_RotationSpeedController_0")


-- =========================================================
-- USTAWIENIA RUCHU POZIOMEGO
-- =========================================================

local MAX_HORIZONTAL_SPEED = 40

local POSITION_GAIN = 1.5

local MIN_HORIZONTAL_POWER = 5


-- =========================================================
-- USTAWIENIA RUCHU PIONOWEGO
-- =========================================================

local MAX_VERTICAL_POWER = 30

local VERTICAL_GAIN = 2.0

local MIN_VERTICAL_POWER = 5


-- =========================================================
-- TOLERANCJA CELU
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

    left.setTargetSpeed(0)
    right.setTargetSpeed(0)
    front.setTargetSpeed(0)
    back.setTargetSpeed(0)

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
-- STEROWANIE PIONOWE
-- =========================================================

local function setVerticalPower(power)

    vertical.setTargetSpeed(power)

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

print()

print("CRUISE HEIGHT =", CRUISE_HEIGHT)
print("DESCENT DISTANCE =", DESCENT_DISTANCE)

sleep(2)


-- =========================================================
-- GŁÓWNA PĘTLA
-- =========================================================

while true do

    -- =====================================================
    -- GPS
    -- =====================================================

    local droneX, droneY, droneZ =
        gps.locate(1)


    if not droneX then

        stop()

        term.clear()
        term.setCursorPos(1, 1)

        print("GPS ERROR")

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
        -- ODLEGŁOŚĆ POZIOMA
        -- =================================================

        local horizontalDistance =
            math.sqrt(
                vx * vx +
                vz * vz
            )


        -- =================================================
        -- WYZNACZENIE ŻĄDANEJ WYSOKOŚCI
        -- =================================================

        local desiredY


        if horizontalDistance >= DESCENT_DISTANCE then

            -- ---------------------------------------------
            -- DALEKO OD CELU
            -- ---------------------------------------------
            --
            -- Lecimy na wysokości przelotowej.
            --

            desiredY =
                CRUISE_HEIGHT


        else

            -- ---------------------------------------------
            -- W STREFIE OPADANIA
            -- ---------------------------------------------

            local t =
                horizontalDistance /
                DESCENT_DISTANCE


            desiredY =
                TARGET_Y +
                (CRUISE_HEIGHT - TARGET_Y) * t

        end


        -- =================================================
        -- WEKTOR PIONOWY
        -- =================================================

        local vy =
            desiredY - droneY


        local verticalDistance =
            math.abs(vy)


        -- =================================================
        -- CZY JESTEŚMY NAD CELEM?
        -- =================================================

        if horizontalDistance <= TARGET_RADIUS
            and math.abs(TARGET_Y - droneY) <= TARGET_HEIGHT then

            stop()

            term.clear()
            term.setCursorPos(1, 1)

            print("=== TARGET REACHED ===")

            print()

            print(string.format(
                "POSITION X: %.2f",
                droneX
            ))

            print(string.format(
                "POSITION Y: %.2f",
                droneY
            ))

            print(string.format(
                "POSITION Z: %.2f",
                droneZ
            ))

            print()

            print("TARGET")

            print("X:", TARGET_X)
            print("Y:", TARGET_Y)
            print("Z:", TARGET_Z)

        else

            -- =================================================
            -- RUCH POZIOMY
            -- =================================================

            if horizontalDistance > TARGET_RADIUS then

                -- ---------------------------------------------
                -- NORMALIZACJA X/Z
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
                -- WORLD -> DRONE
                -- ---------------------------------------------
                --
                -- TESTOWANA TRANSFORMACJA
                --

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
                -- FORWARD / RIGHT
                -- ---------------------------------------------

                local forwardPower =
                    forward *
                    horizontalPower

                local rightPower =
                    rightDirection *
                    horizontalPower


                -- ---------------------------------------------
                -- FRONT / BACK
                -- ---------------------------------------------

                local frontSpeed = 0
                local backSpeed = 0


                if forwardPower > 0 then

                    frontSpeed =
                        forwardPower

                else

                    backSpeed =
                        -forwardPower

                end


                -- ---------------------------------------------
                -- LEFT / RIGHT
                --
                -- left  -> ruch PRAWO
                -- right -> ruch LEWO
                -- ---------------------------------------------

                local leftSpeed = 0
                local rightSpeed = 0


                if rightPower > 0 then

                    leftSpeed =
                        rightPower

                else

                    rightSpeed =
                        -rightPower

                end


                -- ---------------------------------------------
                -- CLAMP
                -- ---------------------------------------------

                frontSpeed =
                    clamp(
                        frontSpeed,
                        0,
                        MAX_HORIZONTAL_SPEED
                    )

                backSpeed =
                    clamp(
                        backSpeed,
                        0,
                        MAX_HORIZONTAL_SPEED
                    )

                leftSpeed =
                    clamp(
                        leftSpeed,
                        0,
                        MAX_HORIZONTAL_SPEED
                    )

                rightSpeed =
                    clamp(
                        rightSpeed,
                        0,
                        MAX_HORIZONTAL_SPEED
                    )


                -- ---------------------------------------------
                -- PROPELLERY
                -- ---------------------------------------------

                left.setTargetSpeed(
                    leftSpeed
                )

                right.setTargetSpeed(
                    rightSpeed
                )

                front.setTargetSpeed(
                    frontSpeed
                )

                back.setTargetSpeed(
                    backSpeed
                )


            else

                -- ---------------------------------------------
                -- JESTEŚMY NAD CELEM X/Z
                -- ---------------------------------------------

                stopHorizontal()

            end


            -- =================================================
            -- RUCH PIONOWY
            -- =================================================

            if verticalDistance > TARGET_HEIGHT then

                -- ---------------------------------------------
                -- SIŁA PIONOWA
                -- ---------------------------------------------

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


                -- ---------------------------------------------
                -- KIERUNEK
                -- ---------------------------------------------

                if vy > 0 then

                    -- CEL / ŻĄDANA WYSOKOŚĆ JEST WYŻEJ

                    setVerticalPower(
                        verticalPower
                    )

                else

                    -- CEL / ŻĄDANA WYSOKOŚĆ JEST NIŻEJ

                    setVerticalPower(
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


            -- -------------------------------------------------
            -- POSITION
            -- -------------------------------------------------

            print("POSITION")

            print(string.format(
                "X: %.2f",
                droneX
            ))

            print(string.format(
                "Y: %.2f",
                droneY
            ))

            print(string.format(
                "Z: %.2f",
                droneZ
            ))

            print()


            -- -------------------------------------------------
            -- TARGET
            -- -------------------------------------------------

            print("TARGET")

            print(string.format(
                "X: %.2f",
                TARGET_X
            ))

            print(string.format(
                "Y: %.2f",
                TARGET_Y
            ))

            print(string.format(
                "Z: %.2f",
                TARGET_Z
            ))

            print()


            -- -------------------------------------------------
            -- DISTANCE
            -- -------------------------------------------------

            print("HORIZONTAL DISTANCE")

            print(string.format(
                "%.2f",
                horizontalDistance
            ))

            print()


            -- -------------------------------------------------
            -- HEIGHT PROFILE
            -- -------------------------------------------------

            print("HEIGHT PROFILE")

            print(string.format(
                "DESIRED Y: %.2f",
                desiredY
            ))

            print(string.format(
                "CURRENT Y: %.2f",
                droneY
            ))

            print(string.format(
                "Y ERROR: %.2f",
                vy
            ))

            print()


            -- -------------------------------------------------
            -- VECTOR
            -- -------------------------------------------------

            print("VECTOR")

            print(string.format(
                "VX: %.2f",
                vx
            ))

            print(string.format(
                "VY: %.2f",
                vy
            ))

            print(string.format(
                "VZ: %.2f",
                vz
            ))

            print()


            -- -------------------------------------------------
            -- HEADING
            -- -------------------------------------------------

            local heading =
                nav.getHeadingRad()

            print("HEADING")

            print(string.format(
                "%.2f deg",
                math.deg(heading)
            ))

            print()


            -- -------------------------------------------------
            -- STATUS
            -- -------------------------------------------------

            if horizontalDistance >=
                DESCENT_DISTANCE then

                print("ALTITUDE: CRUISE")

            else

                print("ALTITUDE: DESCENDING")

            end


            if vy > TARGET_HEIGHT then

                print("VERTICAL: UP")

            elseif vy < -TARGET_HEIGHT then

                print("VERTICAL: DOWN")

            else

                print("VERTICAL: HOLD")

            end

        end


        sleep(0.1)

    end

end
