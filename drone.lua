-- =========================================================
-- HORIZONTAL GPS DRONE
-- GPS -> DIRECTION -> PROPELLER POWER
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
local MAX_SPEED = 30

-- Jak szybko zwiększamy siłę wraz z odległością
local POSITION_GAIN = 1.0

-- W tej odległości zatrzymujemy się
local TARGET_RADIUS = 2


-- =========================================================
-- FUNKCJE
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


local function stop()

    left.setTargetSpeed(0)
    right.setTargetSpeed(0)
    front.setTargetSpeed(0)
    back.setTargetSpeed(0)

end


local function setPropellers(
    leftPower,
    rightPower,
    frontPower,
    backPower
)

    left.setTargetSpeed(leftPower)
    right.setTargetSpeed(rightPower)
    front.setTargetSpeed(frontPower)
    back.setTargetSpeed(backPower)

end


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

        sleep(0.2)

    else

        -- -------------------------------------------------
        -- WEKTOR DO CELU W ŚWIECIE
        -- -------------------------------------------------

        local vx = TARGET_X - droneX
        local vz = TARGET_Z - droneZ


        -- -------------------------------------------------
        -- ODLEGŁOŚĆ
        -- -------------------------------------------------

        local distance =
            math.sqrt(vx * vx + vz * vz)


        -- -------------------------------------------------
        -- CEL OSIĄGNIĘTY
        -- -------------------------------------------------

        if distance <= TARGET_RADIUS then

            stop()

            term.clear()
            term.setCursorPos(1, 1)

            print("TARGET REACHED")
            print()
            print("Distance:", distance)

        else

            -- =============================================
            -- NORMALIZACJA WEKTORA ŚWIATA
            -- =============================================

            local worldX = vx / distance
            local worldZ = vz / distance


            -- =============================================
            -- HEADING DRONA
            -- =============================================

            local heading =
                nav.getHeadingRad()


            -- =============================================
            -- WORLD -> DRONE
            -- =============================================

            local forward =
                worldX * math.sin(heading) +
                worldZ * math.cos(heading)

            local rightDirection =
                worldX * math.cos(heading) -
                worldZ * math.sin(heading)


            -- =============================================
            -- SIŁA ZALEŻNA OD ODLEGŁOŚCI
            -- =============================================

            local power =
                clamp(
                    distance * POSITION_GAIN,
                    0,
                    MAX_SPEED
                )


            -- =============================================
            -- SIŁA W OSI FORWARD / RIGHT
            -- =============================================

            local forwardPower =
                forward * power

            local rightPower =
                rightDirection * power


            -- =============================================
            -- FRONT / BACK
            -- =============================================

            local frontPower = 0
            local backPower = 0

            if forwardPower > 0 then

                frontPower = forwardPower

            else

                backPower = -forwardPower

            end


            -- =============================================
            -- LEFT / RIGHT
            -- =============================================

            local leftPower = 0
            local rightPower = 0

            if rightPower > 0 then

                rightPower = rightPower

            else

                leftPower = -rightPower

            end


            -- =============================================
            -- OGRANICZENIE
            -- =============================================

            frontPower =
                clamp(frontPower, 0, MAX_SPEED)

            backPower =
                clamp(backPower, 0, MAX_SPEED)

            leftPower =
                clamp(leftPower, 0, MAX_SPEED)

            rightPower =
                clamp(rightPower, 0, MAX_SPEED)


            -- =============================================
            -- PROPELLERY
            -- =============================================

            setPropellers(
                leftPower,
                rightPower,
                frontPower,
                backPower
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
            print("X:", TARGET_X)
            print("Z:", TARGET_Z)

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
                "%.1f deg",
                math.deg(heading)
            ))

            print()

            print("DIRECTION")
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
                "FRONT: %.1f",
                frontPower
            ))

            print(string.format(
                "BACK: %.1f",
                backPower
            ))

            print(string.format(
                "LEFT: %.1f",
                leftPower
            ))

            print(string.format(
                "RIGHT: %.1f",
                rightPower
            ))

        end

        sleep(0.1)

    end

end
