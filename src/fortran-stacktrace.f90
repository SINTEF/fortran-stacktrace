module fortran_stacktrace
  implicit none
  private

  public :: say_hello
contains
  subroutine say_hello
    print *, "Hello, fortran-stacktrace!"
  end subroutine say_hello
end module fortran_stacktrace
