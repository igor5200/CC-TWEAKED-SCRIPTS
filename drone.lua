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

local MAX_SPEED = 40

-- Siła na 1 blok odległości
local POSITION_GAIN = 1.5

-- Minimalna siła propellera
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
        -- WEKTOR DO CELU
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
            print(string.format(
                "Distance: %.2f",
                distance
            ))

        else

            -- =============================================
            -- NORMALIZACJA WEKTORA
            -- =============================================

            local worldX =
                vx / distance

            local worldZ =
                vz / distance


            -- =============================================
            -- HEADING
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
            -- FORWARD / RIGHT
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
            -- =============================================

            local leftSpeed = 0
            local rightSpeed = 0

            if rightPower > 0 then

                rightSpeed =
                    rightPower

            else

                leftSpeed =
                    -rightPower

            end


            -- =============================================
            -- OGRANICZENIE
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
            -- STEROWANIE
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
                "TOTAL: %.1f",
                power
            ))

            print()

            print("PROPELLERS")
            print(string.format(
                "FRONT: %.1f",
                frontSpeed
            ))

            print(string.format(
                "BACK: %.1f",
                backSpeed
            ))

            print(string.format(
                "LEFT: %.1f",
                leftSpeed
            ))

            print(string.format(
                "RIGHT: %.1f",
                rightSpeed
            ))

        end

        sleep(0.1)

    end

end
