data work.clust_corners;
set diss.cent_corners;
run;

data work.pre_merge_corners;
set diss.corners_recode;
if Team = 'Alfa Romeo' then Team = 'Kick Sauber';
if Team = 'AlphaTauri' then Team = 'RB';
drop F1;
circ_corner = CAT(Circuit, 'Corner Number'n);
run;

proc sort data=work.clust_corners;
by circ_corner;
run;

proc sort data=work.pre_merge_corners;
by circ_corner;
run;

data work.corner_clust_merge;
merge work.clust_corners work.pre_merge_corners;
by circ_corner;
if CLUSTER = 2 then Corner_Speed = "Medium Speed";
if CLUSTER = 1 then Corner_Speed = "High Speed";
if CLUSTER = 3 then Corner_Speed = "Low Speed";
drop _NAME_ CLUSNAME;
run;

data diss.categorised_corners;
set work.corner_clust_merge;
run;

data work.pre_rating_clean;
set diss.categorised_corners;
drop Brake_bool Brake_bool_Mode 'Track Status'n Stint CLUSTER;
run;

data work.differences_ratings;
set work.pre_rating_clean;
Speed_Diff = Speed-Speed_Mean;
RPM_Diff = RPM-RPM_Mean;
Dist_Diff = 'Distance to Driver Ahead'n-'Distance to Driver Ahead_Mean'n;
Throttle_Diff = 'Throttle %'n-'Throttle %_Mean'n;
run;

proc means data=work.differences_ratings Mean STD var nonobs noprint;
class Driver Corner_Speed;
var Speed_Diff RPM_Diff Dist_Diff Throttle_Diff 'Top Speed'n;
output out=work.driver_diffs mean= std= var= /Autoname;
run;

proc means data=work.differences_ratings Mean STD var nonobs noprint;
class Team Corner_Speed;
var Speed_Diff RPM_Diff Dist_Diff Throttle_Diff 'Top Speed'n;
output out=work.team_diffs mean= std= var= /Autoname;
run;

data diss.team_diffs_corner;
set work.team_diffs;
if cmiss(of Team) then delete;
if cmiss(of Corner_Speed) then delete;
run;

data diss.driver_diffs_corner;
set work.driver_diffs;
if cmiss(of Driver) then delete;
if cmiss(of Corner_Speed) then delete;
run;

proc sgpanel data=diss.driver_diffs_corner;
panelby Corner_Speed/ rows=1 columns=1;
vbar Driver /response=Speed_Diff_Mean;
run;
proc sgpanel data=diss.team_diffs_corner;
panelby Corner_Speed/ rows=1 columns=1;
vbar Team /response=Speed_Diff_Mean;
run;

proc standard data=diss.team_diffs_corner mean=0 std=1 out=work.teams_standard;
var Speed_Diff_Mean RPM_Diff_Mean Dist_Diff_Mean Throttle_Diff_Mean;
run;

data work.reduced_driver_diffs_corner;
set diss.driver_diffs_corner;
if Driver = 'COL' then delete;
if Driver = 'DEN' then delete;
if Driver = 'DOO' then delete;
if Driver = 'DRU' then delete;
if Driver = 'HAD' then delete;
if Driver = 'IWA' then delete;
if Driver = 'OWA' then delete;
if Driver = 'POU' then delete;
if Driver = 'SHW' then delete;
if Driver = 'VES' then delete;
run;

proc standard data=work.reduced_driver_diffs_corner mean=0 std=1 out=work.driver_standard;
var Speed_Diff_Mean RPM_Diff_Mean Dist_Diff_Mean Throttle_Diff_Mean;
run;

proc sgpanel data=work.driver_standard;
panelby Corner_Speed/ rows=1 columns=1;
vbar Driver /response=Speed_Diff_Mean;
run;
proc sgpanel data=work.teams_standard;
panelby Corner_Speed/ rows=1 columns=1;
vbar Team /response=Speed_Diff_Mean;
run;

data diss.driver_standard;
set work.driver_standard;
run;

