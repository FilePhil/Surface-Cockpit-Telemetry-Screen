---- #########################################################################
---- #                                                                       #
---- # Telemetry Widget for EdgeTX Radios                                    #
---- # Copyright (C) EdgeTX                                                  #
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

-- Widget to display the levels of lipo/HVLipo battery with mAh Used based on battery voltage
-- JRWieland
-- Date: 2024
local app_name = "Batt/mAh"
local app_ver = "1.0"
local counter = 0

local sat_cnt = 0
local gspd_id = 0
local speed_current = 0
local speed_max = 0
local speed_sum = 0
local speed_cnt = 0
local speed_average = 0


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
	
	-- create screen
	
  --
	
	
  sat_text =  string.format("Sat:%2d ",sat_cnt)

  h_offset = 2
  text_offset = 2
  row_0 = 0
  row_1 = 10
  row_2 = 20
  row_3 = 30
  row_4 = 55

  --Lines
  --lcd.drawLine(0,row_0,LCD_W,row_0, SOLID, FORCE)	
  lcd.drawLine(0,row_1,LCD_W,row_1, SOLID, FORCE)	
  lcd.drawLine(LCD_W/2,row_2,LCD_W,row_2, SOLID, FORCE)	
  lcd.drawLine(0,row_3,LCD_W,row_3, SOLID, FORCE)	
  lcd.drawLine(0,row_4,LCD_W,row_4, SOLID, FORCE)	
  
  -- General Row
  lcd.drawFilledRectangle(0,0, LCD_W, row_1, GREY_DEFAULT)
  row_0_text =  string.format("Sat:%2d  LQI:%3d %%  TM: 00:00:00",sat_cnt,lqi_current)
  lcd.drawText(h_offset,row_0+text_offset,row_0_text ,SMLSIZE + INVERS)		
 

	
	--update screen data
 

  
  
  mid = 63
  maxRow = 36
  db_width = 42
  db_height = 16

    current_speed_text =  string.format("Spd: %dkm/h",rnd(speed_current,0))
    lcd.drawText(h_offset,row_4+text_offset, current_speed_text, SMLSIZE)

    average_speed_text =  string.format("Avg: %dkm/h",rnd(speed_average,0))
    lcd.drawText(mid+h_offset,row_4+text_offset, average_speed_text, SMLSIZE)
    
    lcd.drawText(mid-db_width,maxRow+8, "Max:" , SMLSIZE)
    lcd.drawText(mid-db_width/2,maxRow, speed_max , DBLSIZE)
    lcd.drawText(mid+db_width/2,maxRow+8, "km/h" , SMLSIZE)


end
 
return {init=init, run=run, background=background}