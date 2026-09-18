program mkBCfile
  ! ============================================================
  ! mkBCfile : gmsh .mesh ファイルから境界条件節点を抽出する
  !
  ! 使い方:
  !   ./mkBCfile.exe <ファイル名>.mesh --dim <次元数>
  !
  !   --dim 2 : 2次元メッシュ → Edges セクション(Line ID)から抽出
  !   --dim 3 : 3次元メッシュ → Triangles セクション(Surface ID)から抽出
  !
  !   ・<ファイル名>.mesh は位置引数（どの順序でも可）
  !   ・--dim はどの位置に置いても認識する
  !
  ! タグリストファイル: <ベース名>.tag
  !   抽出したいID番号を1行1つずつ記述する
  !
  ! 出力ファイル: <ベース名>-bc.txt
  !   1行目: 抽出節点数
  !   2行目以降: 節点番号
  ! ============================================================
  implicit none

  integer :: i, j, k, n, m
  integer :: iostat, nsurface
  integer :: node, nedge, nelem2, ibc, ndim
  integer :: n1, n2, n3, itag
  integer, allocatable :: surface(:), ntag_e(:), ntag_t(:), nbc(:)
  integer, allocatable :: nc_edge(:,:)   ! (2, nedge)  Edge connectivity
  integer, allocatable :: nc2(:,:)       ! (3, nelem2) Triangle connectivity
  double precision, allocatable :: xy(:,:)
  character(256) :: line, string
  character(256) :: basename, listfile, inpmesfile, outbcfile
  character(256) :: arg, argval
  integer :: argc, iarg
  logical :: found_dim, found_file

  ! --------------------------------------------------------
  ! コマンドライン引数の解析
  !   書式: ./mkBCfile.exe <ファイル名>.mesh --dim <次元数>
  !   ・<ファイル名>.mesh : --dim 以外の引数をファイル名として扱う
  !   ・--dim             : 次の引数を次元数として読む
  ! --------------------------------------------------------
  argc = command_argument_count()
  found_dim  = .false.
  found_file = .false.
  ndim = 0
  basename = ''

  iarg = 1
  do while (iarg <= argc)
    call get_command_argument(iarg, arg)

    if (trim(adjustl(arg)) == '--dim') then
      ! --dim の次の引数を次元数として読む
      iarg = iarg + 1
      if (iarg > argc) then
        write(6,'(a)') 'Error: --dim の後に次元数がありません'
        stop
      end if
      call get_command_argument(iarg, argval)
      read(argval, *, iostat=iostat) ndim
      if (iostat /= 0) then
        write(6,'(a,a)') 'Error: --dim の値が不正です: ', trim(argval)
        stop
      end if
      found_dim = .true.

    else
      ! -- で始まらない引数をファイル名として扱う
      basename = trim(adjustl(arg))
      k = len_trim(basename)
      if (k > 5) then
        if (basename(k-4:k) == '.mesh') basename = basename(1:k-5)
      end if
      found_file = .true.
    end if

    iarg = iarg + 1
  end do

  ! 引数チェック
  if (.not. found_file) then
    write(6,'(a)') 'Error: .mesh ファイルが指定されていません'
    write(6,'(a)') '使い方: ./mkBCfile.exe <ファイル名>.mesh --dim 2'
    stop
  end if
  if (.not. found_dim) then
    write(6,'(a)') 'Error: --dim <次元数> が指定されていません (2 または 3)'
    write(6,'(a)') '使い方: ./mkBCfile.exe <ファイル名>.mesh --dim 2'
    stop
  end if
  if (ndim /= 2 .and. ndim /= 3) then
    write(6,'(a,i0)') 'Error: --dim には 2 または 3 を指定してください. 入力値: ', ndim
    stop
  end if

  write(6,'(a,i0)')   '次元数  : ', ndim
  write(6,'(a,a)')    'ベース名: ', trim(basename)

  ! --------------------------------------------------------
  ! タグリストファイル (.tag) の読み込み
  ! --------------------------------------------------------
  listfile = trim(adjustl(basename))//'.tag'
  open(10, file=trim(listfile), status='old', action='read', iostat=iostat)
  if (iostat /= 0) then
    write(6,'(a,a)') 'Error: タグリストファイルが開けません: ', trim(listfile)
    stop
  end if
  nsurface = 0
  do while (.true.)
    read(10, *, iostat=iostat) line
    if (iostat /= 0) exit
    nsurface = nsurface + 1
  end do
  close(10)
  write(6,'(a,i0)') '抽出ID数: ', nsurface

  allocate(surface(nsurface))
  open(10, file=trim(listfile), status='old', action='read')
  do i = 1, nsurface
    read(10, *) surface(i)
  end do
  close(10)
  write(6,'(a)', advance='no') '抽出ID  : '
  do i = 1, nsurface
    write(6,'(i0,1x)', advance='no') surface(i)
  end do
  write(6,*)

  ! --------------------------------------------------------
  ! .mesh ファイルのオープンとヘッダ読み込み
  ! --------------------------------------------------------
  inpmesfile = trim(adjustl(basename))//'.mesh'
  write(6,'(a,a)') '入力ファイル: ', trim(inpmesfile)

  open(10, file=trim(inpmesfile), status='old', action='read', iostat=iostat)
  if (iostat /= 0) then
    write(6,'(a,a)') 'Error: .mesh ファイルが開けません: ', trim(inpmesfile)
    stop
  end if

  ! ヘッダ 4行 (MeshVersionFormatted / Dimension / 数値 / Vertices)
  do i = 1, 4
    read(10, '(A)', iostat=iostat) line
    if (iostat /= 0) then
      write(6,'(a,i0)') 'Error: .mesh ファイルのヘッダ読み込み失敗, 行: ', i
      stop
    end if
  end do

  ! 節点数と座標の読み込み
  read(10, *) node
  write(6,'(a,i0)') '節点数  : ', node
  allocate(xy(3, node))
  do n = 1, node
    read(10, *) (xy(j, n), j = 1, 3)
  end do

  ! --------------------------------------------------------
  ! セクションのスキャン
  ! --------------------------------------------------------
  allocate(nbc(node))
  nbc = 0

  do while (.true.)
    read(10, '(a)', iostat=iostat) string
    if (iostat /= 0) exit
    string = trim(adjustl(string))
    if (len_trim(string) == 0) cycle

    select case(trim(string))

      ! ---- Edges セクション (Line ID → 2次元BC抽出に使用) ----
      case('Edges')
        read(10, *) nedge
        write(6,'(a,i0)') 'Edge数  : ', nedge
        allocate(nc_edge(2, nedge), ntag_e(nedge))
        do m = 1, nedge
          read(10, *) nc_edge(1,m), nc_edge(2,m), ntag_e(m)
        end do

        if (ndim == 2) then
          write(6,'(a)') '2次元モード: Edges から節点を抽出します'
          write(6,'(a,i0,a,i0)') &
            '  Line ID範囲: ', minval(ntag_e), ' - ', maxval(ntag_e)
          do m = 1, nedge
            do i = 1, nsurface
              if (ntag_e(m) == surface(i)) then
                nbc(nc_edge(1,m)) = 1
                nbc(nc_edge(2,m)) = 1
              end if
            end do
          end do
        end if

      ! ---- Triangles セクション (Surface ID → 3次元BC抽出に使用) ----
      case('Triangles')
        read(10, *) nelem2
        write(6,'(a,i0)') '三角形数: ', nelem2
        allocate(nc2(3, nelem2), ntag_t(nelem2))
        do m = 1, nelem2
          read(10, *) (nc2(j,m), j = 1, 3), ntag_t(m)
        end do

        if (ndim == 3) then
          write(6,'(a)') '3次元モード: Triangles から節点を抽出します'
          write(6,'(a,i0,a,i0)') &
            '  Surface ID範囲: ', minval(ntag_t), ' - ', maxval(ntag_t)
          do m = 1, nelem2
            do i = 1, nsurface
              if (ntag_t(m) == surface(i)) then
                nbc(nc2(1,m)) = 1
                nbc(nc2(2,m)) = 1
                nbc(nc2(3,m)) = 1
              end if
            end do
          end do
        end if

      case('End')
        exit

      case default
        ! Tetrahedra など他のセクションはスキップ
        read(10, *) n1   ! 要素数を読み飛ばし
        do m = 1, n1
          read(10, '(a)', iostat=iostat) line
          if (iostat /= 0) exit
        end do

    end select
  end do
  close(10)

  ! --------------------------------------------------------
  ! 出力
  ! --------------------------------------------------------
  outbcfile = trim(adjustl(basename))//'-bc.txt'
  ibc = sum(nbc)
  write(6,'(a,i0)') '抽出節点数: ', ibc
  write(6,'(a,a)')  '出力ファイル: ', trim(outbcfile)

  open(20, file=trim(outbcfile), status='replace')
  write(20, '(i0)') ibc
  do n = 1, node
    if (nbc(n) == 1) write(20, '(i0)') n
  end do
  close(20)

  write(6,'(a)') '完了'

end program mkBCfile
