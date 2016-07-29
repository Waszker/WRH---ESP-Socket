-- File changed by Piotr Waszkiewicz on 25.07.2016

-- Prepare global variables that will help to deal with tactile switch
-- 'bouncing problem'
isChangeInProgress = false

function buttonPressFunction()
   if isChangeInProgress == true then
	do return end
   end

   -- Generally tmr.delay() function should not be used but screw good practice :)
   tmr.delay(300)

   if isChangeInProgress == true or gpio.read(3) == gpio.HIGH then
      do return end
   end
   
   isChangeInProgress = true
   if(gpio.read(4) == gpio.HIGH) then
      gpio.write(4, gpio.LOW);
   else
      gpio.write(4, gpio.HIGH);
   end

   tmr.alarm(1, 300, 0, function()
	isChangeInProgress = false	
   end)
   -- Cancel working timer if user has made some input regarding socket state
   tmr.stop(0)
end

-- Turn off relay as soon as possible
-- and prepare other GPIOs' behaviours
gpio.mode(4, gpio.OUTPUT)
gpio.mode(3, gpio.INT, gpio.PULLUP)
gpio.trig(3, "down", buttonPressFunction)

-- Compile server code and remove original .lua files.
-- This only happens the first time afer the .lua files are uploaded.
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
   -- TODO: Determine if file.close() is needed here?
   print('No list of AP')
   createAP(wifiConfig)
   print('Freeing RAM')
   wifiConfig = nil
   collectgarbage()
   dofile("httpserver.lc")(80)
else
   -- Asume that file has two lines
   -- first one holds ssid value
   -- second one holds password
   wifi.setmode(wifi.STATION)    
   print('Client MAC: ',wifi.sta.getmac())
   wifiConfig.stationPointConfig.ssid = string.gsub(file.readline(), '\n', '')
   wifiConfig.stationPointConfig.pwd = string.gsub(file.readline(), '\n', '')
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
