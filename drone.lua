-- =========================================================
-- HORIZONTAL DRONE AUTOPILOT
-- GPS -> VECTOR -> HEADING -> FRONT/BACK/LEFT/RIGHT
-- =========================================================


-- =========================================================
-- CEL
-- =========================================================

local TARGET_X = 100
local TARGET_Z = 200


-- =========================================================
-- PERIPHERALS
-- =========================================================

local nav = peripheral.wrap("navigation_table_0")

local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")
local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")


-- =========================================================
-- USTAWIENIA
-- =========================================================

-- Maksymalna prędkość RSC.
-- RSC pozwala na -256 .. +256 RPM.
local MAX_SPEED = 100

-- Jak mocno reagujemy na odległość.
local POSITION_GAIN = 2

-- W tej odległości zatrzymujemy drona.
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
-- USTAWIENIE PROPELLERÓW
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

print("DRONE AUTOPILOT")
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

    local droneX, droneY, droneZ = gps.locate(1)


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
        -- WEKTOR ŚWIATOWY DO CELU
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
        -- HEADING DRONA
        -- -------------------------------------------------

        local heading =
            nav.getHeadingRad()


        -- -------------------------------------------------
        -- CEL OSIĄGNIĘTY
        -- -------------------------------------------------

        if distance <= TARGET_RADIUS then

            stop()

        else

            -- =============================================
            -- NORMALIZACJA WEKTORA ŚWIATOWEGO
            -- =============================================

            local worldX =
                vx / distance

            local worldZ =
                vz / distance


            -- =============================================
            -- WORLD -> DRONE
            --
            -- Navigation Table:
            --
            -- heading = 0
            --     dron patrzy w +Z
            --
            -- dodatni heading:
            --     +Z drona obraca się w stronę +X
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
            -- WYMAGANA SIŁA
            -- =============================================

            local forwardPower =
                forward * power

            local rightPower =
                rightDirection * power


            -- =============================================
            -- FORWARD / BACK
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

            print("=== DRONE AUTOPILOT ===")
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

            print("VECTOR WORLD")

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

            print(string.format(
                "HEADING: %.2f rad",
                heading
            ))

            print(string.format(
                "HEADING: %.1f deg",
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

            print("PROPELLERS")

            print(string.format(
                "LEFT:  %.1f RPM",
                leftSpeed
            ))

            print(string.format(
                "RIGHT: %.1f RPM",
                rightSpeed
            ))

            print(string.format(
                "FRONT: %.1f RPM",
                frontSpeed
            ))

            print(string.format(
                "BACK:  %.1f RPM",
                backSpeed
            ))

        end

        sleep(0.1)

    end

end
