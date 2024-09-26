data work.corners;
set diss.corners_recode;
if Team = 'Alfa Romeo' then Team = 'Kick Sauber';
if Team = 'AlphaTauri' then Team = 'RB';
drop F1;
run;

proc univariate data=work.corners plots;
hist Speed/ normal kernel;
run;

proc means data=work.corners mean median mode nmiss min max var std q1 q3 qrange range Missing;
Class Compound;
run;

proc means data=work.corners mean median mode nmiss min max var std q1 q3 qrange range Missing;
Class Circuit;
run;

proc means data=work.corners mean median mode nmiss min max var std q1 q3 qrange range Missing;
Class 'Corner Number'n;
run;

proc means data=work.corners mean median mode nmiss min max var std q1 q3 qrange range completetypes;
Class Team Circuit 'Corner Number'n;
Var Speed Gear RPM 'Top Speed'n 'Throttle %'n 'Tyre Life'n 'Distance to Driver Ahead'n Brake_bool Compound New_Tyre;
output out=work.corners2 mean= mode= /AUTONAME;
run;

proc gplot data=work.corners;
plot speed*'Corner Number'n;
by Circuit notsorted;
run;

data work.corners3;
set work.corners2;
if cmiss(of Team) then delete;
if cmiss(of Circuit) then delete;
drop  _freq_ _type_ Brake_bool_Mean Compound_Mean New_Tyre_Mean 'Distance to Driver Ahead_Mode'n Gear_Mean Gear_Mode RPM_Mean RPM_Mode Speed_Mode 'Throttle %_Mode'n 'Top Speed_Mode'n 'Tyre Life_Mode'n;
if cmiss(of 'Corner Number'n) then delete;
if cmiss(of Speed_Mean) then delete;
run;

ods graphics / maxlegendarea=40;
proc sgpanel data=work.corners3;
panelby Circuit / columns=1 rows=1;
series x='Corner Number'n y=Speed_Mean / group=Team;
run; 

data work.corners_clust;
set work.corners;
circ_corner = CAT(Circuit, 'Corner Number'n);
drop Circuit 'Corner Number'n;
run;

proc cluster data=work.corners_clust method=ward ccc pseudo rsquare outtree=work.Test_Tree print=15 plots=den(height=rsq);
copy circ_corner;
run; 

proc tree data=work.test_tree out=work.custers nclusters=3 noprint;
height _RSQ_;
copy Speed Gear 'Distance to Driver Ahead'n drs rpm Stint 'Throttle %'n 'Top Speed'n 'Track Status'n 'Tyre Life'n circ_corner;
run;

proc sgplot data=work.custers;
scatter x=speed y='Throttle %'n /group=cluster;
run;

proc means data=work.corners mean median mode nmiss min max var std q1 q3 qrange range completetypes;
Class Circuit 'Corner Number'n;
Var Speed Gear RPM 'Top Speed'n 'Throttle %'n 'Tyre Life'n 'Distance to Driver Ahead'n Brake_bool New_Tyre;
output out=work.corners_avg mean= mode= /AUTONAME;
run;

data work.corners_avg_2;
set work.corners_avg;
if cmiss(of Circuit) then delete;
drop  _freq_ _type_ Brake_bool_Mean New_Tyre_Mean New_Tyre_Mode 'Distance to Driver Ahead_Mode'n Gear_Mean Gear_Mode RPM_Mode Speed_Mode 'Throttle %_Mode'n 'Top Speed_Mode'n 'Top Speed_Mean'n 'Tyre Life_Mean'n 'Tyre Life_Mode'n;
if cmiss(of 'Corner Number'n) then delete;
if cmiss(of Speed_Mean) then delete;
run;
data work.corners_avg_clust;
set work.corners_avg_2;
circ_corner = CAT(Circuit, 'Corner Number'n);
drop Circuit 'Corner Number'n;
run;

/* WARD CLUSTERING */

proc cluster data=work.corners_avg_clust method=ward ccc pseudo rsquare outtree=work.avg_Tree_ward print=15 plots=den(height=rsq);
copy circ_corner;
run; 

proc tree data=work.avg_Tree_ward out=work.custers_avg_ward nclusters=3 noprint;
height _RSQ_;
copy circ_corner Speed_Mean RPM_Mean 'Distance to Driver Ahead_Mean'n 'Throttle %_Mean'n Brake_bool_Mode;
run;

proc sgplot data=work.custers_avg_ward tmplout="E:\SHUUsers\55-706554_DataAnalyticsToolsandTechniques\b8017424\HomeSpace\Masters\Dissertation\TestTemplate.txt";
scatter x=Speed_Mean y='Throttle %_Mean'n /group=cluster;
run;

proc template;
define statgraph sgplot;
begingraph / collation=binary;
layout overlay / yaxisopts=(labelFitPolicy=Split) y2axisopts=(labelFitPolicy=Split);
   ScatterPlot X='Speed_Mean'n Y='Throttle %_Mean'n / subpixel=off primary=true Group='CLUSTER'n LegendLabel="'Throttle %_Mean'n" NAME="SCATTER" rolename=(Label=circ_corner) tip=(X Y Label);
   DiscreteLegend "SCATTER"/ title="CLUSTER";
endlayout;
endgraph;
end;
run;

proc sgrender data=work.custers_avg_ward template=sgplot;
run;

data DISS.ward_corners;
set work.custers_avg_ward;
run;

proc means data=diss.ward_corners;
class cluster;
run;

/* MCQUITTY CLUSTERING */

