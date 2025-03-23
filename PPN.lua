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

-- Battery Percent Calculation bases on JRWieland's work: https://github.com/jrwieland/Battery-mAh
-- Telemetry and GPS Handling based on mosch's work https://github.com/moschotto/OpenTX_GPS_Telemetry

local sat_cnt = 0
local gspd_id = 0
local speed_current = 0
local speed_max = 0
local speed_sum = 0
local speed_cnt = 0
local speed_average = 0

local lqi_id = 0
local lqi_current = 0

local bat_id = 0
local bat_value = 0
local bat_percent = 0
local bat_min = 100
local bat_hv = false

-----------------------------------------------------------------


local function getCellPercent(cellValue)
  if cellValue == nil then
    return 0
  end
  local result = 0;

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

	gpssatId = getTelemetryId("Sats")
  
  lqi_id = getTelemetryId("RQly")
  bat_id = getTelemetryId("RxBt")
	
  --if Stats can't be read, try to read Tmp2 (number of satellites SBUS/FRSKY)
	if (gpssatId == -1) then gpssatId = getTelemetryId("Tmp2") end	
end


local function background()
  counter = counter +1
  -- Get GPS related data
  sat_cnt = getValue(gpssatId)
  -- read out the Speed and Calculate the max and average
  speed_current = rnd(getValue(gspd_id),1)
  if speed_current > 1/10 then
    speed_sum = speed_sum + speed_current
    speed_cnt = speed_cnt+1
  end

  if speed_cnt > 0 then
    speed_average = rnd(speed_sum / speed_cnt,1)
  end 

  speed_max = math.max(speed_max,speed_current)

  -- Get Link Quality
  lqi_current = getValue(lqi_id)

  -- Get Battery
  bat_value = getValue(bat_id)
  bat_percent = getCellPercent(bat_value)
  
  if bat_value > 1 then
    bat_min = math.min(bat_min,bat_value)
  end 

end

--main function 
local function run(event)  
	lcd.clear()  
	background() 
	
	--reset telemetry data / total distance on "long press enter"
	if event == EVT_ENTER_LONG then
    speed_current = 0
    speed_sum = 0
    speed_cnt = 1
    speed_average = 0
    speed_max = 0

	end 	
	
  sat_text =  string.format("Sat:%2d ",sat_cnt)

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

  --Lines
  lcd.drawLine(LCD_W/2,row_2,LCD_W,row_2, SOLID, FORCE)	
  lcd.drawLine(LCD_W/2,row_5,LCD_W,row_5, SOLID, FORCE)	

  lcd.drawLine(LCD_W/2,row_1,LCD_W/2,row_3-1, SOLID, FORCE)	
  lcd.drawLine(LCD_W/2,row_4,LCD_W/2,LCD_H, SOLID, FORCE)	
  
  
  -- General Row
  lcd.drawFilledRectangle(0,0, LCD_W, row_1, GREY_DEFAULT)
  row_0_text =  string.format("Sat:%2d  LQI:%3d %%  TM: 00:00:00",sat_cnt,lqi_current)
  lcd.drawText(h_offset,row_0+text_offset,row_0_text ,SMLSIZE + INVERS)		
 

  -- Draw Battery Information
  big_left = h_offset*10

  lcd.drawText(h_offset,row_2-text_offset, "Bat:" , SMLSIZE)

  bat_percent_text =  string.format("%3d",bat_percent)
  lcd.drawText(big_left,row_2-db_height/2, bat_percent_text , DBLSIZE)

  lcd.drawText(big_left+h_offset*4+db_width/2,row_2-6, "%" , MIDSIZE)

  bat_value_text =  string.format("Now: %2.2fV",bat_value)
  lcd.drawText(LCD_W/2 + h_offset,row_1+text_offset,bat_value_text ,SMLSIZE)	

  bat_min_text =  string.format("Min: %2.2fV",bat_min)
  lcd.drawText(LCD_W/2 + h_offset,row_2+text_offset,bat_min_text ,SMLSIZE)	
  	
  -- Second Header with Speed Info
  lcd.drawFilledRectangle(0,row_3, LCD_W, row_4-row_3, GREY_DEFAULT)


  -- General Row

  row_3_text =  string.format("Dist: %3.2f km",0.2)
  lcd.drawText(h_offset,row_3+text_offset,row_3_text ,SMLSIZE + INVERS)		

  
  current_speed_text =  string.format("Now: %dkm/h",rnd(speed_current,0))
  lcd.drawText(LCD_W/2 + h_offset,row_4+text_offset,current_speed_text ,SMLSIZE)	

  average_speed_text =  string.format("Avg: %dkm/h",rnd(speed_average,0))
  lcd.drawText(LCD_W/2 + h_offset,row_5+text_offset,average_speed_text ,SMLSIZE)	


  -- Draw max speed
  lcd.drawText(h_offset,row_4+4, "Max:" , SMLSIZE)
  lcd.drawText(h_offset,row_4+12, "km/h" , SMLSIZE)

  lcd.drawText(big_left+h_offset  ,row_4+4, speed_max , DBLSIZE)

end
 
return {init=init, run=run, background=background}