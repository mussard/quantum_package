
subroutine new_approach
  use bitmasks
 implicit none
 integer :: n_max_good_det
 n_max_good_det = n_inact_orb * n_act_orb *n_det_generators_restart + n_virt_orb * n_act_orb * n_det_generators_restart
 integer :: n_good_det,n_good_hole, n_good_particl
 n_good_det = 0
 n_good_hole = 0
 n_good_particl = 0
 integer(bit_kind), allocatable :: psi_good_det(:,:,:)
 double precision, allocatable :: dressing_restart_good_det(:,:)
 double precision, allocatable :: dressing_matrix_restart_1h1p(:,:)
 double precision, allocatable :: dressing_matrix_restart_2h1p(:,:)
 double precision, allocatable :: dressing_matrix_restart_1h2p(:,:)
 double precision, allocatable :: dressing_diag_good_det(:)

 double precision :: hjk

 integer :: i,j,k,l,i_hole_foboci
 logical :: test_sym
 double precision :: thr,hij
 double precision :: threshold,accu
 double precision, allocatable :: dressing_matrix_1h1p(:,:)
 double precision, allocatable :: dressing_matrix_2h1p(:,:)
 double precision, allocatable :: dressing_matrix_1h2p(:,:)
 double precision, allocatable :: dressing_matrix_extra_1h_or_1p(:,:)
 double precision, allocatable :: H_matrix_tmp(:,:)
 logical :: verbose,is_ok

 double precision,allocatable :: eigenvectors(:,:), eigenvalues(:)


 allocate(psi_good_det(N_int,2,n_max_good_det))
 allocate(dressing_restart_good_det(n_max_good_det,n_det_generators_restart))
 allocate(dressing_matrix_restart_1h1p(N_det_generators_restart, N_det_generators_restart))
 allocate(dressing_matrix_restart_2h1p(N_det_generators_restart, N_det_generators_restart))
 allocate(dressing_matrix_restart_1h2p(N_det_generators_restart, N_det_generators_restart))
 allocate(dressing_diag_good_det(n_max_good_det))

 dressing_restart_good_det = 0.d0
 dressing_matrix_restart_1h1p = 0.d0
 dressing_matrix_restart_2h1p = 0.d0
 dressing_matrix_restart_1h2p = 0.d0
 dressing_diag_good_det = 0.d0


 verbose = .True.
 threshold = threshold_singles
 print*,'threshold = ',threshold
 thr = 1.d-12
 print*,''
 print*,''
 print*,'mulliken spin population analysis'
 accu =0.d0
 do i = 1, nucl_num
  accu += mulliken_spin_densities(i)
  print*,i,nucl_charge(i),mulliken_spin_densities(i)
 enddo
 print*,''
 print*,''
 print*,'DOING FIRST LMCT !!'
 integer :: i_particl_osoci

 do i = 1, n_inact_orb
   i_hole_foboci = list_inact(i)
   print*,'--------------------------'
   ! First set the current generators to the one of restart
   call set_generators_to_generators_restart
   call set_psi_det_to_generators
   call check_symetry(i_hole_foboci,thr,test_sym)
   if(.not.test_sym)cycle
   print*,'i_hole_foboci = ',i_hole_foboci
   call create_restart_and_1h(i_hole_foboci)
!  ! Update the generators 
   call set_generators_to_psi_det
   call set_bitmask_particl_as_input(reunion_of_bitmask)
   call set_bitmask_hole_as_input(reunion_of_bitmask)
   call is_a_good_candidate(threshold,is_ok,verbose)
   print*,'is_ok = ',is_ok
   if(.not.is_ok)cycle
   ! so all the mono excitation on the new generators 
   allocate(dressing_matrix_1h1p(N_det_generators,N_det_generators))
   allocate(dressing_matrix_2h1p(N_det_generators,N_det_generators))
   allocate(dressing_matrix_extra_1h_or_1p(N_det_generators,N_det_generators))
   dressing_matrix_1h1p = 0.d0
   dressing_matrix_2h1p = 0.d0
   dressing_matrix_extra_1h_or_1p = 0.d0
   if(.not.do_it_perturbative)then
    n_good_hole +=1
