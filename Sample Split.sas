proc surveyselect data=diss.final_laps_results outall out=work.laps_test_train_split method=srs samprate=0.3;
run;

data diss.laps_train;
set work.laps_test_train_split;
if Selected = 0;
drop Selected;
if FinishingPosition = 'R' then delete;
if FinishingPosition = 'W' then delete;
if FinishingPosition = 'D' then delete;
run;
data diss.laps_test;
set work.laps_test_train_split;
if Selected = 1;
drop Selected;
if FinishingPosition = 'R' then delete;
if FinishingPosition = 'W' then delete;
if FinishingPosition = 'D' then delete;
run;

data work.qualy_laps_train_sample_1;
set diss.laps_train;
Temp_Qualifying_Pos = input(QualifyingPosition, 2.);
drop QualifyingPosition GridPosition points FinishingPosition DriverNumber; 
run;
data work.qualy_laps_train_sample;
set work.qualy_laps_train_sample_1;
QualifyingPosition = Temp_Qualifying_Pos;
drop Temp_Qualifying_Pos;
run;

data work.race_laps_train_sample_1;
set diss.laps_train;
Temp_Finishing_Pos = input(FinishingPosition, 2.);
drop FinishingPosition QualifyingPosition DriverNumber; 
run;
data work.race_laps_train_sample;
set work.race_laps_train_sample_1;
FinishingPosition = Temp_Finishing_Pos;
drop Temp_Finishing_Pos;
run;

data work.qualy_laps_test_sample_1;
set diss.laps_test;
Temp_Qualifying_Pos = input(QualifyingPosition, 2.);
drop QualifyingPosition GridPosition points FinishingPosition DriverNumber;
run;
data work.qualy_laps_test_sample;
set work.qualy_laps_test_sample_1;
QualifyingPosition = Temp_Qualifying_Pos;
drop Temp_Qualifying_Pos;
run;

data work.race_laps_test_sample_1;
set diss.laps_test;
Temp_Finishing_Pos = input(FinishingPosition, 2.);
drop FinishingPosition QualifyingPosition DriverNumber; 
run;
data work.race_laps_test_sample;
set work.race_laps_test_sample_1;
FinishingPosition = Temp_Finishing_Pos;
drop Temp_Finishing_Pos;
run;

/* Backwards Selection Models */

proc logistic data=work.qualy_laps_train_sample plots=all outest=work.qualy_laps_sample_model;;
class FreshTyre IsPersonalBest Session_Type Session Tyre_Compound;
model QualifyingPosition = High_Speed_Percentage Med_Speed_Percentage Low_Speed_Percentage 
		High_Speed_Rating Med_Speed_Rating Low_Speed_Rating Top_Speed Team_High_Speed_Rating Team_Med_Speed_Rating
		Team_Low_Speed_Rating LapTime LapNumber Stint SpeedFL IsPersonalBest
		TyreLife FreshTyre Session Tyre_Compound Session_Type / selection=backward rsquare stb iplots covb;
run;

proc logistic data=work.race_laps_train_sample plots=all outest=work.race_laps_sample_model;
class FreshTyre IsPersonalBest Session_Type Session Tyre_Compound GridPosition;
model FinishingPosition = GridPosition High_Speed_Percentage Med_Speed_Percentage Low_Speed_Percentage 
		High_Speed_Rating Med_Speed_Rating Low_Speed_Rating Top_Speed Team_High_Speed_Rating Team_Med_Speed_Rating
		Team_Low_Speed_Rating LapTime LapNumber Stint SpeedFL IsPersonalBest
		TyreLife FreshTyre Session Tyre_Compound Session_Type / selection=backward rsquare stb iplots covb ctable;
oddsratio GridPosition;
effectplot interaction(plotby=GridPosition);
run;

/* With Test Sample */

proc logistic data=work.race_laps_train_sample inest=work.race_laps_sample_model plots=all;
class FreshTyre IsPersonalBest Session_Type Session Tyre_Compound GridPosition;
model FinishingPosition = GridPosition High_Speed_Percentage Med_Speed_Percentage 
		High_Speed_Rating Med_Speed_Rating Low_Speed_Rating Top_Speed Team_High_Speed_Rating Team_Med_Speed_Rating
		Team_Low_Speed_Rating LapNumber Stint IsPersonalBest TyreLife FreshTyre
	    Tyre_Compound Session_Type/ rsquare stb iplots covb ctable maxiter=0;
score data=work.race_laps_test_sample out=work.race_laps_sample_pred;
run;


proc logistic data=work.qualy_laps_train_sample plots=all inest=work.qualy_laps_sample_model;;
class FreshTyre IsPersonalBest Session_Type Session Tyre_Compound;
model QualifyingPosition = High_Speed_Percentage High_Speed_Rating Med_Speed_Rating Low_Speed_Rating Top_Speed
		Team_High_Speed_Rating Team_Med_Speed_Rating
		Team_Low_Speed_Rating LapNumber Stint
		Session Tyre_Compound Session_Type/ rsquare stb iplots covb maxiter=0;
score data=work.qualy_laps_test_sample out=work.qualy_laps_sample_pred;
run;

proc freq data=work.qualy_laps_sample_pred ;
by Session_Type notsorted;
Tables F_QualifyingPosition I_QualifyingPosition/ nocol norow nopercent;
run;
proc freq data=work.race_laps_sample_pred ;
by Session_Type notsorted;
Tables F_FinishingPosition I_FinishingPosition/ nocol norow nopercent;
run;

