program MESHtoMES

  implicit none
  integer :: ndim, nen
  integer :: argc, arg_int

  character(20) :: basename, arg_value
  character(20) :: etype, message

argc = command_argument_count()

if (argc .eq. 2) then

  call get_command_argument(1, arg_value)
  call get_command_argument(2, basename)

  read(arg_value, *) ndim

  select case(ndim)

    case(2) ! 2-D meshing
        write(6,*) 'Press 3 or 4'
        write(6,*) '3: 3-nodes Triangles'
        write(6,*) '4: 4-nodes Quadrangles'
        read(5,*) nen

        if (nen .eq. 3) then
          etype = 'Triangles'
        else if(nen .eq. 4) then
          etype = 'Quadrilaterals'
        else
          write(6,*) 'Error: Invalid integer number'
          stop
        end if

    case(3) ! 3-D meshing
        write(6,*) 'Press 4 or 6'
        write(6,*) '4: 4-nodes Tetrahedra'
        write(6,*) '6: 6-nodes Hexahedra'
        read(5,*) nen

        if (nen .eq. 4) then
          etype = 'Tetrahedra'
        else if(nen .eq. 6) then
          etype = 'Hexahedra'
        else
          write(6,*) 'Error: Invalid integer number'
          stop
        end if

    case default
        write(6,*) 'Error: Invalid dimention number'
        write(6,*) '2 or 3 must be choosen'
        stop

  end select

  write(message,'(i1,a3)') ndim, '-D '
  write(6,*) message, etype, ' meshing'

  call read_meshfile(basename, ndim, nen,etype)

else

  write(6,*) 'Error: No arguments provided'
  write(6,*) 'Input ff you have 3D test.mesh file'
  write(6,*) '$./MESH2MES <dimention> <filename w/o extention>'
  stop

end if


end program

!------------------------------------------------
subroutine read_meshfile(basename, ndim, nen, etype)
!------------------------------------------------
implicit none
integer,intent(in) :: ndim, nen
character(20), intent(in) :: basename, etype
integer :: edge1, edge2

integer :: i, j, n, m
integer :: iostat
integer :: node, nelem, node2, nelem2, nedge
integer, allocatable :: nc(:,:), nc2(:,:), ntag(:)
integer, allocatable :: bc(:)
double precision, allocatable :: xy(:,:)
character(20) :: string, line
character(50) :: inpmesfile, outmesfile, outmesbinfile, tagfile

  inpmesfile = trim(adjustl(basename))//'.mesh'
  write(6,*) inpmesfile

  open(10, file=inpmesfile, status='old', action='read')

   do i = 1, 4
     read(10,'(A)', iostat=iostat) line
     if (iostat /= 0) then
        write(6,*) "Error: Something wrong with .mesh file"
        write(6,*) "Line ", i
        exit
     end if
   end do

   read(10,*) node
   allocate(xy(3,node))
   do n = 1, node
     read(10,*) (xy(j,n), j = 1, 3)
   end do

   do while (.true.)
      read(10,'(a)', iostat=iostat) string
      if (iostat /= 0)then
        exit
      end if

      select case(trim(adjustl(string)))
        case('Edges')
          read(10,*) nedge
          write(6,*) 'Edge info'
          allocate(bc(node))
          bc(:) = 0

          do i = 1, nedge
            read(10,*) edge1, edge2
            bc(edge1) = 1
            bc(edge2) = 1
          end do

        case('Triangles')

          read(10,*) nelem2
          allocate(nc2(3,nelem2),ntag(nelem2))
          do m = 1, nelem2
            read(10,*) (nc2(j,m), j = 1, 3), ntag(m)
          end do

        case('Quadrilaterals')
           read(10,*) nelem2
           allocate(nc2(4,nelem2),ntag(nelem2))
           do m = 1, nelem2
             read(10,*) (nc2(j,m), j = 1, 4)
           end do

        case('Tetrahedra')
           write(6,'(a)') '4-node Tetra'
           read(10,*) nelem
           allocate(nc(4,nelem))
           do m = 1, nelem
             read(10,*) (nc(j,m), j = 1, 4)
           end do

           call vol_check(node, nelem, nc, xy)

         case('End')
          write(6,'(a)') 'Done reading mesh file'
          exit

         case default
          write(6,'(a)') 'Error: unexpected argumentations in .mesh file'
          stop
        end select

   end do

