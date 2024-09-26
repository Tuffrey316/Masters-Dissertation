/* Split Data By Year and Qualy - Race */
data work.final_laps_results_1;
set diss.final_laps_results;
if FinishingPosition = 'R' then delete;
if FinishingPosition = 'W' then delete;
if FinishingPosition = 'D' then delete;
Temp_Qualifying_Pos = input(QualifyingPosition, 2.);
Temp_Finishing_Pos = input(FinishingPosition, 2.);
drop QualifyingPosition FinishingPosition;
run;
data work.final_laps_results;
set work.final_laps_results_1;
QualifyingPosition = Temp_Qualifying_Pos;
FinishingPosition = Temp_Finishing_Pos;
drop Temp_Qualifying_Pos Temp_Finishing_Pos;
run;

data work.qualy_laps_2023;
set work.final_laps_results;
if season = 2023;
drop GridPosition points FinishingPosition DriverNumber; 
run;
data work.race_laps_2023;
set work.final_laps_results;
if season = 2023;
drop QualifyingPosition DriverNumber; 
run;

data work.qualy_laps_2024;
set work.final_laps_results;
if season = 2024;
drop GridPosition points FinishingPosition DriverNumber; 
run;
data work.race_laps_2024;
set work.final_laps_results;
if season = 2024;
drop QualifyingPosition DriverNumber; 
run;



proc logistic data=work.qualy_laps_2023 plots=all outest=work.qualy_laps_model;;
class FreshTyre IsPersonalBest Session_Type Session Tyre_Compound;
model QualifyingPosition = High_Speed_Percentage Med_Speed_Percentage Low_Speed_Percentage 
		High_Speed_Rating Med_Speed_Rating Low_Speed_Rating Top_Speed Team_High_Speed_Rating Team_Med_Speed_Rating
		Team_Low_Speed_Rating LapTime LapNumber Stint SpeedFL IsPersonalBest
		TyreLife FreshTyre Session Tyre_Compound Session_Type / selection=backward rsquare stb iplots covb;
run;

proc logistic data=work.race_laps_2023 plots=all outest=work.race_laps_model;
class FreshTyre IsPersonalBest Session_Type Session Tyre_Compound GridPosition;
model FinishingPosition = GridPosition High_Speed_Percentage Med_Speed_Percentage Low_Speed_Percentage 
		High_Speed_Rating Med_Speed_Rating Low_Speed_Rating Top_Speed Team_High_Speed_Rating Team_Med_Speed_Rating
		Team_Low_Speed_Rating LapTime LapNumber Stint SpeedFL IsPersonalBest
		TyreLife FreshTyre Session Tyre_Compound Session_Type / selection=backward rsquare stb iplots covb ctable;
oddsratio GridPosition;
effectplot interaction(plotby=GridPosition);
run;

proc logistic data=work.race_laps_2023 inest=work.race_laps_model plots=all;
class FreshTyre IsPersonalBest Session_Type Session Tyre_Compound GridPosition;
model FinishingPosition = GridPosition High_Speed_Percentage Med_Speed_Percentage 
		High_Speed_Rating Med_Speed_Rating Low_Speed_Rating Team_High_Speed_Rating Team_Med_Speed_Rating
		Team_Low_Speed_Rating LapNumber Stint SpeedFL TyreLife
	    Session Tyre_Compound Session_Type/ rsquare stb iplots covb ctable maxiter=0;
score data=work.race_laps_2024 out=work.race_laps_2024_pred;
run;


proc logistic data=work.qualy_laps_2023 plots=all inest=work.qualy_laps_model;;
class FreshTyre IsPersonalBest Session_Type Session Tyre_Compound;
model QualifyingPosition = High_Speed_Rating Med_Speed_Rating Low_Speed_Rating Top_Speed
		Team_High_Speed_Rating Team_Med_Speed_Rating Team_Low_Speed_Rating LapNumber Stint
		TyreLife FreshTyre Session Tyre_Compound Session_Type/ rsquare stb iplots covb maxiter=0;
score data=work.qualy_laps_2024 out=work.qualy_laps_2024_pred;
run;

/* Attempt at extracting old models probabilites to full race order */

proc means data=work.race_laps_2024_pred print;
by Circuit Session_Type notsorted;
class Driver;
var P_1 P_2 P_3 P_4 P_5 P_6 P_7 P_8 P_9 P_10 P_11 P_12 P_13 P_14 P_15 P_16 P_17 P_18 P_19 P_20 P_R P_D P_W;
output out= work.avg_Prob_Pos_2024;
run;

data work.prob_pos_2024_1;
set work.avg_prob_pos_2024;
drop _type_ _freq_;
if _STAT_ ^= 'MAX' then delete;
if cmiss(of Driver) then delete;
drop _Stat_;
run;

proc means data=work.prob_pos_2024_1 max nway;
class Circuit;
run;

