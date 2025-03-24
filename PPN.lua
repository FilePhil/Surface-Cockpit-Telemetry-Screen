---- #########################################################################
---- #                                                                       #
---- # Telemetry Screen for EdgeTX Radios                                    #
---- # Copyright (C) FilePhil                                                #
-----#                                                                       #
---- # License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               #
---- #                                                                       #
---- # This program is free software; you can redistribute it and/or modify  #
---- # it under the terms of the GNU General Public License version 2 as     #
---- # published by the Free Software Foundation.                            #
---- #                                                                       #
---- # This program is distributed in the hope that it will be useful        #
---- # but WITHOUT ANY WARRANTY; without even the implied warranty of        #
---- # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
---- # GNU General Public License for more details.                          #
---- #                                                                       #
---- #########################################################################

-- Battery Percent Calculation bases on work from JRWieland: https://github.com/jrwieland/Battery-mAh
-- GPS Handling based on work from mosch: https://github.com/moschotto/OpenTX_GPS_Telemetry

----------------------------------
-- Global Variables
local sat_cnt = 0
local sat_min_cnt = 5 --Set the Minimum for accurate Measurements

local gspd_id = 0
local speed_current = 0
local speed_max = 0
local speed_sum = 0
local speed_cnt = 0
local speed_average = 0

local lqi_id = 0
local lqi_current = 0

local dist_id = 0
local dist_value = 0
local gps_lat = 0
local gps_lon = 0
local lat_pre = 0
local lon_pre = 0

local bat_id = 0
local bat_value = 0
local bat_percent = 0
local bat_min = 100
local bat_cell_max_v = 4.2
local bat_cell_cnt = 0

local draw_tick = 0
local draw_flip = false
local draw_first = true

local log_write_wait_time = 1
local log_last_write = 0
local log_row = 0
local log_filename = "/LOGS/log.csv"

local now = 0
local date_table = 0
local inital_time = 0

----------------------------------
-- Drawing offsets
h_offset = 2
text_offset = 2
row_0 = 0
row_1 = 10
row_2 = 21
row_3 = 32
row_4 = 43
row_5 = 55
mid = 63

db_width = 42
db_height = 16

big_left = h_offset*10

----------------------------------

local function SecondsToClock(seconds)
  --format the Timer Values form Seconds into Clock Format
  local seconds = tonumber(seconds)
  if seconds <= 0 then
    return "00:00:00";
  else
    hours = string.format("%02.f", math.floor(seconds/3600));
    mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
    secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));    
	return hours..":"..mins..":"..secs
  end
end

local function write_log()

	now = getGlobalTimer()["session"]-inital_time    
 
  if log_last_write + log_write_wait_time <= now then
	
		time_text = SecondsToClock(now) 
     
    if log_row >= 10800 then --3h of recording
			log_row = 0		
    end		

    if log_row == 0 then
			--clear log
      
			file = io.open(log_filename, "w") 
			  io.write(file,"date_table,Time,Number,LAT,LON,satellites,Distance,GPSspeed,MaxSpeed,BatteryPercent\r\n")		
			io.close(file)				
		end	

    --write logfile		
		file = io.open(log_filename, "a")    				
    
    row_template = "%s,%s,%d,%0.6f,%0.6f,%d,%0.2f,%0.1f,%0.1f,%d\r\n"
    row = string.format(row_template,date_text, time_text,log_row, gps_lat, gps_lon, sat_cnt, dist_value, speed_current, speed_max, bat_percent)
    
    io.write(file, row)
   
    log_row = log_row + 1		
		log_last_write = now
	end	  
end

