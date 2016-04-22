-- Compile server code and remove original .lua files.
-- This only happens the first time afer the .lua files are uploaded.

-- Turn off relay as soon as possible
gpio.mode(4, gpio.OUTPUT)
gpio.mode(3, gpio.INT, gpio.PULLUP)

local pressed = function()
   tmr.delay(300)
   if(gpio.read(4) == gpio.HIGH) then
      gpio.write(4, gpio.LOW);
   else
      gpio.write(4, gpio.HIGH);
   end
   gpio.trig(3, "up", released)
end

local released = function()
   tmr.delay(20)
   gpio.trig(3, "up", pressed)
end

gpio.trig(3, "up", pressed)

-- Helper function
local compileAndRemoveIfNeeded = function(f)
   if file.open(f) then
      file.close()
      print('Compiling:', f)
      node.compile(f)
      file.remove(f)
      collectgarbage()
   end
end

local serverFiles = {
   'httpserver.lua',
   'httpserver-b64decode.lua',
   'httpserver-basicauth.lua',
   'httpserver-conf.lua',
   'httpserver-connection.lua',
   'httpserver-error.lua',
   'httpserver-header.lua',
   'httpserver-request.lua',
   'httpserver-static.lua',
}
for i, f in ipairs(serverFiles) do compileAndRemoveIfNeeded(f) end

compileAndRemoveIfNeeded = nil
serverFiles = nil
collectgarbage()

-- Begin WiFi configuration

local wifiConfig = {}

-- wifi.STATION         -- station: join a WiFi network
-- wifi.SOFTAP          -- access point: create a WiFi network
-- wifi.wifi.STATIONAP  -- both station and access point
-- wifiConfig.mode = wifi.STATION  -- in this project I'll go with pure station

wifiConfig.accessPointConfig = {}
wifiConfig.accessPointConfig.ssid = "ESP-"..node.chipid()   -- Name of the SSID you want to create
wifiConfig.accessPointConfig.pwd = "password"    -- WiFi password - at least 8 characters

wifiConfig.accessPointIpConfig = {}
wifiConfig.accessPointIpConfig.ip = "192.168.111.1"
wifiConfig.accessPointIpConfig.netmask = "255.255.255.0"
wifiConfig.accessPointIpConfig.gateway = "192.168.111.1"

wifiConfig.stationPointConfig = {}
wifiConfig.stationPointConfig.ssid = "WIFI"        -- Name of the WiFi network you want to join
wifiConfig.stationPointConfig.pwd =  "password"           -- Password for the WiFi network

-- Creating AP helper function
local createAP = function(wifiConfig)
   print('Creating own Access Point...')
   print('AP MAC: ',wifi.ap.getmac())
   wifi.setmode(wifi.SOFTAP)
   wifi.ap.config(wifiConfig.accessPointConfig)
   wifi.ap.setip(wifiConfig.accessPointIpConfig)
end

-- Tell the chip to connect to the access point

-- Open file with SSID and passwords, then try to find what network is in range
if file.open("ap_list.txt", "r") == nil then
   -- If there is no such file, create AP and wait for user interaction
   -- TODO: Determine if file.close() is neede here?
   print('No list of AP')
   createAP(wifiConfig)
   print('Freeing RAM')
   wifiConfig = nil
   collectgarbage()
   dofile("httpserver.lc")(80)
else
   wifi.setmode(wifi.STATION)    
   print('Client MAC: ',wifi.sta.getmac())
   ssid = file.readline()
   while ssid ~= nil
   do
      wifiConfig.stationPointConfig.ssid = string.gsub(ssid, '\n', '')
      wifiConfig.stationPointConfig.pwd = string.gsub(file.readline(), '\n', '')
      -- TODO: Check if ssid if present in ap list
      ssid = file.readline()
   end
   print('Connecting to '..wifiConfig.stationPointConfig.ssid..' with pwd '..wifiConfig.stationPointConfig.pwd)
   wifi.sta.config(wifiConfig.stationPointConfig.ssid, wifiConfig.stationPointConfig.pwd, 1)
   file.close()
end

print('chip: ',node.chipid())
print('heap: ',node.heap())

-- End WiFi configuration

-- Connect to the WiFi access point.
-- Once the device is connected, you may start the HTTP server.

if (wifi.getmode() == wifi.STATION) or (wifi.getmode() == wifi.STATIONAP) then
    local joinCounter = 0
    local joinMaxAttempts = 5
    tmr.alarm(0, 3000, 1, function()
       local ip = wifi.sta.getip()
       if ip == nil and joinCounter < joinMaxAttempts then
          print('Connecting to WiFi Access Point ...')
          joinCounter = joinCounter +1
       else
          if joinCounter == joinMaxAttempts then
             print('Failed to connect to WiFi Access Point.')
	     createAP(wifiConfig)
          else
             print('IP: ',ip)
          end
          tmr.stop(0)
          joinCounter = nil
          joinMaxAttempts = nil

	  print('Freeing RAM')
	  wifiConfig = nil
          collectgarbage()
	  dofile("httpserver.lc")(80)
       end
    end)
end
