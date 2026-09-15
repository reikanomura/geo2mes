//+
SetFactory("OpenCASCADE");
scale=0.01;
lc = 40*scale;
lcmin=lc/12;
lcmid=lc/8;
rr= 20*scale;
hh=150*scale;
//lc = 100;

// Rectangle Channel
x_sta = -250*scale; x_end = 250*scale;  dx = x_end-x_sta;
y_sta = -250*scale; y_end = 250*scale;  dy = y_end-y_sta;
z_sta =    0*scale; z_top = 500*scale;  dz = z_top-z_sta;
//

// Make rectangle channel
v_in  = newv; Box(v_in) = {x_sta, y_sta, z_sta, dx, dy, dz};
//

v1=newv; Cylinder(v1) = {0, 0, 0, 0, 0, hh, rr, 2*Pi};
//+
vv=newv; vv=BooleanDifference{ Volume{v_in}; Delete; }{ Volume{v1}; Delete; };

// Periodicity setting
Periodic Surface {4} = {2} Translate {0, dy, 0};
Periodic Surface {6} = {1} Translate {dx, 0, 0};
//
Physical Volume ("fluid") = {1};
Physical Surface ("pipe") = {7,8};

Field[1] = Distance;
Field[1].SurfacesList = {5};
Field[1].Sampling = 100;

Field[2] = Threshold;
Field[2].InField = 1;
Field[2].SizeMin = lcmid;
Field[2].SizeMax = lc;
Field[2].DistMin = 200*scale;
Field[2].DistMax = 300*scale;

Field[3] = Cylinder;
Field[3].Radius = rr*1.5;
Field[3].ZAxis = 1;
Field[3].ZCenter = hh/2.0;
Field[3].VIn = lcmin;
Field[3].VOut = lc;

Field[4] = Min;
Field[4].FieldsList = {2,3};
Background Field = 4;

Mesh.MeshSizeExtendFromBoundary = 0;
Mesh.MeshSizeFromPoints = 0;
Mesh.MeshSizeFromCurvature = 0;

Mesh.FirstNodeTag = 1;
Mesh.FirstElementTag = 1;
Mesh.Algorithm = 5;
Mesh.Algorithm3D = 1;
Mesh.CharacteristicLengthMax = lc;
Mesh.CharacteristicLengthMin = lcmin;
Mesh.OptimizeNetgen = 3;
