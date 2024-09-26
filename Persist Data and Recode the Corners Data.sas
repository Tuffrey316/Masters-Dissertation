data DISS.Corners;
set work.'corner data_0000'n;
run;

data DISS.Laps;
set work.'practice laps_0000'n;
run;

data DISS.Session_Results;
set work.'session results'n;
run;

/* RECODE Corner Variables */

data work.corners_recode;
set diss.corners;
*Recode Brake to boolean;
if Brake = 'True' then Brake_bool = 1;
if Brake = 'False' then Brake_bool = 0;
drop Brake;
*Recode Tyre Compound to numeric categories and apply format;
if 'Tyre Compound'n = 'UNKNOWN' then Compound = -2;
if 'Tyre Compound'n = 'TEST_UNKNOWN' then Compound = -1;
if 'Tyre Compound'n = 'SOFT' then Compound = 0;
if 'Tyre Compound'n = 'MEDIUM' then Compound = 1;
if 'Tyre Compound'n = 'HARD' then Compound = 2;
if 'Tyre Compound'n = 'INTERMEDIATE' then Compound = 3;
if 'Tyre Compound'n = 'WET' then Compound = 4;
drop 'Tyre Compound'n;
*Recode Fresh Tyre;
if 'Fresh Tyre'n = 'True' then New_Tyre = 1;
if 'Fresh Tyre'n = 'False' then New_Tyre = 0;
drop 'Fresh Tyre'n;
*Apply Formats;
Format Brake_bool Bool. Compound TyreCompound. New_Tyre Bool.;
*Replace Erroneous F2 Driver Codes for 2023 Budapest FP1;
if Driver = 'ARO' then Driver = 'VER';
if Driver = 'BEG' then Driver = 'SAR';
if Driver = 'BOY' then Driver = 'PER';
if Driver = 'BRO' then Driver = 'LEC';
if Driver = 'COH' then Driver = 'TSU';
if Driver = 'FCO' then Driver = 'GAS';
if Driver = 'FOR' then Driver = 'NOR';
if Driver = 'GRA' then Driver = 'MAG';
if Driver = 'MAN' then Driver = 'ZHO';
if Driver = 'MAR' then Driver = 'ALB';
if Driver = 'MON' then Driver = 'ALO';
if Driver = 'OSU' then Driver = 'RIC';
if Driver = 'SHI' then Driver = 'OCO';
if Driver = 'TBA' then Driver = 'HUL';
if Driver = 'VIL' then Driver = 'STR';
run;
data diss.corners_recode;
set work.corners_recode;
run;