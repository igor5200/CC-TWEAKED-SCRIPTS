local TARGET_X = -232
local TARGET_Z = -59

local nav = peripheral.wrap("navigation_table_0")

while true do

    local droneX, _, droneZ = gps.locate(1)
    local heading = nav.getHeadingRad()

    if droneX then

        local vx = TARGET_X - droneX
        local vz = TARGET_Z - droneZ

        local distance = math.sqrt(vx * vx + vz * vz)

        if distance > 0 then

            local forward =
                vx * math.sin(heading) +
                vz * math.cos(heading)

            local right =
                vx * math.cos(heading) -
                vz * math.sin(heading)

            -- normalizacja lokalnego wektora
            local length =
                math.sqrt(forward * forward + right * right)

            forward = forward / length
            right = right / length

            term.clear()
            term.setCursorPos(1, 1)

            print("=== VECTOR TEST ===")
            print()

            print("DRONE")
            print(string.format("X: %.2f", droneX))
            print(string.format("Z: %.2f", droneZ))

            print()

            print("TARGET")
            print("X:", TARGET_X)
            print("Z:", TARGET_Z)

            print()

            print("WORLD VECTOR")
            print(string.format("VX: %.2f", vx))
            print(string.format("VZ: %.2f", vz))

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
                right
            ))

            print()

            if math.abs(forward) > math.abs(right) then

                if forward > 0 then
                    print("DIRECTION: FRONT")
                else
                    print("DIRECTION: BACK")
                end

            else

                if right > 0 then
                    print("DIRECTION: RIGHT")
                else
                    print("DIRECTION: LEFT")
                end

            end

        end

    else

        print("GPS ERROR")

    end

    sleep(0.2)
end