proc rank data=work.prob_pos_2024_1 out=work.ranked_pos_2024 descending;
by Circuit Session_Type notsorted;
var P_1 P_2 P_3 P_4 P_5 P_6 P_7 P_8 P_9 P_10 P_11 P_12 P_13 P_14 P_15 P_16 P_17 P_18 P_19 P_20 P_R P_D P_W;
ranks rank_P_1 rank_P_2 rank_P_3 rank_P_4 rank_P_5 rank_P_6 rank_P_7 rank_P_8 rank_P_9 rank_P_10
	  rank_P_11 rank_P_12 rank_P_13 rank_P_14 rank_P_15 rank_P_16 rank_P_17 rank_P_18 rank_P_19 rank_P_20
	  rank_P_R rank_P_D rank_P_W;
run;

proc transpose data=work.prob_pos_2024_1 out=work.temp_rank_pos_2024;
by Circuit Session_Type notsorted;
id Driver;
run;
proc rank data=work.temp_rank_pos_2024 out=work.prob_pos_2024_2 descending;
by Circuit Session_Type notsorted;
var ALB ALO BOT GAS HAM HUL LEC MAG NOR OCO PER PIA RIC RUS SAI SAR STR TSU VER ZHO;
run;
proc transpose data=work.prob_pos_2024_2 out=work.temp_rank_pos_2024;
by Circuit Session_Type notsorted;
id _NAME_;
run;

data diss.Qualy_Preds_2024;
set work.qualy_laps_2024_pred;
keep Circuit Driver Team Session_Type LapTime F_QualifyingPosition I_QualifyingPosition;
run;

data diss.Race_Preds_2024;
set work.race_laps_2024_pred;
keep Circuit Driver Team Session_Type LapTime GridPosition F_FinishingPosition I_FinishingPosition;
run;

proc freq data=diss.Qualy_preds_2024 ;
by Session_Type notsorted;
Tables (Team Driver)*(F_QualifyingPosition I_QualifyingPosition)/ nocol norow nopercent;
output out=work.freq_Qualy_preds_2024;
run;

proc freq data=diss.Race_preds_2024 ;
by Session_Type notsorted;
Tables F_FinishingPosition I_FinishingPosition/ nocol norow nopercent;
run;

/* Important Output */
data diss.qualy_laps_2024_preds;
set work.qualy_laps_2024_pred;
Prediction_Diff = I_QualifyingPosition-F_QualifyingPosition;
Predicted_Qualifying_Pos = input(I_QualifyingPosition, 2.);
run;
data diss.race_laps_2024_preds;
set work.race_laps_2024_pred;
Prediction_Diff = I_FinishingPosition-F_FinishingPosition;
Predicted_Finishing_Pos = input(I_FinishingPosition, 2.);
run;

proc freq data=diss.qualy_laps_2024_preds;
by Session_Type notsorted;
Tables Driver*(F_QualifyingPosition I_QualifyingPosition Prediction_Diff)/ nocol norow nopercent;
run;
proc freq data=diss.race_laps_2024_preds;
by Session_Type notsorted;
Tables Driver*(F_FinishingPosition I_FinishingPosition Prediction_Diff)/ nocol norow nopercent;
run;

title "Actual Qualifying Position against Predicting Qualifying Position by Team";
proc sgplot data=diss.qualy_laps_2024_preds dattrmap=diss.teamcolours;
scatter x=QualifyingPosition y=Predicted_Qualifying_Pos /group=Team attrid=myid jitter;
keylegend/ autoitemsize across=5 down=2;
run;

title "Actual Finishing Position against Predicting Finishing Position by Team";
proc sgplot data=diss.race_laps_2024_preds dattrmap=diss.teamcolours;
scatter x=FinishingPosition y=Predicted_Finishing_Pos /group=Team attrid=myid jitter;
keylegend/ autoitemsize across=5 down=2;
run;
title;

title "Actual Qualifying Position against Predicting Qualifying Position by Driver";
proc sgplot data=diss.qualy_laps_2024_preds dattrmap=diss.drivercolours;
scatter x=QualifyingPosition y=Predicted_Qualifying_Pos /group=Driver attrid=myid jitter;
keylegend/ autoitemsize across=5 down=2;
run;

title "Actual Finishing Position against Predicting Finishing Position by Driver";
proc sgplot data=diss.race_laps_2024_preds dattrmap=diss.drivercolours;
scatter x=FinishingPosition y=Predicted_Finishing_Pos /group=Driver attrid=myid jitter;
keylegend/ autoitemsize across=5 down=2;
run;
title;

data work.reduced_preds_qualy;
set diss.qualy_laps_2024_preds;
where Season = 2024 and Circuit = "Monaco";
run;
data work.reduced_preds_race;
set diss.race_laps_2024_preds;
where Season = 2024 and Circuit = "Monaco";
run;

title "Actual Qualifying Position against Predicting Qualifying Position by Driver (Monaco 2024)";
proc sgplot data=work.reduced_preds_qualy dattrmap=diss.drivercolours;
scatter x=QualifyingPosition y=Predicted_Qualifying_Pos /group=Driver attrid=myid jitter;
keylegend/ autoitemsize across=5 down=2;
run;

title "Actual Finishing Position against Predicting Finishing Position by Driver (Monaco 2024)";
proc sgplot data=work.reduced_preds_race dattrmap=diss.drivercolours;
scatter x=FinishingPosition y=Predicted_Finishing_Pos /group=Driver attrid=myid jitter;
keylegend/ autoitemsize across=5 down=2;
run;
title;
