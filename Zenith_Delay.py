import numpy as np

#Clear METAR

'''
METAR for:	KPAO (Palo Alto Arpt, CA, US)
Text:	KPAO 280447Z 00000KT 10SM SKC 09/03 A3034 RMK LAST
Temperature:	9.0°C ( 48°F)
Dewpoint:	3.0°C ( 37°F) [RH = 66%]
Pressure (altimeter):	30.34 inches Hg (1027.5 mb)
Winds:	calm
Visibility:	10 or more sm (16+ km)
Ceiling:	at least 12,000 feet AGL
Clouds:	clear skies
'''

#Overcast METAR

'''
METAR for:	KPAO (Palo Alto Arpt, CA, US)
Text:	KPAO 040247Z 00000KT 10SM RA SCT012 BKN100 12/09 A2987
Temperature:	12.0°C ( 54°F)
Dewpoint:	9.0°C ( 48°F) [RH = 82%]
Pressure (altimeter):	29.87 inches Hg (1011.6 mb)
Winds:	calm
Visibility:	10 or more sm (16+ km)
Ceiling:	10000 feet AGL
Clouds:	scattered clouds at 1200 feet AGL, broken clouds at 10000 feet AGL
Weather:	RA (moderate rain)
'''

#Starting Parameters

altitude = 22
P_g = 10.275E4
T_g = 273.15 + 9

#Actual Constants

elevation_angle = 90
delta_h = 1
c = 299792458
g = 9.806
m = 28.9647
k = 1.38064852E-23
lam = .0065
P_0 = 10.13E4
T_0 = 288.15
n_0 = 1.000293
tropopause = 20000
avagadro = 6.02214E23
m = m/(1000*avagadro)
path = 0

if tropopause%delta_h != 0:
    print("Altitude increment must be a factor of the tropopause altitude!")
    exit()

#Find Delay

heights = range(altitude,tropopause+delta_h,delta_h)

for h in heights:

    if h < delta_h/2:
        continue

    x = h - delta_h/2

    exponent = ((-m)*g*x)/(k*(T_g-(lam*x)))

    exp = np.exp(exponent)
    
    temp = T_g-(lam*x)-273.15

    n = 1 + ((P_g/P_0)*(n_0-1)*(exp)*T_g/(T_g-(lam*x)))

    path = path + delta_h*(n)

path = path/np.sin(np.radians(elevation_angle))
time = path/c
time_0 = tropopause/c
delay = path-((tropopause-altitude)/np.sin(np.radians(elevation_angle)))

print("Delay = ", round(delay, 5), "m")