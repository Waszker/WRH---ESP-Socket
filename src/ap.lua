local wifiConfig = {}

-- wifi.STATION         -- station: join a WiFi network
-- wifi.SOFTAP          -- access point: create a WiFi network
-- wifi.wifi.STATIONAP  -- both station and access point
-- wifiConfig.mode = wifi.STATION  -- in this project I'll go with pure station

wifiConfig.accessPointConfig = {}
wifiConfig.accessPointConfig.ssid = "ESP-"..node.chipid()   -- Name of the SSID you want to create
wifiConfig.accessPointConfig.pwd = "password"    -- WiFi password - at least 8 characters
wifiConfig.accessPointConfig.auth = wifi.WPA2_PSK
wifiConfig.accessPointConfig.save = false

wifiConfig.accessPointIpConfig = {}
wifiConfig.accessPointIpConfig.ip = "192.168.111.1"
wifiConfig.accessPointIpConfig.netmask = "255.255.255.0"
wifiConfig.accessPointIpConfig.gateway = "192.168.111.1"

wifi.setmode(wifi.SOFTAP)
wifi.setphymode(wifi.PHYMODE_B)
print('Creating own Access Point...')
print('mac: ',wifi.ap.getmac())
wifi.ap.config(wifiConfig.accessPointConfig)
wifi.ap.setip(wifiConfig.accessPointIpConfig)

if file.open("ap_list.txt", "r") ~= nil then
  --Trying to connect to saved access point
  wifi.setmode(wifi.STATIONAP)
  local ssid = string.gsub(file.readline(), '\n', '')
  local pwd = string.gsub(file.readline(), '\n', '')
  wifi.sta.config(ssid, pwd, 1)
  print('Connecting to '..ssid..' using password '..pwd)
  file.close()
end

wifiConfig = nil
collectgarbage()
