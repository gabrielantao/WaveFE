//+
SetFactory("OpenCASCADE");
//+
Point(1) = {0, 0, 0, 0.4};
//+
Point(2) = {12, 0, 0, 0.4};
//+
Point(3) = {12, 2, 0, 0.4};
//+
Point(4) = {0, 2, 0, 0.4};
//+
Line(1) = {1, 2};
//+
Line(2) = {2, 3};
//+
Line(3) = {3, 4};
//+
Line(4) = {4, 1};
//+
Circle(5) = {5, 1, 0, 0.25, 0, 2*Pi};
//+
Curve Loop(1) = {1, 2, 3, 4};
//+
Curve Loop(2) = {5};
//+
Plane Surface(1) = {1, 2};
//+
Physical Curve("inlet", 6) = {4};
//+
Physical Curve("outlet", 7) = {2};
//+
Physical Curve("no-slip", 8) = {3, 1, 5};
