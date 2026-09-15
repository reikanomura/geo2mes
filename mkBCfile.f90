program mkBCfile
implicit none
integer :: i, j, k, n, m
integer :: argc, arg_int
integer :: iostat, nsurface
integer :: node, nedge, nelem2, ibc
integer, allocatable :: surface(:),ntag(:), nbc(:)
integer, allocatable :: nc2(:,:) 
double precision, allocatable :: xy(:,:)
character(20) :: line, string
character(20) :: basename, listfile, inpmesfile, outbcfile

argc = command_argument_count()
call get_command_argument(1, basename)
!call get_command_argument(2, listfile)

listfile = trim(adjustl(basename))//'.tag'

open(10, file=trim(adjustl(listfile)), status='old', action='read')
  nsurface = 0
  do while (.true.)
     read(10,*, iostat=iostat) line
     if (iostat /= 0) exit
     nsurface = nsurface + 1
  end do
close(10)
write(6,*) nsurface

allocate(surface(nsurface))
open(10, file=trim(adjustl(listfile)), status='old', action='read')
  do i = 1, nsurface
     read(10,*) surface(i)
  end do
close(10)

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
       do i = 1, nedge
         read(10,*) line
       end do

     case('Triangles')

        read(10,*) nelem2
        allocate(nc2(3,nelem2),ntag(nelem2))
        do m = 1, nelem2
          read(10,*) (nc2(j,m), j = 1, 3), ntag(m)
        end do
        exit

      case default
       write(6,'(a)') 'Error: unexpected argumentations in .mesh file'
       stop
     end select

end do

write(6,*) maxval(ntag), minval(ntag)
allocate(nbc(node))
nbc = 0

do m = 1, nelem2

  do i = 1, nsurface
    if (ntag(m) .eq. surface(i))then
      nbc(nc2(1,m)) = 1 
      nbc(nc2(2,m)) = 1
      nbc(nc2(3,m)) = 1
    end if
  end do
end do


outbcfile = trim(adjustl(basename))//'-bc.txt'
write(6,*) outbcfile
ibc = sum(nbc)

open(20, file=outbcfile, status='replace')
write(20,*) ibc
do n = 1, node
  if (nbc(n) .eq. 1) write(20,*) n
end do
close(20)

!
!
end program
