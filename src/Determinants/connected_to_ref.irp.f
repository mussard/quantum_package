integer*8 function det_search_key(det,Nint)
  use bitmasks
  implicit none
  BEGIN_DOC
! Return an integer*8 corresponding to a determinant index for searching
  END_DOC
  integer, intent(in) :: Nint
  integer(bit_kind), intent(in) :: det(Nint,2)
  integer :: i
  det_search_key = iand(det(1,1),det(1,2))
  do i=2,Nint
    det_search_key = ieor(det_search_key,iand(det(i,1),det(i,2)))
  enddo
  det_search_key = iand(huge(det(1,1)),det_search_key)
end


integer*8 function occ_pattern_search_key(det,Nint)
  use bitmasks
  implicit none
  BEGIN_DOC
! Return an integer*8 corresponding to a determinant index for searching
  END_DOC
  integer, intent(in) :: Nint
  integer(bit_kind), intent(in) :: det(Nint,2)
  integer :: i
  occ_pattern_search_key = ieor(det(1,1),det(1,2))
  do i=2,Nint
    occ_pattern_search_key = ieor(occ_pattern_search_key,iand(det(i,1),det(i,2)))
  enddo
  occ_pattern_search_key = iand(huge(det(1,1)),occ_pattern_search_key)
end



logical function is_in_wavefunction(key,Nint)
  use bitmasks
  implicit none
  BEGIN_DOC
! True if the determinant ``det`` is in the wave function
  END_DOC
  integer, intent(in)            :: Nint
  integer(bit_kind), intent(in)  :: key(Nint,2)
  integer, external              :: get_index_in_psi_det_sorted_bit

  !DIR$ FORCEINLINE
  is_in_wavefunction = get_index_in_psi_det_sorted_bit(key,Nint) > 0
end

integer function get_index_in_psi_det_sorted_bit(key,Nint)
  use bitmasks
  BEGIN_DOC
! Returns the index of the determinant in the ``psi_det_sorted_bit`` array
  END_DOC
  implicit none

  integer, intent(in)            :: Nint
  integer(bit_kind), intent(in)  :: key(Nint,2)

  integer                        :: i, ibegin, iend, istep, l
  integer*8                      :: det_ref, det_search
  integer*8, external            :: det_search_key
  logical                        :: in_wavefunction
  
  in_wavefunction = .False.
  get_index_in_psi_det_sorted_bit = 0
  ibegin = 1
  iend   = N_det+1
  
  !DIR$ FORCEINLINE
  det_ref = det_search_key(key,Nint)
  !DIR$ FORCEINLINE
  det_search = det_search_key(psi_det_sorted_bit(1,1,1),Nint)
  
  istep = ishft(iend-ibegin,-1)
  i=ibegin+istep
  do while (istep > 0)
    !DIR$ FORCEINLINE
    det_search = det_search_key(psi_det_sorted_bit(1,1,i),Nint)
    if ( det_search > det_ref ) then
      iend = i
    else if ( det_search == det_ref ) then
      exit
    else
      ibegin = i
    endif
    istep = ishft(iend-ibegin,-1)
    i = ibegin + istep 
  end do

  !DIR$ FORCEINLINE
  do while (det_search_key(psi_det_sorted_bit(1,1,i),Nint) == det_ref)
    i = i-1
    if (i == 0) then
      exit
    endif
  enddo

  if (i >= N_det) then
    return
  endif

  i += 1

  !DIR$ FORCEINLINE
  do while (det_search_key(psi_det_sorted_bit(1,1,i),Nint) == det_ref)
    if ( (key(1,1) /= psi_det_sorted_bit(1,1,i)).or.                               &
          (key(1,2) /= psi_det_sorted_bit(1,2,i)) ) then
      continue
    else
      in_wavefunction = .True.
      do l=2,Nint
        if ( (key(l,1) /= psi_det_sorted_bit(l,1,i)).or.                           &
              (key(l,2) /= psi_det_sorted_bit(l,2,i)) ) then
          in_wavefunction = .False.
        endif
      enddo
      if (in_wavefunction) then
        get_index_in_psi_det_sorted_bit = i
!        exit
        return
      endif
    endif
    i += 1
    if (i > N_det) then
!      exit
      return
    endif
    
  enddo

! DEBUG is_in_wf
! if (in_wavefunction) then
!   degree = 1
!   do i=1,N_det
!     integer                        :: degree
!     call get_excitation_degree(key,psi_det(1,1,i),degree,N_int)
!     if (degree == 0) then
!       exit
!     endif
!   enddo
!   if (degree /=0) then
!     stop 'pouet 1'
!   endif
! else
!   do i=1,N_det
!     call get_excitation_degree(key,psi_det(1,1,i),degree,N_int)
!     if (degree == 0) then
!       stop 'pouet 2'
!     endif
!   enddo
! endif
! END DEBUG is_in_wf
end


