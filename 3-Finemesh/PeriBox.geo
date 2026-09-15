//+
SetFactory("OpenCASCADE");

lc = 5;

// Rectangle Channel
x_sta = 0; x_end = 200; dx = x_end-x_sta;
y_sta = 0; y_end = 200; dy = y_end-y_sta;
z_sta = 0; z_top = 400; dz = z_top-z_sta;

// Make rectangle channel
v_in  = newv; Box(v_in) = {x_sta, y_sta, z_sta, dx, dy, dz};

// Make sphere
v_s = newv; Sphere(v_s) = {100, 100, 100, 5};

v() = BooleanDifference{Volume{v_in}; Delete;}{Volume{v_s}; Delete;};

//
Physical Volume ("fluid") = {v()};
Physical Surface ("particle") = {7};

// Define fine region
Field[1] = Ball;
Field[1].Radius = 7.5;
Field[1].VIn = lc / 8;
Field[1].VOut = lc;
Field[1].XCenter = 100;
Field[1].YCenter = 100;
Field[1].ZCenter = 100;
Field[1].Thickness = 30;

Field[2] = Box;
Field[2].VIn = lc / 3;
Field[2].VOut = lc;
Field[2].XMin = -15+100;
Field[2].XMax =  15+100;
Field[2].YMin = -15+100;
Field[2].YMax =  15+100;
Field[2].ZMin = -85+200;
Field[2].ZMax =  120+200;
Field[2].Thickness = 30;

Field[3] = Min;
Field[3].FieldsList = {1,2};
Background Field = 3;

Mesh.MeshSizeExtendFromBoundary = 0;
Mesh.MeshSizeFromPoints = 0;
Mesh.MeshSizeFromCurvature = 0;
Mesh.ScalingFactor = 0.0001;

Mesh.FirstNodeTag = 1;
Mesh.FirstElementTag = 1;
Mesh.Algorithm = 6;
Mesh.Algorithm3D = 1;
Mesh.CharacteristicLengthMax = lc;
Mesh.CharacteristicLengthMin = lc/30;
Mesh.OptimizeNetgen = 1;
Mesh.SaveAll = 1;
