-- =========================================================
-- GPS DRONE 3D
-- GPS -> VECTOR 3D -> HEADING -> PROPELLER POWER
-- =========================================================


-- =========================================================
-- CEL
-- =========================================================

local TARGET_X = -232
local TARGET_Y = 100
local TARGET_Z = -59


-- =========================================================
-- URZĄDZENIA
-- =========================================================

local nav = peripheral.wrap("navigation_table_0")

local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")
local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")

-- Górny propeller
local vertical =
    peripheral.wrap("Create_RotationSpeedController_0")


-- =========================================================
-- USTAWIENIA
-- =========================================================

-- -------------------------
-- RUCH POZIOMY
-- -------------------------

local MAX_HORIZONTAL_SPEED = 40

local POSITION_GAIN = 1.5

local MIN_HORIZONTAL_POWER = 5


-- -------------------------
-- RUCH PIONOWY
-- -------------------------

local MAX_VERTICAL_POWER = 30

local VERTICAL_GAIN = 2.0

local MIN_VERTICAL_POWER = 5


-- -------------------------
-- CEL
-- -------------------------

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
-- STOP CAŁEGO DRONA
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

sleep(2)


-- =========================================================
-- GŁÓWNA PĘTLA
-- =========================================================

while true do

    -- -----------------------------------------------------
    -- GPS
    -- -----------------------------------------------------

    local droneX, droneY, droneZ =
        gps.locate(1)


    -- -----------------------------------------------------
    -- GPS ERROR
    -- -----------------------------------------------------

    if not droneX then

        stop()

        term.clear()
        term.setCursorPos(1, 1)

        print("GPS ERROR")
        print()
        print("Nie mozna znalezc pozycji.")

        sleep(0.2)


    else

        -- =================================================
        -- WEKTOR DO CELU
        -- =================================================

        local vx =
            TARGET_X - droneX

        local vy =
            TARGET_Y - droneY

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
        -- RÓŻNICA WYSOKOŚCI
        -- =================================================

        local verticalDistance =
            math.abs(vy)


        -- =================================================
        -- SPRAWDZENIE CELU
        -- =================================================

        if horizontalDistance <= TARGET_RADIUS
            and verticalDistance <= TARGET_HEIGHT then

            stop()

            term.clear()
            term.setCursorPos(1, 1)

            print("=== TARGET REACHED ===")
            print()

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

            print(string.format(
                "Horizontal: %.2f",
                horizontalDistance
            ))

            print(string.format(
                "Vertical: %.2f",
                verticalDistance
            ))


        else

            -- =================================================
            -- RUCH POZIOMY
            -- =================================================

            if horizontalDistance > TARGET_RADIUS then

                -- ---------------------------------------------
                -- NORMALIZACJA WEKTORA X/Z
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
                --
                -- TESTOWANA WERSJA
                -- ---------------------------------------------

                local forward =
                    -worldX * math.cos(heading) +
                     worldZ * math.sin(heading)


                local rightDirection =
                    worldX * math.sin(heading) +
                    worldZ * math.cos(heading)


                -- ---------------------------------------------
                -- SIŁA POZIOMA
                -- ---------------------------------------------

                local horizontalPower =
                    MIN_HORIZONTAL_POWER +
                    horizontalDistance * POSITION_GAIN


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
                    forward * horizontalPower

                local rightPower =
                    rightDirection * horizontalPower


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
                -- OGRANICZENIE
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
                -- STEROWANIE
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
                    verticalDistance * VERTICAL_GAIN


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

                    -- CEL JEST WYŻEJ

                    setVerticalPower(
                        verticalPower
                    )

                else

                    -- CEL JEST NIŻEJ

                    setVerticalPower(
                        -verticalPower
                    )

                end


            else

                -- ---------------------------------------------
                -- WYSOKOŚĆ OSIĄGNIĘTA
                -- ---------------------------------------------

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
            -- POZYCJA
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
            -- CEL
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
            -- WEKTOR
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
            -- ODLEGŁOŚĆ
            -- -------------------------------------------------

            print("DISTANCE")

            print(string.format(
                "HORIZONTAL: %.2f",
                horizontalDistance
            ))

            print(string.format(
                "VERTICAL: %.2f",
                verticalDistance
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

            if horizontalDistance >
                TARGET_RADIUS then

                print("HORIZONTAL: MOVING")

            else

                print("HORIZONTAL: TARGET")

            end


            if verticalDistance >
                TARGET_HEIGHT then

                if vy > 0 then

                    print("VERTICAL: UP")

                else

                    print("VERTICAL: DOWN")

                end

            else

                print("VERTICAL: TARGET")

            end

        end


        sleep(0.1)

    end

end
