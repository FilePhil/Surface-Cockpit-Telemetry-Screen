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

local function background()
  counter = counter +1
end

local function init()  				
	counter = 100
end
--main function 
local function run(event)  
	lcd.clear()  
	background() 
	
	--reset telemetry data / total distance on "long press enter"
	if event == EVT_ENTER_LONG then
		counter = 0
	end 	
	
	-- create screen
	lcd.drawLine(0,0,0,95, SOLID, FORCE)	
	lcd.drawLine(127,0,127,95, SOLID, FORCE)	
	
	lcd.drawText(2,1,"Tele: " ,SMLSIZE)		
	lcd.drawFilledRectangle(1,0, 126, 8, GREY_DEFAULT)
	
	lcd.drawPixmap(2,10, "/SCRIPTS/TELEMETRY/BMP/Sat16.bmp")		
	lcd.drawLine(42,8, 42, 32, SOLID, FORCE)		
	
	lcd.drawLine(0,32, 128, 32, SOLID, FORCE)				

	
	lcd.drawLine(0,60, 128, 60, SOLID, FORCE)
			

	lcd.drawLine(0,95,127,95, SOLID, FORCE)	
	
	--update screen data
	if update == true then
						
		lcd.drawText(32,1,counter, SMLSIZE + INVERS)			
	
		
	--blink if telemetry stops
	elseif update == false then
				
	end	
end
 
return {init=init, run=run, background=background}