logical function is_connected_to(key,keys,Nint,Ndet)
  use bitmasks
  implicit none
  integer, intent(in)            :: Nint, Ndet
  integer(bit_kind), intent(in)  :: keys(Nint,2,Ndet)
  integer(bit_kind), intent(in)  :: key(Nint,2)
  
  integer                        :: i, l
  integer                        :: degree_x2
  logical, external :: is_generable_cassd
  
  ASSERT (Nint > 0)
  ASSERT (Nint == N_int)
  
  is_connected_to = .false.

  do i=1,Ndet
    degree_x2 = popcnt(xor( key(1,1), keys(1,1,i))) +              &
        popcnt(xor( key(1,2), keys(1,2,i)))
    do l=2,Nint
      degree_x2 = degree_x2 + popcnt(xor( key(l,1), keys(l,1,i))) +&
          popcnt(xor( key(l,2), keys(l,2,i)))
    enddo
    if (degree_x2 > 4) then
      cycle
    else
!       if(.not. is_generable_cassd(keys(1,1,i), key(1,1), Nint)) cycle  !!!Nint==1 !!!!!
      is_connected_to = .true.
      return
    endif
  enddo
end


logical function is_generable_cassd(det1, det2, Nint) !!! TEST Cl HARD !!!!!
  use bitmasks
  implicit none
  integer, intent(in) :: Nint
  integer(bit_kind) :: det1(Nint, 2), det2(Nint, 2)
  integer :: degree, f, exc(0:2, 2, 2), h1, h2, p1, p2, s1, s2, t
  double precision :: phase
  
  is_generable_cassd = .false.
  call get_excitation(det1, det2, exc, degree, phase, Nint)
  if(degree == -1) return
  if(degree == 0) then
    is_generable_cassd = .true.
    return
  end if
  call decode_exc(exc,degree,h1,p1,h2,p2,s1,s2)
  if(degree == 1 .and. h1 <= 11) is_generable_cassd = .true.
  if(degree == 2 .and. h1 <= 11 .and. h2 <= 11) is_generable_cassd = .true.
end function


logical function is_connected_to_by_mono(key,keys,Nint,Ndet)
  use bitmasks
  implicit none
  integer, intent(in)            :: Nint, Ndet
  integer(bit_kind), intent(in)  :: keys(Nint,2,Ndet)
  integer(bit_kind), intent(in)  :: key(Nint,2)
  
  integer                        :: i, l
  integer                        :: degree_x2
  
  
  ASSERT (Nint > 0)
  ASSERT (Nint == N_int)
  
  is_connected_to_by_mono = .false.

  do i=1,Ndet
    degree_x2 = popcnt(xor( key(1,1), keys(1,1,i))) +              &
        popcnt(xor( key(1,2), keys(1,2,i)))
    do l=2,Nint
      degree_x2 = degree_x2 + popcnt(xor( key(l,1), keys(l,1,i))) +&
          popcnt(xor( key(l,2), keys(l,2,i)))
    enddo
    if (degree_x2 > 2) then
      cycle
    else
      is_connected_to_by_mono = .true.
      return
    endif
  enddo
end


integer function connected_to_ref(key,keys,Nint,N_past_in,Ndet)
  use bitmasks
  implicit none
  integer, intent(in)            :: Nint, N_past_in, Ndet
  integer(bit_kind), intent(in)  :: keys(Nint,2,Ndet)
  integer(bit_kind), intent(in)  :: key(Nint,2)
  
  integer                        :: N_past
  integer                        :: i, l
  integer                        :: degree_x2
  logical                        :: t
  double precision               :: hij_elec
  
  ! output :   0 : not connected
  !            i : connected to determinant i of the past
  !           -i : is the ith determinant of the reference wf keys
  
  ASSERT (Nint > 0)
  ASSERT (Nint == N_int)
  
  connected_to_ref = 0
  N_past = max(1,N_past_in)
  if (Nint == 1) then
    
    do i=N_past-1,1,-1
      degree_x2 = popcnt(xor( key(1,1), keys(1,1,i))) +              &
          popcnt(xor( key(1,2), keys(1,2,i)))
      if (degree_x2 > 4) then
        cycle
      else
        connected_to_ref = i
        return
      endif
    enddo
    
    return

    
  else if (Nint==2) then
    
    do i=N_past-1,1,-1
      degree_x2 = popcnt(xor( key(1,1), keys(1,1,i))) +              &
          popcnt(xor( key(1,2), keys(1,2,i))) +                      &
          popcnt(xor( key(2,1), keys(2,1,i))) +                      &
          popcnt(xor( key(2,2), keys(2,2,i)))
      if (degree_x2 > 4) then
        cycle
      else
        connected_to_ref = i
        return
      endif
    enddo
    
    return
    
  else if (Nint==3) then
    
    do i=N_past-1,1,-1
      degree_x2 = popcnt(xor( key(1,1), keys(1,1,i))) +              &
          popcnt(xor( key(1,2), keys(1,2,i))) +                      &
          popcnt(xor( key(2,1), keys(2,1,i))) +                      &
          popcnt(xor( key(2,2), keys(2,2,i))) +                      &
          popcnt(xor( key(3,1), keys(3,1,i))) +                      &
          popcnt(xor( key(3,2), keys(3,2,i)))
      if (degree_x2 > 4) then
        cycle
      else
        connected_to_ref = i
        return
      endif
    enddo
    
    return
    
  else
    
    do i=N_past-1,1,-1
      degree_x2 = popcnt(xor( key(1,1), keys(1,1,i))) +              &
          popcnt(xor( key(1,2), keys(1,2,i)))
      do l=2,Nint
        degree_x2 = degree_x2 + popcnt(xor( key(l,1), keys(l,1,i))) +&
            popcnt(xor( key(l,2), keys(l,2,i)))
        if (degree_x2 > 4) then
          exit
        endif
      enddo
      if (degree_x2 > 4) then
        cycle
      else
        connected_to_ref = i
        return
      endif
    enddo
    
  endif
  
