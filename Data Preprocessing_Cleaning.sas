data work.laps_recode;
set diss.laps;
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
if Team = 'Alfa Romeo' then Team = 'Kick Sauber';
if Team = 'AlphaTauri' then Team = 'RB';
if Compound = 'UNKNOWN' then Tyre_Compound = -2;
if Compound = 'TEST_UNKNOWN' then Tyre_Compound = -1;
if Compound = 'SOFT' then Tyre_Compound = 0;
if Compound= 'MEDIUM' then Tyre_Compound = 1;
if Compound = 'HARD' then Tyre_Compound = 2;
if Compound = 'INTERMEDIATE' then Tyre_Compound = 3;
if Compound = 'WET' then Tyre_Compound = 4;
format Tyre_Compound TyreCompound.;
drop Compound PitOutTime PitInTime F1 Sector1SessionTime Sector2SessionTime Sector3SessionTime LapStartDate LapStartTime Time;
*if cmiss(of LapTime) then LapTime = Sector1Time+Sector2Time+Sector3Time;
run;

proc summary data=work.laps_recode nmiss print;
var LapTime Sector1Time Sector2Time Sector3Time SpeedFL SpeedI1 SpeedI2 SpeedST;
run;

data work.missing_ID;
set work.laps_recode;
if nmiss(LapTime, Sector1Time, Sector2Time, Sector3Time) = 1;
Keep ID Driver DriverNumber Deleted DeletedReason Season Circuit Session;
run;

data work.laps_clean;
set work.laps_recode;
if cmiss(of LapTime) then delete;
if cmiss(of Sector1Time) then delete;
if cmiss(of Sector2Time) then delete;
if cmiss(of Sector3Time) then delete;
if nmiss(Stint) then delete;
if Deleted = 'True' then delete;
if TrackStatus ^= 1 then delete;
drop SpeedI1 SpeedI2 SpeedST DeletedReason Position;
run;
proc summary data=work.laps_clean nmiss print;
var _numeric_;
run;
proc freq data=work.laps_clean nlevels;
run;

proc sort data=work.laps_clean;
by Team;
run;
data work.team_ratings;
set diss.team_ratings;
run;
proc sort data=work.team_ratings;
by Team;
run;
data work.driver_ratings;
set diss.driver_ratings;
run;
proc sort data=work.driver_ratings;
by Driver;
run;
data work.laps_merge;
merge work.team_ratings work.laps_clean;
by Team;
run;
proc sort data=work.laps_merge;
by Driver;
run;
data work.laps_merge_1;
merge work.driver_ratings work.laps_merge;
by Driver;
if cmiss(of High_Speed_Rating) then delete;
if cmiss(of Med_Speed_Rating) then delete;
if cmiss(of Low_Speed_Rating) then delete;
run;
data diss.laps_with_ratings;
set work.laps_merge_1;
run;

proc freq data=diss.laps_with_ratings nlevels;
run;

data diss.corner_speeds;
set work.query_for_categorised_corners;
run;

proc freq data=diss.corner_speeds nlevels;
tables Circuit*Corner_Speed/ out=work.corners_categorised outpct nofreq nocum nocol nopercent; 
run;

data diss.corners_categorised;
set work.corners_categorised;
drop count pct_col percent;
if Corner_Speed = 'High Speed' then High_Speed_Percentage = PCT_ROW;
if Corner_Speed = 'Medium Speed' then Med_Speed_Percentage = PCT_ROW;
if Corner_Speed = 'Low Speed' then Low_Speed_Percentage = PCT_ROW;
drop Corner_Speed pct_row;
run;
proc summary data=diss.corners_categorised max printall nonobs;
class Circuit;
var High_Speed_Percentage Med_Speed_Percentage Low_Speed_Percentage;
output out=work.cat_corners_flat max= /autoname;
run;
data diss.cat_corners;
set work.cat_corners_flat;
if cmiss(Low_Speed_Percentage_Max) then Low_Speed_Percentage_Max = 0;
drop _freq_ _type_;
High_Speed_Percentage = High_Speed_Percentage_Max/100;
Med_Speed_Percentage = Med_Speed_Percentage_Max/100;
Low_Speed_Percentage = Low_Speed_Percentage_Max/100;
drop High_Speed_Percentage_Max Med_Speed_Percentage_Max Low_Speed_Percentage_Max;
if cmiss(Circuit) then delete;
run;

/* Merge Laps with Circuit Ratings */

proc sort data=diss.laps_with_ratings out=work.sorted_laps_with_ratings;
by Circuit;
run;

data work.rated_laps_with_circuit;
merge diss.cat_corners work.sorted_laps_with_ratings;
by Circuit;
drop TrackStatus Deleted FastF1Generated IsAccurate;
run;