data diss.qualy_laps_sample_preds;
set work.qualy_laps_sample_pred;
Prediction_Diff = I_QualifyingPosition-F_QualifyingPosition;
Predicted_Qualifying_Pos = input(I_QualifyingPosition, 2.);
run;
data diss.race_laps_sample_preds;
set work.race_laps_sample_pred;
Prediction_Diff = I_FinishingPosition-F_FinishingPosition;
Predicted_Finishing_Pos = input(I_FinishingPosition, 2.);
run;

proc freq data=diss.qualy_laps_sample_preds;
by Session_Type notsorted;
Tables Driver*(F_QualifyingPosition I_QualifyingPosition Prediction_Diff)/ nocol norow nopercent;
run;
proc freq data=diss.race_laps_sample_preds;
by Session_Type notsorted;
Tables Driver*(F_FinishingPosition I_FinishingPosition Prediction_Diff)/ nocol norow nopercent;
run;

proc sgplot data=diss.qualy_laps_sample_preds;
heatmapparm x=QualifyingPosition y=Predicted_Qualifying_Pos COLORRESPONSE=Prediction_Diff / outline;
run;

proc sgplot data=diss.race_laps_sample_preds;
heatmapparm x=FinishingPosition y=Predicted_Finishing_Pos COLORRESPONSE=Prediction_Diff/ outline;
run;

data diss.teamcolours;
length linecolor $ 9 fillcolor $ 9 value $ 20 MARKERCOLOR $ 9;
input ID $ value & $ linecolor $ fillcolor $ MARKERCOLOR $;
datalines;
myid Alpine  CXFF87BC CXFF87BC CXFF87BC
myid Aston Martin  CX229971 CX229971 CX229971
myid Ferrari  CXE8002D CXE8002D CXE8002D
myid Haas F1 Team  CXB6BABD CXB6BABD CXB6BABD
myid Kick Sauber  CX52E252 CX52E252 CX52E252
myid McLaren  CXFF8000 CXFF8000 CXFF8000
myid Mercedes  CX27F4D2 CX27F4D2 CX27F4D2
myid RB  CX6692FF CX6692FF CX6692FF
myid Red Bull Racing  CX3671C6 CX3671C6 CX3671C6
myid Williams  CX64C4FF CX64C4FF CX64C4FF
;
run;

title "Actual Qualifying Position against Predicting Qualifying Position by Team";
proc sgplot data=diss.qualy_laps_sample_preds dattrmap=diss.teamcolours;
scatter x=QualifyingPosition y=Predicted_Qualifying_Pos /group=Team attrid=myid jitter;
keylegend/ autoitemsize across=5 down=2;
run;

title "Actual Finishing Position against Predicting Finishing Position by Team";
proc sgplot data=diss.race_laps_sample_preds dattrmap=diss.teamcolours;
scatter x=FinishingPosition y=Predicted_Finishing_Pos /group=Team attrid=myid jitter;
keylegend/ autoitemsize across=5 down=2;
run;
title;

title "Actual Qualifying Position against Predicting Qualifying Position by Driver";
proc sgplot data=diss.qualy_laps_sample_preds dattrmap=diss.drivercolours;
scatter x=QualifyingPosition y=Predicted_Qualifying_Pos /group=Driver attrid=myid jitter;
keylegend/ autoitemsize across=5 down=2;
run;

title "Actual Finishing Position against Predicting Finishing Position by Driver";
proc sgplot data=diss.race_laps_sample_preds dattrmap=diss.drivercolours;
scatter x=FinishingPosition y=Predicted_Finishing_Pos /group=Driver attrid=myid jitter;
keylegend/ autoitemsize across=5 down=2;
run;
title;

data diss.drivercolours;
length linecolor $ 9 fillcolor $ 9 value $ 20 MARKERCOLOR $ 9;
input ID $ value & $ linecolor $ fillcolor $ MARKERCOLOR $;
datalines;
myid LEC  CXdc0000 CXdc0000 CXdc0000
myid PIA  CXff8700 CXff8700 CXff8700
myid SAI  CXff8181 CXff8181 CXff8181
myid NOR  CXeeb370 CXeeb370 CXeeb370
myid RUS  CX24ffff CX24ffff CX24ffff
myid VER  CXfcd700 CXfcd700 CXfcd700
myid HAM  CX00d2be CX00d2be CX00d2be
myid TSU  CX356cac CX356cac CX356cac
myid ALB  CX005aff CX005aff CX005aff
myid GAS  CXfe86bc CXfe86bc CXfe86bc
myid ALO  CX006f62 CX006f62 CX006f62
myid RIC  CX2b4562 CX2b4562 CX2b4562
myid BOT  CX00e701 CX00e701 CX00e701
myid STR  CX00413b CX00413b CX00413b
myid SAR  CX012564 CX012564 CX012564
myid ZHO  CX008d01 CX008d01 CX008d01
myid OCO  CXff117c CXff117c CXff117c
myid PER  CXffec7b CXffec7b CXffec7b
myid HUL  CXcacaca CXcacaca CXcacaca
myid MAG  CX000000 CX000000 CX000000
;
run;

data work.reduced_preds_qualy;
set diss.qualy_laps_sample_preds;
where Season = 2024 and Circuit = "Monaco";
run;
data work.reduced_preds_race;
set diss.race_laps_sample_preds;
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
