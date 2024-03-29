----------------------------------------------------------------------
-- File: myweather.lua                                              --
--                                                                  --
-- Custom Awesome widget that loads weather from the daily news-    --
-- peper Sydsvenskan.                                               --
--                                                                  --
-- Created by Joachim Pileborg <arrow@pileborg.org>.                --
-- This file is in the public domain.                               --
----------------------------------------------------------------------

-- Creates a set of widgets that can be added to a wibox.
-- The widgets are a small icon that describes the weather, a text
-- with the temperature, an icon with the wind direction and a text
-- with the wind speed.
-- If the user hovers over the widgets with the mouse, a popup
-- is shown containing a description of the weather

-- TODO: Get weather forecast directly from yr.no instead?
--       Need to be able to handle XML properly then

local capi = {
    widget  = require('widget'),
    image   = require("image"),
    timer   = require("timer")
}
local awful   = require("awful")
local naughty = require("naughty")

local io      = require("io")
local string  = require("string")

module("myweather")

-- remove leading whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(8programming)
function ltrim(s)
    return (s:gsub("^%s*", ""))
end

-- remove trailing whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(8programming)
function rtrim(s)
    local n = #s
    while n > 0 and s:find("^%s", n) do n = n - 1 end
    return s:sub(1, n)
end

local base_url = "http://nyasydsvenskan.vackertvader.se/"

-- Function to fetch the actual weather page
local function get_weather_page(city)
    -- Get URL-encoded 
    function url_encode(str)
        if (str) then
            str = string.gsub (str, "\n", "\r\n")
            str = string.gsub (str, "([^%w ])",
                               function (c) return string.format ("%%%02X", string.byte(c)) end)
            str = string.gsub (str, " ", "+")
        end
        return str	
    end

    return awful.util.pread("curl -fs "..base_url..city.."#")

    -- local io = io
    -- local f = io.popen("curl -fs "..base_url..city.."#", "r")
    -- local s = f:read("*all")
    -- f:close()

    -- return s
end