close(10)


if (ndim .eq. 2) then
   if (nen .eq. 3) call nc_renum(node, nelem2, nc2, xy)

   outmesfile = trim(adjustl(basename))//'.mes'
   open(30, file=outmesfile, status='replace')
     write(30,*) node, nelem2
     do i  =  1, node
       write(30,'(i10,3E21.12)') i, (xy(j,i), j= 1, 3)
     end do
     do i = 1, nelem2
       write(30,*) i, nen, (nc2(j,i), j = 1, nen)
     end do
   close(30)

else if (ndim .eq. 3) then

   outmesbinfile = trim(adjustl(basename))//'-mesh.bin'

   if (etype.eq.'Tetrahedra') then
     open(20, file=outmesbinfile, status='replace', form='unformatted')
       write(20) node, nelem
       write(20) ((xy(j,i), j= 1, 3), i = 1, node)
       write(20) ((nc(j,i), j = 1, 4), i = 1, nelem)
     close(20)

   end if

end if

end subroutine

!------------------------------------------------
subroutine vol_check(node, nelem, nc, xy)
!------------------------------------------------
implicit none
integer, intent(in) :: node, nelem, nc(4,nelem)
double precision, intent(in) :: xy(3,node)

integer :: m
double precision :: x1, x2, x3, x4, y1, y2, y3, y4, z1, z2, z3, z4
double precision :: a11, a12, a13, a21, a22, a23, a31, a32, a33
double precision :: vol06
integer :: n1, n2, n3, n4

do m = 1, nelem
  n1 = nc(1,m)
  n2 = nc(2,m)
  n3 = nc(3,m)
  n4 = nc(4,m)

  x1 = xy(1,n1)
  x2 = xy(1,n2)
  x3 = xy(1,n3)
  x4 = xy(1,n4)

  y1 = xy(2,n1)
  y2 = xy(2,n2)
  y3 = xy(2,n3)
  y4 = xy(2,n4)

  z1 = xy(3,n1)
  z2 = xy(3,n2)
  z3 = xy(3,n3)
  z4 = xy(3,n4)

  a11 = x2 - x1
  a12 = x3 - x1
  a13 = x4 - x1
  a21 = y2 - y1
  a22 = y3 - y1
  a23 = y4 - y1
  a31 = z2 - z1
  a32 = z3 - z1
  a33 = z4 - z1

  vol06  = a11 * a22 * a33 + a21 * a32 * a13 &
         + a31 * a12 * a23 - a11 * a32 * a23 &
         - a31 * a22 * a13 - a21 * a12 * a33


  if(vol06 .le. 0.0) then
    write(6,*)'VOLUME <= 0.0', vol06,   'elem No.=',m
    stop
  end if
end do

end subroutine

! ---------------------------------------------------------------------
subroutine nc_renum(node, nelem, nc, xy)
! ---------------------------------------------------------------------
implicit none
integer, intent(in) :: node, nelem
integer, intent(inout) :: nc(3,nelem)
double precision, intent(in) :: xy(3,node)

integer :: m
integer :: n1, n2, n3
double precision :: x1, x2, x3, y1, y2, y3, a02, area


do m = 1, nelem
  x1 = xy(1,nc(1,m))
  x2 = xy(1,nc(2,m))
  x3 = xy(1,nc(3,m))
  y1 = xy(2,nc(1,m))
  y2 = xy(2,nc(2,m))
  y3 = xy(2,nc(3,m))
  a02 = x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)
  area = a02 * 0.5d0
  if(area .le. 0.0d0) then
    n1 = nc(1,m)
    n2 = nc(2,m)
    n3 = nc(3,m)
    nc(1,m) = n1
    nc(2,m) = n3
    nc(3,m) = n2
  end if
end do

end subroutine
