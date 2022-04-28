! SPDX-FileCopyrightText: 2022 SINTEF Ocean
! SPDX-License-Identifier: MIT

module stacktrace_mod
    use iso_c_binding, only: &
        c_ptr, &
        c_null_ptr
    use error_handling, only: &
        error_hook_t, &
        error_handler_t, &
        fail_reason_t, &
        fail_reason_ctr_t
    implicit none

    private
    public stacktrace_t
    public stacktrace_error_hook_t
    public stacktrace_error_handler_t


    !
    ! Stacktrace generation
    !

    type :: stacktrace_t
        !> Type for generating a stacktrace from the point where load_here is called
        private
        type(c_ptr) :: c_obj = c_null_ptr
    contains
        procedure :: load_here
        procedure :: display

        generic :: assignment(=) => assign
        procedure, private :: assign
        final :: destruct
    end type


    interface
        !> Generate a stacktrace for the point where this procedure is called
        pure module subroutine load_here(this, max_depth, num_skip)
            class(stacktrace_t), intent(inout) :: this
            !> Maximum depth of stacktrace. Default: 128
            integer, optional, intent(in) :: max_depth
            !> Number of stack frames to skip in presented stacktrace. By default
            !! the stack trace will stop at the caller of this routine. Default: 0
            integer, optional, intent(in) :: num_skip
        end subroutine


        !> Generate a character string with the stacktrace in it
        pure module function display(this, snippet) result(chars)
            class(stacktrace_t), intent(in) :: this
            !> Should source code snippets be included, if they are available? Default: True
            logical, optional, intent(in) :: snippet
            character(len=:), allocatable :: chars
        end function


        pure module subroutine assign(lhs, rhs)
            class(stacktrace_t), intent(inout) :: lhs
            type(stacktrace_t), intent(in) :: rhs
        end subroutine


        pure module subroutine destruct(this)
            type(stacktrace_t), intent(inout) :: this
        end subroutine
    end interface


    !
    ! Error handling integration
    !

    type, extends(error_hook_t) :: stacktrace_error_hook_t
        !> Custom hook for fortran-error-handling to include a stacktrace in errors.

        !> Should stacktrace include snippets? Default: True
        logical :: snippet = .true.
    contains
        procedure :: create_handler
    end type


    interface
        pure module subroutine create_handler(this, root_cause, handler)
            class(stacktrace_error_hook_t), intent(in) :: this
            class(fail_reason_t), intent(in) :: root_cause
            class(error_handler_t), allocatable, intent(inout) :: handler
        end subroutine
    end interface


    ! This is for some reason needed to avoid crashes with Intel Fortran. Compiler bug?
    type :: stacktrace_ctr_t
        type(stacktrace_t) :: st
    end type


    type, extends(error_handler_t) :: stacktrace_error_handler_t
        type(stacktrace_ctr_t), allocatable :: stacktrace
        logical :: snippet
    contains
        procedure :: display => display_handler
    end type


    interface
        pure module function display_handler(this, root_cause, chain) result(chars)
            class(stacktrace_error_handler_t), intent(in) :: this
            class(fail_reason_t), intent(in) :: root_cause
            type(fail_reason_ctr_t), intent(in) :: chain(:)
            character(len=:), allocatable :: chars
        end function
    end interface

end module