end



integer function connected_to_ref_by_mono(key,keys,Nint,N_past_in,Ndet)
  use bitmasks
  implicit none
  integer, intent(in)            :: Nint, N_past_in, Ndet
  integer(bit_kind), intent(in)  :: keys(Nint,2,Ndet)
  integer(bit_kind), intent(in)  :: key(Nint,2)
  
  integer                        :: N_past
  integer                        :: i, l
  integer                        :: degree_x2
  logical                        :: t
  double precision               :: hij_elec
  
  ! output :   0 : not connected
  !            i : connected to determinant i of the past
  !           -i : is the ith determinant of the refernce wf keys
  
  ASSERT (Nint > 0)
  ASSERT (Nint == N_int)
  
  connected_to_ref_by_mono = 0
  N_past = max(1,N_past_in)
  if (Nint == 1) then
    
    do i=N_past-1,1,-1
      degree_x2 = popcnt(xor( key(1,1), keys(1,1,i))) +              &
          popcnt(xor( key(1,2), keys(1,2,i)))
      if (degree_x2 > 3.and. degree_x2 <5) then
        cycle
      else if (degree_x2 == 4)then
        cycle
      else if(degree_x2 == 2)then
        connected_to_ref_by_mono = i
        return
      endif
    enddo
    
    return

    
  else if (Nint==2) then
    
    do i=N_past-1,1,-1
      degree_x2 = popcnt(xor( key(1,1), keys(1,1,i))) +              &
          popcnt(xor( key(1,2), keys(1,2,i))) +                      &
          popcnt(xor( key(2,1), keys(2,1,i))) +                      &
          popcnt(xor( key(2,2), keys(2,2,i)))
      if (degree_x2 > 3.and. degree_x2 <5) then
        cycle
      else if (degree_x2 == 4)then
        cycle
      else if(degree_x2 == 2)then
        connected_to_ref_by_mono = i
        return
      endif
    enddo
    
    return
    
  else if (Nint==3) then
    
    do i=N_past-1,1,-1
      degree_x2 = popcnt(xor( key(1,1), keys(1,1,i))) +              &
          popcnt(xor( key(1,2), keys(1,2,i))) +                      &
          popcnt(xor( key(2,1), keys(2,1,i))) +                      &
          popcnt(xor( key(2,2), keys(2,2,i))) +                      &
          popcnt(xor( key(3,1), keys(3,1,i))) +                      &
          popcnt(xor( key(3,2), keys(3,2,i)))
      if (degree_x2 > 3.and. degree_x2 <5) then
        cycle
      else if (degree_x2 == 4)then
        cycle
      else if(degree_x2 == 2)then
        connected_to_ref_by_mono = i
        return
      endif
    enddo
    
    return
    
  else
    
    do i=N_past-1,1,-1
      degree_x2 = popcnt(xor( key(1,1), keys(1,1,i))) +              &
          popcnt(xor( key(1,2), keys(1,2,i)))
      do l=2,Nint
        degree_x2 = degree_x2 + popcnt(xor( key(l,1), keys(l,1,i))) +&
            popcnt(xor( key(l,2), keys(l,2,i)))
      enddo
      if (degree_x2 > 3.and. degree_x2 <5) then
        cycle
      else if (degree_x2 == 4)then
        cycle
      else if(degree_x2 == 2)then
        connected_to_ref_by_mono = i
        return
      endif
    enddo
    
  endif
  
end