proc cluster data=work.corners_avg_clust method=mcquitty ccc pseudo rsquare outtree=work.avg_Tree_mcquitty print=15 plots=den(height=rsq);
copy circ_corner;
run; 

proc tree data=work.avg_Tree_mcquitty out=work.custers_avg_mcquitty nclusters=3 noprint;
height _RSQ_;
copy circ_corner Speed_Mean RPM_Mean 'Distance to Driver Ahead_Mean'n 'Throttle %_Mean'n Brake_bool_Mode;
run;

proc sgrender data=work.custers_avg_mcquitty template=sgplot;
run;

data DISS.mcquitty_corners;
set work.custers_avg_mcquitty;
run;
proc means data=diss.mcquitty_corners;
class cluster;
run;

/* EML CLUSTERING */

proc cluster data=work.corners_avg_clust method=eml ccc pseudo rsquare outtree=work.avg_Tree_eml print=15 plots=den(height=rsq);
copy circ_corner;
run; 

proc tree data=work.avg_Tree_eml out=work.custers_avg_eml nclusters=3 noprint;
height _RSQ_;
copy circ_corner Speed_Mean RPM_Mean 'Distance to Driver Ahead_Mean'n 'Throttle %_Mean'n Brake_bool_Mode;
run;

proc sgrender data=work.custers_avg_eml template=sgplot;
run;

data DISS.eml_corners;
set work.custers_avg_eml;
run;
proc means data=diss.eml_corners;
class cluster;
run;

/* FLEXIBLE CLUSTERING */

proc cluster data=work.corners_avg_clust method=flexible ccc pseudo rsquare outtree=work.avg_Tree_flex print=15 plots=den(height=rsq);
copy circ_corner;
run; 

proc tree data=work.avg_Tree_flex out=work.custers_avg_flex nclusters=3 noprint;
height _RSQ_;
copy circ_corner Speed_Mean RPM_Mean 'Distance to Driver Ahead_Mean'n 'Throttle %_Mean'n Brake_bool_Mode;
run;

proc sgrender data=work.custers_avg_flex template=sgplot;
run;

data DISS.flex_corners;
set work.custers_avg_flex;
run;
proc means data=diss.flex_corners;
class cluster;
run;

/* Complete CLUSTERING */

proc cluster data=work.corners_avg_clust method=complete ccc pseudo rsquare outtree=work.avg_Tree_comp print=15 plots=den(height=rsq);
copy circ_corner;
run; 

proc tree data=work.avg_Tree_comp out=work.custers_avg_comp nclusters=3 noprint;
height _RSQ_;
copy circ_corner Speed_Mean RPM_Mean 'Distance to Driver Ahead_Mean'n 'Throttle %_Mean'n Brake_bool_Mode;
run;

proc sgrender data=work.custers_avg_comp template=sgplot;
run;

data DISS.comp_corners;
set work.custers_avg_comp;
run;
proc means data=diss.comp_corners;
class cluster;
run;


/* centroid CLUSTERING */

proc cluster data=work.corners_avg_clust method=centroid ccc pseudo rsquare outtree=work.avg_Tree_cent print=15 plots=den(height=rsq);
copy circ_corner;
run; 

proc tree data=work.avg_Tree_cent out=work.custers_avg_cent nclusters=3 noprint;
height _RSQ_;
copy circ_corner Speed_Mean RPM_Mean 'Distance to Driver Ahead_Mean'n 'Throttle %_Mean'n Brake_bool_Mode;
run;

proc sgrender data=work.custers_avg_cent template=sgplot;
run;

data DISS.cent_corners;
set work.custers_avg_cent;
run;
proc means data=diss.cent_corners;
class cluster;
run;

/* Single Linkage CLUSTERING */

proc cluster data=work.corners_avg_clust method=single ccc pseudo rsquare outtree=work.avg_Tree_single print=15 plots=den(height=rsq);
copy circ_corner;
run; 

proc tree data=work.avg_Tree_single out=work.custers_avg_single nclusters=3 noprint;
height _RSQ_;
copy circ_corner Speed_Mean RPM_Mean 'Distance to Driver Ahead_Mean'n 'Throttle %_Mean'n Brake_bool_Mode;
run;

proc sgrender data=work.custers_avg_single template=sgplot;
run;

data DISS.single_corners;
set work.custers_avg_single;
run;

proc means data=diss.single_corners;
class cluster;
run;

/* Average CLUSTERING */

proc cluster data=work.corners_avg_clust method=single ccc pseudo rsquare outtree=work.avg_Tree_avg print=15 plots=den(height=rsq);
copy circ_corner;
run; 

proc tree data=work.avg_Tree_avg out=work.custers_avg_avg nclusters=3 noprint;
height _RSQ_;
copy circ_corner Speed_Mean RPM_Mean 'Distance to Driver Ahead_Mean'n 'Throttle %_Mean'n Brake_bool_Mode;
run;

proc sgrender data=work.custers_avg_avg template=sgplot;
run;

data DISS.avg_corners;
set work.custers_avg_avg;
run;

proc means data=diss.avg_corners;
class cluster;
run;

/* Histograms */

proc sgplot data=work.corners_avg_clust;
histogram Speed_Mean;
run;
proc sgplot data=work.corners_avg_clust;
histogram RPM_Mean;
run;
proc sgplot data=work.corners_avg_clust;
histogram 'Throttle %_Mean'n;
run;

proc sgplot data=work.corners_avg_clust;
histogram Brake_bool_Mode;
run;

proc sgplot data=work.corners_avg_clust;
histogram 'Distance to Driver Ahead_Mean'n;
run;