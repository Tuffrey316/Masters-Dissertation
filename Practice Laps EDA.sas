data work.laps;
set diss.laps;
run;

proc means data=work.laps mean median mode nmiss min max var std q1 q3 qrange range;
by Season;
run;

proc means data=work.laps mean median mode nmiss min max var std q1 q3 qrange range;
Class Circuit;
run;

proc sgplot data=work.laps;
histogram LapTime;
run;

proc univariate data=work.laps plots;
hist LapTime/ normal kernel;
run;