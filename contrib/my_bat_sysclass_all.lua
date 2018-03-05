---------------------------------------------------
-- Licensed under the GNU General Public License v2
--  * (c) 2010, Adrian C. <anrxc@sysphere.org>
---------------------------------------------------

-- {{{ Grab environment
local tonumber = tonumber
local setmetatable = setmetatable
local string = { format = string.format }
local helpers = require("vicious.helpers")
local math = {
    min = math.min,
    floor = math.floor
}
-- }}}


-- Bat: provides state, charge, and remaining time for a requested battery
-- vicious.widgets.bat
local bat = {}


-- {{{ Battery widget type
local function worker(format, warg)
    if not warg then return end

    local battery = helpers.pathtotable("/sys/class/power_supply/"..warg)
    local battery_state = {
        ["Full\n"]        = "↯",
        ["Unknown\n"]     = "⌁",
        ["Charged\n"]     = "↯",
        ["Charging\n"]    = "+",
        ["Discharging\n"] = "-"
    }

    -- Check if the battery is present
    if battery.present ~= "1\n" then
        return {battery_state["Unknown\n"], 0, "N/A", 0}
    end


    -- Get state information
    local state = battery_state[battery.status] or battery_state["Unknown\n"]

    -- Get capacity information
    if battery.charge_now then
        remaining, capacity = tonumber(battery.charge_now)*10, tonumber(battery.charge_full)*10
    elseif battery.energy_now then
        remaining, capacity = tonumber(battery.energy_now), tonumber(battery.energy_full)
    else
        return {battery_state["Unknown\n"], 0, "N/A", 0}
    end
--[[ if macbook air then
-- HACK: linux battery driver reports `remaining capacity' in mAh, but 'state' says it's in mWh.
	remaining = ((remaining / 10000) * 7.5) * 1000
	capacity = ((capacity / 10000) * 7.5) * 1000
--]]


    -- Calculate percentage (but work around broken BAT/ACPI implementations)
    local percent = math.min(math.floor(remaining / capacity * 100), 100)


    -- Get charge information
    if battery.current_now then
        rate = tonumber(battery.current_now)/1000 * tonumber(battery.voltage_now)/1000
    elseif battery.power_now then
        rate = tonumber(battery.power_now)
    else
        return {state, percent, "N/A", 0}
    end
    watts = rate / 1000000

    -- Calculate remaining (charging or discharging) time
    local time = "N/A"
    if rate then
        if state == "+" then
            timeleft = (capacity - remaining) / rate
        elseif state == "-" then
            timeleft = remaining / rate
        else
            return {state, percent, time, watts}
        end
        local hoursleft = math.floor(timeleft)
        local minutesleft = math.floor((timeleft - hoursleft) * 60 )
        time = string.format("%02d:%02d", hoursleft, minutesleft)
    end

    return {state, percent, time, watts}
end
-- }}}

return setmetatable(bat, { __call = function(_, ...) return worker(...) end })
