//+
SetFactory("OpenCASCADE");
Mesh.MeshSizeFromCurvature = 20;
d = 0.5;
//+
Point(1) = {0, 0, 0, 0.10};
//+
Point(2) = {25*d, 0, 0, 0.10};
//+
Point(3) = {25*d, 4*d, 0, 0.10};
//+
Point(4) = {0, 4*d, 0, 0.10};
//+
Point(5) = {10*d, 1, 0, 0.05};
//+
Point(6) = {0, 0.25, 0, 0.10};
//+
Point(7) = {0, 0.5, 0, 0.10};
//+
Point(8) = {0, 0.75, 0, 0.10};
//+
Point(9) = {0, 1.0, 0, 0.10};
//+
Point(10) = {0, 1.25, 0, 0.10};
//+
Point(11) = {0, 1.5, 0, 0.10};
//+
Point(12) = {0, 1.75, 0, 0.10};
//+
Line(1) = {1, 2};
//+
Line(2) = {2, 3};
//+
Line(3) = {3, 4};
//+
Line(4) = {4, 12};
//+
Line(5) = {12, 11};
//+
Line(6) = {11, 10};
//+
Line(7) = {10, 9};
//+
Line(8) = {9, 8};
//+
Line(9) = {8, 7};
//+
Line(10) = {7, 6};
//+
Line(11) = {6, 1};
//+
Circle(12) = {5*d, 2*d, 0, d/2, 0, 2*Pi};
//+
Curve Loop(1) = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11};
//+
Curve Loop(2) = {12};
//+
Plane Surface(1) = {1, 2};
//+
Point {5} In Surface {1};
//+
Physical Surface("surface", 13) = {1};
//+
Physical Curve("outlet", 14) = {2};
//+
Physical Point("inlet_1", 15) = {12, 6};
//+
Physical Point("inlet_2", 16) = {11, 7};
//+
Physical Point("inlet_3", 17) = {10, 8};
//+
Physical Point("inlet_4", 18) = {9};
//+
Physical Curve("no-slip", 19) = {1, 3, 12};
