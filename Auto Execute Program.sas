ods html IMAGE_DPI=300;
ods graphics on / imagemap maxlegendarea=100 TIPMAX=19200;

proc format;
value Bool
0 = "False"
1 = "True";
value TyreCompound
-2 = "Unknown"
-1 = "Test Unknown"
0 = "Soft"
1 = "Medium"
2 = "Hard"
3 = "Intermediate"
4 = "Wet";
run;