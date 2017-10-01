return function (connection, req, args)
  dofile("httpserver-header.lc")(connection, 200, 'html')
  connection:send([===[
   <!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Configure socket wifi settings</title></head><body><div align="center"><h1>Configure socket wifi settings</h1>
   <p align="center"><button onclick="window.location.href='/index.html'">MENU</button></p>
   <p align="center"><button onclick="window.location.href='/reset.lua'">RESET</button></p>
   ]===])

  local wifi_ssid, wifi_pwd
  if args.submit ~= nil then
    for name, value in pairs(args) do
      -- Code to invoke goes here
      if tostring(name) == "ssid" then
        wifi_ssid = tostring(value)
      elseif tostring(name) == 'pwd' then
        wifi_pwd = tostring(value)
      end
    end

    -- Change AP settings
    if wifi_ssid ~= nil and wifi_pwd ~= nil then
      file.remove("ap_list.txt")
      file.open("ap_list.txt", "w")
      file.writeline(wifi_ssid)
      file.writeline(wifi_pwd)
      file.close()
      wifi_ssid = nil
      wifi_pwd = nil
    end
  end

  if file.open("ap_list.txt", "r") == nil then
    connection:send("<p>No Access Point configured!</p>")
  else
    -- Asume that file has two lines
    -- first one holds ssid value
    -- second one holds password
    local ssid = string.gsub(file.readline(), '\n', '')
    local pwd = string.gsub(file.readline(), '\n', '')
    connection:send("<p>Saved Access Point: \""..ssid.."\" with password \""..pwd.."\"!</p>")
    file.close()
  end

  connection:send([===[
         <form method="GET">
            SSID:<br><input type="text" name="ssid"><br>
            Password:<br><input type="text" name="pwd"><br>
            <input type="submit" name="submit" value="Submit">
         </form>
      ]===])

  connection:send("</div></body></html>")
end
