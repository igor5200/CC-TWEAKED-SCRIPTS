-- ============================================================
-- DRONE V2
--
-- Uzycie:
--   drone <X> <Y> <Z>
--
-- Przyklad:
--   drone 100 70 -250
--
-- GPS:
--   pozycja drona
--
-- Navigation Table:
--   heading
--
-- Gimbal Sensor:
--   pitch / roll
--   pitch rate / roll rate
--
-- Rotation Speed Controllers:
--   front
--   back
--   left
--   right
-- ============================================================


-- ============================================================
-- ARGUMENTS
-- ============================================================

local targetX = tonumber(arg[1])
local targetY = tonumber(arg[2])
local targetZ = tonumber(arg[3])

if not targetX or not targetY or not targetZ then
    print("Uzycie:")
    print("drone <X> <Y> <Z>")
    print()
    print("Przyklad:")
    print("drone 100 70 -250")
    return
end


-- ============================================================
-- PERIPHERALS
-- ============================================================

local nav = peripheral.wrap("navigation_table_0")
local gimbal = peripheral.wrap("gimbal_sensor_0")

local front = peripheral.wrap("front")
local back  = peripheral.wrap("back")
local left  = peripheral.wrap("left")
local right = peripheral.wrap("right")


if not nav then
    error("Nie znaleziono navigation_table_0")
end

if not gimbal then
    error("Nie znaleziono gimbal_sensor_0")
end

if not front then
    error("Nie znaleziono controllera: front")
end

if not back then
    error("Nie znaleziono controllera: back")
end

if not left then
    error("Nie znaleziono controllera: left")
end

if not right then
    error("Nie znaleziono controllera: right")
end


-- ============================================================
-- SETTINGS
-- ============================================================

-- RPM przy którym dron powinien mniej wiecej wisiec.
--
-- DOBIERZ TO DOSWIADCZALNIE.
local HOVER_RPM = 180


-- Maksymalny kat przechylenia.
--
-- Na poczatek bardzo maly.
local MAX_TILT = math.rad(8)


-- Po ilu blokach chcemy wykorzystac pelny przechyl.
local DISTANCE_FOR_MAX_TILT = 20


-- Jak duza korekta RPM moze wykonac PD.
local MAX_CORRECTION = 30


-- Maksymalne RPM kontrolera.
local MAX_RPM = 256


-- ============================================================
-- PITCH PD
-- ============================================================

local KP_PITCH = 300
local KD_PITCH = 70


-- ============================================================
-- ROLL PD
-- ============================================================

local KP_ROLL = 300
local KD_ROLL = 70


-- ============================================================
-- SIGNS
-- ============================================================
--
-- Jezeli dron reaguje odwrotnie:
--
-- PITCH:
--   1  = normalnie
--  -1  = odwrotnie
--
-- ROLL:
--   1  = normalnie
--  -1  = odwrotnie
--

local PITCH_SIGN = 1
local ROLL_SIGN = 1


-- ============================================================
-- GPS
-- ============================================================

local function getPosition()

    local x, y, z = gps.locate(2)

    if not x then
        return nil
    end

    return x, y, z
end


-- ============================================================
-- MATH
-- ============================================================

local function clamp(value, minValue, maxValue)

    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end


-- Normalizuje kat do:
-- -PI ... +PI
local function normalizeAngle(angle)

    while angle > math.pi do
        angle = angle - 2 * math.pi
    end

    while angle < -math.pi do
        angle = angle + 2 * math.pi
    end

    return angle
end


local function setRPM(controller, rpm)

    rpm = clamp(
        rpm,
        -MAX_RPM,
        MAX_RPM
    )

    controller.setTargetSpeed(rpm)
end


-- ============================================================
-- START
-- ============================================================

print("================================")
print("         DRONE V2")
print("================================")
print()

print(
    string.format(
        "Target: %.1f %.1f %.1f",
        targetX,
        targetY,
        targetZ
    )
)

