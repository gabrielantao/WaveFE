//+
Point(1) = {0, 0, 0, 0.1};
//+
Point(2) = {12, 0, 0, 0.1};
//+
Point(3) = {12, 2, 0, 0.1};
//+
Point(4) = {0, 2, 0, 0.1};
//+
Point(5) = {5, 0.75, 0, 0.05};
//+
Point(6) = {5, 1.25, 0, 0.05};
//+
Point(7) = {5, 1, 0, 0.05};
//+
Line(1) = {1, 2};
//+
Line(2) = {2, 3};
//+
Line(3) = {3, 4};
//+
Line(4) = {4, 1};
//+
Circle(5) = {6, 7, 5};
//+
Line(6) = {5, 7};
//+
Line(7) = {7, 6};
//+
Curve Loop(1) = {1, 2, 3, 4};
//+
Curve Loop(2) = {6, 7, 5};
//+
Plane Surface(1) = {1, 2};
//+
Physical Curve("no-slip", 8) = {1, 3, 5, 6, 7};
//+
Physical Curve("inlet", 9) = {4};
//+
Physical Curve("outlet", 10) = {2};