/* Clean and prepare the Session_Results Data for Merging */
data work.cleaned_results_1;
set diss.session_results;
if Session = "FP1" then delete;
if Session = "FP2" then delete;
if Session = "FP3" then delete;
drop F1 DriverId TeamId TeamColor CountryCode HeadshotUrl;
if Abbreviation = 'ARO' then Abbreviation = 'VER';
if Abbreviation = 'BEG' then Abbreviation = 'SAR';
if Abbreviation = 'BOY' then Abbreviation = 'PER';
if Abbreviation = 'BRO' then Abbreviation = 'LEC';
if Abbreviation = 'COH' then Abbreviation = 'TSU';
if Abbreviation = 'FCO' then Abbreviation = 'GAS';
if Abbreviation = 'FOR' then Abbreviation = 'NOR';
if Abbreviation = 'GRA' then Abbreviation = 'MAG';
if Abbreviation = 'MAN' then Abbreviation = 'ZHO';
if Abbreviation = 'MAR' then Abbreviation = 'ALB';
if Abbreviation = 'MON' then Abbreviation = 'ALO';
if Abbreviation = 'OSU' then Abbreviation = 'RIC';
if Abbreviation = 'SHI' then Abbreviation = 'OCO';
if Abbreviation = 'TBA' then Abbreviation = 'HUL';
if Abbreviation = 'VIL' then Abbreviation = 'STR';
if TeamName = 'Alfa Romeo' then TeamName = 'Kick Sauber';
if TeamName = 'AlphaTauri' then TeamName = 'RB';
drop Q1 Q2 Q3 Time;
if BroadcastName = 'nan' and Abbreviation = "SAR" then BroadcastName = "L SARGEANT";
if BroadcastName = 'nan' and Abbreviation = "STR" then BroadcastName = "L STROLL";
if GridPosition = 0 then GridPosition = 21;
drop Status;
run;

proc freq data=work.cleaned_results_1 nlevels;
run;

data work.cleaned_results_2;
set work.cleaned_results_1;
if Session = "Q" then ClassifiedPosition = Position;
if Session = "SQ" then ClassifiedPosition = Position;
if Session = "SS" then ClassifiedPosition = Position;
drop Position BroadcastName FirstName LastName;
run;

data work.Qualy_Results;
set work.cleaned_results_2;
if Session = "Q";
drop GridPosition Points;
QualifyingPosition = ClassifiedPosition;
drop ClassifiedPosition Session;
Driver = Abbreviation;
drop Abbreviation;
run;
data work.Sprint_Qualy_Results;
set work.cleaned_results_2;
if Session = "SS" or Session = "SQ";
drop GridPosition Points;
QualifyingPosition = ClassifiedPosition;
drop ClassifiedPosition Session;
Driver = Abbreviation;
drop Abbreviation;
run;
data work.Race_Results;
set work.cleaned_results_2;
if Session = "R";
if nmiss(GridPosition) then GridPosition = 0;
FinishingPosition = ClassifiedPosition;
drop ClassifiedPosition;
Driver = Abbreviation;
drop Abbreviation;
run;
data work.Sprint_Race_Results;
set work.cleaned_results_2;
if Session = "S";
if nmiss(GridPosition) then GridPosition = 0;
FinishingPosition = ClassifiedPosition;
drop ClassifiedPosition;
Driver = Abbreviation;
drop Abbreviation;
run;

proc freq data=work.Race_Results nlevels;
run;

proc sort data=work.Qualy_results;
by Season Circuit TeamName Driver DriverNumber;
run;
proc sort data=work.Sprint_Qualy_Results;
by Season Circuit TeamName Driver DriverNumber;
run;
proc sort data=work.Race_Results;
by Season Circuit TeamName Driver DriverNumber;
run;
proc sort data=work.Sprint_Race_Results;
by Season Circuit TeamName Driver DriverNumber;
run;

/* Merge Results Together */

*Merging Sprint Sessions;

data work.Sprint_Results;
merge work.Sprint_qualy_results work.SPRINT_RACE_RESULTS;
by Season Circuit TeamName Driver DriverNumber;
Team = TeamName;
drop Session TeamName;
run;

*Merging Race Sessions;

data work.Final_Race_Results;
merge work.Qualy_results work.Race_Results;
by Season Circuit TeamName Driver DriverNumber;
Team = TeamName;
drop Session TeamName;
run;

/* Merge with Laps */

*Sort Laps;
proc sort data=work.Rated_laps_with_circuit;
by Season Circuit Team Driver DriverNumber;
run;

data Diss.Laps_for_Races;
merge work.final_race_results work.rated_laps_with_circuit;
by Season Circuit Team Driver DriverNumber;
Session_Type = "Race";
run;

data Diss.Laps_for_Sprints;
merge work.Sprint_Results work.rated_laps_with_circuit;
by Season Circuit Team Driver DriverNumber;
Session_Type = "Sprint";
run;

proc freq data=Diss.Laps_for_Races nlevels;
run;
proc freq data=Diss.Laps_for_Sprints nlevels;
run;

data work.All_Laps_with_Results;
set Diss.Laps_for_Sprints;
run;

proc append base=work.ALL_LAPS_WITH_RESULTS data=diss.Laps_for_Races;
run;

proc freq data=work.ALL_LAPS_WITH_RESULTS nlevels;
run;

data diss.final_laps_results;
set work.all_laps_with_results;
if cmiss(of Points) then delete;
if cmiss(of LapTime) then delete;
run;

proc freq data=diss.final_laps_results nlevels;
run;