print()
print("Starting hover...")

setRPM(front, HOVER_RPM)
setRPM(back, HOVER_RPM)
setRPM(left, HOVER_RPM)
setRPM(right, HOVER_RPM)

sleep(2)


-- ============================================================
-- MAIN LOOP
-- ============================================================

while true do

    -- ========================================================
    -- GPS
    -- ========================================================

    local x, y, z = getPosition()

    if not x then

        term.clear()
        term.setCursorPos(1, 1)

        print("GPS ERROR")
        print()
        print("Nie mozna znalezc GPS.")

        -- Nie gasimy silnikow od razu.
        sleep(0.5)

    else

        -- ====================================================
        -- VECTOR TO TARGET
        -- ====================================================

        local dx = targetX - x
        local dy = targetY - y
        local dz = targetZ - z

        local horizontalDistance =
            math.sqrt(
                dx * dx +
                dz * dz
            )

        local distance =
            math.sqrt(
                dx * dx +
                dy * dy +
                dz * dz
            )


        -- ====================================================
        -- CHECK TARGET
        -- ====================================================

        local TARGET_REACHED = 2

        if distance < TARGET_REACHED then

            -- Cel osiagniety.
            --
            -- Utrzymujemy hover.

            setRPM(front, HOVER_RPM)
            setRPM(back, HOVER_RPM)
            setRPM(left, HOVER_RPM)
            setRPM(right, HOVER_RPM)

            term.clear()
            term.setCursorPos(1, 1)

            print("================================")
            print("       TARGET REACHED")
            print("================================")
            print()

            print(
                string.format(
                    "Position: %.1f %.1f %.1f",
                    x,
                    y,
                    z
                )
            )

            print()

            print(
                string.format(
                    "Distance: %.2f",
                    distance
                )
            )

            sleep(0.1)

        else

            -- =================================================
            -- WORLD TARGET ANGLE
            -- =================================================
            --
            -- dx / dz określają kierunek celu na płaszczyźnie.
            --
            -- atan2(dx, dz):
            --
            -- 0       -> +Z
            -- +90°    -> +X
            -- -90°    -> -X
            --

            local targetWorldAngle =
                math.atan(dx, dz)


            -- =================================================
            -- DRONE HEADING
            -- =================================================

            local heading =
                nav.getHeadingRad()


            -- =================================================
            -- TARGET RELATIVE TO DRONE
            -- =================================================

            local bearing =
                normalizeAngle(
                    targetWorldAngle - heading
                )


            -- =================================================
            -- DISTANCE -> TILT
            -- =================================================

            local distanceFactor =
                clamp(
                    horizontalDistance /
                    DISTANCE_FOR_MAX_TILT,
                    0,
                    1
                )


            local requestedTilt =
                MAX_TILT *
                distanceFactor


            -- =================================================
            -- TARGET PITCH / ROLL
            -- =================================================
            --
            -- bearing:
            --
            -- 0°       = przod
            -- +90°     = prawo
            -- -90°     = lewo
            -- 180°     = tyl
            --
            -- cos -> przod/tyl
            -- sin -> lewo/prawo
            --

            local targetPitch =
                math.cos(bearing) *
                requestedTilt *
                PITCH_SIGN


            local targetRoll =
                math.sin(bearing) *
                requestedTilt *
                ROLL_SIGN


            -- =================================================
            -- VERTICAL CONTROL
            -- =================================================
            --
            -- Na razie NIE sterujemy Y.
            --
            -- Dron utrzymuje wysokosc przez HOVER_RPM.
            --
            -- To celowe:
            -- najpierw stabilizujemy lot poziomy.
            --

            -- =================================================
            -- GIMBAL
            -- =================================================

            local angles =
                gimbal.getAnglesRad()

            local rates =
                gimbal.getAngularRatesRad()


            -- Dokumentacja:
            --
            -- angles = { pitch, roll }
            --
            -- rates = { wx, wy, wz }
            --

            local pitch =
                angles[1]

            local roll =
                angles[2]


            local pitchRate =
                rates[1]

            local rollRate =
                rates[3]


            -- =================================================
            -- PITCH PD
            -- =================================================

            local pitchError =
                targetPitch - pitch


            local pitchCorrection =
                KP_PITCH * pitchError
                -
                KD_PITCH * pitchRate


            pitchCorrection =
                clamp(
                    pitchCorrection,
                    -MAX_CORRECTION,
                    MAX_CORRECTION
                )


            -- =================================================
            -- ROLL PD
            -- =================================================

            local rollError =
                targetRoll - roll


            local rollCorrection =
                KP_ROLL * rollError
                -
                KD_ROLL * rollRate


            rollCorrection =
                clamp(
                    rollCorrection,
                    -MAX_CORRECTION,
                    MAX_CORRECTION
                )


            -- =================================================
            -- MOTOR MIXER
            -- =================================================
            --
            -- Pitch:
            --
            -- FRONT -
            -- BACK  +
            --
            -- Roll:
            --
            -- LEFT  +
            -- RIGHT -
            --

            local frontRPM =
                HOVER_RPM -
                pitchCorrection


            local backRPM =
                HOVER_RPM +
                pitchCorrection


            local leftRPM =
                HOVER_RPM +
                rollCorrection


            local rightRPM =
                HOVER_RPM -
                rollCorrection


            -- =================================================
            -- LIMIT RPM
            -- =================================================

            frontRPM =
                clamp(
                    frontRPM,
                    0,
                    MAX_RPM
                )

            backRPM =
                clamp(
                    backRPM,
                    0,
                    MAX_RPM
                )

            leftRPM =
                clamp(
                    leftRPM,
                    0,
                    MAX_RPM
                )

            rightRPM =
                clamp(
                    rightRPM,
                    0,
                    MAX_RPM
                )


            -- =================================================
            -- APPLY RPM
            -- =================================================

            setRPM(front, frontRPM)
            setRPM(back, backRPM)
            setRPM(left, leftRPM)
            setRPM(right, rightRPM)


            -- =================================================
            -- DISPLAY
            -- =================================================

            term.clear()
            term.setCursorPos(1, 1)

            print("================================")
            print("            DRONE V2")
            print("================================")
            print()

            print(
                string.format(
                    "POS: %.1f %.1f %.1f",
                    x,
                    y,
                    z
                )
            )

            print(
                string.format(
                    "TARGET: %.1f %.1f %.1f",
                    targetX,
                    targetY,
                    targetZ
                )
            )

            print()

            print(
                string.format(
                    "Distance: %.2f",
                    distance
                )
            )

            print(
                string.format(
                    "Bearing: %.1f deg",
                    math.deg(bearing)
                )
            )

            print()

            print(
                string.format(
                    "Pitch: %.2f deg",
                    math.deg(pitch)
                )
            )

            print(
                string.format(
                    "Target: %.2f deg",
                    math.deg(targetPitch)
                )
            )

            print()

            print(
                string.format(
                    "Roll: %.2f deg",
                    math.deg(roll)
                )
            )

            print(
                string.format(
                    "Target: %.2f deg",
                    math.deg(targetRoll)
                )
            )

            print()

            print(
                string.format(
                    "Pitch PD: %.2f",
                    pitchCorrection
                )
            )

            print(
                string.format(
                    "Roll PD: %.2f",
                    rollCorrection
                )
            )

            print()

            print(
                string.format(
                    "FRONT: %d",
                    math.floor(frontRPM)
                )
            )

            print(
                string.format(
                    "BACK:  %d",
                    math.floor(backRPM)
                )
            )

            print(
                string.format(
                    "LEFT:  %d",
                    math.floor(leftRPM)
                )
            )

            print(
                string.format(
                    "RIGHT: %d",
                    math.floor(rightRPM)
                )
            )

            sleep(0.05)
        end
    end
end
