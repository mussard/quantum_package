double precision function overlap_gaussian_x(A_center,B_center,alpha,beta,power_A,power_B,dim)
  implicit none
  BEGIN_DOC
  !.. math:: 
  !
  ! \sum_{-infty}^{+infty} (x-A_x)^ax (x-B_x)^bx exp(-alpha(x-A_x)^2) exp(-beta(x-B_X)^2) dx
  !
  END_DOC
  include 'constants.include.F'
  integer,intent(in)             :: dim ! dimension maximum for the arrays representing the polynomials
  double precision,intent(in)    :: A_center,B_center  ! center of the x1 functions
  integer,intent(in)             :: power_A, power_B ! power of the x1 functions
  double precision               :: P_new(0:max_dim),P_center,fact_p,p,alpha,beta
  integer                        :: iorder_p
  call give_explicit_poly_and_gaussian_x(P_new,P_center,p,fact_p,iorder_p,alpha,&
      beta,power_A,power_B,A_center,B_center,dim)
  
! if(fact_p.lt.0.000001d0)then
!   overlap_gaussian_x = 0.d0
!   return
! endif
  
  overlap_gaussian_x = 0.d0
  integer                        :: i
  double precision               :: F_integral
  
  do i = 0,iorder_p
    overlap_gaussian_x += P_new(i) * F_integral(i,p)
  enddo
  
  overlap_gaussian_x*= fact_p
end


subroutine overlap_A_B_C(dim,alpha,beta,gama,a,b,A_center,B_center,Nucl_center,overlap)
 implicit none
  include 'constants.include.F'
 integer, intent(in)            :: dim                                                             
 integer, intent(in)            :: a(3),b(3)         ! powers : (x-xa)**a_x = (x-A(1))**a(1)
 double precision, intent(in)   :: alpha, beta, gama ! exponents
 double precision, intent(in)   :: A_center(3)       ! A center
 double precision, intent(in)   :: B_center (3)      ! B center
 double precision, intent(in)   :: Nucl_center(3)    ! B center
 double precision, intent(out)  :: overlap

 double precision               :: P_new(0:max_dim,3),P_center(3),fact_p,p
 double precision               :: F_integral_tab(0:max_dim)
 integer                        :: iorder_p(3)
 double precision :: overlap_x,overlap_z,overlap_y

 call give_explicit_poly_and_gaussian_double(P_new,P_center,p,fact_p,iorder_p,alpha,beta,gama,a,b,A_center,B_center,Nucl_center,dim)
  if(fact_p.lt.1d-10)then
!   overlap_x = 0.d0
!   overlap_y = 0.d0
!   overlap_z = 0.d0
    overlap = 0.d0
    return
  endif

  integer                        :: nmax
  double precision               :: F_integral
  nmax = maxval(iorder_p)
  do i = 0,nmax
    F_integral_tab(i) = F_integral(i,p)
  enddo
  overlap_x = P_new(0,1) * F_integral_tab(0)
  overlap_y = P_new(0,2) * F_integral_tab(0)
  overlap_z = P_new(0,3) * F_integral_tab(0)
  
  integer                        :: i
  do i = 1,iorder_p(1)
    overlap_x += P_new(i,1) * F_integral_tab(i)
  enddo
  do i = 1,iorder_p(2)
    overlap_y += P_new(i,2) * F_integral_tab(i)
  enddo
  do i = 1,iorder_p(3)
    overlap_z += P_new(i,3) * F_integral_tab(i)
  enddo
  overlap = overlap_x * overlap_y * overlap_z * fact_p 
  
!double precision :: overlap_x_1,overlap_y_1,overlap_z_1,overlap_1
!call test(alpha,beta,gama,a,b,A_center,B_center,Nucl_center,overlap_x_1,overlap_y_1,overlap_z_1,overlap_1)
!print*,'overlap_1 = ',overlap_1
!print*,'overlap   = ',overlap
!if(dabs(overlap - overlap_1).ge.1.d-3)then
!  print*,'power_A(1) = ',a(1)
!  print*,'power_A(2) = ',a(2)
!  print*,'power_A(3) = ',a(3)
!  print*,'power_B(1) = ',b(1)
!  print*,'power_B(2) = ',b(2)
!  print*,'power_B(3) = ',b(3)
!  print*,'alpha = ',alpha
!  print*,'beta = ',beta
!  print*,'gama = ',gama
!  print*,'A_center(1) = ',A_center(1)
!  print*,'A_center(2) = ',A_center(2)
!  print*,'A_center(3) = ',A_center(3)
!  print*,'B_center(1) = ',B_center(1)
!  print*,'B_center(2) = ',B_center(2)
!  print*,'B_center(3) = ',B_center(3)
!  print*,'Nucl_center(1) = ',Nucl_center(1)
!  print*,'Nucl_center(2) = ',Nucl_center(2)
!  print*,'Nucl_center(3) = ',Nucl_center(3)
!  print*,'overlap = ',overlap
!  print*,'overlap_1=',overlap_1

