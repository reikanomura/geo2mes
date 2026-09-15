//+
SetFactory("OpenCASCADE");

lc = 1.0;

// Rectangle Channel
x_sta = 0; x_end = 1.0;  dx = x_end-x_sta;
y_sta = 0; y_end = 0.5;  dy = y_end-y_sta;
z_sta = 0; z_top = 2.0;  dz = z_top-z_sta;

// Make rectangle channel
v_in  = newv; Box(v_in) = {x_sta, y_sta, z_sta, dx, dy, dz};

// Make pipe
v_ball = newv; Sphere(v_ball) = {0.5, 0.5, 1.0, 0.45};

v() = BooleanDifference{Volume{v_in}; Delete;}{Volume{v_ball}; Delete;};

//
Physical Volume ("fluid") = {v()};
Physical Surface ("particle") = {7};


Mesh.ScalingFactor = 0.001;

Mesh.FirstNodeTag = 1;
Mesh.FirstElementTag = 1;
Mesh.Algorithm = 5;
Mesh.Algorithm3D = 1;
Mesh.CharacteristicLengthMax = lc/20;
Mesh.CharacteristicLengthMin = lc;
Mesh.OptimizeNetgen = 1;
Mesh.SaveAll=1;
