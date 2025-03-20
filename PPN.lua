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
	--number of satellites crossfire
	gpssatId = getTelemetryId("Sats")
	--if Stats can't be read, try to read Tmp2 (number of satellites SBUS/FRSKY)
	if (gpssatId == -1) then gpssatId = getTelemetryId("Tmp2") end	
end


local function background()
  counter = counter +1

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
	lcd.drawLine(0,0,0,95, SOLID, FORCE)	
	lcd.drawLine(127,0,127,95, SOLID, FORCE)	
	
	lcd.drawText(2,1,"Tele: " ,SMLSIZE)		
	lcd.drawFilledRectangle(1,0, 126, 8, GREY_DEFAULT)
	

	lcd.drawLine(42,8, 42, 32, SOLID, FORCE)		
	
	lcd.drawLine(0,32, 128, 32, SOLID, FORCE)				

	lcd.drawLine(0,60, 128, 60, SOLID, FORCE)

	lcd.drawLine(0,95,127,95, SOLID, FORCE)	
	
	--update screen data
	sat_text =  string.format("Sat:%d ",sat_cnt)
  lcd.drawText(4,10, sat_text, SMLSIZE)



  current_speed_text =  string.format("Spd:%.1fkm/h",speed_current)
  lcd.drawText(45,10, current_speed_text, SMLSIZE)

  average_speed_text =  string.format("Avg:%.1fkm/h",speed_average)
  lcd.drawText(45,18, average_speed_text, SMLSIZE)
  


  lcd.drawText(4,48, "Max:" , SMLSIZE)
  lcd.drawText(25,40, speed_max , DBLSIZE)
  lcd.drawText(70,48, "km/h" , SMLSIZE)


end
 
return {init=init, run=run, background=background}