!   call all_single_split_for_1h(dressing_matrix_1h1p,dressing_matrix_2h1p)
    call all_single_for_1h(i_hole_foboci,dressing_matrix_1h1p,dressing_matrix_2h1p,dressing_matrix_extra_1h_or_1p)
    allocate(H_matrix_tmp(N_det_generators,N_det_generators))
    do j = 1,N_det_generators
     do k = 1, N_det_generators
      call i_h_j(psi_det_generators(1,1,j),psi_det_generators(1,1,k),N_int,hjk)
      H_matrix_tmp(j,k) = hjk
     enddo
    enddo
    do j = 1, N_det_generators
     do k = 1, N_det_generators
      H_matrix_tmp(j,k) += dressing_matrix_1h1p(j,k) + dressing_matrix_2h1p(j,k) + dressing_matrix_extra_1h_or_1p(j,k)
     enddo
    enddo
    hjk = H_matrix_tmp(1,1)
    do j = 1, N_det_generators
      H_matrix_tmp(j,j) -= hjk
    enddo
    print*,'-----------------------'
    print*,'-----------------------'
    print*,'-----------------------'
    print*,'-----------------------'
    print*,'-----------------------'
    print*,'Dressed matrix :'
    do j = 1, N_det_generators
     write(*,'(100(X,F8.5))') H_matrix_tmp(j,:)
    enddo
    allocate(eigenvectors(N_det_generators,N_det_generators), eigenvalues(N_det_generators))
    call lapack_diag(eigenvalues,eigenvectors,H_matrix_tmp,N_det_generators,N_det_generators)
    print*,'Eigenvector of the dressed matrix :'
    do j = 1, N_det_generators
     print*,'coef = ',eigenvectors(j,1)
    enddo
    print*,'-----------------------'
    print*,'-----------------------'
    print*,'-----------------------'
    print*,'-----------------------'
    print*,'-----------------------'
    deallocate(eigenvectors, eigenvalues)
    deallocate(H_matrix_tmp)
    call update_dressing_matrix(dressing_matrix_1h1p,dressing_matrix_2h1p,dressing_restart_good_det,dressing_matrix_restart_1h1p, &
                                  dressing_matrix_restart_2h1p,dressing_diag_good_det,psi_good_det,n_good_det,n_max_good_det)
   endif
   deallocate(dressing_matrix_1h1p)
   deallocate(dressing_matrix_2h1p)
   deallocate(dressing_matrix_extra_1h_or_1p)
 enddo
 
 print*,''
 print*,''
 print*,'DOING THEN THE MLCT !!'
 do i = 1, n_virt_orb
   i_particl_osoci = list_virt(i)
   print*,'--------------------------'
   ! First set the current generators to the one of restart
   call set_generators_to_generators_restart
   call set_psi_det_to_generators
   call check_symetry(i_particl_osoci,thr,test_sym)
   if(.not.test_sym)cycle
   print*,'i_part_foboci = ',i_particl_osoci
   call create_restart_and_1p(i_particl_osoci)
   ! Update the generators 
   call set_generators_to_psi_det
   call set_bitmask_particl_as_input(reunion_of_bitmask)
   call set_bitmask_hole_as_input(reunion_of_bitmask)
   call is_a_good_candidate(threshold,is_ok,verbose)
   print*,'is_ok = ',is_ok
   if(.not.is_ok)cycle
   ! so all the mono excitation on the new generators 
   allocate(dressing_matrix_1h1p(N_det_generators,N_det_generators))
   allocate(dressing_matrix_1h2p(N_det_generators,N_det_generators))
   allocate(dressing_matrix_extra_1h_or_1p(N_det_generators,N_det_generators))
   dressing_matrix_1h1p = 0.d0
   dressing_matrix_1h2p = 0.d0
   dressing_matrix_extra_1h_or_1p = 0.d0
   if(.not.do_it_perturbative)then
    n_good_hole +=1
