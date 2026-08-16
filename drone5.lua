-- =========================================================
-- GPS DRONE 3D
-- GPS -> VECTOR -> HEADING -> 4 GYROSCOPIC PROPELLERS
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
-- URZĄDZENIA
-- =========================================================

local nav =
    peripheral.wrap("navigation_table_0")


-- =========================================================
-- GYROSCOPIC PROPELLER BEARINGS
-- =========================================================

local front =
    peripheral.wrap("gyroscopic_propeller_bearing_0")

local right =
    peripheral.wrap("gyroscopic_propeller_bearing_1")

local back =
    peripheral.wrap("gyroscopic_propeller_bearing_2")

local left =
    peripheral.wrap("gyroscopic_propeller_bearing_3")


-- =========================================================
-- ROTATION SPEED CONTROLLERS
-- =========================================================

local frontRSC =
    peripheral.wrap("front")

local rightRSC =
    peripheral.wrap("right")

local backRSC =
    peripheral.wrap("back")

local leftRSC =
    peripheral.wrap("left")


-- =========================================================
-- USTAWIENIA RUCHU
-- =========================================================

local MAX_SPEED = 40

local MIN_SPEED = 5

local POSITION_GAIN = 1.5


-- =========================================================
-- TOLERANCJA
-- =========================================================

local TARGET_RADIUS = 2

local TARGET_HEIGHT = 1


-- =========================================================
-- MAKSYMALNE WYCHYLENIE GYROSCOPIC PROPELLERA
-- =========================================================

local MAX_TILT = math.rad(12)


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

frontRSC.setTargetSpeed(0)
rightRSC.setTargetSpeed(0)
backRSC.setTargetSpeed(0)
leftRSC.setTargetSpeed(0)


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
    -- POZYCJA
    -- =====================================================

    local pose =
        sublevel.getLogicalPose()


    local droneX =
        pose.position.x

    local droneY =
        pose.position.y

    local droneZ =
        pose.position.z


    -- =====================================================
    -- WEKTOR DO CELU
    -- =====================================================

    local vx =
        TARGET_X - droneX

    local vz =
        TARGET_Z - droneZ


    local horizontalDistance =
        math.sqrt(
            vx * vx +
            vz * vz
        )


    -- =====================================================
    -- ŻĄDANA WYSOKOŚĆ
    -- =====================================================

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


    -- =====================================================
    -- BŁĄD WYSOKOŚCI
    -- =====================================================

    local vy =
        desiredY - droneY


    -- =====================================================
    -- CEL OSIĄGNIĘTY
    -- =====================================================

    if horizontalDistance <= TARGET_RADIUS
        and math.abs(TARGET_Y - droneY) <= TARGET_HEIGHT then

        frontRSC.setTargetSpeed(0)
        rightRSC.setTargetSpeed(0)
        backRSC.setTargetSpeed(0)
        leftRSC.setTargetSpeed(0)

        print("TARGET REACHED")

        break

    end


    -- =====================================================
    -- NORMALIZACJA WEKTORA X/Z
    -- =====================================================

    local worldX = 0
    local worldZ = 0


    if horizontalDistance > 0 then

        worldX =
            vx / horizontalDistance

        worldZ =
            vz / horizontalDistance

    end


    -- =====================================================
    -- HEADING
    -- =====================================================

    local heading =
        nav.getHeadingRad()


    -- =====================================================
    -- WORLD -> LOCAL
    -- =====================================================

    local forward =
        -worldX * math.cos(heading) +
         worldZ * math.sin(heading)


    local rightDirection =
        worldX * math.sin(heading) +
        worldZ * math.cos(heading)


    -- =====================================================
    -- SIŁA RUCHU
    -- =====================================================

    local distanceError =
        math.sqrt(
            horizontalDistance * horizontalDistance +
            vy * vy
        )


    local power =
        MIN_SPEED +
        distanceError * POSITION_GAIN


    power =
        clamp(
            power,
            MIN_SPEED,
            MAX_SPEED
        )


    -- =====================================================
    -- WEKTOR ŻĄDANEGO RUCHU W LOCAL SPACE
    -- =====================================================

    local desiredX =
        rightDirection

    local desiredY =
        vy / math.max(distanceError, 1)

    local desiredZ =
        forward


    -- =====================================================
    -- NORMALIZACJA
    -- =====================================================

    local desiredLength =
        math.sqrt(
            desiredX * desiredX +
            desiredY * desiredY +
            desiredZ * desiredZ
        )


    desiredX =
        desiredX / desiredLength

    desiredY =
        desiredY / desiredLength

    desiredZ =
        desiredZ / desiredLength


    -- =====================================================
    -- DEBUG
    -- =====================================================

    term.clear()
    term.setCursorPos(1, 1)

    print("=== GPS DRONE 3D ===")
    print()

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

    print("DISTANCE")

    print(string.format(
        "Horizontal: %.2f",
        horizontalDistance
    ))

    print(string.format(
        "Height error: %.2f",
        vy
    ))

    print()

    print("DESIRED VECTOR")

    print(string.format(
        "X: %.3f",
        desiredX
    ))

    print(string.format(
        "Y: %.3f",
        desiredY
    ))

    print(string.format(
        "Z: %.3f",
        desiredZ
    ))

    print()

    print("HEADING")

    print(string.format(
        "%.2f deg",
        math.deg(heading)
    ))

    print()

    print("POWER")

    print(string.format(
        "%.2f",
        power
    ))


    -- =====================================================
    -- GYROSCOPIC PROPELLERS
    -- =====================================================
    --
    -- Na tym etapie ustawiamy wszystkie RSC na tę samą
    -- moc. Kierunek ciągu jest sterowany przez bearing.
    --
    -- UWAGA:
    -- setManualTarget() musi otrzymać poprawny WORLD VECTOR.
    -- Dlatego używamy aktualnego normalnego każdego bearingu
    -- jako podstawy.
    -- =====================================================


    local frontNormal =
    front.getBlockNormal()

local rightNormal =
    right.getBlockNormal()

local backNormal =
    back.getBlockNormal()

local leftNormal =
    left.getBlockNormal()


print()

print("BEARING NORMALS")

print(string.format(
    "FRONT: %.2f %.2f %.2f",
    frontNormal[1],
    frontNormal[2],
    frontNormal[3]
))

print(string.format(
    "RIGHT: %.2f %.2f %.2f",
    rightNormal[1],
    rightNormal[2],
    rightNormal[3]
))

print(string.format(
    "BACK: %.2f %.2f %.2f",
    backNormal[1],
    backNormal[2],
    backNormal[3]
))

print(string.format(
    "LEFT: %.2f %.2f %.2f",
    leftNormal[1],
    leftNormal[2],
    leftNormal[3]
))


    -- =====================================================
    -- RSC
    -- =====================================================

    frontRSC.setTargetSpeed(power)
    rightRSC.setTargetSpeed(power)
    backRSC.setTargetSpeed(power)
    leftRSC.setTargetSpeed(power)


    sleep(0.1)

end