local function getCellPercent(cellValue)
  -- Calculate the Cell Percent based on the Discharing Voltage Curve
  -- Based on https://github.com/jrwieland/Battery-mAh

  if cellValue == nil then
    return 0
  end
  local result = 0;

  -- Curve of 4.2V
  lipoValue = {
        {{3.000,0},{3.093,1},{3.196,2},{3.301,3},{3.401,4},{3.477,5},{3.544,6},{3.601,7},{3.637,8},{3.664,9},{3.679,10}},
        {{3.683,11},{3.689,12},{3.692,13},{3.705,14},{3.710,15},{3.713,16},{3.715,17},{3.720,18},{3.731,19},{3.735,20}},
        {{3.744,21},{3.753,22},{3.756,23},{3.758,24},{3.762,25},{3.767,26},{3.774,27},{3.780,28},{3.783,29},{3.786,30}},
        {{3.789,31},{3.794,32},{3.797,33},{3.800,34},{3.802,35},{3.805,36},{3.808,37},{3.811,38},{3.815,39},{3.818,40}},
        {{3.822,41},{3.825,42},{3.829,43},{3.833,44},{3.836,45},{3.840,46},{3.843,47},{3.847,48},{3.850,49},{3.854,50}},
        {{3.857,51},{3.860,52},{3.863,53},{3.866,54},{3.870,55},{3.874,56},{3.879,57},{3.888,58},{3.893,59},{3.897,60}},
        {{3.902,61},{3.906,62},{3.911,63},{3.918,64},{3.923,65},{3.928,66},{3.939,67},{3.943,68},{3.949,69},{3.955,70}},
        {{3.961,71},{3.968,72},{3.974,73},{3.981,74},{3.987,75},{3.994,76},{4.001,77},{4.007,78},{4.014,79},{4.021,80}},
        {{4.029,81},{4.036,82},{4.044,83},{4.052,84},{4.062,85},{4.074,86},{4.085,87},{4.095,88},{4.105,89},{4.111,90}},
        {{4.116,91},{4.120,92},{4.125,93},{4.129,94},{4.135,95},{4.145,96},{4.176,97},{4.179,98},{4.193,99},{4.200,100}},
      }

  local _percentSplit = lipoValue
  for i1, v1 in ipairs(_percentSplit) do
    if (cellValue <= v1[#v1][1]) then
      for i2, v2 in ipairs(v1) do
        if v2[1] >= cellValue then
          result = v2[2]
          return result
        end
      end
    end
  end
  return 100
end


local function rnd(v,d)
	if d then
		return math.floor((v*10^d)+1/2)/(10^d)
	else
		return math.floor(v+1/2)
	end
end

local function calcDistance(lat_now, lon_now, lat_pre, lon_pre)
  -- Calculate the Distance from the last reading Point

	local d2r = math.pi/180
	local d_lon = (lon_now - lon_pre) * d2r 
	local d_lat = (lat_now - lat_pre) * d2r 
	local a = math.pow(math.sin(d_lat/2.0), 2) + math.cos(lat_pre*d2r) * math.cos(lat_now*d2r) * math.pow(math.sin(d_lon/2.0), 2)
	local c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
	local dist = (6371000 * c) / 1000	
  
	return dist
end

local function updateFlip()
  -- Interal Timer to show different Content
  draw_tick = draw_tick +1
  if draw_tick > 15 then 
    draw_tick = 0 
    draw_flip = not draw_flip
  end
end

local function getTelemetryId(name)    
	field = getFieldInfo(name)
	if field then
		return field.id
	else
		return-1
	end
end

local function init()  				
  gspd_id = getTelemetryId("GSpd")
  gps_id = getTelemetryId("GPS")
  
  sat_id = getTelemetryId("Sats")
  
  lqi_id = getTelemetryId("RQly")
  bat_id = getTelemetryId("RxBt")

  --if Stats can't be read, try to read Tmp2 (number of satellites SBUS/FRSKY)
  if (sat_id == -1) then sat_id = getTelemetryId("Tmp2") end	

end

local function reset()
  --- Set all Values to the Defaults 
  speed_current = 0
  speed_sum = 0
  speed_cnt = 1
  speed_average = 0
  speed_max = 0

  bat_value = 0
  bat_percent = 0
  bat_min = 100

  inital_time = 0

  dist_value = 0

  lqi_current = 0

  log_last_write = 0
  log_row = 0

  lat_pre = gps_lat
  lon_pre = gps_lon
end


local function background()

  -- Get GPS related data
  sat_cnt = getValue(sat_id)

  if sat_cnt > sat_min_cnt then
    -- read out the Speed and Calculate the max and average
    speed_current = rnd(getValue(gspd_id),1)

    if speed_current > 0.1 then
      speed_sum = speed_sum + speed_current
      speed_cnt = speed_cnt+1
    end

    if speed_cnt > 0 then
      speed_average = rnd(speed_sum / speed_cnt,1)
    end 

    speed_max = math.max(speed_max,speed_current)

    --Get Postition
    gps_pos = getValue(gps_id)
    
    if (type(gps_pos) == "table") then 			
      
      -- Add Up the Distance
      gps_lat = rnd(gps_pos["lat"],6)
      gps_lon = rnd(gps_pos["lon"],6)		

      dist_value = dist_value + calcDistance(gps_lat,gps_lon,lat_pre,lon_pre)
      
      lat_pre = gps_lat
      lon_pre = gps_lon
    end

  else
    speed_current = 0
    dist_value = 0
  end     

  -- Get Link Quality
  lqi_current = getValue(lqi_id)

  -- Get Battery Value
  bat_value = getValue(bat_id)

  if bat_value > 1 then -- Minimal Value

    -- Use Global Variable G9 as the Cell Count
    bat_cell_cnt = math.max(model.getGlobalVariable( 8, 0),0) 

    if bat_cell_cnt > 0 then
      bat_value = bat_value / bat_cell_cnt
    end

    -- Only Calculate the Percentage if the value is in the correct Range
    if bat_value <= bat_cell_max_v then 
      bat_percent = getCellPercent(bat_value)
    else
      bat_percent = 0
    end

    -- Log minimal Battery Voltage
    bat_min = math.min(bat_min,bat_value)

  else
    bat_value = 0
  end  
end

--main function 
local function run(event)  
	lcd.clear()  
	background() 
  updateFlip()
	
	--reset telemetry data / total distance on "long press enter"
  if draw_first  or event == EVT_ENTER_LONG then
   
    reset()

    -- Set Filename for the Log File
    inital_time = getGlobalTimer()["session"]
    date_table = getDateTime()
    date_text = string.format("%d-%d-%d",date_table["year"],date_table["mon"],date_table["day"])
    time_text = string.format("%d-%d-%d",date_table["hour"],date_table["min"],date_table["sec"])

    log_filename = string.format("/LOGS/log_%s_%s.csv",date_text,time_text)

    draw_first = false
  else
    write_log()
  end

  --Lines
  lcd.drawLine(LCD_W/2,row_2,LCD_W,row_2, SOLID, FORCE)	
  lcd.drawLine(LCD_W/2,row_5,LCD_W,row_5, SOLID, FORCE)	

  lcd.drawLine(LCD_W/2,row_1,LCD_W/2,row_3-1, SOLID, FORCE)	
  lcd.drawLine(LCD_W/2,row_4,LCD_W/2,LCD_H, SOLID, FORCE)	
  
  
  -- General Row
  lcd.drawFilledRectangle(0,0, LCD_W, row_1, GREY_DEFAULT)
  
  -- Satelite Info
  if sat_cnt < sat_min_cnt and draw_flip then
    sat_text =  string.format("NoGPSFix",sat_cnt)
  else
    sat_text =  string.format("Sat: %2d ",sat_cnt)
  end

  lcd.drawText(1,row_0 + text_offset,sat_text ,SMLSIZE + INVERS)	
  
  -- General Info
  row_0_text =  string.format("LQI:%3d%% TM:%s",lqi_current, SecondsToClock(now))
  lcd.drawText(h_offset*21,row_0 + text_offset,row_0_text ,SMLSIZE + INVERS)		

  -- Draw Battery Information
  lcd.drawText(1,row_2-text_offset, "Bat:" , SMLSIZE)

  -- print "---" when the Battery Reading is to low
  if bat_value < 2 then
    bat_percent_text =  string.format("---")
  else
    bat_percent_text =  string.format("%3d",bat_percent)
  end 

  lcd.drawText(big_left,row_2-db_height/2, bat_percent_text , DBLSIZE)

  lcd.drawText(big_left+h_offset*4+db_width/2,row_2-6, "%" , MIDSIZE)

  bat_value_text =  string.format("Now: %2.2fV",bat_value)
  lcd.drawText(LCD_W/2 + h_offset,row_1+text_offset,bat_value_text ,SMLSIZE)	

  bat_min_text =  string.format("Min: %2.2fV",bat_min)
  lcd.drawText(LCD_W/2 + h_offset,row_2+text_offset,bat_min_text ,SMLSIZE)	
  	
  -- Second Header with Distance Info
  lcd.drawFilledRectangle(0,row_3, LCD_W, row_4-row_3, GREY_DEFAULT)

  row_3_text =  string.format("Dist: %3.2f km",rnd(dist_value,2))
  lcd.drawText(1,row_3+text_offset,row_3_text ,SMLSIZE + INVERS)		

  -- Draw Speed Infos
  current_speed_text =  string.format("Now: %dkm/h",rnd(speed_current,0))
  lcd.drawText(LCD_W/2 + h_offset,row_4+text_offset,current_speed_text ,SMLSIZE)	

  average_speed_text =  string.format("Avg: %dkm/h",rnd(speed_average,0))
  lcd.drawText(LCD_W/2 + h_offset,row_5+text_offset,average_speed_text ,SMLSIZE)	

  -- Draw max speed
  lcd.drawText(1,row_4+4, "Max:" , SMLSIZE)
  lcd.drawText(1,row_4+12, "km/h" , SMLSIZE)

  lcd.drawText(big_left+h_offset  ,row_4+4, speed_max , DBLSIZE)

end
 
return {init=init, run=run, background=background}