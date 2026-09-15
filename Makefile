.SUFFIXES :
.SUFFIXES : .o .f90
FC      = gfortran
PROG1    = ~/.gmsh/MESH2MES
PROG2    = ~/.gmsh/mkBCfile

SRC1     = MESHtoMES.f90 
SRC2 	 = mkBCfile.f90

OBJS1 = $(SRC1:%.f90=%.o)
OBJS2 = $(SRC2:%.f90=%.o)

.f90.o:
	$(FC) $(FFLAGS) $(FFLIB) -c $< -o $@
#
all:$(OBJS1) $(OBJS2)
	$(FC) $(OBJS1) $(FFLAGS) $(FFLIB) -o $(PROG1)
	$(FC) $(OBJS2) $(FFLAGS) $(FFLIB) -o $(PROG2)
#
clean:
	@rm -rf *.exe *.o *.mod *~ $(UNAME)

