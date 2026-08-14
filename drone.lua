-- =========================================================
-- HORIZONTAL GPS DRONE
-- GPS -> VECTOR -> HEADING -> PROPELLER POWER
-- =========================================================


-- =========================================================
-- CEL
-- =========================================================

local TARGET_X = -232
local TARGET_Z = -59


-- =========================================================
-- URZĄDZENIA
-- =========================================================

local nav = peripheral.wrap("navigation_table_0")

local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")
local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")


-- =========================================================
-- USTAWIENIA
-- =========================================================

-- Maksymalna prędkość RSC
local MAX_SPEED = 40

-- Siła na jeden blok odległości
local POSITION_GAIN = 1.5

-- Minimalna siła
local MIN_POWER = 5

-- Promień celu
local TARGET_RADIUS = 2


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
-- STOP
-- =========================================================

local function stop()

    left.setTargetSpeed(0)
    right.setTargetSpeed(0)
    front.setTargetSpeed(0)
    back.setTargetSpeed(0)

end


-- =========================================================
-- PROPELLERY
-- =========================================================

local function setPropellers(
    leftSpeed,
    rightSpeed,
    frontSpeed,
    backSpeed
)

    left.setTargetSpeed(leftSpeed)
    right.setTargetSpeed(rightSpeed)
    front.setTargetSpeed(frontSpeed)
    back.setTargetSpeed(backSpeed)

end


-- =========================================================
-- START
-- =========================================================

print("GPS DRONE")
print()
print("Target:")
print("X =", TARGET_X)
print("Z =", TARGET_Z)

sleep(2)


-- =========================================================
-- GŁÓWNA PĘTLA
-- =========================================================

while true do

    -- -----------------------------------------------------
    -- GPS
    -- -----------------------------------------------------

    local droneX, _, droneZ = gps.locate(1)


    if not droneX then

        stop()

        term.clear()
        term.setCursorPos(1, 1)

        print("GPS ERROR")
        print()
        print("Nie mozna znalezc pozycji.")

        sleep(0.2)

    else

        -- -------------------------------------------------
        -- WEKTOR DO CELU
        -- -------------------------------------------------

        local vx = TARGET_X - droneX
        local vz = TARGET_Z - droneZ


        -- -------------------------------------------------
        -- ODLEGŁOŚĆ
        -- -------------------------------------------------

        local distance =
            math.sqrt(
                vx * vx +
                vz * vz
            )


        -- -------------------------------------------------
        -- CEL OSIĄGNIĘTY
        -- -------------------------------------------------

        if distance <= TARGET_RADIUS then

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
                "Z: %.2f",
                droneZ
            ))

            print()

            print(string.format(
                "Distance: %.2f",
                distance
            ))

        else

            -- =============================================
            -- NORMALIZACJA WEKTORA ŚWIATA
            -- =============================================

            local worldX =
                vx / distance

            local worldZ =
                vz / distance


            -- =============================================
            -- HEADING DRONA
            -- =============================================

            local heading =
                nav.getHeadingRad()


            -- =============================================
            -- WORLD -> DRONE
            --
            -- POPRAWIONA TRANSFORMACJA
            -- =============================================

            local forward =
                -worldX * math.cos(heading) +
                 worldZ * math.sin(heading)


            local rightDirection =
                worldX * math.sin(heading) +
                worldZ * math.cos(heading)


            -- =============================================
            -- SIŁA
            -- =============================================

            local power =
                MIN_POWER +
                distance * POSITION_GAIN


            power =
                clamp(
                    power,
                    MIN_POWER,
                    MAX_SPEED
                )


            -- =============================================
            -- SIŁA FORWARD / RIGHT
            -- =============================================

            local forwardPower =
                forward * power

            local rightPower =
                rightDirection * power


            -- =============================================
            -- FRONT / BACK
            -- =============================================

            local frontSpeed = 0
            local backSpeed = 0


            if forwardPower > 0 then

                frontSpeed =
                    forwardPower

            else

                backSpeed =
                    -forwardPower

            end


            -- =============================================
            -- LEFT / RIGHT
            --
            -- WAŻNE:
            --
            -- left  propeller -> ruch PRAWO
            -- right propeller -> ruch LEWO
            -- =============================================

            local leftSpeed = 0
            local rightSpeed = 0


            if rightPower > 0 then

                -- Chcemy lecieć w PRAWO
                leftSpeed =
                    rightPower

            else

                -- Chcemy lecieć w LEWO
                rightSpeed =
                    -rightPower

            end


            -- =============================================
            -- OGRANICZENIE PRĘDKOŚCI
            -- =============================================

            frontSpeed =
                clamp(
                    frontSpeed,
                    0,
                    MAX_SPEED
                )

            backSpeed =
                clamp(
                    backSpeed,
                    0,
                    MAX_SPEED
                )

            leftSpeed =
                clamp(
                    leftSpeed,
                    0,
                    MAX_SPEED
                )

            rightSpeed =
                clamp(
                    rightSpeed,
                    0,
                    MAX_SPEED
                )


            -- =============================================
            -- STEROWANIE PROPELLERAMI
            -- =============================================

            setPropellers(
                leftSpeed,
                rightSpeed,
                frontSpeed,
                backSpeed
            )


            -- =============================================
            -- DEBUG
            -- =============================================

            term.clear()
            term.setCursorPos(1, 1)


            print("=== GPS DRONE ===")
            print()


            print("POSITION")

            print(string.format(
                "X: %.2f",
                droneX
            ))

            print(string.format(
                "Z: %.2f",
                droneZ
            ))


            print()


            print("TARGET")

            print(string.format(
                "X: %.2f",
                TARGET_X
            ))

            print(string.format(
                "Z: %.2f",
                TARGET_Z
            ))


            print()


            print("WORLD VECTOR")

            print(string.format(
                "VX: %.2f",
                vx
            ))

            print(string.format(
                "VZ: %.2f",
                vz
            ))


            print()


            print(string.format(
                "DISTANCE: %.2f",
                distance
            ))


            print()


            print("HEADING")

            print(string.format(
                "%.2f deg",
                math.deg(heading)
            ))


            print()


            print("LOCAL VECTOR")

            print(string.format(
                "FORWARD: %.3f",
                forward
            ))

            print(string.format(
                "RIGHT: %.3f",
                rightDirection
            ))


            print()


            print("POWER")

            print(string.format(
                "TOTAL: %.1f",
                power
            ))


            print()


            print("PROPELLERS")

            print(string.format(
                "FRONT: %.1f RPM",
                frontSpeed
            ))

            print(string.format(
                "BACK: %.1f RPM",
                backSpeed
            ))

            print(string.format(
                "LEFT: %.1f RPM",
                leftSpeed
            ))

            print(string.format(
                "RIGHT: %.1f RPM",
                rightSpeed
            ))

        end

        sleep(0.1)

    end

end
