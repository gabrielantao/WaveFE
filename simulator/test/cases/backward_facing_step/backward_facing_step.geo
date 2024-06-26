//+
Point(1) = {0.0, 3.0, 0, 0.2};
//+
Point(2) = {0.0, 2.96366565, 0, 0.2};
//+
Point(3) = {0.0, 2.92741333, 0, 0.2};
//+
Point(4) = {0.0, 2.87303406, 0, 0.2};
//+
Point(5) = {0.0, 2.80355090, 0, 0.2};
//+
Point(6) = {0.0, 2.67968945, 0, 0.2};
//+
Point(7) = {0.0, 2.54374255, 0, 0.2};
//+
Point(8) = {0.0, 2.42290234, 0, 0.2};
//+
Point(9) = {0.0, 2.27789246, 0, 0.2};
//+
Point(10) = {0.0, 2.14798926, 0, 0.2};
//+
Point(11) = {0.0, 2.02412683, 0, 0.2};
//+
Point(12) = {0.0, 1.88818085, 0, 0.2};
//+
Point(13) = {0.0, 1.74317188, 0, 0.2};
//+
Point(14) = {0.0, 1.61024640, 0, 0.2};
//+
Point(15) = {0.0, 1.48638489, 0, 0.2};
//+
Point(16) = {0.0, 1.32627020, 0, 0.2};
//+
Point(17) = {0.0, 1.20542908, 0, 0.2};
//+
Point(18) = {0.0, 1.12990418, 0, 0.2};
//+
Point(19) = {0.0, 1.06948316, 0, 0.2};
//+
Point(20) = {0.0, 1.02114654, 0, 0.2};
//+
Point(21) = {0.0, 1.00000000, 0, 0.2};
//+
Point(22) = {4.0, 1.0, 0, 0.2};
//+
Point(23) = {4.00, 0.0, 0, 0.2};
//+
Point(24) = {4.88, 0.0, 0, 0.2};
//+
Point(25) = {6.11, 0.0, 0, 0.2};
//+
Point(26) = {8.17, 0.0, 0, 0.2};
//+
Point(27) = {14.29, 0.0, 0, 0.23};
//+
Point(28) = {40.0, 0.0, 0, 0.23};
//+
Point(29) = {40.0, 3.0, 0, 0.23};
//+
Point(30) = {14.29, 3.0, 0, 0.23};
//+
Point(31) = {8.17, 3.0, 0, 0.2};
//+
Point(32) = {6.11, 3.0, 0, 0.2};
//+
Point(33) = {4.88, 3.0, 0, 0.2};
//+
Point(34) = {4.0, 3.0, 0, 0.2};
//+
Line(1) = {1, 2};
//+
Line(2) = {2, 3};
//+
Line(3) = {3, 4};
//+
Line(4) = {4, 5};
//+
Line(5) = {5, 6};
//+
Line(6) = {6, 7};
//+
Line(7) = {7, 8};
//+
Line(8) = {8, 9};
//+
Line(9) = {9, 10};
//+
Line(10) = {10, 11};
//+
Line(11) = {11, 12};
//+
Line(12) = {12, 13};
//+
Line(13) = {13, 14};
//+
Line(14) = {14, 15};
//+
Line(15) = {15, 16};
//+
Line(16) = {16, 17};
//+
Line(17) = {17, 18};
//+
Line(18) = {18, 19};
//+
Line(19) = {19, 20};
//+
Line(20) = {20, 21};
//+
Line(21) = {21, 22};
//+
Line(22) = {22, 23};
//+
Line(23) = {23, 24};
//+
Line(24) = {24, 25};
//+
Line(25) = {25, 26};
//+
Line(26) = {26, 27};
//+
Line(27) = {27, 28};
//+
Line(28) = {28, 29};
//+
Line(29) = {29, 30};
//+
Line(30) = {30, 31};
//+
Line(31) = {31, 32};
//+
Line(32) = {32, 33};
//+
Line(33) = {33, 34};
//+
Line(34) = {34, 1};
//+
Curve Loop(1) = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34};
//+
Plane Surface(1) = {1};
//+
Physical Curve("no-slip", 35) = {21, 22, 23, 24, 25, 26, 27, 29, 30, 31, 32, 33, 34};
//+
Physical Curve("outlet", 36) = {28};
//+
Physical Point("inlet_1", 37) = {2};
//+
Physical Point("inlet_2", 38) = {3};
//+
Physical Point("inlet_3", 39) = {4};
//+
Physical Point("inlet_4", 40) = {5};
//+
Physical Point("inlet_5", 41) = {6};
//+
Physical Point("inlet_6", 42) = {7};
//+
Physical Point("inlet_7", 43) = {8};
//+
Physical Point("inlet_8", 44) = {9};
//+
Physical Point("inlet_9", 45) = {10};
//+
Physical Point("inlet_10", 46) = {11};
//+
Physical Point("inlet_11", 47) = {12};
//+
Physical Point("inlet_12", 48) = {13};
//+
Physical Point("inlet_13", 49) = {14};
//+
Physical Point("inlet_14", 50) = {15};
//+
Physical Point("inlet_15", 51) = {16};
//+
Physical Point("inlet_16", 52) = {17};
//+
Physical Point("inlet_17", 53) = {18};
//+
Physical Point("inlet_18", 54) = {19};
//+
Physical Point("inlet_19", 55) = {20};
//+
Line(35) = {22, 34};
//+
Line(36) = {24, 33};
//+
Line(37) = {25, 32};
//+
Line(38) = {26, 31};
//+
Line(39) = {27, 30};
//+
Curve {35, 36, 37, 38, 39} In Surface {1};
//+
Physical Curve("geom_4_00", 56) = {35};
//+
Physical Curve("geom_4_88", 57) = {36};
//+
Physical Curve("geom_6_11", 58) = {37};
//+
Physical Curve("geom_8_17", 59) = {38};
//+
Physical Curve("geom_14_29", 60) = {39};
