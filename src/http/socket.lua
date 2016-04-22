return function (connection, req, args)
   dofile("httpserver-header.lc")(connection, 200, 'html')
   connection:send([===[
   <!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Set socket state</title></head><body><div align="center"><h1>Set socket state</h1>
   <p align="center"><button onclick="window.location.href='/index.html'">MENU</button></p>
   <p align="center"><button onclick="window.location = window.location.pathname">RELOAD</button></p>
   <table border=\"1\" style=\"margin: 0px auto;\"><tr>
   ]===])

   tmr.stop(0)
   if args.submit ~= nil or true then
      for name, value in pairs(args) do
	 -- Code to invoke goes here
	 if tostring(name) == "state" then
	    local state = gpio.LOW
            if tostring(value) == "ON" then
               state = gpio.HIGH
            end
            gpio.write(4, state)
            isChangeInProgress = true
	    tmr.alarm(1, 300, 0, function()
	       isChangeInProgress = false	
            end)
	 elseif tostring(name) == 'wait' and tostring(value) ~= '' and tonumber(value) > 0 then
	    print(tonumber(value))
            tmr.alarm(0, 1000 * tonumber(value), 0, function()
		if(gpio.read(4) == gpio.HIGH) then
			gpio.write(4, gpio.LOW);
		else
			gpio.write(4, gpio.HIGH);
		end
	    end)
	 end
      end
   end

   local state = "OFF"
   local change = "ON"
   local color = "green"
   if(gpio.read(4) == gpio.HIGH) then
      state = "ON"
      change = "OFF"
      color = "red"
   end
   connection:send("<td align=\"center\" valign=\"middle\" style=\"color: "..color.."\">"..state.."</td>")
   -- TODO: This code does not actually submit form
   connection:send("<td align=\"center\" valign=\"middle\"> <form method=\"GET\" id=\"form1\"> <input type=\"number\" name=\"wait\" />")
   connection:send("<button type=\"submit\" name=\"state\" form=\"form1\" value=\""..change.."\">"..change.."</button>")
   connection:send("<tr/></table></div></body></html>")
end

