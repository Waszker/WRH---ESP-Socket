return function (connection, req, args)
  dofile("httpserver-header.lc")(connection, 200, 'html')
  connection:send([===[
   <!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Set socket state</title></head><body><div align="center"><h1>Set socket state</h1>
   <p align="center"><button onclick="window.location.href='/index.html'">MENU</button></p>
   <p align="center"><button onclick="window.location = window.location.pathname">RELOAD</button></p>
   <table border=\"1\" style=\"margin: 0px auto;\"><tr>
   ]===])

  for name, value in pairs(args) do
    if tostring(name) == "state" then
      conf.relayTimer:unregister()
      local newState = tostring(value) == "ON" and gpio.HIGH or gpio.LOW
      if (newState == gpio.HIGH) ~= conf.isRelayOn then toggleRelayState() end
    elseif tostring(name) == 'wait' and tostring(value) ~= '' and tonumber(value) > 0 then
      conf.relayTimer:register(1000 * tonumber(value), tmr.ALARM_SINGLE, toggleRelayState)
      conf.relayTimer:start()
    end
  end

  local state = conf.isRelayOn and "ON" or "OFF"
  local change = conf.isRelayOn and "OFF" or "ON"
  local color = conf.isRelayOn and "red" or "green"

  connection:send("<td align=\"center\" valign=\"middle\" style=\"color: "..color.."\">"..state.."</td>")
  connection:send("<td align=\"center\" valign=\"middle\"> <form method=\"GET\" id=\"form1\"> <input type=\"number\" name=\"wait\" />")
  connection:send("<button type=\"submit\" name=\"state\" form=\"form1\" value=\""..change.."\">"..change.."</button>")
  connection:send("</form></td><tr/></table></div></body></html>")
end