local function get_weather(data)
    -- data[1] is the city name
    -- data[2] are the widgets

    local page = get_weather_page(data[1])
    if page == nil or #page == 0 then
        -- print("No weather page found")
        return
    end

    local _, forecast_day_placeholder_end = page:find('<div class="forecast_day_placeholder">')

    local _, _, weather_time = page:find('<span class="forecast_day">(.....)</span>', forecast_day_placeholder_end)

    local _, forecast_day_symbol_end = page:find('<div class="forecast_day_symbol">', forecast_day_placeholder_end)

    local _, weather_icon_start = page:find('src="', forecast_day_symbol_end)
    weather_icon_start = weather_icon_start + 1
    local weather_icon_end = page:find('"', weather_icon_start)
    weather_icon_end = weather_icon_end - 1
    local weather_icon = page:sub(weather_icon_start, weather_icon_end)

    local _, weather_title_start = page:find('title="', weather_icon_end)
    weather_title_start = weather_title_start + 1
    local weather_title_end = page:find('"', weather_title_start)
    weather_title_end = weather_title_end - 1
    local weather_title = page:sub(weather_title_start, weather_title_end)


    local _, weather_temp_start = page:find('<div class="forecast_max_temp">', weather_title_end)
    weather_temp_start = weather_temp_start + 1
    local weather_temp_end = page:find('</div>', weather_temp_start)
    weather_temp_end = weather_temp_end - 1
    local weather_temp = ltrim(rtrim(page:sub(weather_temp_start, weather_temp_end)))

    local _, weather_wind_speed_start = page:find('<div class="forecast_max_wind">', weather_temp_end)
    weather_wind_speed_start = weather_wind_speed_start + 1
    local weather_wind_speed_end = page:find('<img', weather_wind_speed_start)
    weather_wind_speed_end = weather_wind_speed_end - 1
    local weather_wind_speed = ltrim(rtrim(page:sub(weather_wind_speed_start, weather_wind_speed_end)))
    -- TODO: Remove the "m/s"?

    local _, weather_wind_dir_icon_start = page:find('<img alt="vindpil" src="', weather_wind_speed_end)
    weather_wind_dir_icon_start = weather_wind_dir_icon_start + 1
    local weather_wind_dir_icon_end = page:find('"', weather_wind_dir_icon_start)
    weather_wind_dir_icon_end = weather_wind_dir_icon_end - 1
    local weather_wind_dir_icon = page:sub(weather_wind_dir_icon_start, weather_wind_dir_icon_end)

    local confdir = awful.util.getdir("config")

    -- local icons = {
    --     ["Växlande molnighet"] = "clouds",
    --     ["Molnigt"] = "overcast"
    -- }
    -- weather_icon = confdir.."/weather_icons/"..icons[weather_title]..".png"

    local weather_icon_name = weather_icon:match(".+/(.+[dn]w?.png)")
    if weather_icon_name ~= nil then
        weather_icon = confdir.."/myweather_icons/weather/"..weather_icon_name
    else
        weather_icon = nil
    end
    local wind_dir_icon_name = weather_wind_dir_icon:match(".+/(...\.png)")
    if wind_dir_icon_name ~= nil then
        weather_wind_dir_icon = confdir.."/myweather_icons/directions/"..wind_dir_icon_name
    else
        weather_wind_dir_icon = nil
    end

    -- TODO: Split the wind speed into value and unit
    --weather_wind_speed, weather_wind_unit = weather_wind_speed:match("(.+) (.+)")

    -- print("Weather at "..weather_time..":")
    -- print("    "..weather_title.." (icon "..weather_icon..")")
    -- print("    Temp: "..weather_temp)
    -- print("    Wind: "..weather_wind_speed.." (dir. icon "..weather_wind_dir_icon..")")

    if weather_icon ~= nil then
        data[2].weather.image   = capi.image(weather_icon)
    end
    data[2].temp.text       = '<span font="monospace">'..weather_temp..'</span>'
    data[2].wind_speed.text = '<span font="monospace">'..weather_wind_speed..'</span>'
    if weather_wind_dir_icon ~= nil then
        data[2].wind_dir.image  = capi.image(weather_wind_dir_icon)
    end
end

-- Function to create the custom widget
function create(city, update_time) 
    -- local weather = {
    --     city = city,

    --     -- The actual widgets are private
    --     __widgets = {
    --         weather_icon  = capi.widget({ type = "imagebox" }),
    --         tempertature  = capi.widget({ type = "textbox"  }),
    --         wind_speed    = capi.widget({ type = "textbox"  }),
    --         wind_dir_icon = capi.widget({ type = "imagebox" }),
    --         separator     = capi.widget({ type = "textbox", text = " " })
    --     },

    --     -- TODO: Actual weather data

    --     timer = capi.timer({ timeout = update_time })

    --     -- TODO: Add some metatable-fu so access to weather.widget returns the widgets
    --     --       in a form that can be used by a wibox. Maybe even make it so that
    --     --       access directly to the weather table return the wibox-able widgets?
    -- }

    local widgets = {
        weather    = capi.widget({ type = "imagebox" }),
        temp       = capi.widget({ type = "textbox"  }),
        wind_speed = capi.widget({ type = "textbox"  }),
        wind_dir   = capi.widget({ type = "imagebox" }),
    }

    function widgets:get_widgets()
        local separator = capi.widget({ type = "textbox",
                                        name = "weather-separator",
                                        --align = "right",
                                        text = '<span font="monospace"> </span>' })
        return {
            self.wind_speed,
            separator,
            self.wind_dir,
            separator,
            separator,
            self.temp,
            self.weather,

            layout = awful.widget.layout.horizontal.rightleft
        }
    end

    -- Get weather from sydsvenskan.se
    get_weather({ city, widgets })

    -- Setup timer
    weathertimer = capi.timer({ timeout = update_time or 900 })
    weathertimer:add_signal("timeout", function() get_weather({ city, widgets }) end)
    weathertimer:start()

    -- TODO: Setup popup

    return widgets
end
