! SPDX-FileCopyrightText: 2022 SINTEF Ocean
! SPDX-License-Identifier: MIT

submodule(stacktrace_mod) stacktrace_impl
    use iso_c_binding, only:                                            &
        c_int, c_bool, c_loc, c_associated
    use internal_stacktrace_c_interop, only: stacktrace_string_t
    implicit none


    interface
        pure subroutine stacktrace__destruct(ptr) bind(c)
            import
            type(c_ptr), value, intent(in) :: ptr
        end subroutine


        pure function stacktrace__assign_from(ptr) result(new_ptr) bind(c)
            import
            type(c_ptr), value, intent(in) :: ptr
            type(c_ptr) :: new_ptr
        end function


        pure function stacktrace__load_here(max_traces, num_skip) result(ptr) bind(c)
            import
            integer(c_int), value, intent(in) :: max_traces
            integer(c_int), value, intent(in) :: num_skip
            type(c_ptr) :: ptr
        end function


        pure subroutine stacktrace__to_chars(ptr, snippet, fstr) bind(c)
            import
            type(c_ptr), value, intent(in) :: ptr
            logical(c_bool), value, intent(in) :: snippet
            type(c_ptr), intent(in) :: fstr
        end subroutine
    end interface

contains


    pure module subroutine load_here(this, max_depth, num_skip)
        class(stacktrace_t), intent(inout) :: this
        integer, optional, intent(in) :: max_depth
        integer, optional, intent(in) :: num_skip

        integer :: the_max_depth
        integer :: the_num_skip

        ! Calling this subroutine pure is kind of pushing the term because
        ! it will produce a different result depending on where it's called
        ! from. It's useful to get stacktraces from a pure procedure though,
        ! so we live with this cheat...

        the_max_depth = 128
        if(present(max_depth)) the_max_depth = max_depth
        the_num_skip = 0
        if(present(num_skip)) the_num_skip = num_skip

        this%c_obj = stacktrace__load_here(the_max_depth, the_num_skip)
    end subroutine


    pure module subroutine assign(lhs, rhs)
        class(stacktrace_t), intent(inout) :: lhs
        type(stacktrace_t), intent(in) :: rhs

        if (c_associated(lhs%c_obj)) then
            call destruct(lhs)
        end if
        if (c_associated(rhs%c_obj)) then
            lhs%c_obj = stacktrace__assign_from(rhs%c_obj)
        end if
    end subroutine


    pure module subroutine destruct(this)
        type(stacktrace_t), intent(inout) :: this

        if (c_associated(this%c_obj)) then
            call stacktrace__destruct(this%c_obj)
        end if
    end subroutine


    pure module function display(this, snippet) result(chars)
        class(stacktrace_t), intent(in) :: this
        logical, optional, intent(in) :: snippet
        character(len=:), allocatable :: chars

        logical :: show_snippets
        type(stacktrace_string_t), target :: str

        ! If no stacktrace is loaded with load_here, there is nothing to generate
        if (.not. c_associated(this%c_obj)) then
            chars = ''
            return
        end if

        show_snippets = .true.
        if (present(snippet)) show_snippets = snippet

        call stacktrace__to_chars(this%c_obj, logical(show_snippets, c_bool), c_loc(str))
        chars = str%chars
    end function

end submodule