
program scf
  call orthonormalize_mos
  call run
end

subroutine run

  use bitmasks
  implicit none
  double precision               :: SCF_energy_before,SCF_energy_after,diag_H_mat_elem,get_mo_bielec_integral
  double precision               :: E0
  integer                        :: i_it, i, j, k
   
  E0 = HF_energy 
  
  thresh_SCF = 1.d-10
  call damping_SCF
  mo_label = "Canonical"
  TOUCH mo_label mo_coef
  call save_mos
  
end