!   call all_single_split_for_1p(dressing_matrix_1h1p,dressing_matrix_1h2p)
    call all_single_for_1p(i_particl_osoci,dressing_matrix_1h1p,dressing_matrix_1h2p,dressing_matrix_extra_1h_or_1p)
    allocate(H_matrix_tmp(N_det_generators,N_det_generators))
    do j = 1,N_det_generators
     do k = 1, N_det_generators
      call i_h_j(psi_det_generators(1,1,j),psi_det_generators(1,1,k),N_int,hjk)
      H_matrix_tmp(j,k) = hjk
     enddo
    enddo
    do j = 1, N_det_generators
     do k = 1, N_det_generators
      H_matrix_tmp(j,k) += dressing_matrix_1h1p(j,k) + dressing_matrix_1h2p(j,k) + dressing_matrix_extra_1h_or_1p(j,k)
     enddo
    enddo
    hjk = H_matrix_tmp(1,1)
    do j = 1, N_det_generators
      H_matrix_tmp(j,j) -= hjk
    enddo
    print*,'-----------------------'
    print*,'-----------------------'
    print*,'-----------------------'
    print*,'-----------------------'
    print*,'-----------------------'
    print*,'Dressed matrix :'
    do j = 1, N_det_generators
     write(*,'(100(F8.5))') H_matrix_tmp(j,:)
    enddo
    allocate(eigenvectors(N_det_generators,N_det_generators), eigenvalues(N_det_generators))
    call lapack_diag(eigenvalues,eigenvectors,H_matrix_tmp,N_det_generators,N_det_generators)
    print*,'Eigenvector of the dressed matrix :'
    do j = 1, N_det_generators
     print*,'coef = ',eigenvectors(j,1)
    enddo
    print*,'-----------------------'
    print*,'-----------------------'
    print*,'-----------------------'
    print*,'-----------------------'
    print*,'-----------------------'
    deallocate(eigenvectors, eigenvalues)
    deallocate(H_matrix_tmp)
    call update_dressing_matrix(dressing_matrix_1h1p,dressing_matrix_1h2p,dressing_restart_good_det,dressing_matrix_restart_1h1p, &
                                  dressing_matrix_restart_1h2p,dressing_diag_good_det,psi_good_det,n_good_det,n_max_good_det)

   endif
   deallocate(dressing_matrix_1h1p)
   deallocate(dressing_matrix_1h2p)
   deallocate(dressing_matrix_extra_1h_or_1p)
 enddo
 double precision, allocatable :: H_matrix_total(:,:)
 integer :: n_det_total
 n_det_total = N_det_generators_restart + n_good_det
 allocate(H_matrix_total(n_det_total, n_det_total))
 ! Building of the effective Hamiltonian   
 ! We assume that the first determinants are the n_det_generators_restart ones
 ! and then come the n_good_det determinants in psi_good_det
 H_matrix_total = 0.d0
 do i = 1, N_det_generators_restart
  do j = 1, N_det_generators_restart
   call i_H_j(psi_det_generators_restart(1,1,i),psi_det_generators_restart(1,1,j),N_int,hij)
   H_matrix_total(i,j) = hij
   !!! Adding the averaged dressing coming from the 1h1p that are redundant for each of the "n_good_hole" 1h
   H_matrix_total(i,j) += dressing_matrix_restart_1h1p(i,j)/dble(n_good_hole+n_good_particl)  
   !!! Adding the dressing coming from the 2h1p that are not redundant for the any of CI calculations
   H_matrix_total(i,j) += dressing_matrix_restart_2h1p(i,j) + dressing_matrix_restart_1h2p(i,j)
  enddo
 enddo
 do i = 1, n_good_det
  call i_H_j(psi_good_det(1,1,i),psi_good_det(1,1,i),N_int,hij)
  !!! Adding the diagonal dressing coming from the singles 
  H_matrix_total(n_det_generators_restart+i,n_det_generators_restart+i) = hij + dressing_diag_good_det(i) 
  do j = 1, N_det_generators_restart
   !!! Adding the extra diagonal dressing between the references and the singles
   print*,' dressing_restart_good_det = ',dressing_restart_good_det(i,j)
   call i_H_j(psi_good_det(1,1,i),psi_det_generators_restart(1,1,j),N_int,hij)
   H_matrix_total(n_det_generators_restart+i,j) += hij
   H_matrix_total(j,n_det_generators_restart+i) += hij
   H_matrix_total(j,n_det_generators_restart+i) += dressing_restart_good_det(i,j)
   H_matrix_total(n_det_generators_restart+i,j) += dressing_restart_good_det(i,j)
  enddo
  do j = i+1, n_good_det
   !!! Building the naked Hamiltonian matrix between the singles 
   call i_H_j(psi_good_det(1,1,i),psi_good_det(1,1,j),N_int,hij)
   H_matrix_total(n_det_generators_restart+i,n_det_generators_restart+j) = hij 
   H_matrix_total(n_det_generators_restart+j,n_det_generators_restart+i) = hij 
  enddo
 enddo
 print*,'H matrix to diagonalize'
 double precision :: href
 href = H_matrix_total(1,1)
 do i = 1, n_det_total
  H_matrix_total(i,i) -= href
 enddo
 do i = 1, n_det_total
   write(*,'(100(X,F16.8))')H_matrix_total(i,:)
 enddo
 double precision, allocatable :: eigvalues(:),eigvectors(:,:)
 allocate(eigvalues(n_det_total),eigvectors(n_det_total,n_det_total))
 call lapack_diag(eigvalues,eigvectors,H_matrix_total,n_det_total,n_det_total)
 print*,'e_dressed  = ',eigvalues(1) + nuclear_repulsion + href
 do i = 1, n_det_total
  print*,'coef = ',eigvectors(i,1)
 enddo
 integer(bit_kind), allocatable :: psi_det_final(:,:,:)
 double precision, allocatable :: psi_coef_final(:,:)
 double precision :: norm
 allocate(psi_coef_final(n_det_total, N_states))
 allocate(psi_det_final(N_int,2,n_det_total))
 do i = 1, N_det_generators_restart
  do j = 1,N_int 
   psi_det_final(j,1,i) = psi_det_generators_restart(j,1,i)
   psi_det_final(j,2,i) = psi_det_generators_restart(j,2,i)
  enddo
 enddo
 do i = 1, n_good_det
  do j = 1,N_int 
   psi_det_final(j,1,n_det_generators_restart+i) = psi_good_det(j,1,i)
   psi_det_final(j,2,n_det_generators_restart+i) = psi_good_det(j,2,i)
  enddo
 enddo
 norm = 0.d0
 do i = 1, n_det_total
  do j = 1, N_states
   psi_coef_final(i,j) = eigvectors(i,j)
  enddo
  norm += psi_coef_final(i,1)**2