data diss.teams_standard;
set work.teams_standard;
run;

/* Set Team Ratings */
data work.rated_teams_standard;
set diss.teams_standard;
Corner_Rating = Speed_Diff_Mean+(RPM_Diff_Mean*Dist_Diff_Mean*Throttle_Diff_Mean);
drop _freq_ _type_ Dist_Diff_Mean Dist_Diff_StdDev Dist_Diff_Var RPM_Diff_Mean RPM_Diff_StdDev RPM_Diff_Var Speed_Diff_Mean Speed_Diff_StdDev Speed_Diff_Var Throttle_Diff_Mean Throttle_Diff_StdDev Throttle_Diff_Var 'Top Speed_StdDev'n 'Top Speed_Var'n;
run;
proc sgpanel data=work.rated_teams_standard;
panelby Corner_Speed/ rows=1 columns=2;
vbar Team /response=Corner_Rating;
run;
proc sgpanel data=work.rated_teams_standard;
panelby Corner_Speed/ rows=1 columns=2;
vbar Team /response='Top Speed_Mean'n;
run;

data work.rated_teams;
set work.rated_teams_standard;
if Corner_Speed = 'High Speed' then High_Speed_Rating = Corner_Rating;
if Corner_Speed = 'Medium Speed' then Med_Speed_Rating = Corner_Rating;
if Corner_Speed = 'Low Speed' then Low_Speed_Rating = Corner_Rating;
drop Corner_Speed Corner_Rating;
run;
proc summary data=work.rated_teams max printall nonobs;
class Team;
var 'Top Speed_Mean'n High_Speed_Rating Med_Speed_Rating Low_Speed_Rating;
output out=work.rated_teams_flat max= /autoname;
run;
data diss.team_ratings;
set work.rated_teams_flat;
drop _freq_ _type_;
if cmiss(of Team) then delete;
Top_Speed = 'Top Speed_Mean_Max'n;
Team_High_Speed_Rating = High_Speed_Rating_Max;
Team_Med_Speed_Rating = Med_Speed_Rating_Max;
Team_Low_Speed_Rating = Low_Speed_Rating_Max;
drop High_Speed_Rating_Max Med_Speed_Rating_Max Low_Speed_Rating_Max 'Top Speed_Mean_Max'n;
run;
/*Set Driver Ratings */
data work.rated_drivers;
set diss.driver_standard;
Corner_Rating = Speed_Diff_Mean+(RPM_Diff_Mean*Dist_Diff_Mean*Throttle_Diff_Mean);
drop _freq_ _type_ 'Top Speed_Mean'n Dist_Diff_Mean Dist_Diff_StdDev Dist_Diff_Var RPM_Diff_Mean RPM_Diff_StdDev RPM_Diff_Var Speed_Diff_Mean Speed_Diff_StdDev Speed_Diff_Var Throttle_Diff_Mean Throttle_Diff_StdDev Throttle_Diff_Var 'Top Speed_StdDev'n 'Top Speed_Var'n;
if Corner_Speed = 'High Speed' then High_Speed_Rating = Corner_Rating;
if Corner_Speed = 'Medium Speed' then Med_Speed_Rating = Corner_Rating;
if Corner_Speed = 'Low Speed' then Low_Speed_Rating = Corner_Rating;
drop Corner_Speed Corner_Rating;
run;
proc summary data=work.rated_drivers max printall nonobs;
class Driver;
var High_Speed_Rating Med_Speed_Rating Low_Speed_Rating;
output out=work.rated_drivers_flat max= /autoname;
run;
data diss.driver_ratings;
set work.rated_drivers_flat;
drop _freq_ _type_;
if cmiss(of Driver) then delete;
High_Speed_Rating = High_Speed_Rating_Max;
Med_Speed_Rating = Med_Speed_Rating_Max;
Low_Speed_Rating = Low_Speed_Rating_Max;
drop High_Speed_Rating_Max Med_Speed_Rating_Max Low_Speed_Rating_Max 'Top Speed_Mean_Max'n;
run;