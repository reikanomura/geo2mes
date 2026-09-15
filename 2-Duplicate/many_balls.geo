//+
SetFactory("OpenCASCADE");

lc = 1.0;
dd = 1.0;

// Rectangle Channel
x_sta = 0; x_end = 5.0;  dx = x_end-x_sta;
y_sta = 0; y_end = 5.0;  dy = y_end-y_sta;
z_sta = 0; z_top = 5.0;  dz = z_top-z_sta;

// Make rectangle channel
v_in  = newv; Box(v_in) = {x_sta, y_sta, z_sta, dx, dy, dz};

// Make sphere
v_ball = newv; Sphere(v_ball) = {0.5, 0.5, 0.5, dd/2};

// Make Sphere arrays
dx = dd;
dy = dd;
dz = dd;

For i In {1:4}
  Translate{dx, 0, 0} { Duplicata{ Volume{v_ball}; } }
  dx += dd;
EndFor

For i In {1:4}
  Translate{0, dy, 0} { Duplicata{ Volume{13:17:1}; } }
  dy += dd;
EndFor

For i In {1:4}
  Translate{0, 0, dz} { Duplicata{ Volume{13:37:1}; } }
  dz += dd;
EndFor

// Boolean
v() = BooleanDifference{Volume{v_in}; Delete;}{Volume{v_ball(),13:137:1}; Delete;};

//
Physical Volume ("fluid") = {v()};
Physical Surface ("particle") = {7:131:1};

Mesh.ScalingFactor = 0.001;

Mesh.FirstNodeTag = 1;
Mesh.FirstElementTag = 1;
Mesh.Algorithm = 5;
Mesh.Algorithm3D = 1;
Mesh.CharacteristicLengthMax = lc/20;
Mesh.CharacteristicLengthMin = lc;
Mesh.OptimizeNetgen = 1;
Mesh.SaveAll=1;