!  stop
!endif

end

subroutine overlap_gaussian_xyz(A_center,B_center,alpha,beta,power_A,&
      power_B,overlap_x,overlap_y,overlap_z,overlap,dim)
  implicit none
  BEGIN_DOC
  !.. math:: 
  !
  !   S_x = \int (x-A_x)^{a_x} exp(-\alpha(x-A_x)^2)  (x-B_x)^{b_x} exp(-beta(x-B_x)^2) dx \\
  !   S = S_x S_y S_z
  !
  END_DOC
  include 'constants.include.F'
  integer,intent(in)             :: dim ! dimension maximum for the arrays representing the polynomials
  double precision,intent(in)    :: A_center(3),B_center(3)  ! center of the x1 functions
  double precision, intent(in)   :: alpha,beta
  integer,intent(in)             :: power_A(3), power_B(3) ! power of the x1 functions
  double precision, intent(out)  :: overlap_x,overlap_y,overlap_z,overlap
  double precision               :: P_new(0:max_dim,3),P_center(3),fact_p,p
  double precision               :: F_integral_tab(0:max_dim)
  integer                        :: iorder_p(3)
  
  call give_explicit_poly_and_gaussian(P_new,P_center,p,fact_p,iorder_p,alpha,beta,power_A,power_B,A_center,B_center,dim)
!  if(fact_p.lt.1d-20)then
!    overlap_x = 0.d0
!    overlap_y = 0.d0
!    overlap_z = 0.d0
!    overlap = 0.d0
!    return
!  endif
  integer                        :: nmax
  double precision               :: F_integral
  nmax = maxval(iorder_p)
  do i = 0,nmax
    F_integral_tab(i) = F_integral(i,p)
  enddo
  overlap_x = P_new(0,1) * F_integral_tab(0)
  overlap_y = P_new(0,2) * F_integral_tab(0)
  overlap_z = P_new(0,3) * F_integral_tab(0)
  
  integer                        :: i
  do i = 1,iorder_p(1)
    overlap_x = overlap_x + P_new(i,1) * F_integral_tab(i)
  enddo
  call gaussian_product_x(alpha,A_center(1),beta,B_center(1),fact_p,p,P_center(1))
  overlap_x *= fact_p
  
  do i = 1,iorder_p(2)
    overlap_y = overlap_y + P_new(i,2) * F_integral_tab(i)
  enddo
  call gaussian_product_x(alpha,A_center(2),beta,B_center(2),fact_p,p,P_center(2))
  overlap_y *= fact_p
  
  do i = 1,iorder_p(3)
    overlap_z = overlap_z + P_new(i,3) * F_integral_tab(i)
  enddo
  call gaussian_product_x(alpha,A_center(3),beta,B_center(3),fact_p,p,P_center(3))
  overlap_z *= fact_p
  
  overlap = overlap_x * overlap_y * overlap_z
  
end
   

subroutine overlap_x_abs(A_center,B_center,alpha,beta,power_A,power_B,overlap_x,lower_exp_val,dx,nx)
  implicit none
  BEGIN_DOC
  ! .. math                      :: 
  !
  !  \int_{-infty}^{+infty} (x-A_center)^(power_A) * (x-B_center)^power_B * exp(-alpha(x-A_center)^2) * exp(-beta(x-B_center)^2) dx
  !
  END_DOC
  integer                        :: i,j,k,l
  integer,intent(in)             :: power_A,power_B
  double precision, intent(in)   :: lower_exp_val
  double precision,intent(in)    :: A_center, B_center,alpha,beta
  double precision, intent(out)  :: overlap_x,dx
  integer, intent(in)            :: nx
  double precision               :: x_min,x_max,domain,x,factor,dist,p,p_inv,rho
  double precision               :: P_center
  if(power_A.lt.0.or.power_B.lt.0)then
    overlap_x = 0.d0
    dx = 0.d0
    return
  endif
  p = alpha + beta
  p_inv= 1.d0/p
  rho = alpha * beta * p_inv
  dist = (A_center - B_center)*(A_center - B_center)
  P_center = (alpha * A_center + beta * B_center) * p_inv
  if(rho*dist.gt.80.d0)then
   overlap_x= 0.d0
   return
  endif
  factor = dexp(-rho * dist)
  
  double precision               :: tmp
  
  tmp = dsqrt(lower_exp_val/p)
  x_min = P_center - tmp
  x_max = P_center + tmp
  domain = x_max-x_min
  dx = domain/dble(nx)
  overlap_x = 0.d0
  x = x_min
  do i = 1, nx
    x += dx
    overlap_x += abs((x-A_center)**power_A * (x-B_center)**power_B) * dexp(-p * (x-P_center)*(x-P_center))
  enddo
  
  overlap_x = factor * dx * overlap_x
end



