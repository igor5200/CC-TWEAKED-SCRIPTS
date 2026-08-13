local nav = peripheral.find("navigation_table")

if not nav then
    print("Nie znaleziono Navigation Table!")
    return
end

-- Quaternion -> Roll/Pitch/Yaw
local function quaternionToEuler(q)
    local x = q.x
    local y = q.y
    local z = q.z
    local w = q.w

    -- Roll
    local sinr = 2 * (w * x + y * z)
    local cosr = 1 - 2 * (x * x + y * y)
    local roll = math.atan2(sinr, cosr)

    -- Pitch
    local sinp = 2 * (w * y - z * x)

    local pitch

    if math.abs(sinp) >= 1 then
        pitch = math.pi / 2 * (sinp >= 0 and 1 or -1)
    else
        pitch = math.asin(sinp)
    end

    -- Yaw
    local siny = 2 * (w * z + x * y)
    local cosy = 1 - 2 * (y * y + z * z)
    local yaw = math.atan2(siny, cosy)

    return
        math.deg(roll),
        math.deg(pitch),
        math.deg(yaw)
end

while true do
    local q = nav.getOrientation()

    if q then
        local roll, pitch, yaw = quaternionToEuler(q)

        term.clear()
        term.setCursorPos(1, 1)

        print("=== DRONE ORIENTATION ===")
        print()
        print(string.format("Roll : %7.2f deg", roll))
        print(string.format("Pitch: %7.2f deg", pitch))
        print(string.format("Yaw  : %7.2f deg", yaw))
        print()
        print("Quaternion:")
        print(string.format("X: %.4f", q.x))
        print(string.format("Y: %.4f", q.y))
        print(string.format("Z: %.4f", q.z))
        print(string.format("W: %.4f", q.w))
    else
        print("Brak danych orientacji!")
    end

    sleep(0.1)
end
