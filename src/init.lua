--Global variables
conf = {}
conf.led = ws2812.newBuffer(1, 3)
conf.isButtonPressed = false
conf.isRelayOn = false
conf.isLedToggledRegardingRelayState = false
conf.isWifiConnected = false
conf.buttonGpio = 3
conf.relayGpio = 1
conf.relayTimer = tmr.create()

--Global functions
function toggleRelayState()
  conf.relayTimer:unregister()
  conf.isRelayOn = not (gpio.read(conf.relayGpio) == gpio.HIGH)
  local newRelayState = conf.isRelayOn and gpio.HIGH or gpio.LOW
  gpio.write(conf.relayGpio, newRelayState)
  local ledColor = conf.isRelayOn and string.char(0, 255, 0) or string.char(0, 0, 0)
  conf.led:set(1, ledColor)
  ws2812.write(conf.led)
end

function buttonPressed()
  if conf.isButtonPressed == true then
    do return end
  end
  tmr.delay(300)
  if conf.isButtonPressed == true or gpio.read(conf.buttonGpio) == gpio.HIGH then
    do return end
  end
  conf.isButtonPressed = true
  toggleRelayState()
  print('Button pressed')
  tmr.create():alarm(300, tmr.ALARM_SINGLE, function() conf.isButtonPressed = false end)
end

function ledToggleFunction()
  conf.isLedToggledRegardingRelayState = not conf.isLedToggledRegardingRelayState
  if conf.isLedToggledRegardingRelayState and conf.isRelayOn then
    conf.led:set(1, 0, 255, 0) -- set green color if relay is on
  elseif conf.isLedToggledRegardingRelayState then
    conf.led:set(1, 0, 0, 0) -- turn off conf.led if relay is off
  elseif not conf.isLedToggledRegardingRelayState and not conf.isWifiConnected then
    conf.led:set(1, 0, 0, 255) -- turn conf.led to blue color to indicate that WiFi is not connected
  end
  ws2812.write(conf.led)
end

local connectWifi = function(timer)
  local ip = wifi.sta.getip()
  if ip ~= nil then
    print('Got ip address '..ip)
    wifi.setmode(wifi.STATION)
    ip = nil
    connectWifi = nil
    tmr.unregister(timer)
    collectgarbage()
    conf.isWifiConnected = true
  end
end

--Init system peripherals
ws2812.init()
conf.led:set(1, 0, 0, 0)
ws2812.write(conf.led)
tmr.create():alarm(1000, tmr.ALARM_AUTO, ledToggleFunction)
dofile('ap.lua')
tmr.create():alarm(5000, tmr.ALARM_AUTO, connectWifi)
gpio.mode(conf.relayGpio, gpio.OUTPUT)
gpio.write(conf.relayGpio, gpio.LOW)
gpio.mode(conf.buttonGpio, gpio.INT, gpio.PULLUP)
gpio.trig(conf.buttonGpio, "down", buttonPressed)

--Compile server code and remove original .lua files.
--This only happens the first time afer the .lua files are uploaded.
--Helper function
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
dofile("httpserver.lc")(80)
