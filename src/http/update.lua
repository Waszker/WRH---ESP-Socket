local function updateFile(rd)
    local filefolder = ""
    local filename = ""
    local filecontentok = false
    local filemode = "w+"

    for name, value in pairs(rd) do
        if name == "httpFolder" then filefolder = "http/"
        elseif name == "filename" then filename = value
        elseif name == "filecontent" then filecontentok = true
        elseif name == "appenddata" then filemode = "a+"
        end
    end

    filename = filefolder..filename
    if filecontentok == false and file.exists(filename) then file.remove(filename)
    elseif filename ~= "" and filename ~= "http/" then
        for name, value in pairs(rd) do
            if name == "filecontent" then
               file.open(filename, filemode)
               file.write(value)
               file.close(filename)
            end 
        end
    end
end

return function (connection, req, args)
   dofile("httpserver-header.lc")(connection, 200, 'html')
   connection:send([===[
      <!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Software update</title></head><body><div align="center"><h1>Software update</h1>
   ]===])

   if req.method == "GET" then
      connection:send([===[
      <p>Please bear in mind that too big files can reset ESP8266 chip!</p>
      <p>Proceed with caution!</p><br />
      <form method="POST">
         Filename:<br><input type="text" name="filename"><br>
         File content:<br><textarea name="filecontent"></textarea><br>
         Inside HTTP folder:<input type="checkbox" name="httpFolder" value="httpFolder"><br>
         Append data:<input type="checkbox" name="appenddata" value="appenddata"><br>
         <input type="submit" name="submit" value="Submit">
      </form>
      ]===])
   elseif req.method == "POST" then
      local rd = req.getRequestData()
      updateFile(rd)
      connection:send('<h2>Update completed</h2>')
   else
      connection:send("ERROR WTF req.method is ", req.method)
   end

   connection:send('</div></body></html>')
end
