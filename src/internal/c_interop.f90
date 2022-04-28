! SPDX-FileCopyrightText: 2022 SINTEF Ocean
! SPDX-License-Identifier: MIT

module internal_stacktrace_c_interop
    use iso_c_binding, only: c_char, c_null_char, c_ptr, c_f_pointer
    implicit none

    private
    public stacktrace_string_t

    type :: stacktrace_string_t
        character(len=:), allocatable :: chars
    end type

contains


    subroutine stacktrace__set_f_string(ptr, chars) bind(c)
        type(c_ptr), intent(inout) :: ptr
        character(len=1, kind=c_char), intent(in) :: chars(*)

        type(stacktrace_string_t), pointer :: str

        call c_f_pointer(ptr, str)
        str%chars = to_f_chars(chars)
    end subroutine


    pure function to_f_chars(val) result(chars)
        character(len=1, kind=c_char), intent(in) :: val(*)

        integer :: i
        integer :: n
        character(kind=c_char) :: c
        character(len=:), allocatable :: chars

        !Find length
        i = 1
        c = val(i)
        do while(c /= c_null_char)
            i = i + 1
            c = val(i)
        end do
        n = i - 1
        allocate(character(len=n) :: chars)
        do i = 1, n
           chars(i:i) = val(i)
        end do
    end function

end module