! call debug_det(psi_det_final(1, 1, i), N_int)
 enddo
 print*,'norm = ',norm
  
 call set_psi_det_as_input_psi(n_det_total,psi_det_final,psi_coef_final)
 print*,''
!do i = 1, N_det
!  call debug_det(psi_det(1,1,i),N_int)
!  print*,'coef = ',psi_coef(i,1)
!enddo
 provide one_body_dm_mo

 integer :: i_core,iorb,jorb,i_inact,j_inact,i_virt,j_virt,j_core
 do i = 1, n_core_orb
  i_core = list_core(i)
  one_body_dm_mo(i_core,i_core) = 10.d0
  do j = i+1, n_core_orb
   j_core = list_core(j)
   one_body_dm_mo(i_core,j_core) = 0.d0
   one_body_dm_mo(j_core,i_core) = 0.d0
  enddo
  do j = 1, n_inact_orb
   iorb = list_inact(j)
   one_body_dm_mo(i_core,iorb) = 0.d0
   one_body_dm_mo(iorb,i_core) = 0.d0
  enddo
  do j = 1, n_act_orb
   iorb = list_act(j)
   one_body_dm_mo(i_core,iorb) = 0.d0
   one_body_dm_mo(iorb,i_core) = 0.d0
  enddo
  do j = 1, n_virt_orb
   iorb = list_virt(j)
   one_body_dm_mo(i_core,iorb) = 0.d0
   one_body_dm_mo(iorb,i_core) = 0.d0
  enddo
 enddo
 ! Set to Zero the inact-inact part to avoid arbitrary rotations
 do i = 1, n_inact_orb
  i_inact = list_inact(i)
  do j = i+1, n_inact_orb 
   j_inact = list_inact(j)
   one_body_dm_mo(i_inact,j_inact) = 0.d0
   one_body_dm_mo(j_inact,i_inact) = 0.d0
  enddo
 enddo

 ! Set to Zero the inact-virt part to avoid arbitrary rotations
 do i = 1, n_inact_orb
  i_inact = list_inact(i)
  do j = 1, n_virt_orb 
   j_virt = list_virt(j)
   one_body_dm_mo(i_inact,j_virt) = 0.d0
   one_body_dm_mo(j_virt,i_inact) = 0.d0
  enddo
 enddo

 ! Set to Zero the virt-virt part to avoid arbitrary rotations
 do i = 1, n_virt_orb
  i_virt = list_virt(i)
  do j = i+1, n_virt_orb 
   j_virt = list_virt(j)
   one_body_dm_mo(i_virt,j_virt) = 0.d0
   one_body_dm_mo(j_virt,i_virt) = 0.d0
  enddo
 enddo


 print*,''
 print*,'Inactive-active Part of the One body DM'
 print*,''
 do i = 1,n_act_orb
  iorb = list_act(i)
  print*,''
  print*,'ACTIVE ORBITAL  ',iorb
  do j = 1, n_inact_orb
   jorb = list_inact(j)
   if(dabs(one_body_dm_mo(iorb,jorb)).gt.threshold_singles)then
    print*,'INACTIVE  '
    print*,'DM ',iorb,jorb,dabs(one_body_dm_mo(iorb,jorb))
   endif
  enddo
  do j = 1, n_virt_orb
   jorb = list_virt(j)
   if(dabs(one_body_dm_mo(iorb,jorb)).gt.threshold_singles)then
    print*,'VIRT      '
    print*,'DM ',iorb,jorb,dabs(one_body_dm_mo(iorb,jorb))
   endif
  enddo
 enddo
 do i = 1, mo_tot_num
  do j = i+1, mo_tot_num
   if(dabs(one_body_dm_mo(i,j)).le.threshold_fobo_dm)then
      one_body_dm_mo(i,j) = 0.d0
      one_body_dm_mo(j,i) = 0.d0
   endif
  enddo
 enddo






 label = "Natural"
 character*(64) :: label
 integer :: sign
 sign = -1
 
 call mo_as_eigvectors_of_mo_matrix(one_body_dm_mo,size(one_body_dm_mo,1),size(one_body_dm_mo,2),label,sign)
 soft_touch mo_coef
 call save_mos
 
 deallocate(eigvalues,eigvectors,psi_det_final,psi_coef_final)




 deallocate(H_matrix_total)
 deallocate(psi_good_det)
 deallocate(dressing_restart_good_det)
 deallocate(dressing_matrix_restart_1h1p)
 deallocate(dressing_matrix_restart_2h1p)
 deallocate(dressing_diag_good_det)

end


