! SPDX-FileCopyrightText: 2022 SINTEF Ocean
! SPDX-License-Identifier: MIT

submodule(stacktrace_mod) hook_impl

contains


    pure module subroutine create_handler(this, root_cause, handler)
        class(stacktrace_error_hook_t), intent(in) :: this
        class(fail_reason_t), intent(in) :: root_cause
        class(error_handler_t), allocatable, intent(inout) :: handler

        type(stacktrace_error_handler_t), allocatable :: tmp

        allocate(tmp)
        allocate(tmp%stacktrace)
        call tmp%stacktrace%st%load_here(num_skip=3)
        tmp%snippet = this%snippet
        call move_alloc(tmp, handler)
        ! Avoid unused argument warning
        associate (dummy => root_cause)
        end associate
    end subroutine


    pure module function display_handler(this, root_cause, chain) result(chars)
        class(stacktrace_error_handler_t), intent(in) :: this
        class(fail_reason_t), intent(in) :: root_cause
        type(fail_reason_ctr_t), intent(in) :: chain(:)
        character(len=:), allocatable :: chars

        integer :: idx
        integer :: n

        n = size(chain)
        if (n == 0) then
            chars = 'Error: ' // indent_newlines(root_cause%describe(), 7)
        else
            chars = 'Error: ' // indent_newlines(chain(n)%reason%describe(), 7)
            chars = chars // new_line('c') &
                // 'Caused by: '
            do idx = n - 1, 1, -1
                chars = chars // new_line('c') &
                    // '  - ' // indent_newlines(chain(idx)%reason%describe(), 4)
            end do
                chars = chars // new_line('c') &
                    // '  - ' // indent_newlines(root_cause%describe(), 4)
        end if

        if (allocated(this%stacktrace)) then
            chars = chars // new_line('c') &
                // new_line('c') &
                // this%stacktrace%st%display(snippet=this%snippet)
        end if
    end function


    recursive pure function indent_newlines(chars, n) result(indented)
        character(len=*), intent(in) :: chars
        integer, intent(in) :: n
        character(len=:), allocatable :: indented

        integer :: idx

        idx = index(chars, new_line('c'))
        if (idx <= 0) then
            indented = chars
        else
            indented = chars(1:idx)    &
                // repeat(' ', n) // indent_newlines(chars(idx + 1:), n)
        end if
    end function

end submodule