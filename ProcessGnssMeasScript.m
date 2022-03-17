close all
clear
%ProcessGnssMeasScript.m, script to read GnssLogger output, compute and plot:
% pseudoranges, C/No, and weighted least squares PVT solution
%
% you can run the data in pseudoranges log files provided for you: 
prFileName = 'gnss_log_2022_02_28_00_35_07.txt'; %with duty cycling, no carrier phase
% prFileName = 'pseudoranges_log_2016_08_22_14_45_50.txt'; %no duty cycling, with carrier phase
% as follows
% 1) copy everything from GitHub google/gps-measurement-tools/ to 
%    a local directory on your machine
% 2) change 'dirName = ...' to match the local directory you are using:
dirName = 'INSERT FULL DIRECTORY HERE!\GNSS Analysis Tool\logs';
% 3) run ProcessGnssMeasScript.m script file 
param.llaTrueDegDegM = [];

%Author: Frank van Diggelen; modified by Jacob Mukobi
%Open Source code for processing Android GNSS Measurements

%% data
%To add your own data:
% save data from GnssLogger App, and edit dirName and prFileName appropriately
%dirName = 'put the full path for your directory here';
%prFileName = 'put the pseuoranges log file name here';

%% parameters
%param.llaTrueDegDegM = [];
%enter true WGS84 lla, if you know it:
param.llaTrueDegDegM = [37.422578, -122.081678, -28];%Charleston Park Test Site

%% Set the data filter and Read log file
dataFilter = SetDataFilter;
[gnssRaw,gnssAnalysis] = ReadGnssLogger(dirName,prFileName,dataFilter);
if isempty(gnssRaw), return, end

%% Get online ephemeris from Nasa ftp, first compute UTC Time from gnssRaw:
fctSeconds = 1e-3*double(gnssRaw.allRxMillis(end));
utcTime = Gps2Utc([],fctSeconds);
allGpsEph = GetNasaHourlyEphemeris(utcTime,dirName);
if isempty(allGpsEph), return, end

%% process raw measurements, compute pseudoranges:
[gnssMeas] = ProcessGnssMeas(gnssRaw);

%% compute WLS position and velocity

%First iteration raw position
gpsPvt = GpsWlsPvt(gnssMeas,allGpsEph);
raw_pos = gpsPvt.allLlaDegDegM;

gnssMeas.PrM = gnssMeas.PrM - gpsPvt.pseudo_delays;
gpsPvt = GpsWlsPvt(gnssMeas,allGpsEph);
delay_pos = gpsPvt.allLlaDegDegM;
pos_actual_inst = [37.431105, -122.169050, 22];
pos_actual = pos_actual_inst;
delta_pos = abs(delay_pos - raw_pos);

times = size(delta_pos, 1);

%Calculate Average Position

total_raw_pos = zeros(1, 3);
total_delay_pos = zeros(1, 3);

for h = 1:times
total_raw_pos(1) = total_raw_pos(1) + raw_pos(h,1);
total_raw_pos(2) = total_raw_pos(2) + raw_pos(h,2);
total_raw_pos(3) = total_raw_pos(3) + raw_pos(h,3);

total_delay_pos(1) = total_delay_pos(1) + delay_pos(h,1);
total_delay_pos(2) = total_delay_pos(2) + delay_pos(h,2);
total_delay_pos(3) = total_delay_pos(3) + delay_pos(h,3);
end

format long

zenith_delay = 3.08544;
avg_raw_pos = total_raw_pos/times;
avg_delay_pos = total_delay_pos/times;

avg_raw_pos_error = abs(avg_raw_pos - pos_actual);
avg_raw_pos_error(1) = avg_raw_pos_error(1)/(10^(-7));
avg_raw_pos_error(2) = avg_raw_pos_error(2)/(7.94123^(-8));
avg_delay_pos_error = abs(avg_delay_pos - pos_actual);
avg_delay_pos_error(1) = avg_delay_pos_error(1)/(10^(-7));
avg_delay_pos_error(2) = avg_delay_pos_error(2)/(7.94123^(-8));

%Error of Avg position across all timesteps

raw_pos_avg_error = sqrt((avg_raw_pos_error(1)^2)+(avg_raw_pos_error(2)^2))/100
delay_pos_avg_error = sqrt((avg_delay_pos_error(1)^2)+(avg_delay_pos_error(2)^2))/100

for h = 1:times-1
    pos_actual = [pos_actual;pos_actual_inst];
end

%Calculate Errors

raw_pos_error_deg = abs(pos_actual - raw_pos);
delay_pos_error_deg = abs(pos_actual - delay_pos);

raw_pos_error = zeros(times,1);
delay_pos_error = zeros(times,1);

for h = 1:times
    lat_raw = raw_pos_error_deg(h, 1)/(10^(-7));
    lon_raw = raw_pos_error_deg(h, 2)/(7.94123^(-8));
    raw_pos_error(h) = sqrt((lat_raw^2)+(lon_raw^2));
    
    lat_delay = delay_pos_error_deg(h, 1)/(10^(-7));
    lon_delay = delay_pos_error_deg(h, 2)/(7.94123^(-8));
    delay_pos_error(h) = sqrt((lat_delay^2)+(lon_delay^2));
end


%Average of Errors for Each Timestep

avg_raw_pos_error_m = mean(raw_pos_error)/100
avg_delay_pos_error_m = mean(delay_pos_error)/100
    
x = 1:times;

plot(x, raw_pos_error, "r")
hold on
plot(x, delay_pos_error, "b")
grid on
legend("WLS Position Error", "Pseudorange Delay WLS Position Error")
title("Absolute Position Error")
xlabel("Time (seconds)")
ylabel("Position Error (cm)")


%% end of ProcessGnssMeasScript
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2016 Google Inc.
% 
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
%     http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
